# Vexmira ozel sprite'lari (GoldSrc SPR v2). Gri tonlu olanlar oyunda rendercolor ile boyanir.
import os, sys, struct
import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 else '/home/user/claude/cstrike/sprites/vexmira'

SPR_VP_PARALLEL = 2
SPR_ORIENTED = 3
SPR_ADDITIVE = 1


def palette_grey():
    return [(i, i, i) for i in range(256)]


def palette_ramp(stops):
    # stops: [(indeks, (r,g,b)), ...]
    pal = []
    for i in range(256):
        for k in range(len(stops) - 1):
            a, ca = stops[k]
            b, cb = stops[k + 1]
            if a <= i <= b:
                t = (i - a) / max(1, b - a)
                pal.append(tuple(int(round(ca[j] + (cb[j] - ca[j]) * t)) for j in range(3)))
                break
    return pal


def write_spr(path, frames, sprtype, pal, texfmt=SPR_ADDITIVE):
    h, w = frames[0].shape
    with open(path, 'wb') as f:
        f.write(b'IDSP')
        f.write(struct.pack('<iiifiiifi', 2, sprtype, texfmt, float(np.hypot(w / 2, h / 2)), w, h, len(frames), 0.0, 0))
        f.write(struct.pack('<h', 256))
        for c in pal:
            f.write(bytes(c))
        for fr in frames:
            f.write(struct.pack('<i', 0))  # SPR_SINGLE
            f.write(struct.pack('<iiii', -w // 2, h // 2, w, h))
            f.write(np.clip(fr, 0, 255).astype(np.uint8).tobytes())


def validate(path):
    d = open(path, 'rb').read()
    assert d[:4] == b'IDSP'
    ver, typ, fmt, rad, w, h, nf, bl, sync = struct.unpack('<iiifiiifi', d[4:40])
    assert ver == 2 and nf >= 1
    pc = struct.unpack('<h', d[40:42])[0]
    pos = 42 + pc * 3
    for _ in range(nf):
        ft = struct.unpack('<i', d[pos:pos + 4])[0]
        ox, oy, fw, fh = struct.unpack('<iiii', d[pos + 4:pos + 20])
        assert ft == 0 and fw == w and fh == h
        pos += 20 + fw * fh
    assert pos == len(d), (pos, len(d))
    return w, h, nf, typ


def grid(n):
    y, x = np.mgrid[0:n, 0:n]
    c = (n - 1) / 2.0
    dx, dy = (x - c) / c, (y - c) / c
    return np.hypot(dx, dy), np.arctan2(dy, dx), dx, dy


def zone(n=256):
    # yere yatik tehlike alani: parlak dis halka + yumusak dolgu + ic halkalar + uyari cizgileri
    r, a, _, _ = grid(n)
    ring = np.exp(-((r - 0.93) / 0.03) ** 2)
    glow = np.exp(-((r - 0.93) / 0.09) ** 2) * 0.45
    fill = np.clip(1 - r, 0, 1) ** 0.3 * 0.18 * (r < 0.95)
    inner = np.exp(-((r - 0.62) / 0.012) ** 2) * 0.45 + np.exp(-((r - 0.32) / 0.012) ** 2) * 0.35
    ticks = ((np.abs(((a / (2 * np.pi)) * 24) % 1 - 0.5) < 0.12) & (r > 0.78) & (r < 0.88)) * 0.7
    img = np.clip(ring + glow + fill + inner + ticks, 0, 1) * (r <= 1.0)
    return (img * 255).astype(np.uint8)


def target(n=64):
    r, a, dx, dy = grid(n)
    circle = np.exp(-((r - 0.72) / 0.05) ** 2)
    cross = (((np.abs(dx) < 0.05) | (np.abs(dy) < 0.05)) & (r > 0.35) & (r < 0.98)) * 0.9
    dot = np.exp(-(r / 0.09) ** 2)
    img = np.clip(circle + cross + dot, 0, 1) * (r <= 1.0)
    return (img * 255).astype(np.uint8)


def beacon(n=128):
    r, a, dx, dy = grid(n)
    core = np.exp(-(r / 0.12) ** 2)
    halo = np.exp(-(r / 0.45) ** 2) * 0.55
    rays = (np.abs(np.cos(a * 4)) ** 24) * np.exp(-(r / 0.85) ** 2) * 0.7
    rays2 = (np.abs(np.cos(a * 4 + np.pi / 4)) ** 40) * np.exp(-(r / 0.55) ** 2) * 0.45
    img = np.clip(core + halo + rays + rays2, 0, 1) * (r <= 1.0)
    return (img * 255).astype(np.uint8)


def orb(n=64):
    r, a, _, _ = grid(n)
    core = np.exp(-(r / 0.22) ** 2)
    shell = np.exp(-((r - 0.55) / 0.12) ** 2) * (0.6 + 0.4 * np.cos(a * 5)) * 0.6
    halo = np.exp(-(r / 0.75) ** 2) * 0.35
    img = np.clip(core + shell + halo, 0, 1) * (r <= 1.0)
    return (img * 255).astype(np.uint8)


def mark(n=64):
    # kuru kafa isareti
    r, a, dx, dy = grid(n)
    head = (np.hypot(dx / 0.62, (dy + 0.12) / 0.58) < 1.0)
    jaw = (np.abs(dx) < 0.32) & (dy > 0.25) & (dy < 0.62)
    eyes = (np.hypot((dx - 0.25) / 0.16, (dy + 0.1) / 0.18) < 1.0) | (np.hypot((dx + 0.25) / 0.16, (dy + 0.1) / 0.18) < 1.0)
    nose = (np.abs(dx) < 0.07) & (dy > 0.12) & (dy < 0.26)
    teeth = jaw & (np.abs((dx * 6) % 1 - 0.5) < 0.12) & (dy > 0.38)
    skull = (head | jaw) & ~eyes & ~nose & ~teeth
    glow = np.exp(-(r / 0.9) ** 2) * 0.25
    img = np.clip(skull * 1.0 + glow * (~skull), 0, 1) * (r <= 1.0)
    return (img * 255).astype(np.uint8)


def fire_frames(n=64, count=8):
    rng = np.random.default_rng(7)
    frames = []
    y, x = np.mgrid[0:n, 0:n]
    xc = (x - (n - 1) / 2) / ((n - 1) / 2)
    yv = y / (n - 1)  # 0 ust, 1 alt
    for k in range(count):
        ph = k / count * 2 * np.pi
        wob = 0.12 * np.sin(yv * 9 + ph) + 0.06 * np.sin(yv * 17 - ph * 2)
        width = 0.15 + 0.55 * yv ** 0.8
        body = np.exp(-((xc - wob) / width) ** 2) * np.clip(yv * 1.3 - 0.05, 0, 1)
        noise = rng.random((n, n))
        flick = 0.75 + 0.25 * noise
        base = np.clip(1.2 - (1 - yv) * 1.1, 0, 1)
        img = np.clip(body * flick * (0.4 + 0.8 * base), 0, 1)
        frames.append((img * 255).astype(np.uint8))
    return frames


def laser(w=32, h=32):
    x = np.linspace(-1, 1, w)
    prof = np.exp(-(x / 0.18) ** 2) + np.exp(-(x / 0.5) ** 2) * 0.35
    img = np.tile(np.clip(prof, 0, 1), (h, 1))
    return (img * 255).astype(np.uint8)


def main():
    os.makedirs(OUT, exist_ok=True)
    grey = palette_grey()
    red = palette_ramp([(0, (0, 0, 0)), (128, (200, 20, 20)), (220, (255, 120, 60)), (255, (255, 230, 200))])
    purple = palette_ramp([(0, (0, 0, 0)), (128, (110, 0, 170)), (220, (210, 90, 255)), (255, (255, 220, 255))])
    firep = palette_ramp([(0, (0, 0, 0)), (70, (120, 10, 0)), (140, (230, 70, 0)), (200, (255, 170, 20)), (255, (255, 250, 210))])
    out = {
        'zone.spr': ([zone()], SPR_ORIENTED, grey),
        'target.spr': ([target()], SPR_VP_PARALLEL, red),
        'beacon.spr': ([beacon()], SPR_VP_PARALLEL, grey),
        'orb.spr': ([orb()], SPR_VP_PARALLEL, grey),
        'mark.spr': ([mark()], SPR_VP_PARALLEL, purple),
        'fire.spr': (fire_frames(), SPR_VP_PARALLEL, firep),
        'laser.spr': ([laser()], SPR_VP_PARALLEL, grey),
    }
    for name, (frames, typ, pal) in out.items():
        p = os.path.join(OUT, name)
        write_spr(p, frames, typ, pal)
        print(name, validate(p), os.path.getsize(p), 'bayt')


if __name__ == '__main__':
    main()
