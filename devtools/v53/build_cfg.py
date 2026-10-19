#!/usr/bin/env python3
"""Vexmira 5.3.1 / 5.3.2 single config builder.

    python3 devtools/v53/build_cfg.py            # writes configs/vexmira.cfg (+ embeds it into vexmira_gear.sma)

Input : devtools/v53/src/vexmira_530.cfg + vexmira_epic_530.cfg (owner's 5.3.0 files, epic loaded after the base)
Output: ONE configs/vexmira.cfg - every key once, final value, grouped in documented sections (Turkish).
        The gear plugin's embedded default copy (ZC_F_CFG) is regenerated from it, the epic copy emptied.
Overrides for 5.3.1 live in OVERRIDE below (key -> full line).
"""
from __future__ import annotations

import os
import re
import shlex

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
CFG = os.path.join(REPO, 'cstrike/addons/amxmodx/configs')
GEAR = os.path.join(REPO, 'cstrike/addons/amxmodx/scripting/vexmira_gear.sma')

# table commands: number of index tokens after the command (key identity)
INDEXED = {'vex_item': 1, 'vex_class': 1, 'vex_sw': 1, 'vex_gun': 2, 'vex_job': 1, 'vex_boss_stat': 1,
           'vex_boss_skill': 2, 'vex_mode_rule': 1, 'vex_env_event': 1, 'vex_env_mode': 1, 'vex_env_boss': 1,
           'vex_env_calm': 1, 'vex_cosmetic': 2, 'vex_quest': 1, 'vex_sw_text': 2, 'vex_wing': 1, 'vex_pet': 1,
           'vex_hat': 1, 'vex_modewpn': 2, 'vex_res': 1, 'vex_restore': 1}

INFECT_POOL = 'zombie_plague/zombie_infec1.wav|zombie_plague/zombie_infec2.wav'
PAIN_POOL = 'zombie_plague/zombie_pain1.wav|zombie_plague/zombie_pain2.wav|zombie_plague/zombie_pain3.wav|zombie/zo_pain1.wav'
DIE_POOL = 'zombie_plague/zombie_die1.wav|zombie_plague/zombie_die2.wav|zombie_plague/zombie_die3.wav'

