# Part B (v3.0 gorsel kimlik + kaynaklar + precache butcesi): vexmira.cfg guncellemesi.
# Tekrar calistirilabilir (isaretli bloklari yeniden yazar).
import re
P = '/home/user/claude/cstrike/addons/amxmodx/configs/vexmira.cfg'
cfg = open(P, encoding='utf-8').read()

def replace_block(text, start_marker, end_marker, new):
    # start_marker: metin veya alternatif listesi (ilk bulunan)
    if isinstance(start_marker, (list, tuple)):
        found = [text.find(m) for m in start_marker if text.find(m) != -1]
        if not found:
            raise ValueError('marker yok: %r' % (start_marker,))
        a = min(found)
    else:
        a = text.index(start_marker)
    b = text.index(end_marker, a)
    return text[:a] + new + text[b:]

# 1) Sohbet onekleri
cfg = re.sub(r'// Chat oneki \(renkler: \^1 normal, \^3 takim/ozel renk, \^4 yesil\)\nvex_chat_prefix[^\n]*\n(?:vex_chat_prefix_[^\n]*\n)*',
'''// Chat onekleri (renkler: ^1 normal, ^3 takim/ozel renk, ^4 yesil). Mesaj turune gore secilir:
vex_chat_prefix        "^4[VEX]^1"           // sistem mesajlari (yesil)
vex_chat_prefix_boss   "^3[BOSS]^1"          // boss / boss yetenekleri (kirmizi)
vex_chat_prefix_event  "^4[^1EVENT^4]^1"     // eventler / hava olaylari
vex_chat_prefix_vip    "^4[^3VIP^4]^1"       // VIP / ELITE
vex_chat_prefix_admin  "^3[ADMIN]^1"         // admin islemleri
''', cfg, count=1)

# 2) Gorsel kimlik / kafa ustu / boss sesleri cvar bolumu (YENI ZOMBI SINIFLARI bolumunden once)
VIS = '''// =====================================================================
//  GORSEL KIMLIK: KAFA USTU GOSTERGELER + BOSS / OZEL KARAKTER SESLERI
// =====================================================================
// Boss'un kafasinin ustunde oyunlardaki gibi can bari (sprites/vexmira/bossbar.spr) +
// boss amblemi (bossicon.spr); Nemesis / Assassin / Alfa zombide kucuk bar (hpbar_small.spr);
// VIP / admin / MVP / son insan / alfa ikonlari. Sprite dosyasi yoksa o gosterge kapali kalir.
vex_overhead              1       // 1 = kafa ustu can barlari ve ikonlar acik
vex_overhead_self         0       // 1 = oyuncu kendi kafasinin ustundeki bari da gorur
vex_bossbar_width         110     // boss barinin dunyadaki genisligi (birim)
vex_bossbar_height        92      // boss barinin bossun merkezinden yuksekligi (birim)
vex_hpbar_width           44      // kucuk barin genisligi (Nemesis / Assassin / Alfa)
vex_head_icon_size        18      // kafa ustu ikon boyutu (birim)
vex_head_icons            31      // ikon bit maskesi: 1 VIP + 2 admin + 4 MVP + 8 son insan + 16 alfa (0 = kapali)
// Boss / Nemesis / Assassin sesleri (sound/vexmira/boss/*, sound/vexmira/special/*)
vex_boss_idle_min         9       // ara sira hirlama: en az (sn)
vex_boss_idle_max         16      // ara sira hirlama: en cok (sn)
vex_boss_pain_cd          0.9     // aci sesi en az bu kadar arayla (sn) - PAIN / PAIN2 sirayla
vex_boss_attack_cd        1.1     // pence savururken saldiri kukremesi bekleme suresi (sn)
vex_boss_step_dist        120     // boss adim sesi: bu kadar birim yurudukce bir adim (hiza gore)

'''
if '//  GORSEL KIMLIK: KAFA USTU GOSTERGELER' in cfg:
    cfg = replace_block(cfg, '// =====================================================================\n//  GORSEL KIMLIK: KAFA USTU GOSTERGELER',
                        '// =====================================================================\n//  YENI ZOMBI SINIFLARI', VIS)
else:
    i = cfg.index('// =====================================================================\n//  YENI ZOMBI SINIFLARI')
    cfg = cfg[:i] + VIS + cfg[i:]

