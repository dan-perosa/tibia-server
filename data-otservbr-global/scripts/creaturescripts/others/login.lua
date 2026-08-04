local playerLogin = CreatureEvent("PlayerLogin")

function playerLogin.onLogin(player)
	-- Note: the original "premium expired -> teleport to Thais" logic was
	-- removed here. It only made sense for the official OTServBR-Global
	-- towns (Thais, Carlin, etc.) and crashed on custom worlds/towns.
	-- This server doesn't use the premium/free account distinction.

	local town = player:getTown()

	-- Open channels
	if town and table.contains({ TOWNS_LIST.DAWNPORT, TOWNS_LIST.DAWNPORT_TUTORIAL }, town:getId()) then
		player:openChannel(3) -- World chat
	else
		player:openChannel(3) -- World chat
		player:openChannel(5) -- Advertsing main
		if player:getGuild() then
			player:openChannel(0x00) -- guild
		end
	end
	return true
end

playerLogin:register()
