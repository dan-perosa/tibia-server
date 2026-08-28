"""
Generates the Carlin-style depot directly into meu-mapa.otbm using the
Python otbm.py writer -- no RME script execution needed.

Reads the CURRENT saved map (preserving whatever Pedro built manually),
adds/overwrites tiles in the depot working area, and saves back.
"""

from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\meu-mapa.otbm"

# --- Real item IDs, verified against RME's materials data ---
GROUND_STONE = 429  # gray stone tiles

WALL_HORIZONTAL = 1295
WALL_VERTICAL = 1294
WALL_CORNER = 1298
WALL_POLE = 1296

DEPOT_CHEST = 3502
DEPOT_SIGN = 5371
RUG_CENTER = 4858  # red carpet, center piece
SMALL_DRAWER = 2433  # furniture the chest sits on top of

Z = 7
CX, CY = 1030, 1000
CLEAR_RADIUS = 15

X1, X2 = CX - 7, CX + 6
Y1, Y2 = CY - 5, CY + 5
DOOR_X, DOOR_Y = CX, Y2

BAY_AREA_X1 = CX - 6
BAY_WIDTH = 3
BAY_DEPTH = 3


def main():
    print(f"Reading {MAP_PATH} ...")
    m = read_otbm(MAP_PATH)
    print(f"  {len(m.tiles)} tiles before changes")

    # ------------------------------------------------------------------
    # STEP 1: clear the working area
    # ------------------------------------------------------------------
    cleared = 0
    for dx in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
        for dy in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
            key = (CX + dx, CY + dy, Z)
            if key in m.tiles:
                del m.tiles[key]
                cleared += 1
    print(f"  cleared {cleared} existing tiles in the working area")

    # ------------------------------------------------------------------
    # STEP 2: floor
    # ------------------------------------------------------------------
    for x in range(X1, X2 + 1):
        for y in range(Y1, Y2 + 1):
            tile = m.get_or_create_tile(x, y, Z)
            tile.ground = GROUND_STONE

    # ------------------------------------------------------------------
    # STEP 3: outer perimeter walls (skip the door tile)
    # ------------------------------------------------------------------
    def is_corner(x, y):
        return (x in (X1, X2)) and (y in (Y1, Y2))

    for x in range(X1, X2 + 1):
        for y in (Y1, Y2):
            if x == DOOR_X and y == DOOR_Y:
                continue
            tile = m.get_or_create_tile(x, y, Z)
            tile.ground = GROUND_STONE
            tile.items.append(OtbmItem(id=WALL_CORNER if is_corner(x, y) else WALL_HORIZONTAL))

    for y in range(Y1, Y2 + 1):
        for x in (X1, X2):
            if x == DOOR_X and y == DOOR_Y:
                continue
            if is_corner(x, y):
                continue  # already placed above
            tile = m.get_or_create_tile(x, y, Z)
            tile.ground = GROUND_STONE
            tile.items.append(OtbmItem(id=WALL_VERTICAL))

    # ------------------------------------------------------------------
    # STEP 4: 4 walled-off bays along the back (north) wall
    # ------------------------------------------------------------------
    for i in range(4):
        bay_x1 = BAY_AREA_X1 + i * BAY_WIDTH
        chest_x = bay_x1 + 1  # middle tile of the bay

        # Side wall separating this bay from the next (skip after bay 3 --
        # its east side is the building's own east wall)
        if i < 3:
            divider_x = bay_x1 + BAY_WIDTH
            for depth in range(1, BAY_DEPTH + 1):
                tile = m.get_or_create_tile(divider_x, Y1 + depth, Z)
                tile.ground = GROUND_STONE
                tile.items.append(OtbmItem(id=WALL_VERTICAL))

        # Furniture + depot chest stacked on the same tile
        chest_tile = m.get_or_create_tile(chest_x, Y1 + 1, Z)
        chest_tile.items.append(OtbmItem(id=SMALL_DRAWER))
        chest_tile.items.append(OtbmItem(id=DEPOT_CHEST))

        # Rug accent in front of the chest
        rug_tile = m.get_or_create_tile(chest_x, Y1 + 2, Z)
        rug_tile.items.append(OtbmItem(id=RUG_CENTER))

    print("  built 4 walled-off bays with elevated chests + rugs")

    # Sign near the entrance
    sign_tile = m.get_or_create_tile(DOOR_X, DOOR_Y - 1, Z)
    sign_tile.items.append(OtbmItem(id=DEPOT_SIGN))

    print(f"  {len(m.tiles)} tiles after changes")
    print(f"Writing back to {MAP_PATH} ...")
    write_otbm(m, MAP_PATH)
    print("Done!")
    print("IMPORTANT: right-click each depot chest in RME -> Properties -> set Depot ID "
          "to match your town's ID.")


if __name__ == "__main__":
    main()
