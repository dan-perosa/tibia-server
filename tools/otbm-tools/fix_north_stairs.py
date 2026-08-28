"""
The ramp Pedro placed at the north city exit (item 1957, floorchange=north)
is correctly configured, but there was no ground built on z=6 at the exact
landing spot the game computes for floorchange=north: (x, y-1, z-1).
For the ramp tiles at (999-1001, 965, 7), that's (999-1001, 964, 6).

Adds a small solid landing patch on z=6 around that spot using item 20712
(verified real ground-type item, see fix_ground_20888.py).
"""

from otbm import read_otbm, write_otbm, OtbmTile

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"
GROUND_ID = 20712
Z = 6

m = read_otbm(MAP_PATH)

added = 0
for x in range(996, 1005):
    for y in range(959, 966):
        key = (x, y, Z)
        if key not in m.tiles:
            m.tiles[key] = OtbmTile(x=x, y=y, z=Z, ground=GROUND_ID)
            added += 1

print(f"Added {added} new ground tiles at z={Z}")
write_otbm(m, MAP_PATH)
print("Done!")
