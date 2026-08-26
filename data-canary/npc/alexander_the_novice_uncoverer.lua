local internalNpcName = "Alexander the Novice Uncoverer"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 128,
	lookHead = 78,
	lookBody = 39,
	lookLegs = 76,
	lookFeet = 0,
	lookAddons = 3,
}

npcConfig.flags = {
	floorchange = false,
	profession = "teacher",
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

local PROMOTION_COST = 20000
local PROMOTION_LEVEL = 20

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "promotion") or MsgContains(message, "promote") then
		local vocation = player:getVocation()
		local promotedVocation = vocation and vocation:getPromotion()

		if not promotedVocation then
			npcHandler:say("Your vocation has no promotion available.", npc, creature)
			return true
		end

		if vocation:getId() == promotedVocation:getId() then
			npcHandler:say("You are already promoted.", npc, creature)
			return true
		end

		if player:getLevel() < PROMOTION_LEVEL then
			npcHandler:say("Come back when you have reached level " .. PROMOTION_LEVEL .. ".", npc, creature)
			return true
		end

		npcHandler:say("Are you ready to undergo the ritual of promotion? It will cost you " .. PROMOTION_COST .. " gold.", npc, creature)
		npcHandler:setTopic(playerId, 1)
	elseif MsgContains(message, "yes") and npcHandler:getTopic(playerId) == 1 then
		local vocation = player:getVocation()
		local promotedVocation = vocation and vocation:getPromotion()

		if not promotedVocation or vocation:getId() == promotedVocation:getId() then
			npcHandler:setTopic(playerId, 0)
			return true
		end

		if not player:removeMoney(PROMOTION_COST) then
			npcHandler:say("You don't have enough gold.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end

		player:setVocation(promotedVocation)
		npcHandler:say("Congratulations! You are now " .. promotedVocation:getDescription() .. ".", npc, creature)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "no") and npcHandler:getTopic(playerId) == 1 then
		npcHandler:say("Very well, come back when you are ready.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	end

	return true
end

keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I uncover the true potential hidden within novice adventurers. Ask me about {promotion}." })
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "I am Alexander, the Novice Uncoverer." })

npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. Ask me about {promotion} if you feel ready to advance.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, and good luck on your journey.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Come back when you are ready.")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
