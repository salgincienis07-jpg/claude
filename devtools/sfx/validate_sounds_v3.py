# Vexmira v3 ses dogrulayici + spektrogram onizleme
#   python3 validate_sounds_v3.py            -> tum v3 seslerini dogrula (cikis kodu 1 = hata)
#   python3 validate_sounds_v3.py --png DIR  -> ayrica spektrogram kontakt sayfalari uret
# Kontroller: RIFF yapisi (sadece 'fmt ' + 'data'; 'cue '/'smpl'/'LIST' YOK), PCM mono 16 bit,
# 22050/11025 Hz, sure araligi (kategori), boyut <= 160 KB, toplam <= 9 MB, tepe <= -0.5 dBFS,
# kirpilmis ornek yok, DC < 0.003, uc ornekler ~0 (tik yok), yukluk (v2 olcusu + LUFS benzeri).
import os, sys, struct, glob
import numpy as np
from scipy import signal

ROOT = '/home/user/claude/cstrike/sound/vexmira'
BOSSES = ['brute', 'banshee', 'overlord', 'inferno', 'reaper', 'frostlord', 'stormcaller', 'hivequeen', 'void']
CLASSES = ['walker', 'runner', 'tank', 'banshee', 'leech', 'stalker', 'bomber', 'frost', 'spitter', 'hulk', 'voodoo',
           'phantom', 'butcher', 'hunter', 'charger', 'arachne', 'magma', 'volt', 'mimic', 'burrower', 'siren',
           'bulwark', 'sporemother', 'nightmare']
EXTRAS = ['hunter_impact', 'charger_impact', 'arachne_webhit', 'burrower_erupt', 'sporemother_burst', 'mimic_reveal',
          'volt_zap']
RANGES = {'intro': (2.0, 3.5), 'idle': (1.0, 2.5), 'pain': (0.3, 0.8), 'death': (1.0, 2.5), 'step': (0.2, 0.5),
          'attack': (0.4, 0.9), 'ability': (0.6, 2.0), 'ui': (0.1, 0.8), 'hook': (0.3, 1.5), 'extra': (0.4, 2.0)}


def expected():
    out = []
    for b in BOSSES:
        for s, c in (('intro', 'intro'), ('idle', 'idle'), ('pain1', 'pain'), ('pain2', 'pain'), ('death', 'death'),
                     ('step', 'step'), ('attack', 'attack'), ('phase', 'ability'), ('kill', 'ability')):
            out.append((f'boss/{b}_{s}.wav', c))
    for sp in ('nemesis', 'assassin'):
        for s, c in (('intro', 'intro'), ('idle', 'idle'), ('pain', 'pain'), ('death', 'death'), ('attack', 'attack')):
            out.append((f'special/{sp}_{s}.wav', c))
    for c in CLASSES:
        for s, k in (('pain', 'pain'), ('die', 'death'), ('idle', 'idle'), ('ability', 'ability')):
            out.append((f'class/{c}_{s}.wav', k))
    for e in EXTRAS:
        out.append((f'class/{e}.wav', 'extra'))
    for h in ('throw', 'chain', 'hit', 'pull', 'miss'):
        out.append((f'hook/{h}.wav', 'hook'))
    for u in ('vote_start', 'vote_end', 'boss_bar', 'menu_select', 'class_select'):
        out.append((f'ui/{u}.wav', 'ui'))
    return out


def read_wav(path):
    b = open(path, 'rb').read()
    assert b[:4] == b'RIFF' and b[8:12] == b'WAVE', 'RIFF/WAVE degil'
    assert struct.unpack('<I', b[4:8])[0] == len(b) - 8, 'RIFF boyutu tutarsiz'
    p, chunks, fmt, data = 12, [], None, None
    while p + 8 <= len(b):
        cid = b[p:p + 4]
        sz = struct.unpack('<I', b[p + 4:p + 8])[0]
        chunks.append(cid.decode('latin1'))
        body = b[p + 8:p + 8 + sz]
        if cid == b'fmt ':
            fmt = struct.unpack('<HHIIHH', body[:16])
        elif cid == b'data':
            data = np.frombuffer(body, dtype='<i2')
        p += 8 + sz + (sz & 1)
    return chunks, fmt, data, len(b)


