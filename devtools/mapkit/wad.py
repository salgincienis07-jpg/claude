"""WAD3 (Half-Life / GoldSrc texture wad) reader + writer.

Every texture is stored as a miptex lump (type 0x43):

    char  name[16]
    uint  width, height              (multiples of 16)
    uint  offsets[4]                 (mip 0..3, relative to lump start)
    byte  mip0[w*h], mip1[w*h/4], mip2[w*h/16], mip3[w*h/64]
    short palette_count (=256)
    byte  palette[256*3]
    (padding to 4 bytes)

Name prefixes understood by the engine / compilers:

    !name       liquid (turbulent warp, CONTENTS_WATER; !lava* / !slime* special)
    {name       masked: palette index 255 is transparent (palette[255] = 0,0,255)
    +0name..+9name   animated sequence (+a..+j = alternate sequence)
    -0name..-9name   random tiling variants
    ~name       convention for texture lights (handled by RAD via .rad file)
    sky         sky (CSG makes CONTENTS_SKY, engine draws the skybox)

Images enter as RGB(A) numpy arrays / PIL images; each texture gets its own
256 colour palette (median cut, optional dithering). Mip levels are box
filtered from the full colour image and remapped to the same palette.
"""
from __future__ import annotations

import struct
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional, Tuple

import numpy as np
from PIL import Image

MAX_NAME = 15  # 16 bytes incl. NUL
TYP_MIPTEX = 0x43


@dataclass
class MipTex:
    name: str
    width: int
    height: int
    mips: List[bytes]           # 4 levels of palette indices
    palette: bytes              # 768 bytes

    # ------------------------------------------------------------------
    def to_lump(self) -> bytes:
        """Serialise as a miptex lump (also the BSP embedded format)."""
        name = self.name.encode('ascii')[:MAX_NAME].ljust(16, b'\0')
        hdr = 16 + 4 + 4 + 16
        offs = []
        o = hdr
        for m in self.mips:
            offs.append(o)
            o += len(m)
        body = name + struct.pack('<II4I', self.width, self.height, *offs)
        body += b''.join(self.mips)
        body += struct.pack('<H', 256) + self.palette
        while len(body) % 4:
            body += b'\0'
        return body

    @classmethod
    def from_lump(cls, data: bytes, fallback_name: str = '') -> 'MipTex':
        name = data[:16].split(b'\0')[0].decode('ascii', 'replace') or fallback_name
        w, h = struct.unpack('<II', data[16:24])
        offs = struct.unpack('<4I', data[24:40])
        mips = []
        if offs[0] == 0:          # external texture (no pixel data)
            return cls(name, w, h, [], b'')
        for i in range(4):
            sz = (w >> i) * (h >> i)
            mips.append(bytes(data[offs[i]:offs[i] + sz]))
        pal_ofs = offs[3] + (w >> 3) * (h >> 3)
        n = struct.unpack('<H', data[pal_ofs:pal_ofs + 2])[0]
        pal = bytes(data[pal_ofs + 2:pal_ofs + 2 + n * 3]).ljust(768, b'\0')
        return cls(name, w, h, mips, pal)

    # ------------------------------------------------------------------
    def to_rgb(self, level: int = 0) -> np.ndarray:
        """Decode a mip level to an (h, w, 3) uint8 array."""
        w, h = self.width >> level, self.height >> level
        idx = np.frombuffer(self.mips[level], np.uint8).reshape(h, w)
        pal = np.frombuffer(self.palette, np.uint8).reshape(256, 3)
        return pal[idx]

    def to_rgba(self, level: int = 0) -> np.ndarray:
        rgb = self.to_rgb(level)
        a = np.full(rgb.shape[:2] + (1,), 255, np.uint8)
        if self.name.startswith('{'):
            w, h = self.width >> level, self.height >> level
            idx = np.frombuffer(self.mips[level], np.uint8).reshape(h, w)
            a[idx == 255] = 0
        return np.concatenate([rgb, a], axis=2)


