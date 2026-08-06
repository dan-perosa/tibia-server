--[[
Reusable one-time quest reward chest.

Usage in RME:
  1. Place item 2472 ("chest") wherever your quest ends.
  2. Give that chest tile an Action ID from the list below (or add a new one).
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
actions/dawnport/lever.lua, turning a chest into a lever). Stick to the
90000-91000 range below (verified empirically free of collisions on
2026-08-06 by grepping the whole datapack for :aid(/:actionid( calls) and
re-verify with the same grep before reusing this range elsewhere.
]]

local CustomQuestChests = {
	-- Starting class kit chests (pick one, opening one locks the other 3)
	[90001] = { -- Knight
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
		},
	},
	[90002] = { -- Paladin
		group = "starter_kit",
		items = {
			{ id = 14247, count = 1 }, -- ornate crossbow
			{ id = 8063, count = 1 }, -- paladin armor
			{ id = 3371, count = 1 }, -- knight legs
			{ id = 3392, count = 1 }, -- royal helmet
			{ id = 3436, count = 1 }, -- medusa shield
			{ id = 3079, count = 1 }, -- boots of haste
		},
	},
	[90003] = { -- Sorcerer
		group = "starter_kit",
		items = {
			{ id = 16115, count = 1 }, -- wand of everblazing
			{ id = 8074, count = 1 }, -- spellbook of mind control
			{ id = 8043, count = 1 }, -- focus cape
			{ id = 3210, count = 1 }, -- hat of the mad
			{ id = 645, count = 1 }, -- blue legs
			{ id = 3079, count = 1 }, -- boots of haste
		},
	},
	[90004] = { -- Druid
		group = "starter_kit",
		items = {
			{ id = 16118, count = 1 }, -- glacial rod
			{ id = 8074, count = 1 }, -- spellbook of mind control
			{ id = 8043, count = 1 }, -- focus cape
			{ id = 3210, count = 1 }, -- hat of the mad
			{ id = 645, count = 1 }, -- blue legs
			{ id = 3079, count = 1 }, -- boots of haste
		},
	},
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

	for _, entry in ipairs(config.items) do
		if not player:addItem(entry.id, entry.count) then
			player:sendTextMessage(MESSAGE_FAILURE, "You don't have enough room to carry the reward.")
			return true
		end
	end

	player:setStorageValue(storageKey, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found the quest reward!")
	item:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
	return true
end

questChest:id(2472)
questChest:register()
