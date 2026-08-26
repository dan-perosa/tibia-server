--[[
Reusable one-time quest reward chest.

Usage in RME:
  1. Place item 2472 ("chest") wherever your quest ends -- or 7160/7161
     ("frozen chest") for a themed variant; both are registered below.
  2. Give that chest tile an Action ID from the list below (or add a new one,
     and add its item id to the questChest:id(...) call at the bottom if it's
     not 2472/7160/7161).
  3. Add an entry to CustomQuestChests matching that Action ID with the
     reward items. Each player can only claim it once.

Optional "group": chests sharing the same group name share a single
claim -- opening any one of them locks out the rest of the group for that
player (used for the "pick one starting class kit" chests).

IMPORTANT -- picking new Action IDs: Action IDs are a datapack-wide shared
namespace. The engine checks for an Action ID match BEFORE it checks for an
item ID match (see Actions::getAction in src/lua/creature/actions.cpp), so if
any other official quest script happens to already use the same Action ID,
that other script silently wins instead of this one -- this is exactly what
happened the first time (30001 collided with data-otservbr-global/scripts/
actions/dawnport/lever.lua, turning a chest into a lever). Before reusing any
range, re-run this against both data/ and data-otservbr-global/:
  grep -rhoE ':aid\([0-9, ]+\)|:actionid\([0-9, ]+\)' | grep -oE '[0-9]+' | sort -n | uniq

IMPORTANT -- Action IDs baked into the .otbm map file (via RME or otbm.py)
are a 16-bit field (0-65535), NOT arbitrary Lua numbers. A value above 65535
silently wraps around (v mod 65536) when written -- this bit us on
2026-08-06: 90001-90006 written into the map turned into 24465-24470, two of
which collided with the existing starter-kit chests (24465/24466), pointing
those tiles at the WRONG reward and the WRONG storage key. The old "use
90000-91000" advice below only ever applied to Action IDs referenced purely
from Lua (:aid() calls with no matching map tile) -- it does NOT apply to any
Action ID that will actually be placed on a map item. Stay under 65536 for
those, and also grep the *map itself* for the range before reusing it (no
otbm.py helper for this yet -- read the map, scan tile.items for
action_id in range).
]]

local CustomQuestChests = {
	-- Starting class kit chests (pick one, opening one locks the other 3)
	[24465] = { -- Knight
		group = "starter_kit",
		items = {
			{ id = 7418, count = 1 }, -- nightmare blade
			{ id = 7422, count = 1 }, -- jade hammer
			{ id = 7420, count = 1 }, -- reaper's axe
			{ id = 3392, count = 1 }, -- royal helmet
			{ id = 3370, count = 1 }, -- knight armor
			{ id = 3371, count = 1 }, -- knight legs
			{ id = 3436, count = 1 }, -- medusa shield
			{ id = 3079, count = 1 }, -- boots of haste
			{ id = 28552, count = 1 }, -- exercise sword
			{ id = 28553, count = 1 }, -- exercise axe
			{ id = 28554, count = 1 }, -- exercise club
		},
	},
	[24466] = { -- Paladin
		group = "starter_kit",
		items = {
			{ id = 14247, count = 1 }, -- ornate crossbow
			{ id = 8063, count = 1 }, -- paladin armor
			{ id = 3371, count = 1 }, -- knight legs
			{ id = 3392, count = 1 }, -- royal helmet
			{ id = 3436, count = 1 }, -- medusa shield
			{ id = 3079, count = 1 }, -- boots of haste
			{ id = 28555, count = 1 }, -- exercise bow
		},
	},
	[24467] = { -- Sorcerer
		group = "starter_kit",
		items = {
			{ id = 16115, count = 1 }, -- wand of everblazing
			{ id = 8074, count = 1 }, -- spellbook of mind control
			{ id = 8043, count = 1 }, -- focus cape
			{ id = 3210, count = 1 }, -- hat of the mad
			{ id = 645, count = 1 }, -- blue legs
			{ id = 3079, count = 1 }, -- boots of haste
			{ id = 28557, count = 1 }, -- exercise wand
		},
	},
	[24468] = { -- Druid
		group = "starter_kit",
		items = {
			{ id = 16118, count = 1 }, -- glacial rod
			{ id = 8074, count = 1 }, -- spellbook of mind control
			{ id = 8043, count = 1 }, -- focus cape
			{ id = 3210, count = 1 }, -- hat of the mad
			{ id = 645, count = 1 }, -- blue legs
			{ id = 3079, count = 1 }, -- boots of haste
			{ id = 28556, count = 1 }, -- exercise rod
		},
	},

	-- Fire vault room (dragon/spider/scarab tomb, copied from the Banshee
	-- quest layout). 4 independent chests, each with its own one-time
	-- reward -- no group/lockout, a player can open all 4. 200k gold split
	-- evenly across the 4 (50k each, as crystal coins) alongside one piece
	-- of gear per chest.
	[24601] = { items = { { id = 6529, count = 1 }, { id = 3043, count = 5 } } }, -- pair of soft boots + 50k
	[24602] = { items = { { id = 11687, count = 1 }, { id = 3043, count = 5 } } }, -- royal scale robe + 50k
	[24603] = { items = { { id = 11651, count = 1 }, { id = 3043, count = 5 } } }, -- elite draken mail + 50k
	[24604] = { items = { { id = 8060, count = 1 }, { id = 3043, count = 5 } } }, -- master archer's armor + 50k

	-- Hidden Demon Goblin lava corridor reward chest (moved to 987,965,7)
	[24701] = { items = { { id = 3389, count = 1 } } }, -- demon legs

	-- New dragon arena, similar layout to the Demon Goblin one (993,974,7)
	[24702] = { items = { { id = 3363, count = 1 } } }, -- dragon scale legs

	-- Ice arena (Furious Yeti), frozen chest at (968,959,7)
	[24703] = { items = { { id = 19391, count = 1 } } }, -- furious frock

	-- World Wolves secret hunt -- Hellflayer guardian room
	[24801] = {
		items = {
			{ id = 3081, count = 10, backpack = true }, -- backpack of 10x stone skin amulet
			{ id = 3048, count = 10, backpack = true }, -- backpack of 10x might ring
			{ id = 3043, count = 20 }, -- 200k gold (crystal coin = 10k each)
		},
	},

	-- Level 100 gate quest -- final boss room, 5 independent chests
	-- (1247,1131,9)/(1255,1136,9)/(1247,1139,9)/(1255,1139,9)/(1251,1136,9)
	[24901] = { items = { { id = 3229, count = 1 }, { id = 3043, count = 25 } } }, -- helmet of the ancients + 250k
	[24902] = { items = { { id = 16109, count = 1 }, { id = 3043, count = 25 } } }, -- prismatic helmet + 250k
	[24903] = { items = { { id = 16104, count = 1 }, { id = 3043, count = 25 } } }, -- gill gugel + 250k
	[24904] = { items = { { id = 50190, count = 1 }, { id = 3043, count = 25 } } }, -- dark vision bandana + 250k
	[24905] = { items = { { id = 29427, count = 1 }, { id = 3043, count = 25 } } }, -- dark whispers + 250k
}

