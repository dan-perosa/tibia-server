"""
The "down" stairs (item 469) at the far north end of the bridge only go
one way. Add a floorchange=south item just north of them, on z=7, as a
stacked item on top of the existing ground (the same pattern already
proven to survive RME saves for the other ramps). Walking south across it
sends the player back up to (x, 945, 6) -- exactly the down-stairs spot,
closing the loop.
"""

from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"
RAMP_SOUTH_ID = 1953  # floorchange=south

m = read_otbm(MAP_PATH)

for x in (1000, 1001, 1002):
    tile = m.tiles[(x, 944, 7)]
    tile.items = [OtbmItem(id=RAMP_SOUTH_ID)]

write_otbm(m, MAP_PATH)
print("Done!")
