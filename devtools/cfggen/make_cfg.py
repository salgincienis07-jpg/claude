# vexmira.cfg uretici: tablolar .sma'daki varsayilanlardan okunur (tutarlilik)
import re
SMA = '/home/user/claude/cstrike/addons/amxmodx/scripting/vexmira_zombie.sma'
OUT = '/home/user/claude/cstrike/addons/amxmodx/configs/vexmira.cfg'
# eklenti kaynagi: .sma + moduller (scripting/vex/*.inc, bkz. devtools/plugin/MODULES.md)
import glob, os
src = ''.join(open(f, encoding='utf-8').read() for f in
              [SMA] + sorted(glob.glob(os.path.join(os.path.dirname(SMA), 'vex', '*.inc'))))

def arr(name):
    m = re.search(r'^new (?:Float:)?' + name + r'\[[^\]]*\]\s*=\s*\{([^}]*)\}', src, re.M)
    assert m, name
    return [x.strip() for x in m.group(1).split(',')]

def arr2(name):
    m = re.search(r'^new (?:Float:)?' + name + r'\[[^\]]*\]\[[^\]]*\]\s*=\s*\{(.*?)\n\};', src, re.M | re.S)
    assert m, name
    rows = re.findall(r'\{([^{}]*)\}', m.group(1))
    return [[x.strip() for x in r.split(',')] for r in rows]

def light(c):
    c = c.strip()
    if c == '0':
        return '0'
    return c.strip("'")

ITEM = ["Ilk Yardim (can)", "Zirh (zirh miktari)", "Ates Bombasi (adet)", "Buz Bombasi (adet)", "Isaret Fisegi (adet)",
        "Ekstra Ziplama - VIP (adet)", "Yercekimi Botu (yercekimi %)", "Hiz Serumu (+hiz %)", "Sinirsiz Sarjor (-)",
        "Hasar Guclendirici (+hasar %)", "Diriltme Jetonu (-)", "T-Virus Panzehiri (-) [ZOMBI]", "Zombi Cinneti (sn) [ZOMBI]",
        "Enfeksiyon Bombasi (roundda en fazla) [ZOMBI]", "Mutajen (+can) [ZOMBI]", "Ofke (+hasar %) [ZOMBI]",
        "Hizli Yenilenme (-) [ZOMBI]", "Kemik Zirh (hasar azaltma %) [ZOMBI]", "Adrenalin Ignesi (sn)", "Hayalet Pelerini (sn)",
        "Gece Gorusu (-)", "Enerji Kalkani (darbe sayisi)", "Cephane Kutusu (-)", "Zombi Kosusu (sn) [ZOMBI]",
        "Golge Ortusu (sn) [ZOMBI]", "Mutant Bacaklar (yercekimi %) [ZOMBI]", "Yenilenme (can/sn) [ZOMBI]", "Demir Durus (-) [ZOMBI]"]
CLASS = ["Walker", "Runner", "Tank", "Banshee", "Leech", "Stalker", "Bomber", "Frost", "Spitter", "Hulk", "Voodoo", "Phantom"]
SW = ["Plazma Tufegi (M4A1)", "Ejder Topu (M249)", "Yildirim (AWP)", "Buz Kiran (XM1014)", "Altin Kartal (Deagle)",
      "Cehennem SMG (P90)", "Vex Bicici (AK-47)", "Bosluk Cagirici (SG550)"]
PRIM = ["AK-47", "M4A1", "FAMAS", "Galil", "MP5 Navy", "UMP45", "P90", "M3", "XM1014", "AUG", "SG552", "M249", "AWP", "G3SG1"]
SEC = ["USP", "Glock-18", "P228", "Desert Eagle", "Dual Elites", "Five-seveN"]
JOB = ["Medic", "Heavy", "Scout", "Marksman", "Engineer", "Looter", "Gunner", "Demolitions", "Sniper", "Paratrooper", "Pyro",
       "Cryo", "Vampire", "Guardian", "Berserker", "Commander", "Juggernaut", "Ninja", "Ghost", "Grenadier", "Hunter", "Doctor",
       "Gambler", "Tactician", "Lucky", "Elite Soldier"]
