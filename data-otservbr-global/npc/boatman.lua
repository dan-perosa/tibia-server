local internalNpcName = "Boatman"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 129,
	lookHead = 19,
	lookBody = 69,
	lookLegs = 125,
	lookFeet = 50,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
	profession = "normal",
}
npcConfig.speechBubble = SPEECHBUBBLE_NORMAL

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

-- ORC_KEY_ITEM_ID: "bone key", ja colocada no mapa por cima da placa da Quest dos Orcs (959,1125,7)
local ORC_KEY_ITEM_ID = 2973

-- Storage 900001: liberado permanentemente apos a chave ser consumida na primeira viagem
local STORAGE_BOATMAN_UNLOCKED = 900001

local MIRROR_ISLAND_DESTINATION = Position(811, 219, 7)

-- TODO: a ilha secreta (boss Gorgo) ainda nao foi construida no mapa.
-- Atualizar assim que existir (placeholder aponta pro templo da cidade por
-- enquanto, pra nao teleportar o jogador pra um lugar quebrado).
local SECRET_ISLAND_DESTINATION = Position(1000, 1000, 7)
local SECRET_ISLAND_CHANCE = 5 -- % de chance por viagem

local function sailToDestination(player)
	local destination = MIRROR_ISLAND_DESTINATION
	if math.random(1, 100) <= SECRET_ISLAND_CHANCE then
		destination = SECRET_ISLAND_DESTINATION
	end
	player:teleportTo(destination)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "sail") or MsgContains(message, "yes") or MsgContains(message, "passage") then
		if player:getStorageValue(STORAGE_BOATMAN_UNLOCKED) == 1 then
			npcHandler:say("Back again, eh? The waters have been strange lately... but climb in, let's see where the tide takes us today.", npc, creature)
			sailToDestination(player)
		elseif player:getItemCount(ORC_KEY_ITEM_ID) > 0 then
			npcHandler:say("Ah, that key... I recognize the orcs' mark. Very well, come aboard. I can't promise the sea will take us to the same place every time, but Mirror Island is our usual destination.", npc, creature)
			player:removeItem(ORC_KEY_ITEM_ID, 1)
			player:setStorageValue(STORAGE_BOATMAN_UNLOCKED, 1)
			sailToDestination(player)
		else
			npcHandler:say("Without the right key, I won't risk that crossing. I've heard the orcs guard something like that... might be worth looking into.", npc, creature)
		end
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Ahoy, traveler! Looking for passage to {Mirror Island}?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Safe travels, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Safe travels, |PLAYERNAME|.")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
