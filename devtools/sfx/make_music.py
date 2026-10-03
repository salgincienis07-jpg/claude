# Vexmira boss / nemesis muzikleri (prosedurel, MP3). Round bitince plugin "mp3 stop" ile susturur.
import os, sys, subprocess
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from sfx_lib import *

OUT = sys.argv[1] if len(sys.argv) > 1 else '/home/user/claude/cstrike/sound/vexmira'
TMP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/gen/'


def note(n):
    # MIDI numarasi -> Hz
    return 440.0 * 2 ** ((n - 69) / 12.0)


def kick(d=0.45):
    f = 42 + 98 * np.exp(-tt(d) / 0.04)
    return mix(sine(f, d) * env_exp(d, 0.11), lp(noise(0.02), 2000) * 0.3)


def snare(d=0.3):
    body = sine(190, d) * env_exp(d, 0.05) * 0.5
    sn = bp(noise(d), 1500, 7000) * env_exp(d, 0.08)
    return mix(body, sn)


def tom(f, d=0.4):
    fr = f + 0.4 * f * np.exp(-tt(d) / 0.05)
    return sine(fr, d) * env_exp(d, 0.15)


def hat(d=0.06):
    return hp(noise(d), 7000) * env_exp(d, 0.015) * 0.4


def bass_note(f, d):
    x = saw(f, d, 18) * 0.7 + sine(f / 2, d) * 0.5
    return lp(x, 900) * env_adsr(d, 0.005, 0.08, 0.7, 0.04)


def strings(freqs, d, bright=1800):
    return pad(freqs, d, a=0.15, r=0.3, detune=0.005, bright=bright)


def brass(freqs, d):
    return chord_stab(freqs, d, 3500, 500)


def place(buf, sig, t, g=1.0):
    a = n_of(t)
    b = min(len(buf), a + len(sig))
    if a < len(buf):
        buf[a:b] += sig[: b - a] * g


def boss_theme():
    bpm = 140.0
    beat = 60.0 / bpm
    bars = 24
    total = bars * 4 * beat + 3.0
    buf = np.zeros(n_of(total))
    # D minor: Dm - Bb - F - C (her biri 2 bar)
    prog = [(50, [62, 65, 69]), (46, [58, 62, 65]), (41, [57, 60, 65]), (48, [55, 60, 64])]
    bass_pat = [0, 0, 3, 0, -2, 0, 7, 5]  # yari ton kaymalari (8'lik)
    # Giris riser
    place(buf, riser(4 * beat * 2, 120, 2200) * 0.35, 0.0)
    for bar in range(bars):
        t0 = bar * 4 * beat
        root, chord = prog[(bar // 2) % 4]
        intro = bar < 2
        # davul
        if not intro:
            for b in range(4):
                if b in (0, 2):
                    place(buf, kick(), t0 + b * beat, 0.9)
                if b in (1, 3):
                    place(buf, snare(), t0 + b * beat, 0.55)
                for h in range(2):
                    place(buf, hat(), t0 + b * beat + h * beat / 2, 0.5)
            if bar % 4 == 3:
                for i, f in enumerate([180, 150, 120, 95]):
                    place(buf, tom(f), t0 + 3 * beat + i * beat / 4, 0.6)
            place(buf, kick(), t0 + 2.5 * beat, 0.6)
        # bas ostinato
        for e in range(8):
            f = note(root - 12 + bass_pat[e])
            place(buf, bass_note(f, beat / 2 * 0.95), t0 + e * beat / 2, 0.55 if not intro else 0.3)
        # yaylilar
        if bar % 2 == 0:
            place(buf, strings([note(n - 12) for n in chord], 8 * beat, 1600 if bar < 8 else 2600), t0, 0.5)
        # bakir vuruslar
        if bar >= 4 and bar % 2 == 0:
            place(buf, brass([note(n) for n in chord], 1.2), t0, 0.35)
        if bar >= 12 and bar % 4 == 2:
            place(buf, brass([note(n + 12) for n in chord], 0.6), t0 + 2.5 * beat, 0.25)
    # final vurusu
    end = bars * 4 * beat
    place(buf, mix(boom(2.5, 70, 25, 0.8), brass([note(n) for n in [50, 57, 62, 65]], 2.5) * 0.6), end, 0.9)
    buf = reverb(buf, 1.6, 0.18, 6000)
    return buf


def nemesis_theme():
    bpm = 96.0
    beat = 60.0 / bpm
    bars = 16
    total = bars * 4 * beat + 3.0
    buf = np.zeros(n_of(total))
    d = total
    t = tt(d)
    drone = (sine(note(38), d) * 0.5 + sine(note(45), d) * 0.3) * env_lin([(0, 0), (0.05, 1), (0.95, 1), (1, 0)], d)
    buf += fit(drone, len(buf)) * 0.5
    for bar in range(bars):
        t0 = bar * 4 * beat
        # kalp atisi davul
        for b in range(4):
            place(buf, kick(0.5), t0 + b * beat, 0.8)
            place(buf, kick(0.4) * 0.6, t0 + b * beat + 0.18, 0.6)
        if bar >= 4:
            for e in range(8):
                place(buf, hat(), t0 + e * beat / 2, 0.35)
        # gerilim yaylilari (kucuk ikili)
        if bar % 2 == 0:
            base = 50 if (bar // 2) % 2 == 0 else 51
            place(buf, strings([note(base), note(base + 1), note(base + 7)], 8 * beat, 1400 + bar * 80), t0, 0.45)
        # metalik vurus
        if bar % 4 == 3:
            place(buf, bell(note(62), 2.0, 1.41, 5, 0.6) * 0.5, t0 + 2 * beat)
            place(buf, boom(1.2, 80, 30, 0.3) * 0.6, t0 + 3 * beat)
    end = bars * 4 * beat
    place(buf, mix(boom(2.5, 60, 22, 0.8), growl(2.0, 60, 40, 15) * 0.4), end, 0.9)
    return reverb(buf, 1.8, 0.2, 5000)


def to_mp3(x, name):
    os.makedirs(OUT, exist_ok=True)
    wav = TMP + name + '_tmp.wav'
    x = loudnorm(x, -16.0)
    x = fade(x, 0.01, 1.5)
    write_raw = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2')
    import wave
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(Ctx.sr)
        w.writeframes(write_raw.tobytes())
    out = os.path.join(OUT, name + '.mp3')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-ar', '44100', '-ac', '1', '-c:a', 'libmp3lame',
                    '-b:a', '80k', out], check=True)
    os.remove(wav)
    print(name, round(len(x) / Ctx.sr, 1), 's', os.path.getsize(out) // 1024, 'KB')


if __name__ == '__main__':
    to_mp3(boss_theme(), 'boss_theme')
    to_mp3(nemesis_theme(), 'nemesis_theme')
