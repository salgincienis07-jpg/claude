import re
SMA = '/home/user/claude/cstrike/addons/amxmodx/scripting/vexmira_zombie.sma'
OUT = '/home/user/claude/cstrike/addons/amxmodx/configs/vexmira.cfg'
G = '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/gen/'
# eklenti kaynagi: tek dosya scripting/vexmira_zombie.sma (13 bolum, bkz. devtools/plugin/MODULES.md)
import glob, os
src = ''.join(open(f, encoding='utf-8').read() for f in
              [SMA] + sorted(glob.glob(os.path.join(os.path.dirname(SMA), 'vex', '*.inc'))))
body = src[src.index('SetDefaultResources()\n{'):src.index('// Ses dosyasi sunucuda var mi?')]
defs = re.findall(r'DefSound\("([A-Z0-9_]+)",\s*"([^"]*)",\s*"([^"]*)"\)', body)
trie = re.findall(r'TrieSetString\(g_tRes, "([A-Z0-9_]+)",\s*"([^"]*)"\)', body)

def block(name):
    m = re.search(r'static const ' + name + r'\[NUM_BOSSES\]\[\d\]\[\]\s*=\s*\{(.*?)\n    \};', body, re.S)
    rows = re.findall(r'\{([^{}]*)\}', m.group(1))
    return [re.findall(r'"([^"]*)"', r) for r in rows]
bsnd = block('BSND')
brsnd = block('BRSND')

GROUPS = [
 ('ZOMBI SESLERI (genel; sinifa ozel olanlar asagida)', ['ZOMBIE_INFECT','ZOMBIE_PAIN','ZOMBIE_DIE','ZOMBIE_IDLE','ZOMBIE_SLASH','ZOMBIE_HIT','ZOMBIE_STAB','ZOMBIE_HITWALL','EVOLVE']),
 ('ZOMBI [R] YETENEK SESLERI', ['ABILITY_BURST','ABILITY_LEAP','ABILITY_SHIELD','ABILITY_SCREAM','ABILITY_DRAIN','ABILITY_CLOAK','ABILITY_TOXIC','ABILITY_FROST','ZOMBIE_ACID','ZOMBIE_SHOCK','ZOMBIE_HEAL','ZOMBIE_BLINK','MADNESS','ANTIDOTE','NEM_RAGE','ASN_VEIL']),
 ('ROUND / MOD / EVENT', ['ROUND_START','MODE_START','EVENT_START','COUNTDOWN_BEEP','LIGHTNING','AMBIENT','METEOR','LAST_HUMAN','HEARTBEAT','HUMAN_WIN','ZOMBIE_WIN','FINAL_ROUND','MAP_END','SPEED_START','SPEED_WIND','STORM_STRIKE','BLACKOUT']),
 ('KARSILAMA / MENU', ['WELCOME','PLAYER_JOIN','PLAYER_LEAVE','UI_OPEN']),
 ('BOSS (genel; bossa ozel olanlar asagida)', ['BOSS_SPAWN','BOSS_ROAR','BOSS_SCREAM','BOSS_SLAM','BOSS_SUMMON','BOSS_WARN','BOSS_DEATH','BOSS_SOON','BOSS_INTRO','BOSS_STEP','BOSS_PHASE','BOSS_ENRAGE','BOSS_ABILITY','SKILL_UNLOCK','ZONE_WARN','FROST_NOVA','THUNDER','ACID_POOL','GRAVITY_WELL','ECLIPSE']),
 ('OLDURME ANONSLARI / OZEL ANLAR', ['HEADSHOT','KILL_DOUBLE','KILL_TRIPLE','KILL_MULTI','KILL_MEGA','KILL_MONSTER','STREAK_5','STREAK_10','STREAK_15','MVP','QUEST_DONE']),
 ('EKONOMI / VIP', ['LEVEL_UP','ACH_UNLOCK','SHOP_BUY','DAILY','VIP_JOIN']),
 ('BOMBALAR / DURUMLAR / OZEL SILAH', ['NADE_FIRE','NADE_FROST','NADE_INFECT','NADE_MODE','NADE_BEEP','NADE_ARM','NADE_TRIGGER','NADE_CLUSTER','FREEZE','BURN','SW_FIRE','ZAP']),
 ('LAZER MAYINI', ['LM_DEPLOY','LM_CHARGE','LM_ACTIVATE','LM_HIT','LM_KILL','LM_BREAK','LM_PICKUP','LM_DENY']),
 ('HAVA IKMALI', ['AIRDROP_INCOMING','AIRDROP_LAND','AIRDROP_LOOT']),
]
dd = {k: (a, b) for k, a, b in defs}
tt = dict(trie)
L = []
def w(s=''):
    L.append(s)
