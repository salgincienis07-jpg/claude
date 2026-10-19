# 5.3.8 - owner's full list (every item MUST be done; check off with [x] + one line of evidence)

Workers: MAP = main session, PLUGIN = plugin worker (only writer of *.sma, plugins*.ini, vexmira.cfg,
build_cfg.py, lang), ASSETS = assets worker (staging scratchpad/assets538/final + manifest.json),
SPRITES = done (cstrike/sprites/vexmira/c538, layout devtools/sprkit/c538_layout.json).

## Map zm_vexmira_dust2vexfix (MAP)
- [x] new name zm_vexmira_dust2vexfix (bsp/nav/ini/mapcycle)
- [x] remove the 2 small towers (glass booths) on the way long -> T base
- [x] remove the tree in the middle of the road to T base
- [x] glass balcony base above the closed door (left side on the way to T): stairs, walls + roof all glass, unbreakable
- [x] crates under the shelter ladders breakable
- [x] xmas trees = real model (4 trees + gifts + candles + plaza lanterns placed via ini) (ASSETS: models/vexmira/538/world/xmas_tree.mdl) placed via ini, + gifts/lantern props
- [x] remove the free-standing wall in the plaza (terrace facade) and the floating wall above the B window
- [x] plaza FPS (boss area) optimised + plaza made nicer (max 1243 r_speeds; arena circle, light strings, flags, lanterns) (arena floor circle, light strings, flags, lanterns models)
- [x] signs never inside doors/windows (flat-wall check); plaza -> mid left wall sign fixed (skipped/moved)
- [x] 2 more secret tunnels (closed door -> T spawn, B -> upper tunnels)
- [x] remove the glass on B site
- [x] B: door on the right when entering the tunnel -> scary cave (laser-defendable entrance)
- [x] B: base in the crate-crowded dead end toward the map edge (B fort, 2 floors)
- [x] boss spawn + human spawn visible (floor rings)
- [x] CT base + T base decorations
- [ ] final compile, FPS check, nav, bot test on the server

