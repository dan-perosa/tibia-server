"""
Minimal OTBM (Tibia binary map) reader/writer.

Format verified directly against Remere's Map Editor source
(source/iomap_otbm.cpp, source/iomap_otbm.h, source/filehandle.cpp/.h)
and against a real file saved by that same editor (meu-mapa.otbm).

Supports OTBM version 5 (MAP_OTBM_5 = 4), which is what this project's
RME build (Canary's Map Editor 4.0.0) saves. Item attributes use the
"old" per-tag format (count/actionId/uniqueId/text/desc/charges/depotId/
doorId/teleDest), NOT the newer OTBM_ATTR_ATTRIBUTE_MAP(128) format --
that format is only used for MAP_OTBM_4 or > MAP_OTBM_5, which this
version is not.

This intentionally does NOT support container item children (nested
items), which is fine for terrain/building/decoration work but would
need extending if you ever need to place a pre-filled container.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

NODE_START = 0xFE
NODE_END = 0xFF
ESCAPE = 0xFD

# --- Node types (source/iomap_otbm.h: OTBM_NodeTypes_t) ---
OTBM_ROOTV1 = 1
OTBM_MAP_DATA = 2
OTBM_TILE_AREA = 4
OTBM_TILE = 5
OTBM_ITEM = 6
OTBM_TOWNS = 12
OTBM_TOWN = 13
OTBM_HOUSETILE = 14
OTBM_WAYPOINTS = 15
OTBM_WAYPOINT = 16
OTBM_TILE_ZONE = 19

# --- Attribute tags (source/iomap_otbm.h: OTBM_ItemAttribute) ---
OTBM_ATTR_DESCRIPTION = 1
OTBM_ATTR_TILE_FLAGS = 3
OTBM_ATTR_ACTION_ID = 4
OTBM_ATTR_UNIQUE_ID = 5
OTBM_ATTR_TEXT = 6
OTBM_ATTR_DESC = 7
OTBM_ATTR_TELE_DEST = 8
OTBM_ATTR_ITEM = 9
OTBM_ATTR_DEPOT_ID = 10
OTBM_ATTR_EXT_SPAWN_MONSTER_FILE = 11
OTBM_ATTR_EXT_HOUSE_FILE = 13
OTBM_ATTR_HOUSEDOORID = 14
OTBM_ATTR_COUNT = 15
OTBM_ATTR_CHARGES = 22
OTBM_ATTR_EXT_SPAWN_NPC_FILE = 23
OTBM_ATTR_EXT_ZONE_FILE = 24

MAP_OTBM_5 = 4  # client_assets.h MapVersionID -- what this project's files use


# ============================================================================
# Data model
# ============================================================================

@dataclass
class OtbmItem:
    id: int
    count: Optional[int] = None
    action_id: Optional[int] = None
    unique_id: Optional[int] = None
    text: Optional[str] = None
    desc: Optional[str] = None
    charges: Optional[int] = None
    depot_id: Optional[int] = None
    door_id: Optional[int] = None
    tele_dest: Optional[tuple] = None  # (x, y, z)


@dataclass
class OtbmTile:
    x: int
    y: int
    z: int
    house_id: Optional[int] = None
    flags: int = 0
    ground: Optional[int] = None  # plain ground item id (no attributes)
    items: list = field(default_factory=list)  # list[OtbmItem]
    zones: list = field(default_factory=list)  # list[int]


@dataclass
class OtbmTown:
    id: int
    name: str
    x: int
    y: int
    z: int


@dataclass
class OtbmWaypoint:
    name: str
    x: int
    y: int
    z: int


@dataclass
class OtbmMap:
    version: int = MAP_OTBM_5
    width: int = 2048
    height: int = 2048
    items_major: int = 4
    items_minor: int = 4
    description: str = "Saved with otbm.py"
    ext_description: str = ""
    spawn_monster_file: str = ""
    spawn_npc_file: str = ""
    house_file: str = ""
    zone_file: str = ""
    tiles: dict = field(default_factory=dict)  # (x,y,z) -> OtbmTile
    towns: list = field(default_factory=list)  # list[OtbmTown]
    waypoints: list = field(default_factory=list)  # list[OtbmWaypoint]

    def get_or_create_tile(self, x: int, y: int, z: int) -> OtbmTile:
        key = (x, y, z)
        tile = self.tiles.get(key)
        if tile is None:
            tile = OtbmTile(x=x, y=y, z=z)
            self.tiles[key] = tile
        return tile


# ============================================================================
# Low-level binary writer (handles node markers + byte escaping)
# ============================================================================

class _Writer:
    def __init__(self):
        self.buf = bytearray()

    def raw_byte(self, b: int):
        self.buf.append(b)

    def esc_byte(self, b: int):
        if b in (NODE_START, NODE_END, ESCAPE):
            self.buf.append(ESCAPE)
        self.buf.append(b)

    def u8(self, v: int):
        self.esc_byte(v & 0xFF)

    def u16(self, v: int):
        self.esc_byte(v & 0xFF)
        self.esc_byte((v >> 8) & 0xFF)

    def u32(self, v: int):
        for i in range(4):
            self.esc_byte((v >> (8 * i)) & 0xFF)

    def string(self, s: str):
        data = s.encode("utf-8")
        self.u16(len(data))
        for b in data:
            self.esc_byte(b)

    def start_node(self, node_type: int):
        self.raw_byte(NODE_START)
        self.raw_byte(node_type)

    def end_node(self):
        self.raw_byte(NODE_END)


def _write_item(w: _Writer, item: OtbmItem):
    w.start_node(OTBM_ITEM)
    w.u16(item.id)

    if item.count is not None:
        w.u8(OTBM_ATTR_COUNT)
        w.u8(item.count)
    if item.charges is not None:
        w.u8(OTBM_ATTR_CHARGES)
        w.u16(item.charges)
    if item.action_id is not None and item.action_id > 0:
        w.u8(OTBM_ATTR_ACTION_ID)
        w.u16(item.action_id)
    if item.unique_id is not None and item.unique_id > 0:
        w.u8(OTBM_ATTR_UNIQUE_ID)
        w.u16(item.unique_id)
    if item.text:
        w.u8(OTBM_ATTR_TEXT)
        w.string(item.text)
    if item.desc:
        w.u8(OTBM_ATTR_DESC)
        w.string(item.desc)
    if item.tele_dest is not None:
        w.u8(OTBM_ATTR_TELE_DEST)
        w.u16(item.tele_dest[0])
        w.u16(item.tele_dest[1])
        w.u8(item.tele_dest[2])
    if item.door_id is not None:
        w.u8(OTBM_ATTR_HOUSEDOORID)
        w.u8(item.door_id)
    if item.depot_id is not None:
        w.u8(OTBM_ATTR_DEPOT_ID)
        w.u16(item.depot_id)

    w.end_node()


def write_otbm(map_: OtbmMap, path: str):
    w = _Writer()

    # 4-byte header (identifier). RME writes all zeros for this version.
    w.raw_byte(0)
    w.raw_byte(0)
    w.raw_byte(0)
    w.raw_byte(0)

    w.start_node(0)  # ROOT node type -- confirmed via source (iomap_otbm.cpp: f.addNode(0)), not the OTBM_ROOTV1=1 enum
    w.u32(map_.version)
    w.u16(map_.width)
    w.u16(map_.height)
    w.u32(map_.items_major)
    w.u32(map_.items_minor)

    w.start_node(OTBM_MAP_DATA)
    w.u8(OTBM_ATTR_DESCRIPTION)
    w.string(map_.description)
    if map_.ext_description:
        w.u8(OTBM_ATTR_DESCRIPTION)
        w.string(map_.ext_description)
    if map_.spawn_monster_file:
        w.u8(OTBM_ATTR_EXT_SPAWN_MONSTER_FILE)
        w.string(map_.spawn_monster_file)
    if map_.house_file:
        w.u8(OTBM_ATTR_EXT_HOUSE_FILE)
        w.string(map_.house_file)
    if map_.spawn_npc_file:
        w.u8(OTBM_ATTR_EXT_SPAWN_NPC_FILE)
        w.string(map_.spawn_npc_file)
    if map_.zone_file:
        w.u8(OTBM_ATTR_EXT_ZONE_FILE)
        w.string(map_.zone_file)

    # --- Tile areas (256x256 blocks per z-level) ---
    def area_key(x, y, z):
        return (x & 0xFF00, y & 0xFF00, z)

    areas: dict = {}
    for (x, y, z), tile in map_.tiles.items():
        if tile.ground is None and not tile.items and tile.house_id is None and tile.flags == 0:
            continue  # empty tile, nothing to write
        areas.setdefault(area_key(x, y, z), []).append(tile)

    for (ax, ay, az), tiles in sorted(areas.items()):
        w.start_node(OTBM_TILE_AREA)
        w.u16(ax)
        w.u16(ay)
        w.u8(az)

        for tile in sorted(tiles, key=lambda t: (t.y, t.x)):
            is_house_tile = tile.house_id is not None
            w.start_node(OTBM_HOUSETILE if is_house_tile else OTBM_TILE)
            w.u8(tile.x & 0xFF)
            w.u8(tile.y & 0xFF)
            if is_house_tile:
                w.u32(tile.house_id)
            if tile.flags:
                w.u8(OTBM_ATTR_TILE_FLAGS)
                w.u32(tile.flags)
            if tile.ground is not None:
                w.u8(OTBM_ATTR_ITEM)
                w.u16(tile.ground)
            for item in tile.items:
                _write_item(w, item)
            if tile.zones:
                w.start_node(OTBM_TILE_ZONE)
                w.u16(len(tile.zones))
                for zid in tile.zones:
                    w.u16(zid)
                w.end_node()
            w.end_node()

        w.end_node()  # TILE_AREA

    # --- Towns ---
    w.start_node(OTBM_TOWNS)
    for town in map_.towns:
        w.start_node(OTBM_TOWN)
        w.u32(town.id)
        w.string(town.name)
        w.u16(town.x)
        w.u16(town.y)
        w.u8(town.z)
        w.end_node()
    w.end_node()  # TOWNS

    # --- Waypoints ---
    w.start_node(OTBM_WAYPOINTS)
    for wp in map_.waypoints:
        w.start_node(OTBM_WAYPOINT)
        w.string(wp.name)
        w.u16(wp.x)
        w.u16(wp.y)
        w.u8(wp.z)
        w.end_node()
    w.end_node()  # WAYPOINTS

    w.end_node()  # MAP_DATA
    w.end_node()  # ROOT

    with open(path, "wb") as f:
        f.write(w.buf)


# ============================================================================
# Low-level binary reader
# ============================================================================

class _Reader:
    """Parses the raw byte stream into a tree of (node_type, content_bytes, children)."""

    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def _read_de_escaped_run(self):
        """Reads content bytes until (unescaped) NODE_START/NODE_END, de-escaping as it goes."""
        out = bytearray()
        while self.pos < len(self.data):
            b = self.data[self.pos]
            if b == ESCAPE:
                self.pos += 1
                if self.pos < len(self.data):
                    out.append(self.data[self.pos])
                    self.pos += 1
                continue
            if b == NODE_START or b == NODE_END:
                return bytes(out)
            out.append(b)
            self.pos += 1
        return bytes(out)

    def parse_node(self):
        """Assumes self.pos is right after an (unescaped) NODE_START byte.
        Returns (node_type, content_bytes, children) and leaves pos after the matching NODE_END."""
        node_type = self.data[self.pos]
        self.pos += 1
        content = self._read_de_escaped_run()
        children = []
        while self.pos < len(self.data) and self.data[self.pos] == NODE_START:
            self.pos += 1
            children.append(self.parse_node())
        # Now expect NODE_END
        if self.pos < len(self.data) and self.data[self.pos] == NODE_END:
            self.pos += 1
        return (node_type, content, children)


class _FieldReader:
    """Reads typed fields sequentially out of a node's de-escaped content bytes."""

    def __init__(self, content: bytes):
        self.data = content
        self.pos = 0

    def eof(self):
        return self.pos >= len(self.data)

    def u8(self):
        v = self.data[self.pos]
        self.pos += 1
        return v

    def u16(self):
        v = self.data[self.pos] | (self.data[self.pos + 1] << 8)
        self.pos += 2
        return v

    def u32(self):
        v = 0
        for i in range(4):
            v |= self.data[self.pos + i] << (8 * i)
        self.pos += 4
        return v

    def string(self):
        length = self.u16()
        s = self.data[self.pos:self.pos + length].decode("utf-8", errors="replace")
        self.pos += length
        return s


