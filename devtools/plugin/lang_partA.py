# Part A (v3.0 siniflar + F tusu) dil anahtarlari: EN + TR (mevcutlari gunceller, yenileri ekler)
import re
P = '/home/user/claude/cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt'
txt = open(P, encoding='utf-8').read()
lines = txt.split('\n')

EN = [
 # siniflar 12-23
 ('CLASS_12', 'Butcher'), ('CLASS_DESC_12', 'Tough. [R] meat hook pulls a human to you'),
 ('CLASS_13', 'Hunter'), ('CLASS_DESC_13', 'Agile. [R] pounce, stuns on landing'),
 ('CLASS_14', 'Charger'), ('CLASS_DESC_14', 'Heavy. [R] charge, throws humans aside'),
 ('CLASS_15', 'Arachne'), ('CLASS_DESC_15', 'Low gravity. [R] web shot roots + slows'),
 ('CLASS_16', 'Magma'), ('CLASS_DESC_16', 'Fireproof. [R] burning lava trail'),
 ('CLASS_17', 'Volt'), ('CLASS_DESC_17', '[R] EMP: lasers, flashlights, NVG go dark'),
 ('CLASS_18', 'Mimic'), ('CLASS_DESC_18', '[R] looks human, first hit deals x2'),
 ('CLASS_19', 'Burrower'), ('CLASS_DESC_19', '[R] dives underground, erupts knocking up'),
 ('CLASS_20', 'Siren'), ('CLASS_DESC_20', '[R] lullaby lures humans towards you'),
 ('CLASS_21', 'Bulwark'), ('CLASS_DESC_21', 'Huge HP. [R] fortify: -50%% dmg, reflects'),
 ('CLASS_22', 'Sporemother'), ('CLASS_DESC_22', '[R] plants spore pods (poison traps)'),
 ('CLASS_23', 'Nightmare'), ('CLASS_DESC_23', '[R] terror: blinds humans, speeds you up'),
 # HUD satirlari (tus ipuclari)
 ('HUD_CLASS_CD', 'Class : %s   |   [R/G] %d s'),
 ('HUD_CLASS_READY', 'Class : %s   |   [R/G] READY'),
 ('HUD_CLASS_ACT', 'Class : %s   |   [R/G] ACTIVE %d s'),
 ('HUD_BOSS_R', '[R] %s : %s   |   [F/G] Leap : %s'),
 ('HUD_NEM_RF', '[R] Leap : %s   |   [F/G] Rage : %s'),
 ('HUD_ASN_RF', '[R] Leap : %s   |   [F/G] Shadow Veil : %s'),
 ('ABILITY_COOL', 'Ability recharging: %d s'),
 # red / uyari
 ('SKILL_ONLY_ZOMBIE', 'Skills can only be used by living zombies'),
 ('SKILL_ROUND_OVER', 'The round is over - skills are disabled'),
 ('SKILL_MINION', 'Minions have no skills'),
 ('SKILL_STUNNED', 'You are stunned! (%d s)'),
 ('SKILL_NEED_GROUND', 'You must be on the ground!'),
 ('SKILL_BOSS_INTRO', 'The boss is awakening... skills in %d s'),
 ('SKILL_BURROWED', 'You are underground!'),
 ('SKILL_NO_SPACE', 'No room to do that here!'),
 ('SKILL_HOOK_BUSY', 'Your hook is already out!'),
 ('SKILL_NO_TARGET', 'No human in range!'),
 ('LIGHTS_BLOCKED', 'EMP! Your lights are dead for %d s'),
 # kasap
 ('HOOK_THROW_YOU', 'MEAT HOOK!'),
 ('HOOK_GOT_YOU', 'HOOKED: %s!^nReel them in'),
 ('HOOK_PULLED', 'HOOKED by %s!^nYou are being dragged'),
 ('HOOK_IMMUNE', 'The hook slips off - target cannot be pulled!'),
 ('HOOK_MISS_YOU', 'The hook missed'),
 # avci
 ('HUNTER_POUNCE_YOU', 'POUNCE!'),
 ('HUNTER_STUNNED', 'POUNCED by %s!^nYou are stunned'),
 ('HUNTER_HIT_YOU', 'Pinned down: %s'),
 # boga
 ('CHARGER_YOU', 'CHARGE!'),
 ('CHARGER_HIT', 'RAMMED by %s!'),
 ('CHARGER_CRASH', 'You crashed into a wall!'),
 # orumcek
 ('ARACHNE_YOU', 'WEB SHOT!'),
 ('ARACHNE_WEBBED', 'WEBBED by %s!^nYou cannot move'),
 ('ARACHNE_HIT_YOU', 'Webbed: %s'),
 # magma
 ('MAGMA_YOU', 'LAVA TRAIL!^nYour steps set the ground on fire'),
 ('MAGMA_IMMUNE', 'Magma zombies are immune to fire!'),
 # volt
 ('VOLT_YOU', 'EMP BLAST!^n%d laser mine(s) disabled'),
 ('VOLT_EMP_HIT', 'EMP by %s!^nLasers, flashlight and NVG are down'),
 # taklitci
 ('MIMIC_YOU', 'DISGUISE!^nYou look human - your first hit deals x2'),
 ('MIMIC_REVEALED', 'IT WAS A MIMIC: %s!'),
 ('MIMIC_STRIKE_YOU', 'AMBUSH! Disguise dropped'),
 ('MIMIC_END_YOU', 'Your disguise wore off'),
 # kostebek
 ('BURROW_YOU', 'BURROW!^nUnseen and untouchable'),
 ('BURROW_HIT', 'ERUPTION by %s!'),
 # siren
 ('SIREN_YOU', 'LULLABY!^n%d human(s) entranced'),
 ('SIREN_LURED', 'The song of %s...^nYou are drawn towards it'),
 # kale
 ('BULWARK_YOU', 'FORTIFY!^nNo knockback, -50%% damage, reflect'),
 # spor ana
 ('SPORE_YOU', 'SPORE POD planted (%d)'),
 ('SPORE_HIT', 'SPORES of %s!^nPoisoned and slowed'),
 ('SPORE_BURST_YOU', 'Spore pod burst: %d human(s) poisoned'),
 ('SPORE_DESTROYED', '^3[SPORE] ^1Your spore pod was destroyed by ^3%s^1.'),
 # kabus
 ('NIGHTMARE_YOU', 'TERROR!^n%d human(s) blinded - run!'),
 ('NIGHTMARE_HIT', 'NIGHTMARE %s!^nDarkness falls'),
]

