# Part C (v3.0 harita oylamasi, ses yuvalari, efekt sprite'lari, ortam sesleri): vexmira.cfg guncellemesi.
# Tekrar calistirilabilir (isaretli bloklari yeniden yazar).
import re
P = '/home/user/claude/cstrike/addons/amxmodx/configs/vexmira.cfg'
cfg = open(P, encoding='utf-8').read()

# 1) Harita oylamasi bolumu: HARITA PLANI'ndaki "Mod kurallari" satirindan once
MV = '''// ---------------- HARITA OYLAMASI (v3.0) ----------------
// Haritanin sonuna dogru (vex_map_vote_round) paket haritalari arasinda oylama yapilir.
// Mevcut harita ve sunucuda olmayan haritalar (maps/<ad>.bsp) listelenmez. Menude canli oy
// sayisi + yuzde gorunur, oy degistirilebilir, botlar oy vermez, esitlikte rastgele secilir.
// Son round bitince: odul / MVP akisi -> ara ekran (skor tablosu) -> oylanan harita.
// Sohbet: /nextmap (/sonrakiharita)  /maps (/haritalar)  /rtv (/haritadegis) ya da sadece "rtv".
// Admin: konsol "vex_mapvote" (kazanan harita bu round sonunda), "vex_mapvote next" (sadece
// sonraki haritayi belirler), "vex_mapvote cancel"; admin menusu (/admin) 20. secenek.
// ONEMLI: AMXX'in mapchooser.amxx eklentisi plugins.ini'den kaldirilmali (cift oylama olur).
// Yuklu kalirsa vex_map_vote_mapchooser 1 iken bu eklenti onu otomatik duraklatir.
vex_map_vote           1             // 1 = harita oylamasi + RTV acik (0 = kapali, oyunun kendi dongusu)
vex_map_pool           "zm_vex_laboratory zm_vex_harbor zm_vex_ruins zm_vex_frostbase zm_vex_temple"   // oylanacak haritalar (bosluklu liste, en fazla 8 secenek)
vex_map_vote_round     0             // oylamanin yapilacagi round (0 = otomatik: son roundan bir onceki)
vex_map_vote_time      20            // oylama suresi (sn, 5-60)
vex_map_vote_extend    0             // 1 = "bu haritayi uzat" secenegi (harita basina 1 kez; RTV'de "bu haritada kal")
vex_map_extend_rounds  10            // uzatma kazanirsa eklenecek round sayisi (mp_maxrounds artar)
vex_map_change_delay   7.0           // son round bittikten kac sn sonra ara ekran (odul yazilari icin; +3.5 sn sonra harita degisir)
vex_map_vote_mapchooser 1            // 1 = mapchooser.amxx yukluyse duraklat (cift oylama olmasin), 0 = sadece uyar
vex_rtv_ratio          0.60          // RTV: insan oyuncularin bu orani "rtv" yazinca oylama baslar (0 = RTV kapali)
vex_rtv_minplayers     2             // RTV icin en az insan oyuncu
vex_rtv_minround       3             // RTV bu rounddan once kullanilamaz
mapcyclefile           "mapcycle_vexmira.txt"   // oyunun kendi harita dongusu (oylama kapaliysa / yedek): 5 paket haritasi
// ---------------- /HARITA OYLAMASI ----------------

'''
if '// ---------------- HARITA OYLAMASI (v3.0) ----------------' in cfg:
    a = cfg.index('// ---------------- HARITA OYLAMASI (v3.0) ----------------')
    b = cfg.index('// ---------------- /HARITA OYLAMASI ----------------\n\n', a) + len('// ---------------- /HARITA OYLAMASI ----------------\n\n')
    cfg = cfg[:a] + MV + cfg[b:]
else:
    i = cfg.index('// Mod kurallari: vex_mode_rule')
    cfg = cfg[:i] + MV + cfg[i:]

# 2) Precache butcesi: ses butcesi + stok ses engelleme
cfg = re.sub(r'vex_res SOUND_BUDGET[^\n]*\n',
             'vex_res SOUND_BUDGET      "200"    // eklentinin 3D ses siniri (asan sesler genel sese duser). Stok CS + botlar ~270 ses (engellemeyle)\n', cfg, count=1)
