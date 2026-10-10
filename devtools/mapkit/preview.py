"""Software preview renderer for compiled GoldSrc BSPs (+ texture contact sheets).

    python3 -m mapkit.preview cstrike/maps/zm_vex_pilot.bsp out_dir [--size 1200] [--zcut Z]
        [--eye x y z yaw pitch] ...

Renders with the embedded textures and RAD lightmaps (approximate GoldSrc look):
  <name>_top.png       orthographic top-down (ceilings back-face culled -> floor plan)
  <name>_oblique.png   45 deg cutaway from the south-west
  <name>_oblique2.png  45 deg cutaway from the north-east
  <name>_eye_ct.png    perspective, player eye at the CT spawn centroid looking at the T spawns
  <name>_eye_t.png     perspective, from the T spawns looking at the CT spawns
  <name>_eye<N>.png    extra perspective shots (--eye)
Ortho markers: CT spawns blue, T red, lights yellow, ladders green, ambients magenta, sprites cyan.

API: Renderer(BSP(path)).render_ortho(...) / .render_persp(eye, yaw, pitch, fov, w, h)
"""
from __future__ import annotations

import math
import os
import sys
from typing import Dict, List, Optional, Sequence, Tuple

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from .bspcheck import BSP, TEX_SPECIAL

HIDDEN_CLASSES = {'func_ladder', 'trigger_hurt', 'trigger_multiple', 'trigger_once', 'func_buyzone',
                  'trigger_push', 'trigger_teleport', 'func_bomb_target', 'func_hostage_rescue',
                  'func_vip_safetyzone', 'func_escapezone', 'trigger_gravity', 'trigger_changelevel'}


def _font(sz=12):
    try:
        return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', sz)
    except Exception:
        return ImageFont.load_default()


def _light_curve(l):
    # approximate GoldSrc look (lightgamma 2.5 / texgamma 2.0 / brightness 1)
    return np.clip((l / 255.0) ** 0.62 * 1.35, 0, 1.6)


# ----------------------------------------------------------------------
# cameras
# ----------------------------------------------------------------------
class OrthoCam:
    def __init__(self, r, u, d, scale, ox, oy, W, H):
        self.r, self.u, self.d = r, u, d
        self.scale, self.ox, self.oy, self.W, self.H = scale, ox, oy, W, H

    def project(self, V):
        return V @ self.r * self.scale + self.ox, -(V @ self.u) * self.scale + self.oy

    def facing(self, n, V):
        return float(np.dot(n, self.d)) < -1e-4

    def clip(self, V):
        return V

    def rays(self, xs, ys):
        a = (xs - self.ox) / self.scale
        b = -(ys - self.oy) / self.scale
        # start the rays far behind the scene: a ray plane through the origin hid everything
        # in front of it (e.g. all faces above z 0 in the top view)
        O = a[..., None] * self.r + b[..., None] * self.u - 16384.0 * self.d
        D = np.broadcast_to(self.d, O.shape)
        return O, D

    def texel_level(self, depth):
        return int(np.clip(math.floor(math.log2(max(1.0, 1.0 / self.scale))), 0, 3))


class PerspCam:
    def __init__(self, eye, yaw, pitch, fov, W, H, near=4.0):
        self.eye = np.asarray(eye, np.float64)
        yr, pr = math.radians(yaw), math.radians(pitch)
        self.fwd = np.array([math.cos(pr) * math.cos(yr), math.cos(pr) * math.sin(yr), math.sin(pr)])
        self.right = np.cross(self.fwd, [0, 0, 1.0])
        self.right /= np.linalg.norm(self.right)
        self.up = np.cross(self.right, self.fwd)
        self.W, self.H = W, H
        self.f = (W / 2) / math.tan(math.radians(fov) / 2)
        self.near = near

    def _cam(self, V):
        R = V - self.eye
        return R @ self.right, R @ self.up, R @ self.fwd

    def clip(self, V):
        """Clip polygon against the near plane (Sutherland-Hodgman)."""
        _, _, z = self._cam(V)
        if (z >= self.near).all():
            return V
        out = []
        n = len(V)
        for i in range(n):
            a, b = V[i], V[(i + 1) % n]
            za, zb = z[i], z[(i + 1) % n]
            if za >= self.near:
                out.append(a)
            if (za >= self.near) != (zb >= self.near):
                t = (self.near - za) / (zb - za)
                out.append(a + (b - a) * t)
        return np.array(out) if len(out) >= 3 else None

    def project(self, V):
        x, y, z = self._cam(V)
        return self.f * x / z + self.W / 2, -self.f * y / z + self.H / 2

    def facing(self, n, V):
        return float(np.dot(n, V[0] - self.eye)) < -1e-4

    def rays(self, xs, ys):
        D = (self.fwd + ((xs - self.W / 2) / self.f)[..., None] * self.right
             - ((ys - self.H / 2) / self.f)[..., None] * self.up)
        D = D / np.linalg.norm(D, axis=-1, keepdims=True)
        return np.broadcast_to(self.eye, D.shape), D

    def texel_level(self, depth):
        upp = float(np.median(depth)) / self.f   # world units per pixel
        return int(np.clip(math.floor(math.log2(max(1.0, upp))), 0, 3))


