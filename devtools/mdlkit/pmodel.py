"""Gun mesh builder helpers + p_ (third-person weapon) models.

GUN SPACE (all gun builders): origin = centre of the pistol grip (where the hand closes), +X = barrel
direction, +Z = top of the gun, +Y = gun left. The bore axis is ~2.4 units above the grip centre.
Standard positions (72-unit human, see anims.HOLDS):
    support hand grip point = (fore, 0, fore_down) e.g. rifle (9.5, 0, -0.6), ak47 (9.0, 0, -0.5)
p_ models bind the gun to a single root bone named "Bip01 R Hand" whose frame is the grip frame of our
player rig (rig_cs: +X barrel, +Z gun top, palm faces +Y) with the grip centre at rig_cs.GRIP_R, so the
engine's bone merge by NAME puts the gun in the right hand of every vex_* player model. Dual pistols get a
second root "Bip01 L Hand".

    from mdlkit.pmodel import gun_preset, build_pmodel
    build_pmodel('p_ak47', gun_preset('ak47', palette), out_path)
"""
import math
import os
import numpy as np

from .geom import Mesh, box, tube, cylinder, extrude, ellipsoid, flat_shaded, pack_atlas
from .mathx import rot_x, rot_y, rot_z
from .rig_cs import GRIP_R, GRIP_L

BORE_Z = 2.4


# ============================================================================================ parts

def _m(mesh, name, mat):
    mesh.name = name
    mesh.mat = mat
    return mesh


def receiver(length=9.0, height=2.6, width=1.5, x0=-2.5, z0=None, mat='gun_metal', bevel=0.25, name='receiver'):
    z0 = BORE_Z - height * 0.35 if z0 is None else z0
    return _m(box((length, width, height), center=(x0 + length / 2, 0, z0), bevel=bevel), name, mat)


def barrel(x0=6.0, length=10.0, r=0.38, z=BORE_Z, mat='gun_metal', segs=8, name='barrel', r_end=None):
    return _m(cylinder((x0, 0, z), (x0 + length, 0, z), r, r if r_end is None else r_end, segs=segs), name, mat)


def handguard(x0=5.0, length=6.0, r=0.95, z=BORE_Z - 0.35, mat='gun_poly', segs=8, flat=0.85, name='handguard'):
    m = tube([(x0, 0, z), (x0 + length, 0, z)], [r, r * 0.95], segs=segs, radii_b=[r * flat, r * flat * 0.95])
    return _m(m, name, mat)


def pistol_grip(height=3.6, angle=18.0, width=1.2, depth=1.6, mat='gun_poly', name='grip', x=0.0):
    poly = [(-depth / 2, 0), (depth / 2, 0), (depth / 2 * 0.9, -height), (-depth / 2 * 1.1, -height)]
    m = extrude(poly, width, R=rot_x(math.pi / 2), t=(0, 0, 0))
    # tilt backwards, centre the grip around the origin
    m.transform(rot_y(-math.radians(angle)), (x, 0, height * 0.45))
    return _m(m, name, mat)


def magazine(x=2.4, length=4.5, width=1.0, depth=1.6, curve=0.0, angle=8.0, mat='gun_metal', name='mag', z_top=None):
    z_top = BORE_Z - 1.0 if z_top is None else z_top
    n = 5
    pts = []
    for i in range(n + 1):
        t = i / n
        pts.append((x + curve * t * t * length * 0.5 + math.sin(math.radians(angle)) * t * length, 0, z_top - t * length))
    rad = [depth / 2] * (n + 1)
    m = tube(pts, rad, segs=4, radii_b=[width / 2] * (n + 1), ref=np.array([0, 1.0, 0]))
    return _m(m, name, mat)


def stock(x1=-2.5, length=7.5, height=2.4, width=1.2, drop=0.9, mat='gun_poly', name='stock', skeletal=False):
    x0 = x1 - length
    poly = [(x1, BORE_Z - 0.2), (x1, BORE_Z - 1.6), (x0, BORE_Z - drop - height), (x0, BORE_Z - drop)]
    m = extrude(poly, width, R=rot_x(math.pi / 2), t=(0, 0, 0))
    return _m(m, name, mat)


