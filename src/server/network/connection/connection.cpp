/**
 * Canary - A free and open-source MMORPG server emulator
 * Copyright (©) 2019–present OpenTibiaBR <opentibiabr@outlook.com>
 * Repository: https://github.com/opentibiabr/canary
 * License: https://github.com/opentibiabr/canary/blob/main/LICENSE
 * Contributors: https://github.com/opentibiabr/canary/graphs/contributors
 * Website: https://docs.opentibiabr.com/
 */

#include "server/network/connection/connection.hpp"

#include "config/configmanager.hpp"
#include "lib/di/container.hpp"
#include "server/network/message/outputmessage.hpp"
#include "server/network/protocol/protocol.hpp"
#include "server/network/protocol/transport_codec.hpp"
#include "game/scheduling/dispatcher.hpp"
#include "server/network/message/networkmessage.hpp"
#include "server/network/protocol/protocolgame.hpp"
#include "server/server.hpp"
#include "utils/tools.hpp"

ConnectionManager &ConnectionManager::getInstance() {
	return inject<ConnectionManager>();
}

Connection_ptr ConnectionManager::createConnection(asio::io_service &io_service, const ConstServicePort_ptr &servicePort) {
	auto connection = std::make_shared<Connection>(io_service, servicePort);
	connections.emplace(connection);
	return connection;
}

void ConnectionManager::releaseConnection(const Connection_ptr &connection) {
	connections.erase(connection);
}

void ConnectionManager::closeAll() {
	connections.for_each([&](const Connection_ptr &connection) {
		if (connection->socket.is_open()) {
			try {
				std::error_code error;
				connection->socket.shutdown(asio::ip::tcp::socket::shutdown_both, error);
				if (error) {
					g_logger().error("[ConnectionManager::closeAll] - Failed to close connection, system error code {}", error.message());
				}
			} catch (const std::system_error &systemError) {
				g_logger().error("[ConnectionManager::closeAll] - Exception caught: {}", systemError.what());
			}
		}
	});

	connections.clear();
}

Connection::Connection(asio::io_service &initIoService, ConstServicePort_ptr initservicePort) :
	readTimer(initIoService),
	writeTimer(initIoService),
	service_port(std::move(initservicePort)),
	transportCodec(&TransportCodecs::rawClientFirst()),
	socket(initIoService), m_msg() {
	g_logger().error("[Connection::Connection] - DIAGNOSTIC: constructed, this={}", static_cast<const void*>(this));
}

Connection::~Connection() {
	g_logger().error("[Connection::~Connection] - DIAGNOSTIC: destroyed, this={}", static_cast<const void*>(this));
}

void Connection::close(bool force) {
	g_logger().error("[Connection::close] - DIAGNOSTIC: called, this={}, force={}, priorState={}", static_cast<const void*>(this), force, static_cast<int>(connectionState));
	ConnectionManager::getInstance().releaseConnection(shared_from_this());

	std::scoped_lock lock(connectionLock);
	ip = 0;

	if (connectionState == CONNECTION_STATE_CLOSED) {
		return;
	}
	connectionState = CONNECTION_STATE_CLOSED;

	if (protocol) {
		g_dispatcher().addEvent([protocol = protocol] { protocol->release(); }, __FUNCTION__, std::chrono::milliseconds(CONNECTION_WRITE_TIMEOUT * 1000).count());
	}

	if (messageQueue.empty() || force) {
		closeSocket();
	}
}

void Connection::closeSocket() {
	if (!socket.is_open()) {
		return;
	}

	try {
		readTimer.cancel();
		writeTimer.cancel();
		socket.cancel();

		std::error_code error;
		socket.shutdown(asio::ip::tcp::socket::shutdown_both, error);
		if (error && error != asio::error::not_connected) {
			g_logger().error("[Connection::closeSocket] - Failed to shutdown socket: {}", error.message());
		}

		socket.close(error);
		if (error && error != asio::error::not_connected) {
			g_logger().error("[Connection::closeSocket] - Failed to close socket: {}", error.message());
		}
	} catch (const std::system_error &e) {
		g_logger().error("[Connection::closeSocket] - error closeSocket: {}", e.what());
	}
}

