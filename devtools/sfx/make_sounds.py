# Vexmira v2.0 ozel ses paketi uretici (hepsi dongusuz, mono 16 bit)
import os, sys, subprocess, json
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from sfx_lib import *

OUT = sys.argv[1] if len(sys.argv) > 1 else '/home/user/claude/cstrike/sound/vexmira'
LO, HI = 11025, 22050   # dusuk frekansli sesler 11025 Hz (dosya boyutu yarisi)

R = {}  # ad -> (fonksiyon, ornekleme)


LOUD = {}
for _n in ('ui_open', 'tick', 'deny', 'nade_mode', 'nade_beep', 'nade_arm', 'nade_trigger', 'lm_pickup', 'lm_deploy',
           'zone_warn', 'join', 'leave', 'buy', 'lm_activate', 'lm_hit'):
    LOUD[_n] = -19.0
LOUD.update({'ambient': -24.0, 'wind': -21.0, 'heartbeat': -13.0, 'boss_step': -18.0, 'lm_charge': -20.0,
             'burn': -18.0, 'freeze': -17.0, 'zap': -17.0, 'storm_orb': -17.0, 'welcome': -18.0})


BIG = {'boss_spawn', 'boss_death', 'final_round', 'mode_start', 'inferno_nova', 'map_end', 'win_humans', 'win_zombies',
       'boss_enrage', 'void_horizon', 'round_start', 'boss_intro', 'boss_soon', 'banshee_requiem', 'storm_tempest', 'thunder'}


def snd(name, sr=HI):
    def deco(f):
        R[name] = (f, sr)
        return f
    return deco


# ======================= ARAYUZ / EKONOMI =======================

@snd('ui_open')
def _():
    return mix(beep(880, 0.06), (beep(1320, 0.08), 0.05, 0.8))


@snd('tick')
def _():
    return mix(beep(1000, 0.07, 'tri'), (hp(noise(0.01), 3000), 0, 0.5))


@snd('deny')
def _():
    return mix(beep(330, 0.11, 'square') * 0.6, (beep(220, 0.16, 'square') * 0.6, 0.12))


@snd('buy')
def _():
    d = 0.7
    a = bell(1760, d, 1.41, 1.2, 0.18)
    b = bell(2637, d, 1.41, 1.2, 0.22)
    sh = hp(noise(0.35), 6000) * env_exp(0.35, 0.08) * 0.35
    return mix((a, 0, 0.7), (b, 0.07, 0.7), (sh, 0.06))


@snd('levelup', LO)
def _():
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
    parts = [(chime(f, 0.9, 0.35), i * 0.09, 0.6) for i, f in enumerate(notes)]
    sp = tinkle(1.2, 18, 3000, 8000) * 0.25
    return reverb(mix(*parts, (sp, 0.3), (pad([261.6, 329.6, 392.0], 1.3, 0.05, 0.6, bright=3500) * 0.5, 0.35)), 1.2, 0.3)


@snd('achievement', LO)
def _():
    notes = [392.0, 523.25, 659.25, 783.99]
    parts = [(chime(f, 1.0, 0.4), i * 0.11, 0.6) for i, f in enumerate(notes)]
    stab = chord_stab([523.25, 659.25, 783.99, 1046.5], 1.4, 5000, 900) * 0.7
    return reverb(mix(*parts, (stab, 0.44), (timpani(98, 1.2) * 0.5, 0.44)), 1.4, 0.3)


@snd('daily')
def _():
    parts = [(chime(f, 0.8, 0.3), i * 0.05, 0.5) for i, f in enumerate([1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0])]
    return reverb(mix(*parts), 1.0, 0.3)


@snd('quest_done')
def _():
    parts = [(bell(f, 0.9, 2.0, 1.5, 0.3), i * 0.12, 0.6) for i, f in enumerate([659.25, 830.6, 987.8])]
    return reverb(mix(*parts), 1.0, 0.25)


@snd('mvp', LO)
def _():
    st = chord_stab([261.6, 329.6, 392.0, 523.25], 1.8, 5200, 700)
    st2 = chord_stab([349.2, 440.0, 523.25, 698.5], 1.5, 5200, 700)
    return reverb(mix((st, 0, 0.8), (st2, 0.35, 0.9), (timpani(65, 1.6), 0.0, 0.7), (timpani(87, 1.4), 0.35, 0.6),
                      (tinkle(1.2, 20, 3000, 8000) * 0.2, 0.4)), 1.6, 0.3)


@snd('vip_join', LO)
def _():
    p = pad([392.0, 493.9, 587.3, 784.0], 1.8, 0.15, 0.8, bright=4000)
    return reverb(mix(p, (tinkle(1.5, 24, 3500, 9000) * 0.3, 0.1), (bell(1568, 1.2, 3.5, 2, 0.5) * 0.4, 0.2)), 1.5, 0.35)


@snd('welcome', LO)
def _():
    p = pad([220.0, 277.2, 329.6, 440.0], 2.4, 0.6, 1.0, bright=2500)
    return reverb(mix(p, (chime(880, 1.4, 0.5) * 0.5, 0.5), (chime(1318.5, 1.4, 0.5) * 0.4, 0.8)), 1.8, 0.35)


@snd('join')
def _():
    return reverb(mix(chime(784, 0.4, 0.15) * 0.6, (chime(1175, 0.5, 0.18) * 0.6, 0.08)), 0.6, 0.25)


@snd('leave')
def _():
    return reverb(mix(chime(1175, 0.4, 0.15) * 0.6, (chime(784, 0.5, 0.18) * 0.6, 0.08)), 0.6, 0.25)


