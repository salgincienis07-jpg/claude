"""Procedural texture painting in 3D (rest pose) space + UV-space baking.

Pipeline (bake_textures):
  1. every UV island (geom.Mesh after pack_atlas) is rasterised into its texture page, storing the
     rest-pose position P, normal N, island uv and mesh attrs per texel (then dilated into padding);
  2. the mesh's material painter computes colours from P/N/uv (noise is evaluated in 3D so patterns
     run seamlessly across UV seams and between islands);
  3. optional ambient occlusion (multi-direction depth-map visibility) and a soft top-light are
     multiplied in (not on emissive materials);
  4. decals (eyes, stripes, emblems, blood, glow spots ...) are applied in 3D;
  5. pages are quantised to 8-bit with bmp8.quantize.

Materials are dicts: {'type': 'skin'|'cloth'|'metal'|'leather'|'glow'|'fur'|'scales'|'crystal'|'lava'|
'hair'|'bone'|'rubber'|'visor'|'flat', 'color': (r,g,b) 0..255, ... type-specific params ..., 'seed': int}.
"""
import math
import numpy as np

from .raster import raster, dilate

# =============================================================================================== noise

_M1 = np.uint64(0x9E3779B97F4A7C15)


def _hash_u32(ix, iy, iz, seed):
    x = (ix.astype(np.int64) * 73856093) ^ (iy.astype(np.int64) * 19349663) ^ (iz.astype(np.int64) * 83492791)
    x = (x ^ (int(seed) * 2654435761 + 0x5bd1e995)).astype(np.uint64)
    x ^= x >> np.uint64(33)
    x *= np.uint64(0xff51afd7ed558ccd)
    x ^= x >> np.uint64(33)
    x *= np.uint64(0xc4ceb9fe1a85ec53)
    x ^= x >> np.uint64(33)
    return x


def _hash01(ix, iy, iz, seed):
    return (_hash_u32(ix, iy, iz, seed) & np.uint64(0xFFFFFF)).astype(np.float64) / float(0x1000000)


def noise3(P, seed=0):
    """Smooth value noise in [0,1] for points P (...,3)."""
    P = np.asarray(P, dtype=np.float64)
    i = np.floor(P)
    f = P - i
    u = f * f * (3 - 2 * f)
    ix, iy, iz = i[..., 0].astype(np.int64), i[..., 1].astype(np.int64), i[..., 2].astype(np.int64)
    acc = 0.0
    for dx in (0, 1):
        wx = u[..., 0] if dx else 1 - u[..., 0]
        for dy in (0, 1):
            wy = u[..., 1] if dy else 1 - u[..., 1]
            for dz in (0, 1):
                wz = u[..., 2] if dz else 1 - u[..., 2]
                acc = acc + wx * wy * wz * _hash01(ix + dx, iy + dy, iz + dz, seed)
    return acc


_ROTS = None


def _rots():
    global _ROTS
    if _ROTS is None:
        rng = np.random.default_rng(1234)
        rs = []
        for _ in range(8):
            q, _ = np.linalg.qr(rng.normal(size=(3, 3)))
            rs.append(q)
        _ROTS = rs
    return _ROTS


def fbm(P, octaves=4, freq=1.0, lac=2.03, gain=0.5, seed=0):
    """Fractal value noise in ~[0,1]. Octaves are rotated to hide lattice artefacts."""
    P = np.asarray(P, dtype=np.float64)
    amp = 1.0
    tot = 0.0
    norm = 0.0
    rs = _rots()
    for o in range(octaves):
        Q = (P * freq) @ rs[o % len(rs)].T
        tot = tot + amp * noise3(Q, seed + 101 * o)
        norm += amp
        amp *= gain
        freq *= lac
    return tot / norm


def ridged(P, octaves=3, freq=1.0, seed=0, sharp=8.0):
    """Ridge lines (vein-like): 1 near the zero set of a noise field."""
    n = fbm(P, octaves, freq, seed=seed) * 2 - 1
    return np.exp(-np.abs(n) * sharp)


def worley(P, freq=1.0, seed=0, jitter=1.0):
    """Cellular noise: returns (F1, F2, cell_id_hash01) with distances in cell units."""
    P = np.asarray(P, dtype=np.float64) * freq
    c = np.floor(P)
    ci = c.astype(np.int64)
    F1 = np.full(P.shape[:-1], 9.0)
    F2 = np.full(P.shape[:-1], 9.0)
    cid = np.zeros(P.shape[:-1])
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                gx, gy, gz = ci[..., 0] + dx, ci[..., 1] + dy, ci[..., 2] + dz
                fx = gx + 0.5 + (_hash01(gx, gy, gz, seed) - 0.5) * jitter
                fy = gy + 0.5 + (_hash01(gx, gy, gz, seed + 7) - 0.5) * jitter
                fz = gz + 0.5 + (_hash01(gx, gy, gz, seed + 13) - 0.5) * jitter
                d = np.sqrt((P[..., 0] - fx) ** 2 + (P[..., 1] - fy) ** 2 + (P[..., 2] - fz) ** 2)
                h = _hash01(gx, gy, gz, seed + 29)
                closer = d < F1
                F2 = np.where(closer, F1, np.minimum(F2, d))
                cid = np.where(closer, h, cid)
                F1 = np.where(closer, d, F1)
    return F1, F2, cid


