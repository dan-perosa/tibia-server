import sys
from otbm import read_otbm, write_otbm

SRC = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\meu-mapa.otbm"
OUT = r"C:\Users\Pedro\Desktop\tibia-server\tools\otbm-tools\roundtrip_test.otbm"

print(f"Reading {SRC} ...")
m1 = read_otbm(SRC)
print(f"  version={m1.version} width={m1.width} height={m1.height}")
print(f"  description={m1.description!r}")
print(f"  ext_description={m1.ext_description!r}")
print(f"  spawn_monster_file={m1.spawn_monster_file!r}")
print(f"  spawn_npc_file={m1.spawn_npc_file!r}")
print(f"  house_file={m1.house_file!r}")
print(f"  zone_file={m1.zone_file!r}")
print(f"  tiles={len(m1.tiles)} towns={len(m1.towns)} waypoints={len(m1.waypoints)}")

total_items = sum(len(t.items) for t in m1.tiles.values())
grounds = sum(1 for t in m1.tiles.values() if t.ground is not None)
print(f"  total ground tiles={grounds} total stacked items={total_items}")

for town in m1.towns:
    print(f"  town: id={town.id} name={town.name!r} pos=({town.x},{town.y},{town.z})")

print(f"\nWriting round-trip copy to {OUT} ...")
write_otbm(m1, OUT)

print(f"Re-reading {OUT} ...")
m2 = read_otbm(OUT)

print(f"  tiles={len(m2.tiles)} towns={len(m2.towns)} waypoints={len(m2.waypoints)}")

# Compare tile-by-tile
mismatches = 0
if set(m1.tiles.keys()) != set(m2.tiles.keys()):
    missing = set(m1.tiles.keys()) - set(m2.tiles.keys())
    extra = set(m2.tiles.keys()) - set(m1.tiles.keys())
    print(f"  TILE KEY MISMATCH: missing={len(missing)} extra={len(extra)}")
    mismatches += 1
else:
    for key, t1 in m1.tiles.items():
        t2 = m2.tiles[key]
        if t1.ground != t2.ground:
            print(f"  GROUND MISMATCH at {key}: {t1.ground} vs {t2.ground}")
            mismatches += 1
        if len(t1.items) != len(t2.items):
            print(f"  ITEM COUNT MISMATCH at {key}: {len(t1.items)} vs {len(t2.items)}")
            mismatches += 1
        else:
            for i1, i2 in zip(t1.items, t2.items):
                if i1.id != i2.id or i1.depot_id != i2.depot_id or i1.action_id != i2.action_id:
                    print(f"  ITEM MISMATCH at {key}: {i1} vs {i2}")
                    mismatches += 1

if m1.towns != m2.towns:
    print(f"  TOWNS MISMATCH: {m1.towns} vs {m2.towns}")
    mismatches += 1

if mismatches == 0:
    print("\nROUND-TRIP OK: all tiles/items/towns match after read -> write -> read.")
else:
    print(f"\nROUND-TRIP FOUND {mismatches} MISMATCHES.")
    sys.exit(1)
