"""Character assembly: body + accessories + materials + decals from a spec dict.

spec keys used here:
  shape        body.DEFAULT_SHAPE overrides
  mats         part -> material name for the body (torso, neck, head, arm, hand, leg, foot, claw)
  materials    material name -> paint.py material dict
  accessories  list of (accessory_name, params dict) from accessories.ACCESSORIES (or (callable, params):
               fn(rig, sh, **params) -> list of Mesh, for one-off custom parts)
  decals       list of paint decal dicts (3D, rest pose)
  face         dict for the automatic face decals (eyes/mouth/brows), see face_decals()
"""
import numpy as np

from .body import build_body, face_anchor
from . import accessories as ACC


def face_decals(rig, sh, face):
    """Eyes, brows, mouth painted on the head material (rest pose 3D decals)."""
    fa = face_anchor(rig, sh)
    k = fa['k']
    f = dict(dict(eye='human', eye_color=(70, 110, 140), glow=None, brow_color=(60, 45, 35), lips=(150, 90, 85),
                  mouth='closed', teeth=(220, 210, 180), eye_size=1.0, dark_sockets=0.0, target='head',
                  brow_shadow=0.4, cheeks=(205, 120, 110), cheek_amount=0.18, hair=None, stubble=0.0), **(face or {}))
    D = []
    tgt = f['target']
    es = f['eye_size']
    c = fa['center']; rx, ry, rz = fa['radii']
    if f['brow_shadow']:
        D.append(dict(kind='sphere', center=(fa['eye_L'] + fa['eye_R']) / 2 + np.array([0.2, 0, 0.35]) * k, radius=2.6 * k,
                      scale=(1.0, 1.25, 0.32), soft=0.8, color=(90, 70, 65), mode='multiply', alpha=f['brow_shadow'],
                      target=tgt))
    if f['cheek_amount'] and f['eye'] == 'human':
        for side in ('eye_L', 'eye_R'):
            D.append(dict(kind='sphere', center=fa[side] + np.array([0.0, 0, -1.6]) * k, radius=1.5 * k, soft=0.9,
                          color=f['cheeks'], alpha=f['cheek_amount'], target=tgt))
    if f['hair'] is not None:
        # hairline at the temples / sideburns / nape (visible under helmets and caps)
        for sg in (1, -1):
            D.append(dict(kind='sphere', center=c + np.array([0.2 * rx, sg * ry * 0.95, 0.15 * rz]), radius=1.4 * k,
                          scale=(1.0, 0.5, 1.6), soft=0.5, color=f['hair'], alpha=0.9, target=tgt))
        D.append(dict(kind='sphere', center=c + np.array([-rx * 0.95, 0, -0.1 * rz]), radius=3.2 * k, scale=(0.5, 1.0, 0.8),
                      soft=0.5, color=f['hair'], alpha=0.9, target=tgt))
        D.append(dict(kind='sphere', center=c + np.array([0, 0, rz * 0.95]), radius=rx * 1.15, scale=(1.0, 1.0, 0.55),
                      soft=0.3, color=f['hair'], alpha=0.95, target=tgt))
    if f['stubble']:
        D.append(dict(kind='sphere', center=fa['mouth'] + np.array([-0.8, 0, -0.8]) * k, radius=3.4 * k,
                      scale=(0.8, 1.2, 0.75), soft=0.7, color=(110, 95, 85), mode='multiply', alpha=f['stubble'],
                      target=tgt))
    for side in ('eye_L', 'eye_R'):
        c = fa[side]
        if f['dark_sockets']:
            D.append(dict(kind='sphere', center=c + np.array([0.3, 0, 0.1]) * k, radius=1.35 * k * es,
                          scale=(1.0, 1.0, 0.75), soft=0.6, color=(30, 15, 20), mode='multiply', alpha=f['dark_sockets'],
                          target=tgt))
        if f['eye'] == 'human':
            D.append(dict(kind='sphere', center=c + np.array([0.15, 0, 0]) * k, radius=0.62 * k * es,
                          scale=(1, 1.0, 0.55), soft=0.25, color=(235, 232, 225), target=tgt))
            D.append(dict(kind='sphere', center=c + np.array([0.35, 0, 0]) * k, radius=0.3 * k * es, scale=(1, 1, 1),
                          soft=0.3, color=f['eye_color'], target=tgt))
            D.append(dict(kind='sphere', center=c + np.array([0.4, 0, 0]) * k, radius=0.14 * k * es, soft=0.3,
                          color=(10, 10, 12), target=tgt))
            # upper lid shadow
            D.append(dict(kind='sphere', center=c + np.array([0.2, 0, 0.42]) * k, radius=0.7 * k * es,
                          scale=(1, 1, 0.35), soft=0.5, color=(70, 50, 45), mode='multiply', alpha=0.6, target=tgt))
        elif f['eye'] in ('glow', 'dead'):
            col = f['glow'] if f['eye'] == 'glow' else (200, 200, 170)
            D.append(dict(kind='sphere', center=c + np.array([0.2, 0, 0]) * k, radius=0.68 * k * es,
                          scale=(1, 1.0, 0.6), soft=0.35, color=(255, 255, 230) if f['eye'] == 'glow' else col,
                          color2=col, mode='glow' if f['eye'] == 'glow' else 'paint', target=tgt))
            D.append(dict(kind='sphere', center=c + np.array([0.4, 0, 0]) * k, radius=0.22 * k * es, soft=0.4,
                          color=(255, 255, 255) if f['eye'] == 'glow' else (60, 50, 40), mode='glow' if f['eye'] == 'glow' else 'paint',
                          target=tgt))
        # brow
        if f['brow_color'] is not None:
            D.append(dict(kind='sphere', center=c + np.array([0.15, 0, 0.95]) * k, radius=0.85 * k, scale=(1, 1.0, 0.28),
                          soft=0.5, color=f['brow_color'], alpha=0.85, target=tgt))
    m = fa['mouth']
    if f['mouth'] == 'closed':
        D.append(dict(kind='sphere', center=m + np.array([0.1, 0, 0.25]) * k, radius=1.05 * k, scale=(1, 1, 0.3),
                      soft=0.6, color=f['lips'], alpha=0.55, target=tgt))
        D.append(dict(kind='sphere', center=m + np.array([0.1, 0, -0.35]) * k, radius=0.95 * k, scale=(1, 1, 0.32),
                      soft=0.6, color=f['lips'], alpha=0.6, target=tgt))
        D.append(dict(kind='sphere', center=m + np.array([0.1, 0, 0.0]) * k, radius=1.1 * k, scale=(1, 1, 0.13),
                      soft=0.5, color=(60, 30, 30), alpha=0.9, target=tgt))
    elif f['mouth'] in ('open', 'snarl'):
        D.append(dict(kind='sphere', center=m + np.array([0.0, 0, -0.2]) * k, radius=1.35 * k, scale=(1, 1, 0.55),
                      soft=0.3, color=(25, 5, 5), target=tgt))
        # teeth rows
        for zoff in (0.35, -0.75):
            D.append(dict(kind='sphere', center=m + np.array([0.3, 0, zoff]) * k, radius=1.15 * k, scale=(1, 1, 0.16),
                          soft=0.25, color=f['teeth'], target=tgt))
    return D


def assemble(rig, spec):
    shape = spec.get('shape')
    meshes, sh = build_body(rig, shape, spec.get('mats'))
    mats_in = spec.get('materials', {})
    materials = dict(mats_in(rig, sh) if callable(mats_in) else mats_in)
    dec_in = spec.get('decals', [])
    decals = list(dec_in(rig, sh) if callable(dec_in) else dec_in)
    accs = spec.get('accessories', [])
    if callable(accs):
        accs = accs(rig, sh)
    for acc in accs:
        name, params = (acc, {}) if isinstance(acc, str) or callable(acc) else acc
        # custom accessory: a callable fn(rig, sh, **params) -> [Mesh, ...] (content modules)
        fn = name if callable(name) else ACC.ACCESSORIES[name]
        res = fn(rig, sh, **params)
        meshes += res
    if spec.get('face', True) is not False:
        decals = face_decals(rig, sh, spec.get('face') if isinstance(spec.get('face'), dict) else None) + decals
    # default materials for anything missing
    for m in meshes:
        if m.mat not in materials:
            materials[m.mat] = {'type': 'flat', 'color': (180, 180, 180)}
    return meshes, materials, decals, {'shape': sh}