# 3) Lazer / ikmal / sprite bolumu
cfg = replace_block(cfg, ['// =====================================================================\n//  LAZER MAYINI MODELI',
                         '// =====================================================================\n//  LAZER MAYINI / IKMAL'],
'// =====================================================================\n//  ZOMBI SINIFLARI: model', '''// =====================================================================
//  LAZER MAYINI / IKMAL / DUNYA MODELLERI + OZEL SPRITE'LAR
// =====================================================================
// Vexmira lazeri: govde 0, animasyon ADI "idle" (lens nabzi), kurulurken "deploy".
// Dosya yoksa otomatik orijinal tripmine'a (govde 3 / animasyon 7) duser.
// Orijinal model kullanmak icin: MODEL "models/v_tripmine.mdl", BODY "3", SEQUENCE "7"
vex_res LASERMINE_MODEL      "models/vexmira/world/lasermine.mdl"
vex_res LASERMINE_BODY       "0"
vex_res LASERMINE_SEQUENCE   "idle"      // sayi veya animasyon adi
vex_res LASERMINE_DEPLOY_SEQ "deploy"    // kurulum animasyonu ("" = yok)
vex_res LASERMINE_SKIN       "0"
// Ikmal kutusu: dususte parasut govdesi + "fall" (sallanma), yerde "idle". Yoksa w_weaponbox.
vex_res AIRDROP_MODEL        "models/vexmira/world/supply_crate.mdl"
vex_res AIRDROP_BODY_CHUTE   "1"         // parasutlu govde degeri
vex_res AIRDROP_BODY_LANDED  "0"         // yere inince (parasut kalkar)
vex_res AIRDROP_SEQ_FALL     "fall"
vex_res AIRDROP_SEQ_IDLE     "idle"
vex_res EGG_MODEL            "models/vexmira/world/hive_egg.mdl"   // Hive Queen yumurtasi (yoksa parlayan kure)
// Firlatilan bombalarin dunya modelleri (insan bombasi; zombinin enfeksiyon bombasi orijinal kalir)
vex_res W_HEGRENADE          "models/vexmira/world/w_firebomb.mdl"
vex_res W_SMOKEGRENADE       "models/vexmira/world/w_frostbomb.mdl"
vex_res W_FLASHBANG          "models/vexmira/world/w_flare.mdl"
vex_res BOSS_MARK_SPRITE  "sprites/glow01.spr"          // bossun basindaki parlama
vex_res SPR_LASER         "sprites/vexmira/laser.spr"   // lazer / ikmal isin dokusu
vex_res SPR_ZONE          "sprites/vexmira/zone.spr"   // yerdeki tehlike halkasi (herkes gorur)
vex_res SPR_TARGET        "sprites/vexmira/target.spr"   // yildirim / olum isareti hedefi
vex_res SPR_BEACON        "sprites/vexmira/beacon.spr"   // ikmal kutusu altin parlamasi
vex_res SPR_ORB           "sprites/vexmira/orb.spr"   // enerji kuresi / asit / yumurta
vex_res SPR_MARK          "sprites/vexmira/mark.spr"   // kafa ustu olum isareti
vex_res SPR_FIRE          "sprites/vexmira/fire.spr"   // alev
// Kafa ustu gostergeler (kare sayisi / boyut / cizim modu dosyadan okunur)
vex_res SPR_BOSSBAR       "sprites/vexmira/bossbar.spr"        // boss can bari (51 kare: kare i = %2*i)
vex_res SPR_BOSSICON      "sprites/vexmira/bossicon.spr"       // boss amblemi (kare = boss no)
vex_res SPR_HPBAR         "sprites/vexmira/hpbar_small.spr"    // Nemesis / Assassin / Alfa can bari
vex_res SPR_ICON_VIP      "sprites/vexmira/icon_vip.spr"
vex_res SPR_ICON_ADMIN    "sprites/vexmira/icon_admin.spr"
vex_res SPR_ICON_MVP      "sprites/vexmira/icon_mvp.spr"       // onceki roundun MVP'si
vex_res SPR_ICON_LAST     "sprites/vexmira/icon_lasthuman.spr" // son insan
vex_res SPR_ICON_ALPHA    "sprites/vexmira/icon_alpha.spr"     // alfa zombi

// =====================================================================
//  PRECACHE BUTCESI (GoldSrc: 512 ses / 512 model+sprite / 512 indirme)
// =====================================================================
// Stok CS + harita zaten ~200-260 ses ve ~170 model kullanir. Asilirsa harita ACILMAZ.
// 2D sesler (anons / arayuz / muzik) ses yuvasi harcamaz (indirilir, "spk" ile calinir).
// Her haritada sadece BOSS_PRELOAD kadar boss yuklenir (model + pence + sesler); bosslar
// haritadan haritaya doner. Admin "boss sec" menusu sadece yuklu bosslari listeler.
// Sunucu konsolu: vex_precache_stats  (sayilar + yuklu bosslar)
vex_res BOSS_PRELOAD      "4"      // bir haritada en fazla kac boss (1-9)
vex_res BOSS_PRELOAD_LIST ""       // sabit liste (or. "0 3 5 8"); bos = otomatik donusum
vex_res SOUND_BUDGET      "160"    // eklentinin 3D ses siniri (asan sesler genel sese duser; stok CS + botlar ~305 ses)
vex_res MODEL_BUDGET      "250"    // eklentinin model + sprite siniri (en son p_ silah modelleri elenir)

''')

