"""High-level API: one call = generate meshes + textures + animations, compile, validate, preview.

    from mdlkit.api import build_player_model
    report = build_player_model(spec)          # spec: dict, see README "Character spec"

All builders return a dict report: {'out': path, 'size': bytes, 'errors': [...], 'warnings': [...],
'previews': [png paths], 'stats': {...}}. They raise BuildError if compilation or validation fails
(validation problems that are only warnings are returned in the report).
"""
import os
import shutil
import time
import numpy as np

from . import WORK_DIR, PREVIEW_DIR, CSTRIKE
from .rig_cs import Rig, RigSpec, grip_offset
from .body import build_body, face_anchor
from .geom import pack_atlas, Mesh
from .paint import bake_textures
from .bmp8 import quantize, write_bmp8
from .smd import write_reference
from .qc import QC, Sequence
from .anims import export_sequences, Style
from .compile import run_studiomdl
from .hitbox import compute_hitboxes, hull_fit
from .mdl_read import MDL
from . import validate as V
from . import preview as PV

MAX_VERTS = 2000   # MAXSTUDIOVERTS is 2048 per submodel (compiler + engine); keep a margin


class BuildError(RuntimeError):
    pass


def _workdir(name):
    wd = os.path.join(WORK_DIR, name)
    shutil.rmtree(wd, ignore_errors=True)
    os.makedirs(wd)
    return wd


def split_bodyparts(meshes, max_verts=MAX_VERTS, groups=None):
    """Group meshes into submodels with < max_verts unique vertices each. `groups`: optional explicit
    list of name-prefix lists, e.g. [['torso','arm','leg'], ['head','neck']]."""
    def nverts(ms):
        return sum(len(m.v) for m in ms)
    if groups:
        parts = []
        used = set()
        for g in groups:
            ms = [m for m in meshes if any(m.name.startswith(p) for p in g) and id(m) not in used]
            for m in ms:
                used.add(id(m))
            if ms:
                parts.append(ms)
        rest = [m for m in meshes if id(m) not in used]
        if rest:
            parts.append(rest)
    else:
        parts = [[]]
        for m in sorted(meshes, key=lambda m: -len(m.v)):
            placed = False
            for p in parts:
                if nverts(p) + len(m.v) <= max_verts:
                    p.append(m); placed = True; break
            if not placed:
                parts.append([m])
    for p in parts:
        if nverts(p) > max_verts:
            raise BuildError('submodel exceeds %d vertices (%d) - reduce segments' % (max_verts, nverts(p)))
    return parts


def check_textures_exact(mdl_path, wd):
    """The compiled skins must equal the source BMPs pixel-for-pixel (no crop / shift / resample)."""
    from .bmp8 import read_bmp8
    m = MDL(mdl_path)
    for t in m.textures:
        src = os.path.join(wd, t['name'])
        if not os.path.exists(src):
            continue
        idx, pal = read_bmp8(src)
        if idx.shape != t['pixels'].shape or not np.array_equal(idx, t['pixels']):
            raise BuildError('texture %s was cropped/shifted by studiomdl (%s -> %s)' % (t['name'], idx.shape,
                                                                                       t['pixels'].shape))
        if not np.array_equal(pal, t['palette']):
            raise BuildError('palette of %s changed by studiomdl' % t['name'])


def uv_span_meshes(pages, bone=0, pos=(0, 0, 0)):
    """One tiny hidden triangle per texture page whose UVs cover (0,0)..(1,1).
    studiomdl crops every skin to the UV range actually used and, with -p, mis-aligns the crop vertically
    by (pow2 - used height) rows (ResizeTexture aligns the copy to the bottom edge while the coordinates
    are re-based on the top edge). Spanning the full page makes the crop a no-op, so pages stay exactly
    W x H (power of two) and texel coordinates stay exact."""
    out = []
    p = np.asarray(pos, dtype=np.float64)
    for pg in pages:
        v = np.array([p, p + np.array([0.02, 0, 0]), p + np.array([0, 0, 0.02])])
        m = Mesh(v, np.array([[0, 1, 2]]), np.array([[0, 0], [1, 0], [1, 1.0]]), np.tile([0, -1.0, 0], (3, 1)),
                 bone, 'uvspan', name='uvspan')
        m.texture = pg['name']
        m.atlas_uv = np.array([[0.0, 0.0], [1.0, 0.0], [1.0, 1.0]])
        out.append(m)
    return out