OVERRIDE = [
    ('vex_hostname "Vexmira Zombie Plague | 9 Boss + 18 Event | CSO Weapons | TR"', 'sunucu adi (en fazla 63 harf, Turkce harf YOK). Arastirma: listede en cok aranan kelimeler "Zombie Plague" / "ZM"; ozellik yazan adlar (boss, event, CSO) daha cok tiklaniyor; [TR] etiketi Turk oyuncuyu, Ingilizce kelimeler yabanciyi ceker. Alternatifler: "[ZM] Vexmira Zombie Plague | 9 Boss | CSO Silah | Lazer | FDL" / "Vexmira Zombie Plague [TR] | Boss + Event | CSO | Level | FDL"'),
    ('vex_hostname_dynamic 0', '1 = adin sonuna round / mod bilgisi eklenir, 0 = sabit ad'),
    ('vex_res BOSS_PRELOAD "3"', 'haritada yuklenen boss sayisi (her boss ~6 ses + model; 3 = 512 ses sinirindan guvenli pay, bosslar haritadan haritaya doner)'),
    ('vex_res BOSS_PRELOAD_LIST ""', 'bos = bosslar haritadan haritaya sirayla doner (hepsi zamanla gelir)'),
    ('vex_res BOSS_SCALE "1.6"', 'BOSS BUYUKLUGU: 1.0 = normal, 1.6 = 1.6 kat dev (model + hitbox kodla buyutulur)'),
    ('vex_res SKY_MODE "3"', '0 = haritanin kendi gokyuzu, 1 = rastgele, 2 = ilk, 3 = her round sonraki (rotasyon)'),
    ('vex_res SKY_LIST "vexmira_blood vexmira_toxic vexmira_void vexmira_inferno vexmira_eclipse vexmira_deadlight"',
     'gfx/env/<ad>up.tga ... 6 yuz; oyunculara otomatik indirilir'),
    ('vex_res NADE_INFECT_V "models/vexmira/nades/v_infect.mdl"', 'enfeksiyon bombasi el modeli (zombi pencesi)'),
    ('vex_res NADE_INFECT_P "models/vexmira/nades/p_infect.mdl"', 'enfeksiyon bombasi oyuncu ustu modeli'),
    ('vex_res NADE_INFECT_W "models/vexmira/nades/w_infect.mdl"', 'atilan enfeksiyon bombasi modeli'),
    ('vex_res LASERMINE_MODEL "models/vexmira/lasermine/lm_human.mdl"', 'varsayilan lazer mayin modeli'),
    ('vex_res LASERMINE_MODEL_HUMAN "models/vexmira/lasermine/lm_human.mdl"', 'insan lazer mayini (beyaz-mavi teknoloji)'),
    ('vex_res LASERMINE_MODEL_ZOMBIE "models/vexmira/lasermine/lm_zombie.mdl"', 'zombi lazer mayini (organik biyo-mayin)'),
    ('vex_res LASERMINE_BODY "0"', ''), ('vex_res LASERMINE_SKIN "0"', ''),
    ('vex_res LASERMINE_SEQUENCE "idle"', 'mayin bekleme animasyonu'),
    ('vex_res LASERMINE_DEPLOY_SEQ "deploy"', 'mayin acilis animasyonu'),
    ('vex_res LASERMINE_ANGLES "0 0 0"', ''), ('vex_res LASERMINE_OFFSET "0.3"', ''),
    ('vex_res LASERMINE_EMITTER "10.3 0 0"', 'isinin ciktigi uc (model +X ekseni)'),
    ('vex_res CSO_LANG "tr"', 'kart dili: tr / en / both (both = oyuncunun diline gore, ~30 dosya daha indirilir)'),
    ('vex_res SKY_PER_MAP "3"', 'bir haritada donen gokyuzu sayisi (her harita sonraki 3 lu gruba gecer; indirme limiti icin)'),
    ('vex_res CSO_CARDSET "c539"', 'ekran kartlari: c538 = 5.3.8 yeni net kartlar (onerilen; sadece CSO_LANG dili indirilir), c533 = eski kart seti, off = sadece yazi kart'),
    ('vex_res MODEL_GUARD "1"', '1 = bozuk model/sprite (eksik doku, GL_Upload16 dokusu, kesik dosya) oyuncuya GONDERILMEZ, eski/varsayilan model kullanilir; sebep logs/vexmira_modelguard.log'),
    ('vex_res MODEL_UNIQUE "1"', '1 = sadece T dosyasi olmayan oyuncu modelleri benzersiz isimle kopyalanir; model ekleyince: vex_model_build -> restart'),
    ('vex_res ZOMBIE_HIT "zombie/claw_strike1.wav|zombie/claw_strike2.wav|zombie/claw_strike3.wav"',
     'pence ile vurus (| ile birden fazla ses: her vurusta rastgele biri)'),
    ('vex_res ZOMBIE_STAB "zombie/claw_strike2.wav|zombie/claw_strike3.wav"', 'agir pence (sag tik) vurusu'),
    ('vex_res ZOMBIE_SLASH "zombie/claw_miss1.wav|zombie/claw_miss2.wav"', 'pence havaya'),
    ('vex_res ZOMBIE_HITWALL "zombie/claw_miss2.wav|zombie/claw_miss1.wav"', 'pence duvara'),
    ('vex_res ZOMBIE_PAIN "%s"' % PAIN_POOL, 'zombi hasar alinca (sinifa ozel yoksa)'),
    ('vex_res ZOMBIE_DIE "%s"' % DIE_POOL, 'zombi olunce'),
    ('vex_res ZOMBIE_INFECT "%s"' % INFECT_POOL, 'insan zombiye donusunce'),
    ('vex_sw_damage_mult 2.4', 'OZEL SILAH HASARI: tum ozel silahlarin hasar carpani (vex_sw carpaninin USTUNE; 1.0 = eski, 5.3.1 = 3.0)'),
    ('vex_unlimited_bpammo 1', '1 = herkeste sinirsiz yedek mermi (TUM mod/eventlerde), ozel silahlar haric'),
    ('vex_nade_fx 1', '1 = ates / buz / isik / enfeksiyon bombalarinda katmanli epik patlama efektleri'),
    ('vex_cos_follow 1', '1 = kanat + sapka oyuncuya kemikle yapisik (gecikme / isinlanma yok)'),
    ('vex_blackout_light "b"', 'Elektrik Kesintisi roundu isik seviyesi (a = zifiri karanlik ... m = normal)'),
    ('vex_auto_hitbox 1', '1 = boyu uzun modellerde (CSO zombileri, dev bosslar) vurus kutusu modele gore otomatik buyur'),
    ('vex_laser_prices "300 450 600 900"', 'VexCoin lazer isinlari: Plazma / Kan / Toksik / Gokkusagi fiyatlari'),
    ('vex_env_event 18 b 0 0 0 18 0', 'Elektrik Kesintisi: tum round karanlik'),
    # ---- 5.3.3 ----
    ('vex_lm_color_mode 3', 'lazer rengi: 3 = insan mavi / zombi yesil (nabizli), 2 = vex_lm_color, 1 = oyuncuya gore, 0 = mayin canina gore'),
    ('mapcyclefile "mapcycle_vexmira.txt"', 'harita sirasi dosyasi (sunucudaki haritalari buraya ekle; oylama havuzu: vex_map_pool)'),
    ('vex_boss_hpcard 1', '1 = boss savasinda nisangahin ustunde resimli BOSS CAN BARI (yazili bar yerine)'),
    ('vex_cso_notes 255', 'hangi resimli kartlar acik (bit toplami): 1 kill 2 MVP 4 round 8 kazanma 16 boss/ozel round 32 son insan 64 seviye 128 ilk kan/boss oldu/enfekte/geri sayim. 255 = HEPSI'),
    ('vex_cso_fov 89', 'KART ICIN SART: 89 (90 olursa resimli kartlar gorunmez; kart istemcinin zoom nisangahi ile cizilir)'),
    # ---- 5.3.2 ----
    ('vex_chat_prefix "^4[^1VEXMIRA^4]^1"', 'sistem mesaji etiketi (^1 sari ^3 takim rengi ^4 yesil; Turkce harf kullanma, CS 1.6 sohbeti bozuk gosterir)'),
    ('vex_chat_prefix_boss "^3[^4BOSS^3]^1"', 'boss / boss yetenekleri etiketi'),
    ('vex_chat_prefix_event "^4[^3EVENT^4]^1"', 'event / hava olayi etiketi'),
    ('vex_chat_prefix_admin "^3[^4ADMIN^3]^1"', 'admin islemleri etiketi'),
    ('vex_res BOSS_GIANT "file"', 'DEV BOSS: file = boss modelinin buyutulmus + inceltilmis kopyasi kendiliginden uretilir (models/player/<boss>_x16, orijinalin ~3te1 i boyutunda) | off = normal boyut, hic indirme yok | clone = sadece Xash istemcisi (Steam de boss buyumez - KULLANMA)'),
    ('vex_res BOSS_GIANT_TEX "128"', 'dev boss kopyasinda doku boyutu siniri (px). 128 = en kucuk indirme, giris hizli (onerilen) | 256 = daha net ama 3-4 kat buyuk | 512 = daha net ama daha buyuk dosya | 0 = dokulara dokunma'),
    ('vex_res BOSS_GIANT_ALL "0"', '0 = sadece o haritanin 3 bossu indirilir (giris HIZLI, onerilen) | 1 = 9 dev bossun hepsi ilk giriste indirilir (giris COK UZUN) | dev boss istemiyorsan BOSS_GIANT "off" = hic indirme yok'),
    ('vex_topboard 1', 'UST SKOR PANELI (CSO tarzi): 1 = acik  [INSAN galibiyet/canli]  TUR + sure + mod  [ZOMBI galibiyet/canli]'),
    ('vex_topboard_pad 44', 'panelde yan bloklarin ortadan uzakligi (bosluk sayisi). Yazilar ust uste binerse buyut, cok aciksa kucult (10-60)'),
    ('vex_topboard_y 0.01', 'panelin ekrandaki yuksekligi (0.0 = en ust, 0.05 = biraz asagi)'),
    ('vex_radio_text 1', '1 = ozel telsiz sesi calinca sohbete gercekci telsiz metni yazilir (TR/EN, oyuncunun diline gore)'),
    ('vex_cos_smooth 1', '1 = sapkalar oyuncuyla ayni akicilikta hareket eder (gecikme / isinlanma yok)'),
    ('vex_map_pool "zm_vexmira_dust2fixed zm_vexmira_7door zm_vexmira_dust zm_vexmira_icefy zm_3rooms zm_cross zm_dust_world zm_foda zm_fox zm_lila_panic zm_ice_attack3"', 'oylamadaki haritalar (sunucuda .bsp dosyasi olmayan harita oylamada gosterilmez)'),
    ('vex_full_rotation 1', '1 = her haritada (30 round) 7 ozel modun HEPSI + 18 eventin HEPSI + coklu enfeksiyon kesin oynanir (harita basinda plan kurulur; boss roundlari vex_boss_rounds). 0 = eski rastgele sistem'),
    ('vex_special_rounds "4 11 19 26"', 'ozel mod roundlari - SADECE vex_full_rotation 0 iken kullanilir'),
    ('vex_event_chance 30', 'event cikma sansi (%) - SADECE vex_full_rotation 0 iken kullanilir'),
    ('vex_lm_damage 550', 'INSAN lazerinin zombiye vurdugu hasar (her temas)'),
    ('vex_lm_zombie_damage 550', 'ZOMBI lazerinin insana vurdugu hasar (her temas)'),
    ('vex_lm_keep 0', '0 = sahibi zombi olunca / olunce lazerleri KALKAR (5.3.8 istegi), 1 = tur sonuna kadar kalir'),
    ('vex_lm_human_break_mult 1.0', 'insanlarin zombi lazerine verdigi hasar carpani (mermiyle kirma; zombiler icin vex_lm_zombie_mult)'),
    ('vex_boss_arena_tp 1', '1 = boss roundu baslayinca boss ve yasayan tum insanlar haritanin boss meydanina isinlanir (harita ini [arena] bolumu olan haritalarda: zm_vexmira_dust2fixed)'),
    ('vex_bdoor_hp 1200', 'kirilabilir kamp kapilarinin cani (haritada netname vxbd kapi varsa). Insanlar E ile acar/kapatir, zombiler vurarak kirar; her round geri gelir'),
    ('vex_bdoor_boss_mult 4.0', 'boss / nemesis / assassin kapiya bu kat fazla hasar verir'),
    ('vex_gun_damage_mult 1.35', 'NORMAL silahlarin (CS silahlari) zombilere hasar carpani (oyuncu geri bildirimi: hasar az geliyordu)'),
    ('vex_knockback_mult 1.6', 'mermilerin zombiyi geri itme gucu (oyuncu geri bildirimi: geri tepme yetersizdi; eski 0.75)'),
    ('vex_knockback_max 650', 'tek mermide en fazla geri itme hizi'),
    ('vex_headshot_sound "buttons/blip1"', 'zombiye kafadan vurunca vuran oyuncuya calan kisa ses (stok CS sesi, indirme yok; bos = kapali)'),
    ('vex_no_urban 1', '1 = kimse urban (Seal Team 6) gorunumunu almaz. Bazi oyuncularda baska ZP sunucularindan kalma bozuk urban.mdl var: urbanT.mdl hatasi verip oyunu kapatiyordu'),
    ('vex_lm_beam_width 14', 'lazer isini kalinligi (5.3.2 dokusu: ince parlak cekirdek + yumusak isik hali)'),
    # ---- 5.3.8: new crisp overhead sprites (one shared icon sheet, animated HP bars with damage flash)
    ('vex_res SPR_HPBAR "sprites/vexmira/c539/hp538.spr"', 'zombi can bari (kafa ustu): 5.3.8 animasyonlu bar, hasar alinca parlar'),
    ('vex_res SPR_BOSSBAR "sprites/vexmira/c539/bossbar538.spr"', 'boss can bari (kafa ustu): 5.3.8'),
    ('vex_res SPR_BOSSICON "sprites/vexmira/c539/icons538.spr"', 'boss amblemi: icons538 (kare 12-20 = boss turleri)'),
    ('vex_res SPR_ICON_VIP "sprites/vexmira/c539/icons538.spr"', 'VIP ikonu (icons538 kare 1)'),
    ('vex_res SPR_ICON_ADMIN "sprites/vexmira/c539/icons538.spr"', 'ADMIN ikonu (icons538 kare 0)'),
    ('vex_res SPR_ICON_MVP "sprites/vexmira/c539/icons538.spr"', 'MVP ikonu (icons538 kare 3)'),
    ('vex_res SPR_ICON_LAST "sprites/vexmira/c539/icons538.spr"', 'son insan ikonu (icons538 kare 2)'),
    ('vex_res SPR_ICON_ALPHA "sprites/vexmira/c539/icons538.spr"', 'alfa zombi ikonu (icons538 kare 4)'),
    ('vex_res Z0_MODEL "z4_heavy"', ''),
    ('vex_res Z1_MODEL "zombie_source"', ''),
    ('vex_res Z2_MODEL "cso_heavy"', ''),
    ('vex_res Z6_MODEL "deimos_zombi_host"', ''),
    ('vex_res Z9_MODEL "l4d_tank"', ''),
    ('vex_res Z13_MODEL "vex_scary"', ''),
    ('vex_res Z18_MODEL "zombie_source"', ''),
    ('vex_res Z21_MODEL "cso_heavy"', ''),
    ('vex_res Z23_MODEL "nemesis"', ''),
    ('vex_res Z0_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z1_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z2_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z3_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z4_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z5_CLAW "models/vexmira/community/claws/scary.mdl"', ''),
    ('vex_res Z6_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z7_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z8_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z9_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z10_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z11_CLAW "models/vexmira/community/claws/scary.mdl"', ''),
    ('vex_res Z12_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z13_CLAW "models/vexmira/community/claws/scary.mdl"', ''),
    ('vex_res Z14_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z15_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z16_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z17_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z18_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z19_CLAW "models/vexmira/community/claws/scary.mdl"', ''),
    ('vex_res Z20_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z21_CLAW "models/vexmira/community/claws/heavy.mdl"', ''),
    ('vex_res Z22_CLAW "models/vexmira/community/claws/classic.mdl"', ''),
    ('vex_res Z23_CLAW "models/vexmira/community/claws/scary.mdl"', ''),
    ('vex_res CLAW_MODEL "models/zombie_plague/v_knife_zombie.mdl"', 'varsayilan zombi pence modeli'),
    ('vex_res NEMESIS_MODEL "nemesis"', 'Nemesis modeli'),
    ('vex_res NEMESIS_CLAW "models/zombie_plague/v_knife_zombie.mdl"', 'Nemesis pence modeli'),
    ('vex_res HUMAN_MODELS "sp_halo_admins"', 'CT varsayilan karakterler (sadece yazilanlar indirilir, her biri ~1.6 MB; ek secenekler: vx539_csoct vx539_cso2_arctic vx539_re_leon vx539_sakura)'),
    ('vex_res SURVIVOR_MODEL "sp_halo_admins"', 'Survivor modeli (CT setinden: ek indirme yok)'),
    ('vex_res SNIPER_MODEL "sp_halo_admins"', 'Sniper modeli (CT setinden: ek indirme yok)'),
    ('vex_res ADMIN_MODEL "sp_halo_admins"', 'SADECE admin (ADMIN_BAN) CT modeli; "" = kapali, indirilmez'),
    ('vex_res VIP_MODEL "sp_halo_admins"', 'SADECE VIP CT modeli; "" = kapali, indirilmez'),
    ('vex_res V_AK47 "models/vexmira_ze/skins/vexmira_v_ak47.mdl"', ''),
    ('vex_res V_AWP "models/vexmira_ze/skins/vexmira_v_awp.mdl"', ''),
    ('vex_res V_M4A1 "models/vexmira_ze/skins/vexmira_v_m4a1.mdl"', ''),
    ('vex_res V_DEAGLE "models/vexmira_ze/skins/vexmira_v_deagle.mdl"', ''),
    ('vex_res V_FAMAS "models/vexmira_ze/skins/vexmira_v_famas.mdl"', ''),
    ('vex_res V_GALIL "models/vexmira/arena52/default/v_galil.mdl"', ''),
    ('vex_res V_GLOCK18 "models/vexmira_ze/skins/vexmira_v_glock18.mdl"', ''),
    ('vex_res V_USP "models/vexmira_ze/skins/vexmira_v_usp.mdl"', ''),
    ('vex_res V_M249 "models/vexmira_ze/skins/vexmira_v_m249.mdl"', ''),
    ('vex_res V_M3 "models/vexmira_ze/skins/vexmira_v_m3.mdl"', ''),
    ('vex_res V_XM1014 "models/vexmira_ze/skins/vexmira_v_xm1014.mdl"', ''),
    ('mp_consistency 0', 'ReGameDLL: 0 = oyuncunun kendi player modeli yuzunden ATMA ("player model" kick fix)'),
    ('vex_res UNPRECACHE "1"', 'UNPRECACHER: 1 = oyunun kullanilmayan stok dosyalarini sesleri (C4 / bomba, rehine, tutor, geiger, bot telsizi, sprey) yukleme -> precache slotu + giris hizi; 0 = kapali'),
    ('vex_res UNPRECACHE_EXTRA ""', 'ek engellenecek stok dosyalar sesleri (bosluk ile, ornek: "weapons/c4_beep1.wav"); model engellenmez (oyun bazi stok modelleri oyun icinde tekrar yukler)'),
    ('vex_res SPR_ZOMBIE47 ""', 'eski zombi bari kapali (5.3.8 hp538 kullanilir)'),
    # ---- 5.3.8: special knives (Thanos-9 / Skull-9 removed). MK1..MK6 = market knives after the 4 classic ones.
    ('vex_hud_calm 1', '1 = tum HUD yazilari tek sakin renk (oyuncunun tema rengi, beyaza yakin); 0 = eski renkli'),
    ('vex_menu_plain 1', '1 = sade menuler (tek baslik satiri, beyaz numara + yazi, gri fiyat); 0 = eski renkli'),
    ('vex_menu_gap 1', '1 = menude her secenegin altinda bos satir (arasi acik, okunakli); 0 = sik liste'),
    ('vex_res HITMARKER "1"', 'vur / kafadan vur / oldur hissi: c538 nisangah isareti (hm_hit / hm_hs / hm_kill) + kisa stok ses; 0 = kapali'),
    ('vex_res ZUP_STEPS "40 110 220 380 600"', 'ZOMBI SINIF YUKSELTME: seviye 1..5 icin gereken puan (enfekte +1, insan oldurme +2; her sinif ayri, kalici). Seviye basina: bekleme -%6, menzil +%6, hasar +%8; Sv 3+ renkli halka. Menu: say /upgrade veya /yukselt'),
    ('vex_res ITEM_MASK_COST "30"', 'MARKET (insan): Enfeksiyon Maskesi AP fiyati; bir sonraki enfeksiyon vurusunu engeller (0 = satilmaz)'),
    ('vex_res ITEM_MASK_MODEL ""', 'maske takan insanin modeli (models/player/AD/AD.mdl)'),
    ('vex_res ITEM_ZARMOR_COST "25"', 'MARKET (zombi): Zombi Zirhi AP fiyati (0 = satilmaz)'),
    ('vex_res ITEM_ZARMOR_HP "1500"', 'zirhin emdigi toplam hasar'),
    ('vex_res ITEM_ZARMOR_CUT "0.4"', 'zirh varken alinan hasar azalmasi (0.4 = %40)'),
    ('vex_res ITEM_ZARMOR_MODEL ""', 'zirhli zombinin modeli'),
    ('vex_sknife_damage_mult 2.5', 'ozel bicaklarin (Dragon Sword, Katana, Light Saber, Horse Axe) zombiye hasar carpani'),
    ('vex_sknife_knockback 430', 'ozel bicak darbesi zombiyi bu hizla geri iter (her bicakta MK<n>_KB carpani)'),
    ('vex_sknife_boss_kb 0.25', 'boss / nemesis / assassin icin geri itme carpani'),
    ('vex_res MK1_NAME "Balrog-9 / Ates Yumrugu"', 'pazar bicagi 1: ad (MK<n>_V v_ modeli yoksa bicak menude gizlenir)'),
    ('vex_res MK1_V "models/vexmira/arena48/v_balrog.mdl"', 'bicak 1 v_ modeli'),
    ('vex_res MK1_P "models/vexmira/arena48/p_balrog.mdl"', 'bicak 1 p_ modeli'),
    ('vex_res MK1_SND "vexmira/arena48/melee/balrog"', 'bicak 1 ses oneki (_swing.wav / _hit.wav eklenir)'),
    ('vex_res MK1_ANIM "6 0 1 11"', 'bicak 1 animasyon no: cekme bekleme hafif agir'),
    ('vex_res MK1_DMG "1.4"', 'bicak 1 hasar carpani (hafif 170, agir 520 x carpan)'),
    ('vex_res MK1_KB "1.0"', 'bicak 1 geri itme carpani'),
    ('vex_res MK1_FX "0"', 'agir vurus efekti: 0 ates 1 simsek 2 buz 3 havaya firlat 4 zehir alani 5 vakum (cek)'),
    ('vex_res MK1_COST "500"', 'bicak 1 VC fiyati'),
    ('vex_res MK2_NAME "Janus-9 / Yildirim"', 'pazar bicagi 2'),
    ('vex_res MK2_V "models/vexmira/arena48/v_janus.mdl"', ''),
    ('vex_res MK2_P "models/vexmira/arena48/p_janus.mdl"', ''),
    ('vex_res MK2_SND "vexmira/arena48/melee/janus"', ''),
    ('vex_res MK2_ANIM "9 0 3 11"', ''),
    ('vex_res MK2_FX "1"', ''),
    ('vex_res MK2_COST "650"', ''),
    ('vex_res MK2_DMG "1.4"', ''),
    ('vex_res MK3_NAME "Magma Blade / Lav Kilici"', 'pazar bicagi 3'),
    ('vex_res MK3_V "models/vexmira/v539/knives/magmablade/v_magmablade.mdl"', ''),
    ('vex_res MK3_P "models/p_knife.mdl"', 'p_ modeli (stok CS dosyasi, indirme yok)'),
    ('vex_res MK3_SWING ""', 'havaya vurus sesleri (| ile birden fazla, rastgele); bos = stok CS bicak sesi (indirme yok)'),
    ('vex_res MK3_HIT ""', 'zombiye isabet sesleri'),
    ('vex_res MK3_STAB ""', 'agir vurus (sag tik) sesi'),
    ('vex_res MK3_ANIM "3 0 1 4"', 'stok v_knife sirasi: cekme bekleme hafif agir'),
    ('vex_res MK3_DMG "180 650"', 'iki sayi = hafif agir mutlak hasar; tek sayi = carpan'),
    ('vex_res MK3_RATE "0.45 1.1"', 'hafif / agir vurus araligi (sn)'),
    ('vex_res MK3_RANGE "85"', ''),
    ('vex_res MK3_KB "1.6"', ''),
    ('vex_res MK3_FX "0"', '6 = %10 kritik x3 + kirilma parcasi, 7 = 2 sn icinde 3. vurus kombo x1.5'),
    ('vex_res MK3_COST "700"', ''),
    ('vex_res MK4_NAME "Tomahawk / Savas Baltasi"', 'pazar bicagi 4'),
    ('vex_res MK4_V "models/vexmira/v539/knives/tomahawk/v_tomahawk.mdl"', ''),
    ('vex_res MK4_P "models/p_knife.mdl"', ''),
    ('vex_res MK4_SWING "off"', 'off = sunucu sesi yok (model kendi sesini caliyor)'),
    ('vex_res MK4_HIT "vexmira/v539/tomahawk/knife_hit1.wav"', ''),
    ('vex_res MK4_STAB "off"', ''),
    ('vex_res MK4_SOUNDS "vexmira/v539/tomahawk/knife_draw.wav|vexmira/v539/tomahawk/knife_slash1.wav|vexmira/v539/tomahawk/knife_slash2.wav|vexmira/v539/tomahawk/knife_stab1.wav"', 'modelin kendi caldigi sesler (sadece indirilir)'),
    ('vex_res MK4_ANIM "3 0 1 4"', ''),
    ('vex_res MK4_DMG "220 800"', ''),
    ('vex_res MK4_RATE "0.6 1.3"', ''),
    ('vex_res MK4_RANGE "90"', ''),
    ('vex_res MK4_KB "2.2"', ''),
    ('vex_res MK4_FX "3"', ''),
    ('vex_res MK4_COST "850"', ''),
    ('vex_res MK5_NAME "Pickaxe / Kazma"', 'pazar bicagi 5'),
    ('vex_res MK5_V "models/vexmira/v539/knives/pickaxe/v_pickaxeb.mdl"', ''),
    ('vex_res MK5_P "models/p_knife.mdl"', ''),
    ('vex_res MK5_SWING ""', ''),
    ('vex_res MK5_HIT ""', ''),
    ('vex_res MK5_STAB ""', ''),
    ('vex_res MK5_ANIM "3 0 1 4"', ''),
    ('vex_res MK5_DMG "160 600"', ''),
    ('vex_res MK5_RATE "0.4 1.0"', ''),
    ('vex_res MK5_RANGE "80"', ''),
    ('vex_res MK5_KB "1.3"', ''),
    ('vex_res MK5_FX "6"', ''),
    ('vex_res MK5_COST "750"', ''),
    ('vex_res MK6_NAME "Crowbar / Levye"', 'pazar bicagi 6'),
    ('vex_res MK6_V "models/vexmira/v539/knives/crowbar/v_crowbarb.mdl"', ''),
    ('vex_res MK6_P "models/p_knife.mdl"', ''),
    ('vex_res MK6_SWING ""', ''),
    ('vex_res MK6_HIT ""', ''),
    ('vex_res MK6_STAB ""', ''),
    ('vex_res MK6_ANIM "3 0 1 4"', ''),
    ('vex_res MK6_DMG "200 700"', ''),
    ('vex_res MK6_RATE "0.35 1.0"', ''),
    ('vex_res MK6_RANGE "80"', ''),
    ('vex_res MK6_KB "1.8"', ''),
    ('vex_res MK6_FX "7"', ''),
    ('vex_res MK6_COST "800"', ''),
    ('vex_res SG1_NAME "Portal Gun"', 'ARSENAL-538 ozel silah 1 (ozel silah menusunde, AP ile). SG<n>_V dosyasi yoksa gizlenir'),
    ('vex_res SG1_BASE "weapon_m249"', 'taban silah (weapon_m249 / weapon_xm1014 / weapon_mp5navy / weapon_usp / weapon_elite ...)'),
    ('vex_res SG1_V "models/vexmira/v539/weapons/portalgun/v_portalgun.mdl"', ''),
    ('vex_res SG1_P "models/vexmira/v539/weapons/portalgun/p_portalgun.mdl"', 'bos = stok p_ modeli (indirme yok)'),
    ('vex_res SG1_W "models/vexmira/v539/weapons/portalgun/w_portalgun.mdl"', 'yere dusen model; bos = stok'),
    ('vex_res SG1_FIRE "vexmira/v539/portalgun/m249-1.wav"', 'ates sesi (| ile birden fazla)'),
    ('vex_res SG1_FIRE2 ""', 'ozel atis sesi'),
    ('vex_res SG1_SOUNDS ""', 'modelin kendi caldigi sesler (sadece indirilir)'),
    ('vex_res SG1_ANIM "0 4 1 2 1 -1"', 'animasyon no: bekleme cekme ates1 ates2 ates3 doldurma (-1 = yok)'),
    ('vex_res SG1_DMG "1.4"', 'hasar carpani (vex_sw_damage_mult ile carpilir)'),
    ('vex_res SG1_RATE "0.12"', 'atis araligi (sn)'),
    ('vex_res SG1_CLIP "40"', 'sarjor'),
    ('vex_res SG1_BPAMMO "200"', 'yedek mermi'),
    ('vex_res SG1_KB "2.5"', 'geri itme'),
    ('vex_res SG1_FX "1"', 'enerji isini + itme + yavaslatma, sag tik = itme patlamasi (sarjor bitmez)'),
    ('vex_res SG1_COST "30"', 'AP fiyati'),
    ('vex_res SG1_RGB "60 160 255"', 'efekt rengi'),
    ('vex_res SG2_NAME "Balrog-VII"', 'ozel silah 2'),
    ('vex_res SG2_BASE "weapon_m249"', ''),
    ('vex_res SG2_V "models/vexmira/v539/weapons/balrog7/v_balrog7b.mdl"', ''),
    ('vex_res SG2_P ""', ''),
    ('vex_res SG2_W ""', ''),
    ('vex_res SG2_FIRE "vexmira/v539/balrog7/m249-1.wav"', ''),
    ('vex_res SG2_FIRE2 "vexmira/v539/balrog7/m249-2.wav"', ''),
    ('vex_res SG2_SOUNDS "vexmira/v539/balrog7/balrog7_clipout1.wav|vexmira/v539/balrog7/balrog7_clipout2.wav|vexmira/v539/balrog7/balrog7_clipin1.wav|vexmira/v539/balrog7/balrog7_clipin2.wav|vexmira/v539/balrog7/balrog7_clipin3.wav"', ''),
    ('vex_res SG2_ANIM "0 4 1 2 1 3"', ''),
    ('vex_res SG2_DMG "1.3"', ''),
    ('vex_res SG2_RATE "0.09"', ''),
    ('vex_res SG2_CLIP "120"', ''),
    ('vex_res SG2_BPAMMO "360"', ''),
    ('vex_res SG2_KB "1.5"', ''),
    ('vex_res SG2_FX "2"', 'her 10. mermi atesli patlama (90 birim, 60 hasar)'),
    ('vex_res SG2_COST "32"', ''),
    ('vex_res SG2_RGB "255 120 40"', ''),
    ('vex_res SG3_NAME "Balrog-XI"', 'ozel silah 3'),
    ('vex_res SG3_BASE "weapon_xm1014"', ''),
    ('vex_res SG3_V "models/vexmira/v539/weapons/balrog11/v_balrog11.mdl"', ''),
    ('vex_res SG3_P ""', ''),
    ('vex_res SG3_W "models/vexmira/v539/weapons/balrog11/w_balrog11.mdl"', ''),
    ('vex_res SG3_FIRE "vexmira/v539/balrog11/xm1014-1.wav"', ''),
    ('vex_res SG3_FIRE2 ""', ''),
    ('vex_res SG3_SOUNDS "vexmira/v539/balrog11/xm1014-insert.wav|vexmira/v539/balrog11/balrog11_draw.wav"', ''),
    ('vex_res SG3_ANIM "0 6 1 2 1 3"', ''),
    ('vex_res SG3_DMG "1.5"', ''),
    ('vex_res SG3_RATE "0.25"', ''),
    ('vex_res SG3_CLIP "12"', ''),
    ('vex_res SG3_BPAMMO "96"', ''),
    ('vex_res SG3_KB "6.0"', ''),
    ('vex_res SG3_FX "3"', 'her 4. atis yakar; sag tik = alev topu (4 sn bekleme)'),
    ('vex_res SG3_COST "34"', ''),
    ('vex_res SG3_RGB "255 80 30"', ''),
    ('vex_res SG4_NAME "MP7 Nemesis"', 'ozel silah 4'),
    ('vex_res SG4_BASE "weapon_mp5navy"', ''),
    ('vex_res SG4_V "models/vexmira/v539/weapons/mp7nemesis/v_mp7nemesis.mdl"', ''),
    ('vex_res SG4_P ""', ''),
    ('vex_res SG4_W ""', ''),
    ('vex_res SG4_FIRE "vexmira/v539/mp7nemesis/mp5-1.wav|vexmira/v539/mp7nemesis/mp5-2.wav"', ''),
    ('vex_res SG4_FIRE2 ""', ''),
    ('vex_res SG4_SOUNDS "vexmira/v539/mp7nemesis/mp5_clipout.wav|vexmira/v539/mp7nemesis/mp5_clipin.wav|vexmira/v539/mp7nemesis/mp5_slideback.wav"', ''),
    ('vex_res SG4_ANIM "0 2 3 4 5 1"', ''),
    ('vex_res SG4_DMG "1.35"', ''),
    ('vex_res SG4_RATE "0.07"', ''),
    ('vex_res SG4_CLIP "45"', ''),
    ('vex_res SG4_BPAMMO "270"', ''),
    ('vex_res SG4_KB "1.0"', ''),
    ('vex_res SG4_FX "4"', 'zehirli mermi (3 sn, 0.5 sn de 5 hasar, yesil parlama)'),
    ('vex_res SG4_COST "28"', ''),
    ('vex_res SG4_RGB "90 230 90"', ''),
    ('vex_res SG5_NAME "Charger-7"', 'ozel silah 5'),
    ('vex_res SG5_BASE "weapon_m249"', ''),
    ('vex_res SG5_V "models/vexmira/v539/weapons/charger7/v_charger7b.mdl"', ''),
    ('vex_res SG5_P "models/vexmira/v539/weapons/charger7/p_charger7.mdl"', ''),
    ('vex_res SG5_W "models/vexmira/v539/weapons/charger7/w_charger7.mdl"', ''),
    ('vex_res SG5_FIRE "vexmira/v539/charger7/m249-1.wav"', ''),
    ('vex_res SG5_FIRE2 "vexmira/v539/charger7/charger7-2.wav"', ''),
    ('vex_res SG5_SOUNDS "vexmira/v539/charger7/charger7_draw.wav|vexmira/v539/charger7/charger7_clipout1.wav|vexmira/v539/charger7/charger7_clipout2.wav|vexmira/v539/charger7/charger7_clipin1.wav|vexmira/v539/charger7/charger7_clipin2.wav|vexmira/v539/charger7/charger7_clipin3.wav"', ''),
    ('vex_res SG5_ANIM "0 4 1 2 1 3"', ''),
    ('vex_res SG5_DMG "1.25"', ''),
    ('vex_res SG5_RATE "0.08"', ''),
    ('vex_res SG5_CLIP "100"', ''),
    ('vex_res SG5_BPAMMO "300"', ''),
    ('vex_res SG5_KB "1.2"', ''),
    ('vex_res SG5_FX "5"', 'sag tik = delici lazer (400 hasar, 6 sn bekleme)'),
    ('vex_res SG5_COST "36"', ''),
    ('vex_res SG5_RGB "120 200 255"', ''),
    ('vex_res SG6_NAME "Chicken USP"', 'ozel silah 6'),
    ('vex_res SG6_BASE "weapon_usp"', ''),
    ('vex_res SG6_V "models/vexmira/v539/weapons/chickenusp/v_chickenuspb.mdl"', ''),
    ('vex_res SG6_P ""', ''),
    ('vex_res SG6_W ""', ''),
    ('vex_res SG6_FIRE "vexmira/v539/chickenusp/usp_unsil-1.wav"', ''),
    ('vex_res SG6_FIRE2 ""', ''),
    ('vex_res SG6_SOUNDS "vexmira/v539/chickenusp/usp_clipout.wav|vexmira/v539/chickenusp/usp_clipin.wav|vexmira/v539/chickenusp/usp_slideback.wav|vexmira/v539/chickenusp/usp_sliderelease.wav"', ''),
    ('vex_res SG6_ANIM "8 14 9 10 11 13"', ''),
    ('vex_res SG6_DMG "2.0"', ''),
    ('vex_res SG6_RATE "0.15"', ''),
    ('vex_res SG6_CLIP "20"', ''),
    ('vex_res SG6_BPAMMO "120"', ''),
    ('vex_res SG6_KB "3.0"', ''),
    ('vex_res SG6_FX "6"', '%15 sans tavuk sersemletme'),
    ('vex_res SG6_COST "20"', ''),
    ('vex_res SG6_RGB "255 220 120"', ''),
    ('vex_res SG7_NAME "Skull-2"', 'ozel silah 7'),
    ('vex_res SG7_BASE "weapon_elite"', ''),
    ('vex_res SG7_V "models/vexmira/v539/weapons/skull2/v_skull2b.mdl"', ''),
    ('vex_res SG7_P ""', ''),
    ('vex_res SG7_W ""', ''),
    ('vex_res SG7_FIRE "vexmira/v539/skull2/elite_fire.wav"', ''),
    ('vex_res SG7_FIRE2 ""', ''),
    ('vex_res SG7_SOUNDS "vexmira/v539/skull2/skull2_draw2.wav|vexmira/v539/skull2/skull2_clipout.wav|vexmira/v539/skull2/skull2_reload2_1.wav|vexmira/v539/skull2/skull2_reload2_2.wav"', ''),
    ('vex_res SG7_ANIM "0 15 2 3 8 14"', ''),
    ('vex_res SG7_DMG "1.8"', ''),
    ('vex_res SG7_RATE "0.11"', ''),
    ('vex_res SG7_CLIP "36"', ''),
    ('vex_res SG7_BPAMMO "180"', ''),
    ('vex_res SG7_KB "2.0"', ''),
    ('vex_res SG7_FX "7"', 'sag tik tek / cift atis (cift = 2x hiz, 0.8x hasar)'),
    ('vex_res SG7_COST "26"', ''),
    ('vex_res SG7_RGB "200 60 60"', ''),
    ('vex_hpbar_width 34', 'kafa ustu can bari genisligi (birim)'),
    ('vex_bossbar_width 90', 'boss can bari genisligi (birim)'),
    ('vex_head_icon_size 16', 'kafa ustu ikon boyutu'),
]
S535_ABIL = {'BURST': 'roar', 'LEAP': 'whoosh', 'SHIELD': 'shield', 'DRAIN': 'heal', 'CLOAK': 'whoosh', 'TOXIC': 'acid', 'FROST': 'ice'}
# 5.3.2 ambience: 8 looping beds (sound/vexmira/amb532) shared by every round type
_BED = ['calm', 'tension', 'hunt', 'hope', 'storm', 'frost', 'boss', 'chaos']
_MODE_N = ['Enfeksiyon', 'Coklu', 'Nemesis', 'Assassin', 'Survivor', 'Sniper', 'Swarm', 'Plague', 'Armageddon', 'Boss']
_EV_N = ['Normal', 'Kan Ayi', 'Yogun Sis', 'Hiz', 'Dusuk Yercekimi', 'Cift Hasar', 'Karanlik Gece', 'Salgin',
         'Malzeme', 'Delilik', 'Adrenalin', 'Meteor', 'Zombi Surusu', 'Titan', 'Altin', 'Vampir Gecesi',
         'Kafa Avi', 'Firtina', 'Elektrik Kesintisi']