@snd('skill_unlock')
def _():
    r = riser(0.9, 300, 3000) * 0.6
    hit = mix(boom(1.2, 120, 45, 0.3) * 0.8, (chime(1046.5, 1.0, 0.4) * 0.5, 0), (chime(1568, 1.0, 0.4) * 0.4, 0.05))
    return reverb(mix(r, (hit, 0.85), (tinkle(1.2, 20) * 0.25, 0.85)), 1.3, 0.3)


@snd('zone_warn')
def _():
    a = square(sweep(700, 950, 0.16), 0.16, 9) * env_adsr(0.16, 0.005, 0.03, 0.8, 0.03) * 0.5
    return mix(a, (a, 0.18))


@snd('boss_warn')
def _():
    d = 0.42
    k = saw(sweep(320, 470, d, 'lin'), d, 20) * env_adsr(d, 0.01, 0.05, 0.9, 0.05)
    k = lp(dist(k, 2), 3000)
    return reverb(mix(k, (k, 0.46)), 0.8, 0.2)


# ======================= ROUND / MOD / EVENT =======================

@snd('round_start', LO)
def _():
    return reverb(mix(braam(55, 2.6, 2.0), (riser(1.2, 150, 1200) * 0.5, 0.0), (boom(1.6, 70, 30, 0.5), 0.05)), 2.0, 0.35)


@snd('mode_start', LO)
def _():
    b = braam(41.2, 3.0, 3.5)
    return reverb(mix(b, (boom(2.0, 65, 25, 0.6), 0.02), (crack(0.4, 800, 6000) * 0.5, 0.02)), 2.2, 0.35)


@snd('event_start', LO)
def _():
    r = reverse(hp(noise(1.2, 'pink'), 2500) * env_exp(1.2, 0.35)) * 0.8
    return reverb(mix(r, (boom(1.6, 110, 35, 0.4), 1.15), (crack(0.3) * 0.6, 1.15), (riser(1.2, 300, 2500) * 0.4, 0)), 1.6, 0.3)


@snd('final_round', LO)
def _():
    b = braam(36.7, 3.5, 3.0)
    bells = mix(*[(bell(f, 2.5, 3.5, 3, 0.9) * 0.4, i * 0.6) for i, f in enumerate([220, 207.6, 196])])
    return reverb(mix(b, (bells, 0.2), (boom(2.5, 60, 22, 0.8), 0)), 2.5, 0.4)


@snd('map_end', LO)
def _():
    a = chord_stab([261.6, 329.6, 392.0], 1.2, 5000, 900)
    b = chord_stab([349.2, 440.0, 523.25], 1.2, 5000, 900)
    c = chord_stab([392.0, 493.9, 587.3, 784.0], 2.0, 6000, 900)
    return reverb(mix(a, (b, 0.6), (c, 1.2), (timpani(65, 1.5) * 0.7, 0), (timpani(98, 1.5) * 0.7, 1.2),
                      (tinkle(1.5, 25) * 0.25, 1.25)), 1.8, 0.35)


@snd('last_human', LO)
def _():
    d = 2.6
    x = np.zeros(n_of(d))
    for f in (146.8, 155.6, 220.0, 233.1):
        x += saw(f, d, 25) * (1 + 0.3 * np.sin(2 * np.pi * 5.5 * tt(d)))
    x = lp(x, 2200) * env_lin([(0, 0), (0.15, 1), (0.8, 0.8), (1, 0)], d) / 4
    hb = mix(thump(0.4, 50), (thump(0.4, 45) * 0.7, 0.22), (thump(0.4, 50), 0.9), (thump(0.4, 45) * 0.7, 1.12))
    return reverb(mix(x, (hb, 0.1, 1.2)), 1.6, 0.3)


@snd('ambient', LO)
def _():
    d = 7.0
    t = tt(d)
    drone = (sine(55, d) * 0.5 + sine(82.4 * (1 + 0.003 * np.sin(2 * np.pi * 0.2 * t)), d) * 0.35 + sine(116.5, d) * 0.15)
    wind = bp_sweep(noise(d, 'pink'), 300, 900, 0.5) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.25 * t)) * 0.6
    creak = mix((bp(saw(sweep(180, 140, 1.0), 1.0, 20), 300, 2500) * env_lin([(0, 0), (0.2, 1), (1, 0)], 1.0) * 0.3, 3.2))
    x = mix(drone * env_lin([(0, 0), (0.2, 1), (0.8, 1), (1, 0)], d), wind * env_lin([(0, 0), (0.3, 1), (1, 0)], d), creak)
    return reverb(x, 2.0, 0.4)


@snd('heartbeat', LO)
def _():
    # TEK kalp atisi (lub-dub), dongusuz
    return mix(thump(0.35, 48, 0.09), (thump(0.35, 42, 0.08) * 0.75, 0.2))


@snd('thunder_crack', LO)
def _():
    c = hp(noise(0.25), 1500) * env_exp(0.25, 0.04)
    c2 = crackle(0.4, 80, 800, 7000) * 0.6
    rumble = lp(noise(2.6, 'brown'), 250) * env_lin([(0, 0), (0.05, 1), (1, 0)], 2.6) * tremolo(np.ones(n_of(2.6)), 7, 0.5)
    return reverb(mix(c, (c2, 0.02), (rumble, 0.05, 1.3)), 1.8, 0.3)