def anchor_bones(parts, rig):
    """studiomdl orders bones by first use across the reference SMDs (model 0 first). If the first
    submodel does not reference every bone, the missing ones are appended at the END of the bone table,
    which breaks the CS gait-merge order. Add a tiny hidden triangle per missing bone to submodel 0."""
    if not parts:
        return
    used = set()
    for m in parts[0]:
        used |= set(int(b) for b in np.unique(m.bone))
    # parents of used bones are kept by studiomdl anyway, but make every bone explicit
    missing = [i for i in range(rig.n) if i not in used]
    if not missing:
        return
    ref = parts[0][0]
    vs, fs, uvs, bs = [], [], [], []
    for b in missing:
        p = rig.rest_world[b]
        base = len(vs)
        vs += [p, p + np.array([0.02, 0, 0]), p + np.array([0, 0.02, 0])]
        uvs += [ref.uv[0]] * 3
        bs += [b] * 3
        fs.append((base, base + 1, base + 2))
    m = Mesh(np.array(vs), np.array(fs), np.array(uvs), np.tile([0, 0, 1.0], (len(vs), 1)), np.array(bs), ref.mat,
             name='anchor')
    m.texture = ref.texture
    m.atlas_uv = np.repeat(ref.atlas_uv[:1], len(vs), axis=0)
    parts[0].insert(0, m)


def write_textures(wd, baked, dither=6.0):
    out = []
    for b in baked:
        idx, pal = quantize(b['rgb'], 256, mask=b.get('mask'), dither=dither)
        write_bmp8(os.path.join(wd, b['name']), idx, pal)
        out.append(b['name'])
    return out


def build_player_model(spec, out=None, preview=True, quick=False, verbose=True):
    """Build a CS player model from a character spec (see characters.py for examples)."""
    t0 = time.time()
    name = spec['name']
    out = out or spec.get('out') or os.path.join(CSTRIKE, 'models', 'player', name, name + '.mdl')
    wd = _workdir(name)
    rs = spec.get('rig')
    if isinstance(rs, dict):
        rs = RigSpec(**rs)
    rig = Rig(rs or RigSpec())
    # ---- geometry
    if 'build' in spec:
        meshes, materials, decals, extra = spec['build'](rig, spec)
    else:
        from .characters import assemble
        meshes, materials, decals, extra = assemble(rig, spec)
    extra = extra or {}
    # ---- textures
    tex = dict(dict(w=512, h=512, pages=1), **spec.get('tex', {}))
    pages = pack_atlas(meshes, tex['w'], tex['h'], tex['pages'], tex_prefix=spec.get('tex_prefix', name[:10] + '_'))
    if len(pages) < tex['pages']:
        pass
    from .rig_cs import ao_pose_matrices
    baked = bake_textures(meshes, pages, materials, decals, ao=not quick, ao_dirs=24 if quick else 48,
                          ao_pose=ao_pose_matrices(rig) if spec.get('ao_spread', True) else None)
    texnames = write_textures(wd, baked, dither=spec.get('dither', 5.0))
    # ---- reference SMDs (split into bodyparts by vertex budget)
    parts = split_bodyparts(meshes, groups=spec.get('bodypart_groups'))
    anchor_bones(parts, rig)
    parts[0] = uv_span_meshes(pages, rig.index['Bip01 Spine1'], rig.J('Bip01 Spine1')) + parts[0]
    q = QC(name + '.mdl')
    bones = rig.bones_for_smd()
    for pi, pm in enumerate(parts):
        ref = 'ref%d' % pi
        write_reference(os.path.join(wd, ref + '.smd'), bones, rig.rest_local(), pm)
        q.body('studio%d' % pi, ref)
    for b in baked:
        if b.get('mask') is not None:
            q.rendermodes.append((b['name'], 'masked'))
    # ---- hitboxes / attachments / eye
    boxes = compute_hitboxes(rig, meshes, spec.get('hitbox_groups'))
    style = spec.get('style', 'human')
    st = style if isinstance(style, Style) else Style(style, **spec.get('style_params', {}))
    if spec.get('hull_fit'):
        from .hitbox import fit_boxes_to_poses
        from .anims import AnimBuilder, YAWS, PITCHES
        boxes = hull_fit(rig, boxes)
        ab = AnimBuilder(rig, st)
        samples = []
        for crouch, zlo, zhi in ((False, -36, 36), (True, -18, 18)):
            for yw in YAWS:
                for pt in PITCHES:
                    if st.kind == 'human':
                        p = ab.human_upper('rifle', 'aim', crouch, yw, pt, 1)[0]
                    else:
                        p = ab.claw_upper('aim', crouch, yw, pt, 1)[0]
                    samples.append((p, zlo, zhi))
        for _ in range(6):   # bone rotations differ per pose -> iterate the vertical re-centring
            boxes = fit_boxes_to_poses(rig, boxes, samples)
    for g, bn, mn, mx in boxes:
        q.hbox(g, bn, mn, mx)
    k = rig.H / 72.0
    att = spec.get('attachment0')
    if att is None:
        att = ('Bip01 R Hand', grip_offset(rig, 'R') + np.array([14.0, 0.0, 2.5]) * min(k, 1.3))
    q.attachment(0, att[0], att[1])
    fa = face_anchor(rig, extra.get('shape', {'head': {}}) if 'shape' in extra else _shape_for(spec))
    q.eye = tuple(np.round((fa['eye_L'] + fa['eye_R']) / 2, 2))
    q.bbox = ((-16, -16, -36), (16, 16, 36))
    q.cbox = ((-16, -16, -36), (16, 16, 36))
    # ---- animations
    nine = spec.get('nine_exts', None if st.kind == 'human' else {'knife'})
    seqs, table = export_sequences(rig, st, wd, nine_exts=nine, events=spec.get('events'))
    for s in seqs:
        q.add(s)
    q.write(os.path.join(wd, name + '.qc'))
    try:
        path, log = run_studiomdl(wd, name + '.qc', out, extra_args=['-p'])
    except Exception as e:
        raise BuildError(str(e))
    from .mdl_opt import dedupe_animations
    saved = dedupe_animations(out)
    check_textures_exact(out, wd)
    # ---- validate + preview
    rep = V.validate_player(out, budget=spec.get('budget'), expect_nine=nine, kind=st.kind,
                            float_h=st.float_h * rig.H / 72.0)
    rep['out'] = out
    rep['stats']['dedupe_saved'] = saved
    rep['build_seconds'] = round(time.time() - t0, 1)
    rep['textures'] = texnames
    if preview:
        rep['previews'] = PV.player_previews(out, os.path.join(PREVIEW_DIR, spec.get('preview_area', 'mdlkit'), name),
                                             human=(st.kind == 'human'))
    if verbose:
        print(V.format_report(rep))
    if rep['errors']:
        raise BuildError('validation failed for %s:\n  %s' % (name, '\n  '.join(rep['errors'])))
    return rep


