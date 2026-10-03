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


# =====================================================================================
# v3 EKLENTILERI (v2 fonksiyonlarinin davranisi DEGISMEZ; asagidakiler sadece eklenir)
#  - kaynak-filtre vokal sentez: glottal darbe dizisi (Rosenberg) + jitter/shimmer +
#    alt harmonik / "fry" + kaskad formant rezonatorleri (zamanla degisen)
#  - fiziksel/modal darbe sesleri: metal, kemik/tahta, tas, zincir, buz, su/et
#  - doku: ates, ruzgar, gok gurultusu, elektrik, bocek kanadi / tikirti, granuler bulut
#  - erken yansimali konvolusyon reverb, flanger, ileri bakisli sinirlayici, v3 WAV yazici
# =====================================================================================
from scipy.ndimage import minimum_filter1d


def reseed(seed):
    """ses basina sabit tohum (siralamadan bagimsiz tekrar uretilebilirlik)"""
    global rng
    rng = np.random.default_rng(seed)


def _arr(v, n):
    if np.ndim(v) == 0:
        return np.full(n, float(v))
    v = np.asarray(v, float)
    if len(v) == n:
        return v
    return np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(v)), v)


def curve(v, d):
    """skaler | dizi | [(oran, deger), ...] -> n_of(d) uzunlukta egri"""
    if isinstance(v, (list, tuple)) and len(v) and isinstance(v[0], (list, tuple)):
        return env_lin(v, d)
    return _arr(v, n_of(d))


def lpnoise(n, rate, sr=None):
    """standart sapmasi ~1 olan yumusak rastgele egri (rate Hz bant)"""
    sr = sr or Ctx.sr
    w = rng.standard_normal(n + 2048)
    f = max(0.5, min(rate, sr * 0.45))
    sos = signal.butter(2, f / (sr / 2), 'low', output='sos')
    y = signal.sosfiltfilt(sos, w)[1024:1024 + n]
    return y / (np.std(y) + 1e-9)


# ---------------- glottal kaynak ----------------

def glottal(f0, d, jitter=0.01, shimmer=0.05, sub=0.0, fry=0.0, oq=0.6, vib=(0.0, 0.0), os=2):
    """Rosenberg glottal akis darbe dizisi (2x asiri ornekleme).
    jitter: perde titremesi (oran), shimmer: periyot genlik titremesi, sub: periyot ikilenmesi
    (alt harmonik, canavar sesi), fry: rastgele zayif periyot (gicirtili 'vocal fry'),
    vib: (hz, yarim ton). Donus: (turev kaynak [-1,1], akis egrisi)"""
    n = n_of(d)
    N = n * os
    sr2 = Ctx.sr * os
    f = _arr(curve(f0, d), N)
    t = np.arange(N) / sr2
    if vib[1]:
        f = f * 2 ** (vib[1] / 12.0 * np.sin(2 * np.pi * vib[0] * t + rng.uniform(0, 6.28)))
    if jitter:
        f = f * (1 + jitter * 0.6 * lpnoise(N, 6, sr2)) * (1 + jitter * 0.5 * lpnoise(N, 180, sr2))
    f = np.clip(f, 12, sr2 * 0.2)
    ph = np.cumsum(f) / sr2
    k = ph.astype(np.int64)
    p = ph - k
    tp, tn = oq * 0.64, oq * 0.36
    g = np.where(p < tp, 0.5 * (1 - np.cos(np.pi * p / tp)),
                 np.where(p < tp + tn, np.cos(0.5 * np.pi * (p - tp) / tn), 0.0))
    K = int(k[-1]) + 2
    a = 1 + shimmer * rng.standard_normal(K)
    if sub:
        a = a * np.where(np.arange(K) % 2 == 0, 1.0, 1.0 - sub)
    if fry:
        if isinstance(fry, (list, tuple)) and len(fry) and isinstance(fry[0], (list, tuple)):
            fr = np.interp(np.linspace(0, 1, K), [q[0] for q in fry], [q[1] for q in fry])
        else:
            fr = _arr(fry, K) if np.ndim(fry) else np.full(K, float(fry))
        a = a * np.where(rng.random(K) < fr, rng.uniform(0.05, 0.45, K), 1.0)
    g = g * np.clip(a, 0, 3)[k]
    s = np.diff(g, prepend=0.0)
    s = signal.resample_poly(s, 1, os)[:n]
    gl = signal.resample_poly(g, 1, os)[:n]
    s = s / (np.max(np.abs(s)) + 1e-9)
    gl = np.clip(gl, 0, None)
    return fit(s, n), fit(gl / (np.max(gl) + 1e-9), n)