@snd('thunder', LO)
def _():
    d = 3.5
    x = lp(noise(d, 'brown'), 300) * tremolo(np.ones(n_of(d)), 3.5, 0.6)
    x *= env_lin([(0, 0), (0.08, 1), (0.4, 0.8), (1, 0)], d)
    return reverb(mix(x, (hp(noise(0.2), 1000) * env_exp(0.2, 0.05) * 0.5, 0)), 2.0, 0.3)


@snd('wind', LO)
def _():
    d = 3.0
    x = bp_sweep(noise(d, 'pink'), 250, 1600, 0.4) * env_lin([(0, 0), (0.5, 1), (1, 0)], d)
    return x


@snd('speed_start', LO)
def _():
    d = 1.6
    t = tt(d)
    tur = saw(sweep(80, 900, d), d, 14) * 0.4
    x = mix(lp(tur, 4000), whoosh(d, 300, 5000, 0.85) * 0.9)
    return reverb(x * env_lin([(0, 0), (0.85, 1), (1, 0)], d), 0.8, 0.2)


@snd('blackout', LO)
def _():
    d = 1.4
    hum = (saw(120, d, 20) * 0.3 + sine(sweep(400, 35, d), d) * 0.6) * env_lin([(0, 1), (1, 0)], d)
    clk = mix(hp(noise(0.03), 2000) * 0.8, (hp(noise(0.03), 2000) * 0.5, 0.06))
    return reverb(mix(clk, (lp(hum, 2000), 0.02)), 1.0, 0.25)


@snd('meteor', LO)
def _():
    d = 1.3
    whistle = sine(sweep(2200, 300, d), d) * env_lin([(0, 0), (0.3, 0.7), (1, 1)], d) * 0.5
    air = bp_sweep(noise(d), 4000, 600, 0.5) * env_lin([(0, 0), (1, 1)], d) * 0.6
    ex = mix(boom(1.6, 90, 28, 0.45), crack(0.5) * 0.7, (crackle(1.0, 60) * 0.4, 0.05))
    return reverb(mix(whistle, air, (ex, d)), 1.4, 0.3)


@snd('win_humans', LO)
def _():
    a = chord_stab([261.6, 329.6, 392.0, 523.25], 1.0, 5000, 900)
    b = chord_stab([293.7, 370.0, 440.0, 587.3], 1.0, 5000, 900)
    c = chord_stab([392.0, 493.9, 587.3, 784.0], 2.0, 6000, 800)
    return reverb(mix(a, (b, 0.45), (c, 0.9), (timpani(65, 1.2) * 0.8, 0), (timpani(73, 1.2) * 0.8, 0.45),
                      (timpani(98, 1.6) * 0.9, 0.9), (tinkle(1.6, 24) * 0.2, 0.95)), 1.8, 0.3)


@snd('win_zombies', LO)
def _():
    a = chord_stab([110.0, 130.8, 164.8], 2.6, 2500, 300)
    g = growl(2.0, 70, 50, 18) * 0.7
    return reverb(mix(a, (g, 0.2), (boom(2.0, 60, 25, 0.6), 0)), 2.0, 0.35)


# ======================= ZOMBI =======================

@snd('infect', LO)
def _():
    splat = lp(noise(0.25), 1200) * env_exp(0.25, 0.05)
    g = growl(1.1, 95, 70, 30)
    return reverb(mix(splat, (g, 0.05, 0.9), (bubbles(0.6, 20, 200, 600) * 0.3, 0)), 0.9, 0.25)


@snd('z_burst')
def _():
    return mix(whoosh(0.6, 200, 2500, 0.4), (growl(0.5, 120, 90, 35) * 0.6, 0.05))


@snd('z_leap')
def _():
    return whoosh(0.55, 300, 3500, 0.35)


@snd('z_shield')
def _():
    d = 0.9
    x = mix(sine(sweep(200, 600, d), d) * 0.5, sine(sweep(400, 1200, d), d) * 0.3, tinkle(d, 10, 2000, 5000) * 0.3)
    return reverb(x * env_lin([(0, 0), (0.3, 1), (1, 0)], d), 0.9, 0.3)


@snd('z_scream', LO)
def _():
    return reverb(screech(1.4, 1900, 1100), 1.2, 0.3)


@snd('z_drain', LO)
def _():
    d = 1.0
    x = reverse(bp(noise(d, 'pink'), 200, 3000) * env_exp(d, 0.3)) + sine(sweep(500, 120, d), d) * env_exp(d, 0.4) * 0.4
    return reverb(x, 0.9, 0.25)


@snd('z_cloak')
def _():
    d = 0.9
    x = sum(sine(f, d) for f in (1800, 2400, 3100, 3900)) / 4 * env_lin([(0, 1), (1, 0)], d)
    return reverb(tremolo(x, 22, 0.8) + hp(noise(d), 5000) * env_exp(d, 0.2) * 0.2, 1.0, 0.35)


@snd('z_toxic')
def _():
    d = 1.3
    hiss = bp(noise(d), 2000, 7000) * env_lin([(0, 0), (0.1, 1), (1, 0)], d) * 0.5
    return reverb(mix(hiss, bubbles(d, 26, 250, 900) * 0.7, (lp(noise(0.3), 900) * env_exp(0.3, 0.06), 0)), 0.9, 0.2)


@snd('z_frost')
def _():
    return reverb(mix(crackle(0.9, 90, 3000, 10000) * 0.7, whoosh(0.8, 800, 4000, 0.3) * 0.6, tinkle(0.9, 10) * 0.4), 1.0, 0.3)