BOSS = ["Brute", "Banshee", "Overlord", "Inferno", "Reaper", "Frostlord", "Stormcaller", "Hive Queen", "Void"]
BSK = [["Sismik Ezme (yaricap)", "Yer Yarigi (patlama yaricapi)", "Titan Ofkesi (dalga yaricapi, hasar/sn)"],
       ["Ses Mizragi (menzil)", "Hayalet Cigligi (ciglik yaricapi)", "Agit (menzil, hasar/dalga)"],
       ["Kemik Hapsi (menzil)", "Lejyon (can emme yaricapi)", "Olum Novasi (halka genisligi)"],
       ["Alev Nefesi (menzil)", "Ates Sutunlari (sutun yaricapi)", "Supernova (patlama yaricapi)"],
       ["Golge Adimi (isinlanma menzili)", "Ruh Zincirleri (menzil, hasar/0.5sn)", "Olum Isareti (patlama yaricapi)"],
       ["Buz Parcalari (menzil)", "Buz Mezari (menzil)", "Mutlak Sifir (tum harita)"],
       ["Top Yildirim (carpma yaricapi, hasar/0.3sn)", "Yildirim Atilmasi (carpma yaricapi)", "Kasirga (yildirim yaricapi)"],
       ["Asit Tukurugu (havuz yaricapi)", "Zehir Bulutu (bulut yaricapi)", "Kulucka (patlama yaricapi)"],
       ["Bosluk Oku (menzil)", "Tekillik (cekim yaricapi)", "Olay Ufku (cekim yaricapi, hasar/sn)"]]
MODE = ["Enfeksiyon", "Coklu Enfeksiyon", "Nemesis", "Assassin", "Survivor", "Sniper", "Swarm", "Plague", "Armageddon", "BOSS"]
EV = ["Normal (event yok)", "Kan Ayi", "Yogun Sis", "Hiz Tutkusu", "Dusuk Yercekimi", "Cift Hasar", "Karanlik Gece",
      "Salgin Patlamasi", "Malzeme Dususu", "Delilik", "Adrenalin", "Meteor Yagmuru", "Zombi Surusu", "Titan Saati",
      "Altin Hucumu", "Vampir Gecesi", "Kafa Avi", "Firtina", "Elektrik Kesintisi"]
CALM = ["Gunduz", "Alacakaranlik", "Gece", "Yagmurlu", "Karli", "Sisli"]
QUEST = ["3 zombi oldur", "6 zombi oldur", "2500 hasar ver", "6000 hasar ver", "2 headshot", "1 insan enfekte et",
         "3 insan enfekte et", "Roundu insan olarak kazan"]
TRAIL = ["Buz Izi", "Toksik Iz", "Kan Izi", "Kraliyet Izi", "Altin Iz", "Gokkusagi Izi"]
KFX = ["Yildirim Carpmasi", "Altin Patlama", "Kan Cesmesi", "Buz Kirilmasi", "Bosluk Cokusu", "Havai Fisek"]
IFX = ["Zehir Patlamasi", "Golge", "Kan Ayi"]

L = []
def w(s=''):
    L.append(s)
def sec(title):
    w()
    w('// =====================================================================')
    w('//  ' + title)
    w('// =====================================================================')

w('// =====================================================================')
w('//')
w('//   V E X M I R A   Z O M B I E   v2.0   -   TEK AYAR DOSYASI')
w('//   Kurucular: SmurfSexy & Capital')
w('//')
w('//   Konum: cstrike/addons/amxmodx/configs/vexmira.cfg')
w('//   Plugin bu dosyayi HER HARITA BASINDA kendisi okur ve uygular.')
w('//   server.cfg / game.cfg / amxx.cfg icine bir sey yazmana GEREK YOK.')
w('//')
w('//   - Sunucu adi, oyun kurallari, tum canlar / hasarlar / hizlar,')
w('//     AP - XP - VC odulleri, esya fiyatlari / limitleri / levelleri /')
w('//     degerleri, zombi siniflari, ozel silahlar, silahlar, meslekler,')
w('//     bosslar ve 27 boss [R] yetenegi, hava durumu / isik / sis,')
w('//     tum SESLER / MODELLER / SPRITE\'LAR: HEPSI BU DOSYADA.')
w('//   - "//" sonrasi aciklamadir, plugin okumaz.')
w('//   - Oyun icinde degistirdikten sonra: amx_cvar ile tek tek veya')
w('//     sunucu konsoluna  vex_reload  (ses / model / sprite degisiklikleri')
w('//     HARITA DEGISINCE gecerli olur, oyuncular dosyalari indirir).')
w('//   - Dosya bulunamazsa / satir hataliysa plugin varsayilan degeri kullanir,')
w('//     hata nedeni addons/amxmodx/logs/ altina yazilir.')
w('// =====================================================================')

