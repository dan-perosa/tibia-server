---
name: tibia-map-building
description: Build or edit areas of this Canary/OTBM Tibia map by script (hunting grounds, caves, terrain) instead of by hand in RME. Covers the OTBM reader/writer, the safety checks that must run before writing, where to get correct ground/border/wall item ids (RME's own bundled data files), how to make shapes organic instead of geometric, monster spawn XML format, and the mistakes already made once so they aren't repeated. Use whenever asked to add/modify map terrain, hunting areas, or monster spawns via script for this project.
---

# Building Tibia map content by script (this project)

## Preferred method: RME's own built-in Lua scripting API

**Use this instead of raw OTBM editing whenever the terrain needs correct
walls/borders or monster spawns.** This project's RME build
(`rme/canary-map-editor-v4.0-windows/`) ships a full Lua scripting engine —
`scripts/*.lua` files, run from **Scripts → Script Manager** inside RME
(list of discovered scripts + Run/Reload/Open-folder buttons; the menu is
empty in `data/menubar.xml` and gets populated at runtime). It exposes the
editor's own brush/border/spawn engine directly, which is strictly better
than hand-writing item ids into the `.otbm`:

- `tile:applyBrush(brushName, autoBorder)` — draws a **named** ground/wall
  brush (resolved the same way the palette does) instead of a raw item id.
  Pass `false` for `autoBorder` while painting a whole region (borderizing
  tile-by-tile before neighbors exist gives wrong results), then...
- `tile:borderize()` — runs the real border engine (`GroundBrush::doBorders`
  in `source/tile.cpp`/`ground_brush.cpp`) on that tile against its current
  neighbors. Call this over the whole padded region **after** all painting
  is done, matching the demo scripts' own "Pass 1: paint, Pass 2: borderize"
  structure.
- `map:getTile(x,y,z)` → `nil` if nothing there (safety-check reads),
  `map:getOrCreateTile(x,y,z)` → creates-or-returns (writes).
- `tile:setSpawn(size)` + `tile:setCreature(name, spawnTime, direction?)` —
  places a monster + its spawn radius directly; RME writes this into the
  sibling `-monster.xml` on save. No manual XML string-building needed.
- `algo.generateCave(width, height, {fillProbability, iterations,
  birthLimit, deathLimit, seed})` — cellular automata, returns a
  `grid[y][x]` of `0`/`1`. This is what actually produces the winding,
  loopy, room-and-corridor cave shape real hunting grounds have — far
  better than a hand-rolled drunkard's walk (see below).
  **`birthLimit`/`deathLimit` are easy to get badly wrong and this one is
  cheap to verify yourself first** — unlike the border algorithm, this rule
  is short, fully specified, and has no engine-internal state, so port it to
  a ~20-line Python snippet and sweep parameters before recommending any to
  the user. `birthLimit=4, deathLimit=3` (the values used in the shipped
  `cave_generator.lua` demo's iterations=4 default, but pushed to
  `iterations=5` in this project's first attempt) runs away to ~85-95%
  solid wall — confirmed both by the in-RME log (`caveWall=11203` vs
  `caveFloor=1057`, i.e. 91%) and by reproducing the exact same rule in
  Python from `source/lua/lua_api_algo.cpp`'s `generateCave` (grid edges
  always wall, interior seeded at `fillProbability`, `deathLimit`-many
  wall-neighbors keeps a wall alive, `birthLimit`-many turns a floor cell
  into a wall). `fillProbability=0.45, iterations=4, birthLimit=5,
  deathLimit=4` converges to ~35% wall with 99% of the floor in one
  connected region (verified by flood-fill in the same script) — use that
  as the starting point, not the original demo's `birthLimit=4,
  deathLimit=3` default (still visible in `build_cave.lua`'s dialog
  defaults, now exposed as fields instead of hardcoded).
- `noise.simplex(x, y, seed, frequency)` → float in `[-1, 1]`. Use to
  distort a shape's radius for organic coastlines/blobs (see
  `scripts/build_island.lua`'s pattern) instead of hand-picked sine
  harmonics. `noise.fbm(x, y, seed, {frequency, octaves, lacunarity, gain})`
  is the smoother multi-octave version — good for *texture* variety on
  ground that's already walkable, **not** for deciding what's blocking
  (see mistake #6).
- `geo.bezierCurve(controlPoints, steps)` — rivers/paths (see
  `scripts/build_river.lua`). `geo.bresenhamLine(x1,y1,x2,y2)` — a
  straight connector (see `scripts/build_street.lua`).
  `geo.poissonDiskSampling(x1,y1,x2,y2,minDistance,{seed})` and
  `geo.randomScatter(x1,y1,x2,y2,count,{seed,minDistance})` — built-in
  even/random point spacing, better than hand-rolling the shuffle+greedy
  loop from scratch (see `scripts/build_forest.lua`).
  `geo.randomScatter`/`algo.voronoi` together also drive
  `scripts/build_city_lots.lua`'s "border between two Voronoi regions =
  street, interior = lot" trick — worth reusing for any future
  city/village layout.
- `Brushes.get(name)` / `Brushes.getNames()` — look up or enumerate brushes
  by exact name if unsure one exists.
- `creatureExists(name)` — a bare global function (not namespaced under
  anything), returns whether a monster type is actually registered.
  `tile:setCreature(name, ...)` does **not** error on a bad name — it
  silently creates a placeholder "missing monster type" via
  `g_monsters.addMissingMonsterType` (`source/lua/lua_api_tile.cpp`). Call
  `creatureExists(name)` and abort before `setCreature` instead of
  discovering the placeholder later.
- `app.transaction(label, function() ... end)` — groups edits into one
  undo step; wrap each logical pass (terrain, then monsters) in its own.
- `app.hasMap()`, `app.setCameraPosition(x,y,z)`.

**No headless/CLI execution exists** — checked `source/application.cpp`:
the only command-line argument it accepts is a map file path to open, there
is no `--run-script` flag. A script can only be run by a human opening RME
and clicking Run in the Script Manager. Write the `.lua` file into
`rme/canary-map-editor-v4.0-windows/scripts/`, tell the user which one to
run and what to expect it to print, and have them save (Ctrl+S) afterward.

See `rme/canary-map-editor-v4.0-windows/scripts/build_swamp_hunt.lua` for a
full worked, **corrected** example (river extension + noise-distorted lake/
marsh + cellular-automata cave + Poisson-disk monster scatter with a
wall-adjacency filter, plan-then-conflict-check safety pattern) — this
replaced an earlier Python/raw-item-id version of the same hunt that got
both the wall directions and the organic shape wrong (see "Mistakes already
made"). **Copy this file's patterns for the next hunt, don't start from the
bare demo scripts** — it already has both fixes below baked in, so a fresh
run on a new area shouldn't need a follow-up fix script at all:
1. `algo.generateCave` needs `birthLimit=5, deathLimit=4` (not the demo's
   `4`/`3`) or it runs away to ~90%+ solid wall — see "Mistakes already
   made" below for how this was found and verified.
2. Any spawn placed on cave floor must pass `isAwayFromWalls(x,y)` (cell +
   all 4 orthogonal neighbors non-blocking), or it visually reads as
   "inside the wall" from the sprite overhang.

The one-off fix scripts (`fix_swamp_hunt_cave.lua`,
`fix_swamp_hunt_monster_placement.lua`) stay in the folder as a record of
what broke and how it was patched without redoing the whole hunt — they're
not templates for new work, `build_swamp_hunt.lua` already has both fixes.

**When to still use the Python `otbm.py` route below**: read-only analysis
(ground-id frequency, bounding-box emptiness checks, ASCII previews) — it's
faster to iterate on without opening the GUI. Don't use it to *write*
borders, walls, or spawns anymore; that's what produced both mistakes below.


This project edits `meu-mapa/MAPA OFICIAL DE TRABALHO.otbm` (and its sibling
`-monster.xml`/`-npc.xml`/`-house.xml`/`-zones.xml` files) directly with
Python, as an alternative to hand-editing in RME. This skill is the
distilled result of actually doing this once, including two visible
mistakes and their fixes — read the "Mistakes already made" section before
writing any new generator script.

## The tool: `tools/otbm-tools/otbm.py`

A from-scratch OTBM v5 reader/writer (matches this project's RME build,
"Canary's Map Editor 4.0"). Key facts:

- `read_otbm(path) -> OtbmMap`, `write_otbm(map_, path)`.
- `OtbmMap.tiles` is a **dict** keyed by `(x, y, z)` tuples, not a list —
  iterate `.tiles.values()`, not `.tiles`.
- `OtbmTile(x, y, z, house_id=None, flags=0, ground=None, items=[], zones=[])`
  — `ground` is a plain `int` item id (or `None`), `items` is a list of
  `OtbmItem`.
- `OtbmItem(id, count=None, action_id=None, unique_id=None, text=None, ...)`
  — only `id` is required.
- Does **not** support container item children (fine for terrain/building
  work, not for pre-filled containers).
- Run scripts with the real Python (Git Bash's `python3` hits the Windows
  Store stub on this machine): `/c/Python312/python.exe your_script.py`,
  with `sys.path.insert(0, "tools/otbm-tools")` before `from otbm import ...`.

## Mandatory workflow: back up, plan, check, write

Every generator script must follow this shape:

1. **Back up first**, always, before the first run of a session:
   `cp "meu-mapa/MAPA OFICIAL DE TRABALHO.otbm" "....otbm.bak"` (and the
   `-monster.xml` too if you'll touch spawns). These files are gitignored/
   uncommitted work-in-progress — there is no git safety net.
2. **Compute the full set of planned `(x, y, z)` tiles first**, as a dict or
   set, before touching `m.tiles`.
3. **Abort instead of overwriting** if any planned coordinate already
   exists in `m.tiles`:
   ```python
   conflicts = [k for k in planned if k in m.tiles]
   if conflicts:
       raise SystemExit(f"ABORT: {len(conflicts)} planned tiles already exist, e.g. {conflicts[:5]}")
   ```
   This is what actually satisfies "don't overlap existing content" — not a
   visual guess, a real check against the loaded map.
4. To find a safe empty region before designing anything, query the real
   file: per-floor tile counts, x/y bounding box, and "is this candidate box
   empty on ANY floor" via a quick inline query (see pattern below). This
   project's west edge (`x<917`, the true edge of everything ever placed) is
   already known to be empty and was used for the current swamp/cave hunt.
   ```python
   box = [t for t in m.tiles.values() if X0 <= t.x <= X1 and Y0 <= t.y <= Y1]
   print(len(box))  # 0 means genuinely empty on every floor in that box
   ```
5. **Rerunning the script must be idempotent-safe**: restore from `.bak`
   before iterating on a new version, don't try to layer v2 on top of v1's
   already-written tiles (the conflict check will (correctly) abort).
6. **Sanity-check the shape before declaring done**, with a cheap ASCII
   density/kind map (bucket the region into NxN cells, tag each by
   ground-id set membership, print rows). This catches structural bugs
   (wrong bounding box, disconnected regions, degenerate shapes) cheaply.
   **It does not catch rendering bugs** — see next section.

## Mistakes already made (read before reusing patterns)

### 1. Hand-picking one variant from a directional border set → broken wall
The first hunting-ground attempt filled a rectangular room's walls with a
single item id (`4457`, "mountain") on all four sides. That id is only the
**east-edge piece** of a ~46-variant directional border set
(`borders.xml` border id 29: `n`→4460, `e`→4457, `s`→4458, `w`→4461, plus
separate corner ids elsewhere). Using one edge-piece on all sides produced a
broken fence/hatch texture, not a wall.

**Rule going forward: never hand-place a single id from a border/wall set
across multiple directions.** Border and wall items are direction-specific
by construction. There are exactly two safe ways to get them right:
- Write only **plain ground ids** (no border/wall items at all) for the
  fill, then have the user run RME's own border engine over the selection
  (see "Delegate borders to RME" below) — what this project does now.
- Or, if a *wall brush* is genuinely needed (a constructed room, not a
  natural cave — see "ground-fill vs wall-brush" below), look up its
  `horizontal`/`vertical`/`corner`/`pole` pieces in
  `rme/canary-map-editor-v4.0-windows/data/materials/brushs/walls.xml` and
  place the piece that matches that wall segment's actual orientation
  (horizontal run vs vertical run vs corner vs single pole) — never one
  piece everywhere.

### 2. Trusting `items.xml` presence as proof an id renders → black squares
The swamp/cave rebuild scattered small decoration items (`swamp reed` 3688,
`swamp lily` 3689, `swamp grass` 9686) on ~8% of marsh tiles. They're validly
named in `data/items/items.xml`. They still showed up as solid black squares
in RME — items.xml only proves the **server** accepts the id; it says
nothing about whether the **client asset catalog** RME loaded actually has a
sprite for it. A solid black tile in RME means "missing sprite," full stop —
if it's the ground id that's missing, the whole tile blacks out (no layer
underneath to fall back to); if it's a decoration item on otherwise-good
ground, only that item's black box shows.

**Rule going forward: an id is only "safe" once one of these is true**
(in order of preference):
1. It's already used somewhere on the *existing* map (confirmed live/in
   production — check via a ground-id frequency scan of the original file).
2. The user has visually confirmed it renders correctly in RME, in this
   session.
3. Neither — then say so explicitly, use it sparingly, and expect to need
   a correction round after the user looks at it. Don't present unverified
   ids as if they were as safe as (1) or (2).

When something renders as black in a user's screenshot, don't just swap in
another guess — ask them to click/hover the tile in RME (status bar or
right-click → properties shows the exact item id) so the next fix is based
on a fact, not another guess.

### 3. Guessing a Lua brush name from an item's name → silent no-op
`tile:applyBrush(name, ...)` fails **silently** (returns `false`, no error,
no print) if `name` isn't a registered brush — it does not fall back to
anything close. This bit a draft of the "10 hunts" batch: the item at
x=947 on the original map is literally named `"dirt wall"` in
`items.xml`, so that seemed like an obviously-safe brush name to reuse for
a new wall — except it isn't a wall-type brush in RME at all, it's
registered as a **carpet** (`brushs/doodads.xml`, `<carpet align="e" id="5636"/>`),
and `"dirt floor"` isn't a registered brush name either (that dirt-floor
item is only reachable via the `"cave"` ground brush, under a different
name). Both would have produced a completely blank, wall-less "fortress."

**Rule going forward: never infer a brush name from an item's `name=`
attribute in `items.xml`.** Grep the actual brush definition first —
`grep -n '<brush name="' rme/.../data/materials/brushs/grounds.xml` (or
`walls.xml`) — and use exactly that string. Better yet, make the script
self-check: before touching the map, loop every brush name it's about to
use through `Brushes.get(name)` and abort with a clear list of whichever
ones come back `nil`, instead of finding out from a screenshot that a whole
region came out blank (see the `USED_BRUSHES` validation block at the top
of `scripts/build_ten_hunts.lua`). The same applies to monster names for
`tile:setCreature()`: don't title-case the filename and assume it matches —
grep `Game.createMonsterType("...")` in the actual `.lua` file and copy
that exact string; an unregistered name doesn't error either, it silently
creates a placeholder "missing monster type" via
`g_monsters.addMissingMonsterType`.

### 4. Perfect geometric shapes read as lifeless
A perfect circle lake, a perfect rectangle room, a dead-straight corridor,
and monsters on a fixed grid all look artificial next to a real Tibia hunting
ground (winding paths, irregular room shapes, monsters in loose organic
clusters). Real ones have bays, dead ends, rooms of varied size, and no
straight edges longer than a few tiles. See "Organic shape recipes" below —
always reach for these instead of `math.hypot(...) <= R` on its own.

### 5. Placing several zones on a grid without checking the map's header bounds
Planning a batch of N spaced-out hunts on a grid is easy to get right on
spacing (gaps between zones) while missing that the *edge* of the grid runs
past the map's declared `width`/`height` in `OtbmMap` (2048x2048 in this
project, i.e. valid x/y is 0-2047). This actually happened: a batch of 20
hunts on a 4-column grid had its rightmost column's larger zones (some
+100 tiles from center) computed out to x≈2054-2075 before anyone checked —
past the boundary the server likely allocates arrays against. Caught by
recomputing every zone's exact bounding box (not just eyeballing "column
center + typical half-width") and comparing the max against 2047, then
shifting the whole grid 50 tiles to restore margin.

**Rule going forward**: after placing N zones on a grid, compute every
zone's *actual* min/max x and y from its real half-width/half-height (they
won't be uniform if sizes vary, which they should per mistake #4's spirit)
and confirm the extreme corners stay inside `[0, width-1] x [0, height-1]`
from the map header — not just "gap between neighbors > 0."

### 6. Continuous noise (fbm) makes great terrain texture, bad wall geometry
The "Cliff Canyon" experiment classified each tile purely from where it
landed on a raw `noise.fbm` elevation field (`elevation > 0.28 → rock`).
Terrain *texture* variety (the grass/earth split from a second moisture
field) read well — user confirmed "a variedade de terreno melhorou." The
rock/wall geometry did not — user confirmed "a questão das paredes ficou
bem errada." The reason: a raw noise threshold has no neighbor-awareness,
so its rock/not-rock boundary can be an arbitrarily thin, jagged,
disconnected contour — single-tile slivers of rock, or thin walkable
corridors slicing through what should be a solid cliff face — with none of
the "chunky, connected blob" guarantee that cellular automata's
neighbor-counting rule provides by construction.

**Rule going forward**: use continuous noise fields (fbm/simplex) for
*texture variety on ground that is already walkable* (which ground-brush
variant a tile gets, moisture-driven color/type splits) — never to decide
*whether a tile is blocking*. Blocking/wall regions need a
connectivity-aware method: `algo.generateCave` (cellular automata),
`algo.generateDungeon`/`generateMaze` (explicit rooms/corridors), or a
noise-distorted-radius blob (mistake #4's organic recipe, which is still a
smooth single boundary, not a jagged raw-threshold contour). If a hunt
wants both continuous ground texture AND real cliffs/walls, generate the
wall layer with one of those connectivity-aware methods first, then
layer the noise-driven texture only on the cells that method left open.

### 7. `Dialog:show()` returns on X-close too — generation ran with defaults
Closing a script's parameter dialog with the window's X button still lets
execution continue past `dlg:show()`, using whatever was in the fields at
that moment (the defaults, if nothing was edited) — there is no built-in
distinction between "user clicked Generate" and "user closed the window."
This actually happened: the user clicked X intending to cancel, and the
city-lot script generated anyway with default values.

**Rule going forward**: every dialog-driven generator script needs its own
cancel flag — set it only inside the confirm button's `onclick`, and check
it right after `dlg:show()`, aborting before touching the map if it's
still false:
```lua
local confirmed = false
dlg:button({ id = "go", text = "Generate", onclick = function(d)
	confirmed = true
	d:close()
end })
dlg:show()
if not confirmed then
	print("[Label] Cancelled -- dialog was closed without clicking Generate.")
	return
end
```
Add a label near the button telling the user X cancels, so this is
discoverable rather than surprising.

### 8. A shipped demo's hardcoded ids are for *someone else's* server
The RME install ships with several demo generator scripts
(`cave_generator.lua`, `island_generator.lua`, etc. — since replaced by
this project's `build_*.lua` versions) that hardcode raw item ids with
comments like "adjust for your server version." Taking that literally: the
Island demo's `ITEM_SWORD = 2376` is a **red cushioned chair** on this
server, not a sword, and its tree/flower ids were the same
cobwebs/mossy-wall mixup already found in the Forest demo (mistake #3).
None of these demos' raw ids can be trusted without checking
`data/items/items.xml` for this exact project first — "it's a shipped
demo" carries no more authority than any other guess. Prefer a real
brush name (`Brushes.get`) over a raw id wherever a doodad brush exists;
only fall back to a verified raw `addItem(id)` for single non-brush props
(a sword, a sign) after confirming the id's `name=` attribute in
`items.xml` actually matches.

### 9. "Contain" generators vs "connect" generators need different safety
A cave/dungeon/maze/island generator is self-contained — any existing
tile inside its target box is a real conflict, so it should hard-abort
(mistakes #1-#8's pattern). A river or street generator is different on
purpose: its whole job is to run *through* space that may legitimately
border or touch already-built things (connecting two existing hunts, a
road reaching a city gate). Hard-aborting on the first existing tile
would make the tool useless for its actual purpose. For these, **skip**
tiles that already have content (never overwrite) and report both a
painted-count and a skipped-count, instead of aborting the whole
operation. `build_river.lua`/`build_street.lua` use this; every
self-contained area generator in this project still hard-aborts.

## Ground-fill vs wall-brush: two different ways to make something solid

RME has two structurally different ways to represent "you can't walk here":

- **A blocking ground brush** (`type="ground"`, e.g. `"grotto"` — cave rock,
  ids 13594/13644/13645; or `"mountain"` for outdoor cliffs). Just a ground
  id, no separate wall item. Its visual "wall-ness" comes entirely from its
  **border items** where it touches a different ground (see below) — this
  is what natural caves and outdoor mountains use, and it's what
  `build_swamp_hunt.py`'s rock/grotto section uses.
- **A wall brush** (`type="wall"`, e.g. `"stone wall3"` — ids 8201 vertical /
  8202 horizontal / 8205 corner / 8203 pole, already used elsewhere on this
  exact map's city walls). `ground=None` on that tile, with the wall item
  sitting on top. Used for constructed rooms/buildings where you want an
  actual standalone wall object (can have a door variant, etc — see the
  `<door .../>` entries under each wall brush in `walls.xml`).

Pick blocking-ground-brush for natural terrain (caves, mountains, cliffs),
wall-brush for anything built (a house, a fenced room, a dungeon corridor
with doors). Don't mix conventions on the same wall for no reason.

## Where to find the correct ids (authoritative sources, in order)

1. **This map's own existing content.** Before inventing an id, check what's
   already used nearby via a ground-id frequency scan — reusing a
   proven-good id is always the safest choice.
2. **RME's bundled brush/border data**, under
   `rme/canary-map-editor-v4.0-windows/data/materials/`:
   - `brushs/grounds.xml` — every ground brush, its item ids + relative
     `chance` weights (for natural texture variety), and which `border`
     id(s) it declares (`align="outer"`, `to="none"` for map-edge cases).
   - `brushs/walls.xml` — every wall brush's `horizontal`/`vertical`/
     `corner`/`pole` piece ids, plus door variants.
   - `borders/borders.xml` — the actual per-edge item ids for a given
     border id (`n`/`e`/`s`/`w`/`cnw`/`cne`/`csw`/`cse`/`dnw`/`dne`/`dsw`/`dse`).
   - `tilesets/*.xml` just group brush *names* into editor categories — use
     `grounds.xml`/`walls.xml`/`borders.xml` for actual ids.
3. **`data/items/items.xml`** (the server's copy) — confirms an id is
   accepted server-side and gives its name/attributes, but per mistake #2
   above, this alone does not prove it renders.

## Delegate border art to RME — don't hand-simulate it

Write only plain ground ids for fills (per-brush weighted random from
`grounds.xml`, matching real texture variety). Then have the user, in RME:

1. Select the edited region (drag a selection box over it — safer than
   Ctrl+A/"Borderize Map", which touches the whole map and can't be undone).
2. **Edit → Border Options → Borderize Selection** (`Ctrl+B`). This runs
   RME's own border engine using the exact brush/border data above — it is
   the authoritative implementation, not a guess.
3. Save, then restart the server (map edits are never covered by `/reload`
   or `Game.reload()` — see below).

If a generator script needs to guarantee correct borders *without* a user
RME pass (not yet implemented here, but the right next step if ever
needed): parse `borders.xml` for each brush's declared border id, and for
every tile compute which of its 8 neighbors differ in brush, then place the
matching `n/e/s/w/corner/diagonal` piece per the border definition. Don't
attempt a partial/simplified version of this — mistake #1 already showed
what a partial version looks like.

## Organic shape recipes

- **Irregular blobs (lakes, marshes) instead of perfect circles**: perturb
  the radius by angle with a few sine harmonics of random freq/amplitude/
  phase, instead of a fixed radius:
  ```python
  def radial(base, harmonics, angle):
      r = base
      for amp, freq, phase in harmonics:
          r += amp * math.sin(freq * angle + phase)
      return r
  # is_inside: math.hypot(x-cx, y-cy) <= radial(base, harmonics, angle_to(x,y))
  ```
  Add a handful of extra small circles ("bays") at random offsets from the
  main center, unioned in, for coastline inlets — breaks the "ring" look.
- **Winding cave tunnels/rooms instead of a rectangle room**: a drunkard's
  walk that **bounces off boundaries** (reflect heading) rather than
  clamping position — clamping makes it stick to the wall and carve a tiny
  area near the boundary instead of winding through the whole space:
  ```python
  if x < X0 + margin: x = X0 + margin; heading = math.pi - heading
  elif x > X1 - margin: x = X1 - margin; heading = math.pi - heading
  if y < Y0 + margin: y = Y0 + margin; heading = -heading
  elif y > Y1 - margin: y = Y1 - margin; heading = -heading
  ```
  Vary the carve radius per step (3-5 normally, 7-10 every ~10th step for a
  "room"). **Always also carve a short guaranteed straight connector** from
  the fixed entry point into the walk's start position — starting the
  random walk right at a boundary (or relying on it to "find" the entrance
  by chance) produces a disconnected or barely-connected result.
- **Natural-looking monster scatter instead of a fixed grid**: shuffle
  candidate cells, greedily keep ones at least `min_spacing` away from
  already-chosen ones (cheap Poisson-disk approximation), and occasionally
  (~15-35% of the time) add a second monster at a ±1 offset to the same
  spawn block — matches how the existing `-monster.xml` already mixes
  single- and multi-monster spawn blocks.
- **In a cave/room, only place spawns on floor cells whose 4 orthogonal
  neighbors are ALSO non-blocking floor** — not just "this cell is floor."
  A monster on a 1-tile floor sliver against a wall reads as "standing
  inside the wall" in-game, because Tibia's isometric wall sprites overhang
  onto the adjacent floor tile. Filter candidates with
  `tile.hasGround and not tile.isBlocking` on the cell AND all 4 neighbors
  before running the Poisson-disk selection above (see
  `scripts/fix_swamp_hunt_monster_placement.lua`). This check reads the
  *actual current tile state* (post-borderize), which is more reliable than
  re-deriving it from the cellular-automata grid you generated the cave
  from.

## Monster/spawn XML format (`*-monster.xml`)

```xml
<monster centerx="976" centery="1041" centerz="4" radius="1">
    <monster name="Valkyrie" x="0" y="0" z="4" spawntime="60" />
</monster>
<monster centerx="968" centery="1064" centerz="4" radius="1">
    <monster name="Barbarian Bloodwalker" x="0" y="0" z="4" spawntime="60" />
    <monster name="Barbarian Skullhunter" x="1" y="1" z="4" spawntime="60" />
</monster>
```
- Outer `<monster centerx centery centerz radius>` is one spawn point;
  `radius="1"` throughout the existing file.
- Nested `<monster name x y z spawntime>` — `x`/`y` are **relative to the
  center**, `spawntime="60"` throughout the existing file.
- Append new blocks right before `</monsters>` in the sibling `-monster.xml`
  file (same basename as the `.otbm`, e.g.
  `MAPA OFICIAL DE TRABALHO-monster.xml`).
- **Only use monster names that already have a script** in
  `data-otservbr-global/monster/**/*.lua` — grep for the file first, and
  read `monster.experience`/`monster.health` there to judge difficulty tier
  before picking a roster. Don't invent a name that sounds right.
- For picking a themed roster (e.g. "level 200+ swamp"), a real-world web
  search for actual Tibia hunting places/creatures of that level+theme is a
  good sanity check for what's thematically appropriate — but the name
  still has to resolve to an actual script in this datapack before use.

## Non-negotiables

- **Map/terrain/spawn changes never take effect via `/reload <type>` or
  `Game.reload()`** — those only cover script/monster-type/npc/item
  definitions, never map or spawn-position data. A full server restart is
  always required to see the result in-game.
- **This tool cannot render the map.** ASCII density previews (see workflow
  step 6) catch shape/structure bugs; they cannot catch a missing-sprite
  rendering bug (mistake #2). Always expect a screenshot-based correction
  round after the user opens RME, and treat their screenshot as the actual
  ground truth over any amount of internal reasoning about "should be
  valid."