def kweight(x, sr):
    # BS.1770 K agirliklandirma (RBJ ile yeniden tasarlanmis: raf +4 dB @1681 Hz, HP 38 Hz)
    A = 10 ** (4.0 / 40)
    w0 = 2 * np.pi * 1681.97 / sr
    al = np.sin(w0) / 2 * np.sqrt(2)
    cw = np.cos(w0)
    b = [A * ((A + 1) + (A - 1) * cw + 2 * np.sqrt(A) * al), -2 * A * ((A - 1) + (A + 1) * cw),
         A * ((A + 1) + (A - 1) * cw - 2 * np.sqrt(A) * al)]
    a = [(A + 1) - (A - 1) * cw + 2 * np.sqrt(A) * al, 2 * ((A - 1) - (A + 1) * cw), (A + 1) - (A - 1) * cw - 2 * np.sqrt(A) * al]
    y = signal.lfilter(b, a, x)
    return signal.sosfilt(signal.butter(2, 38 / (sr / 2), 'high', output='sos'), y)


def lufs(x, sr):
    y = kweight(x, sr)
    w, h = int(0.4 * sr), int(0.1 * sr)
    if len(y) < w:
        ms = [np.mean(y ** 2)]
    else:
        ms = [np.mean(y[i:i + w] ** 2) for i in range(0, len(y) - w + 1, h)]
    ms = np.array(ms)
    l = -0.691 + 10 * np.log10(ms + 1e-12)
    ms = ms[l > -70]
    if not len(ms):
        return -99.0
    rel = -0.691 + 10 * np.log10(np.mean(ms)) - 10
    ms2 = ms[-0.691 + 10 * np.log10(ms) > rel]
    return float(-0.691 + 10 * np.log10(np.mean(ms2 if len(ms2) else ms)))


