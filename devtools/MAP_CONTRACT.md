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
roundtime = 6       ; istege bagli: bu haritada mp_roundtime (dakika, ondalik olabilir)
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
[locks]             ; istege bagli: <func_button targetname> = <gerekli gorev 1-3> <[messages] anahtari>
reactor_btn = 1 locked_reactor
[hints]             ; istege bagli: ayni bicim; gorev acikken round basina ILK basista insanlara ipucu
fuse_a = 1 fuse_half
```
Olaylar: round_start freeze_end infection boss boss_dead nemesis assassin survivor lasthuman win_humans win_zombies minute.

## Eklenti davranisi (aciklamalar, isim / bicim degismez)
- Tetik: eklenti hedefi `Use(aktivator = dunya, USE_TOGGLE)` ile tetikler (vexprobe_fire varsayilani gibi).
  Isik / kapi gibi toggle hedeflerinde durum gerekiyorsa araya `triggerstate` 0/1 olan bir trigger_relay koy.
- vex_round_start harita varliklari geri yuklendikten ~0.2 sn sonra gelir; haritanin ilk roundunda bir kez
  daha (harita acilisindan 1 sn sonra) gelebilir: sifirlama mantigi iki kez calissa da ayni sonucu vermeli.
- vex_infection her modda mod basinda gelir; ardindan moda gore vex_nemesis / vex_assassin / vex_survivor
  (sniper = survivor, plague = nemesis + survivor). vex_boss boss secilince, vex_minute freeze sonundan
  itibaren her 60 sn (round bitene kadar).
- Hedef listeleri harita basinda bir kez kurulur: vex_* / [events] hedefleri sonradan olusturulan varliklar olamaz.
- vexcmd_* sadece trigger_relay sinifinda calisir; tanimsiz isim (anahtari [messages]'ta olmayan msg, n > 50
  odul) log'a bir satir yazilip yok sayilir. Odul: round bittikten sonra verilmez. Mesaj: ayni relay 4 sn,
  herhangi iki mesaj arasi 1 sn (fazlasi atlanir).
- [markers]: n. isaret n. goreve aittir (gorev acikken gorunur, tamamlaninca kalkar); karsiligi olmayan isaret
  round boyunca gorunur. En fazla 4 isaret; koordinat oyuncu goz hizasinda (zeminden ~64) bir nokta,
  isaretin uzerinde 360 birimlik dikey isik sutunu cizilir (tavan altina koyma). Sadece insanlar gorur.
- [locks]: gorev n bu roundda tamamlanmadiysa butona basan oyuncuya mesaj (oyuncu basina 2 sn'de bir;
  butonu eklenti kilitlemez, gercek kilit haritadaki `master` ile yapilir, kilit sesi icin `locked_sound`).
  [locks] bolumu varsa (ya da [info] `sequential = 1`) gorevler SIRALIDIR: sadece ilk acik gorevin isareti
  gorunur (1 bitince 2 cikar...), freeze sonu listesinde bitenler [OK], simdiki "> n/N", sonrakiler (kilitli).
  `sequential = 0` ile kapatilir. [locks] yoksa eski davranis (tum acik gorevlerin isareti).
- [info] `roundtime = <dk>`: harita yuklenince (ve cfg her yeniden yuklendiginde) mp_roundtime bu degere
  ayarlanir; satiri olmayan haritada vexmira.cfg degeri (veya vex_roundtime > 0 ise o) gecerlidir, ezilen
  deger sonraki haritada geri yuklenir. 0 / yok = dokunma. Buyuk haritada gorevlerin bitebilecegi sure ver.
- [hints]: gorev n acikken o gorevin [hints] butonlarindan round icinde ILK basilanda tum insanlara mesaj
  (or. iki salterden biri: "1/2 - digerini indir"). Butonlar ve anahtarlar harita basinda cozulur; bulunamayan
  satir log'a yazilip yok sayilir. En fazla 8 [locks]+[hints] satiri.
- Metin uzunlugu: satirlar ekranda tek satir okunmali (<= ~90 karakter; 111 uzeri kesilir).
  Satir icinde " ;" yorum baslatir. Eksik dil diger dilden doldurulur.
- Hikaye/gorev kapatma ve test: cvar'lar vex_map_story / vex_map_objectives / vex_map_markers /
  vex_map_rewards / vex_map_events / vex_map_debug (vexmira.cfg), sunucu komutu vex_map_status.
- Test (devtools/server): vexmira.cfg ~13 sn sonra yeniden yuklenir, vex_map_debug 2 komutunu ondan sonra ver;
  botlar sohbet komutu kullanamaz: hikaye icin `vexprobe_call #1 cmd_MsStory`; relay icin `vexprobe_fire vexcmd_...`.

## Round sifirlama
trigger_once kalici olarak silinir. Her round calismasi gereken set piece'ler icin func_button / trigger_multiple /
multi_manager / func_door / func_breakable / func_train ve vex_round_start ile acik sifirlama kullan;
test sunucusunda en az 3 round dene (devtools/server/vexprobe.sma: vexprobe_fire <targetname>).