local GroupStorage = {
	starter_kit = 62200,
}

local BASE_STORAGE = 62000 -- storage range for chests without a group

local function storageKeyFor(actionId, config)
	if config.group then
		return GroupStorage[config.group]
	end
	return BASE_STORAGE + actionId
end

-- Checks capacity/room for the WHOLE reward before adding anything, so a
-- chest can never hand out only part of its reward. Without this, if
-- addItem failed partway through the loop, the chest would still be
-- unlocked to try again, and re-opening it would re-add (duplicate) every
-- item that had already succeeded on the earlier partial attempt.
local REWARD_BACKPACK_ID = 2854

local function hasRoomForReward(player, items)
	local totalWeight = 0
	for _, entry in ipairs(items) do
		totalWeight = totalWeight + (ItemType(entry.id):getWeight() * entry.count)
		if entry.backpack then
			totalWeight = totalWeight + ItemType(REWARD_BACKPACK_ID):getWeight()
		end
	end
	-- getFreeCapacity() and ItemType():getWeight() are both in the same raw
	-- (hundredths-of-oz) scale -- confirmed in src/creatures/players/player.cpp
	-- (Player::getFreeCapacity) and src/lua/functions/items/item_type_functions.cpp
	-- (luaItemTypeGetWeight), and matches how gnomally.lua/imbuement_assistant.lua/
	-- hireling.lua compare them elsewhere in this datapack. A stray "/ 100" here
	-- previously made this check ~100x stricter than it should be, so a reward
	-- chest could refuse "not enough room" even with plenty of free capacity.
	if player:getFreeCapacity() < totalWeight then
		return false
	end

	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not backpack then
		return false
	end
	-- Conservative: assume every reward entry needs its own new slot, even
	-- though a stackable item might actually merge into one already carried.
	if backpack:getEmptySlots(true) < #items then
		return false
	end

	return true
end

local questChest = Action()

function questChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local config = CustomQuestChests[item.actionid]
	if not config then
		player:sendTextMessage(MESSAGE_FAILURE, "This chest has no reward configured.")
		return true
	end

	local storageKey = storageKeyFor(item.actionid, config)
	if player:getStorageValue(storageKey) >= 1 then
		player:sendTextMessage(MESSAGE_FAILURE, "The chest is empty.")
		return true
	end

	if not hasRoomForReward(player, config.items) then
		player:sendTextMessage(MESSAGE_FAILURE, "You don't have enough room to carry the reward. Free up some space and try again.")
		return true
	end

	for _, entry in ipairs(config.items) do
		if entry.backpack then
			local bp = Game.createItem(REWARD_BACKPACK_ID)
			for _ = 1, entry.count do
				bp:addItem(entry.id, 1)
			end
			if not player:addItemEx(bp) then
				-- Should not happen given the check above, but bail out without
				-- marking the chest as claimed if it somehow still fails.
				player:sendTextMessage(MESSAGE_FAILURE, "You don't have enough room to carry the reward. Free up some space and try again.")
				return true
			end
		elseif not player:addItem(entry.id, entry.count) then
			-- Should not happen given the check above, but bail out without
			-- marking the chest as claimed if it somehow still fails.
			player:sendTextMessage(MESSAGE_FAILURE, "You don't have enough room to carry the reward. Free up some space and try again.")
			return true
		end
	end

	player:setStorageValue(storageKey, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found the quest reward!")
	item:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
	return true
end

questChest:id(2472, 7160, 7161) -- 7160/7161: "frozen chest", added 2026-08-23 for the ice arena
questChest:register()
