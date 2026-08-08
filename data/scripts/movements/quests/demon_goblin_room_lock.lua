--[[
Fire/lava corridor with the disguised "Hidden Demon Goblin" (see
data-otservbr-global/monster/demons/hidden_demon_goblin.lua) -- only one
player may be inside at a time, so nobody can tag-team what's meant to be a
solo scare.

No manual flag/timeout: occupancy is checked live via Game.getSpectators
over the room's bounding box every time someone tries to enter, counting
only players with health > 0. This means the room frees up the instant a
player dies (their corpse/respawn no longer counts as "alive") or reaches
the exit -- no edge case can leave it stuck locked.
]]

local ENTRANCE_LANDING = { x = 971, y = 967, z = 7 } -- where the entrance teleport (968,967,7 -> here) drops you
local ENTRANCE_WAIT_SPOT = { x = 967, y = 967, z = 7 } -- one tile before the entrance teleport, outside the room
local ROOM_CENTER = { x = 976, y = 968, z = 7 }
local ROOM_RANGE = { minX = -15, maxX = 15, minY = -11, maxY = 11 } -- covers the whole lava corridor (963-991,957-979) with margin

local function playerAlreadyInside(enteringPlayer)
	local spectators = Game.getSpectators(Position(ROOM_CENTER), false, true, ROOM_RANGE.minX, ROOM_RANGE.maxX, ROOM_RANGE.minY, ROOM_RANGE.maxY)
	for _, spectator in ipairs(spectators) do
		if spectator:getId() ~= enteringPlayer:getId() and spectator:getHealth() > 0 then
			return true
		end
	end
	return false
end

local demonRoomEntrance = MoveEvent()
demonRoomEntrance:type("stepin")

function demonRoomEntrance.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	if playerAlreadyInside(player) then
		player:sendTextMessage(MESSAGE_FAILURE, "Someone else is already in there. Wait for them to finish.")
		player:teleportTo(ENTRANCE_WAIT_SPOT, true)
		return false
	end

	return true
end

demonRoomEntrance:position(ENTRANCE_LANDING)
demonRoomEntrance:register()
