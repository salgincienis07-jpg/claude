"""zm_vex_laboratory - underground Vexmira bio-lab turned toxic disaster.

    cd devtools && python3 -m mapkit.maps.zm_vex_laboratory [--quality final] [--preview DIR] [--wav]

Layout (units, floor z=0 unless noted, all rooms sealed individually):
  ATRIUM      x -640..640, y -640..640, ceiling 448. Sunken toxic pool (liquid + trigger_hurt,
              exit steps E/W) under a z=192 catwalk cross (central hub = camp D). North and south
              balconies (z=192) on solid bases, stairs (W->south balcony, E->north balcony) and
              ladders. CT spawns on the north floor strip. Open floor = boss arena.
  CONTROL     raised control room x -320..320, y 656..960, floor 192 (camp A): door + breakable
              glass windows to the north balcony, lit screens, vent exit to the west lab loft.
  WEST LABS   x -1344..-656, y -448..448, ceiling 320: central corridor, glass-walled labs
              (breakable panes), glowing specimen tanks, raised loft z=192 (camp C: stairs,
              ladder, vent to the control room).
  SERVER      x 656..1344, y -448..448, ceiling 320: rack rows with LEDs/screens, bridge from the
              hub, mezzanine z=192 (camp B: bridge, stairs, ladder).
  SOUTH HALL  quarantine bay x -640..640, y -1216..-656, ceiling 256: T spawns, red emergency
              light, tunnel north into the atrium, crawl vents (64 high) to the labs and server
              room = zombie flank routes.
"""
from __future__ import annotations

import argparse
import math
import os
import struct
import sys

import numpy as np

from ..mapwriter import (CLIP, NULL, TRIGGER, Brush, Entity, Map, ambient, box, catwalk, crate, env_sprite,
                         frame, func_wall, glass, ladder, light, light_spot, masked_entity, pipe, prism,
                         railing, spawn_grid, stairs, trigger_hurt, wall)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
NAME = 'zm_vex_laboratory'
AMB = 'vexmira/map/zm_vex_laboratory_amb.wav'

T = 16
WALL = 'vx_wall_lab'
DARK = 'vx_metal_dark'
PANEL = 'vx_metal_panel'
TRIM = 'vx_trim_metal'
HAZ = 'vx_trim_hazard'


class Ctx:
    def __init__(self, m: Map):
        self.m = m
        self.detail = []      # func_wall (solid props, no vis splits)
        self.masked = []      # func_illusionary rendermode 4 (rails, ladders, decals, grates)
        self.masked_solid = []  # func_wall rendermode 4 (grate decks)
        self.tanks = []       # func_wall rendermode 2 (tank glass)
        self.clip = []

    def W(self, bl):
        self.m.add(bl)

    def D(self, bl):
        self.detail += bl


# ----------------------------------------------------------------------------------------------
def shell(c: Ctx, X0, Y0, X1, Y1, z0, z1, tex, floor, ceil, holes=None, omit=(), wall_tex=None):
    """Room shell around interior box; holes per side in ABSOLUTE coords (a0, a1, hz0, hz1)."""
    holes = holes or {}
    wt = wall_tex or {}
    zb, zt = z0 - T, z1 + T
    if 'bottom' not in omit:
        c.W(box((X0 - T, Y0 - T, zb), (X1 + T, Y1 + T, z0), floor))
    if 'top' not in omit:
        c.W(box((X0 - T, Y0 - T, z1), (X1 + T, Y1 + T, zt), ceil))
    spec = {
        'n': ((X0 - T, Y1), (X1 + T, Y1), 'left', X0 - T),
        's': ((X0 - T, Y0), (X1 + T, Y0), 'right', X0 - T),
        'e': ((X1, Y0), (X1, Y1), 'right', Y0),
        'w': ((X0, Y0), (X0, Y1), 'left', Y0),
    }
    for side, (p0, p1, sd, base) in spec.items():
        if side in omit:
            continue
        hl = [(a0 - base, a1 - base, h0, h1) for a0, a1, h0, h1 in holes.get(side, [])]
        c.W(wall(p0, p1, z0, z1, T, wt.get(side, tex), holes=hl, side=sd))


def band(c: Ctx, side, X0, Y0, X1, Y1, z0, z1, depth, tex, holes=(), detail=True):
    """Trim band on the inside of a wall (skips holes overlapping the band height)."""
    if side in 'ns':
        a_lo, a_hi = X0, X1
    else:
        a_lo, a_hi = Y0, Y1
    cuts = sorted((a0, a1) for a0, a1, h0, h1 in holes if h0 < z1 and h1 > z0)
    segs, cur = [], a_lo
    for a0, a1 in cuts:
        if a0 > cur:
            segs.append((cur, min(a0, a_hi)))
        cur = max(cur, a1)
    if cur < a_hi:
        segs.append((cur, a_hi))
    out = []
    for a, b in segs:
        if b - a < 4:
            continue
        if side == 'n':
            out += box((a, Y1 - depth, z0), (b, Y1, z1), tex)
        elif side == 's':
            out += box((a, Y0, z0), (b, Y0 + depth, z1), tex)
        elif side == 'e':
            out += box((X1 - depth, a, z0), (X1, b, z1), tex)
        else:
            out += box((X0, a, z0), (X0 + depth, b, z1), tex)
    (c.D if detail else c.W)(out)


def plate(c: Ctx, side, x0, y0, z0, x1, y1, z1, tex, solid=True):
    """Thin wall-mounted panel with `tex` fitted on its visible face (`side` = facing dir)."""
    b = Brush.box((x0, y0, z0), (x1, y1, z1), {side: tex, 'all': DARK})
    b.fit_faces((side,))
    (c.W if solid else c.D)([b])
    return b


