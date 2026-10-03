# Part B (v3.0 gorsel kimlik): HUD yazilari, boss bari, sohbet etiketleri - EN + TR
# Tekrar calistirilabilir: anahtarlari gunceller / ekler, sohbet etiketlerini sadelestirir.
import re
P = '/home/user/claude/cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt'
txt = open(P, encoding='utf-8').read()
lines = txt.split('\n')

EN = [
 ('TOP_A', 'V E X M I R A   //   ROUND  %d / %d'),
 ('TOP_B', 'ZOMBIES  %d    -    %d  HUMANS'),
 ('TOP_B_BOSS', 'BOSS FIGHT    -    %d  HUMANS ALIVE'),
 ('TOP_C', '%s   ::   %s'),
 ('TOP_C_BOSSIN', '%s   ::   %s   ::   BOSS IN %d'),
 ('TOP_C_FINAL', '%s   ::   %s   ::   FINAL ROUND'),
 ('HUD_P1', 'LV.%d   //   %s'),
 ('HUD_P1R', 'LV.%d   //   %s   //   TOP #%d'),
 ('HUD_P_HP', 'HP  %d      ARMOR  %d'),
 ('HUD_P_DEAD', 'SPECTATING...'),
 ('HUD_P2', 'XP  [%s]  %d / %d'),
 ('HUD_P3', 'AP  %d      VC  %d      STREAK  %d'),
 ('HUD_CLASS_CD', '%s   ::   [R/G]  %d s'),
 ('HUD_CLASS_READY', '%s   ::   [R/G]  READY'),
 ('HUD_CLASS_ACT', '%s   ::   [R/G]  ACTIVE  %d s'),
 ('HUD_JOB', 'JOB  %s'),
 ('HUD_JOB_LM', 'JOB  %s   ::   LASERS  %d  (%d SET)'),
 ('HUD_BOSS_R', '[R] %s  %s   ::   [F/G] LEAP  %s'),
 ('HUD_NEM_RF', '[R] LEAP  %s   ::   [F/G] RAGE  %s'),
 ('HUD_ASN_RF', '[R] LEAP  %s   ::   [F/G] SHADOW VEIL  %s'),
 ('HUD_AIM', '%s   [%s]^nHP %d   ARMOR %d   LV.%d'),
 ('SPEC_INFO', 'WATCHING  ::  %s^nLV.%d   ::   %s   ::   HP %d   ::   ARMOR %d   ::   AP %d'),
 ('HUD_DROP_COMPASS', 'SUPPLY CRATE  %d m  %s'),
 ('BOSS_HPLINE', 'HP  %d / %d'),
 ('BOSS_PH_1', 'PHASE   [ I ]   II   III'),
 ('BOSS_PH_2', 'PHASE   I   [ II ]   III'),
 ('BOSS_PH_3', 'PHASE   I   II   [ III ]'),
 ('BOSS_PH_RAGE', 'PHASE   I   II   [ III ]   RAGE'),
 ('WAITING_PLAYERS', 'WAITING FOR PLAYERS   ( %d / 2 )'),
 ('COUNTDOWN', 'THE PLAGUE SPREADS IN   %d'),
 ('NMODE_HUD', 'GRENADE MODE  ::  %s^n(right click to change)'),
 ('LM_HINT_HUD', 'V  =  PLANT LASER      C  =  PICK UP'),
 ('PLAN_5', '^1Bosses loaded on this map: ^3%s'),
 ('BOSSINFO_TITLE', '^1Bosses on this map (they come in a shuffled order):'),
 ('THEME_0', 'Vexmira'),
]
TR = [
 ('TOP_A', 'V E X M I R A   //   ROUND  %d / %d'),
 ('TOP_B', 'ZOMBI  %d    -    %d  INSAN'),
 ('TOP_B_BOSS', 'BOSS SAVASI    -    %d  INSAN HAYATTA'),
 ('TOP_C', '%s   ::   %s'),
 ('TOP_C_BOSSIN', '%s   ::   %s   ::   BOSS: %d ROUND SONRA'),
 ('TOP_C_FINAL', '%s   ::   %s   ::   SON ROUND'),
 ('HUD_P1', 'LV.%d   //   %s'),
 ('HUD_P1R', 'LV.%d   //   %s   //   TOP #%d'),
 ('HUD_P_HP', 'CAN  %d      ZIRH  %d'),
 ('HUD_P_DEAD', 'IZLEYICI MODU...'),
 ('HUD_P2', 'XP  [%s]  %d / %d'),
 ('HUD_P3', 'AP  %d      VC  %d      SERI  %d'),
 ('HUD_CLASS_CD', '%s   ::   [R/G]  %d sn'),
 ('HUD_CLASS_READY', '%s   ::   [R/G]  HAZIR'),
 ('HUD_CLASS_ACT', '%s   ::   [R/G]  AKTIF  %d sn'),
 ('HUD_JOB', 'MESLEK  %s'),
 ('HUD_JOB_LM', 'MESLEK  %s   ::   LAZER  %d  (%d KURULU)'),
 ('HUD_BOSS_R', '[R] %s  %s   ::   [F/G] ATILMA  %s'),
 ('HUD_NEM_RF', '[R] ATILMA  %s   ::   [F/G] OFKE  %s'),
 ('HUD_ASN_RF', '[R] ATILMA  %s   ::   [F/G] GOLGE PERDESI  %s'),
 ('HUD_AIM', '%s   [%s]^nCAN %d   ZIRH %d   LV.%d'),
 ('SPEC_INFO', 'IZLENEN  ::  %s^nLV.%d   ::   %s   ::   CAN %d   ::   ZIRH %d   ::   AP %d'),
 ('HUD_DROP_COMPASS', 'IKMAL KUTUSU  %d m  %s'),
 ('BOSS_HPLINE', 'CAN  %d / %d'),
 ('BOSS_PH_1', 'FAZ   [ I ]   II   III'),
 ('BOSS_PH_2', 'FAZ   I   [ II ]   III'),
 ('BOSS_PH_3', 'FAZ   I   II   [ III ]'),
 ('BOSS_PH_RAGE', 'FAZ   I   II   [ III ]   OFKE'),
 ('WAITING_PLAYERS', 'OYUNCU BEKLENIYOR   ( %d / 2 )'),
 ('COUNTDOWN', 'SALGIN   %d   SANIYE ICINDE'),
 ('NMODE_HUD', 'BOMBA MODU  ::  %s^n(degistirmek icin sag tik)'),
 ('LM_HINT_HUD', 'V  =  LAZER KUR      C  =  LAZER SOK'),
 ('PLAN_5', '^1Bu haritada yuklu bosslar: ^3%s'),
 ('BOSSINFO_TITLE', '^1Bu haritanin bosslari (karisik sirayla gelirler):'),
 ('THEME_0', 'Vexmira'),
]

