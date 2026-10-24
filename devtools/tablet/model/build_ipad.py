import sys, os, math
import numpy as np
sys.path.insert(0, '/home/user/claude/devtools')
from PIL import Image
from mdlkit.geom import Mesh
from mdlkit import paint, vmodel
from mdlkit.vmodel import build_vmodel
from mdlkit.pmodel import build_pmodel
from mdlkit.samples import operator_spec
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = '/home/user/claude/cstrike/models/vexmira/tablet/'
IMGS = {k: np.asarray(Image.open(os.path.join(HERE, k + '.png')).convert('RGB'), np.float64) / 255.0 for k in ('back2', 'screen2')}
def img_painter(key):
    def f(ctx, mat):
        im = IMGS[key]; H, W = im.shape[:2]; uv = ctx['uv']
        x = np.clip((uv[:, 0] * (W - 1)).astype(int), 0, W - 1); y = np.clip(((1 - uv[:, 1]) * (H - 1)).astype(int), 0, H - 1)
        return im[y, x].copy()
    return f
paint.PAINTERS['img_back'] = img_painter('back2'); paint.PAINTERS['img_screen'] = img_painter('screen2'); paint.EMISSIVE_TYPES.add('img_screen')
# tablet in GUN SPACE: X = width (towards the support hand), Z = up, Y = thickness (+Y faces the viewer)
WID, HEI, TH, RAD = 17.0, 11.6, 0.46, 1.25
X0, Z0 = -0.6, -4.2           # right edge sits in the right hand grip, a bit below the middle
def rr_outline(w, h, r, cx, cz, n=6):
    pts = []
    for (ax, az, a0) in ((cx + w / 2 - r, cz + h / 2 - r, 0), (cx - w / 2 + r, cz + h / 2 - r, 90), (cx - w / 2 + r, cz - h / 2 + r, 180), (cx + w / 2 - r, cz - h / 2 + r, 270)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n); pts.append((ax + r * math.cos(a), az + r * math.sin(a)))
    return pts
def face(pts, y, normal_y, mat, name, uvbox):
    cx = sum(p[0] for p in pts) / len(pts); cz = sum(p[1] for p in pts) / len(pts)
    x0, x1, z0, z1, flipu = uvbox
    V = [(cx, y, cz)] + [(p[0], y, p[1]) for p in pts]
    UV = []
    for v in V:
        u = (v[0] - x0) / (x1 - x0); u = 1 - u if flipu else u
        UV.append((u, (v[2] - z0) / (z1 - z0)))
    F = [(0, i, i + 1) for i in range(1, len(pts))] + [(0, len(pts), 1)]
    m = Mesh(np.array(V), np.array(F), np.array(UV), mat=mat, name=name)
    if m.n[:, 1].mean() * normal_y < 0: m = Mesh(np.array(V), np.array(F)[:, ::-1], np.array(UV), mat=mat, name=name)
    m.n = np.tile([0, normal_y, 0], (len(V), 1)).astype(float); return m
def rim(pts_a, ya, pts_b, yb, mat, name):
    V, F, UV = [], [], []
    n = len(pts_a)
    for i in range(n):
        V += [(pts_a[i][0], ya, pts_a[i][1]), (pts_b[i][0], yb, pts_b[i][1])]
        UV += [(i / n, 0), (i / n, 1)]
    for i in range(n):
        a, b, c, d = 2 * i, 2 * i + 1, 2 * ((i + 1) % n), 2 * ((i + 1) % n) + 1
        F += [(a, c, b), (b, c, d)]
    m = Mesh(np.array(V, float), np.array(F), np.array(UV, float), mat=mat, name=name)
    cx = np.mean([p[0] for p in pts_a]); cz = np.mean([p[1] for p in pts_a])
    out = np.array([m.v[:, 0] - cx, 0 * m.v[:, 1], m.v[:, 2] - cz]).T
    if (m.n * out).sum() < 0: m = Mesh(np.array(V, float), np.array(F)[:, ::-1], np.array(UV, float), mat=mat, name=name)
    return m