def scope(x0=-1.0, length=7.0, r=0.75, z=BORE_Z + 1.7, mat='gun_metal', lens_mat='gun_lens', name='scope'):
    body = tube([(x0, 0, z), (x0 + 1.2, 0, z), (x0 + 1.6, 0, z), (x0 + length - 1.6, 0, z), (x0 + length - 1.2, 0, z),
                 (x0 + length, 0, z)], [r * 1.25, r * 1.25, r, r, r * 1.35, r * 1.35], segs=10)
    lens = cylinder((x0 + length - 0.05, 0, z), (x0 + length + 0.05, 0, z), r * 1.2, segs=10)
    mount = box((2.6, 0.7, 1.0), center=(x0 + length / 2, 0, z - r - 0.35), bevel=0.1)
    return [_m(body, name, mat), _m(lens, name + '_lens', lens_mat), _m(mount, name + '_mount', mat)]


def rail(x0=-1.5, length=6.0, z=BORE_Z + 1.2, mat='gun_metal', name='rail'):
    return _m(box((length, 0.9, 0.35), center=(x0 + length / 2, 0, z), bevel=0.08), name, mat)


def muzzle_brake(x=16.0, r=0.55, length=1.4, z=BORE_Z, mat='gun_metal', name='muzzle'):
    return _m(cylinder((x, 0, z), (x + length, 0, z), r, r * 0.9, segs=8), name, mat)


def front_sight(x=15.0, z=BORE_Z + 0.4, h=1.0, mat='gun_metal', name='fsight'):
    return _m(box((0.35, 0.3, h), center=(x, 0, z + h / 2), bevel=0.0), name, mat)


def trigger_guard(mat='gun_metal', name='tguard'):
    pts = [(0.9, 0, BORE_Z - 1.3), (1.6, 0, BORE_Z - 2.3), (2.6, 0, BORE_Z - 2.4), (3.2, 0, BORE_Z - 1.4)]
    return _m(tube(pts, 0.15, segs=4), name, mat)


def glow_strip(x0, length, z, y=0.78, mat='gun_glow', name='glow', h=0.25):
    out = []
    for sg in (1, -1):
        out.append(_m(box((length, 0.08, h), center=(x0 + length / 2, sg * y, z)), name, mat))
    return out


# ============================================================================================ presets

def gun_preset(kind, style='military', scale=1.0):
    meshes = _gun_preset(kind, style)
    if scale != 1.0:
        for m in meshes:
            m.v = m.v * scale
    for m in meshes:
        if m.mat == 'default':
            m.mat = 'gun_metal'
    return meshes


