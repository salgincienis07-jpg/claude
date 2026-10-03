"""mapkit self test: WAD round trip + every brush/entity helper compiled.

    cd devtools && python3 -m mapkit.selftest
"""
from __future__ import annotations

import os
import sys
import tempfile

import numpy as np


def test_wad(tmp: str) -> None:
    from . import textures
    from .wad import read_wad, validate_wad, write_wad
    names = ['vx_conc_clean', '{vx_fence', 'vx_lava', '~vx_light_w', '!vx_water']
    texs = textures.build(names)
    p = os.path.join(tmp, 't.wad')
    write_wad(p, texs.values())
    back = read_wad(p)
    assert set(back) == {k.lower() for k in texs}, (set(back), set(texs))
    for k, t in texs.items():
        b = back[k.lower()]
        assert b.mips == t.mips and b.palette == t.palette
    assert not validate_wad(p), validate_wad(p)
    fence = back['{vx_fence']
    idx = np.frombuffer(fence.mips[0], np.uint8)
    assert (idx == 255).any() and fence.palette[765:768] == b'\x00\x00\xff'
    assert all(f'+{i}vx_lava' in back for i in range(10))
    print('wad: OK', len(back), 'textures')


def feature_map():
    from .mapwriter import (CLIP, SKY, TRIGGER, Brush, Map, arch, box, breakable, catwalk, crate, door, env_sprite,
                            frame, func_water, glass, ladder, light, light_environment, light_spot, masked_entity,
                            pipe, prism, room, skybox, spawn_grid, stairs, trigger_hurt, wall, wedge, ambient)
    m = Map('zm_mapkit_selftest', sky='desert')
    # outdoor sky-boxed yard with a solid ground
    m.add(skybox((-1024, -1024, 0), (1024, 1024, 768), ground='vx_sand'))
    m.add_entity(light_environment(-50, 120, (255, 236, 200), 200, diffuse=(120, 150, 200, 60)))
    # building with a doorway + frame + window
    m.add(room((-300, -300, 0), (300, 300, 256), 16, {'sides': 'vx_brick_red', 'bottom': 'vx_wood_floor', 'top': 'vx_roof_tile'},
               omit={'s'}))
    holes = [(268, 364, 0, 112), (100, 196, 64, 144)]
    m.add(wall((-316, -300), (316, -300), 0, 256, 16, 'vx_brick_red', holes=holes, side='right'))
    m.add(frame((-316, -308), (316, -308), 0, 256, 16, 24, 'vx_trim_metal', holes[0]))
    gl = Brush.box((-216, -310, 64), (-120, -306, 144), 'vx_glass')
    m.add_entity(glass([gl]))
    # sliding door (+x) in the doorway
    dp = Brush.box((-48, -306, 0), (48, -302, 112), {'n': 'vx_door_metal', 's': 'vx_door_metal', 'all': 'vx_metal_dark'})
    dp.fit_faces(('n', 's'))
    m.add_entity(door([dp], '+x', speed=80, lip=4))
    # stairs + ramp + pillars + arch + pipe
    m.add(stairs((-200, 100, 0), '+y', 64, 96, rise=8, run=16, clip=True))
    m.add(wedge((150, -150, 0), '+x', 96, 128, 64, 'vx_metal_diam'))
    m.add(prism((500, 500), 32, 12, 0, 300, 'vx_pillar'))
    m.add(arch((600, -600), 0, 64, 160, 128, 32, 'y', 8, 'vx_stone_carved'))
    m.add(box((584, -680, 0), (616, -664, 64), 'vx_stone_carved'))
    m.add(pipe((-900, 600, 40), (-500, 600, 40), 12, 8, 'vx_pipe'))
    m.add(pipe((-900, 700, 0), (-900, 700, 200), 10, 8, 'vx_pipe'))
    # catwalk with railings and a ladder
    slab, rv, rc = catwalk((400, 0), (900, 0), 192, 64)
    m.add(slab, rc)
    for x in (420, 880):
        m.add(box((x - 8, -8, 0), (x + 8, 8, 184), 'vx_metal_dark'))
    m.add(box((900, -64, 0), (964, 64, 192), 'vx_metal_corr'))
    lad, lvis = ladder((900, 40, 0), '+x', 196)
    m.add_entity(lad, masked_entity(rv + lvis, solid=False))
    # water pool (func_water), lava strip with trigger_hurt, breakable crate
    m.add(box((-800, -800, -64), (-500, -500, 0), 'vx_rock'))
    m.add_entity(func_water([Brush.box((-760, -760, 0), (-540, -540, 24), '!vx_water')]))
    m.add(box((-780, -780, 0), (-760, -520, 32), 'vx_rock'), box((-540, -780, 0), (-520, -520, 32), 'vx_rock'),
          box((-760, -780, 0), (-540, -760, 32), 'vx_rock'), box((-760, -540, 0), (-540, -520, 32), 'vx_rock'))
    m.add(box((-400, 700, -32), (-200, 900, 0), 'vx_lavarock'))
    m.add(box((-380, 720, -32), (-220, 880, -8), '+0vx_lava'))
    m.add_entity(trigger_hurt([Brush.box((-380, 720, -8), (-220, 880, 16), TRIGGER)], 20, 8))
    bc = crate((700, 600, 0), 64, 'vx_crate_wood')
    m.add_entity(breakable(bc, material=1, health=50))
    # lights + misc entities
    m.add_entity(light((0, 0, 200), (255, 230, 200), 300), light_spot((0, 0, 250), -90, 0, (255, 255, 255), 400))
    m.add_entity(env_sprite((0, 0, 230), 'sprites/glow01.spr', 0.4), ambient((0, 0, 100), 'vexmira/wind.wav'))
    m.add_entities(spawn_grid('ct', (-1000, 200), (-400, 600), 0, 32, 64, face=(0, 0)))
    m.add_entities(spawn_grid('t', (100, 650), (1000, 1000), 0, 32, 64, face=(0, 0)))
    return m


def test_compile(tmp: str) -> None:
    from .compile import compile_map
    m = feature_map()
    probs = m.spawn_problems()
    assert not probs, probs
    r = compile_map(m, 'draft', work_root=tmp, verbose=False)
    print(r.summary())
    assert r.ok, 'compile failed'
    assert not r.check['errors'], r.check['errors']
    from .bspcheck import format_report
    print(format_report(r.check))
    print('compile: OK')


def main():
    tmp = os.environ.get('MAPKIT_WORK') or tempfile.mkdtemp(prefix='mapkit_')
    os.makedirs(tmp, exist_ok=True)
    test_wad(tmp)
    test_compile(tmp)
    return 0


if __name__ == '__main__':
    sys.exit(main())
