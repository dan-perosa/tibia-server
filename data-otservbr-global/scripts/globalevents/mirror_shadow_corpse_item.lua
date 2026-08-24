-- Mirror's Shadow (ilha secreta, 5% de chance na viagem do Boatman):
-- garante que o corpo ("dead human", item 6560, em 912,257,7) tem o
-- Haunted Mirror Piece (19373) dentro -- gancho de lore pra uma quest
-- futura (o guardiao "de olhos amaldiçoados" que o Castaway Corwin
-- menciona). Rodado no boot em vez de gravado direto no .otbm porque
-- otbm.py nao mexe em conteudo de container, e o item 6560 tem
-- decayTo/duration no items.xml -- rodar isso toda vez que o servidor
-- sobe garante que o item nunca fica faltando por causa do apodrecimento.

local mirrorShadowCorpseItem = GlobalEvent("Mirror Shadow Corpse Item")

function mirrorShadowCorpseItem.onStartup()
	local corpsePosition = Position(912, 257, 7)
	local corpse = Tile(corpsePosition):getItemById(6560)
	if not corpse then
		logger.warn("[Mirror Shadow] Corpo (item 6560) nao encontrado em (912,257,7) -- Haunted Mirror Piece nao foi colocado.")
		return true
	end

	local container = Container(corpse.uid)
	if container:getItemCountById(19373) == 0 then
		container:addItem(19373, 1)
	end
	return true
end

mirrorShadowCorpseItem:register()
