from otbm import read_otbm, write_otbm

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\mapa 2.0.otbm"

NEW_TEMPLE = (982, 1022, 7)  # empty, plain floor tile inside Pedro's real built area


def main():
    print(f"Reading {MAP_PATH} ...")
    m = read_otbm(MAP_PATH)
    print(f"  {len(m.tiles)} tiles before changes")

    removed = 0
    for key in list(m.tiles.keys()):
        tile = m.tiles[key]
        if tile.ground and 20374 <= tile.ground <= 20391:
            del m.tiles[key]
            removed += 1
    print(f"  removed {removed} quarry tiles")

    if m.towns:
        old = m.towns[0]
        print(f"  moving town '{old.name}' temple from ({old.x},{old.y},{old.z}) to {NEW_TEMPLE}")
        old.x, old.y, old.z = NEW_TEMPLE
    else:
        print("  WARNING: no town found in this map!")

    print(f"  {len(m.tiles)} tiles after changes")
    print(f"Writing back to {MAP_PATH} ...")
    write_otbm(m, MAP_PATH)
    print("Done!")


if __name__ == "__main__":
    main()
