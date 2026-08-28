"""
Pedro rebuilt the area above the north stairs as a bridge (z=6, x=998-1002,
y=945-963) and removed the small platform I originally built there. This
left two problems:

1. The north up-ramp (z=7, y=965, floorchange=north) lands at (x, 964, 6) --
   one tile south of the bridge's south end (y=963). That landing tile
   didn't exist, so going up silently failed again.
2. My old "down" stairs (item 469) ended up stranded mid-bridge (y=961),
   disconnected from anything useful.

Fix: bridge the 1-tile gap so the up-ramp actually connects to the bridge,
revert the stranded mid-bridge stairs back to plain floor, and add a new
"down" staircase at the far (north) end of the bridge instead, landing on
the existing z=7 ground below it.
"""

from otbm import read_otbm, write_otbm, OtbmTile

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"
GROUND_ID = 20712
DOWN_STAIRS_ID = 469

m = read_otbm(MAP_PATH)

# 1. Connect the up-ramp's landing spot to the bridge's south end.
for x in (999, 1000, 1001):
    key = (x, 964, 6)
    if key not in m.tiles:
        m.tiles[key] = OtbmTile(x=x, y=964, z=6, ground=GROUND_ID)

# 2. Revert the old stranded mid-bridge down-stairs back to plain floor.
for x in (999, 1000, 1001):
    tile = m.tiles.get((x, 961, 6))
    if tile:
        tile.ground = GROUND_ID
        tile.items = []

# 3. Add the new down-staircase at the far (north) end of the bridge.
for x in (1000, 1001, 1002):
    tile = m.tiles[(x, 945, 6)]
    tile.ground = DOWN_STAIRS_ID

write_otbm(m, MAP_PATH)
print("Done!")
