"""Vexmira 5.3.3 shop item sounds (one per item family), mono 16-bit 22050 Hz.

    cd devtools/sfx && python3 make_item533.py

Out: cstrike/sound/vexmira/item533/<name>.wav
  heal     soft rising chime + breath            armor    metal plates clamp + click
  madness  monster roar + heartbeat + distortion  rage     low growl + fire whoosh
  cloak    shimmer that fades into air            jump     spring boing + whoosh
  speed    turbine whoosh rising                  shield   energy field hum + zap
  regen    bubbling organic pulse                 ammo     magazine slide + click clack
  antidote glass sparkle + cleansing hiss         serum    syringe hiss + mutation squelch
  power    generic power-up sweep
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sfx_lib import (n_of, sine, saw, square, noise, sweep, env_exp, env_adsr, lp, hp, bp, bp_sweep, lp_sweep,  # noqa: E402
                     formant, dist, reverb, mix, write_wav, tremolo, reverse)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cstrike', 'sound', 'vexmira', 'item533')
R = np.random.default_rng(533)


def at(x, n_total, start):
    out = np.zeros(n_total)
    i = n_of(start)
    out[i:i + len(x)] += x[:max(0, n_total - i)]
    return out


def heal():
    d = 1.2
    ch = sum(sine(f, d) * env_exp(d, 0.5) * g for f, g in ((784, 0.4), (1047, 0.35), (1319, 0.3), (1568, 0.2)))
    rise = sweep(400, 1200, d) * env_adsr(d, 0.1, 0.4, 0.4, 0.4) * 0.2
    breath = bp(noise(d), 800, 3000) * env_adsr(d, 0.3, 0.4, 0.2, 0.4) * 0.25
    return reverb(mix(ch, rise, breath), 1.5, 0.35)


def armor():
    d = 0.9
    n = n_of(d)
    x = np.zeros(n)
    for t0 in (0.0, 0.16, 0.34):
        clang = sum(sine(f, 0.5) * env_exp(0.5, 0.08) for f in (620, 1480, 2390)) * 0.4
        x += at(clang + bp(noise(0.5), 1500, 6000) * env_exp(0.5, 0.02), n, t0)
    x += at(hp(noise(0.1), 3000) * env_exp(0.1, 0.01) * 0.8, n, 0.6)
    return reverb(x, 0.6, 0.2)


def madness():
    d = 1.6
    roar = formant(saw(70, d) * env_adsr(d, 0.05, 0.4, 0.7, 0.5), [(400, 150, 1.0), (900, 200, 0.7), (2200, 400, 0.3)])
    roar = dist(roar + bp(noise(d), 200, 2000) * env_adsr(d, 0.05, 0.4, 0.6, 0.5) * 0.4, 3.0)
    beat = np.zeros(n_of(d))
    for t0 in (0.9, 1.2):
        beat += at(lp(noise(0.2, 'brown'), 120, 4) * env_exp(0.2, 0.05) * 2.0, n_of(d), t0)
    return reverb(mix(roar, beat), 1.0, 0.25)


def rage():
    d = 1.3
    growl = dist(formant(saw(55, d) * env_adsr(d, 0.1, 0.4, 0.6, 0.4), [(300, 120, 1.0), (700, 200, 0.6)]), 2.5)
    whoosh = bp_sweep(noise(d), 200, 3000, 0.6) * env_adsr(d, 0.2, 0.4, 0.5, 0.4)
    return mix(growl, whoosh * 0.8)


def cloak():
    d = 1.2
    sh = lp_sweep(sum(sine(f, d) * 0.25 for f in (900, 1350, 2025)) * env_adsr(d, 0.05, 0.4, 0.4, 0.6), 7000, 600)
    air = hp(noise(d), 4000) * env_adsr(d, 0.02, 0.3, 0.3, 0.6) * 0.4
    return reverb(mix(sh, air), 2.0, 0.45)


def jump():
    d = 0.7
    boing = sweep(180, 620, d) * env_exp(d, 0.25) * (1 + 0.4 * sine(18, d))
    whoosh = bp_sweep(noise(d), 500, 3000, 0.5) * env_adsr(d, 0.02, 0.2, 0.3, 0.3) * 0.6
    return mix(boing * 0.7, whoosh)


def speed():
    d = 1.1
    turb = sum(sweep(f0, f0 * 3.2, d) for f0 in (180, 270)) * env_adsr(d, 0.05, 0.5, 0.6, 0.3) * 0.25
    whoosh = bp_sweep(noise(d), 400, 5000, 0.4) * env_adsr(d, 0.1, 0.5, 0.5, 0.3)
    return mix(turb, whoosh)


def shield():
    d = 1.2
    hum = (sine(110, d) + 0.5 * sine(220, d) + 0.3 * sine(330, d)) * env_adsr(d, 0.1, 0.5, 0.6, 0.4) * 0.4
    hum = tremolo(hum, 12, 0.4)
    zap = hp(noise(d), 2500) * env_exp(d, 0.05)
    return reverb(mix(hum, zap * 0.6), 1.0, 0.3)


def regen():
    d = 1.2
    n = n_of(d)
    x = lp(noise(d, 'brown'), 300, 2) * env_adsr(d, 0.1, 0.4, 0.5, 0.4) * 0.5
    for _ in range(18):
        f0 = R.uniform(250, 700)
        x += at(sweep(f0, f0 * 1.6, 0.08) * env_exp(0.08, 0.03) * 0.5, n, R.uniform(0.05, d - 0.12))
    return x


def ammo():
    d = 0.8
    n = n_of(d)
    x = at(bp(noise(0.25), 800, 4000) * env_adsr(0.25, 0.01, 0.1, 0.5, 0.1) * 0.6, n, 0.0)      # slide
    for t0 in (0.32, 0.45):
        x += at(hp(noise(0.06), 2000) * env_exp(0.06, 0.008) + sine(2200, 0.06) * env_exp(0.06, 0.01) * 0.5, n, t0)
    return x


def antidote():
    d = 1.2
    sp = sum(sine(f, d) * env_exp(d, 0.3 + i * 0.08) * 0.2 for i, f in enumerate((1760, 2349, 2637, 3136, 3520)))
    hiss = bp(noise(d), 3000, 8000) * env_adsr(d, 0.05, 0.4, 0.4, 0.5) * 0.4
    return reverb(mix(sp, hiss), 1.5, 0.35)


def serum():
    d = 1.1
    hiss = bp(noise(d), 2000, 7000) * env_adsr(d, 0.01, 0.2, 0.3, 0.2) * 0.6
    squelch = formant(saw(90, d) * env_adsr(d, 0.3, 0.3, 0.5, 0.3), [(500, 200, 1.0), (1200, 300, 0.4)]) * 0.6
    return mix(hiss, at(squelch, n_of(d), 0.15)[:n_of(d)])


def power():
    d = 1.0
    sw = sweep(220, 1760, d) * env_adsr(d, 0.02, 0.5, 0.5, 0.3) * 0.3
    sh = sum(sine(f, d) * env_exp(d, 0.4) * 0.15 for f in (880, 1320, 1760))
    return reverb(mix(sw, sh), 1.0, 0.3)


SOUNDS = dict(heal=heal, armor=armor, madness=madness, rage=rage, cloak=cloak, jump=jump, speed=speed,
              shield=shield, regen=regen, ammo=ammo, antidote=antidote, serum=serum, power=power)


def main():
    for name, fn in SOUNDS.items():
        p = os.path.join(OUT, name + '.wav')
        sec = write_wav(p, fn(), loud=-14.0, max_len=1.7)
        print('  %-8s %.2f s %d bytes' % (name, sec, os.path.getsize(p)))


if __name__ == '__main__':
    main()
