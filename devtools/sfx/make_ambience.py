"""Ambient life + event sounds for zm_vexmira_7door (v3.8): distant gunfire, dogs, far siren, far helicopter,
PA announcement, steam hiss, incoming artillery whistle, heli touchdown. Mono 16-bit, 11025 Hz (distant
sounds are band limited anyway), no cue chunk (one-shots). The plugin plays them from the map ini
[ambience] / [fx] sections (positional EmitAmbientSound, low volume, spaced random intervals).

    cd devtools && python3 sfx/make_ambience.py
"""
import os
import subprocess
import tempfile
import wave

import numpy as np
from scipy import signal

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'cstrike', 'sound', 'vexmira', 'amb')
SR = 11025


def bp(x, lo, hi, o=2):
    return signal.sosfilt(signal.butter(o, [lo / (SR / 2), hi / (SR / 2)], 'band', output='sos'), x)


def lp(x, f, o=2):
    return signal.sosfilt(signal.butter(o, f / (SR / 2), 'low', output='sos'), x)


def hp(x, f, o=2):
    return signal.sosfilt(signal.butter(o, f / (SR / 2), 'high', output='sos'), x)


def env(n, a, d):
    t = np.arange(n) / SR
    return np.minimum(1, t / max(a, 1e-4)) * np.exp(-t / d)


