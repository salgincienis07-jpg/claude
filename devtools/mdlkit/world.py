"""World models (props): static or animated, named sequences, bodygroups.

    from mdlkit.world import build_world_model, on, Bone
    from mdlkit.geom import box, cylinder
    rep = build_world_model(
        'supply_crate',
        bones=[Bone('root'), Bone('chute', 'root', (0, 0, 20))],
        parts=[box((24, 24, 20), center=(0, 0, 10), mat='wood')],          # bodypart 0 "body" (root bone)
        bodygroups=[('parachute', [None, on('chute', canopy_meshes)])],    # body value 0 = no chute, 1 = chute
        sequences=[dict(name='idle', frames=1),
                   dict(name='fall', frames=31, fps=15, loop=True,
                        pose=lambda t: {'chute': dict(rot=(0, 0, 8 * math.sin(2 * math.pi * t)))})],
        materials={'wood': {...}, 'cloth': {...}},
        out='cstrike/models/vexmira/world/supply_crate.mdl')

Conventions
  * Model space = engine space (+X forward, +Y left, +Z up). A prop placed with entity origin on the
    floor should have its base at z = 0 (models are drawn at the entity origin).
  * Bones: list of Bone(name, parent=None, pos=(x,y,z)) with rest WORLD positions, identity rest
    rotation. Default = a single bone 'root' at the origin. Meshes bind to bones with on(bone, meshes)
    (sets mesh.bone_name); meshes without bone_name bind to the first bone. Every bone gets a hidden
    0.02-unit anchor triangle so studiomdl never drops an animated bone without geometry.
  * Sequences: dicts {name, frames=1, fps=10, loop=False, pose=fn(t)->{bone: dict(pos=(dx,dy,dz),
    rot=(yaw,pitch,roll) degrees | R=3x3 matrix)}, events=[(id, frame, options)], activity='ACT_IDLE'} -
    offsets are LOCAL to the bone's parent and relative to the rest pose (rotation about the bone's own
    pivot = its rest position); t runs 0..1 over the sequence. anims.ypr: yaw + = turn left (about Z),
    pitch + = nose DOWN (+Z tips toward +X), roll + = left side up (about X).
    GoldSrc bones cannot scale: hide parts by moving them inside other geometry or use bodygroups.
  * Bodygroups: list of (name, [variant, ...]) where a variant is None (blank) or a list of meshes.
    pev->body = sum(variant_index * base); base = product of the variant counts of earlier groups
    (bodypart 0 "body" has one variant). world_body_value(bodygroups, {'parachute': 1}) computes it.
  * Textures: one or more pages (tex=(w,h), pages=n), painted with paint.py materials; missing
    materials are an ERROR (no magenta). Materials with 'masked' get $texrendermode masked; pass
    rendermodes={'page index': 'additive'} to make a whole page additive (e.g. a glow sprite page).
"""
import math
import os
import numpy as np

from . import PREVIEW_DIR, WORK_DIR, CSTRIKE
from .geom import Mesh, pack_atlas


class Bone(dict):
    def __init__(self, name, parent=None, pos=(0.0, 0.0, 0.0)):
        super().__init__(name=name, parent=parent, pos=tuple(float(x) for x in pos))


def on(bone, *meshes):
    """Bind meshes (or lists of meshes) to a bone by name. Returns a flat list."""
    out = []
    for m in meshes:
        if isinstance(m, (list, tuple)):
            out += on(bone, *m)
        else:
            m.bone_name = bone
            out.append(m)
    return out


def world_body_value(bodygroups, choice):
    """pev->body value for {group_name: variant_index}."""
    base = 1
    val = 0
    for name, variants in bodygroups or []:
        val += choice.get(name, 0) * base
        base *= len(variants)
    return val


def _ypr(yaw=0.0, pitch=0.0, roll=0.0):
    from .anims import ypr
    return ypr(yaw, pitch, roll)