def _gun_preset(kind, style='military'):
    """Return list of meshes in GUN SPACE for a preset. kinds: ak47, m4, smg, p90, pistol, deagle, shotgun,
    sniper, lmg, knife, grenade, scifi_rifle, scifi_pistol."""
    P = []
    if kind == 'ak47':
        P += [receiver(9.5, 2.5, 1.45, -2.6, mat='gun_metal'),
              handguard(6.9, 5.4, 0.95, mat='gun_wood'),
              barrel(6.5, 11.5, 0.33), muzzle_brake(17.8, 0.45, 1.2), front_sight(17.3),
              _m(tube([(7.2, 0, BORE_Z + 0.55), (13.0, 0, BORE_Z + 0.55)], 0.32, segs=6), 'gastube', 'gun_wood'),
              pistol_grip(3.5, 20, 1.15, 1.5, mat='gun_wood'),
              magazine(2.8, 5.4, 1.05, 1.7, curve=1.6, angle=14, mat='gun_metal'),
              stock(-2.6, 8.0, 2.3, 1.15, 1.0, mat='gun_wood'), trigger_guard()]
        P[-1].name = 'tguard'
    elif kind == 'm4':
        P += [receiver(8.0, 2.7, 1.5, -2.4), handguard(5.6, 6.0, 1.0, mat='gun_poly'), barrel(5.6, 11.5, 0.3),
              muzzle_brake(17.1, 0.4, 1.0), rail(-2.0, 7.0, BORE_Z + 1.25), front_sight(14.5, h=1.4),
              pistol_grip(3.4, 22, 1.15, 1.5), magazine(2.4, 4.6, 1.0, 1.7, curve=0.4, angle=6),
              stock(-2.4, 7.0, 2.6, 1.2, 0.6), trigger_guard()]
    elif kind == 'smg':
        P += [receiver(7.5, 2.4, 1.4, -2.2), barrel(5.3, 4.5, 0.32), handguard(4.5, 3.2, 0.9),
              pistol_grip(3.2, 18, 1.1, 1.4), magazine(2.6, 5.0, 0.9, 1.4, curve=0.6, angle=10),
              stock(-2.2, 5.5, 2.0, 1.0, 0.5), trigger_guard()]
    elif kind == 'p90':
        P += [_m(box((13.0, 2.2, 3.6), center=(3.0, 0, BORE_Z - 0.9), bevel=0.8), 'body', 'gun_poly'),
              _m(box((9.0, 1.6, 0.9), center=(3.5, 0, BORE_Z + 1.3), bevel=0.2), 'mag', 'gun_lens'),
              barrel(9.5, 2.5, 0.35), pistol_grip(3.0, 10, 1.2, 1.4)]
    elif kind in ('pistol', 'deagle'):
        L = 6.2 if kind == 'deagle' else 5.0
        P += [_m(box((L, 1.15 if kind == 'deagle' else 1.0, 1.4), center=(L / 2 - 1.2, 0, BORE_Z - 0.25), bevel=0.15), 'slide', 'gun_metal'),
              _m(box((L * 0.8, 1.0, 0.8), center=(L * 0.4 - 1.1, 0, BORE_Z - 1.3), bevel=0.1), 'frame', 'gun_metal'),
              barrel(L - 1.3, 0.4, 0.28), pistol_grip(3.4, 16, 1.15, 1.6, mat='gun_poly'), trigger_guard()]
        P[-1].transform(None, (-1.0, 0, 0.4))
    elif kind == 'shotgun':
        P += [receiver(7.5, 2.6, 1.5, -2.4), barrel(5.1, 13.0, 0.42), _m(tube([(5.1, 0, BORE_Z - 0.9), (16.0, 0, BORE_Z - 0.9)], 0.4, segs=8), 'tubemag', 'gun_metal'),
              _m(tube([(7.0, 0, BORE_Z - 0.9), (11.5, 0, BORE_Z - 0.9)], 0.75, segs=8), 'pump', 'gun_poly'),
              pistol_grip(3.4, 20, 1.15, 1.5), stock(-2.4, 7.5, 2.4, 1.2, 0.8), trigger_guard()]
    elif kind == 'sniper':
        P += [receiver(9.0, 2.4, 1.4, -2.6), barrel(6.4, 15.0, 0.36, r_end=0.3), handguard(6.0, 6.0, 1.0, mat='gun_poly'),
              pistol_grip(3.4, 18, 1.15, 1.5), magazine(2.0, 2.8, 1.0, 1.8), stock(-2.6, 9.0, 3.0, 1.3, 0.8)]
        P += scope(-1.4, 7.5)
    elif kind == 'lmg':
        P += [receiver(11.0, 3.2, 1.9, -2.8), barrel(8.2, 11.5, 0.45), handguard(7.5, 4.0, 1.25),
              _m(box((3.2, 2.6, 3.0), center=(3.4, -1.6, BORE_Z - 2.4), bevel=0.3), 'mag', 'gun_poly'),
              pistol_grip(3.4, 18, 1.2, 1.6), stock(-2.8, 7.5, 2.8, 1.3, 0.9), trigger_guard(),
              _m(tube([(2.0, 0, BORE_Z + 2.4), (3.5, 0, BORE_Z + 3.2), (6.0, 0, BORE_Z + 3.2), (7.5, 0, BORE_Z + 2.4)], 0.22, segs=5), 'handle', 'gun_metal')]
    elif kind == 'knife':
        blade = extrude([(0.0, -0.5), (9.0, -0.25), (10.5, 0.4), (8.5, 0.55), (0.0, 0.55)], 0.18, R=rot_x(math.pi / 2), t=(2.6, 0, BORE_Z - 0.4))
        P += [_m(blade, 'blade', 'gun_blade'), _m(cylinder((-1.5, 0, BORE_Z - 0.4), (2.6, 0, BORE_Z - 0.4), 0.55, 0.5, segs=8), 'handle', 'gun_poly'),
              _m(box((0.4, 0.6, 2.2), center=(2.6, 0, BORE_Z - 0.4), bevel=0.05), 'guard', 'gun_metal')]
        for m in P:
            m.transform(None, (-1.0, 0, -BORE_Z + 0.4))
    elif kind == 'grenade':
        P += [_m(ellipsoid((1.1, 1.1, 1.4), (1.6, 0, 0.2), segs=10, rings=7), 'body', 'gun_metal'),
              _m(box((0.5, 0.6, 1.3), center=(1.0, 0, 1.8), bevel=0.1), 'lever', 'gun_metal'),
              _m(tube([(1.4, 0.3, 1.9), (1.9, 0.9, 2.1), (2.3, 0.6, 2.3)], 0.08, segs=4), 'pin', 'gun_metal')]
    elif kind == 'scifi_rifle':
        P += [receiver(10.0, 3.0, 1.7, -2.8, mat='gun_poly', bevel=0.5), handguard(6.8, 6.5, 1.2, mat='gun_metal', segs=6),
              barrel(6.5, 11.0, 0.42), _m(cylinder((15.0, 0, BORE_Z), (17.6, 0, BORE_Z), 0.75, 0.55, segs=8), 'emitter', 'gun_metal'),
              pistol_grip(3.4, 20, 1.2, 1.5), magazine(2.4, 3.5, 1.2, 1.9, angle=4, mat='gun_glow'),
              stock(-2.8, 7.5, 2.6, 1.3, 0.7), trigger_guard()]
        P += glow_strip(-1.0, 7.5, BORE_Z + 0.4, y=0.88)
        P += glow_strip(7.2, 5.5, BORE_Z - 0.3, y=1.2)
    elif kind == 'scifi_pistol':
        P += [_m(box((6.0, 1.3, 1.7), center=(1.8, 0, BORE_Z - 0.2), bevel=0.3), 'slide', 'gun_poly'),
              _m(cylinder((4.8, 0, BORE_Z), (6.4, 0, BORE_Z), 0.5, 0.4, segs=8), 'emitter', 'gun_metal'),
              pistol_grip(3.4, 16, 1.2, 1.6, mat='gun_poly'), trigger_guard()]
        P += glow_strip(-0.6, 5.0, BORE_Z + 0.2, y=0.67)
    else:
        raise ValueError(kind)
    return P


