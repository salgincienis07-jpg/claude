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

## Yeni oturumda sıfırdan devam (iş akışı kayıtları yoksa)

1. Depoyu klonla, bu branch'e geç. `devtools/DESIGN_v3.md` sözleşmedir.
2. Araçları kur: `devtools/mdlkit/build_studiomdl.sh`, `devtools/mapkit/build_sdhlt.sh`,
   test sunucusu için `devtools/server/README.md` adımları.
3. Eksik içerik: yukarıdaki tabloda "bekliyor/sürüyor" olanlar. Model ajanları `devtools/mdlkit/README.md`,
   harita ajanları `devtools/mapkit/README.md` ile çalışır; eklenti `devtools/plugin/build_plugin.sh` ile derlenir.
4. Son aşama: `devtools/server/run_test.py` ile botlu test, `KURULUM_OKU.txt` + `DEGISIKLIKLER_v3.0.txt`,
   zip (`git archive` + zip), push.