sec('SUNUCU ADI (oyuncu ceken baslik)')
w('// vex_hostname_dynamic: 0 = sabit isim, 1 = sona canli durum eklenir')
w('//   ("... | R7/30 BOSS"), 2 = basa eklenir ("[R7/30 BOSS] ...")')
w('vex_hostname           "EN/TR ZOMBIE | VEXMIRA | Boss + Round Events + Advanced Menu"')
w('vex_hostname_dynamic   1')
w('// Chat oneki (renkler: ^1 normal, ^3 takim/ozel renk, ^4 yesil)')
w('vex_chat_prefix        "^4[^3VEX^4MIRA^4]^1"')

sec('HARITA PLANI (30 ROUND)')
for ln in '''mp_maxrounds           30            // harita 30 round surer, sonra harita degisir
mp_timelimit           0             // sure siniri yok (30 round belirler)
vex_rounds_total       30            // mp_maxrounds 0 yapilirsa plan 30 roundda bir basa doner
vex_boss_rounds        "7 15 23 30"  // BOSS roundlari (son round = FINAL BOSS)
vex_special_rounds     "4 11 19 26"  // ozel mod roundlari (Nemesis, Survivor, Plague...)
vex_boss_every         6             // vex_boss_rounds bos ("") ise her N roundda bir boss
vex_multi_chance       15            // normal roundun Coklu Enfeksiyon olma olasiligi (%)
vex_event_chance       85            // normal roundlarda event olasiligi (%) - 1. round her zaman sakin
vex_countdown          15            // enfeksiyondan once geri sayim (sn)
vex_zombie_respawn     4.0           // olen zombinin geri donus suresi (sn), sadece Infection/Multi
vex_vote_every         4             // kac roundda bir otomatik mod / event oylamasi (0 = kapali)'''.split('\n'):
    w(ln)
w()
w('// Mod kurallari: vex_mode_rule <mod> <ozel round secilme agirligi> <en az oyuncu>')
ch, mp = arr('MODE_CHANCE'), arr('MODE_MINPL')
for i in range(10):
    w(f'vex_mode_rule {i:<3}{ch[i]:<5}{mp[i]:<4}// {MODE[i]}')

sec('CANLAR')
for ln in '''vex_first_zombie_hp    4500          // ilk zombi (sinif carpani uygulanir)
vex_zombie_hp          1800          // enfekte olan zombi (sinif carpani uygulanir)
vex_human_hp           100           // insan taban cani (+ perk / meslek)
vex_last_human_bonus   150           // son insana verilen ekstra can
vex_nemesis_hp         9000          // nemesis taban cani (+500 / oyuncu)
vex_assassin_hp        6000          // assassin taban cani (+300 / oyuncu)
vex_survivor_hp        1200
vex_sniper_hp          900
vex_minion_hp          400           // boss yardimcisi (dirilen olu) cani'''.split('\n'):
    w(ln)

sec('HASARLAR')
for ln in '''vex_zombie_damage      60            // enfeksiyon olmayan modlarda zombi vurusu
vex_minion_damage      35            // boss yardimcilari
vex_nemesis_oneshot    1             // 1 = Nemesis insani TEK VURUSTA oldurur
vex_assassin_oneshot   1             // 1 = Assassin insani TEK VURUSTA oldurur
vex_nemesis_damage     250           // oneshot 0 iken Nemesis vurusu
vex_assassin_damage    200           // oneshot 0 iken Assassin vurusu
vex_nemesis_vs_survivor 250          // Nemesis / Assassin'in Survivor ve Sniper'a vurusu
vex_damage_per_ap      500           // zombiye verilen kac hasar = 1 AP
vex_knockback          1             // 1 = mermiler zombileri geri iter
vex_armor_protect      1             // 1 = zirh bitmeden insan enfekte olmaz
vex_burn_damage_human  6             // yanan insanin saniyelik hasari
vex_burn_damage_zombie 35            // yanan zombinin saniyelik hasari'''.split('\n'):
    w(ln)