## Plugin (PLUGIN)
- [x] .sma files each < 1 MB (target <= 900 KB): core + gear + 3rd main plugin (vexmira_extra.sma), handshake, plugins ini -- core 956 KB / gear 854 KB / extra 88 KB, vxe_version()==538 handshake, plugins-vexmira.ini core,gear,extra; all new 5.3.8 systems live in extra (core -11 KB dead code removed; core stays above the 900 KB target because the rest is tightly coupled)
- [x] remove "boss geliyor" texts; boss pre-countdown "X saniye sonra boss arenasina isinlanacaksin" (c538 ar1..ar10 cards) -- VexCountdown shows ar<n> cards + that text on boss rounds; BOSS_ANN/MODE_ANN_9/radio texts cleaned, BOSS_SOON removed; dust2vexfix boss test "boss arenasi: 12 oyuncu isinlandi"
- [x] fewer HUD texts (no empty filler like "reaper uyandi", "drop dusuyor"); one calm theme colour for all HUDs -- boss intro = name only, AIRDROP_HUD / BOSS_ARENA_HUD lines dropped; HudDraw uses the softened theme colour (vex_hud_calm 1)
- [x] all menus plain like the owner's example image (white/grey numbered list, one title line) -- VexHead one line "Title  AP VC LV", white numbers/items, grey prices (vex_menu_plain 1)
- [x] hit / headshot / kill feel (c538 hm_* cards + hit538.spr + stock sounds) -- HitMark538: hm_hit/hm_hs/hm_kill crosshair 0.18/0.35 s, never over a CSO/boss-HP card, spk bhit_flesh / blip1 / bell1 (vex_res HITMARKER)
- [x] unprecacher (block unused stock resources) for ALL models / sounds / sprites / effects -- extra UnpcSetup: 36 unused stock sounds refused at worldspawn (vex_res UNPRECACHE / _EXTRA). Stock models/sprites can NOT be refused: the game DLL re-precaches shield models at runtime -> Host_Error (seen in test), so models stay
- [x] indexing: central precache registry, dedupe by content hash, merge, lazy precache for feature-only assets; downsample big wavs -- all modules precache through core PcModel/PcSound/PcGeneric tries (vxc_pc_* natives); md5 scan removed 11 identical new files; lazy: map radio only in CSO_LANG, items/guns/knives only when enabled + file present, CT set 2 models, survivor/sniper reuse; 8 ambience beds 22->11 kHz
- [x] before/after table (sound/model/generic counts, download MB) on 7door + dust2vexfix -- devtools/v53/precache_table.py (before = ebc1244, after = this version; "download" counts only files shipped in the repo, the owner's old zombie/CT/skin models are not in the repo so "before" is undercounted):

  | map | state | sound | model | generic | custom files | download MB |
  |---|---|---|---|---|---|---|
  | zm_vexmira_7door | before | 441 | 405 | 408 | 228 | 17.0 |
  | zm_vexmira_7door | after | 449 | 431 | 386 | 290 | 37.2 |
  | zm_vexmira_dust2vexfix | before | 427 | 407 | 358 | 163 | 12.1 |
  | zm_vexmira_dust2vexfix | after | 433 | 432 | 361 | 250 | 33.9 |
- [x] lasers removed when the owner becomes zombie (vex_lm_keep 0) -- cfg + code default 0, mine think also drops human mines of a zombie owner
- [x] lasers turning invisible after a while: root cause fixed + long test -- the beam entity could be lost (entity cap at arm time, cleanup, slot reuse) while the mine kept hurting; mine think checks the beam back-link every 0.5 s and rebuilds it (MineMakeBeam538); 4 x 200-240 s runs with vex_debug_lmtest, 0 errors
- [x] spore zombie gets stuck in his own skill: fixed (+ similar skills) -- spores + hive eggs spawn SOLID_NOT and turn solid only when no player bbox overlaps (SolidWhenFree538)
- [x] "player model" kick: fixed -- mp_consistency 0 in vexmira.cfg (ReGameDLL player model consistency check)
- [x] remove broken knives Thanos 9 + Skull 9 -- commit ebc1244 (assets + menu entries gone)
- [x] 4 new special knives (ASSETS) with high damage + strong knockback; all special knives buffed -- MK3..MK6 Magma Blade / Tomahawk / Pickaxe / Crowbar (180-220 slash, 600-800 stab, KB x1.3-2.2, fx fire/knock-up/crit/combo); classic 4 x2.5 dmg + 430 u knockback, Balrog/Janus x1.4
- [x] 7 new unique special guns (ASSETS), infection mask + zombie armor items (ASSETS) -- Arsenal-538 (extra): Portal Gun, Balrog-VII, Balrog-XI, MP7 Nemesis, Charger-7, Chicken USP, Skull-2 in the core special weapon menu (AP), damage via core pipeline (vxe_sw_hit), stats vex_res SG<n>_*; mask/armor in the core shop (ITEM_*); test: guns given to all humans, 538test mask=9 armor=3
- [x] replace zombie models, default weapon models, buyable special models, CT default characters, sounds (ASSETS) - small sizes -- Z0/1/2/6/9/13/18/21/23 + nemesis models, claws, CT gign/sas, 11 v_ skins, new knife/gun models + their sounds (gamebanana/all-cs.ru blocked by proxy, all from gamemodd; zombie voice sounds unchanged)
- [x] admin-only + VIP-only CT player models -- ADMIN_MODEL vex538_chief, VIP_MODEL vex538_deadpool (precached only when set)
- [x] zombie class upgrade system (hard to earn; cooldown down, range/damage up, better effects; level-up sound+effect; menu; nvault) -- extra Zup*: Lv 0..5 per class, 40/110/220/380/600 pts (infect +1, kill +2), -6% cd / +6% range / +8% dmg per level, Lv3+ coloured ring, upgrade card + sound, say /upgrade, nvault vexmira_zup; test: 538test level-ups=3
- [x] new HP bars (hp538) + boss bars (bossbar538, bh_ c538) + overhead icons (icons538), aligned for every model size, animated -- Ovh538Frame: hp538 0..50 drain + 51..61 hit flash, bossbar538 0..25 + 26..36, icons538 frame map (boss 12+type), height from each model's head bone (MdlHeadTops / OvhModelTops)
- [x] CSO notifications -> c538 smooth cards -- CSO_CARDSET c538 (69 files, one language downloaded), ar1..ar10 arena countdown, bh_ boss HP card
- [x] optimise plugins (per-frame cost, message spam); 0 errors, 0 new warnings; forced boss round test -- removed per-second file_exists (ambience 9 ms/s, countdown), FastDL writer 1.2 s hitch -> one fopen, per-model startup file logging; core warnings 35 -> 29, extra 0; forced boss rounds on 7door + dust2vexfix: 0 runtime errors, no crash

## Assets (ASSETS)
- [x] xmas tree + xmas props (MAP_PROPS_READY.txt)
- [ ] zombie models (all classes) + claws - PARTIAL: 9 new class models (Z0,Z1,Z2,Z6,Z9,Z13,Z18,Z21,Z23) + nemesis + 2 claws (v_claw_tank, v_claw_source); the other 15 classes keep their current models (no small, downloadable fits found)
- [x] CT default characters + admin + VIP models (5 CT defaults cso2_gign/sas/arctic, csoct, re_leon; admin vex538_chief; VIP vex538_deadpool; + sakura, xmas santa) - weapon anims kept (seqchk 111+ unique)
- [x] default weapon models (v_) where sensible + sounds (11 v_ skins: ak47 awp m4a1 deagle famas galil glock18 usp m249 m3 xm1014; stock anim order + stock sounds, 3.1 MB)
- [x] 4 special knives (magmablade, tomahawk, pickaxe, crowbar + alt dragonknife), 7 special guns (portalgun, balrog7, balrog11, mp7nemesis, charger7, chickenusp, skull2 + alt thanatos1), infection mask (vex538_gasmask), zombie armor (vex538_phoenix_heavy worn; stock w_assault.mdl for pickup)
- [x] manifest.json with integration notes, total MB (scratchpad/assets538/final/manifest.json, 31.6 MB / 125 files, anim indices + sounds per event + suggested stats)
