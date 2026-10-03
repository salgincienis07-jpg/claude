# Part A: vexmira.cfg guncellemesi (yeni siniflar, yetenek ayarlari, sinif kaynaklari). Tekrar calistirilabilir.
import re
P = '/home/user/claude/cstrike/addons/amxmodx/configs/vexmira.cfg'
s = open(P, encoding='utf-8').read()

NAMES = ["Walker", "Runner", "Tank", "Banshee", "Leech", "Stalker", "Bomber", "Frost", "Spitter", "Hulk", "Voodoo", "Phantom",
         "Butcher / Kasap", "Hunter / Avci", "Charger / Boga", "Arachne / Orumcek", "Magma", "Volt", "Mimic / Taklitci",
         "Burrower / Kostebek", "Siren", "Bulwark / Kale", "Sporemother / Spor Ana", "Nightmare / Kabus"]
FILES = ["walker", "runner", "tank", "banshee", "leech", "stalker", "bomber", "frost", "spitter", "hulk", "voodoo", "phantom",
         "butcher", "hunter", "charger", "arachne", "magma", "volt", "mimic", "burrower", "siren", "bulwark", "sporemother", "nightmare"]
OLD = ["terror", "leet", "arctic", "guerilla", "terror", "leet", "arctic", "guerilla", "terror", "arctic", "guerilla", "leet",
       "terror", "leet", "arctic", "guerilla", "terror", "arctic", "guerilla", "leet", "guerilla", "arctic", "terror", "leet"]

# 1) vex_class 12-23
NEWCLS = [
 (12, '1.35', 255, '0.90', '0.60', '16.0', 3,  'Butcher / Kasap   [R] et kancasi'),
 (13, '0.85', 300, '0.70', '1.10', '12.0', 6,  'Hunter / Avci     [R] atilma + sersemletme'),
 (14, '1.40', 250, '1.00', '0.50', '15.0', 9,  'Charger / Boga    [R] hucum'),
 (15, '0.85', 290, '0.60', '1.00', '13.0', 11, 'Arachne / Orumcek [R] ag atisi'),
 (16, '1.10', 265, '0.80', '0.90', '18.0', 13, 'Magma             [R] lav izi (ates islemez)'),
 (17, '0.95', 280, '0.80', '1.00', '18.0', 15, 'Volt              [R] EMP'),
 (18, '0.90', 275, '0.80', '1.00', '22.0', 17, 'Mimic / Taklitci  [R] insan kiligi'),
 (19, '1.00', 270, '0.85', '0.90', '18.0', 19, 'Burrower / Kostebek [R] yeraltina dalis'),
 (20, '0.90', 280, '0.80', '1.00', '17.0', 21, 'Siren             [R] ninni (cekim)'),
 (21, '1.70', 240, '1.00', '0.30', '18.0', 23, 'Bulwark / Kale    [R] tahkim'),
 (22, '1.00', 265, '0.80', '1.00', '15.0', 26, 'Sporemother / Spor Ana [R] spor kesesi'),
 (23, '0.90', 290, '0.80', '1.00', '20.0', 28, 'Nightmare / Kabus [R] dehset'),
]
if 'vex_class 12 ' not in s:
    anchor = 'vex_class 11 0.75  300  0.70  1.20  9.0   25  // Phantom\n'
    assert anchor in s
    add = ''.join(f'vex_class {n:<2} {hp:<5} {sp:<4} {gr:<5} {kb:<5} {cd:<5} {lv:<3} // {nm}\n' for n, hp, sp, gr, kb, cd, lv, nm in NEWCLS)
    s = s.replace(anchor, anchor + add)