@snd('z_acid')
def _():
    spit = bp(noise(0.2), 600, 3000) * env_exp(0.2, 0.04)
    sizzle = bp(noise(1.0), 3000, 9000) * env_lin([(0, 0), (0.1, 1), (1, 0)], 1.0) * 0.5
    return mix(spit, (sizzle, 0.08), (bubbles(0.8, 20, 300, 900) * 0.4, 0.1))


@snd('z_heal')
def _():
    parts = [(chime(f, 0.8, 0.3) * 0.5, i * 0.07) for i, f in enumerate([523.25, 659.25, 880.0])]
    return reverb(mix(*parts, (pad([261.6, 392.0], 1.0, 0.1, 0.5, bright=2500) * 0.5, 0)), 1.0, 0.3)


@snd('z_blink')
def _():
    d = 0.45
    x = mix(sine(sweep(300, 3500, d), d) * env_exp(d, 0.12) * 0.6, zap(0.25, 4000, 800) * 0.5)
    return reverb(x, 0.6, 0.3)


@snd('z_shock', LO)
def _():
    return reverb(mix(boom(1.3, 80, 30, 0.35), (crackle(0.6, 70, 300, 3000) * 0.7, 0.03)), 1.0, 0.25)


@snd('evolve', LO)
def _():
    r = riser(1.0, 150, 2000) * 0.6
    g = growl(1.2, 90, 60, 22)
    return reverb(mix(r, (g, 0.6), (boom(1.2, 100, 40, 0.3) * 0.8, 0.9)), 1.3, 0.3)


@snd('madness', LO)
def _():
    d = 1.4
    t = tt(d)
    w = sine(400 * (1 + 0.25 * np.sin(2 * np.pi * 7 * t)), d) * 0.4 + sine(415 * (1 + 0.25 * np.sin(2 * np.pi * 6.3 * t)), d) * 0.4
    return reverb(mix(dist(w * env_lin([(0, 0), (0.2, 1), (1, 0)], d), 2), growl(1.0, 110, 80) * 0.4), 1.2, 0.35)


@snd('antidote')
def _():
    parts = [(chime(f, 0.9, 0.35) * 0.5, i * 0.06) for i, f in enumerate([659.25, 880.0, 1174.7, 1568.0])]
    return reverb(mix(*parts, (tinkle(1.0, 16) * 0.3, 0.1)), 1.2, 0.3)


@snd('nem_rage', LO)
def _():
    g = growl(1.6, 70, 45, 20)
    return reverb(mix(g, (boom(1.4, 80, 30, 0.4), 0), (braam(55, 1.6, 4) * 0.4, 0.05)), 1.4, 0.3)


@snd('asn_veil', LO)
def _():
    d = 1.2
    x = reverse(hp(noise(d), 1500) * env_exp(d, 0.3)) * 0.6
    tone = sine(sweep(900, 200, d), d) * env_lin([(0, 1), (1, 0)], d) * 0.4
    return reverb(mix(x, tone), 1.4, 0.45)


# ======================= BOMBALAR / DURUMLAR =======================

@snd('nade_fire', LO)
def _():
    d = 1.4
    roar = lp_sweep(noise(d, 'pink'), 3000, 500) * env_lin([(0, 0), (0.05, 1), (1, 0)], d)
    return reverb(mix(roar, (boom(1.0, 120, 50, 0.25) * 0.7, 0), (crackle(d, 80, 1000, 6000) * 0.5, 0.05)), 1.0, 0.2)


@snd('nade_frost', LO)
def _():
    sh = hp(noise(0.5), 3000) * env_exp(0.5, 0.08)
    return reverb(mix(sh, (tinkle(1.2, 28, 2500, 9000) * 0.7, 0.02), (boom(0.8, 140, 60, 0.15) * 0.5, 0)), 1.3, 0.3)


@snd('nade_infect')
def _():
    sp = lp(noise(0.35), 1500) * env_exp(0.35, 0.07)
    return reverb(mix(sp, (bubbles(1.0, 30, 200, 700) * 0.6, 0.05), (growl(0.8, 110, 80) * 0.3, 0.1)), 0.9, 0.25)


@snd('nade_cluster')
def _():
    parts = [(mix(crack(0.2, 600, 6000), boom(0.5, 140, 60, 0.1) * 0.6), i * 0.13, 0.8) for i in range(5)]
    return reverb(mix(*parts), 0.9, 0.2)


@snd('nade_mode')
def _():
    return mix(hp(noise(0.015), 2500) * 0.8, (beep(1600, 0.04, 'tri') * 0.5, 0.02))


@snd('nade_beep')
def _():
    return beep(2100, 0.09, 'tri')


@snd('nade_arm')
def _():
    c = hp(noise(0.012), 2500) * 0.8
    return mix(c, (c, 0.07), (beep(1200, 0.08) * 0.6, 0.16), (beep(1800, 0.1) * 0.6, 0.26))


@snd('nade_trigger')
def _():
    b = beep(2600, 0.06, 'square') * 0.5
    return mix(b, (b, 0.08), (b, 0.16))


@snd('freeze')
def _():
    return reverb(mix(crackle(0.8, 120, 3000, 10000) * 0.8, tinkle(0.8, 12) * 0.5), 0.8, 0.25)


@snd('burn')
def _():
    d = 0.9
    return mix(lp_sweep(noise(d, 'pink'), 2500, 600) * env_lin([(0, 0), (0.08, 1), (1, 0)], d), crackle(d, 60, 1200, 6000) * 0.5)


@snd('sw_fire')
def _():
    d = 0.45
    x = mix(sine(sweep(1800, 300, d), d) * env_exp(d, 0.1) * 0.6, zap(0.3, 5000, 1000) * 0.5)
    return reverb(x, 0.5, 0.2)


