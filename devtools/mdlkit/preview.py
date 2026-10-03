"""Software renderer for COMPILED .mdl files, reproducing the engine/client bone setup.

Bone setup ports (exact logic, see comments):
  * cs16client cl_dll/StudioModelRenderer.cpp  StudioCalcRotations / StudioSlerpBones / StudioEstimateFrame
  * cs16client cl_dll/GameStudioModelRenderer.cpp StudioSetupBones (players): walk-sequence yaw hack
    (gaitsequence==3 -> blending[0]-=26), 9-way blend selection, gait merge loop over bone names, root
    transform.
  * blend values: CalculateYawBlend / StudioPlayerBlend helpers are provided (yaw_blend(), pitch_blend()).

Rendering: perspective camera, z-buffer, nearest texel sampling at (s/W, t/H) exactly like the GL path,
GoldSrc-like lambert wrap lighting (r_studio lambert 1.5), engine back-face culling (studiomdl stores
triangles clockwise-from-outside; GL culls GL_FRONT with CCW front faces).
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

from .mdl_read import MDL
from .mathx import (quaternion_slerp_v, quaternion_matrix_v, entity_matrix)
from .raster import raster

ANIM_WALK_SEQUENCE = 3
ANIM_JUMP_SEQUENCE = 6
ANIM_SWIM_1 = 8
ANIM_SWIM_2 = 9
ANIM_FIRST_DEATH_SEQUENCE = 101
ANIM_LAST_DEATH_SEQUENCE = 159
ANIM_FIRST_EMOTION_SEQUENCE = 198
ANIM_LAST_EMOTION_SEQUENCE = 207


# ------------------------------------------------------------------------------------- blend helpers

def yaw_blend(view_minus_gait_deg):
    """CalculateYawBlend: flYaw = entity yaw - gaityaw (+ = looking LEFT of the legs) -> blending[0]."""
    fl = math.fmod(view_minus_gait_deg, 360.0)
    if fl < -180: fl += 360
    elif fl > 180: fl -= 360
    b = (fl / 90.0) * 128.0 + 127.0
    b = 255.0 - max(0.0, min(255.0, b))
    return int(b)


def pitch_blend(view_pitch_deg):
    """StudioPlayerBlend: entity pitch = -v_angle.x/3 (v_angle.x > 0 = looking DOWN) -> blending[1]."""
    pitch = -view_pitch_deg / 3.0
    rng = 45.0
    b = pitch * 3
    if b <= -rng:
        return 255
    if b >= rng:
        return 0
    return int(255 * (rng - b) / (2 * rng))


def estimate_frame(seq, frame256):
    """StudioEstimateFrame without interpolation: curstate.frame (0..255) -> float frame."""
    nf = seq['numframes']
    if nf <= 1:
        return 0.0
    f = frame256 * (nf - 1) / 256.0
    if seq['flags'] & 1:
        f -= int(f / (nf - 1)) * (nf - 1)
        if f < 0:
            f += nf - 1
    else:
        if f >= nf - 1.001:
            f = nf - 1.001
        if f < 0:
            f = 0.0
    return f


# ------------------------------------------------------------------------------------- bone setup

def _slerp_bones(q1, p1, q2, p2, s):
    s = min(max(s, 0.0), 1.0)
    q = quaternion_slerp_v(q1, q2, s)
    p = p1 * (1 - s) + p2 * s
    return q, p


def calc_blended(m, seq_index, f, blending=(127, 127)):
    """Rotations for a sequence with the client's numblends==9 logic (or plain 2-blend / single)."""
    s_desc = m.seqs[seq_index]
    nbl = s_desc['numblends']
    if nbl == 9:
        s = float(blending[0]); t = float(blending[1])
        if s <= 127.0:
            s = s * 2.0
            if t <= 127.0:
                t = t * 2.0; ids = (0, 1, 3, 4)
            else:
                t = 2.0 * (t - 127.0); ids = (3, 4, 6, 7)
        else:
            s = 2.0 * (s - 127.0)
            if t <= 127.0:
                t = t * 2.0; ids = (1, 2, 4, 5)
            else:
                t = 2.0 * (t - 127.0); ids = (4, 5, 7, 8)
        p1, q1 = m.calc_rotations(seq_index, f, ids[0])
        p2, q2 = m.calc_rotations(seq_index, f, ids[1])
        p3, q3 = m.calc_rotations(seq_index, f, ids[2])
        p4, q4 = m.calc_rotations(seq_index, f, ids[3])
        s /= 255.0; t /= 255.0
        q1, p1 = _slerp_bones(q1, p1, q2, p2, s)
        q3, p3 = _slerp_bones(q3, p3, q4, p4, s)
        q1, p1 = _slerp_bones(q1, p1, q3, p3, t)
        return p1, q1
    p, q = m.calc_rotations(seq_index, f, 0)
    if nbl > 1:
        p2, q2 = m.calc_rotations(seq_index, f, 1)
        q, p = _slerp_bones(q, p, q2, p2, blending[0] / 255.0)
    return p, q


