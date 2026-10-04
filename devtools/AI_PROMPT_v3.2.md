# Vexmira Zombie v3.2 – başka bir yapay zekâya verilecek görev komutu

Aşağıdaki metnin tamamını kopyalayıp yapay zekâya ver. Yanına şunları da ekle:
- Elindeki `Vexmira_Zombie_v3.1_FINAL.zip` paketi (ya da depodaki `cstrike/` klasörü)
- Bu klasördeki `HANDOFF_v3.2.md` dosyası

---

## KOMUT (buradan itibaren kopyala)

Sen deneyimli bir **AMX Mod X / CS 1.6 eklenti geliştiricisisin**. Pawn, ReAPI, Fakemeta, Ham Sandwich, ReGameDLL ve GoldSrc motor sınırlarını iyi biliyorsun. Görevin, ekteki **Vexmira Zombie** modunu v3.1 FINAL sürümünden **v3.2** sürümüne taşımak. Bu iş için tam, çalışan ve test edilmiş bir paket bekleniyor.

### 1. Proje
- **Oyun ve sunucu:** Counter-Strike 1.6, sunucuda ReHLDS + ReGameDLL 5.30 + Metamod + AMX Mod X 1.10 + ReAPI 5.26.
- **Mod:** Zombi modu. Birçok round modu var: enfeksiyon, nemesis, assassin, survivor, sniper, swarm, plague, armageddon ve boss roundları. Ayrıca 24 zombi sınıfı, yetenekler, AP parası, VC coini, XP/seviye, market, 16 özel silah, lazer mayını, VIP, kozmetikler ve eventler (meteor, altın ışık vb.) var.
- **Eklenti kaynağı:** `cstrike/addons/amxmodx/scripting/vexmira_zombie.sma` adlı **tek dosya**, yaklaşık 24.700 satır. Dosya 13 bölümden oluşur; dosyada `BOLUM ` diye aratınca bulursun: CORE, FX, HUD, KAYNAKLAR, ISTATISTIK, EKONOMI, SILAHLAR, ZOMBILER, BOSSLAR, MODLAR, OYUNCULAR, ADMIN, HARITALAR.
- **Ayar dosyası:** `cstrike/addons/amxmodx/configs/vexmira.cfg`. Bütün ayarlar bu tek dosyada durur ve her ayarın Türkçe açıklaması vardır.
- **Dil dosyası:** `cstrike/addons/amxmodx/data/lang/vexmira_zombie.txt`. `[en]` ve `[tr]` bölümleri vardır; Türkçe metinler Türkçe özel harf kullanılmadan yazılır (ş→s, ğ→g, ı→i, ö→o, ü→u, ç→c).
- **Derlenmiş eklenti:** `cstrike/addons/amxmodx/plugins/vexmira_zombie.amxx`.

### 2. Değişmez kurallar (hepsine uy)
1. Eklenti **tek .sma dosyası** olarak kalacak. Kodu `#include "..."` ile ayrı dosyalara **bölme**. Sahibi eklentiyi tek başına derliyor; daha önce dosyalar bölündüğünde derleme bozuldu.
2. Her yeni ayar `vexmira.cfg` içine Türkçe açıklamasıyla eklenecek. Koddaki varsayılan değer cfg'dekiyle **aynı** olacak.
3. Oyuncunun gördüğü her metin dil dosyasında hem **EN** hem **TR** olarak bulunacak. Kodun içine metin gömme.
4. Derleme AMX Mod X 1.10 `amxxpc` ve ReAPI 5.26 include dosyalarıyla yapılacak; sonuç **0 hata, 0 uyarı** olmalı.
5. Performans için:
   - Her karede mesaj gönderme (HUD/DHUD dahil).
   - Her karede çalışan fonksiyonlarda (PreThink, AddToFullPack, CmdStart) string işlemi ve arama yapma.
   - Gereksiz entity yaratma.
