# Vexmira v3 — ilerleme ve devam etme rehberi

Bu dosya oturum sınırına / yeniden başlatmaya karşı tutulur. Yeni bir oturum buradan devam eder.
Branch: `claude/zombie-boss-mode-dev-a0m5oq` (her 10 dakikada otomatik commit + push yapılır).

## Durum (en son güncelleme: 2026-10-03 14:20 UTC)

| Alan | Durum | Çıktı |
|---|---|---|
| Tasarım sözleşmesi | bitti | `devtools/DESIGN_v3.md` |
| mapkit (harita kiti) | bitti | `devtools/mapkit`, `cstrike/maps/zm_vex_pilot.bsp` |
| mdlkit (model kiti) | son kontrol sürüyor | `devtools/mdlkit`, 4 örnek model |
| Test sunucusu | son kontrol sürüyor | `devtools/server` (sunucu: `$SP/server`, kurulum README'de) |
| Eklenti A (F tuşu, 12 yeni sınıf, kanca) | bitti | `.sma`, cfg, lang |
| Eklenti B (boss barı, HUD/renk, model/ses bağlama, precache) | bitti | `.sma`, cfg, lang |
| Eklenti C (harita oylaması, ses slotları, efekt sprite, ambiyans, tutarlılık) | sürüyor | |
| Sesler v3 (204 dosya) | bitti | `cstrike/sound/vexmira/{boss,class,special,hook,ui}` |
| Sprite v3 (25 dosya) | bitti | `cstrike/sprites/vexmira/` |
| Modeller (insan 7, zombi 24+24 pençe, boss 9+2 + 11 pençe, silah v_/p_, dünya) | bekliyor | `cstrike/models/...` |
| Haritalar (5) + .nav | bekliyor | `cstrike/maps/zm_vex_*.bsp` |
| Entegrasyon testi, inceleme, belgeler, zip | bekliyor | |

## Arka plan iş akışları (aynı oturum içinde devam ettirmek için)

- Modeller: script `~/.claude/projects/-home-user-claude-devtools/75b34835-cf97-54a7-be23-70299b8b0f9d/workflows/scripts/vex3-models-wf_7585ba81-758.js`, run `wf_7585ba81-758`
- Sunucu + eklenti C + haritalar: script `~/.claude/projects/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/workflows/scripts/vex3-server-plugin-maps-wf_f839418d-d31.js`, run `wf_f839418d-d31`
- Başarısız ajan olursa: `Workflow({scriptPath, resumeFromRunId})` — biten ajanlar önbellekten döner,
  yalnızca yarım kalanlar yeniden çalışır. Yarım kalan ajanın diskteki kısmi çıktısı korunur; yeni ajan
  önce mevcut durumu denetleyip kaldığı yerden devam etmelidir.

## Yeni oturumda sıfırdan devam (iş akışı kayıtları yoksa)

1. Depoyu klonla, bu branch'e geç. `devtools/DESIGN_v3.md` sözleşmedir.
2. Araçları kur: `devtools/mdlkit/build_studiomdl.sh`, `devtools/mapkit/build_sdhlt.sh`,
   test sunucusu için `devtools/server/README.md` adımları.
3. Eksik içerik: yukarıdaki tabloda "bekliyor/sürüyor" olanlar. Model ajanları `devtools/mdlkit/README.md`,
   harita ajanları `devtools/mapkit/README.md` ile çalışır; eklenti `devtools/plugin/build_plugin.sh` ile derlenir.
4. Son aşama: `devtools/server/run_test.py` ile botlu test, `KURULUM_OKU.txt` + `DEGISIKLIKLER_v3.0.txt`,
   zip (`git archive` + zip), push.
