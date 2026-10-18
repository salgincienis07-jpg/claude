"""Vexmira 5.3.5 sound set: royalty-free music + CC0 effects, converted for GoldSrc.

Sources (downloaded once into the scratchpad, see CREDITS in the install guide):
  music  Kevin MacLeod (incompetech.com), CC-BY 4.0
  sfx    OpenGameArt.org, CC0 (rubberduck, kenney, bart, artisticdude, spring-spring, ...)

Output: cstrike/sound/vexmira/s534/
  amb_<bed>.wav  8 round-ambience music loops: mono 8-bit 22050 Hz, 24 s, cue chunk -> the engine loops them
  <name>.wav     effects: mono 16-bit 22050 Hz, silence trimmed, faded, loudness matched, <= 4 s

    python3 devtools/sfx534/build534.py
"""
import os
import struct
import subprocess
import tempfile

import numpy as np

SRC = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/snd534'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'cstrike', 'sound', 'vexmira', 's534')
SR = 22050

# bed: (track, preferred start second or None = loudest 24 s window)
MUSIC = {
    'calm': ('Dark_Fog.mp3', None),
    'tension': ('Gathering_Darkness.mp3', None),
    'hunt': ('Unseen_Horrors.mp3', None),
    'hope': ('Heroic_Age.mp3', None),
    'storm': ('Volatile_Reaction.mp3', None),
    'frost': ('Ice_Flow.mp3', None),
    'boss': ('Five_Armies.mp3', None),
    'chaos': ('Clash_Defiant.mp3', None),
}

D = 'dl/'
# name: (source file, start s, max length s, gain dB)
SFX = {
    'round_start': (D + '100-cc0-sfx/x/gong_01.ogg', 0, 3.5, 0),
    'mode_start': (D + 'cc0-deep-monster-roar/monster_roar.wav', 0, 3.5, 0),
    'event_start': (D + 'wind-whoosh-loop/wind%20woosh%20loop.ogg', 0, 2.5, 0),
    'boss_warn': (D + 'big-scary-troll-sounds/troll-roars_0.ogg', 0, 3.5, 0),
    'final_round': (D + 'sirens-and-alarm-noise/siren_0.mp3', 0, 4.0, -2),
    'last_human': (D + 'heartbeat-sounds/heartbeat_fast_0.wav', 0, 3.5, 0),
    'human_win': (D + 'hyper-ultra-fanfare/sboe.wav', 0, 4.0, 0),
    'zombie_win': (D + 'zombie-moans/darsycho__zombie-moans_0.ogg', 0, 4.0, 0),
    'bell': (D + 'pleasing-bell-sound-effect/pleasing-bell.wav', 0, 3.0, 0),
    'tick': (D + 'interface-beeps/x/Beeps/beep-03.wav', 0, 0.5, -3),
    'kill': (D + '10-impactshield-blocks/x/impact.1.ogg', 0, 1.5, 0),
    'reward': ('lvl/Rise05.wav', 0, 2.5, 0),
    'mvp': ('lvl/Rise07.wav', 0, 3.0, 0),
    'coin': (D + '80-cc0-rpg-sfx/x/item_coins_01.ogg', 0, 1.5, 0),
    'deny': (D + '50-cc0-sci-fi-sfx/x/retro_beep_06.ogg', 0, 0.8, -3),
    'click': (D + '51-ui-sound-effects-buttons-switches-and-clicks/x/click1.wav', 0, 0.4, -4),
    'vote': (D + '100-cc0-sfx/x/bell_01.ogg', 0, 2.0, -2),
    'thunder': (D + '100-cc0-sfx-2/x/sfx100v2_thunder_01.ogg', 0, 4.0, 0),
    'fire': (D + '80-cc0-rpg-sfx/x/spell_fire_01.ogg', 0, 2.5, 0),
    'ice': (D + 'ice-spells/x/coldsnap.wav', 0, 2.5, 0),
    'zap': (D + 'electricity-game-sound-pack/charge.wav', 0, 1.5, -2),
    'dark': (D + '50-cc0-sci-fi-sfx/x/loop_ambient_weird.ogg', 0, 3.0, 0),
    'whoosh': (D + 'swishes-sound-pack/x/swishes/swish-3.wav', 0, 1.0, 0),
    'speed': (D + 'air-whoosh/whoosh2_0.wav', 0, 1.5, 0),
    'roar': (D + '80-cc0-rpg-sfx/x/creature_roar_01.ogg', 0, 2.5, 0),
    'roar2': (D + '80-cc0-creature-sfx/x/roar_02.ogg', 0, 2.5, 0),
    'impact': (D + '100-cc0-sfx/x/slam_02.ogg', 0, 1.5, 0),
    'chain': (D + '80-cc0-rpg-sfx/x/chain_01.ogg', 0, 1.5, 0),
    'acid': (D + '80-cc0-creature-sfx/x/spit_01.ogg', 0, 1.5, 0),
    'heal': (D + 'cure-magic/x/Cure1.wav', 0, 2.0, 0),
    'shield': (D + '10-impactshield-blocks/x/impact.5.ogg', 0, 1.5, 0),
    'power': ('lvl/Rise04.wav', 0, 2.0, 0),
    'beep': (D + '50-cc0-sci-fi-sfx/x/beep_01.ogg', 0, 0.8, -3),
    'boom': (D + '50-cc0-sci-fi-sfx/x/explosion_01.ogg', 0, 2.5, 0),
}


