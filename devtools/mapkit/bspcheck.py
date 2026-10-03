"""BSP v30 (GoldSrc) parser + validator.

    python3 -m mapkit.bspcheck cstrike/maps/zm_vex_pilot.bsp [--json]

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
"""
from __future__ import annotations

import json
import math
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
def check(path: str, min_spawns: int = 32, spacing: float = 48.0) -> dict:
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
        errs.append(f'skyname {sky!r} is not a stock CS sky (clients would need a download)')
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
    if bm > 64:
        warns.append(f'{bm} brush entities use model precache slots (512 total, plugin needs many)')

    # ---------------- spawns
    sp = check_spawns(b, spacing)
    info['spawns'] = sp['summary']
    errs += sp['errors']
    warns += sp['warnings']
    if sp['summary']['ct'] < min_spawns:
        errs.append(f'only {sp["summary"]["ct"]} CT spawns (info_player_start), need >= {min_spawns}')
    if sp['summary']['t'] < min_spawns:
        errs.append(f'only {sp["summary"]["t"]} T spawns (info_player_deathmatch), need >= {min_spawns}')
    return {'path': path, 'errors': errs, 'warnings': warns, 'info': info}


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
    for e in rep['errors']:
        lines.append(f'  ERROR {e}')
    for w in rep['warnings'][:20]:
        lines.append(f'  warn  {w}')
    return '\n'.join(lines)


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('bsp', nargs='+')
    ap.add_argument('--json', action='store_true')
    ap.add_argument('--min-spawns', type=int, default=32)
    a = ap.parse_args(argv)
    rc = 0
    for p in a.bsp:
        r = check(p, a.min_spawns)
        if a.json:
            print(json.dumps(r, indent=1, default=str))
        else:
            print(format_report(r))
        rc |= 1 if r['errors'] else 0
    return rc


if __name__ == '__main__':
    sys.exit(main())
