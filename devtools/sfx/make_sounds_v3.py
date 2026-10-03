# Vexmira Zombie v3.0 - karakter sesleri uretici (204 WAV, tamamen prosedurel / ozgun)
#
#   python3 make_sounds_v3.py                 -> hepsini uret (4 cekirdek)
#   python3 make_sounds_v3.py boss/brute_intro class/walker_pain ...   -> sadece secilenler
#
# Cikti: cstrike/sound/vexmira/{boss,special,class,hook,ui}/*.wav
#   mono 16 bit PCM, 22050 Hz (boss adimlari 11025 Hz), DONGUSUZ (cue / smpl chunk YOK)
# Teknik: kaynak-filtre vokal sentez (Rosenberg glottal darbe + jitter/shimmer + alt harmonik
#   + zamanla degisen kaskad/paralel formantlar), fisilti (gurultu kaynakli formant),
#   modal (fiziksel) darbe sentezi (metal / kemik / tas / buz), granuler doku, ates / ruzgar /
#   gok gurultusu / elektrik / bocek modelleri, prosedurel IR'li konvolusyon reverb,
#   doygunluk, ileri bakisli sinirlayici ve K agirlikli yukluk normalizasyonu (v2 ile tutarli).
# Her ses kendi adindan turetilen sabit tohumla uretilir (tekrar uretilebilir).
import os, sys, zlib, subprocess, tempfile, wave as _wave
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sfx_lib as L
from sfx_lib import *

OUT = '/home/user/claude/cstrike/sound/vexmira'
HI, LO = 22050, 11025

# kategori -> (yukluk hedefi dB [K-pencere], azami sure sn, asgari sure sn)
CAT = {
    'intro': (-15.0, 3.3, 2.0), 'idle': (-17.0, 2.2, 1.0), 'pain': (-16.0, 0.78, 0.3), 'death': (-16.0, 2.4, 1.0),
    'step': (-18.0, 0.48, 0.2), 'attack': (-16.0, 0.88, 0.4), 'ability': (-16.0, 1.95, 0.6), 'ui': (-18.0, 0.78, 0.1),
    'hook': (-16.0, 1.45, 0.3), 'extra': (-15.5, 1.9, 0.4),
}
R = {}  # yol -> (fonksiyon, ornekleme, yukluk, azami, asgari)


# boyut butcesi (204 dosya <= 9 MB): sure tavanlari ses turune gore (sn)
CAP = {
    'boss_intro': 2.5, 'boss_idle': 1.35, 'boss_pain': 0.6, 'boss_death': 1.85, 'boss_step': 0.45,
    'boss_attack': 0.65, 'boss_phase': 1.4, 'boss_kill': 1.15,
    'special_intro': 2.4, 'special_idle': 1.3, 'special_pain': 0.55, 'special_death': 1.5, 'special_attack': 0.62,
    'class_pain': 0.55, 'class_die': 1.12, 'class_idle': 1.07, 'class_ability': 1.08, 'class_extra': 0.9,
    'hook': 0.85, 'hook_pull': 1.1, 'hook_chain': 0.9,
    'ui_vote_start': 0.72, 'ui_vote_end': 0.7, 'ui_boss_bar': 0.62, 'ui_class_select': 0.5, 'ui_menu_select': 0.12,
}
# alcak perdeli girtlak acilari 11025 Hz (icerik < 5 kHz; dosya yarisi)
LOW_PAIN = {'brute', 'overlord', 'inferno', 'frostlord', 'void', 'nemesis', 'walker', 'tank', 'bomber', 'hulk',
            'butcher', 'charger', 'magma', 'burrower', 'bulwark', 'nightmare'}


def cap_of(rel):
    folder, name = rel.split('/')
    if folder == 'hook':
        return CAP.get('hook_' + name, CAP['hook'])
    if folder == 'ui':
        return CAP['ui_' + name]
    kind = name.split('_')[-1].rstrip('12')
    key = folder + '_' + kind
    if folder == 'class' and key not in CAP:
        key = 'class_extra'
    return CAP[key]


def S(rel, cat, sr=HI, loud=None, maxlen=None):
    lo_, mx, mn = CAT[cat]
    folder, name = rel.split('/')
    if name.split('_')[-1].startswith('pain') and name.split('_')[0] in LOW_PAIN:
        sr = LO

    def deco(f):
        R[rel] = (f, sr, lo_ if loud is None else loud, maxlen or cap_of(rel), mn)
        return f
    return deco


_DRY = [0.0]
_CAP = [9.0]


def space(x, kind='room', mixv=None):
    """besteyi bitiren reverb (L.space) sarmalayicisi: kuru icerik dosya tavanini (boyut butcesi)
    asarsa once WSOLA ile perdeyi bozmadan en fazla %25 sikistirir, sonra reverb uygular."""
    x = np.asarray(x, float)
    xa = np.abs(x)
    nz = np.where(xa > xa.max() * 0.01)[0]
    dry = (nz[-1] + 1) / Ctx.sr if len(nz) else 0.0
    target = _CAP[0] * 0.9
    if dry > target:
        r = min(1.3, dry / target)
        x = wsola(x[:nz[-1] + 1], r)
        dry = dry / r
    _DRY[0] = max(_DRY[0], dry)
    return L.space(x, kind, mixv)


def rr():
    return L.rng


def U(a, b):
    return float(L.rng.uniform(a, b))


def norm(x, p=1.0):
    return x / (np.max(np.abs(x)) + 1e-9) * p


def at(x, d):
    return fit(np.asarray(x, float), n_of(d))


# ======================================================================
# ortak vokal yapitaslari
# ======================================================================

def beast(d, f0, seq, fs=0.62, sub=0.4, rough=0.45, rr_=26, jit=0.05, shim=0.18, breath=0.45, drive=2.0, amp=None,
          octave=0.45, bright=0.12, fry=0.05, noisy=0.22, oq=0.55, vib=(0, 0), parallel=False):
    """canavar girtlagi: ana ses + oktav alti alt ses (periyot ikilenmesi) + gurultu katmani + doygunluk"""
    f0c = curve(f0, d)
    rr_ = curve(rr_, d)
    y = voice(d, f0c, seq, fs, jit, shim, sub, fry, oq, breath, rough, rr_, vib=vib, amp=amp, bright=bright,
              parallel=parallel)
    if octave:
        y = y + octave * voice(d, f0c * 0.5, seq, fs * 0.86, jit * 1.4, shim, sub * 0.6, min(0.5, fry * 2 + 0.05), 0.5,
                               breath * 0.4, rough, rr_ * 0.6, amp=amp)
    if noisy:
        nz = unvoiced(d, seq, fs * 1.15, amp=amp, bwk=2.0)
        if rough:
            nz = nz * (1 - 0.6 * (0.5 + 0.5 * np.sin(2 * np.pi * np.cumsum(rr_) / Ctx.sr)))
        y = y + noisy * nz
    y = norm(y)
    return norm(dist(y * drive, 1.2)) if drive else y


def shriek(d, f0, seq=('e', 'i'), fs=1.3, breath=0.5, vib=(7, 0.5), drive=1.6, jit=0.03, rough=0.0, rr_=40, amp=None,
           layers=2, sub=0.0):
    """tiz ciglik: paralel formant (parlak), vibrato, iki hafif kaymis katman"""
    if isinstance(seq, tuple):
        seq = [(i / max(1, len(seq) - 1), v) for i, v in enumerate(seq)]
    f0c = curve(f0, d)
    y = np.zeros(n_of(d))
    for k in range(layers):
        y += voice(d, f0c * (1 + 0.012 * k), seq, fs * (1 + 0.03 * k), jit, 0.1, sub, 0, 0.45, breath, rough, rr_,
                   vib=(vib[0] * (1 + 0.1 * k), vib[1]), amp=amp, parallel=True)
    y = norm(y)
    return norm(dist(y * drive, 1.3)) if drive else y


def hiss(d, fs=1.0, amp=None, seq='ee', lo=2500):
    a = unvoiced(d, seq, fs, amp=amp, bwk=1.4, color=0.2)
    s = sibilant(d, lo, 9500, amp=amp)
    return norm(hp(a, 1200) * 0.6 + s * 0.7)


def breath_in(d, fs=0.8, seq='o', amp=None):
    return unvoiced(d, seq, fs, amp=amp or [(0, 0), (0.7, 1), (1, 0)], bwk=2.2, color=0.7)


def laugh(count, f0, fs, gap=0.06, L0=0.15, fall=0.93, sub=0.3, rough=0.3, breath=0.4, drive=1.4, seq='A',
          beastly=True):
    """'ha ha ha': her hece = aspirasyon 'h' + sesli 'a' (perde her hecede duser)"""
    parts, t, f = [], 0.0, f0
    for i in range(count):
        Lh = L0 * U(0.85, 1.15)
        h = unvoiced(0.05, seq, fs * 1.1, amp=[(0, 0), (0.6, 1), (1, 0.5)], bwk=2.0) * 0.35
        if beastly:
            v = beast(Lh, [(0, f * 1.08), (1, f * 0.92)], [(0, seq), (1, 'uh')], fs, sub, rough, 28, 0.04, 0.15, breath,
                      drive, [(0, 0), (0.12, 1), (0.55, 0.8), (1, 0)], 0.35, 0.1)
        else:
            v = voice(Lh, [(0, f * 1.08), (1, f * 0.92)], [(0, seq), (1, 'uh')], fs, 0.03, 0.1, sub, 0, 0.55, breath,
                      rough, amp=[(0, 0), (0.12, 1), (0.55, 0.8), (1, 0)], parallel=fs > 1.0)
        parts += [(h, t, 1.0), (v, t + 0.035, 1.0 - 0.04 * i)]
        t += Lh + gap * U(0.8, 1.3)
        f *= fall
    return mix(*parts)


def whispers(d, count, fs=0.9, dur=(0.14, 0.3), gap=(0.02, 0.1), seqs=('a', 'o', 'i', 'e', 'u', 'uh'), sib=0.4):
    """anlamsiz fisilti cumleleri: sesli heceler + 's'/'sh' surtunmeleri"""
    parts = []
    for (t, Ls) in syllables(d, count, dur, gap):
        v1, v2 = rr().choice(seqs), rr().choice(seqs)
        w = unvoiced(Ls, [(0, v1), (1, v2)], fs * U(0.92, 1.08), amp=[(0, 0), (0.2, 1), (0.7, 0.7), (1, 0)])
        parts.append((w, t, U(0.6, 1.0)))
        if rr().random() < sib:
            s = sibilant(U(0.05, 0.12), U(2500, 4000), 9000, amp=[(0, 0), (0.3, 1), (1, 0)])
            parts.append((s, max(0, t - 0.04), U(0.2, 0.45)))
    return at(mix(*parts), d) if parts else np.zeros(n_of(d))


def stomp(size=1.0, surface='stone', d=0.45):
    """agir ayak sesi: alt frekans govde + yuzey dokusu"""
    f = 58 / size ** 0.4
    body = sine(sweep(f * 2.4, f * 0.9, d), d) * env_exp(d, 0.07 * size)
    hit = lp(rr().standard_normal(n_of(0.05)), 1800) * env_exp(0.05, 0.01)
    parts = [(body, 0, 1.0), (hit, 0, 0.6)]
    if surface == 'stone':
        parts.append((debris(d, 90, 400, 4500, 0.08, 0.5), 0.005))
    elif surface == 'ice':
        parts.append((crackle(d * 0.6, 120, 2500, 9000) * 0.5, 0.0))
    elif surface == 'flesh':
        parts.append((squelch(0.2, 900, 300, 0.4) * 0.35, 0.0))
    elif surface == 'chitin':
        parts = [(body * 0.4, 0, 1.0)] + [(knock(U(1800, 3200), 0.08, 0.008, False) * 0.6, i * U(0.04, 0.07)) for i in range(4)]
    return mix(*parts)


def body_fall(size=1.0, d=0.9, armor=False, wet=0.0):
    parts = [(thump(0.5, 60 / size ** 0.3, 0.09 * size), 0, 1.0), (thump(0.4, 75, 0.06), 0.13 * size, 0.6),
             (debris(d, 60, 300, 3000, 0.15, 0.4), 0.0)]
    if armor:
        parts += [(metal_hit(U(300, 500), 0.6, 0.25, 'plate') * 0.35, 0.02), (chain_rattle(0.4, 30) * 0.2, 0.05)]
    if wet:
        parts.append((squelch(0.35, 900, 250, 0.6) * wet, 0.0))
    return mix(*parts)


def swish(d=0.35, c0=600, c1=3500, peak=0.45):
    return whoosh(d, c0, c1, peak)


def flesh_hit(d=0.35):
    return mix(thump(d, 80, 0.05), (squelch(0.25, 1200, 350, 0.5) * 0.6, 0.0),
               (lp(rr().standard_normal(n_of(0.04)), 2500) * env_exp(0.04, 0.008) * 0.6, 0))


def heartbeat(d, bpm=60, f=50):
    parts = []
    t = 0.0
    while t < d - 0.3:
        parts += [(thump(0.25, f, 0.05), t, 1.0), (thump(0.25, f * 0.92, 0.05), t + 0.16, 0.7)]
        t += 60.0 / bpm
    return mix(*parts) if parts else np.zeros(n_of(d))


def reverse_swell(d=1.0, lo=300, hi=6000):
    x = bp(noise(d, 'pink'), lo, hi) * env_exp(d, d / 4)
    return reverse(L.space(x, 'hall', 0.5)[:n_of(d)])


# ======================================================================
# BOSSLAR
# ======================================================================
# ---------- 0 BRUTE: derin hirilti / tas / zincir ----------

def bru_v(d, f0, seq, amp=None, drive=2.4, **k):
    return beast(d, f0, seq, fs=0.56, sub=0.5, rough=0.55, rr_=24, jit=0.06, breath=0.5, drive=drive, amp=amp,
                 octave=0.55, bright=0.1, **k)


@S('boss/brute_intro', 'intro')
def _():
    pound = lambda: mix(thump(0.35, 48, 0.08), (squelch(0.15, 900, 300, 0.2) * 0.3, 0),
                        (lp(rr().standard_normal(n_of(0.06)), 1200) * env_exp(0.06, 0.012) * 0.7, 0))
    chest = mix((pound(), 0), (pound(), 0.2, 0.9), (pound(), 0.4, 1.0))
    roar = bru_v(2.15, [(0, 58), (0.12, 92), (0.55, 84), (1, 46)], [(0, 'uh'), (0.14, 'A'), (0.7, 'a'), (1, 'o')],
                 amp=[(0, 0), (0.06, 1), (0.6, 0.9), (1, 0)])
    chains = chain_rattle(2.0, 22, 1500, 4200, amp=[(0, 0), (0.08, 1), (0.6, 0.45), (1, 0)]) * 0.3
    rock = mix(rumble(2.2, 110) * 0.55, (debris(1.6, 70, 300, 3000, 0.6) * 0.45, 0.25))
    return space(mix((chest, 0), (roar, 0.6), (chains, 0.6), (rock, 0.6), (stone_impact(1.0, 1.6) * 0.55, 0.6)), 'cave', 0.26)


@S('boss/brute_idle', 'idle')
def _():
    inh = breath_in(0.55, 0.6, 'o') * 0.5
    ex = bru_v(0.95, [(0, 46), (1, 40)], [(0, 'o'), (1, 'u')], amp=[(0, 0), (0.15, 1), (0.6, 0.7), (1, 0)], drive=1.6)
    ch = chain_rattle(1.3, 7, 1500, 3500, amp=[(0, 0.3), (0.5, 1), (1, 0.2)]) * 0.18
    return space(mix((inh, 0), (ex, 0.5, 0.9), (ch, 0.2)), 'cave', 0.2)


@S('boss/brute_pain1', 'pain')
def _():
    g = bru_v(0.42, [(0, 95), (0.3, 105), (1, 62)], [(0, 'uh'), (1, 'o')], amp=[(0, 0), (0.08, 1), (0.5, 0.7), (1, 0)])
    return space(mix(g, (stone_impact(0.4, 0.6) * 0.35, 0), (debris(0.3, 50, 600, 3500, 0.08) * 0.3, 0)), 'room', 0.15)


@S('boss/brute_pain2', 'pain')
def _():
    g = bru_v(0.55, [(0, 120), (0.25, 128), (1, 70)], [(0, 'A'), (0.6, 'a'), (1, 'uh')], amp=[(0, 0), (0.05, 1), (0.45, 0.8), (1, 0)], drive=3.0)
    return space(mix(g, (chain_rattle(0.4, 25, 1800, 4000) * 0.2, 0.02)), 'room', 0.15)


