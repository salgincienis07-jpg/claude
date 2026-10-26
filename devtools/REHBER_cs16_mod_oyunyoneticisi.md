# CS 1.6 MOD YAPIM REHBERİ — oyunyoneticisi.com hostu için

Bu metni modu yazacak yapay zekâya ver. Vexmira Zombie Plague modunu bu hostta geliştirirken yaşanan her
sorundan çıkarılmış kurallardır. **Kesin bilinenler** ile **doğrulanmamış / kontrol edilmesi gerekenler**
ayrı işaretlendi. Belirsiz bir şeyi varsayma: sunucu sahibine sor veya kodu her iki duruma göre güvenli yaz.

---

## 1. Sunucu ortamı (bilinenler)

- **Motor:** ReHLDS + ReGameDLL, **AMX Mod X 1.10** (1.9 ile de çalışacak şekilde yaz), **ReAPI** var.
  Hook'lar için `RegisterHookChain` (ReAPI) ve `RegisterHam` (hamsandwich) kullanılabilir.
- **Paneldeki modüller:** `sockets`, `geoip`, `mysql`, `sqlite` **AÇIK**. `regex`, `json`, `easy_http` **KAPALI**.
  - Bu yüzden: `regex_*`, `json_*` ve `ezhttp_*` kullanma. Kullanırsan eklenti "module not found" ile yüklenmez.
  - Dış dünyaya bağlantı **sadece `sockets`** ile yapılabilir: düz TCP/UDP. **TLS/HTTPS yok.** Yalnızca `http://`
    (80 portu) ya da düz TCP protokolleri kullanılabilir. HTTPS isteyen API'ler (Firebase, Discord webhook vb.)
    doğrudan kullanılamaz.
  - 80 dışındaki çıkış portları (örneğin 1883/MQTT) **doğrulanmadı.** Mutlaka bir yedek yol yaz.
- **Kalıcı veri:** `nvault` (dosya tabanlı) güvenilir şekilde çalışır. `sqlite` modülü de açık.
  `mysql` modülü açık ama hostun veritabanı verip vermediği ve web tarafında PHP olup olmadığı **bilinmiyor**.
- **Oyuncular:** Hem **Steam** hem **Steam'siz (non-steam / LAN)** oyuncular giriyor. Steam'siz oyuncuların
  bir kısmı aynı kimliği paylaşıyor (`STEAM_ID_LAN`, `VALVE_ID_LAN`, `STEAM_ID_PENDING` vb.).
  **Veriyi sadece SteamID ile kaydetme:** paylaşılan kimliklerde isme göre anahtar kullan (ör. `N_<isim>`).
  Ana kayıt, arkadaş listesi, pazar ve banka hepsi AYNI anahtar kuralını kullanmalı. Aksi halde veriler
  karışır ya da kaybolur.

## 2. Panel ve dosya yükleme

- Dosyalar panelin dosya yöneticisinden `cstrike/` altına yüklenir. Yapı standarttır:
  - `cstrike/addons/amxmodx/plugins/` → `.amxx`
  - `cstrike/addons/amxmodx/scripting/` → `.sma` (panel buradan **kendisi derleyebiliyor**)
  - `cstrike/addons/amxmodx/configs/` → `.cfg`, `.ini`
  - `cstrike/addons/amxmodx/data/lang/` → dil dosyaları
  - `cstrike/models`, `sound`, `sprites`, `maps`, `gfx/env` (skybox) → oyun dosyaları
- **Eklenti listesi:** AMXX, `configs/plugins-*.ini` dosyalarını kendiliğinden yükler. Kendi listeni ayrı bir
  `plugins-<modadi>.ini` dosyasına koy. Aynı eklentiyi iki ini dosyasına yazma.
- **Panel eklentileri kendisi derliyor**, büyük ihtimalle hata ayıklama bilgisi olmadan. `plugins.ini` içinde
  `debug` yazılıysa logda `Plugin not compiled with debug option` uyarısı çıkar; bu bir hata değildir.
  Sen derlediğin `.amxx` dosyalarını `amxxpc -d2` ile derle ki hata olursa log dosya adı ve satır numarası versin.