def sec(t):
    w(); w('// ====================================================================='); w('//  ' + t); w('// =====================================================================')

sec('SESLER / MODELLER / SPRITE\'LAR  (vex_res ANAHTAR "dosya")')
for ln in '''//  - Sesler sound/ klasorune gore:  "vexmira/x.wav" -> cstrike/sound/vexmira/x.wav
//    MP3 muzik tam yol:  "sound/vexmira/muzik.mp3"
//  - Oyuncu modelleri sadece ISIM:  "vex_tank" -> models/player/vex_tank/vex_tank.mdl
//  - El / silah / sprite modelleri tam yol:  "models/vexmira/v_claws.mdl"
//  - Dosya sunucuda yoksa plugin COKMEZ: log'a yazar ve orijinal oyun sesine /
//    modeline duser (oyuncu "failed to transmit" hatasi almaz).
//  - Bir sesi KAPATMAK icin:  vex_res ANAHTAR ""
//  - DONGULU wav (icinde loop / cue noktasi olan) kullanma; kullanirsan plugin
//    onu otomatik durdurur (vex_sound_loopguard).
//  - Ozel dosyalari FastDL'e de yukle (sv_downloadurl). Degisiklikten sonra
//    HARITA DEGISTIR.
//  - Varsayilanlar: Vexmira'nin kendi ozel sesleri (cstrike/sound/vexmira/).
//    Bu klasor yoksa her ses otomatik olarak orijinal HL / CS sesine duser.'''.split('\n'):
    w(ln)
w()
w('vex_res VOX_COUNTDOWN     "1"     // 1 = son 10 saniye oyunun VOX sesiyle sayilir (0 = COUNTDOWN_BEEP)')
for title, keys in GROUPS:
    w()
    w('// ---------------- ' + title + ' ----------------')
    for k in keys:
        a, b = dd[k]
        cmt = f'   // yedek: {b}' if b else ''
        w(f'vex_res {k:<17} "{a}"{cmt}')

w()
w('// ---------------- MUZIK (MP3, round basinda calar, round bitince SUSAR) ----------------')
w('// MODE<n>_MUSIC: 0 Infection 1 Multi 2 Nemesis 3 Assassin 4 Survivor 5 Sniper 6 Swarm 7 Plague 8 Armageddon 9 Boss')
w('// B<n>_MUSIC: bossa ozel muzik (asagida). Oyuncu ayarlardan ortam seslerini kapatabilir.')
for k in ['MODE9_MUSIC', 'MODE2_MUSIC', 'MODE3_MUSIC', 'MODE8_MUSIC']:
    a, b = dd[k]
    w(f'vex_res {k:<17} "{a}"')
w('// vex_res MODE4_MUSIC     "sound/vexmira/survivor_theme.mp3"')

w()
w('// ---------------- ANONS CUMLELERI (oyunun kendi VOX sesleri, dosya indirmez; "" = kapali) ----------------')
for k in ['VOX_BOSS','VOX_BOSSDOWN','VOX_FINAL','VOX_INFECT','VOX_LAST','VOX_AIRDROP','VOX_BLACKOUT','VOX_STORM','VOX_SPEED','VOX_MAPEND']:
    w(f'vex_res {k:<17} "{tt[k]}"')

sec('GOKYUZU')
w('// SKY_MODE: 0 = haritanin kendi gokyuzu, 1 = listeden rastgele (her harita), 2 = listedeki ilk')
w('// Ozel gokyuzu eklersen gfx/env/<isim>up/dn/lf/rt/ft/bk.tga dosyalari oyunculara indirilir.')
w(f'vex_res SKY_MODE          "{tt["SKY_MODE"]}"')
w(f'vex_res SKY_LIST          "{tt["SKY_LIST"]}"')