@S('boss/brute_death', 'death')
def _():
    roar = bru_v(1.5, [(0, 105), (0.25, 95), (1, 30)], [(0, 'A'), (0.5, 'o'), (1, 'u')],
                 amp=[(0, 0), (0.05, 1), (0.6, 0.7), (1, 0)], fry=0.25)
    fall = mix(stone_impact(1.3, 2.0), (body_fall(1.8, 1.0, armor=False) * 0.8, 0),
               (chain_rattle(0.9, 40, 1500, 4500, amp=[(0, 1), (1, 0)]) * 0.4, 0.02))
    return space(mix((roar, 0), (fall, 1.15)), 'cave', 0.28)


@S('boss/brute_step', 'step', sr=LO)
def _():
    return mix(stomp(1.8, 'stone', 0.45), (chain_rattle(0.3, 18, 1800, 3800) * 0.12, 0.03))


@S('boss/brute_attack', 'attack')
def _():
    sw = swish(0.4, 250, 1800, 0.65) * 0.8
    gr = bru_v(0.45, [(0, 80), (0.4, 110), (1, 85)], [(0, 'uh'), (1, 'A')], amp=[(0, 0), (0.2, 1), (1, 0)], drive=2.6)
    hit = stone_impact(0.45, 1.0)
    return space(mix((gr, 0, 0.8), (sw, 0.05), (hit, 0.33, 0.9)), 'room', 0.16)


@S('boss/brute_phase', 'ability')
def _():
    cracks = mix(*[(stone_impact(0.35, 0.5) * 0.5, i * 0.12) for i in range(4)])
    roar = bru_v(1.4, [(0, 90), (0.2, 145), (0.7, 130), (1, 80)], [(0, 'o'), (0.2, 'A'), (1, 'a')],
                 amp=[(0, 0), (0.08, 1), (0.75, 0.9), (1, 0)], drive=3.2)
    return space(mix((cracks, 0), (roar, 0.3), (rumble(1.6, 90) * 0.6, 0.2), (debris(1.2, 90, 300, 4000, 0.5) * 0.4, 0.4)), 'cave', 0.25)


@S('boss/brute_kill', 'ability')
def _():
    lg = laugh(4, 75, 0.56, 0.08, 0.17, 0.95, 0.5, 0.5, 0.4, 2.0, 'uh')
    beat = mix((thump(0.3, 48, 0.07), 0), (thump(0.3, 50, 0.07), 0.18))
    return space(mix((beat, 0), (lg, 0.42)), 'cave', 0.22)


# ---------- 1 BANSHEE (boss): tiz ciglik / ruzgar / hayalet ----------

@S('boss/banshee_intro', 'intro')
def _():
    w = wind(3.0, 400, 1200, 0.65, [(0, 0), (0.4, 1), (0.8, 0.8), (1, 0)]) * 0.5
    sw = reverse_swell(1.0, 800, 8000) * 0.6
    wail = shriek(1.1, [(0, 420), (0.7, 820), (1, 900)], ('u', 'o', 'a'), 1.25, 0.6, (5.5, 0.7), 1.2,
                  amp=[(0, 0), (0.4, 0.7), (1, 1)])
    scr = shriek(1.4, [(0, 1250), (0.2, 1450), (1, 900)], ('a', 'e', 'i', 'e'), 1.4, 0.5, (7.5, 0.6), 1.8,
                 amp=[(0, 0), (0.04, 1), (0.6, 0.85), (1, 0)], layers=3)
    return space(mix((w, 0), (sw, 0.1), (wail, 0.25), (scr, 1.3)), 'ghost', 0.38)


@S('boss/banshee_idle', 'idle')
def _():
    m = shriek(1.6, [(0, 440), (0.5, 520), (1, 400)], ('u', 'o', 'u'), 1.2, 0.8, (4.5, 0.9), 0.0,
               amp=[(0, 0), (0.3, 0.8), (0.7, 1), (1, 0)], layers=1)
    w = wind(1.8, 600, 900, 0.7) * 0.35
    return space(mix(flanger(m, 0.4, 0.003, 0.5, 0.4) * 0.8, w), 'ghost', 0.42)


@S('boss/banshee_pain1', 'pain')
def _():
    s = shriek(0.4, [(0, 1100), (0.3, 1550), (1, 950)], ('e', 'i'), 1.35, 0.4, (9, 0.4), 2.0,
               amp=[(0, 0), (0.06, 1), (0.5, 0.8), (1, 0)])
    return space(s, 'ghost', 0.3)


@S('boss/banshee_pain2', 'pain')
def _():
    g = shriek(0.5, [(0, 750), (0.4, 640), (1, 480)], ('a', 'uh'), 1.25, 1.0, (6, 0.3), 1.2,
               amp=[(0, 0), (0.1, 1), (0.5, 0.6), (1, 0)])
    gasp = breath_in(0.2, 1.2, 'a') * 0.5
    return space(mix(gasp, (g, 0.12)), 'ghost', 0.3)


@S('boss/banshee_death', 'death')
def _():
    s = shriek(1.4, [(0, 1300), (0.3, 1100), (1, 260)], ('i', 'e', 'a', 'u'), 1.35, 0.6, (8, 0.8), 1.6,
               amp=[(0, 0), (0.04, 1), (0.7, 0.6), (1, 0)], layers=3)
    s = flanger(s, 0.8, 0.004, 0.6, 0.6)
    gr = granular(s, 1.6, 0.06, 140, (0.5, 1.6), amp=[(0, 0), (0.5, 0.6), (1, 0)], rev=0.5) * 0.5
    tones = mix(*[(chime(f, 1.2, 0.5) * 0.2, 0.6 + i * 0.15) for i, f in enumerate([1568, 1175, 932])])
    return space(mix(s, (gr, 0.5), (tones, 0), (reverse_swell(0.8, 1500, 9000) * 0.4, 0.9)), 'ghost', 0.45)


@S('boss/banshee_step', 'step', sr=LO)
def _():
    p = bp(noise(0.35, 'pink'), 300, 2000) * env_lin([(0, 0), (0.3, 1), (1, 0)], 0.35)
    tone = sine(sweep(700, 560, 0.35), 0.35) * env_lin([(0, 0), (0.3, 0.3), (1, 0)], 0.35)
    return space(mix(p, tone * 0.4), 'ghost', 0.35)


@S('boss/banshee_attack', 'attack')
def _():
    sw = mix(swish(0.3, 1200, 6000, 0.4), (swish(0.3, 1500, 7000, 0.4) * 0.7, 0.1))
    h = shriek(0.4, [(0, 900), (1, 1300)], ('a', 'i'), 1.3, 0.8, (10, 0.3), 1.8, amp=[(0, 0), (0.2, 1), (1, 0)])
    return space(mix((h, 0, 0.7), (sw, 0.12)), 'ghost', 0.3)


@S('boss/banshee_phase', 'ability')
def _():
    parts = [(shriek(1.3, [(0, f), (0.3, f * 1.15), (1, f * 0.8)], ('a', 'e', 'i'), 1.3 + 0.05 * i, 0.5, (7 + i, 0.6), 1.6,
                     amp=[(0, 0), (0.1, 1), (0.7, 0.8), (1, 0)]), 0.1 * i, 0.7) for i, f in enumerate([880, 1047, 1245])]
    g = wind(1.6, 500, 2500, 0.6, [(0, 0), (0.3, 1), (1, 0)]) * 0.6
    return space(mix(g, *parts), 'ghost', 0.4)


@S('boss/banshee_kill', 'ability')
def _():
    lg = laugh(6, 950, 1.35, 0.03, 0.12, 0.94, 0.0, 0.0, 0.7, 1.2, 'A', beastly=False)
    return space(flanger(lg, 0.5, 0.002, 0.4, 0.35), 'ghost', 0.42)


# ---------- 2 OVERLORD: koro / kemik / nekromant ----------

def ovl_v(d, f0, seq, amp=None, drive=1.6, **k):
    return beast(d, f0, seq, fs=0.74, sub=0.25, rough=0.25, rr_=30, jit=0.025, breath=0.3, drive=drive, amp=amp,
                 octave=0.6, bright=0.08, noisy=0.1, **k)


@S('boss/overlord_intro', 'intro')
def _():
    d = 3.0
    ch = choir(d, [73.4, 110.0, 146.8, 174.6, 220.0], [(0, 'u'), (0.4, 'o'), (0.8, 'a'), (1, 'a')], 0.95, 2,
               amp=[(0, 0), (0.6, 0.8), (0.85, 1), (1, 0)])
    bones = bone_rattle(d, 30, 600, 2200, [(0, 0), (0.7, 1), (0.8, 0.2), (1, 0)]) * 0.35
    voice_ = ovl_v(1.2, [(0, 70), (0.3, 82), (1, 60)], [(0, 'o'), (0.4, 'A'), (1, 'uh')], drive=2.0)
    hit = mix(boom(1.0, 80, 30, 0.35), (bell(110, 1.0, 1.4, 4, 0.5) * 0.4, 0))
    return space(mix((ch, 0, 0.8), (bones, 0), (hit, 2.0, 0.9), (voice_, 1.9, 0.9)), 'hall', 0.32)


@S('boss/overlord_idle', 'idle')
def _():
    d = 1.8
    hum = choir(d, [65.4, 98.0], 'u', 0.85, 2, amp=[(0, 0), (0.3, 1), (0.7, 1), (1, 0)])
    rat = bone_rattle(d, 9, 800, 2000) * 0.25
    return space(mix(hum, rat), 'hall', 0.3)


@S('boss/overlord_pain1', 'pain')
def _():
    g = ovl_v(0.42, [(0, 125), (1, 82)], [(0, 'uh'), (1, 'o')], amp=[(0, 0), (0.08, 1), (0.5, 0.7), (1, 0)])
    return space(mix(g, (knock(1100, 0.15, 0.03) * 0.6, 0), (knock(1500, 0.15, 0.02) * 0.4, 0.05)), 'hall', 0.2)


@S('boss/overlord_pain2', 'pain')
def _():
    g = ovl_v(0.5, [(0, 105), (0.3, 112), (1, 86)], [(0, 'e'), (1, 'a')], amp=[(0, 0), (0.06, 1), (0.6, 0.6), (1, 0)], drive=2.4)
    stab = choir(0.5, [146.8, 174.6, 207.7], 'a', 1.0, 1, amp=[(0, 0), (0.05, 1), (1, 0)]) * 0.5
    return space(mix(g, stab), 'hall', 0.22)


@S('boss/overlord_death', 'death')
def _():
    d = 2.1
    notes = [110.0, 130.8, 164.8, 196.0]
    ch = np.zeros(n_of(d))
    for f in notes:
        ch += voice(d, [(0, f), (0.3, f), (1, f * 0.45)], [(0, 'a'), (1, 'u')], 0.95, 0.02, 0.05, 0, 0, 0.55, 0.3,
                    vib=(5, 0.3), amp=[(0, 0), (0.05, 1), (0.7, 0.6), (1, 0)])
    sc = bone_rattle(1.2, 60, 500, 2500, [(0, 1), (1, 0)]) * 0.5
    return space(mix((norm(ch), 0, 0.8), (ovl_v(0.9, [(0, 95), (1, 45)], [(0, 'A'), (1, 'u')]) * 0.7, 0), (sc, 0.9),
                     (boom(1.0, 70, 28, 0.4) * 0.6, 0.9)), 'hall', 0.32)


@S('boss/overlord_step', 'step', sr=LO)
def _():
    return mix(knock(700, 0.15, 0.03) * 0.6, (knock(950, 0.15, 0.02) * 0.4, 0.03), (thump(0.35, 55, 0.07), 0.0),
               (bone_rattle(0.3, 25, 900, 2200) * 0.25, 0.02))


@S('boss/overlord_attack', 'attack')
def _():
    sw = swish(0.38, 300, 2500, 0.55)
    blast = mix(boom(0.45, 140, 50, 0.12) * 0.7, (choir(0.4, [98.0, 146.8], 'A', 0.9, 1, amp=[(0, 0), (0.05, 1), (1, 0)]) * 0.6, 0))
    return space(mix((sw, 0), (blast, 0.28), (ovl_v(0.3, [(0, 90), (1, 120)], 'A') * 0.5, 0.0)), 'hall', 0.25)


@S('boss/overlord_phase', 'ability')
def _():
    d = 1.2
    ch = choir(d, [73.4, 77.8, 110, 155.6, 220, 233.1], [(0, 'o'), (1, 'A')], 1.0, 1,
               amp=[(0, 0), (0.75, 1), (1, 0)])
    bn = bone_rattle(d, 70, 500, 2600, [(0, 0), (0.8, 1), (1, 0)]) * 0.4
    return space(mix((ch, 0), (bn, 0), (boom(0.6, 90, 30, 0.25) * 0.8, 0.85)), 'hall', 0.3)


@S('boss/overlord_kill', 'ability')
def _():
    lg = laugh(3, 78, 0.72, 0.12, 0.24, 0.94, 0.25, 0.2, 0.3, 1.6, 'o')
    ch = choir(1.3, [146.8, 174.6, 220.0], 'u', 0.95, 1, amp=[(0, 0), (0.3, 0.6), (1, 0)]) * 0.35
    return space(mix(lg, (ch, 0.1)), 'hall', 0.3)


# ---------- 3 INFERNO: alev / kukreme ----------

def inf_v(d, f0, seq, amp=None, drive=2.6, **k):
    return beast(d, f0, seq, fs=0.66, sub=0.35, rough=0.4, rr_=32, jit=0.05, breath=0.9, drive=drive, amp=amp,
                 octave=0.4, bright=0.18, noisy=0.35, **k)


@S('boss/inferno_intro', 'intro')
def _():
    ign = mix(whoosh(0.9, 150, 3500, 0.7), (fire(2.6, 150, 4000, 90, [(0, 0), (0.3, 1), (0.8, 0.8), (1, 0)]) * 0.6, 0.4))
    roar = inf_v(1.9, [(0, 70), (0.2, 118), (0.6, 105), (1, 55)], [(0, 'o'), (0.2, 'A'), (1, 'a')],
                 amp=[(0, 0), (0.08, 1), (0.6, 0.9), (1, 0)])
    lava = bubbles(2.0, 10, 70, 220) * 0.4
    return space(mix((ign, 0), (roar, 0.75), (lava, 0.6), (boom(1.2, 90, 32, 0.4) * 0.7, 0.75)), 'cave', 0.24)


@S('boss/inferno_idle', 'idle')
def _():
    f = fire(1.7, 200, 3500, 70) * 0.6
    g = inf_v(1.2, [(0, 52), (1, 46)], [(0, 'uh'), (1, 'o')], amp=[(0, 0), (0.3, 1), (1, 0)], drive=1.6)
    return space(mix(f, (g, 0.3, 0.7), (bubbles(1.6, 6, 60, 180) * 0.4, 0)), 'cave', 0.2)


@S('boss/inferno_pain1', 'pain')
def _():
    g = inf_v(0.45, [(0, 110), (0.3, 130), (1, 80)], [(0, 'A'), (1, 'uh')], amp=[(0, 0), (0.06, 1), (0.5, 0.7), (1, 0)])
    return space(mix(g, (crackle(0.4, 140, 2000, 8000) * 0.6, 0), (whoosh(0.3, 500, 3000, 0.2) * 0.4, 0)), 'room', 0.15)


@S('boss/inferno_pain2', 'pain')
def _():
    g = inf_v(0.55, [(0, 95), (0.2, 100), (1, 70)], [(0, 'e'), (0.5, 'a'), (1, 'o')], amp=[(0, 0), (0.05, 1), (0.6, 0.7), (1, 0)], drive=3.0)
    return space(mix(g, (sizzle(0.5) * 0.35, 0.05)), 'room', 0.15)


@S('boss/inferno_death', 'death')
def _():
    r = inf_v(1.5, [(0, 120), (0.3, 105), (1, 35)], [(0, 'A'), (0.6, 'o'), (1, 'u')], amp=[(0, 0), (0.05, 1), (0.6, 0.7), (1, 0)], fry=0.3)
    steam = sizzle(1.5, [(0, 0), (0.15, 1), (1, 0)]) * 0.55
    cool = mix(crackle(1.4, 50, 1000, 6000) * 0.5, (stone_impact(0.8, 1.2) * 0.5, 0.2))
    return space(mix((r, 0), (steam, 0.8), (cool, 0.9), (fire(1.0, 150, 3000, 40, [(0, 1), (1, 0)]) * 0.4, 0)), 'cave', 0.24)


@S('boss/inferno_step', 'step', sr=LO)
def _():
    return mix(stomp(1.6, 'stone', 0.4), (sizzle(0.3, [(0, 0), (0.1, 1), (1, 0)]) * 0.25, 0.02),
               (crackle(0.3, 50, 1500, 5000) * 0.3, 0.02))