for _j, _b in enumerate([0, 1, 2, 2, 3, 3, 1, 1, 7, 6]):
    OVERRIDE.append(('vex_res AMBIENT_MODE%d "sound/vexmira/s534/amb_%s.wav"' % (_j, _BED[_b]),
                     'ambiyans: %s roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; "" = sessiz)' % _MODE_N[_j]))
for _j, _b in enumerate([0, 4, 5, 1, 3, 1, 5, 1, 0, 7, 1, 7, 7, 7, 3, 5, 2, 4, 5]):
    OVERRIDE.append(('vex_res AMBIENT_EVENT%d "sound/vexmira/s534/amb_%s.wav"' % (_j, _BED[_b]), 'ambiyans: %s eventi' % _EV_N[_j]))
for _j in range(9):
    OVERRIDE.append(('vex_res AMBIENT_BOSS%d "sound/vexmira/s534/amb_boss.wav"' % _j, 'ambiyans: boss %d roundu' % _j))
for _k, _d in (('BURST', 'patlama'), ('LEAP', 'sicrama'), ('SHIELD', 'kemik kalkan'), ('DRAIN', 'can emme'),
               ('CLOAK', 'gorunmezlik'), ('TOXIC', 'zehir puskurtme'), ('FROST', 'buz patlamasi')):
    OVERRIDE.append(('vex_res ABILITY_%s "vexmira/s534/%s.wav"' % (_k, S535_ABIL[_k]),
                     'zombi yetenegi sesi: %s (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)' % _d))