void Connection::accept(Protocol_ptr protocolPtr) {
	connectionState = CONNECTION_STATE_IDENTIFYING;
	protocol = std::move(protocolPtr);
	g_logger().error("[Connection::accept] - DIAGNOSTIC: this={}, calling onConnectionAccepted", static_cast<const void*>(this));
	protocol->onConnectionAccepted();
	g_logger().error("[Connection::accept] - DIAGNOSTIC: this={}, onConnectionAccepted returned, state={}", static_cast<const void*>(this), static_cast<int>(connectionState));

	if (connectionState == CONNECTION_STATE_CLOSED) {
		g_logger().error("[Connection::accept] - DIAGNOSTIC: this={}, bailing, state is CLOSED", static_cast<const void*>(this));
		return;
	}

	g_logger().error("[Connection::accept] - DIAGNOSTIC: this={}, calling acceptInternal", static_cast<const void*>(this));
	acceptInternal(false);
	g_logger().error("[Connection::accept] - DIAGNOSTIC: this={}, acceptInternal returned", static_cast<const void*>(this));
}

void Connection::acceptInternal(bool toggleParseHeader) {
	readTimer.expires_from_now(std::chrono::seconds(CONNECTION_READ_TIMEOUT));
	readTimer.async_wait([self = std::weak_ptr<Connection>(shared_from_this())](const std::error_code &error) { Connection::handleTimeout(self, error); });

	try {
		asio::async_read(socket, asio::buffer(m_msg.getBuffer(), HEADER_LENGTH), [self = shared_from_this(), toggleParseHeader](const std::error_code &error, std::size_t N) {
			if (toggleParseHeader) {
				self->parseHeader(error);
			} else {
				self->parseProxyIdentification(error);
			}
		});
	} catch (const std::system_error &e) {
		g_logger().error("[Connection::acceptInternal] - Exception in async_read: {}", e.what());
		close(FORCE_CLOSE);
	}
}

void Connection::parseProxyIdentification(const std::error_code &error) {
	std::scoped_lock lock(connectionLock);
	g_logger().error("[Connection::parseProxyIdentification] - DIAGNOSTIC: entered, this={}, error={}", static_cast<const void*>(this), error.message());
	readTimer.cancel();

	if (error || connectionState == CONNECTION_STATE_CLOSED) {
		// TEMP DIAGNOSTIC (2026-08-24): log unconditionally, including reset/eof/aborted.
		g_logger().error("[Connection::parseProxyIdentification] - DIAGNOSTIC: this={}, Read error: {} (state closed: {})", static_cast<const void*>(this), error.message(), connectionState == CONNECTION_STATE_CLOSED);
		close(FORCE_CLOSE);
		return;
	}

	uint8_t* msgBuffer = m_msg.getBuffer();
	auto charData = static_cast<char*>(static_cast<void*>(msgBuffer));
	std::string serverName = g_configManager().getString(SERVER_NAME) + "\n";
	if (connectionState == CONNECTION_STATE_IDENTIFYING) {
		if (msgBuffer[1] == 0x00 || strncasecmp(charData, &serverName[0], 2) != 0) {
			// Probably not proxy identification so let's try standard parsing method
			connectionState = CONNECTION_STATE_OPEN;
			parseHeader(error);
			return;
		} else {
			size_t remainder = serverName.length() - 2;
			if (remainder > 0) {
				connectionState = CONNECTION_STATE_READINGS;
				try {
					readTimer.expires_from_now(std::chrono::seconds(CONNECTION_READ_TIMEOUT));
					readTimer.async_wait([self = std::weak_ptr<Connection>(shared_from_this())](const std::error_code &error) { Connection::handleTimeout(self, error); });

					// Read the remainder of proxy identification
					asio::async_read(socket, asio::buffer(m_msg.getBuffer(), remainder), [self = shared_from_this()](const std::error_code &error, std::size_t N) { self->parseProxyIdentification(error); });
				} catch (const std::system_error &e) {
					g_logger().error("Connection::parseProxyIdentification] - error: {}", e.what());
					close(FORCE_CLOSE);
				}
				return;
			} else {
				connectionState = CONNECTION_STATE_OPEN;
			}
		}
	} else if (connectionState == CONNECTION_STATE_READINGS) {
		size_t remainder = serverName.length() - 2;
		if (strncasecmp(charData, &serverName[2], remainder) == 0) {
			connectionState = CONNECTION_STATE_OPEN;
		} else {
			g_logger().error("Connection::parseProxyIdentification] Invalid Client Login! Server Name mismatch!");
			close(FORCE_CLOSE);
			return;
		}
	}

	acceptInternal(true);
}

