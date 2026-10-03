"""Catalogue of every standard CS 1.6 weapon for p_ models (+ shapes reusable for v_ / w_ models).

    from mdlkit.guns import STANDARD, standard_gun, build_standard_pmodel
    build_standard_pmodel('m4a1')                       # -> cstrike/models/vexmira/weapons/p_m4a1.mdl
    build_standard_pmodel('awp', out=..., palette={'gun_body': {'type': 'metal', 'color': (60, 80, 60)}})
    meshes = standard_gun('famas')                      # GUN SPACE meshes (see pmodel.py)

GUN SPACE (same as pmodel.py): origin = centre of the pistol grip where the hand closes, +X barrel,
+Z top, +Y gun-left, bore axis at z = pmodel.BORE_Z (2.4). 1 unit ~ 1 inch (a 72-unit human).
The player hold for each weapon comes from its ReGameDLL animation extension (STANDARD[w]['ext'],
anims.HOLDS): the support hand of 'rifle'/'carbine'/'ak47'/'mp5'/'shotgun'/'m249' guns closes at
(HOLDS[ext]['fore'], 0, HOLDS[ext]['fore_down']) in gun space, so every long gun has a handguard /
foregrip there. 'onehanded' (pistols, MAC-10, TMP) and 'dualpistols' (Elite: two guns, the second on
"Bip01 L Hand") use the pistol grips; 'knife'/'grenade' are held in the fist.

Materials used by the shapes (override any of them with palette=): gun_metal, gun_poly, gun_wood,
gun_lens, gun_glow, gun_blade, gun_body (main colour of the weapon), gun_accent, gun_dark.
"""
import math
import os
import numpy as np

from .geom import Mesh, box, tube, cylinder, extrude, ellipsoid, lathe
from .mathx import rot_x, rot_y, rot_z
from .pmodel import (BORE_Z, receiver, barrel, handguard, pistol_grip, magazine, stock, scope, rail, muzzle_brake,
                     front_sight, trigger_guard, glow_strip, GUN_MATERIALS, _gun_preset, _m)

R_SIDE = rot_x(math.pi / 2)    # extrude(): polygon (x, z) in the side view, thickness along Y


def side(poly_xz, width, y=0.0, mat='gun_body', name='part'):
    """Side-view silhouette (list of (x, z) in gun space) extruded `width` along Y, centred at y."""
    m = extrude(poly_xz, width, R=R_SIDE, t=(0, y, 0), mat=mat)
    return _m(m, name, mat)


def rod(p0, p1, r, mat='gun_metal', name='rod', segs=6, r1=None):
    return _m(cylinder(p0, p1, r, r if r1 is None else r1, segs=segs), name, mat)


def bx(size, center, mat='gun_body', name='box', bevel=0.12):
    return _m(box(size, center=center, bevel=bevel), name, mat)


# ============================================================================================ shapes

def _pistol(L=5.2, H=1.35, W=1.0, grip_h=3.3, grip_ang=14, slide_mat='gun_metal', frame_mat='gun_poly',
            grip_mat='gun_poly', barrel_len=0.35, silencer=0.0, hammer=True, ported=False):
    """Generic semi-auto pistol: slide over the bore, frame, angled grip with the mag base, guard."""
    x0 = -1.6
    P = [bx((L, W, H), (x0 + L / 2, 0, BORE_Z - 0.2), slide_mat, 'slide', 0.15),
         bx((L * 0.72, W * 0.92, 0.7), (x0 + L * 0.36 + 0.2, 0, BORE_Z - 1.2), frame_mat, 'frame', 0.08),
         pistol_grip(grip_h, grip_ang, W * 1.08, 1.55, mat=grip_mat),
         bx((1.7, W * 1.12, 0.3), (-0.95 + math.sin(math.radians(grip_ang)) * 0.0, 0, -grip_h * 0.55 - 0.05), 'gun_dark', 'magbase', 0.05),
         rod((x0 + L - 0.1, 0, BORE_Z - 0.05), (x0 + L + barrel_len, 0, BORE_Z - 0.05), 0.24, name='barrel'),
         bx((0.25, 0.25, 0.3), (x0 + L - 0.35, 0, BORE_Z + H / 2 - 0.05), 'gun_metal', 'fsight', 0.0),
         bx((0.3, W * 0.8, 0.3), (x0 + 0.25, 0, BORE_Z + H / 2 - 0.05), 'gun_metal', 'rsight', 0.0)]
    tg = trigger_guard()
    tg.transform(None, (-0.9, 0, 0.35))
    P.append(tg)
    for sg in (1, -1):   # slide serrations
        for k in range(4):
            P.append(bx((0.12, 0.05, H * 0.7), (x0 + 0.5 + k * 0.3, sg * (W / 2 + 0.01), BORE_Z - 0.2), 'gun_dark', 'serr', 0.0))
    if hammer:
        P.append(bx((0.35, 0.35, 0.45), (x0 - 0.12, 0, BORE_Z + 0.25), 'gun_metal', 'hammer', 0.05))
    if silencer:
        xs = x0 + L + barrel_len - 0.1
        P.append(rod((xs, 0, BORE_Z - 0.05), (xs + silencer, 0, BORE_Z - 0.05), 0.42, mat='gun_dark', name='silencer', segs=10))
    if ported:
        for sg in (1, -1):
            P.append(bx((L * 0.45, 0.05, 0.3), (x0 + L * 0.68, sg * (W / 2 + 0.01), BORE_Z + 0.05), 'gun_dark', 'port', 0.0))
    return P