# ----------------------------------------------------------------------
class Renderer:
    def __init__(self, bsp: BSP):
        self.b = bsp
        self.tex_cache: Dict[Tuple[int, int], Optional[np.ndarray]] = {}
        self.ent_by_model = {}
        for e in bsp.entities:
            m = e.get('model', '')
            if m.startswith('*'):
                self.ent_by_model[int(m[1:])] = e
        self.cam = None

    def texture(self, mi: int, level: int):
        key = (mi, level)
        if key not in self.tex_cache:
            m = self.b.miptex[mi] if mi < len(self.b.miptex) else None
            img = m.rgba(level) if m is not None else None
            self.tex_cache[key] = None if img is None else img.astype(np.float32) / 255.0
        return self.tex_cache[key]

    def lightmap(self, fi: int, ex):
        f = self.b.faces[fi]
        if f['lightofs'] < 0 or len(self.b.lighting) == 0:
            return None
        w = int(ex[0] // 16 + 1)
        h = int(ex[1] // 16 + 1)
        n = w * h * 3
        acc = np.zeros((h, w, 3), np.float32)
        k = 0
        for s in f['styles']:
            if s == 255:
                continue
            o = int(f['lightofs']) + k * n
            if o + n > len(self.b.lighting):
                break
            acc += self.b.lighting[o:o + n].reshape(h, w, 3).astype(np.float32)
            k += 1
        return acc if k else None

    def _items(self):
        items = []
        for mi, m in enumerate(self.b.models):
            ent = self.ent_by_model.get(mi, {}) if mi else {}
            if ent.get('classname', 'worldspawn') in HIDDEN_CLASSES:
                continue
            rmode = int(ent.get('rendermode', '0') or 0)
            ramt = float(ent.get('renderamt', '255') or 255)
            alpha = 1.0 if rmode in (0, 4) else max(0.15, ramt / 255.0)
            off = np.zeros(3)
            if 'origin' in ent:
                off = np.array([float(x) for x in ent['origin'].split()])
            for fi in range(m['firstface'], m['firstface'] + m['numfaces']):
                items.append((fi, alpha, off))
        return items

    def _draw_all(self, cam, W, H, zcut, bg):
        img = np.zeros((H, W, 3), np.float32) + np.array(bg, np.float32) / 255
        zbuf = np.full((H, W), np.inf, np.float32)
        trans = []
        for fi, alpha, off in self._items():
            if alpha < 1.0:
                trans.append((fi, alpha, off))
            else:
                self._draw_face(cam, fi, off, img, zbuf, 1.0, zcut)
        for fi, alpha, off in trans:
            self._draw_face(cam, fi, off, img, zbuf, alpha, zcut)
        self.cam = cam
        return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))

    # ------------------------------------------------------------------
    def render_ortho(self, view: str = 'top', size: int = 1200, yaw: float = 225, pitch: float = 50,
                     zcut: Optional[float] = None, margin: int = 24, bg=(18, 18, 24)) -> Image.Image:
        if view == 'top':
            d = np.array([0, 0, -1.0])
            r = np.array([1.0, 0, 0])
            u = np.array([0, 1.0, 0])
        else:
            yr, pr = math.radians(yaw), math.radians(pitch)
            d = np.array([math.cos(pr) * math.cos(yr), math.cos(pr) * math.sin(yr), -math.sin(pr)])
            r = np.cross(d, [0, 0, 1.0])
            r /= np.linalg.norm(r)
            u = np.cross(r, d)
        mins, maxs = self.b.models[0]['mins'].astype(np.float64), self.b.models[0]['maxs'].astype(np.float64)
        if zcut is not None:
            maxs[2] = min(maxs[2], zcut)
        corners = np.array([[x, y, z] for x in (mins[0], maxs[0]) for y in (mins[1], maxs[1]) for z in (mins[2], maxs[2])])
        px, py = corners @ r, corners @ u
        span = max(px.max() - px.min(), py.max() - py.min())
        scale = (size - 2 * margin) / span
        W = int(math.ceil((px.max() - px.min()) * scale)) + 2 * margin
        H = int(math.ceil((py.max() - py.min()) * scale)) + 2 * margin
        cam = OrthoCam(r, u, d, scale, -px.min() * scale + margin, py.max() * scale + margin, W, H)
        return self._draw_all(cam, W, H, zcut, bg)

    render = render_ortho   # backwards compatible name

    def render_persp(self, eye, yaw: float, pitch: float = 0.0, fov: float = 90, W: int = 960, H: int = 600,
                     bg=(10, 12, 20)) -> Image.Image:
        cam = PerspCam(eye, yaw, pitch, fov, W, H)
        return self._draw_all(cam, W, H, None, bg)

    def _draw_face(self, cam, fi, off, img, zbuf, alpha, zcut):
        b = self.b
        f = b.faces[fi]
        ti = b.texinfo[f['texinfo']]
        if ti['flags'] & TEX_SPECIAL:
            return  # sky: the engine draws the skybox there; leave background
        pl = b.planes[f['planenum']]
        n = pl['normal'].astype(np.float64)
        dist = float(pl['dist'])
        if f['side']:
            n, dist = -n, -dist
        dist += float(np.dot(n, off))
        V = b.face_vertices(fi) + off
        if zcut is not None and V[:, 2].min() > zcut:
            return
        if not cam.facing(n, V):
            return
        Vc = cam.clip(V)
        if Vc is None:
            return
        X, Y = cam.project(Vc)
        H, W = img.shape[:2]
        x0, x1 = int(max(0, math.floor(X.min()))), int(min(W - 1, math.ceil(X.max())))
        y0, y1 = int(max(0, math.floor(Y.min()))), int(min(H - 1, math.ceil(Y.max())))
        if x1 < x0 or y1 < y0:
            return
        ys, xs = np.mgrid[y0:y1 + 1, x0:x1 + 1].astype(np.float64)
        xs += 0.5
        ys += 0.5
        inside = np.ones(xs.shape, bool)
        nv = len(X)
        area = sum(X[i] * Y[(i + 1) % nv] - X[(i + 1) % nv] * Y[i] for i in range(nv))
        sgn = 1 if area > 0 else -1
        for i in range(nv):
            j = (i + 1) % nv
            e = (X[j] - X[i]) * (ys - Y[i]) - (Y[j] - Y[i]) * (xs - X[i])
            inside &= (e * sgn) >= -0.5
        if not inside.any():
            return
        O, D = cam.rays(xs, ys)
        denom = D @ n
        denom = np.where(np.abs(denom) < 1e-9, -1e-9, denom)
        t = (dist - O @ n) / denom
        P = O + t[..., None] * D
        depth = t.astype(np.float32)
        zs = zbuf[y0:y1 + 1, x0:x1 + 1]
        vis = inside & (depth < zs - 0.01) & (depth > 0)
        if not vis.any():
            return
        level = cam.texel_level(depth[vis])
        vecs = ti['vecs'].astype(np.float64)
        s = P @ vecs[0, :3] + vecs[0, 3] - np.dot(off, vecs[0, :3])
        tt = P @ vecs[1, :3] + vecs[1, 3] - np.dot(off, vecs[1, :3])
        tex = self.texture(int(ti['miptex']), level)
        if tex is None:
            col = np.zeros(P.shape[:2] + (3,), np.float32) + 0.5
            ta = np.ones(P.shape[:2], bool)
        else:
            th, tw = tex.shape[:2]
            sc = 1 << level
            ix = np.floor(s / sc).astype(np.int64) % tw
            iy = np.floor(tt / sc).astype(np.int64) % th
            texel = tex[iy, ix]
            col = texel[..., :3]
            ta = texel[..., 3] > 0.5
        name = b.miptex[int(ti['miptex'])].name if int(ti['miptex']) < len(b.miptex) and b.miptex[int(ti['miptex'])] else ''
        if not name.startswith('!'):          # liquids are fullbright-ish/unlit in the engine
            mn, ex, _ = b.face_extents(fi)
            lm = self.lightmap(fi, ex)
            if lm is not None:
                ls = np.clip(s / 16.0 - mn[0], 0, lm.shape[1] - 1)
                lt = np.clip(tt / 16.0 - mn[1], 0, lm.shape[0] - 1)
                l0x = np.floor(ls).astype(np.int64)
                l0y = np.floor(lt).astype(np.int64)
                l1x = np.minimum(l0x + 1, lm.shape[1] - 1)
                l1y = np.minimum(l0y + 1, lm.shape[0] - 1)
                fx = (ls - l0x)[..., None]
                fy = (lt - l0y)[..., None]
                L = (lm[l0y, l0x] * (1 - fx) * (1 - fy) + lm[l0y, l1x] * fx * (1 - fy) +
                     lm[l1y, l0x] * (1 - fx) * fy + lm[l1y, l1x] * fx * fy)
                col = col * _light_curve(L)
            elif len(b.lighting):
                col = col * 0.04  # no lightmap styles -> black in the engine
        a_mask = vis & ta
        reg = img[y0:y1 + 1, x0:x1 + 1]
        if alpha >= 1.0:
            reg[a_mask] = col[a_mask]
            zs[a_mask] = depth[a_mask]
        else:
            reg[a_mask] = reg[a_mask] * (1 - alpha) + col[a_mask] * alpha

    def project(self, p):
        X, Y = self.cam.project(np.asarray(p, np.float64)[None])
        return float(X[0]), float(Y[0])


