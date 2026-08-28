"""
Generates a first full sketch of the world: 4 tiered biome arms (matching
the earlier design: North=ice, South=desert, East=jungle, West=dark) PLUS
one signature structure per hunt, each inspired by the #1 reference from
referencias-hunts-cidades.md:

  North -> Svargrond (blockhouse cabins + skull pillars)
  South -> Ankrahmun (a real sandstone pyramid, full 5x5 composite)
  East  -> Ab'Dendriel (giant trees + wood platform, treetop feel)
  West  -> Roshamuul/Grimvale (broken walls + black marble ruin)

Preserves the existing city core (around 1000,1000) and the depot
building (around 1030,1000) -- terrain generation skips those zones
entirely instead of overwriting them.
"""

import math
from otbm import read_otbm, write_otbm, OtbmItem

MAP_PATH = r"C:\Users\Pedro\Desktop\tibia-server\meu-mapa\meu-mapa.otbm"

Z = 7
CX, CY = 1000, 1000
SEED = 2026

TOWN_RADIUS = 15
ARM_LENGTH = 70
NEAR_WIDTH = 8
FAR_WIDTH = 30

# Exclusion zones: don't touch tiles already used by the city core / depot
EXCLUSIONS = [
    (985, 985, 1015, 1015),   # city core (temple, decorated plaza)
    (1018, 990, 1040, 1010),  # depot building
]

TIERS = {
    "north": [6580, 7062, 6869],   # snow -> frozen mud -> snowy mountain
    "south": [231, 982, 21477],    # sand -> dry earth -> lava rock soil
    "east":  [1019, 1020, 4691],   # jungle grass -> jungle dirt -> dark swamp
    "west":  [106, 10228, 10549],  # grass (dark) -> dark dirt -> darkest mud
}

DECOS = {
    "north": [3608, 7020, 7021, 7022],
    "south": [3642, 3643, 3644, 3645, 3646, 3648, 3650],
    "east":  [2700, 3614, 3615, 3616, 3621, 3622],
    "west":  [11969, 11970, 11963, 11964, 31114, 31116, 958],
}

GROUND_GRASS = 4515
GROUND_PLAZA = 436
GROUND_ROAD = 937


def simple_noise(x, y, seed):
    """Deterministic pseudo-noise in [-1, 1] without external deps."""
    n = math.sin(x * 12.9898 + y * 78.233 + seed * 0.017) * 43758.5453
    return (n - math.floor(n)) * 2 - 1


def in_exclusion(x, y):
    for x1, y1, x2, y2 in EXCLUSIONS:
        if x1 <= x <= x2 and y1 <= y <= y2:
            return True
    return False


def half_width_at(axis_dist):
    t = min(1.0, axis_dist / ARM_LENGTH)
    smooth = t * t * (3 - 2 * t)
    return NEAR_WIDTH + (FAR_WIDTH - NEAR_WIDTH) * smooth


def tier_ground(zone, axis_dist):
    t = axis_dist / ARM_LENGTH
    if t < 0.4:
        idx = 0
    elif t < 0.75:
        idx = 1
    else:
        idx = 2
    return TIERS[zone][idx]


def arm_ground(x, y):
    dx, dy = x - CX, y - CY
    n = simple_noise(x, y, SEED) * 3

    if dy < 0:
        axis_dist = -dy
        if axis_dist <= ARM_LENGTH and abs(dx) <= half_width_at(axis_dist) + n:
            return tier_ground("north", axis_dist), "north"
    if dy > 0:
        axis_dist = dy
        if axis_dist <= ARM_LENGTH and abs(dx) <= half_width_at(axis_dist) + n:
            return tier_ground("south", axis_dist), "south"
    if dx > 0:
        axis_dist = dx
        if axis_dist <= ARM_LENGTH and abs(dy) <= half_width_at(axis_dist) + n:
            return tier_ground("east", axis_dist), "east"
    if dx < 0:
        axis_dist = -dx
        if axis_dist <= ARM_LENGTH and abs(dy) <= half_width_at(axis_dist) + n:
            return tier_ground("west", axis_dist), "west"
    return None, None


def place_pyramid(m, anchor_x, anchor_y):
    """Ankrahmun-style sandstone pyramid -- exact 5x5 composite from RME's
    'pyramid template' doodad."""
    layout = {
        (0, 0): 2195, (1, 0): 1965, (2, 0): 1965, (3, 0): 1965, (4, 0): 2197,
        (0, 1): 1961, (1, 1): 2196, (2, 1): 1964, (3, 1): 2221, (4, 1): 1963,
        (0, 2): 1961, (1, 2): 1960,               (3, 2): 1962, (4, 2): 1963,
        (0, 3): 1961, (1, 3): 2219, (2, 3): 1966, (3, 3): 2218, (4, 3): 1963,
        (0, 4): 2193, (1, 4): 1967, (2, 4): 1967, (3, 4): 1967, (4, 4): 2191,
    }
    for (ox, oy), item_id in layout.items():
        x, y = anchor_x + ox, anchor_y + oy
        tile = m.get_or_create_tile(x, y, Z)
        if tile.ground is None:
            tile.ground = 231  # sand beneath the pyramid
        tile.items.append(OtbmItem(id=item_id))