def _deagle():
    P = _pistol(L=6.4, H=1.55, W=1.2, grip_h=3.6, grip_ang=12, slide_mat='gun_body', frame_mat='gun_body', grip_mat='gun_poly',
                barrel_len=0.1)
    # flat-topped barrel shroud with the triangular bore face + rail on top
    P.append(bx((3.4, 0.9, 0.22), (2.6, 0, BORE_Z + 0.68), 'gun_body', 'shroud', 0.05))
    P.append(bx((0.15, 1.0, 1.1), (4.82, 0, BORE_Z - 0.1), 'gun_dark', 'muzzleface', 0.0))
    return P


def _elite():
    P = _pistol(L=5.6, H=1.2, W=0.95, grip_h=3.3, grip_ang=13, slide_mat='gun_body', frame_mat='gun_body', grip_mat='gun_wood',
                barrel_len=0.5, ported=True)
    return P


def _glock():
    return _pistol(L=4.9, H=1.3, W=1.0, grip_h=3.2, grip_ang=18, slide_mat='gun_dark', frame_mat='gun_poly', grip_mat='gun_poly',
                   barrel_len=0.15, hammer=False)


def _usp():
    P = _pistol(L=5.6, H=1.35, W=1.05, grip_h=3.4, grip_ang=15, slide_mat='gun_dark', frame_mat='gun_poly', grip_mat='gun_poly',
                barrel_len=0.3)
    P.append(bx((1.6, 0.9, 0.3), (2.4, 0, BORE_Z - 1.65), 'gun_poly', 'rail', 0.05))
    return P


def _p228():
    return _pistol(L=5.0, H=1.35, W=1.0, grip_h=3.3, grip_ang=14, slide_mat='gun_body', frame_mat='gun_dark', grip_mat='gun_poly',
                   barrel_len=0.25)


def _fiveseven():
    P = _pistol(L=5.6, H=1.25, W=0.95, grip_h=3.5, grip_ang=17, slide_mat='gun_dark', frame_mat='gun_body', grip_mat='gun_body',
                barrel_len=0.2, hammer=False)
    return P


def _m4a1():
    P = _gun_preset('m4')
    # carry-handle style rear sight + A2 front sight post, flash hider
    P.append(bx((1.2, 0.45, 0.9), (-1.0, 0, BORE_Z + 1.8), 'gun_metal', 'rsight', 0.08))
    P.append(rod((17.0, 0, BORE_Z), (18.6, 0, BORE_Z), 0.42, mat='gun_dark', name='hider', segs=8))
    for k in range(4):   # handguard vents
        for sg in (1, -1):
            P.append(bx((0.5, 0.06, 0.35), (6.3 + k * 1.3, sg * 0.97, BORE_Z - 0.25), 'gun_dark', 'vent', 0.0))
    return P


def _aug():
    """Steyr AUG bullpup: long curved housing, integrated scope tube with handle, vertical foregrip."""
    body = side([(-10.5, BORE_Z - 2.6), (-10.8, BORE_Z - 0.6), (-9.6, BORE_Z + 0.9), (3.5, BORE_Z + 0.9), (5.2, BORE_Z + 0.2),
                 (5.4, BORE_Z - 1.0), (2.2, BORE_Z - 1.7), (-2.0, BORE_Z - 1.7), (-3.4, BORE_Z - 3.0), (-9.6, BORE_Z - 3.1)],
                1.9, mat='gun_body', name='housing')
    P = [body,
         rod((5.0, 0, BORE_Z), (16.0, 0, BORE_Z), 0.33, name='barrel'),
         rod((14.6, 0, BORE_Z), (16.6, 0, BORE_Z), 0.45, mat='gun_dark', name='hider'),
         pistol_grip(3.2, 16, 1.15, 1.45, mat='gun_body'),
         side([(5.2, BORE_Z - 0.9), (6.1, BORE_Z - 0.9), (6.5, BORE_Z - 4.2), (5.6, BORE_Z - 4.2)], 1.0, mat='gun_body', name='foregrip'),
         side([(-0.5, BORE_Z - 1.6), (5.4, BORE_Z - 1.6), (5.4, BORE_Z - 1.2), (-0.5, BORE_Z - 1.2)], 1.3, mat='gun_body', name='guard'),
         magazine(-3.6, 4.0, 1.0, 1.6, curve=0.6, angle=10, mat='gun_lens', z_top=BORE_Z - 2.6)]
    P += scope(-3.5, 6.5, r=0.62, z=BORE_Z + 2.3, mat='gun_body')
    P.append(side([(-3.4, BORE_Z + 0.8), (2.9, BORE_Z + 0.8), (2.5, BORE_Z + 1.7), (-3.0, BORE_Z + 1.7)], 0.8, mat='gun_body', name='handle'))
    return P