OVERRIDE += [
    ('vex_ambience_volume 0.55', 'ambiyans muzik/ses seviyesi (0.05 - 1.0)'),
    ('vex_ambience_restart 120', 'ambiyans kac saniyede bir tazelenir (parcalar zaten kendi kendine doner; baglanan / sesi kesilen oyuncu icin)'),
]
# 5.3.5 sound set (devtools/sfx534/build534.py): royalty-free music + CC0 effects, shared between similar events;
# stock CS 1.6 sounds where one fits (no download at all). Radio, special knives / weapons, boss voices untouched.
S5 = lambda n: 'vexmira/s534/%s.wav' % n
S535 = {
 'ROUND_START': S5('round_start'), 'MODE_START': S5('mode_start'), 'EVENT_START': S5('event_start'), 'WELCOME': S5('bell'),
 'MAP_END': S5('bell'), 'COUNTDOWN_BEEP': S5('tick'), 'LAST_HUMAN': S5('last_human'), 'FINAL_ROUND': S5('final_round'),
 'HUMAN_WIN': S5('human_win'), 'ZOMBIE_WIN': S5('zombie_win'), 'BOSS_WARN': S5('boss_warn'), 'BOSS_SOON': S5('boss_warn'),
 'UI_BOSS_BAR': S5('boss_warn'), 'NEMESIS_INTRO': S5('mode_start'), 'ASSASSIN_INTRO': S5('mode_start'), 'NEM_RAGE': S5('roar'),
 'LIGHTNING': S5('thunder'), 'THUNDER': S5('thunder'), 'STORM_STRIKE': S5('thunder'), 'ZOMBIE_SHOCK': S5('zap'), 'VOLT_ZAP': S5('zap'),
 'ZAP': S5('zap'), 'METEOR': S5('fire'), 'BURN': S5('fire'), 'NADE_FIRE': S5('fire'), 'NADE_FROST': S5('ice'), 'FROST_NOVA': S5('ice'),
 'FREEZE': S5('ice'), 'BLACKOUT': S5('dark'), 'ECLIPSE': S5('dark'), 'SPEED_START': S5('speed'),
 'KILL_MULTI': S5('kill'), 'KILL_MEGA': S5('kill'), 'KILL_MONSTER': S5('kill'), 'MVP': S5('mvp'), 'QUEST_DONE': S5('reward'),
 'LEVEL_UP': S5('reward'), 'ACH_UNLOCK': S5('reward'), 'SKILL_UNLOCK': S5('reward'), 'SHOP_BUY': S5('coin'), 'DAILY': S5('coin'),
 'UI_OPEN': S5('click'), 'UI_MENU_SELECT': S5('click'), 'UI_CLASS_SELECT': S5('click'), 'UI_VOTE_START': S5('vote'), 'UI_VOTE_END': S5('vote'),
 'AIRDROP_INCOMING': S5('event_start'), 'AIRDROP_LAND': S5('impact'), 'AIRDROP_LOOT': S5('coin'),
 'NADE_MODE': 'items/nvg_on.wav', 'NADE_BEEP': 'weapons/c4_beep1.wav', 'NADE_ARM': 'weapons/c4_beep2.wav',
 'LM_DEPLOY': 'weapons/c4_plant.wav', 'LM_PICKUP': 'items/gunpickup2.wav', 'LM_CHARGE': S5('beep'), 'LM_ACTIVATE': S5('beep'),
 'LM_HIT': S5('zap'), 'LM_BREAK': S5('boom'), 'LM_DENY': S5('deny'),
 'EVOLVE': S5('roar2'), 'ANTIDOTE': S5('heal'), 'ZOMBIE_ACID': S5('acid'), 'ZOMBIE_HEAL': S5('heal'), 'ZOMBIE_BLINK': S5('whoosh'),
 'HUNTER_IMPACT': S5('impact'), 'CHARGER_IMPACT': S5('impact'), 'ARACHNE_WEBHIT': S5('acid'), 'BURROWER_ERUPT': S5('impact'),
 'SPOREMOTHER_BURST': S5('acid'), 'MIMIC_REVEAL': S5('dark'), 'HOOK_THROW': S5('whoosh'), 'HOOK_CHAIN': S5('chain'),
 'HOOK_HIT': S5('impact'), 'HOOK_PULL': S5('chain'), 'HOOK_MISS': S5('whoosh'), 'ABILITY_SCREAM': S5('roar2'),
}
S535_CLASS = ['roar', 'speed', 'impact', 'roar2', 'heal', 'whoosh', 'boom', 'ice', 'acid', 'impact', 'dark', 'whoosh', 'roar', 'whoosh',
              'impact', 'acid', 'fire', 'zap', 'dark', 'impact', 'roar2', 'shield', 'acid', 'dark']