def place_blockhouses(m, anchor_x, anchor_y):
    """Svargrond-style: small wooden cabins + skull pillars."""
    WALL_H, WALL_V, WALL_C, WALL_P = 6840, 6839, 6843, 6841
    FLOOR = 454  # svargrond wooden floor
    SKULL_PILLAR = 10841

    def cabin(x1, y1, size=4):
        x2, y2 = x1 + size - 1, y1 + size - 1
        for x in range(x1, x2 + 1):
            for y in range(y1, y2 + 1):
                tile = m.get_or_create_tile(x, y, Z)
                tile.ground = FLOOR
        for x in range(x1, x2 + 1):
            for y in (y1, y2):
                if x == x1 + size // 2 and y == y2:
                    continue  # door gap
                tile = m.get_or_create_tile(x, y, Z)
                corner = (x in (x1, x2))
                tile.items.append(OtbmItem(id=WALL_C if corner else WALL_H))
        for y in range(y1, y2 + 1):
            for x in (x1, x2):
                if (x, y) in ((x1, y1), (x2, y1), (x1, y2), (x2, y2)):
                    continue
                tile = m.get_or_create_tile(x, y, Z)
                tile.items.append(OtbmItem(id=WALL_V))

    cabin(anchor_x - 6, anchor_y - 2)
    cabin(anchor_x + 2, anchor_y - 2)

    for sx, sy in [(anchor_x - 1, anchor_y - 4), (anchor_x + 1, anchor_y - 4)]:
        tile = m.get_or_create_tile(sx, sy, Z)
        if tile.ground is None:
            tile.ground = 6580  # snow
        tile.items.append(OtbmItem(id=SKULL_PILLAR))


def place_tree_platform(m, anchor_x, anchor_y):
    """Ab'Dendriel-style: giant trees + a small wood platform, treetop feel."""
    GIANT_TREE = {(0, 0): 3773, (1, 0): 3775, (0, 1): 3774, (1, 1): 3776}
    PLATFORM_FLOOR = 408  # wooden floor

    trees = [(anchor_x - 6, anchor_y - 2), (anchor_x + 4, anchor_y - 3), (anchor_x - 2, anchor_y + 3)]
    for tx, ty in trees:
        for (ox, oy), item_id in GIANT_TREE.items():
            x, y = tx + ox, ty + oy
            tile = m.get_or_create_tile(x, y, Z)
            if tile.ground is None:
                tile.ground = 1019  # jungle grass
            tile.items.append(OtbmItem(id=item_id))

    # small wood platform between the trees, like a landing connected by "bridges"
    for x in range(anchor_x - 1, anchor_x + 3):
        for y in range(anchor_y, anchor_y + 3):
            tile = m.get_or_create_tile(x, y, Z)
            tile.ground = PLATFORM_FLOOR


def place_ruins(m, anchor_x, anchor_y):
    """Roshamuul/Grimvale-style: scattered broken walls on dark marble."""
    BROKEN_WALL = [6280, 6281, 6282, 6283]
    BLACK_MARBLE = 410
    STATUE_ANGEL = 2031  # reused as a dark shrine centerpiece

    for x in range(anchor_x - 4, anchor_x + 5):
        for y in range(anchor_y - 4, anchor_y + 5):
            tile = m.get_or_create_tile(x, y, Z)
            tile.ground = BLACK_MARBLE

    n = 0
    ring = [
        (anchor_x - 4, anchor_y - 4), (anchor_x, anchor_y - 4), (anchor_x + 4, anchor_y - 4),
        (anchor_x - 4, anchor_y), (anchor_x + 4, anchor_y),
        (anchor_x - 4, anchor_y + 4), (anchor_x, anchor_y + 4), (anchor_x + 4, anchor_y + 4),
        (anchor_x - 2, anchor_y - 3), (anchor_x + 3, anchor_y + 2),
    ]
    for x, y in ring:
        tile = m.get_or_create_tile(x, y, Z)
        tile.items.append(OtbmItem(id=BROKEN_WALL[n % len(BROKEN_WALL)]))
        n += 1

    tile = m.get_or_create_tile(anchor_x, anchor_y, Z)
    tile.items.append(OtbmItem(id=STATUE_ANGEL))


def main():
    print(f"Reading {MAP_PATH} ...")
    m = read_otbm(MAP_PATH)
    print(f"  {len(m.tiles)} tiles before changes")

    placed = {"north": 0, "south": 0, "east": 0, "west": 0}
    outer = ARM_LENGTH + 5
    for dx in range(-outer, outer + 1):
        for dy in range(-outer, outer + 1):
            x, y = CX + dx, CY + dy
            if in_exclusion(x, y):
                continue

            ground_id, zone = arm_ground(x, y)
            if ground_id is None:
                continue

            tile = m.get_or_create_tile(x, y, Z)
            tile.ground = ground_id
            placed[zone] += 1

            # sparse, varied decoration (about 1 in 30 tiles)
            if int(simple_noise(x, y, SEED + 500) * 1000) % 30 == 0:
                palette = DECOS[zone]
                idx = abs(int(simple_noise(x, y, SEED + 900) * 1000)) % len(palette)
                tile.items.append(OtbmItem(id=palette[idx]))

    print(f"  terrain placed: {placed}")

    # ------------------------------------------------------------------
    # Signature structures, placed inside each arm, past the town radius
    # but well before the exclusion zones' edges.
    # ------------------------------------------------------------------
    place_blockhouses(m, CX, CY - 45)   # North / Svargrond
    print("  placed Svargrond-style blockhouses (North)")

    place_pyramid(m, CX - 2, CY + 45)   # South / Ankrahmun
    print("  placed Ankrahmun-style pyramid (South)")

    place_tree_platform(m, CX + 50, CY)  # East / Ab'Dendriel
    print("  placed Ab'Dendriel-style tree platform (East)")

    place_ruins(m, CX - 50, CY)         # West / Roshamuul-Grimvale
    print("  placed Roshamuul/Grimvale-style ruins (West)")

    print(f"  {len(m.tiles)} tiles after changes")
    print(f"Writing back to {MAP_PATH} ...")
    write_otbm(m, MAP_PATH)
    print("Done!")


if __name__ == "__main__":
    main()
