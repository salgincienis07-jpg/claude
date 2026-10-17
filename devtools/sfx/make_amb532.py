"""Vexmira 5.3.2 round ambience beds: 8 seamless loops, GoldSrc-safe format (8-bit MONO 11025 Hz + cue
chunk, so the engine loops them by itself). Stereo / 44 kHz wav files do not play in CS 1.6 at all.

    cd devtools && python3 sfx/make_amb532.py

Out: cstrike/sound/vexmira/amb532/<name>.wav  (24 s each)
  calm     infection rounds: low dark drone, distant wind, far eerie bells
  tension  multi / swarm / plague: slow heartbeat pulse under a rising drone
  hunt     nemesis / assassin: sub rumble, metallic scrapes, breathing pad
  hope     survivor / sniper: slow minor chord pad, soft shimmer
  storm    storm / blood moon / fog: rain hiss, rolling thunder
  frost    night / blackout / vampire: cold wind, creaks, hollow tones
  boss     boss rounds: war drums, heavy pulse, choir-like drone
  chaos    armageddon / meteor / horde / titan: detuned alarm drones, far explosions
Every component repeats an integer number of times per loop (or is FFT noise of the loop length),
so the loop point is invisible.
"""
import os
import struct

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'cstrike', 'sound', 'vexmira', 'amb532')
SR = 11025
L = 24.0
N = int(SR * L)
T = np.arange(N) / SR


def pnoise(lo, hi, rng, tilt=0.0):
    f = np.fft.rfftfreq(N, 1 / SR)
    mag = ((f >= lo) & (f <= hi)).astype(float)
    mag[1:] *= (f[1:] / max(lo, 1)) ** -tilt
    x = np.fft.irfft(mag * np.exp(2j * np.pi * rng.random(len(f))), N)
    return x / (np.abs(x).max() + 1e-9)


def tone(freq, amp=1.0, detune=0.0):
    """sine snapped to an integer number of cycles per loop"""
    c = max(1, round(freq * L))
    c2 = max(1, round((freq + detune) * L))
    x = np.sin(2 * np.pi * c * T / L)
    if detune:
        x = 0.5 * (x + np.sin(2 * np.pi * c2 * T / L))
    return amp * x


def lfo(cycles, lo=0.0, hi=1.0, phase=0.0):
    return lo + (hi - lo) * (0.5 + 0.5 * np.sin(2 * np.pi * cycles * T / L + phase))


def hit(at, length, decay, freq, rng, noise=0.5):
    """one-shot placed at time 'at' (wraps around the loop end)"""
    n = int(length * SR)
    t = np.arange(n) / SR
    s = (np.sin(2 * np.pi * freq * t * (1 - 0.3 * t / length)) * (1 - noise) + rng.standard_normal(n) * noise)
    s *= np.exp(-t / decay)
    x = np.zeros(N)
    idx = (int(at * SR) + np.arange(n)) % N
    x[idx] += s
    return x


def smooth(x, k=9):
    return np.convolve(np.concatenate([x[-k:], x, x[:k]]), np.ones(k) / k, 'same')[k:-k]


def calm(rng):
    x = tone(55, 0.5, 0.12) + tone(82.5, 0.25, 0.08) + tone(110, 0.12)
    x *= lfo(2, 0.6, 1.0)
    x += 0.35 * smooth(pnoise(90, 700, rng, 1.2), 5) * lfo(3, 0.4, 1.0, 1.0)
    for k, at in enumerate((3.0, 11.0, 18.5)):
        x += 0.18 * hit(at, 4.0, 1.4, [659, 784, 587][k], rng, 0.0)
    return x


def tension(rng):
    x = tone(49, 0.45, 0.2) + tone(73.5, 0.2, 0.1)
    x *= lfo(1, 0.5, 1.0)
    beat = np.zeros(N)
    for b in range(24):                                   # 60 bpm double-thump heartbeat
        beat += hit(b * 1.0, 0.25, 0.06, 48, rng, 0.15) + 0.6 * hit(b * 1.0 + 0.28, 0.25, 0.05, 44, rng, 0.15)
    x += 0.9 * beat
    x += 0.15 * pnoise(200, 1500, rng, 1.0) * lfo(4, 0.2, 0.8)
    return x


def hunt(rng):
    x = 0.6 * pnoise(25, 90, rng) * lfo(2, 0.5, 1.0) + tone(41, 0.35, 0.15)
    for at in (2.0, 9.5, 15.0, 21.0):                    # metallic scrapes
        n = int(1.4 * SR)
        t = np.arange(n) / SR
        s = np.sin(2 * np.pi * (900 + 600 * t) * t) * np.sin(2 * np.pi * 1530 * t) * np.exp(-t / 0.5) * 0.25
        idx = (int(at * SR) + np.arange(n)) % N
        x[idx] += s
    x += 0.25 * smooth(pnoise(150, 600, rng), 9) * lfo(6, 0.0, 1.0)   # breathing
    return x


