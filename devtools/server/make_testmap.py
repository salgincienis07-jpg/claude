#!/usr/bin/env python3
"""zm_vex_testroom - small boot map for the headless test server (NOT shipped).

One 1536x1536x288 hall: 32 CT spawns (south), 32 T spawns (north), crates for cover,
a raised east platform with stairs + ladder (bot nav: ladders/jumps), four pillars,
plenty of light. Generated textures (mapkit, all embedded) + sdhlt.wad tool textures.

    python3 devtools/server/make_testmap.py [--out $SP/server/cstrike/maps] [--quality normal]
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from mapkit.mapwriter import (Map, box, crate, ladder, light, light_environment, prism, room, spawn_grid,  # noqa
                              stairs, masked_entity)
from mapkit.compile import compile_map  # noqa: E402

SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'


def build():
    m = Map('zm_vex_testroom', sky='night', message='Vexmira test room (server harness)')
    X, Y, H, T = 768, 768, 288, 16
    m.add(room((-X, -Y, 0), (X, Y, H), T, 'vx_conc_panel', floor='vx_floor_lab', ceil='vx_metal_panel'))
    # pillars
    for px in (-320, 320):
        for py in (-160, 160):
            m.add(prism((px, py), 40, 8, 0, H, 'vx_pillar'))
    # crates (cover, 48-64 high: jumpable)
    for (cx, cy, s) in ((-520, 0, 64), (-460, 60, 48), (0, 0, 64), (60, -40, 48), (420, -420, 64),
                        (-420, 420, 64), (0, 320, 56), (0, -320, 56)):
        m.add(crate((cx, cy, 0), s, 'vx_crate_mil'))
    # east platform (camp spot), z=128, x 560..752, y -256..256
    PZ = 128
    m.add(box((560, -256, 0), (X, 256, PZ), {'top': 'vx_metal_diam', 'all': 'vx_metal_plate'}))
    m.add(stairs((432, -192, 0), '+x', 64, PZ, rise=16, run=16,
                 tex={'top': 'vx_metal_diam', 'all': 'vx_metal_plate'}))
    lad, lvis = ladder((560, 176, 0), '+x', PZ + 4, width=32, depth=10)
    m.add_entity(lad)
    m.add_entity(masked_entity(lvis, solid=False))
    # lights
    for lx in (-512, -128, 256, 640):
        for ly in (-512, 0, 512):
            m.add_entity(light((lx, ly, H - 32), (255, 240, 220), 260))
    m.add_entity(light((660, 0, PZ + 120), (120, 200, 255), 200))
    # spawns: CT south strip, T north strip
    m.add_entities(spawn_grid('ct', (-700, -720), (520, -520), 0, 32, spacing=72, yaw=90))
    m.add_entities(spawn_grid('t', (-700, 520), (520, 720), 0, 32, spacing=72, yaw=270))
    return m


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(SP, 'server/cstrike/maps'))
    ap.add_argument('--quality', default='normal')
    ap.add_argument('--preview', default=os.path.join(SP, 'previews/server'))
    a = ap.parse_args(argv)
    m = build()
    probs = m.spawn_problems()
    print('spawn problems:', probs)
    print(m.stats())
    r = compile_map(m, quality=a.quality, out_dir=a.out)
    print(r.summary())
    if not r.ok:
        sys.exit(1)
    if a.preview:
        from mapkit.preview import render_views
        os.makedirs(a.preview, exist_ok=True)
        print(render_views(r.bsp, a.preview, size=900))


if __name__ == '__main__':
    main()
