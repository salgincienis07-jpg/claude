"""Vexmira human v_ models (DESIGN_v3 section 4): CT arms (operator spec + tactical gloves with quilted /
stitched knuckle pads and palm grip) + the Vexmira knife, the three special grenades and the special guns.

    cd devtools
    python3 -m mdlkit build mdlkit.content.weapons:v_vexblade
    python3 -m mdlkit build mdlkit.content.weapons:grenades
    python3 -m mdlkit build mdlkit.content.weapons:specials --only v_sw0

Sequence order = ReGameDLL enums (vmodel.WEAPON_SETS): knife / hegrenade / smokegrenade / flashbang and
m4a1 m249 awp xm1014 deagle p90 ak47 sg550 for v_sw0..v_sw7. GUN SPACE: origin = grip centre in the fist,
+X forward (blade / barrel), +Z top, +Y gun-left.
"""
import math
import numpy as np

from . import *          # noqa: F401,F403
from ..geom import ellipsoid as _ell
from ..pmodel import _m
from ..samples import operator_spec, operator_materials


# --------------------------------------------------------------------------------------------- arms
def _arms_materials(rig, sh):
    M = dict(operator_materials(rig, sh))
    glove = {'type': 'leather', 'color': (44, 45, 50), 'seed': 104}
    quilt = {'type': 'cloth', 'color': (30, 31, 35), 'weave': 0.25, 'weave_freq': 6.0, 'plaid': True,
             'plaid_size': 1.1, 'plaid_line': (150, 152, 160), 'dirt': 0.2, 'seed': 931}
    pad = {'type': 'rubber', 'color': (20, 21, 23), 'seed': 932}
    M['hand'] = {'type': 'layers', 'base': glove, 'layers': [
        {'mat': pad, 'where': {'meshes': ['fingers', 'thumb'], 'facing': (0, 0, -1), 'facing_min': 0.1}},
        {'mat': quilt, 'where': {'meshes': ['hand'], 'facing': (0, 0, 1), 'facing_min': 0.2}},
        {'mat': {'type': 'rubber', 'color': (34, 35, 38), 'seed': 933}, 'where': {'meshes': ['fingers'], 'facing': (0, 0, 1), 'facing_min': 0.5}},
        {'mat': glow(VEX_CYAN), 'where': {'meshes': ['hand'], 't': (0.0, 0.07)}},
    ]}
    return M


def vex_arms():
    spec = operator_spec()
    spec['materials'] = _arms_materials
    return spec


GUNMATS = {
    'gun_blade': metal((168, 174, 182), seed=901, scratches=0.55, shine=0.8, edge_wear=0.3),
    'gun_metal': metal((54, 58, 66), seed=902, scratches=0.4, shine=0.4, edge_wear=0.8, panels=1.4),
    'gun_dark': metal((26, 27, 31), seed=903, scratches=0.3, shine=0.25),
    'gun_poly': {'type': 'rubber', 'color': (30, 31, 34), 'seed': 904},
    'gun_wrap': cloth((40, 44, 52), seed=905, weave=0.5, weave_freq=5.0, dirt=0.3),
    'gun_glow': glow(VEX_CYAN, (215, 255, 255), freq=0.9),
    'gun_accent': glow(VEX_PURPLE, (230, 200, 255)),
}


def _v(name, vkind, gun, mats=None, **kw):
    M = dict(GUNMATS)
    M.update(mats or {})
    return dict(kind='vhuman', name=name, vkind=vkind, gun=gun, materials=M, arms=vex_arms(), **kw)