def verb(x, rng, dec=1.2, mix=0.4):
    L = int(SR * dec * 1.5)
    ir = rng.standard_normal(L) * np.exp(-np.arange(L) / (SR * dec / 3))
    ir = lp(ir, 2500)
    w = signal.fftconvolve(x, ir)[:len(x) + L // 2]
    w /= np.abs(w).max() + 1e-9
    y = np.concatenate([x, np.zeros(len(w) - len(x))])
    return y * (1 - mix) + w * mix * np.abs(x).max()


def write(name, x):
    x = x / (np.abs(x).max() + 1e-9) * 0.9
    f = int(SR * 0.01)
    x[-f:] *= np.linspace(1, 0, f)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(np.round(np.clip(x, -1, 1) * 32767).astype('<i2').tobytes())
    print('  %-16s %.2f s' % (name, len(x) / SR))


def gunfire(rng):
    x = np.zeros(int(SR * 3.2))
    t = 0.2
    for burst in range(3):
        for k in range(rng.integers(3, 7)):
            n = int(SR * 0.25)
            s = (rng.standard_normal(n) * env(n, 0.001, 0.03) + np.sin(2 * np.pi * 90 * np.arange(n) / SR) * env(n, 0.002, 0.06))
            i = int(SR * t)
            x[i:i + n] += s[:len(x) - i] * rng.uniform(0.6, 1.0)
            t += rng.uniform(0.08, 0.12)
        t += rng.uniform(0.4, 0.8)
    return verb(lp(x, 1400), rng, 1.6, 0.55)


def dog(rng):
    x = np.zeros(int(SR * 2.4))
    t = 0.1
    for k in range(3):
        n = int(SR * rng.uniform(0.16, 0.24))
        tt = np.arange(n) / SR
        f0 = 420 + 260 * np.sin(np.pi * tt / tt[-1]) + rng.uniform(-30, 30)
        ph = 2 * np.pi * np.cumsum(f0) / SR
        s = sum(np.sin(h * ph) / h for h in range(1, 7)) + 0.3 * rng.standard_normal(n)
        s = bp(s, 400, 2600) * np.sin(np.pi * tt / tt[-1]) ** 0.6
        i = int(SR * t)
        x[i:i + n] += s
        t += rng.uniform(0.35, 0.6)
    return verb(lp(x, 2200), rng, 1.4, 0.5)


def siren_far(rng):
    n = int(SR * 5.0)
    t = np.arange(n) / SR
    f = 600 + 260 * np.sin(2 * np.pi * 0.45 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = (np.sin(ph) + 0.4 * np.sin(2 * ph)) * np.minimum(1, t / 0.8) * np.minimum(1, (t[-1] - t) / 1.2)
    return verb(lp(x, 1600), rng, 2.0, 0.6)


def heli_far(rng):
    n = int(SR * 5.0)
    t = np.arange(n) / SR
    slap = np.zeros(n)
    for k in np.arange(0, 5.0, 1 / 9.5):
        i = int(k * SR)
        m = int(0.05 * SR)
        slap[i:i + m] += np.exp(-np.arange(min(m, n - i)) / (0.012 * SR))
    x = lp(slap, 300) * 1.4 + 0.25 * lp(rng.standard_normal(n), 500)
    x *= np.sin(np.pi * t / t[-1]) ** 1.5           # passes over, far away
    return verb(x, rng, 1.0, 0.4)


def pa(rng):
    chime = np.concatenate([np.sin(2 * np.pi * f * np.arange(int(SR * 0.35)) / SR) * env(int(SR * 0.35), 0.005, 0.25)
                            for f in (784, 659, 523)])
    with tempfile.TemporaryDirectory() as td:
        p = os.path.join(td, 'v.wav')
        subprocess.run(['espeak-ng', '-v', 'mb-us1', '-s', '150', '-w', p,
                        'Attention. This district is under quarantine. Stay indoors. Report all infected.'],
                       check=True, capture_output=True)
        with wave.open(p) as w:
            sr = w.getframerate()
            v = np.frombuffer(w.readframes(w.getnframes()), '<i2').astype(float) / 32768
    v = signal.resample_poly(v, SR, sr)
    v = bp(np.tanh(v * 3), 350, 3000)
    x = np.concatenate([chime * 0.6, np.zeros(int(SR * 0.15)), v / (np.abs(v).max() + 1e-9)])
    return verb(x, rng, 2.2, 0.55)                    # big outdoor loudspeaker echo


def steam(rng):
    n = int(SR * 2.2)
    t = np.arange(n) / SR
    x = hp(rng.standard_normal(n), 1500) * np.minimum(1, t / 0.05) * np.exp(-np.maximum(0, t - 1.4) / 0.3)
    x *= 0.8 + 0.2 * np.sin(2 * np.pi * 13 * t)
    return x


def whistle(rng):
    n = int(SR * 1.6)
    t = np.arange(n) / SR
    f = 2400 - 1500 * (t / t[-1]) ** 1.4
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * np.minimum(1, t / 0.2) * (0.4 + 0.6 * t / t[-1]) + 0.1 * bp(rng.standard_normal(n), 1500, 3500)
    return verb(x, rng, 0.8, 0.3)


def spark(rng):
    n = int(SR * 1.0)
    x = np.zeros(n)
    for k in range(rng.integers(5, 9)):
        m = int(SR * rng.uniform(0.01, 0.04))
        i = int(rng.uniform(0, 0.75) * SR)
        x[i:i + m] += hp(rng.standard_normal(m), 2500) * np.exp(-np.arange(m) / (0.006 * SR))
    hum = np.sin(2 * np.pi * 120 * np.arange(n) / SR) * 0.15 * (np.abs(x) > 0.05)
    return x + lp(hum, 400)


def heli_land(rng):
    n = int(SR * 1.8)
    t = np.arange(n) / SR
    thump = np.sin(2 * np.pi * 55 * t) * env(n, 0.003, 0.12) + 0.5 * lp(rng.standard_normal(n), 400) * env(n, 0.002, 0.08)
    clank = sum(np.sin(2 * np.pi * f * t) * a for f, a in ((310, 0.5), (720, 0.3), (1340, 0.2))) * env(n, 0.001, 0.15)
    hiss = hp(rng.standard_normal(n), 1800) * np.exp(-np.maximum(0, t - 0.4) / 0.5) * (t > 0.35) * 0.35
    return verb(thump + clank * 0.6 + hiss, rng, 0.6, 0.25)


def main():
    rng = np.random.default_rng(3800)
    for name, fn in (('gunfire_far.wav', gunfire), ('dog_far.wav', dog), ('siren_far.wav', siren_far),
                     ('heli_far.wav', heli_far), ('pa_quarantine.wav', pa), ('steam.wav', steam),
                     ('shell_whistle.wav', whistle), ('heli_land.wav', heli_land), ('spark.wav', spark)):
        write(name, fn(rng))


if __name__ == '__main__':
    main()
