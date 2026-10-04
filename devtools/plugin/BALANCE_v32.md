# Vexmira Zombie v3.2 balance pass

Code defaults and `vexmira.cfg` were changed together and match.

| Setting | Old | New |
|---|---|---|
| vex_first_zombie_hp | 4500 | 6000 |
| vex_zombie_hp | 1800 | 2400 |
| vex_nemesis_hp | 9000 | 15000 |
| vex_assassin_hp | 6000 | 10000 |
| vex_nemesis_damage | 250 | 400 |
| vex_assassin_damage | 200 | 300 |
| vex_nemesis_vs_survivor | 250 | 350 |
| vex_damage_per_ap | 500 | 800 |
| vex_boss_hp | 6000 (code 7000) | 9000 |
| vex_boss_hp_per_player | 1500 | 2500 |
| vex_boss_damage | 75 | 90 |
| vex_win_human_ap | 6 | 5 |
| vex_boss_kill_vc | 3 | 2 |
| vex_achievement_vc | 3 | 2 |
| vex_exchange_cost | 60 | 100 |
| vex_perk_cost_step | 4 | 5 |
| vex_survivor_hp | 1200 | 1000 |
| vex_minion_hp | 400 | 600 |
| vex_zombie_damage | 60 | 75 |
| vex_zombie_hp_per_player | 0 (yok) | 40 |
| vex_nemesis_hp_per_player | 500 (sabit kod) | 1200 |
| vex_assassin_hp_per_player | 300 (sabit kod) | 800 |
| vex_knockback_mult | 1.0 (yok) | 0.75 |
| vex_special_dmg_cap | 3000 (sabit kod) | 1500 |
| Voidcaller (sw 7) knockback mult | 2.0 | 1.5 |
| vex_sw 0 AP / dmg mult | 40 / x1.8 | 80 / x1.35 |
| vex_sw 1 AP / dmg mult | 60 / x1.5 | 100 / x1.2 |
| vex_sw 2 AP / dmg mult | 70 / x3 | 120 / x1.9 |
| vex_sw 3 AP / dmg mult | 45 / x1.6 | 85 / x1.3 |
| vex_sw 4 AP / dmg mult | 30 / x2.2 | 70 / x1.5 |
| vex_sw 5 AP / dmg mult | 50 / x1.6 | 95 / x1.25 |
| vex_sw 6 AP / dmg mult | 55 / x1.9 | 105 / x1.35 |
| vex_sw 7 AP / dmg mult | 80 / x2.4 | 135 / x1.6 |
| vex_sw 8 AP / dmg mult | 48 / x1.7 | 90 / x1.3 |
| vex_sw 9 AP / dmg mult | 72 / x1.45 | 115 / x1.2 |
| vex_sw 10 AP / dmg mult | 85 / x2.6 | 140 / x1.7 |
| vex_sw 11 AP / dmg mult | 58 / x1.5 | 100 / x1.25 |
| vex_sw 12 AP / dmg mult | 38 / x2 | 75 / x1.4 |
| vex_sw 13 AP / dmg mult | 65 / x1.5 | 110 / x1.2 |
| vex_sw 14 AP / dmg mult | 68 / x1.7 | 120 / x1.3 |
| vex_sw 15 AP / dmg mult | 92 / x2 | 150 / x1.45 |
| vex_item 8 price / value | 25 / 0 | 35 / 0 |
| vex_item 9 price / value | 30 / 30 | 45 / 20 |
| vex_item 10 price / value | 40 / 0 | 50 / 0 |
| vex_item 11 price / value | 30 / 0 | 40 / 0 |
| vex_item 14 price / value | 15 / 1000 | 15 / 1500 |
| vex_item 21 price / value | 30 / 2 | 40 / 2 |
| vex_item 26 price / value | 25 / 60 | 25 / 80 |

Notes:
- Zombie HP = (base + vex_zombie_hp_per_player * players) * class multiplier. Example with 12 players: infected Walker 1800 -> 2880, Tank 3240 -> 5184.
- Nemesis with 12 players: 15000 (old) -> 29400; Assassin 9600 -> 19600. Both still one-shot normal humans (vex_*_oneshot 1).
- Boss with 10 humans: 7000*mult + 15000 (old code default) -> 9000*mult + 25000.
- Income: damage AP 1 per 800 dmg (was 500), human win 5 AP. A good human round is about 25-30 AP, so a mid special weapon (80-120 AP) costs about 3-4 good rounds.
- VC: exchange 100 AP per VC (was 60), boss kill / achievement 2 VC (was 3), perk step 5 VC (was 4).
- Knockback: all bullets x0.75 (vex_knockback_mult), Voidcaller x1.5 instead of x2.0.
- Single-bullet damage cap vs boss/nemesis/assassin 1500 (was 3000).
