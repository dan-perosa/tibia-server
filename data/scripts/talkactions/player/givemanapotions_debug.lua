-- Temporary debug command: gives 100 mana potions to whoever says it.
-- Not a real game feature -- used to test skill/ML gain rates. Safe to delete later.
local givemanapotions = TalkAction("!givemanapotions")

function givemanapotions.onSay(player, words, param)
	local amount = 100
	if player:getFreeCapacity() < amount then
		player:sendTextMessage(MESSAGE_LOOK, "You're too overweight to carry 100 mana potions right now.")
		return true
	end

	player:addItem(268, amount)
	player:sendTextMessage(MESSAGE_LOOK, "Received " .. amount .. " mana potions (debug command).")
	return true
end

givemanapotions:groupType("gamemaster")
givemanapotions:register()

local giverod = TalkAction("!giverod")

function giverod.onSay(player, words, param)
	if player:getFreeCapacity() < 10 then
		player:sendTextMessage(MESSAGE_LOOK, "You're too overweight to carry that right now.")
		return true
	end

	player:addItem(28556, 1, true, 14400) -- exercise rod, 14400 charges (~8h at the dummy)
	player:sendTextMessage(MESSAGE_LOOK, "Received an exercise rod with 14400 charges (debug command).")
	return true
end

giverod:groupType("gamemaster")
giverod:register()

-- Temporary debug command: reports the player's real, server-side chase state while
-- reproducing the "character walks into the monster while attacking, chase mode has no
-- effect" bug (2026-08-26). Say this WHILE actively attacking and getting pulled in, to
-- see whether followCreature is actually set (chase system engaged) or not (something
-- else is causing the movement). Safe to delete once the bug is found.
local checkchase = TalkAction("!checkchase")

function checkchase.onSay(player, words, param)
	local followed = player:getFollowCreature()
	player:sendTextMessage(MESSAGE_LOOK, string.format(
		"followCreature=%s",
		followed and followed:getName() or "nil"
	))
	return true
end

checkchase:groupType("normal")
checkchase:register()
