--[[
Same stats as the official Demon Goblin (data-otservbr-global/monster/quests/
pits_of_inferno/demon_goblin.lua) but disguised as a Demon: onSpawn overrides
the displayed name/look text before anyone ever sees it, so the nameplate and
"You see a ..." text both read "Demon" even though it's the much weaker
Demon Goblin underneath. Both share the same outfit (lookType 35), so there's
no visual tell either -- only the low health bar gives it away once you
actually engage.

Registered under a different internal name on purpose: Monster:setName()
only changes what's displayed, not the type used for map spawns, and
registering a second MonsterType under the literal name "Demon" would
collide with the real Demon and silently break one of the two (see the
Action ID collision lesson in custom_reward_chests.lua for why that matters).
]]

local mType = Game.createMonsterType("Hidden Demon Goblin")
local monster = {}

monster.description = "a demon goblin"
monster.experience = 25
monster.outfit = {
	lookType = 35,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 50
monster.maxHealth = 50
monster.race = "blood"
monster.corpse = 5995
monster.speed = 75
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
}

monster.strategiesTarget = {
	nearest = 100,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 40,
	targetDistance = 1,
	runHealth = 15,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = false,
	canWalkOnFire = false,
	canWalkOnPoison = false,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {
	interval = 5000,
	chance = 10,
}

monster.loot = {
	{ name = "small stone", chance = 15290, maxCount = 3 },
	{ name = "gold coin", chance = 50320, maxCount = 9 },
	{ id = 3115, chance = 1130 }, -- bone
	{ name = "mouldy cheese", chance = 1000 },
	{ name = "dagger", chance = 1800 },
	{ name = "short sword", chance = 8870 },
	{ name = "bone club", chance = 4900 },
	{ name = "leather helmet", chance = 1940 },
	{ name = "leather armor", chance = 2510 },
	{ name = "small axe", chance = 9700 },
	{ id = 3578, chance = 12750 }, -- fish
	{ name = "goblin ear", chance = 910 },
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -10 },
	{ name = "combat", interval = 2000, chance = 10, type = COMBAT_PHYSICALDAMAGE, minDamage = 0, maxDamage = -25, range = 7, shootEffect = CONST_ANI_SMALLSTONE, target = false },
}

monster.defenses = {
	defense = 10,
	armor = 10,
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 20 },
	{ type = COMBAT_EARTHDAMAGE, percent = -12 },
	{ type = COMBAT_FIREDAMAGE, percent = 0 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 0 },
	{ type = COMBAT_HOLYDAMAGE, percent = 1 },
	{ type = COMBAT_DEATHDAMAGE, percent = -10 },
}

monster.immunities = {
	{ type = "paralyze", condition = false },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = false },
	{ type = "bleed", condition = false },
}

mType.onSpawn = function(monster)
	monster:setName("Demon", "a demon")
end

mType:register(monster)