def setup_bones(m, seq_index, frame=0.0, blending=(127, 127), gaitseq=None, gaitframe=0.0, player=True,
                yaw_deg=0.0, origin=(0, 0, 0), frame_is_float=True):
    """CGameStudioModelRenderer::StudioSetupBones. Returns (nb,3,4) bone->world transforms.
    frame: float frame index into the sequence (frame_is_float) or curstate.frame 0..255."""
    if seq_index >= m.numseq:
        seq_index = 0
    sd = m.seqs[seq_index]
    f = frame if frame_is_float else estimate_frame(sd, frame)
    blending = list(blending)
    if player and gaitseq == ANIM_WALK_SEQUENCE:
        blending[0] = 0 if blending[0] <= 26 else blending[0] - 26
    if player:
        pos, q = calc_blended(m, seq_index, f, blending)
    else:
        pos, q = calc_blended(m, seq_index, f, blending) if sd['numblends'] != 9 else m.calc_rotations(seq_index, f, 0)
    if (player and gaitseq is not None and
            (seq_index < ANIM_FIRST_DEATH_SEQUENCE or seq_index > ANIM_LAST_DEATH_SEQUENCE) and
            (seq_index < ANIM_FIRST_EMOTION_SEQUENCE or seq_index > ANIM_LAST_EMOTION_SEQUENCE) and
            seq_index != ANIM_SWIM_1 and seq_index != ANIM_SWIM_2):
        g = gaitseq if gaitseq < m.numseq else 0
        pos2, q2 = m.calc_rotations(g, gaitframe, 0)
        copy = True
        names = m.bone_names
        for i in range(m.numbones):
            par = m.parents[i]
            if names[i] == 'Bip01 Spine':
                copy = False
            elif par >= 0 and names[par] == 'Bip01 Pelvis':
                copy = True
            if copy:
                pos[i] = pos2[i]
                q[i] = q2[i]
    R = quaternion_matrix_v(q)
    root = entity_matrix(yaw_deg, 0, 0, origin)
    out = np.zeros((m.numbones, 3, 4))
    for i in range(m.numbones):
        bm = np.zeros((3, 4)); bm[:, :3] = R[i]; bm[:, 3] = pos[i]
        par = m.parents[i]
        base = root if par == -1 else out[par]
        out[i, :, :3] = base[:, :3] @ bm[:, :3]
        out[i, :, 3] = base[:, :3] @ bm[:, 3] + base[:, 3]
    return out


def merge_bones(sub, parent_mdl, parent_bones, seq_index=0, frame=0.0, yaw_deg=0.0, origin=(0, 0, 0)):
    """StudioMergeBones: bones of `sub` whose name matches a parent bone take the parent's transform."""
    pos, q = sub.calc_rotations(min(seq_index, sub.numseq - 1), 0.0, 0)
    R = quaternion_matrix_v(q)
    names = {n.lower(): i for i, n in enumerate(parent_mdl.bone_names)}
    root = entity_matrix(yaw_deg, 0, 0, origin)
    out = np.zeros((sub.numbones, 3, 4))
    for i in range(sub.numbones):
        j = names.get(sub.bone_names[i].lower())
        if j is not None:
            out[i] = parent_bones[j]
            continue
        bm = np.zeros((3, 4)); bm[:, :3] = R[i]; bm[:, 3] = pos[i]
        par = sub.parents[i]
        base = root if par == -1 else out[par]
        out[i, :, :3] = base[:, :3] @ bm[:, :3]
        out[i, :, 3] = base[:, :3] @ bm[:, 3] + base[:, 3]
    return out


