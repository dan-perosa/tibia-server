"""
Adds:
- A "down" return staircase on the existing north platform (z=6), so the
  north ramp becomes a round trip.
- A matching up-ramp + upper platform + down staircase on the west and
  east city walls (mirroring the north one), breaching the wall at the
  exact spot to make room for the ramp.

Floorchange mechanics (see canary/src/items/tile.cpp):
  - item with floorchange=north/south/east/west: moves the player to
    floor z-1, offset by 1 tile in that direction.
  - item with floorchange=down: moves the player straight down to z+1
    at the same x,y (as long as that tile exists and isn't itself another
    floorchange tile).
"""

from otbm import read_otbm, write_otbm, OtbmTile

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"

GROUND_ID = 20712     # verified real ground-type item
DOWN_STAIRS_ID = 469  # "stairs", floorchange=down
RAMP_WEST_ID = 1961   # "ramp", floorchange=west
RAMP_EAST_ID = 1960   # "ramp", floorchange=east
OPEN_GRASS_ID = 101   # matches the surrounding city floor

m = read_otbm(MAP_PATH)


def set_ground(x, y, z, ground_id):
    tile = m.tiles.get((x, y, z))
    if tile is None:
        tile = OtbmTile(x=x, y=y, z=z)
        m.tiles[(x, y, z)] = tile
    tile.ground = ground_id
    tile.items = []  # clear any stacked item (e.g. removing a wall)


# --- North: add a return staircase on the existing z=6 platform ---
for x in (999, 1000, 1001):
    set_ground(x, 961, 6, DOWN_STAIRS_ID)

# --- West: breach the wall, add up-ramp + upper platform + return stairs ---
for y in (985, 986, 987):
    set_ground(947, y, 7, RAMP_WEST_ID)  # breach wall, functional ramp

for x in range(941, 950):
    for y in range(982, 991):
        key = (x, y, 6)
        if key not in m.tiles:
            m.tiles[key] = OtbmTile(x=x, y=y, z=6, ground=GROUND_ID)

for y in (985, 986, 987):
    set_ground(948, y, 6, DOWN_STAIRS_ID)  # return stairs, lands just inside the wall

# --- East: breach the wall, add up-ramp + upper platform + return stairs ---
for y in (985, 986, 987):
    set_ground(1056, y, 7, RAMP_EAST_ID)  # breach wall, functional ramp

for x in range(1054, 1063):
    for y in range(982, 991):
        key = (x, y, 6)
        if key not in m.tiles:
            m.tiles[key] = OtbmTile(x=x, y=y, z=6, ground=GROUND_ID)

for y in (985, 986, 987):
    set_ground(1055, y, 6, DOWN_STAIRS_ID)  # return stairs, lands just inside the wall

write_otbm(m, MAP_PATH)
print("Done!")
