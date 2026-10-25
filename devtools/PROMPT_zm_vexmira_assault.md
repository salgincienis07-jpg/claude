# Görev: `zm_vexmira_assault` haritasını hazırla (CS 1.6 / GoldSrc, Zombie Plague, Vexmira sunucusu)

Sen deneyimli bir GoldSrc (Counter-Strike 1.6) harita tasarımcısısın. Hammer / J.A.C.K., ZHLT/VHLT
(hlcsg, hlbsp, hlvis, hlrad), WAD ve BSP sınırlarını çok iyi biliyorsun. Benim için klasik **cs_assault**
haritasını, daha önce yaptırdığım **zm_vexmira_dust2fixed** haritasıyla aynı kalitede ve aynı tarzda bir
**Zombie Plague kamp haritasına** çevireceksin. Haritanın adı **`zm_vexmira_assault`** olacak.

Bu iş bir "biraz değiştir" işi değil. Oyuncuların her gün oynayacağı, sunucunun vitrini olacak bir harita.
Her detay özenli olmalı. Acele etme, kısa yol kullanma, ama hiçbir şeyi de abartıp FPS'i öldürme.
Teslimden önce aşağıdaki **kontrol listesinin tamamını** kendin uygula.

---

## 1. Tarzım ve beklentilerim (dust2fixed'de ne yaptık, aynısını bekliyorum)

- **Orijinal düzen 1:1 korunur.** cs_assault'un tanıdık yerleri (depo / warehouse, çatı, rampa, garaj
  kapıları, ofis, havalandırma kanalları, dış avlu, konteynerler) yerinde kalır; oyuncu haritayı tanımalı.
  Ölçüler, doku hizalamaları ve kat yükseklikleri bozulmaz.
- **Rehine / kurtarma mantığı tamamen kaldırılır:** `hostage_entity`, `func_hostage_rescue`,
  `info_hostage_rescue`, `func_buyzone`, `info_map_parameters`, `trigger_camera`, `func_vip_safetyzone`
  gibi CS'ye özel varlıklar haritada kalmaz.
- **Karanlık, gergin zombi atmosferi:** aydınlatma loş ama oynanabilir. Tamamen karanlık köşe yok;
  sarı-turuncu sokak lambaları, yer yer kırmızı alarm ışıkları ve titrek floresanlar
  (`light` style 1 / 10 gibi). Duvarlarda kan izleri, uyarı levhaları, "KARANTINA" / "QUARANTINE"
  bantları, zombi tehlike işaretleri.
- **VEXMIRA kimliği:** en az 3 yerde "VEXMIRA" tabelası, giriş noktasında haritanın adı ve
  **"MapBy:SmurfSexy"** imzası. Tabelalar duvara gömülü, düz ve okunaklı olacak; doku tek parça
  ve gerilmemiş olacak.
- **Dokular haritanın içine gömülü (embedded):** oyuncu ek `.wad` indirmeyecek. cs_assault'un
  orijinal dokularının yerine görünüşü benzer, kendi çizdiğin / ürettiğin dokuları koy. Hepsinin
  boyutu 16'nın katı olmalı (GoldSrc kuralı), en büyük doku 256x256 (tabela için 512x128'e kadar).
  Kayıp doku (mor-siyah dama) **tek bir tane bile** olmayacak.
- `worldspawn` mesajı: `zm_vexmira_assault - MapBy:SmurfSexy - Vexmira Zombie`.

## 2. Zombie Plague eklemeleri (asıl iş)

Her yapı **düz bir zeminde, tam yüksekliği boş bir alanda** durmalı; başka bir yapıya veya orijinal
duvara gömülmemeli, havada kalmamalı, oyuncu takılmamalı.

1. **İki katlı kamp kaleleri (en az 3 adet):**
   - Zemin kat bir iç duvar ve kapıyla ikiye bölünür.
   - Arka odada 48x48'lik bir kapak ve oradan merdivenle üst kata çıkılır.
   - Üst kat camlı savunma odasıdır: bel hizasında korkuluk, etrafta kırılabilir camlar
     (`func_breakable`, material Glass), köşelerde çelik dikmeler, çatı.
   - Ön kapının önünde iki yan duvarlı bir "lazer girişi" (vestibül) olur; buraya lazer mayını kurulacak.
2. **Kapılar:**
   - Kamp kapıları `func_door` olacak ve `netname` değeri **`vxbd`** olacak.
   - Eklentim bu adı arıyor: insanlar E ile açıp kapatıyor, zombiler kırıyor.
   - Kapılar kendi kendine açılmasın: "use only", wait -1, makul hız.
   - Ahşap barikat kapılar `func_breakable` (material Wood, 400–600 HP) olacak.