# ---------------- formantlar ----------------
# erkek sesli harf formantlari (F1..F5), canavar icin 'fscale' < 1 (buyuk girtlak)
VOWELS = {
    'a': (730, 1090, 2440, 3300, 3850), 'A': (850, 1220, 2600, 3400, 3950),
    'o': (570, 840, 2410, 3300, 3850), 'u': (300, 870, 2240, 3300, 3850),
    'e': (530, 1840, 2480, 3300, 3850), 'i': (270, 2290, 3010, 3500, 4000),
    'ae': (660, 1720, 2410, 3300, 3850), 'uh': (640, 1190, 2390, 3300, 3850),
    'er': (490, 1350, 1690, 3300, 3850), 'oo': (380, 950, 2300, 3300, 3850),
    'ee': (300, 2500, 3200, 3700, 4200), 'n': (280, 1100, 2400, 3300, 3850),
}
FBW = (80, 100, 150, 220, 280)


def vowel_tracks(seq, d, scale=1.0, wobble=0.0, nform=5):
    """seq: 'a' | [(oran, 'a'), (oran, 'o'), ...] -> formant frekans egrileri listesi"""
    n = n_of(d)
    if isinstance(seq, str):
        seq = [(0.0, seq), (1.0, seq)]
    xs = [s[0] for s in seq]
    sc = curve(scale, d)
    tl = np.linspace(0, 1, n)
    F = []
    for j in range(nform):
        ys = [VOWELS[s[1]][j] for s in seq]
        fj = np.interp(tl, xs, ys) * sc
        if wobble:
            fj = fj * (1 + wobble * lpnoise(n, 4))
        F.append(fj)
    return F


def _reson_tv(x, f, bw, block=64):
    """Klatt 2 kutuplu rezonator, frekans/bant genisligi zamanla degisir (DC kazanci 1)"""
    n = len(x)
    f = _arr(f, n)
    bw = _arr(bw, n)
    out = np.empty(n)
    zi = np.zeros(2)
    sr = Ctx.sr
    for a in range(0, n, block):
        b = min(n, a + block)
        m = (a + b) // 2
        fc = min(max(f[m], 20.0), sr * 0.46)
        r = np.exp(-np.pi * max(bw[m], 10.0) / sr)
        B = 2 * r * np.cos(2 * np.pi * fc / sr)
        C = -r * r
        A = 1 - B - C
        out[a:b], zi = signal.lfilter([A], [1, -B, -C], x[a:b], zi=zi)
    return out


def vtract(x, F, bwk=1.0, block=64):
    """kaskad formant filtresi (gercekci sesli harf zarfi)"""
    y = x
    for j, f in enumerate(F):
        y = _reson_tv(y, f, FBW[min(j, len(FBW) - 1)] * bwk, block)
    return y


def pformant(x, F, gains=(1.0, 0.7, 0.45, 0.3, 0.2), bwk=1.0, block=64):
    """paralel formant bankasi (fisilti / tiz ciglik icin daha parlak)"""
    out = np.zeros(len(x))
    for j, f in enumerate(F):
        if j >= len(gains):
            break
        bwj = FBW[min(j, len(FBW) - 1)] * bwk
        y = _reson_tv(x, f, bwj, block)
        # Klatt rezonatoru DC kazanci 1 -> tepe kazanci ~ fc/bw; dengelemek icin hp + olcek
        out += gains[j] * hp(y, max(30, float(np.median(f)) * 0.5), 1) * (bwj / max(float(np.median(f)), 50)) * 4
    return out


def voice(d, f0, seq='a', fscale=1.0, jitter=0.01, shimmer=0.05, sub=0.0, fry=0.0, oq=0.6, breath=0.1,
          rough=0.0, rough_rate=30.0, vib=(0.0, 0.0), bwk=1.0, wobble=0.02, amp=None, drive=0.0,
          hpf=45.0, parallel=False, bright=0.0):
    """kaynak-filtre vokal: glottal + aspirasyon -> (puruz AM) -> formantlar -> zarf -> doygunluk"""
    n = n_of(d)
    s, g = glottal(f0, d, jitter, shimmer, sub, fry, oq, vib)
    if breath:
        asp = hp(rng.standard_normal(n), 900) * (0.25 + 0.75 * g) * 0.35
        s = s + breath * asp
    if rough:
        t = np.arange(n) / Ctx.sr
        ph = 2 * np.pi * np.cumsum(_arr(curve(rough_rate, d), n) * (1 + 0.25 * lpnoise(n, 8))) / Ctx.sr
        r = _arr(curve(rough, d), n)
        s = s * (1 - r * (0.5 + 0.5 * np.sin(ph)))
    F = vowel_tracks(seq, d, fscale, wobble)
    y = pformant(s, F, bwk=bwk) if parallel else vtract(s, F, bwk)
    if bright:
        # buyuk girtlakta ezilen ust formantlari geri ver (2-5 kHz 'varlik' bandi)
        pr = bp(s, 1800, 5200, 2)
        y = y + bright * pr * np.std(y) / (np.std(pr) + 1e-9)
    y = hp(y, hpf)
    y = y / (np.max(np.abs(y)) + 1e-9)
    e = curve(amp if amp is not None else [(0, 0), (0.06, 1), (0.75, 0.8), (1, 0)], d)
    y = y * e
    if drive:
        y = dist(y * drive, 1.5)
    return y