S535_ITEM = {'power': 'power', 'heal': 'heal', 'armor': 'shield', 'madness': 'roar', 'rage': 'roar2', 'cloak': 'whoosh', 'jump': 'whoosh',
             'speed': 'speed', 'shield': 'shield', 'regen': 'heal', 'antidote': 'heal', 'serum': 'acid'}
for _k, _v in S535.items():
    OVERRIDE.append(('vex_res %s "%s"' % (_k, _v), ''))
for _j, _n in enumerate(S535_CLASS):
    OVERRIDE.append(('vex_res Z%d_ABILITY "%s"' % (_j, S5(_n)), ''))
for _k, _n in S535_ITEM.items():
    OVERRIDE.append(('vex_res ITEM_SND_%s "%s"' % (_k, S5(_n)), 'market esyasi sesi: %s' % _k))
OVERRIDE.append(('vex_res ITEM_SND_ammo "items/9mmclip1.wav"', 'market esyasi sesi: mermi (CS 1.6 kendi sesi, indirme yok)'))
# keys whose old value must go (meme sounds on zombies, per-class overrides that hid the pools)
DROP_VALUE_RE = [re.compile(r'^vex_res Z\d+_(DIE|PAIN)$'), re.compile(r'^vex_res SW4_')]
DROP_KEYS = {('vex_restore', 'LASERMINE_MODEL'), ('vex_res', 'SOUND_BLOCK_STOCK'), ('vex_res', 'SOUND_BLOCK_EXTRA')}
DROP_CMDS = {'vex_hat', 'vex_cos_smooth'}     # 5.3.3: hats removed