@snd('zap')
def _():
    return zap(0.35, 3500, 400)


# ======================= LAZER =======================

@snd('lm_deploy')
def _():
    clack = bp(noise(0.06), 800, 5000) * env_exp(0.06, 0.012)
    servo = bp(saw(sweep(400, 700, 0.2), 0.2, 15), 400, 3000) * env_adsr(0.2, 0.01, 0.05, 0.6, 0.05) * 0.4
    return mix(clack, (servo, 0.04), (clack * 0.6, 0.26))


@snd('lm_charge')
def _():
    # dongusuz sarj sesi (orijinal mine_charge dongulu oldugu icin degistirildi)
    d = 1.0
    x = sine(sweep(400, 2400, d), d) * 0.5 + square(sweep(200, 1200, d), d, 7) * 0.15
    return x * env_lin([(0, 0), (0.1, 0.6), (0.9, 1), (1, 0)], d)


@snd('lm_activate')
def _():
    b = mix(beep(1800, 0.06), (beep(2400, 0.08), 0.09))
    hum = (sine(120, 0.4) * 0.4 + sine(240, 0.4) * 0.2) * env_lin([(0, 0), (0.2, 1), (1, 0)], 0.4)
    return mix(b, (hum, 0.12))


@snd('lm_hit')
def _():
    return mix(zap(0.25, 4500, 900), (bp(noise(0.2), 4000, 10000) * env_exp(0.2, 0.06) * 0.6, 0))


@snd('lm_kill')
def _():
    d = 0.8
    x = mix(zap(0.4, 6000, 300), (crackle(0.6, 120, 2000, 9000) * 0.7, 0.02), (sine(sweep(1500, 80, d), d) * env_exp(d, 0.25) * 0.5, 0))
    return reverb(x, 0.8, 0.25)


@snd('lm_break')
def _():
    return reverb(mix(boom(0.9, 150, 50, 0.2) * 0.8, crack(0.4, 1500, 9000), (crackle(0.7, 100, 2000, 9000) * 0.6, 0.03)), 0.9, 0.2)


@snd('lm_pickup')
def _():
    servo = bp(saw(sweep(700, 400, 0.15), 0.15, 15), 400, 3000) * env_adsr(0.15, 0.01, 0.04, 0.6, 0.04) * 0.4
    return mix(servo, (bp(noise(0.05), 800, 5000) * env_exp(0.05, 0.01), 0.14), (beep(1500, 0.06) * 0.4, 0.18))


# ======================= HAVA IKMALI =======================

@snd('airdrop_incoming', LO)
def _():
    d = 2.5
    t = tt(d)
    plane = lp(saw(70 * (1 + 0.01 * np.sin(2 * np.pi * 0.5 * t)), d, 30), 900) * env_lin([(0, 0), (0.5, 1), (1, 0)], d) * 0.6
    radio = mix(beep(1200, 0.12, 'square'), (beep(900, 0.12, 'square'), 0.16), (beep(1200, 0.12, 'square'), 0.32))
    radio = bp(radio, 500, 3000) * 0.5
    static = bp(noise(0.5), 1000, 4000) * env_exp(0.5, 0.2) * 0.25
    return reverb(mix(plane, (radio, 0.1), (static, 0)), 1.0, 0.2)


@snd('airdrop_land')
def _():
    return reverb(mix(thump(0.6, 60, 0.12), (crackle(0.5, 50, 800, 5000) * 0.6, 0.02), (bell(420, 0.6, 1.6, 3, 0.12) * 0.25, 0.03)), 0.7, 0.2)


@snd('airdrop_loot')
def _():
    return reverb(mix(tinkle(0.6, 18, 3000, 9000) * 0.6, (chime(1568, 0.6, 0.2) * 0.5, 0), (chime(2093, 0.6, 0.2) * 0.5, 0.08)), 0.8, 0.25)


# ======================= BOSS (GENEL) =======================

@snd('boss_spawn', LO)
def _():
    b = braam(36.7, 4.0, 3.5)
    quake = lp(noise(4.0, 'brown'), 120) * env_lin([(0, 0), (0.1, 1), (1, 0)], 4.0)
    return reverb(mix(b, (quake, 0, 1.2), (boom(2.5, 70, 22, 0.8), 0), (growl(2.0, 60, 40, 15) * 0.4, 0.4)), 2.5, 0.35)


@snd('boss_intro', LO)
def _():
    d = 2.6
    x = np.zeros(n_of(d))
    for f in (98.0, 103.8, 146.8, 155.6):
        x += saw(f, d, 25) * (1 + 0.2 * np.sin(2 * np.pi * 6 * tt(d)))
    x = lp_sweep(x, 300, 3000) * env_lin([(0, 0), (0.95, 1), (1, 0)], d) / 4
    return reverb(mix(x, riser(d, 100, 1500) * 0.4), 1.5, 0.3)


@snd('boss_scream', LO)
def _():
    return reverb(mix(screech(1.8, 1300, 600), (growl(1.6, 90, 60, 25) * 0.6, 0.1)), 1.5, 0.35)


@snd('boss_summon', LO)
def _():
    d = 2.2
    t = tt(d)
    choir = sum(sine(f * (1 + 0.006 * np.sin(2 * np.pi * 5 * t + i)), d) for i, f in enumerate((110, 130.8, 164.8, 196.0)))
    choir = formant(choir, [(400, 200, 1.0), (800, 300, 0.6)]) * env_lin([(0, 0), (0.3, 1), (1, 0)], d)
    rev = reverse(lp(noise(1.0, 'pink'), 2000) * env_exp(1.0, 0.3)) * 0.6
    return reverb(mix(rev, (choir, 0.6)), 2.0, 0.45)