sec('HIZ / YERCEKIMI')
for ln in '''sv_maxspeed            900           // hiz eventleri icin sinir yukseltildi (onemli!)
vex_zombie_speed_mult  1.0           // tum zombi hizlari carpani
vex_human_speed_mult   1.0           // tum insan hizlari carpani
vex_nemesis_speed      265
vex_assassin_speed     340
vex_nemesis_gravity    0.5
vex_assassin_gravity   0.45
vex_speedrush_human    1.55          // Hiz Tutkusu: insan hiz carpani
vex_speedrush_zombie   1.45          // Hiz Tutkusu: zombi hiz carpani
vex_speedrush_fov      105           // Hiz Tutkusu: gorus acisi (90 = normal)'''.split('\n'):
    w(ln)

sec('NEMESIS / ASSASSIN TUSLARI  ([R] atilma  -  [F] fener tusu: ozel guc)')
for ln in '''vex_special_leap_cooldown   6        // Nemesis / Boss atilma bekleme (Assassin 2/3'u)
vex_nemesis_rage_time       5        // [F] OFKE: +%25 hiz, %30 az hasar alir (sn)
vex_nemesis_rage_cooldown   25
vex_assassin_veil_time      4        // [F] GOLGE PERDESI: neredeyse gorunmez + hizli (sn)
vex_assassin_veil_cooldown  25'''.split('\n'):
    w(ln)

sec('BOSS')
for ln in '''vex_boss_hp            6000          // boss taban cani (bossa ozel carpan uygulanir)
vex_boss_hp_per_player 1500          // her canli insan icin eklenen can
vex_boss_final_mult    1.5           // son round FINAL BOSS can carpani
vex_boss_damage        75            // boss pence hasari (delilik fazinda x1.25)
vex_boss_ability_mult  1.0           // TUM boss yetenek hasarlari carpani (0.5 = yarisi)
vex_boss_phase2        60            // can % bunun altina inince FAZ 2 (yeni [R] yetenegi)
vex_boss_phase3        30            // can % bunun altina inince FAZ 3 = DELILIK (ULTI)
vex_boss_r_auto        12            // boss N sn [R] kullanmazsa (veya bot ise) yetenek kendiliginden (0 = kapali)
vex_boss_r_cooldown_mult 1.0         // [R] bekleme sureleri carpani
vex_boss_r_damage_mult 1.0           // [R] hasarlari carpani
vex_boss_auto_abilities 1            // 1 = bossun otomatik (uyarili) saldirilari acik'''.split('\n'):
    w(ln)
w()
w('// Boss ozellikleri: vex_boss_stat <no> <can carpani> <hiz> <yercekimi> <R> <G> <B (renk)>')
hpm, spd, grv, rgb = arr('BOSS_HP_MULT'), arr('BOSS_SPD'), arr('BOSS_GRAV'), arr2('BOSS_RGB')
for i in range(9):
    w(f'vex_boss_stat {i}  {hpm[i]:<5} {spd[i]:<4} {grv[i]:<5} {rgb[i][0]:>3} {rgb[i][1]:>3} {rgb[i][2]:>3}   // {BOSS[i]}')
w()
w('// ---------------------------------------------------------------------')
w('//  BOSS [R] YETENEKLERI (faza gore degisir, toplam 27)')
w('//  vex_boss_skill <boss> <faz 1-3> <bekleme sn> <hasar> <yaricap / menzil>')
w('//  Faz 1: R = 1. yetenek | Faz 2: R = 2. (1. otomatik) | Faz 3: R = ULTI')
w('// ---------------------------------------------------------------------')
cool, dmg, rad = arr2('BSK_COOL'), arr2('BSK_DMG'), arr2('BSK_RAD')
for b in range(9):
    w(f'// {BOSS[b]}')
    for p in range(3):
        w(f'vex_boss_skill {b} {p+1}  {cool[b][p]:<5} {dmg[b][p]:<5} {rad[b][p]:<5}   // {BSK[b][p]}')

