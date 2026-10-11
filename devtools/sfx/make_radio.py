"""Radio dialogue for zm_vexmira_7door (owner feedback 2026-10-10, item 5).

    cd devtools && python3 sfx/make_radio.py [--only KEY,..] [--no-ini]

Every line is spoken twice (English: MBROLA us1/us2 through espeak-ng, Turkish: espeak-ng tr) and
processed into a military handheld radio: channel notification tone (unique per speaker), squelch
open click, 300-3400 Hz band, compression, light distortion, static bed with crackle, squelch tail.
Output: cstrike/sound/vexmira/radio/cd_<key>_en.wav / _tr.wav, mono 22050 Hz 8-bit, ~2-4 s.
The plugin plays them with "spk" (precache_generic download, no sound precache slot) and prints the
line as a chat subtitle in the player's language. The [radio] / [chatter] sections of
configs/vexmira_maps/zm_vexmira_7door.ini are rewritten from this table (other sections untouched).
"""
import argparse
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy import signal

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
OUT = os.path.join(REPO, 'cstrike', 'sound', 'vexmira', 'radio')
INI = os.path.join(REPO, 'cstrike', 'addons', 'amxmodx', 'configs', 'vexmira_maps', 'zm_vexmira_7door.ini')
SR = 22050

# channel: (EN speaker, TR speaker, EN voice, TR voice, intro tone pattern)
CH = {
    'cmd':   ('Cordon Command', 'Kordon Komuta', 'mb-us2', 'tr+m3', 'cmd'),
    'pilot': ('Angel One', 'Melek Bir', 'mb-us2', 'tr+m1', 'pilot'),
    'alert': ('Emergency Net', 'Acil Durum Agi', 'mb-us1', 'tr+f2', 'alert'),
    'field': ('Field Unit', 'Saha Birimi', 'mb-us2', 'tr+m7', 'field'),
}

