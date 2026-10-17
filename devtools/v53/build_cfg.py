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
    ('vex_hostname "VEXMIRA ZOMBIE PLAGUE | 9 BOSS | 18 EVENT | CSO SILAH | LAZER"', 'sunucu adi (oyun listesinde gorunen, en fazla 63 harf). Oneriler: "VEXMIRA ZOMBIE [TR] 9 BOSS | CSO SILAH | LAZER | JETPACK | LVL" / "VEXMIRA ZP | DEV BOSS + HELIKOPTER HARITA | CSO | 7/24"'),
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
    ('vex_res CSO_CARDSET "c532"', 'ekran kartlari: c532 = 5.3.2 buyuk resimli kartlar (onerilen, 10 indirme), vexmira = eski animasyonlu set (~120 indirme!), off = sadece yazi kart'),
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
    ('vex_res BOSS_GIANT_TEX "256"', 'dev boss kopyasinda doku boyutu siniri (px). 256 = kucuk indirme (onerilen) | 512 = daha net ama daha buyuk dosya | 0 = dokulara dokunma'),
    ('vex_res BOSS_GIANT_ALL "1"', '1 = 9 dev bossun hepsi her haritada yuklenir: oyuncu hepsini ILK GIRISTE bir kez indirir, sonraki haritalarda hic indirme olmaz | 0 = sadece o haritanin 3 bossu (her yeni haritada yeni indirme)'),
    ('vex_topboard 1', 'UST SKOR PANELI (CSO tarzi): 1 = acik  [INSAN galibiyet/canli]  TUR + sure + mod  [ZOMBI galibiyet/canli]'),
    ('vex_topboard_pad 44', 'panelde yan bloklarin ortadan uzakligi (bosluk sayisi). Yazilar ust uste binerse buyut, cok aciksa kucult (10-60)'),
    ('vex_topboard_y 0.01', 'panelin ekrandaki yuksekligi (0.0 = en ust, 0.05 = biraz asagi)'),
    ('vex_radio_text 1', '1 = ozel telsiz sesi calinca sohbete gercekci telsiz metni yazilir (TR/EN, oyuncunun diline gore)'),
    ('vex_cos_smooth 1', '1 = sapkalar oyuncuyla ayni akicilikta hareket eder (gecikme / isinlanma yok)'),
    ('vex_map_pool "zm_vexmira_7door zm_vexmira_dust zm_vexmira_icefy zm_3rooms zm_cross zm_dust_world zm_foda zm_fox zm_lila_panic zm_ice_attack3"', 'oylamadaki haritalar (sunucuda .bsp dosyasi olmayan harita oylamada gosterilmez)'),
    ('vex_full_rotation 1', '1 = her haritada (30 round) 7 ozel modun HEPSI + 18 eventin HEPSI + coklu enfeksiyon kesin oynanir (harita basinda plan kurulur; boss roundlari vex_boss_rounds). 0 = eski rastgele sistem'),
    ('vex_special_rounds "4 11 19 26"', 'ozel mod roundlari - SADECE vex_full_rotation 0 iken kullanilir'),
    ('vex_event_chance 30', 'event cikma sansi (%) - SADECE vex_full_rotation 0 iken kullanilir'),
    ('vex_lm_damage 550', 'INSAN lazerinin zombiye vurdugu hasar (her temas)'),
    ('vex_lm_zombie_damage 550', 'ZOMBI lazerinin insana vurdugu hasar (her temas)'),
    ('vex_lm_keep 1', '1 = lazer, sahibi olunce / enfekte olunca YOK OLMAZ (tur sonuna kadar ya da kirilana kadar kalir)'),
    ('vex_lm_human_break_mult 1.0', 'insanlarin zombi lazerine verdigi hasar carpani (mermiyle kirma; zombiler icin vex_lm_zombie_mult)'),
    ('vex_lm_beam_width 14', 'lazer isini kalinligi (5.3.2 dokusu: ince parlak cekirdek + yumusak isik hali)'),
]
# 5.3.2 ambience: 8 looping beds (sound/vexmira/amb532) shared by every round type
_BED = ['calm', 'tension', 'hunt', 'hope', 'storm', 'frost', 'boss', 'chaos']
_MODE_N = ['Enfeksiyon', 'Coklu', 'Nemesis', 'Assassin', 'Survivor', 'Sniper', 'Swarm', 'Plague', 'Armageddon', 'Boss']
_EV_N = ['Normal', 'Kan Ayi', 'Yogun Sis', 'Hiz', 'Dusuk Yercekimi', 'Cift Hasar', 'Karanlik Gece', 'Salgin',
         'Malzeme', 'Delilik', 'Adrenalin', 'Meteor', 'Zombi Surusu', 'Titan', 'Altin', 'Vampir Gecesi',
         'Kafa Avi', 'Firtina', 'Elektrik Kesintisi']
for _j, _b in enumerate([0, 1, 2, 2, 3, 3, 1, 1, 7, 6]):
    OVERRIDE.append(('vex_res AMBIENT_MODE%d "sound/vexmira/amb532/%s.wav"' % (_j, _BED[_b]),
                     'ambiyans: %s roundu (calm/tension/hunt/hope/storm/frost/boss/chaos ya da kendi wav dosyan; mono 22kHz alti; "" = sessiz)' % _MODE_N[_j]))
for _j, _b in enumerate([0, 4, 5, 1, 3, 1, 5, 1, 0, 7, 1, 7, 7, 7, 3, 5, 2, 4, 5]):
    OVERRIDE.append(('vex_res AMBIENT_EVENT%d "sound/vexmira/amb532/%s.wav"' % (_j, _BED[_b]), 'ambiyans: %s eventi' % _EV_N[_j]))
for _j in range(9):
    OVERRIDE.append(('vex_res AMBIENT_BOSS%d "sound/vexmira/amb532/boss.wav"' % _j, 'ambiyans: boss %d roundu' % _j))
for _k, _d in (('BURST', 'patlama'), ('LEAP', 'sicrama'), ('SHIELD', 'kemik kalkan'), ('DRAIN', 'can emme'),
               ('CLOAK', 'gorunmezlik'), ('TOXIC', 'zehir puskurtme'), ('FROST', 'buz patlamasi')):
    OVERRIDE.append(('vex_res ABILITY_%s "vexmira/skill532/%s.wav"' % (_k, _k.lower()),
                     'zombi yetenegi sesi: %s (5.3.2 ozel ses; eskiden hepsi ayni silah sesiydi)' % _d))
OVERRIDE += [
    ('vex_ambience_volume 0.55', 'ambiyans muzik/ses seviyesi (0.05 - 1.0)'),
    ('vex_ambience_restart 120', 'ambiyans kac saniyede bir tazelenir (parcalar zaten kendi kendine doner; baglanan / sesi kesilen oyuncu icin)'),
]
# keys whose old value must go (meme sounds on zombies, per-class overrides that hid the pools)
DROP_VALUE_RE = [re.compile(r'^vex_res Z\d+_(DIE|PAIN)$'), re.compile(r'^vex_res SW4_')]
DROP_KEYS = {('vex_restore', 'LASERMINE_MODEL')}
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
