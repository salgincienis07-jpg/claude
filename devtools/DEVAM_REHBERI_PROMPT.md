# VEXMIRA ZOMBIE — DEVAM REHBERİ (Başka bir yapay zekâya verilecek prompt)

> Bu dosyayı olduğu gibi yeni yapay zekâya yapıştır. Paketteki tüm dosyalar bu rehberde anlatılan yapıdadır.

---

## 0. ROLÜN VE KURALLAR

Sen bir **CS 1.6 AMX Mod X eklenti geliştiricisisin**. Sunucu sahibi Türkçe konuşur; ona **Türkçe**, kısa ve net cevap ver.

- Sunucu: **ReHLDS + ReGameDLL 5.30 + Metamod-R + AMX Mod X 1.10 + ReAPI 5.24/5.26**.
- Hosting: **OyunYöneticisi paneli** (panel42.oyunyoneticisi.com). Panelde:
  - **Dosya Yönetici (ftp)** var: klasör gezilebiliyor, dosya **yüklenebiliyor** (sahibi zip yüklemiş, açma özelliği belirsiz).
  - **Eklentiler → Eklenti Yükle**: `.sma` dosyasını **kendisi derliyor**, dosya adına sayı öneki ekliyor, `_` ve "sma" harflerini siliyor (örn. `vx42_plasma` → `1791780721_vx42pla.amxx`) ve `plugins.ini`'ye kendi satırını yazıyor. `.amxx` yüklenince "Invalid Plugin" hatası çıkıyor.
  - **Modül Ayarları**: GeoIP **AÇIK** olmalı (eklenti GeoIP kullanıyor). SQLite açık kalsın, diğerleri (Sockets, Regex, JSON, MySQL, EasyHTTP) gerekmez.
- **Tüm model/ses/sprite dosyaları sunucuda zaten yüklü.** Sahibe sadece eklenti + config dosyalarını gönder (asset gönderme).
- Sahibi **tek dosya** istiyor: tüm Vexmira işlevleri **tek `zombie_core.sma`** içinde, include/ek dosya gerektirmeden; config, dil ve harita ini dosyaları da içine gömülü (ilk açılışta yoksa kendisi yazar).
- Amaç: **oyuncu çekmek** (sunucu boş). Her şey eksiksiz, düzgün, şık, FPS dostu olmalı.

---

## 1. PAKETTEKİ DOSYALAR

```
addons/amxmodx/
  scripting/
    zombie_core.sma          <-- ÜRETİLMİŞ TEK DOSYA (4.3.0-Single). ŞU AN DERLENİYOR + ÇALIŞIYOR (aşağıya bak)
    vexmira_core.sma         <-- çok-dosyalı 4.2.0 çekirdek (zombie_core bunun üzerinden üretiliyor)
    vx42_*.sma (14 adet)     <-- eşya/silah eklentileri: janus7 plasma thunderbolt ethereal salamander bow
                                 dragonsword katana lightsaber horseaxe hev jetpack minigun diagnostic
    include/vex_*.inc        <-- core'un include'ları (asset_guard, community_core, community, event_sounds,
                                 normal_world, restore_features)
    upstream/*.sma           <-- silahların orijinal CSO kaynakları (referans)
  plugins/
    zombie_core.amxx         <-- tek dosyanın derlenmiş hali (test edildi)
    vexmira_core.amxx, vx42_*.amxx  <-- çok-dosyalı 4.2.0 sürümü (artık kullanılmayacak)
  configs/
    vexmira.cfg              <-- tüm ayarlar (vex_res ... model/ses yolları, cvar'lar)
    plugins-vexmira42.ini    <-- çok-dosyalı sürümün listesi (tek dosyada GEREKMEZ)
    vexmira_maps/*.ini       <-- harita senaryoları (zm_vexmira_icefy, _dust, _7door)
    vexmira_motd_tr.html / _en.html
  data/lang/vexmira_zombie.txt   <-- dil dosyası [en] + [tr]
devtools/
  single/make_single.py      <-- ÇOK-DOSYALI kaynaklardan zombie_core.sma ÜRETEN araç (Python 3)
  single/pawntok.py          <-- Pawn tokenizer (make_single.py kullanıyor)
  single/menu_style.pwn      <-- yeni menü renk/stil yardımcıları (YARIM, henüz bağlanmadı)
  owner_ref/vexmira_old_paths.cfg <-- sahibinin ESKİ cfg'si (eski model/ses/efekt yolları referansı)
  plugin/build_plugin.sh     <-- derleme betiği (yolları kendi ortamına göre düzelt)
compiler/                    <-- AMXX 1.10 Linux derleyici (amxxpc + amxxpc32.so) + include/ (ReAPI dahil)
panel_stdinc/                <-- SADECE stok include'lar (ReAPI yok) – tek dosyanın panelde derlenebildiğini test etmek için
```