GUN_MATERIALS = {
    'gun_metal': {'type': 'metal', 'color': (58, 60, 64), 'scratches': 0.5, 'shine': 0.4, 'edge_wear': 0.9, 'seed': 201},
    'gun_poly': {'type': 'rubber', 'color': (30, 31, 33), 'seed': 202},
    'gun_wood': {'type': 'leather', 'color': (112, 62, 30), 'seed': 203},
    'gun_lens': {'type': 'visor', 'color': (30, 60, 90), 'color2': (180, 220, 255)},
    'gun_glow': {'type': 'glow', 'color': (0, 220, 255), 'color2': (200, 255, 255)},
    'gun_blade': {'type': 'metal', 'color': (170, 175, 185), 'scratches': 0.7, 'shine': 0.8, 'seed': 204},
}

# support-hand distances along the gun X from the grip centre for each preset (keep in sync with HOLDS)
FORE = {'ak47': 9.0, 'm4': 8.5, 'smg': 7.0, 'p90': 6.0, 'shotgun': 10.0, 'sniper': 9.5, 'lmg': 9.5,
        'scifi_rifle': 9.5}


def muzzle_point(meshes):
    """Furthest point along +X near the bore axis (attachment 0)."""
    V = np.vstack([m.v for m in meshes])
    sel = np.abs(V[:, 2] - BORE_Z) < 1.2
    x = V[sel, 0].max() if sel.any() else V[:, 0].max()
    return np.array([x + 0.3, 0.0, BORE_Z])


# ============================================================================================ p_ model

