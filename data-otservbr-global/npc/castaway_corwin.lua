-- Castaway Corwin: naufrago preso na Mirror's Shadow (ilha secreta, 5% de
-- chance na viagem do Boatman). So um monologo, sem loja, sem quest ainda
-- -- gancho de lore, fala definida pelo Pedro.
--
-- Visual de "machucado" (pedido do Pedro, pacote completo):
-- 1. Barra de vida parcial (25/100)
-- 2. Outfit "Beggar" (lookType 157)
-- 3. Efeito visual de dor ocasional (onThink)
-- 4. Falas de dor ocasionais (voices)
-- 5. Bandagem ensanguentada + mancha de sangue no chao ao lado dele

local internalNpcName = "Castaway Corwin"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 25
npcConfig.maxHealth = 100
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 157, -- Beggar
	lookHead = 38,
	lookBody = 39,
	lookLegs = 76,
	lookFeet = 76,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
	profession = "normal",
}
npcConfig.speechBubble = SPEECHBUBBLE_NORMAL

npcConfig.voices = {
	interval = 15000,
	chance = 15,
	{ text = "Ngh... my leg..." },
	{ text = "*coughs* ...still here..." },
	{ text = "Please... someone..." },
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

local PAIN_EFFECT_CHANCE = 1 -- em 30 (checado a cada onThink)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)

	if math.random(1, 30) <= PAIN_EFFECT_CHANCE then
		npc:getPosition():sendMagicEffect(CONST_ME_DRAWBLOOD)
	end
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

npcHandler:setMessage(
	MESSAGE_GREET,
	"Wait... you... you're real?! By God, how many years has it been... twenty? Twenty-five? I came on that cursed boat like everyone else, thinking I'd see the Medusa. The fog swallowed everything, and by the time I noticed, I was already here. I tried everything, I swear. I tried swimming, the tide dragged me back with a broken leg. I tried building a raft, it rotted before I could finish it. There's a way out, I know it. A teleport, guarded by... by that thing. That creature with the same cursed eyes as the Medusa herself. I got close once. Once. I still have the scar. I could never get past it alone. If you get out of here... please, don't forget me. Don't let me become just another stone on this island."
)
npcHandler:setMessage(MESSAGE_FAREWELL, "Please... don't forget me.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Please... don't forget me.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