# 4) Bosslar bolumu
BOSS = [('Brute','brute'),('Banshee','banshee'),('Overlord','overlord'),('Inferno','inferno'),('Reaper','reaper'),
        ('Frostlord','frostlord'),('Stormcaller','stormcaller'),('Hive Queen','hivequeen'),('Void','void')]
OLD = ['terror','vip','leet','arctic','gsg9','sas','gign','guerilla','urban']
RS = [('brute_stomp','brute_shatter','brute_wrath'),('banshee_lance','banshee_shriek','banshee_requiem'),
      ('overlord_prison','overlord_legion','overlord_nova'),('inferno_breath','inferno_pillar','inferno_nova'),
      ('reaper_step','reaper_chains','reaper_mark'),('frost_shards','frost_tomb','frost_zero'),
      ('storm_orb','storm_dash','storm_tempest'),('hive_spit','hive_cloud','hive_eggs'),
      ('void_bolt','void_singularity','void_horizon')]
b = ['''// =====================================================================
//  BOSSLAR: model, pence, bossa ozel sesler ve [R] yetenek sesleri
// =====================================================================
// B<n>_MODEL = oyuncu modeli adi (yoksa orijinal CS modeli), B<n>_CLAW = pence (el) modeli.
// Sesler (sound/vexmira/boss/<ad>_*.wav):
//   _INTRO giris (herkese)  _IDLE ara sira hirlama  _PAIN / _PAIN2 aci (sirayla)
//   _DEATH olum  _STEP adim (hiza gore)  _ATTACK pence / yetenek kukremesi
//   _PHASE faz degisimi  _KILL insan oldurunce alay  _R1 / _R2 / _R3 faz yetenekleri
// Istege bagli: B<n>_MUSIC "sound/vexmira/boss0_theme.mp3"
// Sadece bu haritada yuklenen bosslarin dosyalari indirilir (bkz. BOSS_PRELOAD).
''']
EV = [('INTRO','intro'),('IDLE','idle'),('PAIN','pain1'),('PAIN2','pain2'),('DEATH','death'),('STEP','step'),
      ('ATTACK','attack'),('PHASE','phase'),('KILL','kill')]
for i,(nm,f) in enumerate(BOSS):
    b.append('\n// %d - %s   (yedek model: %s)\n' % (i, nm, OLD[i]))
    b.append('vex_res B%d_MODEL     "vex_b_%s"\n' % (i, f))
    b.append('vex_res B%d_CLAW      "models/vexmira/claws/v_%s.mdl"\n' % (i, f))
    for k, sfx in EV:
        b.append('vex_res B%d_%-7s"vexmira/boss/%s_%s.wav"\n' % (i, k + ' ', f, sfx))
    for r in range(3):
        b.append('vex_res B%d_R%d        "vexmira/%s.wav"\n' % (i, r + 1, RS[i][r]))