def unvoiced(d, seq='a', fscale=1.0, amp=None, bwk=1.6, color=0.5, hpf=120):
    """fisilti / nefes: gurultu kaynak + formantlar"""
    n = n_of(d)
    src = rng.standard_normal(n) * (1 - color) + noise(d, 'pink') * color * 2.5
    F = vowel_tracks(seq, d, fscale, 0.04)
    y = pformant(src, F, gains=(0.8, 1.0, 0.8, 0.5, 0.35), bwk=bwk)
    y = hp(y, hpf)
    y = y / (np.max(np.abs(y)) + 1e-9)
    return y * curve(amp if amp is not None else [(0, 0), (0.15, 1), (0.7, 0.8), (1, 0)], d)


def sibilant(d, lo=3500, hi=9000, amp=None):
    y = bp(rng.standard_normal(n_of(d)), lo, hi, 2)
    y = y / (np.max(np.abs(y)) + 1e-9)
    return y * curve(amp if amp is not None else [(0, 0), (0.2, 1), (0.8, 0.7), (1, 0)], d)


def syllables(d, count, dur=(0.12, 0.25), gap=(0.03, 0.12)):
    """[(baslangic_sn, sure_sn), ...] konusma ritmi"""
    out, t = [], 0.0
    for i in range(count):
        L = rng.uniform(*dur)
        if t + L > d:
            break
        out.append((t, L))
        t += L + rng.uniform(*gap)
    return out


def choir(d, notes, seq='a', fscale=1.0, per=2, detune=0.012, vib=(5.2, 0.25), breath=0.25, amp=None, jitter=0.006):
    out = np.zeros(n_of(d))
    for f in notes:
        for k in range(per):
            fd = f * (1 + rng.uniform(-detune, detune))
            out += voice(d, fd, seq, fscale * rng.uniform(0.96, 1.04), jitter, 0.03, 0, 0, 0.55, breath,
                         vib=(vib[0] * rng.uniform(0.85, 1.15), vib[1]), amp=amp, wobble=0.015)
    return out / (len(notes) * per) ** 0.7


# ---------------- modal / fiziksel darbeler ----------------

def modal(freqs, taus, amps, d):
    t = tt(d)
    x = np.zeros(len(t))
    for f, ta, a in zip(freqs, taus, amps):
        if f < Ctx.sr * 0.47:
            x += a * np.sin(2 * np.pi * f * t) * np.exp(-t / max(ta, 1e-4))
    return x


def metal_hit(f=420, d=1.0, tau=0.4, kind='plate', bright=1.0):
    if kind == 'bar':
        ratios = [1, 2.756, 5.404, 8.933, 13.34]
    elif kind == 'bell':
        ratios = [0.5, 1, 1.183, 1.506, 2.0, 2.514, 2.662, 3.011]
    else:
        ratios = sorted([1.0] + list(rng.uniform(1.3, 9.0, 9)))
    fr = [f * r * rng.uniform(0.995, 1.005) for r in ratios]
    ta = [tau / (1 + 0.35 * i) for i in range(len(fr))]
    am = [(1.0 / (1 + 0.5 * i)) * bright ** min(i, 3) * rng.uniform(0.6, 1.0) for i in range(len(fr))]
    strike = hp(rng.standard_normal(n_of(0.012)), 2000) * env_exp(0.012, 0.002) * 0.6
    return mix(modal(fr, ta, am, d) / max(1.0, sum(am) * 0.5), (strike, 0))


def clink(f=None, d=0.12):
    f = f or rng.uniform(2200, 5200)
    return metal_hit(f, d, rng.uniform(0.02, 0.06), 'plate') * rng.uniform(0.4, 1.0)


def chain_rattle(d=1.0, rate=30, fmin=1800, fmax=5500, amp=None, cluster=3):
    """zincir halkalari: kumelenmis kucuk metal carpismalari"""
    n = n_of(d)
    out = np.zeros(n)
    e = curve(amp if amp is not None else 1.0, d)
    k = int(rate * d)
    for _ in range(k):
        t0 = rng.uniform(0, d * 0.95)
        for c in range(rng.integers(1, cluster + 1)):
            tc = t0 + c * rng.uniform(0.008, 0.03)
            p = int(tc * Ctx.sr)
            if p >= n - 10:
                continue
            h = clink(rng.uniform(fmin, fmax), 0.1)
            L = min(len(h), n - p)
            out[p:p + L] += h[:L] * e[p]
    return out


