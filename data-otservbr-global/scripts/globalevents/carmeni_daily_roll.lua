-- Carmeni (NPC aventureiro do porto): sorteia 1 item por dia entre 4 faixas
-- de raridade. O item sorteado fica em GlobalStorage.Carmeni.DailyItem, a
-- faixa em GlobalStorage.Carmeni.DailyTier -- o npc/carmeni.lua le esses
-- valores pra saber o que esta vendendo hoje.

-- tier 1=Fraco 2=Mediano 3=Bom 4=Jackpot
local CarmeniPool = {
	{ tier = 1, price = 25000, items = { 7453, 8030, 25700, 16117, 50183 } }, -- Executioner, Elethriel's Elemental Bow, Dream Blossom Staff, Muck Rod, Sai
	{ tier = 2, price = 60000, items = { 3296, 8023, 35522, 35521, 50176 } }, -- Warlord Sword, Royal Crossbow, Jungle Wand, Jungle Rod, Depth Claws
	{ tier = 3, price = 120000, items = { 30396, 30393, 30399, 30400, 50167, 31631 } }, -- Cobra Axe, Cobra Crossbow, Cobra Wand, Cobra Rod, Cobra Bo, The Cobra Amulet
	{ tier = 4, price = 200000, items = { 34253, 34150, 34152, 34151, 50162, 34158 } }, -- Lion Axe, Lion Longbow, Lion Wand, Lion Rod, Lion Claws, Lion Amulet
}

-- pesos em % (somam 100): Fraco 40, Mediano 35, Bom 20, Jackpot 5
local TIER_WEIGHTS = { 40, 35, 20, 5 }

local function rollCarmeniItem()
	local roll = math.random(1, 100)
	local acc = 0
	local tierIndex = 1
	for i, weight in ipairs(TIER_WEIGHTS) do
		acc = acc + weight
		if roll <= acc then
			tierIndex = i
			break
		end
	end

	local tierData = CarmeniPool[tierIndex]
	local itemId = tierData.items[math.random(1, #tierData.items)]

	Game.setStorageValue(GlobalStorage.Carmeni.DailyTier, tierData.tier)
	Game.setStorageValue(GlobalStorage.Carmeni.DailyItem, itemId)

	return tierData.tier, itemId
end

local carmeniDailyRoll = GlobalEvent("CarmeniDailyRoll")

function carmeniDailyRoll.onTime(interval)
	local tier, itemId = rollCarmeniItem()
	local itemType = ItemType(itemId)
	logger.info("[Carmeni] Item do dia sorteado: " .. itemType:getName() .. " (tier " .. tier .. ")")
	return true
end

carmeniDailyRoll:time(configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME))
carmeniDailyRoll:register()