# 2) Yetenek ayarlari bolumu (OZEL SILAHLAR'dan once)
SEC = '''// =====================================================================
//  YENI ZOMBI SINIFLARI (12-23) - [R] YETENEK AYARLARI
// =====================================================================
// [R] = reload tusu. Yedek: [G] (drop) tusu ya da konsolda vex_skill / vex_skill2
vex_skill_alt_keys        1       // 1 = zombilerde G (drop) tusu da yetenegi kullanir (insanlarda silah atma degismez)
vex_bot_abilities         1       // 1 = bot zombiler yakinda gorunen insan varken yeteneklerini kendiliginden kullanir
// 12 Kasap: et kancasi (zincirli kanca insani kasaba ceker; Boss / Survivor / Sniper cekilemez)
vex_butcher_hook_speed    1400    // kanca ucus hizi (birim/sn)
vex_butcher_hook_range    900     // kancanin en uzak menzili (birim)
vex_butcher_pull_speed    600     // insanin cekilme hizi (birim/sn)
vex_butcher_pull_time     1.2     // en uzun cekme suresi (sn); gorus kesilince / 60 birime gelince biter
vex_butcher_hook_damage   10      // kanca takilinca verilen hasar
// 13 Avci: uzun atilma, inince yakindaki insani sersemletir
vex_hunter_pounce_power   860     // ileri atilma gucu
vex_hunter_pounce_up      330     // yukari atilma gucu
vex_hunter_radius         70      // inis etki yaricapi (birim)
vex_hunter_stun           1.0     // sersemletme suresi (sn)
vex_hunter_damage         15      // inis hasari
// 14 Boga: dumduz hucum, yoldaki insanlari yana savurur; duvara carparsa kendisi sersemler
vex_charger_time          1.5     // hucum suresi (sn)
vex_charger_speed         650     // hucum hizi (birim/sn)
vex_charger_damage        20      // carpilan insana hasar
vex_charger_push          550     // savurma gucu
vex_charger_self_stun     0.5     // duvara carpinca kendi sersemleme suresi (sn)
// 15 Orumcek: ag mermisi; vurulan insan kok salar ve yavaslar
vex_arachne_web_speed     1100    // ag mermisi hizi
vex_arachne_web_range     1000    // ag menzili
vex_arachne_root          1.5     // kok (hareketsiz) suresi (sn)
vex_arachne_slow          3.0     // kokten sonra yavaslama suresi (sn)
vex_arachne_damage        5       // ag hasari
// 16 Magma: yurudugu yere lav havuzlari birakir; ates bombasi / yanma islemez
vex_magma_trail_time      5       // lav izi suresi (sn)
vex_magma_pool_life       4       // her lav havuzunun omru (sn)
vex_magma_pool_radius     60      // lav havuzu yaricapi
vex_magma_pool_damage     6       // havuzdaki insana saniyede hasar (+ yanma)
vex_magma_fire_immune     1       // 1 = Magma ates hasari almaz
// 17 Volt: EMP - yakindaki lazer mayinlari kapanir, fener / gece gorusu soner
vex_volt_radius           350     // EMP yaricapi
vex_volt_mine_off         6       // lazer mayinlarinin kapali kalma suresi (sn)
vex_volt_light_off        6       // fener / gece gorusu kilit suresi (sn)
vex_volt_damage           8       // elektrik hasari
vex_volt_slow             1.5     // yavaslatma suresi (sn)
// 18 Taklitci: insan modeline girer (parlama / ayak sesi yok); ilk vurusu ekstra hasar verir ve kiligi acar
vex_mimic_time            10      // kilik suresi (sn)
vex_mimic_damage_mult     2.0     // kiliktayken ilk vurus hasar carpani
// 19 Kostebek: yeraltina dalar (gorunmez + hasar almaz + hizli), cikista insanlari havaya firlatir
vex_burrower_time         3       // yeraltinda kalma suresi (sn)
vex_burrower_speed        1.5     // yeraltinda hiz carpani
vex_burrower_radius       220     // cikis sok dalgasi yaricapi
vex_burrower_knockup      450     // havaya firlatma gucu
vex_burrower_damage       15      // cikis hasari
// 20 Siren: ninni - gorus hattindaki insanlar yavasca Siren'e cekilir (pembe ekran + yavaslama)
vex_siren_radius          400     // etki yaricapi
vex_siren_time            2.5     // cekim suresi (sn)
vex_siren_pull            170     // cekim hizi (birim/sn)
// 21 Kale: tahkim - geri tepme yok, hasar azaltma, aldigi hasarin bir kismini yansitir (oldurmez)
vex_bulwark_time          5       // tahkim suresi (sn)
vex_bulwark_reduce        50      // hasar azaltma (%)
vex_bulwark_reflect       25      // yansitilan hasar (%; vurus basina en fazla 60)
// 22 Spor Ana: ayagina spor kesesi diker; insan yaklasinca patlar (zehir + yavaslama). Kese vurularak kirilabilir
vex_sporemother_max       2       // ayni anda en fazla kese (fazlasi en eskiyi sondurur)
vex_sporemother_radius    120     // tetiklenme yaricapi (patlama 1.4 kati)
vex_sporemother_hp        120     // kese cani
vex_sporemother_poison    6       // zehir suresi (sn; saniyede 6 hasar)
vex_sporemother_life      60      // kesenin omru (sn)
vex_sporemother_slow      3.0     // yavaslatma suresi (sn)
// 23 Kabus: dehset - gorus hattindaki insanlarin ekrani kararir, fenerleri soner; Kabus hizlanir
vex_nightmare_radius      450     // etki yaricapi
vex_nightmare_blind       2.5     // karartma suresi (sn)
vex_nightmare_boost       3       // Kabus hizlanma suresi (sn)
vex_nightmare_speed       1.35    // hizlanma carpani

'''
if 'vex_butcher_hook_speed' not in s:
    anchor = '''// =====================================================================
//  OZEL SILAHLAR
// ====================================================================='''
    assert s.count(anchor) == 1
    s = s.replace(anchor, SEC + anchor)

