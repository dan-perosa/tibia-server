local internalNpcName = "Captain Windrift"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 132, -- Nobleman (male) -- capitao distinto da Royal Tibia Line
	lookHead = 19,
	lookBody = 113,
	lookLegs = 112,
	lookFeet = 114,
	lookAddons = 2,
}

npcConfig.flags = {
	floorchange = false,
	profession = "sailor",
}
npcConfig.speechBubble = SPEECHBUBBLE_SAILOR

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

-- Travel
-- Stock destinations disabled: this is a custom map, none of the official
-- Tibia city coordinates below mean anything here. Kept as a single stub
-- line until real custom-city destinations exist to sail to.
local NOT_READY_TEXT = "I'll be sailing to new shores soon -- places that aren't on any map yet. Come find me again once they've been charted."

-- Kick
-- Disabled for the same reason as travel: the official kick destination
-- coordinates below don't exist on this map.

-- Basic
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "My name is Captain Windrift from the Royal Tibia Line." })
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I am the captain of this sailing-ship." })
keywordHandler:addKeyword({ "captain" }, StdModule.say, { npcHandler = npcHandler, text = "I am the captain of this sailing-ship." })
keywordHandler:addKeyword({ "ship" }, StdModule.say, { npcHandler = npcHandler, text = "The Royal Tibia Line connects all seaside towns of Tibia." })
keywordHandler:addKeyword({ "line" }, StdModule.say, { npcHandler = npcHandler, text = "The Royal Tibia Line connects all seaside towns of Tibia." })
keywordHandler:addKeyword({ "company" }, StdModule.say, { npcHandler = npcHandler, text = "The Royal Tibia Line connects all seaside towns of Tibia." })
keywordHandler:addKeyword({ "route" }, StdModule.say, { npcHandler = npcHandler, text = NOT_READY_TEXT })
keywordHandler:addKeyword({ "tibia" }, StdModule.say, { npcHandler = npcHandler, text = "The Royal Tibia Line connects all seaside towns of Tibia." })
keywordHandler:addKeyword({ "good" }, StdModule.say, { npcHandler = npcHandler, text = "We can transport everything you want." })
keywordHandler:addKeyword({ "passenger" }, StdModule.say, { npcHandler = npcHandler, text = "We would like to welcome you on board." })
keywordHandler:addKeyword({ "trip" }, StdModule.say, { npcHandler = npcHandler, text = NOT_READY_TEXT })
keywordHandler:addKeyword({ "passage" }, StdModule.say, { npcHandler = npcHandler, text = NOT_READY_TEXT })
keywordHandler:addKeyword({ "town" }, StdModule.say, { npcHandler = npcHandler, text = NOT_READY_TEXT })
keywordHandler:addKeyword({ "destination" }, StdModule.say, { npcHandler = npcHandler, text = NOT_READY_TEXT })
keywordHandler:addKeyword({ "sail" }, StdModule.say, { npcHandler = npcHandler, text = NOT_READY_TEXT })
keywordHandler:addKeyword({ "go" }, StdModule.say, { npcHandler = npcHandler, text = NOT_READY_TEXT })

npcHandler:setMessage(MESSAGE_GREET, "Welcome on board, |PLAYERNAME|. Where can I {sail} you today?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Good bye. Recommend us if you were satisfied with our service.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Good bye then.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
