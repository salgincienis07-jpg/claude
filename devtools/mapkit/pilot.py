"""zm_vex_pilot - end-to-end test map for the mapkit pipeline (testing only).

    cd devtools && python3 -m mapkit.pilot [--quality final] [--out ../cstrike/maps]

Layout (units, floor z=0):
  * main lab hall  x -640..640, y -512..512, h 320: CT spawns (south),
    sunken toxic pool (liquid + trigger_hurt), 4 pillars, crate cover,
    east CT camp platform (z 160) with stairs + ladder + railings + grate,
    SW control booth with breakable glass windows and lit screens,
    skylight shaft (sky + light_environment), VEXMIRA neon sign (texlight).
  * zombie den (north) x -640..640, y 528..1040, h 256: T spawns, red
    emergency lamps, blood/goo overlays; connected by an auto blast door
    (func_door) and an arched open passage.
"""
from __future__ import annotations

import argparse
import os
import sys

from .mapwriter import (CLIP, NULL, SKY, TRIGGER, Brush, Entity, Map, ambient, arch, box, catwalk, crate,
                        door, env_sprite, frame, glass, ladder, light, light_environment, light_spot,
                        masked_entity, prism, railing, room, spawn_grid, stairs, wall, func_illusionary,
                        func_wall, trigger_hurt)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))

WALL = 'vx_wall_lab'
FLOOR = 'vx_floor_lab'
CEIL = 'vx_metal_panel'