def _famas():
    """FAMAS bullpup: carry handle along the whole top, bipod folded under the barrel."""
    body = side([(-10.0, BORE_Z - 2.4), (-10.2, BORE_Z - 0.4), (-9.0, BORE_Z + 0.8), (4.5, BORE_Z + 0.8), (6.0, BORE_Z - 0.2),
                 (6.0, BORE_Z - 1.4), (-2.0, BORE_Z - 1.4), (-3.2, BORE_Z - 2.9), (-9.2, BORE_Z - 3.0)],
                1.8, mat='gun_body', name='housing')
    handle = side([(-7.5, BORE_Z + 0.7), (5.0, BORE_Z + 0.7), (5.0, BORE_Z + 2.5), (4.2, BORE_Z + 2.5), (3.6, BORE_Z + 1.4),
                   (-6.4, BORE_Z + 1.4), (-6.9, BORE_Z + 2.4), (-7.5, BORE_Z + 2.4)], 0.6, mat='gun_dark', name='handle')
    P = [body, handle,
         rod((5.8, 0, BORE_Z), (15.0, 0, BORE_Z), 0.32, name='barrel'),
         rod((14.4, 0, BORE_Z), (15.6, 0, BORE_Z), 0.44, mat='gun_dark', name='brake'),
         pistol_grip(3.2, 14, 1.15, 1.45, mat='gun_dark'),
         side([(-0.6, BORE_Z - 1.4), (3.0, BORE_Z - 1.4), (3.0, BORE_Z - 2.4), (-0.6, BORE_Z - 2.4)], 1.2, mat='gun_dark', name='guard'),
         magazine(-4.4, 3.4, 0.9, 1.5, curve=0.0, angle=4, mat='gun_metal', z_top=BORE_Z - 2.6)]
    for sg in (1, -1):
        P.append(rod((6.6, sg * 0.35, BORE_Z - 0.6), (13.6, sg * 0.35, BORE_Z - 0.4), 0.16, mat='gun_metal', name='bipod', segs=5))
    return P


def _galil():
    P = [receiver(9.3, 2.5, 1.45, -2.6, mat='gun_body'),
         handguard(6.6, 5.6, 0.95, mat='gun_wood', segs=8),
         barrel(6.4, 11.8, 0.32), muzzle_brake(18.0, 0.45, 1.3),
         front_sight(16.6, h=1.6), pistol_grip(3.4, 18, 1.15, 1.5, mat='gun_poly'),
         magazine(2.8, 5.0, 1.05, 1.7, curve=1.2, angle=10, mat='gun_metal'), trigger_guard(),
         _m(tube([(7.0, 0, BORE_Z + 0.55), (12.5, 0, BORE_Z + 0.55)], 0.3, segs=6), 'gastube', 'gun_metal'),
         rod((4.0, 0.9, BORE_Z + 0.1), (6.5, 0.9, BORE_Z + 1.2), 0.15, name='handle')]
    # folding skeleton stock (two tubes + butt plate)
    for z in (BORE_Z - 0.3, BORE_Z - 1.9):
        P.append(rod((-2.6, 0, z), (-10.2, 0, z - 0.4), 0.18, name='stocktube'))
    P.append(bx((0.5, 1.1, 2.4), (-10.3, 0, BORE_Z - 1.3), 'gun_poly', 'butt', 0.1))
    return P


def _sg552():
    P = [receiver(8.5, 2.6, 1.5, -2.5, mat='gun_body'),
         handguard(6.0, 4.6, 1.0, mat='gun_body', segs=8),
         barrel(6.0, 8.0, 0.32), muzzle_brake(13.8, 0.45, 1.2),
         pistol_grip(3.4, 18, 1.15, 1.5, mat='gun_body'), trigger_guard(),
         magazine(2.6, 4.6, 1.0, 1.7, curve=0.9, angle=9, mat='gun_lens')]
    P += scope(-1.6, 5.2, r=0.62, z=BORE_Z + 1.8, mat='gun_dark')
    # folding skeleton stock
    P.append(side([(-2.5, BORE_Z + 0.3), (-9.5, BORE_Z - 0.2), (-9.5, BORE_Z - 2.8), (-8.7, BORE_Z - 2.8), (-8.7, BORE_Z - 0.9),
                   (-2.5, BORE_Z - 0.9)], 0.9, mat='gun_body', name='stock'))
    return P