class _WorldRig:
    def __init__(self, bones):
        self.names = [b['name'] for b in bones]
        self.index = {n: i for i, n in enumerate(self.names)}
        if len(self.index) != len(self.names):
            raise ValueError('duplicate bone names')
        self.parents = []
        for b in bones:
            p = b.get('parent')
            if p is not None and p not in self.index:
                raise ValueError('bone %s: unknown parent %s' % (b['name'], p))
            if p is not None and self.index[p] >= self.index[b['name']]:
                raise ValueError('bone %s must come after its parent %s' % (b['name'], p))
            self.parents.append(-1 if p is None else self.index[p])
        self.world = np.array([np.asarray(b.get('pos', (0, 0, 0)), float) for b in bones])
        self.local = np.array([self.world[i] - (self.world[p] if p >= 0 else 0) for i, p in enumerate(self.parents)])

    def smd_bones(self):
        return [dict(name=n, parent=p) for n, p in zip(self.names, self.parents)]

    def rest_local(self):
        return [(self.local[i], np.eye(3)) for i in range(len(self.names))]

    def frame(self, offsets):
        fr = []
        for i, n in enumerate(self.names):
            o = offsets.get(n, {}) if offsets else {}
            pos = self.local[i] + np.asarray(o.get('pos', (0, 0, 0)), float)
            R = np.asarray(o['R'], float) if 'R' in o else _ypr(*o.get('rot', (0, 0, 0)))
            fr.append((pos, R))
        return fr

    def world_mats(self, offsets):
        fr = self.frame(offsets)
        out = []
        for i, (p, R) in enumerate(fr):
            par = self.parents[i]
            if par < 0:
                out.append((R, p))
            else:
                PR, Pt = out[par]
                out.append((PR @ R, PR @ p + Pt))
        return out


def _flat(meshes):
    out = []
    for m in meshes:
        if isinstance(m, (list, tuple)):
            out += _flat(m)
        elif m is not None:
            out.append(m)
    return out


def _bind(meshes, rig):
    res = []
    for m in _flat(meshes):
        mm = m.copy()
        for attr in ('bone_name', 'no_hitbox'):
            if hasattr(m, attr):
                setattr(mm, attr, getattr(m, attr))
        mm.texture, mm.atlas_uv, mm.island = m.texture, m.atlas_uv, m.island
        bn = getattr(m, 'bone_name', None)
        if bn is not None:
            if bn not in rig.index:
                raise ValueError('mesh %s bound to unknown bone %s' % (m.name, bn))
            mm.set_bone(rig.index[bn])
        elif int(m.bone.max()) >= len(rig.names):
            mm.set_bone(0)
        res.append(mm)
    return res


def _anchors(rig, ref):
    vs, fs, bs = [], [], []
    for i in range(len(rig.names)):
        p = rig.world[i]
        b0 = len(vs)
        vs += [p, p + np.array([0.02, 0, 0]), p + np.array([0, 0.02, 0])]
        bs += [i] * 3
        fs.append((b0, b0 + 1, b0 + 2))
    m = Mesh(np.array(vs), np.array(fs), np.tile(ref.uv[0], (len(vs), 1)), np.tile([0, 0, 1.0], (len(vs), 1)),
             np.array(bs), ref.mat, name='anchor')
    m.texture = ref.texture
    m.atlas_uv = np.repeat(ref.atlas_uv[:1], len(vs), axis=0)
    return m