TR = [
 ('CLASS_12', 'Kasap'), ('CLASS_DESC_12', 'Dayanikli. [R] et kancasi insani sana ceker'),
 ('CLASS_13', 'Avci'), ('CLASS_DESC_13', 'Cevik. [R] atilma, inince sersemletir'),
 ('CLASS_14', 'Boga'), ('CLASS_DESC_14', 'Agir. [R] hucum, insanlari savurur'),
 ('CLASS_15', 'Orumcek'), ('CLASS_DESC_15', 'Hafif. [R] ag atisi: kok + yavaslama'),
 ('CLASS_16', 'Magma'), ('CLASS_DESC_16', 'Ates islemez. [R] yanan lav izi'),
 ('CLASS_17', 'Volt'), ('CLASS_DESC_17', '[R] EMP: lazer, fener, gece gorusu soner'),
 ('CLASS_18', 'Taklitci'), ('CLASS_DESC_18', '[R] insan kiligi, ilk vurus x2'),
 ('CLASS_19', 'Kostebek'), ('CLASS_DESC_19', '[R] yeraltina dalar, cikista firlatir'),
 ('CLASS_20', 'Siren'), ('CLASS_DESC_20', '[R] ninni insanlari sana ceker'),
 ('CLASS_21', 'Kale'), ('CLASS_DESC_21', 'Devasa can. [R] tahkim: -%%50 hasar, yansitma'),
 ('CLASS_22', 'Spor Ana'), ('CLASS_DESC_22', '[R] spor kesesi diker (zehirli tuzak)'),
 ('CLASS_23', 'Kabus'), ('CLASS_DESC_23', '[R] dehset: insanlari kor eder, hizlanirsin'),
 ('HUD_CLASS_CD', 'Sinif : %s   |   [R/G] %d sn'),
 ('HUD_CLASS_READY', 'Sinif : %s   |   [R/G] HAZIR'),
 ('HUD_CLASS_ACT', 'Sinif : %s   |   [R/G] AKTIF %d sn'),
 ('HUD_BOSS_R', '[R] %s : %s   |   [F/G] Atilma : %s'),
 ('HUD_NEM_RF', '[R] Atilma : %s   |   [F/G] Ofke : %s'),
 ('HUD_ASN_RF', '[R] Atilma : %s   |   [F/G] Golge : %s'),
 ('ABILITY_COOL', 'Yetenek yenileniyor: %d sn'),
 ('SKILL_ONLY_ZOMBIE', 'Yetenekleri sadece canli zombiler kullanabilir'),
 ('SKILL_ROUND_OVER', 'Round bitti - yetenekler kapali'),
 ('SKILL_MINION', 'Yardimci zombilerin yetenegi yok'),
 ('SKILL_STUNNED', 'Sersemledin! (%d sn)'),
 ('SKILL_NEED_GROUND', 'Yerde olmalisin!'),
 ('SKILL_BOSS_INTRO', 'Boss uyaniyor... yetenekler %d sn sonra'),
 ('SKILL_BURROWED', 'Yeraltindasin!'),
 ('SKILL_NO_SPACE', 'Burada buna yer yok!'),
 ('SKILL_HOOK_BUSY', 'Kancan zaten havada!'),
 ('SKILL_NO_TARGET', 'Menzilde insan yok!'),
 ('LIGHTS_BLOCKED', 'EMP! Isiklarin %d sn kapali'),
 ('HOOK_THROW_YOU', 'ET KANCASI!'),
 ('HOOK_GOT_YOU', 'YAKALANDI: %s!^nCek onu'),
 ('HOOK_PULLED', '%s seni KANCALADI!^nSurukleniyorsun'),
 ('HOOK_IMMUNE', 'Kanca kaydi - bu hedef cekilemez!'),
 ('HOOK_MISS_YOU', 'Kanca iskaladi'),
 ('HUNTER_POUNCE_YOU', 'ATILMA!'),
 ('HUNTER_STUNNED', '%s USTUNE ATLADI!^nSersemledin'),
 ('HUNTER_HIT_YOU', 'Yere serildi: %s'),
 ('CHARGER_YOU', 'HUCUM!'),
 ('CHARGER_HIT', '%s seni EZDI!'),
 ('CHARGER_CRASH', 'Duvara carptin!'),
 ('ARACHNE_YOU', 'AG ATISI!'),
 ('ARACHNE_WEBBED', '%s seni AGA DUSURDU!^nKipirdayamiyorsun'),
 ('ARACHNE_HIT_YOU', 'Aga dustu: %s'),
 ('MAGMA_YOU', 'LAV IZI!^nAdimlarin zemini tutusturuyor'),
 ('MAGMA_IMMUNE', 'Magma zombisine ates islemez!'),
 ('VOLT_YOU', 'EMP PATLAMASI!^n%d lazer mayini kapandi'),
 ('VOLT_EMP_HIT', '%s EMP patlatti!^nLazer, fener ve gece gorusu kapali'),
 ('MIMIC_YOU', 'KILIK!^nInsan gibi gorunuyorsun - ilk vurusun x2'),
 ('MIMIC_REVEALED', 'O BIR TAKLITCIYDI: %s!'),
 ('MIMIC_STRIKE_YOU', 'PUSU! Kilik dustu'),
 ('MIMIC_END_YOU', 'Kiligin bozuldu'),
 ('BURROW_YOU', 'YERALTI!^nGorunmez ve dokunulmazsin'),
 ('BURROW_HIT', '%s YERDEN FIRLADI!'),
 ('SIREN_YOU', 'NINNI!^n%d insan buyulendi'),
 ('SIREN_LURED', '%s sarki soyluyor...^nOna dogru cekiliyorsun'),
 ('BULWARK_YOU', 'TAHKIM!^nGeri tepme yok, -%%50 hasar, yansitma'),
 ('SPORE_YOU', 'SPOR KESESI dikildi (%d)'),
 ('SPORE_HIT', '%s sporlari!^nZehirlendin ve yavasladin'),
 ('SPORE_BURST_YOU', 'Spor kesesi patladi: %d insan zehirlendi'),
 ('SPORE_DESTROYED', '^3[SPOR] ^1Spor keseni ^3%s^1 patlatti.'),
 ('NIGHTMARE_YOU', 'DEHSET!^n%d insan kor oldu - saldir!'),
 ('NIGHTMARE_HIT', 'KABUS %s!^nKaranlik cokuyor'),
]
assert [k for k,_ in EN] == [k for k,_ in TR]