def build_pmodel(name, gun_meshes, out, materials=None, dual=False, tex=(128, 128), preview=True, sequences=('idle',),
                 decals=(), scale=1.0):
    """Compile a p_ model: gun meshes in GUN SPACE -> bound to "Bip01 R Hand" (and mirrored to "Bip01 L Hand"
    when dual=True). Returns report dict."""
    from . import WORK_DIR, PREVIEW_DIR
    from .paint import bake_textures
    from .api import write_textures, _workdir
    from .smd import write_reference, write_animation
    from .qc import QC, Sequence
    from .compile import run_studiomdl
    from .mdl_read import MDL
    from .mdl_opt import dedupe_animations
    mats = dict(GUN_MATERIALS, **(materials or {}))
    wd = _workdir(name)
    bones = [dict(name='Bip01 R Hand', parent=-1)]
    rest = [(np.zeros(3), np.eye(3))]
    meshes = []
    for m in gun_meshes:
        mm = m.copy()
        mm.v = mm.v * scale + GRIP_R
        mm.set_bone(0)
        meshes.append(mm)
    if dual:
        bones.append(dict(name='Bip01 L Hand', parent=-1))
        rest.append((np.zeros(3), np.eye(3)))
        for m in gun_meshes:
            mm = m.copy()
            mm.v = mm.v * scale + GRIP_L
            mm.set_bone(1)
            meshes.append(mm)
    pages = pack_atlas(meshes, tex[0], tex[1], 1, tex_prefix=name[:12] + '_')
    baked = bake_textures(meshes, pages, mats, decals, ao=True, ao_dirs=24, toplight=0.25)
    texnames = write_textures(wd, baked, dither=3.0)
    from .api import uv_span_meshes
    write_reference(os.path.join(wd, 'ref.smd'), bones, rest, uv_span_meshes(pages, 0, GRIP_R) + meshes)
    for s in sequences:
        write_animation(os.path.join(wd, 'a_%s.smd' % s), bones, [rest])
    q = QC(name + '.mdl')
    q.body('weapon', 'ref')
    mz = muzzle_point(gun_meshes) * scale + GRIP_R
    q.attachment(0, 'Bip01 R Hand', mz)
    for s in sequences:
        q.add(Sequence(s, ['a_%s' % s], fps=30, loop=True))
    q.write(os.path.join(wd, name + '.qc'))
    run_studiomdl(wd, name + '.qc', out, extra_args=['-p'])
    m = MDL(out)
    rep = dict(out=out, size=os.path.getsize(out), errors=[], warnings=[],
               stats=dict(bones=m.bone_names, tris=m.tri_count(), textures=[(t['name'], t['width'], t['height']) for t in m.textures]))
    if rep['size'] > 0.08e6:
        rep['warnings'].append('p_ model larger than 80 KB budget')
    if preview:
        rep['previews'] = preview_pmodel(out, os.path.join(PREVIEW_DIR, 'mdlkit', name))
    return rep


def preview_pmodel(path, outbase, player=None, ext='ak47'):
    """Render the gun alone and merged into a player model's hands (if a player model exists), posed with
    the weapon's animation extension `ext` (guns.STANDARD[w]['ext'], e.g. rifle, onehanded, dualpistols)."""
    from . import preview as PV
    from .mdl_read import MDL
    from . import CSTRIKE
    m = MDL(path)
    ims = [PV.render_pose(m, 0, view=v, W=260, H=200, player=False, title=os.path.basename(path) + ' ' + v)
           for v in ('left', 'q', 'top')]
    outs = []
    pl = player or os.path.join(CSTRIKE, 'models/player/vex_operator/vex_operator.mdl')
    if os.path.exists(pl):
        P = MDL(pl)
        for seq, view in (('ref_aim_' + ext, 'q'), ('ref_aim_' + ext, 'left'), ('ref_reload_' + ext, 'q'),
                          ('crouch_aim_' + ext, 'q')):
            if seq in P.seq_by_name:
                frame = 7 if 'reload' in seq else 0
                g = P.seq_by_name['crouch_idle' if 'crouch' in seq else 'idle1']
                ims.append(PV.render_pose(P, seq, frame, (127, 127), g, 0, view=view, W=260, H=300, sub_models=[m],
                                          title='%s %s' % (seq, view)))
        bones = PV.setup_bones(P, P.seq_by_name['ref_aim_' + ext], 0, (127, 127), P.seq_by_name['idle1'], 0)
        hand = bones[P.bone_names.index('Bip01 R Hand')][:, 3]
        for view in ('q', 'left', 'top'):
            ims.append(PV.render_pose(P, 'ref_aim_' + ext, 0, (127, 127), P.seq_by_name['idle1'], 0, view=view, W=260,
                                      H=300, sub_models=[m], center=hand + np.array([5, 4, 0]), dist=45,
                                      title='hands closeup ' + view))
    p = outbase + '_preview.png'
    os.makedirs(os.path.dirname(p), exist_ok=True)
    PV.grid(ims, 4).save(p)
    outs.append(p)
    return outs


def build_pak47_sample():
    from . import CSTRIKE
    out = os.path.join(CSTRIKE, 'models/vexmira/weapons/p_ak47.mdl')
    rep = build_pmodel('p_ak47', gun_preset('ak47'), out, tex=(128, 128))
    print(rep)
    return rep
