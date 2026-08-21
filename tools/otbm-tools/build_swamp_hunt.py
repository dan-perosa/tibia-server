"""
Builds a level-200+ swamp hunting ground west of the city (x<=916, the
westmost edge of the whole map -- verified empty on every floor before
writing), by extending the existing river into an irregular lake/marsh,
with a winding rock cave (drunkard's-walk carve, not a rectangle) at the
far end holding the strongest monsters.

Ground fill uses the same item ids/weights as RME's own brush definitions
(rme/canary-map-editor-v4.0-windows/data/materials/brushs/grounds.xml),
so the borders these brushes declare (borders.xml) will apply correctly
when you run Edit > Border Options > Borderize Selection (Ctrl+B) over
the new area in RME. This script intentionally does NOT hand-place any
border/wall item -- picking the right one of a ~46-variant border set by
hand is exactly what broke the first version (an edge-only variant used
on all 4 sides of a rectangle). Only plain ground ids are written here.

Aborts instead of overwriting if it ever finds an existing tile at a
coordinate it's about to write.
"""

import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from otbm import OtbmItem, OtbmTile, read_otbm, write_otbm  # noqa: E402

MAP_PATH = Path(__file__).resolve().parents[2] / "meu-mapa" / "MAPA OFICIAL DE TRABALHO.otbm"
MONSTER_XML_PATH = MAP_PATH.with_name(MAP_PATH.stem + "-monster.xml")

Z = 7
RNG = random.Random(42)

# --- ground brushes, mirrored from RME's grounds.xml (id, relative chance) ---
SWAMP = [(4680, 220), (4681, 33), (4682, 33), (4683, 34), (4684, 33), (4685, 33),
         (4687, 33), (4688, 33), (4689, 34), (4690, 33), (4738, 33), (4739, 33),
         (4740, 34), (4741, 33), (4742, 12), (4743, 12), (4744, 12)]
SEA = [(4597, 3), (4598, 1), (4599, 1), (4600, 1), (4601, 1), (4602, 1),
       (4609, 1), (4610, 1), (4611, 1), (4612, 1), (4613, 1), (4614, 1)]
CAVE_FLOOR = [(351, 6), (352, 1), (353, 1), (354, 1), (355, 1),
              (7756, 2500), (8770, 1000), (10480, 1000)]
GROTTO_ROCK = [(13594, 2500), (13644, 2500), (13645, 2500)]
DECOR_IDS = [3688, 3689, 9686]


def weighted_choice(pairs):
    total = sum(w for _, w in pairs)
    r = RNG.uniform(0, total)
    acc = 0
    for item_id, w in pairs:
        acc += w
        if r <= acc:
            return item_id
    return pairs[-1][0]


# --- region geometry ---
LAKE_CENTER = (818, 1087)
LAKE_BASE_R = 34
LAKE_HARMONICS = [(6, 3, 0.4), (4, 5, 2.1), (3, 2, 4.7)]

MARSH_BASE_R = 55
MARSH_HARMONICS = [(14, 2, 1.1), (9, 4, 3.0), (6, 6, 5.2)]
BAYS = [(RNG.uniform(0, 2 * math.pi), RNG.uniform(28, 42), RNG.uniform(14, 22)) for _ in range(4)]

CHANNEL_X0, CHANNEL_X1 = 850, 917  # x1 exclusive: 917 is the existing river tile
CHANNEL_HALFWIDTH = 45
CHANNEL_Y_CENTER = 1087

ROCK_X0, ROCK_X1 = 685, 782
ROCK_Y0, ROCK_Y1 = 1015, 1155

BOX_X0, BOX_X1 = 685, 920
BOX_Y0, BOX_Y1 = 1010, 1160


def radial(base, harmonics, angle):
    r = base
    for amp, freq, phase in harmonics:
        r += amp * math.sin(freq * angle + phase)
    return r


def is_water(x, y):
    if CHANNEL_X0 <= x < CHANNEL_X1:
        y0 = CHANNEL_Y_CENTER + 8 * math.sin((x - CHANNEL_X0) * 0.12)
        if abs(y - y0) <= CHANNEL_HALFWIDTH:
            return True
    dx, dy = x - LAKE_CENTER[0], y - LAKE_CENTER[1]
    d = math.hypot(dx, dy)
    ang = math.atan2(dy, dx)
    return d <= radial(LAKE_BASE_R, LAKE_HARMONICS, ang)


