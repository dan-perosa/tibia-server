-- Chama de retorno da tumba custom de Skartholt (entrada em
-- movements_all_teleports_tombs_coal_basin.lua, uid 60000). So um passo
-- na chama, sem item nenhum, teleporta de volta pra fora da tumba.

local skartholtTombReturn = MoveEvent()

function skartholtTombReturn.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local destination = Position(1014, 1009, 7)
	player:teleportTo(destination)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

skartholtTombReturn:type("stepin")
skartholtTombReturn:uid(60001)
skartholtTombReturn:register()