def decode(path, start=0.0, length=None):
    cmd = ['ffmpeg', '-v', 'error', '-ss', str(start), '-i', path]
    if length:
        cmd += ['-t', str(length)]
    cmd += ['-ac', '1', '-ar', str(SR), '-f', 'f32le', '-']
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def rms_db(x):
    return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-9)


def wav(path, x, bits=16, loop=False):
    if bits == 8:
        rng = np.random.default_rng(534)
        q = np.clip(np.round(x * 127 + 128 + (rng.random(len(x)) - rng.random(len(x)))), 0, 255).astype(np.uint8).tobytes()
    else:
        q = np.clip(np.round(x * 32767), -32768, 32767).astype('<i2').tobytes()
    fmt = struct.pack('<HHIIHH', 1, 1, SR, SR * bits // 8, bits // 8, bits)
    body = b'WAVE' + b'fmt ' + struct.pack('<I', len(fmt)) + fmt
    if loop:   # one cue point at 0: GoldSrc loops the whole file
        cue = struct.pack('<I', 1) + struct.pack('<II4sIII', 1, 0, b'data', 0, 0, 0)
        body += b'cue ' + struct.pack('<I', len(cue)) + cue
    body += b'data' + struct.pack('<I', len(q)) + q + (b'\0' if len(q) % 2 else b'')
    with open(path, 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', len(body)) + body)


def music(bed, track, start):
    x = decode(os.path.join(SRC, 'music', track))
    L, cf = int(24.0 * SR), int(2.0 * SR)
    if start is None:   # loudest steady 24 s window after the intro
        win = int(SR)
        e = np.sqrt(np.convolve(x ** 2, np.ones(win) / win, 'valid'))
        cs = np.concatenate([[0], np.cumsum(e)])
        lo, hi = int(8 * SR), len(e) - L - cf
        best = max(range(lo, max(lo + 1, hi), SR // 2), key=lambda s: cs[s + L] - cs[s])
        s = best
    else:
        s = int(start * SR)
    seg = x[s:s + L].copy()
    pre = x[s - cf:s]
    t = np.linspace(0, 1, cf)
    seg[-cf:] = seg[-cf:] * np.cos(t * np.pi / 2) + pre * np.sin(t * np.pi / 2)   # end flows into the start
    seg *= 10 ** ((-19.0 - rms_db(seg)) / 20)
    seg = np.clip(seg, -0.97, 0.97)
    wav(os.path.join(OUT, 'amb_%s.wav' % bed), seg, bits=8, loop=True)
    return s / SR


def sfx(name, src, start, maxlen, gain):
    p = os.path.join(SRC, src)
    x = decode(p, start, maxlen + 1.0)
    thr = np.max(np.abs(x)) * 0.02
    nz = np.nonzero(np.abs(x) > thr)[0]
    if len(nz):
        x = x[max(0, nz[0] - int(0.005 * SR)):nz[-1] + int(0.05 * SR)]
    x = x[:int(maxlen * SR)]
    f = min(len(x) // 4, int(0.25 * SR))
    if f > 0:
        x[-f:] *= np.linspace(1, 0, f) ** 2
    x[:int(0.003 * SR)] *= np.linspace(0, 1, int(0.003 * SR))
    x *= 10 ** ((-14.0 + gain - rms_db(x)) / 20)
    pk = np.max(np.abs(x))
    if pk > 0.95:
        x *= 0.95 / pk
    wav(os.path.join(OUT, name + '.wav'), x)


def main():
    os.makedirs(OUT, exist_ok=True)
    lvl = os.path.join(SRC, 'lvl')       # .aif level-up pack -> wav once
    os.makedirs(lvl, exist_ok=True)
    for n in ('Rise04', 'Rise05', 'Rise07'):
        a = os.path.join(SRC, D, 'level-up-power-up-coin-get-13-sounds/x/%s.aif' % n)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', a, os.path.join(lvl, n + '.wav')], check=True)
    for bed, (tr, st) in MUSIC.items():
        s = music(bed, tr, st)
        print('  amb_%-8s %-24s from %5.1f s  %d KB' % (bed, tr, s, os.path.getsize(os.path.join(OUT, 'amb_%s.wav' % bed)) // 1024))
    for n, a in SFX.items():
        sfx(n, *a)
    tot = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
    print('%d files, %d KB' % (len(os.listdir(OUT)), tot // 1024))


if __name__ == '__main__':
    main()