SECTIONS = [
    ('GENEL', 'Sunucu adi, sohbet etiketleri, temel ayarlar',
     r'^(vex_hostname|vex_chat_prefix|mp_|sv_|mapcyclefile|vex_motd|vex_lang|vex_start_|vex_welcome|vex_chat|vex_ui|vex_skill_alt)'),
    ('ROUND VE MODLAR', 'Round sayisi, boss / ozel round sirasi, mod olasiliklari (vex_mode_rule <mod> <sans%> <min oyuncu>)',
     r'^(vex_rounds|vex_boss_rounds|vex_special_rounds|vex_boss_every|vex_multi|vex_event_chance|vex_countdown|vex_zombie_respawn|vex_mode_rule|vex_round|vex_first|vex_last|vex_final)'),
    ('HARITA VE OYLAMA', 'Harita havuzu, oylama, RTV, harita hikayesi',
     r'^(vex_map|vex_vote|vex_rtv)'),
    ('CAN / HASAR / DENGE', 'Zombi ve insan canlari, hasarlar, geri tepme',
     r'^(vex_.*_hp|vex_.*hp_per|vex_.*damage|vex_.*_dmg|vex_knockback|vex_armor|vex_nemesis|vex_assassin|vex_survivor|vex_sniper|vex_minion|vex_zombie|vex_human|vex_speed|vex_special)'),
    ('OZEL SILAHLAR VE MERMI', 'vex_sw <no> <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme> | vex_gun p/s <no> <seviye> <mermi> | vex_modewpn survivor/sniper <yuva> <silah> <hasar> <sarjor> <yedek> <efekt>',
     r'^(vex_sw|vex_gun|vex_modewpn|vex_unlimited|vex_arsenal)'),
    ('MARKET ESYALARI', 'vex_item <no> <AP fiyat> <round limiti> <seviye> <deger>  (deger: can / sure / miktar)',
     r'^(vex_item|vex_shop|vex_exchange|vex_buy)'),
    ('SINIFLAR VE MESLEKLER', 'vex_class <no> <can carpani> <hiz> <yercekimi> <geri tepme> <yetenek bekleme> <seviye> | vex_job <no> <seviye>',
     r'^(vex_class|vex_job|vex_zc_|vex_ability|vex_volt|vex_siren|vex_sporemother|vex_.*mother|vex_hunter|vex_charger|vex_arachne|vex_burrow|vex_mimic|vex_magma)'),
    ('BOSSLAR', 'vex_boss_stat <boss> <can carpani> <hiz> <yercekimi> <R G B> | vex_boss_skill <boss> <faz 1-3> <bekleme sn> <hasar> <yaricap>',
     r'^(vex_boss)'),
    ('EVENTLER, ISIK VE HAVA', 'vex_env_event/mode/boss/calm <no> <isik a-z> <sis R> <G> <B> <yogunluk> <hava 0 yok 1 yagmur 2 kar>',
     r'^(vex_env|vex_weather|vex_blackout|vex_event|vex_storm|vex_meteor|vex_airdrop|vex_speedrush)'),
    ('BOMBALAR', 'Ates / buz / isik / enfeksiyon bombalari ve bomba modlari',
     r'^(vex_nade)'),
    ('LAZER MAYIN', 'Lazer mayin hasari, sayisi, menzili, isin stilleri',
     r'^(vex_lm_|vex_laser)'),
    ('KOZMETIK VE VEXCOIN', 'vex_wing/pet/hat <no> "EN ad" "TR ad" <model> <VC> <vip> <bone/head/back/follow> <x y z> <aci p y r> <olcek> <anim> <hiz> | vex_cosmetic <kat> <no> <VC>',
     r'^(vex_cos|vex_wing|vex_pet|vex_hat|vex_vc|vex_coin)'),
    ('VIP', 'VIP / ELITE ayricaliklari', r'^(vex_vip)'),
    ('HUD / CSO EKRAN / ARAYUZ', 'Ust skor paneli, CSO kartlari, can barlari, simgeler',
     r'^(vex_hud|vex_topboard|vex_cso|vex_overhead|vex_bossbar|vex_hpbar|vex_head_icon|vex_radio|vex_banner|vex_tip)'),
    ('SES VE MUZIK', 'Ses dongu korumasi, meme sesleri, radyo',
     r'^(vex_sound|vex_ambience|vex_meme|vex_six|vex_music|vex_round_stopsound)'),
    ('GOREV / ODUL / SEVIYE', 'vex_quest <no> <hedef> <XP> <AP> | kazanma odulleri',
     r'^(vex_quest|vex_win_|vex_daily|vex_ach|vex_xp|vex_level|vex_perk|vex_kill|vex_reward)'),
]
RES_SECTIONS = [
    ('KAYNAK: GOKYUZU / ATMOSFER', r'^(SKY_|AMBIENT|FOG|WEATHER)'),
    ('KAYNAK: ZOMBI SESLERI VE MODELLERI', r'^(Z\d+_|ZOMBIE_|CLAW|ABILITY_)'),
    ('KAYNAK: BOSSLAR', r'^(B\d+_|BOSS_)'),
    ('KAYNAK: OYUNCU MODELLERI', r'^(HUMAN|VIP_MODEL|ADMIN_MODEL|SURVIVOR|SNIPER|NEMESIS|ASSASSIN|MODEL)'),
    ('KAYNAK: SILAH MODELLERI', r'^(V_|P_|W_|SW\d|VX)'),
    ('KAYNAK: BOMBALAR VE LAZER MAYIN', r'^(NADE_|LASERMINE|LM_)'),
    ('KAYNAK: SPRITE / EFEKT', r'^(SPR_|FX_)'),
    ('KAYNAK: BUTCE / DIGER', r'.'),
]


def tokens(line):
    try:
        return shlex.split(line, posix=True)
    except ValueError:
        return line.split()


def key_of(code):
    t = tokens(code)
    if not t:
        return None
    n = INDEXED.get(t[0], 0)
    return tuple(t[:1 + n])


def split_comment(raw):
    q = False
    for i, ch in enumerate(raw):
        if ch == '"':
            q = not q
        elif not q and raw.startswith('//', i):
            return raw[:i].rstrip(), raw[i + 2:].strip()
    return raw.rstrip(), ''


def parse(path):
    out = []
    pending = []
    for raw in open(path, encoding='latin-1').read().splitlines():
        s = raw.strip()
        if not s:
            pending = []
            continue
        if s.startswith('//') or s.startswith(';') or s.startswith('#'):
            pending.append(s.lstrip('/;# ').strip())
            continue
        code, com = split_comment(s)
        k = key_of(code)
        if not k:
            continue
        out.append({'key': k, 'code': code, 'comment': com, 'lead': [p for p in pending if p]})
        pending = []
    return out


BOSS_TR = ['BRUTE', 'BANSHEE', 'OVERLORD', 'INFERNO', 'REAPER', 'FROSTLORD', 'STORMCALLER', 'HIVE QUEEN', 'VOID']
CLASS_TR = ['Walker', 'Runner', 'Tank', 'Banshee', 'Leech', 'Stalker', 'Bomber', 'Frost', 'Spitter', 'Hulk', 'Voodoo',
            'Phantom', 'Kasap', 'Avci', 'Boga', 'Orumcek', 'Magma', 'Volt', 'Taklitci', 'Kostebek', 'Siren', 'Kale',
            'Spor Ana', 'Kabus']
MODE_TR = ['Enfeksiyon', 'Coklu Enfeksiyon', 'Nemesis', 'Assassin', 'Survivor', 'Sniper', 'Swarm', 'Plague', 'Armageddon', 'Boss']
SW_TR = ['Arbalest', 'Heaven Splitter', 'Quantum Horizon', 'Magnum Drill Chimera', 'Dark Knight', 'Infinity Laser Fist',
         'Void Avenger', 'Dual Beretta Gunslinger']
BOSS_WHAT = {'INTRO': 'giris sesi (boss dogunca)', 'IDLE': 'bekleme / nefes sesi', 'PAIN': 'hasar alma sesi',
             'PAIN2': 'hasar alma sesi 2', 'DEATH': 'olum sesi', 'STEP': 'adim / yurume sesi', 'ATTACK': 'pence saldiri sesi',
             'PHASE': 'faz gecis (ofkelenme) sesi', 'KILL': 'oyuncu oldurunce cikan ses', 'R1': '1. yetenek sesi',
             'R2': '2. yetenek sesi', 'R3': '3. yetenek sesi', 'MODEL': 'oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD yazilir)',
             'CLAW': 'el / pence modeli (v_ modeli)'}
ZC_WHAT = {'MODEL': 'oyuncu modeli (models/player/<AD>/<AD>.mdl -> sadece AD)', 'IDLE': 'bekleme / homurtu sesi',
           'CLAW': 'el / pence modeli', 'ABILITY': 'yetenek (R) sesi', 'PAIN': 'hasar sesi', 'DIE': 'olum sesi'}
WPN_WHAT = {'V': 'el (gorus) modeli', 'P': 'oyuncunun elindeki model (baskalari gorur)', 'W': 'yere dusen model'}