# key, channel, English line, Turkish line (spoken, with Turkish letters), Turkish subtitle (ASCII)
LINES = [
    ('ev_freeze_end', 'cmd', 'All survivors, restore power at the substation. Move out!',
     'Tüm sağ kalanlar, trafo merkezinde elektriği verin. Harekete geçin!',
     'Tum sag kalanlar, trafo merkezinde elektrigi verin. Harekete gecin!'),
    ('brk_half', 'field', 'Breaker one is down. Throw the second breaker, now!',
     'Birinci şalter indi. Hemen ikinci şalteri indirin!',
     'Birinci salter indi. Hemen ikinci salteri indirin!'),
    ('power', 'cmd', 'Power is back on the grid. Now lower the lift bridge!',
     'Elektrik geri geldi. Şimdi kaldırma köprüsünü indirin!',
     'Elektrik geri geldi. Simdi kaldirma koprusunu indirin!'),
    ('bridge', 'cmd', 'Bridge is down, harbor road is open. Get to the tower roof!',
     'Köprü indi, liman yolu açık. Kule çatısına çıkın!',
     'Kopru indi, liman yolu acik. Kule catisina cikin!'),
    ('beacon', 'cmd', 'Beacon is lit! Medevac is on the way. Hold that roof!',
     'İşaret yandı! Helikopter yolda. Çatıyı tutun!',
     'Isaret yandi! Helikopter yolda. Catiyi tutun!'),
    ('heli_in', 'pilot', 'Cordon, Angel One. I have your beacon, inbound now!',
     'Kordon, burası Melek Bir. İşaretinizi görüyorum, geliyoruz!',
     'Kordon, burasi Melek Bir. Isaretinizi goruyorum, geliyoruz!'),
    ('heli_clear', 'pilot', 'Clear the pad! Clear the pad! Touching down!',
     'Pisti boşaltın! Pisti boşaltın! İniyoruz!',
     'Pisti bosaltin! Pisti bosaltin! Iniyoruz!'),
    ('heli', 'pilot', 'Angel One on the deck! Get aboard, fifteen seconds!',
     'Melek Bir indi! Binin, on beş saniye!',
     'Melek Bir indi! Binin, on bes saniye!'),
    ('heli_go', 'pilot', 'Lifting off! Hold on tight back there!',
     'Kalkıyoruz! Arkada sıkı tutunun!',
     'Kalkiyoruz! Arkada siki tutunun!'),
    ('lock', 'cmd', 'Negative, no power there. Finish the previous objective.',
     'Olumsuz, orada güç yok. Önce önceki görevi bitirin.',
     'Olumsuz, orada guc yok. Once onceki gorevi bitirin.'),
    ('breach', 'alert', 'Contact! The evac train is breached! Infected in the station!',
     'Temas! Tahliye treni patladı! İstasyonda enfekteliler var!',
     'Temas! Tahliye treni patladi! Istasyonda enfekteliler var!'),
    ('boss', 'alert', 'All units, massive hostile in the plaza. Do not engage alone!',
     'Tüm birimler, meydanda dev bir düşman. Yalnız çatışmayın!',
     'Tum birimler, meydanda dev bir dusman. Yalniz catismayin!'),
    ('ev_boss_dead', 'cmd', 'The big one is down! Outstanding work!',
     'Dev olan düştü! Harika iş!',
     'Dev olan dustu! Harika is!'),
    ('ev_lasthuman', 'cmd', 'You are the last one out there. Survive, at all costs!',
     'Dışarıda tek sen kaldın. Ne pahasına olursa olsun hayatta kal!',
     'Disarida tek sen kaldin. Ne pahasina olursa olsun hayatta kal!'),
    ('ev_minute', 'alert', 'Incoming artillery! Shells inbound, take cover!',
     'Topçu ateşi! Mermiler geliyor, siper alın!',
     'Topcu atesi! Mermiler geliyor, siper alin!'),
    ('blackout', 'alert', 'Grid failure! We lost power, emergency lights only!',
     'Şebeke çöktü! Elektrik gitti, sadece acil ışıklar!',
     'Sebeke coktu! Elektrik gitti, sadece acil isiklar!'),
    ('barricade', 'alert', 'The tower barricade is down! They are inside!',
     'Kule barikatı yıkıldı! İçerideler!',
     'Kule barikati yikildi! Icerideler!'),
    ('scare', 'field', 'What was that? Something is moving out there...',
     'O da neydi? Dışarıda bir şey hareket ediyor...',
     'O da neydi? Disarida bir sey hareket ediyor...'),
    ('supply', 'field', 'Supplies found. Grab the ammo and keep moving.',
     'Erzak bulundu. Mermileri alın ve ilerleyin.',
     'Erzak bulundu. Mermileri alin ve ilerleyin.'),
    ('ev_win_humans', 'cmd', 'Evac complete. Cordon Seven, you made it. Command out.',
     'Tahliye tamam. Kordon Yedi, başardınız. Komuta tamam.',
     'Tahliye tamam. Kordon Yedi, basardiniz. Komuta tamam.'),
    ('ev_win_zombies', 'cmd', 'We have lost Cordon Seven. All units, fall back...',
     'Kordon Yedi\'yi kaybettik. Tüm birimler, geri çekilin...',
     'Kordon Yedi\'yi kaybettik. Tum birimler, geri cekilin...'),
]
LOW = ('scare', 'supply')          # low priority (written with a negative length: skipped when the net is busy)
CHATTER = [
    ('ch_gate', 'field', 'Gate Seven to any unit. Does anyone copy? Over.',
     'Kapı Yedi\'den tüm birimlere. Beni duyan var mı? Tamam.',
     'Kapi Yedi\'den tum birimlere. Beni duyan var mi? Tamam.'),
    ('ch_patrol', 'field', 'Patrol Two, we lost the east checkpoint. They are everywhere!',
     'Devriye İki, doğu kontrol noktasını kaybettik. Her yerdeler!',
     'Devriye Iki, dogu kontrol noktasini kaybettik. Her yerdeler!'),
    ('ch_wall', 'cmd', 'Quarantine is in effect. Nobody crosses the wall.',
     'Karantina yürürlükte. Kimse duvarı geçemez.',
     'Karantina yururlukte. Kimse duvari gecemez.'),
    ('ch_medic', 'alert', 'Medical team, we need stretchers at the field hospital!',
     'Sağlık ekibi, sahra hastanesine sedye lazım!',
     'Saglik ekibi, sahra hastanesine sedye lazim!'),
]