def _read_item_attributes(item: OtbmItem, fr: _FieldReader):
    while not fr.eof():
        tag = fr.u8()
        if tag == OTBM_ATTR_COUNT:
            item.count = fr.u8()
        elif tag == OTBM_ATTR_CHARGES:
            item.charges = fr.u16()
        elif tag == OTBM_ATTR_ACTION_ID:
            item.action_id = fr.u16()
        elif tag == OTBM_ATTR_UNIQUE_ID:
            item.unique_id = fr.u16()
        elif tag == OTBM_ATTR_TEXT:
            item.text = fr.string()
        elif tag == OTBM_ATTR_DESC:
            item.desc = fr.string()
        elif tag == OTBM_ATTR_TELE_DEST:
            x = fr.u16()
            y = fr.u16()
            z = fr.u8()
            item.tele_dest = (x, y, z)
        elif tag == OTBM_ATTR_HOUSEDOORID:
            item.door_id = fr.u8()
        elif tag == OTBM_ATTR_DEPOT_ID:
            item.depot_id = fr.u16()
        else:
            raise ValueError(f"Unknown item attribute tag {tag} for item {item.id} -- "
                              f"this map may use a newer/older OTBM attribute format than otbm.py supports.")


def read_otbm(path: str) -> OtbmMap:
    with open(path, "rb") as f:
        raw = f.read()

    body = raw[4:]  # skip 4-byte identifier header
    reader = _Reader(body)
    assert reader.data[reader.pos] == NODE_START
    reader.pos += 1
    root_type, root_content, root_children = reader.parse_node()

    fr = _FieldReader(root_content)
    map_ = OtbmMap()
    map_.version = fr.u32()
    map_.width = fr.u16()
    map_.height = fr.u16()
    map_.items_major = fr.u32()
    map_.items_minor = fr.u32()

    assert len(root_children) == 1
    map_data_type, map_data_content, map_data_children = root_children[0]
    assert map_data_type == OTBM_MAP_DATA

    mfr = _FieldReader(map_data_content)
    descriptions = []
    while not mfr.eof():
        tag = mfr.u8()
        if tag == OTBM_ATTR_DESCRIPTION:
            descriptions.append(mfr.string())
        elif tag == OTBM_ATTR_EXT_SPAWN_MONSTER_FILE:
            map_.spawn_monster_file = mfr.string()
        elif tag == OTBM_ATTR_EXT_HOUSE_FILE:
            map_.house_file = mfr.string()
        elif tag == OTBM_ATTR_EXT_SPAWN_NPC_FILE:
            map_.spawn_npc_file = mfr.string()
        elif tag == OTBM_ATTR_EXT_ZONE_FILE:
            map_.zone_file = mfr.string()
        else:
            raise ValueError(f"Unknown map-data attribute tag {tag}")
    if descriptions:
        map_.description = descriptions[0]
        if len(descriptions) > 1:
            map_.ext_description = descriptions[1]

    for child_type, child_content, child_children in map_data_children:
        if child_type == OTBM_TILE_AREA:
            afr = _FieldReader(child_content)
            area_x = afr.u16()
            area_y = afr.u16()
            area_z = afr.u8()
            for tile_type, tile_content, tile_children in child_children:
                tfr = _FieldReader(tile_content)
                local_x = tfr.u8()
                local_y = tfr.u8()
                x = area_x + local_x
                y = area_y + local_y
                z = area_z
                tile = OtbmTile(x=x, y=y, z=z)
                if tile_type == OTBM_HOUSETILE:
                    tile.house_id = tfr.u32()
                while not tfr.eof():
                    tag = tfr.u8()
                    if tag == OTBM_ATTR_TILE_FLAGS:
                        tile.flags = tfr.u32()
                    elif tag == OTBM_ATTR_ITEM:
                        tile.ground = tfr.u16()
                    else:
                        raise ValueError(f"Unknown tile attribute tag {tag} at ({x},{y},{z})")
                for item_type, item_content, item_children in tile_children:
                    if item_type == OTBM_ITEM:
                        ifr = _FieldReader(item_content)
                        item = OtbmItem(id=ifr.u16())
                        _read_item_attributes(item, ifr)
                        tile.items.append(item)
                    elif item_type == OTBM_TILE_ZONE:
                        zfr = _FieldReader(item_content)
                        count = zfr.u16()
                        for _ in range(count):
                            tile.zones.append(zfr.u16())
                    else:
                        raise ValueError(f"Unknown child node type {item_type} inside tile ({x},{y},{z})")
                map_.tiles[(x, y, z)] = tile
        elif child_type == OTBM_TOWNS:
            for town_type, town_content, _ in child_children:
                tfr = _FieldReader(town_content)
                town = OtbmTown(
                    id=tfr.u32(),
                    name=tfr.string(),
                    x=tfr.u16(),
                    y=tfr.u16(),
                    z=tfr.u8(),
                )
                map_.towns.append(town)
        elif child_type == OTBM_WAYPOINTS:
            for wp_type, wp_content, _ in child_children:
                wfr = _FieldReader(wp_content)
                wp = OtbmWaypoint(
                    name=wfr.string(),
                    x=wfr.u16(),
                    y=wfr.u16(),
                    z=wfr.u8(),
                )
                map_.waypoints.append(wp)
        else:
            raise ValueError(f"Unknown top-level node type {child_type} under MAP_DATA")

    return map_
