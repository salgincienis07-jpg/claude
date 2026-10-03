# Vexmira lang guncelleme: mevcut anahtarlari gunceller, yenileri ekler (EN + TR)
import re, sys
P = '/home/user/claude/cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt'
lines = open(P, encoding='utf-8').read().split('\n')

# Bolumleri ayir
sections = {}
order = []
cur = None
for ln in lines:
    m = re.match(r'^\[(\w+)\]\s*$', ln)
    if m:
        cur = m.group(1)
        sections[cur] = []
        order.append(cur)
        continue
    if cur:
        sections[cur].append(ln)

def setkeys(sec, kv):
    body = sections[sec]
    idx = {}
    for i, ln in enumerate(body):
        m = re.match(r'^([A-Z0-9_]+)\s*=', ln)
        if m:
            idx[m.group(1)] = i
    added = []
    for k, v in kv:
        line = f'{k} = {v}'
        if k in idx:
            body[idx[k]] = line
        else:
            added.append(line)
    # yeni anahtarlar bolum sonuna (bos satirlardan once)
    while body and body[-1].strip() == '':
        body.pop()
    if added:
        body.append('')
        body.append('// ---- v2.0 ----')
        body.extend(added)
    body.append('')

BOSS_EN = ["BRUTE", "BANSHEE", "OVERLORD", "INFERNO", "REAPER", "FROSTLORD", "STORMCALLER", "HIVE QUEEN", "VOID"]
SK_EN = [["SEISMIC STOMP", "EARTHSHATTER", "TITAN WRATH"],
         ["SONIC LANCE", "PHANTOM SHRIEK", "REQUIEM"],
         ["BONE PRISON", "RAISE LEGION", "DEATH NOVA"],
         ["FLAME BREATH", "FIRE PILLARS", "SUPERNOVA"],
         ["SHADOW STEP", "SOUL CHAINS", "DEATH'S MARK"],
         ["ICE SHARDS", "GLACIAL TOMB", "ABSOLUTE ZERO"],
         ["BALL LIGHTNING", "THUNDER DASH", "TEMPEST"],
         ["ACID SPIT", "TOXIC CLOUD", "HATCHERY"],
         ["VOID BOLT", "SINGULARITY", "EVENT HORIZON"]]
SK_TR = [["SISMIK EZME", "YER YARIGI", "TITAN OFKESI"],
         ["SES MIZRAGI", "HAYALET CIGLIGI", "AGIT"],
         ["KEMIK HAPSI", "LEJYON", "OLUM NOVASI"],
         ["ALEV NEFESI", "ATES SUTUNLARI", "SUPERNOVA"],
         ["GOLGE ADIMI", "RUH ZINCIRLERI", "OLUM ISARETI"],
         ["BUZ PARCALARI", "BUZ MEZARI", "MUTLAK SIFIR"],
         ["TOP YILDIRIM", "YILDIRIM ATILMASI", "KASIRGA"],
         ["ASIT TUKURUGU", "ZEHIR BULUTU", "KULUCKA"],
         ["BOSLUK OKU", "TEKILLIK", "OLAY UFKU"]]
TIP_EN = [["Everyone around it is thrown into the air!", "Eruptions are marching toward you - step aside!", "6 seconds of fury - run, don't fight up close!"],
          ["A sonic wave in front of her - get out of her sight!", "She appears BEHIND someone and screams!", "5 waves of wailing - the whole map bleeds!"],
          ["Someone is locked in a bone cage!", "The fallen rise and your life is drained!", "3 rings of death spread out - stay between them!"],
          ["A cone of fire in front of it - flank it!", "Fire bursts from under your feet - MOVE!", "It is charging a huge blast - RUN FAR AWAY!"],
          ["It vanished... and its next hit is DOUBLE!", "Chained! Run away to break the chain!", "Everyone is marked - leave your spot NOW!"],
          ["A fan of ice spears - take cover!", "Someone is frozen solid!", "Keep moving or you will freeze!"],
          ["A ball of lightning drifts - stay away from it!", "It dashes like a lightning bolt!", "Lightning strikes the marked circles!"],
          ["Acid incoming - avoid the green pools!", "A toxic cloud surrounds her - keep distance!", "Shoot the eggs before they hatch!"],
          ["A void bolt pulls its victim in!", "A black hole opens - run out of the circle!", "Darkness falls and everything is pulled in!"]]
