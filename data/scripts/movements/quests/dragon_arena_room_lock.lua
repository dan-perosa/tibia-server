--[[
New dragon arena, built next to the Hidden Demon Goblin lava corridor
(same "one player at a time" format, see demon_goblin_room_lock.lua for the
original). Chamber is roughly (983-990,971-977,7), chest nook (993-999,970-975,7)
with the reward chest at (993,974,7) -> Dragon Scale Legs (Action ID 24702,
custom_reward_chests.lua).

Same no-flag/no-timeout approach: occupancy checked live via
Game.getSpectators over the room's bounding box, only counting players with
health > 0 -- frees up instantly on death or leaving, no edge case can leave
it stuck locked.

Entrance teleport destination was fixed 2026-08-23 alongside this script:
both entrances (989,964,7 and 995,973,7) used to land at (984,967,7), which
turned out to be sitting on lava with a wall item on top of it (most likely
left over from before the Demon Goblin room was moved to its current spot).
First redirected both to a shared (983,967,7). Pedro then split them into
their own landing tiles (each entrance's own "south" gate leading here):
]]

local ENTRANCE_LANDINGS = {
	{ x = 985, y = 974, z = 7 }, -- from the (982,974,7) entrance teleport
	{ x = 1000, y = 973, z = 7 }, -- from the (995,973,7) entrance teleport
}
local ENTRANCE_WAIT_SPOT = { x = 980, y = 967, z = 7 } -- a few tiles before the landing, outside the room
local ROOM_CENTER = { x = 989, y = 975, z = 7 }
-- Covers the chamber (983-990,971-977) and chest nook (993-999,970-975) with
-- margin, starting at y=970 so it doesn't reach up into the Demon Goblin
-- room's territory (which is now capped at y=968, see that script).
local ROOM_RANGE = { minX = -11, maxX = 11, minY = -5, maxY = 5 }

local function playerAlreadyInside(enteringPlayer)
	local spectators = Game.getSpectators(Position(ROOM_CENTER), false, true, ROOM_RANGE.minX, ROOM_RANGE.maxX, ROOM_RANGE.minY, ROOM_RANGE.maxY)
	for _, spectator in ipairs(spectators) do
		if spectator:getId() ~= enteringPlayer:getId() and spectator:getHealth() > 0 then
			return true
		end
	end
	return false
end

local dragonArenaEntrance = MoveEvent()
dragonArenaEntrance:type("stepin")

function dragonArenaEntrance.onStepIn(creature, item, position, fromPosition)
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
	dragonArenaEntrance:position(landing)
end
dragonArenaEntrance:register()