6. Precache sınırları sıkı: oyun + harita + eklenti toplamı şu an ses 442/512, model 304/512. Yeni dosya eklerken toplamı 490'ın altında tut.
7. Var olan özellikleri bozma. Kayıtlı oyuncu verileri (nvault) ve cfg formatı geriye uyumlu kalmalı.
8. **Yapmadığın veya test etmediğin bir şeyi yapılmış gibi yazma.** Sunucu çalıştıramıyorsan bunu açıkça belirt.

### 3. Yapılacaklar (her maddenin kabul ölçütü var)

**G1 – Özel silah hatası (en önemli madde)**
- **Şikâyet:** "Listenin sonundaki özel silahları (sonradan eklenen 8–15. slotlar) alınca mermi çıkmıyor, sonra TÜM silahlar bozuluyor."
- **Kök sebebi bul.** Şuralara bak:
  - `NUM_SPECIAL 16` ve buna bağlı dizilerin boyutları, 8 elemanlı kalmış diziler, 8 bitlik bit maskeleri.
  - cfg'deki `vex_sw` ve `vex_sw_text` satırlarının okunması.
  - Silahı verme, çekme (deploy), şarjör/mermi, atış aralığı ve geri tepme kancaları; `m_flNextPrimaryAttack` ve benzeri bekleme süreleri.
  - Atış sesi değiştirme kodu (`FM_EmitSound` ile çekme/şarjör sesleri).
  - Ölümde, silah atınca, round sonunda ve oyuncu çıkınca sıfırlanmayan oyuncu verileri.
- **Kabul:** 16 slotun her biri alınabiliyor, ateş ediyor, şarjör değiştiriyor ve atılabiliyor. Ölünce ve yeni roundda başka hiçbir silah bozulmuyor. Raporda kök sebebi satır numarasıyla yaz.

**G2 – Lazer mayını sökme**
- Mayın anında sökülmeyecek. Oyuncu basılı tutacak, ekranda ilerleme çubuğu (`BarTime` mesajı) çıkacak, süre `vex_lm_take_time` ayarından gelecek (varsayılan 2.0 saniye).
- Şu durumlarda iptal olacak: oyuncu uzaklaşırsa (96 birimden fazla), nişanı mayından çekerse, hasar alırsa, ölürse veya round biterse. Mesajlar EN/TR.

**G3 – Lazer mayını menüden kalksın**
- Oyuncu menülerindeki lazer mayını maddeleri kaldırılacak.
- Marketten satın alma, say komutları ve bind ile kurma/sökme çalışmaya devam edecek.

**G4 – Meteor eventi**
- Meteor sayısı en az yarıya inecek. Sayı ve aralık için cfg ayarları eklenecek.
- Meteor oyuncuya **hiçbir zaman doğrudan isabet etmeyecek**. Rastgele bir insanın 96–220 birim önüne veya yanına düşecek; düşeceği nokta yere izle (trace) bulunacak.
- Düşmeden önce kısa bir uyarı efekti olacak. Hasar yalnızca patlama alanından gelecek ve adil olacak. Boss meteor yağmuru da aynı kurala uyacak.

**G5 – Menü sadeleştirme**
- **Sorun:** Ana menüde yaklaşık 22 madde var; çok karmaşık ve kafa karıştırıcı.
- **Hedef:** Ana menü **tek sayfa** ve **en fazla 8 net madde** olacak. Örnek düzen:
  1. Market (eşyalar + özel silahlar)
  2. Silahlar
  3. Zombi sınıfı
  4. Karakter (profil, seviye, görevler, başarımlar, unvanlar, TOP)
  5. Ödüller / günlük
  6. Kozmetik
  7. Ayarlar (dil, HUD, ses, FPS)
  8. VIP (admin menüsü yalnızca adminlere görünür)
- Diğer maddeler bu gruplara taşınacak. Tekrar eden ve gereksiz maddeler kalkacak; say komutları çalışmaya devam edecek.
- Bütün menülerde aynı başlık stili ve renkler kullanılacak, numaralandırma tutarlı olacak ve her alt menüde "geri" ile "çıkış" bulunacak. Başlıklar EN/TR olacak.
- **Kabul:** Raporda yeni menü ağacının tamamı ve eski maddelerin nereye gittiği yer alacak.

