# Vexmira v3.2 - CSO tarzi ekran bildirimi sesleri (7 kisa WAV, prosedurel, sabit tohum)
#   python3 make_cso_sounds.py [cikti_klasoru]
# Cikti: cstrike/sound/vexmira/cso/*.wav  (mono 16 bit 22050 Hz; 2D "spk" ile calinir,
#   eklenti precache_generic kullanir -> ses yuvasi harcamaz)
import os, sys
sys.dont_write_bytecode = True
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sfx_lib as L
from sfx_lib import *

OUT = sys.argv[1] if len(sys.argv) > 1 else '/home/user/claude/cstrike/sound/vexmira/cso'


def at(x, n_total, start):
    out = np.zeros(n_total)
    s = n_of(start)
    e = min(n_total, s + len(x))
    out[s:e] += x[:e - s]
    return out


def km():
    # olum isareti: metalik "tik" + parlak cift nota (CSO killmark)
    d = 0.55
    n = n_of(d)
    hit = metal_hit(1150, 0.35, 0.08, 'plate') * 0.7
    b1 = bell(1320, 0.5, 2.0, 1.6, 0.16) * 0.55
    b2 = bell(1980, 0.45, 2.0, 1.2, 0.14) * 0.45
    return mix(at(hit, n, 0), at(b1, n, 0.0), at(b2, n, 0.07), at(crack(0.06, 3000, 9000) * 0.4, n, 0))


def km_sp():
    # headshot / bicak / bomba: daha agir darbe + yukselen parlama
    d = 0.8
    n = n_of(d)
    th = thump(0.4, 70, 0.1) * 0.9
    hit = metal_hit(700, 0.5, 0.15, 'plate') * 0.6
    up = sine(sweep(900, 2400, 0.25), 0.25) * env_lin([(0, 0), (0.2, 1), (1, 0)], 0.25) * 0.35
    b = bell(2200, 0.55, 2.0, 1.8, 0.2) * 0.5
    return mix(at(th, n, 0), at(hit, n, 0), at(up, n, 0.03), at(b, n, 0.22))


def mvp():
    # MVP: parlak akor + zil arpej
    d = 1.6
    n = n_of(d)
    st = chord_stab([523.25, 659.25, 783.99, 1046.5], 1.4, 6000, 1200) * 0.7
    parts = [at(st, n, 0)]
    for i, f in enumerate((1046.5, 1318.5, 1568.0, 2093.0)):
        parts.append(at(chime(f, 0.7, 0.25) * 0.35, n, 0.08 + i * 0.09))
    return reverb(mix(*parts), 1.0, 0.25)


def banner():
    # round / mod bandi: hizli whoosh + darbe
    d = 1.1
    n = n_of(d)
    w = whoosh(0.45, 300, 4500, 0.85) * 0.8
    b = boom(0.8, 110, 40, 0.22) * 0.9
    s = chord_stab([110, 164.8, 220], 0.7, 3000, 400) * 0.5
    return reverb(mix(at(w, n, 0), at(b, n, 0.4), at(s, n, 0.4)), 0.9, 0.2)


def win():
    # kazanan: yukselen iki akor
    d = 1.8
    n = n_of(d)
    a = chord_stab([392.0, 493.9, 587.3], 0.6, 5000, 900) * 0.6
    b = chord_stab([523.25, 659.25, 783.99, 1046.5], 1.2, 6500, 900) * 0.75
    t = timpani(65, 1.0) * 0.6
    return reverb(mix(at(a, n, 0), at(t, n, 0.0), at(b, n, 0.42), at(t * 0.8, n, 0.42)), 1.2, 0.25)


def alert():
    # boss / enfeksiyon / son insan: alarm darbe + braam
    d = 1.6
    n = n_of(d)
    br = braam(55, 1.4, 2.2) * 0.8
    bp1 = beep(880, 0.12, 'square') * 0.3
    bp2 = beep(660, 0.12, 'square') * 0.3
    return reverb(mix(at(br, n, 0.05), at(bp1, n, 0), at(bp2, n, 0.16), at(bp1, n, 0.32)), 1.0, 0.2)


def level():
    # seviye atlama: yukselen parlak arpej
    d = 1.2
    n = n_of(d)
    parts = []
    for i, f in enumerate((659.25, 783.99, 987.77, 1318.5, 1568.0)):
        parts.append(at(bell(f, 0.6, 2.0, 1.4, 0.2) * 0.4, n, i * 0.07))
    parts.append(at(riser(0.4, 400, 3000) * 0.25, n, 0))
    return reverb(mix(*parts), 1.0, 0.25)


SOUNDS = {'km': (km, 0.7), 'km_sp': (km_sp, 0.9), 'mvp': (mvp, 1.8), 'banner': (banner, 1.3),
          'win': (win, 2.0), 'alert': (alert, 1.8), 'levelup': (level, 1.4)}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    tot = 0
    for name, (fn, mx) in SOUNDS.items():
        L.reseed(sum(map(ord, name)))
        p = os.path.join(OUT, name + '.wav')
        dur = write_wav(p, fn(), 22050, 0.9, -16.0, mx)
        sz = os.path.getsize(p)
        tot += sz
        print('%-10s %.2fs %6d bytes' % (name, dur, sz))
    print('toplam %d bytes' % tot)
