local internalNpcName = "Elda"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 138,
	lookHead = 78,
	lookBody = 39,
	lookLegs = 39,
	lookFeet = 39,
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
	{ text = "Fine jewelry for the discerning adventurer!" },
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

npcConfig.shop = {
	-- Plasma set (Falcon Bastion/Feyrist) -- temporario, 30min de duracao
	-- depois de equipado, some sozinho. Trancado por vocacao. Sem preco
	-- oficial de NPC pra copiar (normalmente so quest), valor estimado
	-- pensando na natureza consumivel.
	{ itemName = "collar of blue plasma", clientId = 23526, buy = 8000 },
	{ itemName = "collar of green plasma", clientId = 23527, buy = 8000 },
	{ itemName = "collar of orange plasma", clientId = 50153, buy = 8000 },
	{ itemName = "collar of red plasma", clientId = 23528, buy = 8000 },
	{ itemName = "ring of blue plasma", clientId = 23530, buy = 5000 },
	{ itemName = "ring of green plasma", clientId = 23532, buy = 5000 },
	{ itemName = "ring of orange plasma", clientId = 50151, buy = 5000 },
	{ itemName = "ring of red plasma", clientId = 23534, buy = 5000 },

	{ itemName = "energy ring", clientId = 3051, buy = 1500 },
	{ itemName = "glacier amulet", clientId = 815, buy = 1000 },
	{ itemName = "life ring", clientId = 3052, buy = 1500 },
	{ itemName = "lightning pendant", clientId = 816, buy = 1000 },
	{ itemName = "magma amulet", clientId = 817, buy = 1000 },
	{ itemName = "might ring", clientId = 3048, buy = 3000 },
	{ itemName = "sacred tree amulet", clientId = 9302, buy = 35000 },
	{ itemName = "shockwave amulet", clientId = 9304, buy = 35000 },
	{ itemName = "stone skin amulet", clientId = 3081, buy = 18000 },
	{ itemName = "terra amulet", clientId = 814, buy = 1000 },
	{ itemName = "time ring", clientId = 3053, buy = 5000 },
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