3. **Depo (warehouse) sığınağı:**
   - Çelik ana kapı (`vxbd`), yan tarafta kırılabilir tahta barikat, camlı pencereler.
   - İçeride sandıklardan bir asma kat olacak.
   - Çatısı yürünebilir olacak; etrafında korkuluk ve dışarıdan çıkan bir merdiven (`func_ladder`) bulunacak.
4. **Gözetleme kuleleri (2–3 adet):**
   - Tahta direkler, kapaklı platform, içeriden merdiven ve kırılabilir camlı kulübe.
5. **Sandık kaleleri:** U şeklinde, 2 sandık yüksekliğinde, basamak sandıkla çıkılan saklanma köşeleri.
6. **Boss meydanı (çok önemli):**
   - Haritanın kenarında, mevcut oynanışı bozmayan geniş bir alan (dış avlu veya otopark tarafı).
   - Döşeli meydan, ortada 3 basamaklı kaide üstünde bir heykel, kaidenin 4 köşesinde mangal / ateş sepeti.
   - Kuzey duvarında sütunlu bir revak ve sütunların arasında Vexmira sancakları.
   - Yükseltilmiş bir savunma terası; meydana tek geniş merdivenle inilecek, waist-high korkulukları olacak.
   - Boss savaşında kaçışmak için meydanda alçak duvarlar ve sandıklar.
   - Meydan gökyüzü kapağına kadar duvarla kapalı olacak (FPS için diğer bölgeleri görmemeli).
   - Boss başlayınca herkes buraya ışınlanıyor; spawn noktalarını `.ini` dosyasındaki `[arena]`
     bölümüne yaz (aşağıda).