@S('boss/inferno_attack', 'attack')
def _():
    sw = swish(0.4, 300, 3000, 0.5)
    fl = fire(0.6, 200, 5000, 90, [(0, 0), (0.1, 1), (1, 0)]) * 0.8
    g = inf_v(0.35, [(0, 90), (1, 120)], [(0, 'uh'), (1, 'A')], amp=[(0, 0), (0.2, 1), (1, 0)])
    return space(mix((g, 0, 0.7), (sw, 0.05), (fl, 0.15)), 'room', 0.18)


@S('boss/inferno_phase', 'ability')
def _():
    up = mix(whoosh(1.0, 120, 4500, 0.5), (fire(1.6, 150, 5000, 120, [(0, 0), (0.3, 1), (1, 0)]) * 0.8, 0.1))
    r = inf_v(1.2, [(0, 85), (0.25, 150), (1, 100)], [(0, 'o'), (0.25, 'A'), (1, 'a')], amp=[(0, 0), (0.08, 1), (0.8, 0.9), (1, 0)], drive=3.2)
    return space(mix((up, 0), (r, 0.35), (boom(1.0, 100, 35, 0.3) * 0.8, 0.35), (crackle(1.0, 120, 1000, 8000) * 0.5, 0.4)), 'cave', 0.24)


@S('boss/inferno_kill', 'ability')
def _():
    lg = laugh(4, 92, 0.66, 0.07, 0.16, 0.94, 0.35, 0.4, 0.7, 2.2, 'A')
    return space(mix(lg, (fire(1.2, 200, 3500, 80, [(0, 0), (0.2, 1), (1, 0)]) * 0.35, 0)), 'cave', 0.22)


# ---------- 4 REAPER: fisilti / metal / tirpan ----------

def scythe_ring(d=1.2, f=1650):
    return metal_hit(f, d, 0.6, 'bar', 0.9)


def scrape(d=0.8, f0=2200, f1=3200):
    """metal surtunmesi (tirpan bilenmesi): gurultu -> dar rezonatorler + surtunme AM"""
    n = n_of(d)
    src = rr().standard_normal(n) * (0.5 + 0.5 * np.abs(np.sin(np.pi * np.cumsum(np.full(n, 35.0)) / Ctx.sr)))
    y = np.zeros(n)
    for k, r_ in enumerate([1.0, 2.31, 3.6]):
        fc = np.linspace(f0, f1, n) * r_
        y += L._reson_tv(src, fc, fc / 60) / (1 + k)
    return norm(hp(y, 600)) * env_lin([(0, 0), (0.1, 1), (0.8, 0.8), (1, 0)], d)


@S('boss/reaper_intro', 'intro')
def _():
    toll = bell(98, 2.4, 1.4, 5, 0.7) * 0.7
    wh = mix(*[(whispers(1.7, 8, U(0.75, 1.05)) * 0.5, U(0, 0.25)) for _ in range(3)])
    sc = scrape(0.7, 2000, 3300) * 0.45
    ring_ = scythe_ring(0.9, 1650) * 0.6
    breath = reverse(unvoiced(0.8, [(0, 'a'), (1, 'u')], 0.7, amp=[(0, 0), (0.1, 1), (1, 0)])) * 0.6
    return space(mix((toll, 0), (wh, 0.2), (breath, 0.55), (sc, 1.1), (ring_, 1.65)), 'ghost', 0.38)


@S('boss/reaper_idle', 'idle')
def _():
    b = unvoiced(1.6, [(0, 'o'), (0.5, 'a'), (1, 'uh')], 0.72, amp=[(0, 0), (0.3, 1), (0.6, 0.5), (0.8, 0.9), (1, 0)])
    b = b * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 21 * tt(1.6))))
    ch = chain_rattle(1.6, 5, 2500, 5000) * 0.2
    return space(mix(b, ch), 'ghost', 0.4)


@S('boss/reaper_pain1', 'pain')
def _():
    h = hiss(0.4, 1.1, [(0, 0), (0.05, 1), (0.4, 0.6), (1, 0)], 'i')
    return space(mix(h, (chain_rattle(0.3, 30, 2500, 5000) * 0.35, 0)), 'ghost', 0.3)


@S('boss/reaper_pain2', 'pain')
def _():
    g = unvoiced(0.5, [(0, 'a'), (1, 'uh')], 0.8, amp=[(0, 0), (0.06, 1), (0.5, 0.5), (1, 0)])
    rasp = voice(0.5, [(0, 70), (1, 50)], 'a', 0.75, 0.15, 0.4, 0.5, 0.6, 0.5, 1.5, amp=[(0, 0), (0.06, 1), (0.5, 0.4), (1, 0)]) * 0.5
    return space(mix(g, rasp, (metal_hit(1200, 0.4, 0.15, 'plate') * 0.35, 0)), 'ghost', 0.3)


@S('boss/reaper_death', 'death')
def _():
    ex = unvoiced(1.6, [(0, 'A'), (0.5, 'a'), (1, 'u')], 0.7, amp=[(0, 0), (0.05, 1), (1, 0)])
    ex = flanger(ex, 0.6, 0.004, 0.6, 0.5)
    clang = mix(metal_hit(900, 1.0, 0.35, 'bar'), (metal_hit(1300, 0.8, 0.25, 'bar') * 0.6, 0.18), (metal_hit(1100, 0.6, 0.2, 'bar') * 0.4, 0.3))
    return space(mix((ex, 0), (clang, 0.9, 0.6), (bell(98, 1.5, 1.4, 4, 0.6) * 0.3, 0.2), (reverse_swell(0.7, 500, 6000) * 0.4, 0.25)), 'ghost', 0.4)


@S('boss/reaper_step', 'step', sr=LO)
def _():
    cloth = bp(noise(0.3, 'pink'), 400, 3000) * env_lin([(0, 0), (0.3, 1), (1, 0)], 0.3)
    return mix(cloth * 0.7, (chain_rattle(0.25, 18, 2200, 4500) * 0.3, 0.05), (thump(0.25, 70, 0.04) * 0.4, 0.05))


@S('boss/reaper_attack', 'attack')
def _():
    sw = mix(swish(0.35, 800, 6000, 0.5), (swish(0.3, 1500, 8000, 0.5) * 0.6, 0.03))
    return space(mix((sw, 0), (scythe_ring(0.6, 1900) * 0.5, 0.2), (hiss(0.25, 1.0) * 0.3, 0)), 'ghost', 0.3)


@S('boss/reaper_phase', 'ability')
def _():
    d = 1.7
    wh = mix(*[(whispers(d, 9, U(0.7, 1.1)) * 0.5, 0) for _ in range(4)]) * env_lin([(0, 0.3), (0.8, 1), (1, 0)], d)
    sc = scrape(1.3, 1800, 3800) * env_lin([(0, 0), (0.8, 1), (1, 0)], 1.3)
    return space(mix((wh, 0), (sc, 0.3, 0.6), (bell(98, 1.2, 1.4, 6, 0.6) * 0.5, 0.0)), 'ghost', 0.4)


@S('boss/reaper_kill', 'ability')
def _():
    parts = []
    for i in range(4):
        parts.append((unvoiced(0.16, [(0, 'A'), (1, 'uh')], 0.85, amp=[(0, 0), (0.1, 1), (1, 0)]), 0.1 + i * 0.2, 1 - 0.12 * i))
    return space(mix((bell(220, 1.4, 1.41, 3, 0.6) * 0.4, 0), *parts), 'ghost', 0.42)


# ---------- 5 FROSTLORD: buz catlamasi / derin ----------

def frl_v(d, f0, seq, amp=None, drive=1.8, **k):
    return beast(d, f0, seq, fs=0.6, sub=0.35, rough=0.3, rr_=20, jit=0.03, breath=0.6, drive=drive, amp=amp,
                 octave=0.6, bright=0.1, noisy=0.25, **k)


def shimmer_ice(d, count=24):
    return tinkle(d, count, 2500, 9000)


@S('boss/frostlord_intro', 'intro')
def _():
    d = 3.0
    groan = creak(2.2, 8, 22, (180, 420, 1150), 10, [(0, 0), (0.2, 1), (0.9, 0.8), (1, 0)]) * 0.5
    cracks = mix(*[(ice_crack(0.6, 1.0), 0.3 + i * 0.28, 0.6) for i in range(4)])
    bel = frl_v(1.6, [(0, 52), (0.3, 66), (1, 48)], [(0, 'u'), (0.3, 'o'), (1, 'o')], amp=[(0, 0), (0.15, 1), (0.7, 0.8), (1, 0)])
    sh = shimmer_ice(d, 30) * env_lin([(0, 0), (0.6, 1), (1, 0)], d) * 0.3
    w = wind(d, 600, 1500, 0.4, [(0, 0), (0.5, 0.8), (1, 0)]) * 0.35
    return space(mix((groan, 0), (w, 0), (cracks, 0), (bel, 1.2, 0.95), (sh, 0)), 'cave', 0.3)


@S('boss/frostlord_idle', 'idle')
def _():
    d = 1.8
    br = unvoiced(d, [(0, 'o'), (1, 'u')], 0.7, amp=[(0, 0), (0.4, 1), (1, 0)]) * 0.5
    cr = creak(d, 6, 12, (220, 500, 1300), 12, [(0, 0), (0.3, 0.7), (1, 0)]) * 0.4
    return space(mix(br, cr, (shimmer_ice(d, 8) * 0.25, 0)), 'cave', 0.28)


@S('boss/frostlord_pain1', 'pain')
def _():
    g = frl_v(0.45, [(0, 85), (1, 60)], [(0, 'uh'), (1, 'o')], amp=[(0, 0), (0.08, 1), (0.5, 0.7), (1, 0)])
    return space(mix(ice_crack(0.45, 0.8) * 0.7, (g, 0.03, 0.8)), 'room', 0.18)


@S('boss/frostlord_pain2', 'pain')
def _():
    g = frl_v(0.6, [(0, 92), (0.3, 98), (1, 58)], [(0, 'a'), (1, 'u')], amp=[(0, 0), (0.06, 1), (0.6, 0.7), (1, 0)], drive=2.3)
    return space(mix(g, (crackle(0.5, 160, 2500, 9500) * 0.5, 0), (shimmer_ice(0.5, 8) * 0.3, 0.1)), 'room', 0.18)


@S('boss/frostlord_death', 'death')
def _():
    b = frl_v(1.3, [(0, 80), (0.3, 70), (1, 32)], [(0, 'o'), (1, 'u')], amp=[(0, 0), (0.06, 1), (0.6, 0.7), (1, 0)], fry=0.3)
    sh = mix(*[(ice_crack(0.5, 1.2), 0.9 + i * 0.07, 0.7) for i in range(6)])
    gl = shimmer_ice(1.2, 50) * 0.5
    return space(mix((b, 0), (sh, 0), (gl, 1.0), (stone_impact(1.0, 1.4) * 0.5, 1.0)), 'cave', 0.3)


@S('boss/frostlord_step', 'step', sr=LO)
def _():
    return mix(stomp(1.7, 'ice', 0.45), (shimmer_ice(0.3, 4) * 0.15, 0.02))


@S('boss/frostlord_attack', 'attack')
def _():
    sw = swish(0.45, 500, 5000, 0.5)
    ic = mix(crackle(0.4, 180, 3000, 10000) * 0.6, (shimmer_ice(0.4, 12) * 0.4, 0))
    g = frl_v(0.35, [(0, 70), (1, 95)], 'A', amp=[(0, 0), (0.2, 1), (1, 0)])
    return space(mix((g, 0, 0.6), (sw, 0.05), (ic, 0.25)), 'room', 0.22)


@S('boss/frostlord_phase', 'ability')
def _():
    d = 1.8
    casc = mix(*[(ice_crack(0.6, 1.0) * U(0.4, 0.8), i * 0.11) for i in range(9)])
    w = wind(d, 400, 2500, 0.5, [(0, 0), (0.6, 1), (1, 0)]) * 0.5
    b = frl_v(1.0, [(0, 60), (0.3, 88), (1, 70)], [(0, 'o'), (0.4, 'A'), (1, 'a')], drive=2.4)
    return space(mix((casc, 0), (w, 0), (b, 0.65)), 'cave', 0.3)


@S('boss/frostlord_kill', 'ability')
def _():
    lg = laugh(3, 62, 0.6, 0.12, 0.22, 0.95, 0.35, 0.25, 0.5, 1.6, 'o')
    return space(mix(lg, (shimmer_ice(1.2, 14) * 0.3, 0.2)), 'cave', 0.3)


# ---------- 6 STORMCALLER: gok gurultusu / elektrik ----------

def stm_v(d, f0, seq, amp=None, drive=2.0, ringf=None, **k):
    y = beast(d, f0, seq, fs=0.78, sub=0.2, rough=0.2, rr_=35, jit=0.03, breath=0.5, drive=drive, amp=amp,
              octave=0.35, bright=0.15, noisy=0.15, **k)
    if ringf:
        y = 0.65 * y + 0.35 * norm(ring(y, ringf))
    return y


@S('boss/stormcaller_intro', 'intro')
def _():
    ch = riser(1.2, 300, 4000) * 0.45
    hum = elec_buzz(1.3, 110, 0.4, [(0, 0), (1, 1)]) * 0.35
    th = thunder(2.0, 1.2)
    sh = stm_v(1.3, [(0, 120), (0.2, 170), (1, 110)], [(0, 'a'), (0.3, 'A'), (1, 'o')], amp=[(0, 0), (0.08, 1), (0.7, 0.8), (1, 0)], ringf=55)
    sp = mix(*[(arc(0.25), 1.2 + U(0, 1.4), 0.35) for _ in range(5)])
    return space(mix((ch, 0), (hum, 0), (th, 1.15), (sh, 1.3, 0.9), (sp, 0)), 'arena', 0.25)


@S('boss/stormcaller_idle', 'idle')
def _():
    d = 1.8
    b = elec_buzz(d, 120, 0.6, [(0, 0), (0.2, 1), (0.8, 1), (1, 0)]) * 0.45
    rm = thunder(d, 0.0, 2.5) * 0.5
    return space(mix(rm, b, (crackle(d, 40, 2500, 9000) * 0.4, 0)), 'arena', 0.22)


@S('boss/stormcaller_pain1', 'pain')
def _():
    g = stm_v(0.4, [(0, 150), (1, 110)], [(0, 'uh'), (1, 'o')], amp=[(0, 0), (0.08, 1), (0.5, 0.7), (1, 0)], ringf=80)
    return space(mix(zap(0.3, 4000, 300) * 0.6, (g, 0.02)), 'room', 0.18)


@S('boss/stormcaller_pain2', 'pain')
def _():
    g = stm_v(0.55, [(0, 170), (0.3, 185), (1, 120)], [(0, 'A'), (1, 'a')], amp=[(0, 0), (0.06, 1), (0.6, 0.7), (1, 0)], drive=2.8)
    return space(mix(g, (arc(0.4) * 0.5, 0.05)), 'room', 0.18)


@S('boss/stormcaller_death', 'death')
def _():
    th = thunder(2.1, 1.3)
    wh = sine(sweep(2200, 40, 1.6), 1.6) * env_lin([(0, 0), (0.05, 1), (1, 0)], 1.6) * 0.35
    sp = mix(*[(arc(U(0.1, 0.25)), U(0.3, 1.6), U(0.2, 0.5)) for _ in range(8)])
    v = stm_v(0.9, [(0, 160), (1, 60)], [(0, 'A'), (1, 'u')], amp=[(0, 0), (0.06, 1), (1, 0)], ringf=40)
    return space(mix((v, 0), (th, 0.3), (wh, 0.3), (sp, 0)), 'arena', 0.25)


@S('boss/stormcaller_step', 'step', sr=LO)
def _():
    return mix(thump(0.35, 60, 0.06), (metal_hit(U(1800, 2200), 0.3, 0.08, 'bar') * 0.3, 0.0), (crackle(0.25, 60, 2500, 6000) * 0.35, 0.02))


@S('boss/stormcaller_attack', 'attack')
def _():
    lash = mix(zap(0.45, 6000, 250), (arc(0.35) * 0.7, 0.02))
    return space(mix((swish(0.35, 600, 5000, 0.4) * 0.6, 0), (lash, 0.1), (stm_v(0.3, [(0, 110), (1, 150)], 'A') * 0.4, 0)), 'arena', 0.22)


@S('boss/stormcaller_phase', 'ability')
def _():
    d = 1.9
    rise = mix(riser(0.6, 200, 3000) * 0.4, elec_buzz(0.6, 100, 0.2, [(0, 0), (1, 1)]) * 0.4)
    th = mix(thunder(0.7, 1.2), (thunder(0.55, 1.0) * 0.8, 0.25))
    sh = stm_v(0.65, [(0, 140), (0.3, 200), (1, 150)], 'A', drive=2.6, ringf=60)
    return space(mix((rise, 0), (th, 0.55), (sh, 0.6, 0.8)), 'arena', 0.25)


