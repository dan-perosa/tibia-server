"""
Ad-hoc script: dá mais vida ao patio/porto perto do Yasir (x~1019-1034, y~977-1002, z=7).
- Adiciona um novo barco pequeno ao sul do patio (coluna x=1026, y=1000-1008),
  reusando os MESMOS item ids do barco original em x=1033 (ja comprovado que
  renderiza nesse mapa).
- Espalha algumas props decorativas (caixote, barril, rede de pesca) no patio
  vazio, reusando ids ja usados na vizinhanca portuaria.
Nao mexe em nenhum ground id -- so adiciona itens em cima do que ja existe,
e so em tiles que hoje estao sem nenhum item (nunca sobrescreve).
"""
import sys
sys.path.insert(0, "tools/otbm-tools")
from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = "meu-mapa/MAPA OFICIAL DE TRABALHO.otbm"
Z = 7

m = read_otbm(MAP_PATH)

def tile(x, y):
    return m.tiles.get((x, y, Z))

# ---------------------------------------------------------------------------
# 1) Novo barco pequeno, coluna x=1026, indo do patio (norte) para a agua (sul)
# ---------------------------------------------------------------------------
boat_plan = [
    (1026, 1000, [4972]),               # bollard (amarracao em terra)
    (1026, 1001, [4978]),               # hawser (corda) -- mantem puddle existente
    (1026, 1002, [4979]),               # hawser (corda) -- mantem puddle existente
    (1026, 1003, [1759]),               # small boat (popa)
    (1026, 1004, [1758]),               # small boat
    (1026, 1005, [1758]),               # small boat
    (1026, 1006, [1757]),               # small boat
    (1026, 1007, [1755, 1766]),         # small boat (proa) + small sail
    (1026, 1008, [4973]),               # anchor (na agua, a frente da proa)
]

boat_conflicts = []
for x, y, _ in boat_plan:
    t = tile(x, y)
    if t is None:
        boat_conflicts.append((x, y, "tile inexistente"))

if boat_conflicts:
    raise SystemExit(f"ABORT: tiles do barco nao existem no mapa: {boat_conflicts}")

for x, y, new_items in boat_plan:
    t = tile(x, y)
    for iid in new_items:
        t.items.append(OtbmItem(id=iid))

print(f"Barco: {len(boat_plan)} tiles atualizados (coluna x=1026, y=1000-1008).")

# ---------------------------------------------------------------------------
# 2) Decoracao espalhada no patio vazio (x=1021-1032, y=979-999)
#    Só em tiles que hoje NAO tem nenhum item, ground compativel com o patio.
# ---------------------------------------------------------------------------
PATIO_GROUNDS = {22356, 22355, 1771, 16484, 16485, 20712, 21345, 500}

decor_candidates = [
    (1022, 981, 2471),   # crate
    (1030, 980, 2523),   # barrel
    (1023, 986, 2745),   # fishing net
    (1029, 987, 2471),   # crate
    (1021, 992, 2523),   # barrel
    (1031, 993, 2748),   # fishing net
    (1024, 996, 2471),   # crate
    (1028, 998, 2523),   # barrel
    (1022, 998, 2750),   # fishing net
    (1031, 984, 2471),   # crate
]

decor_skipped = []
decor_placed = []
for x, y, iid in decor_candidates:
    t = tile(x, y)
    if t is None:
        decor_skipped.append((x, y, "tile inexistente"))
        continue
    if t.items:
        decor_skipped.append((x, y, f"ja tem item(s) {[it.id for it in t.items]}"))
        continue
    if t.ground not in PATIO_GROUNDS:
        decor_skipped.append((x, y, f"ground {t.ground} fora do patio"))
        continue
    t.items.append(OtbmItem(id=iid))
    decor_placed.append((x, y, iid))

print(f"Decoracao: {len(decor_placed)} props colocadas, {len(decor_skipped)} puladas.")
for x, y, reason in decor_skipped:
    print("  pulado:", x, y, "-", reason)

write_otbm(m, MAP_PATH)
print("Mapa salvo:", MAP_PATH)
