"""
Root cause do "agua" na hunt de scarab (piso 8, mas tambem usado nos pisos
6 e 7): o brush "muddy sand" do RME (grounds.xml, ids 19271-19278, nome
"gray sand" no items.xml deste servidor) EXISTE no items.xml (tem nome),
mas nao tem os flags de "ground" corretos nos dados de appearance que o
Canary usa em runtime (fonte separada dos items.xml, nao inspecionavel por
grep) -- confirmado ao vivo pelo Pedro: tile nao e so visualmente "agua",
e literalmente impossivel de andar ali, exatamente como o bug historico do
item 20888 (ver fix_ground_20888.py).

Fix: troca ground 19271-19278 -> 422 ("sandstone tile" / brush "tiled
sandstone floor" no RME). CORRIGIDO apos falha do primeiro fix: a tentativa
anterior usou 9246 ("earth"), que na verdade e o brush "earth mountain"
(parede rochosa, bloqueia passagem) -- confirmado quebrado pelo Pedro ao
vivo (virou parede solida na hunt inteira). Dessa vez o Pedro confirmou
direto no RME (Properties do tile) que 422 e o chao andavel de verdade que
ja funciona do lado -- nao e mais chute.
"""
import sys
sys.path.insert(0, "tools/otbm-tools")
from otbm import read_otbm, write_otbm

MAP_PATH = "meu-mapa/MAPA OFICIAL DE TRABALHO.otbm"
BAD_IDS = set(range(19271, 19279))
GOOD_ID = 422

m = read_otbm(MAP_PATH)
print(f"{len(m.tiles)} tiles total")

fixed_by_floor = {}
for tile in m.tiles.values():
    if tile.ground in BAD_IDS:
        fixed_by_floor[tile.z] = fixed_by_floor.get(tile.z, 0) + 1
        tile.ground = GOOD_ID

total = sum(fixed_by_floor.values())
print(f"Trocado ground 19271-19278 -> {GOOD_ID} em {total} tiles")
print("Por floor:", fixed_by_floor)

write_otbm(m, MAP_PATH)
print("Mapa salvo:", MAP_PATH)