def is_marsh(x, y):
    if is_water(x, y):
        return False
    dx, dy = x - LAKE_CENTER[0], y - LAKE_CENTER[1]
    d = math.hypot(dx, dy)
    ang = math.atan2(dy, dx)
    if d <= radial(MARSH_BASE_R, MARSH_HARMONICS, ang):
        return True
    for bay_ang, bay_dist, bay_r in BAYS:
        bx = LAKE_CENTER[0] + bay_dist * math.cos(bay_ang)
        by = LAKE_CENTER[1] + bay_dist * math.sin(bay_ang)
        if math.hypot(x - bx, y - by) <= bay_r:
            return True
    if CHANNEL_X0 - 14 <= x < CHANNEL_X1:
        y0 = CHANNEL_Y_CENTER + 8 * math.sin((x - CHANNEL_X0) * 0.12)
        if abs(y - y0) <= CHANNEL_HALFWIDTH + 13:
            return True
    return False


def carve_cave(start, n_steps):
    """Drunkard's walk carving a winding tunnel with a few rounded rooms.
    Bounces off the rock rectangle's edges (instead of sticking to them)
    so the full n_steps keep winding back and forth through the space."""
    margin = 6
    x, y = float(start[0]), float(start[1])
    heading = math.pi  # heading west
    carved = set()
    for i in range(n_steps):
        heading += RNG.uniform(-0.6, 0.6)
        x += math.cos(heading) * 1.6
        y += math.sin(heading) * 1.6
        if x < ROCK_X0 + margin:
            x = ROCK_X0 + margin
            heading = math.pi - heading
        elif x > ROCK_X1 - margin:
            x = ROCK_X1 - margin
            heading = math.pi - heading
        if y < ROCK_Y0 + margin:
            y = ROCK_Y0 + margin
            heading = -heading
        elif y > ROCK_Y1 - margin:
            y = ROCK_Y1 - margin
            heading = -heading
        ix, iy = round(x), round(y)
        radius = RNG.randint(3, 5)
        if i % 11 == 0:
            radius = RNG.randint(7, 10)  # a room
        for cx in range(ix - radius, ix + radius + 1):
            for cy in range(iy - radius, iy + radius + 1):
                if (cx - ix) ** 2 + (cy - iy) ** 2 <= radius * radius:
                    carved.add((cx, cy))
    return carved


def carve_connector(x0, x1, y_center):
    """Guaranteed thick bridge from the marsh edge into the rock interior,
    so the random-walk cave always connects regardless of where it wanders."""
    carved = set()
    for x in range(x0, x1 - 1, -1):
        y0 = y_center + 4 * math.sin((x - x0) * 0.2)
        radius = RNG.randint(5, 7)
        iy = round(y0)
        for cx in range(x - radius, x + radius + 1):
            for cy in range(iy - radius, iy + radius + 1):
                if (cx - x) ** 2 + (cy - iy) ** 2 <= radius * radius:
                    carved.add((cx, cy))
    return carved


def build_regions():
    water, marsh = set(), set()
    for x in range(BOX_X0, BOX_X1):
        for y in range(BOX_Y0, BOX_Y1):
            if is_water(x, y):
                water.add((x, y))
            elif is_marsh(x, y):
                marsh.add((x, y))

    connector = carve_connector(781, 754, 1085)
    cave = connector | carve_cave((754, 1085), 220)
    cave -= water
    cave -= marsh

    rock = set()
    for x in range(ROCK_X0, ROCK_X1):
        for y in range(ROCK_Y0, ROCK_Y1):
            if (x, y) not in cave and (x, y) not in water and (x, y) not in marsh:
                rock.add((x, y))

    return water, marsh, cave, rock


