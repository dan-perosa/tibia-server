-- Minlevel and multiplier are MANDATORY
-- Maxlevel is OPTIONAL, but is considered infinite by default
-- Create a stage with minlevel 1 and no maxlevel to disable stages
-- Calibrated against real Tibia global XP/hour data (manual hunting, no bots)
-- and the server's own getExpForLevel curve -- see docs/exp-rate-design.md
-- for the full methodology, data sources, and decision history.
experienceStages = {
	{
		minlevel = 1,
		maxlevel = 100,
		multiplier = 12, -- doubled again from 6 on 2026-08-26 (was 3 originally, doubled 2026-08-24) -- still felt too slow after real playtesting
	},
	{
		minlevel = 101,
		maxlevel = 200,
		multiplier = 7,
	},
	{
		minlevel = 201,
		maxlevel = 300,
		multiplier = 11,
	},
	{
		minlevel = 301,
		maxlevel = 400,
		multiplier = 13,
	},
	{
		minlevel = 401,
		maxlevel = 500,
		multiplier = 15,
	},
	{
		minlevel = 501,
		maxlevel = 700,
		multiplier = 20, -- reduced from 34 on 2026-08-27, see docs/exp-rate-design.md
	},
	{
		minlevel = 701,
		maxlevel = 850,
		multiplier = 25, -- reduced from 43
	},
	{
		minlevel = 851,
		maxlevel = 1000,
		multiplier = 30, -- reduced from 52
	},
	{
		minlevel = 1001,
		maxlevel = 1200,
		multiplier = 34, -- reduced from 58
	},
	{
		minlevel = 1201,
		maxlevel = 1350,
		multiplier = 37, -- reduced from 63
	},
	{
		minlevel = 1351,
		maxlevel = 1500,
		multiplier = 40, -- reduced from 68
	},
	{
		minlevel = 1501,
		maxlevel = 1750,
		multiplier = 43, -- reduced from 74
	},
	{
		minlevel = 1751,
		maxlevel = 2000,
		multiplier = 47, -- reduced from 80
	},
	{
		minlevel = 2001,
		maxlevel = 2500,
		multiplier = 50, -- reduced from 85
	},
	{
		minlevel = 2501,
		multiplier = 53, -- reduced from 91
	},
}

-- Left EMPTY and UNUSED (2026-08-24): skill/magic level rate no longer reads these tables at
-- all. Player:onGainSkillTries (data/events/scripts/player.lua) now computes a custom 3-phase
-- rate curve directly instead of calling getRateFromTable() against these -- see
-- docs/skill-power-design.md for the full design. rateSkill/rateMagic in config.lua are also
-- unused for this reason. Kept here (still empty) only so the template defaults below aren't
-- lost, in case skill/magic ever need to go back to the stock stages-table approach.
skillsStages = {}
-- skillsStages = {
-- 	{
-- 		minlevel = 10,
-- 		maxlevel = 60,
-- 		multiplier = 15,
-- 	},
-- 	{
-- 		minlevel = 61,
-- 		maxlevel = 80,
-- 		multiplier = 10,
-- 	},
-- 	{
-- 		minlevel = 81,
-- 		maxlevel = 110,
-- 		multiplier = 6,
-- 	},
-- 	{
-- 		minlevel = 111,
-- 		maxlevel = 125,
-- 		multiplier = 4,
-- 	},
-- 	{
-- 		minlevel = 126,
-- 		multiplier = 2,
-- 	},
-- }

magicLevelStages = {}
-- magicLevelStages = {
-- 	{
-- 		minlevel = 0,
-- 		maxlevel = 60,
-- 		multiplier = 10,
-- 	},
-- 	{
-- 		minlevel = 61,
-- 		maxlevel = 80,
-- 		multiplier = 7,
-- 	},
-- 	{
-- 		minlevel = 81,
-- 		maxlevel = 100,
-- 		multiplier = 5,
-- 	},
-- 	{
-- 		minlevel = 101,
-- 		maxlevel = 110,
-- 		multiplier = 4,
-- 	},
-- 	{
-- 		minlevel = 111,
-- 		maxlevel = 125,
-- 		multiplier = 3,
-- 	},
-- 	{
-- 		minlevel = 126,
-- 		multiplier = 2,
-- 	},
-- }