def _sg550():
    P = [receiver(9.5, 2.6, 1.5, -2.6, mat='gun_body'),
         handguard(6.6, 6.2, 1.0, mat='gun_body', segs=8),
         barrel(6.6, 13.0, 0.36), muzzle_brake(19.4, 0.5, 1.3),
         pistol_grip(3.4, 16, 1.2, 1.6, mat='gun_body'), trigger_guard(),
         magazine(2.5, 3.8, 1.0, 1.7, curve=0.5, angle=6, mat='gun_lens'),
         stock(-2.6, 9.0, 3.0, 1.3, 0.8, mat='gun_body'),
         bx((1.6, 0.5, 0.9), (-6.8, 0, BORE_Z + 0.2), 'gun_dark', 'cheek', 0.15)]
    P += scope(-2.0, 8.0, r=0.8, z=BORE_Z + 2.0, mat='gun_dark')
    return P


def _g3sg1():
    P = [receiver(10.0, 2.6, 1.5, -2.8, mat='gun_body'),
         handguard(7.0, 6.0, 1.05, mat='gun_body', segs=8, flat=0.8),
         barrel(7.0, 13.4, 0.36), muzzle_brake(20.2, 0.5, 1.6),
         pistol_grip(3.5, 18, 1.2, 1.6, mat='gun_poly'), trigger_guard(),
         magazine(2.6, 3.4, 1.0, 1.7, curve=0.0, angle=4, mat='gun_metal'),
         stock(-2.8, 9.0, 3.2, 1.3, 0.7, mat='gun_body'),
         bx((2.0, 0.55, 1.1), (-7.0, 0, BORE_Z + 0.25), 'gun_poly', 'cheek', 0.2)]
    P += scope(-2.4, 8.4, r=0.85, z=BORE_Z + 2.1, mat='gun_dark')
    return P


def _awp():
    P = _gun_preset('sniper')
    for m in P:
        if m.name in ('receiver', 'handguard', 'stock'):
            m.mat = 'gun_body'
    P.append(muzzle_brake(21.2, 0.52, 1.6, mat='gun_dark'))
    P.append(bx((1.0, 0.5, 1.6), (-9.6, 0, BORE_Z - 1.8), 'gun_dark', 'buttpad', 0.15))
    P.append(rod((1.4, -0.9, BORE_Z + 0.3), (1.4, -1.9, BORE_Z + 0.1), 0.14, name='bolt'))
    P.append(_m(ellipsoid((0.3, 0.3, 0.3), (1.4, -1.95, BORE_Z + 0.1), segs=6, rings=4), 'boltknob', 'gun_metal'))
    return P


def _scout():
    P = [receiver(7.5, 1.9, 1.2, -2.4, mat='gun_dark'), barrel(5.0, 15.0, 0.3, r_end=0.26),
         pistol_grip(3.3, 20, 1.1, 1.4, mat='gun_body'), magazine(1.8, 2.2, 0.9, 1.5, mat='gun_dark'),
         side([(-2.4, BORE_Z - 0.4), (-9.6, BORE_Z - 0.9), (-9.6, BORE_Z - 3.2), (-8.6, BORE_Z - 3.2), (-6.0, BORE_Z - 1.9),
               (-2.4, BORE_Z - 1.6)], 1.1, mat='gun_body', name='stock'),
         side([(4.6, BORE_Z - 0.4), (11.5, BORE_Z - 0.3), (11.5, BORE_Z - 1.2), (4.6, BORE_Z - 1.5)], 1.1, mat='gun_body', name='fore'),
         rod((1.2, -0.8, BORE_Z + 0.2), (1.2, -1.7, BORE_Z), 0.12, name='bolt')]
    P += scope(-1.4, 6.8, r=0.62, z=BORE_Z + 1.5, mat='gun_dark')
    return P


def _mp5():
    P = [receiver(8.0, 2.2, 1.35, -2.4, mat='gun_dark'),
         _m(cylinder((5.4, 0, BORE_Z - 0.3), (9.8, 0, BORE_Z - 0.3), 0.95, 0.9, segs=10), 'handguard', 'gun_poly'),
         barrel(9.6, 1.6, 0.3), _m(cylinder((10.6, 0, BORE_Z), (11.4, 0, BORE_Z), 0.35, segs=6), 'lugs', 'gun_metal'),
         pistol_grip(3.2, 16, 1.1, 1.4, mat='gun_poly'), trigger_guard(),
         magazine(2.6, 5.0, 0.85, 1.4, curve=2.0, angle=18, mat='gun_metal'),
         _m(cylinder((10.0, 0, BORE_Z + 0.6), (10.0, 0, BORE_Z + 1.5), 0.42, segs=8), 'fsight', 'gun_metal'),
         bx((0.9, 1.0, 0.7), (-1.6, 0, BORE_Z + 1.2), 'gun_metal', 'drum', 0.1),
         rod((2.0, 0.8, BORE_Z + 0.4), (7.0, 0.8, BORE_Z + 0.4), 0.12, name='cocktube')]
    for sg in (1, -1):   # retractable stock rails
        P.append(rod((-2.4, sg * 0.6, BORE_Z - 0.2), (-8.0, sg * 0.6, BORE_Z - 0.4), 0.15, name='stockrail'))
    P.append(bx((0.5, 1.6, 2.6), (-8.2, 0, BORE_Z - 1.0), 'gun_poly', 'butt', 0.12))
    return P


