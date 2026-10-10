"""zm_vex_cordon - "Cordon 7": a night harbor district of Vexmira sealed behind a military
quarantine wall (flagship map). Build spec: maps/zm_vex_cordon_SPEC.md (binding).

    cd devtools && python3 -m mapkit.maps.zm_vex_cordon [--quality draft|normal|final] [--preview DIR]
                                                        [--mock] [--dry]

STAGE 1 (this file so far): blockout at final scale + VIS structure + spawns.
Every district is a sealed, sky-capped cell (outdoor) or a ceilinged room (indoor); districts are
joined only by low openings (headers <= 256) placed off-axis, by short tunnels or dog-legs, so VIS
keeps every view small. Levels: city z 0, harbor z -128, tower floors 0/192/384, roof 576.

    v  no-man's land vista (unreachable)      A  Gate 7 checkpoint (CT spawn)
    c  command post   a  supply alley         M  market street (M1 + M2, S-bend)   m arcade   p pharmacy
    R  terminus station (T spawn, derailed train, ticket block)   f1/f2 forecourt dog-legs
    H  field hospital yard, w triage ward     S  substation yard, h switch house, gantry deck (camp)
    L  lantern lane (Z-bend)                  P  Liberation Plaza (boss arena, 7 mouths)
    T0..T3 Customs Tower (lobby, offices, plant, roof + crown), 2 stair cores   t south passage
    K  Kade harbor road (2 gate arches, ramp to -128)   n stair lane   F fish market hall (loft camp)
    e  harbor steps (memorial)   Q quay + bridge cabin   ~ canal (lift bridge)   C container terminal
    B  bay vista (unreachable, freighter VIS blocker)   hangar (sealed, helicopter waits there)

Zone tool: `zone()` builds a cell from a union of rectangles: floor slab, top slab (sky or
ceiling, optional sky strips / holes), and walls 16 thick OUTSIDE the boundary, each wall facade
up to its roofline and sky above, with rectangular holes. Shared walls belong to ONE zone (the
other zone passes a `skip` hole). `--mock` adds func_detail boxes at 100 % of the spec's per-zone
face budgets (perf check of the VIS structure only, compiled to the work dir, never shipped).
"""
from __future__ import annotations

import argparse
import os
import random
import sys

from ..mapwriter import (CLIP, NULL, Brush, Entity, Map, box, door, glass, ladder, light, light_environment,
                         masked_entity, spawn_grid, stairs, wedge)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
NAME = 'zm_vex_cordon'

T = 16
INF = 100000
SKY = 'sky'
HINT, SKIP = 'HINT', 'SKIP'

# stand-in palette (stage 2 swaps in vx_facade / vx_quar_wall / vx_shopfront / vx_tarp / vx_bay ...)
FAC = 'vx_brick_dark'
CONC = 'vx_conc_stain'
CRACK = 'vx_conc_crack'
ASPH = 'vx_asphalt'
PLAST = 'vx_plaster'
TILE = 'vx_tile_dirty'
MDARK = 'vx_metal_dark'
RUST = 'vx_metal_rust'
CORR = 'vx_metal_corr'
BUNK = 'vx_bunker'
WATER = '!vx_water_dk'

TEX_SCALE = {ASPH: 2, CRACK: 2, CONC: 2, FAC: 2, 'vx_dirt': 2}


# ==============================================================================================
# geometry helpers
def _boundary(rects):
    """Boundary segments of a union of axis rectangles: (axis, line, a0, a1, sgn).
    axis 'x' = wall on the line x=line (runs along y), sgn = +1 when the outside is at +axis."""
    xs = sorted({r[0] for r in rects} | {r[2] for r in rects})
    ys = sorted({r[1] for r in rects} | {r[3] for r in rects})

    def inside(px, py):
        return any(r[0] < px < r[2] and r[1] < py < r[3] for r in rects)

    nx, ny = len(xs) - 1, len(ys) - 1
    ins = [[inside((xs[i] + xs[i + 1]) / 2, (ys[j] + ys[j + 1]) / 2) for j in range(ny)] for i in range(nx)]
    segs = []
    for i, x in enumerate(xs):
        for j in range(ny):
            lo = ins[i - 1][j] if i > 0 else False
            hi = ins[i][j] if i < nx else False
            if lo != hi:
                segs.append(('x', x, ys[j], ys[j + 1], 1 if lo else -1))
    for j, y in enumerate(ys):
        for i in range(nx):
            lo = ins[i][j - 1] if j > 0 else False
            hi = ins[i][j] if j < ny else False
            if lo != hi:
                segs.append(('y', y, xs[i], xs[i + 1], 1 if lo else -1))
    segs.sort(key=lambda s: (s[0], s[1], s[4], s[2]))
    out = []
    for s in segs:
        o = out[-1] if out else None
        if o and o[0] == s[0] and o[1] == s[1] and o[4] == s[4] and o[3] == s[2]:
            out[-1] = (o[0], o[1], o[2], s[3], o[4])
        else:
            out.append(s)
    return out, inside


def _solid(a0, a1, z0, z1, holes):
    """Solid (a, z) rectangles of the strip [a0,a1]x[z0,z1] minus holes (b0, b1, h0, h1)."""
    hs = [(max(b0, a0), min(b1, a1), max(h0, z0), min(h1, z1)) for b0, b1, h0, h1 in holes]
    hs = [h for h in hs if h[1] - h[0] > 0.5 and h[3] - h[2] > 0.5]
    bps = sorted({a0, a1} | {h[0] for h in hs} | {h[1] for h in hs})
    cols = []
    for p, q in zip(bps, bps[1:]):
        mid = (p + q) / 2
        cut = sorted((h[2], h[3]) for h in hs if h[0] < mid < h[1])
        sol, cur = [], z0
        for c0, c1 in cut:
            if c0 > cur:
                sol.append((cur, c0))
            cur = max(cur, c1)
        if cur < z1:
            sol.append((cur, z1))
        if cols and cols[-1][2] == sol and cols[-1][1] == p:
            cols[-1][1] = q
        else:
            cols.append([p, q, sol])
    return [(p, q, s0, s1) for p, q, sol in cols for s0, s1 in sol]


