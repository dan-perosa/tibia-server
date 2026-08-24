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

-- 2026-08-23: Pedro re-pointed each entrance teleport at its own landing tile
-- instead of both sharing one (971,967,7) -- both are the "north" gates of
-- the complex, entering this room specifically:
local ENTRANCE_LANDINGS = {
	{ x = 979, y = 965, z = 7 }, -- from the (976,965,7) entrance teleport
	{ x = 993, y = 964, z = 7 }, -- from the (989,964,7) entrance teleport
}
local ENTRANCE_WAIT_SPOT = { x = 967, y = 967, z = 7 } -- one tile before the entrance teleport, outside the room
local ROOM_CENTER = { x = 976, y = 968, z = 7 }
-- Trimmed 2026-08-23: used to reach maxY=11 (y up to 979), which swallowed the
-- new dragon arena room built just south of here (its chamber/chest start at
-- y=970/971) -- see dragon_arena_room_lock.lua. Capped at maxY=0 (y=968) so a
-- player fighting in the dragon arena no longer falsely blocks this room's
-- entrance. Covers this room's own chamber (977-984,962-968) and chest nook
-- (985-991,963-966) with margin; y=969 is left as an unclaimed buffer row.
local ROOM_RANGE = { minX = -15, maxX = 15, minY = -11, maxY = 0 }

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

for _, landing in ipairs(ENTRANCE_LANDINGS) do
	demonRoomEntrance:position(landing)
end
demonRoomEntrance:register()