# ------------------------------------------------------------------------------------- geometry

def posed_triangles(m, bones, body=0, skin=0):
    """Return list of per-mesh dicts with world tri positions, normals, s/t, texture index."""
    out = []
    for bp in m.bodyparts:
        if not bp['models']:
            continue
        mi = (body // max(bp['base'], 1)) % bp['nummodels']
        mod = bp['models'][mi]
        if mod['numverts'] == 0:
            continue
        vb = mod['vert_bone']; nbn = mod['norm_bone']
        Rv = bones[vb, :, :3]; tv = bones[vb, :, 3]
        wv = np.einsum('nij,nj->ni', Rv, mod['verts']) + tv
        Rn = bones[nbn, :, :3]
        wn = np.einsum('nij,nj->ni', Rn, mod['norms'])
        for me in mod['meshes']:
            if not me['tris']:
                continue
            t = np.array(me['tris'])  # (ntri, 3, 4)
            tex = me['skinref']
            if m.skinref is not None and skin < m.skinref.shape[0] and tex < m.skinref.shape[1]:
                tex = int(m.skinref[skin, tex])
            out.append(dict(pos=wv[t[:, :, 0]], nrm=wn[t[:, :, 1]], st=t[:, :, 2:4].astype(np.float64), tex=tex))
    return out


class Camera:
    def __init__(self, eye, target, fov_deg=40.0, W=320, H=320, up=(0, 0, 1), ortho=None):
        self.eye = np.asarray(eye, float)
        self.target = np.asarray(target, float)
        f = self.target - self.eye
        f /= np.linalg.norm(f)
        r = np.cross(f, np.asarray(up, float))
        if np.linalg.norm(r) < 1e-6:
            r = np.cross(f, np.array([1.0, 0, 0]))
        r /= np.linalg.norm(r)
        u = np.cross(r, f)
        self.f, self.r, self.u = f, r, u
        self.W, self.H = W, H
        self.fov = fov_deg
        self.ortho = ortho
        self.focal = (W / 2) / math.tan(math.radians(fov_deg) / 2)

    def project(self, P):
        d = P - self.eye
        x = d @ self.r; y = d @ self.u; z = d @ self.f
        if self.ortho:
            s = self.W / self.ortho
            return np.stack([self.W / 2 + x * s, self.H / 2 - y * s], -1), z
        zc = np.maximum(z, 1e-3)
        return np.stack([self.W / 2 + self.focal * x / zc, self.H / 2 - self.focal * y / zc], -1), z


def view_camera(view, center=(0, 0, 0), dist=150.0, fov=40.0, W=320, H=320, height=8.0):
    """Named views around a model facing +X: front, back, left, right, q (3/4 front-left), q2, top."""
    c = np.asarray(center, float)
    ang = {'front': 0, 'q': 35, 'left': 90, 'qback': 145, 'back': 180, 'right': -90, 'q2': -35}
    if view == 'top':
        return Camera(c + np.array([0.01, 0, dist]), c, fov, W, H, up=(1, 0, 0))
    a = math.radians(ang[view])
    eye = c + np.array([math.cos(a) * dist, math.sin(a) * dist, height])
    return Camera(eye, c, fov, W, H)


def texture_rgb(m):
    out = []
    for t in m.textures:
        pix = t['pixels']; pal = t['palette']
        rgb = pal[pix].astype(np.float64) / 255.0
        out.append(dict(rgb=rgb, idx=pix, w=t['width'], h=t['height'], flags=t['flags']))
    return out


def render(meshes, cam, textures, light_dir=(-0.4, -0.3, -0.85), ambient=0.42, shade=0.62, bg=(40, 44, 52),
           extra_lines=None, cull=True, supersample=1, fullbright=False):
    W, H = cam.W * supersample, cam.H * supersample
    scale = supersample
    zbuf = np.full((H, W), np.inf)
    color = np.zeros((H, W, 3))
    color[:] = np.asarray(bg) / 255.0
    L = np.asarray(light_dir, float); L /= np.linalg.norm(L)
    for me in meshes:
        tex = textures[me['tex']] if me['tex'] < len(textures) else None
        P = me['pos'].reshape(-1, 3)
        xy, z = cam.project(P)
        xy = xy.reshape(-1, 3, 2) * scale
        z = z.reshape(-1, 3)
        valid = np.all(z > 0.5, axis=1)
        a = xy[:, 0]; b = xy[:, 1]; c = xy[:, 2]
        area = (b[:, 0] - a[:, 0]) * (c[:, 1] - a[:, 1]) - (b[:, 1] - a[:, 1]) * (c[:, 0] - a[:, 0])
        if cull:
            # studiomdl stores triangles clockwise seen from outside (quake order). In our y-down
            # screen space a clockwise-from-viewer triangle has positive 'area'.
            valid &= area > 0
        nrm = me['nrm']
        # lighting per vertex (gouraud like the engine)
        cosv = -(nrm @ L)
        lam = 1.5
        lc = (cosv + (lam - 1.0)) / lam
        illum = ambient + shade * np.clip(lc, 0, 1)
        if fullbright or (tex is not None and tex['flags'] & 0x4):
            illum = np.ones_like(illum)
        attr = np.concatenate([me['st'], illum[..., None]], axis=2)
        idx = np.nonzero(valid)[0]
        if len(idx) == 0:
            continue
        zb2, ab, tid = raster(xy[idx], z[idx], attr[idx], W, H, depth_test=True)
        upd = tid >= 0
        # nearer than global zbuffer?
        upd &= zb2 < zbuf
        if tex is not None:
            s = np.clip(np.floor(ab[..., 0]).astype(int), 0, tex['w'] - 1)
            t = np.clip(np.floor(ab[..., 1]).astype(int), 0, tex['h'] - 1)
            texel = tex['rgb'][t, s]
            if tex['flags'] & 0x40:  # masked
                upd &= tex['idx'][t, s] != 255
        else:
            texel = np.ones((H, W, 3)) * 0.8
        lit = np.clip(texel * ab[..., 2:3] * 1.12, 0, 1)
        if tex is not None and tex['flags'] & 0x20:  # additive
            color[upd] = np.clip(color[upd] + texel[upd], 0, 1)
        else:
            color[upd] = lit[upd]
            zbuf[upd] = zb2[upd]
    img = Image.fromarray((np.clip(color, 0, 1) * 255).astype(np.uint8), 'RGB')
    if supersample > 1:
        img = img.resize((cam.W, cam.H), Image.LANCZOS)
    if extra_lines:
        d = ImageDraw.Draw(img)
        for (p0, p1, col) in extra_lines:
            xy, z = cam.project(np.array([p0, p1], float))
            if np.all(z > 0.5):
                d.line([tuple(xy[0]), tuple(xy[1])], fill=col, width=1)
    return img


def box_lines(R, t, mn, mx, col):
    corners = []
    for i in range(8):
        c = np.array([mx[0] if i & 1 else mn[0], mx[1] if i & 2 else mn[1], mx[2] if i & 4 else mn[2]])
        corners.append(R @ c + t)
    edges = [(0, 1), (2, 3), (4, 5), (6, 7), (0, 2), (1, 3), (4, 6), (5, 7), (0, 4), (1, 5), (2, 6), (3, 7)]
    return [(corners[a], corners[b], col) for a, b in edges]


HITGROUP_COLORS = {0: (200, 200, 200), 1: (255, 60, 60), 2: (255, 160, 40), 3: (255, 230, 60),
                   4: (80, 200, 255), 5: (60, 120, 255), 6: (120, 255, 120), 7: (40, 180, 60)}


def hitbox_lines(m, bones):
    lines = []
    for hb in m.hitboxes:
        B = bones[hb['bone']]
        lines += box_lines(B[:, :3], B[:, 3], hb['bbmin'], hb['bbmax'], HITGROUP_COLORS.get(hb['group'], (255, 255, 255)))
    return lines


def hull_lines(crouch=False):
    z0, z1 = (-18, 18) if crouch else (-36, 36)
    return box_lines(np.eye(3), np.zeros(3), (-16, -16, z0), (16, 16, z1), (255, 0, 255))


_FONT = None


def _font():
    global _FONT
    if _FONT is None:
        for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
                  '/usr/share/fonts/dejavu/DejaVuSans.ttf'):
            if os.path.exists(p):
                _FONT = ImageFont.truetype(p, 11)
                break
        else:
            _FONT = ImageFont.load_default()
    return _FONT


