"""BSP v30 (GoldSrc) parser + validator.

    python3 -m mapkit.bspcheck cstrike/maps/zm_vex_pilot.bsp [--json] [--perf-only] [--at "x y z"]

Checks (errors fail, warnings inform):
  * header version 30, lump bounds
  * every lump against the GoldSrc engine limits (HLSDK bspfile.h)
  * every texture embedded (no external / wad-dependent miptex), sizes /16,
    worldspawn "wad" key empty, skyname is a stock CS sky
  * face lightmap extents (engine "Bad surface extents" error)
  * lightmap data size consistency
  * world bounds inside +-4096 (CS 1.6 coordinate limit)
  * entity key/value length limits, entity count, brush model (precache) count
  * spawn points: >= 32 CT + 32 T, exact stuck test against the compiled
    player clip hull (hull 1, standing) incl. solid brush entities, spacing,
    distance to the floor below.
  * precache budget (entity_budget): brush entities (model slots), sounds and
    models the game DLL precaches for the map's entities, new vs. already
    precached on every map; errors over max_brush_ents / max_map_sounds.
  * rendering cost (perf_analysis): GL renderer r_speeds "wpoly" estimate -
    per-leaf PVS sums and an exact replay of the world/brush-entity drawing
    from player eye positions; worst leaves / views with coordinates, heavy
    brush entities, animated light styles, sprites, texture / lightmap / bsp
    bytes; thresholds from PERF_DEFAULTS (warn p95 > 900, error max > 1300).
    perf_at(bsp, [(x, y, z)]) gives the numbers at chosen spots.
"""
from __future__ import annotations

import json
import math
import os
import struct
import sys
from typing import Dict, List, Optional, Tuple

import numpy as np

LUMPS = ['entities', 'planes', 'textures', 'vertexes', 'visibility', 'nodes', 'texinfo', 'faces', 'lighting',
         'clipnodes', 'leafs', 'marksurfaces', 'edges', 'surfedges', 'models']

DT = {
    'planes': np.dtype([('normal', '<f4', 3), ('dist', '<f4'), ('type', '<i4')]),
    'vertexes': np.dtype([('p', '<f4', 3)]),
    'nodes': np.dtype([('planenum', '<i4'), ('children', '<i2', 2), ('mins', '<i2', 3), ('maxs', '<i2', 3),
                       ('firstface', '<u2'), ('numfaces', '<u2')]),
    'texinfo': np.dtype([('vecs', '<f4', (2, 4)), ('miptex', '<i4'), ('flags', '<i4')]),
    'faces': np.dtype([('planenum', '<u2'), ('side', '<i2'), ('firstedge', '<i4'), ('numedges', '<i2'),
                       ('texinfo', '<i2'), ('styles', 'u1', 4), ('lightofs', '<i4')]),
    'clipnodes': np.dtype([('planenum', '<i4'), ('children', '<i2', 2)]),
    'leafs': np.dtype([('contents', '<i4'), ('visofs', '<i4'), ('mins', '<i2', 3), ('maxs', '<i2', 3),
                       ('firstmarksurface', '<u2'), ('nummarksurfaces', '<u2'), ('ambient', 'u1', 4)]),
    'marksurfaces': np.dtype('<u2'),
    'edges': np.dtype([('v', '<u2', 2)]),
    'surfedges': np.dtype('<i4'),
    'models': np.dtype([('mins', '<f4', 3), ('maxs', '<f4', 3), ('origin', '<f4', 3), ('headnode', '<i4', 4),
                        ('visleafs', '<i4'), ('firstface', '<i4'), ('numfaces', '<i4')]),
}

# GoldSrc engine limits (HLSDK utils/common/bspfile.h) - counts or bytes
LIMITS = {
    'models': 400, 'planes': 32767, 'vertexes': 65535, 'nodes': 32767, 'texinfo': 8192, 'faces': 65535,
    'clipnodes': 32767, 'leafs': 8192, 'marksurfaces': 65535, 'edges': 256000, 'surfedges': 512000,
    'textures_count': 512, 'textures': 0x200000, 'lighting': 0x200000, 'visibility': 0x200000,
    'entities': 128 * 1024,
}

CONTENTS = {-1: 'empty', -2: 'solid', -3: 'water', -4: 'slime', -5: 'lava', -6: 'sky'}
TEX_SPECIAL = 1
STOCK_SKIES = {'desert', 'city', 'night', 'space', 'cx', 'office', 'de_storm', 'backalley', 'morning', 'green',
               'snow', 'tornsky', 'trainyard', '2desert', 'cliff', 'hav', 'dusk', 'neb6', 'xen9', 'alien1',
               'alien2', 'alien3', 'black', 'blue', 'grnplsnt'}
# our own skies (6 TGAs under cstrike/gfx/env, shipped + listed in the map .res); --allow-sky adds more
CUSTOM_SKIES = {'vexmira_night'}
ALLOW_SKIES = set()
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))


def sky_files(sky):
    return [os.path.join(REPO_ROOT, 'cstrike', 'gfx', 'env', f'{sky}{s}.tga') for s in ('rt', 'lf', 'up', 'dn', 'ft', 'bk')]


def _tga24_ok(path):
    with open(path, 'rb') as f:
        h = f.read(18)
    w, hh = h[12] | h[13] << 8, h[14] | h[15] << 8
    return len(h) == 18 and h[2] == 2 and h[16] == 24 and w == hh and w <= 512 and os.path.getsize(path) >= 18 + w * hh * 3


# static (at compile position) solid brush entities that can trap a spawn
SOLID_BRUSH_CLASSES = {'func_wall', 'func_breakable', 'func_door', 'func_door_rotating', 'func_pushable',
                       'func_button', 'func_wall_toggle', 'func_conveyor', 'momentary_door'}


class Miptex:
    __slots__ = ('name', 'width', 'height', 'offsets', 'data', 'embedded')

    def __init__(self, name, w, h, offsets, data):
        self.name, self.width, self.height, self.offsets, self.data = name, w, h, offsets, data
        self.embedded = offsets[0] != 0

    def rgba(self, level=0) -> Optional[np.ndarray]:
        if not self.embedded:
            return None
        w, h = self.width >> level, self.height >> level
        idx = np.frombuffer(self.data, np.uint8, w * h, self.offsets[level]).reshape(h, w)
        pofs = self.offsets[3] + (self.width >> 3) * (self.height >> 3) + 2
        pal = np.frombuffer(self.data, np.uint8, 768, pofs).reshape(256, 3)
        rgb = pal[idx]
        a = np.full((h, w, 1), 255, np.uint8)
        if self.name.startswith('{'):
            a[idx == 255] = 0
        return np.concatenate([rgb, a], 2)