def _markers(rd: Renderer, im: Image.Image, legend: str):
    dr = ImageDraw.Draw(im)
    b = rd.b
    rad = max(3, 16 * rd.cam.scale)
    for e in b.entities:
        cls = e.get('classname', '')
        if 'origin' not in e:
            continue
        o = np.array([float(x) for x in e['origin'].split()])
        x, y = rd.project(o)
        if cls in ('info_player_start', 'info_player_deathmatch'):
            c = (60, 150, 255) if cls == 'info_player_start' else (255, 60, 60)
            dr.ellipse([x - rad, y - rad, x + rad, y + rad], outline=c, width=2)
            yaw = math.radians(float((e.get('angles', '0 0 0').split() + ['0', '0'])[1]))
            tx, ty = rd.project(o + np.array([math.cos(yaw), math.sin(yaw), 0]) * 24)
            dr.line([x, y, tx, ty], fill=c, width=2)
        elif cls in ('light', 'light_spot'):
            dr.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 230, 80))
        elif cls == 'ambient_generic':
            dr.rectangle([x - 3, y - 3, x + 3, y + 3], outline=(255, 0, 255))
        elif cls == 'env_sprite':
            dr.ellipse([x - 3, y - 3, x + 3, y + 3], outline=(0, 230, 255))
    for mi, e in rd.ent_by_model.items():
        if e.get('classname') == 'func_ladder':
            m = b.models[mi]
            x, y = rd.project((m['mins'] + m['maxs']) / 2)
            dr.rectangle([x - 5, y - 5, x + 5, y + 5], outline=(60, 255, 90), width=2)
    dr.rectangle([0, 0, im.width, 20], fill=(0, 0, 0))
    dr.text((6, 3), legend + '   CT=blue  T=red  light=yellow  ladder=green  sound=magenta  sprite=cyan',
            fill=(230, 230, 230), font=_font(13))