@S('boss/stormcaller_kill', 'ability')
def _():
    lg = laugh(4, 140, 0.8, 0.06, 0.15, 0.93, 0.15, 0.2, 0.5, 1.6, 'A')
    lg = 0.7 * lg + 0.3 * norm(ring(lg, 70)) * np.max(np.abs(lg))
    return space(mix(lg, (crackle(1.0, 60, 2000, 9000) * 0.3, 0), (thunder(1.2, 0.0, 2.0) * 0.4, 0.2)), 'arena', 0.22)


# ---------- 7 HIVE QUEEN: bocek tikirtisi / vizilti ----------

def insect_scream(d, f0, amp=None, fs=1.15, drive=1.8):
    v = voice(d, f0, [(0, 'e'), (0.5, 'i'), (1, 'e')], fs, 0.04, 0.3, 0.3, 0.1, 0.4, 0.4, 0.7,
              [(0, 70), (1, 55)], amp=amp, parallel=True)
    return norm(dist(v * drive, 1.3))


def swarm(d, count=6, f=(170, 260), amp=None):
    return norm(sum(insect_buzz(d, U(*f), 0.7) * U(0.4, 1.0) for _ in range(count))) * curve(amp if amp is not None else 1.0, d)


@S('boss/hivequeen_intro', 'intro')
def _():
    d = 3.0
    sw = swarm(d, 8, (150, 300), [(0, 0), (0.5, 1), (0.85, 0.7), (1, 0)]) * 0.5
    cl = chitter(d, 40, 2000, 5000, [(0, 0.3), (0.6, 1), (1, 0.4)]) * 0.5
    sc = insect_scream(1.3, [(0, 320), (0.2, 520), (1, 380)], amp=[(0, 0), (0.08, 1), (0.7, 0.8), (1, 0)])
    wet = squelch(0.5, 900, 250, 1.0) * 0.4
    return space(mix((sw, 0), (cl, 0), (wet, 1.25), (sc, 1.5)), 'cave', 0.22)


@S('boss/hivequeen_idle', 'idle')
def _():
    d = 1.7
    pur = chitter(d, 28, 1500, 3500, [(0, 0.4), (0.5, 1), (1, 0.4)], burst=(6, 14)) * 0.6
    wb = swarm(d, 3, (180, 230), [(0, 0), (0.3, 0.5), (0.7, 0.5), (1, 0)]) * 0.35
    return space(mix(pur, wb, (bubbles(d, 6, 150, 400) * 0.2, 0)), 'cave', 0.2)


@S('boss/hivequeen_pain1', 'pain')
def _():
    s = insect_scream(0.38, [(0, 600), (0.3, 750), (1, 500)], amp=[(0, 0), (0.06, 1), (0.5, 0.6), (1, 0)])
    return space(mix(s, (chitter(0.3, 50, 2500, 5000) * 0.5, 0.05)), 'room', 0.15)


@S('boss/hivequeen_pain2', 'pain')
def _():
    h = hiss(0.5, 1.2, [(0, 0), (0.05, 1), (1, 0)], 'e', 2000)
    return space(mix(h * 0.6, (chitter(0.45, 60, 1800, 4500, burst=(5, 10)) * 0.7, 0), (squelch(0.3, 1000, 400) * 0.3, 0.05)), 'room', 0.15)


@S('boss/hivequeen_death', 'death')
def _():
    s = insect_scream(1.2, [(0, 560), (0.3, 480), (1, 160)], amp=[(0, 0), (0.05, 1), (0.6, 0.6), (1, 0)])
    wings = insect_buzz(1.6, 220, 0.7, [(0, 0.8), (1, 0)])
    gate = signal.lfilter([0.01], [1, -0.99], (lpnoise(len(wings), 12) > -0.3).astype(float))
    wings = wings * gate
    crack_ = mix(knock(1500, 0.2, 0.02, False), (knock(2200, 0.2, 0.015, False) * 0.7, 0.04), (splat(0.5) * 0.7, 0.06))
    return space(mix((s, 0), (wings * 0.4, 0.1), (crack_, 1.05)), 'cave', 0.22)


@S('boss/hivequeen_step', 'step', sr=LO)
def _():
    return stomp(1.4, 'chitin', 0.4)


@S('boss/hivequeen_attack', 'attack')
def _():
    snap = mix(*[(knock(U(2200, 3200), 0.1, 0.008, False), 0.04 * i, 0.8) for i in range(3)])
    burst = insect_buzz(0.45, 260, 0.7, [(0, 0), (0.1, 1), (1, 0)]) * 0.5
    return space(mix((burst, 0), (hiss(0.3, 1.2) * 0.4, 0.05), (snap, 0.22)), 'room', 0.15)


@S('boss/hivequeen_phase', 'ability')
def _():
    d = 1.8
    sw = swarm(d, 10, (160, 340), [(0, 0.2), (0.7, 1), (1, 0)])
    sc = insect_scream(1.0, [(0, 420), (0.3, 700), (1, 500)])
    return space(mix((sw, 0, 0.6), (chitter(d, 60, 2000, 6000) * 0.5, 0), (sc, 0.6)), 'cave', 0.22)


@S('boss/hivequeen_kill', 'ability')
def _():
    tr = chitter(1.2, 70, 2500, 5500, [(0, 1), (0.6, 0.9), (1, 0)], burst=(10, 20))
    return space(mix(tr, (insect_scream(0.5, [(0, 700), (1, 900)]) * 0.5, 0.0)), 'cave', 0.2)


# ---------- 8 VOID: ters ses / ugultu ----------

def void_drone(d, f=36.7, amp=None):
    t = tt(d)
    x = sine(f, d) + sine(f * 1.012, d) * 0.8 + 0.4 * sine(f * 2.997, d) + 0.25 * saw(f * 4.02, d, 10)
    x = lp(x, 900)
    return norm(x) * curve(amp if amp is not None else [(0, 0), (0.3, 1), (0.7, 1), (1, 0)], d)


def void_v(d, f0, seq, amp=None, drive=1.8):
    y = beast(d, f0, seq, fs=0.7, sub=0.4, rough=0.3, rr_=18, jit=0.04, breath=0.4, drive=drive, amp=amp,
              octave=0.5, bright=0.1, noisy=0.2)
    y = 0.6 * y + 0.4 * norm(ring(y, 33))
    return norm(reverse(y))


@S('boss/void_intro', 'intro')
def _():
    d = 3.0
    sw = reverse_swell(1.6, 100, 4000)
    dr = void_drone(d, 36.7, [(0, 0), (0.5, 1), (0.85, 1), (1, 0)]) * 0.6
    vv = void_v(1.3, [(0, 60), (0.5, 80), (1, 50)], [(0, 'o'), (0.5, 'A'), (1, 'uh')])
    gr = granular(vv, 2.0, 0.08, 60, (0.4, 1.0), amp=[(0, 0), (0.4, 1), (1, 0)], rev=0.6) * 0.35
    drop = boom(1.4, 70, 22, 0.5)
    return space(mix((dr, 0), (sw, 0), (drop, 1.6), (vv, 1.55, 0.9), (gr, 1.0)), 'hall', 0.35)


@S('boss/void_idle', 'idle')
def _():
    d = 1.8
    dr = void_drone(d, 41.2)
    wh = reverse(whispers(d, 6, 0.8)) * 0.35
    return space(mix(dr * 0.8, wh, (tremolo(bp(noise(d, 'pink'), 2000, 5000), 3, 0.8) * 0.12, 0)), 'hall', 0.35)


@S('boss/void_pain1', 'pain')
def _():
    v = void_v(0.45, [(0, 70), (1, 110)], [(0, 'u'), (1, 'A')], amp=[(0, 0), (0.5, 0.7), (0.92, 1), (1, 0)])
    return space(v, 'hall', 0.25)


@S('boss/void_pain2', 'pain')
def _():
    src = beast(0.5, [(0, 120), (1, 70)], 'A', 0.75, drive=2)
    st = mix(*[(src[:n_of(0.06)] * env_lin([(0, 0), (0.1, 1), (0.9, 1), (1, 0)], 0.06), 0.065 * i, 1.0) for i in range(5)])
    return space(mix(st, (pitch(src, -5)[:n_of(0.5)] * 0.6, 0.3)), 'hall', 0.25)


@S('boss/void_death', 'death')
def _():
    d = 2.2
    suck = reverse(lp(noise(1.6, 'pink'), 3000) * env_exp(1.6, 0.4)) * 0.8
    dr = void_drone(d, 55, [(0, 1), (1, 0)]) * 0.6
    dr = dr * 1.0
    fall = sine(sweep(220, 25, d), d) * env_lin([(0, 0), (0.1, 1), (1, 0)], d) * 0.5
    implode = boom(0.9, 60, 20, 0.35)
    v = void_v(1.2, [(0, 40), (1, 90)], [(0, 'u'), (1, 'A')])
    return space(mix((suck, 0), (dr, 0), (fall, 0), (v, 0.3, 0.6), (implode, 1.5)), 'hall', 0.35)


@S('boss/void_step', 'step', sr=LO)
def _():
    pre = reverse(lp(noise(0.2, 'pink'), 1500) * env_exp(0.2, 0.05)) * 0.5
    return mix(pre, (thump(0.25, 45, 0.06) * 1.0, 0.19))


@S('boss/void_attack', 'attack')
def _():
    w = mix(sine(sweep(1400, 60, 0.6), 0.6) * env_exp(0.6, 0.18), ring(zap(0.4, 3000, 200), 120) * 0.5)
    return space(mix(reverse(swish(0.3, 500, 4000, 0.4)) * 0.6, (w, 0.25)), 'hall', 0.3)


@S('boss/void_phase', 'ability')
def _():
    d = 1.0
    det = sum(saw(sweep(f, f * 2.0, d), d, 15) for f in (55, 55.6, 82.4, 110.3)) / 4
    det = lp_sweep(det, 200, 3000) * env_lin([(0, 0), (0.85, 1), (1, 0)], d)
    rv = reverse_swell(0.8, 1000, 9000) * 0.6
    return space(mix((det, 0, 0.6), (rv, 0.2), (boom(0.5, 80, 25, 0.18), 0.95)), 'hall', 0.32)


@S('boss/void_kill', 'ability')
def _():
    lg = laugh(4, 85, 0.72, 0.07, 0.16, 0.95, 0.4, 0.3, 0.4, 1.6, 'A')
    lg = reverse(lg)
    return space(mix(lg, (void_drone(1.4, 36.7) * 0.4, 0)), 'hall', 0.35)


# ======================================================================
# OZEL: NEMESIS (mutant super asker, dokunacli kol) / ASSASSIN (ninja zombi)
# ======================================================================

def nem_v(d, f0, seq, amp=None, drive=3.0, **k):
    return beast(d, f0, seq, fs=0.7, sub=0.45, rough=0.5, rr_=30, jit=0.05, breath=0.6, drive=drive, amp=amp,
                 octave=0.5, bright=0.16, noisy=0.25, **k)


def tentacle(d=0.5):
    """dokunac kirbaci: hizli islak whoosh + kamci catlamasi + yapiskan et"""
    w = swish(d * 0.7, 400, 4000, 0.7)
    cr = hp(rr().standard_normal(n_of(0.03)), 1500) * env_exp(0.03, 0.006)
    return mix((w, 0, 0.8), (squelch(d * 0.6, 1500, 300, 0.8) * 0.7, d * 0.45), (cr, d * 0.48, 0.9))


@S('special/nemesis_intro', 'intro')
def _():
    br = mix(*[(breath_in(0.35, 0.75, 'a') * 0.5, i * 0.5) for i in range(2)])
    hit = mix(boom(1.2, 110, 35, 0.3), (metal_hit(180, 1.0, 0.4, 'plate') * 0.4, 0))
    r = nem_v(1.5, [(0, 80), (0.15, 125), (0.6, 112), (1, 70)], [(0, 'o'), (0.15, 'A'), (1, 'a')],
              amp=[(0, 0), (0.06, 1), (0.7, 0.85), (1, 0)])
    return space(mix((br, 0), (hit, 0.95), (r, 1.0), (tentacle(0.6) * 0.6, 1.6), (squelch(0.5, 700, 200) * 0.5, 2.0)), 'arena', 0.24)


@S('special/nemesis_idle', 'idle')
def _():
    parts = []
    for i in range(2):
        parts += [(breath_in(0.35, 0.7, 'o') * 0.6, i * 0.75),
                  (nem_v(0.4, [(0, 60), (1, 52)], [(0, 'o'), (1, 'uh')], amp=[(0, 0), (0.2, 1), (1, 0)], drive=1.8) * 0.7, i * 0.75 + 0.33)]
    return space(mix(*parts, (squelch(0.4, 600, 250, 0.5) * 0.25, 0.6)), 'room', 0.2)


@S('special/nemesis_pain', 'pain')
def _():
    g = nem_v(0.45, [(0, 120), (0.3, 135), (1, 85)], [(0, 'A'), (1, 'uh')], amp=[(0, 0), (0.06, 1), (0.5, 0.7), (1, 0)])
    return space(mix(g, (squelch(0.3, 1100, 300, 0.4) * 0.35, 0)), 'room', 0.15)


@S('special/nemesis_death', 'death')
def _():
    r = nem_v(1.3, [(0, 125), (0.3, 110), (1, 38)], [(0, 'A'), (0.6, 'o'), (1, 'u')], amp=[(0, 0), (0.05, 1), (0.6, 0.7), (1, 0)], fry=0.3)
    return space(mix((r, 0), (body_fall(1.3, 1.0, armor=True, wet=0.6), 1.0)), 'arena', 0.24)


@S('special/nemesis_attack', 'attack')
def _():
    g = nem_v(0.3, [(0, 100), (1, 140)], [(0, 'uh'), (1, 'A')], amp=[(0, 0), (0.25, 1), (1, 0)])
    return space(mix((g, 0, 0.6), (tentacle(0.55), 0.08)), 'room', 0.18)


def blade_shing(d=0.6, f=2600):
    """kilic cekme: kisa surtunme + parlak metal cinlamasi"""
    sc = scrape(0.22, f * 0.8, f * 1.2) * 0.6
    return mix((sc, 0), (metal_hit(f, d, 0.35, 'bar', 1.2) * 0.7, 0.18))


@S('special/assassin_intro', 'intro')
def _():
    sw = reverse_swell(0.8, 1500, 9000) * 0.5
    h = hiss(1.0, 1.1, [(0, 0), (0.1, 1), (0.6, 0.6), (1, 0)], 'i')
    wh = whispers(1.3, 6, 1.05) * 0.6
    return space(mix((sw, 0), (blade_shing(0.8, 2700), 0.7), (blade_shing(0.8, 3100), 1.05, 0.9), (h, 1.3, 0.6), (wh, 1.0, 0.6)), 'ghost', 0.3)


@S('special/assassin_idle', 'idle')
def _():
    d = 1.4
    b = unvoiced(d, [(0, 'ee'), (0.5, 'i'), (1, 'ee')], 1.1, amp=[(0, 0), (0.3, 0.8), (0.5, 0.3), (0.8, 0.9), (1, 0)])
    return space(mix(b * 0.7, (scrape(0.5, 3000, 2600) * 0.25, 0.7)), 'ghost', 0.3)


@S('special/assassin_pain', 'pain')
def _():
    h = hiss(0.4, 1.2, [(0, 0), (0.04, 1), (0.4, 0.5), (1, 0)], 'i', 3000)
    v = voice(0.35, [(0, 260), (1, 200)], 'e', 1.05, 0.05, 0.2, 0, 0, 0.5, 1.2, amp=[(0, 0), (0.1, 1), (1, 0)]) * 0.5
    return space(mix(h, v), 'room', 0.2)


@S('special/assassin_death', 'death')
def _():
    g = unvoiced(0.9, [(0, 'a'), (1, 'u')], 1.0, amp=[(0, 0), (0.05, 1), (1, 0)])
    rasp = voice(0.9, [(0, 180), (1, 70)], [(0, 'a'), (1, 'u')], 1.0, 0.1, 0.3, 0.3, 0.4, 0.5, 1.0, amp=[(0, 0), (0.06, 1), (1, 0)]) * 0.5
    clat = mix(metal_hit(2300, 0.5, 0.15, 'bar'), (metal_hit(2600, 0.4, 0.1, 'bar') * 0.6, 0.12), (metal_hit(2450, 0.3, 0.08, 'bar') * 0.3, 0.2))
    return space(mix((g, 0), (rasp, 0), (clat, 0.75, 0.7), (thump(0.4, 70, 0.08) * 0.6, 0.8)), 'room', 0.25)


@S('special/assassin_attack', 'attack')
def _():
    a = mix(swish(0.25, 1500, 8000, 0.5), (metal_hit(3200, 0.3, 0.12, 'bar') * 0.3, 0.15))
    b = mix(swish(0.25, 1800, 9000, 0.5), (metal_hit(3500, 0.3, 0.1, 'bar') * 0.3, 0.15))
    return space(mix((a, 0), (b, 0.18), (hiss(0.15, 1.2) * 0.3, 0.0)), 'room', 0.18)