sec('LAZER MAYINI MODELI + ISIN / OZEL SPRITE\'LAR')
w('// LASERMINE_MODEL degistirirsen BODY / SEQUENCE / SKIN de ayarla (orijinal tripmine: 3 / 7 / 0)')
w(f'vex_res LASERMINE_MODEL   "{tt["LASERMINE_MODEL"]}"')
w('vex_res LASERMINE_BODY    "3"')
w('vex_res LASERMINE_SEQUENCE "7"')
w('vex_res LASERMINE_SKIN    "0"')
w('// ornek: vex_res LASERMINE_MODEL "models/vexmira/lasermine.mdl"  +  BODY "0"  SEQUENCE "0"')
w(f'vex_res AIRDROP_MODEL     "{tt["AIRDROP_MODEL"]}"')
w('vex_res BOSS_MARK_SPRITE  "sprites/glow01.spr"          // bossun basindaki parlama')
for k in ['SPR_LASER', 'SPR_ZONE', 'SPR_TARGET', 'SPR_BEACON', 'SPR_ORB', 'SPR_MARK', 'SPR_FIRE']:
    desc = {'SPR_LASER': 'lazer / ikmal isin dokusu', 'SPR_ZONE': 'yerdeki tehlike halkasi (herkes gorur)',
            'SPR_TARGET': 'yildirim / olum isareti hedefi', 'SPR_BEACON': 'ikmal kutusu altin parlamasi',
            'SPR_ORB': 'enerji kuresi / asit / yumurta', 'SPR_MARK': 'kafa ustu olum isareti', 'SPR_FIRE': 'alev'}[k]
    w(f'vex_res {k:<17} "{tt[k]}"   // {desc}')

sec('ZOMBI SINIFLARI: model, pence (el modeli), sinifa ozel sesler')
w('// Z<n>_MODEL = oyuncu modeli adi, Z<n>_CLAW = el/pence modeli (bos = CLAW_MODEL)')
w('// Z<n>_PAIN / _DIE / _IDLE / _SLASH / _HIT / _STAB / _HITWALL / _INFECT / _ABILITY')
w('// vex_res CLAW_MODEL      "models/vexmira/v_claws.mdl"')
CL = ["Walker", "Runner", "Tank", "Banshee", "Leech", "Stalker", "Bomber", "Frost", "Spitter", "Hulk", "Voodoo", "Phantom"]
for i in range(12):
    w(f'vex_res Z{i}_MODEL {"":<8}"{tt[f"Z{i}_MODEL"]}"   // {CL[i]}')
w('// vex_res Z0_CLAW        "models/vexmira/v_claws_walker.mdl"')
w('// vex_res Z0_PAIN        "vexmira/walker_pain.wav"')

sec('BOSSLAR: model, pence, bossa ozel sesler ve [R] yetenek sesleri')
w('// B<n>_SPAWN / _ROAR / _SCREAM / _ABILITY / _DEATH / _MUSIC, B<n>_R1 / _R2 / _R3 (yetenek sesleri)')
BN = ["Brute", "Banshee", "Overlord", "Inferno", "Reaper", "Frostlord", "Stormcaller", "Hive Queen", "Void"]
EVS = ["SPAWN", "ROAR", "SCREAM", "ABILITY", "DEATH"]
for b in range(9):
    w()
    w(f'// {b} - {BN[b]}')
    w(f'vex_res B{b}_MODEL       "{tt[f"B{b}_MODEL"]}"')
    w(f'// vex_res B{b}_CLAW     "models/vexmira/v_boss{b}.mdl"')
    for e in range(5):
        w(f'vex_res B{b}_{EVS[e]:<10}"{bsnd[b][e]}"')
    for p in range(3):
        w(f'vex_res B{b}_R{p+1}         "{brsnd[b][p]}"')
    w(f'// vex_res B{b}_MUSIC    "sound/vexmira/boss{b}_theme.mp3"')

sec('OZEL KARAKTERLER / INSAN MODELLERI')
for k in ['NEMESIS_MODEL', 'ASSASSIN_MODEL', 'SURVIVOR_MODEL', 'SNIPER_MODEL']:
    w(f'vex_res {k:<17} "{tt[k]}"')
w('// vex_res NEMESIS_CLAW    "models/vexmira/v_nemesis.mdl"')
w('// vex_res ASSASSIN_CLAW   "models/vexmira/v_assassin.mdl"')
w('// Bos = oyunun normal CT modeli:')
w('// vex_res HUMAN_MODEL     "vex_human"')
w('// vex_res VIP_MODEL       "vex_vip"')
w('// vex_res ADMIN_MODEL     "vex_admin"')

sec('SILAH MODELLERI (insanlar)  V_<SILAH> = el modeli, P_<SILAH> = elde gorunen')
w('// Silah adlari: P228 GLOCK18 USP DEAGLE ELITE FIVESEVEN M3 XM1014 MAC10 TMP MP5NAVY')
w('// UMP45 P90 GALIL FAMAS AK47 M4A1 SG552 AUG SCOUT AWP G3SG1 SG550 M249 KNIFE')
w('// HEGRENADE SMOKEGRENADE FLASHBANG')
w('// vex_res V_AK47          "models/vexmira/v_ak47.mdl"')
w('// vex_res P_AK47          "models/vexmira/p_ak47.mdl"')
w('// vex_res V_KNIFE         "models/vexmira/v_knife.mdl"')
w('// Ozel silahlar (SW<n>_VMODEL / SW<n>_PMODEL):')
w('// 0 Plasma (M4A1) 1 Dragon (M249) 2 Thunderbolt (AWP) 3 Frost Breaker (XM1014)')
w('// 4 Golden Eagle (Deagle) 5 Hellfire (P90) 6 Vex Reaper (AK-47) 7 Voidcaller (SG550)')
w('// vex_res SW0_VMODEL      "models/vexmira/v_sw0.mdl"')
w('// vex_res SW0_PMODEL      "models/vexmira/p_sw0.mdl"')