void Connection::parseHeader(const std::error_code &error) {
	std::scoped_lock lock(connectionLock);
	g_logger().error("[Connection::parseHeader] - DIAGNOSTIC: entered, this={}, error={}", static_cast<const void*>(this), error.message());
	readTimer.cancel();

	if (error) {
		// TEMP DIAGNOSTIC (2026-08-24): log unconditionally, including reset/eof/aborted.
		g_logger().error("[Connection::parseHeader] - DIAGNOSTIC: this={}, Read error: {}", static_cast<const void*>(this), error.message());
		close(FORCE_CLOSE);
		return;
	} else if (connectionState == CONNECTION_STATE_CLOSED) {
		return;
	}

	uint32_t timePassed = std::max<uint32_t>(1, (time(nullptr) - timeConnected) + 1);
	if ((++packetsSent / timePassed) > static_cast<uint32_t>(g_configManager().getNumber(MAX_PACKETS_PER_SECOND))) {
		g_logger().warn("[Connection::parseHeader] - {} disconnected for exceeding packet per second limit.", convertIPToString(getIP()));
		close();
		return;
	}

	if (timePassed > 2) {
		timeConnected = time(nullptr);
		packetsSent = 0;
	}

	const auto size = getTransportCodec().decodeBodySize(m_msg.getLengthHeader());

	if (!size || *size > INPUTMESSAGE_MAXSIZE) {
		close(FORCE_CLOSE);
		return;
	}

	try {
		readTimer.expires_from_now(std::chrono::seconds(CONNECTION_READ_TIMEOUT));
		readTimer.async_wait([self = std::weak_ptr<Connection>(shared_from_this())](const std::error_code &error) { Connection::handleTimeout(self, error); });

		// Read packet content
		m_msg.setLength(*size + HEADER_LENGTH);
		// Read the remainder of proxy identification
		asio::async_read(socket, asio::buffer(m_msg.getBodyBuffer(), *size), [self = shared_from_this()](const std::error_code &error, std::size_t N) { self->parsePacket(error); });
	} catch (const std::system_error &e) {
		g_logger().error("[Connection::parseHeader] - error: {}", e.what());
		close(FORCE_CLOSE);
	}
}

