"""
3a rodada do fix do "gray sand" (mesmo bug de sempre: brush "muddy sand" do
RME usa ids 19271-19302, que existem no items.xml mas nao funcionam como
chao de verdade no Canary) + correcao do desvio da escada de descida em
(1117, 1047/1048, 6).

Gray sand:
- Ground 19271-19302 -> 422 ("sandstone tile", ja validado ao vivo nas
  duas rodadas anteriores).
- Itens decorativos soltos na mesma faixa: removidos.

Escada (1117, 1047, 6) e (1117, 1048, 6):
Sao duas rampas de descida (item 7734, floorchange=down) lado a lado.
O motor calcula o destino da descida checando se o tile DIRETAMENTE
ABAIXO do ponto de chegada (mesmo x,y, z+1) tem ele mesmo uma flag de
floorchange direcional (north/south/east/west) -- se tiver, aplica o
deslocamento. Sem isso, cai reto embaixo.

Ja existe um item 7545 ("ramp", variante SEM direcao) bem em cima do
tile de pouso de (1117,1047,6) -- ou seja, o desenho da escada ja estava
la, só faltava ser a peca CERTA da familia. 7546 e a mesma peca "ramp"
mas com floorchange=south, que faz o motor subtrair 1 do y no pouso
(1047 -> 1046), exatamente o que o Pedro pediu.

Fix:
- (1117, 1047, 7): troca o item 7545 -> 7546 (mesma familia visual,
  agora com a flag south). Resultado: (1117,1047,6) desce ate
  (1117,1046,7) em vez de (1117,1047,7).
- (1117, 1048, 7): adiciona item 7546 (nao existia peca de rampa ali
  ainda, só o chao quebrado). Resultado: (1117,1048,6) desce ate
  (1117,1047,7) em vez de (1117,1048,7) -- mantem as duas entradas da
  escada levando a pontos distintos, um degrau ao norte de onde caiam
  antes.
"""
import sys
sys.path.insert(0, "tools/otbm-tools")
from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = "meu-mapa/MAPA OFICIAL DE TRABALHO.otbm"
BAD_IDS = set(range(19271, 19303))
GOOD_GROUND_ID = 422
SOUTH_RAMP_ID = 7546

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

# --- correcao do desvio da escada ---
t1 = m.tiles.get((1117, 1047, 7))
swapped = False
for it in t1.items:
    if it.id == 7545:
        it.id = SOUTH_RAMP_ID
        swapped = True
        break
print("(1117,1047,7): item 7545 -> 7546?", swapped)

t2 = m.tiles.get((1117, 1048, 7))
has_ramp = any(it.id in (7543, 7544, 7545, 7546, 7547, 7548, 7549) for it in t2.items)
if not has_ramp:
    t2.items.append(OtbmItem(id=SOUTH_RAMP_ID))
    print("(1117,1048,7): item 7546 adicionado")
else:
    print("(1117,1048,7): ja tinha peca de rampa, nada adicionado")

write_otbm(m, MAP_PATH)
print("Mapa salvo:", MAP_PATH)
