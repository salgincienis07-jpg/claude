"""zm_vexmira_7door map props (owner feedback 2026-10-10, item 6): medevac helicopter, hero statue,
Vexmira flags, plaza fountain water, string lights. All spawned by the plugin from the map ini [models]
section (info_target, not solid, client-side animation: framerate 1 + animtime).

    cd devtools
    python3 -m mdlkit build mdlkit.content.cordon:all
    python3 -m mdlkit build mdlkit.content.cordon:heli

Contracts with devtools/mapkit/maps/zm_vexmira_7door.py:
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




# ============================================================================================ hero statue
STATUE_MATS = {
    'st_bronze': metal((92, 100, 78), seed=1301, edge_wear=0.9, scratches=0.08, shine=0.5),
    'st_bronze2': metal((120, 96, 60), seed=1302, scratches=0.3, shine=0.6, edge_wear=0.9),
    'st_stone': metal((150, 146, 138), seed=1303, panels=40.0, scratches=0.1, shine=0.05, edge_wear=0.4),
    'st_dark': metal((60, 60, 62), seed=1304, scratches=0.2, shine=0.2),
    'st_flame': glow((255, 150, 40), (255, 240, 170)),
    'st_plate': metal((180, 150, 70), seed=1305, scratches=0.2, shine=0.7),
}
STATUE_SCALE = 1.55


def _posed_soldier():
    """Operator body + gear posed heroically (right arm raises a flare torch, left hand on the slung rifle,
    head up), baked to static geometry, scaled STATUE_SCALE, feet at z = 0. Returns (meshes, torch tip)."""
    from ..rig_cs import Rig, RigSpec
    from ..characters import assemble
    from ..pose import Pose
    from ..mathx import axis_angle
    from ..samples import operator_spec
    spec = operator_spec(quick=True)
    rig = Rig(spec['rig'] if not isinstance(spec['rig'], dict) else RigSpec(**spec['rig']))
    meshes, materials, decals, extra = assemble(rig, spec)
    p = Pose(rig)
    rad = math.radians
    p.rotate_world('Bip01 R UpperArm', axis_angle([1, 0, 0], rad(-150)))       # arm up (right side is -Y)
    p.rotate_world('Bip01 R UpperArm', axis_angle([0, 1, 0], rad(-15)))
    p.rotate_world('Bip01 R Forearm', axis_angle([1, 0, 0], rad(-15)))
    p.rotate_world('Bip01 L UpperArm', axis_angle([1, 0, 0], rad(-14)))
    p.rotate_world('Bip01 L Forearm', axis_angle([0, 1, 0], rad(-12)))
    p.rotate_world('Bip01 Head', axis_angle([0, 1, 0], rad(-12)))
    p.rotate_world('Bip01 L Thigh', axis_angle([0, 1, 0], rad(-22)))           # left foot forward on a rock
    p.rotate_world('Bip01 L Calf', axis_angle([0, 1, 0], rad(30)))
    WR, WT = p.world()
    M = []
    for i in range(rig.n):
        R = WR[i] @ rig.rest_rot_world[i].T
        M.append((R, WT[i] - R @ rig.rest_world[i]))
    out = []
    zmin = 1e9
    for m in meshes:
        mm = m.copy()
        v = np.array([M[b][0] @ x + M[b][1] for x, b in zip(m.v, m.bone)])
        n = np.array([M[b][0] @ x for x, b in zip(m.n, m.bone)])
        mm.v, mm.n = v, n
        mm.set_bone(0)
        mm.mat = 'st_bronze'
        mm.name = 'statue_' + (m.name or 'part')
        zmin = min(zmin, v[:, 2].min())
        out.append(mm)
    for mm in out:
        mm.v = (mm.v - np.array([0, 0, zmin])) * STATUE_SCALE
    # torch grip = centre of the right fist (fingers + thumb)
    fist = [mm for mm in out if mm.name in ('statue_fingers_R', 'statue_thumb_R', 'statue_hand_R')]
    hand = np.vstack([mm.v for mm in fist]).mean(0)
    return out, hand


def statue():
    """Hero statue for the Liberation Plaza memorial column: a quarantine-force soldier in bronze raising a
    flare torch (glowing flame), standing on a small stone plinth with a bronze plaque. Origin = top centre
    of the column cap (the plinth base), model faces +X."""
    body, hand = _posed_soldier()
    # bronze cast: drop the parts a sculptor would merge into the surface (cheaper, < 150 KB)
    drop = ('statue_goggle_strap', 'statue_ear', 'statue_helmet_rail', 'statue_helmet_mount', 'statue_buckle',
            'statue_part')
    body = [m for m in body if m.name not in drop]
    P = [hull([(x, y, z) for x in (-30, 30) for y in (-30, 30) for z in (0, 6)], 'st_stone', 'plinth_base'),
         hull([(x, y, z) for x in (-24, 24) for y in (-24, 24) for z in (6, 20)], 'st_stone', 'plinth'),
         hull([(x, y, z) for x in (-27, 27) for y in (-27, 27) for z in (20, 24)], 'st_stone', 'plinth_cap'),
         slab(24, 25, -14, 14, 9, 17, 'st_plate', 'plaque'),
         hull([(-6, 6, 24), (8, 10, 24), (10, -4, 24), (-4, -8, 24), (0, 2, 30), (6, 2, 31)], 'st_bronze2', 'rock')]
    for m in body:
        m.translate((0, 0, 24))
        m.detail = 0.6
    tip = hand + np.array([0, 0, 24])
    P.append(rod(tuple(tip + (0, 0, -10)), tuple(tip + (0, 0, 22)), 2.4, mat='st_dark', name='torch', segs=8))
    P.append(rod(tuple(tip + (0, 0, 22)), tuple(tip + (0, 0, 26)), 3.6, mat='st_bronze2', name='torch_cup', segs=10))
    from ..geom import ellipsoid as _e
    P.append(_e((4.5, 4.5, 9), tuple(tip + (0, 0, 32)), segs=10, rings=6, mat='st_flame'))
    for m in P:
        m.detail = 0.25
    for m in body:
        m.detail = 0.35
    return dict(kind='world', name='cd_statue', parts=P + body, sequences=[dict(name='idle', frames=1)],
                materials=STATUE_MATS, tex=(256, 128), out=_out('cd_statue'), preview_area=AREA, budget=0.15e6)


# ============================================================================================ flags
FLAG_MATS = {
    'fl_cloth': cloth((70, 30, 120), seed=1401, weave=0.35, dirt=0.25),
    'fl_pole': metal((150, 152, 158), seed=1402, scratches=0.4, shine=0.6),
    'fl_gold': metal((200, 165, 60), seed=1403, scratches=0.2, shine=0.8),
    'fl_dark': metal((40, 42, 46), seed=1404),
}
FLAG_N, FLAG_W, FLAG_H, FLAG_TOP = 7, 16.0, 72.0, 282.0


def flag():
    """Vexmira flag on a 290-unit pole (origin = pole foot). Cloth = 7 rigid strips on a bone chain along +X
    (each strip starts at its bone pivot, so the cloth stays continuous), sequence 'wave' (looped, 1.6 s):
    a travelling wave with growing amplitude toward the free edge + flutter. Purple cloth, white Vexmira
    emblem on both sides, cyan hem."""
    P = [rod((0, 0, 0), (0, 0, 292), 2.2, mat='fl_pole', name='pole', segs=8),
         rod((0, 0, 0), (0, 0, 10), 6, mat='fl_dark', name='base', segs=8),
         rod((0, 0, 292), (0, 0, 296), 3.4, mat='fl_gold', name='finial_ring', segs=8)]
    from ..geom import ellipsoid as _e
    P.append(_e((3.4, 3.4, 5), (0, 0, 300), segs=8, rings=5, mat='fl_gold'))
    for z in (FLAG_TOP, FLAG_TOP - FLAG_H):
        P.append(rod((0, 0, z), (3, 0, z), 1.2, mat='fl_dark', name='clip', segs=6))
    bones = [Bone('root')]
    cloth_parts = []
    for k in range(FLAG_N):
        nm = 'f%d' % k
        bones.append(Bone(nm, 'root' if k == 0 else 'f%d' % (k - 1), (2 + k * FLAG_W, 0, FLAG_TOP)))
        st = bx((FLAG_W, 0.7, FLAG_H), (2 + (k + 0.5) * FLAG_W, 0, FLAG_TOP - FLAG_H / 2), 'fl_cloth', 'cloth%d' % k, 0.0)
        st.detail = 1.0
        cloth_parts += on(nm, st)

    def wave(t):
        out = {}
        for k in range(FLAG_N):
            a = (5 + 3.2 * k) * math.sin(2 * math.pi * t - 0.85 * k)
            r = 3.0 * math.sin(4 * math.pi * t - 1.3 * k)
            out['f%d' % k] = dict(rot=(a * (0.55 if k else 0.4), 0, r))
        return out
    for m in P:
        m.detail = 0.2
    cx = 2 + FLAG_N * FLAG_W / 2
    dec = [dict(kind='shape', shape='vex', center=(cx, 0, FLAG_TOP - FLAG_H / 2 + 2), u=(1, 0, 0), v=(0, 0, 1), size=24,
                color=(235, 235, 245), depth=3, soft=0.35),
           dict(kind='band', normal=(0, 0, 1), offset=FLAG_TOP - FLAG_H + 4, width=6, color=(0, 220, 255), soft=0.4,
                target='fl_cloth'),
           dict(kind='band', normal=(0, 0, 1), offset=FLAG_TOP - 4, width=6, color=(0, 220, 255), soft=0.4,
                target='fl_cloth')]
    return dict(kind='world', name='cd_flag', parts=P + cloth_parts, bones=bones,
                sequences=[dict(name='wave', frames=25, fps=15, loop=True, pose=wave)],
                materials=FLAG_MATS, decals=dec, tex=(256, 128), out=_out('cd_flag'), preview_area=AREA, budget=0.06e6)


# ============================================================================================ string lights
BULB_COLS = [(255, 40, 40), (40, 255, 80), (60, 120, 255), (255, 210, 40), (200, 60, 255), (255, 120, 20)]
LIGHT_MATS = {'li_wire': metal((25, 25, 27), seed=1501, scratches=0.0, shine=0.1),
              'li_sock': metal((40, 40, 42), seed=1502),
              'li_halo': {'type': 'flat', 'color': (0, 0, 0)}}
for _i, _c in enumerate(BULB_COLS):
    LIGHT_MATS['li_b%d' % _i] = glow(_c, tuple(min(255, int(v * 0.5 + 140)) for v in _c))


def _catenary(n, L, sag):
    return [(L * i / n, 0.0, -sag * (1 - (2.0 * i / n - 1) ** 2)) for i in range(n + 1)]


def string_lights():
    """String of 12 coloured bulbs on a sagging wire, LIGHTS_LEN long along +X (origin = left anchor,
    sag 26). Bodygroup 'part': 0 = wire + sockets + bulbs (normal render), 1 = soft glow halos (black
    background: spawn a 2nd entity with body 1, rendermode additive + renderfx strobe = blinking)."""
    pts = _catenary(16, LIGHTS_LEN, 26)
    wire = [tube(pts, 0.45, segs=4, mat='li_wire', cap_start=False, cap_end=False, name='wire')]
    bulbs, halos, decs = [], [], []
    nb = 12
    from ..geom import ellipsoid as _e
    for i in range(nb):
        x = LIGHTS_LEN * (i + 0.5) / nb
        z = -26 * (1 - (2.0 * x / LIGHTS_LEN - 1) ** 2)
        c = i % len(BULB_COLS)
        wire.append(rod((x, 0, z - 0.4), (x, 0, z - 3.0), 1.1, mat='li_sock', name='sock', segs=6))
        bulbs.append(_e((1.7, 1.7, 2.4), (x, 0, z - 5.2), segs=6, rings=4, mat='li_b%d' % c))
        h = bx((12, 0.2, 12), (x, 0, z - 5.2), 'li_halo', 'halo', 0.0)
        h.detail = 1.4
        halos.append(h)
        decs.append(dict(kind='sphere', center=(x, 0, z - 5.2), radius=5.6, soft=1.0, color=BULB_COLS[c], mode='add',
                         target='li_halo'))
    for m in wire + bulbs:
        m.detail = 0.25
    return dict(kind='world', name='cd_lights', parts=wire, bodygroups=[('part', [bulbs, halos])],
                sequences=[dict(name='idle', frames=1)], materials=LIGHT_MATS, decals=decs, tex=(256, 128),
                out=_out('cd_lights'), preview_area=AREA, budget=0.07e6)


# ============================================================================================ fountain water
WATER_MATS = {'wa_jet': glow((120, 190, 255), (235, 250, 255), freq=0.6),
              'wa_foam': glow((170, 210, 240), (255, 255, 255), freq=1.2)}
FOUNTAIN_HALF = 160.0      # plinth half size around the fountain origin (map: plinth -160..160 x -224..96)
FOUNTAIN_SPOUT_Z = 74.0
FOUNTAIN_WATER_Z = 12.0
# The entity origin must sit in open air (studio lighting is sampled at the origin; inside the plinth the
# additive jets would be lit black = invisible): origin = plinth centre + FOUNTAIN_ORIGIN (above the basin)
FOUNTAIN_ORIGIN = np.array([192.0, 0.0, 40.0])


def _jet(p0, n, reach=52.0, peak=18.0):
    p0 = np.asarray(p0, float); n = np.asarray(n, float)
    def at(s):
        return p0 + n * reach * s + np.array([0, 0, 4 * peak * s * (1 - s) - (p0[2] - FOUNTAIN_WATER_Z) * s * s])
    def tan(s):
        d = n * reach + np.array([0, 0, 4 * peak * (1 - 2 * s) - 2 * (p0[2] - FOUNTAIN_WATER_Z) * s])
        return d / np.linalg.norm(d)
    return at, tan


def _align(z_to):
    """Rotation taking +Z to the direction z_to."""
    z = np.array([0, 0, 1.0]); a = np.asarray(z_to, float)
    v = np.cross(z, a); c = float(np.dot(z, a))
    if np.linalg.norm(v) < 1e-9:
        return np.eye(3)
    vx = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + vx + vx @ vx * (1.0 / (1.0 + c))


def fountain_water():
    """Water of the Liberation Plaza fountain (render it additive): 8 arcing jets from spouts on the four
    sides of the monument plinth (2 per side, z 74) into the basin (water z 12); each jet = a chain of stretched
    droplets (8 per jet) on their own bones that slide along the parabola (sequence 'flow', looped 0.8 s: every drop
    takes the next one's place = continuous stream), plus foam rings that pulse where the jets land.
    Origin = plinth centre at floor level + FOUNTAIN_ORIGIN."""
    N = 8
    bones = [Bone('root')]
    parts = []
    jets = []
    h = FOUNTAIN_HALF
    for side, n in enumerate(((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0))):
        for off in (-80, 80):
            t = np.array((-n[1], n[0], 0))
            p0 = np.array(n) * (h + 3) + t * off + np.array([0, 0, FOUNTAIN_SPOUT_Z])
            jets.append(_jet(p0, n))
    from ..geom import ellipsoid as _e, lathe as _lathe
    for j, (at, tan) in enumerate(jets):
        for k in range(N):
            s0 = k / N
            nm = 'j%d_%d' % (j, k)
            c = at(s0)
            bones.append(Bone(nm, 'root', tuple(c)))
            m = _e((2.3, 2.3, 7.0), (0, 0, 0), segs=5, rings=3, mat='wa_jet')
            m.transform(R=_align(tan(s0)), t=c)
            m.detail = 0.15
            parts += on(nm, m)
        # foam ring where the jet lands
        land = at(1.0)
        nm = 'f%d' % j
        bones.append(Bone(nm, 'root', tuple(land)))
        ring = _lathe([(0, 9), (1.5, 6), (0.5, 3)], axis_start=tuple(land), segs=10, mat='wa_foam', name='foam')
        ring.detail = 0.1
        parts += on(nm, ring)

    for m in parts:
        m.translate(tuple(-FOUNTAIN_ORIGIN))
    for b_ in bones[1:]:
        b_['pos'] = tuple(np.asarray(b_['pos']) - FOUNTAIN_ORIGIN)

    def flow(t):
        out = {}
        for j, (at, tan) in enumerate(jets):
            for k in range(N):
                s0, s1 = k / N, (k + t) / N
                out['j%d_%d' % (j, k)] = dict(pos=tuple(at(s1) - at(s0)), R=_align(tan(s1)) @ _align(tan(s0)).T)
            out['f%d' % j] = dict(pos=(0, 0, 1.2 * math.sin(2 * math.pi * (t + j * 0.13))))
        return out
    return dict(kind='world', name='cd_fountain', parts=parts, bones=bones,
                sequences=[dict(name='flow', frames=9, fps=10, loop=True, pose=flow)],
                materials=WATER_MATS, tex=(128, 128), out=_out('cd_fountain'), preview_area=AREA, budget=0.12e6)


# ============================================================================================ locomotive
LOCO_MATS = {
    'lo_body': metal((120, 34, 40), seed=1601, paint=(135, 30, 38), panels=32.0, chipping=0.35, edge_wear=0.8,
                     scratches=0.35, rust=0.15),
    'lo_stripe': metal((215, 200, 60), seed=1602, scratches=0.3),
    'lo_dark': metal((36, 36, 40), seed=1603, scratches=0.4, rust=0.2),
    'lo_steel': metal((120, 122, 126), seed=1604, scratches=0.5, shine=0.5, rust=0.1),
    'lo_glass': {'type': 'visor', 'color': (40, 60, 80), 'color2': (150, 180, 200)},
    'lo_lamp': glow((255, 240, 200), (255, 255, 255)),
    'lo_red': glow((255, 40, 30), (255, 160, 140)),
}


def locomotive():
    """Derailed diesel locomotive of the evac train (station track, crashed into the breach): 432 x 128 x 144,
    origin = bottom centre (track bed), nose toward +X. Cab with windows at the front, engine hood with
    grilles and fans, bogies with wheels, buffers, headlights, Vexmira hazard livery. Static."""
    L, W_, H = 432.0, 128.0, 144.0
    P = []
    x0, x1 = -L / 2, L / 2
    P.append(slab(x0 + 30, x1 - 30, -50, 50, 18, 34, 'lo_dark', 'frame'))                       # underframe
    P.append(hull(sect(x0 + 24, 62, 34, 118, 10) + sect(x1 - 120, 62, 34, 118, 10), 'lo_body', 'hood'))
    P.append(hull(sect(x1 - 122, 64, 34, 140, 8) + sect(x1 - 30, 64, 34, 138, 8) + sect(x1 - 6, 50, 34, 104, 12),
                  'lo_body', 'cab'))
    for sy in (1, -1):
        P.append(slab(x0 + 20, x1 - 10, sy * 64 - 1, sy * 64 + 1, 44, 52, 'lo_stripe', 'stripe') if sy > 0 else
                 slab(x0 + 20, x1 - 10, -65, -63, 44, 52, 'lo_stripe', 'stripe'))
        for xw in (x1 - 110, x1 - 70):
            P.append(slab(xw, xw + 30, sy * 64.5 - 0.6, sy * 64.5 + 0.6, 92, 124, 'lo_glass', 'side_win'))
        for xg in range(int(x0 + 40), int(x1 - 140), 40):
            P.append(slab(xg, xg + 28, sy * 62.5 - 0.6, sy * 62.5 + 0.6, 60, 100, 'lo_dark', 'grille'))
    P.append(hull([(x1 - 6, -46, 100), (x1 - 6, 46, 100), (x1 - 4, -40, 128), (x1 - 4, 40, 128),
                   (x1 - 2, -46, 100), (x1 - 2, 46, 100)], 'lo_glass', 'windscreen'))
    for xf in (x0 + 70, x0 + 150, x0 + 230):
        P.append(rod((xf, 0, 118), (xf, 0, 122), 22, mat='lo_dark', name='fan', segs=12))
    P.append(rod((x0 + 110, 20, 118), (x0 + 110, 20, 140), 6, mat='lo_dark', name='exhaust', segs=8))
    for xb in (x0 + 70, x1 - 90):                      # bogies + wheels
        P.append(slab(xb - 46, xb + 46, -54, 54, 8, 22, 'lo_dark', 'bogie'))
        for xw in (xb - 28, xb + 28):
            for sy in (1, -1):
                P.append(rod((xw, sy * 50, 14), (xw, sy * 60, 14), 15, mat='lo_steel', name='wheel', segs=12))
    for xe, sg in ((x1, 1), (x0, -1)):                 # buffers + headlights + coupler
        for sy in (1, -1):
            P.append(rod((xe, sy * 40, 30), (xe + sg * 10, sy * 40, 30), 6, mat='lo_steel', name='buffer', segs=8))
        P.append(slab(min(xe, xe + sg * 6), max(xe, xe + sg * 6), -10, 10, 22, 34, 'lo_dark', 'coupler'))
    for sy in (1, -1):
        P.append(rod((x1 - 3, sy * 30, 66), (x1 + 1, sy * 30, 66), 6, mat='lo_lamp', name='headlight', segs=10))
        P.append(rod((x0 + 21, sy * 44, 60), (x0 + 17, sy * 44, 60), 4, mat='lo_red', name='taillight', segs=8))
    P.append(slab(x1 - 100, x1 - 40, -30, 30, 140, 146, 'lo_dark', 'horn_box'))
    for m in P:
        m.detail = 0.12
    dec = [dict(kind='shape', shape='vex', center=(x0 + 150, sy * 64, 84), u=(1, 0, 0), v=(0, 0, 1), size=16,
                color=(160, 90, 255), depth=6, soft=0.4, facing=(0, sy, 0)) for sy in (1, -1)]
    dec.append(dict(kind='sphere', center=(x1 - 60, 40, 30), radius=50, soft=1.0, color=(40, 20, 10), mode='multiply',
                    alpha=0.6))
    return dict(kind='world', name='cd_loco', parts=P, sequences=[dict(name='idle', frames=1)], materials=LOCO_MATS,
                decals=dec, tex=(256, 128), out=_out('cd_loco'), preview_area=AREA, budget=0.12e6)


# ============================================================================================ windsock
def windsock():
    """Helipad windsock: 140-unit mast with a striped orange/white sock (4 rigid rings on a bone chain)
    swinging in the wind (sequence 'blow', looped 2 s). Origin = mast foot."""
    mats = {'ws_pole': metal((150, 152, 158), seed=1701, scratches=0.4), 'ws_or': cloth((235, 110, 20), seed=1702, dirt=0.2),
            'ws_wh': cloth((230, 230, 225), seed=1703, dirt=0.25), 'ws_red': glow((255, 40, 30))}
    P = [rod((0, 0, 0), (0, 0, 142), 1.8, mat='ws_pole', name='pole', segs=8),
         rod((0, 0, 142), (0, 0, 146), 2.6, mat='ws_red', name='lamp', segs=8),
         rod((0, 0, 132), (6, 0, 132), 1.0, mat='ws_pole', name='arm', segs=6)]
    bones = [Bone('root')]
    sock = []
    for k in range(4):
        nm = 's%d' % k
        x = 6 + k * 10
        bones.append(Bone(nm, 'root' if k == 0 else 's%d' % (k - 1), (x, 0, 132)))
        r0, r1 = 7.0 - k * 1.2, 6.0 - k * 1.2
        sock += on(nm, tube([(x, 0, 132), (x + 10, 0, 132)], [r0, r1], segs=10, mat='ws_or' if k % 2 == 0 else 'ws_wh',
                            cap_start=False, cap_end=False, name='sock'))
    for m in P + sock:
        m.detail = 0.4

    def blow(t):
        out = {}
        for k in range(4):
            out['s%d' % k] = dict(rot=(10 * math.sin(2 * math.pi * t - 0.7 * k), -4 * (k + 1) * (0.5 + 0.5 * math.sin(2 * math.pi * t)), 0))
        return out
    return dict(kind='world', name='cd_windsock', parts=P + sock, bones=bones,
                sequences=[dict(name='blow', frames=21, fps=10, loop=True, pose=blow)], materials=mats, tex=(64, 64),
                out=_out('cd_windsock'), preview_area=AREA, budget=0.03e6)


def all():   # noqa: A001
    return [heli(), statue(), flag(), string_lights(), fountain_water(), locomotive(), windsock()]