def hope(rng):
    x = np.zeros(N)
    chords = [(220, 261.6, 329.6), (196, 246.9, 293.7), (174.6, 220, 261.6), (196, 246.9, 329.6)]
    seg = N // 4
    for i, ch in enumerate(chords):
        env = np.zeros(N)
        a = i * seg
        w = np.hanning(seg * 2)
        idx = (a - seg // 2 + np.arange(seg * 2)) % N
        env[idx] += w
        for f in ch:
            x += 0.18 * tone(f, 1.0, 0.25) * env
    x += 0.06 * pnoise(2000, 4500, rng) * lfo(3, 0.2, 1.0)
    return x


def storm(rng):
    x = 0.55 * pnoise(400, 4500, rng, 0.6)               # rain
    x += 0.12 * pnoise(3000, 5000, rng)
    for at, ln in ((4.0, 4.5), (13.0, 6.0), (20.5, 3.5)):
        n = int(ln * SR)
        t = np.arange(n) / SR
        r = np.convolve(rng.standard_normal(n), np.ones(60) / 60, 'same')
        s = r / (np.abs(r).max() + 1e-9) * np.exp(-t / (ln / 3)) * np.minimum(1, t / 0.08) * 1.4
        idx = (int(at * SR) + np.arange(n)) % N
        x[idx] += s
    return x


def frost(rng):
    x = 0.6 * pnoise(120, 1100, rng, 1.3) * lfo(2, 0.4, 1.0) * lfo(5, 0.7, 1.0, 2.0)
    x += 0.3 * pnoise(380, 560, rng) * lfo(3, 0.1, 0.9, 0.5)          # howl
    x += tone(98, 0.15, 0.05) + tone(147, 0.08)
    for at in (5.0, 12.5, 19.0):                                       # creaks
        n = int(0.6 * SR)
        t = np.arange(n) / SR
        s = np.sign(np.sin(2 * np.pi * (35 + 20 * t) * t)) * np.exp(-t / 0.2) * 0.15
        idx = (int(at * SR) + np.arange(n)) % N
        x[idx] += smooth(s, 5)
    return x


def boss(rng):
    x = tone(36.7, 0.5, 0.1) + tone(55, 0.3, 0.2) + tone(73.4, 0.18, 0.3) + tone(110, 0.1, 0.4)
    x *= lfo(4, 0.6, 1.0)
    for b in range(48):                                   # war drums, 120 bpm, accent every 4
        acc = 1.0 if b % 4 == 0 else (0.6 if b % 2 == 0 else 0.35)
        x += acc * hit(b * 0.5, 0.4, 0.09, 58, rng, 0.3)
    x += 0.12 * pnoise(500, 1200, rng) * lfo(1, 0.3, 1.0)
    return x


def chaos(rng):
    x = tone(220, 0.15, 1.3) * lfo(12, 0.2, 1.0) + tone(311, 0.12, 1.7) * lfo(8, 0.2, 1.0, 1.0)
    x += 0.4 * pnoise(30, 120, rng)
    for at in (1.5, 6.0, 10.2, 14.8, 19.3, 22.6):
        x += 0.8 * hit(at, 2.5, 0.5, 40, rng, 0.7)
    return x


BEDS = {'calm': calm, 'tension': tension, 'hunt': hunt, 'hope': hope, 'storm': storm, 'frost': frost,
        'boss': boss, 'chaos': chaos}


def write(name, x):
    # gentle limiter + fixed loudness (ambience sits UNDER the game: peaks at 70%)
    x = np.tanh(1.6 * x / (np.abs(x).max() + 1e-9)) / np.tanh(1.6) * 0.7
    data = np.clip(np.round(x * 127 + 128), 0, 255).astype(np.uint8).tobytes()
    fmt = struct.pack('<HHIIHH', 1, 1, SR, SR, 1, 8)
    cue = struct.pack('<I', 1) + struct.pack('<II4sIII', 1, 0, b'data', 0, 0, 0)
    chunks = b'fmt ' + struct.pack('<I', len(fmt)) + fmt + b'cue ' + struct.pack('<I', len(cue)) + cue
    chunks += b'data' + struct.pack('<I', len(data)) + data + (b'\0' if len(data) % 2 else b'')
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name + '.wav'), 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', 4 + len(chunks)) + b'WAVE' + chunks)
    print('  %-8s %.1f s %d bytes' % (name, L, 44 + len(data)))


def main():
    for i, (name, fn) in enumerate(BEDS.items()):
        write(name, fn(np.random.default_rng(5320 + i)))


if __name__ == '__main__':
    main()