# 3) Sinif kaynaklari bolumu (Z<n>_MODEL "terror" ... satirlari yeniden yazilir)
start = s.index('//  ZOMBI SINIFLARI: model, pence (el modeli), sinifa ozel sesler')
start = s.rfind('// =====', 0, start)
end = s.index('//  BOSSLAR: model, pence, bossa ozel sesler')
end = s.rfind('// =====', 0, end)
res = '''// =====================================================================
//  ZOMBI SINIFLARI: model, pence (el modeli), sinifa ozel sesler
// =====================================================================
// Z<n>_MODEL = oyuncu modeli ADI (models/player/<ad>/<ad>.mdl). Yoksa orijinal CS modeline duser.
// Z<n>_CLAW  = el / pence modeli (tam yol). Yoksa CLAW_MODEL, o da yoksa normal bicak.
// Z<n>_PAIN / _DIE / _IDLE / _ABILITY = sinifa ozel sesler (yoksa genel ZOMBIE_* sesi)
// Ek (istege bagli): Z<n>_SLASH / _HIT / _STAB / _HITWALL / _INFECT
// vex_res CLAW_MODEL      "models/vexmira/v_claws.mdl"
'''
for i in range(24):
    f = FILES[i]
    res += f'\n// {i} - {NAMES[i]}   (yedek model: {OLD[i]})\n'
    res += f'vex_res Z{i}_MODEL    "vex_z_{f}"\n'
    res += f'vex_res Z{i}_CLAW     "models/vexmira/claws/v_{f}.mdl"\n'
    for ev in ('pain', 'die', 'idle', 'ability'):
        res += f'vex_res Z{i}_{ev.upper():<8}"vexmira/class/{f}_{ev}.wav"\n'
res += '''
// ---------------- YENI SINIF YETENEK SESLERI / MODELLERI / SPRITE'LARI ----------------
vex_res HUNTER_IMPACT     "vexmira/class/hunter_impact.wav"       // yedek: garg/gar_stomp1.wav
vex_res CHARGER_IMPACT    "vexmira/class/charger_impact.wav"      // yedek: garg/gar_stomp1.wav
vex_res ARACHNE_WEBHIT    "vexmira/class/arachne_webhit.wav"      // yedek: bullchicken/bc_spithit1.wav
vex_res BURROWER_ERUPT    "vexmira/class/burrower_erupt.wav"      // yedek: garg/gar_stomp1.wav
vex_res SPOREMOTHER_BURST "vexmira/class/sporemother_burst.wav"   // yedek: bullchicken/bc_acid1.wav
vex_res MIMIC_REVEAL      "vexmira/class/mimic_reveal.wav"        // yedek: zombie/zo_alert30.wav
vex_res VOLT_ZAP          "vexmira/class/volt_zap.wav"            // yedek: weapons/electro4.wav
vex_res HOOK_THROW        "vexmira/hook/throw.wav"                // kasap kancasi atis  (yedek: zombie/claw_miss1.wav)
vex_res HOOK_CHAIN        "vexmira/hook/chain.wav"                // zincir gerilmesi
vex_res HOOK_HIT          "vexmira/hook/hit.wav"                  // kanca takildi (yedek: zombie/claw_strike1.wav)
vex_res HOOK_PULL         "vexmira/hook/pull.wav"                 // cekilen insan
vex_res HOOK_MISS         "vexmira/hook/miss.wav"                 // iska (yedek: zombie/claw_miss2.wav)
vex_res HOOK_MODEL        "models/vexmira/world/hook.mdl"         // kanca basi (yoksa parlayan sprite)
vex_res SPORE_MODEL       "models/vexmira/world/spore_pod.mdl"    // spor kesesi (yoksa SPR_SPORE)
vex_res SPR_CHAIN         "sprites/vexmira/chain.spr"             // kanca zinciri isin dokusu (yoksa kirmizi lazer)
vex_res SPR_WEB           "sprites/vexmira/web.spr"               // orumcek agi
vex_res SPR_SPORE         "sprites/vexmira/spore.spr"             // spor bulutu / kese
vex_res SPR_EMP           "sprites/vexmira/emp.spr"               // Volt EMP halkasi

'''
s = s[:start] + res + s[end:]
open(P, 'w', encoding='utf-8').write(s)
print('cfg ok')