def knock(f=900, d=0.15, tau=0.025, wood=True):
    """kemik / tahta tak sesi"""
    ratios = [1, 2.31, 3.9, 5.6] if wood else [1, 1.6, 2.2]
    k = modal([f * r for r in ratios], [tau, tau * 0.6, tau * 0.4, tau * 0.3], [1, 0.6, 0.35, 0.2], d)
    cl = bp(rng.standard_normal(n_of(0.006)), f, min(f * 6, 9500)) * env_exp(0.006, 0.0015)
    return mix(k, (cl, 0, 0.6))


def bone_rattle(d=0.8, rate=40, fmin=700, fmax=2400, amp=None):
    n = n_of(d)
    out = np.zeros(n)
    e = curve(amp if amp is not None else 1.0, d)
    for _ in range(int(rate * d)):
        p = rng.integers(0, max(1, n - 3500))
        h = knock(rng.uniform(fmin, fmax), 0.15, rng.uniform(0.01, 0.03)) * rng.uniform(0.3, 1)
        L = min(len(h), n - p)
        out[p:p + L] += h[:L] * e[p]
    return out


def debris(d=1.0, density=80, lo=400, hi=4000, decay=None, amp=1.0):
    """dusen tas / toprak parcaciklari (yogunluk zamanla azalir)"""
    n = n_of(d)
    out = np.zeros(n)
    k = int(density * d)
    dec = decay or d / 3
    for _ in range(k):
        tp = rng.exponential(dec)
        if tp >= d - 0.02:
            continue
        p = int(tp * Ctx.sr)
        L = int(rng.integers(60, 500))
        L = min(L, n - p)
        g = rng.standard_normal(L) * np.exp(-np.arange(L) / (L / 5)) * rng.uniform(0.2, 1.0)
        out[p:p + L] += g
    return bp(out, lo, hi) * amp


def stone_impact(d=1.2, size=1.0):
    f = 70 / size ** 0.5
    body = sine(sweep(f * 2.0, f * 0.8, d), d) * env_exp(d, 0.12 * size)
    crunch = lp(rng.standard_normal(n_of(0.08)), 3500) * env_exp(0.08, 0.015)
    grit = debris(d, 120 * size, 300, 5000, d / 4, 0.5)
    low = lp(noise(d, 'brown'), 200) * env_exp(d, 0.25 * size)
    return mix((body, 0, 1.0), (crunch, 0, 0.9), (grit, 0.01, 0.8), (low, 0, 0.7))


def squelch(d=0.35, f0=600, f1=250, wet=1.0):
    """islak et / sivi sesi: rezonant tarama + kabarcik AM"""
    n = n_of(d)
    src = rng.standard_normal(n) * (0.5 + 0.5 * np.abs(lpnoise(n, 60)))
    y = bp_sweep(src, f0, f1, 0.4, 48)
    y = y / (np.max(np.abs(y)) + 1e-9) * env_lin([(0, 0), (0.08, 1), (0.5, 0.5), (1, 0)], d)
    b = bubbles(d, 25 * wet, 250, 900) * 0.4 * wet
    return y + b * env_exp(d, d / 2)


def splat(d=0.4):
    return mix(thump(d, 90, 0.05) * 0.7, (squelch(d, 1400, 300), 0, 0.9), (hp(rng.standard_normal(n_of(0.05)), 1500) * env_exp(0.05, 0.01) * 0.5, 0))


def thunder(d=2.5, crack_amt=1.0, dist_k=1.0):
    n = n_of(d)
    cr = mix(hp(rng.standard_normal(n_of(0.25)), 1200) * env_exp(0.25, 0.04), (bp(rng.standard_normal(n_of(0.4)), 300, 3000) * env_exp(0.4, 0.08), 0.01))
    # yuvarlanan gurultu: rastgele zamanli patlamalar
    bursts = np.zeros(n)
    for _ in range(int(14 * d)):
        p = int(rng.exponential(d / 3) * Ctx.sr)
        if p < n:
            bursts[p] += rng.uniform(0.3, 1.0)
    envb = signal.lfilter([1], [1, -np.exp(-1 / (0.12 * Ctx.sr))], bursts)
    roll = lp_sweep(noise(d, 'brown'), 900 / dist_k, 120, 48) * (0.3 + envb / (envb.max() + 1e-9)) * env_lin([(0, 0), (0.03, 1), (1, 0)], d)
    sub = sine(sweep(60, 30, d), d) * env_exp(d, d / 4) * 0.5
    return mix((cr, 0, crack_amt), (roll, 0.02, 1.2), (sub, 0.02))


