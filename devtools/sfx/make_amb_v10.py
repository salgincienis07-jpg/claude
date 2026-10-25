"""Vexmira v10 round ambience: ONE seamless loop for every round / event / boss (instead of 8 low-quality loops).

Track: "Gathering Darkness" - Kevin MacLeod (incompetech.com), Creative Commons Attribution 4.0
       https://creativecommons.org/licenses/by/4.0/
Output: cstrike/sound/vexmira/v10/ambience.wav
  - WAV (not mp3): plays even when a player's MP3 volume is 0; players can turn it off in the settings
  - 16-bit mono 22050 Hz (clean, no 8-bit hiss), 42 s from the steadiest part of the track
  - the last 3 s cross-fade into the first ones and a cue chunk marks the loop: GoldSrc repeats it without a gap
  - loudness about -21 LUFS so it sits under gunfire and voices (~1.8 MB, one download instead of eight)

    python3 devtools/sfx/make_amb_v10.py
"""
import os
import struct
import subprocess
import numpy as np

SRC = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/snd534/music/Gathering_Darkness.mp3'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cstrike', 'sound', 'vexmira', 'v10', 'ambience.wav')
SR = 22050
L = 42.0
CF = 3.0


def pcm(path):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(SR), '-f', 's16le', '-'], capture_output=True, check=True).stdout
    return np.frombuffer(raw, '<i2').astype(np.float64) / 32768.0


def steadiest(x):
    e = np.sqrt(np.convolve(x ** 2, np.ones(SR) / SR, 'valid'))[::SR]
    n = int(L)
    best, bs = 12, -1e9
    for s in range(12, len(e) - n - 6):
        w = e[s:s + n]
        sc = np.mean(w) - 1.5 * np.std(w) - 2.0 * max(0.0, np.max(w) - 2.0 * np.mean(w))
        if sc > bs:
            best, bs = s, sc
    return best


def write_wav(path, x):
    q = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2').tobytes()
    fmt = struct.pack('<HHIIHH', 1, 1, SR, SR * 2, 2, 16)
    cue = struct.pack('<I', 1) + struct.pack('<II4sIII', 1, 0, b'data', 0, 0, 0)
    body = b'WAVE' + b'fmt ' + struct.pack('<I', len(fmt)) + fmt + b'cue ' + struct.pack('<I', len(cue)) + cue
    body += b'data' + struct.pack('<I', len(q)) + q
    with open(path, 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', len(body)) + body)


def main():
    x = pcm(SRC)
    st = steadiest(x) * SR
    n, cf = int(L * SR), int(CF * SR)
    seg = x[st:st + n].copy()
    pre = x[st - cf:st]
    t = np.linspace(0, 1, cf)
    seg[-cf:] = seg[-cf:] * np.cos(t * np.pi / 2) + pre * np.sin(t * np.pi / 2)  # the end flows into the start
    rms = np.sqrt(np.mean(seg ** 2))
    seg *= 10 ** ((-21.0 - 20 * np.log10(rms + 1e-9)) / 20)
    pk = np.max(np.abs(seg))
    if pk > 0.89:
        seg *= 0.89 / pk
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    write_wav(OUT, seg)
    print('ambience.wav from %.0f s, %d KB' % (st / SR, os.path.getsize(OUT) // 1024))


if __name__ == '__main__':
    main()