# ----------------------------------------------------------------------
# Image -> MipTex conversion
# ----------------------------------------------------------------------
def _box_down(img: np.ndarray, f: int) -> np.ndarray:
    h, w = img.shape[:2]
    c = img.shape[2]
    return img.reshape(h // f, f, w // f, f, c).mean(axis=(1, 3))


def make_miptex(name: str, image, dither: bool = False,
                masked: Optional[bool] = None) -> MipTex:
    """Build a MipTex from an RGB/RGBA image (numpy float 0..1 / uint8 or PIL).

    masked: if True (default when name starts with '{'), pixels with alpha<128
    map to palette index 255 (blue key 0,0,255), all others use indices 0..254.
    """
    if len(name) > MAX_NAME:
        raise ValueError(f'texture name too long (>15): {name}')
    if isinstance(image, Image.Image):
        arr = np.asarray(image.convert('RGBA')).astype(np.float32) / 255.0
    else:
        arr = np.asarray(image, dtype=np.float32)
        if arr.max() > 1.5:
            arr = arr / 255.0
        if arr.ndim == 2:
            arr = np.stack([arr] * 3, -1)
        if arr.shape[2] == 3:
            arr = np.concatenate([arr, np.ones(arr.shape[:2] + (1,), np.float32)], 2)
    arr = np.clip(arr, 0, 1)
    h, w = arr.shape[:2]
    if w % 16 or h % 16:
        raise ValueError(f'{name}: size {w}x{h} not a multiple of 16')
    if masked is None:
        masked = name.startswith('{')

    rgb = arr[..., :3]
    alpha = arr[..., 3]
    ncol = 255 if masked else 256
    dmode = Image.Dither.FLOYDSTEINBERG if dither else Image.Dither.NONE

    # palette from the full-res image (+ the mips so small levels stay faithful)
    src = (rgb * 255 + 0.5).astype(np.uint8)
    if masked:
        opaque = alpha >= 0.5
        if opaque.any():
            pix = src[opaque]
        else:
            pix = np.zeros((1, 3), np.uint8)
        side = int(np.ceil(np.sqrt(len(pix))))
        pad = np.zeros((side * side, 3), np.uint8)
        pad[:len(pix)] = pix
        pad[len(pix):] = pix[0]
        pal_src = Image.fromarray(pad.reshape(side, side, 3), 'RGB')
    else:
        pal_src = Image.fromarray(src, 'RGB')
    q = pal_src.quantize(colors=ncol, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pal = list(q.getpalette()[:ncol * 3])
    pal += [0] * (ncol * 3 - len(pal))
    if masked:
        pal += [0, 0, 255]
    else:
        pal = pal[:768]
    palimg = Image.new('P', (1, 1))
    # quantize(palette=) uses the first 256 entries; for masked textures make
    # index 255 unreachable by duplicating entry 0 into it for the mapping step
    map_pal = list(pal)
    if masked:
        map_pal[765:768] = map_pal[0:3]
    palimg.putpalette(map_pal)

    mips = []
    for lvl in range(4):
        f = 1 << lvl
        if f == 1:
            m_rgb, m_a = rgb, alpha
        else:
            m_rgb = _box_down(rgb * (alpha[..., None] if masked else 1.0), f)
            m_a = _box_down(alpha[..., None], f)[..., 0]
            if masked:
                m_rgb = m_rgb / np.maximum(m_a[..., None], 1e-4)
        im = Image.fromarray((np.clip(m_rgb, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGB')
        idx = np.asarray(im.quantize(palette=palimg, dither=dmode), np.uint8).copy()
        if masked:
            idx[idx == 255] = 0
            idx[m_a < 0.5] = 255
        mips.append(idx.tobytes())
    return MipTex(name, w, h, mips, bytes(pal[:768]))


# ----------------------------------------------------------------------
# WAD3 files
# ----------------------------------------------------------------------
def write_wad(path: str, textures: Iterable[MipTex]) -> int:
    """Write a WAD3 file; returns its size in bytes."""
    textures = list(textures)
    names = set()
    data = bytearray(b'WAD3' + b'\0' * 8)
    entries = []
    for t in textures:
        key = t.name.lower()
        if key in names:
            raise ValueError(f'duplicate texture name {t.name}')
        names.add(key)
        lump = t.to_lump()
        entries.append((len(data), len(lump), t.name))
        data += lump
    dir_ofs = len(data)
    for ofs, size, name in entries:
        data += struct.pack('<iiibbbb16s', ofs, size, size, TYP_MIPTEX, 0, 0, 0,
                            name.encode('ascii')[:MAX_NAME].ljust(16, b'\0'))
    struct.pack_into('<ii', data, 4, len(entries), dir_ofs)
    with open(path, 'wb') as f:
        f.write(data)
    return len(data)


def read_wad(path: str) -> Dict[str, MipTex]:
    """Read a WAD2/WAD3 file into {lowercase name: MipTex}."""
    with open(path, 'rb') as f:
        buf = f.read()
    magic, n, ofs = struct.unpack('<4sii', buf[:12])
    if magic not in (b'WAD3', b'WAD2'):
        raise ValueError(f'{path}: not a wad ({magic!r})')
    out = {}
    for i in range(n):
        fp, ds, sz, typ, comp, _, _, nm = struct.unpack('<iiibbbb16s', buf[ofs + 32 * i: ofs + 32 * i + 32])
        name = nm.split(b'\0')[0].decode('ascii', 'replace')
        if typ != TYP_MIPTEX or comp:
            continue
        out[name.lower()] = MipTex.from_lump(buf[fp:fp + ds], name)
    return out


def validate_wad(path: str) -> List[str]:
    """Return a list of problems (empty == OK)."""
    problems = []
    try:
        texs = read_wad(path)
    except Exception as e:  # pragma: no cover
        return [f'unreadable: {e}']
    for k, t in texs.items():
        if len(t.name) > MAX_NAME:
            problems.append(f'{t.name}: name too long')
        if t.width % 16 or t.height % 16:
            problems.append(f'{t.name}: size not /16')
        if t.width > 512 or t.height > 512:
            problems.append(f'{t.name}: larger than 512')
        if len(t.mips) != 4:
            problems.append(f'{t.name}: missing mips')
        if t.name.startswith('{') and t.palette[765:768] != b'\x00\x00\xff':
            problems.append(f'{t.name}: masked texture palette[255] is not blue')
        if t.name.startswith('+'):
            base = t.name[2:].lower()
            frame = t.name[1]
            if frame not in '0123456789abcdefghij':
                problems.append(f'{t.name}: bad animation frame char')
            if frame not in '0a' and f'+0{base}' not in texs and f'+a{base}' not in texs:
                problems.append(f'{t.name}: animation without frame 0')
    return problems
