"""
Two problems found in the north stairs/bridge area:

1. Pedro placed item 7888 ("stone stairs") at (999-1002, 945, 7) trying to
   build his own return-up path. That specific item ID is hard-coded in
   data-otservbr-global/scripts/movements/rookgaard/rook_village.lua to
   kick ANY player who steps on it back out with "You don't have any
   business there anymore" -- it's a leftover Rookgaard anti-return script
   that fires no matter where on the map the item is placed. Removing it
   and using a normal ramp item (1953, floorchange=south, same one used
   elsewhere on this map) with the same landing math fixes it cleanly.

2. The down-stairs (469) at z=6 (999-1002, 964) sit exactly on the tile
   players land on after walking up the main north ramp -- immediately
   sending them back down again. Reverted to plain floor; the real
   "down" return is the one at z=6 row 946 instead.
"""

from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"
GROUND_ID = 20712
RAMP_SOUTH_ID = 1953  # floorchange=south, already used safely elsewhere

m = read_otbm(MAP_PATH)

# 1. Remove the cursed "stone stairs" (7888) and replace with a working ramp.
for x in (999, 1000, 1001, 1002):
    tile = m.tiles[(x, 945, 7)]
    tile.items = [i for i in tile.items if i.id != 7888]

for x in (999, 1000, 1001, 1002):
    tile = m.tiles[(x, 946, 7)]
    tile.items = [OtbmItem(id=RAMP_SOUTH_ID)]

# 2. Remove the down-stairs sitting on the main ramp's landing spot.
for x in (999, 1000, 1001, 1002):
    tile = m.tiles[(x, 964, 6)]
    tile.ground = GROUND_ID
    tile.items = []

write_otbm(m, MAP_PATH)
print("Done!")