def _ump45():
    P = [side([(-2.6, BORE_Z + 0.9), (8.8, BORE_Z + 0.9), (9.4, BORE_Z + 0.2), (9.4, BORE_Z - 1.4), (3.8, BORE_Z - 1.6),
               (1.8, BORE_Z - 1.2), (-2.6, BORE_Z - 1.0)], 1.6, mat='gun_body', name='body'),
         barrel(9.2, 1.3, 0.3), pistol_grip(3.3, 16, 1.15, 1.5, mat='gun_body'), trigger_guard(),
         magazine(2.8, 5.2, 1.0, 1.55, curve=0.0, angle=4, mat='gun_body'),
         rail(-1.5, 8.0, BORE_Z + 1.05)]
    P.append(side([(-2.6, BORE_Z + 0.2), (-9.4, BORE_Z - 0.2), (-9.4, BORE_Z - 2.6), (-8.5, BORE_Z - 2.6), (-8.5, BORE_Z - 0.9),
                   (-2.6, BORE_Z - 0.8)], 0.9, mat='gun_poly', name='stock'))
    for k in range(3):
        for sg in (1, -1):
            P.append(bx((0.6, 0.05, 0.3), (5.8 + k * 1.1, sg * 0.81, BORE_Z - 0.5), 'gun_dark', 'vent', 0.0))
    return P


def _mac10():
    """MAC-10: boxy receiver, mag in the grip, short threaded barrel, folded wire stock."""
    P = [bx((7.0, 1.4, 2.0), (1.6, 0, BORE_Z - 0.5), 'gun_body', 'body', 0.12),
         side([(-0.8, BORE_Z - 1.5), (0.5, BORE_Z - 1.5), (0.2, BORE_Z - 6.0), (-1.1, BORE_Z - 6.0)], 1.15, mat='gun_poly', name='grip'),
         bx((1.4, 1.0, 0.35), (-0.45, 0, BORE_Z - 6.2), 'gun_dark', 'magbase', 0.05),
         barrel(5.1, 1.6, 0.32), trigger_guard(),
         bx((0.6, 0.35, 0.6), (4.6, 0, BORE_Z + 0.75), 'gun_metal', 'fsight', 0.05)]
    for sg in (1, -1):
        P.append(rod((-1.9, sg * 0.55, BORE_Z - 0.2), (4.5, sg * 0.55, BORE_Z - 1.9), 0.12, name='wirestock'))
    P.append(rod((4.5, 0.55, BORE_Z - 1.9), (4.5, -0.55, BORE_Z - 1.9), 0.12, name='wirestock'))
    return P


def _tmp():
    """TMP: compact SMG with a vertical foregrip, mag in the grip and a suppressor."""
    P = [side([(-2.0, BORE_Z + 0.8), (5.6, BORE_Z + 0.8), (6.0, BORE_Z + 0.2), (6.0, BORE_Z - 1.2), (-2.0, BORE_Z - 1.2)],
              1.4, mat='gun_body', name='body'),
         side([(-0.7, BORE_Z - 1.2), (0.5, BORE_Z - 1.2), (0.3, BORE_Z - 6.2), (-0.9, BORE_Z - 6.2)], 1.1, mat='gun_body', name='grip'),
         side([(3.8, BORE_Z - 1.2), (4.8, BORE_Z - 1.2), (5.0, BORE_Z - 3.8), (4.1, BORE_Z - 3.8)], 0.9, mat='gun_body', name='foregrip'),
         rod((5.9, 0, BORE_Z), (11.2, 0, BORE_Z), 0.5, mat='gun_dark', name='silencer', segs=10), trigger_guard(),
         rail(-1.2, 5.5, BORE_Z + 0.95)]
    return P