def rect_minus(rect, holes):
    """Axis rectangle minus rectangles -> list of rectangles (x0, y0, x1, y1)."""
    x0, y0, x1, y1 = rect
    hs = [(max(h[0], x0), max(h[1], y0), min(h[2], x1), min(h[3], y1)) for h in holes]
    hs = [h for h in hs if h[2] > h[0] and h[3] > h[1]]
    return [(p, s0, q, s1) for p, q, s0, s1 in _solid(x0, x1, y0, y1, [(h[0], h[2], h[1], h[3]) for h in hs])]


def _band(axis, line, sgn):
    return (line, line + T) if sgn > 0 else (line - T, line)


def _wall_box(axis, line, sgn, a0, a1, z0, z1, tex_in, tex_out):
    c0, c1 = _band(axis, line, sgn)
    if axis == 'x':
        inner, outer = ('w', 'e') if sgn > 0 else ('e', 'w')
        return box((c0, a0, z0), (c1, a1, z1), {inner: tex_in, outer: tex_out, 'all': tex_in})
    inner, outer = ('s', 'n') if sgn > 0 else ('n', 's')
    return box((a0, c0, z0), (a1, c1, z1), {inner: tex_in, outer: tex_out, 'all': tex_in})


class Zone:
    def __init__(self, key, rects, z0, z1):
        self.key, self.rects, self.z0, self.z1 = key, rects, z0, z1

    def centre(self):
        r = max(self.rects, key=lambda r: (r[2] - r[0]) * (r[3] - r[1]))
        return ((r[0] + r[2]) / 2, (r[1] + r[3]) / 2)


class Builder:
    def __init__(self, mock=False):
        self.m = Map(NAME + ('_mock' if mock else ''), sky='night', tex_scale=TEX_SCALE)
        self.mock = mock
        self.det = []          # func_detail
        self.zones = {}
        self.ents = []
        self.lad_vis = {}      # area -> ladder visual brushes (one masked func_illusionary per area)
        self._hints = set()

    # ------------------------------------------------------------------ primitives
    def W(self, bl):
        self.m.add(bl)

    def D(self, bl):
        self.det += bl

    def slab(self, rect, z0, z1, tex, holes=(), sky=()):
        for r in rect_minus(rect, list(holes) + list(sky)):
            self.W(box((r[0], r[1], z0), (r[2], r[3], z1), tex))
        for s in sky:
            x0, y0, x1, y1 = max(s[0], rect[0]), max(s[1], rect[1]), min(s[2], rect[2]), min(s[3], rect[3])
            if x1 > x0 and y1 > y0:
                self.W(box((x0, y0, z0), (x1, y1, z1), SKY))

    def zone(self, key, rects, z0, z1, floor, wall, top=SKY, rl=None, rls=(), holes=(), out=None,
             top_holes=(), top_sky=(), omit=(), hint_z=None):
        """Sealed cell. rects: (x0,y0,x1,y1) interior; rl: default roofline (facade below, sky above,
        None = z1); rls: (axis, line, a0, a1, rl) roofline spans; holes: (axis, line, a0, a1, h0, h1)
        absolute (line = interior boundary coordinate); out: {(axis, line): tex} outer face texture."""
        zn = Zone(key, rects, z0, z1)
        self.zones[key] = zn
        rl = z1 if rl is None else rl
        out = out or {}
        ext = lambda r: (r[0] - T, r[1] - T, r[2] + T, r[3] + T)
        for r in rects:
            if 'bottom' not in omit:
                self.W(box((r[0] - T, r[1] - T, z0 - T), (r[2] + T, r[3] + T, z0), floor))
            if 'top' not in omit:
                th = [h for h in top_holes]
                self.slab(ext(r), z1, z1 + T, top if top != SKY else SKY, holes=th,
                          sky=top_sky if top != SKY else ())
        segs, inside = _boundary(rects)
        cols = set()
        for axis, line, a0, a1, sgn in segs:
            hl = [(h[2], h[3], h[4], h[5]) for h in holes if h[0] == axis and h[1] == line]
            spans = [(s[2], s[3], s[4]) for s in rls if s[0] == axis and s[1] == line]
            bps = sorted({a0, a1} | {v for sp in spans for v in sp[:2] if a0 < v < a1})
            tin = wall
            tout = out.get((axis, line), wall)
            for p, q in zip(bps, bps[1:]):
                mid = (p + q) / 2
                r = next((sp[2] for sp in spans if sp[0] <= mid <= sp[1]), rl)
                r = max(z0, min(r, z1))
                for b0, b1, s0, s1 in _solid(p, q, z0, r, hl):
                    self.W(_wall_box(axis, line, sgn, b0, b1, s0, s1, tin, tout))
                for b0, b1, s0, s1 in _solid(p, q, r, z1, hl):
                    self.W(_wall_box(axis, line, sgn, b0, b1, s0, s1, SKY, SKY))
            # corner columns (convex corners only)
            c0, c1 = _band(axis, line, sgn)
            for e0, e1 in ((a0 - T, a0), (a1, a1 + T)):
                cx, cy = ((c0 + c1) / 2, (e0 + e1) / 2) if axis == 'x' else ((e0 + e1) / 2, (c0 + c1) / 2)
                if inside(cx, cy):
                    continue
                k = (axis, c0, c1, e0, e1)
                if k in cols:
                    continue
                cols.add(k)
                mn = (c0, e0) if axis == 'x' else (e0, c0)
                mx = (c1, e1) if axis == 'x' else (e1, c1)
                # skip columns fully inside a skip-hole of this edge (owned by the neighbour)
                col_holes = [(h0, h1) for b0, b1, h0, h1 in hl if b0 <= e0 and b1 >= e1]
                zs = _solid(0, 1, z0, z1, [(0, 1, h0, h1) for h0, h1 in col_holes])
                for _, _, s0, s1 in zs:
                    self.W(box((mn[0], mn[1], s0), (mx[0], mx[1], s1), tin if s1 <= max(rl, z0) else SKY))
        # VIS: HINT plane in every finite opening (splits the zone exactly at its mouth) ...
        for h in holes:
            axis, line, a0, a1, h0, h1 = h
            if a0 <= -INF or a1 >= INF or h0 <= -INF or h1 >= INF or h1 >= z1:
                continue
            seg = next((sg for sg in segs if sg[0] == axis and sg[1] == line and sg[2] <= a0 and sg[3] >= a1), None)
            if seg is None:
                continue
            c0, c1 = _band(axis, line, seg[4])
            mn = (c0, a0, max(h0, z0)) if axis == 'x' else (a0, c0, max(h0, z0))
            mx = (c1, a1, min(h1, z1)) if axis == 'x' else (a1, c1, min(h1, z1))
            key = (mn, mx)
            if key not in self._hints:
                self._hints.add(key)
                self.hint(mn, mx, axis)
        # ... and an optional horizontal plane at header height (separates the open air above
        # the headers from the street level, so the leaves people stand in see less)
        if hint_z is not None:
            for r in rects:
                self.hint((r[0], r[1], hint_z), (r[2], r[3], hint_z + 8), 'z')
        return zn

    def tunnel(self, axis, a0, a1, b0, b1, z0, z1, wall, floor, ceil):
        """Passage between two zone walls: along `axis` from a0 to a1, cross-section b0..b1 x z0..z1."""
        if axis == 'x':
            self.W(box((a0, b0 - T, z0 - T), (a1, b1 + T, z0), floor))
            self.W(box((a0, b0 - T, z1), (a1, b1 + T, z1 + T), ceil))
            self.W(box((a0, b0 - T, z0), (a1, b0, z1), wall))
            self.W(box((a0, b1, z0), (a1, b1 + T, z1), wall))
        else:
            self.W(box((b0 - T, a0, z0 - T), (b1 + T, a1, z0), floor))
            self.W(box((b0 - T, a0, z1), (b1 + T, a1, z1 + T), ceil))
            self.W(box((b0 - T, a0, z0), (b0, a1, z1), wall))
            self.W(box((b1, a0, z0), (b1 + T, a1, z1), wall))

    def hint(self, mins, maxs, face):
        """HINT brush: HINT on the two faces normal to `face` axis ('x'|'y'|'z'), SKIP elsewhere."""
        keys = {'x': ('e', 'w'), 'y': ('n', 's'), 'z': ('top', 'bottom')}[face]
        self.W(box(mins, maxs, {keys[0]: HINT, keys[1]: HINT, 'all': SKIP}))

    def ladder(self, area, base, facing, height):
        e, vis = ladder(base, facing, height)
        self.ents.append(e)
        self.lad_vis.setdefault(area, []).extend(vis)

    def ent(self, e):
        self.ents.append(e)
        return e