TIP_TR = [["Etrafindaki herkes havaya ucuyor!", "Patlamalar sana dogru ilerliyor - yana kac!", "6 saniyelik ofke - kac, yakin dovusme!"],
          ["Onundeki herkese ses dalgasi - gorus alanindan cik!", "Birinin ARKASINDA belirip ciglik atiyor!", "5 feryat dalgasi - tum harita kanar!"],
          ["Biri kemik kafese kilitlendi!", "Dusenler diriliyor, canin emiliyor!", "3 olum halkasi yayiliyor - aralarinda kal!"],
          ["Onune ates puskurtuyor - yanindan dolas!", "Ayaginin altindan ates fiskiriyor - KIPIRDA!", "Dev bir patlama hazirliyor - COK UZAGA KAC!"],
          ["Kayboldu... sonraki vurusu CIFT hasar!", "Zincirlendin! Kopartmak icin uzaklas!", "Herkes isaretlendi - HEMEN yerinden ayril!"],
          ["Yelpaze seklinde buz mizraklari - siper al!", "Biri buz kesti!", "Durma, durursan donarsin!"],
          ["Bir yildirim topu suzuluyor - uzak dur!", "Yildirim gibi atiliyor!", "Yildirim isaretli halkalara dusuyor!"],
          ["Asit geliyor - yesil havuzlardan uzak dur!", "Etrafi zehirli bulut - mesafeni koru!", "Yumurtalari catlamadan vur!"],
          ["Bosluk oku kurbanini kendine ceker!", "Kara delik acildi - halkadan disari kos!", "Karanlik coktu, her sey icine cekiliyor!"]]
INFO_EN = ["Keep your distance!", "Don't stand in front of her!", "Kill it before its army grows!", "Never stand still!",
           "It hunts the weakest!", "Keep moving!", "Break line of sight!", "Burn the eggs!", "Don't get pulled in!"]
INFO_TR = ["Mesafeni koru!", "Onunde durma!", "Ordusu buyumeden indir!", "Asla yerinde durma!",
           "En zayifi avlar!", "Hep hareket et!", "Gorus hattini kir!", "Yumurtalari yak!", "Icine cekilme!"]

en, tr = [], []
for b in range(9):
    for p in range(3):
        en.append((f'BSK_{b}_{p+1}', SK_EN[b][p]))
        tr.append((f'BSK_{b}_{p+1}', SK_TR[b][p]))
        en.append((f'BSKT_{b}_{p+1}', TIP_EN[b][p]))
        tr.append((f'BSKT_{b}_{p+1}', TIP_TR[b][p]))
    en.append((f'BOSS_INFO_{b}', f'^4[BOSS] ^3{BOSS_EN[b]}^1 - [R]: ^4{SK_EN[b][0]}^1 > ^4{SK_EN[b][1]}^1 > ^3{SK_EN[b][2]}^1. {INFO_EN[b]}'))
    tr.append((f'BOSS_INFO_{b}', f'^4[BOSS] ^3{BOSS_EN[b]}^1 - [R]: ^4{SK_TR[b][0]}^1 > ^4{SK_TR[b][1]}^1 > ^3{SK_TR[b][2]}^1. {INFO_TR[b]}'))

ADMM_EN = ["Next round: choose MODE", "Start a MODE now (round restarts)", "Next round: choose EVENT", "Start an EVENT now (round restarts)",
           "Next round: choose BOSS", "Summon a BOSS now (round restarts)", "Player actions", "Weather / light NOW",
           "Start mode vote", "Start event vote", "Restart round", "End round: HUMANS win", "End round: ZOMBIES win",
           "Drop a supply crate now", "Give every human grenades + lasers", "Give everyone 50 AP", "Zombie respawn",
           "Laser mines", "Reload vexmira.cfg"]
ADMM_TR = ["Sonraki round: MOD sec", "Bir MODU simdi baslat (round yenilenir)", "Sonraki round: EVENT sec", "Bir EVENTI simdi baslat (round yenilenir)",
           "Sonraki round: BOSS sec", "Simdi BOSS cagir (round yenilenir)", "Oyuncu islemleri", "Hava durumu / isik (hemen)",
           "Mod oylamasi baslat", "Event oylamasi baslat", "Roundu yeniden baslat", "Roundu bitir: INSANLAR kazansin", "Roundu bitir: ZOMBILER kazansin",
           "Hemen hava ikmali indir", "Tum insanlara bomba + lazer ver", "Herkese 50 AP ver", "Zombi geri donusu",
           "Lazer mayinlari", "vexmira.cfg dosyasini yenile"]
