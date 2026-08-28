local tptemplo = TalkAction("!tptemplo")

function tptemplo.onSay(player, words, param)
	local town = player:getTown()
	if not town then
		player:sendCancelMessage("Your town could not be found.")
		return true
	end

	player:teleportTo(town:getTemplePosition())
	return true
end

tptemplo:groupType("normal")
tptemplo:register()