void Connection::parsePacket(const std::error_code &error) {
	std::scoped_lock lock(connectionLock);
	readTimer.cancel();

	if (error || connectionState == CONNECTION_STATE_CLOSED) {
		if (error) {
			g_logger().debug("[Connection::parsePacket] - Read error: {}", error.message());
		}
		close(FORCE_CLOSE);
		return;
	}

	bool skipReadingNextPacket = false;
	if (!receivedFirst) {
		// First message received
		receivedFirst = true;

		if (!protocol) {
			// Check packet checksum
			uint32_t checksum;
			if (int32_t len = m_msg.getLength() - m_msg.getBufferPosition() - CHECKSUM_LENGTH;
			    len > 0) {
				checksum = adlerChecksum(m_msg.getBuffer() + m_msg.getBufferPosition() + CHECKSUM_LENGTH, len);
			} else {
				checksum = 0;
			}

			uint32_t recvChecksum = m_msg.get<uint32_t>();
			if (recvChecksum != checksum) {
				// it might not have been the checksum, step back
				m_msg.skipBytes(-CHECKSUM_LENGTH);
			}

			// Game protocol has already been created at this point
			protocol = service_port->make_protocol(recvChecksum == checksum, m_msg, shared_from_this());
			if (!protocol) {
				close(FORCE_CLOSE);
				return;
			}
		} else {
			m_msg.skipBytes(getTransportCodec().getProfile().serverFirstPacketHeaderBytes);
		}

		protocol->onRecvFirstMessage(m_msg);
	} else {
		// Send the packet to the current protocol
		skipReadingNextPacket = protocol->onRecvMessage(m_msg);
	}

	try {
		readTimer.expires_from_now(std::chrono::seconds(CONNECTION_READ_TIMEOUT));
		readTimer.async_wait([self = std::weak_ptr<Connection>(shared_from_this())](const std::error_code &error) { Connection::handleTimeout(self, error); });

		if (!skipReadingNextPacket) {
			// Wait to the next packet
			asio::async_read(socket, asio::buffer(m_msg.getBuffer(), HEADER_LENGTH), [self = shared_from_this()](const std::error_code &error, std::size_t N) { self->parseHeader(error); });
		}
	} catch (const std::system_error &e) {
		g_logger().error("[Connection::parsePacket] - error: {}", e.what());
		close(FORCE_CLOSE);
	}
}

void Connection::resumeWork() {
	readTimer.expires_from_now(std::chrono::seconds(CONNECTION_READ_TIMEOUT));
	readTimer.async_wait([self = std::weak_ptr<Connection>(shared_from_this())](const std::error_code &error) { Connection::handleTimeout(self, error); });

	try {
		asio::async_read(socket, asio::buffer(m_msg.getBuffer(), HEADER_LENGTH), [self = shared_from_this()](const std::error_code &error, std::size_t N) { self->parseHeader(error); });
	} catch (const std::system_error &e) {
		g_logger().error("[Connection::resumeWork] - Exception in async_read: {}", e.what());
		close(FORCE_CLOSE);
	}
}

void Connection::send(const OutputMessage_ptr &outputMessage) {
	std::scoped_lock lock(connectionLock);
	g_logger().error("[Connection::send] - DIAGNOSTIC: entered, this={}", static_cast<const void*>(this));
	if (connectionState == CONNECTION_STATE_CLOSED) {
		g_logger().error("[Connection::send] - DIAGNOSTIC: bailing out, this={}, connectionState already CLOSED", static_cast<const void*>(this));
		return;
	}

	bool noPendingWrite = messageQueue.empty();
	messageQueue.emplace_back(outputMessage);

	if (noPendingWrite) {
		if (socket.is_open()) {
			try {
				g_logger().error("[Connection::send] - DIAGNOSTIC: posting internalWorker");
				asio::post(socket.get_executor(), [self = shared_from_this()] { self->internalWorker(); });
			} catch (const std::system_error &e) {
				g_logger().error("[Connection::send] - Exception in posting write operation: {}", e.what());
				close(FORCE_CLOSE);
			}
		} else {
			g_logger().error("[Connection::send] - Socket is not open for writing.");
			close(FORCE_CLOSE);
		}
	} else {
		g_logger().error("[Connection::send] - DIAGNOSTIC: pending write already in flight, queued instead");
	}
}

