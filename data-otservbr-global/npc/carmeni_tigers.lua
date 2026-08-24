-- Carmeni: aventureiro que roda o porto vendendo 1 item por dia, achado em
-- sua ultima expedicao. Raridade/preco sorteados pelo globalevent
-- carmeni_daily_roll.lua (ver GlobalStorage.Carmeni em lib/core/storages.lua).
-- Limite de 1 compra por personagem por dia (Storage.Carmeni.LastBuyDate).
-- Usa a janela de trade nativa (openShopWindowTable), reconstruida a cada
-- pedido de trade com o item do dia -- nao usa npcConfig.shop estatico.

local internalNpcName = "Carmeni Tigers"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 150
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 146,
	lookHead = 94,
	lookBody = 39,
	lookLegs = 87,
	lookFeet = 76,
	lookAddons = 2,
}

npcConfig.flags = {
	floorchange = false,
	profession = "trader",
}
npcConfig.speechBubble = SPEECHBUBBLE_NORMAL

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "Every expedition brings a surprise. Ask for a {trade} and take a look." },
}

-- Mesma tabela do globalevent carmeni_daily_roll.lua -- se mudar uma, mude a outra.
-- tier 1=Fraco 2=Mediano 3=Bom 4=Jackpot
local CARMENI_POOL = {
	{ tier = 1, price = 25000, items = { 7453, 8030, 25700, 16117, 50183 } },
	{ tier = 2, price = 60000, items = { 3296, 8023, 35522, 35521, 50176 } },
	{ tier = 3, price = 120000, items = { 30396, 30393, 30399, 30400, 50167, 31631 } },
	{ tier = 4, price = 200000, items = { 34253, 34150, 34152, 34151, 50162, 34158 } },
}
local CARMENI_TIER_WEIGHTS = { 40, 35, 20, 5 }
local CARMENI_TIER_PRICE = { [1] = 25000, [2] = 60000, [3] = 120000, [4] = 200000 }

local function todayAsNumber()
	return tonumber(os.date("%Y%m%d"))
end

-- Sorteia o item do dia se ainda nao tiver sido sorteado (ex: primeira vez
-- que o servidor liga, antes do primeiro save diario rodar o globalevent).
local function ensureDailyItemRolled()
	if Game.getStorageValue(GlobalStorage.Carmeni.DailyItem) ~= -1 then
		return
	end

	local roll = math.random(1, 100)
	local acc = 0
	local tierIndex = 1
	for i, weight in ipairs(CARMENI_TIER_WEIGHTS) do
		acc = acc + weight
		if roll <= acc then
			tierIndex = i
			break
		end
	end

	local tierData = CARMENI_POOL[tierIndex]
	local itemId = tierData.items[math.random(1, #tierData.items)]

	Game.setStorageValue(GlobalStorage.Carmeni.DailyTier, tierData.tier)
	Game.setStorageValue(GlobalStorage.Carmeni.DailyItem, itemId)
end

local function getTodaysOffer()
	ensureDailyItemRolled()
	local itemId = Game.getStorageValue(GlobalStorage.Carmeni.DailyItem)
	local tier = Game.getStorageValue(GlobalStorage.Carmeni.DailyTier)
	local price = CARMENI_TIER_PRICE[tier] or 0
	return itemId, price
end

local function alreadyBoughtToday(player)
	return player:getStorageValue(Storage.Carmeni.LastBuyDate) == todayAsNumber()
end

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

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "expedition") or MsgContains(message, "find") then
		if alreadyBoughtToday(player) then
			npcHandler:say("I've already sold you what I found today. Come back tomorrow, maybe I'll bring something even better.", npc, creature)
		else
			local itemId, price = getTodaysOffer()
			local itemType = ItemType(itemId)
			npcHandler:say("Today's expedition brought back something good: " .. itemType:getArticle() .. " " .. itemType:getName() .. ", for " .. price .. " gold coins. Ask for a {trade} to take it.", npc, creature)
		end
	end
	return true
end

-- Abre a janela de trade nativa, mas montada na hora com o item do dia --
-- npcConfig.shop fica vazio de propósito, pra nunca vender itens antigos.
local function onTradeRequest(npc, creature, message)
	local player = Player(creature)

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if alreadyBoughtToday(player) then
		npcHandler:say("I've already sold you what I found on that expedition. Come back tomorrow, maybe I'll bring something even better.", npc, creature)
		return false
	end

	local itemId, price = getTodaysOffer()
	local itemType = ItemType(itemId)

	npcHandler:say("Here's what I found. That's all I have today.", npc, creature)
	npc:openShopWindowTable(player, {
		{ itemName = itemType:getName(), clientId = itemId, buy = price },
	})
	return false
end

-- On buy npc shop message
npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	if alreadyBoughtToday(player) then
		player:sendTextMessage(MESSAGE_TRADE, "I've already sold you what I found on that expedition. Come back tomorrow.")
		return
	end

	local todayItemId = Game.getStorageValue(GlobalStorage.Carmeni.DailyItem)
	if itemId ~= todayItemId then
		return
	end

	npc:sellItem(player, itemId, 1, subType, 0, ignore, inBackpacks)
	player:setStorageValue(Storage.Carmeni.LastBuyDate, todayAsNumber())
end

npcHandler:setMessage(MESSAGE_GREET, "Hello, |PLAYERNAME|! I just got back from an expedition, and I think I brought back something worthwhile today... Ask for a {trade} and take a look at what I found.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Good luck out there, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Good luck out there.")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setCallback(CALLBACK_ON_TRADE_REQUEST, onTradeRequest)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
