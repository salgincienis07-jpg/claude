# Vexmira Zombie v3.0 — Ortak Tasarım Belgesi (tüm ajanlar için tek kaynak)

Bu belge v3.0 içerik üretiminin sözleşmesidir. Her ajan kendi bölümünü uygular,
başka bölümlerin dosyalarına dokunmaz. Belirsizlikte bu belgedeki isimler geçerlidir.

## 0. Kalite çıtası

- Her şey ÖZGÜN ve PROSEDÜREL üretilir (kod ile). İnternetten hazır model / ses /
  harita / doku İNDİRİLMEZ (telif). İzinli ağ: GitHub `git clone` (kaynak kod
  referansı için), PyPI `pip install`, GitHub release indirmeleri (yalnızca
  sunucu ikili dosyaları: ReHLDS / ReGameDLL / Metamod-R / ReAPI).
- Üretim kodu `devtools/` altında, tekrar çalıştırılabilir, sabit tohumlu (seed).
- Her çıktı DOĞRULANIR (format ayrıştırıcı + limit kontrolü) ve görsel çıktılar
  için önizleme PNG'si üretilir: `$SP/previews/<alan>/...`. Önizlemeye bakarak
  (Read aracı ile) kaliteyi kendin kontrol et; çirkin / bozuk ise düzelt.
- Oyun motoru limitlerine uy (GoldSrc / CS 1.6 / ReHLDS).

## 1. Yollar

- Depo: `/home/user/claude` (paket = depo). Oyun dosyaları `cstrike/...` altında.
- `$SP` = `/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad`
- Araçlar (derlenmiş, depoya girmez):
  - `$SP/tools/smdl/studiomdl` — HLSDK studiomdl Linux portu (32-bit). 16 blend'e kadar destekler.
  - `$SP/tools/sdhlt/tools/{sdHLCSG,sdHLBSP,sdHLVIS,sdHLRAD,sdRIPENT}` + `sdhlt.wad`, `lights.rad`.
  - `$SP/tools/bin/amxxpc` — AMXX derleyici; `devtools/plugin/build_plugin.sh [çıktı]`.
- Referans kaynaklar (salt okunur):
  - `$SP/tools/hlsdk` — Valve HLSDK (studio.h, studiomdl, smdlexp, activity.h).
  - `$SP/tools/cs16client` — CS 1.6 istemcisinin açık kaynak yeniden yazımı
    (oyuncu animasyon/blend/gait mantığı: `cl_dll/GameStudioModelRenderer.cpp`).
  - `$SP/tools/regamedll` — ReGameDLL_CS kaynak (sunucu: sekans adları, silah animasyon enum'ları).
- Üretim kodu: `devtools/mdlkit`, `devtools/mapkit`, `devtools/sprkit`, `devtools/sfx`,
  `devtools/server`, `devtools/plugin`, `devtools/cfggen`.
- Çıktılar:
  - Oyuncu modelleri: `cstrike/models/player/<ad>/<ad>.mdl`
  - Diğer modeller: `cstrike/models/vexmira/...` (claws/, weapons/, world/)
  - Sesler: `cstrike/sound/vexmira/...` (alt klasörler: boss/, class/, special/, hook/, map/, ui/)
  - Sprite'lar: `cstrike/sprites/vexmira/...`
  - Haritalar: `cstrike/maps/<ad>.bsp` (+ `.nav` sunucu testinden)

## 2. Ajan kuralları

- Sadece sana atanan yollara yaz. `git commit` YAPMA (ana oturum commit eder).
- Eklentiye (`vexmira_zombie.sma`) sadece eklenti ajanları dokunur.
- Bitince kısa bir RAPOR döndür: üretilen dosyalar, boyutlar, doğrulama sonuçları,
  önizleme yolları, bilinen sınırlamalar.

## 3. Oyuncu modeli kadrosu (models/player/<ad>/<ad>.mdl)

Ölçek: CS oyuncu hull'u 32x32x72; model orijini hull merkezinde (ayaklar z=-36,
çömelince ayaklar z=-18). Hitbox'lar hull içinde kalmalı (dışı vurulamaz).