void Connection::internalWorker() {
	std::unique_lock lock(connectionLock);
	g_logger().error("[Connection::internalWorker] - DIAGNOSTIC: entered, queueSize={}, state={}", messageQueue.size(), static_cast<int>(connectionState));
	if (messageQueue.empty()) {
		if (connectionState == CONNECTION_STATE_CLOSED) {
			closeSocket();
		}
		return;
	}

	const auto &outputMessage = messageQueue.front();
	lock.unlock();
	protocol->onSendMessage(outputMessage);
	lock.lock();

	// The lock was released above -- another thread may have closed this connection
	// (and the underlying socket) in the meantime. Writing to an already-closed socket
	// here would surface as a Win32 ERROR_INVALID_HANDLE from async_write. Bail out instead.
	if (connectionState == CONNECTION_STATE_CLOSED || !socket.is_open()) {
		g_logger().error("[Connection::internalWorker] - DIAGNOSTIC: bailing out after onSendMessage, state={}, socketOpen={}", static_cast<int>(connectionState), socket.is_open());
		return;
	}

	g_logger().error("[Connection::internalWorker] - DIAGNOSTIC: calling internalSend");
	internalSend(outputMessage);
}

uint32_t Connection::getIP() {
	std::scoped_lock lock(connectionLock);

	if (ip == 1) {
		std::error_code error;
		asio::ip::tcp::endpoint endpoint = socket.remote_endpoint(error);
		if (error) {
			g_logger().error("[Connection::getIP] - Failed to get remote endpoint: {}", error.message());
			ip = 0;
		} else {
			ip = htonl(endpoint.address().to_v4().to_uint());
		}
	}
	return ip;
}

void Connection::setTransportCodec(const TransportCodec &codec, InitialTransportState state) {
	std::scoped_lock lock(connectionLock);
	transportCodec = &codec;
	initialTransportState = state;
}

void Connection::setInitialTransportState(InitialTransportState state) {
	std::scoped_lock lock(connectionLock);
	initialTransportState = state;
}

const TransportCodec &Connection::getTransportCodec() const {
	return transportCodec ? *transportCodec : TransportCodecs::rawClientFirst();
}

InitialTransportState Connection::getInitialTransportState() const {
	return initialTransportState;
}

void Connection::internalSend(const OutputMessage_ptr &outputMessage) {
	writeTimer.expires_from_now(std::chrono::seconds(CONNECTION_WRITE_TIMEOUT));
	writeTimer.async_wait([self = std::weak_ptr<Connection>(shared_from_this())](const std::error_code &error) { Connection::handleTimeout(self, error); });

	try {
		asio::async_write(socket, asio::buffer(outputMessage->getOutputBuffer(), outputMessage->getLength()), [self = shared_from_this()](const std::error_code &error, std::size_t N) { self->onWriteOperation(error); });
	} catch (const std::system_error &e) {
		g_logger().error("[Connection::internalSend] - Exception in async_write: {}", e.what());
		close(FORCE_CLOSE);
	}
}

void Connection::onWriteOperation(const std::error_code &error) {
	std::unique_lock lock(connectionLock);
	writeTimer.cancel();

	if (error) {
		g_logger().error("[Connection::onWriteOperation] - Write error: {}", error.message());
		messageQueue.clear();
		close(FORCE_CLOSE);
		return;
	}

	messageQueue.pop_front();

	if (!messageQueue.empty()) {
		const auto &outputMessage = messageQueue.front();
		lock.unlock();
		protocol->onSendMessage(outputMessage);
		lock.lock();
		internalSend(outputMessage);
	} else if (connectionState == CONNECTION_STATE_CLOSED) {
		closeSocket();
	}
}

void Connection::handleTimeout(ConnectionWeak_ptr connectionWeak, const std::error_code &error) {
	if (error == asio::error::operation_aborted) {
		return;
	}

	if (auto connection = connectionWeak.lock()) {
		if (!error) {
			g_logger().debug("Connection Timeout, IP: {}", convertIPToString(connection->getIP()));
		} else {
			g_logger().debug("Connection Timeout or error: {}, IP: {}", error.message(), convertIPToString(connection->getIP()));
		}
		connection->close(FORCE_CLOSE);
	}
}