def _p90():
    """P90: sculpted bullpup body with the thumbhole grip and a translucent top magazine."""
    body = side([(-6.5, BORE_Z - 3.6), (-6.8, BORE_Z - 0.6), (-5.6, BORE_Z + 0.6), (5.8, BORE_Z + 0.6), (7.0, BORE_Z - 0.4),
                 (7.2, BORE_Z - 2.2), (4.8, BORE_Z - 2.4), (3.8, BORE_Z - 4.2), (2.6, BORE_Z - 4.2), (2.4, BORE_Z - 2.6),
                 (0.9, BORE_Z - 2.6), (0.4, BORE_Z - 4.6), (-0.8, BORE_Z - 4.6), (-1.4, BORE_Z - 2.6), (-3.5, BORE_Z - 2.6),
                 (-4.8, BORE_Z - 3.8)], 2.1, mat='gun_body', name='body')
    P = [body,
         bx((10.0, 1.5, 0.75), (0.4, 0, BORE_Z + 1.0), 'gun_lens', 'mag', 0.2),
         barrel(6.8, 2.6, 0.33), _m(cylinder((8.6, 0, BORE_Z), (9.6, 0, BORE_Z), 0.42, segs=8), 'hider', 'gun_dark'),
         bx((3.2, 0.9, 0.7), (2.8, 0, BORE_Z + 1.65), 'gun_dark', 'sight', 0.1)]
    return P


def _m249():
    P = _gun_preset('lmg')
    for m in P:
        if m.name in ('receiver', 'stock'):
            m.mat = 'gun_body'
    P.append(rod((19.3, 0, BORE_Z), (20.6, 0, BORE_Z), 0.55, mat='gun_dark', name='hider'))
    for sg in (1, -1):   # bipod folded forward
        P.append(rod((13.5, sg * 0.3, BORE_Z - 0.8), (19.0, sg * 0.4, BORE_Z - 0.9), 0.17, name='bipod', segs=5))
    P.append(_m(tube([(3.4, -0.4, BORE_Z - 1.0), (3.6, -0.2, BORE_Z + 0.3), (3.8, 0.2, BORE_Z + 1.1)], 0.3, segs=5), 'belt', 'gun_metal'))
    return P


def _m3():
    P = [receiver(7.5, 2.6, 1.5, -2.4, mat='gun_dark'), barrel(5.1, 14.0, 0.44),
         _m(tube([(5.1, 0, BORE_Z - 0.9), (17.0, 0, BORE_Z - 0.9)], 0.42, segs=8), 'tubemag', 'gun_metal'),
         _m(tube([(7.4, 0, BORE_Z - 0.9), (12.4, 0, BORE_Z - 0.9)], 0.78, segs=8), 'pump', 'gun_poly'),
         pistol_grip(3.4, 20, 1.15, 1.5, mat='gun_poly'), trigger_guard(),
         stock(-2.4, 8.0, 2.6, 1.2, 1.0, mat='gun_poly'),
         rail(-1.8, 6.0, BORE_Z + 1.4), front_sight(18.4, BORE_Z + 0.3, 0.6)]
    for k in range(5):
        P.append(_m(cylinder((7.8 + k * 1.0, 0, BORE_Z - 0.9), (8.1 + k * 1.0, 0, BORE_Z - 0.9), 0.82, segs=8), 'ridge', 'gun_dark'))
    return P


def _xm1014():
    P = [receiver(8.0, 2.6, 1.5, -2.5, mat='gun_body'), barrel(5.6, 12.5, 0.42),
         _m(tube([(5.6, 0, BORE_Z - 0.9), (16.0, 0, BORE_Z - 0.9)], 0.42, segs=8), 'tubemag', 'gun_metal'),
         _m(cylinder((7.0, 0, BORE_Z - 0.6), (12.0, 0, BORE_Z - 0.6), 0.95, 0.9, segs=8), 'fore', 'gun_poly'),
         pistol_grip(3.4, 18, 1.15, 1.5, mat='gun_poly'), trigger_guard(),
         rail(-1.6, 7.0, BORE_Z + 1.4)]
    # telescoping stock: tube + adjustable butt
    P.append(rod((-2.5, 0, BORE_Z - 0.6), (-8.4, 0, BORE_Z - 0.9), 0.45, name='stocktube', segs=8))
    P.append(side([(-6.5, BORE_Z - 0.2), (-9.4, BORE_Z - 0.4), (-9.4, BORE_Z - 3.2), (-8.5, BORE_Z - 3.2), (-6.5, BORE_Z - 1.6)],
                  1.2, mat='gun_poly', name='butt'))
    P.append(bx((1.8, 0.5, 0.5), (16.4, 0, BORE_Z - 0.4), 'gun_metal', 'clamp', 0.08))
    return P


def _ak47():
    return _gun_preset('ak47')


