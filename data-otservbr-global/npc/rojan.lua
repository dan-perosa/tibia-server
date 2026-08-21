local internalNpcName = "Rojan"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 136,
	lookHead = 41,
	lookBody = 72,
	lookLegs = 95,
	lookFeet = 96,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
	profession = "trader",
}
npcConfig.speechBubble = SPEECHBUBBLE_TRADE

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "Train your skills on the dummies! I've got the weapons for it." },
	{ text = "Tired of running out of charges mid-training? Ask me for a {bulk} order!" },
}

-- Bulk-charge training weapons: same item id as the shop entries above, but
-- with more charges baked in (subtype), priced proportionally (40 gold per
-- charge, matching 2000 gold / 50 charges). Handled OUTSIDE the normal shop
-- system on purpose: the engine looks up an item's buy price by item id
-- ONLY (src/creatures/npcs/npc.cpp, Npc::onPlayerBuyItem), not by subtype/
-- charges -- registering the same item id multiple times at different
-- prices in npcConfig.shop would make every purchase charge whichever price
-- was registered LAST for that id, regardless of which tier the player
-- actually clicked. A custom keyword flow with manual pricing avoids that.
local TrainingWeapons = {
	["training axe"] = 28541,
	["training bow"] = 28543,
	["training club"] = 28542,
	["training rod"] = 28544,
	["training shield"] = 44064,
	["training sword"] = 28540,
	["training wand"] = 28545,
	["training wraps"] = 50292,
}

local BulkTiers = { 100, 250, 500 }
local GOLD_PER_CHARGE = 40 -- 2000 gold / 50 charges, same rate as the base version

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
	npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

local pendingOrder = {}

local function tiersList()
	local parts = {}
	for _, tier in ipairs(BulkTiers) do
		table.insert(parts, tostring(tier))
	end
	return table.concat(parts, ", ")
end

local function weaponNamesList()
	local names = {}
	for name in pairs(TrainingWeapons) do
		table.insert(names, "{" .. name .. "}")
	end
	table.sort(names)
	return table.concat(names, ", ")
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	local lowerMsg = message:lower()
	local topic = npcHandler:getTopic(playerId)

	if MsgContains(message, "bulk") then
		npcHandler:say("Which weapon do you want in bulk? " .. weaponNamesList() .. ".", npc, creature)
		npcHandler:setTopic(playerId, 1)
	elseif topic == 1 and TrainingWeapons[lowerMsg] then
		pendingOrder[playerId] = { weapon = lowerMsg }
		npcHandler:say("How many charges? I offer " .. tiersList() .. ".", npc, creature)
		npcHandler:setTopic(playerId, 2)
	elseif topic == 2 and tonumber(message) then
		local tier = tonumber(message)
		local isValidTier = false
		for _, t in ipairs(BulkTiers) do
			if t == tier then
				isValidTier = true
				break
			end
		end
		if not isValidTier then
			npcHandler:say("I only offer " .. tiersList() .. " charges. Pick one of those.", npc, creature)
		else
			pendingOrder[playerId].tier = tier
			local price = tier * GOLD_PER_CHARGE
			pendingOrder[playerId].price = price
			npcHandler:say("A " .. pendingOrder[playerId].weapon .. " with " .. tier .. " charges costs " .. price .. " gold. Should I proceed?", npc, creature)
			npcHandler:setTopic(playerId, 3)
		end
	elseif topic == 3 then
		if MsgContains(message, "yes") then
			local order = pendingOrder[playerId]
			local itemId = TrainingWeapons[order.weapon]
			if (player:getMoney() + player:getBankBalance()) < order.price then
				npcHandler:say("You don't have enough gold for that.", npc, creature)
			else
				local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
				if not backpack or backpack:getEmptySlots(true) < 1 then
					npcHandler:say("You don't have enough room to carry it. Free up a slot and try again.", npc, creature)
				else
					player:removeMoneyBank(order.price)
					player:addItem(itemId, 1, true, order.tier)
					npcHandler:say("Here you go, freshly charged.", npc, creature)
				end
			end
		else
			npcHandler:say("Alright, let me know if you change your mind.", npc, creature)
		end
		pendingOrder[playerId] = nil
		npcHandler:setTopic(playerId, 0)
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Train your skills on the dummies! Need a {training} weapon, or a {bulk} order with more charges?")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ itemName = "training axe", clientId = 28541, buy = 2000 },
	{ itemName = "training bow", clientId = 28543, buy = 2000 },
	{ itemName = "training club", clientId = 28542, buy = 2000 },
	{ itemName = "training rod", clientId = 28544, buy = 2000 },
	{ itemName = "training shield", clientId = 44064, buy = 2000 },
	{ itemName = "training sword", clientId = 28540, buy = 2000 },
	{ itemName = "training wand", clientId = 28545, buy = 2000 },
	{ itemName = "training wraps", clientId = 50292, buy = 2000 },
}
-- On buy npc shop message
npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end
-- On sell npc shop message
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
	player:sendTextMessage(MESSAGE_TRADE, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
end
-- On check npc shop message (look item)
npcType.onCheckItem = function(npc, player, clientId, subType) end

npcType:register(npcConfig)
