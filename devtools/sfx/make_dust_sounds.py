"""zm_vexmira_dust sounds (2 small one-shots, 8-bit mono 11025 Hz, no cue):
  dust_gong.wav    3 s market gong (gong button)
  dust_storm.wav   5 s sandstorm gust (sandstorm button; the plugin adds brown fog + dust puffs)

    cd devtools && python3 sfx/make_dust_sounds.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_ice_sounds import SR, periodic_noise, write  # noqa: E402
import make_ice_sounds  # noqa: E402

make_ice_sounds.OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cstrike', 'sound',
                                   'vexmira', 'map')


def gong(rng):
    n = SR * 3
    t = np.arange(n) / SR
    x = np.zeros(n)
    for f, a, d in ((110, 1.0, 2.2), (164, 0.6, 1.8), (233, 0.5, 1.4), (318, 0.35, 1.0), (447, 0.25, 0.7), (612, 0.15, 0.5)):
        wob = 1 + 0.004 * np.sin(2 * np.pi * 3.1 * t)
        x += a * np.sin(2 * np.pi * f * t * wob) * np.exp(-t / d)
    x *= np.minimum(1, t / 0.01) * (1 + 0.3 * np.exp(-t / 0.08))
    return x


def storm(rng):
    n = SR * 5
    t = np.arange(n) / n
    x = periodic_noise(n, 60, 2500, rng, tilt=0.9)
    hiss = periodic_noise(n, 1500, 4500, rng)
    env = np.minimum(1, t / 0.25) * np.minimum(1, (1 - t) / 0.35)
    g = 0.7 + 0.3 * np.sin(2 * np.pi * 2.3 * t) * np.sin(2 * np.pi * 0.7 * t + 1)
    return (x + 0.4 * hiss) * env * g


def main():
    rng = np.random.default_rng(7201)
    write('dust_gong.wav', gong(rng), False)
    write('dust_storm.wav', storm(rng), False)


if __name__ == '__main__':
    main()