def _knife():
    """Combat knife: clip-point blade with fuller, guard, ribbed grip (held in the fist, blade forward)."""
    blade = side([(2.0, -0.05), (8.6, 0.2), (10.6, 0.85), (9.0, 1.05), (7.2, 0.95), (2.0, 1.05)], 0.16, mat='gun_blade', name='blade')
    P = [blade,
         bx((5.6, 0.04, 0.22), (5.0, 0.09, 0.7), 'gun_metal', 'fuller', 0.0),
         bx((0.35, 0.65, 2.0), (1.9, 0, 0.5), 'gun_metal', 'guard', 0.05),
         _m(cylinder((-2.4, 0, 0.5), (1.8, 0, 0.5), 0.52, 0.5, segs=8), 'handle', 'gun_poly'),
         _m(cylinder((-2.75, 0, 0.5), (-2.4, 0, 0.5), 0.6, 0.6, segs=8), 'pommel', 'gun_metal')]
    for k in range(4):
        P.append(_m(cylinder((-1.9 + k * 0.9, 0, 0.5), (-1.7 + k * 0.9, 0, 0.5), 0.57, segs=8), 'ridge', 'gun_dark'))
    for m in P:
        m.transform(None, (0.4, 0, -0.5))
    return P


def _grenade(kind):
    """Grenades held in the fist: body around the grip centre, spoon along the top, pin ring."""
    P = []
    if kind == 'hegrenade':
        P.append(_m(ellipsoid((1.2, 1.2, 1.5), (0.4, 0, 0.1), segs=10, rings=8), 'body', 'gun_body'))
        P.append(_m(cylinder((0.4, 0, -1.5), (0.4, 0, -1.2), 0.7, segs=8), 'base', 'gun_body'))
        P.append(_m(cylinder((0.4, 0, 0.0), (0.4, 0, 0.35), 1.24, segs=10), 'band', 'gun_accent'))
        top = 1.5
    else:
        h = 3.4
        P.append(_m(cylinder((0.4, 0, -1.5), (0.4, 0, -1.5 + h), 0.95, segs=10), 'body', 'gun_body'))
        P.append(_m(cylinder((0.4, 0, 0.2), (0.4, 0, 0.6), 0.97, segs=10), 'band', 'gun_accent'))
        if kind == 'flashbang':
            for z in (-0.9, 1.2):
                P.append(_m(cylinder((0.4, 0, z), (0.4, 0, z + 0.3), 0.97, segs=10), 'band2', 'gun_accent'))
        top = -1.5 + h
    P.append(_m(cylinder((0.4, 0, top - 0.1), (0.4, 0, top + 0.5), 0.45, segs=8), 'fuze', 'gun_metal'))
    P.append(bx((0.35, 0.5, 2.6), (-0.75, 0, top - 1.0), 'gun_metal', 'spoon', 0.06))
    P.append(_m(tube([(0.8, 0.4, top + 0.3), (1.3, 0.9, top + 0.5), (1.7, 0.6, top + 0.9), (1.4, 0.1, top + 1.1),
                      (0.9, 0.3, top + 0.6)], 0.09, segs=4), 'pin', 'gun_metal'))
    for m in P:
        m.transform(None, (0.3, 0, -0.2))
    return P


# weapon -> shape builder, ReGameDLL animation extension, dual, palette (material overrides)
_DARK = {'type': 'metal', 'color': (34, 35, 38), 'scratches': 0.35, 'shine': 0.3, 'edge_wear': 0.7, 'seed': 211}
_BLACK_POLY = {'type': 'rubber', 'color': (28, 29, 31), 'seed': 212}


def _metal(c, seed=220, wear=0.8):
    return {'type': 'metal', 'color': c, 'scratches': 0.45, 'shine': 0.4, 'edge_wear': wear, 'seed': seed}


def _poly(c, seed=230):
    return {'type': 'rubber', 'color': c, 'seed': seed}


