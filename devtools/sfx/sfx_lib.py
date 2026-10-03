# Vexmira ses tasarim kutuphanesi: numpy/scipy ile prosedurel ses uretimi.
# Cikti: mono, 16 bit PCM WAV (dongu / cue noktasi YOK -> GoldSrc'de susmama sorunu olmaz)
import numpy as np
from scipy import signal
import wave, struct, os

rng = np.random.default_rng(20261002)


class Ctx:
    sr = 22050


def n_of(d, sr=None):
    return max(1, int(round((sr or Ctx.sr) * d)))


def tt(d, sr=None):
    sr = sr or Ctx.sr
    return np.arange(n_of(d, sr)) / sr


# ---------------- osilatorler ----------------

def _phase(freq, d):
    n = n_of(d)
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,)) if np.ndim(freq) else np.full(n, float(freq))
    return 2 * np.pi * np.cumsum(f) / Ctx.sr


def sine(freq, d, phase=0.0):
    return np.sin(_phase(freq, d) + phase)


def saw(freq, d, harmonics=None):
    # bant sinirli testere: harmonik toplami (aliasing yok)
    n = n_of(d)
    f = np.full(n, float(freq)) if np.ndim(freq) == 0 else np.asarray(freq, float)
    ph = 2 * np.pi * np.cumsum(f) / Ctx.sr
    fmax = float(np.max(f))
    k_max = harmonics or max(1, int((Ctx.sr / 2 - 200) / max(fmax, 1)))
    k_max = min(k_max, 60)
    out = np.zeros(n)
    for k in range(1, k_max + 1):
        amp = 1.0 / k
        # yuksek frekansli harmoniklerde Nyquist ustunu kes
        mask = (f * k) < (Ctx.sr / 2 - 100)
        out += amp * np.sin(k * ph) * mask
    return out * 0.6


def square(freq, d, harmonics=None):
    n = n_of(d)
    f = np.full(n, float(freq)) if np.ndim(freq) == 0 else np.asarray(freq, float)
    ph = 2 * np.pi * np.cumsum(f) / Ctx.sr
    fmax = float(np.max(f))
    k_max = harmonics or max(1, int((Ctx.sr / 2 - 200) / max(fmax, 1)))
    k_max = min(k_max, 40)
    out = np.zeros(n)
    for k in range(1, k_max + 1, 2):
        mask = (f * k) < (Ctx.sr / 2 - 100)
        out += (1.0 / k) * np.sin(k * ph) * mask
    return out * 0.8


def tri(freq, d):
    n = n_of(d)
    f = np.full(n, float(freq)) if np.ndim(freq) == 0 else np.asarray(freq, float)
    ph = 2 * np.pi * np.cumsum(f) / Ctx.sr
    out = np.zeros(n)
    for i, k in enumerate(range(1, 16, 2)):
        mask = (f * k) < (Ctx.sr / 2 - 100)
        out += ((-1) ** i) / (k * k) * np.sin(k * ph) * mask
    return out * 0.8


def fm(carrier, mod_ratio, index, d, index_env=None):
    n = n_of(d)
    t = tt(d)
    mod = np.sin(2 * np.pi * carrier * mod_ratio * t)
    ie = index if index_env is None else index * index_env
    return np.sin(2 * np.pi * carrier * t + ie * mod)


def noise(d, color='white'):
    n = n_of(d)
    w = rng.standard_normal(n)
    if color == 'white':
        return w / 3.0
    if color == 'pink':
        b, a = [0.049922035, -0.095993537, 0.050612699, -0.004408786], [1, -2.494956002, 2.017265875, -0.522189400]
        return signal.lfilter(b, a, w) * 1.2
    if color == 'brown':
        x = signal.lfilter([1.0], [1.0, -0.997], w)
        x = signal.sosfilt(signal.butter(1, 20 / (Ctx.sr / 2), 'high', output='sos'), x)
        return x / (np.max(np.abs(x)) + 1e-9) * 0.8
    return w


def sweep(f0, f1, d, curve='exp'):
    t = np.linspace(0, 1, n_of(d))
    if curve == 'exp' and f0 > 0 and f1 > 0:
        return f0 * (f1 / f0) ** t
    return f0 + (f1 - f0) * t


# ---------------- zarflar ----------------

def env_exp(d, tau):
    return np.exp(-tt(d) / max(tau, 1e-4))


def env_adsr(d, a=0.01, dc=0.1, s=0.7, r=0.2):
    n = n_of(d)
    na, nd, nr = n_of(a), n_of(dc), n_of(r)
    ns = max(0, n - na - nd - nr)
    e = np.concatenate([np.linspace(0, 1, na, endpoint=False), np.linspace(1, s, nd, endpoint=False),
                        np.full(ns, s), np.linspace(s, 0, nr)])
    return fit(e, n)


