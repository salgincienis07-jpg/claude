# Vexmira Zombie - DEVIR TESLIM (baska bir yapay zeka / gelistirici icin)

Bu belge 3.1 paketinden sonra KALAN TUM isleri anlatir. Depo: bu repo, branch `claude/zombie-boss-mode-dev-a0m5oq`.
Son gonderilen paket: Vexmira_Zombie_v3.1.zip (hata duzeltmeleri, otomatik takim, cfg model rehberi). Eklenti kaynagi sonra yeniden TEK dosyaya birlestirildi (asagiya bak).

## 1. Proje ozeti
- CS 1.6 (GoldSrc) zombi modu. Sunucu: ReHLDS + ReGameDLL 5.30 + Metamod + AMX Mod X 1.10 + ReAPI 5.26.
- Tek eklenti, TEK kaynak dosya: `cstrike/addons/amxmodx/scripting/vexmira_zombie.sma` (13 bolum: dosyada
  `BOLUM n/13` ara: CORE, FX, HUD, KAYNAKLAR, ISTATISTIK, EKONOMI, SILAHLAR, ZOMBILER, BOSSLAR, MODLAR,
  OYUNCULAR, ADMIN, HARITALAR). Hangi kod nerede: `devtools/plugin/MODULES.md`. TEK .amxx olarak derlenir.
  KURAL: kodu ASLA ayri `#include "..."` dosyalarina bolme. Sahip eklentiyi tek basina derliyor; 3.1'de
  `vex/*.inc` diye bolununce derleyici dosyalari bulamadi ve "hicbir sey calismiyor" dedi. Tek dosya kalacak.
- Tum ayarlar tek dosyada: `cstrike/addons/amxmodx/configs/vexmira.cfg` (Turkce aciklamali).
- Tum oyuncu metinleri EN + TR: `cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt` (Turkce harfsiz yazilir: s, g, i, o, u, c).
- Tasarim sozlesmesi: `devtools/DESIGN_v3.md`. Ilerleme / gecmis: `devtools/PROGRESS_v3.md`.
- Harita <-> eklenti sozlesmesi: `devtools/MAP_CONTRACT.md` (gorev 3 ve 4 buna gore yapilir).
- Araclar: harita kiti `devtools/mapkit/` (Python ile brush harita yazar, SDHLT ile derler, `bspcheck.py --perf` FPS olcer),
  model kiti `devtools/mdlkit/` (Python ile GoldSrc .mdl uretir, HLSDK studiomdl), ses `devtools/sfx/`, sprite `devtools/sprkit/`,
  test sunucusu `devtools/server/` (run_test.py: botlu otomatik test, ozet: calisma zamani hatalari, precache sayilari, takilan botlar).

## 2. Derleme ve test (ONEMLI)
- Derleyici: AMX Mod X 1.10 `amxxpc` + ReAPI 5.26 include dosyalari. Derleme:
  `amxxpc vexmira_zombie.sma -i<amxx include dizini> -i<scripting dizini> -o vexmira_zombie.amxx`
  (`devtools/plugin/build_plugin.sh` bunu yapar; icindeki T= yolunu kendi amxxpc dizinine gore duzelt). 0 hata / 0 uyari olmali.
- Test sunucusu kurulumu: `devtools/server/README.md` (ReHLDS + ReGameDLL + Metamod + AMXX + ReAPI, botlarla).
  Ornek: `VEX_SERVER=<sunucu> python3 devtools/server/run_test.py --map zm_vex_laboratory --seconds 300 --bots 16 --commands devtools/server/sessions/full_session.txt --rebuild-plugin`
- Her degisiklikten sonra: derleme 0/0, botlu tam test 0 "AMXX RUN-TIME ERRORS", precache toplam ses <= 490/512, model <= 470/512.
- Paketleme: `devtools/release/pack31.sh` (v1 oyuncu modelleri, pence modelleri, p_ak47, pilot haritasi HARIC).

## 3. Kurallar
- Sahibin istegi: her sey ozgun, detayli, profesyonel; FPS cok iyi; yon/hizalama hatasi olmayacak (orn. kanca ters gitmesin);
  sunucuya girerken uzun indirme olmasin (yeni dosyalar kucuk); her ayar vexmira.cfg'de, her metin EN+TR.