# Bolumler
idx = {}
cur = None
for i, ln in enumerate(lines):
    m = re.match(r'^\[(\w+)\]\s*$', ln)
    if m:
        cur = m.group(1); continue
    m = re.match(r'^([A-Za-z0-9_]+)\s*=', ln)
    if m and cur:
        idx[(cur, m.group(1))] = i

def apply(sec, kv):
    global lines
    added = []
    for k, v in kv:
        if (sec, k) in idx:
            lines[idx[(sec, k)]] = f'{k} = {v}'
        else:
            added.append(f'{k} = {v}')
    return added

addEN = apply('en', EN)
addTR = apply('tr', TR)
# [tr] baslangicindan once EN eklemeleri, dosya sonuna TR eklemeleri
tr_at = lines.index('[tr]')
# bos satirlari koru: [tr] oncesindeki son dolu satirdan sonra ekle
ins = tr_at
while ins > 0 and lines[ins-1].strip() == '':
    ins -= 1
lines = lines[:ins] + addEN + lines[ins:]
while lines and lines[-1].strip() == '':
    lines.pop()
lines += addTR
open(P, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print('EN added', len(addEN), 'TR added', len(addTR))

# --- ikinci gecis: tus ipuclari ([F] yedekleri) ---
lines = open(P, encoding='utf-8').read().split('\n')
idx = {}
cur = None
for i, ln in enumerate(lines):
    m = re.match(r'^\[(\w+)\]\s*$', ln)
    if m:
        cur = m.group(1); continue
    m = re.match(r'^([A-Za-z0-9_]+)\s*=', ln)
    if m and cur:
        idx[(cur, m.group(1))] = i
EN2 = [
 ('HELP_2', '^4[?] ^3ZOMBIES:^1 claw humans to infect them. ^4[R]^1 or ^4[G]^1 = class ability. Bosses: ^4[R]^1 skill, ^4[F]^1/^4[G]^1 leap.'),
 ('ROLE_NEMESIS_YOU', 'YOU ARE THE NEMESIS - ONE HIT KILLS^n[R] leap     [F] or [G] rage'),
 ('ROLE_ASSASSIN_YOU', 'YOU ARE THE ASSASSIN - ONE HIT KILLS^n[R] leap     [F] or [G] shadow veil'),
 ('ROLE_BOSS_YOU', '^3[!] ^1You are the ^3BOSS^1! ^4[R]^1 = special skill, ^4[F]^1 or ^4[G]^1 = leap.'),
 ('ROLE_BOSS_KEYS', '^4[BOSS] ^1Keys: ^4[R]^1 = phase skill (a new one every phase), ^4[F]^1 / ^4[G]^1 = leap. Your attacks grow stronger every phase!'),
 ('SKILL_KEYS_HINT', '^4[KEYS] ^1If ^4[F]^1 does nothing, press ^4[G]^1, type ^4/skill2^1 or bind it: ^4bind f vex_skill2^1 (R: ^4vex_skill^1).'),
]
TR2 = [
 ('HELP_2', '^4[?] ^3ZOMBILER:^1 pencenle vur, enfekte et. ^4[R]^1 ya da ^4[G]^1 = sinif yetenegi. Boss: ^4[R]^1 yetenek, ^4[F]^1/^4[G]^1 atilma.'),
 ('ROLE_NEMESIS_YOU', 'NEMESIS SENSIN - TEK VURUSTA OLDURURSUN^n[R] atilma     [F] ya da [G] ofke'),
 ('ROLE_ASSASSIN_YOU', 'ASSASSIN SENSIN - TEK VURUSTA OLDURURSUN^n[R] atilma     [F] ya da [G] golge perdesi'),
 ('ROLE_BOSS_YOU', '^3[!] ^1BOSS ^3sensin^1! ^4[R]^1 = ozel yetenek, ^4[F]^1 ya da ^4[G]^1 = atilma.'),
 ('ROLE_BOSS_KEYS', '^4[BOSS] ^1Tuslar: ^4[R]^1 = faz yetenegi (her fazda yenisi gelir), ^4[F]^1 / ^4[G]^1 = atilma. Her fazda saldirilarin guclenir!'),
 ('SKILL_KEYS_HINT', '^4[TUSLAR] ^1^4[F]^1 calismazsa ^4[G]^1 tusuna bas, ^4/beceri2^1 yaz ya da konsola: ^4bind f vex_skill2^1 (R: ^4vex_skill^1).'),
]
for sec, kv in (('en', EN2), ('tr', TR2)):
    for k, v in kv:
        if (sec, k) in idx:
            lines[idx[(sec, k)]] = f'{k} = {v}'
        else:
            if sec == 'en':
                at = lines.index('[tr]')
                while at > 0 and lines[at-1].strip() == '':
                    at -= 1
                lines.insert(at, f'{k} = {v}')
                idx = {kk: (vv + 1 if vv >= at else vv) for kk, vv in idx.items()}
            else:
                while lines and lines[-1].strip() == '':
                    lines.pop()
                lines.append(f'{k} = {v}')
open(P, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print('pass2 ok')