# ======================================================================
# ZOMBI SINIFLARI (24) -> class/<c>_{pain,die,idle,ability}.wav + ekler
# ======================================================================
# her sinifin vokal profili: (temel perde, formant olcegi, ana parametreler)

def zv(d, f0, seq, fs, amp=None, **k):
    """genel zombi girtlagi (beast ile ayni yapi, sinif parametreleriyle)"""
    p = dict(sub=0.3, rough=0.35, rr_=24, jit=0.05, shim=0.18, breath=0.45, drive=1.8, octave=0.3, bright=0.12,
             noisy=0.2)
    p.update(k)
    return beast(d, f0, seq, fs, amp=amp, **p)


A_PAIN = [(0, 0), (0.06, 1), (0.45, 0.7), (1, 0)]
A_DIE = [(0, 0), (0.05, 1), (0.55, 0.75), (1, 0)]

# ---------- 0 WALKER: klasik inilti ----------
WK = dict(sub=0.25, rough=0.35, rr_=20, jit=0.06, breath=0.5, drive=1.5, octave=0.25)


@S('class/walker_pain', 'pain')
def _():
    return space(zv(0.45, [(0, 145), (0.2, 160), (1, 100)], [(0, 'A'), (1, 'uh')], 0.84, A_PAIN, **WK), 'room', 0.15)


@S('class/walker_die', 'death')
def _():
    g = zv(1.1, [(0, 130), (0.3, 115), (1, 55)], [(0, 'a'), (0.5, 'o'), (1, 'u')], 0.84, A_DIE, fry=0.35, **WK)
    gur = mix(bubbles(0.4, 25, 200, 600) * 0.4, squelch(0.3, 600, 250, 0.6) * 0.3)
    return space(mix((g, 0), (gur, 0.8), (body_fall(0.9, 0.6), 1.0)), 'room', 0.18)


@S('class/walker_idle', 'idle')
def _():
    g = zv(1.4, [(0, 92), (0.4, 105), (1, 80)], [(0, 'o'), (0.4, 'uh'), (0.8, 'o'), (1, 'u')], 0.84,
           [(0, 0), (0.25, 1), (0.6, 0.8), (1, 0)], **WK)
    return space(g, 'room', 0.18)


@S('class/walker_ability', 'ability')
def _():
    # hiz patlamasi: hizlanan saldirgan hirilti + kalp atisi + firlama
    g = zv(0.9, [(0, 110), (0.6, 190), (1, 170)], [(0, 'uh'), (0.5, 'A'), (1, 'a')], 0.84, [(0, 0), (0.15, 1), (0.85, 0.9), (1, 0)],
           sub=0.3, rough=0.45, rr_=26, jit=0.05, breath=0.7, drive=2.2, octave=0.25)
    return space(mix((heartbeat(0.9, 140, 55) * 0.6, 0), (g, 0.15), (swish(0.35, 400, 3000, 0.4) * 0.5, 0.75)), 'room', 0.15)


# ---------- 1 RUNNER: hirilti / nefes nefese ----------
RN = dict(sub=0.1, rough=0.2, rr_=35, jit=0.04, breath=1.4, drive=1.6, octave=0.0, bright=0.25, noisy=0.35)


def pant(count, rate=0.17, fs=1.0, f0=180):
    parts = []
    for i in range(count):
        inn = i % 2 == 0
        v = unvoiced(0.12, 'A' if inn else 'uh', fs * (1.05 if inn else 0.95), amp=[(0, 0), (0.3, 1), (1, 0)], bwk=1.4)
        parts.append((v, i * rate * U(0.9, 1.1), 0.9 if inn else 0.7))
        if not inn:
            parts.append((voice(0.1, f0 * U(0.9, 1.1), 'uh', fs, 0.08, 0.3, 0, 0.3, 0.5, 1.5,
                                amp=[(0, 0), (0.3, 1), (1, 0)]) * 0.35, i * rate + 0.01, 1.0))
    return mix(*parts)


@S('class/runner_pain', 'pain')
def _():
    return space(zv(0.4, [(0, 230), (0.25, 290), (1, 190)], [(0, 'e'), (1, 'a')], 1.0, A_PAIN, **RN), 'room', 0.15)


@S('class/runner_die', 'death')
def _():
    wz = zv(0.9, [(0, 240), (0.3, 200), (1, 90)], [(0, 'a'), (0.5, 'uh'), (1, 'u')], 1.0, A_DIE, fry=0.4, **RN)
    ch = mix(*[(unvoiced(0.12, 'uh', 1.0, amp=[(0, 0), (0.3, 1), (1, 0)]) * 0.5, 0.9 + i * 0.16) for i in range(2)])
    return space(mix(wz, (ch, 0), (body_fall(0.7, 0.5), 1.1)), 'room', 0.15)


@S('class/runner_idle', 'idle')
def _():
    return space(pant(8, 0.165, 1.0, 190), 'room', 0.15)


@S('class/runner_ability', 'ability')
def _():
    # uzun ziplama: hazirlik nefesi + efor ciglik + firlama
    sc = zv(0.6, [(0, 220), (0.4, 340), (1, 260)], [(0, 'uh'), (0.4, 'A'), (1, 'a')], 1.0, [(0, 0), (0.15, 1), (1, 0)], **RN)
    return space(mix((pant(2, 0.12), 0), (sc, 0.2), (swish(0.5, 300, 3500, 0.5) * 0.7, 0.4)), 'room', 0.15)


# ---------- 2 TANK: derin boru gibi bogurme ----------
TK = dict(sub=0.5, rough=0.45, rr_=22, jit=0.04, breath=0.4, drive=2.2, octave=0.55, bright=0.08)


@S('class/tank_pain', 'pain')
def _():
    return space(zv(0.5, [(0, 85), (0.2, 92), (1, 62)], [(0, 'uh'), (1, 'o')], 0.6, A_PAIN, **TK), 'room', 0.15)


@S('class/tank_die', 'death')
def _():
    g = zv(1.0, [(0, 82), (0.3, 75), (1, 34)], [(0, 'o'), (1, 'u')], 0.6, A_DIE, fry=0.3, **TK)
    return space(mix((g, 0), (body_fall(1.6, 0.9, armor=True), 0.85)), 'room', 0.18)


@S('class/tank_idle', 'idle')
def _():
    br = breath_in(0.45, 0.6, 'o') * 0.4
    ex = zv(0.9, [(0, 52), (1, 46)], [(0, 'o'), (1, 'u')], 0.6, [(0, 0), (0.2, 1), (1, 0)], **TK)
    return space(mix((br, 0), (ex, 0.4), (metal_hit(260, 0.5, 0.2, 'plate') * 0.12, 0.9)), 'room', 0.18)


@S('class/tank_ability', 'ability')
def _():
    # hasar kalkani: zirh plakalari kilitlenir + derin metal rezonans + kisa bogurme
    clank = mix(metal_hit(240, 1.0, 0.5, 'plate'), (metal_hit(330, 0.8, 0.4, 'plate') * 0.7, 0.12))
    hum = (sine(98, 1.1) + 0.5 * sine(147, 1.1)) * env_lin([(0, 0), (0.2, 1), (1, 0)], 1.1) * 0.4
    g = zv(0.5, [(0, 70), (1, 95)], [(0, 'o'), (1, 'A')], 0.6, [(0, 0), (0.2, 1), (1, 0)], **TK)
    return space(mix((g, 0, 0.8), (clank, 0.3), (hum, 0.35)), 'room', 0.2)


# ---------- 3 BANSHEE: ciglik ----------
@S('class/banshee_pain', 'pain')
def _():
    return space(shriek(0.4, [(0, 950), (0.3, 1250), (1, 850)], ('e', 'i'), 1.3, 0.5, (9, 0.4), 1.8, amp=A_PAIN), 'room', 0.2)


@S('class/banshee_die', 'death')
def _():
    s = shriek(1.1, [(0, 1050), (0.25, 1150), (1, 300)], ('i', 'e', 'a', 'u'), 1.3, 0.6, (7, 0.7), 1.5, amp=A_DIE)
    return space(mix(s, (body_fall(0.6, 0.5), 1.0)), 'hall', 0.25)


@S('class/banshee_idle', 'idle')
def _():
    # hickiran aglama: kisa titrek heceler
    parts = []
    for i in range(4):
        f = U(480, 560)
        parts.append((shriek(0.22, [(0, f), (1, f * 0.85)], ('u', 'o'), 1.2, 1.0, (11, 0.8), 0.0,
                             amp=[(0, 0), (0.3, 1), (1, 0)], layers=1) * U(0.6, 1.0), i * 0.3))
        parts.append((breath_in(0.12, 1.2, 'u') * 0.3, i * 0.3 + 0.22))
    return space(mix(*parts), 'hall', 0.25)


@S('class/banshee_ability', 'ability')
def _():
    # kor eden ciglik: delici ciglik + kulak cinlamasi (tinnitus)
    s = shriek(0.85, [(0, 1100), (0.15, 1500), (1, 1200)], ('a', 'i', 'i'), 1.4, 0.4, (8, 0.4), 2.2,
               amp=[(0, 0), (0.04, 1), (0.8, 0.9), (1, 0)], layers=3)
    tin = sine(3800, 0.75) * env_lin([(0, 0), (0.2, 0.25), (1, 0)], 0.75)
    return space(mix(s, (tin, 0.2)), 'hall', 0.25)


# ---------- 4 LEECH: islak sulurtu ----------
LC = dict(sub=0.2, rough=0.6, rr_=45, jit=0.06, breath=0.5, drive=1.4, octave=0.2, noisy=0.15)


def slurp(d=0.6, f0=500, f1=1400):
    s = squelch(d, f0, f1, 1.2)
    suck = bp_sweep(noise(d, 'pink'), f0 * 0.6, f1 * 1.5, 0.3) * env_lin([(0, 0), (0.5, 1), (1, 0)], d)
    return mix(s, norm(suck) * 0.5)


def gurgle(d, f0=110, fs=0.9, amp=None):
    v = zv(d, f0, [(0, 'o'), (0.5, 'u'), (1, 'o')], fs, amp, sub=0.2, rough=0.8, rr_=[(0, 40), (1, 25)], breath=0.4, drive=1.2, octave=0.2)
    b = bubbles(d, 30, 150, 600)
    return v * 0.7 + norm(b) * 0.4


@S('class/leech_pain', 'pain')
def _():
    sq = zv(0.4, [(0, 300), (0.3, 360), (1, 240)], [(0, 'e'), (1, 'i')], 1.05, A_PAIN, **LC)
    return space(mix(sq, (splat(0.35) * 0.5, 0)), 'room', 0.15)


@S('class/leech_die', 'death')
def _():
    g = gurgle(1.1, [(0, 160), (1, 70)], 0.95, A_DIE)
    return space(mix(g, (splat(0.5) * 0.7, 0.9), (squelch(0.4, 900, 200) * 0.5, 1.0)), 'room', 0.15)


@S('class/leech_idle', 'idle')
def _():
    return space(mix((slurp(0.5, 400, 1200), 0), (slurp(0.45, 450, 1500) * 0.8, 0.6), (gurgle(0.5, 120, 0.95) * 0.4, 0.9)), 'room', 0.15)


@S('class/leech_ability', 'ability')
def _():
    # can emme: uzun emme + yutkunma + yukselen nabiz
    s = slurp(0.7, 300, 1800)
    gulp = mix(*[(thump(0.15, 90, 0.03) * 0.7, 0.62 + i * 0.13) for i in range(3)])
    return space(mix(s, (heartbeat(0.8, 140, 60) * 0.5, 0.1), (gulp, 0), (bubbles(0.8, 40, 200, 800) * 0.3, 0.05)), 'room', 0.15)


# ---------- 5 STALKER: tislama ----------
@S('class/stalker_pain', 'pain')
def _():
    h = hiss(0.4, 1.0, [(0, 0), (0.03, 1), (0.4, 0.6), (1, 0)], 'i', 2500)
    v = zv(0.3, [(0, 180), (1, 140)], 'e', 1.0, A_PAIN, breath=1.2, drive=1.2, octave=0) * 0.4
    return space(mix(knock(2600, 0.08, 0.006, False) * 0.3, (h, 0.01), (v, 0.02)), 'room', 0.15)


@S('class/stalker_die', 'death')
def _():
    h = hiss(0.85, 0.95, [(0, 0), (0.05, 1), (0.6, 0.6), (1, 0)], 'ee', 2000)
    rat = voice(0.7, [(0, 90), (1, 45)], 'uh', 0.85, 0.1, 0.4, 0.3, [(0, 0.2), (1, 0.8)], 0.5, 1.0,
                amp=[(0, 0), (0.1, 0.6), (1, 0)]) * 0.5
    return space(mix(h, (rat, 0.25), (body_fall(0.7, 0.3), 0.75)), 'room', 0.15)


@S('class/stalker_idle', 'idle')
def _():
    parts = [(hiss(0.5, 1.0, [(0, 0), (0.3, 1), (1, 0)], 'ee', 2800) * 0.8, 0),
             (hiss(0.45, 0.9, [(0, 0), (0.3, 1), (1, 0)], 'i', 2400) * 0.6, 0.7)]
    parts += [(knock(U(2500, 3500), 0.06, 0.004, False) * 0.25, 0.5 + 0.07 * i) for i in range(3)]
    return space(mix(*parts), 'room', 0.18)


@S('class/stalker_ability', 'ability')
def _():
    # gorunmezlik: ters hisirti emilimi + faz kaymasi (flanger) + sonen cinlama
    rv = reverse(hiss(0.5, 1.0, [(0, 1), (1, 0)], 'ee', 2500))
    sh = flanger(bp(noise(0.5, 'pink'), 1500, 8000) * env_lin([(0, 0), (0.2, 1), (1, 0)], 0.5), 2.0, 0.004, 0.7, 0.7)
    ch = chime(1760, 0.45, 0.15) * 0.3
    return space(mix((rv, 0), (norm(sh) * 0.6, 0.45), (ch, 0.48)), 'hall', 0.3)


# ---------- 6 BOMBER: fokurtu ----------
BM = dict(sub=0.35, rough=0.7, rr_=[(0, 30), (1, 18)], jit=0.05, breath=0.3, drive=1.5, octave=0.35, noisy=0.15)


def belly(d, rate=20):
    return mix(bubbles(d, rate, 80, 300), (lp(rr().standard_normal(n_of(d)), 300) * env_lin([(0, 0), (0.3, 1), (1, 0)], d) * 0.2, 0))


@S('class/bomber_pain', 'pain')
def _():
    g = zv(0.45, [(0, 120), (0.3, 130), (1, 85)], [(0, 'uh'), (1, 'o')], 0.75, A_PAIN, **BM)
    return space(mix(g, (belly(0.4, 25) * 0.4, 0)), 'room', 0.15)


@S('class/bomber_die', 'death')
def _():
    g = gurgle(1.1, [(0, 110), (1, 55)], 0.75, A_DIE)
    return space(mix(g, (belly(1.2, 35) * 0.5, 0), (splat(0.5) * 0.7, 1.0)), 'room', 0.15)


@S('class/bomber_idle', 'idle')
def _():
    return space(mix(belly(1.5, 22) * 0.9, (zv(0.7, 80, [(0, 'o'), (1, 'u')], 0.75, [(0, 0), (0.3, 1), (1, 0)], **BM) * 0.5, 0.5)), 'room', 0.15)


@S('class/bomber_ability', 'ability')
def _():
    # zehir patlamasi: sisen karin (yukselen fokurtu + gerilme) -> islak patlama + zehir tislamasi
    swell = mix(bubbles(0.5, 50, 150, 900) * env_lin([(0, 0.3), (1, 1)], 0.5), creak(0.5, 20, 80, (300, 800, 1900), 8) * 0.25)
    ex = mix(boom(0.5, 100, 40, 0.14), (splat(0.4), 0), (hiss(0.45, 1.0, [(0, 1), (1, 0)], 'e', 2000) * 0.5, 0.04))
    return space(mix((swell, 0), (ex, 0.48)), 'room', 0.2)


# ---------- 7 FROST: buzlu citirti ----------
FR = dict(sub=0.2, rough=0.3, rr_=22, jit=0.04, breath=0.9, drive=1.4, octave=0.2, noisy=0.3)


@S('class/frost_pain', 'pain')
def _():
    g = zv(0.42, [(0, 140), (1, 100)], [(0, 'uh'), (1, 'o')], 0.85, A_PAIN, **FR)
    return space(mix(ice_crack(0.35, 0.4) * 0.6, (g, 0.02, 0.8)), 'room', 0.15)