def write_tiles(m, water, marsh, cave, rock):
    planned = {}
    for x, y in water:
        planned[(x, y, Z)] = "water"
    for x, y in marsh:
        planned[(x, y, Z)] = "marsh"
    for x, y in cave:
        planned[(x, y, Z)] = "cave"
    for x, y in rock:
        planned[(x, y, Z)] = "rock"

    conflicts = [k for k in planned if k in m.tiles]
    if conflicts:
        raise SystemExit(f"ABORT: {len(conflicts)} planned tiles already exist, e.g. {conflicts[:5]}")

    for (x, y, z), kind in planned.items():
        items = []
        if kind == "water":
            ground = weighted_choice(SEA)
        elif kind == "marsh":
            ground = weighted_choice(SWAMP)
            # Decoration items (swamp reed/lily/grass) were dropped: they rendered
            # as solid black squares in RME (missing client sprite), even though
            # they're validly named in items.xml -- see SKILL.md, "id validity"
            # rule. Re-add only after confirming a given id renders in a live
            # RME check.
        elif kind == "cave":
            ground = weighted_choice(CAVE_FLOOR)
        else:  # rock
            ground = weighted_choice(GROTTO_ROCK)
        m.tiles[(x, y, z)] = OtbmTile(x=x, y=y, z=z, ground=ground, items=items)

    return planned


def spawn_block(entries):
    cx, cy, cz = entries[0][1], entries[0][2], Z
    lines = [f'\t<monster centerx="{cx}" centery="{cy}" centerz="{cz}" radius="1">\n']
    for name, x, y, _ in entries:
        lines.append(f'\t\t<monster name="{name}" x="{x - cx}" y="{y - cy}" z="{cz}" spawntime="60" />\n')
    lines.append("\t</monster>\n")
    return "".join(lines)


def scatter_spawns(cells, names, min_spacing, cluster_chance=0.35):
    cells = list(cells)
    RNG.shuffle(cells)
    chosen = []
    for cx, cy in cells:
        if all((cx - ox) ** 2 + (cy - oy) ** 2 >= min_spacing ** 2 for ox, oy in chosen):
            chosen.append((cx, cy))

    blocks = []
    for i, (cx, cy) in enumerate(chosen):
        name = names[i % len(names)]
        entries = [(name, cx, cy, Z)]
        if RNG.random() < cluster_chance:
            ox, oy = cx + RNG.choice([-1, 1]), cy + RNG.choice([-1, 1])
            entries.append((names[(i + 1) % len(names)], ox, oy, Z))
        blocks.append(spawn_block(entries))
    return blocks


def build_spawns(marsh, cave):
    blocks = []
    filler = [(x, y) for x, y in marsh]
    blocks += scatter_spawns(filler, ["Marsh Stalker", "Swampling"], min_spacing=6)

    wet_band = [(x, y) for x, y in marsh
                if radial(LAKE_BASE_R, LAKE_HARMONICS, math.atan2(y - LAKE_CENTER[1], x - LAKE_CENTER[0])) <=
                math.hypot(x - LAKE_CENTER[0], y - LAKE_CENTER[1]) <=
                radial(LAKE_BASE_R, LAKE_HARMONICS, math.atan2(y - LAKE_CENTER[1], x - LAKE_CENTER[0])) + 12]
    blocks += scatter_spawns(wet_band, ["Hydra"], min_spacing=9)

    blocks += scatter_spawns(list(cave), ["Werecrocodile", "Feral Werecrocodile"], min_spacing=7, cluster_chance=0.15)
    return blocks


def append_spawns(blocks):
    text = MONSTER_XML_PATH.read_text(encoding="utf-8")
    marker = "</monsters>"
    if marker not in text:
        raise SystemExit(f"ABORT: could not find {marker!r} in {MONSTER_XML_PATH}")
    text = text.replace(marker, "".join(blocks) + marker)
    MONSTER_XML_PATH.write_text(text, encoding="utf-8")


def main():
    m = read_otbm(str(MAP_PATH))
    water, marsh, cave, rock = build_regions()
    planned = write_tiles(m, water, marsh, cave, rock)
    write_otbm(m, str(MAP_PATH))

    blocks = build_spawns(marsh, cave)
    append_spawns(blocks)

    counts = {"water": len(water), "marsh": len(marsh), "cave": len(cave), "rock": len(rock)}
    print("Tiles placed:", counts, "total:", len(planned))
    print("Spawn blocks appended:", len(blocks))


if __name__ == "__main__":
    main()