def auto_comment(key, value):
    """Turkish explanation for a vex_res line that has none."""
    m = re.match(r'^B(\d)_([A-Z0-9]+)$', key)
    if m and int(m.group(1)) < len(BOSS_TR):
        return 'BOSS %s (%s): %s' % (m.group(1), BOSS_TR[int(m.group(1))], BOSS_WHAT.get(m.group(2), m.group(2).lower()))
    m = re.match(r'^Z(\d+)_([A-Z0-9]+)$', key)
    if m and int(m.group(1)) < len(CLASS_TR):
        return 'ZOMBI SINIFI %s (%s): %s' % (m.group(1), CLASS_TR[int(m.group(1))], ZC_WHAT.get(m.group(2), m.group(2).lower()))
    m = re.match(r'^MODE(\d)_MUSIC$', key)
    if m:
        return '%s roundu muzigi (.wav ya da .mp3)' % MODE_TR[int(m.group(1))]
    m = re.match(r'^SW(\d)_([A-Z]+)$', key)
    if m:
        what = {'VMODEL': 'el modeli', 'PMODEL': 'oyuncu ustu model', 'WMODEL': 'yerdeki model', 'FIRE': 'ates sesi'}.get(m.group(2), m.group(2).lower())
        return 'OZEL SILAH %s (%s): %s' % (m.group(1), SW_TR[int(m.group(1))], what)
    m = re.match(r'^([VPW])_([A-Z0-9]+)$', key)
    if m:
        return '%s silahi: %s' % (m.group(2).lower(), WPN_WHAT[m.group(1)])
    m = re.match(r'^(SURVIVOR|SNIPER)_W(\d)_([A-Z]+)$', key)
    if m:
        return '%s silahi %s: %s' % (m.group(1).capitalize(), m.group(2), {'VMODEL': 'el modeli', 'PMODEL': 'oyuncu ustu model', 'SOUND': 'ates sesi'}.get(m.group(3), ''))
    m = re.match(r'^STREAK_(\d)$', key)
    if m:
        return 'seri oldurme sesi (%s. seviye)' % m.group(1)
    v = value.lower()
    known = {'MODEL_BUDGET': 'eklentinin yukleyebilecegi en fazla model/sprite sayisi (512 sinirina karsi koruma)',
             'SOUND_BUDGET': 'eklentinin yukleyebilecegi en fazla 3D ses sayisi (512 sinirina karsi koruma)',
             'HUMAN_MODELS': 'insan oyuncu modelleri (birden fazla: bosluk ile; models/player/AD/AD.mdl -> AD)',
             'ADMIN_MODEL': 'admin oyuncu modeli', 'VIP_MODEL': 'VIP oyuncu modeli', 'SURVIVOR_MODEL': 'Survivor modeli',
             'SNIPER_MODEL': 'Sniper modeli', 'NEMESIS_MODEL': 'Nemesis modeli', 'ASSASSIN_MODEL': 'Assassin modeli',
             'VOX_COUNTDOWN': 'geri sayim anonsu: 0 kapali, 1 sayilar, 2 sayilar + efekt',
             'LASERMINE_BODY': 'mayin model govde no', 'LASERMINE_SKIN': 'mayin model skin no',
             'LASERMINE_ANGLES': 'mayin model aci duzeltmesi (pitch yaw roll)', 'LASERMINE_OFFSET': 'mayinin duvardan uzakligi (birim)'}
    if key in known:
        return known[key]
    if key.startswith('VOX_'):
        return 'anons (vox) sesi: ' + key[4:].lower()
    if key.endswith('_MODEL') or key.endswith('MODELS'):
        return 'model: ' + key.lower().replace('_', ' ') + ' (bos = varsayilan)'
    if not value.strip('"'):
        return key.lower().replace('_', ' ') + ' (bos = varsayilan ses / kapali; kendi dosyani yazabilirsin)'
    if '.wav' in v or '.mp3' in v:
        return 'ses: ' + key.lower().replace('_', ' ') + ' (degistirmek icin kendi dosya yolunu yaz; "" = sessiz)'
    if '.mdl' in v:
        return 'model: ' + key.lower().replace('_', ' ')
    if '.spr' in v:
        return 'sprite / efekt: ' + key.lower().replace('_', ' ')
    return ''


EV_TR = ['Normal', 'Kan Ayi', 'Yogun Sis', 'Hiz Tutkusu', 'Dusuk Yercekimi', 'Cift Hasar', 'Karanlik Gece', 'Salgin',
         'Malzeme Dususu', 'Delilik', 'Adrenalin', 'Meteor Yagmuru', 'Zombi Surusu', 'Titan Saati', 'Altin Hucumu',
         'Vampir Gecesi', 'Kafa Avi', 'Firtina', 'Elektrik Kesintisi']
CVAR_TR = {
    'mp_maxrounds': 'harita kac round surer', 'mp_roundover': 'round bitince bekleme davranisi (ReGameDLL)',
    'mp_autoteambalance': 'otomatik takim dengeleme (zombi modunda 0)', 'mp_limitteams': 'takim farki siniri (0 = yok)',
    'mp_buytime': 'CS satin alma suresi (0 = kapali, market eklentide)', 'mp_buy_anywhere': 'her yerde CS market (0 = kapali)',
    'mp_maxmoney': 'en fazla para', 'mp_t_default_weapons_secondary': 'T baslangic tabancasi ("" = yok)',
    'mp_ct_default_weapons_secondary': 'CT baslangic tabancasi', 'mp_t_default_weapons_primary': 'T baslangic silahi',
    'mp_ct_default_weapons_primary': 'CT baslangic silahi', 'mp_t_give_player_knife': 'T bicak verilir', 'mp_ct_give_player_knife': 'CT bicak verilir',
    'mp_free_armor': 'bedava zirh', 'mp_weapons_allow_map_placed': 'haritadaki silahlar alinabilir', 'mp_nadedrops': 'olunce bomba dusurme',
    'mp_weapondrop': 'olunce silah dusurme', 'mp_item_staytime': 'yerdeki esya kac sn kalir', 'mp_falldamage': 'dusme hasari',
    'mp_respawn_immunitytime': 'dogunca dokunulmazlik sn', 'mp_kill_filled_spawn': 'dolu dogma noktasinda oldurme',
    'mp_show_scenarioicon': 'senaryo ikonu', 'mp_scoreboard_showmoney': 'skor tablosunda para gorunumu', 'mp_knockback': 'CS geri tepmesi (eklentininki ayri)',
    'mp_freezetime': 'round basi donma suresi (sn)', 'mp_roundtime': 'round suresi (dakika)', 'mp_friendlyfire': 'takim hasari',
    'mp_footsteps': 'ayak sesleri', 'mp_tkpunish': 'takim oldurme cezasi', 'sv_alltalk': '1 = herkes birbirini duyar',
    'sv_allowupload': 'oyuncu spray yukleme', 'sv_auto_precache_sounds_in_models': 'modellerdeki sesleri otomatik yukle (0 = ses limiti icin kapali)',
    'vex_ui52': 'ekran duyurulari (mod / event baslangic yazilari)', 'vex_rounds_total': 'toplam round (harita oylamasi icin)',
    'vex_boss_rounds': 'hangi roundlar BOSS roundu (bosluk ile)', 'vex_event_chance': 'event cikma sansi (%)',
    'vex_vote_every': 'kac roundda bir mod oylamasi', 'vex_map_pool': 'oylamadaki haritalar', 'vex_map_vote_round': 'harita oylamasi hangi roundda',
    'vex_map_vote_time': 'harita oylama suresi (sn)', 'vex_map_vote_extend': '1 = "haritayi uzat" secenegi', 'vex_map_ambience': 'harita ortam sesi seviyesi / sikligi',
    'vex_survivor_hp': 'Survivor cani', 'vex_sniper_hp': 'Sniper cani', 'vex_nemesis_speed': 'Nemesis hizi', 'vex_assassin_speed': 'Assassin hizi',
    'vex_nemesis_gravity': 'Nemesis yercekimi (1 = normal)', 'vex_assassin_gravity': 'Assassin yercekimi',
    'vex_nemesis_rage_cooldown': 'Nemesis ofke yetenegi bekleme (sn)', 'vex_assassin_veil_cooldown': 'Assassin gorunmezlik bekleme (sn)',
    'vex_boss_hp': 'boss temel cani', 'vex_boss_hp_per_player': 'her oyuncu basina boss can artisi', 'vex_special_kill_ap': 'ozel zombi oldurme odulu (AP)',
    'vex_nade_cluster_damage': 'misket bombasi parca hasari', 'vex_boss_kill_ap': 'boss oldurme odulu (AP)', 'vex_boss_kill_vc': 'boss oldurme odulu (VexCoin)',
    'vex_bossbar_width': 'boss can bari genisligi', 'vex_airdrop': '1 = ikmal kutusu dususu acik', 'vex_env_calm_random': 'sakin roundlarda rastgele isik/hava',
    'vex_weather': 'hava durumu (0 kapali, 1 yagmur, 2 kar)', 'vex_nade_fire_radius': 'ates bombasi yaricapi', 'vex_nade_frost_radius': 'buz bombasi yaricapi',
    'vex_lm_enable': '1 = lazer mayin acik', 'vex_lm_per_round': 'oyuncu basina round basi mayin', 'vex_lm_per_round_vip': 'VIP round basi mayin',
    'vex_lm_max': 'ayni anda en fazla mayin', 'vex_lm_max_vip': 'VIP ayni anda en fazla mayin', 'vex_lm_block_modes': 'lazer mayinin YASAK oldugu modlar',
    'vex_vip_contact': 'VIP almak icin iletisim (menude gorunur)', 'vex_vip_bonus': 'VIP ekstra odul %', 'vex_vip_armor': 'VIP round basi zirh',
    'vex_vip_autopack': 'VIP otomatik paket', 'vex_vip_spawnprot': 'VIP dogma korumasi (sn)', 'vex_vip_vote_weight': 'VIP oy agirligi',
    'vex_vip_join_announce': 'VIP girince duyuru', 'vex_hud_style': 'HUD stili', 'vex_hud_mvp': 'MVP bilgisi HUD da', 'vex_hud_overhead': 'kafa ustu bilgi stili',
    'vex_cso_style': '1 = CSO resimli kart sistemi acik (0 = kapali)', 'vex_cso_time': 'kart ekranda kalma suresi (sn)', 'vex_cso_sound': 'kart sesi',
    'vex_cso_icons': 'sag tarafta rol ikonu', 'vex_overhead': 'kafa ustu can bari / ikon', 'vex_overhead_margin': 'kafa ustu ikon yuksekligi', 'vex_head_icon_size': 'kafa ustu ikon boyutu',
    'vex_radio52': '1 = ozel telsiz sesleri acik', 'vex_radio52_interval': 'rastgele telsiz konusmasi araligi (sn)', 'vex_six_tracer_every': 'iz mermisi sikligi',
    'vex_meme_cooldown': 'meme sesi bekleme (sn)', 'vex_win_human_ap': 'insanlar kazaninca AP', 'vex_win_zombie_ap': 'zombiler kazaninca AP',
    'vex_achievement_vc': 'basarim odulu (VC)', 'vex_infect_xp': 'enfekte etme XP', 'vex_mvp_vc': 'MVP odulu (VC)', 'vex_debug_dirs': 'gelistirici testi (0 birak)',
    'vex_elite_bonus': 'ELITE ekstra odul %', 'vex_elite_armor': 'ELITE zirh', 'amx_language': 'varsayilan dil (en / tr)', 'amx_client_languages': 'oyuncu kendi dilini secebilir',
    'vex_connection_log': 'baglanma / ayrilma kaydi', 'vex_start_ap': 'yeni oyuncu baslangic AP', 'vex_motd': 'giriste bilgi penceresi',
    'vex_chat_tip_interval': 'sohbet ipucu araligi (sn)', 'vex_modewpn': 'Survivor / Sniper silahi: <mod> <yuva> <silah> <hasar> <sarjor> <yedek> <efekt>',
}


