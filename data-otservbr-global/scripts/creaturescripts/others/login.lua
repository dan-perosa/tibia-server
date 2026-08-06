local playerLogin = CreatureEvent("PlayerLogin")

-- Auto-learn every instant spell matching the player's vocation, so nobody
-- needs to pay an NPC to learn spells. Level/mana/vocation are still
-- enforced normally when actually casting -- this only marks them as
-- "known" (see Player::hasLearnedInstantSpell). Generated on 2026-08-06 by
-- extracting spell:name()/spell:vocation() from every file in
-- data/scripts/spells/ -- if new spells get added later, regenerate with:
--   grep -oE 'spell:name\("[^"]+"\)' and 'spell:vocation\([^)]+\)' across that folder.
local AllVocationSpells = {
	{ name = "Light Healing", vocations = { "druid", "elder druid", "exalted monk", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Intense Recovery", vocations = { "elite knight", "knight", "paladin", "royal paladin" } },
	{ name = "Wound Cleansing", vocations = { "elite knight", "knight" } },
	{ name = "Intense Healing", vocations = { "druid", "elder druid", "exalted monk", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Bruise Bane", vocations = { "elite knight", "knight" } },
	{ name = "Fair Wound Cleansing", vocations = { "elite knight", "knight" } },
	{ name = "Mass Spirit Mend", vocations = { "exalted monk", "monk" } },
	{ name = "Cure Electrification", vocations = { "druid", "elder druid" } },
	{ name = "Cure Bleeding", vocations = { "druid", "elder druid", "elite knight", "knight" } },
	{ name = "Ultimate Healing", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Restoration", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Nature's Embrace", vocations = { "druid", "elder druid" } },
	{ name = "Cure Curse", vocations = { "paladin", "royal paladin" } },
	{ name = "Cure Poison", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Heal Friend", vocations = { "druid", "elder druid" } },
	{ name = "Salvation", vocations = { "paladin", "royal paladin" } },
	{ name = "Restore Balance", vocations = { "exalted monk", "monk" } },
	{ name = "Cure Burning", vocations = { "druid", "elder druid" } },
	{ name = "Intense Wound Cleansing", vocations = { "elite knight", "knight" } },
	{ name = "Divine Healing", vocations = { "paladin", "royal paladin" } },
	{ name = "Mass Healing", vocations = { "druid", "elder druid" } },
	{ name = "Magic Patch", vocations = { "druid", "elder druid", "exalted monk", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Spirit Mend", vocations = { "exalted monk", "monk" } },
	{ name = "Recovery", vocations = { "elite knight", "knight", "paladin", "royal paladin" } },
	{ name = "Protect Party", vocations = { "paladin", "royal paladin" } },
	{ name = "Train Party", vocations = { "elite knight", "knight" } },
	{ name = "Enchant Party", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Enlighten Party", vocations = { "exalted monk", "monk" } },
	{ name = "Heal Party", vocations = { "druid", "elder druid" } },
	{ name = "Forceful Uppercut", vocations = { "exalted monk", "monk" } },
	{ name = "Chill Out", vocations = { "druid", "elder druid" } },
	{ name = "Lightning", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Annihilation", vocations = { "elite knight", "knight" } },
	{ name = "Holy Flash", vocations = { "paladin", "royal paladin" } },
	{ name = "Groundshaker", vocations = { "elite knight", "knight" } },
	{ name = "Great Death Beam", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Buzz", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Mystic Repulse", vocations = { "exalted monk", "monk" } },
	{ name = "Flurry of Blows", vocations = { "exalted monk", "monk" } },
	{ name = "Strong Terra Strike", vocations = { "druid", "elder druid" } },
	{ name = "Terra Strike", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Greater Tiger Clash", vocations = { "exalted monk", "monk" } },
	{ name = "Executioner's Throw", vocations = { "elite knight", "knight" } },
	{ name = "Whirlwind Throw", vocations = { "elite knight", "knight" } },
	{ name = "Fire Wave", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Mud Attack", vocations = { "druid", "elder druid" } },
	{ name = "Brutal Strike", vocations = { "elite knight", "knight" } },
	{ name = "Inflict Wound", vocations = { "elite knight", "exalted monk", "knight", "monk" } },
	{ name = "Ice Strike", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Great Energy Beam", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Divine Missile", vocations = { "paladin", "royal paladin" } },
	{ name = "Double Jab", vocations = { "exalted monk", "monk" } },
	{ name = "Electrify", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Apprentice's Strike", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Tiger Clash", vocations = { "exalted monk", "monk" } },
	{ name = "Ultimate Terra Strike", vocations = { "druid", "elder druid" } },
	{ name = "Strong Ice Strike", vocations = { "druid", "elder druid" } },
	{ name = "Eternal Winter", vocations = { "druid", "elder druid" } },
	{ name = "Strong Ethereal Spear", vocations = { "paladin", "royal paladin" } },
	{ name = "Rage of the Skies", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Swift Jab", vocations = { "exalted monk", "monk" } },
	{ name = "Ice Burst", vocations = { "druid", "elder druid" } },
	{ name = "Fierce Berserk", vocations = { "elite knight", "knight" } },
	{ name = "Ethereal Spear", vocations = { "paladin", "royal paladin" } },
	{ name = "Divine Caldera", vocations = { "paladin", "royal paladin" } },
	{ name = "Devastating Knockout", vocations = { "exalted monk", "monk" } },
	{ name = "Ultimate Energy Strike", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Lesser Front Sweep", vocations = { "elite knight", "knight" } },
	{ name = "Energy Strike", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Greater Flurry of Blows", vocations = { "exalted monk", "monk" } },
	{ name = "Curse", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Scorch", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Great Fire Wave", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Envenom", vocations = { "druid", "elder druid" } },
	{ name = "Spiritual Outburst", vocations = { "exalted monk", "monk" } },
	{ name = "Divine Grenade", vocations = { "paladin", "royal paladin" } },
	{ name = "Chained Penance", vocations = { "exalted monk", "monk" } },
	{ name = "Ice Wave", vocations = { "druid", "elder druid" } },
	{ name = "Ignite", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Front Sweep", vocations = { "elite knight", "knight" } },
	{ name = "Physical Strike", vocations = { "druid", "elder druid" } },
	{ name = "Terra Burst", vocations = { "druid", "elder druid" } },
	{ name = "Ultimate Ice Strike", vocations = { "druid", "elder druid" } },
	{ name = "Lesser Ethereal Spear", vocations = { "paladin", "royal paladin" } },
	{ name = "Wrath of Nature", vocations = { "druid", "elder druid" } },
	{ name = "Strong Energy Strike", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Ultimate Flame Strike", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Energy Beam", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Berserk", vocations = { "elite knight", "knight" } },
	{ name = "Energy Wave", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Strong Ice Wave", vocations = { "druid", "elder druid" } },
	{ name = "Strong Flame Strike", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Hell's Core", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Death Strike", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Flame Strike", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Sweeping Takedown", vocations = { "exalted monk", "monk" } },
	{ name = "Terra Wave", vocations = { "druid", "elder druid" } },
	{ name = "Summon Druid Familiar", vocations = { "druid", "elder druid" } },
	{ name = "Monk familiar", vocations = { "exalted monk", "monk" } },
	{ name = "Summon Knight Familiar", vocations = { "elite knight", "knight" } },
	{ name = "Summon Sorcerer Familiar", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Summon Paladin Familiar", vocations = { "paladin", "royal paladin" } },
	{ name = "Avatar of Nature", vocations = { "druid", "elder druid" } },
	{ name = "Food", vocations = { "druid", "elder druid" } },
	{ name = "Haste", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Summon Creature", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Sap Strength", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Challenge", vocations = { "elite knight" } },
	{ name = "Avatar of Storm", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Swift Foot", vocations = { "paladin", "royal paladin" } },
	{ name = "Virtue of Harmony", vocations = { "exalted monk", "monk" } },
	{ name = "Virtue of Sustain", vocations = { "exalted monk", "monk" } },
	{ name = "Magic Rope", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Divine Dazzle", vocations = { "paladin", "royal paladin" } },
	{ name = "Creature Illusion", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Find Fiend", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Focus Harmony", vocations = { "exalted monk", "monk" } },
	{ name = "Find Person", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Cancel Magic Shield", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Magic Shield", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Sharpshooter", vocations = { "paladin", "royal paladin" } },
	{ name = "Ultimate Light", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Divine Empowerment", vocations = { "paladin", "royal paladin" } },
	{ name = "Light", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Avatar of Balance", vocations = { "exalted monk", "monk" } },
	{ name = "Strong Haste", vocations = { "druid", "elder druid", "exalted monk", "master sorcerer", "monk", "sorcerer" } },
	{ name = "Chivalrous Challenge", vocations = { "elite knight", "knight" } },
	{ name = "Balanced Brawl", vocations = { "exalted monk", "monk" } },
	{ name = "Mentor Other", vocations = { "exalted monk", "monk" } },
	{ name = "Charge", vocations = { "elite knight", "knight" } },
	{ name = "Cancel Invisibility", vocations = { "paladin", "royal paladin" } },
	{ name = "Invisibility", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Virtue of Justice", vocations = { "exalted monk", "monk" } },
	{ name = "Great Light", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Avatar of Light", vocations = { "paladin", "royal paladin" } },
	{ name = "Expose Weakness", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Levitate", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Blood Rage", vocations = { "elite knight", "knight" } },
	{ name = "Protector", vocations = { "elite knight", "knight" } },
	{ name = "Focus Serenity", vocations = { "exalted monk", "monk" } },
	{ name = "Avatar of Steel", vocations = { "elite knight", "knight" } },
	{ name = "Paralyze Rune", vocations = { "druid", "elder druid" } },
	{ name = "Conjure Piercing Bolt", vocations = { "paladin", "royal paladin" } },
	{ name = "Conjure Power Bolt", vocations = { "royal paladin" } },
	{ name = "Magic Wall Rune", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Chameleon Rune", vocations = { "druid", "elder druid" } },
	{ name = "Great Fireball Rune", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Conjure Bolt", vocations = { "paladin", "royal paladin" } },
	{ name = "Ultimate Healing Rune", vocations = { "druid", "elder druid" } },
	{ name = "Intense Healing Rune", vocations = { "druid", "elder druid" } },
	{ name = "Conjure Royal Star", vocations = { "paladin", "royal paladin" } },
	{ name = "Heavy Magic Missile Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Avalanche Rune", vocations = { "druid", "elder druid" } },
	{ name = "Energy Bomb Rune", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Arrow Call", vocations = { "paladin", "royal paladin" } },
	{ name = "Stalagmite Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Fire Bomb Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Light Stone Shower Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Fireball Rune", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Wild Growth Rune", vocations = { "druid", "elder druid" } },
	{ name = "Animate Dead Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Soulfire Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Destroy Field Rune", vocations = { "druid", "elder druid", "exalted monk", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Icicle Rune", vocations = { "druid", "elder druid" } },
	{ name = "Poison Field Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Fire Field Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Stone Shower Rune", vocations = { "druid", "elder druid" } },
	{ name = "Thunderstorm Rune", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Disintegrate Rune", vocations = { "druid", "elder druid", "exalted monk", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Conjure Explosive Arrow", vocations = { "paladin", "royal paladin" } },
	{ name = "Sudden Death Rune", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Poison Wall Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Poison Bomb Rune", vocations = { "druid", "elder druid" } },
	{ name = "Enchant Spear", vocations = { "paladin", "royal paladin" } },
	{ name = "Conjure Sniper Arrow", vocations = { "paladin", "royal paladin" } },
	{ name = "Conjure Arrow", vocations = { "paladin", "royal paladin" } },
	{ name = "Conjure Poisoned Arrow", vocations = { "paladin", "royal paladin" } },
	{ name = "Cure Poison Rune", vocations = { "druid", "elder druid" } },
	{ name = "Explosion Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Holy Missile Rune", vocations = { "paladin", "royal paladin" } },
	{ name = "Convince Creature Rune", vocations = { "druid", "elder druid" } },
	{ name = "Fire Wall Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Conjure Wand of Darkness", vocations = { "master sorcerer", "sorcerer" } },
	{ name = "Energy Wall Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Lightest Missile Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Blank Rune", vocations = { "druid", "elder druid", "master sorcerer", "paladin", "royal paladin", "sorcerer" } },
	{ name = "Enchant Staff", vocations = { "master sorcerer" } },
	{ name = "Energy Field Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "Light Magic Missile Rune", vocations = { "druid", "elder druid", "master sorcerer", "sorcerer" } },
	{ name = "House Kick", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "House Guest List", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "House Door List", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
	{ name = "House Subowner List", vocations = { "druid", "elder druid", "elite knight", "exalted monk", "knight", "master sorcerer", "monk", "paladin", "royal paladin", "sorcerer" } },
}

local function learnAllSpells(player)
	local vocation = player:getVocation():getName():lower()
	for _, spell in ipairs(AllVocationSpells) do
		for _, voc in ipairs(spell.vocations) do
			if voc == vocation then
				player:learnSpell(spell.name)
				break
			end
		end
	end
end

function playerLogin.onLogin(player)
	-- Note: the original "premium expired -> teleport to Thais" logic was
	-- removed here. It only made sense for the official OTServBR-Global
	-- towns (Thais, Carlin, etc.) and crashed on custom worlds/towns.
	-- This server doesn't use the premium/free account distinction.

	local town = player:getTown()

	-- Open channels
	if town and table.contains({ TOWNS_LIST.DAWNPORT, TOWNS_LIST.DAWNPORT_TUTORIAL }, town:getId()) then
		player:openChannel(3) -- World chat
	else
		player:openChannel(3) -- World chat
		player:openChannel(5) -- Advertsing main
		if player:getGuild() then
			player:openChannel(0x00) -- guild
		end
	end

	learnAllSpells(player)

	return true
end

playerLogin:register()
