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
- [ ] .sma files each < 1 MB (target <= 900 KB): core + gear + 3rd main plugin (vexmira_extra.sma), handshake, plugins ini
- [ ] remove "boss geliyor" texts; boss pre-countdown "X saniye sonra boss arenasina isinlanacaksin" (c538 ar1..ar10 cards)
- [ ] fewer HUD texts (no empty filler like "reaper uyandi", "drop dusuyor"); one calm theme colour for all HUDs
- [ ] all menus plain like the owner's example image (white/grey numbered list, one title line)
- [ ] hit / headshot / kill feel (c538 hm_* cards + hit538.spr + stock sounds)
- [ ] unprecacher (block unused stock resources) for ALL models / sounds / sprites / effects
- [ ] indexing: central precache registry, dedupe by content hash, merge, lazy precache for feature-only assets; downsample big wavs
- [ ] before/after table (sound/model/generic counts, download MB) on 7door + dust2vexfix
- [ ] lasers removed when the owner becomes zombie (vex_lm_keep 0)
- [ ] lasers turning invisible after a while: root cause fixed + long test
- [ ] spore zombie gets stuck in his own skill: fixed (+ similar skills)
- [ ] "player model" kick: fixed
- [ ] remove broken knives Thanos 9 + Skull 9
- [ ] 4 new special knives (ASSETS) with high damage + strong knockback; all special knives buffed
- [ ] 7 new unique special guns (ASSETS), infection mask + zombie armor items (ASSETS)
- [ ] replace zombie models, default weapon models, buyable special models, CT default characters, sounds (ASSETS) - small sizes
- [ ] admin-only + VIP-only CT player models
- [ ] zombie class upgrade system (hard to earn; cooldown down, range/damage up, better effects; level-up sound+effect; menu; nvault)
- [ ] new HP bars (hp538) + boss bars (bossbar538, bh_ c538) + overhead icons (icons538), aligned for every model size, animated
- [ ] CSO notifications -> c538 smooth cards
- [ ] optimise plugins (per-frame cost, message spam); 0 errors, 0 new warnings; forced boss round test

## Assets (ASSETS)
- [x] xmas tree + xmas props (MAP_PROPS_READY.txt)
- [ ] zombie models (all classes) + claws
- [ ] CT default characters + admin + VIP models
- [ ] default weapon models (v_) where sensible + sounds
- [ ] 4 special knives, 7 special guns, infection mask, zombie armor
- [ ] manifest.json with integration notes, total MB