- Bilinen motor kisitlari: sunucu eklentisi oyuncunun ekranina keyfi 2D resim CIZEMEZ (bkz. gorev 2); MOVETYPE_FOLLOW sprite'lar
  oyuncunun belinde cizilir (kafa ustu icin AddToFullPack kullaniliyor); TE_PLAYERATTACHMENT sprite'i her zaman normal modda cizilir.
- Kucuk, hedefli duzenlemeler yap; dosyalari scriptle bastan yazma. Her adimdan sonra commit.

## 4. Gorevler (oncelik sirasina gore)
Asagidaki gorev tanimlari ayrintili spesifikasyondur (Ingilizce). Her gorevin sonunda: derle, botlu test, commit, kisa rapor.

### 1. OZEL SILAH SISTEMI (oncelik 1)

```
TASK: data-driven special weapon framework (SILAHLAR section of the .sma + cfg + lang). The owner will replace/add special weapons with downloaded models and asked: "will sounds, animations and effects work automatically?" Make that true:
- every special weapon defined in vexmira.cfg (keep the 8 current ones as defaults, allow up to 16): EN/TR name, base CS weapon, price, team/limits, v_/p_/w_ models, fire sound(s), optional draw/reload sounds, damage multiplier, clip/ammo, fire rate, recoil, effect type (plasma/fire/ice/lightning/void/explosive/none) with tracer, impact and muzzle sprite + colour;
- animations automatic: at precache read the v_ model's studio header (sequence names/count) and map idle/shoot/reload/draw by name patterns, falling back to the base weapon's standard indexes; play the right animations even when a custom model's sequence order differs;
- sounds automatic: if the shoot sequences have sound events (5001/5004 etc.) do not double them, otherwise play the configured fire sound; precache only existing files, safe fallbacks;
- a Turkish "Ozel silah ekleme rehberi" in vexmira.cfg (step by step).
Prove it with a stock v_ model of another weapon used as a "custom" model (different sequence order): log the detected mapping and show the correct sequences/sounds are used when firing/reloading/drawing. Compile 0/0, full session 0 runtime errors, commit.
```

### 2. GRAFIK HUD (oncelik 2)

```
TASK: HUD redesign (HUD section of the .sma, new sprites under cstrike/sprites/vexmira/ made with devtools/sprkit in the Vexmira purple + cyan palette, cfg, lang). Owner: "replace the top info HUD (round counter, zombie vs human counts, boss), the right-side HUD (level, HP, armor, XP, AP, VC, streak, profession, quest) and the end-of-round MVP text with special graphic gauges like the boss health bars, unique; no text HUD at all."
Engine reality: a server plugin cannot draw arbitrary 2D images on the client screen. Available: native HUD elements (health, armor, money (already shows AP), round timer, radar, BarTime/BarTime2 progress bar, StatusIcon icons that exist in the client's hud.txt, weapon/ammo icons and crosshair via custom sprites/weapon_*.txt + WeaponList), world-space sprites/models (like our overhead boss bars), screen fades, HUD/DHUD text. Research what CS 1.6 servers really do for graphic HUDs and implement the best achievable no-text design: native elements where they already show the value, graphic world-space elements and native progress bars where they fit (e.g. XP progress via BarTime2 on gain, MVP crown sprite + flash above the MVP at round end instead of text, round/boss state via graphic elements), details on demand (menu). Keep readability and performance (no per-frame message spam). Everything must be switchable back from vexmira.cfg: vex_hud_style (0 = classic Vexmira text HUD exactly as before, 1 = new graphic HUD (default), 2 = default CS look: no custom HUD panels, only the game's native HUD) plus a per-element override for each part (top info, right panel, MVP, XP/progress, overhead bars/icons, story/objective lines) with values like -1 = follow vex_hud_style, 0 = off, 1 = text, 2 = graphic where applicable; document all of it in Turkish in vexmira.cfg and make sure changing them at runtime (or on map change) works. In the report state clearly which parts became graphic and which could not and why (the owner will read it). Compile 0/0, full session 0 runtime errors, commit.
```

### 3. HARITA <-> EKLENTI KONUSMASI (oncelik 3)

