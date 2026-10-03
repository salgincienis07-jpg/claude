# Part C (v3.0 harita oylamasi / RTV / admin): vexmira_zombie.txt [en] + [tr] anahtarlari.
# Tekrar calistirilabilir: var olan anahtar guncellenir, yoksa bolumun sonuna eklenir.
import re
P = '/home/user/claude/cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt'
lines = open(P, encoding='utf-8').read().split('\n')

EN = [
    ('MAPV_START', '^3%s^1 started the ^4next map vote^1! You have ^4%d^1 seconds - press the number of your map.'),
    ('MAPV_START_HUD', 'NEXT MAP VOTE^nPick the next map from the menu'),
    ('MAPV_TITLE', 'Next Map Vote'),
    ('MAPV_LEFT', 'Ends in \\r%d s\\d  |  votes: \\w%d'),
    ('MAPV_EXTEND', 'Extend this map (+%d rounds)'),
    ('MAPV_STAY', 'Stay on this map'),
    ('MAPV_NOTE', 'You can change your vote. Tie = random. Bots do not vote.'),
    ('MAPV_CAST', '^3%s^1 voted for ^4%s'),
    ('MAPV_RECAST', '^3%s^1 changed the vote to ^4%s'),
    ('MAPV_RESULT', '^1Next map: ^4%s^1 with ^4%d^1 votes (^4%d%%^1).'),
    ('MAPV_RESULT_HUD', 'NEXT MAP^n%s'),
    ('MAPV_NOVOTES', '^1Nobody voted - the next map was picked at random: ^4%s'),
    ('MAPV_EXTENDED', '^1The map was ^4extended by %d rounds^1! The next vote comes before the new last round.'),
    ('MAPV_EXTENDED_HUD', 'MAP EXTENDED^n+%d rounds'),
    ('MAPV_STAYED', '^1The vote decided to ^4stay on this map^1 (^4%d^1 votes).'),
    ('MAPV_STAYED_HUD', 'WE STAY ON THIS MAP'),
    ('MAPV_NONE', '^1No other map of the pool is installed on this server, so there is nothing to vote for.'),
    ('MAPV_ONLY', '^1Only one map is available, so it is next: ^4%s'),
    ('MAPV_ROUNDEND', '^1The map changes to ^4%s^1 when this round ends.'),
    ('MAPV_CHANGING', '^1Changing map to ^4%s^1 ...'),
    ('MAPV_CHANGING_HUD', 'NEXT MAP: %s^nSee you there!'),
    ('MAPV_NEXT_IS', '^1Next map: ^4%s^1 (after the last round).'),
    ('MAPV_NEXT_NOW', '^1Next map: ^4%s^1 (changes at the end of this round).'),
    ('MAPV_NEXT_VOTE', '^1The next map is chosen by vote in round ^4%d^1 of ^4%d^1. Type ^4/maps^1 for the list.'),
    ('MAPV_NEXT_CYCLE', '^1Next map: ^4%s'),
    ('MAPV_LIST_HDR', '^1Map pool (^4%d^1 rounds left on this map):'),
    ('MAPV_LIST_KEY', '^3*^1 = current map, ^4>^1 = next map, ^1(-) = not installed. Type ^4/rtv^1 to rock the vote.'),
    ('RTV_OFF', '^1Rock the vote is disabled on this server.'),
    ('RTV_CHANGING', '^1The map is already changing to ^4%s^1.'),
    ('RTV_DECIDED', '^1The next map is already decided: ^4%s^1. It comes after the last round.'),
    ('RTV_TOO_EARLY', '^1Rock the vote opens in round ^4%d^1.'),
    ('RTV_MINPL', '^1Rock the vote needs at least ^4%d^1 players.'),
    ('RTV_ALREADY', '^1You already rocked the vote (^4%d^1/^4%d^1).'),
    ('RTV_ROCKED', '^3%s^1 wants to change the map! ^4%d^1/^4%d^1 - type ^4rtv^1 to join.'),
    ('RTV_START', '^1Enough players rocked the vote - the ^4map vote^1 starts now!'),
    ('ADMM_20', 'Map vote (winner comes after this round)'),
    ('ADM_MAPVOTE', '^4%s^1 started a ^4map vote^1 (^4%d^1 options).'),
    ('ADM_MAPVOTE_CANCEL', '^4%s^1 cancelled the map vote.'),
    ('MAPDESC_zm_vex_laboratory', '(bio lab)'),
    ('MAPDESC_zm_vex_harbor', '(night harbor)'),
    ('MAPDESC_zm_vex_ruins', '(ruined city)'),
    ('MAPDESC_zm_vex_frostbase', '(frost base)'),
    ('MAPDESC_zm_vex_temple', '(boss temple)'),
]
TR = [
    ('MAPV_START', '^3%s^1 ^4sonraki harita oylamasini^1 baslatti! ^4%d^1 saniyen var - haritanin numarasina bas.'),
    ('MAPV_START_HUD', 'HARITA OYLAMASI^nMenuden sonraki haritayi sec'),
    ('MAPV_TITLE', 'Sonraki Harita Oylamasi'),
    ('MAPV_LEFT', 'Bitmesine \\r%d sn\\d  |  oy: \\w%d'),
    ('MAPV_EXTEND', 'Bu haritayi uzat (+%d round)'),
    ('MAPV_STAY', 'Bu haritada kal'),
    ('MAPV_NOTE', 'Oyunu degistirebilirsin. Esitlik = rastgele. Botlar oy vermez.'),
    ('MAPV_CAST', '^3%s^1 oyunu ^4%s^1 icin kullandi'),
    ('MAPV_RECAST', '^3%s^1 oyunu ^4%s^1 olarak degistirdi'),
    ('MAPV_RESULT', '^1Sonraki harita: ^4%s^1, ^4%d^1 oyla (^4%%%d^1).'),
    ('MAPV_RESULT_HUD', 'SONRAKI HARITA^n%s'),
    ('MAPV_NOVOTES', '^1Kimse oy vermedi - sonraki harita rastgele secildi: ^4%s'),
    ('MAPV_EXTENDED', '^1Harita ^4%d round uzatildi^1! Yeni son roundan once tekrar oylanacak.'),
    ('MAPV_EXTENDED_HUD', 'HARITA UZATILDI^n+%d round'),
    ('MAPV_STAYED', '^1Oylama sonucu ^4bu haritada kaliyoruz^1 (^4%d^1 oy).'),
    ('MAPV_STAYED_HUD', 'BU HARITADA KALIYORUZ'),
    ('MAPV_NONE', '^1Havuzdaki diger haritalar bu sunucuda yuklu degil, oylanacak harita yok.'),
    ('MAPV_ONLY', '^1Tek uygun harita var, sonraki harita o: ^4%s'),
    ('MAPV_ROUNDEND', '^1Bu round bitince harita ^4%s^1 olacak.'),
    ('MAPV_CHANGING', '^1Harita ^4%s^1 olarak degisiyor ...'),
    ('MAPV_CHANGING_HUD', 'SONRAKI HARITA: %s^nOrada gorusuruz!'),
    ('MAPV_NEXT_IS', '^1Sonraki harita: ^4%s^1 (son roundan sonra).'),
    ('MAPV_NEXT_NOW', '^1Sonraki harita: ^4%s^1 (bu round bitince).'),
    ('MAPV_NEXT_VOTE', '^1Sonraki harita ^4%d^1. roundda oylamayla secilir (toplam ^4%d^1). Liste icin ^4/haritalar^1 yaz.'),
    ('MAPV_NEXT_CYCLE', '^1Sonraki harita: ^4%s'),
    ('MAPV_LIST_HDR', '^1Harita havuzu (bu haritada ^4%d^1 round kaldi):'),
    ('MAPV_LIST_KEY', '^3*^1 = su anki harita, ^4>^1 = sonraki harita, ^1(-) = sunucuda yok. Harita degisimi icin ^4/rtv^1 yaz.'),
    ('RTV_OFF', '^1Bu sunucuda harita degistirme oylamasi (RTV) kapali.'),
    ('RTV_CHANGING', '^1Harita zaten ^4%s^1 olarak degisiyor.'),
    ('RTV_DECIDED', '^1Sonraki harita zaten belli: ^4%s^1. Son roundan sonra gelecek.'),
    ('RTV_TOO_EARLY', '^1RTV ^4%d^1. roundda acilir.'),
    ('RTV_MINPL', '^1RTV icin en az ^4%d^1 oyuncu gerekli.'),
    ('RTV_ALREADY', '^1Zaten RTV yazdin (^4%d^1/^4%d^1).'),
    ('RTV_ROCKED', '^3%s^1 haritayi degistirmek istiyor! ^4%d^1/^4%d^1 - katilmak icin ^4rtv^1 yaz.'),
    ('RTV_START', '^1Yeterli oyuncu RTV yazdi - ^4harita oylamasi^1 basliyor!'),
    ('ADMM_20', 'Harita oylamasi (kazanan bu round sonunda gelir)'),
    ('ADM_MAPVOTE', '^4%s^1 ^4harita oylamasi^1 baslatti (^4%d^1 secenek).'),
    ('ADM_MAPVOTE_CANCEL', '^4%s^1 harita oylamasini iptal etti.'),
    ('MAPDESC_zm_vex_laboratory', '(biyo laboratuvar)'),
    ('MAPDESC_zm_vex_harbor', '(gece limani)'),
    ('MAPDESC_zm_vex_ruins', '(yikik sehir)'),
    ('MAPDESC_zm_vex_frostbase', '(karli us)'),
    ('MAPDESC_zm_vex_temple', '(boss tapinagi)'),
]

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
        if m and m.group(1) in want:
            lines[i] = '%s = %s' % (m.group(1), want[m.group(1)])
            seen.add(m.group(1))
    add = ['%s = %s' % (k, v) for k, v in pairs if k not in seen]
    ins = end
    while ins > start + 1 and lines[ins - 1].strip() == '':
        ins -= 1
    lines[ins:ins] = add

assert [k for k, _ in EN] == [k for k, _ in TR]
for k, v in TR:
    assert all(ord(c) < 128 for c in v), k
apply('en', EN)
apply('tr', TR)
open(P, 'w', encoding='utf-8').write('\n'.join(lines))

def keys(sec):
    s = '\n'.join(lines)
    a = s.index('[%s]' % sec)
    b = s.find('\n[', a + 1)
    body = s[a:b if b != -1 else len(s)]
    return re.findall(r'^(\w+) = ', body, re.M)
en, tr = keys('en'), keys('tr')
print('en', len(en), 'tr', len(tr), 'dup_en', len(en) - len(set(en)), 'dup_tr', len(tr) - len(set(tr)),
      'only_en', sorted(set(en) - set(tr))[:10], 'only_tr', sorted(set(tr) - set(en))[:10])
