"""8-bit indexed BMP writer + palette quantisation tuned for GoldSrc model skins.

* write_bmp8(path, indices(h,w) uint8, palette(256,3) uint8) writes a bottom-up BI_RGB 8-bit BMP with a
  full 256-entry palette (what studiomdl's LoadBMP expects).
* quantize(rgb(h,w,3) uint8|float, ncolors=256, mask=None, dither=...) -> (indices, palette)
  Median-cut seed (Pillow) refined by k-means in a perceptual-ish space, then optional ordered (Bayer)
  dithering against the final palette. If `mask` (bool h,w; True = transparent) is given, index 255 is
  reserved for the transparent key colour (0,0,255) as GoldSrc 'masked' textures require.
"""
import struct
import numpy as np
from PIL import Image

TRANSPARENT_KEY = (0, 0, 255)


def write_bmp8(path, idx, pal):
    idx = np.asarray(idx, dtype=np.uint8)
    h, w = idx.shape
    pal = np.zeros((256, 3), dtype=np.uint8) if pal is None else np.asarray(pal, dtype=np.uint8)
    if pal.shape[0] < 256:
        pal = np.vstack([pal, np.zeros((256 - pal.shape[0], 3), dtype=np.uint8)])
    row = (w + 3) & ~3
    data = np.zeros((h, row), dtype=np.uint8)
    data[:, :w] = idx
    data = data[::-1]  # bottom-up
    pal_bytes = np.zeros((256, 4), dtype=np.uint8)
    pal_bytes[:, 0] = pal[:, 2]
    pal_bytes[:, 1] = pal[:, 1]
    pal_bytes[:, 2] = pal[:, 0]
    off = 14 + 40 + 1024
    size = off + data.size
    with open(path, 'wb') as f:
        f.write(struct.pack('<2sIHHI', b'BM', size, 0, 0, off))
        f.write(struct.pack('<IiiHHIIiiII', 40, w, h, 1, 8, 0, data.size, 2835, 2835, 256, 256))
        f.write(pal_bytes.tobytes())
        f.write(data.tobytes())


def read_bmp8(path):
    with open(path, 'rb') as f:
        b = f.read()
    off = struct.unpack_from('<I', b, 10)[0]
    w, h = struct.unpack_from('<ii', b, 18)
    bpp = struct.unpack_from('<H', b, 28)[0]
    assert bpp == 8, 'not 8-bit'
    ncol = struct.unpack_from('<I', b, 46)[0] or 256
    pal = np.frombuffer(b, dtype=np.uint8, count=ncol * 4, offset=54).reshape(-1, 4)[:, [2, 1, 0]]
    row = (w + 3) & ~3
    data = np.frombuffer(b, dtype=np.uint8, count=row * abs(h), offset=off).reshape(abs(h), row)[:, :w]
    if h > 0:
        data = data[::-1]
    full = np.zeros((256, 3), dtype=np.uint8)
    full[:len(pal)] = pal
    return data.copy(), full


def _to_space(c):
    # cheap perceptual weighting (approximates Lab distances well enough for palettes)
    c = c.astype(np.float32)
    return c * np.array([0.9, 1.2, 0.7], dtype=np.float32)


def _kmeans(samples, centers, iters=8):
    s = _to_space(samples)
    for _ in range(iters):
        cs = _to_space(centers)
        # chunked nearest-centre search
        lab = np.empty(len(s), dtype=np.int32)
        for i in range(0, len(s), 32768):
            d = ((s[i:i + 32768, None, :] - cs[None, :, :]) ** 2).sum(-1)
            lab[i:i + 32768] = d.argmin(1)
        newc = centers.astype(np.float64).copy()
        cnt = np.bincount(lab, minlength=len(centers))
        for ch in range(3):
            sm = np.bincount(lab, weights=samples[:, ch].astype(np.float64), minlength=len(centers))
            nz = cnt > 0
            newc[nz, ch] = sm[nz] / cnt[nz]
        centers = newc
    return np.clip(np.round(centers), 0, 255).astype(np.uint8)