@S('class/frost_die', 'death')
def _():
    g = zv(0.8, [(0, 130), (1, 60)], [(0, 'a'), (1, 'u')], 0.85, A_DIE, **FR)
    cr = crackle(0.75, 40, 3000, 10000) * env_lin([(0, 0), (1, 1)], 0.75) * 0.6
    sh = mix(ice_crack(0.4, 0.6), (tinkle(0.35, 16, 3000, 9000) * 0.6, 0.03))
    return space(mix((g, 0), (cr, 0), (sh, 0.68)), 'room', 0.2)


@S('class/frost_idle', 'idle')
def _():
    d = 1.3
    chat = np.zeros(n_of(d))
    for k in range(int(d * 13)):
        p = int((k / 13 + U(-0.01, 0.01)) * Ctx.sr)
        c = knock(U(1800, 2600), 0.03, 0.004, False) * U(0.3, 0.8)
        if 0 <= p < len(chat) - len(c):
            chat[p:p + len(c)] += c
    chat *= env_lin([(0, 0), (0.15, 1), (0.6, 0.4), (0.75, 1), (1, 0)], d)
    br = unvoiced(d, 'u', 0.9, amp=[(0, 0), (0.5, 0.6), (1, 0)]) * 0.5
    return space(mix(chat * 0.7, br, (crackle(d, 15, 4000, 10000) * 0.3, 0)), 'room', 0.15)


@S('class/frost_ability', 'ability')
def _():
    # buz halkasi: soguk patlama + halka seklinde yayilan citirti + kristal cinlamalar
    d = 1.3
    burst = mix(thump(0.4, 80, 0.08), whoosh(0.8, 3000, 400, 0.15) * 0.8)
    ring_ = crackle(1.0, 200, 3000, 10000) * env_lin([(0, 0), (0.15, 1), (1, 0)], 1.0) * 0.6
    return space(mix((burst, 0), (ring_, 0.05), (tinkle(d, 30, 3000, 9000) * 0.45, 0.1)), 'hall', 0.25)


# ---------- 8 SPITTER: asit gargarasi ----------
SP_ = dict(sub=0.15, rough=0.7, rr_=[(0, 45), (1, 30)], jit=0.05, breath=0.5, drive=1.3, octave=0.15, noisy=0.2)


@S('class/spitter_pain', 'pain')
def _():
    g = zv(0.42, [(0, 220), (0.3, 250), (1, 170)], [(0, 'e'), (1, 'o')], 1.05, A_PAIN, **SP_)
    return space(mix(g, (bubbles(0.3, 30, 300, 1000) * 0.3, 0)), 'room', 0.15)


@S('class/spitter_die', 'death')
def _():
    g = gurgle(1.1, [(0, 200), (1, 90)], 1.05, A_DIE)
    return space(mix(g, (sizzle(0.9, [(0, 0), (0.2, 1), (1, 0)]) * 0.4, 0.4), (body_fall(0.6, 0.6, wet=0.5), 1.0)), 'room', 0.15)


@S('class/spitter_idle', 'idle')
def _():
    return space(mix(gurgle(1.0, 150, 1.05, [(0, 0), (0.3, 1), (1, 0)]) * 0.8, (sizzle(0.7, [(0, 0), (0.3, 1), (1, 0)]) * 0.3, 0.6)), 'room', 0.15)


@S('class/spitter_ability', 'ability')
def _():
    # asit puskurtme: bogaz temizleme 'hork' -> islak puskurtme -> cizirti
    hork = norm(bp_sweep(rr().standard_normal(n_of(0.35)), 300, 1500, 0.4)) * env_lin([(0, 0), (0.6, 1), (1, 0)], 0.35)
    hork = hork * (0.6 + 0.4 * np.sin(2 * np.pi * 40 * tt(0.35)))
    spray = mix(lp(noise(0.5), 4000) * env_exp(0.5, 0.15), bubbles(0.5, 40, 400, 1500) * 0.4)
    return space(mix((hork, 0, 0.8), (spray, 0.32), (sizzle(0.8) * 0.45, 0.45)), 'room', 0.18)


# ---------- 9 HULK: kukreme ----------
HK = dict(sub=0.45, rough=0.45, rr_=26, jit=0.05, breath=0.7, drive=2.6, octave=0.5, bright=0.15, noisy=0.25)


@S('class/hulk_pain', 'pain')
def _():
    return space(zv(0.5, [(0, 120), (0.25, 135), (1, 85)], [(0, 'A'), (1, 'uh')], 0.66, A_PAIN, **HK), 'room', 0.15)


@S('class/hulk_die', 'death')
def _():
    r = zv(0.85, [(0, 125), (0.3, 110), (1, 40)], [(0, 'A'), (0.6, 'o'), (1, 'u')], 0.66, A_DIE, fry=0.3, **HK)
    return space(mix((r, 0), (body_fall(1.8, 0.45), 0.65)), 'room', 0.2)


@S('class/hulk_idle', 'idle')
def _():
    parts = []
    for i in range(2):
        parts.append((zv(0.5, [(0, 70), (1, 60)], [(0, 'uh'), (1, 'o')], 0.66, [(0, 0), (0.2, 1), (1, 0)], **HK) * 0.8, i * 0.62))
        parts.append((breath_in(0.25, 0.7, 'a') * 0.4, i * 0.62 + 0.4))
    return space(mix(*parts), 'room', 0.18)


@S('class/hulk_ability', 'ability')
def _():
    # sok dalgasi: kukreme + yere vurus + yayilan dalga
    r = zv(0.7, [(0, 100), (0.3, 165), (1, 130)], [(0, 'o'), (0.3, 'A'), (1, 'a')], 0.66, [(0, 0), (0.1, 1), (1, 0)], **HK)
    slam = mix(stone_impact(0.5, 1.5), (whoosh(0.45, 2000, 200, 0.1) * 0.5, 0.02))
    return space(mix((r, 0), (slam, 0.48)), 'hall', 0.2)


# ---------- 10 VOODOO: ilahi / tilsim ----------
def chant(d, notes=(130.8, 196.0), count=5, fs=0.95, syl=0.22):
    parts = []
    seqs = [('o', 'u'), ('a', 'o'), ('e', 'a'), ('u', 'o'), ('a', 'e')]
    t = 0.0
    for i in range(count):
        s0, s1 = seqs[i % len(seqs)]
        Ls = syl * U(0.85, 1.25)
        for j, f in enumerate(notes):
            parts.append((voice(Ls, f * U(0.995, 1.005), [(0, s0), (1, s1)], fs, 0.02, 0.06, 0, 0, 0.55, 0.3,
                                vib=(5, 0.15), amp=[(0, 0), (0.15, 1), (0.7, 0.8), (1, 0)]) * (1.0 if j == 0 else 0.55), t))
        t += Ls + U(0.02, 0.06)
        if t > d:
            break
    return mix(*parts)


def shaker(d, rate=8):
    out = np.zeros(n_of(d))
    for k in range(int(d * rate)):
        p = int(k / rate * Ctx.sr)
        s = hp(rr().standard_normal(n_of(0.06)), 4000) * env_lin([(0, 0), (0.2, 1), (1, 0)], 0.06)
        if p + len(s) < len(out):
            out[p:p + len(s)] += s * (1.0 if k % 2 == 0 else 0.6)
    return out


@S('class/voodoo_pain', 'pain')
def _():
    y = voice(0.4, [(0, 240), (0.3, 270), (1, 180)], [(0, 'a'), (1, 'e')], 1.0, 0.04, 0.15, 0.1, 0, 0.55, 0.5, amp=A_PAIN)
    return space(mix(y, (shaker(0.3, 16) * 0.3, 0), (knock(1400, 0.12, 0.02) * 0.4, 0)), 'room', 0.15)


@S('class/voodoo_die', 'death')
def _():
    c = chant(0.6, (130.8, 196.0), 2)
    fall = voice(0.8, [(0, 131), (1, 65)], [(0, 'o'), (1, 'u')], 0.95, 0.04, 0.15, 0.2, 0.3, 0.55, 0.5, amp=A_DIE)
    drop = mix(bone_rattle(0.5, 50, 800, 2400, [(0, 1), (1, 0)]) * 0.5, (thump(0.4, 60, 0.08), 0))
    return space(mix((c, 0, 0.7), (fall, 0.45), (drop, 1.0)), 'hall', 0.25)


@S('class/voodoo_idle', 'idle')
def _():
    c = chant(1.3, (123.5, 185.0), 5, syl=0.2)
    return space(mix(c * 0.8, (shaker(1.3, 6) * 0.25, 0)), 'hall', 0.25)


@S('class/voodoo_ability', 'ability')
def _():
    # iyilestirme: ilahi + yukselen sihirli parilti + davul
    c = chant(0.9, (146.8, 220.0, 293.7), 4, syl=0.18)
    sp = mix(*[(chime(f, 0.45, 0.15) * 0.3, 0.3 + 0.1 * i) for i, f in enumerate([587.3, 740.0, 880.0, 1174.7])])
    dr = mix(timpani(73.4, 0.4) * 0.6, (timpani(73.4, 0.4) * 0.5, 0.33))
    return space(mix((c, 0, 0.8), (sp, 0), (dr, 0), (tinkle(0.6, 14, 3000, 8000) * 0.2, 0.3)), 'hall', 0.28)


# ---------- 11 PHANTOM: hayalet fisiltisi ----------
@S('class/phantom_pain', 'pain')
def _():
    g = unvoiced(0.45, [(0, 'A'), (1, 'u')], 1.0, amp=A_PAIN)
    return space(flanger(g, 1.5, 0.003, 0.6, 0.5), 'ghost', 0.4)


@S('class/phantom_die', 'death')
def _():
    w = unvoiced(1.2, [(0, 'a'), (0.5, 'o'), (1, 'u')], 0.95, amp=A_DIE)
    gr = granular(w, 1.4, 0.07, 90, (0.7, 1.5), amp=[(0, 0.2), (0.5, 1), (1, 0)], rev=0.5) * 0.5
    return space(mix(flanger(w, 0.6, 0.004, 0.6, 0.5), (gr, 0.2), (chime(880, 1.0, 0.4) * 0.12, 0.3)), 'ghost', 0.45)


@S('class/phantom_idle', 'idle')
def _():
    w = whispers(1.5, 7, 1.0)
    return space(flanger(w, 0.4, 0.003, 0.5, 0.4), 'ghost', 0.45)


@S('class/phantom_ability', 'ability')
def _():
    # isinlanma: ters emilim -> 'pop' -> fisilti kirintisi
    r = reverse(swish(0.4, 400, 6000, 0.3))
    pop = mix(sine(sweep(900, 200, 0.12), 0.12) * env_exp(0.12, 0.03), hp(rr().standard_normal(n_of(0.02)), 2000) * env_exp(0.02, 0.004) * 0.5)
    w = whispers(0.6, 3, 1.05) * 0.6
    return space(mix((r, 0), (pop, 0.4), (w, 0.5)), 'ghost', 0.42)


# ---------- 12 BUTCHER: agir homurtu + zincir ----------
BT = dict(sub=0.45, rough=0.4, rr_=22, jit=0.05, breath=0.6, drive=2.2, octave=0.45, bright=0.1)


def hook_creak(d=0.8):
    return creak(d, 10, 25, (420, 1100, 2600), 14, [(0, 0), (0.3, 1), (1, 0)])


@S('class/butcher_pain', 'pain')
def _():
    g = zv(0.45, [(0, 105), (1, 75)], [(0, 'uh'), (1, 'o')], 0.68, A_PAIN, **BT)
    return space(mix(g, (chain_rattle(0.4, 30, 1500, 4200) * 0.3, 0.02)), 'room', 0.15)


@S('class/butcher_die', 'death')
def _():
    g = zv(0.8, [(0, 100), (0.3, 90), (1, 40)], [(0, 'a'), (1, 'u')], 0.68, A_DIE, fry=0.3, **BT)
    return space(mix((g, 0), (body_fall(1.5, 0.45, wet=0.4), 0.6), (chain_rattle(0.4, 70, 1500, 4500, [(0, 1), (1, 0)]) * 0.45, 0.62)), 'room', 0.18)


@S('class/butcher_idle', 'idle')
def _():
    br = mix(breath_in(0.4, 0.65, 'o') * 0.4, (zv(0.6, [(0, 68), (1, 60)], [(0, 'o'), (1, 'u')], 0.68, [(0, 0), (0.2, 1), (1, 0)], **BT) * 0.7, 0.4))
    ch = chain_rattle(1.4, 10, 1600, 3800, [(0, 0.3), (0.5, 1), (1, 0.3)]) * 0.3
    return space(mix(br, (ch, 0), (hook_creak(0.8) * 0.15, 0.3)), 'room', 0.18)


@S('class/butcher_ability', 'ability')
def _():
    # et kancasi atisi: efor 'HUAH' + zincir savrulmasi
    g = zv(0.4, [(0, 90), (0.4, 140), (1, 110)], [(0, 'uh'), (0.4, 'A'), (1, 'a')], 0.68, [(0, 0), (0.15, 1), (1, 0)], **BT)
    sw = swish(0.45, 300, 2500, 0.5)
    ch = chain_rattle(0.6, 60, 1500, 4500, [(0, 0.3), (0.3, 1), (1, 0.2)]) * 0.5
    return space(mix((g, 0), (sw, 0.2), (ch, 0.25)), 'room', 0.15)


# ---------- 13 HUNTER: vahsi tiz ciglik ----------
HN = dict(rough=0.5, rr_=55, breath=0.9, vib=(14, 0.4), drive=2.0, jit=0.06, sub=0.2)


@S('class/hunter_pain', 'pain')
def _():
    return space(shriek(0.35, [(0, 600), (0.3, 780), (1, 520)], ('a', 'e'), 1.1, amp=A_PAIN, **HN), 'room', 0.15)


@S('class/hunter_die', 'death')
def _():
    s = shriek(1.0, [(0, 700), (0.3, 640), (1, 180)], ('e', 'a', 'u'), 1.1, amp=A_DIE, **HN)
    return space(mix(s, (body_fall(0.7, 0.6), 0.95)), 'room', 0.18)


@S('class/hunter_idle', 'idle')
def _():
    g = zv(1.0, [(0, 140), (1, 120)], [(0, 'uh'), (1, 'e')], 0.9, [(0, 0), (0.2, 0.7), (1, 0)], rough=0.6, rr_=35, drive=1.4)
    sc = shriek(0.35, [(0, 500), (1, 700)], ('a', 'e'), 1.1, amp=[(0, 0), (0.3, 1), (1, 0)], **HN) * 0.6
    clicks = mix(*[(knock(U(2000, 3000), 0.05, 0.004, False) * 0.3, 0.2 + 0.05 * i) for i in range(4)])
    return space(mix((g, 0), (clicks, 0), (sc, 0.95)), 'room', 0.15)


@S('class/hunter_ability', 'ability')
def _():
    # atilma: gerilen hirilti -> sicrama ciglik -> ruzgar
    g = zv(0.4, [(0, 130), (1, 170)], 'uh', 0.9, [(0, 0), (0.5, 1), (1, 0.5)], rough=0.7, rr_=40, drive=1.6)
    s = shriek(0.5, [(0, 650), (0.3, 900), (1, 750)], ('a', 'i'), 1.1, amp=[(0, 0), (0.1, 1), (1, 0)], **HN)
    return space(mix((g, 0), (s, 0.35), (swish(0.55, 400, 4500, 0.4) * 0.7, 0.4)), 'room', 0.15)


@S('class/hunter_impact', 'extra')
def _():
    slam = mix(thump(0.45, 65, 0.08), (flesh_hit(0.35) * 0.7, 0))
    rake = mix(*[(scrape(0.12, U(1500, 2500), U(2500, 3500)) * 0.5, 0.05 + 0.06 * i) for i in range(3)])
    sc = shriek(0.3, [(0, 800), (1, 650)], ('a', 'e'), 1.1, amp=[(0, 0), (0.1, 1), (1, 0)], **HN) * 0.6
    return space(mix((slam, 0), (rake, 0.02), (sc, 0.05), (debris(0.5, 60, 400, 3000, 0.1) * 0.3, 0)), 'room', 0.15)


# ---------- 14 CHARGER: boga bogurmesi ----------
CG = dict(sub=0.35, rough=0.3, rr_=20, jit=0.03, breath=0.4, drive=1.8, octave=0.4, bright=0.08)


def bellow(d, f0, amp=None):
    # burun sesi 'muu' + aci veren sesli harf acilmasi
    return zv(d, f0, [(0, 'n'), (0.2, 'oo'), (0.6, 'o'), (1, 'u')], 0.72, amp, **CG)


def snort(d=0.25):
    s = bp(rr().standard_normal(n_of(d)), 400, 3000) * env_lin([(0, 0), (0.1, 1), (0.4, 0.5), (1, 0)], d)
    return norm(s * (0.6 + 0.4 * np.sin(2 * np.pi * 60 * tt(d))))


