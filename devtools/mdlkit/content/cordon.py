"""zm_vex_cordon map props (owner feedback 2026-10-10, item 6): medevac helicopter, hero statue,
Vexmira flags, plaza fountain water, string lights. All spawned by the plugin from the map ini [models]
section (info_target, not solid, client-side animation: framerate 1 + animtime).

    cd devtools
    python3 -m mdlkit build mdlkit.content.cordon:all
    python3 -m mdlkit build mdlkit.content.cordon:heli

Contracts with devtools/mapkit/maps/zm_vex_cordon.py:
  heli   origin = the func_train origin (ORIGIN brush in the bbox centre of the collision brushes), so the
         brush deck top is at z = HELI_DECK_Z (-32) in model space, deck
         x -128..128 (nose toward -X), y -96..96; side door gaps x -64..64; skids touch z = -32 (the
         landed deck top is 16 above the roof). MOVETYPE_FOLLOW keeps yaw 0 (model +X = map +X).
         Sequence 0 'fly' (main + tail rotor spin), attachment 0 = searchlight under the nose.
  statue origin = top centre of the memorial column cap (z 336 in the map), faces +X (yaw set in the ini).
  flag   origin = foot of the pole; the cloth hangs toward +X; sequence 0 'wave'.
  water  origin = top centre of the fountain bowl; sequence 0 'flow' (jets + falling water, looped).
  lights origin = left anchor of the strand; strand along +X (length LIGHTS_LEN), sags in -Z;
         body 0 = wire + bulbs (normal), body 1 = glow halos (render additive with renderfx strobe).
"""
import math
import numpy as np

from . import *          # noqa: F401,F403
from ..geom import Mesh, flat_shaded, box_project_uv, loft, Ring, ellipsoid as _ell
from ..anims import ypr

AREA = 'cordon'
HELI_DECK_Z = -32.0
LIGHTS_LEN = 256.0


def _out(name):
    return world_out(name)


def hull(points, mat, name='hull'):
    """Convex hull of points -> flat shaded mesh with box-projected UVs (chunky hard-surface parts)."""
    from scipy.spatial import ConvexHull
    pts = np.asarray(points, float)
    c = (pts.max(0) + pts.min(0)) / 2
    rel = pts - c
    h = ConvexHull(rel)
    f = h.simplices.copy()
    fn = np.cross(rel[f[:, 1]] - rel[f[:, 0]], rel[f[:, 2]] - rel[f[:, 0]])
    inward = np.einsum('ij,ij->i', fn, rel[f].mean(1)) < 0
    f[inward] = f[inward][:, ::-1]
    m = flat_shaded(Mesh(rel, f, None, None, 0, mat))
    m.uv = box_project_uv(m.v, m.n, (rel.max(0) - rel.min(0)) / 2)
    m.size = (3 * float(max(rel.max(0)[:2] - rel.min(0)[:2])), 2 * float(max(rel.max(0)[1:] - rel.min(0)[1:])))
    m.translate(c)
    m.name = name
    return m


def slab(x0, x1, y0, y1, z0, z1, mat, name='slab', bevel=0.0):
    return bx((x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), mat, name, bevel)


def sect(x, hw, z0, z1, chamfer):
    """Octagonal fuselage cross-section at x: half width hw, z0..z1, chamfered corners."""
    c = chamfer
    return [(x, -hw, z0 + c), (x, -hw + c, z0), (x, hw - c, z0), (x, hw, z0 + c),
            (x, hw, z1 - c), (x, hw - c, z1), (x, -hw + c, z1), (x, -hw, z1 - c)]


# ============================================================================================ helicopter
HELI_MATS = {
    'hb_body': metal((74, 82, 56), seed=1201, paint=(78, 86, 58), panels=24.0, chipping=0.25, edge_wear=0.7,
                     scratches=0.3, shine=0.2),
    'hb_dark': metal((40, 43, 40), seed=1202, panels=12.0, scratches=0.3, edge_wear=0.5, shine=0.25),
    'hb_floor': metal((60, 62, 60), seed=1203, scratches=0.5, shine=0.3),
    'hb_steel': metal((120, 124, 128), seed=1204, scratches=0.5, shine=0.5, edge_wear=0.3),
    'hb_glass': {'type': 'visor', 'color': (40, 70, 95), 'color2': (170, 200, 220)},
    'hb_blade': metal((28, 29, 30), seed=1205, scratches=0.2, shine=0.3),
    'hb_tip': metal((210, 190, 40), seed=1206, scratches=0.2),
    'hb_white': metal((215, 215, 205), seed=1207, scratches=0.2, shine=0.25, edge_wear=0.2),
    'hb_red': glow((255, 30, 20), (255, 140, 110)),
    'hb_green': glow((40, 255, 70), (200, 255, 200)),
    'hb_lamp': glow((255, 250, 225), (255, 255, 255)),
    'hb_rubber': {'type': 'rubber', 'color': (24, 24, 26), 'seed': 1208},
}