def label(img, text, col=(255, 255, 255)):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, img.width, 14], fill=(0, 0, 0))
    d.text((3, 1), text, fill=col, font=_font())
    return img


def grid(images, cols, pad=2, bg=(20, 20, 24)):
    if not images:
        return Image.new('RGB', (10, 10))
    w = max(i.width for i in images); h = max(i.height for i in images)
    rows = (len(images) + cols - 1) // cols
    out = Image.new('RGB', (cols * (w + pad) + pad, rows * (h + pad) + pad), bg)
    for k, im in enumerate(images):
        r, c = divmod(k, cols)
        out.paste(im, (pad + c * (w + pad), pad + r * (h + pad)))
    return out


# ------------------------------------------------------------------------------------- high level

def render_pose(m, seq, frame=0.0, blending=(127, 127), gaitseq=None, gaitframe=0.0, view='q', W=240, H=300,
                dist=None, center=None, fov=34.0, hitboxes=False, hull=False, crouch=False, body=0, skin=0,
                yaw=0.0, sub_models=(), player=True, title=None, supersample=2, height=None, floor=None):
    if isinstance(seq, str):
        seq = m.seq_by_name[seq.lower()]
    bones = setup_bones(m, seq, frame, blending, gaitseq, gaitframe, player=player, yaw_deg=yaw)
    meshes = posed_triangles(m, bones, body, skin)
    texs = texture_rgb(m)
    # attached sub models (p_ weapons) merged by bone name
    for sub in sub_models:
        sb = merge_bones(sub, m, bones, yaw_deg=yaw)
        sm = posed_triangles(sub, sb)
        st = texture_rgb(sub)
        base = len(texs)
        for me in sm:
            me['tex'] += base
        texs += st
        meshes += sm
    if center is None:
        allp = np.concatenate([me['pos'].reshape(-1, 3) for me in meshes]) if meshes else np.zeros((1, 3))
        center = (allp.min(0) + allp.max(0)) / 2
        ext = np.max(allp.max(0) - allp.min(0))
        if dist is None:
            dist = max(60.0, ext * 1.9)
    if dist is None:
        dist = 150
    cam = view_camera(view, center, dist, fov, W, H, height=height if height is not None else dist * 0.08)
    lines = []
    if hitboxes:
        lines += hitbox_lines(m, bones)
    if hull:
        lines += hull_lines(crouch)
    if floor is not None:
        for x in range(-60, 61, 20):
            lines.append(((x, -60, floor), (x, 60, floor), (90, 160, 90)))
            lines.append(((-60, x, floor), (60, x, floor), (90, 160, 90)))
    img = render(meshes, cam, texs, extra_lines=lines, supersample=supersample)
    if title:
        label(img, title)
    return img