def env_lin(points, d):
    # points: [(zaman_orani, deger), ...]
    n = n_of(d)
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return np.interp(np.linspace(0, 1, n), xs, ys)


def fit(x, n):
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


# ---------------- filtreler ----------------

def _sos(kind, f, order=2):
    nyq = Ctx.sr / 2
    if kind == 'band':
        lo, hi = f
        lo = max(10, min(lo, nyq * 0.95))
        hi = max(lo + 10, min(hi, nyq * 0.98))
        return signal.butter(order, [lo / nyq, hi / nyq], btype='band', output='sos')
    f = max(10, min(f, nyq * 0.97))
    return signal.butter(order, f / nyq, btype=kind, output='sos')


def lp(x, f, order=2):
    return signal.sosfilt(_sos('low', f, order), x)


def hp(x, f, order=2):
    return signal.sosfilt(_sos('high', f, order), x)


def bp(x, lo, hi, order=2):
    return signal.sosfilt(_sos('band', (lo, hi), order), x)


def lp_sweep(x, f0, f1, blocks=64, curve='exp'):
    # zamanla degisen alcak geciren (blok blok)
    n = len(x)
    out = np.zeros(n)
    edges = np.linspace(0, n, blocks + 1).astype(int)
    zi = None
    for i in range(blocks):
        a, b = edges[i], edges[i + 1]
        if b <= a:
            continue
        r = i / max(1, blocks - 1)
        f = f0 * (f1 / f0) ** r if curve == 'exp' else f0 + (f1 - f0) * r
        sos = _sos('low', f, 2)
        if zi is None:
            zi = signal.sosfilt_zi(sos) * 0
        y, zi = signal.sosfilt(sos, x[a:b], zi=zi)
        out[a:b] = y
    return out


def bp_sweep(x, c0, c1, q=0.35, blocks=64):
    n = len(x)
    out = np.zeros(n)
    edges = np.linspace(0, n, blocks + 1).astype(int)
    zi = None
    for i in range(blocks):
        a, b = edges[i], edges[i + 1]
        if b <= a:
            continue
        r = i / max(1, blocks - 1)
        c = c0 * (c1 / c0) ** r
        sos = _sos('band', (c * (1 - q), c * (1 + q)), 2)
        if zi is None:
            zi = signal.sosfilt_zi(sos) * 0
        y, zi = signal.sosfilt(sos, x[a:b], zi=zi)
        out[a:b] = y
    return out


def formant(x, formants):
    # sesli harf / canavar girtlagi: paralel bant geciren
    out = np.zeros(len(x))
    for f, bw, g in formants:
        out += g * bp(x, f - bw / 2, f + bw / 2, 2)
    return out


# ---------------- efektler ----------------

def dist(x, drive=3.0):
    return np.tanh(x * drive) / np.tanh(drive)


def bitcrush(x, bits=8):
    q = 2 ** (bits - 1)
    return np.round(x * q) / q