b.append('''
// =====================================================================
//  OZEL KARAKTERLER / INSAN MODELLERI
// =====================================================================
// Oyuncu modelleri sadece ISIM (models/player/<ad>/<ad>.mdl). Yoksa orijinal CS modeline duser.
vex_res NEMESIS_MODEL     "vex_nemesis"                          // yedek: terror
vex_res NEMESIS_CLAW      "models/vexmira/claws/v_nemesis.mdl"
vex_res ASSASSIN_MODEL    "vex_assassin"                         // yedek: leet
vex_res ASSASSIN_CLAW     "models/vexmira/claws/v_assassin.mdl"
vex_res SURVIVOR_MODEL    "vex_survivor"                         // yedek: gign
vex_res SNIPER_MODEL      "vex_sniper"                           // yedek: sas
vex_res VIP_MODEL         "vex_vip"                              // VIP / ELITE insanlar
vex_res ADMIN_MODEL       "vex_admin"                            // adminler (ADMIN_BAN)
// Insanlar (CT): listeden rastgele, oyuncu basina sabit. Hicbiri yoksa oyunun CT modeli.
vex_res HUMAN_MODELS      "vex_operator vex_ranger vex_hazmat"
// vex_res HUMAN_MODEL     "vex_custom"                          // listeye bir model daha ekler
// Nemesis / Assassin sesleri (sound/vexmira/special/)
vex_res NEMESIS_INTRO     "vexmira/special/nemesis_intro.wav"    // giris (herkese)
vex_res NEMESIS_IDLE      "vexmira/special/nemesis_idle.wav"
vex_res NEMESIS_PAIN      "vexmira/special/nemesis_pain.wav"
vex_res NEMESIS_DEATH     "vexmira/special/nemesis_death.wav"
vex_res NEMESIS_ATTACK    "vexmira/special/nemesis_attack.wav"
vex_res ASSASSIN_INTRO    "vexmira/special/assassin_intro.wav"
vex_res ASSASSIN_IDLE     "vexmira/special/assassin_idle.wav"
vex_res ASSASSIN_PAIN     "vexmira/special/assassin_pain.wav"
vex_res ASSASSIN_DEATH    "vexmira/special/assassin_death.wav"
vex_res ASSASSIN_ATTACK   "vexmira/special/assassin_attack.wav"
// Arayuz sesleri (2D)
vex_res UI_VOTE_START     "vexmira/ui/vote_start.wav"
vex_res UI_VOTE_END       "vexmira/ui/vote_end.wav"
vex_res UI_BOSS_BAR       "vexmira/ui/boss_bar.wav"              // boss can bari belirince
vex_res UI_MENU_SELECT    "vexmira/ui/menu_select.wav"
vex_res UI_CLASS_SELECT   "vexmira/ui/class_select.wav"

// =====================================================================
//  SILAH MODELLERI (insanlar)  V_<SILAH> = el modeli, P_<SILAH> = elde gorunen
// =====================================================================
// Dosya yoksa oyunun kendi modeli kullanilir. p_ modelleri en dusuk onceliklidir
// (MODEL_BUDGET dolarsa ilk onlar elenir).
// Silah adlari: P228 GLOCK18 USP DEAGLE ELITE FIVESEVEN M3 XM1014 MAC10 TMP MP5NAVY
// UMP45 P90 GALIL FAMAS AK47 M4A1 SG552 AUG SCOUT AWP G3SG1 SG550 M249 KNIFE
// HEGRENADE SMOKEGRENADE FLASHBANG
vex_res V_KNIFE           "models/vexmira/weapons/v_vexblade.mdl"   // Vexmira bicagi
vex_res V_HEGRENADE       "models/vexmira/weapons/v_firebomb.mdl"   // ates bombasi
vex_res V_SMOKEGRENADE    "models/vexmira/weapons/v_frostbomb.mdl"  // buz bombasi
vex_res V_FLASHBANG       "models/vexmira/weapons/v_flare.mdl"      // isaret fisegi
''')
WEAP = ['P228','SCOUT','XM1014','MAC10','AUG','ELITE','FIVESEVEN','UMP45','SG550','GALIL','FAMAS','USP','GLOCK18','AWP',
        'MP5NAVY','M249','M3','M4A1','TMP','G3SG1','DEAGLE','SG552','AK47','P90']
for w in WEAP:
    b.append('vex_res P_%-15s "models/vexmira/weapons/p_%s.mdl"\n' % (w, w.lower()))
b.append('// Bicak / bombalar: p_vexblade / p_firebomb / p_frostbomb / p_flare varsa o, yoksa\n')
b.append('// p_knife / p_hegrenade / p_smokegrenade / p_flashbang otomatik secilir. Elle:\n')
b.append('// vex_res P_KNIFE         "models/vexmira/weapons/p_vexblade.mdl"\n')
b.append('''// Ozel silahlar (SW<n>_VMODEL / SW<n>_PMODEL):
// 0 Plazma (M4A1) 1 Ejder Topu (M249) 2 Yildirim (AWP) 3 Buz Kiran (XM1014)
// 4 Altin Kartal (Deagle) 5 Cehennem SMG (P90) 6 Vex Bicici (AK-47) 7 Bosluk Cagirici (SG550)
''')
for i in range(8):
    b.append('vex_res SW%d_VMODEL       "models/vexmira/weapons/v_sw%d.mdl"\n' % (i, i))
    b.append('vex_res SW%d_PMODEL       "models/vexmira/weapons/p_sw%d.mdl"\n' % (i, i))
b.append('\n')
cfg = replace_block(cfg, '// =====================================================================\n//  BOSSLAR: model, pence',
                    '// =====================================================================\n//  OYUN KURALLARI - ReGameDLL', ''.join(b))
open(P, 'w', encoding='utf-8').write(cfg)
print('ok')