def nearest_indices(rgb, pal):
    flat = rgb.reshape(-1, 3)
    ps = _to_space(pal)
    out = np.empty(len(flat), dtype=np.uint8)
    fs = _to_space(flat)
    for i in range(0, len(flat), 32768):
        d = ((fs[i:i + 32768, None, :] - ps[None, :, :]) ** 2).sum(-1)
        out[i:i + 32768] = d.argmin(1)
    return out.reshape(rgb.shape[:2])


def _bayer(n=8):
    m = np.array([[0]])
    while m.shape[0] < n:
        m = np.block([[4 * m, 4 * m + 2], [4 * m + 3, 4 * m + 1]])
    return (m + 0.5) / (m.size)


def ordered_dither(rgb, pal, amplitude):
    """Vectorised ordered (Bayer 8x8) dithering: adds a +-amplitude/2 threshold pattern before
    nearest-palette mapping. amplitude ~ 4..12 RGB units hides banding without visible grain."""
    h, w, _ = rgb.shape
    b = _bayer(8)
    t = np.tile(b, (h // 8 + 1, w // 8 + 1))[:h, :w] - 0.5
    img = np.clip(rgb.astype(np.float32) + t[..., None] * amplitude, 0, 255)
    return nearest_indices(img, pal)


def quantize(rgb, ncolors=256, mask=None, dither=0.0, seed=1):
    """rgb: (h,w,3) uint8 or float 0..255. Returns (indices uint8 (h,w), palette (256,3) uint8)."""
    rgb = np.clip(np.asarray(rgb, dtype=np.float32), 0, 255).astype(np.uint8)
    h, w, _ = rgb.shape
    ncol = ncolors
    if mask is not None:
        ncol = min(ncolors, 255)
    opaque = rgb.reshape(-1, 3) if mask is None else rgb[~mask]
    if len(opaque) == 0:
        opaque = np.zeros((1, 3), dtype=np.uint8)
    uniq = np.unique(opaque, axis=0)
    if len(uniq) <= ncol:
        pal = np.zeros((256, 3), dtype=np.uint8)
        pal[:len(uniq)] = uniq
        idx = nearest_indices(rgb, pal[:len(uniq)])
    else:
        # median cut seed via Pillow on a sample image
        rng = np.random.default_rng(seed)
        n = min(len(opaque), 200000)
        sample = opaque[rng.choice(len(opaque), n, replace=False)] if len(opaque) > n else opaque
        side = int(np.ceil(np.sqrt(len(sample))))
        pad = np.zeros((side * side, 3), dtype=np.uint8)
        pad[:len(sample)] = sample
        pad[len(sample):] = sample[: side * side - len(sample)] if len(sample) >= side * side - len(sample) else sample[0]
        im = Image.fromarray(pad.reshape(side, side, 3), 'RGB')
        q = im.quantize(colors=ncol, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        seedpal = np.array(q.getpalette()[:ncol * 3], dtype=np.uint8).reshape(-1, 3)
        km_n = min(len(sample), 60000)
        kms = sample[rng.choice(len(sample), km_n, replace=False)] if len(sample) > km_n else sample
        cent = _kmeans(kms, seedpal, iters=6)
        pal = np.zeros((256, 3), dtype=np.uint8)
        pal[:ncol] = cent
        if dither and dither > 0:
            idx = ordered_dither(rgb, pal[:ncol], float(dither))
        else:
            idx = nearest_indices(rgb, pal[:ncol])
    if mask is not None:
        pal[255] = TRANSPARENT_KEY
        idx = idx.copy()
        idx[idx == 255] = 254
        idx[mask] = 255
    return idx.astype(np.uint8), pal


def save_rgb_as_bmp8(path, rgb, mask=None, dither=0.0, ncolors=256):
    idx, pal = quantize(rgb, ncolors=ncolors, mask=mask, dither=dither)
    write_bmp8(path, idx, pal)
    return idx, pal