```
TASK: implement the plugin side of devtools/MAP_CONTRACT.md in the HARITALAR section of the .sma: fire vex_* targetnames on the listed events; hook Use of trigger_relay for vexcmd_* (msg/reward/objective, once per round each, cheap); load configs/vexmira_maps/<map>.ini (info, story typewriter on first spawn + /story, objectives at freeze end with completion state, messages EN|TR by player language, extra [events], optional [markers] shown to humans as a guiding world-space sprite while the objective is open). Robust parsing (missing file = off), cvars to toggle, light on CPU/network. Test with zm_vex_laboratory and its .ini (fire relays with vexprobe_fire) for 3 rounds. Compile 0/0, full session 0 runtime errors, commit.
```

### 4. LABORATUVAR: FPS + ETKILESIM + HIKAYE (oncelik 4)

```
TASK: improve the EXISTING zm_vex_laboratory (devtools/mapkit/maps/zm_vex_laboratory.py; do not redesign it) so it has a story flow and good FPS: (1) FPS: run devtools/mapkit/bspcheck.py --perf on the current bsp, then fix the worst views (more VIS blocking with walls/bends/hint brushes, fewer light styles/env_sprites, simplify heavy detail in open areas) until the perf report is clearly better; (2) interactivity per devtools/MAP_CONTRACT.md: 3-5 set pieces (e.g. story terminals -> vexcmd_msg_*, a reactor/power objective with buttons -> vexcmd_obj_1_done + vexcmd_reward_h_10 + door/lights, alarm lights + shake on vex_boss, red emergency lights on vex_lasthuman), all reset on vex_round_start; (3) write cstrike/addons/amxmodx/configs/vexmira_maps/zm_vex_laboratory.ini (EN+TR story, objectives, messages, events, markers). Compile final, bspcheck OK, regenerate .nav (run_test.py --nav-all --force-nav --maps laboratory), one 200 s bot run with --no-rebuild on server <test-sunucun> port 27035 (0 errors, check stuck spots), test the relays with vexprobe_fire if available. Commit.
```

### 5. OPTIMIZASYON + SON KONTROL (oncelik 5)

```
TASK: optimize the plugin (server CPU and, importantly, CLIENT FPS load it causes) without changing behaviour. Baseline: devtools/plugin/PERF_BASELINE.md. Look at per-frame forwards (PreThink/PostThink/AddToFullPack/CmdStart/thinks/tasks: early exits, cached values, bitsums, no string formatting in hot paths), entity counts (overhead sprites, projectiles, beams), TE effect spam and dynamic lights (TE_DLIGHT is expensive for clients), env_sprite glows, screen fades, HUD message frequency/size, sending effects only to clients that can see them (PVS/PAS), per-player rate limits. Measure after with the same 300 s / 31 bots / --no-debug run (+ the HLTV proxy as a real client if practical) and write devtools/plugin/PERF_v31.md (before/after, list of changes, and a concrete answer whether splitting into several .amxx plugins would help - the source is one file with 13 sections inside one plugin). Then a final regression pass over this part's changes: full session on zm_vex_laboratory (480 s, 16 bots) with 0 runtime errors, EN/TR lang completeness for new keys, precache totals. Update devtools/PROGRESS_v3.md. Commit.
```

### 6a. JETPACK / RPG MODELLERI

```
YOUR AREA: item models with devtools/mdlkit (new content module devtools/mdlkit/content/items.py). Server: kendi test sunucun. Client renderer agent report:
(yok - kendi test sunucunu kullan)
Build, professional and detailed (bevels, panels, decals, wear, glowing parts; compact 8-bit textures; each file <= ~180 KB):
- cstrike/models/vexmira/items/p_jetpack.mdl: Vexmira jetpack worn on the back; it is attached to the player with MOVETYPE_FOLLOW, so it must bone-merge onto the stock CS player skeleton: include the exact CS player bone names from mdlkit rig_cs up to the spine bone it sits on and parent the jetpack geometry to the upper spine; attachments 0 and 1 at the two nozzle exits (flames are plugin sprites). Sequences: idle, fly (subtle vibration / flaps). Verify the merge visually with a stock-like CS player in idle, run and crouch poses.
- cstrike/models/vexmira/items/w_jetpack.mdl: the same jetpack lying on the ground (origin at the bottom centre, +X forward), sequence idle.
- cstrike/models/vexmira/items/v_rpg.mdl: first-person RPG with the Vexmira CT arms used by the other v_ models (devtools/mdlkit/content/weapons.py); sequences named exactly: idle, draw, shoot, reload (plugin maps by name); correct view framing at 90 FOV.
- cstrike/models/vexmira/items/p_rpg.mdl (third person, bone-merge like other p_ models in devtools/mdlkit/pmodel.py) and w_rpg.mdl (on the ground).
- cstrike/models/vexmira/items/rocket.mdl: rocket projectile, +X forward, origin at its centre, attachment 0 at the tail (trail start), sequence idle (spinning fins or glow pulse).
Render previews (devtools/previews_items_v3.png), run mdlkit validation, a short server test that precaches them (add them temporarily via a test plugin or check with the vexprobe precache dump) and, if the client renderer exists, screenshots. Commit.
```