def _label(im, text):
    dr = ImageDraw.Draw(im)
    dr.rectangle([0, 0, im.width, 20], fill=(0, 0, 0))
    dr.text((6, 3), text, fill=(230, 230, 230), font=_font(13))


def spawn_centroids(b: BSP):
    out = {}
    for cls, key in (('info_player_start', 'ct'), ('info_player_deathmatch', 't')):
        pts = [np.array([float(x) for x in e['origin'].split()]) for e in b.entities if e.get('classname') == cls]
        if pts:
            out[key] = np.mean(pts, axis=0)
    return out


def render_views(bsp_path: str, out_dir: str, size: int = 1200, zcut: Optional[float] = None,
                 eyes: Sequence[Tuple[float, float, float, float, float]] = ()) -> List[str]:
    """Write ortho + perspective previews; returns the PNG paths."""
    os.makedirs(out_dir, exist_ok=True)
    b = BSP(bsp_path)
    rd = Renderer(b)
    name = os.path.splitext(os.path.basename(bsp_path))[0]
    outs = []
    for view, kw in (('top', {}), ('oblique', dict(yaw=45, pitch=45)), ('oblique2', dict(yaw=225, pitch=45))):
        im = rd.render_ortho('top' if view == 'top' else 'oblique', size, zcut=zcut, **kw)
        _markers(rd, im, f'{name} {view}')
        p = os.path.join(out_dir, f'{name}_{view}.png')
        im.save(p)
        outs.append(p)
    # perspective: from each spawn group toward the other (player eye height)
    cen = spawn_centroids(b)
    shots = []
    if 'ct' in cen and 't' in cen:
        for a, bb in (('ct', 't'), ('t', 'ct')):
            eye = cen[a] + (0, 0, 17)
            dv = cen[bb] - cen[a]
            yaw = math.degrees(math.atan2(dv[1], dv[0]))
            shots.append((f'eye_{a}', eye, yaw, -5.0))
    for i, (x, y, z, yaw, pitch) in enumerate(eyes):
        shots.append((f'eye{i}', np.array([x, y, z]), yaw, pitch))
    for tag, eye, yaw, pitch in shots:
        im = rd.render_persp(eye, yaw, pitch, 90, 960, 600)
        _label(im, f'{name} {tag}  eye={np.round(eye).astype(int).tolist()} yaw={yaw:.0f} pitch={pitch:.0f} fov=90')
        p = os.path.join(out_dir, f'{name}_{tag}.png')
        im.save(p)
        outs.append(p)
    return outs