def build_world_model(name, parts, sequences=None, out=None, bones=None, bodygroups=None, materials=None,
                      decals=(), tex=(256, 256), pages=1, budget=0.25e6, preview=True, attachments=(),
                      rendermodes=None, preview_area='mdlkit', ao=True, toplight=0.22, dither=4.0, verbose=True,
                      eye=(0, 0, 0), controllers=()):
    """Compile a world/prop model. Returns a report dict (raises RuntimeError on errors).
    parts: meshes of the always-visible body (bodypart 0 "body"). See module doc for the rest."""
    import time
    from .api import _workdir, write_textures, uv_span_meshes, MAX_VERTS, split_bodyparts
    from .paint import bake_textures
    from .smd import write_reference, write_animation
    from .qc import QC, Sequence
    from .compile import run_studiomdl
    from .mdl_opt import dedupe_animations
    t0 = time.time()
    rig = _WorldRig(bones or [Bone('root')])
    body = _bind(list(parts), rig)
    groups = []
    for gname, variants in bodygroups or []:
        vv = []
        for var in variants:
            vv.append(None if var is None else _bind(list(var) if isinstance(var, (list, tuple)) else [var], rig))
        groups.append((gname, vv))
    allm = body + [m for _, vv in groups for var in vv if var for m in var]
    if not allm:
        raise ValueError('world model %s has no geometry' % name)
    mats = dict(materials or {})
    missing = sorted(set(m.mat for m in allm) - set(mats))
    if missing:
        raise RuntimeError('%s: no material for %s (add them to materials=)' % (name, missing))
    out = out or os.path.join(CSTRIKE, 'models/vexmira/world', name + '.mdl')
    wd = _workdir(name)
    pg = pack_atlas(allm, tex[0], tex[1], pages, tex_prefix=name[:12] + '_')
    baked = bake_textures(allm, pg, mats, list(decals), ao=ao, ao_dirs=24, toplight=toplight, ao_slope_bias=1.5)
    texnames = write_textures(wd, baked, dither=dither)
    smd_bones = rig.smd_bones()
    rest = rig.rest_local()
    q = QC(name + '.mdl')
    q.eye = tuple(eye)
    body_parts = split_bodyparts(body, MAX_VERTS)
    body_parts[0] = uv_span_meshes(pg, 0, rig.world[0]) + [_anchors(rig, body_parts[0][0])] + body_parts[0]
    for pi, pm in enumerate(body_parts):
        fn = 'body%d' % pi
        write_reference(os.path.join(wd, fn + '.smd'), smd_bones, rest, pm)
        q.body('body' if pi == 0 else 'body%d' % pi, fn)
    for gi, (gname, vv) in enumerate(groups):
        names = []
        for vi, var in enumerate(vv):
            if var is None:
                names.append(None)
                continue
            if sum(len(m.v) for m in var) > MAX_VERTS:
                raise RuntimeError('bodygroup %s variant %d exceeds %d vertices' % (gname, vi, MAX_VERTS))
            fn = 'g%d_%d' % (gi, vi)
            write_reference(os.path.join(wd, fn + '.smd'), smd_bones, rest, var)
            names.append(fn)
        q.bodygroup(gname, names)
    for b in baked:
        if b.get('mask') is not None:
            q.rendermodes.append((b['name'], 'masked'))
    for k, mode in (rendermodes or {}).items():
        q.rendermodes.append((pg[int(k)]['name'], mode))
    for i, (bn, pos) in enumerate(attachments):
        q.attachment(i, bn, pos)
    # bone controllers: (index 0-3, bone, 'X'|'Y'|'Z'|'XR'|'YR'|'ZR', start, end); translation types move
    # the bone in its parent space (root: model space), set at run time with pev->controller[index]
    for ci, bn, typ, c0, c1 in controllers:
        q.extra.append('$controller %d "%s" %s %g %g' % (ci, bn, typ, c0, c1))
    seqs = sequences or [dict(name='idle', frames=1)]
    for sd in seqs:
        n = int(sd.get('frames', 1))
        fn_pose = sd.get('pose')
        frames = []
        for f in range(n):
            t = f / max(n - 1, 1)
            frames.append(rig.frame(fn_pose(t) if fn_pose else None))
        fn = 'a_' + sd['name']
        write_animation(os.path.join(wd, fn + '.smd'), smd_bones, frames)
        q.add(Sequence(sd['name'], [fn], fps=sd.get('fps', 10.0), loop=sd.get('loop', False),
                       activity=sd.get('activity'), events=sd.get('events')))
    q.write(os.path.join(wd, name + '.qc'))
    run_studiomdl(wd, name + '.qc', out, extra_args=['-p'])
    dedupe_animations(out)
    rep = validate_world(out, [s['name'] for s in seqs], budget=budget,
                         groups=[('body', 1)] * len(body_parts) + [(g, len(v)) for g, v in groups])
    rep['textures'] = texnames
    rep['build_seconds'] = round(time.time() - t0, 1)
    if preview:
        rep['previews'] = preview_world(out, os.path.join(PREVIEW_DIR, preview_area, name))
    if verbose:
        from .vmodel import _fmt
        print(_fmt(rep))
    if rep['errors']:
        raise RuntimeError('validation failed for %s:\n  %s' % (name, '\n  '.join(rep['errors'])))
    return rep


