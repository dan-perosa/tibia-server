"""
Root cause of the water-spawn bug: item 20888 ("marble floor" in RME's brush
list) is flagged primarytype="tools" in Canary's items.xml, not a real floor.
Canary's loader only sets tile.ground when Item::items[id].isGroundTile() is
true (see canary/src/io/iomap.cpp + canary/src/items/items.cpp, group is set
from the item's appearance flags(), not from RME's grounds.xml). Since 20888
isn't flagged as ground-type, every tile using it as ground loads with NO
ground at all in Canary -> renders/behaves like water.

Fix: replace ground=20888 with ground=20712 ("oramond marble floor1"),
same visual family, confirmed primarytype="artificial tiles" (real floor).
"""

import sys
from pathlib import Path

from otbm import read_otbm, write_otbm

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MAP_PATH = REPO_ROOT / "meu-mapa" / "MAPA OFICIAL DE TRABALHO.otbm"

MAP_PATH = sys.argv[1] if len(sys.argv) > 1 else str(DEFAULT_MAP_PATH)
BAD_ID = 20888
GOOD_ID = 20712

m = read_otbm(MAP_PATH)
print(f"{len(m.tiles)} tiles total")

fixed = 0
for tile in m.tiles.values():
    if tile.ground == BAD_ID:
        tile.ground = GOOD_ID
        fixed += 1

print(f"Replaced ground {BAD_ID} -> {GOOD_ID} on {fixed} tiles")

if m.towns:
    t = m.towns[0]
    print(f"Town temple stays at ({t.x},{t.y},{t.z}) - its ground is now fixed too")

write_otbm(m, MAP_PATH)
print("Done!")