def _heli_decals():
    d = []
    for sy in (1, -1):        # medevac crosses (white square + red cross) on the cabin rear side panels
        d.append(dict(kind='shape', shape='box', center=(96, sy * 104, 50), u=(1, 0, 0), v=(0, 0, 1), size=17,
                      color=(225, 225, 215), depth=10, soft=0.4, facing=(0, sy, 0)))
        d.append(dict(kind='shape', shape='cross', center=(96, sy * 104, 50), u=(1, 0, 0), v=(0, 0, 1), size=14,
                      color=(200, 20, 18), depth=10, soft=0.4, facing=(0, sy, 0)))
        d.append(dict(kind='shape', shape='vex', center=(300, sy * 30, 84), u=(1, 0, 0), v=(0, 0, 1), size=13,
                      color=(160, 90, 255), depth=24, soft=0.4, facing=(0, sy, 0)))
    d.append(dict(kind='shape', shape='box', center=(0, 0, 106), u=(1, 0, 0), v=(0, 1, 0), size=26,
                  color=(225, 225, 215), depth=6, soft=0.4, facing=(0, 0, 1)))
    d.append(dict(kind='shape', shape='cross', center=(0, 0, 106), u=(1, 0, 0), v=(0, 1, 0), size=21,
                  color=(200, 20, 18), depth=6, soft=0.4, facing=(0, 0, 1)))
    return d