def contact_sheet(texs: Dict[str, 'object'], path: str, cell: int = 200, cols: int = 8):
    """Texture contact sheet (MipTex dict), 128px textures tiled 2x2 to show seams."""
    items = [(n, t) for n, t in texs.items() if not (n.startswith('+') and n[1] != '0')]
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * cell, rows * (cell + 16)), (40, 40, 48))
    d = ImageDraw.Draw(sheet)
    font = _font(11)
    for i, (n, t) in enumerate(items):
        im = Image.fromarray(t.to_rgba(0), 'RGBA')
        bg = Image.new('RGBA', im.size, (255, 0, 255, 255))
        bg.alpha_composite(im)
        im = bg.convert('RGB')
        if t.width <= 128 and t.height <= 128:
            im2 = Image.new('RGB', (t.width * 2, t.height * 2))
            for a in range(2):
                for c in range(2):
                    im2.paste(im, (a * t.width, c * t.height))
            im = im2
        s = min(cell / im.width, cell / im.height)
        im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.NEAREST)
        x, y = (i % cols) * cell, (i // cols) * (cell + 16)
        sheet.paste(im, (x, y))
        d.text((x + 2, y + cell + 1), f'{n} {t.width}x{t.height}', fill=(255, 255, 255), font=font)
    sheet.save(path)
    return path


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('bsp')
    ap.add_argument('out_dir')
    ap.add_argument('--size', type=int, default=1200)
    ap.add_argument('--zcut', type=float, default=None)
    ap.add_argument('--eye', type=float, nargs=5, action='append', default=[],
                    metavar=('X', 'Y', 'Z', 'YAW', 'PITCH'), help='extra perspective shot')
    a = ap.parse_args(argv)
    for p in render_views(a.bsp, a.out_dir, a.size, a.zcut, a.eye):
        print(p)


if __name__ == '__main__':
    sys.exit(main())
