local lastdeath = TalkAction("!lastdeath")

function lastdeath.onSay(player, words, param)
	local deathPosition = player:kv():scoped("last-death"):get("position")
	if type(deathPosition) ~= "table" then
		player:sendCancelMessage("No recorded death found for this character yet.")
		return true
	end

	player:teleportTo(Position(deathPosition.x, deathPosition.y, deathPosition.z))
	return true
end

lastdeath:groupType("god")
lastdeath:register()