### İnsanlar (CT) — silah tutar, TÜM CS silah sekansları 9-blend
| ad | tema |
|---|---|
| vex_operator | standart CT: koyu lacivert taktik üniforma, kask, gözlük, cyan şeritli Vexmira armalı |
| vex_ranger | kum/haki saha askeri, bere + bandana, sırt çantası |
| vex_hazmat | sarı-siyah koruyucu tulum, gaz maskesi, oksijen tüpü |
| vex_vip | altın-beyaz zırhlı elit, pelerin şeridi, altın vizör |
| vex_admin | siyah-kırmızı komutan, uzun palto, kırmızı parlayan vizör |
| vex_survivor | ağır zırhlı (juggernaut), omuz plakaları, yaralı/kirli |
| vex_sniper | kamuflaj pelerinli keskin nişancı, kapüşon, maske |

### Zombi sınıfları (24) — sadece bıçak (pençe); sadece bıçak sekansları 9-blend
İndeks = eklentideki sınıf no. Renk = eklentideki CLASS_RGB (yeni sınıflar için öneri).
| no | ad | model | tema / siluet | renk |
|---|---|---|---|---|
| 0 | Walker | vex_z_walker | klasik çürümüş sivil, yırtık gömlek | 0,140,0 |
| 1 | Runner | vex_z_runner | zayıf, uzun bacaklı, eşofmanlı, öne eğik koşucu | 255,140,0 |
| 2 | Tank | vex_z_tank | iri, kas yığını, metal plaka saplanmış | 40,90,255 |
| 3 | Banshee | vex_z_banshee | uzun saçlı solgun kadın hayalet, yırtık elbise | 200,200,255 |
| 4 | Leech | vex_z_leech | kırmızı damarlı, sülük ağızlı | 200,0,0 |
| 5 | Stalker | vex_z_stalker | sıska, kapüşonlu, uzun pençeli, koyu teal | 0,110,110 |
| 6 | Bomber | vex_z_bomber | şişkin karın, yeşil kabarcıklı püstüller | 120,255,0 |
| 7 | Frost | vex_z_frost | buz kristalleri saplı, mavi-beyaz donmuş ten | 0,200,255 |
| 8 | Spitter | vex_z_spitter | uzun boyun, asit salyası, sarı-yeşil | 150,255,0 |
| 9 | Hulk | vex_z_hulk | dev gövde, büyük kollar, turuncu yaralar | 255,80,0 |
| 10 | Voodoo | vex_z_voodoo | kemik kolye, maske, mor-pembe büyü dövmeleri | 255,0,180 |
| 11 | Phantom | vex_z_phantom | yarı saydam ruh, mavi-mor sis kumaş | 120,120,255 |
| 12 | Butcher | vex_z_butcher | kasap önlüğü, zincirli KANCA, iri, et kancaları | 180,30,30 |
| 13 | Hunter | vex_z_hunter | kapüşonlu, dört ayaklı çömelmiş duruş, sargılı | 90,90,110 |
| 14 | Charger | vex_z_charger | tek dev kol, omuz kalkanı gibi kemik | 200,120,60 |
| 15 | Arachne | vex_z_arachne | örümcek: sırtında 4 ekstra bacak, mor-siyah | 140,0,200 |
| 16 | Magma | vex_z_magma | kara kabuklu, çatlaklarından lav parlayan | 255,90,0 |
| 17 | Volt | vex_z_volt | sırtında akü/kablolar, elektrik mavisi damarlar | 80,180,255 |
| 18 | Mimic | vex_z_mimic | yarısı insan (asker kıyafeti) yarısı et yığını | 160,160,160 |
| 19 | Burrower | vex_z_burrower | toprak kaplı, kazıcı pençeler, kask lambası kırık | 140,100,50 |
| 20 | Siren | vex_z_siren | uzun pembe saç, parlayan gözler, ince | 255,90,200 |
| 21 | Bulwark | vex_z_bulwark | taş/kaya zırh plakaları, gri-yeşil | 120,140,120 |
| 22 | Sporemother | vex_z_sporemother | mantar/spor keseleri, yeşil-kahve | 110,200,60 |
| 23 | Nightmare | vex_z_nightmare | siyah dumanlı, çok gözlü, kırmızı göz parıltısı | 120,0,0 |