7. **Gizli yollar:** en az 1 gizli tünel veya havalandırma kısayolu (dust2fixed'deki "A short gizli tünel" gibi).
8. **Doğuş noktaları:**
   - **32 CT (`info_player_start`) + 32 T (`info_player_deathmatch`)**.
   - Hepsi zeminde, birbirinden en az 48 birim uzakta, tavana ve duvara gömülmemiş olacak.
   - İnsanlar ve zombiler aynı noktada doğmayacak.
9. **Merdivenler:** `func_ladder` + görsel merdiven dokusu. Her merdivenden inip çıkılabildiğini test et.
10. **Işıklar:** her kalenin, kulenin ve meydanın kendi ışığı olacak. `light_environment`
    gece / alacakaranlık tonunda olacak.

## 3. Eklenti ile konuşma (harita sözleşmesi — isimler birebir aynı olacak)

**Eklenti haritaya** şu adlarla haber verir; bu `targetname`'leri kullanırsan tetiklenir:
`vex_round_start`, `vex_freeze_end`, `vex_infection`, `vex_boss`, `vex_boss_dead`, `vex_nemesis`,
`vex_assassin`, `vex_survivor`, `vex_lasthuman`, `vex_win_humans`, `vex_win_zombies`, `vex_minute`.
- `vex_round_start` iki kez gelebilir; sıfırlama mantığın iki kez çalışsa da aynı sonucu vermeli.
- Örnek kullanımlar: boss gelince alarm ışığı ve siren; son insan kalınca kırmızı ışıklar.

**Harita eklentiye** şu adlarla haber verir. Sınıf **mutlaka `trigger_relay`** olacak:
- `vexcmd_msg_<anahtar>`: `.ini` dosyasındaki `[messages]` metnini herkese gösterir.
- `vexcmd_reward_h_<n>` / `vexcmd_reward_z_<n>`: yaşayan insanlara / zombilere n ammo pack verir (n ≤ 50).
- `vexcmd_obj_<1-3>_done`: n. görev tamamlandı.

İstersen 1–3 küçük görev ekle. Örnek: "jeneratörü çalıştır" (`func_button` → relay → ışıklar + `vexcmd_obj_1_done`).

**Senaryo dosyası:** `cstrike/addons/amxmodx/configs/vexmira_maps/zm_vexmira_assault.ini`
(latin-1 / ASCII, **Türkçe harf yok**: ı→i, ş→s, ğ→g, ü→u, ö→o, ç→c):
```
; zm_vexmira_assault - assault zombie camp edition (latin-1, Turkce harfsiz) - MapBy:SmurfSexy
[info]
name_en = Vexmira Assault ZM
name_tr = Vexmira Assault ZM
roundtime = 5
[story_en]
line = ... (en fazla 6 satir, kisa ve atmosferik)
[story_tr]
line = ...
[objective_en]
line = ... (en fazla 3 gorev)
[objective_tr]
line = ...
[messages]
anahtar = English text | Turkce metin
[events]
boss 0 hedef_targetname
[markers]
Boss arena | Boss arenasi = x y z
Warehouse fort | Depo kalesi = x y z
[arena]
boss = x y z aci
human = x y z aci        ; 32 satir, meydanda 8x4 izgara, 80 birim aralik, zemin + 1
```
`[markers]` koordinatı oyuncunun göz hizasında (zeminden yaklaşık +64) olacak. En fazla 4 işaret.

## 4. Performans ve motor sınırları (taviz yok)

- **FPS dust2 seviyesinde kalacak.** Hedef r_speeds: her yerde **wpoly < 800**, kalabalık yerlerde
  bile < 1000; epoly hesaba dahil.
- Uzun görüş hatlarını duvar / perde / bina ile kes. Meydan diğer bölgeleri görmemeli.
- Sadece dekor olan ve hiçbir şeyi kapatmayan her şey **tek bir `func_detail` / `func_wall`** içine.
  Bu, vis bölünmesi olmaması ve ucuz olması için.
- Gökyüzüne bakan dış yüzeyler `sky`; görünmeyen yüzeyler `NULL` / `SKIP`.
- Sınırlar: brush model < 400 (motor sınırı 512), entity < 900, clipnode / marksurface /
  lightdata limitlerinin altında. Derleme logunda **tek bir uyarı bile** kalmayacak.
- **Leak yok.** hlvis **full** (fast değil), hlrad **final** kalite (`-extra`, bounce 2+).
- BSP dosyası mümkünse **4 MB altında** (oyuncu hızlı indirsin).
- Kırılabilir camların / tahtaların sesi ve parçaları doğru materyalde olacak (Glass / Wood / Metal).

## 5. Teslim etmen gerekenler

1. `zm_vexmira_assault.bsp` (dokular gömülü, ek wad yok).
2. Kaynak dosya (`.rmf` veya `.map`). Ben sonra düzenleyebileyim.
3. `zm_vexmira_assault.ini` (yukarıdaki biçimde).
4. `zm_vexmira_assault.res`: gerekiyorsa sky dosyaları ve ek sprite / ses. Boşsa yazma.
5. Kısa bir değişiklik listesi: hangi kale nerede, kapılar, gizli yol, boss meydanı, koordinatlar.
6. Derleme logu (hlcsg / hlbsp / hlvis / hlrad çıktısı): uyarısız.
7. En az 8 ekran görüntüsü: her kale, depo, kule, meydan, gizli yol, spawn alanları, r_speeds açıkken
   en kalabalık 2 nokta.

## 6. Teslimden önce kontrol listesi (hepsini kendin uygula)

- [ ] Harita `sv_cheats 1`, `r_speeds 1`, `developer 1` ile açılıyor; konsolda hiç hata / eksik dosya yok.
- [ ] Kayıp doku yok, gerilmiş / yanlış hizalı doku yok, tabelalar okunaklı.
- [ ] 32 + 32 doğuş noktasının hepsinde doğulabiliyor (`bot_add` ile 32 bot ve en az 2 tur).
- [ ] Her `vxbd` kapı E ile açılıp kapanıyor ve kırılınca geri gelmiyor. Tur yenilenince tüm kapılar,
      camlar ve barikatlar eski haline dönüyor.
- [ ] Her merdivenden çıkılıp iniliyor; hiçbir yerde takılma, sıkışma, havada kalma, görünmez duvar yok.
- [ ] Kalelere zombilerin girebileceği en az bir yol var (kapı kırma / cam kırma / barikat). Hiçbir yer
      %100 kapatılamıyor (kamp var ama "ölümsüz köşe" yok).
- [ ] Boss meydanındaki `[arena]` noktalarına ışınlanınca kimse duvara / birbirine gömülmüyor.
- [ ] En kötü noktada wpoly < 1000; FPS düşüşü yok.
- [ ] `.ini` Türkçe harfsiz, latin-1 kodlamada; tüm `targetname`'ler sözleşmeyle birebir aynı.
- [ ] Dosya boyutu makul; gereksiz ses, model veya sprite eklenmemiş.

Bir şeyden emin değilsen kendi kararını uydurma. Sor ya da iki seçeneği açıklayıp ekran görüntüsüyle göster.
Kalite, hız ve tutarlılık bu haritanın her köşesinde aynı olmalı.