class BSP:
    def __init__(self, path: str):
        self.path = path
        with open(path, 'rb') as f:
            self.raw = f.read()
        ver = struct.unpack('<i', self.raw[:4])[0]
        if ver != 30:
            raise ValueError(f'{path}: BSP version {ver} (expected 30)')
        self.lumps = {}
        for i, n in enumerate(LUMPS):
            ofs, ln = struct.unpack('<ii', self.raw[4 + 8 * i: 12 + 8 * i])
            if ofs < 0 or ln < 0 or ofs + ln > len(self.raw):
                raise ValueError(f'lump {n} out of file bounds')
            self.lumps[n] = (ofs, ln)
        for n, dt in DT.items():
            ofs, ln = self.lumps[n]
            if ln % dt.itemsize:
                raise ValueError(f'lump {n} size {ln} not a multiple of {dt.itemsize}')
            setattr(self, n, np.frombuffer(self.raw, dt, ln // dt.itemsize, ofs))
        ofs, ln = self.lumps['lighting']
        self.lighting = np.frombuffer(self.raw, np.uint8, ln, ofs)
        ofs, ln = self.lumps['visibility']
        self.visdata = self.raw[ofs:ofs + ln]
        ofs, ln = self.lumps['entities']
        self.entdata = self.raw[ofs:ofs + ln].split(b'\0')[0].decode('latin-1')
        self.entities = parse_entities(self.entdata)
        self.miptex = self._read_textures()

    def _read_textures(self) -> List[Optional[Miptex]]:
        ofs, ln = self.lumps['textures']
        if ln == 0:
            return []
        n = struct.unpack('<i', self.raw[ofs:ofs + 4])[0]
        offs = struct.unpack(f'<{n}i', self.raw[ofs + 4: ofs + 4 + 4 * n])
        out = []
        for o in offs:
            if o < 0:
                out.append(None)
                continue
            b = ofs + o
            name = self.raw[b:b + 16].split(b'\0')[0].decode('latin-1')
            w, h = struct.unpack('<II', self.raw[b + 16:b + 24])
            mofs = struct.unpack('<4I', self.raw[b + 24:b + 40])
            out.append(Miptex(name, w, h, mofs, self.raw[b:]))
        return out

    # ------------------------------------------------------------------
    def face_vertices(self, i: int) -> np.ndarray:
        f = self.faces[i]
        se = self.surfedges[f['firstedge']: f['firstedge'] + f['numedges']]
        idx = np.where(se >= 0, self.edges['v'][np.abs(se), 0], self.edges['v'][np.abs(se), 1])
        return self.vertexes['p'][idx].astype(np.float64)

    def face_extents(self, i: int):
        """(texmins (s,t) in luxel units, extents (s,t) in texels, uv (n,2))."""
        f = self.faces[i]
        ti = self.texinfo[f['texinfo']]
        V = self.face_vertices(i).astype(np.float32)
        vecs = ti['vecs'].astype(np.float32)
        # float32 like the engine's CalcSurfaceExtents
        st = (V[:, 0:1] * vecs[:, 0] + V[:, 1:2] * vecs[:, 1] + V[:, 2:3] * vecs[:, 2] + vecs[:, 3]).astype(np.float64)
        mn = np.floor(st.min(axis=0) / 16)
        mx = np.ceil(st.max(axis=0) / 16)
        return mn, (mx - mn) * 16, st

    def point_contents(self, p, hull: int = 0, model: int = 0, offset=None) -> int:
        """Exact engine point test. hull 0 = point (nodes), 1 = standing
        player, 2 = large, 3 = crouching player (clipnodes). offset = the
        brush entity's origin (origin-brush entities)."""
        m = self.models[model]
        p = np.asarray(p, np.float64) - (m['origin'] if offset is None else offset)
        num = int(m['headnode'][hull])
        planes = self.planes
        if hull == 0:
            nodes = self.nodes
            while num >= 0:
                nd = nodes[num]
                pl = planes[nd['planenum']]
                d = (p[pl['type']] if pl['type'] < 3 else float(np.dot(pl['normal'], p))) - pl['dist']
                num = int(nd['children'][0 if d >= 0 else 1])
            return int(self.leafs[-num - 1]['contents'])
        cn = self.clipnodes
        while num >= 0:
            nd = cn[num]
            pl = planes[nd['planenum']]
            d = (p[pl['type']] if pl['type'] < 3 else float(np.dot(pl['normal'], p))) - pl['dist']
            num = int(nd['children'][0 if d >= 0 else 1])
        return num

    def lumpsize(self, n):
        return self.lumps[n][1]


def parse_entities(s: str) -> List[Dict[str, str]]:
    ents, cur = [], None
    i, n = 0, len(s)
    tokens = []
    while i < n:
        c = s[i]
        if c in ' \t\r\n':
            i += 1
        elif c in '{}':
            tokens.append(c)
            i += 1
        elif c == '"':
            j = s.index('"', i + 1)
            tokens.append(s[i + 1:j])
            i = j + 1
        else:
            j = i
            while j < n and s[j] not in ' \t\r\n{}"':
                j += 1
            tokens.append(s[i:j])
            i = j
    k = 0
    pairs = []
    while k < len(tokens):
        t = tokens[k]
        if t == '{':
            cur = {}
            pairs = []
        elif t == '}':
            if cur is not None:
                cur['__pairs__'] = pairs
                ents.append(cur)
            cur = None
        else:
            v = tokens[k + 1] if k + 1 < len(tokens) else ''
            cur[t] = v
            pairs.append((t, v))
            k += 1
        k += 1
    return ents


# ======================================================================
def check(path: str, min_spawns: int = 32, spacing: float = 48.0, perf: bool = True,
          perf_opts: Optional[dict] = None) -> dict:
    """Validate a compiled BSP. perf: also run perf_analysis() + entity_budget() (rep['perf'],
    rep['budget']); perf_opts: PERF_DEFAULTS overrides (thresholds, strict, ...)."""
    errs: List[str] = []
    warns: List[str] = []
    info: Dict[str, object] = {}
    try:
        b = BSP(path)
    except Exception as e:
        return {'path': path, 'errors': [f'parse failed: {e}'], 'warnings': [], 'info': {}}
    import os
    info['file_bytes'] = os.path.getsize(path)

    # ---------------- lump limits
    counts = {}
    for n in ('models', 'planes', 'vertexes', 'nodes', 'texinfo', 'faces', 'clipnodes', 'leafs', 'marksurfaces',
              'edges', 'surfedges'):
        counts[n] = len(getattr(b, n))
    counts['textures_count'] = len(b.miptex)
    sizes = {n: b.lumpsize(n) for n in ('textures', 'lighting', 'visibility', 'entities')}
    usage = {}
    for k, v in list(counts.items()) + list(sizes.items()):
        lim = LIMITS[k]
        usage[k] = (v, lim, round(100.0 * v / lim, 1))
        if v > lim:
            errs.append(f'{k}: {v} exceeds engine limit {lim}')
        elif v > lim * 0.85:
            warns.append(f'{k}: {v} is {100 * v / lim:.0f}% of the engine limit {lim}')
    info['usage'] = usage
    if len(b.leafs) - 1 > 8192 - 1:
        errs.append('too many leafs for the engine')

    # ---------------- textures
    names, ext = [], []
    for i, m in enumerate(b.miptex):
        if m is None:
            errs.append(f'texture slot {i} is empty (-1 offset)')
            continue
        names.append(m.name)
        if not m.embedded:
            ext.append(m.name)
        if m.width % 16 or m.height % 16 or m.width == 0 or m.height == 0:
            errs.append(f'texture {m.name} size {m.width}x{m.height} not multiple of 16')
        if m.width > 512 or m.height > 512:
            warns.append(f'texture {m.name} larger than 512 ({m.width}x{m.height})')
    if ext:
        errs.append(f'textures not embedded (client would need a wad): {ext}')
    info['textures'] = names
    ws = b.entities[0] if b.entities else {}
    if ws.get('classname') != 'worldspawn':
        errs.append('first entity is not worldspawn')
    if ws.get('wad', '').strip(' ;'):
        errs.append(f'worldspawn wad key not empty: {ws.get("wad")}')
    sky = ws.get('skyname', '')
    if sky.lower() not in STOCK_SKIES:
        if sky.lower() in CUSTOM_SKIES or sky.lower() in ALLOW_SKIES:
            miss = [f for f in sky_files(sky) if not os.path.isfile(f)]
            if miss:
                errs.append(f'custom sky {sky!r}: missing {", ".join(os.path.relpath(f, REPO_ROOT) for f in miss)}')
            else:
                bad = [os.path.basename(f) for f in sky_files(sky) if not _tga24_ok(f)]
                if bad:
                    errs.append(f'custom sky {sky!r}: not 24-bit uncompressed square TGA <= 512: {bad}')
                warns.append(f'custom sky {sky!r} (6 TGAs shipped in cstrike/gfx/env; list them in the map .res)')
        else:
            errs.append(f'skyname {sky!r} is not a stock CS sky (clients would need a download; '
                        f'ship it under cstrike/gfx/env and add it to CUSTOM_SKIES or pass --allow-sky)')
    info['skyname'] = sky

    # ---------------- faces: extents + lightmaps
    bad = 0
    light_bytes = 0
    nostyle = 0
    for i in range(len(b.faces)):
        f = b.faces[i]
        ti = b.texinfo[f['texinfo']]
        if ti['flags'] & TEX_SPECIAL:
            continue
        mn, ex, _ = b.face_extents(i)
        if ex[0] > 256 or ex[1] > 256:
            bad += 1
            if bad <= 5:
                errs.append(f'face {i}: bad surface extents {ex.tolist()} (engine Sys_Error)')
        nst = sum(1 for s in f['styles'] if s != 255)
        if f['lightofs'] >= 0:
            sz = int((ex[0] // 16 + 1) * (ex[1] // 16 + 1)) * 3 * nst
            light_bytes = max(light_bytes, int(f['lightofs']) + sz)
        elif nst:
            nostyle += 1
    if bad > 5:
        errs.append(f'... {bad} faces with bad extents in total')
    if light_bytes > len(b.lighting):
        warns.append(f'lightmap data truncated: need {light_bytes} have {len(b.lighting)}')
    if len(b.lighting) == 0:
        warns.append('no lightmap data (RAD not run?) - map will be fullbright')
    if len(b.visdata) == 0:
        warns.append('no visibility data (VIS not run?) - everything is drawn')

    # ---------------- bounds
    w = b.models[0]
    info['world_mins'] = w['mins'].tolist()
    info['world_maxs'] = w['maxs'].tolist()
    if (np.abs(w['mins']) > 4096).any() or (np.abs(w['maxs']) > 4096).any():
        warns.append(f'world exceeds +-4096 ({w["mins"].tolist()} .. {w["maxs"].tolist()}): CS entities limited there')

    # ---------------- entities
    info['entities'] = len(b.entities)
    if len(b.entities) > 600:
        warns.append(f'{len(b.entities)} entities (edict budget ~900 with 32 players)')
    for e in b.entities:
        for k, v in e['__pairs__']:
            if len(k) >= 32:
                errs.append(f'entity key too long: {k}')
            if len(v) >= 1024:
                errs.append(f'entity value too long for {k}')
    bm = len(b.models) - 1
    info['brush_models'] = bm

    # ---------------- spawns
    sp = check_spawns(b, spacing)
    info['spawns'] = sp['summary']
    errs += sp['errors']
    warns += sp['warnings']
    if sp['summary']['ct'] < min_spawns:
        errs.append(f'only {sp["summary"]["ct"]} CT spawns (info_player_start), need >= {min_spawns}')
    if sp['summary']['t'] < min_spawns:
        errs.append(f'only {sp["summary"]["t"]} T spawns (info_player_deathmatch), need >= {min_spawns}')

    # ---------------- precache budget + rendering cost
    rep = {'path': path, 'errors': errs, 'warnings': warns, 'info': info}
    o = dict(PERF_DEFAULTS, **(perf_opts or {}))
    bud = entity_budget(b, o)
    rep['budget'] = bud
    e2, w2 = budget_problems(bud, bool(o['strict']))
    errs += e2
    warns += w2
    if perf:
        try:
            pr = perf_analysis(b, o)
        except Exception as ex:                      # never let the analysis break a compile
            import traceback
            warns.append(f'perf analysis failed: {ex!r} ({traceback.format_exc(limit=-1).strip().splitlines()[-2].strip()})')
        else:
            rep['perf'] = pr
            errs += pr['errors']
            warns += pr['warnings']
    return rep


def _vec(s):
    return np.array([float(x) for x in s.split()], np.float64)


def check_spawns(b: BSP, spacing: float = 48.0) -> dict:
    errs, warns = [], []
    pts = []
    model_ents = []
    for e in b.entities:
        m = e.get('model', '')
        if m.startswith('*') and e.get('classname') in SOLID_BRUSH_CLASSES:
            model_ents.append((int(m[1:]), e))
    for e in b.entities:
        cls = e.get('classname')
        if cls not in ('info_player_start', 'info_player_deathmatch'):
            continue
        o = _vec(e.get('origin', '0 0 0'))
        team = 'ct' if cls == 'info_player_start' else 't'
        pts.append((team, o))
        c = b.point_contents(o, 1)
        if c == -2:
            errs.append(f'{team} spawn {o.tolist()} is stuck in the world (hull 1 solid)')
            continue
        if b.point_contents(o, 0) == -2:
            errs.append(f'{team} spawn {o.tolist()} is outside the map')
            continue
        for mi, me in model_ents:
            off = _vec(me['origin']) if 'origin' in me else None
            if b.point_contents(o, 1, mi, off) == -2:
                errs.append(f'{team} spawn {o.tolist()} is stuck in {me.get("classname")} *{mi}')
        # drop to floor
        drop = None
        for dz in range(0, 400, 2):
            if b.point_contents(o - (0, 0, dz), 1) == -2:
                drop = dz
                break
        if drop is None:
            errs.append(f'{team} spawn {o.tolist()} has no floor below within 400 units')
        elif drop > 18:
            warns.append(f'{team} spawn {o.tolist()} floats {drop} units above the floor')
    close = 0
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            d = pts[i][1] - pts[j][1]
            if abs(d[2]) < 72 and max(abs(d[0]), abs(d[1])) < spacing:
                close += 1
                if close <= 5:
                    errs.append(f'spawns overlap/too close (<{spacing}): {pts[i][1].tolist()} {pts[j][1].tolist()}')
    zs = {}
    for t, o in pts:
        zs.setdefault(t, set()).add(round(o[2]))
    summary = {'ct': sum(1 for t, _ in pts if t == 'ct'), 't': sum(1 for t, _ in pts if t == 't'),
               'ct_floor_z': sorted(zs.get('ct', [])), 't_floor_z': sorted(zs.get('t', [])), 'too_close': close}
    return {'errors': errs, 'warnings': warns, 'summary': summary}


# ======================================================================
# Performance analysis: GoldSrc GL renderer "r_speeds wpoly" estimate
# ======================================================================
#
# What the GL renderer does each frame (R_MarkLeaves / R_RecursiveWorldNode /
# R_DrawBrushModel, as in GLQuake/Xash3D, which GoldSrc's hw renderer follows):
#   1. decompress the PVS row of the view leaf; mark every visible leaf and its
#      parent nodes;
#   2. walk the world BSP: skip unmarked nodes and nodes whose bbox is outside
#      the 4 frustum planes; a reached leaf marks its marksurfaces; a reached
#      node draws its own faces that were marked AND face the viewer (plane
#      side test; warped/underwater faces are not backface culled);
#   3. sky faces are not drawn as polygons (sky box); warped faces ("!name",
#      water*, laser*) are cut into SUBDIVIDE_SIZE world-unit pieces (one GL
#      poly each, GL_SubdivideSurface);
#   4. every brush entity the server sends (any of its leaves in the PVS) and
#      whose bbox is in the frustum is drawn WHOLE (no VIS inside it; only
#      per-face backface culling).  wpoly (c_brush_polys) counts world AND
#      brush-entity polys.
# Two metrics:
#   pvs  - per world leaf, 360 degrees, no frustum/backface culling: every face
#          referenced by the marksurfaces of all PVS-visible leaves (deduped)
#          + all faces of the PVS-visible brush entities.  Upper bound; shows
#          how well VIS blocks.
#   view - replay of steps 1-4 from player eye positions (sampled on every
#          walkable floor of the world and of solid brush entities, standing
#          hull must fit, eye = origin + 17 = floor + 54, plus every spawn) for
#          8 yaw directions at pitch 0, fov 90 (4:3 definition, Hor+ widened to
#          the aspect, default 16:9); the worst direction counts.  This is what
#          r_speeds "wpoly" shows in game; thresholds apply to it by default.
#          Checked against a scalar port of the engine traversal (same node
#          order): identical except for eyes under water, where a few warped
#          faces marked late in the traversal are counted extra.

SUBDIVIDE_SIZE = 64.0      # Xash3D/GoldSrc GL_SubdivideSurface step for warped surfaces
EYE_HEIGHT = 53.0          # CS: origin = floor + 36, view_ofs 17
# brush entities the client never draws (EF_NODRAW or renderamt 0 at spawn)
NODRAW_BRUSH_CLASSES = {'func_ladder', 'func_buyzone', 'func_bomb_target', 'func_hostage_rescue', 'func_escapezone',
                        'func_vip_safetyzone', 'func_monsterclip', 'func_traincontrols', 'game_zone_player',
                        'func_mortar_field', 'env_bubbles', 'func_weaponcheck'}
SPRITE_CLASSES = {'env_sprite', 'env_glow', 'cycler_sprite'}

PERF_DEFAULTS = {
    'warn_p95': 900,          # warn when the p95 of the metric exceeds this
    'error_max': 1300,        # error when the max of the metric exceeds this
    'metric': 'view',         # thresholds apply to 'view' (r_speeds estimate) or 'pvs' (per-leaf PVS sum)
    'fov': 90.0,              # CS default_fov (defined for 4:3)
    'aspect': 16.0 / 9.0,     # screen aspect (wider than 4:3 widens fov_x, vertical fov stays)
    'yaws': 8,                # view directions per eye point (pitch 0)
    'pitches': (0.0,),
    'spacing': 96.0,          # eye sample grid on walkable floors (units)
    'max_samples': 4000,
    'subdivide': SUBDIVIDE_SIZE,
    'ent_faces_warn': 200,    # drawn brush entity with more faces: warning (not VIS-culled)
    'anim_style_faces_warn': 64,   # faces with animated light styles (lightmap re-upload every frame)
    'sprites_warn': 24,       # env_sprite / env_glow / cycler_sprite entities
    'max_bsp_mb': 4.5,        # hard budgets (errors when strict)
    'max_brush_ents': 60,
    'max_map_sounds': 10,
    'strict': True,           # False: threshold errors are reported as warnings (e.g. vis -fast builds)
}

# ---------------------------------------------------------------- precache rules (ReGameDLL)
# sounds and models the game DLL precaches on every map anyway (measured: ReGameDLL 5.30, no plugin,
# vexprobe precache dump of an entity-less map); a map entity that uses them costs no new slot
GAME_BASE_SOUNDS = frozenset('''
buttons/bell1.wav buttons/blip1.wav buttons/blip2.wav buttons/button11.wav buttons/latchunlocked2.wav
buttons/lightswitch2.wav buttons/spark5.wav buttons/spark6.wav common/bodydrop3.wav common/bodydrop4.wav
common/bodysplat.wav common/npc_step1.wav common/npc_step2.wav common/npc_step3.wav common/npc_step4.wav
common/null.wav common/wpn_denyselect.wav common/wpn_hudoff.wav common/wpn_hudon.wav common/wpn_moveselect.wav
common/wpn_select.wav debris/glass1.wav debris/glass2.wav debris/glass3.wav debris/wood1.wav debris/wood2.wav
debris/wood3.wav items/9mmclip1.wav items/ammopickup2.wav items/equip_nvg.wav items/flashlight1.wav
items/gunpickup2.wav items/kevlar.wav items/nvg_off.wav items/nvg_on.wav items/suitchargeok1.wav
items/tr_kevlar.wav items/weapondrop1.wav plats/train_use1.wav plats/vehicle_ignition.wav'''.split())
GAME_BASE_MODELS = frozenset('''
models/agibs.mdl models/hgibs.mdl sprites/WXplo1.spr sprites/b-tele1.spr sprites/black_smoke1.spr
sprites/black_smoke2.spr sprites/black_smoke3.spr sprites/black_smoke4.spr sprites/blood.spr sprites/bloodspray.spr
sprites/bubble.spr sprites/c-tele1.spr sprites/eexplo.spr sprites/explode1.spr sprites/fast_wallpuff1.spr
sprites/fexplo.spr sprites/fexplo1.spr sprites/gas_puff_01.spr sprites/laserbeam.spr sprites/laserdot.spr
sprites/ledglow.spr sprites/pistol_smoke1.spr sprites/pistol_smoke2.spr sprites/radio.spr sprites/rifle_smoke1.spr
sprites/rifle_smoke2.spr sprites/rifle_smoke3.spr sprites/shadow_circle.spr sprites/smoke.spr sprites/smokepuff.spr
sprites/steam1.spr sprites/voiceicon.spr sprites/wall_puff1.spr sprites/wall_puff2.spr sprites/wall_puff3.spr
sprites/wall_puff4.spr sprites/zerogxplode.spr'''.split())
_GAME_BASE_SOUNDS_L = {s.lower() for s in GAME_BASE_SOUNDS}
_GAME_BASE_MODELS_L = {s.lower() for s in GAME_BASE_MODELS}

_NULL = 'common/null.wav'
_DOOR_MOVE = {i: f'doors/doormove{i}.wav' for i in range(1, 11)}
_DOOR_STOP = {i: f'doors/doorstop{i}.wav' for i in range(1, 9)}
_BUTTON = {0: _NULL, 12: 'buttons/latchlocked1.wav', 13: 'buttons/latchunlocked1.wav', 14: 'buttons/lightswitch2.wav'}
_BUTTON.update({i: f'buttons/button{i}.wav' for i in range(1, 12)})
_BUTTON.update({20 + i: f'buttons/lever{i}.wav' for i in range(1, 6)})
_PLAT_MOVE = {1: 'plats/bigmove1.wav', 2: 'plats/bigmove2.wav', 3: 'plats/elevmove1.wav', 4: 'plats/elevmove2.wav',
              5: 'plats/elevmove3.wav', 6: 'plats/freightmove1.wav', 7: 'plats/freightmove2.wav',
              8: 'plats/heavymove1.wav', 9: 'plats/rackmove1.wav', 10: 'plats/railmove1.wav',
              11: 'plats/squeekmove1.wav', 12: 'plats/talkmove1.wav', 13: 'plats/talkmove2.wav'}
_PLAT_STOP = {1: 'plats/bigstop1.wav', 2: 'plats/bigstop2.wav', 3: 'plats/freightstop1.wav', 4: 'plats/heavystop2.wav',
              5: 'plats/rackstop1.wav', 6: 'plats/railstop1.wav', 7: 'plats/squeekstop1.wav', 8: 'plats/talkstop1.wav'}
_TTRAIN = {1: 'plats/ttrain1.wav', 2: 'plats/ttrain2.wav', 3: 'plats/ttrain3.wav', 4: 'plats/ttrain4.wav',
           5: 'plats/ttrain6.wav', 6: 'plats/ttrain7.wav'}
_SPARKS = [f'buttons/spark{i}.wav' for i in range(1, 7)]
# func_breakable "material": (gib model, break sounds, material (impact) sounds)
_MATERIAL = {
    0: ('models/glassgibs.mdl', ['debris/bustglass1.wav', 'debris/bustglass2.wav'], ['debris/glass1.wav', 'debris/glass2.wav', 'debris/glass3.wav']),
    1: ('models/woodgibs.mdl', ['debris/bustcrate1.wav', 'debris/bustcrate2.wav'], ['debris/wood1.wav', 'debris/wood2.wav', 'debris/wood3.wav']),
    2: ('models/metalplategibs.mdl', ['debris/bustmetal1.wav', 'debris/bustmetal2.wav'], ['debris/metal1.wav', 'debris/metal2.wav', 'debris/metal3.wav']),
    3: ('models/fleshgibs.mdl', ['debris/bustflesh1.wav', 'debris/bustflesh2.wav'],
        [f'debris/flesh{i}.wav' for i in (1, 2, 3, 5, 6, 7)]),
    4: ('models/cindergibs.mdl', ['debris/bustconcrete1.wav', 'debris/bustconcrete2.wav'], ['debris/concrete1.wav', 'debris/concrete2.wav', 'debris/concrete3.wav']),
    5: ('models/ceilinggibs.mdl', ['debris/bustceiling.wav'], []),
    6: ('models/computergibs.mdl', ['buttons/spark5.wav', 'buttons/spark6.wav', 'debris/bustmetal1.wav', 'debris/bustmetal2.wav'],
        ['debris/metal1.wav', 'debris/metal2.wav', 'debris/metal3.wav']),
    7: ('models/glassgibs.mdl', ['debris/bustglass1.wav', 'debris/bustglass2.wav'], ['debris/glass1.wav', 'debris/glass2.wav', 'debris/glass3.wav']),
    8: ('models/rockgibs.mdl', ['debris/bustconcrete1.wav', 'debris/bustconcrete2.wav'], ['debris/concrete1.wav', 'debris/concrete2.wav', 'debris/concrete3.wav']),
}
_SHOOTER_MAT = {0: 0, 1: 1, 2: 2, 3: 3, 4: 8}


def _ival(e, k, d=0) -> int:
    try:
        return int(float(e.get(k, d)))
    except (TypeError, ValueError):
        return d


def entity_precache(e: Dict[str, str]) -> Tuple[List[str], List[str]]:
    """(sounds, models) the game DLL precaches for this entity (ReGameDLL rules for the
    stock map entities; '*n' brush models are not included)."""
    cls = e.get('classname', '')
    snd: List[str] = []
    mdl: List[str] = []
    if cls in ('func_door', 'func_door_rotating', 'func_water', 'momentary_door'):
        snd.append(_DOOR_MOVE.get(_ival(e, 'movesnd'), _NULL))
        if cls != 'momentary_door':
            snd.append(_DOOR_STOP.get(_ival(e, 'stopsnd'), _NULL))
        for k in ('locked_sound', 'unlocked_sound'):
            if _ival(e, k):
                snd.append(_BUTTON.get(_ival(e, k), 'buttons/button9.wav'))
    elif cls in ('func_button', 'func_rot_button', 'momentary_rot_button'):
        snd.append(_BUTTON.get(_ival(e, 'sounds'), 'buttons/button9.wav'))
        if cls == 'func_button' and _ival(e, 'spawnflags') & 64:      # SF_BUTTON_SPARK_IF_OFF
            snd += _SPARKS
        for k in ('locked_sound', 'unlocked_sound'):
            if _ival(e, k):
                snd.append(_BUTTON.get(_ival(e, k), 'buttons/button9.wav'))
    elif cls in ('func_breakable', 'func_pushable'):
        if cls == 'func_pushable':
            snd += ['debris/pushbox1.wav', 'debris/pushbox2.wav', 'debris/pushbox3.wav']
        if cls == 'func_breakable' or _ival(e, 'spawnflags') & 128:    # SF_PUSH_BREAKABLE
            gib, bust, mat = _MATERIAL.get(_ival(e, 'material'), (None, [], []))
            snd += bust + mat
            gib = e.get('gibmodel') or gib
            if gib:
                mdl.append(gib)
        if e.get('spawnobject'):
            pass                                                        # item precached by the game anyway
    elif cls in ('func_plat', 'func_platrot', 'func_train'):
        snd.append(_PLAT_MOVE.get(_ival(e, 'movesnd'), _NULL))
        snd.append(_PLAT_STOP.get(_ival(e, 'stopsnd'), _NULL))
    elif cls == 'func_tracktrain':
        if _ival(e, 'sounds') in _TTRAIN:
            snd.append(_TTRAIN[_ival(e, 'sounds')])
        snd += ['plats/ttrain_brake1.wav', 'plats/ttrain_start1.wav']
    elif cls == 'func_vehicle':
        if 1 <= _ival(e, 'sounds') <= 7:
            snd.append(f'plats/vehicle{_ival(e, "sounds")}.wav')
        snd += ['plats/vehicle_brake1.wav', 'plats/vehicle_start1.wav']
    elif cls == 'func_rotating':
        msg = e.get('message', '')
        if msg:
            snd.append(msg)
        elif 1 <= _ival(e, 'sounds') <= 5:
            snd.append(f'fans/fan{_ival(e, "sounds")}.wav')
    elif cls == 'ambient_generic':
        msg = e.get('message', '')
        if len(msg) > 1 and not msg.startswith('!'):
            snd.append(msg)
    elif cls in ('env_spark', 'env_debris'):
        snd += _SPARKS
    elif cls == 'env_message':
        if e.get('messagesound'):
            snd.append(e['messagesound'])
    elif cls == 'env_shooter':
        if e.get('shootmodel'):
            mdl.append(e['shootmodel'])
        m = _SHOOTER_MAT.get(_ival(e, 'shootsounds', -1))
        if m is not None:
            snd += _MATERIAL[m][2]
    elif cls == 'env_beverage':
        mdl.append('models/can.mdl')
        snd.append('weapons/g_bounce3.wav')
    elif cls == 'func_healthcharger':
        snd += ['items/medshot4.wav', 'items/medshotno1.wav', 'items/medcharge4.wav']
    elif cls == 'func_recharge':
        snd += ['items/suitcharge1.wav', 'items/suitchargeno1.wav', 'items/suitchargeok1.wav']
    elif cls in ('env_beam', 'env_laser'):
        for k in ('texture', 'EndSprite'):
            if e.get(k):
                mdl.append(e[k])
    elif cls == 'env_funnel':
        mdl.append('sprites/flare6.spr')
    if cls not in ('worldspawn',) and not cls.startswith(('func_', 'trigger_', 'info_')):
        m = e.get('model', '')
        if m and not m.startswith('*') and m.lower().endswith(('.mdl', '.spr')):
            mdl.append(m)
    norm = lambda s: s.replace('\\', '/')
    return [norm(s) for s in snd], [norm(m) for m in mdl]


def entity_budget(b: 'BSP', opts: Optional[dict] = None) -> dict:
    """Precache impact of the map's entities: brush entities (each '*n' model is one model
    precache slot), sounds and studio/sprite models the game DLL precaches for them.
    'new' = not already precached by the game DLL on every map (plugin precaches not counted)."""
    o = dict(PERF_DEFAULTS, **(opts or {}))
    brush = sorted({int(e['model'][1:]) for e in b.entities if e.get('model', '').startswith('*')})
    snd_by: Dict[str, List[str]] = {}
    mdl_by: Dict[str, List[str]] = {}
    for e in b.entities:
        s, m = entity_precache(e)
        for x in s:
            snd_by.setdefault(x, []).append(e.get('classname', '?'))
        for x in m:
            mdl_by.setdefault(x, []).append(e.get('classname', '?'))
    new_snd = sorted(s for s in snd_by if s.lower() not in _GAME_BASE_SOUNDS_L)
    new_mdl = sorted(m for m in mdl_by if m.lower() not in _GAME_BASE_MODELS_L)
    custom_snd = sorted(s for s in snd_by if 'vexmira' in s.lower())
    return {
        'brush_entities': len(brush),
        'brush_models_in_bsp': len(b.models) - 1,
        'sounds_referenced': sorted(snd_by),
        'sounds_new': new_snd,
        'sounds_custom': custom_snd,
        'sound_users': {k: sorted(set(v)) for k, v in snd_by.items()},
        'models_referenced': sorted(mdl_by),
        'models_new': new_mdl,
        'model_slots_new': len(brush) + len(new_mdl),
        'sound_slots_new': len(new_snd),
        'max_brush_ents': o['max_brush_ents'],
        'max_map_sounds': o['max_map_sounds'],
    }


# ---------------------------------------------------------------- geometry helpers
def _subdivide_count(v: np.ndarray, size: float) -> int:
    """Number of GL polys GL_SubdivideSurface makes of a warped face (SubdividePolygon_r)."""
    mins, maxs = v.min(0), v.max(0)
    for i in range(3):
        m = (mins[i] + maxs[i]) * 0.5
        m = size * math.floor(m / size + 0.5)
        if maxs[i] - m < 8 or m - mins[i] < 8:
            continue
        dist = v[:, i] - m
        front, back = [], []
        n = len(v)
        for j in range(n):
            p, d = v[j], dist[j]
            if d >= 0:
                front.append(p)
            if d <= 0:
                back.append(p)
            q, dq = v[(j + 1) % n], dist[(j + 1) % n]
            if d == 0 or dq == 0:
                continue
            if (d > 0) != (dq > 0):
                mid = p + (d / (d - dq)) * (q - p)
                front.append(mid)
                back.append(mid)
        return _subdivide_count(np.array(front), size) + _subdivide_count(np.array(back), size)
    return 1


def _frustum_normals(yaw: float, pitch: float, fov_x: float, fov_y: float) -> np.ndarray:
    """4 inward frustum plane normals (R_SetFrustum), pitch in degrees up."""
    y, p = math.radians(yaw), math.radians(pitch)
    f = np.array([math.cos(p) * math.cos(y), math.cos(p) * math.sin(y), math.sin(p)])
    r = np.array([math.sin(y), -math.cos(y), 0.0])
    u = np.cross(r, f)
    hx, hy = math.radians(fov_x / 2), math.radians(fov_y / 2)
    return np.array([f * math.sin(hx) - r * math.cos(hx), f * math.sin(hx) + r * math.cos(hx),
                     f * math.sin(hy) - u * math.cos(hy), f * math.sin(hy) + u * math.cos(hy)])


def _stats(a) -> dict:
    a = np.asarray(a, np.float64)
    if a.size == 0:
        return {'n': 0, 'max': 0, 'p95': 0, 'p50': 0, 'mean': 0}
    return {'n': int(a.size), 'max': int(a.max()), 'p95': int(round(float(np.percentile(a, 95)))),
            'p50': int(round(float(np.percentile(a, 50)))), 'mean': int(round(float(a.mean())))}


def _miptex_bytes(m: Optional[Miptex]) -> int:
    if m is None:
        return 0
    if not m.embedded:
        return 40
    return 40 + (m.width * m.height * 85) // 64 + 2 + 768


class _World:
    """Precomputed world tree / face / entity data for the perf analysis."""

    def __init__(self, b: 'BSP', o: dict):
        self.b = b
        nvis = int(b.models[0]['visleafs'])
        self.nvis = nvis
        L = nvis + 1                                       # leaf indices 0..nvis (0 = shared solid leaf)
        self.L = L
        leafs = b.leafs[:L]
        self.contents = leafs['contents'].astype(np.int32)
        self.leaf_mins = leafs['mins'].astype(np.float64)
        self.leaf_maxs = leafs['maxs'].astype(np.float64)
        nn = len(b.nodes)
        self.nn = nn
        # world tree parents
        head = int(b.models[0]['headnode'][0])
        self.head = head
        npar = np.full(nn, -2, np.int64)
        lpar = np.full(max(L, 1), -2, np.int64)
        npar[head] = -1
        stack = [head]
        world_nodes = []
        ch = b.nodes['children']
        while stack:
            n = stack.pop()
            world_nodes.append(n)
            for c in ch[n]:
                c = int(c)
                if c >= 0:
                    npar[c] = n
                    stack.append(c)
                elif -c - 1 < L:
                    lpar[-c - 1] = n
        self.node_parent, self.leaf_parent = npar, lpar
        self.world_nodes = np.array(sorted(world_nodes), np.int64)
        self.node_mins = b.nodes['mins'].astype(np.float64)
        self.node_maxs = b.nodes['maxs'].astype(np.float64)
        # faces: kind / polys / planes
        nf = len(b.faces)
        names = [(m.name.lower() if m else '') for m in b.miptex]
        ti_tex = b.texinfo['miptex']
        kind = np.zeros(nf, np.int8)                   # 0 normal, 1 sky, 2 warped
        poly = np.ones(nf, np.float64)
        for i in range(nf):
            mt = int(ti_tex[b.faces[i]['texinfo']])
            nm = names[mt] if 0 <= mt < len(names) else ''
            if nm.startswith('sky'):
                kind[i], poly[i] = 1, 0
            elif nm.startswith(('!', 'water', 'laser')):
                kind[i] = 2
                poly[i] = _subdivide_count(b.face_vertices(i), o['subdivide'])
        self.kind, self.poly = kind, poly
        self.unit = (kind != 1).astype(np.float64)      # r_speeds counter: one per drawn face (warped too)
        pl = b.planes[b.faces['planenum']]
        self.fn = pl['normal'].astype(np.float64)
        self.fd = pl['dist'].astype(np.float64)
        self.fback = b.faces['side'] != 0
        nwf = int(b.models[0]['numfaces'])
        self.nwf = nwf
        face_node = np.full(nwf, -1, np.int64)
        for n in self.world_nodes:
            ff, fc = int(b.nodes[n]['firstface']), int(b.nodes[n]['numfaces'])
            face_node[ff:min(ff + fc, nwf)] = n
        self.face_node = face_node
        # marksurfaces of world leaves 1..nvis, flattened
        first = leafs['firstmarksurface'].astype(np.int64)
        num = leafs['nummarksurfaces'].astype(np.int64)
        num[0] = 0
        tot = int(num.sum())
        owner = np.repeat(np.arange(L), num)
        idx = np.arange(tot) - np.repeat(np.cumsum(num) - num, num) + np.repeat(first, num)
        mf = b.marksurfaces[idx].astype(np.int64) if tot else np.zeros(0, np.int64)
        ok = mf < nwf
        self.mark_leaf, self.mark_face = owner[ok], mf[ok]
        # faces referenced by water/slime/lava leaves are "underwater" (no backface culling)
        nocull = kind == 2
        wl = np.nonzero(self.contents[self.mark_leaf] < -2)[0]
        nocull[self.mark_face[wl]] = True
        self.nocull = nocull
        # PVS rows (packed)
        self.rowbytes = (nvis + 7) >> 3
        self.novis = len(b.visdata) == 0
        self._rows: Dict[int, np.ndarray] = {}
        self._entities(o)

    # ---------------- PVS
    def pvs(self, leaf: int) -> np.ndarray:
        """bool[L]: leaves visible from leaf (index = leaf number, own leaf included)."""
        r = self._rows.get(leaf)
        if r is not None:
            return r
        L = self.L
        ofs = int(self.b.leafs[leaf]['visofs']) if 0 < leaf < L else -1
        row = np.zeros(L, bool)
        if leaf <= 0 or leaf >= L:
            pass
        elif self.novis or ofs < 0:
            row[1:] = True
        else:
            vd = self.b.visdata
            out = bytearray()
            i, n = ofs, len(vd)
            while len(out) < self.rowbytes and i < n:
                c = vd[i]
                if c:
                    out.append(c)
                    i += 1
                else:
                    out.extend(bytes(vd[i + 1] if i + 1 < n else 0))
                    i += 2
            out = bytes(out[:self.rowbytes]).ljust(self.rowbytes, b'\0')
            bits = np.unpackbits(np.frombuffer(out, np.uint8), bitorder='little')[:self.nvis].astype(bool)
            row[1:] = bits
            row[leaf] = True
        row[0] = False
        self._rows[leaf] = row
        return row

    def marked_nodes(self, row: np.ndarray) -> np.ndarray:
        m = np.zeros(self.nn, bool)
        cur = self.leaf_parent[np.nonzero(row)[0]]
        cur = np.unique(cur[cur >= 0])
        while cur.size:
            cur = cur[~m[cur]]
            m[cur] = True
            cur = self.node_parent[cur]
            cur = np.unique(cur[cur >= 0])
        return m

    def point_leaf(self, p) -> int:
        b = self.b
        p = np.asarray(p, np.float64)
        num = self.head
        planes, nodes = b.planes, b.nodes
        while num >= 0:
            nd = nodes[num]
            pl = planes[nd['planenum']]
            t = int(pl['type'])
            d = (p[t] if t < 3 else float(np.dot(pl['normal'], p))) - pl['dist']
            num = int(nd['children'][0 if d >= 0 else 1])
        return -num - 1

    def box_leaves(self, mins, maxs) -> np.ndarray:
        """World leaves touched by a box (SV_FindTouchedLeafs, non-solid only)."""
        b = self.b
        out = []
        stack = [self.head]
        mins, maxs = np.asarray(mins, np.float64), np.asarray(maxs, np.float64)
        while stack:
            n = stack.pop()
            if n < 0:
                lf = -n - 1
                if 0 < lf < self.L and self.contents[lf] != -2:
                    out.append(lf)
                continue
            nd = b.nodes[n]
            pl = b.planes[nd['planenum']]
            nrm = pl['normal'].astype(np.float64)
            hi = float(np.sum(np.maximum(nrm * mins, nrm * maxs)))
            lo = float(np.sum(np.minimum(nrm * mins, nrm * maxs)))
            if hi >= pl['dist']:
                stack.append(int(nd['children'][0]))
            if lo < pl['dist']:
                stack.append(int(nd['children'][1]))
        return np.array(sorted(set(out)), np.int64)

    # ---------------- brush entities
    def _entities(self, o):
        b = self.b
        ents = []
        for e in b.entities:
            m = e.get('model', '')
            if not m.startswith('*'):
                continue
            try:
                mi = int(m[1:])
            except ValueError:
                continue
            if mi <= 0 or mi >= len(b.models):
                continue
            md = b.models[mi]
            cls = e.get('classname', '')
            off = _vec(e['origin']) if 'origin' in e else md['origin'].astype(np.float64)
            rm, ra = _ival(e, 'rendermode'), _ival(e, 'renderamt')
            drawn = not (cls.startswith('trigger_') or cls in NODRAW_BRUSH_CLASSES or (rm != 0 and ra <= 0)
                         or (_ival(e, 'effects') & 128))
            ff, fc = int(md['firstface']), int(md['numfaces'])
            mins = md['mins'].astype(np.float64) + off
            maxs = md['maxs'].astype(np.float64) + off
            ents.append({'model': mi, 'classname': cls, 'targetname': e.get('targetname', ''), 'drawn': bool(drawn),
                         'solid': cls in SOLID_BRUSH_CLASSES, 'rendermode': rm, 'renderamt': ra, 'off': off,
                         'mins': mins, 'maxs': maxs, 'ff': ff, 'fc': fc,
                         'leaves': self.box_leaves(mins - 1, maxs + 1)})
        self.ents = ents
        E = len(ents)
        self.E = E
        self.ent_touch = np.zeros((E, self.L), bool)
        for i, en in enumerate(ents):
            self.ent_touch[i, en['leaves']] = True
        self.ent_drawn = np.array([en['drawn'] for en in ents], bool)
        self.ent_mins = np.array([en['mins'] for en in ents]).reshape(E, 3)
        self.ent_maxs = np.array([en['maxs'] for en in ents]).reshape(E, 3)
        fidx = np.concatenate([np.arange(en['ff'], en['ff'] + en['fc']) for en in ents]) if E else np.zeros(0, np.int64)
        fidx = fidx.astype(np.int64)
        self.ef = fidx
        self.eowner = np.concatenate([np.full(en['fc'], i) for i, en in enumerate(ents)]) if E else np.zeros(0, np.int64)
        self.eoff = np.array([en['off'] for en in ents]).reshape(E, 3)
        self.ent_polys = np.bincount(self.eowner, weights=self.poly[fidx], minlength=E) if E else np.zeros(0)
        self.ent_units = np.bincount(self.eowner, weights=self.unit[fidx], minlength=E) if E else np.zeros(0)
        self.ent_faces = np.array([en['fc'] for en in ents], np.int64)
        self.ent_visible_polys = np.where(self.ent_drawn, self.ent_polys, 0.0)

    def ent_pvs(self, row: np.ndarray) -> np.ndarray:
        if not self.E:
            return np.zeros(0, bool)
        return (self.ent_touch & row[None, :]).any(1)


class _Viewer:
    """Replays the GL renderer's world + brush entity drawing from an eye position for a fixed
    set of view directions (R_MarkLeaves, R_RecursiveWorldNode with R_CullBox and the plane side
    test, R_DrawBrushModel).  eval(eye) -> (leaf, total[D], world[D], ents[D], faces[D]) per direction:
    GL polys (warped faces subdivided), world / brush-entity part, and the r_speeds counter (one per
    drawn face).  dirs: [(yaw, pitch_up_degrees)], default o['yaws'] x o['pitches']."""

    def __init__(self, w: _World, o: dict, dirs=None):
        self.w = w
        fov_x0 = float(o['fov'])
        self.fov_y = math.degrees(2 * math.atan(math.tan(math.radians(fov_x0 / 2)) * 3.0 / 4.0))
        self.fov_x = math.degrees(2 * math.atan(math.tan(math.radians(self.fov_y / 2)) * float(o['aspect'])))
        self.dirs = list(dirs) if dirs else \
            [(360.0 * k / int(o['yaws']), float(p)) for p in o['pitches'] for k in range(int(o['yaws']))]
        self.Nn = np.stack([_frustum_normals(y, p, self.fov_x, self.fov_y) for y, p in self.dirs])   # (D,4,3)
        # boxes: all nodes, leaves 0..nvis, brush entities; box passes a plane if its farthest corner is in front
        bmins = np.concatenate([w.node_mins, w.leaf_mins, w.ent_mins])
        bmaxs = np.concatenate([w.node_maxs, w.leaf_maxs, w.ent_maxs])
        bc, bh = (bmins + bmaxs) / 2, (bmaxs - bmins) / 2
        self.A = np.einsum('dpk,nk->dpn', self.Nn, bc) + np.einsum('dpk,nk->dpn', np.abs(self.Nn), bh)
        nwf = w.nwf
        self.pw = w.poly[:nwf]
        self.p1 = w.unit[:nwf]
        self.fnw, self.fdw, self.fbw, self.ncw = w.fn[:nwf], w.fd[:nwf], w.fback[:nwf], w.nocull[:nwf]
        self.fnode_ok = w.face_node >= 0
        self.static = self.fnode_ok & (self.pw > 0)
        self.efn, self.efd, self.efb = w.fn[w.ef], w.fd[w.ef], w.fback[w.ef]
        self.efnc, self.efp, self.ef1 = w.nocull[w.ef], w.poly[w.ef], w.unit[w.ef]
        self.cache: Dict[int, tuple] = {}

    def leaf_data(self, lf: int):
        """Everything that depends only on the view leaf, restricted to its PVS: visible leaves,
        their marksurfaces, the candidate faces, the marked nodes and their frustum box terms."""
        c = self.cache.get(lf)
        if c is not None:
            return c
        w = self.w
        row = w.pvs(lf)
        vl = np.nonzero(row)[0]                                          # visible leaves
        mn = np.nonzero(w.marked_nodes(row))[0]                          # their ancestors (R_MarkLeaves)
        sel = row[w.mark_leaf]
        mleaf = np.searchsorted(vl, w.mark_leaf[sel])                    # local leaf index
        cf, mface = np.unique(w.mark_face[sel], return_inverse=True)    # candidate faces, local face index
        node_local = np.full(w.nn, -1, np.int64)
        node_local[mn] = np.arange(len(mn))
        fnl = node_local[np.where(self.fnode_ok[cf], w.face_node[cf], 0)]
        fok = self.static[cf] & (fnl >= 0)                             # drawable face on a marked node
        ev = np.nonzero(w.ent_pvs(row) & w.ent_drawn)[0] if w.E else np.zeros(0, np.int64)
        boxes = np.concatenate([mn, w.nn + vl, w.nn + w.L + ev])
        c = {'row': row, 'A': self.A[:, :, boxes], 'nN': len(mn), 'nL': len(vl), 'mleaf': mleaf, 'mface': mface,
             'cf': cf, 'fnl': np.where(fnl >= 0, fnl, 0), 'fok': fok, 'fn': self.fnw[cf], 'fd': self.fdw[cf],
             'fb': self.fbw[cf], 'nc': self.ncw[cf], 'pw': self.pw[cf], 'p1': self.p1[cf], 'ev': ev}
        self.cache[lf] = c
        return c

    def eval(self, eye):
        w = self.w
        eye = np.asarray(eye, np.float64)
        D = len(self.dirs)
        lf = w.point_leaf(eye)
        c = self.leaf_data(lf)
        nN, nL, F = c['nN'], c['nL'], len(c['cf'])
        dd = self.Nn @ eye                                              # (D,4)
        passb = (c['A'] >= dd[:, :, None] - 1e-6).all(1)                # (D, boxes): R_CullBox
        passN, passL, passE = passb[:, :nN], passb[:, nN:nN + nL], passb[:, nN + nL:]
        if F:
            di, mi = np.nonzero(passL[:, c['mleaf']])                   # leaf reached -> marks its faces
            marked = np.zeros((D, F), bool)
            marked[di, c['mface'][mi]] = True
            facing = ((c['fn'] @ eye - c['fd'] < 0) == c['fb']) | c['nc']
            drawn = (marked & passN[:, c['fnl']] & (c['fok'] & facing)[None, :]).astype(np.float64)
            vw, nw = drawn @ c['pw'], drawn @ c['p1']
        else:
            vw = nw = np.zeros(D)
        if len(c['ev']):
            sel = np.isin(w.eowner, c['ev'])
            own = w.eowner[sel]
            edots = np.einsum('mk,mk->m', self.efn[sel], eye[None, :] - w.eoff[own]) - self.efd[sel]
            efacing = ((edots < 0) == self.efb[sel]) | self.efnc[sel]
            per_ent = np.bincount(own, weights=self.efp[sel] * efacing, minlength=w.E)[c['ev']]
            per_ent1 = np.bincount(own, weights=self.ef1[sel] * efacing, minlength=w.E)[c['ev']]
            pe = passE.astype(np.float64)
            ve, ne = pe @ per_ent, pe @ per_ent1
        else:
            ve = ne = np.zeros(D)
        return lf, vw + ve, vw, ve, nw + ne


def _floor_samples(w: _World, o: dict) -> List[np.ndarray]:
    """Eye positions (floor + 53) on every walkable floor face (world + solid brush entities),
    on a world grid of o['spacing'] units plus each face centre; player hull 1 must fit."""
    b = w.b
    S = float(o['spacing'])
    solid_ents = [en for en in w.ents if en['solid']]
    faces = [(i, None) for i in range(w.nwf)]
    for en in solid_ents:
        faces += [(i, en) for i in range(en['ff'], en['ff'] + en['fc'])]
    keys = {}
    for i, en in faces:
        if w.kind[i] != 0:
            continue
        n = w.fn[i] * (-1.0 if w.fback[i] else 1.0)
        if n[2] < 0.7:
            continue
        V = b.face_vertices(i)
        off = en['off'] if en is not None else np.zeros(3)
        V = V + off
        d = float(np.dot(w.fn[i], off) + w.fd[i])
        lo, hi = V[:, :2].min(0), V[:, :2].max(0)
        xs = np.arange(math.ceil(lo[0] / S) * S, hi[0] + 1e-6, S)
        ys = np.arange(math.ceil(lo[1] / S) * S, hi[1] + 1e-6, S)
        pts = [V[:, :2].mean(0)]
        if xs.size and ys.size:
            gx, gy = np.meshgrid(xs, ys)
            P = np.stack([gx.ravel(), gy.ravel()], 1)
            e0 = V[:, :2]
            e1 = np.roll(e0, -1, 0)
            cr = (e1[None, :, 0] - e0[None, :, 0]) * (P[:, None, 1] - e0[None, :, 1]) - \
                 (e1[None, :, 1] - e0[None, :, 1]) * (P[:, None, 0] - e0[None, :, 0])
            inside = (cr >= -1e-3).all(1) | (cr <= 1e-3).all(1)
            pts += list(P[inside])
        slope = 16.0 * (abs(w.fn[i][0]) + abs(w.fn[i][1])) / max(abs(w.fn[i][2]), 1e-6)
        for x, y in pts:
            z = (d - w.fn[i][0] * x - w.fn[i][1] * y) / w.fn[i][2]
            org = np.array([x, y, z + 36.0 + slope + 1.0])
            eye = org + (0, 0, EYE_HEIGHT - 36.0)
            k = tuple(np.round(eye / 48.0).astype(int))
            if k not in keys:
                keys[k] = (org, eye)
    # spawn points
    for e in b.entities:
        if e.get('classname') in ('info_player_start', 'info_player_deathmatch') and 'origin' in e:
            org = _vec(e['origin'])
            eye = org + (0, 0, EYE_HEIGHT - 36.0)
            keys.setdefault(tuple(np.round(eye / 48.0).astype(int)), (org, eye))
    items = [keys[k] for k in sorted(keys)]
    if len(items) > o['max_samples'] * 2:
        step = len(items) / (o['max_samples'] * 2)
        items = [items[int(i * step)] for i in range(o['max_samples'] * 2)]
    out = []
    for org, eye in items:
        if b.point_contents(org, 1) == -2:
            continue
        stuck = False
        for en in solid_ents:
            if ((org + (16, 16, 36)) < en['mins']).any() or ((org - (16, 16, 36)) > en['maxs']).any():
                continue
            if b.point_contents(org, 1, en['model'], en['off']) == -2:
                stuck = True
                break
        if stuck:
            continue
        lf = w.point_leaf(eye)
        if lf <= 0 or lf >= w.L or w.contents[lf] in (-2, -6):
            continue
        out.append(eye)
        if len(out) >= o['max_samples']:
            break
    return out


def perf_analysis(src, opts: Optional[dict] = None) -> dict:
    """Rendering-cost analysis of a compiled BSP (path or BSP). Returns a dict (JSON-safe);
    see the section comment above for the metrics.  opts: PERF_DEFAULTS keys."""
    import time
    t0 = time.time()
    o = dict(PERF_DEFAULTS, **(opts or {}))
    b = src if isinstance(src, BSP) else BSP(src)
    import os
    w = _World(b, o)
    L, nwf = w.L, w.nwf
    res: Dict[str, object] = {'settings': {k: (list(v) if isinstance(v, tuple) else v) for k, v in o.items()}}
    errs: List[str] = []
    warns: List[str] = []

    # ------------------------------------------------ totals
    tex_bytes = [(_miptex_bytes(m), m.name if m else '?', (m.width, m.height) if m else (0, 0)) for m in b.miptex]
    drawable_world = int((w.kind[:nwf] != 1).sum())
    res['totals'] = {
        'bsp_bytes': os.path.getsize(b.path) if os.path.exists(b.path) else len(b.raw),
        'world_faces': nwf, 'world_faces_drawable': drawable_world,
        'world_polys': int(w.poly[:nwf].sum()),
        'sky_faces': int((w.kind[:nwf] == 1).sum()),
        'warped_faces': int((w.kind[:nwf] == 2).sum()), 'warped_polys': int(w.poly[:nwf][w.kind[:nwf] == 2].sum()),
        'total_faces': len(b.faces),
        'leaves': w.nvis, 'open_leaves': int(((w.contents[1:] != -2) & (w.contents[1:] != -6)).sum()),
        'brush_entities': w.E, 'brush_entities_drawn': int(w.ent_drawn.sum()),
        'brush_entity_faces_drawn': int(w.ent_faces[w.ent_drawn].sum()) if w.E else 0,
        'textures': len(b.miptex), 'texture_bytes': b.lumpsize('textures'),
        'textures_largest': [f'{n} {s[0]}x{s[1]} {v // 1024}K' for v, n, s in sorted(tex_bytes, reverse=True)[:3]],
        'lightmap_bytes': len(b.lighting), 'vis_bytes': len(b.visdata), 'novis': w.novis,
    }

    # ------------------------------------------------ per-leaf PVS metric
    leaves = np.array([l for l in range(1, L) if w.contents[l] not in (-2, -6)], np.int64)
    pv_faces = np.zeros(len(leaves))
    pv_world = np.zeros(len(leaves))
    pv_ent = np.zeros(len(leaves))
    pv_nleaf = np.zeros(len(leaves))
    drawable = w.kind[:nwf] != 1
    pw = w.poly[:nwf]
    # gather only the marksurfaces of the visible leaves (mark arrays are grouped by leaf)
    mcount = np.bincount(w.mark_leaf, minlength=L)
    mstart = np.cumsum(mcount) - mcount
    for i, l in enumerate(leaves):
        row = w.pvs(int(l))
        vl = np.flatnonzero(row)
        cnt = mcount[vl]
        tot = int(cnt.sum())
        idx = np.repeat(mstart[vl] - (np.cumsum(cnt) - cnt), cnt) + np.arange(tot)
        f = np.unique(w.mark_face[idx])
        pv_faces[i] = int(drawable[f].sum())
        pv_world[i] = float(pw[f].sum())
        pv_nleaf[i] = len(vl)
        if w.E:
            pv_ent[i] = float(w.ent_visible_polys[w.ent_touch[:, vl].any(1)].sum())
    pv_total = pv_world + pv_ent
    res['pvs'] = {'faces': _stats(pv_faces), 'world_wpoly': _stats(pv_world), 'ent_wpoly': _stats(pv_ent),
                  'total': _stats(pv_total), 'visible_leaves': _stats(pv_nleaf),
                  'visible_leaf_fraction': round(float(pv_nleaf.mean() / max(w.nvis, 1)), 3) if len(leaves) else 0}

    # ------------------------------------------------ view metric at player eye positions
    V = _Viewer(w, o)
    eyes = _floor_samples(w, o)
    view_tot, view_world, view_ent, view_faces, view_dir, view_leaf = [], [], [], [], [], []
    for eye in eyes:
        lf, tot, vw, ve, nf = V.eval(eye)
        k = int(np.argmax(tot))
        view_tot.append(tot[k])
        view_world.append(vw[k])
        view_ent.append(ve[k])
        view_faces.append(nf[k])
        view_dir.append(V.dirs[k])
        view_leaf.append(lf)
    D, fov_x, fov_y = len(V.dirs), V.fov_x, V.fov_y
    view_tot = np.array(view_tot)
    res['view'] = {'samples': len(eyes), 'fov': [round(fov_x, 1), round(fov_y, 1)], 'directions': D,
                   'total': _stats(view_tot), 'world_wpoly': _stats(view_world), 'ent_wpoly': _stats(view_ent),
                   'faces': _stats(view_faces)}

    # ------------------------------------------------ worst spots
    player_leaves = set(view_leaf)
    order = np.argsort(-pv_total, kind='stable')
    worst_leaves = []
    for i in order[:5]:
        l = int(leaves[i])
        mn, mx = w.leaf_mins[l], w.leaf_maxs[l]
        worst_leaves.append({'leaf': l, 'centre': ((mn + mx) / 2).round(0).tolist(), 'size': (mx - mn).round(0).tolist(),
                             'total': int(pv_total[i]), 'world': int(pv_world[i]), 'ents': int(pv_ent[i]),
                             'faces': int(pv_faces[i]), 'visible_leaves': int(pv_nleaf[i]),
                             'player': l in player_leaves})
    res['pvs']['worst'] = worst_leaves
    worst_views = []
    for i in np.argsort(-view_tot, kind='stable'):
        e = eyes[i]
        if any(np.linalg.norm(e - np.array(x['eye'])) < 192 for x in worst_views):
            continue
        worst_views.append({'eye': e.round(0).tolist(), 'yaw': view_dir[i][0], 'pitch': view_dir[i][1],
                            'total': int(view_tot[i]), 'world': int(view_world[i]), 'ents': int(view_ent[i]),
                            'faces': int(view_faces[i]), 'leaf': int(view_leaf[i])})
        if len(worst_views) >= 5:
            break
    res['view']['worst'] = worst_views
    # small enclosed vs open: the best leaves too (sanity)
    res['pvs']['best'] = [{'leaf': int(leaves[i]), 'centre': ((w.leaf_mins[leaves[i]] + w.leaf_maxs[leaves[i]]) / 2).round(0).tolist(),
                           'total': int(pv_total[i]), 'visible_leaves': int(pv_nleaf[i])}
                          for i in np.argsort(pv_total, kind='stable')[:3]]

    # ------------------------------------------------ brush entities, light styles, sprites
    heavy = []
    for i, en in enumerate(w.ents):
        if not en['drawn'] or en['fc'] == 0:
            continue
        heavy.append({'model': f"*{en['model']}", 'classname': en['classname'], 'faces': int(en['fc']),
                      'polys': int(w.ent_polys[i]), 'leaves': int(len(en['leaves'])),
                      'size': (en['maxs'] - en['mins']).round(0).tolist(), 'rendermode': en['rendermode']})
    heavy.sort(key=lambda x: -x['faces'])
    res['brush_entities'] = heavy[:8]
    st = b.faces['styles']
    anim = ((st >= 1) & (st < 32)).any(1)
    switch = ((st >= 32) & (st < 255)).any(1)
    lights = [e for e in b.entities if e.get('classname', '').startswith('light') and e.get('classname') != 'light_environment']
    styled = sorted({_ival(e, 'style') for e in lights if _ival(e, 'style')})
    sprites = [e for e in b.entities if e.get('classname') in SPRITE_CLASSES]
    res['lighting'] = {'light_entities': len(lights), 'animated_styles': [s for s in styled if s < 32],
                       'switchable_lights': sum(1 for e in lights if e.get('targetname')),
                       'animated_style_faces': int(anim.sum()), 'switchable_style_faces': int(switch.sum())}
    res['sprites'] = {'count': len(sprites), 'additive': sum(1 for e in sprites if _ival(e, 'rendermode') == 5),
                      'models': sorted({e.get('model', '') for e in sprites})}
    trans = [h for h in heavy if h['rendermode'] != 0]
    res['transparent_brush_faces'] = int(sum(h['faces'] for h in trans))

    # ------------------------------------------------ thresholds
    strict = bool(o['strict'])
    metric = o['metric']
    if metric == 'view' and not len(eyes):
        warns.append('perf: no player eye positions found (no walkable floors?) - thresholds use the PVS metric')
        metric = 'pvs'
    sv = res['view']['total'] if metric == 'view' else res['pvs']['total']
    where = ''
    if metric == 'view' and worst_views:
        wv = worst_views[0]
        where = f" at eye ({' '.join(str(int(x)) for x in wv['eye'])}) yaw {wv['yaw']:.0f}"
    elif worst_leaves:
        wl = worst_leaves[0]
        where = f" in leaf {wl['leaf']} around ({' '.join(str(int(x)) for x in wl['centre'])})"
    label = 'view wpoly (r_speeds estimate)' if metric == 'view' else 'PVS wpoly per leaf'
    if o['error_max'] and sv['max'] > o['error_max']:
        (errs if strict else warns).append(f"perf: max {label} {sv['max']} > {o['error_max']}{where}")
    if o['warn_p95'] and sv['p95'] > o['warn_p95']:
        warns.append(f"perf: p95 {label} {sv['p95']} > {o['warn_p95']}")
    if w.novis:
        warns.append('perf: no VIS data - every leaf sees everything')
    for h in heavy:
        if h['faces'] > o['ent_faces_warn']:
            warns.append(f"perf: brush entity {h['model']} {h['classname']} has {h['faces']} faces "
                         f"(spans {' x '.join(str(int(x)) for x in h['size'])}): drawn whole, not VIS-culled "
                         f"- make it world geometry or split it")
    if res['lighting']['animated_style_faces'] > o['anim_style_faces_warn']:
        warns.append(f"perf: {res['lighting']['animated_style_faces']} faces have animated light styles "
                     f"{res['lighting']['animated_styles']} (lightmap re-upload every frame)")
    if len(sprites) > o['sprites_warn']:
        warns.append(f"perf: {len(sprites)} sprite entities (env_sprite/env_glow) > {o['sprites_warn']}")
    tb = res['totals']['bsp_bytes']
    if o['max_bsp_mb'] and tb > o['max_bsp_mb'] * 1024 * 1024:
        (errs if strict else warns).append(f"budget: bsp {tb / 1048576:.2f} MB > {o['max_bsp_mb']} MB")
    res['metric'] = metric
    res['errors'], res['warnings'] = errs, warns
    res['seconds'] = round(time.time() - t0, 2)
    return res


def perf_at(src, points, opts: Optional[dict] = None) -> List[dict]:
    """PVS and view numbers at given eye positions, e.g. to compare two spots or to check a fix:
    bspcheck map.bsp --at "x y z" --at "x y z pitch yaw".  A point is (x, y, z) -> all o['yaws']
    directions, or (x, y, z, pitch, yaw) in engine angles (pitch > 0 looks down, like
    getpos / vexcam_pos) -> additionally that exact view ('exact')."""
    o = dict(PERF_DEFAULTS, **(opts or {}))
    b = src if isinstance(src, BSP) else BSP(src)
    w = _World(b, o)
    V = _Viewer(w, o)
    out = []
    for p in points:
        p = [float(x) for x in p]
        if len(p) not in (3, 5):
            raise ValueError(f'--at needs "x y z" or "x y z pitch yaw", got {p}')
        eye = np.asarray(p[:3], np.float64)
        lf, tot, vw, ve, nf = V.eval(eye)
        row = w.pvs(lf)
        marked = np.bincount(w.mark_face, weights=row[w.mark_leaf].astype(np.float64), minlength=w.nwf) > 0
        evis = w.ent_pvs(row) & w.ent_drawn if w.E else np.zeros(0, bool)
        pvs_world = float(marked.astype(np.float64) @ w.poly[:w.nwf])
        pvs_ent = float(evis.astype(np.float64) @ w.ent_polys) if w.E else 0.0
        k = int(np.argmax(tot))
        out.append({'eye': eye.round(1).tolist(), 'leaf': int(lf), 'contents': CONTENTS.get(int(w.contents[lf]) if 0 <= lf < w.L else -2, '?'),
                    'visible_leaves': int(row.sum()), 'pvs_faces': int((marked & (w.kind[:w.nwf] != 1)).sum()),
                    'pvs_world': int(pvs_world), 'pvs_ents': int(pvs_ent), 'pvs_total': int(pvs_world + pvs_ent),
                    'view_max': int(tot[k]), 'view_world': int(vw[k]), 'view_ents': int(ve[k]), 'view_faces': int(nf[k]),
                    'view_yaw': V.dirs[k][0],
                    'view_by_dir': {f'{y:.0f}/{pt:.0f}': int(t) for (y, pt), t in zip(V.dirs, tot)},
                    'ents_visible': [f"*{w.ents[i]['model']}" for i in np.nonzero(evis)[0]]})
        if len(p) == 5:
            _, t1, w1, e1, n1 = _Viewer(w, o, dirs=[(p[4], -p[3])]).eval(eye)
            out[-1]['exact'] = {'pitch': p[3], 'yaw': p[4], 'total': int(t1[0]), 'world': int(w1[0]),
                                'ents': int(e1[0]), 'faces': int(n1[0])}
    return out


def format_at(rows: List[dict]) -> str:
    L = []
    for r in rows:
        L.append(f"  at ({_xyz(r['eye'])}) leaf {r['leaf']} ({r['contents']}), sees {r['visible_leaves']} leaves: "
                 f"PVS total {r['pvs_total']} (world faces {r['pvs_faces']}, world wpoly {r['pvs_world']}, ents {r['pvs_ents']}); "
                 f"view max {r['view_max']} at yaw {r['view_yaw']:.0f} (world {r['view_world']} + ents {r['view_ents']}"
                 f"{'' if r['view_faces'] == r['view_max'] else '; ' + str(r['view_faces']) + ' faces'})")
        x = r.get('exact')
        if x:
            L.append(f"      view pitch {x['pitch']:g} yaw {x['yaw']:g}: {x['total']} = world {x['world']} + ents {x['ents']}"
                     f"{'' if x['faces'] == x['total'] else ' (' + str(x['faces']) + ' faces = r_speeds counter)'}")
        L.append('      by yaw/pitch: ' + ' '.join(f'{k}:{v}' for k, v in r['view_by_dir'].items())
                 + (f"; brush ents in PVS: {' '.join(r['ents_visible'])}" if r['ents_visible'] else ''))
    return '\n'.join(L)


def budget_problems(bud: dict, strict: bool = True) -> Tuple[List[str], List[str]]:
    errs, warns = [], []
    tgt = errs if strict else warns
    if bud['brush_entities'] > bud['max_brush_ents']:
        tgt.append(f"budget: {bud['brush_entities']} brush entities > {bud['max_brush_ents']} (model precache slots)")
    if bud['sound_slots_new'] > bud['max_map_sounds']:
        tgt.append(f"budget: {bud['sound_slots_new']} new sound precaches > {bud['max_map_sounds']}: {bud['sounds_new']}")
    return errs, warns


def _xyz(v) -> str:
    return ' '.join(str(int(round(x))) for x in v)


def format_perf(p: dict, bud: Optional[dict] = None) -> str:
    t = p['totals']
    L = []
    L.append(f"  perf ({p['seconds']}s; wpoly = GL polys incl. brush entities, sky excluded, water subdivided):")
    L.append(f"    world {t['world_faces']} faces ({t['sky_faces']} sky, {t['warped_faces']} water -> {t['warped_polys']} polys), "
             f"{t['leaves']} leaves ({t['open_leaves']} open), vis {t['vis_bytes'] // 1024} KiB, "
             f"each leaf sees {100 * p['pvs']['visible_leaf_fraction']:.0f}% of the leaves on average")
    L.append(f"    brush entities {t['brush_entities']} ({t['brush_entities_drawn']} drawn, {t['brush_entity_faces_drawn']} faces); "
             f"{t['textures']} textures {t['texture_bytes'] // 1024} KiB (largest: {', '.join(t['textures_largest'])}); "
             f"lightmaps {t['lightmap_bytes'] // 1024} KiB; bsp {t['bsp_bytes'] / 1048576:.2f} MB")
    s = p['pvs']
    L.append(f"    PVS per leaf (360 deg, no culling, n={s['total']['n']}): total max {s['total']['max']} p95 {s['total']['p95']} "
             f"mean {s['total']['mean']} | world faces max {s['faces']['max']} p95 {s['faces']['p95']} mean {s['faces']['mean']}, "
             f"world wpoly max {s['world_wpoly']['max']} p95 {s['world_wpoly']['p95']}, ents max {s['ent_wpoly']['max']}")
    v = p['view']
    L.append(f"    VIEW r_speeds estimate (eye points n={v['samples']}, worst of {v['directions']} yaws, fov {v['fov'][0]}x{v['fov'][1]}, "
             f"frustum + backface): total max {v['total']['max']} p95 {v['total']['p95']} mean {v['total']['mean']} "
             f"(world max {v['world_wpoly']['max']} p95 {v['world_wpoly']['p95']}; ents max {v['ent_wpoly']['max']} p95 {v['ent_wpoly']['p95']})")
    if v.get('faces') and v['faces']['max'] != v['total']['max']:
        L.append(f"      faces drawn (r_speeds counter, a water face counts once): max {v['faces']['max']} "
                 f"p95 {v['faces']['p95']} mean {v['faces']['mean']}")
    if s.get('worst'):
        L.append('    worst leaves (PVS total; * = players stand there):')
        for x in s['worst']:
            L.append(f"      leaf {x['leaf']:5d} centre ({_xyz(x['centre'])}) size ({_xyz(x['size'])}): {x['total']} = world {x['world']} "
                     f"+ ents {x['ents']}, sees {x['visible_leaves']} leaves{' *' if x['player'] else ''}")
    if s.get('best'):
        L.append('    lightest leaves: ' + ', '.join(f"leaf {x['leaf']} ({_xyz(x['centre'])}) {x['total']}" for x in s['best']))
    if v.get('worst'):
        L.append('    worst views (eye position, yaw):')
        for x in v['worst']:
            L.append(f"      eye ({_xyz(x['eye'])}) yaw {x['yaw']:.0f}: {x['total']} = world {x['world']} + ents {x['ents']} (leaf {x['leaf']})")
    hv = [h for h in p.get('brush_entities', []) if h['faces'] >= 20]
    if hv:
        L.append('    biggest drawn brush entities: ' + ', '.join(
            f"{h['model']} {h['classname']} {h['faces']}f/{h['leaves']} leaves{' rm' + str(h['rendermode']) if h['rendermode'] else ''}"
            for h in hv[:5]))
    lt, sp = p['lighting'], p['sprites']
    L.append(f"    lights {lt['light_entities']} (animated styles {lt['animated_styles'] or '-'}, {lt['switchable_lights']} switchable), "
             f"styled faces: animated {lt['animated_style_faces']} switchable {lt['switchable_style_faces']}; "
             f"sprites {sp['count']} ({sp['additive']} additive); transparent brush faces {p['transparent_brush_faces']}")
    if bud:
        L.append(f"  precache budget: brush entities {bud['brush_entities']}/{bud['max_brush_ents']}, "
                 f"new models {len(bud['models_new'])} {bud['models_new'] or ''} -> model slots +{bud['model_slots_new']}; "
                 f"sounds {len(bud['sounds_referenced'])} referenced, {bud['sound_slots_new']}/{bud['max_map_sounds']} new "
                 f"{bud['sounds_new'] or ''}")
    return '\n'.join(L)


def format_report(rep: dict) -> str:
    lines = [f"bspcheck {rep['path']}: {'OK' if not rep['errors'] else 'FAILED'}"]
    info = rep.get('info', {})
    if 'file_bytes' in info:
        lines.append(f"  size {info['file_bytes'] / 1024:.0f} KiB, entities {info.get('entities')}, brush models {info.get('brush_models')}, sky {info.get('skyname')}")
    if 'usage' in info:
        lines.append('  lump usage (count/limit %):')
        row = []
        for k, (v, lim, pct) in info['usage'].items():
            row.append(f'{k}={v} ({pct}%)')
        for i in range(0, len(row), 4):
            lines.append('    ' + '  '.join(row[i:i + 4]))
    if 'spawns' in info:
        s = info['spawns']
        lines.append(f"  spawns CT {s['ct']} (z {s['ct_floor_z']}), T {s['t']} (z {s['t_floor_z']})")
    if 'textures' in info:
        lines.append(f"  {len(info['textures'])} embedded textures")
    if rep.get('perf'):
        lines.append(format_perf(rep['perf'], rep.get('budget')))
    elif rep.get('budget'):
        b = rep['budget']
        lines.append(f"  precache budget: brush entities {b['brush_entities']}/{b['max_brush_ents']}, new models "
                     f"{b['models_new'] or '-'}, new sounds {b['sound_slots_new']}/{b['max_map_sounds']} {b['sounds_new'] or ''}")
    for e in rep['errors']:
        lines.append(f'  ERROR {e}')
    for w in rep['warnings'][:20]:
        lines.append(f'  warn  {w}')
    if len(rep['warnings']) > 20:
        lines.append(f"  ... {len(rep['warnings']) - 20} more warnings")
    return '\n'.join(lines)


def main(argv=None):
    import argparse
    D = PERF_DEFAULTS
    ap = argparse.ArgumentParser(description='Validate GoldSrc BSPs: engine limits, textures, spawns, precache '
                                             'budget and rendering cost (r_speeds wpoly estimate).')
    ap.add_argument('bsp', nargs='+')
    ap.add_argument('--json', action='store_true', help='print the full report (incl. perf + budget) as JSON')
    ap.add_argument('--min-spawns', type=int, default=32)
    ap.add_argument('--allow-sky', action='append', default=[], metavar='NAME',
                    help='accept this non-stock skyname (its 6 TGAs must exist under cstrike/gfx/env)')
    g = ap.add_argument_group('performance / budget')
    g.add_argument('--no-perf', action='store_true', help='skip the rendering-cost analysis')
    g.add_argument('--perf-only', action='store_true', help='print only the perf + budget part')
    g.add_argument('--perf-warn', type=int, default=D['warn_p95'], help='warn when p95 wpoly > N (%(default)s)')
    g.add_argument('--perf-error', type=int, default=D['error_max'], help='error when max wpoly > N (%(default)s)')
    g.add_argument('--perf-metric', choices=('view', 'pvs'), default=D['metric'],
                   help='metric the thresholds apply to: view = r_speeds estimate at player eye positions '
                        '(default), pvs = per-leaf PVS sum (360 deg, no culling)')
    g.add_argument('--perf-lenient', action='store_true', help='report threshold/budget errors as warnings')
    g.add_argument('--fov', type=float, default=D['fov'])
    g.add_argument('--aspect', type=float, default=D['aspect'], help='screen aspect (default 16:9)')
    g.add_argument('--yaws', type=int, default=D['yaws'], help='view directions per eye point')
    g.add_argument('--spacing', type=float, default=D['spacing'], help='eye sample grid (units)')
    g.add_argument('--max-brush-ents', type=int, default=D['max_brush_ents'])
    g.add_argument('--max-map-sounds', type=int, default=D['max_map_sounds'])
    g.add_argument('--max-bsp-mb', type=float, default=D['max_bsp_mb'])
    g.add_argument('--at', action='append', metavar='"X Y Z [PITCH YAW]"',
                   help='also print PVS + view numbers at this eye position (repeatable); with engine angles '
                        '(pitch > 0 = down, as getpos / vexcam_pos) also that exact view')
    a = ap.parse_args(argv)
    ALLOW_SKIES.update(s.lower() for s in a.allow_sky)
    opts = {'warn_p95': a.perf_warn, 'error_max': a.perf_error, 'metric': a.perf_metric, 'strict': not a.perf_lenient,
            'fov': a.fov, 'aspect': a.aspect, 'yaws': a.yaws, 'spacing': a.spacing, 'max_brush_ents': a.max_brush_ents,
            'max_map_sounds': a.max_map_sounds, 'max_bsp_mb': a.max_bsp_mb}
    rc = 0
    out = []
    for p in a.bsp:
        r = check(p, a.min_spawns, perf=not a.no_perf, perf_opts=opts)
        if a.at:
            pts = [[float(x) for x in s.replace(',', ' ').split()] for s in a.at]
            r['at'] = perf_at(p, pts, opts)
        if a.json:
            out.append(r)
        elif a.perf_only:
            print(f"bspcheck {p}:")
            if r.get('perf'):
                print(format_perf(r['perf'], r.get('budget')))
            for e in r['errors']:
                if e.startswith(('perf', 'budget')) or not r.get('perf'):
                    print(f'  ERROR {e}')
            for w in r['warnings']:
                if w.startswith(('perf', 'budget')):
                    print(f'  warn  {w}')
        else:
            print(format_report(r))
        if a.at and not a.json:
            print(format_at(r['at']))
        rc |= 1 if r['errors'] else 0
    if a.json:
        print(json.dumps(out[0] if len(out) == 1 else out, indent=1, default=_json_default))
    return rc


def _json_default(x):
    if isinstance(x, np.ndarray):
        return x.tolist()
    if isinstance(x, (np.integer,)):
        return int(x)
    if isinstance(x, (np.floating,)):
        return float(x)
    if isinstance(x, (set, frozenset)):
        return sorted(x)
    return str(x)


if __name__ == '__main__':
    sys.exit(main())