### Bosslar (9) — büyük canavarlar (görsel boy ~100-120 birim; hitbox hull içinde)
| no | ad | model | tema | renk |
|---|---|---|---|---|
| 0 | Brute | vex_b_brute | dev goril-ogre, kaya yumruklar, zincirler | 255,120,0 |
| 1 | Banshee | vex_b_banshee | süzülen hayalet kraliçe, yırtık tül, uzun pençe | 190,210,255 |
| 2 | Overlord | vex_b_overlord | kemik taçlı nekromant lord, pelerin, asa | 160,0,255 |
| 3 | Inferno | vex_b_inferno | lav iblisi, boynuzlar, alev parlayan göğüs | 255,50,0 |
| 4 | Reaper | vex_b_reaper | kapüşonlu ölüm, tırpan kol, iskelet yüz | 120,0,190 |
| 5 | Frostlord | vex_b_frostlord | buz devi, kristal taç ve omuzlar | 0,190,255 |
| 6 | Stormcaller | vex_b_stormcaller | fırtına şamanı, metal çubuklar, parlayan rünler | 255,240,80 |
| 7 | Hive Queen | vex_b_hivequeen | böcek kraliçe, kabuk, kanat parçaları, yumurta kesesi | 110,255,0 |
| 8 | Void | vex_b_void | kara delik varlığı, yüzen parçalar, mor çekirdek | 220,0,140 |
Özel: `vex_nemesis` (kırmızı-siyah mutant süper asker, dokunaçlı kol),
`vex_assassin` (siyah-mor ninja zombi, ince, uzun bıçak pençeler).

## 4. El (v_) modelleri