sec('OYUN KURALLARI - ReGameDLL ayarlari')
for ln in '''mp_round_infinite "abcdefghijk"   // round bitisini tamamen Vexmira yonetir (sure, rehine, bomba...)
mp_roundover 3
mp_autoteambalance 0
mp_limitteams 0
mp_auto_join_team 0
mp_buytime 0
mp_buy_anywhere 0
mp_maxmoney 999999
mp_t_default_weapons_secondary ""
mp_ct_default_weapons_secondary ""
mp_t_default_weapons_primary ""
mp_ct_default_weapons_primary ""
mp_t_give_player_knife 1
mp_ct_give_player_knife 1
mp_free_armor 0
mp_weapons_allow_map_placed 0
mp_nadedrops 0
mp_weapondrop 1
mp_item_staytime 15
mp_falldamage 1
mp_respawn_immunitytime 0
mp_kill_filled_spawn 0
mp_show_scenarioicon 0
mp_scoreboard_showmoney 3
mp_knockback 0'''.split('\n'):
    w(ln)

sec('SUNUCU AYARLARI')
for ln in '''// hostname yerine yukaridaki vex_hostname kullanilir (dinamik)
mp_freezetime 3
mp_roundtime 4
mp_round_restart_delay 5
mp_friendlyfire 0
mp_footsteps 1
mp_flashlight 1                    // 1 OLMALI: Boss / Nemesis / Assassin [F] tusu fener tusudur
mp_tkpunish 0
sv_alltalk 1
sv_allowdownload 1                 // ozel ses / sprite indirmesi icin 1 OLMALI
sv_allowupload 0
// FastDL kullaniyorsan ac (ozel dosyalar cok daha hizli iner):
// sv_downloadurl "http://senin-fastdl-adresin/cstrike/"
sv_maxrate 100000
sv_minrate 25000
sv_maxupdaterate 102
sv_minupdaterate 30
amx_language "en"
amx_client_languages 1'''.split('\n'):
    w(ln)

w()
w('// =====================================================================')
w('//  ADMIN KOMUTLARI (konsol)')
w('//    vex_mode  <0-9>         sonraki round modu')
w('//       0 Infection  1 Multi  2 Nemesis  3 Assassin  4 Survivor')
w('//       5 Sniper     6 Swarm  7 Plague   8 Armageddon 9 Boss')
w('//    vex_boss  <0-8 | -1>    sonraki round BOSS ve hangi boss (-1 = rastgele)')
w('//       0 Brute 1 Banshee 2 Overlord 3 Inferno 4 Reaper 5 Frostlord')
w('//       6 Stormcaller 7 Hive Queen 8 Void')
w('//    vex_event <0-18>        sonraki round eventi')
w('//       1 Blood Moon  2 Fog  3 Speed Rush  4 Low Gravity  5 Double Damage')
w('//       6 Dark Night  7 Plague Outbreak  8 Supply Drop  9 Berserk')
w('//       10 Adrenaline 11 Meteor 12 Horde 13 Titan 14 Gold Rush')
w('//       15 Vampire Night 16 Headhunter 17 Thunderstorm 18 Blackout')
w('//    vex_reload               bu dosyayi yeniden yukler (RCON)')
w('//    vex_give_ap / vex_give_vc / vex_give_xp <isim> <miktar>   (RCON)')
w('//    vex_vip_add <isim | #userid | "STEAM_ID"> <gun> <1=VIP 2=ELITE>')
w('//    vex_vip_remove <isim | #userid | "STEAM_ID">   |   vex_vip_list')
w('//  Oyun icinden: M -> Admin Menusu (ADMIN_BAN "d" yetkisi): tum modlar,')
w('//  eventler, bosslar (hemen / sonraki round), hava durumu, ikmal, lazer')
w('//  ac/kapa, round bitir, oyuncu islemleri, ayarlari yenile...')
w('// =====================================================================')

p1 = open(G + 'cfg_part1.txt').read()
open(OUT, 'w', encoding='utf-8').write(p1 + '\n'.join(L) + '\n')
print('ok', len(p1.split('\n')) + len(L))