def elec_buzz(d=1.0, f=120, sputter=0.3, amp=None):
    """elektrik vizildamasi: kare dalga + harmonik + rastgele kesinti"""
    n = n_of(d)
    x = square(f * (1 + 0.004 * lpnoise(n, 5)), d, 25) * 0.6 + saw(f * 2, d, 20) * 0.3
    x = x + hp(rng.standard_normal(n), 3000) * 0.25 * (np.abs(lpnoise(n, 40)) > 1.0)
    if sputter:
        gate = (lpnoise(n, 25) > (-1.5 + 3 * sputter)).astype(float)
        gate = signal.lfilter([0.02], [1, -0.98], gate)
        x = x * (1 - sputter + sputter * gate / (gate.max() + 1e-9))
    x = bp(x, 80, 7000)
    return x / (np.max(np.abs(x)) + 1e-9) * curve(amp if amp is not None else 1.0, d)


def arc(d=0.3, f=None):
    """elektrik arki: cizirtili yuksek gerilim bosalmasi"""
    n = n_of(d)
    f = f or rng.uniform(70, 160)
    gate = (rng.random(n) < 0.25).astype(float)
    nz = hp(rng.standard_normal(n), 1500) * gate
    tone = square(f * (1 + 0.1 * lpnoise(n, 30)), d, 30)
    x = nz * 0.8 + tone * 0.4 * (np.abs(lpnoise(n, 90)) > 0.6)
    x = x * env_lin([(0, 0), (0.02, 1), (0.6, 0.6), (1, 0)], d)
    return lp(x, 9500)


def ice_crack(d=0.6, big=1.0):
    """buz catlamasi: keskin tikirti dizisi + yuksek rezonans + derin 'tum'"""
    n = n_of(d)
    out = np.zeros(n)
    t = 0.0
    while t < d * 0.6:
        p = int(t * Ctx.sr)
        h = mix(hp(rng.standard_normal(n_of(0.004)), 3000) * rng.uniform(0.4, 1.0),
                (modal([rng.uniform(2500, 7000), rng.uniform(1200, 3000)], [0.015, 0.03], [0.5, 0.3], 0.08), 0))
        L = min(len(h), n - p)
        out[p:p + L] += h[:L]
        t += rng.exponential(0.018)
    low = sine(sweep(140, 60, d), d) * env_exp(d, 0.1) * 0.6 * big
    return mix(out, (low, 0), (lp(rng.standard_normal(n), 900) * env_exp(d, 0.05) * 0.4 * big, 0))


def creak(d=1.0, rate0=20, rate1=60, freqs=(320, 900, 2100), q=12.0, amp=None):
    """yapis-kay surtunme (buz / tas / ip gerilmesi): darbe dizisi -> rezonatorler"""
    n = n_of(d)
    r = curve([(0, rate0), (1, rate1)] if np.ndim(rate0) == 0 else rate0, d) * (1 + 0.3 * lpnoise(n, 6))
    ph = np.cumsum(np.clip(r, 2, 400)) / Ctx.sr
    imp = np.diff(np.floor(ph), prepend=0.0) * rng.uniform(0.5, 1.0, n)
    imp = imp + 0.02 * rng.standard_normal(n) * (np.abs(lpnoise(n, 20)) > 1.2)
    out = np.zeros(n)
    for i, f in enumerate(freqs):
        bw = f / q
        out += _reson_tv(imp, f * (1 + 0.04 * lpnoise(n, 2)), bw) * (f / bw) ** 0.0 / (1 + i * 0.5)
    out = hp(out, 80)
    out = out / (np.max(np.abs(out)) + 1e-9)
    return out * curve(amp if amp is not None else [(0, 0), (0.2, 1), (0.8, 1), (1, 0)], d)


def grind(d=1.0, lo=150, hi=2500, rate=18, amp=None):
    """tas surtunmesi: kumlu gurultu + dusuk frekansli takilma"""
    n = n_of(d)
    nz = bp(rng.standard_normal(n), lo, hi)
    stick = 0.5 + 0.5 * np.abs(np.sin(np.pi * np.cumsum(rate * (1 + 0.4 * lpnoise(n, 3))) / Ctx.sr)) ** 3
    grit = debris(d, 160, 800, 6000, d * 3, 0.5)
    x = nz * stick + grit
    x = x / (np.max(np.abs(x)) + 1e-9)
    return x * curve(amp if amp is not None else [(0, 0), (0.15, 1), (0.85, 1), (1, 0)], d)