- Pençeler (bıçak sekans düzeni, 8 sekans; ReGameDLL `wpn_knife.cpp` enum'u):
  `cstrike/models/vexmira/claws/v_<ad>.mdl` — ad = model adındaki `vex_z_`/`vex_b_`
  sonrası (örn. `v_walker.mdl`, `v_butcher.mdl`, `v_brute.mdl`, `v_nemesis.mdl`, `v_assassin.mdl`). 35 adet.
- İnsan (aynı Vexmira CT eldiveni/kolu):
  - `models/vexmira/weapons/v_vexblade.mdl` (bıçak), `v_firebomb.mdl` (HE), `v_frostbomb.mdl` (duman),
    `v_flare.mdl` (flash). Sekans düzeni ReGameDLL enum'larına birebir uyar.
  - Özel silahlar `v_sw0..v_sw7.mdl` (taban silahların sekans düzeni): 0 Plazma (M4A1),
    1 Ejder Topu (M249), 2 Yıldırım (AWP), 3 Buz Kıran (XM1014), 4 Altın Kartal (Deagle),
    5 Cehennem SMG (P90), 6 Vex Biçici (AK47), 7 Boşluk Çağırıcı (SG550). Bilim-kurgu stil.
- p_ modelleri (insan modellerimizin "Bip01 R Hand" kemiğine isimle birleşir):
  `models/vexmira/weapons/p_<silah>.mdl` tüm standart silahlar + bıçak + bombalar + p_sw0..7.

## 5. Dünya modelleri (`models/vexmira/world/`)
lasermine.mdl (kurulum + idle animasyon, ışık lensi), supply_crate.mdl (paraşüt
bodygroup, sallanma), hive_egg.mdl (nabız + çatlama), spore_pod.mdl, hook.mdl (kanca
başı), w_firebomb.mdl, w_frostbomb.mdl, w_flare.mdl.

## 6. Sesler (WAV mono 16-bit 22050 Hz (adım/kısa sesler 11025 olabilir), DÖNGÜSÜZ — "cue" chunk YOK)
Tam dosya listesi (eklenti bu isimleri kullanır; ses ajanı bu isimlerle üretir):
- Boss (b ∈ brute, banshee, overlord, inferno, reaper, frostlord, stormcaller, hivequeen, void):
  `sound/vexmira/boss/<b>_intro.wav, <b>_idle.wav, <b>_pain1.wav, <b>_pain2.wav, <b>_death.wav,
  <b>_step.wav, <b>_attack.wav, <b>_phase.wav, <b>_kill.wav` (9 x 9 = 81). Mevcut R yetenek sesleri
  (`sound/vexmira/brute_stomp.wav` vb.) aynen kalır. Her bossun kendine has sesi: Brute=derin hırıltı/taş,
  Banshee=tiz çığlık/rüzgar, Overlord=koro/kemik, Inferno=alev/kükreme, Reaper=fısıltı/metal,
  Frostlord=buz çatlaması/derin, Storm=gök gürültüsü/elektrik, Hive=böcek tıkırtısı/vızıltı, Void=ters ses/uğultu.
- Özel: `sound/vexmira/special/nemesis_{intro,idle,pain,death,attack}.wav`,
  `sound/vexmira/special/assassin_{intro,idle,pain,death,attack}.wav`.
- Sınıf (c = sınıf model adının `vex_z_` sonrası: walker ... nightmare, 24 adet):
  `sound/vexmira/class/<c>_{pain,die,idle,ability}.wav` (96) + ek: `hunter_impact, charger_impact,
  arachne_webhit, burrower_erupt, sporemother_burst, mimic_reveal, volt_zap` (.wav, aynı klasör).
- Kanca: `sound/vexmira/hook/{throw,chain,hit,pull,miss}.wav`.
- Arayüz (2D): `sound/vexmira/ui/{vote_start,vote_end,boss_bar,menu_select,class_select}.wav`.
- Harita ortam sesleri: `sound/vexmira/map/<harita>_*.wav` (harita ajanları üretir, ambient_generic).

## 7. Sprite'lar (`sprites/vexmira/...`)
- `bossbar.spr`: boss can barı (bossun kafasının üstünde, herkes görür), 51 kare
  (kare i = %2*i doluluk), ~192x24, çok renkli (SPR_ALPHTEST, palet 255 = saydam), oyun boss barı stili
  (koyu çerçeve, altın kenar, kırmızı→turuncu dolgu, segment çizgileri).
- `bossicon.spr`: 9 kare boss amblemi (kare = boss no).
- `hpbar_small.spr`: 51 kare küçük bar (Nemesis/Assassin/Alfa zombi).
- Kafa üstü ikonlar: `icon_vip.spr`, `icon_admin.spr`, `icon_mvp.spr`, `icon_lasthuman.spr`, `icon_alpha.spr`.
- Efektler: `slash.spr`, `chain.spr` (kanca zinciri ışın dokusu), `web.spr`, `spore.spr`, `emp.spr`,
  `shock.spr` (halka), `heal.spr`, `levelup.spr`, `infect.spr`, `ice.spr`, `void.spr`, `toxic.spr`,
  `explo_fire.spr`, `explo_ice.spr`, `explo_toxic.spr`, `explo_void.spr` (çok kareli).

## 8. Haritalar (5 adet, `zm_vex_*`, özgün, gömülü dokular)
| ad | tema |
|---|---|
| zm_vex_laboratory | yeraltı biyo-laboratuvar: zehirli havuzlar, podyum köprüler, havalandırma kanalları |
| zm_vex_harbor | gece limanı: konteyner yığınları, vinç, depo, iskele, su |
| zm_vex_ruins | yıkık şehir meydanı: çatılar, merdivenler, kırık binalar, kamp noktaları |
| zm_vex_frostbase | karlı askeri üs: sığınaklar, kuleler, buz göleti |
| zm_vex_temple | antik tapınak arenası (boss için geniş): sütunlar, lav kanalları, basamaklar |
En az 32 T + 32 CT spawn, insanlar için savunulabilir kamp noktaları, merdivenler
(func_ladder), ışık (light / texlight), stok CS gökyüzü adı (indirme gerektirmez).
30. round sonunda bu 5 harita arasında oylama (eklenti).

## 9. HUD / yazı / renk paleti (eklenti)
| tür | renk (RGB) | not |
|---|---|---|
| Marka / sistem | 160,90,255 (Vexmira moru) + 0,220,255 (cyan) | başlıklar |
| İnsan bilgisi | 0,200,255 | panel, insan uyarıları |
| Zombi bilgisi | 120,255,40 | zombi paneli |
| Tehlike / boss | 255,40,40 → 255,170,0 | boss barı, uyarılar |
| Event | 255,190,0 | event duyuruları |
| Ödül / AP | 255,215,0 | AP/XP/VC kazanımı |
| Bekleme süresi | 180,180,180 | soğuma |
Chat önekleri: `[VEX]` sistem (yeşil), `[BOSS]` kırmızı (takım rengi), `[EVENT]`, `[VIP]`, `[ADMIN]`.

## 10. Boyut bütçesi (toplam indirme ~60 MB hedef)
- İnsan oyuncu modeli ≤ 1.0 MB, zombi ≤ 0.45 MB, boss ≤ 0.7 MB, pençe ≤ 0.2 MB,
  p_ ≤ 0.08 MB, v_ insan ≤ 0.4 MB, harita ≤ 4 MB, ses dosyası ≤ 200 KB (çoğu < 60 KB).

## 11. Precache bütçesi (KRİTİK — GoldSrc limitleri: ses 512, model+sprite 512, generic 512)
- Stok CS + harita zaten ~200-260 ses ve ~170 model kullanır. Eklenti:
  - 2D sesler (anons, UI, HUD, müzik) `precache_generic("sound/...")` + istemci `spk` / `mp3 play` ile çalınır
    (ses slotu harcamaz). Yalnızca 3D (konumlu) sesler `precache_sound` ile.
  - Her haritada sadece o haritanın boss planındaki bosslar (en fazla 4) yüklenir (model + pençe + ses).
    Admin "boss seç" menüsü yalnız yüklü bossları listeler.
  - Eklenti precache sonunda sayıları loglar: `[Vexmira] precache: sound=N model=M generic=G`
    (precache_* dönüş indekslerinden). Hedef: ses <= 470, model <= 440 (harita entity'leri için pay).
- Haritalar: brush entity sayısı <= 120 (her biri model slotu).

## 12. Yeni zombi sınıfları (12-23) — yetenekler ([R]) ve değerler (cfg'den ayarlanır)
| no | ad (EN / TR) | can x | hız | yerçekimi | geri tepme | R bekleme | level | [R] yeteneği |
|---|---|---|---|---|---|---|---|---|
| 12 | Butcher / Kasap | 1.35 | 255 | 0.90 | 0.60 | 16 | 3 | ET KANCASI: nişan yönüne zincirli kanca fırlatır (1400 u/s, 900 birim). İnsana takılırsa onu kasaba doğru ~600 u/s çeker (en fazla 1.2 sn, görüş kesilince/60 birime gelince biter), az hasar. Zincir ışını (chain.spr) + kanca modeli. Boss/Survivor çekilemez. |
| 13 | Hunter / Avcı | 0.85 | 300 | 0.70 | 1.10 | 12 | 6 | ATILMA: uzun sıçrama; inişte 70 birim içindeki insanı 1.0 sn sersemletir (dondurma) + hasar. |
| 14 | Charger / Boğa | 1.40 | 250 | 1.00 | 0.50 | 15 | 9 | HÜCUM: 1.5 sn dümdüz yüksek hızlı koşu; yoldaki insanları yana savurur + hasar; duvara çarpınca kendisi 0.5 sn sersemler. |
| 15 | Arachne / Örümcek | 0.85 | 290 | 0.60 | 1.00 | 13 | 11 | AĞ ATIŞI: ağ mermisi; vurulan insan 1.5 sn kök salar (hareket edemez) ve 3 sn yavaşlar (web.spr). |
| 16 | Magma / Magma | 1.10 | 265 | 0.80 | 0.90 | 18 | 13 | LAV İZİ: 5 sn boyunca yürüdüğü yere yanan lav havuzları bırakır. Pasif: ateş bombası ve yanma işlemez. |
| 17 | Volt / Volt | 0.95 | 280 | 0.80 | 1.00 | 18 | 15 | EMP: 350 birimde insanların lazer mayınları 6 sn kapanır, fener/gece görüşü söner, zincir elektrik küçük hasar + kısa yavaşlatma. |
| 18 | Mimic / Taklitçi | 0.90 | 275 | 0.80 | 1.00 | 22 | 17 | KILIK: 10 sn insan modeli gibi görünür (zombi parıltısı/ayak sesi yok); kılıktayken ilk vuruşu x2 hasar verir ve kılığı açar. |
| 19 | Burrower / Köstebek | 1.00 | 270 | 0.85 | 0.90 | 18 | 19 | YERALTI: 3 sn toprağa dalar (görünmez + hasar almaz + hızlı, toprak parçacık izi); çıkışta etraftaki insanları havaya fırlatan şok dalgası. |
| 20 | Siren / Siren | 0.90 | 280 | 0.80 | 1.00 | 17 | 21 | NİNNİ: 400 birimdeki insanlar 2.5 sn yavaşça Siren'e doğru çekilir + pembe hipnoz ekran rengi + yavaşlama. |
| 21 | Bulwark / Kale | 1.70 | 240 | 1.00 | 0.30 | 18 | 23 | TAHKİM: 5 sn geri tepme yok, %50 hasar azaltma, aldığı hasarın %25'ini yansıtır; taş parıltısı. |
| 22 | Sporemother / Spor Ana | 1.00 | 265 | 0.80 | 1.00 | 15 | 26 | SPOR KESESİ: ayağına tuzak kese diker (en fazla 2); 120 birime giren insan → patlar: zehir hasarı (zamanla) + yavaşlama. Kese vurularak yok edilebilir. |
| 23 | Nightmare / Kâbus | 0.90 | 290 | 0.80 | 1.00 | 20 | 28 | DEHŞET: 450 birimde görüş hattındaki insanların ekranı 2.5 sn kararır, fenerleri söner; Kâbus 3 sn hızlanır. |
Botlar (CS bot) zombi iken yeteneklerini insan yakınındayken otomatik kullanır.
