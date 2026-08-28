"""
Configura a nova quest atras dos portoes de level 100:
- 4 teleportes (item 1949) com destino certo (alguns vieram do mapa oficial
  com tele_dest apontando pra coordenada que nao existe aqui, ou sem
  destino nenhum).
- 5 baus de recompensa (item 2472) na sala final do boss, Action ID
  24901-24905 (faixa confirmada livre em scripts e no mapa).
"""
import sys
sys.path.insert(0, "tools/otbm-tools")
from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = "meu-mapa/MAPA OFICIAL DE TRABALHO.otbm"
Z = 9

m = read_otbm(MAP_PATH)

def tile(x, y):
    return m.tiles.get((x, y, Z))

# --- Teleportes ---
teleport_fixes = [
    ((1213, 1096), (1252, 1096, Z)),   # entrada -> sala do meio
    ((1252, 1097), (1211, 1096, Z)),   # retorno -> sala anterior
    ((1252, 1114), (1251, 1131, Z)),   # -> sala final do boss
    ((1252, 1143), (1000, 1000, 7)),   # saida final -> templo
]

for (x, y), dest in teleport_fixes:
    t = tile(x, y)
    found = False
    for it in t.items:
        if it.id == 1949:
            it.tele_dest = dest
            it.unique_id = None  # limpa uid orfao vindo do mapa oficial (so o da saida tinha)
            found = True
    if not found:
        raise SystemExit(f"ABORT: nenhum teleporte (1949) encontrado em ({x},{y},{Z})")
    print(f"Teleporte ({x},{y},{Z}) -> {dest}")

# --- Baus de recompensa (sala final do boss) ---
CHEST_ITEM_ID = 2472
chest_positions = [
    (1247, 1131),
    (1255, 1136),
    (1247, 1139),
    (1255, 1139),
    (1251, 1136),
]
ACTION_IDS = [24901, 24902, 24903, 24904, 24905]

conflicts = []
for x, y in chest_positions:
    t = tile(x, y)
    if t is None:
        conflicts.append((x, y, "tile inexistente"))
    elif t.items:
        conflicts.append((x, y, f"ja tem item(s) {[it.id for it in t.items]}"))

if conflicts:
    raise SystemExit(f"ABORT: conflitos nas posicoes dos baus: {conflicts}")

for (x, y), aid in zip(chest_positions, ACTION_IDS):
    t = tile(x, y)
    t.items.append(OtbmItem(id=CHEST_ITEM_ID, action_id=aid))
    print(f"Bau (aid={aid}) colocado em ({x},{y},{Z})")

write_otbm(m, MAP_PATH)
print("Mapa salvo:", MAP_PATH)