sec('EKONOMI / ODULLER (AP = Ammo Pack, XP, VC = Vex Coin)')
for ln in '''vex_start_ap           20            // yeni oyuncunun baslangic AP'si
vex_kill_ap            2             // zombi oldurme AP
vex_kill_xp            8             // zombi oldurme XP (ALFA zombi x2.5)
vex_infect_ap          3             // enfekte etme AP
vex_infect_xp          10
vex_headshot_ap        1             // headshot ile oldurme ek AP (Kafa Avi eventinde x3)
vex_win_human_xp       25            // insanlar kazaninca (boss / ozel modda katlanir)
vex_win_human_ap       6
vex_win_zombie_xp      15            // zombiler kazaninca
vex_win_zombie_ap      4
vex_boss_kill_xp       120           // boss'u indiren
vex_boss_kill_ap       25
vex_boss_kill_vc       3
vex_special_kill_xp    80            // Nemesis / Assassin indiren
vex_special_kill_ap    15
vex_boss_board_ap      "40 25 15"    // boss hasar tablosu 1. 2. 3. odulu
vex_mvp_ap             10            // round MVP odulu
vex_mvp_vc             1
vex_daily_ap           20            // gunluk odul taban AP (+10 / seri gunu)
vex_achievement_ap     25            // basarim odulu
vex_achievement_vc     3
vex_exchange_cost      60            // markette X AP -> 1 VC takasi
vex_perk_cost_step     4             // perk maliyeti = (seviye + 1) * bu deger VC
vex_quests             1             // 1 = her round herkese kucuk bir gorev
vex_evolve             3             // bir roundda kac enfeksiyonla ALFA ZOMBI olunur (0 = kapali)'''.split('\n'):
    w(ln)
w()
w('// Gorevler: vex_quest <no> <gereken> <XP> <AP>')
qn, qx, qa = arr('QUEST_NEED'), arr('QUEST_XP'), arr('QUEST_AP')
for i in range(8):
    w(f'vex_quest {i}  {qn[i]:<5} {qx[i]:<4} {qa[i]:<4}  // {QUEST[i]}')

sec('MARKET ESYALARI')
w('// vex_item <no> <fiyat AP> <round limiti (0 = sinirsiz)> <gereken level> <deger>')
w('// "deger" esyanin ana etkisidir (parantez icinde ne oldugu yazili)')
ic, il, ilv, iv = arr('ITEM_COST'), arr('ITEM_LIMIT'), arr('ITEM_LVL'), arr('ITEM_VAL')
for i in range(28):
    w(f'vex_item {i:<3}{ic[i]:<5}{il[i]:<4}{ilv[i]:<4}{iv[i]:<6}// {ITEM[i]}')

sec('ZOMBI SINIFLARI')
w('// vex_class <no> <can carpani> <hiz> <yercekimi> <geri tepme carpani> <[R] bekleme sn> <level>')
chp, cs, cg, ck, cc, cl = arr('CLASS_HP'), arr('CLASS_SPD'), arr('CLASS_GRAV'), arr('CLASS_KB'), arr('CLASS_COOL'), arr('CLASS_LVL')
for i in range(12):
    w(f'vex_class {i:<3}{chp[i]:<6}{cs[i]:<5}{cg[i]:<6}{ck[i]:<6}{cc[i]:<6}{cl[i]:<4}// {CLASS[i]}')

sec('OZEL SILAHLAR')
w('// vex_sw <no> <fiyat AP> <level> <hasar carpani> <yedek mermi>')
sc_, sl, sm, sa = arr('SW_COST'), arr('SW_LVL'), arr('SW_MULT'), arr('SW_BPAMMO')
for i in range(8):
    w(f'vex_sw {i}  {sc_[i]:<4} {sl[i]:<4} {sm[i]:<5} {sa[i]:<5}  // {SW[i]}')

sec('SILAH SECIMI (her doguste)')
w('// vex_gun <p = birincil | s = ikincil> <no> <level> <yedek mermi>')
pl, pa = arr('PRIM_LVL'), arr('PRIM_AMMO')
for i in range(14):
    w(f'vex_gun p {i:<3}{pl[i]:<4}{pa[i]:<5}// {PRIM[i]}')
sl2, sa2 = arr('SEC_LVL'), arr('SEC_AMMO')
for i in range(6):
    w(f'vex_gun s {i:<3}{sl2[i]:<4}{sa2[i]:<5}// {SEC[i]}')