def render_viewmodel(m, seq, frame=0.0, W=320, H=240, fov_h=90.0, title=None, supersample=2, body=0):
    """First-person view: camera at the model origin looking down +X (CS default fov 90, 4:3)."""
    if isinstance(seq, str):
        seq = m.seq_by_name[seq.lower()]
    bones = setup_bones(m, seq, frame, (0, 0), None, 0, player=False)
    meshes = posed_triangles(m, bones, body)
    cam = Camera((0, 0, 0), (1, 0, 0), fov_h, W, H)
    img = render(meshes, cam, texture_rgb(m), light_dir=(0.3, -0.4, -0.85), supersample=supersample)
    if title:
        label(img, title)
    return img


def render_rest(meshes, view='q', W=300, H=360, colors=None, center=None, dist=None, fov=34.0, title=None,
                bone_colors=False, pages=None, wire=False, light_dir=(-0.4, -0.3, -0.85)):
    """Quick look at un-compiled geom.Mesh lists in their rest pose (flat material colours, or the
    baked pages if given: pages = list of rgb arrays indexed like pack_atlas pages)."""
    tris = []
    allp = np.vstack([m.v for m in meshes])
    if center is None:
        center = (allp.min(0) + allp.max(0)) / 2
    if dist is None:
        dist = max(60.0, np.max(allp.max(0) - allp.min(0)) * 1.9)
    cam = view_camera(view, center, dist, fov, W, H, height=dist * 0.08)
    texs = []
    out_meshes = []
    rng = np.random.default_rng(3)
    palette = {}
    for m in meshes:
        if pages is not None and m.island is not None:
            pi = m.island[0]
            while len(texs) <= pi:
                texs.append(None)
            if texs[pi] is None:
                rgb = pages[pi].astype(np.float64) / 255.0
                texs[pi] = dict(rgb=rgb, idx=np.zeros(rgb.shape[:2], np.uint8), w=rgb.shape[1], h=rgb.shape[0], flags=0)
            st = np.column_stack([m.attrs['_px'], m.attrs['_py']])
            ff = m.f[:, ::-1]   # studiomdl flips source (CCW) triangles to the engine's CW order
            out_meshes.append(dict(pos=m.v[ff], nrm=m.n[ff], st=st[ff], tex=pi))
        else:
            key = (m.bone[0] if bone_colors else m.mat)
            if key not in palette:
                c = (colors or {}).get(m.mat) if not bone_colors else None
                palette[key] = np.asarray(c, float) / 255 if c is not None else rng.uniform(0.3, 0.95, 3)
            ff = m.f[:, ::-1]
            out_meshes.append(dict(pos=m.v[ff], nrm=m.n[ff], st=np.zeros((len(m.f), 3, 2)), tex=-1,
                                   col=palette[key], bone=m.bone[ff] if bone_colors else None))
    # flat coloured meshes: fake 1x1 textures per colour
    base = len(texs)
    for me in out_meshes:
        if me['tex'] == -1:
            if bone_colors:
                pass
            texs.append(dict(rgb=np.ones((1, 1, 3)) * me['col'], idx=np.zeros((1, 1), np.uint8), w=1, h=1, flags=0))
            me['tex'] = len(texs) - 1
    img = render(out_meshes, cam, texs, cull=True, supersample=2, light_dir=light_dir)
    if title:
        label(img, title)
    return img