@snd('boss_slam', LO)
def _():
    return reverb(mix(boom(1.8, 75, 25, 0.5), crack(0.5, 600, 5000) * 0.6, (crackle(1.0, 70, 300, 3000) * 0.5, 0.05)), 1.5, 0.3)


@snd('boss_death', LO)
def _():
    ex = mix(boom(3.0, 80, 20, 0.9), crack(0.6, 500, 6000) * 0.7, (crackle(2.0, 60, 300, 4000) * 0.5, 0.1))
    fall = saw(sweep(300, 30, 3.5), 3.5, 20) * env_lin([(0, 0), (0.1, 0.5), (1, 0)], 3.5) * 0.3
    return reverb(mix(ex, (lp(fall, 1500), 0.2), (boom(2.0, 60, 25, 0.6), 0.8)), 2.5, 0.35)


@snd('boss_soon', LO)
def _():
    d = 2.6
    horn = lp(saw(73.4, d, 30) + saw(110, d, 30) * 0.6, 900) * env_lin([(0, 0), (0.4, 1), (0.85, 0.8), (1, 0)], d)
    return reverb(horn, 2.5, 0.5)


@snd('boss_step', LO)
def _():
    return thump(0.5, 40, 0.12)


@snd('boss_phase', LO)
def _():
    return reverb(mix(boom(1.8, 90, 30, 0.5), (riser(1.2, 200, 2500) * 0.5, 0.2), (braam(49, 1.8, 3) * 0.5, 0)), 1.8, 0.35)


@snd('boss_enrage', LO)
def _():
    g = growl(2.2, 65, 40, 16)
    return reverb(mix(dist(g * 1.5, 3), (boom(2.0, 70, 22, 0.6), 0), (braam(41, 2.4, 4) * 0.5, 0.05)), 1.8, 0.3)


@snd('frost_nova', LO)
def _():
    return reverb(mix(boom(1.0, 140, 50, 0.25) * 0.7, hp(noise(0.5), 2500) * env_exp(0.5, 0.1), (tinkle(1.5, 36, 2500, 9000) * 0.7, 0.03)), 1.6, 0.35)


@snd('acid_pool', LO)
def _():
    return reverb(mix(bubbles(1.6, 30, 200, 800) * 0.8, bp(noise(1.6), 2500, 8000) * env_lin([(0, 0), (0.1, 1), (1, 0)], 1.6) * 0.4), 1.0, 0.25)


@snd('gravity_well', LO)
def _():
    d = 2.0
    t = tt(d)
    warp = sine(sweep(400, 40, d), d) * 0.6 + lp(saw(sweep(200, 30, d), d, 20), 1200) * 0.4
    flange = warp + np.interp(np.arange(len(warp)) - (60 + 50 * np.sin(2 * np.pi * 0.8 * t)), np.arange(len(warp)), warp)
    return reverb(flange * env_lin([(0, 0), (0.1, 1), (1, 0)], d), 1.6, 0.4)


@snd('eclipse', LO)
def _():
    d = 2.6
    sw = lp_sweep(noise(d, 'pink'), 200, 1500) * env_lin([(0, 0), (0.6, 1), (1, 0)], d) * 0.6
    drone = (sine(41.2, d) + sine(61.7, d) * 0.6) * env_lin([(0, 0), (0.4, 1), (1, 0)], d)
    return reverb(mix(sw, drone), 2.2, 0.45)


# ======================= BOSS [R] YETENEKLERI =======================

@snd('brute_stomp', LO)
def _():
    return reverb(mix(boom(1.5, 85, 28, 0.4), crack(0.5, 600, 5000) * 0.7, (crackle(1.0, 60, 300, 2500) * 0.5, 0.05)), 1.2, 0.3)


@snd('brute_shatter', LO)
def _():
    hits = [(mix(boom(0.7, 110, 45, 0.18), crack(0.3, 800, 6000) * 0.6), i * 0.14, 0.9) for i in range(4)]
    return reverb(mix(*hits), 1.2, 0.3)


@snd('brute_wrath', LO)
def _():
    g = growl(1.8, 60, 45, 14)
    drums = mix(*[(timpani(55, 0.6) * 0.8, i * 0.25) for i in range(6)])
    return reverb(mix(dist(g * 1.4, 3), (drums, 0.1), (boom(1.5, 70, 25, 0.5), 0)), 1.4, 0.3)


@snd('banshee_lance')
def _():
    d = 1.0
    sonic = sine(sweep(2600, 500, d), d) * env_exp(d, 0.25) * 0.5
    burst = bp(noise(0.4), 1500, 8000) * env_exp(0.4, 0.08)
    return reverb(mix(burst, sonic, (boom(0.8, 160, 60, 0.15) * 0.5, 0)), 1.0, 0.3)


@snd('banshee_shriek', LO)
def _():
    return reverb(echo(screech(1.2, 2600, 1400), 0.13, 0.35, 3), 1.4, 0.4)


@snd('banshee_requiem', LO)
def _():
    d = 2.6
    t = tt(d)
    choir = sum(sine(f * (1 + 0.008 * np.sin(2 * np.pi * 5.5 * t + i)), d) for i, f in enumerate((220, 261.6, 311.1, 392.0, 466.2)))
    choir = formant(choir, [(700, 300, 1.0), (1200, 400, 0.7), (2600, 600, 0.3)]) * env_lin([(0, 0), (0.25, 1), (1, 0)], d)
    return reverb(mix(choir, (screech(1.0, 1800, 1200) * 0.3, 0.3)), 2.4, 0.5)