**G6 – VIP**
- **Sorun:** VIP menüsünde çok az özellik var; oyuncuların VIP almak için bir sebebi olmalı.
- **Önerilen ek özellikler:** AP, XP ve VC kazancında çarpan; her round ücretsiz VIP paketi (zırh + bombalar); ekstra zıplama; özel kozmetik, iz ve chat etiketi; özel silah indirimi; respawn modlarında daha hızlı doğma.
- Oyunu parayla kazanılır hâle (pay-to-win) getirmeyecek.
- Bütün değerler cfg'den ayarlanabilecek. VIP menüsünde VIP'in neler sağladığını gösteren net bir bilgi sayfası olacak.

**G7 – Mesajlar**
- Gereksiz otomatik bilgilendirme mesajları kaldırılacak: doğuşta çıkan uzun yazılar, tekrar eden ipuçları, uzun DHUD metinleri. Oyun durumu için önemli mesajlar kalacak.
- Bunların yerine chatte belli aralıklarla ipucu gösterilecek:
  - 15–20 faydalı EN/TR ipucu, sırayla dönecek.
  - Her oyuncu kendi dilinde görecek.
  - Aralık `vex_chat_tip_interval` ayarıyla belirlenecek (varsayılan 90 saniye, 0 = kapalı).

**G8 – Denge (sayılarla)**
- **Sorun:** Silahlar çok güçlü, zombiler güçsüz; nemesis ve assassin çok zayıf.
- **İncelenecek değerler:**
  - Normal silah hasarı ve hasar artışları.
  - 16 özel silahın hasar çarpanı, fiyatı ve gereken seviyesi.
  - Geri itme (knockback).
  - Zombi sınıflarının canı, hızı, yerçekimi ve can yenilemesi; yetenek bekleme süreleri ve hasarları.
  - Nemesis, assassin, survivor ve sniper canının oyuncu sayısına göre artışı.
  - Boss canları.
  - AP, VC ve XP kazanma/harcama hızları ve fiyatlar.
- **Hedefler:**
  - Özel silahlar güçlü olsun ama tek atışta öldüren makineye dönüşmesin.
  - Zombilerin canı yaklaşık %25–40 artsın ve oyuncu sayısına göre ölçeklensin.
  - Nemesis dolu bir insan takımı için gerçek tehdit olsun; assassin görünmez ve ölümcül olsun.
  - Bosslar 10–20 kişiyle 2–4 dakika sürsün.
  - İyi oynayan biri yaklaşık 3–4 roundda bir özel silah alabilsin; VC kozmetikler için daha yavaş birikmeli.
- Değişen her değer hem kodda hem cfg'de aynı olacak. Eski → yeni değer tablosunu gerekçeleriyle birlikte `BALANCE_v32.md` dosyasına yaz.

**G9 – Kod incelemesi**
- Hata, eksik, bozukluk ve mantık hatası kalmayacak. Bunları kontrol et:
  - Dizi sınırları (oyuncu id 0/33, sınıf/boss/eşya/özel silah indeksleri).
  - Geçerliliği kontrol edilmeden kullanılan entity'ler.
  - Ölünce ya da oyuncu çıkınca hâlâ çalışan task'lar.
  - Round ve ölüm sıfırlamaları.
  - Menü işleyicileri (`menu_destroy`, madde aralıkları).
  - Hız, yerçekimi ve render değerlerinin geri yüklenmesi.
  - Mod geçişleri ve kazanma koşulları.
  - Kod ↔ cfg ↔ dil dosyası tutarlılığı: her cvar cfg'de olacak, her dil anahtarı EN ve TR'de olacak, format argüman sayıları eşleşecek.
- **Bilinen bir şüphe:** Bir testte 6 round "kazanan yok" bitti. Bunun bir hata olup olmadığını kontrol et.
- Bulduğun her hatayı satır numarası ve senaryosuyla raporla, sonra düzelt.