def tablet():
    cx, cz = X0 + WID / 2, Z0 + HEI / 2
    outer = rr_outline(WID, HEI, RAD, cx, cz)
    inner = rr_outline(WID - 0.5, HEI - 0.5, RAD - 0.25, cx, cz)
    y1, y0 = TH / 2, -TH / 2
    P = [rim(outer, y0 + 0.08, outer, y1 - 0.08, 'ip_alu', 'side'),
         rim(outer, y1 - 0.08, inner, y1, 'ip_alu', 'chamf1'), rim(inner, y0, outer, y0 + 0.08, 'ip_alu', 'chamf2')]
    # front: black glass bezel + the screen (inset) ; back: anodised back with logo + camera
    P.append(face(inner, y1, 1.0, 'ip_glass', 'bezel', (cx - WID / 2, cx + WID / 2, cz - HEI / 2, cz + HEI / 2, False)))
    scr = rr_outline(WID - 1.5, HEI - 1.5, 0.55, cx, cz)
    P.append(face(scr, y1 + 0.012, 1.0, 'ip_screen', 'screen', (cx - (WID - 1.5) / 2, cx + (WID - 1.5) / 2, cz - (HEI - 1.5) / 2, cz + (HEI - 1.5) / 2, False)))
    P.append(face(inner, y0, -1.0, 'ip_back', 'back', (cx - (WID - 0.5) / 2, cx + (WID - 0.5) / 2, cz - (HEI - 0.5) / 2, cz + (HEI - 0.5) / 2, False)))
    import math as _m
    for m in P:
        if m.name == 'screen': m.size = (WID - 1.5, HEI - 1.5); m.detail = 4.0
        elif m.name == 'back': m.size = (WID - 0.5, HEI - 0.5); m.detail = 1.6
        elif m.name == 'bezel': m.size = (WID, HEI); m.detail = 0.15
        else: m.size = (2 * (WID + HEI), TH); m.detail = 0.6
    return P
MATS = {
    'ip_alu': {'type': 'metal', 'color': (150, 148, 156), 'scratches': 0.12, 'shine': 0.9, 'edge_wear': 0.2, 'seed': 661},
    'ip_glass': {'type': 'flat', 'color': (10, 10, 12)},
    'ip_screen': {'type': 'img_screen'}, 'ip_back': {'type': 'img_back'},
}
vmodel.WEAPON_SETS['c4'] = [('idle1', 'idle', 31, 15, True), ('draw', 'draw', 16, 24, False), ('drop', 'draw', 16, 24, False),
                            ('arm', 'shoot', 10, 24, False)]
vmodel.STOCK_SOUNDS['c4'] = {'draw': [(0.1, 'items/gunpickup2.wav')], 'shoot': [(0.1, 'buttons/lightswitch2.wav')]}
vmodel.FAMILY['c4'] = 'rifle'
HOLD = dict(grip=tuple(float(v) for v in os.environ.get('GRIP', '13.0,-6.5,-5.2').split(',')),
            rot=tuple(float(v) for v in os.environ.get('ROT', '96,-4,-18').split(',')),
            fore=WID - float(os.environ.get('FOREB','3.2')), fore_z=float(os.environ.get('FOREZ', '0.6')), scale=1.0)
which = sys.argv[1] if len(sys.argv) > 1 else 'v'
if which == 'v':
    build_vmodel('v_tablet', operator_spec(), kind='c4', gun_meshes=tablet(), out=OUT + 'v_tablet.mdl', tex=(512, 512),
                 materials=MATS, style={'hold': HOLD, 'gun_scale': 1.0})
else:
    meshes = tablet()
    # p_/w_: smaller (player scale), screen facing the holder
    import numpy as _np
    def _R(a, b, c):
        a, b, c = [_np.radians(v) for v in (a, b, c)]
        Rx = _np.array([[1,0,0],[0,_np.cos(a),-_np.sin(a)],[0,_np.sin(a),_np.cos(a)]])
        Ry = _np.array([[_np.cos(b),0,_np.sin(b)],[0,1,0],[-_np.sin(b),0,_np.cos(b)]])
        Rz = _np.array([[_np.cos(c),-_np.sin(c),0],[_np.sin(c),_np.cos(c),0],[0,0,1]])
        return Rz @ Ry @ Rx
    rot = [float(v) for v in os.environ.get('ROTP', '-35,0,90').split(',')] if which == 'p' else [0, 0, 0]
    off = _np.array([float(v) for v in os.environ.get('OFFP', '0,0,2.5').split(',')]) if which == 'p' else _np.zeros(3)
    if which == 'w': rot = [90, 0, 0]
    R = _R(*rot)
    for m in meshes:
        m.v = (m.v * 0.55) @ R.T + off
        m.n = m.n @ R.T
    if which == 'w':
        V = _np.vstack([m.v for m in meshes]); c = (V.min(0) + V.max(0)) / 2; c[2] = V[:, 2].min()
        for m in meshes: m.v = m.v - c
    print(build_pmodel('p_tablet' if which == 'p' else 'w_tablet', meshes, OUT + ('p_tablet.mdl' if which == 'p' else 'w_tablet.mdl'),
                       materials=MATS, tex=(256, 256), preview=False))