def ceil_lamp(c: Ctx, x, y, z, w=128, d=64, tex='~vx_light_w', axis='x'):
    if axis == 'y':
        w, d = d, w
    b = Brush.box((x - w / 2, y - d / 2, z - 6), (x + w / 2, y + d / 2, z), {'bottom': tex, 'all': DARK})
    b.fit_faces(('bottom',))
    c.W([b])
    c.D(box((x - w / 2 - 4, y - d / 2 - 4, z - 10), (x + w / 2 + 4, y - d / 2, z), DARK))
    c.D(box((x - w / 2 - 4, y + d / 2, z - 10), (x + w / 2 + 4, y + d / 2 + 4, z), DARK))


def wall_lamp(c: Ctx, face, x, y, z, color, tex='~vx_light_r', glow=0.3, bright=90, style=None):
    """Caged lamp on a wall; face = direction the lamp faces (into the room)."""
    dx, dy = {'n': (0, 1), 's': (0, -1), 'e': (1, 0), 'w': (-1, 0)}[face]
    if dx:
        b = Brush.box((min(x, x + dx * 6), y - 16, z - 16), (max(x, x + dx * 6), y + 16, z + 16), {face: tex, 'all': DARK})
    else:
        b = Brush.box((x - 16, min(y, y + dy * 6), z - 16), (x + 16, max(y, y + dy * 6), z + 16), {face: tex, 'all': DARK})
    b.fit_faces((face,))
    c.D([b])
    c.m.add_entity(light((x + dx * 24, y + dy * 24, z), color, bright, style=style))
    if glow:
        c.m.add_entity(env_sprite((x + dx * 10, y + dy * 10, z), 'sprites/glow01.spr', glow, color, 150))


def barrel(c: Ctx, x, y, z=0, tex='vx_hazard'):
    c.D(prism((x, y), 15, 10, z, z + 44, {'top': DARK, 'bottom': DARK, 'all': tex}))
    c.D(prism((x, y), 16, 10, z + 14, z + 18, DARK))
    c.D(prism((x, y), 16, 10, z + 30, z + 34, DARK))


def rails(c: Ctx, segs, z, height=40):
    for a, b in segs:
        v, cl = railing(a, b, z, height)
        c.masked += v
        c.clip += cl
        # metal cap on top of the masked rail
        (ax, ay), (bx, by) = a, b
        if abs(ay - by) < 1e-6:
            xa, xb = sorted((ax, bx))
            c.D(box((xa, ay - 2, z + height), (xb, ay + 2, z + height + 4), DARK))
        else:
            ya, yb = sorted((ay, by))
            c.D(box((ax - 2, ya, z + height), (ax + 2, yb, z + height + 4), DARK))


def lad(c: Ctx, base, facing, height):
    e, vis = ladder(base, facing, height, width=32, depth=12)
    c.m.add_entity(e)
    c.masked += vis
    x, y, z = base
    # side stringers
    dx, dy = {'+x': (1, 0), '-x': (-1, 0), '+y': (0, 1), '-y': (0, -1)}[facing]
    px, py = -dy, dx
    for s in (-1, 1):
        cx, cy = x + px * s * 18 - dx * 3, y + py * s * 18 - dy * 3
        c.D(box((cx - 2, cy - 2, z), (cx + 2, cy + 2, z + height), DARK))


def glass_pane(c: Ctx, axis, a0, a1, at, z0, z1, health=40):
    if axis == 'x':     # pane runs along x, at y = at
        g = Brush.box((a0, at - 2, z0), (a1, at + 2, z1), 'vx_glass')
        g.fit_faces(('n', 's'))
    else:
        g = Brush.box((at - 2, a0, z0), (at + 2, a1, z1), 'vx_glass')
        g.fit_faces(('e', 'w'))
    c.m.add_entity(glass([g], breakable=True, health=health, renderamt=80))


def decal(c: Ctx, face, x0, y0, z0, x1, y1, z1, tex):
    b = Brush.box((x0, y0, z0), (x1, y1, z1), {face: tex, 'all': NULL})
    b.fit_faces((face,))
    c.masked.append(b)