def _shape_for(spec):
    from .body import _merge_shape
    return _merge_shape(spec.get('shape'))


def preview_textures(spec, out_png=None, views=('front', 'q', 'left', 'qback'), quick=True):
    """Fast look-dev loop: build meshes + bake textures and render the REST pose (no compile)."""
    rs = spec.get('rig')
    if isinstance(rs, dict):
        rs = RigSpec(**rs)
    rig = Rig(rs or RigSpec())
    if 'build' in spec:
        meshes, materials, decals, extra = spec['build'](rig, spec)
    else:
        from .characters import assemble
        meshes, materials, decals, extra = assemble(rig, spec)
    tex = dict(dict(w=512, h=512, pages=1), **spec.get('tex', {}))
    pages = pack_atlas(meshes, tex['w'], tex['h'], tex['pages'], tex_prefix='lookdev_')
    from .rig_cs import ao_pose_matrices
    baked = bake_textures(meshes, pages, materials, decals, ao=not quick, ao_dirs=16 if quick else 48,
                          ao_pose=ao_pose_matrices(rig) if spec.get('ao_spread', True) else None)
    rgbs = []
    for b in baked:
        idx, pal = quantize(b['rgb'], 256, mask=b.get('mask'), dither=spec.get('dither', 5.0))
        rgbs.append(pal[idx])
    hz = (rig.H - 72) / 2
    ims = [PV.render_rest(meshes, v, pages=rgbs, title=v, W=300, H=420, dist=95 * rig.H / 72) for v in views]
    ims += [PV.render_rest(meshes, v, pages=rgbs, title='head ' + v, W=300, H=300, center=(0, 0, 29 + hz * 1.6),
                           dist=26 * rig.H / 72) for v in ('front', 'q', 'left')]
    from PIL import Image
    sheet = PV.grid(ims, 4)
    atlas = [Image.fromarray(r) for r in rgbs]
    if out_png is None:
        out_png = os.path.join(PREVIEW_DIR, spec.get('preview_area', 'mdlkit'), spec['name'] + '_lookdev.png')
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    sheet.save(out_png)
    for i, a in enumerate(atlas):
        a.save(out_png.replace('.png', '_atlas%d.png' % i))
    return out_png, [m.name for m in meshes], sum(len(m.v) for m in meshes)