@S('class/charger_pain', 'pain')
def _():
    return space(mix(snort(0.2) * 0.5, (zv(0.4, [(0, 120), (1, 90)], [(0, 'A'), (1, 'uh')], 0.72, A_PAIN, **CG), 0.05)), 'room', 0.15)


@S('class/charger_die', 'death')
def _():
    b = bellow(1.1, [(0, 110), (0.3, 105), (1, 45)], A_DIE)
    return space(mix((b, 0), (body_fall(1.5, 0.9), 0.95)), 'room', 0.18)


@S('class/charger_idle', 'idle')
def _():
    return space(mix((snort(0.25), 0, 0.7), (snort(0.22), 0.35, 0.5),
                     (zv(0.7, [(0, 72), (1, 64)], [(0, 'o'), (1, 'u')], 0.72, [(0, 0), (0.2, 1), (1, 0)], **CG) * 0.6, 0.6)), 'room', 0.15)


@S('class/charger_ability', 'ability')
def _():
    # hucum: bogurme + hizlanan agir adimlar + ruzgar
    b = bellow(0.8, [(0, 95), (0.4, 140), (1, 120)], [(0, 0), (0.1, 1), (1, 0)])
    steps = mix(*[(stomp(1.2, 'stone', 0.25) * 0.5, 0.25 + i * (0.16 - i * 0.01)) for i in range(7)])
    return space(mix((snort(0.2) * 0.6, 0), (b, 0.1), (steps, 0), (whoosh(0.9, 300, 2500, 0.8) * 0.4, 0.5)), 'room', 0.15)


@S('class/charger_impact', 'extra')
def _():
    hit = mix(boom(0.8, 110, 40, 0.18), (flesh_hit(0.4), 0), (knock(900, 0.2, 0.02) * 0.6, 0.01), (knock(1300, 0.2, 0.015) * 0.4, 0.02))
    return space(mix(hit, (debris(0.8, 90, 300, 4000, 0.25) * 0.6, 0.02), (zv(0.3, [(0, 130), (1, 90)], 'uh', 0.72, A_PAIN, **CG) * 0.5, 0.08)), 'room', 0.18)


# ---------- 15 ARACHNE: tikirti / orumcek ----------
@S('class/arachne_pain', 'pain')
def _():
    s = insect_scream(0.35, [(0, 900), (1, 700)], amp=A_PAIN, fs=1.25)
    return space(mix(s * 0.8, (chitter(0.35, 70, 2500, 6000) * 0.6, 0)), 'room', 0.15)


@S('class/arachne_die', 'death')
def _():
    ch = chitter(1.2, 50, 2000, 5500, [(0, 1), (1, 0)], burst=(4, 10))
    cr = mix(knock(1800, 0.2, 0.015, False), (knock(2400, 0.2, 0.01, False) * 0.6, 0.05))
    h = hiss(0.8, 1.1, [(0, 0), (0.1, 1), (1, 0)], 'e', 2500) * 0.5
    return space(mix((ch, 0, 0.8), (cr, 0.5), (h, 0.55), (insect_scream(0.5, [(0, 800), (1, 400)], fs=1.25) * 0.5, 0)), 'room', 0.15)


@S('class/arachne_idle', 'idle')
def _():
    d = 1.3
    taps = mix(*[(knock(U(2200, 3500), 0.05, 0.004, False) * 0.3, i * 0.11 + U(0, 0.03)) for i in range(int(d / 0.11) - 1)])
    return space(mix(chitter(d, 45, 2500, 6000, [(0, 0.3), (0.5, 1), (1, 0.4)]) * 0.7, taps), 'room', 0.15)


@S('class/arachne_ability', 'ability')
def _():
    # ag atisi: puskurtme 'thwip' (hizli tarama) + ucan ag
    thw = norm(bp_sweep(rr().standard_normal(n_of(0.25)), 4000, 700, 0.4)) * env_lin([(0, 0), (0.05, 1), (1, 0)], 0.25)
    fly = swish(0.5, 2000, 800, 0.2) * 0.5
    return space(mix((chitter(0.25, 60, 3000, 6000) * 0.4, 0), (thw, 0.15), (fly, 0.25)), 'room', 0.15)


@S('class/arachne_webhit', 'extra')
def _():
    spl = mix(splat(0.35), (crackle(0.4, 80, 1500, 6000) * 0.4, 0))
    tw = sine(sweep(140, 90, 0.6), 0.6) * env_exp(0.6, 0.15) * (1 + 0.3 * np.sin(2 * np.pi * 14 * tt(0.6)))
    return space(mix((spl, 0), (tw * 0.6, 0.02), (squelch(0.4, 600, 1500, 0.6) * 0.4, 0.15)), 'room', 0.15)


# ---------- 16 MAGMA: lav fokurtusu + kukreme ----------
MG = dict(sub=0.4, rough=0.5, rr_=28, jit=0.05, breath=0.9, drive=2.4, octave=0.4, bright=0.15, noisy=0.3)


def lava(d, rate=10):
    return mix(bubbles(d, rate, 60, 200), (crackle(d, 30, 1200, 5000) * 0.4, 0),
               (lp(rr().standard_normal(n_of(d)), 200) * (0.5 + 0.5 * lpnoise(n_of(d), 3)) * 0.25, 0))


@S('class/magma_pain', 'pain')
def _():
    g = zv(0.45, [(0, 115), (0.3, 125), (1, 85)], [(0, 'A'), (1, 'uh')], 0.7, A_PAIN, **MG)
    return space(mix(g, (sizzle(0.4) * 0.35, 0.02)), 'room', 0.15)


@S('class/magma_die', 'death')
def _():
    r = zv(0.8, [(0, 110), (1, 40)], [(0, 'A'), (1, 'u')], 0.7, A_DIE, fry=0.3, **MG)
    return space(mix((r, 0), (sizzle(0.6, [(0, 0), (0.2, 1), (1, 0)]) * 0.45, 0.35), (crackle(0.35, 60, 800, 4000) * 0.5, 0.65), (body_fall(1.2, 0.35), 0.62)), 'room', 0.18)


@S('class/magma_idle', 'idle')
def _():
    return space(mix(lava(1.5, 9), (zv(0.8, [(0, 62), (1, 55)], [(0, 'o'), (1, 'u')], 0.7, [(0, 0), (0.3, 1), (1, 0)], **MG) * 0.5, 0.4)), 'cave', 0.18)


@S('class/magma_ability', 'ability')
def _():
    # lav izi: patlama + fiskiran lav + cizirti
    er = mix(boom(0.7, 90, 40, 0.2) * 0.8, whoosh(0.7, 200, 3000, 0.3))
    return space(mix((er, 0), (lava(1.2, 18) * 0.8, 0.1), (fire(1.0, 200, 4000, 80, [(0, 0), (0.2, 1), (1, 0)]) * 0.5, 0.15)), 'cave', 0.18)


# ---------- 17 VOLT: elektrik vizildamasi ----------
def volt_v(d, f0, seq, amp=None):
    v = zv(d, f0, seq, 0.9, amp, rough=0.2, breath=0.5, drive=1.6)
    return norm(0.55 * v + 0.45 * norm(ring(v, 120)) + 0.25 * elec_buzz(d, 120, 0.5) * curve(amp if amp is not None else 1.0, d))


@S('class/volt_pain', 'pain')
def _():
    return space(mix(zap(0.3, 5000, 400) * 0.6, (volt_v(0.4, [(0, 180), (1, 130)], [(0, 'A'), (1, 'uh')], A_PAIN), 0.02)), 'room', 0.15)


@S('class/volt_die', 'death')
def _():
    v = volt_v(0.9, [(0, 160), (1, 60)], [(0, 'a'), (1, 'u')], A_DIE)
    sp = mix(*[(arc(U(0.08, 0.2)) * U(0.3, 0.7), U(0.0, 1.1)) for _ in range(7)])
    die = elec_buzz(1.2, 120, 0.7, [(0, 1), (1, 0)]) * 0.4
    die = die * env_lin([(0, 1), (1, 0)], 1.2)
    wh = sine(sweep(1800, 60, 1.2), 1.2) * env_lin([(0, 0), (0.05, 0.3), (1, 0)], 1.2)
    return space(mix((v, 0), (sp, 0), (die, 0.2), (wh, 0.2)), 'room', 0.15)


@S('class/volt_idle', 'idle')
def _():
    d = 1.4
    b = elec_buzz(d, 120, 0.5, [(0, 0), (0.2, 1), (0.8, 1), (1, 0)]) * 0.6
    sp = mix(*[(arc(U(0.05, 0.12)) * 0.4, U(0.1, 1.2)) for _ in range(4)])
    return space(mix(b, sp), 'room', 0.15)


@S('class/volt_ability', 'ability')
def _():
    # EMP: yukselen sarj vizlamasi -> bosalma (bum + citirti) -> sonen elektronik
    ch = sine(sweep(200, 3200, 0.5), 0.5) * env_lin([(0, 0), (1, 1)], 0.5) * 0.4 + elec_buzz(0.5, 100, 0.1, [(0, 0), (1, 1)]) * 0.4
    dis = mix(boom(0.5, 120, 40, 0.15), (zap(0.45, 8000, 200) * 0.8, 0), (crackle(0.5, 150, 2000, 9000) * 0.6, 0))
    off = sine(sweep(1200, 80, 0.45), 0.45) * env_lin([(0, 0.4), (1, 0)], 0.45)
    return space(mix((ch, 0), (dis, 0.48), (off, 0.55)), 'hall', 0.2)


@S('class/volt_zap', 'extra')
def _():
    return space(mix(arc(0.4, 90), (zap(0.45, 7000, 300) * 0.8, 0), (elec_buzz(0.5, 120, 0.6, [(0, 1), (1, 0)]) * 0.4, 0.05)), 'room', 0.12)


# ---------- 18 MIMIC: bozuk insan sesi ----------
def speak(text, voice_='mb-us2', speed=130, pitch_=40):
    fd, tmp = tempfile.mkstemp(suffix='.wav')
    os.close(fd)
    try:
        subprocess.run(['espeak-ng', '-v', voice_, '-s', str(speed), '-p', str(pitch_), '-a', '170', text, '-w', tmp],
                       check=True, capture_output=True)
        w = _wave.open(tmp)
        sr = w.getframerate()
        raw = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').astype(float) / 32768.0
        w.close()
    finally:
        os.unlink(tmp)
    x = resample(raw, sr, Ctx.sr) if sr != Ctx.sr else raw
    idx = np.where(np.abs(x) > 0.01)[0]
    return norm(x[idx[0]:idx[-1] + 1]) if len(idx) else x


def corrupt(x, amount=0.5, down=0.0):
    """taklitci bozulmasi: perde dususu, takilma (tekrar eden tane), halka mod, bitcrush"""
    if down:
        x = tstretch_pitch(x, 2 ** (-down / 12))
    n = len(x)
    out = x.copy()
    G = n_of(0.05)
    p = 0
    while p < n - 3 * G:
        if rr().random() < amount * 0.35:
            seg = x[p:p + G] * np.hanning(G)
            for k in range(1, int(rr().integers(2, 4))):
                if p + k * G + G < n:
                    out[p + k * G:p + k * G + G] = out[p + k * G:p + k * G + G] * 0.3 + seg
            p += 3 * G
        else:
            p += G
    y = (1 - amount * 0.4) * out + amount * 0.4 * norm(ring(out, 47))
    return norm(dist(bitcrush(y, 7) * (1 + amount * 2), 1.2))


@S('class/mimic_pain', 'pain')
def _():
    h = speak('ah', 'mb-us2', 160, 55)
    return space(mix(corrupt(at(h, 0.3), 0.6, 2) * 0.8, (zv(0.35, [(0, 150), (1, 110)], 'A', 0.8, A_PAIN) * 0.5, 0.05)), 'room', 0.15)


@S('class/mimic_die', 'death')
def _():
    h = speak('no no', 'mb-us2', 120, 40)
    hc = corrupt(h, 0.5, 3)[:n_of(0.55)]
    g = zv(0.6, [(0, 120), (1, 45)], [(0, 'o'), (1, 'u')], 0.75, A_DIE, fry=0.3)
    return space(mix((fade(hc, 0.002, 0.06), 0, 0.8), (g, 0.42), (body_fall(0.9, 0.35, wet=0.4), 0.85)), 'room', 0.15)


@S('class/mimic_idle', 'idle')
def _():
    h = speak('help me', 'mb-us2', 115, 45)
    c = corrupt(h, 0.6, 4)
    return space(mix(c, (zv(0.5, 80, 'o', 0.75, [(0, 0), (0.3, 1), (1, 0)]) * 0.35, len(c) / Ctx.sr - 0.1)), 'room', 0.2)


@S('class/mimic_ability', 'ability')
def _():
    # kilik: et sesi + hirilti -> yumusayan (temizlenen) insan sesine donus
    g = zv(0.6, [(0, 90), (1, 150)], [(0, 'uh'), (1, 'a')], 0.75, [(0, 0), (0.3, 1), (1, 0)])
    h = speak('hey', 'mb-us2', 140, 50)
    hc = corrupt(h, 0.15, 0)
    return space(mix((squelch(0.5, 400, 1400) * 0.6, 0), (reverse(g) * 0.7, 0.1), (hc, 0.65)), 'room', 0.2)


@S('class/mimic_reveal', 'extra')
def _():
    h = speak('gotcha', 'mb-us2', 150, 45)
    tear = mix(squelch(0.4, 1500, 300), (flesh_hit(0.3) * 0.6, 0.05))
    r = zv(0.8, [(0, 130), (0.3, 170), (1, 120)], [(0, 'a'), (0.3, 'A'), (1, 'a')], 0.75, [(0, 0), (0.1, 1), (1, 0)], drive=2.4, octave=0.4)
    hc = corrupt(h, 0.7, 1)
    return space(mix((hc, 0, 0.8), (tear, len(hc) / Ctx.sr * 0.7), (r, len(hc) / Ctx.sr * 0.75)), 'room', 0.18)


# ---------- 19 BURROWER: toprak gurultusu ----------
BR = dict(sub=0.35, rough=0.4, rr_=22, jit=0.05, breath=0.5, drive=1.8, octave=0.35)


def dirt(d, density=120):
    return mix(debris(d, density, 200, 3000, d / 2, 0.8), (lp(noise(d, 'brown'), 200) * env_lin([(0, 0), (0.2, 1), (1, 0)], d) * 0.6, 0))


@S('class/burrower_pain', 'pain')
def _():
    g = zv(0.45, [(0, 110), (1, 80)], [(0, 'uh'), (1, 'o')], 0.72, A_PAIN, **BR)
    return space(mix(g, (debris(0.3, 80, 400, 3000, 0.08) * 0.4, 0)), 'room', 0.15)


@S('class/burrower_die', 'death')
def _():
    g = zv(0.8, [(0, 105), (1, 42)], [(0, 'a'), (1, 'u')], 0.72, A_DIE, fry=0.3, **BR)
    return space(mix((g, 0), (dirt(0.5, 150), 0.5), (body_fall(1.2, 0.4), 0.6)), 'room', 0.15)


@S('class/burrower_idle', 'idle')
def _():
    d = 1.4
    scr = mix(*[(grind(0.18, 300, 3000, 30) * 0.5, 0.15 + i * 0.3) for i in range(4)])
    return space(mix(rumble(d, 100) * 0.5, scr, (zv(0.5, 70, 'u', 0.72, [(0, 0), (0.3, 1), (1, 0)], **BR) * 0.35, 0.8)), 'room', 0.15)


@S('class/burrower_ability', 'ability')
def _():
    # topraga dalis: kazma patlamasi + alcalan toprak gurultusu
    d = 1.3
    dig = mix(*[(grind(0.15, 200, 2500, 40) * 0.6, i * 0.1) for i in range(4)])
    dn = rumble(d, 160, [(0, 0), (0.15, 1), (1, 0)]) * 0.8
    return space(mix((dig, 0), (dirt(0.8, 160), 0.2), (dn, 0.2), (thump(0.4, 55, 0.1), 0.3)), 'cave', 0.2)


@S('class/burrower_erupt', 'extra')
def _():
    return space(mix(boom(1.0, 90, 30, 0.25), (stone_impact(1.0, 1.3) * 0.8, 0), (dirt(1.2, 200) * 0.8, 0.05),
                     (whoosh(0.6, 200, 2500, 0.2) * 0.4, 0)), 'cave', 0.2)