### Derleme
```bash
cd compiler && ./amxxpc /TAM/YOL/zombie_core.sma -i/TAM/YOL/panel_stdinc -o/TAM/YOL/zombie_core.amxx
```
(`zombie_core.sma` stok include'larla — amxmodx, amxmisc, engine, fakemeta, fakemeta_util, hamsandwich, fun, cstrike, xs, nvault, geoip — derlenir; ReAPI ve vex_*.inc içine gömülüdür. Şu an **0 hata**.)

### Yeniden üretme (kaynakta değişiklik yaptıysan)
```bash
python3 devtools/single/make_single.py --out addons/amxmodx/scripting/zombie_core.sma --inc compiler/include
```
> `make_single.py` içindeki `SP`/`DEF_INC` yollarını kendi ortamına göre düzelt. Değişiklikleri **ya çok-dosyalı kaynaklarda yapıp yeniden üret** ya da doğrudan `zombie_core.sma` üzerinde yap (o zaman artık üretme, tek dosyayı ana kaynak kabul et — ÖNERİLEN: bundan sonra doğrudan zombie_core.sma'yı düzenle, daha basit).

---

## 2. ŞU ANKİ DURUM (SON TEST)

`zombie_core.amxx` tek başına (başka Vexmira eklentisi yokken) test sunucusunda, zm_vexmira_icefy, 6 bot:
- **Çökme yok**, runtime error yok, `modul: 14/14 acik`.
- Precache: **sound 477/512**, model 421/512, generic 363/512 (sınıra yakın – ses EKLEME, eklersen başka bir şey çıkar).
- vexmira.cfg yüklendi (571 satır), harita senaryosu yüklendi.
- Uyarı: `sprites/weapon_m134.txt` eksik (minigun HUD) – zararsız, atlanıyor.

**Doğrulanmadı (test edilmedi):** gömülü config/dil dosyalarının "yoksa yaz" özelliği, menüler, satın almalar (tek dosyada), kozmetik görünüm, boss raundu, FPS ölçümü. Çok-dosyalı 4.2.0'da bunlar test edildi ve çalışıyordu (debug komutlarıyla: 6 özel silah, 5 bıçak, 5 CT modeli, HEV, Jetpack, kanat/pet/şapka satın alma+kuşanma+kayıt, zorla boss raundu `vex_boss <n>` + `sv_restart 1`).

---

## 3. KALAN İŞLER (ÖNCELİK SIRASIYLA)

### 3.1 Tek dosyayı doğrula ve tamamla (EN ÖNEMLİ)
1. **Gömülü dosyaların yazılması:** sunucuda `configs/vexmira.cfg`, `configs/vexmira_maps/*.ini`, `configs/vexmira_motd_*.html`, `data/lang/vexmira_zombie.txt` YOKKEN eklentiyi başlat → `plugin_precache`'te dosyaları yazıyor mu, dil dosyası **ilk haritada** yükleniyor mu (`register_dictionary` yazmadan SONRA çağrılmalı), mevcut dosyalar **üzerine yazılmıyor** mu kontrol et. Zorla yeniden yazma: cvar/komut (`zc_rewrite_configs` / `zc_writeconfigs`) var mı bak, yoksa ekle.
2. **Satın alma / menü testi (tek dosyada):** her özel silah (Janus VII, Plasma, Thunderbolt, Ethereal, Salamander, Compound Bow), 4 bıçak (Dragon Sword, Dual Katana, Light Saber, Horse Axe) + "CS:GO Butterfly", 5 CT modeli (vex_soldier, vex_gign, vex_halo, vex_spetsnaz, vex_gsg9), HEV Suit, Jetpack (+Bazooka), Minigun (sadece Survivor). AP/VC düşüyor mu, eşya veriliyor mu, kuşanma kaydı (nvault) harita değişiminde kalıyor mu.
   - Komutlar: `/menu` (M), `/shop`, `/ozel` `/sw` `/ozelsilah`, `/bicak` `/knife`, `/model` `/skin` `/karakter`, `/jetpack` `/jet`, `/hev` `/zirh`, `/cosmetic`.
   - Eskiden görülen hata: "Bunu su an alamazsin" (SHOP_UNAVAIL) — sebebi eşya eklentilerinin yüklenmemesiydi (dosya koruma/precache taşması/panel bozulması). Tek dosyada bileşen tablosu (ZcCall) ile çağrılıyor; her bileşenin `give` sonucunu kontrol et.
3. **Kopya koruması:** eski Vexmira eklentileri (vexmira_zombie*, vexmira_core*, vex_*.amxx, vx42_*.amxx, sayı önekli kopyalar) aynı anda yüklüyse onları `pause` edip konsola uyarı yazmalı; **kendini** (panelin verdiği isimle bile, örn. `1791..._zombiecore.amxx`) asla durdurmamalı. Panel ismini değiştirse de çalışmalı — **hiçbir yerde dosya adına göre arama olmamalı.**
4. **Boss raundu:** `vex_boss <n>` + `sv_restart 1` ile zorla; boss can barı, sesleri, yetenek efektleri, faz değişimleri çalışıyor mu.

### 3.2 Menü tasarımı (sahibinin isteği)
- Menüler **sade, anlaşılır, modern**. Hepsi sarı-kırmızı OLMASIN. Renk planı:
  - Başlık: `\w` beyaz + vurgu kelime `\y` sarı.
  - Eşya adı: `\w` beyaz.
  - Fiyat/durum: `\R` ile sağa yaslı; fiyat `\y`, sahip/kilitli/bilgi `\d` gri, **`\r` kırmızı SADECE uyarı** (AP/VC yetmiyor, kilitli).
  - Ayraç/açıklama satırları `\d`. Kuşanılan: `\y*` veya `\d[KUSANILDI]`.
  - Her menüde Geri / Çıkış. TR ve EN aynı düzen.
- Sohbet mesajları: `^4` yeşil vurgu, `^3` isim/takım rengi, `^1` normal — tek renk olmasın.
- `devtools/single/menu_style.pwn` yarım bir yardımcı; tamamla veya kendi yönteminle uygula. Tüm menüleri (M ana menü → Market, Silahlar/Teçhizat, Sınıf/Meslek, Karakter, Ödüller, Kozmetik [İnsan/CT modelleri, Bıçak koleksiyonu, Kanat, Şapka, Pet, İz, Efektler], Ayarlar, VIP/Admin) tek tek gözden geçir; hiçbir satırda `ML_NOTFOUND` kalmasın (dil dosyasındaki [en] ve [tr] anahtarlarını kontrol et).

### 3.3 Kozmetikler
- Kanatlar sırta **düz ve sabit** (MOVETYPE_FOLLOW + aiment, açı 0, cfg ofsetleri `vex_wing_*`).
- Şapkalar kafanın üstünde.
- Petler **karakterin içine girmemeli**: yanında (≥26 birim yan mesafe), hafif süzülme, idle animasyonu (sequence/framerate).
- Her kozmetiği takan HERKESTE tam ve düzgün görünmeli (kalite düşürme yok). Kozmetiği olmayan oyuncu için boşuna işlem yapma (performans).
- Kozmetik modeller: `models/vexmira/cos/` (bizim) ve `models/vexmira/community/cosmetics/` (topluluk).

### 3.4 Oyuncu çekme / ilk izlenim
- `vex_hostname` (cfg) varsayılanı: `VEXMIRA ZOMBIE [TR] | CSO SILAHLAR + BOSS + HIKAYE MAP` (63 karakter sınırı; `vex_hostname_dynamic` raunt etiketi sığmazsa eklemiyor).
- İlk giriş: kısa hoş geldin + net `/menu` ipucu, hızlı raunt başlangıcı; yeni oyuncu bonusu mekanizması varsa çalışır olsun (para ile güç satma YOK).
- **Sohbet spamını azalt:** sahibinin log'unda neredeyse her raunt `[IPUCU]` + reklam satırı çıkıyordu; ipucu sıklığını düşür (örn. 3-4 dakikada bir), aynı ipucunu art arda gösterme.

### 3.5 Performans (FPS)
- Birleştirmede aynı forward'lar (PreThink/PostThink/AddToFullPack/CmdStart/think) tek dispatcher'da olmalı, erken return.
- Her karede tüm entity'leri dolaşan döngü olmasın; HUD güncellemelerini makul aralığa çek (0.1–0.5 sn), task sayısını düşük tut.
- Test log'unda "performance issue ... executed more than X ms" uyarısı oyun sırasında olmamalı (sadece precache'te normal).

### 3.6 Ses yuvası (512 sınırı) — DİKKAT
- Şu an 477/512. `vex_res SOUND_BUDGET 110`, `BOSS_PRELOAD 3`. Silah eklentilerinin sadece-model sesleri (`draw/clipin/idle`) `precache_generic` ile indiriliyor (yuva harcamıyor). Yeni ses eklemen gerekirse aynı yöntemi kullan; 512'yi geçerse sunucu `Host_Error ... over the 512 limit` ile **çöker**.
- 7door ve dust haritaları test edilmedi; birkaç ses fazla olabilir — kontrol et.

### 3.7 Diğer bilinen konular
- Lazer mayın: model `models/vexmira/world/lasermine.mdl` (cfg'de), yüzeye göre yön (düzlem normali), kurma/sökme sesleri (LM_DEPLOY / LM_PICKUP) — doğrula.
- Zombi vuruş efektleri ve sınıf yetenek sesleri cfg'de eski yollara döndürüldü (owner_ref) — oyunda kontrol.
- Sol tık sesi sorunu çözüldü (zombi pain/idle sesleri meme "bruh/vine_boom" idi; orijinallere döndü, vine_boom 6+ öldürme serisinde).
- HEV giyerken enfekte olan oyuncunun HEV modelinde kalması düzeltildi.
- CSO tarzı bildirimler, can barları, VIP/admin/MVP/son insan/alfa kafa üstü ikonları orijinal sprite'lara döndü — oyunda boyut/konum kontrolü gerekebilir.

---

## 4. SAHİBİNE TESLİM (KURULUM TALİMATI ŞABLONU)

Pakete SADECE: `zombie_core.sma`, `zombie_core.amxx`, config/dil/harita ini dosyaları, `KURULUM_TEK.txt`. (Model/ses/sprite YOK.)

KURULUM_TEK.txt içeriği şunları anlatmalı:
1. Panel → Eklentiler → Modül Ayarları: **GeoIP = Aktif**, Kaydet.
2. Dosya Yönetici ile ESKİ Vexmira dosyalarını sil: `addons/amxmodx/plugins/` içindeki `vexmira_zombie*`, `vexmira_core*`, `vex_*.amxx`, `vx42_*.amxx`, başında sayı olan tüm Vexmira kopyaları; `configs/plugins.ini` içindeki bunlara ait satırlar; `configs/plugins-vexmira.ini` ve `configs/plugins-vexmira42.ini`.
3. **Yöntem A:** Panel → Eklenti Yükle ile `zombie_core.sma` yükle (panel derler). **Yöntem B:** Dosya Yönetici ile `zombie_core.amxx`'i `addons/amxmodx/plugins/` içine yükle ve `configs/plugins.ini` sonuna `zombie_core.amxx` satırı ekle. (İkisini aynı anda yapma.)
4. Server Reset. İlk açılışta eklenti cfg/dil/harita dosyalarını eksikse kendisi yazar (var olanlara dokunmaz).
5. Konsolda `amxx plugins` → "Vexmira Zombie Core 4.3.x" **running** görünmeli. Hata/çökme olursa konsolun **son satırlarını** ve `addons/amxmodx/logs/error_*.log` içeriğini iste.

---

## 5. ÇALIŞMA ÖNERİSİ (Yeni yapay zekâ için)
1. Önce `zombie_core.sma`'yı derle, kendi test ortamın varsa (ReHLDS + ReGameDLL + AMXX 1.10 + ReAPI, botlarla) dene; yoksa kodu dikkatle oku ve mantık hatası ara.
2. Menü renk düzenini ve kozmetik/menü eksiklerini tamamla.
3. Spam/ilk izlenim/hostname ayarlarını yap.
4. Derle (0 hata), sahibine yukarıdaki paket yapısıyla gönder.
5. Her değişiklikte VERSION'u artır (örn. 4.3.1) ki sahip `amxx plugins` ile hangi sürümün yüklü olduğunu görebilsin.
