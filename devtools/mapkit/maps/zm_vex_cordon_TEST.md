# zm_vex_cordon - integration test (map + real plugin)

Date 2026-10-10. Server serverD (ReHLDS + ReGameDLL + AMXX 1.10 + ReAPI), port 27037, 16 bots,
plugin built from the repo .sma (0 errors, 0 warnings, 360211 bytes), debug flag on.
Runs (archived under scratchpad/serverD/runs/):

| run | dir | length | what |
|---|---|---|---|
| 1 | 20261010_133402 | 225 s, 5 rounds | story, objectives, all 3 objective chains via the real buttons, vexcmd relays, boss / nemesis / survivor / assassin rounds |
| 2 | 20261010_133851 | 185 s, 2 rounds | first-round round_start, freeze_end ini event, boss round + ini boss event |
| 3 | 20261010_134234 | 205 s, 2 rounds | natural round: last human + zombie win |

No crash in any run, amxx_error.log empty, 0 "run time error" lines.

## Results

| check | result | evidence |
|---|---|---|
| scenario ini loads | PASS | `map durum: ini=1 gorev=3 isaret=3 komut=15` (15/15 vexcmd relays mapped) |
| story typewriter on spawn + /story | PASS | `map hikaye #1 satir 1/6 .. 6/6`, replay via `vexprobe_call #1 cmd_MsStory` |
| objectives at freeze end | PASS | `map gorevler #1..#16: 0/3 tamam` each round |
| SP1 power (both breakers) | PASS | relays msg_power / reward_h_5 / obj_1_done fired by the map chain |
| SP2 lift bridge (master = power) | PASS | msg_bridge / reward_h_8 / obj_2_done |
| SP3 beacon + heli | PASS | msg_beacon / obj_3_done, then msg_heli / reward_h_15 at +25 s; status `done=111` |
| rewards / objectives once per round | PASS | duplicate reward_h_5 + obj_1_done fired by hand: done stays 111; next round `done=000` |
| SP7 barricade break | PASS | msg_barricade / reward_z_5 |
| markers only for humans, hidden when done | PASS | before: `gorebilen=16 gizli=0`; after infection + all done: `nodraw=1 gorebilen=8 gizli=8`; next round visible again |
| vex_round_start (incl. first round) | PASS | map-start use of both `vex_round_start` multi_managers at t=1 s, then every restart (6 rounds) |
| vex_freeze_end + ini `freeze_end 1 cd_barrier_up` | PASS | barrier door used 1 s after freeze end in every round |
| vex_infection + ini `infection 30 cd_r_siren_st_off` | PASS | breach chain + siren switched off 30 s later |
| vex_boss + ini `boss 4 cd_billboard_mm` | PASS | vex_boss multi_manager, msg_boss, billboard at +4 s (runs 1, 2) |
| vex_nemesis / vex_assassin / vex_survivor | PASS | `map olay` lines in the forced-mode rounds, blackout chain used |
| vex_lasthuman | PASS (natural) | run 3: cd_blackout_mm, cd_boom_far, west lights off |
| vex_win_zombies | PASS (natural) | run 3: cd_r_siren_all_on |
| vex_minute | PASS | fired at 60 s of a live round (shelling chain) |
| vex_boss_dead, vex_win_humans | map side PASS, plugin side by code | bots could not kill the boss in the test time (`kill` client command is ignored for bots); the map reactions were proven with `vexprobe_fire` in the stage 3 sessions (cordon_setpieces.txt, cordon_heli.txt); plugin calls MsEvent(ME_BOSS_DEAD) in BossDeath and ME_WIN_HUMANS in MsRoundEnd for WINSTATUS_CTS |
| precache | PASS | `precache toplam: sound=450/512 model=277/512 generic=234/512`; only "bulunamadi" line is the optional SKY_LIST note (map uses its own stock sky) |

## Performance (bspcheck --perf-only, final bsp)

| | result | budget |
|---|---|---|
| view wpoly max / p95 / mean | 1042 / 880 / 544 | < 1300 / < 900 |
| faces drawn max / p95 | 999 / 864 | |
| brush entities | 35 | <= 60 |
| animated styled faces | 0 (9 switchable groups) | < 64 |
| sprites | 24 | <= 24 |
| new sounds | 9 | <= 10 |
| textures | 34 | 20-35 |
| bsp | 3.24 MB | <= 4.5 MB |
| entities (live max) | 524 edicts with 16 players | < 600 map entities |

## Review (eye previews of the busiest zones: harbor steps, plaza, worst view, west street, fish market, CT spawn)
All zones lit and readable, signs/arrows legible, materials fit the zones (quarantine stencils and
hazard bands at Gate 7, rusted containers and wet concrete at the harbor, brick facades in the
city). No blocking issue found.

## Open (not blocking)
- Rotation direction of the Gate 7 barrier arm and the boss billboard is only checked by end angles,
  not watched in a game client.
- Harbor steps (906) and crane (924) are above their soft spec targets but under the hard gates.
- Pad lamp has no amber stage (sprite budget 24/24).