# ==============================================================================================
def build(mock=False) -> Map:
    b = Builder(mock)
    Z = b.zone
    X, Y = 'x', 'y'
    sk = lambda axis, line, a0=-INF, a1=INF, h0=-INF, h1=INF: (axis, line, a0, a1, h0, h1)

    # ---------------------------------------------------------------- NORTH-WEST: cordon
    # v  no-man's land vista (unreachable). s wall = quarantine wall, owned by A.
    Z('v', [(-3328, 2576, -1984, 3200)], 0, 1152, 'vx_dirt', CONC, rl=0,
      holes=[sk(Y, 2576, h1=784)])
    # A  Gate 7 checkpoint (CT spawn yard 1344 x 1152)
    Z('A', [(-3328, 1408, -1984, 2560)], 0, 768, CRACK, CONC, rl=448,
      rls=[(X, -3328, -INF, INF, 512)],
      holes=[(Y, 2560, -3328, -1984, 448, 768),          # over the quarantine wall into the vista
             (Y, 2560, -2768, -2512, 0, 320),            # Gate 7 (cd_gate7)
             (X, -1984, 1888, 2144, 0, 208),             # sally port -> market
             (Y, 1408, -2816, -2688, 0, 128),            # -> command post
             (Y, 1408, -2304, -2176, 0, 192)],           # -> supply alley (dog-leg N hole)
      out={(Y, 1408): PLAST, (Y, 2560): 'vx_dirt'})
    b.W(box((-3328, 2560, 448), (-1984, 2576, 768), CLIP))           # no climbing over the cordon
    # sally port tunnel A -> M1 (overpass header)
    b.tunnel(X, -1968, -1936, 1888, 2144, 0, 208, BUNK, CRACK, BUNK)
    # c  command post (indoor, doors N + S)
    Z('c', [(-3072, 1040, -2432, 1392)], 0, 176, CRACK, PLAST, top=PLAST,
      holes=[sk(Y, 1392), sk(Y, 1040)])
    # a  supply alley (dog-leg: N hole x[-2304,-2176] in A's wall, S hole x[-2176,-2048] in S's wall)
    Z('a', [(-2304, 1040, -2048, 1392)], 0, 640, CRACK, FAC, rl=320, holes=[sk(Y, 1392), sk(Y, 1040)])
    b.W(box((-2208, 1168, 0), (-2048, 1264, 192), BUNK))            # dog-leg baffle (sandbag wall, world)

    # ---------------------------------------------------------------- WEST: substation
    Z('S', [(-3328, -640, -1984, 1024)], 0, 704, CRACK, FAC, rl=448,
      rls=[(Y, 1024, -INF, INF, 384), (X, -3328, -INF, INF, 512), (X, -1984, -INF, INF, 416)],
      holes=[(Y, 1024, -2816, -2688, 0, 128), (Y, 1024, -2176, -2048, 0, 192),
             (X, -1984, -192, 96, 0, 224),                # -> lantern lane
             (Y, -640, -3200, -2944, 0, 224)],            # -> stair lane
      out={(Y, 1024): PLAST})
    # h  switch house (breaker A), doors E + S
    Z('h', [(-3200, 384, -2752, 896)], 0, 176, CRACK, CORR, top={'bottom': MDARK, 'all': CORR},
      holes=[(X, -2752, 576, 704, 0, 128), (Y, 384, -3040, -2912, 0, 128)])
    # gantry deck z 160 (camp C3): stairs N end (CLIP ramp), ladder S end
    b.W(box((-2272, -512, 144), (-2048, 480, 160), MDARK))
    b.W(stairs((-2144, 800, 0), '-y', 128, 160, rise=8, run=16, tex=MDARK, clip=True))
    b.W(box((-2192, -512, 0), (-2128, -496, 144), MDARK))            # ladder back plate
    b.ladder('S', (-2160, -512, 0), '+y', 164)
    for x, y in ((-2264, -500), (-2064, -500), (-2264, 460), (-2064, 460), (-2264, -20), (-2064, -20)):
        b.D(box((x - 8, y - 8, 0), (x + 8, y + 8, 144), MDARK))      # deck posts
    for i in range(3):                                                # transformer compounds (blockout)
        x = -3168 + i * 352
        b.D(box((x, -400, 0), (x + 224, -224, 192), MDARK))

    # ---------------------------------------------------------------- lantern lane (Z-bend)
    Z('L', [(-1968, -192, -1680, 96), (-1680, -576, -1424, 96), (-1424, -576, -1168, -288)], 0, 640,
      ASPH, FAC, rl=352, rls=[(X, -1424, -INF, INF, 320), (X, -1680, -INF, INF, 384)],
      holes=[sk(X, -1968), sk(X, -1168)])

    # ---------------------------------------------------------------- market street + pharmacy + arcade
    Z('M', [(-1920, 1792, -1168, 2240), (-1600, 704, -1216, 1792)], 0, 704, ASPH, FAC, rl=448,
      rls=[(Y, 2240, -INF, INF, 384), (X, -1216, -INF, INF, 384)],
      holes=[(X, -1920, 1888, 2144, 0, 208),             # sally port
             (X, -1168, 1920, 2112, 0, 160),             # station side gate (roller shutter)
             (X, -1216, 736, 960, 0, 192),               # arcade -> plaza
             (Y, 2240, -1856, -1760, 0, 112),            # pharmacy door
             (Y, 2240, -1728, -1600, 48, 144)],          # pharmacy shop window (breakable)
      out={(Y, 2240): PLAST})
    Z('p', [(-1904, 2256, -1584, 2480)], 0, 160, TILE, PLAST, top=PLAST, holes=[sk(Y, 2256)])
    b.tunnel(X, -1216, -1152, 736, 960, 0, 192, CONC, ASPH, CONC)    # market arcade m
    b.tunnel(X, -1152, -1104, 1920, 2112, 0, 160, CORR, CRACK, CORR)  # station side gate
    b.D(box((-1696, 2192, 0), (-1640, 2240, 48), 'vx_crate_mil'))    # duck-jump crate under the window

    # ---------------------------------------------------------------- terminus station (T spawn)
    sky_strips = [(-1024, y, 1024, y + 64) for y in (1600, 1952, 2272)]
    R = Z('R', [(-1088, 1408, 1088, 2496)], -32, 448, TILE, FAC, top=MDARK, top_sky=sky_strips,
          holes=[(X, -1088, 1920, 2112, 0, 160),         # side gate
                 (Y, 1408, -768, -576, 0, 192),          # -> forecourt W
                 (Y, 1408, 576, 768, 0, 192),            # -> forecourt E
                 (X, 1088, 1984, 2368, 0, 256)],         # breach -> hospital
          out={(Y, 1408): FAC, (X, 1088): FAC})
    pit = (-896, 2048, 1088, 2400)                                    # track bed -32 (terminus buffers W)
    for r in rect_minus((-1088, 1408, 1088, 2496), [pit]):
        b.W(box((r[0], r[1], -32), (r[2], r[3], 0), TILE))
    b.W(box((-128, 1408, -32), (128, 1856, 448), CONC))               # ticket block (VIS splitter)
    # derailed train: car 1 (duck-jump roof 104), car 2 (camp C2 roof 128, ladder), car 3 in the breach
    b.D(box((-880, 2112, -32), (-400, 2240, 104), RUST))
    b.D(box((-320, 2160, -32), (352, 2288, 128), RUST))
    b.D(box((640, 2112, -32), (1072, 2240, 112), RUST))
    b.D(box((-472, 2056, 0), (-424, 2104, 56), 'vx_crate_mil'))      # duck-jump crate -> car 1
    b.W(box((-48, 2156, -32), (48, 2160, 128), NULL))                # ladder face (inside car 2 skin)
    b.ladder('R', (0, 2160, -32), '+y', 164)

    # forecourts (dog-legs R <-> P)
    for key, xr in (('f1', (-768, -384)), ('f2', (384, 768))):
        Z(key, [(xr[0], 1040, xr[1], 1392)], 0, 512, CRACK, FAC, rl=256,
          holes=[sk(Y, 1392, h1=464), sk(Y, 1040)])
        mid = (xr[0] + xr[1]) / 2
        b.W(box((mid - 32, 1168, 0), (mid + 32, 1264, 160), BUNK))    # baffle in the dog-leg

    # ---------------------------------------------------------------- field hospital + ward
    Z('H', [(1104, 1344, 2560, 2496)], 0, 640, CRACK, FAC, rl=384, rls=[(Y, 2496, -INF, INF, 448)],
      holes=[sk(X, 1104, 1408, 2496, h1=464),
             (Y, 1344, 2240, 2496, 0, 256)])             # checkpoint B arch -> Kade
    Z('w', [(1856, 1904, 2544, 2480)], 0, 176, TILE, PLAST, top={'bottom': PLAST, 'all': MDARK},
      holes=[(X, 1856, 2048, 2176, 0, 128), (Y, 1904, 2240, 2368, 0, 128)])

    # ---------------------------------------------------------------- Liberation Plaza (boss arena)
    Z('P', [(-1152, -1152, 1152, 1024)], 0, 1216, ASPH, FAC, rl=512,
      rls=[(Y, 1024, -INF, INF, 448), (Y, -1152, -INF, INF, 640), (X, 1152, -INF, INF, 640),
           (X, 1152, 448, 832, 1152)],                   # tower facade + crown
      holes=[(Y, 1024, -576, -384, 0, 192), (Y, 1024, 384, 576, 0, 192),      # forecourts
             (X, -1152, 736, 960, 0, 192), (X, -1152, -560, -304, 0, 208),    # arcade, lantern lane
             (X, 1152, 96, 352, 0, 128),                                       # lobby glass doors
             (X, 1152, -288, -128, 240, 320), (X, 1152, 176, 336, 240, 320),   # office windows (T1)
             (X, 1152, -560, -400, 0, 208),                                    # south passage t
             (Y, -1152, -384, 384, 0, 224)],                                   # harbor steps arch
      out={(X, 1152): PLAST})
    b.D(box((-160, -224, 0), (160, 96, 96), CONC))                   # monument plinth (blockout)

    # ---------------------------------------------------------------- Customs Tower
    nw_core, se_core = (1184, 464, 1440, 816), (1888, -368, 2144, -16)
    nw_fl, se_fl = (1184, 592, 1440, 816), (1888, -240, 2144, -16)    # stair flights + N landings
    tower = [(1168, -384, 2160, 832)]
    for key, z0, z1 in (('T0', 0, 176), ('T1', 192, 368), ('T2', 384, 560)):
        Z(key, tower, z0, z1, CRACK if key != 'T0' else TILE, PLAST, top=PLAST, top_holes=[nw_fl, se_fl],
          holes=[sk(X, 1168), sk(X, 2160)] + ([(Y, -384, 1920, 2048, 0, 112)] if key == 'T0' else []),
          out={(Y, 832): FAC, (Y, -384): FAC}, omit=('bottom',) if key != 'T0' else ())
    Z('T3', tower, 576, 1536, CRACK, CONC, rl=640, omit=('bottom',),
      holes=[sk(X, 1168, h1=1232), sk(X, 2160, h1=720)], out={(Y, 832): FAC, (Y, -384): FAC})
    for key, rc, door_side, door_span, flA, flB, dirA in (
            ('Cnw', nw_core, X, (1440, 464, 592), (1248, 592), (1376, 720), '+y'),
            ('Cse', se_core, X, (1888, -368, -240), (1952, -240), (2080, -112), '+y')):
        line, d0, d1 = door_span
        hs = [(X, line, d0, d1, L, L + 112) for L in (0, 192, 384, 576)]
        if key == 'Cse':
            hs.append((Y, -368, 1920, 2048, 0, 112))      # from the south passage
        Z(key, [rc], 0, 704, CONC, CONC, top=CONC, holes=hs, omit=('bottom',))
        nl = (rc[0], flB[1] if key == 'Cnw' else -112, rc[2], rc[3])  # north landing
        for L in (0, 192, 384):
            b.W(stairs((flA[0], flA[1], L), dirA, 128, 96, rise=12, run=16, tex=CRACK, clip=True))
            b.W(box((nl[0], nl[1], L + 80), (nl[2], nl[3], L + 96), CRACK))
            b.W(stairs((flB[0], flB[1], L + 96), '-y', 128, 96, rise=12, run=16, tex=CRACK, clip=True))
        b.W(box((flB[0] - 64, flA[1], 0), (flB[0] + 64, flB[1], 96), CONC))   # fill under the first B flight
    b.W(box((1168, 448, 720), (1456, 832, 1152), CONC))              # crown (landmark seen from the plaza)
    # tower south passage t (flank P <-> K)
    Z('t', [(1168, -560, 2160, -400)], 0, 512, ASPH, FAC, rl=256,
      holes=[sk(X, 1168), sk(X, 2160), sk(Y, -400)])

    # ---------------------------------------------------------------- Kade (3 cells split by gate arches)
    arch = lambda line: (Y, line, 2240, 2496, 0, 224)
    kw = {(X, 2176): PLAST}
    Z('Kn', [(2176, 656, 2560, 1328)], 0, 704, ASPH, FAC, rl=448, rls=[(X, 2176, -INF, INF, 640)],
      holes=[sk(Y, 1328, h1=656), arch(656)], out=kw)
    Z('Km', [(2176, -304, 2560, 624)], 0, 704, ASPH, FAC, rl=448, rls=[(X, 2176, -INF, INF, 640)],
      holes=[arch(624), arch(-304),
             (X, 2176, 48, 144, 192, 304),               # fire-escape balcony door into T1
             (X, 2176, 32, 96, 576, 704)], out=kw)       # roof hatch (parapet) into T3
    Z('Ks', [(2176, -1072, 2560, -336)], -128, 704, ASPH, FAC, rl=448, rls=[(X, 2176, -INF, INF, 640)],
      holes=[arch(-336), (X, 2176, -560, -400, 0, 208), sk(Y, -1072)], out=kw)
    for r in rect_minus((2176, -1072, 2560, -336), [(2176, -1072, 2560, -800)]):
        b.W(box((r[0], r[1], -128), (r[2], r[3], 0), CRACK))
    b.W(wedge((2368, -1072, -128), '+y', 384, 272, 128, ASPH))     # ramp 0 -> -128 to the terminal
    # fire escape: balcony z 192 + ladder 1 (K floor -> balcony) + ladder 2 (balcony -> roof hatch)
    b.W(box((2176, 0, 176), (2272, 192, 192), MDARK))
    b.W(box((2256, 64, 0), (2272, 128, 176), MDARK))
    b.ladder('K', (2272, 96, 0), '-x', 196)
    b.ladder('K', (2176, 64, 192), '-x', 388)

    # ---------------------------------------------------------------- stair lane + fish market
    Z('n', [(-3200, -1072, -2944, -656)], -128, 512, CRACK, FAC, rl=256,
      holes=[sk(Y, -656, h0=0), sk(Y, -1072, h1=272)])
    b.W(box((-3200, -800, -128), (-3072, -656, 0), CRACK))           # west half: landing z 0
    b.W(stairs((-3136, -1056, -128), '+y', 128, 128, rise=16, run=32, tex=CRACK, clip=True))
    b.W(box((-3072, -1072, -128), (-2944, -656, 0), CRACK))          # east half: level walkway to the loft
    Z('F', [(-3328, -2304, -1792, -1088)], -128, 256, TILE, FAC, top=RUST,
      top_sky=[(-3000, -1800, -2700, -1600), (-2400, -1800, -2100, -1600)],
      holes=[(X, -1792, -2240, -1984, -128, 96),         # net alley -> quay (roller shutter)
             (Y, -1088, -3200, -3072, -128, -16),        # under the loft from the stair lane
             (Y, -1088, -3072, -2944, 0, 112)],          # onto the loft
      out={(X, -1792): CONC})
    b.W(box((-3328, -1280, -16), (-1792, -1088, 0), MDARK))          # loft deck z 0 (camp C5)
    for x in (-2944, -2176):
        b.W(stairs((x, -1472, -128), '+y', 96, 128, rise=16, run=24, tex=MDARK, clip=True))

    # ---------------------------------------------------------------- harbor steps
    Z('e', [(-384, -1584, 384, -1168)], -128, 640, CRACK, FAC, rl=320,
      holes=[sk(Y, -1168, h0=0), sk(Y, -1584)])
    b.W(box((-384, -1232, -128), (384, -1168, 0), CRACK))            # top landing (plaza level)
    b.W(box((-128, -1520, -128), (128, -1232, 192), CONC))           # memorial block (VIS blocker)
    for xc in (-256, 256):
        b.W(stairs((xc, -1488, -128), '+y', 256, 128, rise=8, run=16, tex=CRACK, clip=True))

    # ---------------------------------------------------------------- quay + bridge cabin + canal
    Z('Q', [(-1776, -2560, 1152, -1600)], -128, 768, CONC, FAC, rl=384,
      holes=[(Y, -1600, -384, 384, -128, 64),            # customs arcade (header z 64)
             (X, 1152, -2240, -1856, -128, 384),         # bridge gap
             sk(X, -1776, -2304, -1600, h1=272), sk(Y, -2560)],
      out={(X, 1152): CONC})
    b.W(box((912, -1792, -128), (1152, -1600, 0), CONC))             # cabin base
    Z('cab', [(928, -1776, 1136, -1616)], 0, 128, MDARK, CORR, top={'bottom': MDARK, 'all': CORR},
      holes=[(X, 928, -1760, -1664, 0, 112), (Y, -1776, 960, 1120, 48, 112)])
    b.W(stairs((656, -1712, -128), '+x', 96, 128, rise=8, run=16, tex=CONC, clip=True))
    Z('~', [(1168, -2560, 1328, -1600)], -224, 768, 'vx_rock', CONC, rl=384,
      holes=[sk(X, 1168, h0=-128), sk(X, 1328, h0=-128), sk(Y, -2560, h0=-192)])
    b.W(box((1168, -2560, -224), (1328, -1600, -176), WATER))        # wading water (48 deep)
    b.W(stairs((1264, -2208, -224), '-x', 64, 96, rise=16, run=16, tex=CONC))   # exit steps W bank
    b.W(stairs((1232, -1888, -224), '+x', 64, 96, rise=16, run=16, tex=CONC))   # exit steps E bank

    # ---------------------------------------------------------------- container terminal
    Z('C', [(1344, -2560, 3328, -1088)], -128, 896, CONC, 'vx_cont_blue', rl=448,
      holes=[(Y, -1088, 2176, 2560, -128, 256), (X, 1344, -2240, -1856, -128, 384), sk(Y, -2560)])
    stacks = [(1408, -2272, 1536, -1824, 2),             # blocks the bridge-gap view into the terminal
              (1664, -1472, 2240, -1344, 2), (2624, -1472, 3200, -1344, 2),
              (1792, -1856, 2304, -1728, 1), (3008, -1856, 3264, -1600, 2),
              (1664, -2304, 2240, -2176, 2), (2944, -2400, 3264, -2176, 1)]
    for x0, y0, x1, y1, hgt in stacks:
        tex = 'vx_cont_red' if (x0 // 128) % 2 else 'vx_cont_blue'
        b.W(box((x0, y0, -128), (x1, y1, -128 + 128 * hgt), tex))
    # gantry crane deck z 256 (camp C4): 4 legs, leg ladder, crate hop route from the 1-high stack
    b.W(box((2528, -2096, 240), (2784, -1904, 256), RUST))
    for x, y in ((2528, -2096), (2752, -2096), (2528, -1936), (2752, -1936)):
        b.D(box((x, y, -128), (x + 32, y + 32, 240), RUST))
    b.ladder('C', (2544, -2096, -128), '+y', 388)
    for x, y, z, h in ((2312, -1716, -128, 48), (2312, -1716, -80, 48),
                       (2840, -2000, -128, 48), (2840, -2000, -80, 48), (2840, -2000, -32, 48),
                       (2840, -2000, 16, 48), (2840, -2000, 64, 48), (2840, -2000, 112, 48),
                       (2840, -2000, 160, 48)):
        pass   # crate staircase placed below (stage 2 replaces with real props)
    for i, (x, h) in enumerate(((2880, 48), (2832, 96), (2800, 144), (2800, 192), (2800, 240))):
        b.D(box((x - 24, -1904 + 8, -128), (x + 24, -1904 + 56, -128 + h), 'vx_crate_mil'))

    # ---------------------------------------------------------------- bay vista (unreachable)
    Z('B', [(-3456, -3456, 3456, -2576)], -192, 1152, ASPH, SKY, rl=-192,
      rls=[(Y, -2576, -INF, INF, -96)],
      holes=[(Y, -2576, -1776, 1152, -96, 768), (Y, -2576, 1168, 1328, -96, 768),
             (Y, -2576, 1344, 3328, -96, 896)], out={(Y, -2576): CONC})
    b.W(box((-1776, -2576, -96), (1152, -2560, 768), CLIP))
    b.W(box((1168, -2576, -96), (1328, -2560, 768), CLIP))
    b.W(box((1344, -2576, -96), (3328, -2560, 896), CLIP))
    b.W(box((700, -2900, -192), (2300, -2700, 128), RUST))          # freighter hull (VIS blocker Q|C)
    b.W(box((-664, -3264, -192), (-536, -3136, 448), CONC))         # lighthouse (blockout)

    # ---------------------------------------------------------------- hidden helicopter hangar
    Z('hangar', [(3584, 2816, 3968, 3200)], 0, 384, NULL, NULL, top=NULL)

    # ============================================================== brush entities (structural set)
    E = b.ent
    gate = E(door(box((-2768, 2560, 0), (-2512, 2576, 320), RUST), 'up', speed=60, wait=-1, lip=0,
                  targetname='cd_gate7'))
    gate['movesnd'] = 2
    E(door(box((-1136, 1920, 0), (-1120, 2112, 160), CORR), 'up', speed=120, wait=4, lip=8))     # side gate
    E(door(box((-1792, -2240, -128), (-1776, -1984, 96), CORR), 'up', speed=120, wait=4, lip=8))  # net alley
    E(door(box((-2816, 1024, 0), (-2688, 1040, 128), 'vx_door_metal'), '+x', speed=160, wait=4))  # CP south
    E(door(box((-2752, 576, 0), (-2736, 704, 128), 'vx_door_metal'), '+y', speed=160, wait=4))    # switch house
    E(door(box((1840, 2048, 0), (1856, 2176, 128), 'vx_door_metal'), '+y', speed=160, wait=4))    # ward
    E(door(box((1920, -392, 0), (2048, -376, 112), 'vx_door_metal'), '+x', speed=160, wait=4))    # SE stair door
    for y0, y1, d in ((96, 224, '-y'), (224, 352, '+y')):                                         # lobby glass
        g = E(door(box((1152, y0, 0), (1168, y1, 128), 'vx_glass'), d, speed=160, wait=4))
        g['rendermode'], g['renderamt'] = 2, 90
    E(door(box((1152, -2176, 240), (1344, -1920, 256), RUST), 'down', speed=48, wait=-1, lip=0,
           targetname='cd_bridge'))
    for mn, mx, hp in (((-1728, 2240, 48), (-1600, 2256, 144), 80),    # pharmacy window
                       ((1152, -288, 240), (1168, -128, 320), 80),    # office glass W
                       ((1152, 176, 240), (1168, 336, 320), 80),      # office glass E
                       ((960, -1792, 48), (1120, -1776, 112), 60)):   # cabin glass
        E(glass(box(mn, mx, 'vx_glass'), health=hp))
    bar = E(glass(box((1440, 464, 0), (1456, 592, 112), 'vx_glass'), health=1500))               # riot barricade
    bar['targetname'] = 'cd_barricade'
    for area, vis in b.lad_vis.items():
        E(masked_entity(vis, solid=False))

    # ============================================================== spawns
    b.ents += spawn_grid('ct', (-3200, 1536), (-2560, 1880), 0, 32, spacing=72, yaw=0)
    b.ents += spawn_grid('t', (224, 1488), (1072, 1784), 0, 32, spacing=72, yaw=90)

    # ============================================================== light (stage 1 fill, readable previews)
    b.ents.append(light_environment(-58, 135, (150, 165, 215), 70, diffuse=(55, 65, 100, 35), origin=(0, 0, 800)))
    fills = [((-2656, 1984, 256), 260), ((-2752, 1216, 120), 160), ((-2176, 1216, 200), 140),
             ((-1544, 2016, 256), 240), ((-1408, 1250, 256), 220), ((-1744, 2368, 110), 130),
             ((-600, 1650, 300), 260), ((600, 1650, 300), 260), ((0, 2250, 300), 260),
             ((-576, 1216, 200), 150), ((576, 1216, 200), 150), ((1800, 1700, 256), 240),
             ((2200, 2190, 120), 140), ((-2656, 192, 300), 280), ((-2976, 640, 120), 140),
             ((-1552, -100, 220), 200), ((-500, 500, 400), 320), ((500, -600, 400), 320),
             ((1664, 224, 120), 180), ((1664, 224, 300), 180), ((1664, 224, 480), 160), ((1664, 224, 700), 220),
             ((1312, 640, 300), 140), ((2016, -192, 300), 140), ((1664, -480, 200), 150),
             ((2368, 990, 256), 200), ((2368, 160, 256), 200), ((2368, -700, 200), 200),
             ((-3072, -864, 150), 150), ((-2560, -1700, 150), 240), ((-2560, -1200, 100), 150),
             ((0, -1376, 150), 180), ((-300, -2080, 150), 260), ((900, -2080, 150), 200),
             ((1032, -1696, 80), 120), ((1248, -2080, 100), 160), ((2336, -1824, 200), 280),
             ((2336, -1300, 150), 200), ((2900, -2300, 150), 200), ((3776, 3008, 300), 200)]
    for p, br in fills:
        b.ents.append(light(p, (255, 214, 170), br))

    # ============================================================== mock detail (perf check only)
    if mock:
        budgets = {'v': 120, 'A': 550, 'c': 160, 'a': 100, 'M': 680, 'R': 850, 'f1': 90, 'f2': 90, 'H': 450,
                   'w': 120, 'S': 600, 'h': 120, 'L': 260, 'P': 700, 'T0': 200, 'T1': 240, 'T2': 120, 'T3': 280,
                   't': 60, 'Kn': 140, 'Km': 140, 'Ks': 140, 'n': 60, 'F': 480, 'e': 160, 'Q': 520, '~': 60,
                   'C': 650, 'B': 220}
        rng = random.Random(7)
        for key, faces in budgets.items():
            zn = b.zones[key]
            for _ in range(faces // 5):
                r = rng.choice(zn.rects)
                sx, sy = rng.randint(16, 48), rng.randint(16, 48)
                x = rng.randint(int(r[0]) + 8, int(r[2]) - 8 - sx)
                y = rng.randint(int(r[1]) + 8, int(r[3]) - 8 - sy)
                z = zn.z0 + rng.choice((0, 0, 0, 64, 128))
                b.D(box((x, y, z), (x + sx, y + sy, z + rng.randint(16, 64)), MDARK))

    # ============================================================== assemble
    m = b.m
    if b.det:
        m.add_entity(Entity('func_detail', b.det, zhlt_detaillevel=1))
    m.add_entity(b.ents)
    m.add_entity(Entity('info_map_parameters', buying=3))
    b.m._zones = b.zones
    return m


# ----------------------------------------------------------------------------------------------
# --at checkpoints (spec section 12; eye z = floor + 54)
CHECKPOINTS = [
    ('A', (-2900, 1700, 54)), ('M1', (-1600, 2016, 54)), ('R', (0, 1950, 54)), ('R T-spawn', (540, 1600, 54)),
    ('S', (-2600, 200, 54)), ('gantry', (-2160, 0, 214)), ('P centre', (0, -400, 54)), ('P NW', (-1000, 900, 54)),
    ('T3 pad', (1664, 224, 630)), ('K', (2368, 100, 54)), ('F', (-2560, -1700, -74)), ('e', (-256, -1200, 54)),
    ('Q', (0, -2100, -74)), ('C', (2600, -1900, -74)), ('crane', (2650, -2000, 310)),
]
# eye shots: (x, y, z, yaw, pitch), one per district
EYES = [
    (-2880, 1700, 54, 0, 0),        # A: CT spawn looking at the sally port
    (-1800, 2016, 54, 0, 0),        # M1 toward the station side gate
    (-1408, 1500, 54, 270, 0),      # M2 toward the arcade
    (600, 1600, 54, 90, 0),         # R: T spawn looking at the train
    (-900, 1950, 54, 0, 0),         # R platform east
    (-2600, 200, 54, 0, 0),         # S yard toward the gantry
    (-1850, -50, 54, 0, 0),         # L lane
    (-900, 800, 54, 315, 0),        # P from the NW toward the tower
    (0, -900, 54, 90, 0),           # P from the south (monument, forecourts)
    (1400, 224, 54, 0, 0),          # T0 lobby
    (1300, 224, 630, 0, 0),         # T3 roof
    (2368, 900, 54, 270, 0),        # K north cell
    (-2560, -1500, -74, 270, 0),    # F fish market
    (0, -1250, 30, 270, -10),       # e harbor steps
    (-600, -2100, -74, 0, 0),       # Q toward the bridge gap
    (2368, -1200, -74, 270, 0),     # C terminal from the ramp
    (1800, 1900, 54, 0, 0),         # H yard
]


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--quality', default='normal')
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'maps'))
    ap.add_argument('--preview', default=None)
    ap.add_argument('--mock', action='store_true', help='add mock detail at the spec face budgets (perf test)')
    ap.add_argument('--dry', action='store_true')
    a = ap.parse_args(argv)
    m = build(mock=a.mock)
    probs = m.spawn_problems()
    print('pre-compile spawn check:', probs or 'OK', m.stats())
    if a.dry:
        return 0 if not probs else 1
    from ..compile import compile_map
    r = compile_map(m, a.quality, None if a.mock else a.out)
    print(r.summary())
    if r.bsp and os.path.exists(r.bsp):
        from ..bspcheck import perf_at
        try:
            for (label, p), res in zip(CHECKPOINTS, perf_at(r.bsp, [pt for _, pt in CHECKPOINTS])):
                print(f"  at {label:10s} {p}: view max {res['view_max']} (yaw {res['view_yaw']:.0f}), "
                      f"PVS {res['pvs_total']}, leaves {res['visible_leaves']}, {res['contents']}")
        except Exception as ex:   # perf_at output format is informative only
            print('  (perf_at:', ex, ')')
    if r.ok and a.preview:
        from ..preview import render_views
        for p in render_views(r.bsp, a.preview, 1100, eyes=EYES):
            print(p)
    return 0 if r.ok else 1


if __name__ == '__main__':
    sys.exit(main())
