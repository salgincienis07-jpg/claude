#!/usr/bin/env python3
"""vexprobe_reset - round-reset / interactivity probe map for the test server (NOT shipped).

One hall with 32 CT + 32 T spawns and one instance of every entity class a Vexmira map may
use for set pieces, each with a targetname r_* and (where it fires something) an output
trigger_relay r_*_out, so vexprobe's Use log shows exactly what fired and when.
Used to measure which entity classes ReGameDLL restores on round restart and what each class
costs in precache slots (MAPS_v3.md section 4). Writes into the SERVER maps dir only.

    python3 devtools/server/make_resetmap.py [--out $SP/server/cstrike/maps]
    VEX_SERVER=... python3 devtools/server/run_test.py --map vexprobe_reset --no-rebuild --no-vexmira \
        --bots 2 --seconds 60 --commands devtools/server/sessions/reset_probe.txt
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from mapkit.mapwriter import (ORIGIN, TRIGGER, Brush, Entity, Map, ambient, box, door, env_sprite,  # noqa: E402
                              light, room, spawn_grid)
from mapkit.compile import compile_map  # noqa: E402

SP = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad'
MT = {'all': 'vx_metal_plate'}


def relay(name, target='', state=1, **kw):
    e = Entity('trigger_relay', origin=(0, 0, 200), targetname=name, triggerstate=state, **kw)
    if target:
        e['target'] = target
    return e


def out(name):
    return relay(name)


def build():
    m = Map('vexprobe_reset', sky='night', message='vexprobe round-reset probe')
    X, Y, H = 1024, 768, 320
    m.add(room((-X, -Y, 0), (X, Y, H), 16, 'vx_conc_panel', floor='vx_floor_lab', ceil='vx_metal_panel'))
    for lx in (-768, -256, 256, 768):
        for ly in (-512, 0, 512):
            m.add_entity(light((lx, ly, H - 40), (255, 240, 220), 240))
    m.add_entities(spawn_grid('ct', (-X, -Y), (X, -Y + 230), 0, 32, spacing=72, yaw=90))
    m.add_entities(spawn_grid('t', (-X, Y - 230), (X, Y), 0, 32, spacing=72, yaw=270))
    E = m.add_entity

    # --- doors / buttons ---------------------------------------------------------------
    d = door(box((-900, -300, 0), (-772, -284, 128), MT), 'up', speed=400, wait=-1, targetname='r_door', sounds=1)
    E(d)
    rot = Entity('func_door_rotating', box((-700, -300, 0), (-604, -292, 112), MT) +
                 box((-704, -300, 0), (-696, -292, 112), ORIGIN),
                 targetname='r_rotdoor', distance=90, speed=200, wait=-1, angles=(0, 0, 0))
    E(rot)
    E(Entity('func_button', box((-560, -300, 48), (-528, -292, 80), MT), targetname='r_button', target='r_btn_out',
             wait=-1, speed=50, lip=4, angles=(0, 90, 0), sounds=1))
    E(Entity('func_button', box((-480, -300, 48), (-448, -292, 80), MT), targetname='r_btn_toggle',
             target='r_btntg_out', wait=-1, speed=50, lip=4, angles=(0, 90, 0), spawnflags=32))
    E(out('r_btn_out'), out('r_btntg_out'))
    # button -> map->plugin relay (exercises the vexcmd log path)
    E(relay('vexcmd_msg_probe'))
    E(Entity('func_button', box((-400, -300, 48), (-368, -292, 80), MT), targetname='r_button_cmd',
             target='vexcmd_msg_probe', wait=2, speed=50, lip=4, angles=(0, 90, 0)))

    # --- breakables (three materials: precache cost per material) -------------------------
    E(Entity('func_breakable', box((-300, -300, 0), (-236, -236, 64), {'all': 'vx_crate_wood'}),
             targetname='r_break', target='r_break_out', material=1, health=50))
    E(Entity('func_breakable', box((-200, -300, 0), (-136, -284, 64), {'all': 'vx_glass'}),
             targetname='r_break_glass', material=0, health=20, rendermode=2, renderamt=90))
    E(Entity('func_breakable', box((-100, -300, 0), (-36, -236, 64), MT),
             targetname='r_break_metal', material=2, health=200))
    E(out('r_break_out'))
    E(Entity('func_breakable', box((0, -300, 0), (64, -236, 16), {'all': 'vx_crate_wood'}),
             targetname='r_break_trig', material=1, health=1, spawnflags=1))   # only breaks when triggered

    # --- func_train on two path_corners -------------------------------------------------
    E(Entity('path_corner', origin=(0, 0, 200), targetname='r_p1', target='r_p2'))
    E(Entity('path_corner', origin=(400, 0, 200), targetname='r_p2', target='r_p1'))
    E(Entity('func_train', box((-32, -32, 168), (32, 32, 232), MT) + box((-8, -8, 192), (8, 8, 208), ORIGIN),
             targetname='r_train', target='r_p1', speed=100))

    # --- triggers ----------------------------------------------------------------------------
    E(Entity('trigger_once', box((-900, 100, 0), (-836, 164, 72), TRIGGER), targetname='r_once', target='r_once_out'))
    E(Entity('trigger_multiple', box((-800, 100, 0), (-736, 164, 72), TRIGGER), targetname='r_multi',
             target='r_multi_out', wait=1))
    E(out('r_once_out'), out('r_multi_out'))
    E(Entity('trigger_hurt', box((-700, 100, 0), (-636, 164, 72), TRIGGER), targetname='r_hurt', dmg=1,
             damagetype=0))
    E(Entity('trigger_auto', origin=(0, 0, 220), target='r_auto_out', triggerstate=1))
    E(out('r_auto_out'))

    # --- logic ----------------------------------------------------------------------------------
    E(Entity('multi_manager', origin=(0, 0, 240), targetname='r_mm', r_mm_out1=1, r_mm_out2=20))
    E(out('r_mm_out1'), out('r_mm_out2'))
    E(Entity('game_counter', origin=(0, 0, 240), targetname='r_counter', target='r_counter_out', health=2))
    E(out('r_counter_out'))
    E(relay('r_relay_once', 'r_relayonce_out', spawnflags=1), out('r_relayonce_out'))
    E(relay('r_ct_src', 'r_ct_a'), out('r_ct_a'), out('r_ct_b'))
    E(Entity('trigger_changetarget', origin=(0, 0, 240), targetname='r_ct', target='r_ct_src', m_iszNewTarget='r_ct_b'))
    E(Entity('multisource', origin=(0, 0, 240), targetname='r_ms'))
    E(relay('r_ms_in1', 'r_ms'), relay('r_ms_in2', 'r_ms'))
    E(door(box((-600, 300, 0), (-472, 316, 128), MT), 'up', speed=400, wait=-1, targetname='r_msdoor'))
    m.entities[-1]['master'] = 'r_ms'

    # --- team masters (game_team_master: ReGameDLL compares the activator's team) --------------
    E(Entity('game_team_master', origin=(0, 0, 240), targetname='r_gtm_ct', teamindex=2, triggerstate=2))
    E(Entity('game_team_master', origin=(0, 0, 240), targetname='r_gtm_t', teamindex=1, triggerstate=2))
    # touch doors must NOT have a targetname (a func_door with a targetname ignores touch)
    E(door(box((-400, 300, 0), (-272, 316, 128), MT), 'up', speed=400, wait=3))      # CT only: func_door@-336/308/64
    m.entities[-1]['master'] = 'r_gtm_ct'
    E(door(box((-200, 300, 0), (-72, 316, 128), MT), 'up', speed=400, wait=3))       # T only: func_door@-136/308/64
    m.entities[-1]['master'] = 'r_gtm_t'
    E(Entity('func_button', box((100, 300, 48), (132, 308, 80), MT), targetname='r_teambutton',
             target='r_teambutton_out', wait=1, speed=50, lip=4, angles=(0, 90, 0), master='r_gtm_ct'))
    E(out('r_teambutton_out'))
    # positive multisource control: both inputs in the same round -> r_ms2door opens
    E(Entity('multisource', origin=(0, 0, 240), targetname='r_ms2'))
    E(relay('r_ms2_in1', 'r_ms2'), relay('r_ms2_in2', 'r_ms2'))
    E(door(box((-800, 300, 0), (-672, 316, 128), MT), 'up', speed=400, wait=-1, targetname='r_ms2door'))
    m.entities[-1]['master'] = 'r_ms2'
    E(Entity('trigger_multiple', box((0, 300, 0), (64, 364, 72), TRIGGER), targetname='r_teamtrig',
             target='r_teamtrig_out', wait=1, master='r_gtm_ct'))
    E(out('r_teamtrig_out'))
    # team-filtered damage zone, switchable: trigger (zombies only) -> game_player_hurt gated by a multisource
    E(Entity('trigger_multiple', box((200, 300, 0), (264, 364, 72), TRIGGER), targetname='r_zhurt',
             target='r_zhurt_do', wait=0.5, master='r_gtm_t'))
    E(Entity('game_player_hurt', origin=(0, 0, 240), targetname='r_zhurt_do', dmg=15, master='r_zhurt_on'))
    E(Entity('multisource', origin=(0, 0, 240), targetname='r_zhurt_on'))
    E(relay('r_zhurt_switch', 'r_zhurt_on', state=2))
    # human heal pad: negative damage heals the activator (CT only)
    E(Entity('trigger_multiple', box((300, 300, 0), (364, 364, 72), TRIGGER), targetname='r_heal',
             target='r_heal_do', wait=0.5, master='r_gtm_ct'))
    E(Entity('game_player_hurt', origin=(0, 0, 240), targetname='r_heal_do', dmg=-10))
    E(Entity('game_player_hurt', origin=(0, 0, 240), targetname='r_dmg30', dmg=30))     # test helper: hurt the activator
    # +use-only door (spawnflags 256) for humans only: Use with a T activator must do nothing
    E(door(box((400, 300, 0), (528, 316, 128), MT), 'up', speed=400, wait=3, targetname='r_usedoor', use_only=True))
    m.entities[-1]['master'] = 'r_gtm_ct'

    # --- lights / sprites / sounds / render ------------------------------------------------------
    E(light((300, 200, 100), (255, 80, 40), 200, targetname='r_light'))
    E(light((500, 200, 100), (40, 80, 255), 200, targetname='r_light_off'))
    m.entities[-1]['spawnflags'] = 1
    E(env_sprite((300, 300, 100), scale=0.3, targetname='r_spr_on', start_on=True))
    E(env_sprite((500, 300, 100), scale=0.3, targetname='r_spr_off', start_on=False))
    snd = 'vexmira/map/zm_vex_laboratory_amb.wav'
    E(ambient((300, 400, 100), snd, targetname='r_amb_loop', start_silent=True))
    E(ambient((500, 400, 100), snd, targetname='r_amb_on'))
    # safe alarm pattern: looped + start silent, switched OFF explicitly at every round start
    E(ambient((700, 400, 100), snd, targetname='r_amb_alarm', start_silent=True))
    E(Entity('trigger_auto', origin=(0, 0, 220), target='r_alarm_reset', triggerstate=1))
    E(relay('r_alarm_reset', 'r_amb_alarm', state=0))
    E(Entity('func_wall_toggle', box((600, -300, 0), (728, -284, 128), MT), targetname='r_wt'))
    E(Entity('func_wall', box((800, -300, 0), (928, -284, 128), MT), targetname='r_rwall'))
    E(Entity('env_render', origin=(0, 0, 240), targetname='r_render', target='r_rwall', rendermode=2, renderamt=40))
    E(Entity('func_rotating', box((600, 0, 100), (728, 16, 116), MT) + box((656, 0, 100), (672, 16, 116), ORIGIN),
             targetname='r_rot', speed=90, spawnflags=1, sounds=0))
    E(Entity('func_plat', box((800, 0, 0), (928, 128, 8), MT), targetname='r_plat', height=64, speed=100))
    E(Entity('env_spark', origin=(800, 300, 100), targetname='r_spark', MaxDelay=1, spawnflags=32))
    E(Entity('env_shake', origin=(0, 0, 240), targetname='r_shake', amplitude=4, duration=1, frequency=40, radius=500,
             spawnflags=1))

    # --- plugin contract hooks (only visible when the installed plugin implements it) --------------
    for ev in ('vex_round_start', 'vex_freeze_end', 'vex_infection', 'vex_minute'):
        E(relay(ev, 'r_%s_out' % ev[4:]), out('r_%s_out' % ev[4:]))
    return m


def main(argv=None):
    ap = argparse.ArgumentParser()
    srv = os.environ.get('VEX_SERVER', os.path.join(SP, 'server'))
    ap.add_argument('--out', default=os.path.join(srv, 'cstrike/maps'))
    ap.add_argument('--quality', default='draft')
    a = ap.parse_args(argv)
    m = build()
    print('spawn problems:', m.spawn_problems())
    print(m.stats())
    r = compile_map(m, quality=a.quality, out_dir=a.out)
    print(r.summary())
    sys.exit(0 if r.ok else 1)


if __name__ == '__main__':
    main()
