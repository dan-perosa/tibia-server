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
	{ text = "Train your skills on the dummy! Exercise weapons, durable, or lasting -- your pick." },
}

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

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- Exercise weapons: 3 real Tibia tiers, each a distinct item id (so no
-- shop price-by-id ambiguity like a custom subtype system would have).
-- Charges confirmed in items.xml: exercise 500, durable 1800, lasting
-- 14400. Prices are Tibia Global's real values from memory (lasting
-- confirmed by Pedro at 10kk) -- flag if exercise/durable look off.
npcConfig.shop = {
	{ itemName = "exercise sword", clientId = 28552, buy = 2000000 },
	{ itemName = "exercise axe", clientId = 28553, buy = 2000000 },
	{ itemName = "exercise club", clientId = 28554, buy = 2000000 },
	{ itemName = "exercise bow", clientId = 28555, buy = 2000000 },
	{ itemName = "exercise rod", clientId = 28556, buy = 2000000 },
	{ itemName = "exercise wand", clientId = 28557, buy = 2000000 },
	{ itemName = "exercise shield", clientId = 44065, buy = 2000000 },
	{ itemName = "exercise wraps", clientId = 50293, buy = 2000000 },

	{ itemName = "durable exercise sword", clientId = 35279, buy = 5000000 },
	{ itemName = "durable exercise axe", clientId = 35280, buy = 5000000 },
	{ itemName = "durable exercise club", clientId = 35281, buy = 5000000 },
	{ itemName = "durable exercise bow", clientId = 35282, buy = 5000000 },
	{ itemName = "durable exercise rod", clientId = 35283, buy = 5000000 },
	{ itemName = "durable exercise wand", clientId = 35284, buy = 5000000 },
	{ itemName = "durable exercise shield", clientId = 44066, buy = 5000000 },
	{ itemName = "durable exercise wraps", clientId = 50294, buy = 5000000 },

	{ itemName = "lasting exercise sword", clientId = 35285, buy = 10000000 },
	{ itemName = "lasting exercise axe", clientId = 35286, buy = 10000000 },
	{ itemName = "lasting exercise club", clientId = 35287, buy = 10000000 },
	{ itemName = "lasting exercise bow", clientId = 35288, buy = 10000000 },
	{ itemName = "lasting exercise rod", clientId = 35289, buy = 10000000 },
	{ itemName = "lasting exercise wand", clientId = 35290, buy = 10000000 },
	{ itemName = "lasting exercise shield", clientId = 44067, buy = 10000000 },
	{ itemName = "lasting exercise wraps", clientId = 50295, buy = 10000000 },
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