### 6b. JETPACK + RPG (market)

```
YOUR AREA: market items Jetpack and RPG (EKONOMI + SILAHLAR sections, cfg, lang). Server: kendi test sunucun. Previous plugin work:
(yok - kendi test sunucunu kullan)
Item model builder report (models at cstrike/models/vexmira/items/: p_jetpack, w_jetpack, v_rpg (sequences idle/draw/shoot/reload), p_rpg, w_rpg, rocket):
(yok - kendi test sunucunu kullan)
Owner: "add a JETPACK to the market: when the owner dies it falls to the ground and can be picked up; it fires a missile with RIGHT CLICK (like the classic one); and add an RPG to the market, custom designed."
Jetpack: humans only, AP price + round limit in cfg; worn model on the back (p_jetpack via MOVETYPE_FOLLOW bone merge; hidden for its owner in first person); flying while holding JUMP in the air (or the classic duck+jump; choose and document) with fuel that drains and recharges, thrust physics that feel good, nozzle flame/smoke sprites, looping thrust sound; RIGHT CLICK (attack2) while holding the knife fires a rocket (rocket.mdl, trail, explosion damage + knockback to zombies, cooldown, ammo/charge in cfg); on death it drops as w_jetpack at the body with remaining fuel and humans can pick it up by walking over it (and zombies cannot); removed on infection (drops), cleaned up at round end; no flying for zombies; respect the owner's other movement items (parachute etc.).
RPG: a special weapon using the special-weapon framework if suitable (v_rpg idle/draw/shoot/reload, p_/w_ models, rocket projectile, big explosion with sprite + sound, limited rockets, reload time), market entry with price/limits in cfg, EN/TR texts. Both: sounds (use existing project sounds or generate new ones with devtools/sfx tools; keep them small), precache budget respected. Add an admin/test console command to give items to a player for testing; test with bots (give items, make bots fly via the command or a test hook) and with HLTV telemetry; compile 0/0, full session 0 runtime errors, commit.
```

### 7a. 5 PET MODELI

```
YOUR AREA: 5 animated cosmetic PET models with devtools/mdlkit (new module devtools/mdlkit/content/pets.py). Server: kendi test sunucun. Previous model work:
(yok - kendi test sunucunu kullan)
Pets float next to their owner's shoulder (the plugin moves them). Stylized, unique, very polished (the owner calls procedural blocky models amateurish: use smooth silhouettes, faceted "low-poly art" style done deliberately, gradients, rim highlights, glowing emissive parts with additive/fullbright textures where supported). Files and designs (exact names):
 cstrike/models/vexmira/cosmetics/pet_drone.mdl - Vex Drone: hovering mini combat drone, 4 spinning rotors, cyan scanning eye.
 cstrike/models/vexmira/cosmetics/pet_wisp.mdl - Void Wisp: glowing purple crystal core with orbiting crystal shards.
 cstrike/models/vexmira/cosmetics/pet_dragon.mdl - Ember Dragonling: small flying dragon, flapping wings, swaying tail, ember glow.
 cstrike/models/vexmira/cosmetics/pet_owl.mdl - Frost Owl: stylized faceted owl, flapping, icy blue glow.
 cstrike/models/vexmira/cosmetics/pet_jelly.mdl - Neon Jellyfish: bioluminescent floating jellyfish with pulsing bell and trailing tentacles.
Each: origin at the body centre, +X forward, about 10-18 units long; sequences named exactly idle (hover/breathing loop), move (fast-follow loop), happy (one-shot celebration, e.g. spin or loop-the-loop); smooth looping animation curves; each file <= ~150 KB. Contact sheet devtools/previews_pets_v3.png with 2-3 frames per sequence; mdlkit validation; client screenshots if available. Commit.
```

