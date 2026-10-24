# VEXMIRA TABLET — data contract (plugin <-> web tablet)

The in-game tablet is a static web app served from the server's FastDL web root:

    http://f16.oyunyoneticisi.biz/cstrike/vexmira_web/ipad.html

Files live in the repo at `cstrike/vexmira_web/` (the hosting panel copies the cstrike folder to FastDL).
The plugin opens it with `show_motd(id, "<full url>")` — the CS 1.6 MOTD window loads a URL when the motd
text starts with `http://`. The Steam CS 1.6 MOTD window is a Chromium (CEF) based HTML view, about
640x480 (it may be larger on big screens; the page must scale to the window, never scroll horizontally).

## Hard limits
* The whole URL (incl. hash) must stay **under 1400 characters** (engine MOTD limit 1536).
* The page cannot run game commands: every action button shows the in-game command / key to use
  (`/kasa`, `/takas`, `/gunluk` ...). Results of actions (case open result, daily reward claim) are
  passed in by the plugin when it re-opens the tablet.
* No server API, no cookies needed. `localStorage` may be used for UI preferences (theme, sounds,
  wallpaper, language override); wrap it in try/catch.
* Must work in an older Chromium (assume Chrome 70): ES5 + basic ES2015 (let/const/arrow ok), no modules,
  no fetch to other hosts, no external CDN (everything inline or relative files under vexmira_web/).

## URL format
    ipad.html#<k>=<v>&<k>=<v>...
Values are URL-encoded. Lists use `;` between records and `~` between record fields.

| key | meaning |
|---|---|
| `l` | language `tr` or `en` |
| `pg` | page to open: `home` `prof` `top` `time` `ach` `achtop` `inv` `case` `daily` `zup` `trade` `set` `adm` `about` |
| `n` | player name |
| `s` | SteamID64 (string, may be empty for non-steam) -> profile link `https://steamcommunity.com/profiles/<s>` |
| `lv` `xp` `xn` | level, xp, xp needed for next level |
| `ap` `vc` | AP (in-game money) and VexCoin |
| `k` `i` `d` `h` `w` `b` | kills, infections, deaths, headshots, wins, boss kills |
| `pt` | playtime in minutes |
| `vip` | 0 none, 1 VIP, 2 ELITE ; `vd` = VIP days left |
| `r` | role: 0 player, 1 admin, 2 founder |
| `rk` | player's rank position on the server (0 = unranked) |
| `a` | achievements unlocked: bitmask as decimal integer (ids below) |
| `t` | top15 by level: `name~lv~kills;...` (max 15) |
| `tt` | top playtime: `name~minutes;...` (max 10) |
| `at` | achievement leaderboard: `name~count;...` (max 10) |
| `iv` | inventory owned masks: `k<mask>.c<mask>.w<mask>.p<mask>.f<mask>.z<mask>` (k knives, c CT skins, w wings, p pets, f kill effects, z laser colors), decimal masks |
| `eq` | equipped: `k<idx>.c<idx>.w<idx>.p<idx>.f<idx>.z<idx>` (0 = none, 1-based) |
| `dy` | daily: `<streak>~<claimedToday 0/1>~<secondsUntilNext>` |
| `zu` | zombie upgrade: `<points>~<lv0>,<lv1>,...` (24 classes, level 0-5 each) ; `zc` = current class id |
| `cr` | case result (only on `pg=case`): `<caseId>~<itemCode>~<rarity 0-4>` -> plays the opening animation and lands on that item |
| `kc` | keys/cases owned: `<bronze>~<silver>~<gold>~<vip>` |
| `on` | online players count ; `mx` max players ; `mp` map name ; `rd` round `x/30` |
| `sv` | admin stats (only when r>=1): `<uptimeMin>~<players>~<bans24h>` |
| `ts` | unix time of the data (for "updated x min ago") |

## Item codes (inventory + case loot)
`k<n>` knives, `c<n>` CT skins, `w<n>` wings, `p<n>` pets, `f<n>` kill effects, `z<n>` laser colors (n = 1-based index into items.js), `v1` VIP 1 day, `v3` VIP 3 days, `v7` VIP 7 days, `$50` `$150` `$500` VexCoin,
`a200` `a500` AP.

Display names are NOT fixed (the owner keeps changing knives/models/pets). The plugin writes
`vexmira_web/items.js` at every map start from the server config:

    window.VXITEMS = {
      k: [{tr:"Balrog-9 / Ates Yumrugu", en:"Balrog-9", r:2, vc:600}, ...],  // knives; index 0 = item 1
      c: [...], w: [...], p: [...], f: [...], z: [...],                     // CT skins, wings, pets, kill fx, laser colors
      cases: [{tr:"Bronz Kasa", en:"Bronze Case", vc:150, loot:[["k1",2,8.5],["w3",1,12.0]]}, ...]  // [code, rarity, chance%]
    };