STANDARD = {
    'ak47': dict(shape=_ak47, ext='ak47', palette={}),
    'aug': dict(shape=_aug, ext='carbine', palette={'gun_body': _poly((62, 74, 52), 231), 'gun_lens': {'type': 'visor', 'color': (60, 70, 60), 'color2': (150, 170, 140)}}),
    'awp': dict(shape=_awp, ext='rifle', palette={'gun_body': _poly((54, 72, 50), 232)}),
    'deagle': dict(shape=_deagle, ext='onehanded', palette={'gun_body': _metal((118, 120, 124), 221)}),
    'elite': dict(shape=_elite, ext='dualpistols', dual=True, palette={'gun_body': _metal((150, 152, 158), 222)}),
    'famas': dict(shape=_famas, ext='carbine', palette={'gun_body': _poly((40, 42, 40), 233)}),
    'fiveseven': dict(shape=_fiveseven, ext='onehanded', palette={'gun_body': _poly((40, 38, 36), 234)}),
    'g3sg1': dict(shape=_g3sg1, ext='mp5', palette={'gun_body': _metal((44, 46, 44), 223)}),
    'galil': dict(shape=_galil, ext='ak47', palette={'gun_body': _metal((52, 54, 50), 224), 'gun_wood': {'type': 'leather', 'color': (96, 60, 34), 'seed': 225}}),
    'glock18': dict(shape=_glock, ext='onehanded', palette={}),
    'm249': dict(shape=_m249, ext='m249', palette={'gun_body': _metal((48, 50, 46), 226)}),
    'm3': dict(shape=_m3, ext='shotgun', palette={}),
    'm4a1': dict(shape=_m4a1, ext='rifle', palette={}),
    'mac10': dict(shape=_mac10, ext='onehanded', palette={'gun_body': _metal((40, 40, 42), 227)}),
    'mp5': dict(shape=_mp5, ext='mp5', palette={}),
    'p228': dict(shape=_p228, ext='onehanded', palette={'gun_body': _metal((52, 52, 56), 228)}),
    'p90': dict(shape=_p90, ext='carbine', palette={'gun_body': _poly((36, 38, 40), 235),
                                                   'gun_lens': {'type': 'visor', 'color': (70, 60, 40), 'color2': (200, 170, 110)}}),
    'scout': dict(shape=_scout, ext='rifle', palette={'gun_body': _poly((30, 32, 34), 236)}),
    'sg550': dict(shape=_sg550, ext='rifle', palette={'gun_body': _poly((40, 44, 40), 237),
                                                     'gun_lens': {'type': 'visor', 'color': (60, 50, 40), 'color2': (190, 160, 120)}}),
    'sg552': dict(shape=_sg552, ext='mp5', palette={'gun_body': _poly((42, 46, 42), 238),
                                                   'gun_lens': {'type': 'visor', 'color': (60, 50, 40), 'color2': (190, 160, 120)}}),
    'tmp': dict(shape=_tmp, ext='onehanded', palette={'gun_body': _poly((34, 34, 36), 239)}),
    'ump45': dict(shape=_ump45, ext='carbine', palette={'gun_body': _poly((36, 36, 38), 240)}),
    'usp': dict(shape=_usp, ext='onehanded', palette={}),
    'xm1014': dict(shape=_xm1014, ext='m249', palette={'gun_body': _metal((46, 48, 50), 229)}),
    'knife': dict(shape=_knife, ext='knife', palette={}),
    'hegrenade': dict(shape=lambda: _grenade('hegrenade'), ext='grenade',
                      palette={'gun_body': {'type': 'metal', 'color': (70, 84, 50), 'scratches': 0.4, 'shine': 0.25, 'seed': 241},
                               'gun_accent': {'type': 'metal', 'color': (170, 140, 40), 'seed': 242}}),
    'smokegrenade': dict(shape=lambda: _grenade('smokegrenade'), ext='grenade',
                         palette={'gun_body': {'type': 'metal', 'color': (110, 112, 112), 'scratches': 0.4, 'shine': 0.25, 'seed': 243},
                                  'gun_accent': {'type': 'metal', 'color': (40, 40, 42), 'seed': 244}}),
    'flashbang': dict(shape=lambda: _grenade('flashbang'), ext='grenade',
                      palette={'gun_body': {'type': 'metal', 'color': (60, 64, 70), 'scratches': 0.4, 'shine': 0.3, 'seed': 245},
                               'gun_accent': {'type': 'metal', 'color': (215, 215, 205), 'seed': 246}}),
}

BASE_MATERIALS = dict(GUN_MATERIALS, gun_body=dict(GUN_MATERIALS['gun_metal'], seed=250), gun_accent=_metal((150, 120, 40), 251),
                      gun_dark=_DARK)


def standard_gun(weapon):
    """GUN SPACE meshes of a standard weapon (fresh copies)."""
    meshes = STANDARD[weapon]['shape']()
    for m in meshes:
        if m.mat == 'default':
            m.mat = 'gun_metal'
    return meshes


def standard_materials(weapon, palette=None):
    mats = dict(BASE_MATERIALS)
    mats.update(STANDARD[weapon].get('palette', {}))
    mats.update(palette or {})
    return mats


def build_standard_pmodel(weapon, out=None, palette=None, meshes=None, tex=(128, 128), preview=True, name=None,
                          preview_area='mdlkit', budget=0.08e6):
    """p_<weapon>.mdl for any standard CS weapon (STANDARD keys). meshes: optional replacement shape
    (GUN SPACE), e.g. a restyled standard_gun(weapon). Returns the pmodel report + 'ext'."""
    from . import CSTRIKE, PREVIEW_DIR
    from .pmodel import build_pmodel, preview_pmodel
    info = STANDARD[weapon]
    name = name or 'p_' + weapon
    out = out or os.path.join(CSTRIKE, 'models/vexmira/weapons', name + '.mdl')
    rep = build_pmodel(name, meshes if meshes is not None else standard_gun(weapon), out,
                       materials=standard_materials(weapon, palette), dual=info.get('dual', False), tex=tex, preview=False)
    rep['ext'] = info['ext']
    if rep['size'] > budget:
        rep['errors'].append('size %d > budget %d' % (rep['size'], budget))
    if preview:
        rep['previews'] = preview_pmodel(out, os.path.join(PREVIEW_DIR, preview_area, name), ext=info['ext'])
    return rep