for i in range(19):
    en.append((f'ADMM_{i+1}', ADMM_EN[i]))
    tr.append((f'ADMM_{i+1}', ADMM_TR[i]))
ADME_EN = ["Reset (round default)", "Clear day", "Dusk", "Night", "Rain", "Snow", "Thick fog", "Storm", "Blood red", "Pitch black"]
ADME_TR = ["Sifirla (roundun varsayilani)", "Acik gunduz", "Alacakaranlik", "Gece", "Yagmur", "Kar", "Yogun sis", "Firtina", "Kan kirmizi", "Zifiri karanlik"]
for i in range(10):
    en.append((f'ADME_{i}', ADME_EN[i]))
    tr.append((f'ADME_{i}', ADME_TR[i]))
for k, e, t in [(13, "Make Assassin", "Assassin yap"), (14, "Make Sniper", "Sniper yap"), (15, "Give +3 laser mines", "+3 lazer mayini ver"),
                (16, "Give all grenades", "Tum bombalari ver"), (17, "Freeze for 5 s", "5 sn dondur")]:
    en.append((f'ADMA_{k}', e))
    tr.append((f'ADMA_{k}', t))

common = [
 ('ADM_AIRDROP', '^3[ADMIN] ^4%s^1 called in a ^4supply drop^1!', '^3[ADMIN] ^4%s^1 bir ^4hava ikmali^1 indirdi!'),
 ('ADM_END_HUMANS', '^3[ADMIN] ^4%s^1 ended the round: ^4HUMANS WIN^1.', '^3[ADMIN] ^4%s^1 roundu bitirdi: ^4INSANLAR KAZANDI^1.'),
 ('ADM_END_ZOMBIES', '^3[ADMIN] ^4%s^1 ended the round: ^3ZOMBIES WIN^1.', '^3[ADMIN] ^4%s^1 roundu bitirdi: ^3ZOMBILER KAZANDI^1.'),
 ('ADM_ENV_SET', '^3[ADMIN] ^4%s^1 changed the weather / light (preset ^4#%d^1).', '^3[ADMIN] ^4%s^1 hava durumunu / isigi degistirdi (^4#%d^1).'),
 ('ADM_GAVE_NADES', '^3[ADMIN] ^4%s^1 gave every human ^4all grenades + lasers^1!', '^3[ADMIN] ^4%s^1 tum insanlara ^4butun bombalari + lazerleri^1 verdi!'),
 ('ADM_LASER_ON', '^3[ADMIN] ^4%s^1 turned laser mines ^4ON^1.', '^3[ADMIN] ^4%s^1 lazer mayinlarini ^4ACTI^1.'),
 ('ADM_LASER_OFF', '^3[ADMIN] ^4%s^1 turned laser mines ^3OFF^1.', '^3[ADMIN] ^4%s^1 lazer mayinlarini ^3KAPATTI^1.'),
 ('ADM_NEXT_BOSS', '^3[ADMIN] ^4%s^1 set the next round to a ^3BOSS^1 (^4#%d^1, -1 = random).', '^3[ADMIN] ^4%s^1 sonraki roundu ^3BOSS^1 yapti (^4#%d^1, -1 = rastgele).'),
 ('ADM_NOW_BOSS', '^3[ADMIN] ^4%s^1 is summoning a ^3BOSS^1 right now (^4#%d^1)!', '^3[ADMIN] ^4%s^1 simdi bir ^3BOSS^1 cagiriyor (^4#%d^1)!'),
 ('ADM_NOW_EVENT', '^3[ADMIN] ^4%s^1 is starting event ^4#%d^1 right now!', '^3[ADMIN] ^4%s^1 ^4#%d^1 numarali eventi simdi baslatiyor!'),
 ('ADM_NOT_ACTIVE', '^3[!] ^1There is no active round right now.', '^3[!] ^1Su an aktif bir round yok.'),
 ('ADM_RELOADED', '^3[ADMIN] ^4%s^1 reloaded ^4vexmira.cfg^1 (^4%d^1 lines).', '^3[ADMIN] ^4%s^1 ^4vexmira.cfg^1 dosyasini yeniledi (^4%d^1 satir).'),
 ('AFK_WARN', '^3[AFK] ^1Move! You will be moved to spectators in ^4%d^1 seconds.', '^3[AFK] ^1Kipirda! ^4%d^1 saniye icinde izleyiciye alinacaksin.'),
 ('AFK_MOVED', '^3[AFK] ^3%s^1 was moved to spectators (AFK).', '^3[AFK] ^3%s^1 izleyiciye alindi (AFK).'),
 ('AFK_KICKED', '^3[AFK] ^3%s^1 was kicked (AFK).', '^3[AFK] ^3%s^1 sunucudan atildi (AFK).'),
 ('NEM_RAGE_YOU', 'RAGE!^nFaster and tougher for a few seconds', 'OFKE!^nBirkac saniye daha hizli ve dayanikli'),
 ('NEM_RAGE_ALL', '^3[!] ^1The ^3NEMESIS %s^1 is in a ^3RAGE^1! Keep your distance!', '^3[!] ^3NEMESIS %s^1 ^3OFKELENDI^1! Uzak durun!'),
 ('ASN_VEIL_YOU', 'SHADOW VEIL!^nYou are almost invisible', 'GOLGE PERDESI!^nNeredeyse gorunmezsin'),
 ('ROLE_BOSS_KEYS', '^4[BOSS] ^1Keys: ^4[R]^1 = phase skill (a new one every phase), ^4[F]^1 (flashlight) = leap. Your attacks grow stronger every phase!', '^4[BOSS] ^1Tuslar: ^4[R]^1 = faz yetenegi (her fazda yenisi gelir), ^4[F]^1 (fener) = atilma. Her fazda saldirilarin guclenir!'),
 ('ROLE_BOSS_YOU', '^3[!] ^1You are the ^3BOSS^1! ^4[R]^1 = special skill, ^4[F]^1 = leap.', '^3[!] ^1BOSS ^3sensin^1! ^4[R]^1 = ozel yetenek, ^4[F]^1 = atilma.'),
 ('ROLE_NEMESIS_YOU', 'YOU ARE THE NEMESIS - ONE HIT KILLS^n[R] leap     [F] rage', 'NEMESIS SENSIN - TEK VURUSTA OLDURURSUN^n[R] atilma     [F] ofke'),
 ('ROLE_ASSASSIN_YOU', 'YOU ARE THE ASSASSIN - ONE HIT KILLS^n[R] leap     [F] shadow veil', 'ASSASSIN SENSIN - TEK VURUSTA OLDURURSUN^n[R] atilma     [F] golge perdesi'),
 ('BSK_BUSY', 'A skill is already active!', 'Zaten bir yetenek aktif!'),
 ('BSK_NO_TARGET', 'No target in range!', 'Menzilde hedef yok!'),
 ('BSK_FIRST_SKILL', '^4[BOSS] ^1Your first ^4[R]^1 skill: ^3%s^1. New skills unlock at ^460%%^1 and ^430%%^1 health!', '^4[BOSS] ^1Ilk ^4[R]^1 yetenegin: ^3%s^1. Can ^4%%60^1 ve ^4%%30^1 olunca yeni yetenekler acilir!'),
 ('BSK_UNLOCK_ALL', '^3[BOSS] ^3%s^1 learned a new skill: ^3%s^1 (phase ^4%d^1)!', '^3[BOSS] ^3%s^1 yeni bir yetenek ogrendi: ^3%s^1 (faz ^4%d^1)!'),
 ('BSK_UNLOCK_YOU', 'NEW [R] SKILL!^n%s', 'YENI [R] YETENEGI!^n%s'),
 ('BSK_PRISON_YOU', 'BONE PRISON! You are trapped!', 'KEMIK HAPSI! Kafese kilitlendin!'),
 ('BSK_EMPOWER', 'Your next hit deals DOUBLE damage!', 'Sonraki vurusun CIFT hasar!'),
 ('BSK_CHAINED', 'SOUL CHAINS! Run away to break them!', 'RUH ZINCIRI! Kopartmak icin uzaklas!'),
 ('BSK_CHAIN_BROKEN', '^4[+] ^1You broke the ^3soul chain^1!', '^4[+] ^3Ruh zincirini^1 kopardin!'),
 ('BSK_MARKED', "DEATH'S MARK! Move away from your spot!", 'OLUM ISARETI! Yerinden hemen ayril!'),
 ('BSK_TOMB_YOU', 'GLACIAL TOMB! You are frozen!', 'BUZ MEZARI! Dondun!'),
 ('BSK_ZERO_TIP', 'ABSOLUTE ZERO! Keep moving or you will freeze!', 'MUTLAK SIFIR! Durma, durursan donarsin!'),
 ('BSK_EGGS_TIP', 'EGGS! Shoot them before they hatch!', 'YUMURTALAR! Catlamadan vurun!'),
 ('BSK_PULLED', 'VOID BOLT! You are being pulled in!', 'BOSLUK OKU! Icine cekiliyorsun!'),
 ('HUD_ACTIVE', 'ACTIVE', 'AKTIF'),
 ('HUD_READY', 'READY', 'HAZIR'),
 ('HUD_SECONDS', '%d s', '%d sn'),
 ('HUD_BOSS_R', '[R] %s : %s   |   [F] Leap : %s', '[R] %s : %s   |   [F] Atilma : %s'),
 ('HUD_NEM_RF', '[R] Leap : %s   |   [F] Rage : %s', '[R] Atilma : %s   |   [F] Ofke : %s'),
 ('HUD_ASN_RF', '[R] Leap : %s   |   [F] Shadow Veil : %s', '[R] Atilma : %s   |   [F] Golge : %s'),
 ('HUD_DROP_COMPASS', 'SUPPLY CRATE : %d m   %s', 'IKMAL KUTUSU : %d m   %s'),
 ('LM_AIM_INFO_MINE', 'YOUR LASER  [ %s ]^nHP %d / %d     C = pick up', 'SENIN LAZERIN  [ %s ]^nCAN %d / %d     C = sok'),
 ('LM_GIFT', '^4[LASER] ^1You received ^4+%d^1 laser mines!', '^4[LASER] ^4+%d^1 lazer mayini aldin!'),
 ('LM_INFO_1', '^4[LASER] ^1Every round each human gets ^4%d^1 laser mines for FREE (no AP).', '^4[LASER] ^1Her round her insana ^4%d^1 lazer mayini BEDAVA verilir (AP yok).'),
 ('LM_INFO_2', '^4[LASER] ^4V^1 = plant on the wall you aim at.  ^4C^1 = pick it up instantly (back to your bag).', '^4[LASER] ^4V^1 = baktigin duvara kur.  ^4C^1 = aninda sok (cantana geri doner).'),
 ('LM_INFO_3', '^4[LASER] ^1Any zombie that touches the beam ^3dies instantly^1. Zombies can claw the mine to break it.', '^4[LASER] ^1Isina degen zombi ^3aninda olur^1. Zombiler pencesiyle mayini kirabilir.'),
 ('LM_M_INFO', 'How it works', 'Nasil calisir'),
 ('LM_M_RULE', 'Free %d lasers every round - no AP needed', 'Her round %d lazer bedava - AP gerekmez'),
 ('LM_WORN_OUT', '^3[LASER] ^1One of your lasers burned out after too many kills.', '^3[LASER] ^1Lazerlerinden biri cok oldurmekten yandi.'),
 ('LM_NO_MINE', '^4[LASER] ^1You used all your lasers this round (^4%d^1 per round). Pick one up with ^4C^1 to move it.', '^4[LASER] ^1Bu roundki tum lazerlerini kullandin (round basina ^4%d^1). Yerini degistirmek icin ^4C^1 ile sok.'),
 ('LM_HINT', '^4[LASER] ^1You have ^4%d^1 free laser mines! Aim at a wall and press ^4V^1. ^4C^1 = pick up.', '^4[LASER] ^4%d^1 bedava lazer mayinin var! Duvara bak ve ^4V^1 tusuna bas. ^4C^1 = sok.'),
 ('LM_PLANTED', '^4[LASER] ^1Laser planted! It arms in a moment. ^4(%d left)', '^4[LASER] ^1Lazer kuruldu! Birazdan aktif olur. ^4(%d kaldi)'),
 ('LM_BIND_HINT', '^4[LASER] ^4V^1 = plant, ^4C^1 = pick up (C works without binding). Console: ^4bind v +setlaser', '^4[LASER] ^4V^1 = kur, ^4C^1 = sok (C icin bind gerekmez). Konsol: ^4bind v +setlaser'),
 ('NMODE_DESC_2', '^4[Sensor] ^1lands and arms (beep), explodes only when a zombie comes in range AND in sight', '^4[Sensor] ^1yere oturur ve kurulur (bip), sadece zombi menzile VE gorus hattina girince patlar'),
 ('NMODE_DESC_3', '^4[Laser Trap] ^1sticks to the wall / floor it hits, draws a laser, explodes ON the zombie that crosses it', '^4[Lazer Tuzak] ^1carptigi duvara / zemine yapisir, lazer ceker, lazeri kesen zombinin USTUNDE patlar'),
 ('SHOP_EXCHANGE', 'Exchange %d AP -> 1 VC', 'Takas: %d AP -> 1 VC'),
 ('SHOP_EXCHANGED', '^4[$] ^1Exchanged your AP for ^41 VC^1.', '^4[$] ^1AP takas edildi: ^4+1 VC^1.'),
 ('HELP_2', '^4[?] ^3ZOMBIES:^1 claw humans to infect them. ^4[R]^1 = class ability. Bosses: ^4[R]^1 skill, ^4[F]^1 leap.', '^4[?] ^3ZOMBILER:^1 pencenle vur, enfekte et. ^4[R]^1 = sinif yetenegi. Boss: ^4[R]^1 yetenek, ^4[F]^1 atilma.'),
 ('MODE_DESC_2', '^4[Nemesis] ^1One huge zombie that ^3kills in ONE hit^1. [R] leap, [F] rage.', '^4[Nemesis] ^1TEK VURUSTA ^3olduren^1 dev zombi. [R] atilma, [F] ofke.'),
 ('MODE_DESC_3', '^4[Assassin] ^1A very fast zombie that ^3kills in ONE hit^1, hunting in the dark.', '^4[Assassin] ^1Karanlikta avlanan, TEK VURUSTA ^3olduren^1 cok hizli zombi.'),
 ('MODE_DESC_9', '^4[BOSS] ^13 phases, 5 skills: a NEW [R] skill every phase. Watch the colored circles!', '^4[BOSS] ^13 faz, 5 yetenek: her fazda YENI bir [R] yetenegi. Renkli halkalara dikkat!'),
 ('AIRDROP_HUD', 'SUPPLY DROP INCOMING!^nFollow the GOLDEN BEAM', 'HAVA IKMALI GELIYOR!^nALTIN ISIK SUTUNUNU takip et'),
 ('ADV_17', '^4[i] ^1Every round you get ^43 free laser mines^1: ^4V^1 = plant, ^4C^1 = pick up. Zombies that touch the beam die!', '^4[i] ^1Her round ^43 bedava lazer^1: ^4V^1 = kur, ^4C^1 = sok. Isina degen zombi olur!'),
 ('ADV_19', '^4[i] ^1A ^4golden beam^1 in the sky = ^4supply drop^1. Your HUD shows the distance and direction!', '^4[i] ^1Gokyuzune uzanan ^4altin isik^1 = ^4hava ikmali^1. Mesafe ve yon HUD\'da yazar!'),
 ('ADV_23', '^4[i] ^1Bosses learn a NEW ^4[R]^1 skill every phase. Always watch the colored circles on the ground!', '^4[i] ^1Bosslar her fazda YENI bir ^4[R]^1 yetenegi ogrenir. Yerdeki renkli halkalara hep dikkat et!'),
 ('ADV_24', '^4[i] ^1Every round every human gets ^4all grenades^1 automatically. Right click = grenade mode!', '^4[i] ^1Her round her insana ^4tum bombalar^1 otomatik verilir. Sag tik = bomba modu!'),
 ('ADV_25', '^4[!] ^3Nemesis^1 and ^3Assassin^1 kill in ONE hit. Keep your distance and use lasers!', '^4[!] ^3Nemesis^1 ve ^3Assassin^1 TEK VURUSTA oldurur. Mesafeni koru, lazer kullan!'),
 ('ADV_26', '^4[i] ^1Every event changes the ^4weather and light^1: rain, snow, blood moon, fog...', '^4[i] ^1Her event ^4hava durumunu ve isigi^1 degistirir: yagmur, kar, kanli ay, sis...'),
]
for k, e, t in common:
    en.append((k, e))
    tr.append((k, t))

setkeys('en', en)
setkeys('tr', tr)

out = []
for sec in order:
    out.append(f'[{sec}]')
    out.extend(sections[sec])
open(P, 'w', encoding='utf-8').write('\n'.join(out).rstrip('\n') + '\n')
print('ok', len(en), len(tr))