def hash_points(n, seed, lo, hi):
    rng = np.random.default_rng(seed)
    return rng.uniform(lo, hi, size=(n, len(lo)))

# =============================================================================================== colour helpers


def C(c):
    return np.asarray(c, dtype=np.float64) / 255.0


def mix(a, b, t):
    t = np.asarray(t, dtype=np.float64)
    if t.ndim and t.shape[-1] != 3:
        t = t[..., None]
    return a * (1 - t) + b * t


def hsv_shift(rgb, dh=0.0, ds=0.0, dv=0.0):
    """Shift hue/sat/value of rgb arrays (...,3) in 0..1 (dh in turns)."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = np.max(rgb, -1); mn = np.min(rgb, -1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-9
    rr = m & (mx == r); gg = m & (mx == g) & ~rr; bb = m & ~rr & ~gg
    h[rr] = ((g - b)[rr] / d[rr]) % 6
    h[gg] = (b - r)[gg] / d[gg] + 2
    h[bb] = (r - g)[bb] / d[bb] + 4
    h = h / 6.0
    s = np.where(mx > 1e-9, d / np.maximum(mx, 1e-9), 0)
    v = mx
    h = (h + dh) % 1.0
    s = np.clip(s + ds, 0, 1)
    v = np.clip(v + dv, 0, 1)
    i = np.floor(h * 6).astype(int) % 6
    f = h * 6 - np.floor(h * 6)
    p = v * (1 - s); q = v * (1 - f * s); t = v * (1 - (1 - f) * s)
    out = np.stack([np.choose(i, [v, q, p, p, t, v]), np.choose(i, [t, v, v, q, p, p]),
                    np.choose(i, [p, p, t, v, v, q])], -1)
    return out

# =============================================================================================== materials


def _get(mat, k, d):
    return mat.get(k, d)


def paint_flat(ctx, mat):
    return np.broadcast_to(C(mat.get('color', (180, 180, 180))), ctx['P'].shape).copy()


def paint_skin(ctx, mat):
    P, N = ctx['P'], ctx['N']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (190, 150, 125)))
    var = mat.get('variation', 0.12)
    col = np.broadcast_to(base, P.shape).copy()
    # large blotches
    b = fbm(P, 4, 0.06, seed=s)
    col = col * (1 + (b[..., None] - 0.5) * 2 * var)
    # second tint (e.g. greenish/bluish decay)
    if 'tint2' in mat:
        t2 = C(mat['tint2'])
        m2 = np.clip((fbm(P, 3, 0.045, seed=s + 5) - 0.45) * 3.0, 0, 1) * mat.get('tint2_amount', 0.6)
        col = mix(col, t2, m2)
    # pores / speckle
    sp = noise3(P * 1.9, s + 11)
    col = col * (1 + (sp[..., None] - 0.5) * mat.get('pores', 0.10))
    # veins
    if mat.get('veins', 0) > 0:
        v = ridged(P, 3, mat.get('vein_freq', 0.22), seed=s + 3, sharp=mat.get('vein_sharp', 14.0))
        v = v * np.clip(fbm(P, 2, 0.05, seed=s + 4) * 1.6 - 0.3, 0, 1)
        col = mix(col, C(mat.get('vein_color', (70, 30, 60))), np.clip(v * mat['veins'], 0, 1))
    # rot / necrosis patches
    if mat.get('rot', 0) > 0:
        f1, f2, cid = worley(P, mat.get('rot_freq', 0.12), seed=s + 21)
        patch = np.clip((fbm(P, 4, 0.09, seed=s + 22) - (0.62 - 0.25 * mat['rot'])) * 4.0, 0, 1)
        rc = mix(C(mat.get('rot_color', (70, 85, 40))), C(mat.get('rot_color2', (45, 35, 25))), cid)
        col = mix(col, rc, patch)
        # wet rim
        rim = np.clip(1 - np.abs(patch - 0.5) * 4, 0, 1) * 0.35
        col = col * (1 - rim[..., None] * 0.5)
    # wounds
    if mat.get('wounds', 0) > 0:
        f1, f2, cid = worley(P, mat.get('wound_freq', 0.09), seed=s + 31)
        sel = cid < mat['wounds'] * 0.35
        w = np.clip(1 - f1 / 0.32, 0, 1) * sel
        wound = mix(C((95, 10, 12)), C((40, 0, 4)), np.clip(1 - f1 / 0.18, 0, 1))
        col = mix(col, wound, np.clip(w * 2.2, 0, 1))
    if mat.get('blood', 0) > 0:
        col = apply_blood(col, P, mat['blood'], s + 41)
    if mat.get('scars', 0) > 0:
        sc = ridged(P, 2, 0.35, seed=s + 51, sharp=30) * (fbm(P, 2, 0.06, seed=s + 52) > 0.55)
        col = mix(col, col * 0.6 + C((120, 40, 50)) * 0.4, np.clip(sc * mat['scars'] * 1.5, 0, 1))
    return col


def apply_blood(col, P, amount, seed, color=(120, 6, 8)):
    sp = fbm(P, 5, 0.11, seed=seed)
    drops = noise3(P * 0.9, seed + 1)
    m = np.clip((sp - (0.70 - 0.22 * amount)) * 6.0, 0, 1)
    m = np.maximum(m, np.clip((drops - (0.93 - 0.08 * amount)) * 12, 0, 1))
    dark = np.clip((sp - 0.75) * 5, 0, 1)
    bc = mix(C(color), C((50, 0, 2)), dark)
    return mix(col, bc, m * 0.92)


def paint_cloth(ctx, mat):
    P, N, uv = ctx['P'], ctx['N'], ctx['uv']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (60, 70, 90)))
    col = np.broadcast_to(base, P.shape).copy()
    # camo / pattern
    if mat.get('camo'):
        cols = [C(c) for c in mat['camo']]
        n1 = fbm(P, 4, mat.get('camo_freq', 0.07), seed=s + 7)
        n2 = fbm(P, 4, mat.get('camo_freq', 0.07) * 1.3, seed=s + 8)
        k = len(cols)
        sel = np.clip((n1 * 1.6 - 0.3) * k, 0, k - 1e-6).astype(int)
        col = np.stack([c for c in cols])[sel]
        col = mix(col, cols[0], (n2 > 0.66) * 0.6)
    # plaid / tartan (3D bands: horizontal by z, vertical by angle around the body)
    if mat.get('plaid'):
        pc = C(mat['plaid'])
        sz = mat.get('plaid_size', 3.0)
        ang = np.arctan2(P[..., 1], P[..., 0]) * 7.0
        h = np.abs(((P[..., 2] / sz) % 2.0) - 1.0)
        v = np.abs(((ang / (sz * 0.35)) % 2.0) - 1.0)
        band = (h < 0.35).astype(float) * 0.55 + (v < 0.35).astype(float) * 0.55
        thin = ((np.abs(((P[..., 2] / sz) % 1.0) - 0.5) < 0.05) | (np.abs(((ang / (sz * 0.35)) % 1.0) - 0.5) < 0.05))
        col = mix(col, pc, np.clip(band, 0, 0.9))
        col = mix(col, C(mat.get('plaid_line', (230, 220, 200))), thin * 0.35)
    # folds: stretched noise along the gravity/limb axis gives soft vertical folds
    fa = mat.get('fold_axis', (0, 0, 1))
    fa = np.asarray(fa, float); fa /= np.linalg.norm(fa)
    Q = P - np.outer(P @ fa, fa) * 0.85
    folds = fbm(Q, 3, mat.get('fold_freq', 0.18), seed=s + 3)
    col = col * (0.78 + 0.44 * folds[..., None])
    # weave
    w = mat.get('weave', 0.07)
    if w:
        q = P * mat.get('weave_freq', 3.1)
        weave = (np.sin(q[..., 0] + q[..., 2]) * np.sin(q[..., 1] - q[..., 2] * 0.7))
        col = col * (1 + w * weave[..., None])
    # stripes (3D bands)
    for st in mat.get('stripes', []):
        n = np.asarray(st['normal'], float); n /= np.linalg.norm(n)
        d = P @ n - st['offset']
        m = np.clip((st['width'] * 0.5 - np.abs(d)) * 3, 0, 1)
        col = mix(col, C(st['color']), m)
    # dirt (towards the bottom and in noise)
    dirt = mat.get('dirt', 0.3)
    if dirt:
        dn = fbm(P, 4, 0.08, seed=s + 17)
        low = np.clip((-P[..., 2] - mat.get('dirt_z', 10)) / 30.0, 0, 1)
        m = np.clip((dn - 0.55) * 3 + low * 0.8, 0, 1) * dirt
        col = mix(col, C(mat.get('dirt_color', (70, 58, 42))), m)
    # stains
    if mat.get('stains', 0):
        f = fbm(P, 3, 0.12, seed=s + 23)
        col = mix(col, col * 0.55, np.clip((f - 0.68) * 6, 0, 1) * mat['stains'])
    # tears: dark holes with frayed edges
    if mat.get('tears', 0) > 0:
        f1, f2, cid = worley(P, mat.get('tear_freq', 0.10), seed=s + 31)
        sel = cid < mat['tears'] * 0.5
        hole = np.clip((0.30 - f1) * 12, 0, 1) * sel
        fray = np.clip((0.38 - f1) * 10, 0, 1) * sel - hole
        col = mix(col, col * 0.55, np.clip(fray, 0, 1))
        inner = C(mat.get('tear_color', (60, 35, 30)))
        col = mix(col, inner, hole)
    if mat.get('blood', 0) > 0:
        col = apply_blood(col, P, mat['blood'], s + 41)
    return col


def paint_metal(ctx, mat):
    P, N = ctx['P'], ctx['N']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (90, 95, 105)))
    col = np.broadcast_to(base, P.shape).copy()
    br = fbm(P * np.array([1, 1, 6.0]), 2, 0.6, seed=s)
    col = col * (0.88 + 0.22 * br[..., None])
    # painted layer with chipping
    if 'paint' in mat:
        pc = C(mat['paint'])
        chip = fbm(P, 5, 0.25, seed=s + 5)
        edge = ctx.get('edge', np.zeros(P.shape[:-1]))
        exposed = np.clip((chip + edge * mat.get('edge_wear', 0.6) - (0.78 - 0.3 * mat.get('chipping', 0.4))) * 8, 0, 1)
        col = mix(pc * (0.9 + 0.2 * br[..., None]), col, exposed)
    else:
        edge = ctx.get('edge', np.zeros(P.shape[:-1]))
        col = col * (1 + edge[..., None] * mat.get('edge_wear', 0.5) * 0.6)
    # panel lines
    if mat.get('panels', 0):
        g = mat['panels']
        q = P / g
        fr = np.abs(q - np.round(q))
        line = np.clip(1 - np.min(fr, -1) * g * 1.2, 0, 1) ** 4
        col = col * (1 - 0.45 * line[..., None])
    # scratches
    if mat.get('scratches', 0.4):
        sc = ridged(P * np.array([1, 1, 0.3]), 2, 0.9, seed=s + 9, sharp=40)
        col = mix(col, np.clip(col * 1.5 + 0.08, 0, 1), np.clip(sc * mat.get('scratches', 0.4), 0, 1))
    if mat.get('rust', 0):
        r = fbm(P, 4, 0.12, seed=s + 13)
        col = mix(col, C((110, 55, 25)) * (0.7 + 0.5 * r[..., None]), np.clip((r - (0.7 - 0.3 * mat['rust'])) * 5, 0, 1))
    # fake specular from the normal (top-front highlight)
    spec = np.clip(N @ np.array([0.35, 0.15, 0.92]), 0, 1) ** 8 * mat.get('shine', 0.35)
    col = col + spec[..., None]
    if mat.get('blood', 0) > 0:
        col = apply_blood(col, P, mat['blood'], s + 41)
    return col


def paint_leather(ctx, mat):
    P = ctx['P']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (70, 50, 35)))
    n = fbm(P, 5, 0.5, seed=s)
    cr = ridged(P, 2, 0.6, seed=s + 1, sharp=20)
    col = base * (0.8 + 0.35 * n[..., None]) * (1 - 0.25 * cr[..., None])
    col = col * (0.9 + 0.2 * fbm(P, 2, 0.05, seed=s + 2)[..., None])
    if mat.get('blood', 0) > 0:
        col = apply_blood(col, P, mat['blood'], s + 41)
    return col


def paint_rubber(ctx, mat):
    P = ctx['P']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (35, 35, 38)))
    n = fbm(P, 3, 0.7, seed=s)
    return base * (0.85 + 0.3 * n[..., None])


def paint_glow(ctx, mat):
    P, N = ctx['P'], ctx['N']
    s = mat.get('seed', 0)
    c1 = C(mat.get('color', (0, 220, 255)))
    c2 = C(mat.get('color2', tuple(min(255, int(x * 0.35 + 180)) for x in mat.get('color', (0, 220, 255)))))
    n = fbm(P, 3, mat.get('freq', 0.3), seed=s)
    t = np.clip(n * 1.4 - 0.2, 0, 1)
    if mat.get('pulse_axis') is not None:
        a = np.asarray(mat['pulse_axis'], float)
        t = np.clip(t * 0.6 + 0.4 * (0.5 + 0.5 * np.sin(P @ a)), 0, 1)
    return mix(c1, c2, t)


def paint_fur(ctx, mat):
    P, uv = ctx['P'], ctx['uv']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (90, 70, 50)))
    tip = C(mat.get('tip', tuple(min(255, int(c * 1.5 + 20)) for c in mat.get('color', (90, 70, 50)))))
    ax = np.asarray(mat.get('axis', (0, 0, 1)), float); ax /= np.linalg.norm(ax)
    # strands: high frequency perpendicular to axis, low along it
    Q = P + np.outer(P @ ax, ax) * (-0.85)
    strands = noise3(Q * 3.2, s)
    clumps = fbm(P, 3, 0.25, seed=s + 1)
    t = np.clip(strands * 0.7 + clumps * 0.5 - 0.15, 0, 1)
    col = mix(base * 0.55, tip, t)
    return col


def paint_hair(ctx, mat):
    m2 = dict(mat)
    m2.setdefault('axis', (0, 0, 1))
    return paint_fur(ctx, m2)


def paint_scales(ctx, mat):
    P, N = ctx['P'], ctx['N']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (60, 90, 50)))
    edgec = C(mat.get('edge_color', tuple(int(c * 0.35) for c in mat.get('color', (60, 90, 50)))))
    f1, f2, cid = worley(P, mat.get('freq', 0.55), seed=s)
    e = np.clip((f2 - f1) * 4.0, 0, 1)
    col = base * (0.75 + 0.5 * cid[..., None])
    col = mix(edgec, col, e)
    hi = np.clip(1 - f1 * 1.6, 0, 1) ** 2 * 0.25
    return np.clip(col + hi[..., None], 0, 1)


def paint_crystal(ctx, mat):
    P, N = ctx['P'], ctx['N']
    s = mat.get('seed', 0)
    c1 = C(mat.get('color', (120, 200, 255)))
    c2 = C(mat.get('color2', (230, 250, 255)))
    f1, f2, cid = worley(P, mat.get('freq', 0.35), seed=s)
    facet = 0.65 + 0.5 * cid
    edge = np.clip(1 - (f2 - f1) * 6, 0, 1)
    col = c1 * facet[..., None]
    col = mix(col, c2, edge * 0.85)
    spark = (noise3(P * 4.0, s + 3) > 0.92) * 0.6
    return np.clip(col + spark[..., None], 0, 1)


def paint_lava(ctx, mat):
    P = ctx['P']
    s = mat.get('seed', 0)
    crust = C(mat.get('color', (35, 28, 26)))
    hot = C(mat.get('hot', (255, 120, 10)))
    core = C(mat.get('core', (255, 230, 120)))
    # warp the cell lookup so cracks are irregular, not a giraffe pattern
    Pw = P + (np.stack([fbm(P, 2, 0.15, seed=s + 5), fbm(P, 2, 0.15, seed=s + 6), fbm(P, 2, 0.15, seed=s + 7)], -1) - 0.5) * 6.0
    f1, f2, cid = worley(Pw, mat.get('freq', 0.32), seed=s)
    d = f2 - f1
    wvar = 0.5 + fbm(P, 3, 0.2, seed=s + 8)
    crack = np.clip(1 - d / (mat.get('crack_width', 0.09) * wvar), 0, 1) ** 1.5
    n = fbm(P, 4, 0.3, seed=s + 1)
    col = crust * (0.6 + 0.7 * n[..., None]) * (0.85 + 0.3 * cid[..., None])
    # heat glow bleeding into the crust next to cracks
    col = mix(col, hot * 0.45, np.clip(1 - d / (0.3 * wvar), 0, 1) ** 3 * 0.6)
    glow = mix(hot, core, np.clip(crack * 1.5 - 0.4, 0, 1))
    col = mix(col, glow, np.clip(crack * 1.6, 0, 1))
    ctx['emissive_mask'] = crack > 0.25
    return col


def paint_bone(ctx, mat):
    P = ctx['P']
    s = mat.get('seed', 0)
    base = C(mat.get('color', (215, 205, 175)))
    n = fbm(P, 4, 0.4, seed=s)
    col = base * (0.8 + 0.3 * n[..., None])
    t = ctx['attrs'].get('t')
    if t is not None:
        rings = 0.5 + 0.5 * np.sin(t * mat.get('rings', 30))
        col = col * (0.9 + 0.1 * rings[..., None])
        tipc = C(mat.get('tip_color', (60, 50, 45)))
        col = mix(col, tipc, np.clip((t - 0.65) * 2.5, 0, 1) * mat.get('tip_dark', 0.7))
    return col


def paint_visor(ctx, mat):
    P, N = ctx['P'], ctx['N']
    c1 = C(mat.get('color', (20, 180, 255)))
    c2 = C(mat.get('color2', (230, 255, 255)))
    band = np.clip(1 - np.abs(N[..., 2] - 0.35) * 4, 0, 1)
    col = mix(c1 * 0.55, c1, np.clip(N[..., 0] * 0.5 + 0.5, 0, 1))
    col = mix(col, c2, band * 0.7)
    return col


def _where(ctx, w):
    """Evaluate a layer condition -> weight array (0..1)."""
    P = ctx['P']
    n = P.shape[0]
    out = np.ones(n)
    if 'meshes' in w:
        names = w['meshes']
        mn = ctx.get('mesh', '')
        if not any(mn.startswith(x) for x in names):
            return np.zeros(n)
    if 'not_meshes' in w:
        mn = ctx.get('mesh', '')
        if any(mn.startswith(x) for x in w['not_meshes']):
            return np.zeros(n)
    soft = w.get('soft', 0.6)
    rag = 0.0
    if w.get('ragged'):
        rag = (fbm(P, 3, w.get('ragged_freq', 0.35), seed=w.get('seed', 9)) - 0.5) * 2 * w['ragged']
    if 'z' in w:
        lo, hi = w['z']
        z = P[..., 2] + rag
        out = out * np.clip((z - lo) / soft + 0.5, 0, 1) * np.clip((hi - z) / soft + 0.5, 0, 1)
    if 't' in w:
        lo, hi = w['t']
        t = ctx['attrs']['t'] + rag * 0.08
        out = out * np.clip((t - lo) / 0.04 + 0.5, 0, 1) * np.clip((hi - t) / 0.04 + 0.5, 0, 1)
    if 'x' in w:
        lo, hi = w['x']
        x = P[..., 0] + rag
        out = out * np.clip((x - lo) / soft + 0.5, 0, 1) * np.clip((hi - x) / soft + 0.5, 0, 1)
    if 'y' in w:
        lo, hi = w['y']
        y = P[..., 1] + rag
        out = out * np.clip((y - lo) / soft + 0.5, 0, 1) * np.clip((hi - y) / soft + 0.5, 0, 1)
    if 'holes' in w:
        # worley holes (torn cloth showing what is below)
        f1, f2, cid = worley(P, w.get('hole_freq', 0.12), seed=w.get('seed', 9) + 3)
        sel = cid < w['holes']
        hole = np.clip((w.get('hole_size', 0.33) - f1 - rag * 0.05) * 10, 0, 1) * sel
        out = out * (1 - hole)
    if 'facing' in w:
        fd = np.asarray(w['facing'], float)
        out = out * np.clip((ctx['N'] @ fd - w.get('facing_min', 0.0)) * 3, 0, 1)
    return out


def paint_layers(ctx, mat):
    """Stack of materials: base material then layers [{'mat': {...}, 'where': {...}, 'edge': color}] .
    'edge' draws a darker/frayed border along the layer boundary (seams, torn edges)."""
    base = mat['base']
    col = PAINTERS[base.get('type', 'flat')](ctx, base)
    for L in mat.get('layers', []):
        w = _where(ctx, L['where'])
        if not np.any(w > 0):
            continue
        lm = L['mat']
        lc = PAINTERS[lm.get('type', 'flat')](ctx, lm)
        if 'emissive_mask' in ctx and lm.get('type') not in EMISSIVE_TYPES:
            ctx['emissive_mask'] = ctx['emissive_mask'] & (w < 0.5)
        if lm.get('type') in EMISSIVE_TYPES:
            em = ctx.get('emissive_mask', np.zeros(len(w), bool))
            ctx['emissive_mask'] = em | (w > 0.5)
        col = mix(col, lc, w)
        if 'edge' in L:
            e = np.clip(1 - np.abs(w - 0.5) * 3.2, 0, 1)
            col = mix(col, C(L['edge']), e * L.get('edge_alpha', 0.6))
    return col


PAINTERS = {
    'flat': paint_flat, 'skin': paint_skin, 'cloth': paint_cloth, 'metal': paint_metal, 'armor': paint_metal,
    'leather': paint_leather, 'rubber': paint_rubber, 'glow': paint_glow, 'fur': paint_fur, 'hair': paint_hair,
    'scales': paint_scales, 'crystal': paint_crystal, 'lava': paint_lava, 'bone': paint_bone, 'horn': paint_bone,
    'visor': paint_visor, 'layers': paint_layers,
}
EMISSIVE_TYPES = {'glow', 'visor'}

# =============================================================================================== decals


def _decal_weight(P, d):
    kind = d.get('kind', 'sphere')
    if kind == 'sphere':
        c = np.asarray(d['center'], float)
        r = d['radius']
        sc = np.asarray(d.get('scale', (1, 1, 1)), float)
        dist = np.linalg.norm((P - c) / sc, axis=-1)
        soft = d.get('soft', 0.25)
        return np.clip((r - dist) / max(r * soft, 1e-6), 0, 1)
    if kind == 'band':
        n = np.asarray(d['normal'], float); n /= np.linalg.norm(n)
        dd = P @ n - d['offset']
        w = np.clip((d['width'] * 0.5 - np.abs(dd)) / max(d.get('soft', 0.3), 1e-6), 0, 1)
        if 'region' in d:
            w = w * _region(P, d['region'])
        return w
    if kind == 'shape':
        # 2D SDF shape projected along an axis
        c = np.asarray(d['center'], float)
        ax_u = np.asarray(d['u'], float); ax_v = np.asarray(d['v'], float)
        ax_n = np.cross(ax_u, ax_v)
        rel = P - c
        u = rel @ ax_u / d['size']; v = rel @ ax_v / d['size']
        depth = np.abs(rel @ ax_n)
        sdf = SHAPES[d['shape']](u, v)
        w = np.clip(-sdf * d['size'] / max(d.get('soft', 0.3), 1e-6), 0, 1)
        w = w * (depth < d.get('depth', 6.0))
        if 'facing' in d:
            pass
        return w
    raise ValueError(kind)


def _region(P, reg):
    lo = np.asarray(reg[0], float); hi = np.asarray(reg[1], float)
    return np.all((P >= lo) & (P <= hi), axis=-1).astype(float)


def _sd_box(u, v, hu, hv):
    du = np.abs(u) - hu; dv = np.abs(v) - hv
    return np.sqrt(np.maximum(du, 0) ** 2 + np.maximum(dv, 0) ** 2) + np.minimum(np.maximum(du, dv), 0)


def _sd_seg(u, v, a, b, r):
    pu, pv = u - a[0], v - a[1]
    bu, bv = b[0] - a[0], b[1] - a[1]
    h = np.clip((pu * bu + pv * bv) / (bu * bu + bv * bv), 0, 1)
    return np.sqrt((pu - bu * h) ** 2 + (pv - bv * h) ** 2) - r


def _sd_vex_logo(u, v):
    """Vexmira emblem: a bold V inside a diamond outline."""
    vshape = np.minimum(_sd_seg(u, v, (-0.42, 0.42), (0.0, -0.40), 0.11), _sd_seg(u, v, (0.42, 0.42), (0.0, -0.40), 0.11))
    dia = np.abs(np.abs(u) + np.abs(v) - 0.92) - 0.07
    return np.minimum(vshape, dia)


SHAPES = {
    'circle': lambda u, v: np.sqrt(u * u + v * v) - 1.0,
    'ring': lambda u, v: np.abs(np.sqrt(u * u + v * v) - 0.8) - 0.15,
    'diamond': lambda u, v: (np.abs(u) + np.abs(v) - 1.0) * 0.7071,
    'box': lambda u, v: _sd_box(u, v, 1.0, 1.0),
    'bar': lambda u, v: _sd_box(u, v, 1.0, 0.25),
    'cross': lambda u, v: np.minimum(_sd_box(u, v, 1.0, 0.25), _sd_box(u, v, 0.25, 1.0)),
    'chevron': lambda u, v: np.minimum(_sd_seg(u, v, (-0.8, 0.3), (0, -0.4), 0.18), _sd_seg(u, v, (0.8, 0.3), (0, -0.4), 0.18)),
    'vex': _sd_vex_logo,
    'skull': lambda u, v: np.minimum(np.maximum(np.sqrt(u * u + (v - 0.2) ** 2) - 0.8,
                                                -np.minimum(np.sqrt((u - 0.32) ** 2 + (v - 0.15) ** 2) - 0.22,
                                                            np.sqrt((u + 0.32) ** 2 + (v - 0.15) ** 2) - 0.22)),
                                     _sd_box(u, v + 0.65, 0.4, 0.2)),
    'slit': lambda u, v: _sd_box(u, v, 1.0, 0.18),
}


def apply_decals(col, P, N, decals, mesh_name, mat_name, emis):
    for d in decals:
        tgt = d.get('target')
        if tgt is not None:
            if isinstance(tgt, str):
                tgt = [tgt]
            if mesh_name not in tgt and mat_name not in tgt:
                continue
        w = _decal_weight(P, d)
        if 'facing' in d:
            fdir = np.asarray(d['facing'], float)
            w = w * np.clip((N @ fdir) * 3, 0, 1)
        if not np.any(w > 0):
            continue
        mode = d.get('mode', 'paint')
        c = C(d.get('color', (255, 255, 255)))
        if 'color2' in d:
            c = mix(c, C(d['color2']), np.clip(1 - w, 0, 1))
        a = d.get('alpha', 1.0)
        if mode == 'paint':
            col = mix(col, c, w * a)
        elif mode == 'multiply':
            col = mix(col, col * c, w * a)
        elif mode == 'add':
            col = np.clip(col + c * (w * a)[..., None], 0, 1)
        elif mode == 'glow':
            col = mix(col, c, w * a)
            emis |= w > 0.3
        elif mode == 'blood':
            col = apply_blood(col, P, d.get('amount', 0.6) * w.max(), d.get('seed', 3))
    return col, emis

# =============================================================================================== AO


def bake_ao(meshes, points, normals, ndirs=48, res=192, max_dist=None, bias=0.6, seed=7, slope_bias=0.0):
    """Visibility-based AO: render orthographic depth maps of the whole rest-pose model from `ndirs`
    directions; a texel is 'lit' from a direction if it is not behind other geometry there."""
    V = np.vstack([m.v for m in meshes])
    tris = np.vstack([m.v[m.f] for m in meshes])
    lo, hi = V.min(0), V.max(0)
    ctr = (lo + hi) / 2
    ext = np.max(hi - lo) * 0.55 + 1
    rng = np.random.default_rng(seed)
    dirs = rng.normal(size=(ndirs * 3, 3))
    dirs /= np.linalg.norm(dirs, axis=1, keepdims=True)
    dirs = dirs[dirs[:, 2] > -0.6][:ndirs]  # less light from below
    vis = np.zeros(len(points))
    wsum = np.zeros(len(points))
    for d in dirs:
        # camera looking along -d (light comes from +d)
        f = -d
        up = np.array([0, 0, 1.0]) if abs(f[2]) < 0.9 else np.array([1.0, 0, 0])
        r = np.cross(f, up); r /= np.linalg.norm(r)
        u = np.cross(r, f)
        def proj(X):
            rel = X - ctr
            return np.stack([(rel @ r) / ext * res / 2 + res / 2, -(rel @ u) / ext * res / 2 + res / 2], -1), rel @ f
        txy, tz = proj(tris.reshape(-1, 3))
        txy = txy.reshape(-1, 3, 2); tz = tz.reshape(-1, 3)
        zb, _, _ = raster(txy, tz, None, res, res, depth_test=True)
        pxy, pz = proj(points)
        ix = np.clip(pxy[:, 0].astype(int), 0, res - 1); iy = np.clip(pxy[:, 1].astype(int), 0, res - 1)
        # sample a 3x3 min to be conservative
        zmin = zb[iy, ix]
        w = np.clip(normals @ d, 0, 1)
        sb = 0.0
        if slope_bias:   # slope-scaled depth bias (big flat faces at grazing light: no triangle acne)
            sb = slope_bias * (2 * ext / res) * np.sqrt(np.clip(1 - w * w, 0, 1)) / np.maximum(w, 0.15)
        lit = pz <= zmin + bias + ext * 0.004 + sb
        vis += lit * w
        wsum += w
    ao = vis / np.maximum(wsum, 1e-6)
    return ao

# =============================================================================================== baking


def bake_textures(meshes, pages, materials, decals=(), ao=True, ao_strength=0.75, toplight=0.18,
                  ao_dirs=40, seed=0, ao_pose=None, ao_slope_bias=0.0):
    """Paint all pages. Returns list of dicts {'name','rgb' (h,w,3) uint8, 'mask' (h,w) bool|None,
    'emissive' (h,w) bool}."""
    out = []
    # global AO samples are computed per page on texel positions
    for pi, page in enumerate(pages):
        W, H = page['w'], page['h']
        ids = page['islands']
        tri_xy, tri_attr, tri_mesh = [], [], []
        for mi in ids:
            m = meshes[mi]
            px = np.column_stack([m.attrs['_px'], m.attrs['_py']])
            # two-sided meshes share texels between both sides: draw the back faces first so the front
            # (outward) faces overwrite them (otherwise AO / light are baked for the inner side)
            mf = m.f
            bk = m.attrs.get('_back')
            if bk is not None and len(bk) == len(m.v):
                mf = m.f[np.argsort(-bk[m.f].min(1), kind='stable')]
            xy = px[mf]
            # attributes: P(3) N(3) uv(2) t theta
            t = m.attrs.get('t', np.zeros(len(m.v)))
            th = m.attrs.get('theta', np.zeros(len(m.v)))
            A = np.column_stack([m.v, m.n, m.uv, t, th])
            tri_xy.append(xy)
            tri_attr.append(A[mf])
            tri_mesh.append(np.full(len(m.f), mi))
        tri_xy = np.vstack(tri_xy); tri_attr = np.vstack(tri_attr); tri_mesh = np.concatenate(tri_mesh)
        # make orientation irrelevant (UV islands may be mirrored)
        _, attr, tid = raster(tri_xy, None, tri_attr, W, H, depth_test=False)
        valid = tid >= 0
        mesh_of = np.full((H, W), -1)
        mesh_of[valid] = tri_mesh[tid[valid]]
        # island-local coverage edges (for edge wear): distance from each texel to the coverage border
        from scipy import ndimage
        edge_dist = ndimage.distance_transform_edt(valid)
        # dilate attributes and mesh ids into the padding
        attr = dilate(attr, valid)
        mesh_of = dilate(mesh_of, valid)
        rgb = np.zeros((H, W, 3))
        emis = np.zeros((H, W), bool)
        mask = np.zeros((H, W), bool)
        P_all = attr[..., 0:3]
        N_all = attr[..., 3:6]
        nn = np.linalg.norm(N_all, axis=-1, keepdims=True)
        N_all = N_all / np.maximum(nn, 1e-9)
        for mi in ids:
            m = meshes[mi]
            sel = mesh_of == mi
            if not sel.any():
                continue
            mat = materials.get(m.mat, {'type': 'flat', 'color': (200, 0, 200)})
            ctx = dict(P=P_all[sel], N=N_all[sel], uv=attr[..., 6:8][sel], mesh=m.name,
                       attrs={'t': attr[..., 8][sel], 'theta': attr[..., 9][sel]},
                       edge=np.clip(1 - edge_dist[sel] / mat.get('edge_px', 3.0), 0, 1))
            painter = PAINTERS[mat.get('type', 'flat')]
            col = painter(ctx, mat)
            e = np.zeros(sel.sum(), bool)
            if mat.get('type') in EMISSIVE_TYPES or mat.get('emissive'):
                e[:] = True
            if 'emissive_mask' in ctx:
                e |= ctx['emissive_mask']
            col, e = apply_decals(col, ctx['P'], ctx['N'], [d for d in decals], m.name, m.mat, e)
            rgb[sel] = col
            emis[sel] = e
            if mat.get('masked'):
                mk = mat['masked'](ctx) if callable(mat['masked']) else np.zeros(sel.sum(), bool)
                mask[sel] = mk
        # AO + top light
        if ao:
            pts = P_all[valid]
            nrm = N_all[valid]
            ao_meshes = meshes
            if ao_pose is not None:
                # occlusion is computed in a spread 'AO pose' (arms/legs away from the body) so limbs do not
                # bake shadows onto the torso that would be wrong in every real animation
                tri_bone = np.concatenate([meshes[mi].bone[meshes[mi].f[:, 0]] for mi in ids])
                tb = tri_bone[tid[valid]]
                M = ao_pose[tb]
                pts = np.einsum('nij,nj->ni', M[:, :, :3], pts) + M[:, :, 3]
                nrm = np.einsum('nij,nj->ni', M[:, :, :3], nrm)
                ao_meshes = []
                for mm in meshes:
                    pm = mm.copy()
                    Mv = ao_pose[mm.bone]
                    pm.v = np.einsum('nij,nj->ni', Mv[:, :, :3], mm.v) + Mv[:, :, 3]
                    ao_meshes.append(pm)
            a = bake_ao(ao_meshes, pts + nrm * 0.15, nrm, ndirs=ao_dirs, slope_bias=ao_slope_bias)
            aomap = np.ones((H, W))
            aomap[valid] = a
            aomap = dilate(aomap, valid)
            shade = (1 - ao_strength) + ao_strength * np.clip(aomap * 1.25, 0, 1)
        else:
            shade = np.ones((H, W))
        top = 1 + toplight * (N_all[..., 2] * 0.8 + N_all[..., 0] * 0.2)
        shade = shade * top
        rgb = np.where(emis[..., None], rgb, rgb * shade[..., None])
        out.append(dict(name=page['name'], rgb=(np.clip(rgb, 0, 1) * 255).astype(np.uint8),
                        mask=mask if mask.any() else None, emissive=emis))
    return out