### 7b. 5 KANAT MODELI

```
YOUR AREA: 5 animated cosmetic WINGS models with devtools/mdlkit (new module devtools/mdlkit/content/wings.py). Server: kendi test sunucun. Previous model work:
(yok - kendi test sunucunu kullan)
Wings are attached to the player with MOVETYPE_FOLLOW and must BONE-MERGE onto the stock CS player skeleton: include the exact CS player bone names from mdlkit rig_cs (root chain up to the upper spine) and parent the wing bones to the upper spine so they follow crouch/run/lean; sit just behind the shoulder blades without clipping the body in idle/run/crouch/jump poses (check with a stock-like CS player model). Exact files and designs:
 cstrike/models/vexmira/cosmetics/wings_angel.mdl - white layered feathers with gold trim.
 cstrike/models/vexmira/cosmetics/wings_demon.mdl - dark bat membrane wings with bone fingers and claw tips.
 cstrike/models/vexmira/cosmetics/wings_phoenix.mdl - fiery feathers, glowing orange-yellow (additive/fullbright parts).
 cstrike/models/vexmira/cosmetics/wings_cyber.mdl - mechanical segmented plates with neon cyan lines.
 cstrike/models/vexmira/cosmetics/wings_frost.mdl - translucent ice-crystal shards with frost glow.
Feathers/membranes via masked or additive textures where it improves the look. Sequences named exactly: idle (slow breathing flap), run (folded back, slight bounce), fly (strong flaps for jumping/falling). Each <= ~200 KB. Contact sheet devtools/previews_wings_v3.png on a player in idle/run/crouch; mdlkit validation; client screenshots if available. Commit.
```

### 7c. PET + KANAT KOZMETIK (VC market)

```
YOUR AREA: pets + wings cosmetics in the coin (VC) market (EKONOMI section / cosmetics, cfg, lang). Server: kendi test sunucun. Previous plugin work:
(yok - kendi test sunucunu kullan)
Model reports (files: cstrike/models/vexmira/cosmetics/pet_drone|pet_wisp|pet_dragon|pet_owl|pet_jelly.mdl with sequences idle/move/happy; wings_angel|wings_demon|wings_phoenix|wings_cyber|wings_frost.mdl with sequences idle/run/fly, bone-merged to the CS player skeleton):
(yok - kendi test sunucunu kullan)
Add two cosmetic categories (pets, wings; 5 each) to the existing cosmetics menu (VC prices in cfg, VIP/elite discounts like the other cosmetics, owned bits + selected pet/wing saved backwards-compatibly with existing saved data). Behaviour: humans show their pet and wings; when infected they are removed (restored after respawn as human); wings: MOVETYPE_FOLLOW + aiment so the model bone-merges, sequence idle/run/fly from the owner's state (on ground still / moving / in air), hidden for the owner himself (first person) and spectators in eye view, hidden when the owner is invisible/dead; pets: separate entity floating smoothly near the owner's shoulder (not inside walls: trace and pull in), facing the owner's move direction, sequence idle/move by speed, happy on the owner's kills or level ups; cheap thinks (>= 0.05 s, skip when nothing changes); bots may get random cosmetics with a cvar (default off) for showcase. EN/TR names/descriptions. Test with bots (cvar on) + HLTV telemetry (positions, sequences, visibility), compile 0/0, full session 0 runtime errors, commit.
```

### 8a. HARITA TASARIM BELGESI (MAPS_v3.md)

