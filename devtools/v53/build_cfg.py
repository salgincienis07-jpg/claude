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
    ('vex_hostname "Zombie Plague | Vexmira | Boss+Events+Bunny"', 'sunucu adi (oyun listesinde gorunen)'),
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
    ('vex_sw_damage_mult 3.0', 'OZEL SILAH HASARI: tum ozel silahlarin hasar carpani (vex_sw carpaninin USTUNE; 1.0 = eski)'),
    ('vex_unlimited_bpammo 1', '1 = herkeste sinirsiz yedek mermi (TUM mod/eventlerde), ozel silahlar haric'),
    ('vex_nade_fx 1', '1 = ates / buz / isik / enfeksiyon bombalarinda katmanli epik patlama efektleri'),
    ('vex_cos_follow 1', '1 = kanat + sapka oyuncuya kemikle yapisik (gecikme / isinlanma yok)'),
    ('vex_blackout_light "b"', 'Elektrik Kesintisi roundu isik seviyesi (a = zifiri karanlik ... m = normal)'),
    ('vex_auto_hitbox 1', '1 = boyu uzun modellerde (CSO zombileri, dev bosslar) vurus kutusu modele gore otomatik buyur'),
    ('vex_laser_prices "300 450 600 900"', 'VexCoin lazer isinlari: Plazma / Kan / Toksik / Gokkusagi fiyatlari'),
    ('vex_env_event 18 b 0 0 0 18 0', 'Elektrik Kesintisi: tum round karanlik'),
    # ---- 5.3.2 ----
    ('vex_chat_prefix "^4[^1VEXMIRA^4]^1"', 'sistem mesaji etiketi (^1 sari ^3 takim rengi ^4 yesil; Turkce harf kullanma, CS 1.6 sohbeti bozuk gosterir)'),
    ('vex_chat_prefix_boss "^3[^4BOSS^3]^1"', 'boss / boss yetenekleri etiketi'),
    ('vex_chat_prefix_event "^4[^3EVENT^4]^1"', 'event / hava olayi etiketi'),
    ('vex_chat_prefix_admin "^3[^4ADMIN^3]^1"', 'admin islemleri etiketi'),
    ('vex_res BOSS_GIANT "clone"', 'DEV BOSS YONTEMI: clone = boss kendi modeliyle buyuk cizilir (YENI DOSYA YOK, oyuncu hicbir sey indirmez - onerilen) | file = eski yontem (models/player/<boss>_x16 dosyasi uretilir, indirme gerekir) | off = normal boyut'),
    ('vex_topboard 1', 'UST SKOR PANELI (CSO tarzi): 1 = acik  [INSAN galibiyet/canli]  TUR + sure + mod  [ZOMBI galibiyet/canli]'),
    ('vex_topboard_pad 44', 'panelde yan bloklarin ortadan uzakligi (bosluk sayisi). Yazilar ust uste binerse buyut, cok aciksa kucult (10-60)'),
    ('vex_topboard_y 0.01', 'panelin ekrandaki yuksekligi (0.0 = en ust, 0.05 = biraz asagi)'),
    ('vex_radio_text 1', '1 = ozel telsiz sesi calinca sohbete gercekci telsiz metni yazilir (TR/EN, oyuncunun diline gore)'),
    ('vex_cos_smooth 1', '1 = sapkalar oyuncuyla ayni akicilikta hareket eder (gecikme / isinlanma yok)'),
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
DROP_VALUE_RE = [re.compile(r'^vex_res Z\d+_(DIE|PAIN)$')]
DROP_KEYS = {('vex_restore', 'LASERMINE_MODEL')}

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
    for k in list(order):
        if k in DROP_KEYS or (k[0] == 'vex_res' and len(k) > 1 and any(r.match('vex_res ' + k[1]) for r in DROP_VALUE_RE)):
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
        for l in e['lead']:
            if not l.lower().startswith(('vexmira zombie', 'vexmira community', 'vexmira six', 'vexmira 5.')):
                out.append('// ' + l)
        code = e['code']
        out.append(('%-60s // %s' % (code, e['comment'])) if e['comment'] else code)

    out += [
        '// VEXMIRA ZOMBIE 5.3.1 - TEK AYAR DOSYASI (vexmira_core + vexmira_gear)',
        '// ' + '-' * W,
        '// NASIL DEGISTIRILIR:',
        '//  * Her satir: ayar_adi deger      // aciklama   ("//" sonrasi okunmaz, istediginiz notu yazabilirsiniz)',
        '//  * Degeri degistirip kaydedin; oyunda "amx_rcon vex_reload" veya harita degisimi ile gecerli olur.',
        '//  * vex_res ... satirlari (model / ses / sprite / gokyuzu) SADECE harita degisiminde yuklenir.',
        '//  * Ses satirlarinda birden fazla dosya "a.wav|b.wav|c.wav" seklinde yazilabilir: her seferinde rastgele biri.',
        '//  * Yol yazarken: modeller "models/...mdl", sesler "sound/" OLMADAN ("zombie/claw_strike1.wav").',
        '//  * Dosya sunucuda yoksa eklenti onu ATLAR (cokmez) ve logs/ altina "bulunamadi" yazar.',
        '//  * vexmira_epic.cfg ARTIK KULLANILMAZ: tum ayarlar bu dosyada (eski dosya otomatik .old yapilir).',
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
