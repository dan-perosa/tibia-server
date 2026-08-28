"""
Adds the 3 remaining starter-kit reward chests (Paladin, Sorcerer, Druid)
next to the existing Knight chest (2472, actionid=30001 at 979,1087,7),
each with a readable sign next to it naming the class.
"""

from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm"
CHEST_ID = 2472
SIGN_ID = 2012
Z = 7

chests = [
    (979, "Knight", 30001),   # already placed, just add its sign
    (977, "Paladin", 30002),
    (975, "Sorcerer", 30003),
    (973, "Druid", 30004),
]

m = read_otbm(MAP_PATH)

for x, className, actionId in chests:
    chest_key = (x, 1087, Z)
    tile = m.tiles.get(chest_key)
    if tile is None:
        raise SystemExit(f"No tile at {chest_key}, aborting")

    has_chest = any(i.id == CHEST_ID for i in tile.items)
    if not has_chest:
        tile.items.append(OtbmItem(id=CHEST_ID, action_id=actionId))
        print(f"Placed chest for {className} at {chest_key}")
    else:
        for i in tile.items:
            if i.id == CHEST_ID:
                i.action_id = actionId
        print(f"Chest for {className} already present at {chest_key}, set actionid={actionId}")

    sign_key = (x, 1088, Z)
    sign_tile = m.tiles.get(sign_key)
    if sign_tile is None:
        raise SystemExit(f"No tile at {sign_key}, aborting")
    sign_tile.items.append(OtbmItem(id=SIGN_ID, text=f"{className} starting kit"))
    print(f"Placed sign for {className} at {sign_key}")

write_otbm(m, MAP_PATH)
print("Done!")