def fire(d=1.0, lo=150, hi=3500, crackles=60, amp=None):
    n = n_of(d)
    body = bp(noise(d, 'pink'), lo, hi) * (0.7 + 0.3 * lpnoise(n, 3))
    flick = lp(rng.standard_normal(n), 300) * (0.6 + 0.4 * lpnoise(n, 7))
    x = body + flick * 0.6 + crackle(d, crackles, 1500, 8000) * 0.6
    x = x / (np.max(np.abs(x)) + 1e-9)
    return x * curve(amp if amp is not None else [(0, 0), (0.1, 1), (0.85, 0.9), (1, 0)], d)


def sizzle(d=0.8, amp=None):
    n = n_of(d)
    x = hp(rng.standard_normal(n), 3500) * (0.6 + 0.4 * np.abs(lpnoise(n, 30)))
    x = x + crackle(d, 120, 3000, 9000) * 0.5
    x = x / (np.max(np.abs(x)) + 1e-9)
    return x * curve(amp if amp is not None else [(0, 1), (1, 0)], d)


def wind(d=2.0, c0=500, c1=900, howl=0.5, amp=None):
    n = n_of(d)
    src = noise(d, 'pink')
    c = np.clip(np.exp(np.log(c0) + (np.log(c1) - np.log(c0)) * np.linspace(0, 1, n) + 0.25 * lpnoise(n, 0.8)), 80, 6000)
    y = _reson_tv(src, c, c * 0.08) * 0.6 + _reson_tv(src, c * 1.9, c * 0.1) * 0.3
    y = y / (np.max(np.abs(y)) + 1e-9)
    body = bp(src, c0 * 0.5, c1 * 3)
    body = body / (np.max(np.abs(body)) + 1e-9)
    x = y * howl + body * (1 - howl)
    return x * curve(amp if amp is not None else [(0, 0), (0.3, 1), (0.7, 1), (1, 0)], d)


def rumble(d=1.5, f=120, amp=None):
    n = n_of(d)
    x = lp(noise(d, 'brown'), f) * (0.6 + 0.4 * lpnoise(n, 2))
    x = x / (np.max(np.abs(x)) + 1e-9)
    return x * curve(amp if amp is not None else [(0, 0), (0.2, 1), (0.8, 1), (1, 0)], d)


def insect_buzz(d=1.0, f=210, depth=0.6, amp=None):
    """bocek kanadi: kanat vurusu (testere) + hizli AM + vucut rezonansi"""
    n = n_of(d)
    fr = f * (1 + 0.04 * lpnoise(n, 4))
    x = saw(fr, d, 30)
    x = x * (1 - depth * (0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(fr * 0.5) / Ctx.sr)))
    x = formant(x, [(900, 500, 1.0), (2200, 900, 0.7), (4200, 1500, 0.3)])
    x = x / (np.max(np.abs(x)) + 1e-9)
    return x * curve(amp if amp is not None else [(0, 0), (0.1, 1), (0.9, 1), (1, 0)], d)


def chitter(d=0.8, rate=35, fmin=2200, fmax=5500, amp=None, burst=(3, 9)):
    """bocek / orumcek tikirtisi: hizli tik dizileri"""
    n = n_of(d)
    out = np.zeros(n)
    e = curve(amp if amp is not None else 1.0, d)
    t = rng.uniform(0, 0.03)
    while t < d - 0.05:
        k = rng.integers(*burst)
        f = rng.uniform(fmin, fmax)
        r = rate * rng.uniform(0.7, 1.4)
        for i in range(k):
            p = int((t + i / r) * Ctx.sr)
            if p >= n - 400:
                break
            c = modal([f * rng.uniform(0.97, 1.03), f * 1.7], [0.004, 0.003], [1, 0.4], 0.015)
            c = c + hp(rng.standard_normal(len(c)), 3000) * env_exp(0.015, 0.0015) * 0.5
            out[p:p + len(c)] += c * e[p] * rng.uniform(0.5, 1.0)
        t += k / r + rng.uniform(0.03, 0.15)
    return out


def puff(d=0.35, lo=300, hi=2500):
    """yumusak gaz / spor fiskirmasi"""
    x = bp(rng.standard_normal(n_of(d)), lo, hi)
    x = x / (np.max(np.abs(x)) + 1e-9)
    e = env_lin([(0, 0), (0.06, 1), (0.25, 0.6), (1, 0)], d)
    pop = thump(0.12, rng.uniform(110, 160), 0.02) * 0.5
    return mix(x * e, (pop, 0))


