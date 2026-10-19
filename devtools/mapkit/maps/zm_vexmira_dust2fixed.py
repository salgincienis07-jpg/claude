"""zm_vexmira_dust2fixed - de_dust2 (owner supplied .rmf source) turned into a Vexmira Zombie Plague camp map.

    cd devtools && python3 -m mapkit.maps.zm_vexmira_dust2fixed --rmf de_dust2.rmf [--quality final] [--preview DIR]

The original layout is kept 1:1 (brushes, texture alignment); cs_dust.wad textures are replaced by our own
dust-style look-alikes (mapkit/dust2tex.py, embedded -> no wad download). Bomb sites / buy zones / hostage
gear are removed; zombie-plague additions (camps, doors, glass, towers, signs, spawns) live in ADDITIONS.
"""
from __future__ import annotations

import argparse
import os
import re
import sys

from .. import dust2tex  # noqa: F401  (registers the d2_* textures)
from ..mapwriter import Map
from ..rmf import RMF

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
NAME = 'zm_vexmira_dust2fixed'
DROP = {'func_bomb_target', 'func_buyzone', 'info_bomb_target', 'func_hostage_rescue', 'hostage_entity',
        'info_map_parameters', 'trigger_camera', 'info_target'}


def retex(m: RMF):
    miss = set()
    def fix(s):
        for f in s.faces:
            k = f.tex.lower()
            if k in dust2tex.RMF_TEX:
                f.tex = dust2tex.RMF_TEX[k]
            else:
                miss.add(f.tex)
    for s in m.world_solids:
        fix(s)
    for e in m.ents:
        for s in e.solids:
            fix(s)
    return miss


def base_map(rmf_path):
    m = RMF(rmf_path)
    miss = retex(m)
    if miss:
        print('unmapped textures:', miss)
    m.ents = [e for e in m.ents if e.classname not in DROP]
    m.world.keys = [('classname', 'worldspawn'), ('skyname', 'desert'), ('MaxRange', '8192'),
                    ('message', 'zm_vexmira_dust2fixed - MapBy:SmurfSexy - Vexmira Zombie')]
    return m


def build(rmf_path, quality='normal', preview=None, out=None):
    from ..compile import compile_map
    m = base_map(rmf_path)
    from . import zm_vexmira_dust2fixed_add as add
    add.prepare(m)
    extra_world, extra_ents = add.additions(m)
    text = m.to_map(extra_world, extra_ents)
    work = os.environ.get('MAPKIT_WORK', os.path.join(HERE, '..', '.build'))
    os.makedirs(work, exist_ok=True)
    mp = os.path.join(work, NAME + '.map')
    open(mp, 'w').write(text)
    r = compile_map(mp, quality=quality, out_dir=out or os.path.join(REPO, 'cstrike', 'maps'))
    print(r.summary())
    if preview and r.ok:
        from ..preview import render_views
        render_views(r.bsp, preview)
    add.write_ini(m, r.bsp if r.ok else None)
    return r


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--rmf', required=True)
    ap.add_argument('--quality', default='normal')
    ap.add_argument('--preview')
    ap.add_argument('--out')
    a = ap.parse_args()
    r = build(a.rmf, a.quality, a.preview, a.out)
    sys.exit(0 if r.ok else 1)