def validate_world(path, seq_names=None, budget=0.25e6, groups=None):
    """Generic checks for props / w_ models: parse, size, sequence names, bodypart layout, textures,
    vertex limits, winding."""
    from .mdl_read import MDL
    from .validate import check_winding
    m = MDL(path)
    E, W = [], []
    size = os.path.getsize(path)
    if budget and size > budget:
        E.append('size %d > budget %d' % (size, budget))
    names = [s['label'] for s in m.seqs]
    if seq_names is not None and names != list(seq_names):
        E.append('sequences %s != %s' % (names, list(seq_names)))
    if groups is not None:
        got = [(bp['name'], bp['nummodels']) for bp in m.bodyparts]
        if [g[1] for g in got] != [g[1] for g in groups]:
            E.append('bodyparts %s != expected %s' % (got, groups))
    for t in m.textures:
        w, h = t['width'], t['height']
        if w > 512 or h > 512 or (w & (w - 1)) or (h & (h - 1)):
            E.append('texture %s %dx%d not power of two <= 512' % (t['name'], w, h))
    for bp in m.bodyparts:
        for mod in bp['models']:
            if mod['numverts'] >= 2048 or mod['numnorms'] >= 2048:
                E.append('submodel %s/%s has %d verts' % (bp['name'], mod['name'], mod['numverts']))
    if m.numseqgroups != 1:
        E.append('model uses %d sequence groups (must be 1)' % m.numseqgroups)
    bad, tot = check_winding(m)
    if tot and bad > 0.02 * tot:
        W.append('winding: %d/%d triangles look inverted' % (bad, tot))
    return dict(out=path, errors=E, warnings=W,
                stats=dict(size=size, seqs=names, bones=m.bone_names, tris=m.tri_count(),
                           bodyparts=[(bp['name'], bp['nummodels']) for bp in m.bodyparts],
                           textures=[(t['name'], t['width'], t['height']) for t in m.textures],
                           winding_bad='%d/%d' % (bad, tot)))


def preview_world(path, outbase, views=('q', 'left', 'front', 'top'), frames_per_seq=4):
    """Sheet: rest views (all bodygroup variants switched on), then every sequence at a few frames,
    then each bodygroup variant on its own."""
    from .mdl_read import MDL
    from . import preview as PV
    m = MDL(path)
    # body value with the LAST variant of every group (usually the 'on' state)
    full = 0
    for bp in m.bodyparts:
        full += (bp['nummodels'] - 1) * bp['base']
    # common framing from the rest pose of every sequence frame 0 with everything on
    pts = []
    for s in m.seqs:
        for f in np.linspace(0, max(s['numframes'] - 1.001, 0), min(3, s['numframes'])):
            b = PV.setup_bones(m, s['index'], f, player=False)
            tris = PV.posed_triangles(m, b, full)
            if tris:
                pts.append(np.vstack([t['pos'].reshape(-1, 3) for t in tris]))
    P = np.vstack(pts)
    lo, hi = np.percentile(P, 0.5, axis=0), np.percentile(P, 99.5, axis=0)
    c = (lo + hi) / 2
    ext = float(np.max(hi - lo))
    dist = max(18.0, ext * 2.2)
    ims = []
    for v in views:
        ims.append(PV.render_pose(m, 0, 0, view=v, W=260, H=220, player=False, body=full, center=c, dist=dist,
                                  title='%s %s' % (os.path.basename(path), v)))
    for s in m.seqs:
        n = s['numframes']
        frs = sorted(set(int(round(x)) for x in np.linspace(0, n - 1, min(frames_per_seq, n))))
        for f in frs:
            ims.append(PV.render_pose(m, s['index'], float(min(f, n - 1.001)), view='q', W=260, H=220, player=False,
                                      body=full, center=c, dist=dist, title='%s f%d' % (s['label'], f)))
    for bp in m.bodyparts:
        if bp['nummodels'] < 2:
            continue
        for vi in range(bp['nummodels']):
            body = full - (bp['nummodels'] - 1) * bp['base'] + vi * bp['base']
            ims.append(PV.render_pose(m, 0, 0, view='q', W=260, H=220, player=False, body=body, center=c, dist=dist,
                                      title='%s=%d (body %d)' % (bp['name'], vi, body)))
    p = outbase + '_world.png'
    os.makedirs(os.path.dirname(p), exist_ok=True)
    PV.grid(ims, 4).save(p)
    return [p]