def heli():
    """Military medevac helicopter around the cordon func_train deck (see module doc). Open cabin with
    side door gaps; cockpit + glass canopy toward -X; tail boom +X; engine deck, 4-blade main rotor
    (bone 'rotor'), 2-blade tail rotor (bone 'trotor'), skids, nav / beacon / landing lights.
    Sequence 'fly': rotors spin (main 90 deg per 0.13 s = 1.9 rev/s, tail 4 rev/s)."""
    Z = HELI_DECK_Z
    P = []
    # --- belly + floor rim (hides the brush deck sides; deck brush is z -24..-16)
    P.append(hull(sect(-128, 104, Z - 22, Z - 2, 8) + sect(132, 104, Z - 22, Z - 2, 8), 'hb_dark', 'belly'))
    # --- cabin walls: low sills with door gaps (x -64..64), pillars, window bars, roof
    for sy in (1, -1):
        y0, y1 = sorted((sy * 96, sy * 106))
        for xa, xb in ((-128, -64), (64, 132)):
            P.append(slab(xa, xb, y0, y1, Z - 4, Z + 42, 'hb_body', 'sill'))       # waist panel (rail 40)
            P.append(slab(xa, xb, y0 - 1, y1 + 1, Z + 40, Z + 46, 'hb_dark', 'sill_cap', 0.8))
        for xp in (-124, -66, 66, 126):
            P.append(slab(xp - 5, xp + 5, y0, y1, Z + 42, Z + 106, 'hb_body', 'pillar', 0.8))
        for xa, xb in ((-124, -66), (66, 126)):
            P.append(slab(xa, xb, y0 + (1 if sy > 0 else 0), y1 - (0 if sy > 0 else 1), Z + 98, Z + 106, 'hb_body', 'header'))
        P.append(slab(-66, 66, y0, y1, Z + 92, Z + 108, 'hb_body', 'door_header'))
        P.append(slab(-70, 70, y0 + (8 if sy > 0 else -4), y1 + (0 if sy > 0 else -8), Z + 100, Z + 104,
                      'hb_steel', 'door_rail'))                                     # sliding door rail
        P.append(slab(70, 128, min(sy * 108, sy * 112), max(sy * 108, sy * 112), Z + 6, Z + 100, 'hb_body', 'door'))
    P.append(hull(sect(-150, 108, Z + 104, Z + 114, 6) + sect(140, 108, Z + 104, Z + 114, 6), 'hb_body', 'roof'))
    P.append(slab(124, 134, -96, 96, Z - 4, Z + 106, 'hb_body', 'rear_wall'))
    P.append(slab(122, 125, -40, 40, Z + 60, Z + 92, 'hb_glass', 'rear_window'))
    P.append(slab(-128, -120, -96, 96, Z - 4, Z + 106, 'hb_dark', 'bulkhead'))
    P.append(slab(-121, -119, -34, 34, Z + 40, Z + 90, 'hb_glass', 'bulkhead_win'))
    # cabin interior: folded stretcher racks on the rear wall + wall lamps (above head height)
    for sy in (1, -1):
        P.append(slab(108, 122, sy * 60 - 30, sy * 60 + 30, Z + 74, Z + 78, 'hb_steel', 'rack'))
        P.append(slab(-110, -100, sy * 88 - 4, sy * 88 + 4, Z + 96, Z + 100, 'hb_lamp', 'cabin_lamp'))
    # --- cockpit nose (toward -X) + canopy
    nose = (sect(-128, 106, Z - 22, Z + 112, 10) + sect(-170, 100, Z - 22, Z + 100, 14) +
            sect(-215, 82, Z - 18, Z + 70, 18) + sect(-250, 52, Z - 10, Z + 38, 16) + sect(-268, 22, Z + 0, Z + 22, 8))
    P.append(hull([p for p in nose if p[2] <= Z + 34] + [(-128, -106, Z + 34), (-128, 106, Z + 34), (-215, -82, Z + 34),
                                                          (-215, 82, Z + 34), (-250, -52, Z + 34), (-250, 52, Z + 34)],
                  'hb_body', 'nose'))
    canopy = [p for p in nose if p[2] >= Z + 30 and p[0] < -129] + [(-130, -104, Z + 112), (-130, 104, Z + 112),
                                                                    (-130, -106, Z + 30), (-130, 106, Z + 30),
                                                                    (-252, -50, Z + 30), (-252, 50, Z + 30)]
    P.append(hull([(x, y * 1.0, z) for x, y, z in canopy], 'hb_glass', 'canopy'))
    for yy in (-40, 40):                                                  # canopy frame bars
        P.append(hull([(-130, yy - 3, Z + 112), (-130, yy + 3, Z + 112), (-232, yy * 0.8 - 3, Z + 52),
                       (-232, yy * 0.8 + 3, Z + 52), (-131, yy, Z + 116), (-233, yy * 0.8, Z + 55)], 'hb_dark', 'cframe'))
    P.append(hull([(-130, -3, Z + 113), (-130, 3, Z + 113), (-246, -3, Z + 40), (-246, 3, Z + 40),
                   (-131, 0, Z + 117), (-247, 0, Z + 43)], 'hb_dark', 'cframe'))
    # searchlight under the nose + landing lamp
    P.append(rod((-226, 0, Z - 14), (-226, 0, Z - 26), 6, mat='hb_dark', name='spot_mount', segs=8))
    P.append(rod((-226, 0, Z - 26), (-236, 0, Z - 30), 9, mat='hb_dark', name='spot', segs=10))
    P.append(rod((-236, 0, Z - 30), (-238, 0, Z - 31), 7.5, mat='hb_lamp', name='spot_lens', segs=10))
    P.append(rod((-180, 30, Z - 22), (-180, 30, Z - 25), 6, mat='hb_lamp', name='land_lamp', segs=8))
    # --- engine deck + exhausts + intakes
    P.append(hull(sect(-96, 62, Z + 112, Z + 140, 14) + sect(70, 56, Z + 112, Z + 146, 16) + sect(96, 40, Z + 112, Z + 132, 12),
                  'hb_body', 'engine'))
    for sy in (1, -1):
        P.append(rod((60, sy * 50, Z + 132), (104, sy * 66, Z + 136), 9, mat='hb_dark', name='exhaust', segs=8))
        P.append(rod((-96, sy * 44, Z + 128), (-102, sy * 44, Z + 128), 10, mat='hb_dark', name='intake', segs=8))
        P.append(slab(-60, 40, sy * 63 - 1, sy * 63 + 1, Z + 118, Z + 134, 'hb_dark', 'grille'))
    # --- tail boom, fin, stabiliser, tail rotor gearbox
    P.append(hull(sect(126, 44, Z + 46, Z + 110, 12) + sect(300, 22, Z + 84, Z + 112, 8) + sect(470, 11, Z + 92, Z + 108, 4),
                  'hb_body', 'boom'))
    P.append(hull([(430, -5, Z + 96), (430, 5, Z + 96), (500, -4, Z + 96), (500, 4, Z + 96),
                   (476, -3, Z + 196), (476, 3, Z + 196), (498, -3, Z + 196), (498, 3, Z + 196)], 'hb_body', 'fin'))
    P.append(hull([(420, -70, Z + 98), (420, 70, Z + 98), (450, -70, Z + 98), (450, 70, Z + 98),
                   (424, -70, Z + 103), (424, 70, Z + 103), (446, -70, Z + 103), (446, 70, Z + 103)], 'hb_body', 'stab'))
    P.append(rod((486, 4, Z + 160), (486, 14, Z + 160), 6, mat='hb_dark', name='tr_hub', segs=8))
    P.append(rod((488, 0, Z + 197), (488, 0, Z + 204), 4, mat='hb_red', name='beacon_tail', segs=8))
    P.append(rod((-20, 0, Z + 146), (-20, 0, Z + 152), 5, mat='hb_red', name='beacon_top', segs=8))
    P.append(slab(442, 448, 70, 74, Z + 97, Z + 104, 'hb_green', 'nav_l'))
    P.append(slab(442, 448, -74, -70, Z + 97, Z + 104, 'hb_red', 'nav_r'))
    # --- skids (touch z = Z - 16 = -32: the landed deck top is 16 above the roof)
    for sy in (1, -1):
        y = sy * 80
        P.append(tube([(-196, y, Z - 6), (-180, y, Z - 13), (-160, y, Z - 15), (140, y, Z - 15)], 3.5, segs=8,
                      mat='hb_steel', name='skid'))
        for xs in (-120, 90):
            P.append(rod((xs, sy * 58, Z - 20), (xs, y, Z - 13), 3.2, mat='hb_steel', name='strut', segs=6))
        P.append(slab(-100, 60, y - 2, y + 2, Z - 16, Z - 12, 'hb_rubber', 'skid_shoe'))
    # --- main rotor (bone 'rotor' at the hub) + tail rotor (bone 'trotor')
    RZ = Z + 168
    P.append(rod((0, 0, Z + 140), (0, 0, RZ), 7, mat='hb_steel', name='mast', segs=10))
    rotor = [rod((0, 0, RZ - 4), (0, 0, RZ + 6), 16, mat='hb_dark', name='hub', segs=12)]
    for k in range(4):
        a = math.radians(45 + 90 * k)
        ca, sa = math.cos(a), math.sin(a)
        pts = []
        for r_, w_ in ((14, 8), (40, 11), (236, 10), (248, 9)):
            for s in (-1, 1):
                for zz in (-1.2, 1.2):
                    pts.append((ca * r_ - sa * s * w_, sa * r_ + ca * s * w_, RZ + zz))
        rotor.append(hull(pts, 'hb_blade', 'blade'))
        rotor.append(hull([(ca * r - sa * s * 9.5, sa * r + ca * s * 9.5, RZ + zz) for r in (232, 249) for s in (-1, 1)
                           for zz in (-1.4, 1.4)], 'hb_tip', 'blade_tip'))
    trotor = [rod((486, 14, Z + 160), (486, 18, Z + 160), 5, mat='hb_dark', name='tr_hub2', segs=8)]
    for k in range(2):
        a = math.radians(90 * k + 30)
        ca, sa = math.cos(a), math.sin(a)
        trotor.append(hull([(486 + ca * r - sa * s * 4, 16 + d, Z + 160 + sa * r + ca * s * 4)
                            for r in (-44, 44) for s in (-1, 1) for d in (-0.8, 0.8)], 'hb_blade', 'tblade'))
    bones = [Bone('root'), Bone('rotor', 'root', (0, 0, RZ)), Bone('trotor', 'root', (486, 16, Z + 160))]
    parts = P + on('rotor', rotor) + on('trotor', trotor)
    for m in parts:
        m.detail = 0.1
    seq = [dict(name='fly', frames=5, fps=30, loop=True,
                pose=lambda t: {'rotor': dict(rot=(-90.0 * t, 0, 0)),
                                'trotor': dict(R=_rot_y(math.radians(180.0 * t)))})]
    return dict(kind='world', name='cd_heli', parts=parts, bones=bones, sequences=seq,
                attachments=[('root', (-238, 0, Z - 32))], materials=HELI_MATS, decals=_heli_decals(),
                tex=(256, 256), out=_out('cd_heli'), preview_area=AREA, budget=0.15e6)


def _rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def all():   # noqa: A001
    return [heli()]
