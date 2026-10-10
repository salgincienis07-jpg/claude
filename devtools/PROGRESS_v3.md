# Vexmira v3 — ilerleme ve devam etme rehberi

Bu dosya oturum sınırına / yeniden başlatmaya karşı tutulur. Yeni bir oturum buradan devam eder.
Branch: `claude/zombie-boss-mode-dev-a0m5oq` (her 10 dakikada otomatik commit + push yapılır).

## Durum (en son güncelleme: 2026-10-03 23:55 UTC)

| Alan | Durum | Çıktı |
|---|---|---|
| Tasarım sözleşmesi | bitti | `devtools/DESIGN_v3.md` |
| mapkit (harita kiti) | bitti | `devtools/mapkit`, `cstrike/maps/zm_vex_pilot.bsp` |
| mdlkit (model kiti) | v1 bitti; v2 (MakeHuman tabanlı) yapılıyor | `devtools/mdlkit`, 4 örnek model |
| Test sunucusu | son kontrol sürüyor | `devtools/server` (sunucu: `$SP/server`, kurulum README'de) |
| Eklenti A (F tuşu, 12 yeni sınıf, kanca) | bitti | `.sma`, cfg, lang |
| Eklenti B (boss barı, HUD/renk, model/ses bağlama, precache) | bitti | `.sma`, cfg, lang |
| Eklenti C (harita oylaması, ses slotları, efekt sprite, ambiyans, tutarlılık) | bitti | |
| Sesler v3 (204 dosya) | bitti | `cstrike/sound/vexmira/{boss,class,special,hook,ui}` |
| Sprite v3 (25 dosya) | bitti | `cstrike/sprites/vexmira/` |
| Modeller (insan 7, zombi 24+24 pençe, boss 9+2 + 11 pençe, silah v_/p_, dünya) | bekliyor | `cstrike/models/...` |
| Haritalar (5) + .nav | bekliyor | `cstrike/maps/zm_vex_*.bsp` |
| Entegrasyon testi, inceleme, belgeler, zip | bekliyor | |
| Sahip hata listesi 7 madde (boss ustu siyah kare, kanca zinciri yonu, isin / itme yon denetimi, lazer menzil + nemesis/assassin yasagi, parasut yercekimi, model rehberi) | bitti (2026-10-04) | eklenti + `vexmira.cfg` "KENDI MODELINI EKLEME REHBERI"; dogrulama: `devtools/server/README.md` DIRCHK testleri |

## Arka plan iş akışları (aynı oturum içinde devam ettirmek için)

- 2026-10-03 ~20:00: kullanıcı ilk prosedürel modelleri "acemice" buldu (devtools/previews_models_v3.png).
  Model üretimi durduruldu; yeni iş akışı: MakeHuman (CC0) anatomisi + detaylı doku pişirme ile model boru hattı v2
  (3 kanıt model: vex_operator, vex_z_walker, vex_b_brute + karşılaştırma görseli devtools/previews_mdlkit2_compare.png)
  ve paralel olarak 5 harita (sırayla).
  script `~/.claude/projects/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/workflows/scripts/vex3-quality-upgrade-wf_a52f9d2f-924.js`,
  run `wf_a52f9d2f-924`. Yarıda kalırsa: `Workflow({scriptPath, resumeFromRunId: "wf_a52f9d2f-924"})`.
- Kanıt modeller beğenilirse: tüm modeller (7 insan, 24 zombi + pençe, 9 boss + Nemesis/Assassin + pençe, silahlar,
  dünya modelleri) v2 boru hattıyla yeniden üretilecek; sonra sunucu/nav/test + tam zip.
- Eklenti C, mdlkit v1, sesler, sprite'lar bitti (önceki run wf_4b0c2ac1-207, durduruldu).
- Ara sürüm (3.0.0-ara) kullanıcıya gönderildi: `Vexmira_Zombie_v3.0_ARA.zip`.

- 2026-10-03 23:55: kullanım sınırı sonrası yeniden başlatıldı (iş akışı betikleri scratchpad/wf/ altına kopyalandı):
  hizalama düzeltmesi `wf/align-fix.js` run `wf_f59e0f41-149` (can barı/ikonlar oyuncunun içinde, lazer ters → düzelt
  + inceleme; sonra 3.0.1 ara sürüm), kalite yükseltme `wf/quality-upgrade.js` run `wf_a52f9d2f-924`.
  Resume: `Workflow({scriptPath: "$SP/wf/<ad>.js", resumeFromRunId: "<run>"})`.

- 2026-10-04 00:00: kullanıcı isteği: 3.0.1 ara sürüm = hizalama düzeltmesi + 1 tam harita (zm_vex_laboratory) +
  silah v_ modelleri + lazer/ikmal/w_ bomba modelleri; oyuncu modelleri sonra. Kalite yükseltme (MakeHuman) durduruldu.
  İçerik: `wf/content301.js` run `wf_27dc55f2-a80`; hizalama: `wf/align-fix.js` run `wf_f59e0f41-149`.
  İkisi bitince ana oturum: harita .nav kontrolü, botlu test, 3.0.1 zip (stok oyuncu modelleri, p_ YOK), gönder.

- 2026-10-04 00:18: content301 bitti (commit 602ccbe): zm_vex_laboratory (+nav, ambiyans), v_vexblade, v_firebomb/
  frostbomb/flare, v_sw0..7, lasermine, supply_crate, w_ bombalar. Merdiven yan direkleri katı değil yapıldı +
  yeniden derlendi + yeni nav (1817c0c). Hizalama ajanı (wf_f59e0f41-149) HLTV ile gerçek istemci testi yapıyor.
  Paket: `devtools/release/pack301.sh` (v1 oyuncu/pençe modelleri, p_ak47, pilot HARİÇ) + not `devtools/release/ARA_SURUM_v3.0.1_OKU.txt` (betik $SP kopyasını okur)
  (@@ALIGN@@ ve @@TEST@@ yerlerini doldur). Sonra VERSION "3.0.1-ara", botlu test, zip gönder.

- 2026-10-04 00:33: kullanıcı (%79 kullanım): oyuncu modelleri beklesin; yetişebildiğince silah modelleri, bıçaklar
  (zombi pençeleri), efektler. 3.0.1 paketi sabit revizyondan (`$SP/pin301_rev.txt`, `$SP/pack301.sh`) çıkar.
  3.0.2 iş akışı `$SP/wf/weapons-fx-302.js` run `wf_446ac8ba-53e`: 34 pençe (MakeHuman el anatomisi), p_ modeller
  (vexblade, 3 bomba, sw0-7), hook/hive_egg/spore_pod dünya modelleri, efekt sprite yükseltmesi + entegrasyon testi.
  Sonra: 3.0.2 zip (v1 oyuncu modelleri hariç).

- 2026-10-04 00:37: kullanıcı %92 kullanımda "bitir at" dedi: 3.0.1 zip gönderildi (Vexmira_Zombie_v3.0.1_ARA.zip).
  3.0.2 iş akışı (4 pençe: v_claw_zombie/mutant/stalker/boss, p_ modeller, hook/hive_egg/spore_pod, efekt sprite'ları)
  BAŞLAMADAN durduruldu; devam: `Workflow({scriptPath: "$SP/wf/weapons-fx-302.js"})` (yeni çalıştırma).
  cfg pençeleri zaten 4 modele eşlendi. Kalan: oyuncu modelleri (MakeHuman), 4 harita, laboratuvar havalandırma
  ağzında bot takılması (y -800..-736 ağız dar), tam sürüm belgeleri + zip.

- 2026-10-04 05:00: YENI TUR (3.1). Kullanici: oyuncu modelleri IPTAL; haritalar hikayeli/etkilesimli/buyuk/FPS cok iyi;
  eklenti optimizasyonu (gerekirse 9-10 dosyaya bol); markette jetpack (olunce duser, alinir, sag tik fuze) + RPG;
  5 pet + 5 kanat (VC kozmetik); kanca efekti ters capraz + benzer hatalar; boss ustu siyah arka planli beyaz efekt;
  lazer menzili sinirli; nemesis/assassin modunda lazer yok; parasut gravity bozuyor; cfg'de el/model yollari;
  ozel silah eklerken ses/animasyon/efekt otomatik; yazili HUD yerine grafik gostergeler (MVP dahil).
  Is akislari (script'ler $SP/wf/ altinda):
   * haritalar: `$SP/wf/maps-v3.js` run `wf_0bd24f59-127` (onceki wf_99c64f43-b19 limit yuzunden bitti) (tasarim MAPS_v3.md + perf araci + 5 harita build/verify/fix)
   * eklenti+icerik: `$SP/wf/plugin-v31.js` run `wf_c2a7c186-7b6` (onceki wf_1ce2427a-43d limit yuzunden bitti; split + perf araci + istemci kismen yapildi) (split -> bugfix -> ozel silah -> harita hikaye
     destegi -> jetpack/RPG -> HUD -> pet/kanat -> optimizasyon -> final review; paralel: istemci renderer + modeller)
  Yarida kalirsa: TaskStop (calisiyorsa) + Workflow({scriptPath, resumeFromRunId}).
  Sonra: tum haritalarla entegrasyon testi, paket 3.1 (v1 oyuncu modelleri haric), kullaniciya gonder.

- 2026-10-04 10:30: kullanici "limite takilmadan bitsin" dedi -> paralel is akislari durduruldu; TEK AJAN, sirali,
  tasarruflu plan. Parca 1: `$SP/wf/p1.js` run `wf_1c110c81-b75` (split kontrol -> hata duzeltmeleri -> test istemcisi ->
  MAPS_v3.md -> laboratuvar yenileme -> harita hikaye destegi). Bitince 3.1-ara paketi gonderilir.
  Parca 2 (sonra): ozel silah sistemi, jetpack/RPG (+modeller), grafik HUD, 5 pet + 5 kanat.
  Parca 3 (sonra): liman, yikik sehir, karli us, tapinak + optimizasyon + final kontrol.
  Harita<->eklenti sozlesmesi: devtools/MAP_CONTRACT.md.

- 2026-10-04 11:22: kullanim %95 -> is akisi DURDURULDU. Gonderildi: Vexmira_Zombie_v3.1.zip (hata duzeltmeleri, otomatik
  takim, cfg model rehberi, moduler eklenti). Bitenler (onbellekte): split-check, bugfixes.
  DEVAM (limit sifirlaninca): Workflow({scriptPath: "$SP/wf/p1.js", resumeFromRunId: "wf_1c110c81-b75"})
  sira (kullanici istegi): OZEL SILAH SISTEMI -> GRAFIK HUD (cfg ile geri donulebilir) -> map-story -> laboratuvar (FPS + etkilesim + ini)
  -> optimizasyon+final -> paket ($SP/pack31.sh / devtools/release/pack31.sh, not: SURUM_v3.1_OKU.txt) -> gonder.
  Sonra: jetpack/RPG, 5 pet + 5 kanat, 4 harita.
- 2026-10-04 15:25: sahip "eklentiyi bolmussun, .inc dosyalari yuzunden hicbir sey calismiyor" dedi (tek basina
  derleyince vex/*.inc bulunamiyor). Kaynak yeniden TEK dosya vexmira_zombie.sma (13 "BOLUM n/13" bolumu), vex/
  silindi, VERSION "3.1". amxx_compare: bolunmus derlemeyle EQUIVALENT; test 120 s / 8 bot 0 hata. Paket yeniden
  gonderildi. KURAL: eklentiyi bir daha include dosyalarina bolme. p1.js: split/bugfix adimlari tamam olarak
  isaretlendi (yeniden calismaz), ortak metin tek dosya kuralini soyler.
- 2026-10-04: sahip "sadece 1 tane mukemmel etkilesimli essiz buyuk, bol FPS'li harita bitir" dedi. Is akisi
  vex-flagship-map (run wf_b52843c0-d85, betik $SP/wf/flagship.js): 3 tasarim + 3 hakem -> SPEC, harita 4 asamada
  (serverB) || eklenti harita-hikaye destegi (serverC), entegrasyon (serverD), 3 acili denetim + duzeltme (serverE/F).
  DEVAM: Workflow({scriptPath: "$SP/wf/flagship.js", resumeFromRunId: "wf_b52843c0-d85"}). Sonra paket + gonder.

- 2026-10-04 17:10: sahip kendi "Vexmira_Zombie_v3.1_FINAL.zip" paketini (baska bir asistanin PATCH9'u, hic sunucuda
  denenmemis) gonderdi ve ONCELIK verdi; harita isi (wf_b52843c0-d85) DURDURULDU, sonra devam edilecek.
  Paket b3b629f ile ice alindi (VERSION 3.2-dev). Is akisi vex-v32-overhaul (run wf_9488d02c-ff8, betik $SP/wf/v32.js):
  menu sadelestirme, VIP, ozel silah 8-15 hatasi, lazer sokme bari, denge/ekonomi, meteor, mesajlar -> chat ipuclari,
  kod incelemesi, HUD grafik dosyalari. DEVAM: Workflow({scriptPath: "$SP/wf/v32.js", resumeFromRunId: "wf_9488d02c-ff8"}).

- 2026-10-04 17:18: sahip kullanim %88 dedi -> buyuk v3.2 akisi DURDURULDU; yalin akis vex-v32-lean (run wf_c7a55db0-ddf,
  betik $SP/wf/v32lean.js): 1) ozel silah 8-15 hatasi + lazer sokme bari + meteor + lazer menuden cikar, 2) menu/VIP/mesajlar,
  3) denge + eksik dosya varsayilanlari + HUD grafik modu yedek yazi. Her ajan commit eder; sonra paket ($SP/pack31.sh, ad v3.2).

- 2026-10-04 17:19: kullanim %96 -> yalin akis da DURDURULDU (ilk ajan yeni basliyordu, kod degismedi).
  SIFIRLANINCA ILK IS: Workflow({scriptPath: "$SP/wf/v32lean.js"}) (3 ajan: silah/lazer/meteor -> menu/VIP/mesaj ->
  denge/dosya/HUD), sonra paket v3.2 + gonder. Ardindan harita: Workflow({scriptPath: "$SP/wf/flagship.js"}).
  $SP yoksa (yeni oturum): istekler devtools/HANDOFF_v3.1.md + bu dosyadaki listeye gore.

- 2026-10-04 SON DURUM (otomatik devam icin): sahip "devam et; sinir dolarsa kayitli yerden otomatik devam et" dedi.
  SIRA: (1) vex-v33 is akisi run wf_91ca5680-a67, betik $SP/wf/v33.js (madde 22 combo/sag HUD/menu aciklama,
  madde 23 animasyonlu transparan CSO sprite'lar) -> yarim kaldiysa: Workflow({scriptPath: "$SP/wf/v33.js",
  resumeFromRunId: "wf_91ca5680-a67"}). (2) bitince paket: bash $SP/pack32h.sh (HEAD'den derler) -> SendUserFile.
  (3) harita CALISIYOR: run wf_e0c4a70f-a93 -> yarim kaldiysa Workflow({scriptPath: "$SP/wf/flagship.js", resumeFromRunId: "wf_e0c4a70f-a93"}) (bitince paket + gonder). v33 + v3.2 paketi BITTI (01:39 UTC gonderildi).
  Saatlik rutin bunu okuyup yarim kalan akisi devam ettirir; kullanici durdurmadikca ilerle.

## Yeni oturumda sıfırdan devam (iş akışı kayıtları yoksa)

1. Depoyu klonla, bu branch'e geç. `devtools/DESIGN_v3.md` sözleşmedir.
2. Araçları kur: `devtools/mdlkit/build_studiomdl.sh`, `devtools/mapkit/build_sdhlt.sh`,
   test sunucusu için `devtools/server/README.md` adımları.
3. Eksik içerik: yukarıdaki tabloda "bekliyor/sürüyor" olanlar. Model ajanları `devtools/mdlkit/README.md`,
   harita ajanları `devtools/mapkit/README.md` ile çalışır; eklenti `devtools/plugin/build_plugin.sh` ile derlenir.
4. Son aşama: `devtools/server/run_test.py` ile botlu test, `KURULUM_OKU.txt` + `DEGISIKLIKLER_v3.0.txt`,
   zip (`git archive` + zip), push.

- 2026-10-10 07:30: sahip haritanin hedeflerini yeniledi: yuksek FPS, duzgun texture/tasarim, net yonlendirme, her raund calisan
  hikaye/eventler, gercekci gerilimli ambiyans, duzgun etkilesim/efekt/animasyon, 32 kisi rahat oynasin (ana yollar >= 128),
  essiz ve eglenceli. Bunlar flagship.js'e "OWNER REQUIREMENTS" olarak eklendi; eski run durduruldu (tasarim yeni basliyordu).
  YENI run wf_57454fa6-612 -> yarim kaldiysa: Workflow({scriptPath: "$SP/wf/flagship.js", resumeFromRunId: "wf_57454fa6-612"}).
  Bitince: paket + gonder + push.
- 2026-10-10 07:40: ek istek: texture'lar ambiyansla uyumlu, gercekci, uygun olsun (OWNER REQUIREMENTS 2b). Run yeniden
  baslatildi: YENI run wf_72ed255d-1ec -> yarim kaldiysa Workflow({scriptPath: "$SP/wf/flagship.js", resumeFromRunId: "wf_72ed255d-1ec"}).
- 2026-10-10 07:55: sahip "kullanim %60, hizlandir" dedi -> YALIN akis (flagship.js yalin surum; tam surum $SP/wf/flagship.full.js):
  1 ajan tasarim+SPEC (Aci B karantina bolgesi + diger acilardan en iyi fikirler) -> harita 3 asama || eklenti hikaye destegi
  -> entegrasyon -> 1 birlesik inceleme + 1 duzeltme. ~7 ajan (onceden ~17). YENI run wf_8f0bb905-afd ->
  yarim kaldiysa Workflow({scriptPath: "$SP/wf/flagship.js", resumeFromRunId: "wf_8f0bb905-afd"}).
