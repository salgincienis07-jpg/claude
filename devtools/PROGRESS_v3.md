# Vexmira v3 — ilerleme ve devam etme rehberi

Bu dosya oturum sınırına / yeniden başlatmaya karşı tutulur. Yeni bir oturum buradan devam eder.
Branch: `claude/zombie-boss-mode-dev-a0m5oq` (her 10 dakikada otomatik commit + push yapılır).

## Durum (en son güncelleme: 2026-10-03 18:55 UTC)

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

- 2026-10-03 14:35'te iki iş akışı kullanım sınırına takıldı (tüm ajanlar yarıda). 18:55'te tek iş akışında
  birleştirilip yeniden başlatıldı (sırayla: eklenti C + mdlkit → 6 model ajanı → 5 harita → sunucu/nav/test):
  script `~/.claude/projects/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/workflows/scripts/vex3-full-continue-wf_4b0c2ac1-207.js`,
  run `wf_4b0c2ac1-207`.
- Başarısız ajan olursa: `Workflow({scriptPath, resumeFromRunId: "wf_4b0c2ac1-207"})` — biten ajanlar önbellekten döner.
  Ajan istemleri "önce diskteki kısmi işi incele, kaldığın yerden devam et" der.
- Ara sürüm (3.0.0-ara) 18:52'de kullanıcıya gönderildi: `Vexmira_Zombie_v3.0_ARA.zip` (eklenti 245dec7 anı + ses + sprite + walker modeli + pilot harita).

## Yeni oturumda sıfırdan devam (iş akışı kayıtları yoksa)

1. Depoyu klonla, bu branch'e geç. `devtools/DESIGN_v3.md` sözleşmedir.
2. Araçları kur: `devtools/mdlkit/build_studiomdl.sh`, `devtools/mapkit/build_sdhlt.sh`,
   test sunucusu için `devtools/server/README.md` adımları.
3. Eksik içerik: yukarıdaki tabloda "bekliyor/sürüyor" olanlar. Model ajanları `devtools/mdlkit/README.md`,
   harita ajanları `devtools/mapkit/README.md` ile çalışır; eklenti `devtools/plugin/build_plugin.sh` ile derlenir.
4. Son aşama: `devtools/server/run_test.py` ile botlu test, `KURULUM_OKU.txt` + `DEGISIKLIKLER_v3.0.txt`,
   zip (`git archive` + zip), push.