# ----------------------------------------------------------------------------------------------
def build() -> Map:
    m = Map(NAME, sky='night', message='Vexmira Laboratory')
    c = Ctx(m)

    # ================================ ATRIUM =================================================
    AX, AY, AZ = 640, 640, 448
    PX, PY = 256, 224           # pool half extents
    atr_holes = {
        'n': [(-48, 48, 192, 304), (-288, -80, 232, 296), (80, 288, 232, 296)],
        's': [(-96, 96, 0, 128)],
        'e': [(-64, 64, 0, 128), (-64, 64, 192, 320)],
        'w': [(-80, 80, 0, 128)],
    }
    shell(c, -AX, -AY, AX, AY, -96, AZ, WALL, 'vx_floor_lab', PANEL, holes=atr_holes, omit=('bottom',),
          wall_tex={'n': WALL})
    # floor with a pool pit
    F = 'vx_floor_lab'
    c.W(box((-AX - T, -AY - T, -112), (AX + T, -PY, 0), F))
    c.W(box((-AX - T, PY, -112), (AX + T, AY + T, 0), F))
    c.W(box((-AX - T, -PY, -112), (-PX, PY, 0), F))
    c.W(box((PX, -PY, -112), (AX + T, PY, 0), F))
    c.W(box((-PX, -PY, -112), (PX, PY, -64), 'vx_tile_dirty'))
    for b in m.world.brushes[-5:-1]:
        b.retex({'top': F, 'all': 'vx_tile_dirty'})
    c.W(box((-PX - 8, -PY - 8, 0), (PX + 8, -PY, 6), HAZ))
    c.W(box((-PX - 8, PY, 0), (PX + 8, PY + 8, 6), HAZ))
    c.W(box((-PX - 8, -PY, 0), (-PX, PY, 6), HAZ))
    c.W(box((PX, -PY, 0), (PX + 8, PY, 6), HAZ))
    c.W(box((-PX, -PY, -64), (PX, PY, -16), '!vx_toxic'))
    m.add_entity(trigger_hurt([Brush.box((-PX, -PY, -64), (PX, PY, -20), TRIGGER)], dmg=5, damagetype=1 << 20))
    # pool exit steps (west + east)
    c.W(stairs((-PX + 72, -120, -64), '-x', 64, 64, rise=16, run=18, tex={'top': 'vx_metal_diam', 'all': 'vx_tile_dirty'}))
    c.W(stairs((PX - 72, 120, -64), '+x', 64, 64, rise=16, run=18, tex={'top': 'vx_metal_diam', 'all': 'vx_tile_dirty'}))
    # drain grates on the pool floor + submerged debris
    c.D(box((-40, -40, -64), (40, 40, -60), {'top': '{vx_grate', 'all': DARK}))

    # balcony bases (solid) + decks z=192
    BZ = 192
    # north base: pipes wall face
    c.W(box((-AX, 512, 0), (AX, AY, BZ - 16), {'s': 'vx_pipes_wall', 'all': PANEL}))
    c.W(box((-AX, 512, BZ - 16), (AX, AY, BZ), {'top': 'vx_metal_floor', 's': HAZ, 'all': DARK}))
    # south base with a central ground tunnel (x -96..96, h 128)
    c.W(box((-AX, -AY, 0), (-96, -512, BZ - 16), {'n': 'vx_pipes_wall', 'all': PANEL}))
    c.W(box((96, -AY, 0), (AX, -512, BZ - 16), {'n': 'vx_pipes_wall', 'all': PANEL}))
    c.W(box((-96, -AY, 128), (96, -512, BZ - 16), {'bottom': PANEL, 'all': DARK}))
    c.W(box((-AX, -AY, BZ - 16), (AX, -512, BZ), {'top': 'vx_metal_floor', 'n': HAZ, 'all': DARK}))
    c.D(frame((-AX, -512 - 4), (AX, -512 - 4), 0, 160, 8, 16, TRIM, (AX - 96, AX + 96, 0, 128), trim=12))
    # tunnel walls (pipes) + light
    ceil_lamp(c, 0, -576, 128, 96, 32, '~vx_light_r')
    # balcony base vents / panels
    for x in (-512, -160, 160, 512):
        plate(c, 's', x - 48, 506, 40, x + 48, 512, 104, 'vx_vent', solid=False)
    for x in (-512, 512):
        plate(c, 'n', x - 48, -512, 40, x + 48, -506, 104, 'vx_vent', solid=False)

    # stairs: west -> south balcony, east -> north balcony (+ landings)
    STX = {'top': 'vx_metal_diam', 'all': DARK}
    c.W(stairs((-600, -128, 0), '-y', 64, BZ, rise=16, run=24, tex=STX, clip=True))
    c.W(box((-AX, -512, 0), (-568, -416, BZ), {'top': 'vx_metal_diam', 'all': PANEL}))
    c.W(stairs((600, 128, 0), '+y', 64, BZ, rise=16, run=24, tex=STX, clip=True))
    c.W(box((568, 416, 0), (AX, 512, BZ), {'top': 'vx_metal_diam', 'all': PANEL}))
    # ladders on the balcony bases
    lad(c, (-320, 512, 0), '+y', BZ + 4)
    lad(c, (320, -512, 0), '-y', BZ + 4)

    # catwalk cross over the pool, hub = camp D
    CW = {'top': 'vx_metal_diam', 'bottom': DARK, 'all': HAZ}
    HUB = 112
    c.W(box((-HUB, -HUB, BZ - 12), (HUB, HUB, BZ), {'top': 'vx_metal_floor', 'bottom': DARK, 'all': HAZ}))
    c.W(box((-48, HUB, BZ - 12), (48, 512, BZ), CW))
    c.W(box((-48, -512, BZ - 12), (48, -HUB, BZ), CW))
    c.W(box((HUB, -48, BZ - 12), (1120, 48, BZ), CW))
    # beams under the catwalks
    c.D(box((-40, HUB, BZ - 24), (-32, 512, BZ - 12), DARK) + box((32, HUB, BZ - 24), (40, 512, BZ - 12), DARK))
    c.D(box((-40, -512, BZ - 24), (-32, -HUB, BZ - 12), DARK) + box((32, -512, BZ - 24), (40, -HUB, BZ - 12), DARK))
    c.D(box((HUB, -40, BZ - 24), (1120, -32, BZ - 12), DARK) + box((HUB, 32, BZ - 24), (1120, 40, BZ - 12), DARK))
    # supports
    for x, y in ((-96, -96), (96, -96), (-96, 96), (96, 96)):
        c.D(prism((x, y), 12, 8, -64, BZ - 12, 'vx_pipe'))
        c.D(prism((x, y), 18, 8, -64, -40, DARK))
    for x, y, z0 in ((0, -384, 0), (416, 0, 0), (880, 0, 0)):
        c.D(prism((x, y), 12, 8, z0, BZ - 12, 'vx_pipe'))
        c.D(prism((x, y), 20, 8, z0, 12, DARK))
    # rails: hub (west side full, others with gaps), catwalks, balconies
    rs = [((-HUB + 2, -HUB), (-HUB + 2, HUB)),
          ((-HUB, HUB - 2), (-48, HUB - 2)), ((48, HUB - 2), (HUB, HUB - 2)),
          ((-HUB, -HUB + 2), (-48, -HUB + 2)), ((48, -HUB + 2), (HUB, -HUB + 2)),
          ((HUB - 2, HUB), (HUB - 2, 48)), ((HUB - 2, -HUB), (HUB - 2, -48)),
          ((-46, HUB), (-46, 512)), ((46, HUB), (46, 512)),
          ((-46, -512), (-46, -HUB)), ((46, -512), (46, -HUB)),
          ((HUB, -46), (640, -46)), ((HUB, 46), (640, 46)),
          ((656, -46), (1118, -46)), ((656, 46), (1118, 46)),
          # north balcony edge y=512: gaps at ladder (-352..-288), catwalk, east landing
          ((-AX, 514), (-352, 514)), ((-288, 514), (-48, 514)), ((48, 514), (568, 514)),
          # south balcony edge: gaps at west landing, catwalk, ladder (288..352)
          ((-568, -514), (-48, -514)), ((48, -514), (288, -514)), ((352, -514), (AX, -514))]
    rails(c, rs, BZ)
    # hub cover: two waist-high equipment crates
    c.D(crate((-40, 40, BZ), 40, 'vx_crate_mil'))
    c.D(crate((40, -40, BZ), 40, 'vx_crate_mil'))

    # ceiling: beams + light fixtures + pipes
    for y in (-384, -128, 128, 384):
        c.D(box((-AX, y - 16, AZ - 32), (AX, y + 16, AZ), {'bottom': DARK, 'all': TRIM}))
    for x in (-384, 0, 384):
        for y in (-256, 0, 256):
            ceil_lamp(c, x, y, AZ, 128, 64)
    for x, y in ((-384, -256), (384, -256), (-384, 256), (384, 256), (0, 0)):
        m.add_entity(light((x, y, AZ - 64), (240, 245, 255), 95))
    c.D(pipe((-AX, AY - 24, 400), (AX, AY - 24, 400), 10, 8, 'vx_pipe'))
    c.D(pipe((-AX, AY - 48, 376), (AX, AY - 48, 376), 7, 8, 'vx_pipe'))
    c.D(pipe((-AX, -AY + 24, 400), (AX, -AY + 24, 400), 10, 8, 'vx_pipe'))
    for x, y in ((-AX + 20, AY - 20), (AX - 20, AY - 20), (-AX + 20, -AY + 20), (AX - 20, -AY + 20)):
        c.D(pipe((x, y, BZ), (x, y, AZ), 12, 8, 'vx_pipe'))
    # upper wall pilasters + baseboards + mid trim
    for x in (-512, -384, 384, 512):
        c.D(box((x - 16, AY - 16, BZ), (x + 16, AY, AZ), {'s': TRIM, 'all': DARK}))
        c.D(box((x - 16, -AY, BZ), (x + 16, -AY + 16, AZ), {'n': TRIM, 'all': DARK}))
    for y in (-384, 384):
        c.D(box((-AX, y - 16, BZ + 16), (-AX + 16, y + 16, AZ), {'e': TRIM, 'all': DARK}))
        c.D(box((AX - 16, y - 16, BZ + 16), (AX, y + 16, AZ), {'w': TRIM, 'all': DARK}))
    for s in ('e', 'w'):
        band(c, s, -AX, -512, AX, 512, 0, 12, 4, DARK, [(a0, a1, h0, h1) for a0, a1, h0, h1 in atr_holes[s]])
        band(c, s, -AX, -512, AX, 512, 232, 240, 4, TRIM, [(a0, a1, h0, h1) for a0, a1, h0, h1 in atr_holes[s]])
    band(c, 'n', -AX, -AY, AX, AY, 320, 328, 4, TRIM, atr_holes['n'])
    band(c, 's', -AX, -AY, AX, AY, 320, 328, 4, TRIM)
    # frames around the ground doors (W and E) and the control room door
    c.D(frame((-AX - 8, -AY), (-AX - 8, AY), 0, 160, 8, 32, TRIM, (AY - 80, AY + 80, 0, 128), trim=12))
    c.D(frame((AX + 8, -AY), (AX + 8, AY), 0, 160, 8, 32, TRIM, (AY - 64, AY + 64, 0, 128), trim=12))
    c.D(frame((AX + 8, -AY), (AX + 8, AY), 192, 340, 8, 32, TRIM, (AY - 64, AY + 64, BZ, 320), trim=12))
    c.D(frame((-AX, AY + 8), (AX, AY + 8), 192, 320, 8, 32, TRIM, (AX - 48, AX + 48, BZ, 304), trim=10))
    for a0, a1 in ((-288, -80), (80, 288)):
        c.D(frame((-AX, AY + 8), (AX, AY + 8), 200, 320, 8, 28, TRIM, (AX + a0, AX + a1, 232, 296), trim=8))
        glass_pane(c, 'x', a0, a1, AY + 8, 232, 296, health=60)
    # signs: VEXMIRA neon (cyan underline strip) on the east/west upper walls, danger, bio, exits
    for side, xw in (('e', -AX), ('w', AX)):
        d = 4 if side == 'e' else -4
        xa, xb = sorted((xw, xw + d))
        plate(c, side, xa, -128, 352, xb, 128, 416, '~vx_neon_vex')
        plate(c, side, xa, -128, 336, xb, 128, 344, '~vx_light_c')
        m.add_entity(env_sprite((xw + d * 4, 0, 384), 'sprites/glow01.spr', 1.0, (40, 220, 255), 80))
        m.add_entity(light((xw + d * 20, 0, 360), (40, 220, 255), 110))
    plate(c, 'n', -128, -AY, 228, 128, -AY + 4, 292, '~vx_neon_dngr')
    plate(c, 's', -96, AY - 4, 324, 96, AY, 372, '~vx_neon_safe')
    plate(c, 'w', AX - 4, -48, 148, AX, 48, 180, '~vx_neon_exit')
    plate(c, 'e', -AX, -48, 148, -AX + 4, 48, 180, '~vx_neon_exit')
    plate(c, 'n', -200, -512, 120, -136, -508, 184, 'vx_sign_bio', solid=False)
    plate(c, 'n', 136, -512, 120, 200, -508, 184, 'vx_sign_bio', solid=False)
    plate(c, 's', 160, 508, 112, 288, 512, 176, 'vx_sign_vex', solid=False)
    # toxic glow: green lights over the pool, spot from above, sprites
    for x, y in ((-160, -120), (160, -120), (-160, 120), (160, 120)):
        m.add_entity(light((x, y, 16), (110, 255, 60), 110))
        m.add_entity(env_sprite((x, y, -12), 'sprites/glow01.spr', 0.8, (110, 255, 60), 90))
    m.add_entity(light_spot((0, 0, AZ - 40), pitch=-90, color=(130, 255, 90), brightness=200, cone=40, cone2=70))
    # red emergency lamps (pulse) on the balcony bases and upper walls
    for x in (-448, 448):
        wall_lamp(c, 's', x, 512, 150, (255, 40, 30), bright=90, style=None)
        wall_lamp(c, 'n', x, -512, 150, (255, 40, 30), bright=90)
    for y in (-256, 256):
        wall_lamp(c, 'e', -AX, y, 300, (255, 40, 30), bright=80, glow=0.25)
        wall_lamp(c, 'w', AX, y, 300, (255, 40, 30), bright=80, glow=0.25)
    # cover on the atrium floor: barrels, crates, lab carts, blast barriers
    for x, y in ((-330, -300), (-300, -340), (300, -430), (-430, 160), (440, -160), (210, -330)):
        barrel(c, x, y)
    for x, y, s, t in ((-420, -300, 64, 'vx_crate_mil'), (420, -330, 56, 'vx_crate_wood'), (-200, -420, 48, 'vx_crate_mil'),
                       (360, -250, 48, 'vx_crate_mil')):
        c.D(crate((x, y, 0), s, t))
    c.D(crate((-420, -300, 64), 40, 'vx_crate_wood'))
    for x0, y0, x1, y1 in ((-520, -40, -456, 40), (456, -200, 520, -136)):
        c.D(box((x0, y0, 0), (x1, y1, 48), {'top': DARK, 'all': HAZ}))
    # blood / goo decals
    decal(c, 'w', AX - 2, -480, 24, AX, -352, 152, '{vx_claw')
    decal(c, 'e', -AX, 200, 30, -AX + 2, 328, 158, '{vx_blood2')
    decal(c, 'top', -500, 360, 0, -372, 488, 0.5, '{vx_goo')
    decal(c, 'top', 120, -460, 0, 248, -332, 0.5, '{vx_blood1')

    # CT spawns: north floor strip (between pool curb and the north base)
    m.add_entities(spawn_grid('ct', (-536, 236), (536, 512), 0, 32, spacing=72, yaw=270))

    # ================================ CONTROL ROOM (camp A) =================================
    CX0, CX1, CY0, CY1, CZ0, CZ1 = -320, 320, 656, 960, BZ, 336
    shell(c, CX0, CY0, CX1, CY1, CZ0, CZ1, 'vx_conc_panel', 'vx_metal_floor', PANEL,
          holes={'w': [(880, 944, BZ, 256)]}, omit=('s',))
    # desks under the windows (cover), screens on the back wall, racks
    for a0, a1 in ((-288, -96), (96, 288)):
        c.D(box((a0, 664, BZ), (a1, 696, BZ + 36), {'top': 'vx_console', 'all': DARK}))
    for i, (x, tx) in enumerate(((-224, '~vx_screen1'), (-96, '~vx_screen2'), (32, '~vx_screen3'), (160, '~vx_screen1'))):
        plate(c, 's', x, CY1 - 4, 240, x + 96, CY1, 312, tx)
    c.D(box((-256, 900, BZ), (224, 952, BZ + 40), {'top': 'vx_console', 'all': DARK}))
    for x in (-304, 272):
        b = Brush.box((x, 720, BZ), (x + 32, 812, BZ + 112), {'e': 'vx_server', 'w': 'vx_server', 'all': DARK})
        c.D([b])
    plate(c, 'e', CX0, 700, 260, CX0 + 4, 828, 324, 'vx_sign_vex')
    plate(c, 'w', CX1 - 4, 720, 300, CX1, 848, 308, '~vx_light_c')
    ceil_lamp(c, -160, 808, CZ1, 128, 32, '~vx_light_c')
    ceil_lamp(c, 160, 808, CZ1, 128, 32, '~vx_light_c')
    m.add_entity(light((0, 800, 300), (150, 230, 255), 110))
    m.add_entity(light((-200, 720, 260), (40, 220, 255), 60))
    m.add_entity(light((200, 720, 260), (40, 220, 255), 60))
    c.D(crate((240, 760, BZ), 40, 'vx_crate_mil'))
    c.D(box((-320, 880 - 8, BZ + 64), (-312, 944 + 8, BZ + 72), TRIM))

    # ================================ VENT: control room -> west loft ========================
    VZ0, VZ1 = BZ, BZ + 64
    shell(c, -1248, 880, -336, 944, VZ0, VZ1, 'vx_metal_corr', 'vx_metal_floor', 'vx_metal_corr',
          holes={'s': [(-1248, -1184, VZ0, VZ1)]}, omit=('e',))
    shell(c, -1248, 464, -1184, 880, VZ0, VZ1, 'vx_metal_corr', 'vx_metal_floor', 'vx_metal_corr', omit=('n', 's'))
    for x in (-1000, -660):
        m.add_entity(light((x, 912, VZ1 - 12), (90, 200, 255), 40))
    m.add_entity(light((-1216, 680, VZ1 - 12), (90, 200, 255), 40))
    plate(c, 'e', -1248, 896, VZ0 + 8, -1244, 928, VZ0 + 56, 'vx_vent', solid=False)

    # ================================ WEST LABS ==============================================
    WX0, WX1, WY0, WY1, WZ = -1344, -656, -448, 448, 320
    shell(c, WX0, WY0, WX1, WY1, 0, WZ, 'vx_wall_lab', 'vx_tile_lab', PANEL,
          holes={'s': [(-1000, -936, 0, 64)], 'n': [(-1248, -1184, VZ0, VZ1)]}, omit=('e',))
    # loft (camp C) base + deck
    LX = -1152
    c.W(box((WX0, WY0, 0), (LX, WY1, BZ - 16), {'e': 'vx_pipes_wall', 'all': PANEL}))
    c.W(box((WX0, WY0, BZ - 16), (LX, WY1, BZ), {'top': 'vx_metal_floor', 'e': HAZ, 'all': DARK}))
    c.W(stairs((-864, 416, 0), '-x', 64, BZ, rise=16, run=24, tex=STX, clip=True))
    lad(c, (LX, -320, 0), '-x', BZ + 4)
    rails(c, [((LX - 2, -448), (LX - 2, -352)), ((LX - 2, -288), (LX - 2, 384))], BZ)
    plate(c, 'e', WX0, -96, 240, WX0 + 4, 96, 288, '~vx_neon_safe')
    m.add_entity(light((WX0 + 40, 0, 260), (40, 220, 255), 90))
    c.D(crate((WX0 + 40, 300, BZ), 48, 'vx_crate_mil'))
    c.D(crate((WX0 + 40, 248, BZ), 40, 'vx_crate_wood'))
    c.D(box((WX0, -200, BZ), (WX0 + 40, -40, BZ + 36), {'top': 'vx_console', 'all': DARK}))
    # partitions (corridor y -80..80), glass windows, doors
    for sgn in (1, -1):
        y0, y1 = (80, 96) if sgn > 0 else (-96, -80)
        ym = (y0 + y1) / 2
        holes = [(-1120 - LX, -920 - LX, 48, 136), (-896 - LX, -832 - LX, 0, 112), (-808 - LX, -688 - LX, 48, 136)]
        c.W(wall((LX, ym), (WX1, ym), 0, WZ, 16, 'vx_wall_lab', holes=holes, side='center'))
        for a0, a1 in ((-1120, -920), (-808, -688)):
            glass_pane(c, 'x', a0, a1, ym, 48, 136, health=30)
            c.D(box((a0, ym - 12, 40), (a1, ym + 12, 48), TRIM))
        c.D(frame((LX, ym), (WX1, ym), 0, 128, 16, 24, TRIM, (-896 - LX, -832 - LX, 0, 112), trim=8))
    # lab benches + specimen tanks
    for x0, x1, y0, y1 in ((-1100, -940, 200, 248), (-860, -700, 200, 248), (-1100, -940, -248, -200), (-860, -700, -248, -200)):
        c.D(box((x0, y0, 0), (x1, y1, 36), {'top': 'vx_tile_lab', 'all': PANEL}))
        c.D(box((x0 - 4, y0 - 4, 36), (x1 + 4, y1 + 4, 40), DARK))
    for x, y in ((-720, 380), (-720, -380), (-1080, -400), (-840, -400)):
        c.D(prism((x, y), 30, 12, 0, 16, DARK))
        c.D(prism((x, y), 30, 12, 112, 128, DARK))
        c.D(prism((x, y), 18, 10, 16, 112, '+0vx_sludge'))
        c.tanks += prism((x, y), 26, 12, 16, 112, 'vx_glass')
        m.add_entity(light((x, y - 40 if y > 0 else y + 40, 64), (110, 255, 60), 60))
    for x in (-1080, -880):
        for y in (-260, 0, 260):
            ceil_lamp(c, x, y, WZ, 128, 32, '~vx_light_w' if y else '~vx_light_c')
    m.add_entity(light((-1000, 270, 220), (240, 245, 255), 80, style=10))
    m.add_entity(light((-1000, -270, 220), (240, 245, 255), 80))
    m.add_entity(light((-900, 0, 200), (40, 220, 255), 70))
    plate(c, 's', -820, WY1 - 4, 132, -756, WY1, 196, 'vx_sign_bio')
    plate(c, 'n', -820, WY0, 132, -756, WY0 + 4, 196, 'vx_sign_bio')
    decal(c, 'n', -1080, WY0, 20, -952, WY0 + 2, 148, '{vx_blood2')
    decal(c, 's', -760, WY1 - 2, 30, -632 - 20, WY1, 158, '{vx_goo')
    c.D(pipe((LX, 64, 290), (WX1, 64, 290), 8, 8, 'vx_pipe'))
    c.D(pipe((LX, -64, 290), (WX1, -64, 290), 8, 8, 'vx_pipe'))

    # ================================ SERVER ROOM (camp B) ===================================
    SX0, SX1, SY0, SY1, SZ = 656, 1344, -448, 448, 320
    shell(c, SX0, SY0, SX1, SY1, 0, SZ, 'vx_metal_panel', 'vx_metal_floor', PANEL,
          holes={'s': [(936, 1000, 0, 64)]}, omit=('w',))
    MX = 1120
    c.W(box((MX, SY0, 0), (SX1, SY1, BZ - 16), {'w': 'vx_server', 'all': PANEL}))
    c.W(box((MX, SY0, BZ - 16), (SX1, SY1, BZ), {'top': 'vx_metal_floor', 'w': HAZ, 'all': DARK}))
    c.W(stairs((832, 416, 0), '+x', 64, BZ, rise=16, run=24, tex=STX, clip=True))
    lad(c, (MX, -256, 0), '+x', BZ + 4)
    rails(c, [((MX + 2, -448), (MX + 2, -288)), ((MX + 2, -224), (MX + 2, -48)), ((MX + 2, 48), (MX + 2, 384))], BZ)
    for x0, x1, y in ((700, 900, -300), (700, 1040, -180), (700, 1040, 180), (700, 1040, 300)):
        b = Brush.box((x0, y - 16, 0), (x1, y + 16, 112), {'n': 'vx_server', 's': 'vx_server', 'top': DARK, 'all': DARK})
        c.D([b])
        c.D(box((x0, y - 18, 112), (x1, y + 18, 118), TRIM))
        c.D(pipe((x0 + 8, y, 118), (x0 + 8, y, SZ), 6, 6, 'vx_pipe'))
    for x in (780, 960):
        for y in (-240, 240):
            ceil_lamp(c, x, y, SZ, 128, 32, '~vx_light_c')
    m.add_entity(light((870, -240, 260), (60, 200, 255), 90))
    m.add_entity(light((870, 240, 260), (60, 200, 255), 90))
    m.add_entity(light((870, 0, 140), (200, 230, 255), 70))
    m.add_entity(light((1230, 0, 290), (220, 235, 255), 90))
    for i, (y, tx) in enumerate(((-352, '~vx_screen3'), (-224, '~vx_screen1'), (160, '~vx_screen2'), (288, '~vx_screen1'))):
        plate(c, 'w', SX1 - 4, y, 232, SX1, y + 96, 304, tx)
    c.D(box((SX1 - 40, -160, BZ), (SX1, 96, BZ + 36), {'top': 'vx_console', 'all': DARK}))
    c.D(crate((1180, -400, BZ), 48, 'vx_crate_mil'))
    c.D(crate((1180, 400, BZ), 40, 'vx_crate_mil'))
    wall_lamp(c, 'n', 760, SY0, 220, (255, 40, 30), bright=70, glow=0.25)
    wall_lamp(c, 's', 760, SY1, 220, (255, 40, 30), bright=70, glow=0.25)
    plate(c, 'n', 700, SY0, 60, 828, SY0 + 4, 124, 'vx_sign_vex', solid=False)

    # ================================ SOUTH HALL (T spawns) ==================================
    HX, HY0, HY1, HZ = 640, -1216, -656, 256
    shell(c, -HX, HY0, HX, HY1, 0, HZ, 'vx_conc_stain', 'vx_tile_dirty', 'vx_conc_crack',
          holes={'w': [(-800, -736, 0, 64)], 'e': [(-800, -736, 0, 64)], 'n': [(-96, 96, 0, 128)]})
    c.D(frame((-HX, HY1 + 8 - 16), (HX, HY1 + 8 - 16), 0, 160, 8, 16, HAZ, (HX - 96, HX + 96, 0, 128), trim=12))
    plate(c, 's', -128, HY1 - 4, 168, 128, HY1, 232, '~vx_neon_dngr')
    for x in (-448, 0, 448):
        for y in (-1088, -800):
            ceil_lamp(c, x, y, HZ, 64, 64, '~vx_light_r')
    for x, y in ((-448, -940), (448, -940), (0, -940)):
        m.add_entity(light((x, y, 200), (255, 50, 35), 110, style=None))
    m.add_entity(light((0, -1150, 120), (255, 120, 90), 70))
    for y in (-1100, -880):
        wall_lamp(c, 'e', -HX, y, 180, (255, 40, 30), bright=60, glow=0.3, style=2)
        wall_lamp(c, 'w', HX, y, 180, (255, 40, 30), bright=60, glow=0.3, style=2)
    for x in (-HX + 20, HX - 20):
        c.D(pipe((x, HY0, 230), (x, HY1, 230), 10, 8, 'vx_pipe'))
    c.D(pipe((-HX, HY0 + 24, 220), (HX, HY0 + 24, 220), 12, 8, 'vx_pipe'))
    band(c, 'n', -HX, HY0, HX, HY1, 0, 48, 4, HAZ, [(-96, 96, 0, 128)])
    band(c, 's', -HX, HY0, HX, HY1, 0, 48, 4, HAZ)
    band(c, 'e', -HX, HY0, HX, HY1, 64, 72, 4, TRIM)
    band(c, 'w', -HX, HY0, HX, HY1, 64, 72, 4, TRIM)
    for s in ('e', 'w'):
        x = -HX if s == 'w' else HX
        d = 1 if s == 'w' else -1
        c.D(frame((x - d * 8, HY0), (x - d * 8, HY1), 0, 80, 8, 32, TRIM, (-800 - HY0, -736 - HY0, 0, 64), trim=8))
    decal(c, 'n', -500, HY0, 20, -372, HY0 + 2, 148, '{vx_blood1')
    decal(c, 'n', 300, HY0, 30, 428, HY0 + 2, 158, '{vx_goo')
    decal(c, 'e', -HX, -1000, 40, -HX + 2, -872, 168, '{vx_claw')
    decal(c, 'w', HX - 2, -1060, 20, HX, -932, 148, '{vx_blood2')
    # quarantine bay structure: support columns with hazard bases + decon barriers near the tunnel
    for x in (-384, 384):
        for y in (-760, -1150):
            c.D(box((x - 20, y - 20, 0), (x + 20, y + 20, HZ), {'all': 'vx_conc_panel'}))
            c.D(box((x - 24, y - 24, 0), (x + 24, y + 24, 40), {'top': DARK, 'all': HAZ}))
            c.D(box((x - 24, y - 24, HZ - 16), (x + 24, y + 24, HZ), TRIM))
    for x0, x1 in ((-260, -170), (170, 260)):
        c.D(box((x0, -740, 0), (x1, -716, 44), {'top': DARK, 'all': HAZ}))
    m.add_entities(spawn_grid('t', (-600, -1110), (600, -800), 0, 32, spacing=72, yaw=90))
    m.add_entity(ambient((0, -940, 160), AMB, volume=6, radius='large'))
    m.add_entity(ambient((0, 0, 300), AMB, volume=5, radius='large'))
    m.add_entity(ambient((-1000, 0, 200), AMB, volume=4, radius='medium'))
    m.add_entity(ambient((1000, 0, 200), AMB, volume=4, radius='medium'))

    # ================================ CRAWL VENTS (zombie flank routes) =======================
    for sgn in (-1, 1):
        xa, xb = sorted((sgn * 656, sgn * 1000))
        mx0, mx1 = sorted((sgn * 936, sgn * 1000))
        shell(c, xa, -800, xb, -736, 0, 64, 'vx_metal_corr', 'vx_metal_floor', 'vx_metal_corr',
              holes={'n': [(mx0, mx1, 0, 64)]}, omit=('e',) if sgn < 0 else ('w',))
        shell(c, mx0, -736, mx1, -464, 0, 64, 'vx_metal_corr', 'vx_metal_floor', 'vx_metal_corr', omit=('n', 's'))
        m.add_entity(light(((xa + xb) / 2, -768, 52), (255, 120, 60), 35))
        m.add_entity(light(((mx0 + mx1) / 2, -600, 52), (90, 200, 255), 35))
        # vent grilles framing the mouths
        c.D(box((mx0 - 8, -448, 64), (mx1 + 8, -440, 72), TRIM))

    # ----------------------------------------------------------------------------------------
    m.add(c.clip)
    if c.detail:
        m.add_entity(func_wall(c.detail))
    if c.tanks:
        m.add_entity(func_wall(c.tanks, rendermode=2, renderamt=110))
    if c.masked:
        m.add_entity(masked_entity(c.masked, solid=False))
    m.add_entity(Entity('info_map_parameters', buying=0))
    return m


