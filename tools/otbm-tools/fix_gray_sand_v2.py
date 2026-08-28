"""
2a rodada do fix do "gray sand" (mesmo bug do fix_gray_sand.py, mas o
Pedro pintou area nova com o mesmo brush quebrado e usou uma faixa mais
ampla de ids do que da primeira vez). O items.xml declara o nome "gray
sand" de 19271 ate 19302 (fromid/toid) -- a primeira correcao so cobriu
19271-19278 (os ids que o brush "muddy sand" do RME usa por padrao),
mas o Pedro tambem usou variantes decorativas soltas dentro da faixa mais
ampla (19271-19302), inclusive como ITEM em cima de outro chao, nao so
como GROUND.

Fix:
- Ground: 19271-19302 -> 422 ("sandstone tile", ja confirmado ao vivo
  funcionando, mesma escolha do fix anterior).
- Item decorativo solto na mesma faixa: removido (era so um "speckle" de
  textura, sem funcao, mesmo risco de nao renderizar/bloquear que o
  ground original).
"""
import sys
sys.path.insert(0, "tools/otbm-tools")
from otbm import read_otbm, write_otbm

MAP_PATH = "meu-mapa/MAPA OFICIAL DE TRABALHO.otbm"
BAD_IDS = set(range(19271, 19303))
GOOD_GROUND_ID = 422

m = read_otbm(MAP_PATH)
print(f"{len(m.tiles)} tiles total")

ground_fixed_by_floor = {}
items_removed = 0

for tile in m.tiles.values():
    if tile.ground in BAD_IDS:
        ground_fixed_by_floor[tile.z] = ground_fixed_by_floor.get(tile.z, 0) + 1
        tile.ground = GOOD_GROUND_ID

    if tile.items:
        before = len(tile.items)
        tile.items = [it for it in tile.items if it.id not in BAD_IDS]
        items_removed += before - len(tile.items)

print(f"Ground trocado (19271-19302 -> {GOOD_GROUND_ID}): {sum(ground_fixed_by_floor.values())} tiles")
print("Por floor:", ground_fixed_by_floor)
print(f"Itens decorativos soltos removidos: {items_removed}")

write_otbm(m, MAP_PATH)
print("Mapa salvo:", MAP_PATH)
