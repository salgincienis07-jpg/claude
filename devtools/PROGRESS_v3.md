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

## Yeni oturumda sıfırdan devam (iş akışı kayıtları yoksa)

1. Depoyu klonla, bu branch'e geç. `devtools/DESIGN_v3.md` sözleşmedir.
2. Araçları kur: `devtools/mdlkit/build_studiomdl.sh`, `devtools/mapkit/build_sdhlt.sh`,
   test sunucusu için `devtools/server/README.md` adımları.
3. Eksik içerik: yukarıdaki tabloda "bekliyor/sürüyor" olanlar. Model ajanları `devtools/mdlkit/README.md`,
   harita ajanları `devtools/mapkit/README.md` ile çalışır; eklenti `devtools/plugin/build_plugin.sh` ile derlenir.
4. Son aşama: `devtools/server/run_test.py` ile botlu test, `KURULUM_OKU.txt` + `DEGISIKLIKLER_v3.0.txt`,
   zip (`git archive` + zip), push.