def pwrms(x, sr, win=0.3):
    w = int(sr * win)
    if len(x) <= w:
        return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)
    c = np.cumsum(np.concatenate([[0.0], x ** 2]))
    idx = np.arange(0, len(x) - w + 1, max(1, w // 4))
    return 20 * np.log10(np.sqrt(np.max((c[idx + w] - c[idx]) / w)) + 1e-12)


def analyze(path):
    chunks, fmt, data, size = read_wav(path)
    errs = []
    if chunks != ['fmt ', 'data']:
        errs.append('chunk listesi ' + str(chunks))
    tag, ch, sr, br, ba, bits = fmt
    if tag != 1 or ch != 1 or bits != 16:
        errs.append(f'format tag={tag} ch={ch} bits={bits}')
    if sr not in (22050, 11025):
        errs.append(f'sr={sr}')
    x = data.astype(float) / 32768.0
    dur = len(x) / sr
    peak = float(np.max(np.abs(x)))
    clip = int(np.sum(np.abs(data.astype(int)) >= 32700))
    dc = float(np.mean(x))
    edge = max(abs(x[0]), abs(x[-1]))
    spec = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    fr = np.fft.rfftfreq(len(x), 1 / sr)
    cent = float(np.sum(fr * spec) / (np.sum(spec) + 1e-12))
    return dict(chunks=chunks, sr=sr, dur=dur, size=size, peak_db=20 * np.log10(peak + 1e-12), clip=clip, dc=dc,
                edge=edge, pw=pwrms(x, sr), lufs=lufs(x, sr), cent=cent, errs=errs, x=x)


# ---------------- spektrogram ----------------
_CM = np.array([[0, 0, 4], [40, 11, 84], [101, 21, 110], [159, 42, 99], [212, 72, 66], [245, 125, 21],
                [250, 193, 39], [252, 255, 164]], float)


def cmap(v):
    v = np.clip(v, 0, 1) * (len(_CM) - 1)
    i = np.minimum(v.astype(int), len(_CM) - 2)
    f = (v - i)[..., None]
    return (_CM[i] * (1 - f) + _CM[i + 1] * f).astype(np.uint8)


def spectro_img(x, sr, W=300, H=110, dmax=3.5):
    nfft = 512 if sr == 22050 else 256
    hop = max(16, int(len(x) / W))
    f, t, Z = signal.stft(x, sr, nperseg=nfft, noverlap=max(0, nfft - hop), boundary=None)
    S = 20 * np.log10(np.abs(Z) + 1e-7)
    S = (S - (S.max() - 80)) / 80
    # frekans ekseni: 0..11025 Hz, kare koklu olcek (alt frekanslar genis)
    fy = (np.linspace(1, 0, H) ** 2) * 11025
    rows = np.array([np.interp(fy, f, S[:, j], right=0) for j in range(S.shape[1])]).T
    cols = np.linspace(0, rows.shape[1] - 1, max(2, int(W * min(1.0, len(x) / sr / dmax))))
    img = np.array([np.interp(cols, np.arange(rows.shape[1]), r) for r in rows])
    full = np.zeros((H, W))
    full[:, :img.shape[1]] = img
    return cmap(full)


def contact_sheet(items, path, cols=4, W=300, H=110, title=''):
    from PIL import Image, ImageDraw
    rows = (len(items) + cols - 1) // cols
    pad, lab = 6, 14
    im = Image.new('RGB', (cols * (W + pad) + pad, rows * (H + lab + pad) + pad + 18), (18, 14, 26))
    dr = ImageDraw.Draw(im)
    dr.text((pad, 3), title + '   (y: 0-11 kHz sqrt, x: 0-3.5 s)', fill=(200, 180, 255))
    for k, (name, x, sr) in enumerate(items):
        r, c = divmod(k, cols)
        X, Y = pad + c * (W + pad), 18 + pad + r * (H + lab + pad)
        dr.text((X, Y), name, fill=(220, 220, 220))
        im.paste(Image.fromarray(spectro_img(x, sr, W, H)), (X, Y + lab))
    im.save(path)


def main():
    png = None
    if '--png' in sys.argv:
        png = sys.argv[sys.argv.index('--png') + 1]
    exp = expected()
    total, bad, res = 0, 0, {}
    for rel, cat in exp:
        p = os.path.join(ROOT, rel)
        if not os.path.exists(p):
            print('EKSIK', rel)
            bad += 1
            continue
        a = analyze(p)
        lo, hi = RANGES[cat]
        e = list(a['errs'])
        if not (lo - 1e-3 <= a['dur'] <= hi + 1e-3):
            e.append(f'sure {a["dur"]:.2f} ({lo}-{hi})')
        if a['size'] > 160 * 1024:
            e.append(f'boyut {a["size"] // 1024} KB')
        if a['peak_db'] > -0.5:
            e.append(f'tepe {a["peak_db"]:.2f} dBFS')
        if a['clip']:
            e.append(f'kirpma {a["clip"]}')
        if abs(a['dc']) > 0.003:
            e.append(f'DC {a["dc"]:.4f}')
        if a['edge'] > 0.01:
            e.append(f'uc ornek {a["edge"]:.3f}')
        if a['sr'] == 11025 and cat not in ('step', 'pain'):
            e.append('11025 Hz sadece adim/kisa aci icin')
        total += a['size']
        res[rel] = (cat, a)
        flag = 'OK ' if not e else 'ERR'
        bad += bool(e)
        print(f'{flag} {rel:34} {a["sr"]:5}Hz {a["dur"]:5.2f}s {a["size"] // 1024:4}KB peak {a["peak_db"]:6.2f} '
              f'pwRMS {a["pw"]:6.1f} LUFS {a["lufs"]:6.1f} cent {a["cent"]:6.0f} {"; ".join(e)}')
    print(f'\nTOPLAM {len(res)}/{len(exp)} dosya, {total / 1e6:.2f} MB ({total / 1048576:.2f} MiB), hata {bad}')
    if total > 9 * 1024 * 1024:
        print('HATA: toplam > 9 MB')
        bad += 1
    # kategori bazinda yukluk ozeti + v2 karsilastirmasi
    cats = {}
    for rel, (cat, a) in res.items():
        cats.setdefault(cat, []).append(a['lufs'])
    for c, v in sorted(cats.items()):
        print(f'  {c:8} n={len(v):3} LUFS median {np.median(v):6.1f}  min {min(v):6.1f}  max {max(v):6.1f}')
    v2 = [f for f in glob.glob(ROOT + '/*.wav')]
    if v2:
        l2 = []
        for f in v2:
            try:
                l2.append(analyze(f)['lufs'])
            except Exception:
                pass
        print(f'  v2 referans n={len(l2)} LUFS median {np.median(l2):6.1f}  (p10 {np.percentile(l2, 10):.1f}, p90 {np.percentile(l2, 90):.1f})')
    if png and res:
        os.makedirs(png, exist_ok=True)
        groups = {}
        for rel, (cat, a) in res.items():
            folder = rel.split('/')[0]
            if folder == 'boss':
                key = 'boss_' + rel.split('/')[1].split('_')[0]
                key = 'boss_a' if any(rel.split('/')[1].startswith(b) for b in BOSSES[:5]) else 'boss_b'
            elif folder == 'class':
                nm = rel.split('/')[1]
                idx = next((i for i, c in enumerate(CLASSES) if nm.startswith(c + '_')), 99)
                key = 'class_a' if idx < 8 else ('class_b' if idx < 16 else 'class_c')
            else:
                key = 'misc'
            groups.setdefault(key, []).append((rel.split('/')[1][:-4], a['x'], a['sr']))
        for k, items in groups.items():
            cols = 9 if k.startswith('boss') else (4 if k.startswith('class') else 5)
            contact_sheet(items, os.path.join(png, f'spec_{k}.png'), cols, 210 if cols == 9 else 300, 90, k)
        print('onizleme:', png)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
