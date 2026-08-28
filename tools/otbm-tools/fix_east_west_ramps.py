"""
The east/west up-ramps (items 1960/1961) were placed directly as tile
ground, which RME doesn't treat as a real "ground" brush -- they got
silently stripped the next time the map was saved in RME. Fix: place them
as a stacked item on top of a normal validated ground tile instead,
mirroring how the north ramp (item 1957, which already survives RME saves)
is set up.
"""

from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"
GROUND_ID = 20712
RAMP_WEST_ID = 1961
RAMP_EAST_ID = 1960

m = read_otbm(MAP_PATH)

for y in (985, 986, 987):
    tile = m.tiles[(947, y, 7)]
    tile.ground = GROUND_ID
    tile.items = [OtbmItem(id=RAMP_WEST_ID)]

    tile = m.tiles[(1056, y, 7)]
    tile.ground = GROUND_ID
    tile.items = [OtbmItem(id=RAMP_EAST_ID)]

write_otbm(m, MAP_PATH)
print("Done!")