# --------------------------------------------------------------------------------------------- knife
def _vexblade():
    # clip-point blade with spine serrations (side view polygon, x forward, z up)
    top = [(2.0, 1.15), (3.0, 1.15)]
    for k in range(6):                      # serrated spine
        x = 3.0 + k * 0.55
        top += [(x + 0.27, 1.38), (x + 0.55, 1.15)]
    top += [(7.4, 1.15), (9.2, 1.0), (11.4, 0.55)]
    bottom = [(10.2, 0.05), (8.0, -0.25), (5.0, -0.32), (2.6, -0.25), (2.0, 0.0)]
    blade = side(top + bottom, 0.18, mat='gun_blade', name='blade')
    P = [blade,
         side([(2.6, -0.2), (5.0, -0.27), (8.0, -0.2), (10.1, 0.1), (10.0, 0.22), (8.0, -0.06), (5.0, -0.13), (2.6, -0.06)],
              0.21, mat='gun_glow', name='edge'),
         bx((5.0, 0.22, 0.24), (5.6, 0, 0.62), 'gun_dark', 'fuller', 0.0),
         bx((0.5, 0.9, 2.5), (1.85, 0, 0.45), 'gun_metal', 'guard', 0.12),
         bx((0.52, 0.94, 0.25), (1.85, 0, -0.6), 'gun_glow', 'guardglow', 0.0),
         _m(cylinder((-2.6, 0, 0.45), (1.6, 0, 0.45), 0.58, 0.52, segs=10), 'handle', 'gun_poly'),
         _m(cylinder((-3.2, 0, 0.45), (-2.6, 0, 0.45), 0.66, 0.62, segs=10), 'pommel', 'gun_metal'),
         _m(cylinder((-3.35, 0, 0.45), (-3.2, 0, 0.45), 0.4, 0.4, segs=10), 'pommelcap', 'gun_glow'),
         _m(tube([(-3.3, 0, -0.1), (-3.75, 0, -0.35), (-3.9, 0, 0.2), (-3.5, 0, 0.35)], 0.09, segs=4), 'lanyard', 'gun_metal')]
    for k in range(5):                      # paracord wrap rings
        x = -2.3 + k * 0.8
        P.append(_m(cylinder((x, 0, 0.45), (x + 0.4, 0, 0.45), 0.62, segs=10), 'wrap', 'gun_wrap'))
    for sg in (1, -1):                      # rivets on the blade ricasso and guard screws
        P.append(_m(cylinder((2.5, sg * 0.08, 0.5), (2.5, sg * 0.14, 0.5), 0.17, segs=6), 'rivet', 'gun_metal'))
        P.append(_m(cylinder((1.85, sg * 0.45, 1.3), (1.85, sg * 0.52, 1.3), 0.14, segs=6), 'screw', 'gun_blade'))
    for m in P:
        m.transform(None, (0.4, 0, -0.45))
    return P


def v_vexblade():
    """Vexmira combat knife (V_KNIFE): serrated clip-point blade with a cyan energy edge, paracord grip,
    glowing pommel. Knife sequence order: idle slash1 slash2 draw stab stab_miss midslash1 midslash2."""
    return _v('v_vexblade', 'knife', _vexblade())


# --------------------------------------------------------------------------------------------- grenades
def _pin(top):
    return [_m(tube([(0.8, 0.4, top + 0.3), (1.3, 0.9, top + 0.5), (1.7, 0.6, top + 0.9), (1.4, 0.1, top + 1.1),
                     (0.9, 0.3, top + 0.6)], 0.09, segs=4), 'pin', 'gun_blade'),
            _m(cylinder((0.4, 0, top - 0.1), (0.4, 0, top + 0.5), 0.45, segs=8), 'fuze', 'gun_metal'),
            bx((0.35, 0.5, 2.8), (-0.8, 0, top - 1.1), 'gun_blade', 'spoon', 0.06)]


def _firebomb():
    P = [_m(_ell((1.25, 1.25, 1.55), (0.4, 0, 0.1), segs=12, rings=8), 'body', 'gun_body'),
         _m(cylinder((0.4, 0, -1.6), (0.4, 0, -1.25), 0.75, 0.85, segs=10), 'base', 'gun_dark')]
    for z in (-0.6, 0.55):
        P.append(_m(cylinder((0.4, 0, z), (0.4, 0, z + 0.25), 1.24, segs=12), 'rib', 'gun_dark'))
    for a in range(6):
        ang = a * math.pi / 3
        P.append(bx((0.18, 0.18, 0.55), (0.4 + 1.22 * math.cos(ang), 1.22 * math.sin(ang), 0.05), 'gun_glow', 'vent', 0.0))
    P += _pin(1.55)
    for m in P:
        m.transform(None, (0.3, 0, -0.2))
    return P