@snd('overlord_prison')
def _():
    rattle = mix(*[(bp(noise(0.03), 1500, 6000) * env_exp(0.03, 0.008), i * 0.045, rng.uniform(0.4, 1.0)) for i in range(14)])
    return reverb(mix(rattle, (boom(0.9, 100, 40, 0.2) * 0.8, 0.6)), 1.0, 0.3)


@snd('overlord_legion', LO)
def _():
    d = 2.2
    t = tt(d)
    choir = sum(sine(f * (1 + 0.006 * np.sin(2 * np.pi * 4.5 * t + i)), d) for i, f in enumerate((98, 116.5, 146.8, 174.6)))
    choir = formant(choir, [(400, 200, 1.0), (750, 300, 0.6)]) * env_lin([(0, 0), (0.3, 1), (1, 0)], d)
    rumble = lp(noise(d, 'brown'), 150) * env_lin([(0, 0), (0.2, 1), (1, 0)], d)
    return reverb(mix(choir, rumble), 2.0, 0.45)


@snd('overlord_nova', LO)
def _():
    pulses = [(mix(reverse(lp(noise(0.5, 'pink'), 1500) * env_exp(0.5, 0.15)) * 0.6, (boom(0.9, 90, 35, 0.25), 0.48)), i * 0.6) for i in range(3)]
    return reverb(mix(*pulses), 1.4, 0.35)


@snd('inferno_breath', LO)
def _():
    d = 1.6
    roar = bp(noise(d, 'pink'), 150, 3500) * env_lin([(0, 0), (0.08, 1), (0.8, 0.9), (1, 0)], d)
    return reverb(mix(roar, crackle(d, 90, 1500, 7000) * 0.5, (boom(0.6, 100, 50, 0.15) * 0.5, 0)), 1.0, 0.2)


@snd('inferno_pillar', LO)
def _():
    up = whoosh(0.9, 200, 3000, 0.4)
    return reverb(mix(up, (boom(1.0, 90, 40, 0.3), 0.3), (crackle(1.0, 80, 1200, 6000) * 0.6, 0.3)), 1.0, 0.25)


@snd('inferno_nova', LO)
def _():
    charge = riser(2.0, 100, 2500) * 0.6
    hum = saw(sweep(55, 220, 2.0), 2.0, 20) * env_lin([(0, 0), (1, 1)], 2.0) * 0.3
    ex = mix(boom(2.5, 70, 20, 0.8), crack(0.6, 400, 6000) * 0.8, (crackle(1.5, 70, 300, 4000) * 0.6, 0.05))
    return reverb(mix(charge, lp(hum, 2000), (ex, 2.0)), 2.0, 0.35)


@snd('reaper_step')
def _():
    sh = reverse(hp(noise(0.5), 800) * env_exp(0.5, 0.12)) * 0.7
    return reverb(mix(sh, (thump(0.4, 55, 0.1), 0.45)), 1.0, 0.4)


@snd('reaper_chains', LO)
def _():
    clinks = mix(*[(bell(rng.uniform(1800, 3200), 0.25, 1.414, 4, 0.05), i * 0.07, rng.uniform(0.3, 0.8)) for i in range(16)])
    drone = (sine(55, 1.6) + sine(58.3, 1.6)) * env_lin([(0, 0), (0.2, 1), (1, 0)], 1.6) * 0.4
    return reverb(mix(clinks, drone), 1.2, 0.3)


@snd('reaper_mark', LO)
def _():
    b = bell(110, 2.2, 1.4, 6, 0.8)
    wh = bp(noise(1.5, 'pink'), 2000, 6000) * env_lin([(0, 0), (0.5, 1), (1, 0)], 1.5) * 0.25
    return reverb(mix(b, (wh, 0.2)), 2.0, 0.45)


@snd('frost_shards')
def _():
    shards = mix(*[(whoosh(0.35, 1500, 6000, 0.5) * 0.6, i * 0.05) for i in range(5)])
    return reverb(mix(shards, (tinkle(0.9, 20, 3000, 9000) * 0.6, 0.15)), 1.0, 0.3)


@snd('frost_tomb')
def _():
    return reverb(mix(crackle(0.9, 140, 2500, 10000) * 0.8, (thump(0.5, 70, 0.1) * 0.8, 0.6), (tinkle(0.8, 10) * 0.4, 0.6)), 1.1, 0.3)


@snd('frost_zero')
def _():
    d = 2.6
    wind = bp_sweep(noise(d, 'pink'), 400, 2500, 0.5) * env_lin([(0, 0), (0.3, 1), (1, 0)], d)
    res = sum(sine(f, d) for f in (1318.5, 1760, 2349)) / 3 * env_lin([(0, 0), (0.5, 0.4), (1, 0)], d)
    return reverb(mix(wind, res * 0.5, (tinkle(d, 30) * 0.3, 0)), 2.0, 0.4)


@snd('storm_orb', LO)
def _():
    d = 1.4
    t = tt(d)
    hum = (sine(110, d) + square(220, d, 7) * 0.3) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t))
    return reverb(mix(lp(hum, 2500) * env_lin([(0, 0), (0.1, 1), (1, 0)], d) * 0.6, crackle(d, 50, 2000, 9000) * 0.7), 0.8, 0.25)


@snd('storm_dash')
def _():
    return reverb(mix(whoosh(0.7, 500, 5000, 0.3), zap(0.5, 6000, 300) * 0.8), 0.8, 0.25)


