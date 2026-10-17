"""Team laser mines (5.3.1): a clean CT tech mine and an organic zombie bio-mine.

    cd devtools && python3 -m mdlkit.content.lasermines

Both keep the laser mine contract of content/world.py:lasermine (the plugin settings are shared):
+X = beam direction, mounting face at x = 0, origin = centre of the mounting face, attachment 0 = lens tip
(10.3, 0, 0) on bone 'head', sequences deploy (0) + idle (1, looping pulse).
Out: cstrike/models/vexmira/lasermine/lm_human.mdl, lm_zombie.mdl
"""
from __future__ import annotations

import math
import os

import numpy as np

from . import *          # noqa: F401,F403
from . import world as W
from ..geom import ellipsoid as _ell

OUT = os.path.join(CSTRIKE, 'models', 'vexmira', 'lasermine')

HUMAN_MATS = dict(W.WMATS)
HUMAN_MATS.update({
    'mine_body': metal((206, 212, 222), seed=901, panels=1.8, chipping=0.15, edge_wear=0.5, scratches=0.2, shine=0.6),
    'mine_plate': metal((40, 52, 78), seed=902, panels=2.5, edge_wear=0.7, scratches=0.3),
    'mine_dark': metal((24, 30, 44), seed=903, scratches=0.2, shine=0.4),
    'mine_hazard': metal((0, 160, 220), seed=904, panels=0, chipping=0.2, edge_wear=0.6),
    'mine_cyan': glow((0, 220, 255), (220, 255, 255), freq=0.9),
    'mine_core': glow((160, 240, 255), (255, 255, 255)),
    'mine_led': glow((0, 255, 160), (200, 255, 230)),
    'mine_lens': {'type': 'visor', 'color': (0, 170, 255), 'color2': (220, 255, 255)},
})

ZOMBIE_MATS = dict(W.WMATS)
ZOMBIE_MATS.update({
    'mine_body': {'type': 'skin', 'color': (112, 70, 64), 'seed': 911},
    'mine_plate': {'type': 'skin', 'color': (70, 42, 40), 'seed': 912},
    'mine_dark': {'type': 'skin', 'color': (48, 30, 28), 'seed': 913},
    'mine_steel': {'type': 'bone', 'color': (214, 200, 160), 'seed': 914},
    'mine_rubber': {'type': 'skin', 'color': (60, 20, 22), 'seed': 915},
    'mine_hazard': {'type': 'skin', 'color': (90, 110, 40), 'seed': 916},
    'mine_cyan': glow((120, 255, 40), (230, 255, 160), freq=1.1),
    'mine_core': glow((190, 255, 80), (255, 255, 200)),
    'mine_led': glow((255, 30, 20), (255, 180, 140)),
    'mine_lens': glow((90, 255, 30), (220, 255, 150)),
})


def _spikes():
    """bone spikes + tendrils on the zombie pod (bone 'head' / 'root')."""
    out = []
    for k in range(6):
        a = k * math.pi / 3 + math.pi / 6
        c, s = math.cos(a), math.sin(a)
        out.append(rod((3.0 + (k % 2), 2.8 * c, 2.8 * s), (2.2 + (k % 2), 4.3 * c, 4.3 * s), 0.38, mat='mine_steel',
                       name='spike', segs=5, r1=0.05))
    head = on('head', *out)
    tend = []
    for k in range(4):
        a = k * math.pi / 2 + 0.4
        c, s = math.cos(a), math.sin(a)
        tend.append(tube([(0.6, 3.4 * c, 3.4 * s), (1.0, 5.4 * c, 5.0 * s), (0.7, 6.6 * c, 6.4 * s),
                          (0.3, 7.4 * c, 7.0 * s)], [0.55, 0.42, 0.3, 0.12], segs=5, mat='mine_rubber'))
    return head + tend


def _variant(name, mats, extra=()):
    spec = W.lasermine()
    spec = dict(spec)
    spec['name'] = name
    spec['materials'] = mats
    spec['parts'] = list(spec['parts']) + list(extra)
    spec['out'] = os.path.join(OUT, name + '.mdl')
    spec['preview_area'] = 'lasermine'
    if name == 'lm_zombie':
        spec['decals'] = []
    return spec


def human():
    return _variant('lm_human', HUMAN_MATS)


def zombie():
    return _variant('lm_zombie', ZOMBIE_MATS, _spikes())


def all():     # noqa: A001 - mdlkit build entry point name
    return [human(), zombie()]


def main():
    from . import build
    os.makedirs(OUT, exist_ok=True)
    for spec in all():
        build(spec)


if __name__ == '__main__':
    main()