# ---------- 20 SIREN: urkutucu sarki ----------
def siren_song(d, notes, seq=('a', 'o'), fs=1.25, amp=None, vib=(5.5, 0.35)):
    """yumusak kadin sesi: legato nota gecisleri (portamento) + vibrato + nefes"""
    k = len(notes)
    pts = []
    for i, f in enumerate(notes):
        a, b = i / k, (i + 1) / k
        pts += [(a + 0.04 / k, f), (b - 0.02 / k, f)]
    pts = [(0, notes[0])] + pts + [(1, notes[-1])]
    sq = [(i / max(1, len(seq) - 1), v) for i, v in enumerate(seq)]
    v = voice(d, pts, sq, fs, 0.006, 0.03, 0, 0, 0.5, 0.35, vib=vib, amp=amp, parallel=True)
    v2 = voice(d, [(t, f * 1.006) for t, f in pts], sq, fs * 1.02, 0.006, 0.03, 0, 0, 0.5, 0.35, vib=(vib[0] * 1.1, vib[1]),
               amp=amp, parallel=True)
    return norm(v + 0.6 * v2)


@S('class/siren_pain', 'pain')
def _():
    s = siren_song(0.4, [740, 880, 620], ('a', 'e', 'a'), 1.25, A_PAIN, (9, 0.5))
    return space(s, 'hall', 0.3)


@S('class/siren_die', 'death')
def _():
    s = siren_song(1.3, [880, 830, 700, 520, 330], ('a', 'o', 'u'), 1.25, A_DIE, (6, 0.6))
    return space(flanger(s, 0.5, 0.003, 0.5, 0.4), 'ghost', 0.42)


@S('class/siren_idle', 'idle')
def _():
    s = siren_song(1.15, [440, 523.3, 493.9, 392.0], ('u', 'u', 'o'), 1.2, [(0, 0), (0.2, 0.9), (0.8, 1), (1, 0)])
    return space(s, 'ghost', 0.42)


@S('class/siren_ability', 'ability')
def _():
    # ninni: hipnotik melodi + armoni (kucuk uclu) + parilti
    d = 1.15
    a = siren_song(d, [659.3, 784.0, 880.0, 784.0, 659.3, 587.3], ('a', 'o', 'a'), 1.25, [(0, 0), (0.1, 1), (0.85, 1), (1, 0)])
    b = siren_song(d, [523.3, 659.3, 698.5, 659.3, 523.3, 493.9], ('o', 'u', 'o'), 1.2, [(0, 0), (0.15, 0.7), (0.85, 0.7), (1, 0)])
    pad_ = pad([220.0, 329.6], d, 0.4, 0.5, bright=1500) * 0.6
    return space(mix(a, (b, 0, 0.6), (pad_, 0), (tinkle(d, 12, 3000, 7000) * 0.15, 0)), 'ghost', 0.4)


# ---------- 21 BULWARK: tas surtunmesi ----------
BW = dict(sub=0.5, rough=0.35, rr_=18, jit=0.03, breath=0.4, drive=1.8, octave=0.5)


@S('class/bulwark_pain', 'pain')
def _():
    g = zv(0.45, [(0, 90), (1, 66)], [(0, 'uh'), (1, 'o')], 0.62, A_PAIN, **BW)
    return space(mix(stone_impact(0.4, 0.5) * 0.6, (g, 0.02, 0.8)), 'room', 0.15)


@S('class/bulwark_die', 'death')
def _():
    g = zv(0.75, [(0, 85), (1, 35)], [(0, 'o'), (1, 'u')], 0.62, A_DIE, fry=0.3, **BW)
    crumble = mix(grind(0.35, 150, 2500, 25) * 0.5, (stone_impact(0.6, 1.4), 0.2), (debris(0.6, 160, 300, 5000, 0.2) * 0.6, 0.22))
    return space(mix((g, 0), (crumble, 0.35)), 'room', 0.18)


@S('class/bulwark_idle', 'idle')
def _():
    d = 1.5
    return space(mix(grind(d, 120, 1800, 12, [(0, 0), (0.3, 0.8), (0.7, 0.8), (1, 0)]) * 0.6,
                     (zv(0.8, 55, [(0, 'o'), (1, 'u')], 0.62, [(0, 0), (0.3, 1), (1, 0)], **BW) * 0.5, 0.5)), 'room', 0.18)


@S('class/bulwark_ability', 'ability')
def _():
    # tahkim: tas plakalar surtunur ve 3 agir 'klonk' ile kilitlenir + alcak ugultu
    gr = grind(0.45, 150, 2200, 22)
    cl = mix(*[(stone_impact(0.3, 0.8) * 0.8, 0.33 + 0.15 * i) for i in range(3)])
    hum = (sine(73.4, 0.5) + 0.4 * sine(110, 0.5)) * env_lin([(0, 0), (0.3, 1), (1, 0)], 0.5) * 0.4
    return space(mix((gr, 0, 0.6), (cl, 0), (hum, 0.45)), 'room', 0.2)


# ---------- 22 SPOREMOTHER: spor puflamasi ----------
@S('class/sporemother_pain', 'pain')
def _():
    g = zv(0.4, [(0, 170), (1, 120)], [(0, 'e'), (1, 'o')], 0.9, A_PAIN, rough=0.6, rr_=40, breath=0.6, drive=1.3, octave=0.15)
    return space(mix(puff(0.3, 400, 2500) * 0.6, (g, 0.03, 0.8)), 'room', 0.15)


@S('class/sporemother_die', 'death')
def _():
    puffs = mix(*[(puff(0.35, 300, 2200) * U(0.4, 0.8), 0.1 + i * U(0.12, 0.2)) for i in range(5)])
    g = gurgle(1.0, [(0, 130), (1, 55)], 0.9, A_DIE)
    return space(mix((g, 0, 0.8), (puffs, 0.2), (hiss(0.8, 1.0, [(0, 0), (0.1, 1), (1, 0)], 'u', 1500) * 0.3, 0.6)), 'room', 0.18)


@S('class/sporemother_idle', 'idle')
def _():
    d = 1.4
    puffs = mix(*[(puff(0.3, 400, 2000) * U(0.3, 0.6), 0.1 + i * 0.4 + U(0, 0.1)) for i in range(3)])
    return space(mix(puffs, (gurgle(0.9, 95, 0.9, [(0, 0), (0.4, 1), (1, 0)]) * 0.45, 0.3)), 'room', 0.15)


@S('class/sporemother_ability', 'ability')
def _():
    # spor kesesi dikme: islak gomme + siskinlik + yumusak 'pop'
    plant = mix(squelch(0.4, 400, 1200) * 0.8, (thump(0.3, 70, 0.05) * 0.6, 0.05))
    infl = creak(0.4, 15, 60, (250, 700), 8) * 0.3
    return space(mix((plant, 0), (infl, 0.3), (puff(0.35, 500, 3000), 0.7)), 'room', 0.15)


@S('class/sporemother_burst', 'extra')
def _():
    b = mix(boom(0.6, 130, 50, 0.12) * 0.6, (puff(0.5, 300, 3500), 0), (splat(0.4) * 0.5, 0))
    cloud = hiss(1.2, 0.9, [(0, 0), (0.1, 1), (1, 0)], 'u', 1200) * 0.5
    return space(mix((b, 0), (cloud, 0.05), (bubbles(0.8, 20, 300, 1200) * 0.25, 0.05)), 'room', 0.2)


# ---------- 23 NIGHTMARE: derin seytani fisilti ----------
def demon_whisper(d, count=6, down=7):
    w = whispers(d * 2 ** (down / 12), count, 0.95, sib=0.5)
    w = tstretch_pitch(w, 2 ** (-down / 12))
    return at(w, d)


@S('class/nightmare_pain', 'pain')
def _():
    s = unvoiced(0.4, [(0, 'A'), (1, 'uh')], 0.7, amp=A_PAIN)
    v = zv(0.4, [(0, 80), (1, 60)], 'A', 0.65, A_PAIN, rough=0.6, drive=2.2, octave=0.5) * 0.5
    return space(mix(s, v), 'hall', 0.3)


@S('class/nightmare_die', 'death')
def _():
    sc = zv(0.85, [(0, 60), (1, 160)], [(0, 'u'), (1, 'A')], 0.68, [(0, 0), (0.7, 0.8), (0.95, 1), (1, 0)], rough=0.5, drive=2.0, octave=0.5)
    return space(mix(reverse(sc), (demon_whisper(0.8, 4) * 0.5, 0.15), (boom(0.45, 60, 25, 0.15) * 0.5, 0.62)), 'hall', 0.35)


@S('class/nightmare_idle', 'idle')
def _():
    d = 1.15
    return space(mix(demon_whisper(d, 5), (heartbeat(d, 62, 42) * 0.35, 0), (sine(36.7, d) * env_lin([(0, 0), (0.5, 0.3), (1, 0)], d), 0)), 'hall', 0.35)


@S('class/nightmare_ability', 'ability')
def _():
    # dehset: ters emilim + alt frekans darbe + fisilti korosu + uyumsuz tiz ciglik
    rv = reverse_swell(0.5, 200, 6000)
    hit = boom(0.5, 60, 22, 0.2)
    wh = mix(*[(demon_whisper(0.5, 3, U(4, 10)) * 0.4, 0) for _ in range(3)])
    sc = shriek(0.45, [(0, 1600), (1, 1500)], ('i', 'e'), 1.3, 0.4, (13, 0.8), 1.6, amp=[(0, 0), (0.2, 0.5), (1, 0)])
    return space(mix((rv, 0), (hit, 0.47), (wh, 0.48), (sc * 0.4, 0.5)), 'hall', 0.35)


# ======================================================================
# KANCA (Butcher): sound/vexmira/hook/
# ======================================================================
@S('hook/throw', 'hook')
def _():
    w = swish(0.55, 300, 3500, 0.35)
    unc = chain_rattle(0.6, 70, 1800, 5000, [(0, 1), (1, 0.3)])
    return space(mix((w, 0), (unc * 0.6, 0.05), (metal_hit(900, 0.3, 0.1, 'bar') * 0.3, 0)), 'room', 0.12)


@S('hook/chain', 'hook')
def _():
    d = 0.9
    ch = chain_rattle(d, 90, 1600, 5200, [(0, 0.6), (0.2, 1), (0.8, 1), (1, 0)])
    zip_ = bp(rr().standard_normal(n_of(d)), 1500, 6000) * env_lin([(0, 0), (0.2, 0.3), (0.8, 0.3), (1, 0)], d)
    return space(mix(ch, norm(zip_) * 0.25), 'room', 0.1)


@S('hook/hit', 'hook')
def _():
    thunk = mix(metal_hit(600, 0.4, 0.12, 'plate') * 0.6, (thump(0.3, 90, 0.05), 0))
    return space(mix((thunk, 0), (flesh_hit(0.35), 0.0), (squelch(0.35, 1500, 300, 0.6) * 0.7, 0.02),
                     (chain_rattle(0.35, 60, 1800, 4500, [(0, 1), (1, 0)]) * 0.5, 0.06)), 'room', 0.12)


@S('hook/pull', 'hook')
def _():
    # makara / mandal tiklamalari + zincir surtunmesi + gerilme gicirtisi
    d = 1.2
    ticks = mix(*[(metal_hit(U(1800, 2200), 0.08, 0.02, 'bar') * 0.6, i * 0.07) for i in range(int(d / 0.07) - 1)])
    drag = chain_rattle(d, 60, 1500, 4000, [(0, 0.5), (0.5, 1), (1, 0.3)]) * 0.5
    st = creak(d, 18, 30, (300, 800, 1900), 10, [(0, 0), (0.3, 1), (1, 0)]) * 0.3
    return space(mix(ticks, drag, st), 'room', 0.12)


@S('hook/miss', 'hook')
def _():
    w = swish(0.35, 400, 3000, 0.5)
    cl = mix(metal_hit(700, 0.5, 0.15, 'plate'), (metal_hit(1100, 0.3, 0.08, 'plate') * 0.5, 0.18), (metal_hit(900, 0.2, 0.06, 'plate') * 0.3, 0.3))
    return space(mix((w, 0), (cl, 0.28), (chain_rattle(0.4, 50, 1500, 4000, [(0, 1), (1, 0)]) * 0.5, 0.3), (debris(0.4, 60, 500, 4000, 0.1) * 0.3, 0.3)), 'room', 0.12)


# ======================================================================
# ARAYUZ (2D, precache_generic + spk): sound/vexmira/ui/
# ======================================================================
@S('ui/vote_start', 'ui', loud=-16.5)
def _():
    # harita oylamasi basliyor: mor/cyan marka akoru + iki notali fanfar + yumusak darbe
    st = chord_stab([293.7, 370.0, 440.0, 587.3], 0.75, 5000, 900) * 0.6
    b1 = bell(880.0, 0.6, 2.0, 1.5, 0.25) * 0.5
    b2 = bell(1318.5, 0.5, 2.0, 1.5, 0.22) * 0.5
    return space(mix((boom(0.5, 120, 50, 0.1) * 0.5, 0), (st, 0), (b1, 0.0), (b2, 0.14), (tinkle(0.5, 8, 4000, 8000) * 0.15, 0.15)), 'room', 0.2)


@S('ui/vote_end', 'ui', loud=-16.5)
def _():
    # oylama bitti: tokmak vurusu + cozulen akor
    gavel = mix(knock(520, 0.2, 0.03), (thump(0.2, 90, 0.04) * 0.6, 0))
    ch = mix(*[(chime(f, 0.6, 0.25) * 0.4, 0.12 + 0.05 * i) for i, f in enumerate([587.3, 740.0, 880.0, 1174.7])])
    return space(mix((gavel, 0), (ch, 0)), 'room', 0.2)


@S('ui/boss_bar', 'ui', loud=-16.0)
def _():
    # boss can bari belirdi: agir alt darbe + metal cinlama + kisa uyumsuz 'braam'
    d = 0.7
    hit = thump(0.5, 48, 0.12)
    br = braam(55, d, 3.0) * 0.35
    mt = metal_hit(330, 0.6, 0.25, 'bell') * 0.3
    return space(mix((hit, 0), (br, 0.0), (mt, 0.0)), 'arena', 0.18)


@S('ui/menu_select', 'ui', loud=-20.0)
def _():
    return mix(hp(rr().standard_normal(n_of(0.006)), 3000) * env_exp(0.006, 0.0015) * 0.5, (beep(1567.98, 0.06, 'tri') * 0.6, 0.004),
               (beep(2349.3, 0.06, 'sine') * 0.3, 0.035))


@S('ui/class_select', 'ui', loud=-17.0)
def _():
    # sinif secildi: kisa organik hirilti + yukselen parilti
    g = zv(0.3, [(0, 110), (1, 150)], 'A', 0.8, [(0, 0), (0.2, 1), (1, 0)], drive=1.8) * 0.5
    up = mix(*[(chime(f, 0.4, 0.15) * 0.4, 0.15 + 0.05 * i) for i, f in enumerate([523.3, 784.0, 1046.5])])
    return space(mix((swish(0.3, 500, 4000, 0.7) * 0.4, 0), (g, 0.0), (up, 0)), 'room', 0.2)


# ======================================================================
# uretim
# ======================================================================

def render(rel):
    fn, sr, loud, mx, mn = R[rel]
    L.reseed(zlib.crc32(rel.encode()) & 0x7fffffff)
    _DRY[0] = 0.0
    _CAP[0] = mx
    try:
        x = fn()
    except Exception:
        import traceback
        tb = traceback.format_exc().strip().splitlines()
        return rel, -1.0, sr, 0, ' | '.join(l.strip() for l in tb[-4:])
    # dogal uzunluk (kuyruk -46 dB) / tavan orani: bestenin tavana sigip sigmadigini gormek icin
    nat = _DRY[0]
    if os.environ.get('VEX_NAT') and nat > mx * 0.95:
        print(f'  uzun: {rel} kuru {nat:.2f}s > tavan {mx:.2f}s')
    path = os.path.join(OUT, rel + '.wav')
    dur = write_wav3(path, x, sr, loud=loud, max_len=mx, min_len=mn)
    return rel, round(dur, 2), sr, os.path.getsize(path), ''


def main():
    sel = [a for a in sys.argv[1:] if not a.startswith('-')]
    names = [k for k in R if not sel or k in sel or any(k.startswith(s) for s in sel)]
    try:
        from multiprocessing import Pool
        with Pool(min(4, os.cpu_count() or 1)) as pool:
            res = pool.map(render, names, chunksize=1)
    except Exception as e:
        print('paralel uretim basarisiz, seri devam:', e)
        res = [render(n) for n in names]
    total, errs = 0, 0
    for rel, dur, sr, sz, err in sorted(res):
        total += sz
        if err:
            errs += 1
            print(f'HATA {rel}: {err}')
        else:
            print(f'{rel:32} {dur:5.2f}s {sr:5}Hz {sz // 1024:4} KB')
    print(f'TOPLAM {len(res) - errs} ses, {total / 1048576:.2f} MiB, hata {errs}')
    sys.exit(1 if errs else 0)


if __name__ == '__main__':
    main()