def reverb(x, decay=1.2, mix=0.3, bright=4500, predelay=0.012):
    n_ir = n_of(decay * 1.2)
    ir = rng.standard_normal(n_ir) * np.exp(-tt(decay * 1.2) * (6.9 / decay))
    ir = lp(ir, bright)
    ir = np.concatenate([np.zeros(n_of(predelay)), ir])
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = signal.fftconvolve(x, ir)[: len(x) + len(ir) // 2]
    dry = fit(x, len(wet))
    return dry * (1 - mix) + wet * mix * 0.9


def echo(x, delay=0.18, fb=0.4, n=4):
    d = n_of(delay)
    out = np.concatenate([x, np.zeros(d * n)])
    for i in range(1, n + 1):
        out[d * i: d * i + len(x)] += x * (fb ** i)
    return out


def ring(x, f):
    return x * np.sin(2 * np.pi * f * np.arange(len(x)) / Ctx.sr)


def tremolo(x, rate, depth=0.5):
    m = 1 - depth + depth * (0.5 + 0.5 * np.sin(2 * np.pi * rate * np.arange(len(x)) / Ctx.sr))
    return x * m


def reverse(x):
    return x[::-1].copy()


def pitch(x, semis):
    # basit yeniden ornekleme ile perde (sure de degisir)
    ratio = 2 ** (semis / 12.0)
    n = int(len(x) / ratio)
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


# ---------------- karistirma ----------------

def mix(*parts):
    # parts: (sinyal, baslangic_sn, kazanc) veya sinyal
    items = []
    for p in parts:
        if isinstance(p, tuple):
            sig = p[0]
            at = p[1] if len(p) > 1 else 0.0
            g = p[2] if len(p) > 2 else 1.0
        else:
            sig, at, g = p, 0.0, 1.0
        items.append((np.asarray(sig, float), n_of(at) if at > 0 else 0, g))
    total = max(o + len(s) for s, o, g in items)
    out = np.zeros(total)
    for s, o, g in items:
        out[o:o + len(s)] += s * g
    return out


def fade(x, fin=0.004, fout=0.03):
    x = x.copy()
    a, b = min(len(x), n_of(fin)), min(len(x), n_of(fout))
    if a > 0:
        x[:a] *= np.linspace(0, 1, a)
    if b > 0:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def trim_silence(x, thr=0.0015):
    idx = np.where(np.abs(x) > thr)[0]
    if len(idx) == 0:
        return x
    return x[: idx[-1] + n_of(0.02)]


def normalize(x, peak=0.9):
    m = np.max(np.abs(x)) + 1e-9
    return x * (peak / m)


def resample(x, sr_from, sr_to):
    if sr_from == sr_to:
        return x
    n = int(len(x) * sr_to / sr_from)
    return signal.resample_poly(x, sr_to, sr_from)[:n] if sr_from % sr_to == 0 or sr_to % sr_from == 0 else np.interp(
        np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


def loudnorm(x, target_db=-15.0, ceil=0.97):
    # en yuksek 0.3 sn'lik pencerenin RMS'i hedefe cekilir, tepeler yumusak sinirlanir
    x = np.asarray(x, float)
    win = n_of(0.3)
    if len(x) > win:
        step = max(1, win // 2)
        r = max(np.sqrt(np.mean(x[i:i + win] ** 2)) for i in range(0, len(x) - win + 1, step))
    else:
        r = np.sqrt(np.mean(x ** 2))
    y = x * (10 ** (target_db / 20.0) / (r + 1e-9))
    return ceil * np.tanh(y / ceil)


def write_wav(path, x, sr=22050, peak=0.9, loud=-15.0, max_len=3.2):
    x = normalize(np.asarray(x, float), 0.9)
    x = trim_silence(x, 0.004)
    if len(x) > n_of(max_len):
        x = x[:n_of(max_len)]
        x = fade(x, 0.0, 0.35)
    x = fade(loudnorm(x, loud), 0.003, 0.06)
    if sr != Ctx.sr:
        # alcak ornekleme: once alias filtre
        x = lp(x, sr * 0.45, 4)
        x = resample(x, Ctx.sr, sr)
        x = fade(np.clip(x, -0.98, 0.98), 0.003, 0.06)
    data = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    return len(data) / sr


# ---------------- hazir ses parcalari ----------------

def boom(d=1.5, f0=90, f1=30, tau=0.35, sub=1.0):
    t = tt(d)
    body = sine(sweep(f0, f1, d), d) * env_exp(d, tau) * sub
    click = lp(noise(0.05), 3000) * env_exp(0.05, 0.01)
    rumble = lp(noise(d, 'brown'), 160) * env_exp(d, tau * 1.8) * 0.8
    return mix(body, (click, 0, 0.8), (rumble, 0.0, 1.0))


def crack(d=0.4, lo=1200, hi=9000):
    return bp(noise(d), lo, hi) * env_exp(d, d / 6)


def whoosh(d=0.8, c0=400, c1=3000, peak_at=0.6):
    x = bp_sweep(noise(d, 'pink'), c0, c1, 0.45)
    e = env_lin([(0, 0), (peak_at, 1), (1, 0)], d)
    return x * e


def riser(d=2.0, f0=200, f1=1600):
    n = noise(d, 'pink')
    x = bp_sweep(n, f0, f1, 0.3) * env_lin([(0, 0), (0.9, 1), (1, 0.6)], d)
    tone = saw(sweep(f0 / 2, f1 / 2, d), d, 8) * env_lin([(0, 0), (1, 0.4)], d) * 0.3
    return x + lp(tone, 3000)


def bell(f, d=1.5, ratio=3.5, index=2.5, tau=0.5):
    e = env_exp(d, tau)
    return fm(f, ratio, index, d, index_env=e) * e


def chime(f, d=1.0, tau=0.35):
    t = tt(d)
    x = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t) + 0.2 * np.sin(2 * np.pi * f * 5.4 * t)
    return x * env_exp(d, tau)


def pad(freqs, d, a=0.3, r=0.6, detune=0.004, bright=2200):
    x = np.zeros(n_of(d))
    for f in freqs:
        for dt in (-detune, 0, detune):
            x += saw(f * (1 + dt), d, 20)
    x = lp(x, bright)
    return x * env_adsr(d, a, 0.2, 0.85, r) / (len(freqs) * 3)


def braam(root=55, d=3.0, drive=2.5):
    x = np.zeros(n_of(d))
    for f, g in ((root, 1.0), (root * 1.5, 0.6), (root * 2, 0.5), (root * 1.007, 0.8), (root * 0.5, 0.7)):
        x += saw(f, d, 30) * g
    x = lp_sweep(x, 120, 2400, 64)
    x = dist(x * 0.5, drive)
    e = env_lin([(0, 0), (0.06, 1), (0.5, 0.75), (1, 0)], d)
    return x * e


def growl(d=1.2, f0=80, f1=60, rough=25):
    t = tt(d)
    base = saw(sweep(f0, f1, d), d, 40)
    am = 0.6 + 0.4 * np.sin(2 * np.pi * rough * t + 3 * np.sin(2 * np.pi * 3 * t))
    x = base * am + noise(d) * 0.4
    x = formant(x, [(500, 300, 1.0), (1100, 400, 0.6), (2400, 600, 0.3)])
    return dist(x * 2, 2.0) * env_lin([(0, 0), (0.1, 1), (0.7, 0.8), (1, 0)], d)


def screech(d=1.4, f0=1800, f1=900):
    t = tt(d)
    car = sweep(f0, f1, d)
    x = np.sin(_phase(car, d) + 4 * np.sin(2 * np.pi * 37 * t)) * 0.6 + bp(noise(d), 1500, 6000) * 0.5
    x = formant(x, [(1200, 500, 1.0), (2600, 800, 0.8), (3800, 1000, 0.4)])
    return dist(x * 2.5, 2) * env_lin([(0, 0), (0.08, 1), (0.6, 0.8), (1, 0)], d)


def zap(d=0.35, f0=3000, f1=200):
    t = tt(d)
    x = square(sweep(f0, f1, d), d, 9) * 0.5 + hp(noise(d), 2500) * 0.6
    x *= (rng.random(n_of(d)) > 0.35)  # cizirti
    return lp(x, 9000) * env_exp(d, d / 3)


def crackle(d=1.0, density=60, lo=1500, hi=8000, amp=1.0):
    n = n_of(d)
    out = np.zeros(n)
    k = int(density * d)
    for _ in range(k):
        p = rng.integers(0, max(1, n - 400))
        L = rng.integers(40, 300)
        out[p:p + L] += rng.standard_normal(L) * np.exp(-np.arange(L) / (L / 4)) * rng.uniform(0.3, 1.0)
    return bp(out, lo, hi) * amp


def bubbles(d=1.2, rate=18, fmin=300, fmax=1100):
    n = n_of(d)
    out = np.zeros(n)
    k = int(rate * d)
    for _ in range(k):
        p = rng.integers(0, max(1, n - 3000))
        L = rng.integers(600, 2400)
        f0 = rng.uniform(fmin, fmax)
        tl = np.arange(L) / Ctx.sr
        f = f0 * (1 + 1.5 * tl / (L / Ctx.sr))
        out[p:p + L] += np.sin(2 * np.pi * np.cumsum(f) / Ctx.sr) * np.exp(-tl * 18) * rng.uniform(0.3, 1)
    return out


def tinkle(d=1.0, count=14, fmin=2500, fmax=7000):
    n = n_of(d)
    out = np.zeros(n)
    for _ in range(count):
        p = rng.integers(0, max(1, n - 4000))
        L = 4000
        f = rng.uniform(fmin, fmax)
        tl = np.arange(L) / Ctx.sr
        out[p:p + L] += (np.sin(2 * np.pi * f * tl) + 0.3 * np.sin(2 * np.pi * f * 2.7 * tl)) * np.exp(-tl * 25) * rng.uniform(0.3, 1)
    return out


def thump(d=0.5, f=55, tau=0.12):
    return sine(sweep(f * 2.2, f, d), d) * env_exp(d, tau) + lp(noise(d), 400) * env_exp(d, 0.02) * 0.5


def beep(f, d=0.1, kind='sine'):
    osc = {'sine': sine, 'square': square, 'tri': tri}[kind]
    return osc(f, d) * env_adsr(d, 0.003, 0.02, 0.8, 0.02)


def chord_stab(freqs, d=1.6, bright0=4000, bright1=600):
    x = np.zeros(n_of(d))
    for f in freqs:
        for dt in (-0.006, 0.0, 0.006):
            x += saw(f * (1 + dt), d, 25)
    x = lp_sweep(x, bright0, bright1, 48)
    return x * env_lin([(0, 0), (0.02, 1), (0.4, 0.6), (1, 0)], d) / len(freqs)


def timpani(f=65, d=1.5):
    t = tt(d)
    x = np.sin(2 * np.pi * f * t + 0.6 * np.sin(2 * np.pi * f * 1.5 * t)) * env_exp(d, 0.45)
    return x + lp(noise(d), 600) * env_exp(d, 0.05) * 0.4