Category lengths vary; inventory mask bit i = item i+1. If items.js is missing/empty use generic names
("Bicak 3 / Knife 3"). Current sample (for items.js shipped in the repo): knives Balrog-9, Janus-9, Rune Blade,
Holy Sword Divine Order, Miracle Prism Sword; pets Kirby, FTurtle, Padrigo, Mystic Cat / Gizemli Kedi,
Snowman / Kardan Adam; wings Ashen Angel/Kullu Melek, Black Reaper/Kara Hasatci, Butterfly Guard/Kelebek Muhafiz,
Demon Wings/Iblis Kanadi, Phoenix Wings/Anka Kanadi, Seraph Wings/Seraf Kanadi; kill effects Lightning/Yildirim,
Gold Burst/Altin Patlama, Blood Fountain/Kan Cesmesi, Ice Shatter/Buz Kirilmasi, Void Collapse/Bosluk Cokusu,
Fireworks/Havai Fisek; laser colors Plasma/Plazma, Blood/Kan, Toxic/Toksik, Rainbow/Gokkusagi.

Rarity 0 Common/Siradan (grey), 1 Rare/Nadir (blue), 2 Epic/Destansi (purple), 3 Legendary/Efsanevi (gold),
4 Mythic/Mitik (red, VIP drops).

Cases: 0 Bronze / Bronz (150 VC), 1 Silver / Gumus (350 VC), 2 Gold / Altin (700 VC), 3 Nightmare / Kabus (VIP drop chance, 1200 VC).

## Achievements (ids, TR / EN, reward)
0 Ilk Kan / First Blood (kill 1 zombie) 50 AP
1 Imha Uzmani / Exterminator (100 kills) 5 VC
2 Zombi Avcisi / Zombie Slayer (1000 kills) 25 VC
3 Salgin Tasiyici / Plaguebearer (100 infections) 10 VC
4 Boss Avcisi / Boss Hunter (kill a boss) 10 VC
5 Boss Katili / Bossbane (25 boss kills) 40 VC
6 Hayatta Kalan / Survivor (win 50 rounds as human) 15 VC
7 Son Savunma / Last Stand (win as last human) 20 VC
8 Kafa Avcisi / Headhunter (500 headshots) 20 VC
9 Gazi / Veteran (level 25) 25 VC
10 Olumsuz / Immortal (level 50) 60 VC
11 Efsane / Legend (level 100) 150 VC
12 Sadik / Devoted (7-day daily streak) 30 VC
13 Mukemmeliyetci / Perfectionist (all others) 250 VC
14 Gece Kusu / Night Owl (10 hours played) 20 VC
15 Bagimli / Addicted (100 hours played) 100 VC
16 Kasa Avcisi / Case Hunter (open 25 cases) 30 VC
17 Sansli / Lucky (drop a Legendary or Mythic) 50 VC
18 Tuccar / Trader (complete 10 trades) 25 VC
19 Lazer Ustasi / Laser Master (100 kills with laser mines) 20 VC
20 Bicak Ustasi / Blade Master (100 knife kills) 25 VC
21 Kurtarici / Savior (cure yourself 10 times with antidote) 15 VC
22 Koleksiyoncu / Collector (own 20 items) 50 VC
23 Kiyamet / Armageddon (win an Armageddon round) 20 VC
24 Nemesis Avcisi / Nemesis Hunter (kill a Nemesis) 20 VC
25 Gercek Hayatta Kalan / True Survivor (win a Survivor round as survivor) 25 VC
26 Kabus / Nightmare (infect 5 humans in one round) 20 VC
27 Seri Katil / Rampage (10 kills in one life) 25 VC
28 Evrim / Evolution (max a zombie class upgrade, level 5) 40 VC
29 Kurucu Dostu / Founder's Friend (play on the server's first week — given by admins) 100 VC

## Pages
home: big clock, greeting, quick tiles (profile, top15, cases, daily, achievements, zombie upgrade, inventory,
trade, settings, admin if r>=1), notification list (from data: daily available, new achievement, VIP days),
server card (map, round, online).
prof: avatar (initials, colored by level), name, steam profile link, VIP badge, level bar, all stats, rank.
top / time / achtop: leaderboards with medals for 1-3, the player highlighted if present.
ach: grid of 30 achievements, locked/unlocked, reward, progress text; total unlocked count.
inv: categories, owned/equipped badges; how to equip (`/envanter` in game).
case: 4 case cards with prices and drop tables (rarity colors, % chances); when `cr` is given: CS:GO-style
horizontal reel animation (≈5 s, ease-out) landing on the result, rarity glow, sound (WebAudio synthesized:
ticks while spinning, fanfare by rarity), confetti for Legendary/Mythic. "Open again: /kasa".
daily: 7-day calendar with streak, today's reward, countdown to next.
zup: 24 zombie classes with level 0-5 pips, points, cost table, current class highlighted.
trade: how trading works (`/takas <name>`), rules, last trades not needed.
set: dark/light theme, wallpaper picker (5+ built-in CSS/SVG wallpapers), sounds on/off, notifications on/off,
language TR/EN, all saved in localStorage.
adm (r>=1): server stats (from `sv`), admin command reference grouped; founder-only section (r=2):
reset top15 / toptime / achievements commands (`vex_reset_top`, `vex_reset_time`, `vex_reset_ach`),
give VC/AP (`vex_give_vc`), VIP add.
about: Vexmira logo, version, "Tablet & mod: smurfsexy", server address, discord.

Credit text "smurfsexy" must appear in about page and in the status bar / lock screen.