def player_previews(path, outbase, human=True, weapon=None):
    """Standard preview sheet set for a player model. Returns list of PNG paths.
    weapon: optional p_ model path merged into the hands (default: our p_ak47 for humans if it exists)."""
    os.makedirs(os.path.dirname(outbase), exist_ok=True)
    m = MDL(path)
    subs = ()
    if human:
        from . import CSTRIKE
        wp = weapon or os.path.join(CSTRIKE, 'models/vexmira/weapons/p_ak47.mdl')
        if os.path.exists(wp):
            subs = (MDL(wp),)
    S = m.seq_by_name
    outs = []
    ext = 'rifle' if human else 'knife'
    if human and 'ref_aim_ak47' in S:
        ext = 'ak47'
    aim = S['ref_aim_' + ext]
    idle = S['idle1']
    # 1. turntable of the standing aim pose
    ib = setup_bones(m, idle, 0, (127, 127), None, 0)
    hs = max(1.0, (ib[:, 2, 3].max() + 36 + 6) / 72.0)
    ims = [render_pose(m, aim, 0, (127, 127), idle, 0, view=v, title='aim %s %s' % (ext, v), W=300, H=400,
                       dist=105 * hs, center=(0, 0, -36 + 36 * hs), sub_models=subs)
           for v in ('front', 'q', 'left', 'qback', 'back', 'q2')]
    hb = setup_bones(m, aim, 0, (127, 127), idle, 0)
    head = hb[m.bone_names.index('Bip01 Head')][:, 3] + np.array([0, 0, 4.0])
    ims += [render_pose(m, aim, 0, (127, 127), idle, 0, view=v, title='head ' + v, W=300, H=400, center=head, dist=30)
            for v in ('front', 'q', 'left')]
    p = outbase + '_turn.png'; grid(ims, 6).save(p); outs.append(p)
    # 2. 9-blend matrix (front-quarter view), crouch row
    ims = []
    for t in (0, 127, 255):
        for s in (0, 127, 255):
            ims.append(render_pose(m, aim, 0, (s, t), idle, 0, view='q', W=200, H=250, title='s%d t%d' % (s, t),
                                   sub_models=subs))
    p = outbase + '_blend9.png'; grid(ims, 3).save(p); outs.append(p)
    # 3. locomotion + crouch + jump + swim
    ims = []
    for nm, gseq, fr in (('walk', 'walk', 0), ('walk', 'walk', 15), ('run', 'run', 0), ('run', 'run', 11),
                         ('crouchrun', 'crouchrun', 8), ('crouch_idle', 'crouch_idle', 0), ('jump', 'jump', 10),
                         ('longjump', 'longjump', 10)):
        g = S[gseq]
        up = S[('crouch_aim_' if 'crouch' in nm else 'ref_aim_') + ext]
        ims.append(render_pose(m, up, 0, (127, 127), g, fr, view='left' if fr else 'q', W=200, H=250,
                               title='%s f%d' % (nm, fr), hitboxes=False, sub_models=subs))
    ims.append(render_pose(m, S['swim'], 6, view='left', W=200, H=250, title='swim'))
    ims.append(render_pose(m, S['treadwater'], 6, view='q', W=200, H=250, title='treadwater'))
    p = outbase + '_moves.png'; grid(ims, 5).save(p); outs.append(p)
    # 4. actions: shoot / reload / flinch
    ims = []
    acts = [('ref_shoot_' + ext, [0, 2, 4] if human else [0, 4, 7]), ('ref_reload_' + ext, [0, 5, 9, 13]) if human else
            ('crouch_shoot_' + ext, [3, 6]), ('head_flinch', [2]), ('gut_flinch', [2])]
    for nm, frs in acts:
        if nm not in S:
            continue
        si = S[nm]
        for f in frs:
            f = min(f, m.seqs[si]['numframes'] - 1)
            ims.append(render_pose(m, si, f, (127, 127), idle, 0, view='q', W=200, H=250, title='%s f%d' % (nm, f),
                                   sub_models=subs))
    p = outbase + '_actions.png'; grid(ims, 5).save(p); outs.append(p)
    # 5. deaths (end frames) + hitbox overlay
    ims = []
    for s in m.seqs:
        if 101 <= s['index'] <= 159:
            fl = -18 if s['label'] == 'crouch_die' else -36
            for view, f in (('left', s['numframes'] * 0.45), ('left', s['numframes'] - 1.001), ('q', s['numframes'] - 1.001)):
                ims.append(render_pose(m, s['index'], f, view=view, W=180, H=150, title='%s f%.0f' % (s['label'], f),
                                       floor=fl, center=(0, 0, fl + 12 * hs), dist=110 * hs,
                                       height=(6 if view == 'left' else 40) * hs))
    p = outbase + '_deaths.png'; grid(ims, 6).save(p); outs.append(p)
    ims = []
    ims = [render_pose(m, aim, 0, (127, 127), idle, 0, view=v, hitboxes=True, hull=True, title='hitboxes ' + v,
                       center=(0, 0, 0), dist=150) for v in ('front', 'left', 'q')]
    ims.append(render_pose(m, S['crouch_aim_' + ext], 0, (127, 127), S['crouch_idle'], 0, view='q', hitboxes=True,
                           hull=True, crouch=True, title='crouch hitboxes', center=(0, 0, 0), dist=150))
    p = outbase + '_hitbox.png'; grid(ims, 4).save(p); outs.append(p)
    return outs
