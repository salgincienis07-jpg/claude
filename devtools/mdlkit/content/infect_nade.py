"""Vexmira infection bomb: a toxic-green glass canister with steel cage, hazard band, fuze, spoon and pin.

    cd devtools && python3 -m mdlkit.content.infect_nade [--no-preview]

Writes cstrike/models/vexmira/nades/{v_infect,p_infect,w_infect}.mdl
  v_infect: zombie claw arms (walker spec) holding the bomb, hegrenade sequence order (idle, pullpin, throw, deploy)
  p_infect: the bomb in "Bip01 R Hand" (bone-merged onto any player model)
  w_infect: thrown / dropped world model (origin at the canister centre)
"""
from __future__ import annotations

import argparse
import os

import numpy as np

from .. import CSTRIKE
from ..geom import cylinder, ellipsoid, tube
from ..guns import bx
from ..pmodel import _m

OUT = os.path.join(CSTRIKE, 'models', 'vexmira', 'nades')

MATS = {
    'nade_glass': {'type': 'glow', 'color': (70, 255, 40), 'color2': (200, 255, 120), 'freq': 0.9, 'seed': 501,
                   'pulse_axis': (0, 0, 2.2)},
    'nade_cap': {'type': 'metal', 'color': (46, 48, 52), 'scratches': 0.5, 'shine': 0.45, 'edge_wear': 0.8, 'seed': 502},
    'nade_rail': {'type': 'metal', 'color': (120, 124, 130), 'scratches': 0.35, 'shine': 0.6, 'edge_wear': 0.6, 'seed': 503},
    'nade_band': {'type': 'metal', 'color': (230, 190, 30), 'scratches': 0.5, 'shine': 0.3, 'edge_wear': 0.9, 'seed': 504},
    'nade_dark': {'type': 'rubber', 'color': (24, 26, 22), 'seed': 505},
    'gun_metal': {'type': 'metal', 'color': (150, 152, 156), 'scratches': 0.3, 'shine': 0.6, 'seed': 506},
}


def bomb_meshes():
    """GUN SPACE (grip frame, +X forward, +Z up, centred on the fist like guns._grenade)."""
    P = []
    h0, h1 = -1.7, 1.5                                     # glass canister height
    P.append(_m(cylinder((0.4, 0, h0), (0.4, 0, h1), 0.82, segs=12), 'glass', 'nade_glass'))
    P.append(_m(cylinder((0.4, 0, h0 - 0.45), (0.4, 0, h0 + 0.05), 1.02, segs=12), 'capb', 'nade_cap'))
    P.append(_m(cylinder((0.4, 0, h1 - 0.05), (0.4, 0, h1 + 0.45), 1.02, segs=12), 'capt', 'nade_cap'))
    P.append(_m(ellipsoid((0.75, 0.75, 0.35), (0.4, 0, h1 + 0.5), segs=10, rings=5), 'dome', 'nade_cap'))
    for k in range(4):                                     # steel cage rails
        a = k * np.pi / 2 + np.pi / 4
        x, y = 0.4 + np.cos(a) * 0.98, np.sin(a) * 0.98
        P.append(_m(cylinder((x, y, h0), (x, y, h1), 0.11, segs=5), 'rail', 'nade_rail'))
    P.append(_m(cylinder((0.4, 0, -0.25), (0.4, 0, 0.25), 0.9, segs=12), 'band', 'nade_band'))      # hazard band
    for k in range(6):                                     # black hazard stripes on the band
        a = k * np.pi / 3
        x, y = 0.4 + np.cos(a) * 0.9, np.sin(a) * 0.9
        P.append(bx((0.12, 0.30, 0.52), (x, y, 0.0), 'nade_dark', 'stripe', 0.0))
    top = h1 + 0.75
    P.append(_m(cylinder((0.4, 0, top - 0.2), (0.4, 0, top + 0.45), 0.36, segs=8), 'fuze', 'gun_metal'))
    P.append(bx((0.35, 0.5, 2.8), (-0.8, 0, top - 1.1), 'gun_metal', 'spoon', 0.06))
    P.append(_m(tube([(0.8, 0.4, top + 0.25), (1.3, 0.9, top + 0.45), (1.7, 0.6, top + 0.85), (1.4, 0.1, top + 1.05),
                      (0.9, 0.3, top + 0.55)], 0.09, segs=4), 'pin', 'gun_metal'))
    P.append(_m(cylinder((0.4, 0, top + 0.45), (0.4, 0, top + 1.4), 0.05, segs=4), 'needle', 'nade_rail'))
    P.append(_m(ellipsoid((0.16, 0.16, 0.16), (0.4, 0, top + 1.45), segs=6, rings=4), 'tip', 'nade_glass'))
    for m in P:
        m.transform(None, (0.3, 0, -0.2))
    return P


def build(preview=True):
    from ..vmodel import build_vmodel
    from ..pmodel import build_pmodel
    from ..samples import walker_spec
    from ..world import build_world_model
    os.makedirs(OUT, exist_ok=True)
    reps = {}
    reps['v'] = build_vmodel('v_infect', walker_spec(), kind='hegrenade', gun_meshes=bomb_meshes(),
                             out=os.path.join(OUT, 'v_infect.mdl'), materials=MATS, preview=preview,
                             sounds={'pullpin': [(0.5, 'weapons/pinpull.wav')]}, tex=(256, 256), budget=0.45e6)
    reps['p'] = build_pmodel('p_infect', bomb_meshes(), os.path.join(OUT, 'p_infect.mdl'), materials=MATS,
                             preview=preview)
    wm = bomb_meshes()
    for m in wm:
        m.transform(None, (-0.7, 0, 0.0))
    reps['w'] = build_world_model('w_infect', wm, out=os.path.join(OUT, 'w_infect.mdl'), materials=MATS,
                                  tex=(128, 128), preview=preview, sequences=[dict(name='idle', frames=1)]
                                  if False else None)
    return reps


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--no-preview', action='store_true')
    a = ap.parse_args(argv)
    reps = build(not a.no_preview)
    for k, r in reps.items():
        print(k, {x: r.get(x) for x in ('size', 'errors', 'warnings') if x in r})


if __name__ == '__main__':
    main()