- **Tek `.sma` dosyasının boyutu 1 MB'ın (1.000.000 bayt) altında kalmalı.** Panel ya da derleyici sınırı
  büyük dosyada sorun çıkardı; çok büyük modu birkaç eklentiye böl.
- **Panel log adlarını farklı veriyor.** Logda farklı bir eklenti adı görmek, eklentinin iki kez yüklendiği
  anlamına gelmez. Eklentilerin birbirini **dosya adıyla değil, `register_plugin` başlığıyla** bulmasını sağla:
  `is_plugin_loaded("Baslik")` kullan.
- **Kurulumda eski dosyalar kalıyor.** Sürüm değiştirince adı değişen dosyaları (eski `.amxx`, eski web
  klasörü) OKU dosyasında tek tek "SİL" diye yaz. İsim çakışmasını önlemek için büyük değişiklikte yeni ad
  kullan (ör. `vex_tab02` → `vex_tab06`).

## 3. FastDL / web hostu (çok önemli)

- FastDL adresi: `http://f16.oyunyoneticisi.biz/cstrike/` (sadece `http`).
- **Sunucunun oyun sırasında yazdığı dosyalar FastDL'ye ancak 15–30 dakikada bir kopyalanıyor.**
  Sonuçları:
  - Sunucunun canlı yazdığı bir dosyayı (json/js veri dosyası, sıralama dosyası) web sayfasından okuyup
    **anlık veri bekleme.** 15–30 dakika eski veri gelir.
  - Oyunculara indirilecek her dosya (model, ses, sprite, harita) hem sunucuda hem FastDL'de olmalı.
- Web tarafında **PHP veya veritabanı olduğu bilinmiyor.** Sunucu tarafı kod (PHP) varsayma; sayfalar
  statik HTML/JS olmalı.

## 4. MOTD (oyun içi tarayıcı) kuralları

Oyunda web sayfası (`show_motd`) göstereceksen:

- **İki farklı tarayıcı var:**
  - Steam'siz istemciler eski bir Chromium kullanıyor (yaklaşık Chromium 18): ES5 yaz; `let/const`, ok
    fonksiyonu, `fetch`, `Promise`, template string yok. `XMLHttpRequest` kullan.
  - Steam'in yeni sürümünde modern bir tarayıcı var. Bu tarayıcı `localStorage`'ı kalıcı tutuyor; önbellekteki
    eski veri gerçek veriyi ezmesin.
- **Açık MOTD penceresi, sunucudan gelen yeni adresi YOK SAYAR.** Pencere açıkken `show_motd` ile içeriği
  güncelleyemezsin. Canlı güncelleme için sayfanın kendisi bir kanal dinlemeli.
- **Adres uzunluğu sınırlı:** veriyi URL'nin `#` kısmında taşıyorsan yaklaşık **1390 karakteri** geçme.
  Uzun listeler (32 oyuncu, pazar ilanları, sıralamalar) sığmaz ve **sessizce kesilir**. Liste kesilmesini
  mutlaka ele al.
- Sayfa dosyalarına sürüm etiketi koy (`t06ui.js?v=105`); yoksa oyuncular eski JS'i önbellekten kullanır.
- MOTD sayfasına gizli anahtar koyarsan, komutları o anahtarla **imzala** (SHA-256) ve sıra numarası ile
  tekrar saldırısını engelle. Anahtarı herkese açık kanala hiç yazma.

## 5. Dışarıyla haberleşme (relay) sınırları

- **ntfy.sh** (ücretsiz): sunucu IP'si başına **günde yaklaşık 250 mesaj**, ayrıca ilk 60 istekten sonra
  ~5 saniyede 1 istek sınırı var. Sunucudan oyunculara giden her cevap bu sınıra sayılır; 32 oyunculu
  sunucuda saatler içinde dolar. Oyuncunun kendi tarayıcısından gönderdiği mesajlar ise oyuncunun IP'sine
  sayılır.
- Herkese açık MQTT broker'ları (ör. `broker.emqx.io`, sunucu TCP 1883, sayfa `ws://...:8083/mqtt`) günlük
  sınır koymuyor. Ancak **çalışma garantisi yok** ve hostun 1883 portuna izin verdiği **doğrulanmadı.**
  Her zaman yedek yol (ntfy veya oyun içi sohbet) bırak.