```
YOUR AREA: the map bible. Server for experiments: <test-sunucun>, port 27015.
Write devtools/MAPS_v3.md (English, concise but complete) that five separate builder agents will follow. Contents:
1. Shared lore: the Vexmira corporation outbreak, one coherent timeline linking the 5 maps (each map = one chapter), tone (sci-fi horror; palette Vexmira purple + cyan, hazard orange accents).
2. For each map: zm_vex_laboratory (REVAMP and ENLARGE the existing one: keep its best areas, add new zones), zm_vex_harbor, zm_vex_ruins (ruined city), zm_vex_frostbase (arctic base), zm_vex_temple (ancient temple where the virus came from): chapter story (EN+TR, Turkish without special letters), 5-8 named zones with approximate dimensions and an ASCII layout plan, flow (human camps/defense spots vs zombie flank routes, boss arena, vertical levels), spawn areas (32 CT + 32 T), at least 5 interactive set pieces per map wired to the plugin contract (story terminals -> vexcmd_msg, objectives -> vexcmd_obj, rewards, alarms on vex_boss/vex_lasthuman, moving trains/lifts/cranes, breakable barricades, collapsing bridges, power/lights sequences, doors that zombies or humans can open, etc.), lighting mood, ambient sound plan (<= 10 sounds), sky (stock CS skies only), and the map script .ini content (story, objectives, messages, events) ready to paste.
   Make the maps feel BIG: larger footprints than the current laboratory (which is about 2700 x 2200 units), more distinct zones and verticality, but with sightlines broken up so FPS stays high.
3. Performance rules for GoldSrc that every builder must follow, concretely (VIS compartmentalization with bends/occluders, hint brushes, NULL on hidden faces, func_detail or func_wall/illusionary use if our SDHLT supports func_detail (check devtools/mapkit/build_sdhlt.sh and the built tools), clipnode-friendly collision, lightmap scale on big faces, limits on lights with styles, env_sprite counts, large open outdoor areas split by buildings) and numeric budgets: per-leaf visible world polygons (wpoly estimate) target and hard max, total faces, brush entities, texture count, bsp size.
4. Round-reset rules: find out on the test server (ReGameDLL) which entity classes are restored on round restart (func_door, func_button, func_breakable, func_train, trigger_once, trigger_multiple, multi_manager, env_*, ambient_generic, game_text...) and write the safe patterns. You may extend devtools/server/vexprobe.sma (a small test-only plugin used by run_test.py; build it the same way run_test.py does) with server commands such as "vexprobe_fire <targetname>" (Use all entities with that targetname) and "vexprobe_ents <classname>" (dump state: origin, solid, effects, health, toggle state) so builders can test interactivity from --cmd.
5. A per-map checklist the verifiers will use.
Keep it practical; builders get only this document plus the toolkit.
```

### 8b. YENI HARITALAR (liman, yikik sehir, karli us, tapinak) - her biri icin

```
YOUR AREA: the map zm_vex_<...> ONLY (its mapkit module, cstrike/maps/zm_vex_<...>.bsp/.nav/.res, its sounds under cstrike/sound/vexmira/map/, its map script cstrike/addons/amxmodx/configs/vexmira_maps/zm_vex_<...>.ini, previews under devtools/previews_maps_v3/). Shared toolkit files (mapwriter.py, textures.py etc.) may get small backwards-compatible additions only; other builders work in parallel. Server: <test-sunucu-dizini>/<...>, port <...>.
(yok - kendi test sunucunu kullan)
Follow devtools/MAPS_v3.md (the map bible) for this map exactly: story, zones, layout, set pieces, ini, lighting, sounds, budgets and performance rules. Build it to a professional standard: detailed architecture (trims, frames, pipes, props built from brushes, signage), consistent texture alignment, believable lighting, readable routes, no ugly flat boxes.
Process: write the module; compile --quality final; fix leaks/errors; read the bspcheck perf report and iterate on VIS blocking/hints/detail until the budgets hold; render previews (mapkit preview) and look at them critically, improve weak areas; generate .nav (run_test.py --nav-all --force-nav --maps <...>); run a bot session (>= 240 s, 16 bots, --commands devtools/server/sessions/full_session.txt) and fix stuck spots and errors; test every interactive set piece and its round reset with vexprobe_fire / vexprobe_ents over at least 3 rounds (see the bible for the probe commands); check precache totals in the plugin log (vexmira precache toplam line).
```

## 5. Bitis kontrol listesi
- [ ] Derleme 0 hata / 0 uyari
- [ ] zm_vex_laboratory'de 16-24 botla en az 8 dk test: 0 calisma zamani hatasi, 0 cokme
- [ ] Precache toplam ses <= 490/512, model <= 470/512 (eklenti log satiri "precache toplam")
- [ ] Yeni her lang anahtari EN + TR; yeni her ayar vexmira.cfg'de Turkce aciklamali
- [ ] SURUM_v3.x_OKU.txt guncellendi; paket devtools/release/pack31.sh ile uretildi