sec('INSAN MESLEKLERI (level kilidi)')
w('// vex_job <no> <level>')
jl = arr('JOB_LVL')
for i in range(26):
    w(f'vex_job {i:<3}{jl[i]:<4}// {JOB[i]}')

sec('LAZER MAYINI  (V = kur, C = sok)')
for ln in '''vex_lm_enable          1
vex_lm_boss            0             // 0 = boss roundlarinda lazer YOK
vex_lm_per_round       3             // HER ROUND her insana verilen lazer hakki (AP ile satis YOK)
vex_lm_per_round_vip   3             // VIP / ELITE icin
vex_lm_max             3             // ayni anda kurulu lazer (oyuncu)
vex_lm_max_vip         3
vex_lm_team_max        40            // tum takim toplam
vex_lm_oneshot         1             // 1 = isina degen zombi TEK ATISTA olur
vex_lm_damage          150           // oneshot 0 iken temas hasari (0.25 sn'de bir)
vex_lm_special_damage  600           // Nemesis / Assassin / Boss'a temas hasari (oldurmez)
vex_lm_health          600           // mayin cani (zombiler pence ile kirabilir)
vex_lm_kill_wear       100           // her oldurmede mayindan giden can
vex_lm_beam_wear       18            // oneshot 0 iken her temasta giden can
vex_lm_zombie_mult     3.0           // zombi pencesinin mayina carpani (nemesis / boss x2.5 daha)
vex_lm_plant_time      1.0           // kurma suresi (sn, V basili tutulur; 0 = aninda)
vex_lm_take_time       0             // sokme suresi (0 = C'ye basinca ANINDA)
vex_lm_arm_time        1.5           // kurulduktan sonra isinin acilma suresi
vex_lm_plant_range     128           // duvara en fazla uzaklik
vex_lm_take_range      170           // C ile sokme menzili
vex_lm_beam_width      8             // isin kalinligi
vex_lm_color_mode      0             // 0 = cana gore (mavi>sari>kirmizi), 1 = oyuncuya ozel renk, 2 = sabit renk
vex_lm_color           "0 200 255"   // color_mode 2 icin R G B
vex_airdrop_laser      1             // hava ikmalinden +1 lazer cikabilir'''.split('\n'):
    w(ln)

sec('BOMBALAR / BOMBA MODLARI (bomba elindeyken SAG TIK)')
for ln in '''vex_give_nades         "abc"         // HER ROUND her insana: a = ates (HE), b = buz (duman), c = isaret fisegi
vex_nade_modes         1             // 1 = carpma / sensor / lazer tuzak / gudumlu / parcali aktif
vex_nade_fire_damage   80            // ates bombasi hasari
vex_nade_fire_radius   260
vex_nade_fire_burn     6             // tutusma suresi (sn)
vex_nade_frost_radius  260
vex_nade_frost_time    3.0           // donma suresi
vex_nade_infect_radius 240           // zombi enfeksiyon bombasi yaricapi
vex_nade_flare_time    25            // isaret fisegi isik suresi
vex_nade_sensor_radius 170           // SENSOR: algilama yaricapi
vex_nade_sensor_arm    1.5           // SENSOR: yere oturduktan sonra kurulma suresi
vex_nade_sensor_life   60            // SENSOR / LAZER TUZAK: en fazla bekleme (sonra patlar)
vex_nade_laser_length  900           // LAZER TUZAK: isin uzunlugu
vex_nade_laser_arm     1.0           // LAZER TUZAK: yapistiktan sonra isin acilma suresi
vex_nade_homing_radius 750           // GUDUMLU: zombi arama yaricapi
vex_nade_cluster       4             // PARCALI: kucuk patlama sayisi
vex_nade_cluster_damage 45'''.split('\n'):
    w(ln)

sec('HAVA IKMALI / KARSILAMA / AFK')
for ln in '''vex_airdrop            1
vex_airdrop_every      70            // kac saniyede bir ikmal (Malzeme Dususu eventinde 20)
vex_airdrop_beacon     1             // 1 = gokyuzune uzanan ALTIN ISIK SUTUNU + parlama
vex_airdrop_compass    1             // 1 = insanlarin HUD'unda kutuya mesafe + yon
vex_airdrop_zombie_heal 300          // kutuyu kiran zombiye verilen can
vex_motd               1             // 1 = Vexmira karsilama penceresi (configs/vexmira_motd_tr/en.html)
vex_join_messages      1             // baglaniyor / katildi / ayrildi mesajlari
vex_afk_time           120           // N sn hic kipirdamayan oyuncu (0 = kapali)
vex_afk_action         1             // 1 = izleyiciye al, 2 = sunucudan at'''.split('\n'):
    w(ln)

