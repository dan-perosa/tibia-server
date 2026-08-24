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

givemanapotions:groupType("normal")
givemanapotions:register()

local giverod = TalkAction("!giverod")

function giverod.onSay(player, words, param)
	if player:getFreeCapacity() < 10 then
		player:sendTextMessage(MESSAGE_LOOK, "You're too overweight to carry that right now.")
		return true
	end

	player:addItem(35283, 1, true, 1800) -- durable exercise rod, 1800 charges
	player:sendTextMessage(MESSAGE_LOOK, "Received a durable exercise rod (debug command).")
	return true
end

giverod:groupType("normal")
giverod:register()