# Sohbet etiketi kategorisi (eklentideki ChatTag ile ayni kural)
def category(k):
    if k.startswith('BOSS') or k.startswith('BSK') or k.startswith('FINAL_BOSS'):
        return 'BOSS'
    if k.startswith('EV_') or k.startswith('EVENT') or k.startswith('STORM') or k.startswith('BLACKOUT') \
       or k.startswith('SPEED') or k.startswith('METEOR') or k.startswith('GOLD'):
        return 'EVENT'
    if k.startswith('VIP') or k.startswith('ELITE'):
        return 'VIP'
    if k.startswith('ADM'):
        return 'ADMIN'
    return 'VEX'

GENERIC = re.compile(r'^\^[1-4]\[(i|!|\+|\*|>|\?)\] ?')
def clean_chat(k, v):
    # yalnizca sohbet satirlari (renk kodu ile baslayanlar)
    if not v.startswith('^'):
        return v
    cat = category(k)
    m = re.match(r'^\^[1-4]\[([A-Z]+)\] ?', v)
    if m and m.group(1) == cat and cat != 'VEX':
        v = v[m.end():]
    else:
        v = GENERIC.sub('', v, count=1)
    if v and not v.startswith('^'):
        v = '^1' + v
    return v

def apply(sec_name, pairs):
    global lines
    start = lines.index('[%s]' % sec_name)
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if lines[i].startswith('['):
            end = i
            break
    want = dict(pairs)
    seen = set()
    for i in range(start + 1, end):
        m = re.match(r'^(\w+) = (.*)$', lines[i])
        if not m:
            continue
        k, v = m.groups()
        if k in want:
            v = want[k]
            seen.add(k)
        nv = clean_chat(k, v)
        lines[i] = '%s = %s' % (k, nv)
    add = ['%s = %s' % (k, v) for k, v in pairs if k not in seen]
    # sona (bir sonraki bolumden once) ekle
    ins = end
    while ins > start + 1 and lines[ins - 1].strip() == '':
        ins -= 1
    lines[ins:ins] = add

apply('en', EN)
apply('tr', TR)
open(P, 'w', encoding='utf-8').write('\n'.join(lines))

# Parite kontrolu
def keys(sec):
    s = '\n'.join(lines)
    a = s.index('[%s]' % sec)
    b = s.find('\n[', a + 1)
    body = s[a:b if b != -1 else len(s)]
    return set(re.findall(r'^(\w+) = ', body, re.M))
en, tr = keys('en'), keys('tr')
print('en', len(en), 'tr', len(tr), 'only_en', sorted(en - tr)[:10], 'only_tr', sorted(tr - en)[:10])