def _frostbomb():
    P = [_m(cylinder((0.4, 0, -1.5), (0.4, 0, 1.8), 0.95, segs=12), 'body', 'gun_body'),
         _m(cylinder((0.4, 0, -1.65), (0.4, 0, -1.3), 1.0, segs=12), 'base', 'gun_dark'),
         _m(cylinder((0.4, 0, 1.7), (0.4, 0, 2.0), 1.0, segs=12), 'top', 'gun_dark')]
    for a in range(4):
        ang = a * math.pi / 2 + math.pi / 4
        P.append(bx((0.16, 0.45, 1.6), (0.4 + 0.93 * math.cos(ang), 0.93 * math.sin(ang), 0.1), 'gun_glow', 'window', 0.0))
    for a, h in ((0.5, 0.9), (2.5, 0.7), (4.4, 1.0)):
        P.append(_m(horn((0.4 + 0.8 * math.cos(a), 0.8 * math.sin(a), 1.6), (math.cos(a) * 0.6, math.sin(a) * 0.6, 1.0), h, 0.25),
                    'ice', 'gun_ice'))
    P += _pin(2.0)
    for m in P:
        m.transform(None, (0.3, 0, -0.2))
    return P


def _flare():
    P = [_m(cylinder((0.4, 0, -2.2), (0.4, 0, 2.2), 0.62, segs=10), 'body', 'gun_body'),
         _m(cylinder((0.4, 0, 2.2), (0.4, 0, 2.9), 0.67, segs=10), 'cap', 'gun_dark'),
         _m(_ell((0.45, 0.45, 0.35), (0.4, 0, 2.95), segs=8, rings=4), 'tip', 'gun_glow'),
         _m(cylinder((0.4, 0, -2.4), (0.4, 0, -2.1), 0.68, segs=10), 'base', 'gun_dark'),
         bx((1.1, 0.08, 1.6), (0.4, 0.62, 0.9), 'gun_accent', 'label', 0.0)]
    for z in (-1.6, -1.0, -0.4):
        P.append(_m(cylinder((0.4, 0, z), (0.4, 0, z + 0.18), 0.66, segs=10), 'rib', 'gun_dark'))
    P += _pin(2.9)
    for m in P:
        m.transform(None, (0.3, 0, -0.2))
    return P


def v_firebomb():
    """Fire bomb (V_HEGRENADE, hegrenade enum order): red ribbed body with orange glow vents."""
    return _v('v_firebomb', 'hegrenade', _firebomb(),
              {'gun_body': metal((150, 36, 18), seed=911, paint=(165, 40, 20), chipping=0.35, edge_wear=0.8),
               'gun_glow': glow((255, 110, 0), (255, 230, 120))})


def v_frostbomb():
    """Frost bomb (V_SMOKEGRENADE, smokegrenade enum order): pale-blue canister, ice crystals, cyan windows."""
    return _v('v_frostbomb', 'smokegrenade', _frostbomb(),
              {'gun_body': metal((150, 190, 215), seed=912, paint=(170, 205, 230), chipping=0.3, edge_wear=0.8),
               'gun_glow': glow((90, 210, 255), (230, 250, 255)),
               'gun_ice': {'type': 'crystal', 'color': (150, 220, 255), 'seed': 913}})


def v_flare():
    """Signal flare (V_FLASHBANG, flashbang enum order): red stick flare with glowing striker tip."""
    return _v('v_flare', 'flashbang', _flare(),
              {'gun_body': {'type': 'rubber', 'color': (170, 30, 26), 'seed': 914},
               'gun_glow': glow((255, 60, 40), (255, 220, 180)),
               'gun_accent': glow(GOLD, (255, 250, 200))})


def grenades():
    return [v_firebomb(), v_frostbomb(), v_flare()]


def all():
    return [v_vexblade()] + grenades()