BLK = '''vex_res SOUND_BLOCK_STOCK "1"      // 1 = bu modda HIC calinmayan ~35 stok ses yuklenmez (C4/bomba, round telsizi, bot duzenleme, tutor, geiger, silah HUD)
vex_res SOUND_BLOCK_EXTRA ""       // ek engellenecek stok sesler (bosluklu liste, or. "player/pl_shot1.wav"); sadece oyunun kendi precache'i
'''
cfg = re.sub(r'vex_res SOUND_BLOCK_STOCK[^\n]*\n(vex_res SOUND_BLOCK_EXTRA[^\n]*\n)?', '', cfg)
cfg = cfg.replace('vex_res MODEL_BUDGET      "250"', BLK + 'vex_res MODEL_BUDGET      "250"', 1)
cfg = cfg.replace('// 2D sesler (anons / arayuz / muzik) ses yuvasi harcamaz (indirilir, "spk" ile calinir).\n',
                  '// 2D sesler (anons / arayuz / muzik) ses yuvasi harcamaz (indirilir, "spk" ile calinir).\n'
                  '// v3.0: boss olum / faz / alay / R yetenek sesleri ve Nemesis/Assassin olum sesi de 2D (herkes duyar).\n'
                  if '// v3.0: boss olum / faz / alay' not in cfg else
                  '// 2D sesler (anons / arayuz / muzik) ses yuvasi harcamaz (indirilir, "spk" ile calinir).\n', 1)

# 3) Efekt sprite'lari (SPR_EMP satirindan sonra)
FX = '''// v3.0 efekt sprite'lari (yoksa eski efekt / oyunun kendi sprite'i). Boss yeteneklerinde bossun
// elementine gore: Inferno ates, Frostlord buz, Hive Queen zehir, Overlord / Reaper / Void bosluk,
// Brute / Banshee / Stormcaller sok dalgasi.
vex_res SPR_EXPLO_FIRE    "sprites/vexmira/explo_fire.spr"        // ates bombasi / Inferno patlamasi
vex_res SPR_EXPLO_ICE     "sprites/vexmira/explo_ice.spr"         // buz bombasi / Frostlord
vex_res SPR_EXPLO_TOXIC   "sprites/vexmira/explo_toxic.spr"       // enfeksiyon bombasi / asit / spor
vex_res SPR_EXPLO_VOID    "sprites/vexmira/explo_void.spr"        // Void / Overlord / Reaper patlamasi
vex_res SPR_HEAL          "sprites/vexmira/heal.spr"              // iyilesme (medkit, Voodoo, Leech...)
vex_res SPR_LEVELUP       "sprites/vexmira/levelup.spr"           // level atlama
vex_res SPR_INFECT        "sprites/vexmira/infect.spr"            // enfeksiyon
vex_res SPR_SHOCK         "sprites/vexmira/shock.spr"             // sok dalgasi (Avci / Kostebek / sok bosslari)
vex_res SPR_SLASH         "sprites/vexmira/slash.spr"             // zombi pence darbesi
vex_res SPR_ICE           "sprites/vexmira/ice.spr"               // donan oyuncu / buz izi
vex_res SPR_VOID          "sprites/vexmira/void.spr"              // bosluk izi
vex_res SPR_TOXIC         "sprites/vexmira/toxic.spr"             // zehir izi
'''
cfg = re.sub(r"// v3\.0 efekt sprite'lari.*?vex_res SPR_TOXIC[^\n]*\n", '', cfg, flags=re.S)
anchor = re.search(r'vex_res SPR_EMP[^\n]*\n', cfg)
cfg = cfg[:anchor.end()] + FX + cfg[anchor.end():]

# 4) Round basi sessizlik: ortam sesleri notu
cfg = re.sub(r'vex_round_stopsound    1[^\n]*\n',
             'vex_round_stopsound    1             // 1 = yeni round basinda tum eklenti sesleri + muzik susar (haritanin dongulu ortam sesleri 0.8 sn sonra geri gelir)\n',
             cfg, count=1)

open(P, 'w', encoding='utf-8').write(cfg)
print('ok', len(cfg))
