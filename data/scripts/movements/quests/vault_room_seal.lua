--[[
Fire vault room (dragon/spider/scarab tomb) -- one-way stairs down from the
central fire-trap platform (z=6) back to the room floor (z=7). Every
player must be able to go up and come back down independently; once a
given player has come back down, that SAME player can no longer use the up
stairs again -- only the teleport back to town is left.

This is deliberately per-player (a storage value), not a wall/gate created
on the shared tile. An earlier version used the same trick as the official
Queen of the Banshees quest (dynamically creating a blocking item on the
tile after the player crosses it -- see the CHANGELOG entry this replaces),
but that seals the staircase for EVERYONE as soon as the first player comes
down, which would strand anyone still up on the platform. A per-player
storage check has no such shared-state problem and needs no item at all.

How it works:
  1. Stepping on any of the 3 down-stairs landing tiles (where the player
     arrives after using the 469 stairs on z=6) sets a storage flag.
  2. Stepping on any of the 3 up-stairs tiles (the 1956 floorchange=north
     items) checks that flag first. If it's set, the player is teleported
     right back to where they came from before the floor change can happen
     (Game::internalMoveCreature places the creature on this tile BEFORE
     resolving TILESTATE_FLOORCHANGE, so teleporting away here reliably
     cancels the ascent -- see src/game/game.cpp around
     internalMoveCreature(creature, toTile, flags), the
     "could happen if a script move the creature" branch).
]]

local DESCENDED_STORAGE = 62300

local markDescended = MoveEvent()
markDescended:type("stepin")

function markDescended.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	player:setStorageValue(DESCENDED_STORAGE, 1)
	return true
end

-- The 3 tiles the player lands on right after using the down stairs
-- (469 at 1223-1225,1115,z=6) -- see CHANGELOG 2026-08-06 for how these
-- were computed from Tile::queryDestination in tile.cpp. All 3 land on
-- y=1115 (no offset): the tile the engine checks for a compensating
-- FLOORCHANGE_NORTH flag is (x,1115,7), which only has the *decorative*
-- ramp item 1957 (no floorchange attribute at all) -- not 1956 (the real
-- floorchange=north stairs, one row further at y=1114). An earlier version
-- of this file mixed the two up and used y=1116 for two of the three,
-- which only triggered if the player happened to walk one extra tile
-- south after landing.
markDescended:position({ x = 1223, y = 1115, z = 7 })
markDescended:position({ x = 1224, y = 1115, z = 7 })
markDescended:position({ x = 1225, y = 1115, z = 7 })
markDescended:register()

local blockReascend = MoveEvent()
blockReascend:type("stepin")

function blockReascend.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	if player:getStorageValue(DESCENDED_STORAGE) >= 1 then
		player:sendTextMessage(MESSAGE_FAILURE, "The stairs have collapsed behind you. There is no way back up.")
		player:teleportTo(fromPosition, true)
		return false
	end

	return true
end

blockReascend:position({ x = 1222, y = 1114, z = 7 })
blockReascend:position({ x = 1223, y = 1114, z = 7 })
blockReascend:position({ x = 1224, y = 1114, z = 7 })
blockReascend:register()