def cvar_comment(key):
    cmd = key[0]
    if cmd == 'vex_sw' and len(key) > 1:
        return 'OZEL SILAH %s (%s): <AP> <seviye> <hasar carpani> <yedek mermi> <efekt> <R G B> <sarjor> <zincir> <atis hizi> <geri tepme>' % (key[1], SW_TR[int(key[1])])
    if cmd == 'vex_sw_text' and len(key) > 2:
        return 'OZEL SILAH %s yazisi (%s): ad + aciklama' % (key[1], key[2])
    if cmd in ('vex_env_event', 'vex_env_mode', 'vex_env_boss', 'vex_env_calm') and len(key) > 1:
        n = int(key[1])
        who = {'vex_env_event': 'EVENT %d (%s)' % (n, EV_TR[n] if n < len(EV_TR) else n),
               'vex_env_mode': 'MOD %d (%s)' % (n, MODE_TR[n] if n < len(MODE_TR) else n),
               'vex_env_boss': 'BOSS %d (%s)' % (n, BOSS_TR[n] if n < len(BOSS_TR) else n),
               'vex_env_calm': 'sakin tur %d' % n}[cmd]
        return '%s: <isik a-z (a karanlik, m normal)> <sis R G B> <sis yogunluk> <hava 0/1 yagmur/2 kar>' % who
    if cmd == 'vex_wing':
        return 'KANAT %s: "EN ad" "TR ad" <model> <VC fiyat> <vip 0/1> <bone> <x y z> <aci p y r> <olcek> <animasyon> <hiz>' % key[1]
    if cmd == 'vex_pet':
        return 'PET %s: "EN ad" "TR ad" <model> <VC fiyat> <vip 0/1> <follow> <x y z> <aci> <olcek> <anim> <hiz>' % key[1]
    return CVAR_TR.get(cmd, '')


def main():
    SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src')
    base = parse(os.path.join(SRC, 'vexmira_530.cfg'))
    epic_path = os.path.join(SRC, 'vexmira_epic_530.cfg')
    epic = parse(epic_path) if os.path.exists(epic_path) else []
    order, table = [], {}
    for e in base + epic:                       # later wins (epic loaded after base)
        k = e['key']
        if k in table:
            old = table[k]
            if not e['comment']:
                e['comment'] = old['comment']
            if not e['lead']:
                e['lead'] = old['lead']
        else:
            order.append(k)
        table[k] = e
    for line, com in OVERRIDE:
        k = key_of(line)
        if k not in table:
            order.append(k)
            table[k] = {'key': k, 'code': line, 'comment': com, 'lead': []}
        else:
            table[k]['code'] = line
            if com:
                table[k]['comment'] = com
    for k in order:
        e = table[k]
        if k[0] == 'vex_res' and len(k) > 1 and not e['comment']:
            val = e['code'].split(None, 2)[2] if len(e['code'].split(None, 2)) > 2 else ''
            e['comment'] = auto_comment(k[1], val)
        elif not e['comment']:
            e['comment'] = cvar_comment(k)
    for k in list(order):
        if k in DROP_KEYS or k[0] in DROP_CMDS or (k[0] == 'vex_res' and len(k) > 1 and any(r.match('vex_res ' + k[1]) for r in DROP_VALUE_RE)):
            order.remove(k)
            table.pop(k, None)
    # sectioning
    sec = {name: [] for name, _, _ in SECTIONS}
    sec['DIGER'] = []
    res = {name: [] for name, _ in RES_SECTIONS}
    restore = []
    for k in order:
        e = table[k]
        if k[0] == 'vex_res':
            for name, rx in RES_SECTIONS:
                if re.match(rx, k[1] if len(k) > 1 else ''):
                    res[name].append(e)
                    break
            continue
        if k[0] == 'vex_restore':
            restore.append(e)
            continue
        for name, _, rx in SECTIONS:
            if re.match(rx, k[0]):
                sec[name].append(e)
                break
        else:
            sec['DIGER'].append(e)
    W = 78
    out = []

    def hdr(title, desc=''):
        out.append('')
        out.append('// ' + '=' * W)
        out.append('// ' + title)
        if desc:
            for chunk in re.findall(r'.{1,%d}(?:\s|$)' % (W - 2), desc):
                out.append('//   ' + chunk.strip())
        out.append('// ' + '=' * W)

    def emit(e):
        pass                                    # 5.3.3: old (English) note lines dropped, sections explain
        code = e['code']
        out.append(('%-60s // %s' % (code, e['comment'])) if e['comment'] else code)

    out += [
        '// VEXMIRA ZOMBIE 5.3.3 - TEK AYAR DOSYASI (vexmira_core + vexmira_gear)',
        '// ' + '-' * W,
        '// NASIL DEGISTIRILIR:',
        '//  * Her satir:   ayar_adi  deger      // aciklama    ("//" sonrasi okunmaz, kendi notunu yazabilirsin)',
        '//  * Kaydet; oyunda "amx_rcon vex_reload" ya da harita degisimiyle gecerli olur.',
        '//  * vex_res ... satirlari (model / ses / sprite / gokyuzu / ambiyans) SADECE harita degisiminde yuklenir.',
        '//  * SES YOLU:   "sound/" ile ya da onsuz yazabilirsin, ikisi de olur:  "vexmira/x.wav" = "sound/vexmira/x.wav"',
        '//      wav dosyasi MONO olmali (8 ya da 16 bit, 11025 / 22050 Hz). Stereo / 44 kHz wav CS 1.6 da CALMAZ.',
        '//      Muzik / ambiyans icin .mp3 de kullanabilirsin.',
        '//  * Birden fazla ses:  "a.wav|b.wav|c.wav"  -> her seferinde rastgele biri.',
        '//  * MODEL YOLU: "models/klasor/dosya.mdl"; oyuncu modellerinde sadece klasor adi (models/player/AD/AD.mdl -> "AD").',
        '//  * "" (bos) = o ses / model kapali ya da varsayilan.',
        '//  * Dosya sunucuda yoksa eklenti onu ATLAR (cokmez). Hangi dosyalarin eksik oldugunu gormek icin',
        '//    sunucu konsoluna (ya da admin olarak oyunda) yaz:  vex_kontrol',
        '// ORNEKLER:',
        '//    Nemesis roundu ambiyansi    ->  vex_res AMBIENT_MODE2 "sound/benim/nemesis_amb.wav"',
        '//    Boss 0 (Brute) giris sesi    ->  vex_res B0_INTRO "benim/brute_giris.wav"',
        '//    Zombi pencesi sesleri        ->  vex_res ZOMBIE_HIT "zombie/claw1.wav|zombie/claw2.wav"',
        '//    Kanat modeli                 ->  vex_wing 1 "Ad" "Ad TR" models/benim/kanat.mdl 250 0 bone -3 0 -2 0 0 0 1 1 1.0',
        '//    Market esyasi sesi           ->  vex_res ITEM_SND_madness "benim/cinnet.wav"',
        '//  * vexmira_epic.cfg ARTIK KULLANILMAZ: tum ayarlar bu dosyada.',
        '// ' + '-' * W,
    ]
    for name, desc, _ in SECTIONS:
        if sec[name]:
            hdr(name, desc)
            for e in sec[name]:
                emit(e)
    if sec['DIGER']:
        hdr('DIGER AYARLAR', 'Yukaridaki gruplara girmeyen ayarlar')
        for e in sec['DIGER']:
            emit(e)
    hdr('KAYNAKLAR (vex_res)', 'Model / ses / sprite yollari. Degisiklik harita degisiminde gecerli olur. '
        'Bos deger "" = varsayilan / kapali.')
    for name, _ in RES_SECTIONS:
        if res[name]:
            out.append('')
            out.append('// ---- ' + name + ' ' + '-' * max(4, W - 7 - len(name)))
            for e in res[name]:
                emit(e)
    if restore:
        hdr('ORIJINAL KAYNAKLAR (vex_restore)', 'Dosya sunucuda varsa kullanilir, yoksa yeni yedek korunur')
        for e in restore:
            emit(e)
    text = '\n'.join(out).strip('\n') + '\n'
    open(os.path.join(CFG, 'vexmira.cfg'), 'w', encoding='latin-1').write(text)
    print('vexmira.cfg: %d keys, %d lines' % (len(order), text.count('\n')))
    embed(text)


def pawn_str(line):
    return '"' + line.replace('^', '^^').replace('"', '^"') + '"'


def embed(cfg_text):
    s = open(GEAR, encoding='latin-1').read()

    def repl(name, lines):
        nonlocal s
        a = s.index('new const %s[][] = {' % name)
        b = s.index('\n};', a)
        body = ',\n'.join(pawn_str(l) for l in lines)
        s = s[:a] + 'new const %s[][] = {\n%s' % (name, body) + s[b:]
    repl('ZC_F_CFG', cfg_text.rstrip('\n').split('\n'))
    repl('ZC_F_EPIC_CFG', ['// Vexmira 5.3.1: bu dosya artik kullanilmaz - tum ayarlar vexmira.cfg icinde'])
    lang = open(os.path.join(REPO, 'cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt'), encoding='latin-1').read()
    repl('ZC_F_LANG', lang.rstrip('\n').split('\n'))
    open(GEAR, 'w', encoding='latin-1').write(s)
    print('embedded cfg + lang into vexmira_gear.sma')


if __name__ == '__main__':
    main()