def build() -> Map:
    m = Map('zm_vex_pilot', sky='night', message='Vexmira Pilot (mapkit test)',
            extra={})
    T = 16
    # ------------------------------------------------------------------
    # MAIN HALL shell (custom floor with a pool pit, ceiling with skylight)
    X0, X1, Y0, Y1, ZT = -640, 640, -512, 512, 320
    m.add(room((X0, Y0, 0), (X1, Y1, ZT), T, WALL, omit={'n', 'bottom', 'top'}))
    # floor (z -96..0) with pool pit x -192..192, y -64..192 (bottom z -64)
    PX0, PX1, PY0, PY1 = -192, 192, -64, 192
    fz0 = -96
    m.add(box((X0 - T, Y0 - T, fz0), (X1 + T, PY0, 0), FLOOR))
    m.add(box((X0 - T, PY1, fz0), (X1 + T, Y1 + T, 0), FLOOR))
    m.add(box((X0 - T, PY0, fz0), (PX0, PY1, 0), FLOOR))
    m.add(box((PX1, PY0, fz0), (X1 + T, PY1, 0), FLOOR))
    m.add(box((PX0, PY0, fz0), (PX1, PY1, -64), 'vx_tile_dirty'))
    # pool walls inside the pit get dirty tiles
    for b in m.world.brushes[-5:-1]:
        b.retex({'top': FLOOR, 'all': 'vx_tile_dirty'})
    # hazard curb around the pool
    m.add(box((PX0 - 8, PY0 - 8, 0), (PX1 + 8, PY0, 6), 'vx_trim_hazard'))
    m.add(box((PX0 - 8, PY1, 0), (PX1 + 8, PY1 + 8, 6), 'vx_trim_hazard'))
    m.add(box((PX0 - 8, PY0, 0), (PX0, PY1, 6), 'vx_trim_hazard'))
    m.add(box((PX1, PY0, 0), (PX1 + 8, PY1, 6), 'vx_trim_hazard'))
    # toxic liquid (world brush with a ! texture = water contents) + damage
    m.add(box((PX0, PY0, -64), (PX1, PY1, -14), '!vx_toxic'))
    # exit steps out of the pool (west side), rise 16 / run 20
    m.add(stairs((PX0 + 80, 64, -64), '-x', 64, 64, rise=16, run=20, tex={'top': 'vx_metal_diam', 'all': 'vx_tile_dirty'}))
    m.add_entity(trigger_hurt([Brush.box((PX0, PY0, -64), (PX1, PY1, -20), TRIGGER)], dmg=6,
                              damagetype=1 << 20))
    # ceiling with a 256x256 skylight hole (x -128..128, y -384..-128)
    SX0, SX1, SY0, SY1 = -128, 128, -384, -128
    m.add(box((X0 - T, Y0 - T, ZT), (SX0, Y1 + T, ZT + T), CEIL))
    m.add(box((SX1, Y0 - T, ZT), (X1 + T, Y1 + T, ZT + T), CEIL))
    m.add(box((SX0, Y0 - T, ZT), (SX1, SY0, ZT + T), CEIL))
    m.add(box((SX0, SY1, ZT), (SX1, Y1 + T, ZT + T), CEIL))
    # skylight shaft + sky lid
    m.add(box((SX0 - T, SY0 - T, ZT + T), (SX1 + T, SY0, ZT + 96), 'vx_metal_dark'))
    m.add(box((SX0 - T, SY1, ZT + T), (SX1 + T, SY1 + T, ZT + 96), 'vx_metal_dark'))
    m.add(box((SX0 - T, SY0, ZT + T), (SX0, SY1, ZT + 96), 'vx_metal_dark'))
    m.add(box((SX1, SY0, ZT + T), (SX1 + T, SY1, ZT + 96), 'vx_metal_dark'))
    m.add(box((SX0 - T, SY0 - T, ZT + 96), (SX1 + T, SY1 + T, ZT + 96 + T), SKY))
    # skylight grate (masked, non-solid) just below the sky
    sky_grate = Brush.box((SX0, SY0, ZT + 80), (SX1, SY1, ZT + 82), {'top': '{vx_grate', 'bottom': '{vx_grate', 'all': NULL})
    m.add_entity(light_environment(pitch=-75, yaw=60, color=(170, 190, 255), brightness=90,
                                   diffuse=(60, 70, 110, 40), origin=(0, -256, ZT + 60)))

    # north wall of the hall with a door hole and an arch passage
    DOOR_X, ARCH_X = -256, 256
    holes = [(DOOR_X - 64 + 656, DOOR_X + 64 + 656, 0, 128), (ARCH_X - 64 + 656, ARCH_X + 64 + 656, 0, 160)]
    nwall = wall((X0 - T, Y1), (X1 + T, Y1), 0, ZT, T, WALL, holes=holes, side='left')
    for bw in nwall:   # zombie-den side of the shared wall
        bw.face('n').tex = 'vx_conc_stain'
    m.add(nwall)
    m.add(frame((X0 - T, Y1 + T / 2), (X1 + T, Y1 + T / 2), 0, ZT, T, T + 8, 'vx_trim_metal', holes[0], trim=8))
    m.add(arch((ARCH_X, Y1 + T / 2), 96, 64, 128, 160, T, 'x', 8, 'vx_stone_carved'))
    # blast door (auto opens on touch, slides up)
    dpanel = Brush.box((DOOR_X - 64, Y1 + 4, 0), (DOOR_X + 64, Y1 + 12, 128), {'n': 'vx_door_lab', 's': 'vx_door_lab', 'all': 'vx_metal_dark'})
    dpanel.fit_faces(('n', 's'))
    m.add_entity(door([dpanel], 'up', speed=140, wait=3, lip=8, sounds=0))
    # DANGER neon over the door (hall side)
    sign = Brush.box((DOOR_X - 96, Y1 - 4, 152), (DOOR_X + 96, Y1, 200), {'s': '~vx_neon_dngr', 'all': 'vx_metal_dark'})
    sign.fit_faces(('s',))
    m.add(sign)

    # ------------------------------------------------------------------
    # ZOMBIE DEN (north room)
    RY0, RY1, RZ = Y1 + T, 1040, 256
    m.add(room((X0, RY0, 0), (X1, RY1, RZ), T, 'vx_conc_stain', floor='vx_tile_dirty', ceil='vx_conc_crack',
               omit={'s'}))
    # red emergency lamps on the side walls + light entities + glow sprites
    for y in (680, 900):
        for x, face in ((X0, 'e'), (X1, 'w')):
            dx = 4 if face == 'e' else -4
            lb = Brush.box((min(x, x + dx), y - 24, 168), (max(x, x + dx), y + 24, 216), {face: '~vx_light_r', 'all': 'vx_metal_dark'})
            lb.fit_faces((face,))
            m.add(lb)
            m.add_entity(light((x + dx * 12, y, 192), (255, 40, 30), 110))
            m.add_entity(env_sprite((x + dx * 3, y, 192), 'sprites/glow01.spr', 0.35, (255, 40, 30), 160))
    m.add_entity(light((0, 780, 230), (255, 120, 90), 120))
    m.add_entity(light((-400, 780, 230), (200, 60, 40), 90))
    m.add_entity(light((400, 780, 230), (200, 60, 40), 90))
    # slime/blood overlays (masked, non solid)
    decals = []
    for x, y, tex in ((-300, 1040 - 2, '{vx_blood1'), (200, 1040 - 2, '{vx_goo'), (520, 1040 - 2, '{vx_blood2')):
        b = Brush.box((x - 64, y, 40), (x + 64, y + 2, 168), {'s': tex, 'all': NULL})
        b.fit_faces(('s',))
        decals.append(b)
    claw = Brush.box((X1 - 2, 760, 60), (X1, 888, 188), {'w': '{vx_claw', 'all': NULL})
    claw.fit_faces(('w',))
    decals.append(claw)
    m.add_entity(masked_entity(decals, solid=False))
    m.add_entities(spawn_grid('t', (X0, RY0), (X1, RY1), 0, 32, spacing=72, yaw=270))
    m.add_entity(ambient((0, 800, 128), 'vexmira/heartbeat.wav', volume=6, radius='medium'))

    # ------------------------------------------------------------------
    # HALL DETAILS
    for px, py in ((-352, 256), (352, 256), (-352, -48), (352, -48)):
        m.add(prism((px, py), 26, 8, 0, ZT, 'vx_metal_panel'))
        m.add(prism((px, py), 34, 8, 0, 12, 'vx_metal_dark'))
    # ceiling light fixtures (texlights) + fill lights
    for fx in (-448, 0, 448):
        for fy in (-320, 64, 384):
            if fx == 0 and fy == -320:
                continue  # skylight
            lb = Brush.box((fx - 64, fy - 32, ZT - 6), (fx + 64, fy + 32, ZT), {'bottom': '~vx_light_w', 'all': 'vx_metal_dark'})
            lb.fit_faces(('bottom',))
            m.add(lb)
    for fx, fy in ((-448, -320), (448, -320), (-448, 384), (448, 384), (0, 64)):
        m.add_entity(light((fx, fy, 220), (255, 246, 230), 110))
    m.add_entity(light_spot((0, 64, 300), pitch=-90, color=(120, 255, 80), brightness=260, cone=35, cone2=60))
    m.add_entity(env_sprite((0, 64, -6), 'sprites/glow01.spr', 0.6, (110, 255, 60), 120))
    # VEXMIRA neon sign on the west wall + its glow
    sign = Brush.box((X0, -64, 196), (X0 + 4, 192, 260), {'e': '~vx_neon_vex', 'all': 'vx_metal_dark'})
    sign.fit_faces(('e',))
    m.add(sign)
    m.add_entity(env_sprite((X0 + 12, 64, 228), 'sprites/glow01.spr', 1.2, (170, 90, 255), 70))
    # corporate plate + bio sign + exit sign
    plate = Brush.box((X1 - 4, -224, 120), (X1, -96, 184), {'w': 'vx_sign_vex', 'all': 'vx_metal_dark'})
    plate.fit_faces(('w',))
    m.add(plate)
    bio = Brush.box((PX0 - 40, Y1 - 4, 40), (PX0 + 24, Y1, 104), {'s': 'vx_sign_bio', 'all': 'vx_metal_dark'})
    bio.fit_faces(('s',))
    m.add(bio)
    ex = Brush.box((ARCH_X - 32, Y1 - 4, 176), (ARCH_X + 32, Y1, 208), {'s': '~vx_neon_exit', 'all': 'vx_metal_dark'})
    ex.fit_faces(('s',))
    m.add(ex)
    # crates (cover)
    for x, y, s, t in ((-264, 100, 64, 'vx_crate_mil'), (-264, 36, 48, 'vx_crate_wood'), (264, 120, 64, 'vx_crate_wood'),
                       (-500, 440, 64, 'vx_crate_mil'), (-436, 440, 64, 'vx_crate_mil')):
        m.add(crate((x, y, 0), s, t))
    m.add(crate((-468, 440, 64), 64, 'vx_crate_wood'))
    # container prop on the west side
    cont = Brush.box((X0, 120, 0), (X0 + 96, 376, 128), {'e': 'vx_cont_blue', 'n': 'vx_cont_end', 's': 'vx_cont_end',
                                                        'top': 'vx_metal_corr', 'all': 'vx_cont_blue'})
    cont.fit_faces(('e', 'n', 's'))
    m.add(cont)

    # ------------------------------------------------------------------
    # CT CAMP PLATFORM (east), top z=160
    PZ = 160
    BX0 = 448
    # solid base block (north part) with machine panels
    m.add(box((BX0, 96, 0), (X1, 256, PZ - 8), {'all': 'vx_metal_panel', 'top': 'vx_metal_dark'}))
    # walkable grate deck (func_wall, masked) over the whole platform + support beams
    deck = Brush.box((BX0, -256, PZ - 8), (X1, 256, PZ), {'top': '{vx_grate', 'bottom': '{vx_grate', 'all': 'vx_metal_dark'})
    m.add(box((BX0, -256, PZ - 16), (X1, -240, PZ - 8), 'vx_metal_dark'))
    m.add(box((BX0, -16, PZ - 16), (X1, 0, PZ - 8), 'vx_metal_dark'))
    m.add(box((BX0, -256, PZ - 16), (BX0 + 16, 96, PZ - 8), 'vx_metal_dark'))
    m.add(prism((BX0 + 16, -240), 10, 8, 0, PZ - 16, 'vx_metal_dark'))
    m.add(prism((BX0 + 16, -8), 10, 8, 0, PZ - 16, 'vx_metal_dark'))
    deck_ent = masked_entity([deck, sky_grate], solid=True)
    m.add_entity(deck_ent)
    # stairs along the east wall from the south (rise 16 / run 24)
    m.add(stairs((X1 - 32, -496, 0), '+y', 64, PZ, rise=16, run=24, tex={'top': 'vx_metal_diam', 'all': 'vx_metal_dark'}))
    # railings (masked visual + clip)
    vis_all, clip_all = [], []
    for a, b in (((BX0 + 2, -256), (BX0 + 2, 144)), ((BX0 + 2, 208), (BX0 + 2, 256)), ((BX0, -254), (X1 - 64, -254))):
        v, c = railing(a, b, PZ)
        vis_all += v
        clip_all += c
    m.add(clip_all)
    # ladder on the base block's west face (y 160..192)
    lad, lvis = ladder((BX0, 176, 0), '+x', PZ + 4, width=32, depth=10)
    m.add_entity(lad)
    m.add_entity(masked_entity(vis_all + lvis, solid=False))
    # camp extras: ammo crates on the deck
    m.add(crate((X1 - 48, 200, PZ), 48, 'vx_crate_mil'))

    # ------------------------------------------------------------------
    # CONTROL BOOTH (SW corner) with glass windows + screens
    BX1, BY1, BZ = -384, -320, 128
    win_n = (64, 192, 48, 104)      # along the north wall from x=-640
    m.add(wall((X0, BY1), (BX1, BY1), 0, BZ, T, 'vx_metal_panel', holes=[win_n], side='right'))
    # east wall with an open doorway (y -512..-320 measured from y=-512)
    m.add(wall((BX1, Y0), (BX1, BY1), 0, BZ, T, 'vx_metal_panel', holes=[(32, 96, 0, 104)], side='left'))
    m.add(box((X0, Y0, BZ), (BX1, BY1, BZ + T), {'bottom': 'vx_metal_floor', 'all': 'vx_metal_dark'}))
    gl = Brush.box((X0 + win_n[0], BY1 - T / 2 - 2, win_n[2]), (X0 + win_n[1], BY1 - T / 2 + 2, win_n[3]), 'vx_glass')
    gl.fit_faces(('n', 's'))
    m.add_entity(glass([gl], breakable=True, health=30, renderamt=90))
    # console desk + wall screens
    m.add(box((X0, -500, 0), (X0 + 48, -340, 36), {'top': 'vx_console', 'all': 'vx_metal_dark'}))
    for i, tx in enumerate(('~vx_screen1', '~vx_screen2', '~vx_screen3')):
        y0 = -496 + i * 54
        s = Brush.box((X0, y0, 48), (X0 + 4, y0 + 48, 84), {'e': tx, 'all': 'vx_metal_dark'})
        s.fit_faces(('e',))
        m.add(s)
    m.add_entity(light((-560, -420, 100), (140, 220, 255), 60))
    srv = Brush.box((-520, -512, 0), (-420, -480, 112), {'n': 'vx_server', 'all': 'vx_metal_dark'})
    srv.fit_faces(('n',))
    m.add(srv)

    # ------------------------------------------------------------------
    # CT spawns (south part of the hall, same floor), facing north
    m.add_entities(spawn_grid('ct', (-368, Y0), (416, -96), 0, 32, spacing=72, yaw=90))
    m.add_entity(ambient((0, -200, 200), 'vexmira/ambient.wav', volume=5, radius='large'))
    m.add_entity(Entity('info_map_parameters', buying=0))
    return m


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--quality', default='final')
    ap.add_argument('--out', default=os.path.join(REPO, 'cstrike', 'maps'))
    ap.add_argument('--preview', default=None, help='directory for preview PNGs')
    a = ap.parse_args(argv)
    from .compile import compile_map
    m = build()
    probs = m.spawn_problems()
    print('pre-compile spawn check:', probs or 'OK', m.stats())
    r = compile_map(m, a.quality, a.out)
    if r.ok and a.preview:
        from .preview import render_views
        for p in render_views(r.bsp, a.preview, 1200):
            print(p)
    return 0 if r.ok else 1


if __name__ == '__main__':
    sys.exit(main())
