"""
Clones Pedro's own hand-built central structure (marble floor + framework
wall + decorative corner pattern around 1000,1000) to the depot location,
then adds functional depot chests inside it.
"""

from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\meu-mapa.otbm"

Z = 7
SRC_X1, SRC_Y1 = 990, 990
SRC_X2, SRC_Y2 = 1010, 1010

DEST_CX, DEST_CY = 1030, 1000
OFFSET_X = DEST_CX - 1000
OFFSET_Y = DEST_CY - 1000

DEPOT_CHEST = 3502
CLEAR_RADIUS = 15


def main():
    print(f"Reading {MAP_PATH} ...")
    m = read_otbm(MAP_PATH)

    # ------------------------------------------------------------------
    # STEP 1: clear whatever is currently at the depot working area
    # (removes the earlier "Carlin stone" attempt Pedro didn't like)
    # ------------------------------------------------------------------
    cleared = 0
    for dx in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
        for dy in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
            key = (DEST_CX + dx, DEST_CY + dy, Z)
            if key in m.tiles:
                del m.tiles[key]
                cleared += 1
    print(f"  cleared {cleared} tiles at the depot location")

    # ------------------------------------------------------------------
    # STEP 2: clone Pedro's own structure tile-by-tile with an offset
    # ------------------------------------------------------------------
    cloned = 0
    for x in range(SRC_X1, SRC_X2 + 1):
        for y in range(SRC_Y1, SRC_Y2 + 1):
            src_tile = m.tiles.get((x, y, Z))
            if not src_tile:
                continue
            new_x = x + OFFSET_X
            new_y = y + OFFSET_Y
            new_tile = m.get_or_create_tile(new_x, new_y, Z)
            new_tile.ground = src_tile.ground
            new_tile.items = [OtbmItem(id=i.id) for i in src_tile.items]
            cloned += 1
    print(f"  cloned {cloned} tiles from your structure to ({DEST_CX},{DEST_CY})")

    # ------------------------------------------------------------------
    # STEP 3: add 4 functional depot chests on the plain marble apron
    # tiles (the same relative spots that were bare marble in the source)
    # ------------------------------------------------------------------
    chest_spots = [
        (996, 998), (996, 1002),
        (1004, 998), (1004, 1002),
    ]
    for sx, sy in chest_spots:
        x = sx + OFFSET_X
        y = sy + OFFSET_Y
        tile = m.get_or_create_tile(x, y, Z)
        tile.items.append(OtbmItem(id=DEPOT_CHEST))
    print(f"  placed {len(chest_spots)} depot chests")

    print(f"Writing back to {MAP_PATH} ...")
    write_otbm(m, MAP_PATH)
    print("Done!")
    print(f"Depot is centered at ({DEST_CX},{DEST_CY},{Z}) -- Ctrl+G there in RME to look.")
    print("Right-click each depot chest -> Properties -> set Depot ID to match your town's ID.")


if __name__ == "__main__":
    main()