**G10 – HUD grafikleri ve eksik dosyalar**
- **HUD:** `vex_hud_style 1` (grafik) modunda grafiği olmayan parçalar şu an tamamen gizleniyor. Hiçbir parça kaybolmayacak: gerçek grafik karşılığı varsa o gösterilecek, yoksa kısa ve şık bir yazı gösterilecek.
- **Motor sınırı:** CS 1.6'da sunucu eklentisi istemci ekranına keyfi 2D resim çizemez. Kullanılabilecekler şunlar:
  - Oyuncuların kafa üstünde dünya içi sprite'lar
  - `BarTime` / `BarTime2` ilerleme çubukları
  - İstemcinin hud.txt dosyasında bulunan ikonlar (`StatusIcon`)
  - `ScreenFade`
  - DHUD ve HUD yazıları
- Gereken her sprite üretilip pakete konacak.
- **Eksik dosyalar:** `vexmira.cfg` pakette **olmayan** dosyalara işaret ediyor:
  - `models/vexmira/claws/v_claw_*.mdl`
  - 3. şahıs silah modelleri (`p_*.mdl`)
  - `hook.mdl`, `hive_egg.mdl`, `spore_pod.mdl`
  - `vex_tank` oyuncu modeli
  - Özel silahların 8–15. slot model dosyaları
  - `sound/vexmira/x.wav` ve mp3 tema dosyaları
- Bu ayarların her biri ya var olan bir dosyaya ya da boş değere (= oyunun orijinali) çekilecek; yanına "dosyanı koyunca buraya yaz" diye Türkçe açıklama eklenecek. Ya da dosya üretilecek.
- **Kabul:** Temiz kurulumda sunucu logunda "bulunamadi" uyarısı çıkmayacak.

### 4. Test
- **Sunucu çalıştırabiliyorsan:** ReHLDS + ReGameDLL + AMXX + ReAPI ile, botlarla (`bot_quota 16`) en az 2 × 8 dakika oyna.
  - Bütün modları ve eventleri dene: admin menüsünden mod, boss ve event başlat.
  - 16 özel silahın hepsini al ve ateş et.
  - Lazer kur, sök, iptal durumlarını dene.
  - Bütün menüleri EN ve TR olarak gez.
  - HUD stillerini (0/1/2) oyun açıkken değiştir.
  - `addons/amxmodx/logs` klasöründe **0 çalışma hatası** olmalı.
- **Sunucu çalıştıramıyorsan:** Derleme 0/0 olmalı. Kodu satır satır izleyerek kontrol et. Raporda "canlı test yapılmadı" diye **açıkça** yaz.

### 5. Teslim
1. Güncel `vexmira_zombie.sma` (tek dosya), derlenmiş `vexmira_zombie.amxx`, `vexmira.cfg`, dil dosyası ve yeni sprite/ses dosyaları.
2. `cstrike/` klasör yapısını koruyan bir zip paketi: `Vexmira_Zombie_v3.2.zip`. Kaynaktaki `#define VERSION` değeri `"3.2"` olacak.
3. Türkçe bir değişiklik notu, `SURUM_v3.2_OKU.txt`. İçeriği:
   - G1–G10 için ne yapıldığı
   - Yeni cfg ayarları
   - Yeni menü ağacı
   - Denge tablosu
   - Neyin test edildiği ve neyin edilmediği
4. Yapamadığın veya motor yüzünden mümkün olmayan her şeyi gerekçesiyle ve dürüstçe yaz.

### 6. Sonraki iş (G1–G10 bittikten sonra, ayrı görev)
- Tek bir **amiral gemisi harita**: etkileşimli, eşsiz, büyük hissettiren ve FPS'i yüksek.
- **FPS sınırı:** Ekranda görünen poligon sayısı (r_speeds wpoly) en fazla 1300, oyuncuların bulunduğu noktaların %95'inde 900'ün altında; bunun için `func_detail` kullanılacak ve harita geneline yayılan dev `func_wall` olmayacak.
- **Hikâye ve akış:** Her roundda yön, amaç ve akış olacak. Harita, eklentinin olaylarına (`vex_round_start`, `vex_boss`, `vex_lasthuman`, …) tepki verecek ve `vexcmd_*` relay'leri üzerinden eklentiye haber verecek.
- Ayrıntılar depoda `devtools/MAP_CONTRACT.md` ve `devtools/mapkit/README.md` dosyalarında.
