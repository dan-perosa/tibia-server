--[[
Custom boss for the ice arena (3rd challenge, ice theme). Same idea as
Hidden Demon Goblin (demons/hidden_demon_goblin.lua): a custom monster
registered under its own internal name so it doesn't collide with the
official "Yeti", but here the twist is the opposite -- looks like the
classic weak Yeti, hits like a boss. Stats/defense mirror Stalking Stalk
(plants/stalking_stalk.lua, the dragon arena's boss) at Pedro's request,
with the two ranged/AoE attacks and the elemental table re-themed from
plant/fire/earth to ice, and the melee's plant visual effect dropped.
]]

local mType = Game.createMonsterType("Furious Yeti")
local monster = {}

monster.description = "a furious yeti"
monster.experience = 11569
monster.outfit = {
	lookType = 110,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.raceId = 2272
monster.Bestiary = {
	class = "Mammal",
	race = BESTY_RACE_MAMMAL,
	toKill = 5000,
	FirstUnlock = 200,
	SecondUnlock = 2000,
	CharmsPoints = 100,
	Stars = 5,
	Occurrence = 0,
	Locations = "Somewhere cold.",
}

monster.health = 17100
monster.maxHealth = 17100
monster.race = "blood"
monster.corpse = 6038
monster.speed = 190
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
	staticAttackChance = 90,
	targetDistance = 2,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = true,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "RRRAAAGH!", yell = true },
}

monster.loot = {
	{ name = "gold coin", chance = 100000, maxCount = 100 },
	{ name = "platinum coin", chance = 60000, maxCount = 5 },
	{ name = "small diamond", chance = 7140, minCount = 1, maxCount = 3 },
	{ name = "frosty heart", chance = 15000 },
	{ id = 7441, chance = 12000 }, -- ice cube
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -400 },
	{ name = "combat", interval = 4000, chance = 40, type = COMBAT_ICEDAMAGE, minDamage = -800, maxDamage = -1050, range = 7, shootEffect = CONST_ANI_SMALLICE, effect = CONST_ME_ICEATTACK, target = true },
	{ name = "combat", interval = 2900, chance = 25, type = COMBAT_ICEDAMAGE, minDamage = -850, maxDamage = -1130, radius = 4, effect = CONST_ME_ICETORNADO, target = false },
}

monster.defenses = {
	defense = 110,
	armor = 76,
	mitigation = 2.11,
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = -25 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 0 },
	{ type = COMBAT_FIREDAMAGE, percent = -25 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 25 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 10 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
