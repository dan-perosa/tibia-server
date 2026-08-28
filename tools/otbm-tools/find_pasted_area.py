"""
Compares mapa 2.0 tile-by-tile against the downloaded reference map to find
exactly which tiles were accidentally pasted (identical ground+items at the
same x,y,z coordinate = came from the reference map).
"""

from otbm import read_otbm

MINE = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\mapa 2.0.otbm"
REFERENCE = r"C:\Users\Pedro\Desktop\tibia-server\Nova pasta\worldArquitoTibiano\world\otservbr.otbm"

print(f"Reading {MINE} ...")
mine = read_otbm(MINE)
print(f"  {len(mine.tiles)} tiles")

print(f"Reading {REFERENCE} ... (this is big, will take a while)")
ref = read_otbm(REFERENCE)
print(f"  {len(ref.tiles)} tiles")

pasted = []
original = []
for key, tile in mine.tiles.items():
    ref_tile = ref.tiles.get(key)
    if ref_tile and ref_tile.ground == tile.ground and [i.id for i in ref_tile.items] == [i.id for i in tile.items]:
        pasted.append(key)
    else:
        original.append(key)

print(f"\npasted (matches reference map exactly): {len(pasted)}")
print(f"original (Pedro's own, doesn't match reference): {len(original)}")

if pasted:
    xs = [p[0] for p in pasted]
    ys = [p[1] for p in pasted]
    print(f"pasted bounds: x {min(xs)}-{max(xs)}  y {min(ys)}-{max(ys)}")

if original:
    xs = [p[0] for p in original]
    ys = [p[1] for p in original]
    print(f"original bounds: x {min(xs)}-{max(xs)}  y {min(ys)}-{max(ys)}")
    print("\nsample of original (Pedro's own) tiles:")
    for key in sorted(original)[:30]:
        t = mine.tiles[key]
        print(f"  {key} ground={t.ground} items={[i.id for i in t.items]}")