def granular(src, d, grain=0.05, density=120, pitch=(0.8, 1.25), amp=None, rev=0.0):
    """kaynaktan rastgele taneler (Hann pencereli), perde / konum dagitimi"""
    n = n_of(d)
    out = np.zeros(n)
    e = curve(amp if amp is not None else 1.0, d)
    G = n_of(grain)
    for _ in range(int(density * d)):
        p = rng.integers(0, max(1, n - G * 2))
        ratio = rng.uniform(*pitch)
        L = int(G * ratio) + 2
        s0 = rng.integers(0, max(1, len(src) - L - 1))
        seg = src[s0:s0 + L]
        if len(seg) < 4:
            continue
        g = np.interp(np.linspace(0, len(seg) - 1, G), np.arange(len(seg)), seg)
        if rng.random() < rev:
            g = g[::-1]
        out[p:p + G] += g * np.hanning(G) * e[p]
    return out


def flanger(x, rate=0.3, depth=0.003, fb=0.5, mixv=0.5):
    n = len(x)
    t = np.arange(n) / Ctx.sr
    dl = (0.0015 + depth * (0.5 + 0.5 * np.sin(2 * np.pi * rate * t))) * Ctx.sr
    idx = np.arange(n) - dl
    y = np.interp(idx, np.arange(n), x, left=0.0)
    y2 = np.interp(idx, np.arange(n), y, left=0.0)
    return x * (1 - mixv) + (y + fb * y2) * mixv / (1 + fb)


def tstretch_pitch(x, ratio):
    """yeniden ornekleme (perde+sure birlikte, 'yavaslatilmis canavar' etkisi)"""
    n = int(len(x) / ratio)
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


def space(x, kind='room', mixv=None):
    """erken yansima + gec kuyruk konvolusyon reverb (prosedurel IR)"""
    P = {'room': (0.6, 6000, 0.008, 0.22), 'hall': (1.6, 4500, 0.02, 0.28), 'cave': (2.2, 2600, 0.03, 0.32),
         'ghost': (2.6, 6500, 0.04, 0.42), 'arena': (1.2, 5000, 0.015, 0.25), 'tight': (0.35, 7000, 0.004, 0.18)}
    dec, bright, pre, m = P[kind]
    m = m if mixv is None else mixv
    L = n_of(dec * 1.25)
    ir = rng.standard_normal(L) * np.exp(-tt(dec * 1.25) * (6.9 / dec))
    ir = lp(ir, bright)
    # erken yansimalar
    er = np.zeros(n_of(0.09))
    for _ in range(9):
        er[rng.integers(n_of(0.004), len(er))] += rng.uniform(-1, 1) * 0.6
    ir[:len(er)] += er * np.max(np.abs(ir[:len(er)]) + 1e-9)
    ir = np.concatenate([np.zeros(n_of(pre)), ir])
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = signal.fftconvolve(x, ir)[: len(x) + len(ir)]
    dry = fit(x, len(wet))
    wet = wet * (np.sqrt(np.mean(x ** 2)) / (np.sqrt(np.mean(wet ** 2)) + 1e-12))
    return dry * (1 - m) + wet * m


# ---------------- dinamik + v3 yazici ----------------

def limiter(x, ceil=0.92, look=0.008):
    """ileri bakisli tepe sinirlayici: kazanc egrisi asla gerekenin ustune cikmaz (kirpma yok)"""
    a = np.abs(x)
    g = np.minimum(1.0, ceil / (a + 1e-12))
    L = max(2, n_of(look))
    g = minimum_filter1d(g, size=2 * L + 1, mode='nearest')
    w = np.hanning(2 * L + 3)[1:-1]
    w /= w.sum()
    g = np.convolve(np.pad(g, L, mode='edge'), w, mode='valid')[:len(x)]
    return x * g


