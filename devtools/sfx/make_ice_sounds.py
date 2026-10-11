"""zm_vexmira_icefy sounds (3 small files, 8-bit mono 11025 Hz):
  ice_wind.wav   4 s seamless wind loop (cue chunk at 0 -> ambient_generic loops it)
  ice_fire.wav   3 s seamless campfire crackle loop (cue chunk)
  ice_alarm.wav  2.4 s klaxon one-shot (alarm button; no cue)
  ice_bell.wav   2.6 s hand bell (bell button; no cue)

    cd devtools && python3 sfx/make_ice_sounds.py
"""
import os
import struct

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'cstrike', 'sound', 'vexmira', 'map')
SR = 11025


def periodic_noise(n, lo, hi, rng, tilt=0.0):
    """Band limited noise that is exactly periodic over n samples (FFT synthesis) -> seamless loop."""
    f = np.fft.rfftfreq(n, 1 / SR)
    mag = ((f >= lo) & (f <= hi)).astype(float)
    mag[1:] *= (f[1:] / max(lo, 1)) ** -tilt
    spec = mag * np.exp(2j * np.pi * rng.random(len(f)))
    x = np.fft.irfft(spec, n)
    return x / (np.abs(x).max() + 1e-9)


def write(name, x, loop):
    x = x / (np.abs(x).max() + 1e-9) * 0.85
    data = np.clip(np.round(x * 127 + 128), 0, 255).astype(np.uint8).tobytes()
    fmt = struct.pack('<HHIIHH', 1, 1, SR, SR, 1, 8)
    chunks = b'fmt ' + struct.pack('<I', len(fmt)) + fmt
    if loop:
        cue = struct.pack('<I', 1) + struct.pack('<II4sIII', 1, 0, b'data', 0, 0, 0)
        chunks += b'cue ' + struct.pack('<I', len(cue)) + cue
    chunks += b'data' + struct.pack('<I', len(data)) + data + (b'\0' if len(data) % 2 else b'')
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', 4 + len(chunks)) + b'WAVE' + chunks)
    print('  %-14s %.2f s %d bytes' % (name, len(x) / SR, 44 + len(data)))


def wind(rng):
    n = SR * 4
    t = np.arange(n) / n
    base = periodic_noise(n, 80, 900, rng, tilt=1.2)
    howl = periodic_noise(n, 300, 520, rng)
    g = 0.65 + 0.25 * np.sin(2 * np.pi * t) + 0.1 * np.sin(2 * np.pi * 3 * t + 1)   # periodic gusts
    return base * g + 0.35 * howl * (0.5 + 0.5 * np.sin(2 * np.pi * 2 * t + 0.5))


def fire(rng):
    n = SR * 3
    x = 0.35 * periodic_noise(n, 60, 700, rng, tilt=1.0)
    for _ in range(46):                                   # crackles (wrap around -> seamless)
        p = rng.integers(0, n)
        L = int(rng.integers(30, 160))
        c = rng.standard_normal(L) * np.exp(-np.arange(L) / (L / 4)) * rng.uniform(0.4, 1.0)
        idx = (p + np.arange(L)) % n
        x[idx] += c
    return x


def alarm(rng):
    n = int(SR * 2.4)
    t = np.arange(n) / SR
    f = 520 + 260 * (np.mod(t, 0.6) / 0.6)                # rising klaxon sweeps
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sign(np.sin(ph)) * 0.6 + np.sin(2 * ph) * 0.3
    env = np.minimum(1, t / 0.02) * np.minimum(1, (2.4 - t) / 0.25)
    return x * env


def bell(rng):
    """Small hand bell: inharmonic partials, fast attack, 2.2 s decay, two strikes."""
    n = int(SR * 2.6)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k, (f, a, d) in enumerate(((880, 1.0, 1.2), (2090, 0.5, 0.6), (2560, 0.35, 0.5), (3520, 0.2, 0.3), (440, 0.3, 1.6))):
        for t0, g in ((0.0, 1.0), (0.55, 0.8)):
            tt = np.clip(t - t0, 0, None)
            x += g * a * np.sin(2 * np.pi * f * tt) * np.exp(-tt / d) * (t >= t0)
    return x * np.minimum(1, t / 0.003)


def main():
    rng = np.random.default_rng(7101)
    write('ice_wind.wav', wind(rng), True)
    write('ice_fire.wav', fire(rng), True)
    write('ice_alarm.wav', alarm(rng), False)
    write('ice_bell.wav', bell(rng), False)


if __name__ == '__main__':
    main()
