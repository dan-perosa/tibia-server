"""
Builds a brand new, minimal, known-good map from scratch:
a solid 41x41 floor platform (ground item 20712, confirmed
primarytype="artificial tiles" i.e. a REAL ground-type item in
Canary's item database, not the 20888 "tools" item that caused
the water-spawn bug) with one town temple dead center.

This intentionally has almost nothing else on it -- it's a clean
starting canvas for building manually in RME.
"""

from otbm import OtbmMap, OtbmTile, OtbmTown, write_otbm

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"

GROUND_ID = 20712  # "oramond marble floor1" -- verified real ground type
CENTER_X, CENTER_Y, Z = 1000, 1000, 7
RADIUS = 20  # -> 41x41 platform

MAP_BASENAME = "MAPA OFICIAL DE TRABALHO"
m = OtbmMap(
    description=MAP_BASENAME,
    spawn_monster_file=f"{MAP_BASENAME}-monster.xml",
    house_file=f"{MAP_BASENAME}-house.xml",
    spawn_npc_file=f"{MAP_BASENAME}-npc.xml",
    zone_file=f"{MAP_BASENAME}-zones.xml",
)

for x in range(CENTER_X - RADIUS, CENTER_X + RADIUS + 1):
    for y in range(CENTER_Y - RADIUS, CENTER_Y + RADIUS + 1):
        tile = OtbmTile(x=x, y=y, z=Z, ground=GROUND_ID)
        m.tiles[(x, y, Z)] = tile

m.towns.append(OtbmTown(id=1, name="Cidade de Spawn", x=CENTER_X, y=CENTER_Y, z=Z))

write_otbm(m, MAP_PATH)
print(f"Wrote fresh map: {len(m.tiles)} tiles, temple at ({CENTER_X},{CENTER_Y},{Z})")