- Herkese açık kanaldan giden veriyi oyuncuya özel anahtarla **şifrele.**

## 6. AMXX kodlama kuralları (yaşanan hatalardan)

- **Stack hatası (`Run time error 3: stack error`):** büyük yerel diziler ve iç içe forward'lar yığını
  taşırıyor. Her eklentiye `#pragma dynamic 32768` ekle; büyük tamponları `static` yap.
- `state` Pawn'da ayrılmış kelimedir; parametre ya da değişken adı olarak kullanma.
- `nvault`: harita sonunda (`plugin_end`) kasa kapanmış olabilir. Kaydetmeden önce kasayı adıyla yeniden aç,
  kaydet, kapat; geçersiz tutamaçla (`INVALID_HANDLE`) `nvault_close` çağırma.
- **Cvar pointer'ları** `plugin_init` sırasında başka eklentinin cvar'ı henüz yoksa geçersiz kalır
  (`invalid cvar pointer`). Kullanmadan önce kontrol et, gerekirse adıyla yeniden al.
- Bir eklenti başka eklentinin native'ini kullanıyorsa `set_native_filter` ile o eklenti yokken de
  yüklenebilir olsun. Ama asıl işlevi (ör. HUD'da hasar sayısı) **ana eklentiye** koy; yardımcı eklenti
  yüklenmezse özellik tamamen kaybolmasın.
- **Asset guard:** eksik bir model/ses/sprite tüm özelliği kapatmasın. `file_exists` ile kontrol et, opsiyonel
  efektlerde oyunun kendi dosyasına düş (`sprites/smoke.spr`, `sprites/zerogxplode.spr` gibi), eksik dosyayı
  logda adıyla yaz.
- **Precache sınırları:** model+sprite toplamı 512 (güvenli hedef ~450), ses ~512. Gereksiz model yükleme;
  silahlarda mümkünse orijinal CS 1.6 modellerini kullan, oyuncunun indirdiği dosyaları az tut.
- **HUD yazı tipi Türkçe büyük harfleri (İ, Ş, Ğ) bozuk gösteriyor:** HUD/DHUD'da ASCII kullan.
  Orijinal sarı orta yazı için `client_print(id, print_center, ...)`.
- `client_cmd` Steam istemcilerde birçok komut için engelleniyor; oyuncu ayarını zorlamaya güvenme.
- Her eklentide bir **durum konsol komutu** olsun (ör. `vex_tab06`, `zc_modules`): bağlantı, kapalı modül,
  eksik dosya bilgisini yazsın. Sorunu sunucu sahibi bu çıktıyla bildirebilsin.

## 7. 32 oyuncu ve performans

- Mod 32 oyuncuda takılmadan çalışmalı. Ağır işleri tick başına sınırla (ör. 50 ms'de en fazla 4 oyuncu);
  aynı anda 32 kişiye toplu iş yapma.
- Her karede (`PreThink`, `CmdStart`) pahalı iş (dosya, hash, string arama) yapma.
- Test: botlarla 32 kişi doldur, kare süresi ve fps'i ölç.

## 8. Teslim paketi (sunucu sahibinin beklentisi)

- Sunucu sahibiyle **Türkçe** konuş; bütün açıklamalar, OKU dosyası ve oyun içi metinler Türkçe olsun
  (oyun içinde ASCII Türkçe).
- Her sürüm için tek bir zip hazırla:
  - derlenmiş `.amxx` dosyaları ve tüm `.sma` kaynakları (+ include)
  - tüm `.cfg` ve `.ini` dosyaları, dil dosyaları
  - web klasörü
  - Türkçe `OKU_vX.txt`: neyin neden değiştiği, kurulum adımları, silinecek eski dosyalar, kontrol komutları
- Bütün ayarlar tek bir cfg dosyasında, satır satır Türkçe açıklamalı olsun.
- Test etmediğin bir şeyi "test edildi" diye yazma. Test edilmediyse OKU'da açıkça belirt.
- Güvenlik: oyuncular birbirinin verisine erişememeli, komutlar taklit edilememeli, yönetici işlemleri
  sunucuda yetki kontrolünden geçmeli.