# ----------------------------------------------------------------------------------------------
def make_ambient(path: str, sr: int = 22050, seconds: float = 5.0):
    """Seamless looping lab ambience: ventilation hum + distant machinery + bubbling + dripping.
    Every periodic component completes an integer number of cycles in the loop. cue at 0 = loop."""
    rng = np.random.default_rng(4242)
    n = int(sr * seconds)
    t = np.arange(n) / sr
    f = lambda hz: round(hz * seconds) / seconds   # integer cycles per loop
    x = 0.32 * np.sin(2 * np.pi * f(55) * t) + 0.18 * np.sin(2 * np.pi * f(110) * t + 0.4)
    x += 0.08 * np.sin(2 * np.pi * f(165.2) * t) + 0.05 * np.sin(2 * np.pi * f(331) * t + 1.1)
    x *= 0.8 + 0.2 * np.sin(2 * np.pi * f(0.4) * t)
    # ventilation noise: circularly filtered white noise (FFT band-pass -> perfectly periodic)
    spec = np.fft.rfft(rng.standard_normal(n))
    fr = np.fft.rfftfreq(n, 1 / sr)
    spec *= np.exp(-((fr - 380) / 260) ** 2) + 0.35 * np.exp(-((fr - 1400) / 500) ** 2)
    air = np.fft.irfft(spec, n)
    air /= np.abs(air).max()
    x += 0.22 * air * (0.85 + 0.15 * np.sin(2 * np.pi * f(0.2) * t))
    # toxic bubbling + drips (placed circularly)
    for k in range(14):
        pos = int(rng.uniform(0, n))
        fq = rng.uniform(180, 420)
        L = int(0.09 * sr)
        tt = np.arange(L) / sr
        b = np.sin(2 * np.pi * (fq + 900 * tt) * tt) * np.exp(-tt * 45) * rng.uniform(0.08, 0.16)
        idx = (pos + np.arange(L)) % n
        x[idx] += b
    for k in range(3):
        pos = int(rng.uniform(0, n))
        L = int(0.12 * sr)
        tt = np.arange(L) / sr
        b = np.sin(2 * np.pi * (1300 - 500 * tt) * tt) * np.exp(-tt * 60) * 0.18
        x[(pos + np.arange(L)) % n] += b
    x = x / np.abs(x).max() * 0.7
    pcm = (x * 32767).astype('<i2').tobytes()
    fmt = struct.pack('<HHIIHH', 1, 1, sr, sr * 2, 2, 16)
    cue = struct.pack('<I', 1) + struct.pack('<II4sIII', 1, 0, b'data', 0, 0, 0)
    body = b'WAVE' + b'fmt ' + struct.pack('<I', len(fmt)) + fmt + b'cue ' + struct.pack('<I', len(cue)) + cue \
        + b'data' + struct.pack('<I', len(pcm)) + pcm
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as fh:
        fh.write(b'RIFF' + struct.pack('<I', len(body)) + body)
    return path


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--quality', default='final')
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'maps'))
    ap.add_argument('--preview', default=None)
    ap.add_argument('--wav', action='store_true', help='(re)write the looping ambience WAV')
    ap.add_argument('--dry', action='store_true')
    a = ap.parse_args(argv)
    if a.wav:
        p = make_ambient(os.path.join(REPO, 'cstrike', 'sound', AMB))
        print('wav', p, os.path.getsize(p))
    m = build()
    probs = m.spawn_problems()
    print('pre-compile spawn check:', probs or 'OK', m.stats())
    if a.dry:
        return 0 if not probs else 1
    from ..compile import compile_map
    r = compile_map(m, a.quality, a.out)
    print(r.summary())
    if r.ok and a.preview:
        from ..preview import render_views
        eyes = [(0, 560, BZ_EYE, 270, -15), (900, 0, 64, 0, 5), (-900, 0, 64, 180, 5), (0, -1100, 64, 90, 5),
                (0, 900, 192 + 64, 270, -10)]
        for p in render_views(r.bsp, a.preview, 1100, eyes=eyes):
            print(p)
    return 0 if r.ok else 1


BZ_EYE = 192 + 64

if __name__ == '__main__':
    sys.exit(main())