def peak_window_rms(x, sr=None, win=0.3):
    sr = sr or Ctx.sr
    w = max(1, int(sr * win))
    if len(x) <= w:
        return float(np.sqrt(np.mean(x ** 2)))
    c = np.cumsum(np.concatenate([[0.0], x ** 2]))
    step = max(1, w // 4)
    idx = np.arange(0, len(x) - w + 1, step)
    return float(np.sqrt(np.max((c[idx + w] - c[idx]) / w)))


def kweight(x, sr=None):
    """BS.1770 K agirliklandirma (raf +4 dB @1.68 kHz + HP 38 Hz), algisal yukluk olcusu icin"""
    sr = sr or Ctx.sr
    A = 10 ** (4.0 / 40)
    w0 = 2 * np.pi * 1681.97 / sr
    al = np.sin(w0) / 2 * np.sqrt(2)
    cw = np.cos(w0)
    b = [A * ((A + 1) + (A - 1) * cw + 2 * np.sqrt(A) * al), -2 * A * ((A - 1) + (A + 1) * cw),
         A * ((A + 1) + (A - 1) * cw - 2 * np.sqrt(A) * al)]
    a = [(A + 1) - (A - 1) * cw + 2 * np.sqrt(A) * al, 2 * ((A - 1) - (A + 1) * cw),
         (A + 1) - (A - 1) * cw - 2 * np.sqrt(A) * al]
    y = signal.lfilter(b, a, x)
    return signal.sosfilt(signal.butter(2, 38 / (sr / 2), 'high', output='sos'), y)


def loudness_db(x):
    """v3 yukluk olcusu: K agirlikli en yuksek 0.4 sn pencere RMS'i (dB). Cok basli seslerin
    asiri yukseltilmemesi icin ham pencere RMS'inin 3 dB altiyla sinirlanir."""
    kp = 20 * np.log10(peak_window_rms(kweight(x), win=0.4) + 1e-12)
    rp = 20 * np.log10(peak_window_rms(x, win=0.4) + 1e-12)
    return max(kp, rp - 3.0)


def write_wav3(path, x, sr=22050, loud=-15.5, max_len=3.0, ceil=0.92, tail_db=-46.0, min_len=0.0):
    """v3 yazici: DC/subsonik temizligi, sessizlik kirpma, K agirlikli yukluk normalizasyonu
    (v2 seslerinin medyanina kalibre), ileri bakisli sinirlayici, tiksiz fade,
    mono 16 bit PCM, cue/dongu YOK (sadece fmt + data)."""
    x = np.asarray(x, float)
    x = signal.sosfiltfilt(signal.butter(2, 28 / (Ctx.sr / 2), 'high', output='sos'), x)
    x = x / (np.max(np.abs(x)) + 1e-9)
    thr = 10 ** (tail_db / 20)
    idx = np.where(np.abs(x) > thr)[0]
    if len(idx):
        a = max(0, idx[0] - n_of(0.002))
        b = min(len(x), idx[-1] + n_of(0.01))
        x = x[a:b]
    if len(x) > n_of(max_len):
        x = x[:n_of(max_len)]
        k = n_of(min(0.3, max_len * 0.2))
        x[-k:] *= np.linspace(1, 0, k) ** 1.5
    # yukluk: v2 ile tutarli (v2 medyani K-pencere -15.6 dB); limiter tepeleri kirpmadan tutar
    for _ in range(2):
        x = x * 10 ** ((loud - loudness_db(x)) / 20.0)
        x = limiter(x, ceil)
    x = fade(x, 0.002, 0.04)
    # kalan DC'yi uclari bozmadan (Hann agirlikli) cikar
    w = np.hanning(len(x)) if len(x) > 8 else np.ones(len(x))
    x = x - np.mean(x) * w / (np.mean(w) + 1e-12)
    if min_len and len(x) < n_of(min_len):
        x = fit(x, n_of(min_len))
    if sr != Ctx.sr:
        x = signal.resample_poly(x, sr, Ctx.sr)
        x = limiter(x, ceil)
        x = fade(x, 0.002, 0.04)
        w = np.hanning(len(x)) if len(x) > 8 else np.ones(len(x))
        x = x - np.mean(x) * w / (np.mean(w) + 1e-12)
    data = np.clip(np.round(x * 32767), -32767, 32767).astype('<i2')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    return len(data) / sr


def wsola(x, ratio, win=0.045, tol=0.014):
    """WSOLA zaman sikistirma/uzatma (perde degismez). ratio > 1 -> daha kisa.
    Hann pencereli %50 ortusme + capraz ilinti hizalamasi: tik / faz kirilmasi olmaz."""
    x = np.asarray(x, float)
    W = n_of(win)
    W += W % 2
    H = W // 2
    T = n_of(tol)
    n_out = int(len(x) / ratio)
    if len(x) < 3 * W or n_out < 2 * W:
        return np.interp(np.linspace(0, len(x) - 1, max(2, n_out)), np.arange(len(x)), x)
    xp = np.concatenate([x, np.zeros(2 * W + T)])
    out = np.zeros(n_out + 2 * W)
    ws = np.zeros(n_out + 2 * W)
    w = np.hanning(W)
    prev = None
    po = 0
    while po < n_out:
        pi = int(po * ratio)
        if prev is None:
            best = pi
        else:
            target = xp[prev + H: prev + H + W]
            lo = max(0, pi - T)
            hi = max(lo, min(len(x) - 1, pi + T))
            seg = xp[lo: hi + W]
            c = np.correlate(seg, target, 'valid')
            best = lo + int(np.argmax(c)) if len(c) else pi
        out[po:po + W] += xp[best:best + W] * w
        ws[po:po + W] += w
        prev = best
        po += H
    y = out[:n_out] / np.maximum(ws[:n_out], 0.5)
    return y