# ---------------------------------------------------------------------------------------------- dsp
def _sos(kind, f, order=2):
    nyq = SR / 2.0
    if kind == 'band':
        return signal.butter(order, [f[0] / nyq, f[1] / nyq], btype='band', output='sos')
    return signal.butter(order, f / nyq, btype=kind, output='sos')


def bp(x, lo, hi, order=4):
    return signal.sosfilt(_sos('band', (lo, hi), order), x)


def hp(x, f, order=2):
    return signal.sosfilt(_sos('high', f, order), x)


def tone(f, d, amp=0.5, square=0.0):
    t = np.arange(int(SR * d)) / SR
    s = np.sin(2 * np.pi * f * t)
    if square:
        s = (1 - square) * s + square * np.sign(s)
    e = np.minimum(1, np.minimum(t / 0.004, (d - t) / 0.006))
    return s * e * amp


def gap(d):
    return np.zeros(int(SR * d))


def squelch(rng, d=0.07, amp=0.55):
    n = int(SR * d)
    x = hp(rng.standard_normal(n), 900) * np.exp(-np.arange(n) / (SR * d / 3.0))
    x[:12] += np.linspace(1.0, 0, 12)               # contact click
    return x * amp


def intro(kind, rng):
    if kind == 'cmd':        # two-tone up chirp (command net)
        return np.concatenate([squelch(rng), tone(880, 0.07), gap(0.015), tone(1320, 0.09), gap(0.05)])
    if kind == 'pilot':      # single high chirp with a warble (aircraft)
        t = np.arange(int(SR * 0.14)) / SR
        w = np.sin(2 * np.pi * (1500 + 120 * np.sin(2 * np.pi * 28 * t)) * t) * np.minimum(1, np.minimum(t / 0.004, (0.14 - t) / 0.01)) * 0.5
        return np.concatenate([squelch(rng), w, gap(0.05)])
    if kind == 'alert':      # urgent triple beep (emergency net)
        b = tone(1050, 0.055, 0.55, square=0.4)
        return np.concatenate([squelch(rng), b, gap(0.035), b, gap(0.035), b, gap(0.06)])
    return np.concatenate([squelch(rng, 0.09, 0.7), gap(0.04)])        # field: plain squelch break


def outro(kind, rng):
    tail = squelch(rng, 0.16, 0.45)
    if kind == 'cmd':
        return np.concatenate([gap(0.04), tone(1000, 0.06, 0.4), tail])   # roger beep
    return np.concatenate([gap(0.03), tail])


def speak(text, voice, speed):
    with tempfile.TemporaryDirectory() as td:
        p = os.path.join(td, 'v.wav')
        subprocess.run(['espeak-ng', '-v', voice, '-s', str(speed), '-p', '42', '-w', p, text], check=True,
                       capture_output=True)
        with wave.open(p) as w:
            sr, n = w.getframerate(), w.getnframes()
            x = np.frombuffer(w.readframes(n), '<i2').astype(float) / 32768.0
    if sr != SR:
        x = signal.resample_poly(x, SR, sr)
    idx = np.where(np.abs(x) > 0.01)[0]
    if len(idx):
        x = x[max(0, idx[0] - 200): idx[-1] + 400]
    return x


def radio_voice(x, rng):
    x = x / (np.abs(x).max() + 1e-9)
    x = hp(x, 220, 2)
    # compression: envelope follower, fast attack / slow release, ~4:1 above -24 dB
    env = np.abs(x)
    a = signal.lfilter([0.08], [1, -0.92], env)
    r = signal.lfilter([0.002], [1, -0.998], env)
    e = np.maximum(a, r) + 1e-4
    db = 20 * np.log10(e)
    gain_db = np.where(db > -24, (-24 - db) * 0.75, 0)
    x = x * 10 ** (gain_db / 20)
    x = x / (np.abs(x).max() + 1e-9)
    x = np.tanh(x * 2.6) / np.tanh(2.6)            # light overdrive (transistor radio)
    x = bp(x, 300, 3400, 4)
    x = x + 0.12 * bp(x * np.abs(x), 1800, 3400, 2)  # a little intermod grit in the presence band
    return x / (np.abs(x).max() + 1e-9)


