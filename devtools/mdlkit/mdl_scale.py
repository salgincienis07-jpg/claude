"""mdl_scale - reference implementation of the plugin's giant-boss model scaler (vexmira_core GmPatch).

    cd devtools && python3 -m mdlkit.mdl_scale IN.mdl OUT.mdl --k 1.6

Scales every translational quantity of a GoldSrc IDST v10 studio model by k and lifts the root bones by
36*(k-1) so a CS player model keeps its feet on the floor (origin = hull centre, feet at -36):
header eye/min/max/bbmin/bbmax, bone value[0..2] + scale[0..2] (animated positions = value + delta*scale),
X/Y/Z bone controllers, hitbox boxes, sequence linear movement + boxes, attachments, model bounding
radius and vertices. Rotations, normals, textures and animation data are untouched.
"""
from __future__ import annotations

import argparse
import struct


def _f(b, o):
    return struct.unpack_from('<f', b, o)[0]


def _i(b, o):
    return struct.unpack_from('<i', b, o)[0]


def _sf(b, o, k, add=0.0):
    struct.pack_into('<f', b, o, _f(b, o) * k + add)


def _s3(b, o, k, addz=0.0):
    _sf(b, o, k)
    _sf(b, o + 4, k)
    _sf(b, o + 8, k, addz)


def scale_mdl(data: bytes, k: float) -> bytes:
    b = bytearray(data)
    if _i(b, 0) != 0x54534449 or _i(b, 4) != 10:
        raise ValueError('not an IDST v10 model')
    lift = 36.0 * (k - 1.0)
    for o in (76, 88, 100, 112, 124):
        _s3(b, o, k, lift)
    nb, bi = _i(b, 140), _i(b, 144)
    for n in range(nb):
        o = bi + n * 112
        parent = _i(b, o + 32)
        _sf(b, o + 64, k)
        _sf(b, o + 68, k)
        _sf(b, o + 72, k, lift if parent < 0 else 0.0)
        for j in range(3):
            _sf(b, o + 88 + 4 * j, k)
    nc, ci = _i(b, 148), _i(b, 152)
    for n in range(min(nc, 64)):
        o = ci + n * 24
        if _i(b, o + 4) & 7:
            _sf(b, o + 8, k)
            _sf(b, o + 12, k)
    nh, hi = _i(b, 156), _i(b, 160)
    for n in range(min(nh, 256)):
        o = hi + n * 32
        _s3(b, o + 8, k)
        _s3(b, o + 20, k)
    ns, si = _i(b, 164), _i(b, 168)
    for n in range(min(ns, 1024)):
        o = si + n * 176
        _s3(b, o + 76, k)
        _s3(b, o + 96, k, lift)
        _s3(b, o + 108, k, lift)
    na, ai = _i(b, 212), _i(b, 216)
    for n in range(min(na, 16)):
        _s3(b, ai + n * 88 + 40, k)
    nbp, bpi = _i(b, 204), _i(b, 208)
    for p in range(min(nbp, 32)):
        o = bpi + p * 76
        nm, mi = _i(b, o + 64), _i(b, o + 72)
        for m in range(min(nm, 64)):
            mo = mi + m * 112
            _sf(b, mo + 68, k)
            nv, vi = _i(b, mo + 80), _i(b, mo + 88)
            for v in range(min(nv, 32768)):
                _s3(b, vi + v * 12, k)
    return bytes(b)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('dst')
    ap.add_argument('--k', type=float, default=1.6)
    a = ap.parse_args(argv)
    open(a.dst, 'wb').write(scale_mdl(open(a.src, 'rb').read(), a.k))
    print('wrote', a.dst)


if __name__ == '__main__':
    main()