@snd('storm_tempest', LO)
def _():
    d = 2.8
    rain = bp(noise(d), 1500, 5000) * env_lin([(0, 0), (0.2, 1), (1, 0.6)], d) * 0.4
    th = lp(noise(d, 'brown'), 300) * tremolo(np.ones(n_of(d)), 4, 0.6) * env_lin([(0, 0), (0.1, 1), (1, 0)], d)
    return reverb(mix(rain, th, (hp(noise(0.2), 1500) * env_exp(0.2, 0.04) * 0.6, 0.1)), 1.8, 0.3)


@snd('hive_spit')
def _():
    return mix(lp(noise(0.25), 1500) * env_exp(0.25, 0.05), (whoosh(0.5, 400, 2000, 0.3) * 0.6, 0.03), (bubbles(0.4, 12, 300, 900) * 0.3, 0.05))


@snd('hive_cloud', LO)
def _():
    d = 1.8
    hiss = bp(noise(d), 1500, 7000) * env_lin([(0, 0), (0.2, 1), (1, 0)], d) * 0.6
    return reverb(mix(hiss, bubbles(d, 22, 200, 700) * 0.6), 1.2, 0.3)


@snd('hive_eggs', LO)
def _():
    sq = lp(noise(0.4), 900) * env_exp(0.4, 0.1)
    beat = mix(thump(0.3, 60), (thump(0.3, 55) * 0.7, 0.18), (thump(0.3, 60), 0.7), (thump(0.3, 55) * 0.7, 0.88))
    return reverb(mix(sq, (beat, 0.2), (bubbles(1.4, 18, 150, 500) * 0.4, 0)), 1.2, 0.3)


@snd('void_bolt')
def _():
    d = 0.8
    x = mix(sine(sweep(1600, 60, d), d) * env_exp(d, 0.25) * 0.7, zap(0.4, 3000, 200) * 0.4)
    return reverb(x, 1.0, 0.4)


@snd('void_singularity', LO)
def _():
    d = 2.2
    suck = reverse(lp(noise(d, 'pink'), 2500) * env_exp(d, 0.6)) * 0.7
    warp = sine(sweep(300, 30, d), d) * env_lin([(0, 0), (0.2, 1), (1, 0)], d) * 0.6
    return reverb(mix(suck, warp), 1.8, 0.4)


@snd('void_horizon', LO)
def _():
    d = 2.8
    swell = lp_sweep(noise(d, 'brown'), 100, 1200) * env_lin([(0, 0), (0.7, 1), (1, 0)], d)
    sub = (sine(36.7, d) + sine(55, d) * 0.5) * env_lin([(0, 0), (0.5, 1), (1, 0)], d)
    return reverb(mix(swell, sub, (braam(36.7, d, 3) * 0.3, 0)), 2.4, 0.45)


# ======================= SPIKER (MBROLA + islem) =======================
VOX = {
    'vox_headshot': 'Headshot!', 'vox_double': 'Double kill!', 'vox_triple': 'Triple kill!',
    'vox_multi': 'Multi kill!', 'vox_mega': 'Mega kill!', 'vox_monster': 'Monster kill!',
    'vox_rampage': 'Rampage!', 'vox_unstoppable': 'Unstoppable!', 'vox_godlike': 'Godlike!',
}


def make_vox(text, tmp):
    import wave as _w
    subprocess.run(['espeak-ng', '-v', 'mb-us2', '-s', '118', '-p', '28', '-a', '180', text, '-w', tmp],
                   check=True, capture_output=True)
    w = _w.open(tmp)
    sr = w.getframerate()
    raw = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').astype(float) / 32768.0
    w.close()
    x = resample(raw, sr, Ctx.sr) if sr != Ctx.sr else raw
    # derin "arena spikeri": perde -3, hafif doygunluk, alt kalin katman, kisa yanki
    lowv = pitch(x, -3.0)
    sub = lp(pitch(x, -12.0), 400)
    sub = fit(sub, len(lowv)) * 0.35
    v = lowv + sub
    v = hp(v, 70)
    v = dist(v * 1.6, 1.8)
    v = v + 0.25 * bp(v, 2000, 5000)
    v = reverb(v, 0.9, 0.22, 6000, 0.02)
    hit = boom(0.7, 120, 50, 0.15) * 0.35
    return mix(v, (hit, 0.0))


def main():
    os.makedirs(OUT, exist_ok=True)
    total = 0
    report = {}
    only = set(sys.argv[2:])
    for name, (fn, sr) in R.items():
        if only and name not in only:
            continue
        x = fn()
        cap = 6.0 if name == 'ambient' else (4.5 if name in BIG else 3.2)
        dur = write_wav(os.path.join(OUT, name + '.wav'), x, sr, loud=LOUD.get(name, -15.0), max_len=cap)
        sz = os.path.getsize(os.path.join(OUT, name + '.wav'))
        total += sz
        report[name] = (round(dur, 2), sr, sz)
    tmp = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/gen/_vox.wav'
    for name, text in VOX.items():
        if only and name not in only:
            continue
        x = make_vox(text, tmp)
        dur = write_wav(os.path.join(OUT, name + '.wav'), x, LO, loud=-13.0)
        sz = os.path.getsize(os.path.join(OUT, name + '.wav'))
        total += sz
        report[name] = (round(dur, 2), LO, sz)
    for k in sorted(report):
        print(f'{k:22} {report[k][0]:6.2f}s {report[k][1]:6}Hz {report[k][2] // 1024:5} KB')
    print('TOPLAM', len(report), 'ses,', total // 1024, 'KB')


if __name__ == '__main__':
    main()