sec('SES KORUMASI (round bitince sesler susar)')
for ln in '''vex_sound_loopguard    1             // 1 = DONGULU wav'lar otomatik durdurulur / spk ile calinmaz
vex_sound_loop_max     3.0           // dongulu ses en fazla kac sn calsin
vex_round_stopsound    1             // 1 = yeni round basinda tum sesler + muzik susar'''.split('\n'):
    w(ln)

sec('ORTAM: ISIK / SIS / HAVA DURUMU (her event, mod ve boss icin)')
w('vex_env                1             // 1 = ortam sistemi acik')
w('vex_env_calm_random    1             // 1 = event olmayan roundlarda rastgele hava (gunduz/gece/yagmur/kar/sis)')
w('vex_weather            1             // 1 = yagmur / kar gonderilir (oyuncuda cl_weather acik olmali)')
w('//')
w('// vex_env_* <no> <isik> <sis R> <sis G> <sis B> <sis yogunlugu> <hava>')
w('//   isik: a (zifiri) .. m (normal) .. z (cok parlak), 0 = degistirme')
w('//   sis yogunlugu: 0 = sis yok, 10 hafif, 25 orta, 45 yogun')
w('//   hava: 0 = acik, 1 = yagmur, 2 = kar')
el, ef, ew = arr('ENV_EV_LIGHT'), arr2('ENV_EV_FOG'), arr('ENV_EV_WEATHER')
for i in range(19):
    f = ef[i]
    w(f'vex_env_event {i:<3}{light(el[i]):<3}{f[0]:>4} {f[1]:>4} {f[2]:>4} {f[3]:>4}  {ew[i]}   // {EV[i]}')
ml, mf, mw = arr('ENV_MODE_LIGHT'), arr2('ENV_MODE_FOG'), arr('ENV_MODE_WEATHER')
for i in range(10):
    f = mf[i]
    w(f'vex_env_mode {i:<3}{light(ml[i]):<3}{f[0]:>4} {f[1]:>4} {f[2]:>4} {f[3]:>4}  {mw[i]}   // {MODE[i]} (0 = event / boss ayari gecerli)')
bl, bf, bw = arr('ENV_BOSS_LIGHT'), arr2('ENV_BOSS_FOG'), arr('ENV_BOSS_WEATHER')
for i in range(9):
    f = bf[i]
    w(f'vex_env_boss {i:<3}{light(bl[i]):<3}{f[0]:>4} {f[1]:>4} {f[2]:>4} {f[3]:>4}  {bw[i]}   // {BOSS[i]}')
cl_, cf, cw = arr('ENV_CALM_LIGHT'), arr2('ENV_CALM_FOG'), arr('ENV_CALM_WEATHER')
for i in range(6):
    f = cf[i]
    w(f'vex_env_calm {i:<3}{light(cl_[i]):<3}{f[0]:>4} {f[1]:>4} {f[2]:>4} {f[3]:>4}  {cw[i]}   // sakin round: {CALM[i]}')

sec('KOZMETIK FIYATLARI (Vex Coin, kalici)')
w('// vex_cosmetic <tur: 0 iz, 1 oldurme efekti, 2 enfeksiyon efekti> <no> <fiyat VC>')
for i, (n, p) in enumerate(zip(TRAIL, arr('TRAIL_PRICE'))):
    w(f'vex_cosmetic 0 {i}  {p:<4}// {n}')
for i, (n, p) in enumerate(zip(KFX, arr('KFX_PRICE'))):
    w(f'vex_cosmetic 1 {i}  {p:<4}// {n}')
for i, (n, p) in enumerate(zip(IFX, arr('IFX_PRICE'))):
    w(f'vex_cosmetic 2 {i}  {p:<4}// {n}')

sec('VIP / ILETISIM')
w('vex_vip_contact        "discord.gg/vexmira"')

open('/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/gen/cfg_part1.txt', 'w').write('\n'.join(L) + '\n')
print('part1 lines', len(L))