def static_bed(n, rng, level=0.05):
    s = bp(rng.standard_normal(n), 400, 3800, 2)
    s /= np.abs(s).max() + 1e-9
    flutter = 0.7 + 0.3 * np.sin(2 * np.pi * rng.uniform(5, 9) * np.arange(n) / SR)
    s = s * flutter * level
    k = rng.integers(6, 14)                            # crackle pops
    for p in rng.integers(0, n, k):
        L = int(SR * rng.uniform(0.002, 0.008))
        s[p:p + L] += rng.standard_normal(min(L, n - p)) * rng.uniform(0.15, 0.4)
    return s


def build_line(text, voice, kind, seed, speed):
    rng = np.random.default_rng(seed)
    v = radio_voice(speak(text, voice, speed), rng)
    i, o = intro(kind, rng), outro(kind, rng)
    x = np.concatenate([i, v * 0.92, o])
    x = x + static_bed(len(x), rng)
    # tones / squelch are band limited too (same radio)
    x = bp(x, 280, 3700, 2)
    x = x / (np.abs(x).max() + 1e-9) * 0.97
    f = int(SR * 0.004)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    return x


def write_u8(path, x):
    rng = np.random.default_rng(1)
    y = np.clip(np.round(x * 127.0 + 128.0 + rng.uniform(-0.5, 0.5, len(x))), 0, 255).astype(np.uint8)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(1)
        w.setframerate(SR)
        w.writeframes(y.tobytes())
    return len(y) / SR


def make(only=None):
    rows = []
    for group, table in (('radio', LINES), ('chatter', CHATTER)):
        for n, (key, ch, en, tr_say, tr_sub) in enumerate(table):
            spk_en, spk_tr, v_en, v_tr, kind = CH[ch]
            fe, ft = 'cd_%s_en.wav' % key, 'cd_%s_tr.wav' % key
            if not only or key in only:
                seed = 9000 + 37 * n + (500 if group == 'chatter' else 0)
                de = write_u8(os.path.join(OUT, fe), build_line(en, v_en, kind, seed, 182))
                dt = write_u8(os.path.join(OUT, ft), build_line(tr_say, v_tr, kind, seed + 1, 205))
            else:
                de = dt = 0.0
                for f in (fe, ft):
                    with wave.open(os.path.join(OUT, f)) as w:
                        d = w.getnframes() / w.getframerate()
                    de, dt = (d, dt) if f == fe else (de, d)
            dur = max(de, dt)
            if key in LOW:
                dur = -dur
            rows.append((group, key, dur, fe, ft, '%s: %s' % (spk_en, en), '%s: %s' % (spk_tr, tr_sub)))
            print('  %-8s %-15s en %.2f s  tr %.2f s  %s' % (group, key, de, dt, ch))
    return rows


def write_ini(rows):
    with open(INI, encoding='latin-1') as fh:
        lines = fh.read().split('\n')
    out, skip = [], False
    for ln in lines:
        s = ln.strip().lower()
        if s.startswith('['):
            skip = s.split(';')[0].strip() in ('[radio]', '[chatter]')
        if not skip:
            out.append(ln)
    while out and not out[-1].strip():
        out.pop()
    for group in ('radio', 'chatter'):
        out.append('')
        if group == 'radio':
            out.append('[radio]              ; <key> = <sec> <EN wav> <TR wav> <EN subtitle> | <TR subtitle>  (sound/vexmira/radio/; -sec = low priority)')
            out.append('                     ; key = [messages] key, ev_<event>, lock, or a vexcmd_radio_<key> relay')
        else:
            out.append('[chatter]            ; random radio chatter while the round is live (vex_map_chatter = average gap in s, 0 = off)')
        for g, key, dur, fe, ft, se, st in rows:
            if g == group:
                out.append('%s = %.1f %s %s %s | %s' % (key, dur, fe, ft, se, st))
    with open(INI, 'w', encoding='latin-1', newline='\n') as fh:
        fh.write('\n'.join(out) + '\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', default='')
    ap.add_argument('--no-ini', action='store_true')
    a = ap.parse_args()
    rows = make(set(a.only.split(',')) if a.only else None)
    if not a.no_ini:
        write_ini(rows)
        print('ini:', INI)
    tot = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
    print('files: %d, %.0f KB' % (len(os.listdir(OUT)), tot / 1024))


if __name__ == '__main__':
    main()
