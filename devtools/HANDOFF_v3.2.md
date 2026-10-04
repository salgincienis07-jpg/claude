# Vexmira v3.2 - yapilacaklar (sahibin istegi, 2026-10-04)

Temel: sahibin "Vexmira_Zombie_v3.1_FINAL.zip" paketi, commit b3b629f (tek dosya .sma, VERSION 3.2-dev).
Bu surum daha once hic sunucuda denenmemisti; 300 sn / 16 botluk ilk testte 0 calisma hatasi, ama asagidakiler eksik/bozuk.
Kurallar: devtools/HANDOFF_v3.1.md (tek .sma dosyasi, tek cfg, EN+TR, Turkce harfsiz, derleme 0/0, botlu test).

1. OZEL SILAH HATASI: listenin sonundaki ozel silahlar (8-15. slotlar, sonradan eklenen) alininca mermi cikmiyor ve
   sonra TUM silahlar bozuluyor. Kok sebebi bul (NUM_SPECIAL 16 tablolar, vex_sw cfg okuma, deploy/clip/atis araligi
   kancalari, oyuncu durum dizileri), duzelt, 16 slotun hepsini sunucuda dene.
2. LAZER SOKME: aninda olmasin; ilerleme cubugu (BarTime) + sure (vex_lm_take_time, varsayilan 2 sn); uzaklasinca /
   nisani cekince / hasar alinca / olunce / round bitince iptal.
3. LAZER MAYINI MENUDEN KALKSIN (market, say komutlari, bind'lar calismaya devam etsin).
4. METEOR EVENTI: cok fazla meteor dusuyor -> en az yarisi; meteor oyuncuya DIREKT isabet etmesin, 96-220 birim
   onune/yanina dussun, once kisa uyari efekti; adil hasar.
5. MENU: cok karmasik, gereksiz cok sey var (ana menu ~22 madde). Tek sayfa, en fazla 8 net madde, mantikli gruplar,
   tutarli EN/TR basliklar, her alt menude geri/cikis; eszsiz ve belirgin gorunum.
6. VIP: cok az ozellik var -> VIP almak icin gercek sebep (AP/XP/VC carpani, her round ucretsiz paket, ekstra ziplama,
   ozel kozmetik/chat etiketi, indirimler...), pay-to-win olmadan; VIP menusunde net bilgi sayfasi; hepsi cfg'de.
7. MESAJLAR: gereksiz otomatik bilgilendirme mesajlari kalksin; yerine belli araliklarla chatte EN/TR ipuclari
   (vex_chat_tip_interval, varsayilan 90 sn, 0 = kapali).
8. DENGE: silahlar cok guclu, zombiler gucsuz, nemesis/assassin vb. cok zayif. Para (AP), coin (VC), XP, fiyatlar,
   zombi siniflari, yetenekler, bosslar - hepsini sayilarla incele ve tutarli denge kur; kod varsayilani = cfg degeri;
   eski -> yeni tablo devtools/plugin/BALANCE_v32.md.
9. KOD INCELEMESI: hata, eksik, bozukluk, mantik hatasi kalmasin (dizi sinirlari, round/olum sifirlamalari, menu
   handler'lari, cfg <-> kod <-> lang tutarliligi).
10. HUD GRAFIKLERI / DOSYALAR: grafik HUD modunda (vex_hud_style 1) bircok parca grafigi olmadigi icin tamamen gizleniyor;
   hicbir parca kaybolmasin (grafigi olamayan parca kisa yazi), gereken sprite'lar uretilsin; cfg'nin isaret ettigi ama
   pakette olmayan dosyalar (pence v_claw_*, p_ silah modelleri, hook/egg/spore, vex_tank, x.wav, mp3...) ya uretilsin ya da
   var olan / bos (orijinale don) varsayilana cekilsin -> temiz kurulumda "bulunamadi" uyarisi olmasin.
Sonra: tek amiral gemisi harita (etkilesimli, eszsiz, buyuk, yuksek FPS) - plan devtools/PROGRESS_v3.md.

## Ek istekler (2026-10-04 aksam) - 4. asama
11. MENU RENKLERI: tum menuler renkli ve dikkat cekici; BEYAZ ve GRI KULLANILMAYACAK (CS 1.6 menu renkleri sadece
    \r kirmizi, \y sari, \w beyaz, \d gri). Baslik: kirmizi "VEXMIRA" + sari baslik; numaralar kirmizi; madde adlari sari;
    fiyat/seviye/durum kirmizi; kilitli maddeler gri DEGIL: tiklanabilir kalsin, "[KILITLI]" etiketi, secilince mesaj
    (menu callback ITEM_DISABLED kullanma -> gri olur). Ayiricilar kirmizi. Chat mesajlari/ipuclari renkli (yesil/takim/sari).
12. UST ROUND BILGISI + SAG HUD + MVP: duz yazi degil, sprite / ozel tasarim. Gercek sprite olabilenler sprite olsun
    (MVP: kafa ustu sprite amblem + efekt; kafa ustu barlar; boss bari), ekran HUD'u icin motorun izin verdigi en
    gorsel cozum: oyunun hud.txt ikonlari (StatusIcon/Scenario), BarTime ilerleme cubuklari, cercevel renkli DHUD tasarimi.
    Eksik sprite dosyalari uretilsin (devtools/sprkit). Sinir (sunucu eklentisi ekrana keyfi 2D resim cizemez) raporda acikca.
13. HERSEYI KONTROL ET: tum ozellikler, menuler, HUD'lar, mesajlar tek tek; hicbiri unutulmasin.
