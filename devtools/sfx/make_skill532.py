"""Vexmira 5.3.2 zombie skill sounds: one fitting sound per generic ability (before: all used janus7_change1).

    cd devtools/sfx && python3 make_skill532.py

Out: cstrike/sound/vexmira/skill532/<name>.wav (mono 16-bit 22050 Hz, no loop)
  burst   explosive shock burst (deep boom + crack + debris)
  leap    powerful pounce (whoosh + grunt-like formant)
  shield  bone armour hardening (crystal shimmer + low thud)
  drain   life drain (reverse suck + heartbeat)
  cloak   vanishing (rising shimmer that fades into air)
  toxic   acid spray (wet hiss + bubbling)
  frost   cold blast (crackling ice + wind gust)
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sfx_lib import (n_of, tt, sine, saw, noise, sweep, env_exp, env_adsr, lp, hp, bp, bp_sweep, lp_sweep,  # noqa: E402
                     formant, dist, reverb, mix, write_wav, fit, reverse)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cstrike', 'sound', 'vexmira', 'skill532')
R = np.random.default_rng(532)


def burst():
    d = 1.4
    boom = lp(noise(d, 'brown'), 180, 4) * env_exp(d, 0.35) * 1.4
    sub = sine(42, d) * env_exp(d, 0.25)
    crack = hp(noise(d), 1800) * env_exp(d, 0.03)
    debris = bp(noise(d), 900, 4000) * env_exp(d, 0.5) * (R.random(n_of(d)) > 0.985) * 3
    return reverb(dist(mix(boom, sub, crack * 0.8, debris * 0.6), 1.8), 1.1, 0.25)


def leap():
    d = 0.8
    whoosh = bp_sweep(noise(d), 300, 2400, 0.5) * env_adsr(d, 0.05, 0.3, 0.4, 0.3)
    grunt = formant(saw(110, d) * env_exp(d, 0.18), [(600, 120, 1.0), (1000, 160, 0.6), (2400, 300, 0.3)])
    return mix(whoosh, dist(grunt, 2.0) * 0.7)


def shield():
    d = 1.2
    shimmer = sum(sine(f, d) * env_exp(d, 0.5 + i * 0.1) for i, f in enumerate((1320, 1760, 2349, 2794)))
    thud = lp(noise(d, 'brown'), 200, 4) * env_exp(d, 0.12) * 1.5
    crunch = bp(noise(d), 600, 2500) * env_exp(d, 0.06)
    return reverb(mix(shimmer * 0.35, thud, crunch * 0.6), 1.4, 0.3)


def drain():
    d = 1.3
    suck = reverse(bp_sweep(noise(d), 3000, 300, 0.4) * env_exp(d, 0.45))
    beat = np.zeros(n_of(d))
    for at in (0.15, 0.45, 0.85):
        i = n_of(at)
        b = lp(noise(0.2, 'brown'), 120, 4) * env_exp(0.2, 0.05) * 2
        beat[i:i + len(b)] += b[:len(beat) - i]
    tone = sweep(300, 90, d) * env_adsr(d, 0.2, 0.4, 0.5, 0.4) * 0.3
    return reverb(mix(suck, beat, tone), 1.2, 0.3)


def cloak():
    d = 1.3
    rise = sum(sine(f, d) * 0.25 for f in (700, 1050, 1575)) * env_adsr(d, 0.4, 0.5, 0.3, 0.5)
    rise = lp_sweep(rise, 800, 6000)
    air = hp(noise(d), 3000) * env_adsr(d, 0.6, 0.4, 0.2, 0.3) * 0.5
    return reverb(mix(rise, air), 2.0, 0.45)


def toxic():
    d = 1.3
    hiss = bp(noise(d), 1500, 7000) * env_adsr(d, 0.02, 0.4, 0.6, 0.6)
    bub = np.zeros(n_of(d))
    for _ in range(28):
        at = R.uniform(0.05, d - 0.15)
        f0 = R.uniform(300, 900)
        b = sweep(f0, f0 * 1.8, 0.07) * env_exp(0.07, 0.025)
        i = n_of(at)
        bub[i:i + len(b)] += b[:len(bub) - i] * 0.5
    return mix(hiss * 0.8, bub)


def frost():
    d = 1.3
    gust = bp_sweep(noise(d), 400, 1500, 0.6) * env_adsr(d, 0.1, 0.4, 0.5, 0.5)
    crackle = hp(noise(d), 2500) * (R.random(n_of(d)) > 0.992) * 4 * env_exp(d, 0.6)
    chime = sum(sine(f, d) * env_exp(d, 0.4) for f in (2093, 2637, 3136)) * 0.18
    return reverb(mix(gust, crackle, chime), 1.6, 0.35)


SOUNDS = {'burst': burst, 'leap': leap, 'shield': shield, 'drain': drain, 'cloak': cloak, 'toxic': toxic, 'frost': frost}


def main():
    for name, fn in SOUNDS.items():
        p = os.path.join(OUT, name + '.wav')
        sec = write_wav(p, fn(), loud=-14.0, max_len=1.6)
        print('  %-7s %.2f s %d bytes' % (name, sec, os.path.getsize(p)))


if __name__ == '__main__':
    main()
