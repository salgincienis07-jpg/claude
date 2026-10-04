# Harita <-> eklenti sozlesmesi (3.1)

Haritalar ve eklenti bu sozlesmeye gore birbirleriyle konusur. Iki taraf da tam bu isimleri kullanir.

## (a) Eklenti -> harita
Su olaylarda eklenti, targetname'i asagidaki olan TUM varliklari tetikler (trigger_relay gibi Use):
vex_round_start (yeni round, oyun harita varliklarini geri yukledikten sonra: set piece'leri burada SIFIRLA),
vex_freeze_end, vex_infection (ilk zombi / mod basladi), vex_boss, vex_boss_dead, vex_nemesis, vex_assassin,
vex_survivor, vex_lasthuman, vex_win_humans, vex_win_zombies, vex_minute (round icinde her 60 sn).

## (b) Harita -> eklenti
Sinifi MUTLAKA trigger_relay olan ve targetname'i su olan varliklar:
- vexcmd_msg_<key>: haritanin [messages] bolumundeki <key> metni herkese hikaye satiri + ses olarak gosterilir
- vexcmd_reward_h_<n>: yasayan her insana n ammo pack (n <= 50; her relay round basina bir kez)
- vexcmd_reward_z_<n>: ayni sey zombiler icin
- vexcmd_obj_<1-3>_done: n. gorev tamamlandi (duyuru + ses, round basina bir kez)

## (c) Harita senaryo dosyasi
cstrike/addons/amxmodx/configs/vexmira_maps/<harita>.ini (latin-1/ASCII, Turkce harfsiz):
```
[info]
name_en = ...
name_tr = ...
[story_en]          ; en fazla 6 "line = ..." (ilk dogusta bir kez daktilo efektiyle, /story ile tekrar)
line = ...
[story_tr]
line = ...
[objective_en]      ; en fazla 3 "line = ..." (her round freeze sonunda, tamamlanma durumu ile)
line = ...
[objective_tr]
line = ...
[messages]          ; <key> = English | Turkce
reactor = Reactor online! | Reaktor calisiyor!
[events]            ; <olay> <gecikme sn> <targetname>
boss 0 lab_alarm
[markers]           ; istege bagli: <ad_en> | <ad_tr> = x y z (gorev acikken insanlara yon gosteren isaret)
Reactor | Reaktor = 0 512 64
```
Olaylar: round_start freeze_end infection boss boss_dead nemesis assassin survivor lasthuman win_humans win_zombies minute.

## Round sifirlama
trigger_once kalici olarak silinir. Her round calismasi gereken set piece'ler icin func_button / trigger_multiple /
multi_manager / func_door / func_breakable / func_train ve vex_round_start ile acik sifirlama kullan;
test sunucusunda en az 3 round dene (devtools/server/vexprobe.sma: vexprobe_fire <targetname>).
