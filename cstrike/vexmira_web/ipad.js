/* VEXMIRA iPad 6.0 - opened by the game in the MOTD window. Data comes in the URL hash (see CONTRACT.md),
   item / achievement names from items.js (written by the server). Tablet & Mod: smurfsexy */
(function () {
'use strict';
var $ = function (id) { return document.getElementById(id); };
function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }
function num(v, d) { var n = parseInt(v, 10); return isNaN(n) ? (d || 0) : n; }
function fmt(n) { n = num(n); return n >= 1000000 ? (n / 1000000).toFixed(1) + 'M' : n >= 10000 ? (n / 1000).toFixed(1) + 'K' : String(n); }
function store(k, v) { try { if (v === undefined) return localStorage.getItem('vx_' + k); localStorage.setItem('vx_' + k, v); } catch (e) { return null; } return null; }

// ------------------------------------------------------------------ data
function parseHash() {
  var h = (location.hash || '').replace(/^#/, ''), o = {};
  if (!h) return null;
  h.split('&').forEach(function (p) { var i = p.indexOf('='); if (i > 0) o[p.slice(0, i)] = p.slice(i + 1); });
  return o;
}
function dec(s) { try { return decodeURIComponent(s || ''); } catch (e) { return s || ''; } }
var RAW = parseHash(), DEMO = !RAW || !RAW.n;
if (DEMO) RAW = {
  l: 'tr', pg: 'home', n: 'Kara%20Kurt', s: '76561198000000001', lv: '37', xp: '33100', xn: '32400', ap: '2350', vc: '415',
  k: '1842', i: '913', d: '640', h: '512', w: '288', b: '14', pt: '3920', vip: '1', vd: '12', r: '2', rk: '3', a: '1717247',
  iv: 'k21.c3.w5.p2.f9.z3.t1', eq: 'k1.c2.w1.p0.f1.z2.t1', dy: '5~0~5230', zu: '0~3,2,5,1,0,0,2,0,0,4,0,0,1,0,0,0,0,3,0,0,0,0,0,0', zc: '2',
  kc: '0~0~0~0', on: '18', mx: '32', mp: 'zm_vexmira_dust2fixed', rd: '12%2F30', sv: '734~18~0', ts: String(Math.floor(Date.now() / 1000)),
  t: 'Golge~58~5120;Vampir~52~4300;Kara%20Kurt~37~1842;Sessiz~33~1600;Neon~31~1505;Kabus~28~1300;Toz~25~1120;Avci~21~990;Yarasa~19~870;Duman~17~700;Kuzgun~15~650;Siper~12~420;Ayaz~10~300;Pars~8~200;Zehir~6~120',
  tt: 'Vampir~9120;Golge~8410;Kara%20Kurt~3920;Neon~3010;Kabus~2500;Avci~1990;Toz~1500;Duman~980;Yarasa~760;Ayaz~400',
  at: 'Golge~24;Vampir~21;Kara%20Kurt~15;Neon~12;Kabus~11;Avci~9;Toz~7;Duman~5;Yarasa~4;Ayaz~2'
};
var D = {
  lang: (store('lang') || dec(RAW.l) || 'tr') === 'en' ? 'en' : 'tr', page: dec(RAW.pg) || 'home', name: dec(RAW.n) || 'Player', sid: dec(RAW.s),
  lv: num(RAW.lv, 1), xp: num(RAW.xp), xn: num(RAW.xn, 1), ap: num(RAW.ap), vc: num(RAW.vc), k: num(RAW.k), inf: num(RAW.i), d: num(RAW.d),
  hs: num(RAW.h), w: num(RAW.w), b: num(RAW.b), pt: num(RAW.pt), vip: num(RAW.vip), vd: num(RAW.vd), role: num(RAW.r), rank: num(RAW.rk),
  ach: num(RAW.a), on: num(RAW.on), mx: num(RAW.mx, 32), map: dec(RAW.mp), round: dec(RAW.rd), ts: num(RAW.ts)
};
function lst(s, fields) { if (!s) return []; return dec(s.replace(/%7E/gi, '~').replace(/%3B/gi, ';')) ? s.split(';').map(function (r) { var f = r.split('~'), o = {}; fields.forEach(function (k, i) { o[k] = dec(f[i] || ''); }); return o; }) : []; }
D.top = lst(RAW.t, ['n', 'lv', 'k']); D.tt = lst(RAW.tt, ['n', 'v']); D.at = lst(RAW.at, ['n', 'v']);
function masks(s) { var o = {}; (s || '').split('.').forEach(function (p) { if (p) o[p.charAt(0)] = num(p.slice(1)); }); return o; }
D.iv = masks(dec(RAW.iv)); D.eq = masks(dec(RAW.eq));
var dy = dec(RAW.dy).split('~'); D.streak = num(dy[0]); D.claimed = num(dy[1]) === 1; D.next = num(dy[2]);
var zu = dec(RAW.zu).split('~'); D.zpts = num(zu[0]); D.zlv = (zu[1] || '').split(',').map(function (x) { return num(x); }); D.zc = num(RAW.zc, -1);
var sv = dec(RAW.sv).split('~'); D.up = num(sv[0]); D.svp = num(sv[1]);
var cr = RAW.cr ? dec(RAW.cr).split('~') : null; D.cr = cr ? { c: num(cr[0]), code: cr[1], r: num(cr[2]) } : null;

// ------------------------------------------------------------------ texts
var T = {
  tr: { home: 'Ana Ekran', hello: 'Hos geldin', unlock: 'Kilidi acmak icin dokun', prof: 'Profil', top: 'Top 15', time: 'Sure Siralamasi', ach: 'Basarimlar', achtop: 'Basarim Top', inv: 'Envanter',
    'case': 'Kasalar', daily: 'Gunluk Odul', zup: 'Zombi Gelisim', trade: 'Takas', set: 'Ayarlar', adm: 'Yonetim', about: 'Hakkinda', level: 'Seviye', kills: 'Oldurme', infs: 'Enfeksiyon',
    deaths: 'Olum', hs: 'Kafa', wins: 'Galibiyet', boss: 'Boss', play: 'Oynama', hours: 'saat', min: 'dk', rank: 'Siralama', type: 'Oyunda yaz', steam: 'Steam profili', online: 'cevrimici',
    map: 'Harita', round: 'Round', vipDays: 'VIP: {0} gun kaldi', dailyReady: 'Gunluk odulun hazir!', dailyWait: 'Siradaki odul: {0}', newAch: 'Basarim', you: 'Sen', name: 'Oyuncu', val: 'Deger',
    noData: 'Henuz kayit yok', unlocked: 'acildi', locked: 'kilitli', owned: 'sahip', equipped: 'TAKILI', all: 'Tumu', knives: 'Bicaklar', skins: 'Karakterler', wings: 'Kanatlar', pets: 'Petler',
    kfx: 'Oldurme Efekti', lasers: 'Lazerler', trails: 'Izler', chances: 'Dusme ihtimalleri', open: 'Kasa ac', opening: 'Kasa aciliyor...', got: 'Kazandin', dup: 'Zaten vardi: VC iade edildi',
    rar: ['Siradan', 'Nadir', 'Destansi', 'Efsanevi', 'Mitik'], day: 'Gun', streak: 'Seri', claim: 'Odulunu al', claimed: 'Bugunku odul alindi', points: 'Puan', current: 'Su anki sinifin',
    zupHow: 'Zombiyken insan enfekte et (+1) ya da oldur (+2). Seviye atladikca yeteneklerin guclenir.', tradeHow: 'Takas sistemi: sunucudaki bir oyuncuyu sec, verecegin esyayi sec; karsi taraf ya kendi esyasini verir ya da hediye olarak kabul eder. Tum takaslar kayit altindadir.',
    theme: 'Tema', dark: 'Karanlik', light: 'Aydinlik', sound: 'Sesler', notif: 'Bildirimler', lang: 'Dil', wall: 'Duvar kagidi', adminOnly: 'Bu bolum sadece yonetim icindir.',
    founder: 'Kurucu islemleri', uptime: 'Calisma suresi', players: 'Oyuncu', cmds: 'Komutlar', credit: 'Tablet ve mod', back: 'Geri', demo: 'Ornek veriler gosteriliyor', vipDrop: 'VIP sadece Kabus Kasasindan dusuk ihtimalle cikar',
    updated: 'Guncellendi: {0} dk once', store: 'App Store', game: 'Vex Kanat', get: 'AL', openB: 'AC', remove: 'Kaldir', installed: 'Yuklu', installing: 'Yukleniyor', featured: 'Gunun Uygulamasi',
    exitHint: 'Sag tik: geri  |  Cikmak icin: ESC / Tamam', tapStart: 'Baslamak icin tikla', best: 'En iyi', score: 'Skor', over: 'Oyun bitti', core: 'Sistem uygulamasi',
    d_prof: 'Seviyen, istatistiklerin, Steam profilin', d_top: 'Sunucunun en iyi 15 oyuncusu', d_time: 'En cok oynayanlar', d_ach: '30 basarim ve odulleri', d_achtop: 'Basarim yarismasi', d_inv: 'Bicak, kanat, pet ve efektlerin',
    d_case: 'Kasa ac, efsanevi esya kazan', d_daily: '7 gunluk odul serisi', d_zup: 'Zombi siniflarini gelistir', d_trade: 'Oyuncularla esya takasi', d_game: 'Borularin arasindan uc, rekor kir', d_set: 'Tema, ses, duvar kagidi', d_adm: 'Yonetim paneli', d_about: 'Vexmira hakkinda', d_store: 'Uygulama indir' },
  en: { home: 'Home', hello: 'Welcome', unlock: 'Tap to unlock', prof: 'Profile', top: 'Top 15', time: 'Playtime', ach: 'Achievements', achtop: 'Achievement Top', inv: 'Inventory',
    'case': 'Cases', daily: 'Daily Reward', zup: 'Zombie Upgrade', trade: 'Trade', set: 'Settings', adm: 'Admin', about: 'About', level: 'Level', kills: 'Kills', infs: 'Infections',
    deaths: 'Deaths', hs: 'Headshots', wins: 'Wins', boss: 'Boss', play: 'Played', hours: 'h', min: 'min', rank: 'Rank', type: 'Type in game', steam: 'Steam profile', online: 'online',
    map: 'Map', round: 'Round', vipDays: 'VIP: {0} days left', dailyReady: 'Your daily reward is ready!', dailyWait: 'Next reward: {0}', newAch: 'Achievement', you: 'You', name: 'Player', val: 'Value',
    noData: 'No records yet', unlocked: 'unlocked', locked: 'locked', owned: 'owned', equipped: 'EQUIPPED', all: 'All', knives: 'Knives', skins: 'Characters', wings: 'Wings', pets: 'Pets',
    kfx: 'Kill Effects', lasers: 'Lasers', trails: 'Trails', chances: 'Drop chances', open: 'Open case', opening: 'Opening case...', got: 'You got', dup: 'Duplicate: VC refunded',
    rar: ['Common', 'Rare', 'Epic', 'Legendary', 'Mythic'], day: 'Day', streak: 'Streak', claim: 'Claim reward', claimed: "Today's reward claimed", points: 'Points', current: 'Your current class',
    zupHow: 'As a zombie, infect humans (+1) or kill them (+2). Every level makes your class abilities stronger.', tradeHow: 'Trading: pick a player on the server and the item you give; the other player gives one of their items back or accepts it as a gift. Every trade is logged.',
    theme: 'Theme', dark: 'Dark', light: 'Light', sound: 'Sounds', notif: 'Notifications', lang: 'Language', wall: 'Wallpaper', adminOnly: 'This section is for staff only.',
    founder: 'Founder actions', uptime: 'Uptime', players: 'Players', cmds: 'Commands', credit: 'Tablet & mod', back: 'Back', demo: 'Showing sample data', vipDrop: 'VIP only drops (rarely) from the Nightmare Case',
    updated: 'Updated {0} min ago', store: 'App Store', game: 'Vex Wings', get: 'GET', openB: 'OPEN', remove: 'Remove', installed: 'Installed', installing: 'Installing', featured: 'App of the Day',
    exitHint: 'Right click: back  |  To exit: ESC / OK', tapStart: 'Click to start', best: 'Best', score: 'Score', over: 'Game over', core: 'System app',
    d_prof: 'Your level, stats and Steam profile', d_top: "The server's top 15", d_time: 'Most played', d_ach: '30 achievements and rewards', d_achtop: 'Achievement race', d_inv: 'Your knives, wings, pets and effects',
    d_case: 'Open cases, win legendary items', d_daily: '7-day reward streak', d_zup: 'Upgrade zombie classes', d_trade: 'Trade items with players', d_game: 'Fly between the pipes, beat the record', d_set: 'Theme, sound, wallpaper', d_adm: 'Admin panel', d_about: 'About Vexmira', d_store: 'Download apps' }
};
(function (a, b) { for (var k in a) T.tr[k] = a[k]; for (var j in b) T.en[j] = b[j]; })({
  guide: 'Rehber', cmds: 'Komutlar', music: 'Muzik', notes: 'Notlar', calc: 'Hesap Makinesi', snake: 'Vex Yilan', g2048: 'Vex 2048', whack: 'Zombi Avi', games: 'Oyunlar',
  d_guide: 'Modlar, zombi siniflari, ipuclari', d_cmds: 'Tum sohbet komutlari tek yerde', d_music: 'Korku atmosferi muzikleri', d_notes: 'Kendi notlarin', d_calc: 'Hizli hesap', d_snake: 'Klasik yilan, karanlik temada', d_g2048: 'Kutulari birlestir, 2048e ulas', d_whack: '30 saniyede en cok zombiyi vur',
  cc: 'Kontrol Merkezi', accent: 'Vurgu rengi', bright: 'Parlaklik', edit: 'Ana ekrani duzenle', done: 'Bitti', custom: 'Ozellestir', wpNames: ['Kizil Sis', 'Ucurum', 'Zehir', 'Altigen', 'Kor', 'Mor Safak', 'Gece Mavisi', 'Vexmira'],
  cat_games: 'Oyunlar', cat_tools: 'Araclar', cat_server: 'Sunucu', top3: 'En iyiler', np: 'Simdi caliyor', tracks: ['Karanlik Koridor', 'Kalp Atisi', 'Kanli Yagmur', 'Sisli Gece'], stop: 'Durdur',
  modes: 'Oyun Modlari', classes: 'Zombi Siniflari', tips: 'Ipuclari', notesPh: 'Buraya yaz... (otomatik kaydedilir)', timeLeft: 'Sure', start: 'Basla', again: 'Tekrar', hint2048: 'Ok tuslari ile kaydir', hintSnake: 'Ok tuslari / WASD ile yonlendir',
  widgetHint: 'Duzenlemek icin bir simgeye basili tut', xp: 'XP'
}, {
  guide: 'Guide', cmds: 'Commands', music: 'Music', notes: 'Notes', calc: 'Calculator', snake: 'Vex Snake', g2048: 'Vex 2048', whack: 'Zombie Hunt', games: 'Games',
  d_guide: 'Modes, zombie classes, tips', d_cmds: 'Every chat command in one place', d_music: 'Horror ambience tracks', d_notes: 'Your own notes', d_calc: 'Quick maths', d_snake: 'Classic snake, dark theme', d_g2048: 'Merge tiles, reach 2048', d_whack: 'Hit as many zombies as you can in 30 s',
  cc: 'Control Center', accent: 'Accent color', bright: 'Brightness', edit: 'Edit home screen', done: 'Done', custom: 'Customize', wpNames: ['Crimson Fog', 'Abyss', 'Toxic', 'Hexgrid', 'Ember', 'Violet Dawn', 'Midnight', 'Vexmira'],
  cat_games: 'Games', cat_tools: 'Tools', cat_server: 'Server', top3: 'Top players', np: 'Now playing', tracks: ['Dark Corridor', 'Heartbeat', 'Blood Rain', 'Foggy Night'], stop: 'Stop',
  modes: 'Game Modes', classes: 'Zombie Classes', tips: 'Tips', notesPh: 'Write here... (saved automatically)', timeLeft: 'Time', start: 'Start', again: 'Again', hint2048: 'Slide with the arrow keys', hintSnake: 'Steer with arrow keys / WASD',
  widgetHint: 'Press and hold an icon to edit', xp: 'XP'
});
function L(k) { var s = T[D.lang][k]; return s == null ? (T.tr[k] == null ? k : T.tr[k]) : s; }
function F(k, a) { return L(k).replace('{0}', a); }
var ZCLS = { tr: ['Walker', 'Runner', 'Tank', 'Banshee', 'Leech', 'Stalker', 'Bomber', 'Frost', 'Spitter', 'Hulk', 'Voodoo', 'Phantom', 'Kasap', 'Avci', 'Boga', 'Orumcek', 'Magma', 'Volt', 'Taklitci', 'Kostebek', 'Siren', 'Kale', 'Spor Ana', 'Kabus'],
  en: ['Walker', 'Runner', 'Tank', 'Banshee', 'Leech', 'Stalker', 'Bomber', 'Frost', 'Spitter', 'Hulk', 'Voodoo', 'Phantom', 'Butcher', 'Hunter', 'Charger', 'Arachne', 'Magma', 'Volt', 'Mimic', 'Burrower', 'Siren', 'Bulwark', 'Sporemother', 'Nightmare'] };
var ACH_FB = [['Ilk Kan', 'First Blood'], ['Imha Uzmani', 'Exterminator'], ['Zombi Avcisi', 'Zombie Slayer'], ['Salgin Tasiyici', 'Plaguebearer'], ['Boss Avcisi', 'Boss Hunter'], ['Boss Katili', 'Bossbane'],
  ['Hayatta Kalan', 'Survivor'], ['Son Savunma', 'Last Stand'], ['Kafa Avcisi', 'Headhunter'], ['Gazi', 'Veteran'], ['Olumsuz', 'Immortal'], ['Efsane', 'Legend'], ['Sadik', 'Devoted'], ['Mukemmeliyetci', 'Perfectionist'],
  ['Gece Kusu', 'Night Owl'], ['Bagimli', 'Addicted'], ['Kasa Avcisi', 'Case Hunter'], ['Sansli', 'Lucky'], ['Tuccar', 'Trader'], ['Lazer Ustasi', 'Laser Master'], ['Bicak Ustasi', 'Blade Master'], ['Kurtarici', 'Savior'],
  ['Koleksiyoncu', 'Collector'], ['Kiyamet', 'Armageddon'], ['Nemesis Avcisi', 'Nemesis Hunter'], ['Gercek Hayatta Kalan', 'True Survivor'], ['Kabus', 'Nightmare'], ['Seri Katil', 'Rampage'], ['Evrim', 'Evolution'], ['Kurucu Dostu', "Founder's Friend"]];
var VX = window.VXITEMS || {};
var CATN = { k: 'knives', c: 'skins', w: 'wings', p: 'pets', f: 'kfx', z: 'lasers', t: 'trails' };
function catList(c) { return (VX[c] && VX[c].length) ? VX[c] : []; }
function itemName(code) {
  var c = code.charAt(0), n = code.slice(1);
  if (c === 'a') return n + ' AP'; if (c === '$') return n + ' VexCoin'; if (c === 'v') return D.lang === 'tr' ? 'VIP ' + n + ' Gun' : 'VIP ' + n + ' Day' + (n === '1' ? '' : 's');
  var l = catList(c)[num(n) - 1]; if (l) return l[D.lang] || l.en || l.tr;
  return (L(CATN[c] || 'inv')) + ' ' + n;
}
function achList() {
  var a = (VX.ach && VX.ach.length) ? VX.ach : ACH_FB.map(function (x) { return { tr: x[0], en: x[1], dtr: '', den: '' }; });
  return a.map(function (x) { return { n: x[D.lang] || x.en, d: (D.lang === 'tr' ? x.dtr : x.den) || '', vc: x.vc, ap: x.ap }; });
}

// ------------------------------------------------------------------ icons (inline svg paths, one 24px grid, 1.9 stroke)
var IC = {
  prof: '<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20.5c1.2-3.8 4-5.6 7.5-5.6s6.3 1.8 7.5 5.6"/>',
  top: '<path d="M8 21h8M12 16.5V21M6.5 3.5h11V9a5.5 5.5 0 0 1-11 0z"/><path d="M6.5 5.5H3.5v1.8A3.2 3.2 0 0 0 6.7 10.5M17.5 5.5h3v1.8a3.2 3.2 0 0 1-3.2 3.2"/>',
  time: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.6 1.6M9.5 2.5h5"/>',
  ach: '<path d="M12 3l2.7 5.5 6 .9-4.35 4.2 1 6L12 16.8 6.65 19.6l1-6L3.3 9.4l6-.9z"/>',
  achtop: '<path d="M5 20.5V13M10 20.5V6M15 20.5v-9M20 20.5V9M3 20.5h18"/>',
  inv: '<rect x="3.5" y="7" width="17" height="13.5" rx="2.5"/><path d="M8.5 7V5.5a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2V7M3.5 12.5h17M10.5 12.5v2h3v-2"/>',
  'case': '<path d="M4 9.5h16v10a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 19.5z"/><path d="M3 6.5h18v3H3zM12 6.5V21M12 6.5C10 2.5 6.5 3 7 5s5 1.5 5 1.5 4.5.5 5-1.5-3-2.5-5 1.5"/>',
  daily: '<rect x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4M9 15l2 2 4-4"/>',
  zup: '<path d="M12 2.5c4.2 3.2 6.3 6.3 6.3 9.4a6.3 6.3 0 0 1-12.6 0c0-3.1 2.1-6.2 6.3-9.4z"/><path d="M12 10.5v7M9 13.5l3-3 3 3"/>',
  trade: '<path d="M4 8.5h14l-3.5-3.5M20 15.5H6l3.5 3.5"/>',
  set: '<circle cx="12" cy="12" r="3.2"/><path d="M19.4 13.5l1.6 1.2-2 3.4-1.9-.7a7.5 7.5 0 0 1-2.2 1.3L14.6 21h-4l-.3-2.3a7.5 7.5 0 0 1-2.2-1.3l-1.9.7-2-3.4 1.6-1.2a7.6 7.6 0 0 1 0-3L4.2 9.3l2-3.4 1.9.7a7.5 7.5 0 0 1 2.2-1.3L10.6 3h4l.3 2.3a7.5 7.5 0 0 1 2.2 1.3l1.9-.7 2 3.4-1.6 1.2a7.6 7.6 0 0 1 0 3z"/>',
  adm: '<path d="M12 2.5l8 3.5v6c0 5-3.6 8.6-8 9.5-4.4-.9-8-4.5-8-9.5V6z"/><path d="M8.8 12l2.2 2.2 4.4-4.4"/>',
  about: '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5M12 7.6v.1"/>',
  bell: '<path d="M6 9a6 6 0 0 1 12 0c0 6.5 2.5 8 2.5 8h-17S6 15.5 6 9M10 20.5h4"/>',
  gift: '<rect x="3.5" y="8.5" width="17" height="12" rx="1.5"/><path d="M12 8.5v12M3.5 12.5h17M12 8.5C10 4.5 6.5 5 7 7s5 1.5 5 1.5 4.5.5 5-1.5-3-2.5-5 1.5"/>',
  blade: '<path d="M14.5 3.5l6-1-1 6-9 9-4-4z"/><path d="M5.5 14.5l-2 2 4 4 2-2M13 8l3 3"/>',
  map: '<path d="M12 21s-6.5-6-6.5-11.3a6.5 6.5 0 0 1 13 0C18.5 15 12 21 12 21z"/><circle cx="12" cy="9.6" r="2.4"/>',
  flag: '<path d="M5.5 21V3.5M5.5 4h11.5l-2.2 4 2.2 4H5.5"/>',
  users: '<circle cx="9" cy="8" r="3.4"/><path d="M2.8 20c.8-3.4 3.3-5.3 6.2-5.3s5.4 1.9 6.2 5.3M15.5 4.8a3.4 3.4 0 0 1 0 6.4M17.6 14.8c1.9.7 3.1 2.4 3.6 5.2"/>',
  store: '<path d="M8 17.5L12.5 6M16 17.5L11.5 6M6 13.5h12M4 17.5h16"/>',
  game: '<path d="M7.5 7.5h9a5 5 0 0 1 4.9 6l-.6 3a2.4 2.4 0 0 1-4.2 1L15 15.5H9L7.4 17.5a2.4 2.4 0 0 1-4.2-1l-.6-3a5 5 0 0 1 4.9-6z"/><path d="M8 10.3v3M6.5 11.8h3M15.5 11h.1M17.5 12.8h.1"/>',
  dl: '<path d="M12 4v11M7 10l5 5 5-5M5 20h14"/>',
  guide: '<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v15H6.5A2.5 2.5 0 0 0 4 20.5z"/><path d="M4 20.5A2.5 2.5 0 0 1 6.5 18H20v3H6.5M9 7.5h7M9 11h5"/>',
  cmds: '<rect x="3" y="4.5" width="18" height="15" rx="2.5"/><path d="M7 9.5l3 2.5-3 2.5M12.5 15H17"/>',
  music: '<path d="M9 18V5.5l11-2V16"/><circle cx="6.5" cy="18" r="2.5"/><circle cx="17.5" cy="16" r="2.5"/><path d="M9 9.5l11-2"/>',
  notes: '<path d="M6 3.5h9l4 4v13H6z"/><path d="M15 3.5v4h4M9 12h7M9 15.5h7M9 8.5h3"/>',
  calc: '<rect x="5" y="3" width="14" height="18" rx="2.5"/><path d="M8 7h8v3H8zM8.5 13.5h.1M12 13.5h.1M15.5 13.5h.1M8.5 17h.1M12 17h.1M15.5 17h.1"/>',
  snake: '<path d="M4 17.5c0-2 1.5-3.5 3.5-3.5h9a3.5 3.5 0 0 0 0-7H9"/><path d="M9 5l-3 2 3 2M4 17.5h8"/><circle cx="12.5" cy="17.5" r=".2"/>',
  g2048: '<rect x="3.5" y="3.5" width="7.5" height="7.5" rx="1.8"/><rect x="13" y="3.5" width="7.5" height="7.5" rx="1.8"/><rect x="3.5" y="13" width="7.5" height="7.5" rx="1.8"/><rect x="13" y="13" width="7.5" height="7.5" rx="1.8"/>',
  whack: '<path d="M12 3.5c-4 0-7 3-7 6.8 0 2.4 1.2 4 2.6 5v3.2h8.8v-3.2c1.4-1 2.6-2.6 2.6-5 0-3.8-3-6.8-7-6.8z"/><path d="M9.3 10.5h.1M14.7 10.5h.1M10 18.5v2M14 18.5v2M10.5 14.5h3"/>',
  games: '<rect x="3.5" y="3.5" width="7.5" height="7.5" rx="2"/><rect x="13" y="3.5" width="7.5" height="7.5" rx="2"/><rect x="3.5" y="13" width="7.5" height="7.5" rx="2"/><rect x="13" y="13" width="7.5" height="7.5" rx="2"/>',
  brush: '<path d="M18.5 3.5l2 2-9 9-2.5.5.5-2.5zM9 15c-2.5 0-4 1.5-4 3.5 0 1-.8 1.8-1.5 2 3 .8 7 0 7-3.5"/>',
  moon: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>',
  vol: '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z"/><path d="M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11"/>',
  globe: '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.5 3.5 5.5 3.5 8.5s-1 6-3.5 8.5c-2.5-2.5-3.5-5.5-3.5-8.5s1-6 3.5-8.5z"/>',
  grid: '<path d="M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z"/>',
  bright: '<circle cx="12" cy="12" r="3.2"/><path d="M12 4v1.5M12 18.5V20M4 12h1.5M18.5 12H20M6.3 6.3l1 1M16.7 16.7l1 1M6.3 17.7l1-1M16.7 7.3l1-1"/>',
  play: '<path d="M8 5.5v13l10.5-6.5z"/>',
  pause: '<path d="M8 5.5v13M16 5.5v13"/>'
};
var ICOL = {
  prof: '#ff5468,#9a0f26', top: '#ffb547,#c2540a', time: '#5aaeff,#1747b0', ach: '#ffd862,#c98400', achtop: '#ff7d5c,#a8261c',
  inv: '#ad7bff,#4c1fae', 'case': '#ff4f7b,#8e0b3f', daily: '#43e0a0,#0b7a50', zup: '#a2e65c,#2c7710', trade: '#45d9d2,#0b6f7c',
  set: '#a3acb7,#3b424c', adm: '#ff5a5a,#7c0a12', about: '#6c7280,#20242c', store: '#5aaeff,#5b36f2', game: '#ff9147,#c4310c',
  guide: '#7c8bff,#2c2fa3', cmds: '#4a505c,#111317', music: '#ff6492,#b3124c', notes: '#ffd34d,#d48f00', calc: '#ff9f2e,#4a2a0a',
  snake: '#56e07a,#147a30', g2048: '#ffbf5a,#cf6a0c', whack: '#c75cff,#5c0f9c', games: '#3b3346,#15111c'
};
function svg(k) { return '<svg viewBox="0 0 24 24">' + (IC[k] || IC.about) + '</svg>'; }
function grad(k) { var c = (ICOL[k] || ICOL.about).split(','); return 'background:linear-gradient(160deg,' + c[0] + ' 0%,' + c[1] + ' 100%)'; }
// ------------------------------------------------------------------ VEXMIRA logo (emblem tile + wordmark, no subtitle)
var LGN = 0;
function emblem() {
  var u = 'e' + (++LGN);
  return '<svg class="emb" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><defs>' +
    '<linearGradient id="' + u + 'b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a0814"/><stop offset=".55" stop-color="#14040a"/><stop offset="1" stop-color="#050206"/></linearGradient>' +
    '<radialGradient id="' + u + 'g" cx=".5" cy=".38" r=".55"><stop offset="0" stop-color="#ff2846" stop-opacity=".55"/><stop offset="1" stop-color="#ff2846" stop-opacity="0"/></radialGradient>' +
    '<linearGradient id="' + u + 'v" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset=".55" stop-color="#e9e1ea"/><stop offset="1" stop-color="#9c8f9f"/></linearGradient>' +
    '<linearGradient id="' + u + 'r" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff5a70"/><stop offset="1" stop-color="#b30c2a"/></linearGradient>' +
    '<linearGradient id="' + u + 'h" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>' +
    '<rect x="2" y="2" width="116" height="116" rx="30" fill="url(#' + u + 'b)"/>' +
    '<rect x="2" y="2" width="116" height="116" rx="30" fill="url(#' + u + 'g)"/>' +
    '<g opacity=".08" stroke="#fff" stroke-width="1"><path d="M20 30h80M20 45h80M20 60h80M20 75h80M20 90h80"/></g>' +
    '<circle cx="60" cy="60" r="41" fill="none" stroke="url(#' + u + 'r)" stroke-width="2.4" stroke-dasharray="190 8 40 8"/>' +
    '<circle cx="60" cy="60" r="35" fill="none" stroke="#fff" stroke-opacity=".08" stroke-width="1"/>' +
    '<path d="M31 35h15.5L60 72.5 73.5 35H89L65 92H55z" fill="url(#' + u + 'v)"/>' +
    '<path d="M55 92h10l-5 10z" fill="url(#' + u + 'r)"/>' +
    '<path d="M46.5 35l3 0L60 64l-1.6 4.4z" fill="#b30c2a" opacity=".85"/>' +
    '<rect x="2" y="2" width="116" height="116" rx="30" fill="url(#' + u + 'h)"/>' +
    '<rect x="2.75" y="2.75" width="114.5" height="114.5" rx="29.3" fill="none" stroke="#fff" stroke-opacity=".14" stroke-width="1.5"/></svg>';
}
function wordmark() {
  var u = 'w' + (++LGN);
  return '<svg class="wm" viewBox="0 0 420 70" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="' + u + '" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#bdb2c0"/></linearGradient></defs>' +
    '<text x="210" y="48" text-anchor="middle" font-family="Segoe UI,Helvetica Neue,Arial,sans-serif" font-weight="700" font-size="46" letter-spacing="14" fill="url(#' + u + ')">VEXMIRA</text>' +
    '<path d="M120 62h80M220 62h80" stroke="#e3243b" stroke-width="2" stroke-linecap="round"/><circle cx="210" cy="62" r="3" fill="#e3243b"/></svg>';
}
function LOGO() { return '<div class="logo">' + emblem() + wordmark() + '</div>'; }

// ------------------------------------------------------------------ sound (WebAudio, after first click)
var AC = null, soundOn = store('snd') !== '0', notifOn = store('ntf') !== '0';
function ac() { if (!AC) { try { AC = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { AC = null; } } return AC; }
function tone(f, d, type, vol, when, slide) {
  if (!soundOn) return; var a = ac(); if (!a) return;
  var t = a.currentTime + (when || 0), o = a.createOscillator(), g = a.createGain();
  o.type = type || 'sine'; o.frequency.setValueAtTime(f, t); if (slide) o.frequency.exponentialRampToValueAtTime(slide, t + d);
  g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol || 0.15, t + 0.01); g.gain.exponentialRampToValueAtTime(0.0001, t + d);
  o.connect(g); g.connect(a.destination); o.start(t); o.stop(t + d + 0.05);
}
var SND = {
  click: function () { tone(1400, 0.04, 'square', 0.04); },
  open: function () { tone(520, 0.12, 'sine', 0.08, 0, 880); },
  close: function () { tone(700, 0.1, 'sine', 0.06, 0, 380); },
  notif: function () { tone(988, 0.12, 'sine', 0.1); tone(1319, 0.2, 'sine', 0.1, 0.11); },
  tick: function () { tone(2200, 0.025, 'square', 0.035); },
  unlock: function () { tone(220, 0.25, 'sawtooth', 0.05, 0, 440); tone(660, 0.18, 'sine', 0.06, 0.12); },
  drone: function () { tone(55, 2.6, 'sawtooth', 0.025, 0, 49); tone(82, 2.6, 'sine', 0.03, 0.2, 78); },
  win: function (r) { var base = [392, 440, 523, 659, 784][r] || 440; for (var i = 0; i < 3 + r; i++) tone(base * Math.pow(1.122, i), 0.22, i % 2 ? 'triangle' : 'sine', 0.09, i * 0.09); if (r >= 3) { tone(base / 2, 1.4, 'sawtooth', 0.04, 0.3); } }
};

// ------------------------------------------------------------------ theme / wallpaper
var WP = num(store('wp'), 7) % 8;
function applyTheme() { document.documentElement.setAttribute('data-theme', store('theme') === 'light' ? 'light' : 'dark'); document.documentElement.lang = D.lang; }
function applyWall() { $('wall').className = 'wall wp' + WP + ($('lock').className.indexOf('off') >= 0 ? '' : ''); }

// ------------------------------------------------------------------ clock / status
var DAYS = { tr: ['Pazar', 'Pazartesi', 'Sali', 'Carsamba', 'Persembe', 'Cuma', 'Cumartesi'], en: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'] };
var MON = { tr: ['Ocak', 'Subat', 'Mart', 'Nisan', 'Mayis', 'Haziran', 'Temmuz', 'Agustos', 'Eylul', 'Ekim', 'Kasim', 'Aralik'], en: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'] };
function pad(n) { return n < 10 ? '0' + n : '' + n; }
function clock() {
  var d = new Date(), t = pad(d.getHours()) + ':' + pad(d.getMinutes());
  $('stTime').textContent = t; $('lockTime').textContent = t;
  $('lockDate').textContent = DAYS[D.lang][d.getDay()] + ', ' + d.getDate() + ' ' + MON[D.lang][d.getMonth()];
  $('stOnline').textContent = D.on ? D.on + '/' + D.mx : '';
}

// ------------------------------------------------------------------ banners
function banner(title, text, icon, color, delay) {
  if (!notifOn) return;
  setTimeout(function () {
    var b = document.createElement('div'); b.className = 'bn';
    b.innerHTML = '<div class="bi" style="background:' + (color || 'var(--acc)') + '">' + svg(icon || 'bell') + '</div><div><b>' + esc(title) + '</b><span>' + esc(text) + '</span></div>';
    $('banners').appendChild(b); SND.notif();
    setTimeout(function () { b.className = 'bn out'; setTimeout(function () { if (b.parentNode) b.parentNode.removeChild(b); }, 450); }, 4200);
  }, delay || 0);
}
function hms(s) { s = Math.max(0, s | 0); return pad(Math.floor(s / 3600)) + ':' + pad(Math.floor(s % 3600 / 60)); }

// ------------------------------------------------------------------ apps
var CATALOG = ['prof', 'top', 'time', 'ach', 'achtop', 'inv', 'case', 'daily', 'zup', 'trade', 'guide', 'cmds', 'music', 'notes', 'calc', 'game', 'snake', 'g2048', 'whack', 'set', 'store', 'about'];
var CATS = [['cat_server', ['prof', 'top', 'time', 'ach', 'achtop', 'inv', 'case', 'daily', 'zup', 'trade']], ['cat_games', ['game', 'snake', 'g2048', 'whack']], ['cat_tools', ['guide', 'cmds', 'music', 'notes', 'calc']]];
var GAMES = ['game', 'snake', 'g2048', 'whack'];
var CORE = ['store', 'set', 'about', 'adm'], DEF = ['prof', 'top', 'ach', 'inv', 'case', 'daily', 'zup', 'trade', 'guide', 'music', 'game', 'snake'];
var INST = (function () { var v = store('apps6'); try { v = v ? JSON.parse(v) : null; } catch (e) { v = null; } return v || DEF.slice(); })();
function installed(a) { return CORE.indexOf(a) >= 0 || INST.indexOf(a) >= 0 || a === D.page; }
function saveInst() { store('apps6', JSON.stringify(INST)); }
var APPS = CATALOG;
var DOCK = ['prof', 'case', 'store', 'set'];
function cmd(c) { return '<div class="cmd">' + esc(L('type')) + ': <b>' + esc(c) + '</b></div>'; }
function card(t, body) { return '<div class="card">' + (t ? '<h3>' + esc(t) + '</h3>' : '') + body + '</div>'; }
function stat(v, l) { return '<div class="stat"><b>' + esc(v) + '</b><span>' + esc(l) + '</span></div>'; }
function avaColor(lv) { var c = lv >= 75 ? '#ffb000,#a33a00' : lv >= 50 ? '#b04aff,#3d0a6e' : lv >= 25 ? '#2f80ed,#0b2c66' : '#c8102e,#4a0510'; c = c.split(','); return 'background:linear-gradient(145deg,' + c[0] + ',' + c[1] + ')'; }
function initials(n) { var p = n.replace(/[^A-Za-z0-9 ]/g, '').trim().split(/\s+/); return ((p[0] || '?').charAt(0) + (p[1] ? p[1].charAt(0) : '')).toUpperCase(); }
function medal(i) { return '<span class="medal ' + (i < 3 ? 'm' + (i + 1) : '') + '">' + (i + 1) + '</span>'; }
function board(rows, cols, valFn) {
  if (!rows.length) return '<p class="muted">' + esc(L('noData')) + '</p>';
  var h = '<table class="lb"><tr><th>#</th><th>' + esc(L('name')) + '</th>' + cols.map(function (c) { return '<th>' + esc(c) + '</th>'; }).join('') + '</tr>';
  rows.forEach(function (r, i) { h += '<tr class="' + (r.n === D.name ? 'me' : '') + '"><td>' + medal(i) + '</td><td class="n">' + esc(r.n) + '</td>' + valFn(r).map(function (v) { return '<td>' + esc(v) + '</td>'; }).join('') + '</tr>'; });
  return h + '</table>';
}
function ichip(ic, label, val, col) { return '<div class="ichip"><span class="ii" style="background:' + col + '22;color:' + col + '">' + svg(ic) + '</span><span><small>' + esc(label) + '</small><b>' + esc(val) + '</b></span></div>'; }
var R = {};
R.prof = function () {
  var pct = Math.max(0, Math.min(100, D.xn > 0 ? Math.round(D.xp * 100 / D.xn) : 100));
  var steam = D.sid ? '<a class="lnk" href="https://steamcommunity.com/profiles/' + esc(D.sid) + '" target="_blank">' + esc(L('steam')) + ' &rsaquo;</a>' : '';
  return card('', '<div class="prof"><div class="ava" style="' + avaColor(D.lv) + '">' + esc(initials(D.name)) + '</div><div style="flex:1"><h2>' + esc(D.name) + (D.vip ? '<span class="vip">' + (D.vip === 2 ? 'ELITE' : 'VIP') + '</span>' : '') +
    '</h2><div class="sub">' + esc(L('level')) + ' ' + D.lv + (D.rank ? ' &middot; #' + D.rank + ' ' + esc(L('rank')) : '') + (D.vip && D.vd ? ' &middot; ' + esc(F('vipDays', D.vd)) : '') + '</div>' +
    '<div class="bar"><i style="width:' + pct + '%"></i></div><div class="sub">XP ' + fmt(D.xp) + ' / ' + fmt(D.xn) + ' &nbsp; ' + steam + '</div></div></div>') +
    card('', '<div class="stats">' + stat(fmt(D.k), L('kills')) + stat(fmt(D.inf), L('infs')) + stat(fmt(D.hs), L('hs')) + stat(fmt(D.w), L('wins')) + stat(fmt(D.b), L('boss')) + stat(fmt(D.d), L('deaths')) +
      stat(Math.floor(D.pt / 60) + ' ' + L('hours'), L('play')) + stat(achCount() + '/' + achList().length, L('ach')) + '</div>') +
    card('', '<div class="stats">' + stat(fmt(D.ap), 'AP') + stat(fmt(D.vc), 'VexCoin') + stat(D.streak, L('streak')) + stat(D.on + '/' + D.mx, L('online')) + '</div>' + cmd('/istatistik'));
};
R.top = function () { return card(L('top'), board(D.top, [L('level'), L('kills')], function (r) { return [r.lv, fmt(r.k)]; })) + cmd('/top15'); };
R.time = function () { return card(L('time'), board(D.tt, [L('play')], function (r) { var m = num(r.v); return [Math.floor(m / 60) + ' ' + L('hours') + ' ' + (m % 60) + ' ' + L('min')]; })) + cmd('/toptime'); };
R.achtop = function () { return card(L('achtop'), board(D.at, [L('ach')], function (r) { return [r.v + ' / ' + achList().length]; })) + cmd('/basarimtop'); };
function achCount() { var n = 0; for (var i = 0; i < 31; i++) if (D.ach & (1 << i)) n++; return n; }
R.ach = function () {
  var a = achList(), h = '<div class="achs">';
  a.forEach(function (x, i) {
    var on = (D.ach & (1 << i)) !== 0;
    h += '<div class="ach' + (on ? ' on' : '') + '"><div class="ai">' + (on ? '&#9733;' : '&#128274;') + '</div><div><b>' + esc(x.n) + '</b><small>' + esc(x.d) + '</small>' + (x.vc ? '<em>+' + x.vc + ' VC' + (x.ap ? ' +' + x.ap + ' AP' : '') + '</em>' : '') + '</div></div>';
  });
  return card(achCount() + ' / ' + a.length + ' ' + L('unlocked'), h + '</div>') + cmd('/basarim');
};
var invTab = 'k';
R.inv = function () {
  var cats = ['k', 'c', 'w', 'p', 'f', 'z', 't'].filter(function (c) { return catList(c).length || (D.iv[c] | 0); });
  if (cats.indexOf(invTab) < 0) invTab = cats[0] || 'k';
  var h = '<div class="tabs">' + cats.map(function (c) { return '<span class="tab' + (c === invTab ? ' on' : '') + '" data-tab="' + c + '">' + esc(L(CATN[c])) + '</span>'; }).join('') + '</div><div class="items">';
  var list = catList(invTab), n = Math.max(list.length, 0);
  if (!n) { for (var b = 0; b < 16; b++) if ((D.iv[invTab] | 0) & (1 << b)) n = b + 1; }
  for (var i = 0; i < n; i++) {
    var it = list[i] || {}, own = ((D.iv[invTab] | 0) & (1 << i)) !== 0, eq = (D.eq[invTab] | 0) === i + 1, r = it.r | 0;
    if (it.ok === 0 && !own) continue;
    h += '<div class="it' + (own ? '' : ' no') + '">' + (eq ? '<span class="eq">' + esc(L('equipped')) + '</span>' : '') + '<div class="ib" style="' + grad(invTab === 'k' ? 'case' : invTab === 'w' ? 'ach' : invTab === 'p' ? 'daily' : 'inv') + '">' + svg(invTab === 'k' ? 'blade' : invTab === 'p' ? 'prof' : 'inv') + '</div><b>' + esc(itemName(invTab + (i + 1))) + '</b><small class="t' + r + '">' + esc(L('rar')[r]) + (it.vc ? ' &middot; ' + it.vc + ' VC' : '') + '</small><div class="rb r' + r + '"></div></div>';
  }
  return card(L('inv'), h + '</div>' + cmd(D.lang === 'tr' ? '/envanter  /kozmetik  /bicak' : '/inventory  /cosmetic  /knife'));
};
var caseSel = 0;
function caseColors(c) { return ['#b06a2e,#4a2408', '#c9ced6,#5a6068', '#ffd34a,#a06400', '#7a0018,#14000a'][c]; }
function caseData() {
  var c = (VX.cases && VX.cases.length) ? VX.cases : [{ tr: 'Bronz Kasa', en: 'Bronze Case', vc: 150, loot: [] }, { tr: 'Gumus Kasa', en: 'Silver Case', vc: 350, loot: [] }, { tr: 'Altin Kasa', en: 'Gold Case', vc: 700, loot: [] }, { tr: 'Kabus Kasasi', en: 'Nightmare Case', vc: 1200, loot: [] }];
  return c;
}
R['case'] = function () {
  var cs = caseData(), h = '<div class="cases">';
  cs.forEach(function (c, i) { var col = caseColors(i).split(','); h += '<div class="case' + (i === caseSel ? ' sel' : '') + '" data-case="' + i + '"><div class="cb" style="background:linear-gradient(160deg,' + col[0] + ',' + col[1] + ')"></div><b>' + esc(c[D.lang] || c.en) + '</b><small>' + c.vc + ' VC</small></div>'; });
  h += '</div>';
  var reel = D.cr ? '<div class="reelbox"><div class="needle"></div><div id="reel" class="reel"></div></div><div id="winBox"></div>' : '';
  var c = cs[caseSel], loot = (c.loot || []).slice().sort(function (a, b) { return b[1] - a[1]; }), lh = '<div class="loot">';
  loot.forEach(function (l) { lh += '<div style="border-left-color:' + ['#9aa0a8', '#3c8cff', '#a646ff', '#ffbe28', '#ff2a2a'][l[1]] + '"><span class="t' + l[1] + '">' + esc(itemName(l[0])) + '</span><b>' + Number(l[2]).toFixed(2) + '%</b></div>'; });
  lh += '</div>';
  return (D.cr ? card(L('opening'), reel) : '') + card(L('case'), h + cmd('/kasa')) + card(L('chances') + ' - ' + (c[D.lang] || c.en), (loot.length ? lh : '<p class="muted">' + esc(L('noData')) + '</p>') + '<p class="muted" style="margin-top:8px">' + esc(L('vipDrop')) + '</p>');
};
function runReel() {
  if (!D.cr || !$('reel')) return;
  var cs = caseData(), c = cs[D.cr.c] || cs[0], pool = (c.loot && c.loot.length) ? c.loot : [[D.cr.code, D.cr.r, 1]], items = [], WIN = 38;
  for (var i = 0; i < 46; i++) { var p = pool[Math.floor(Math.random() * pool.length)]; items.push(i === WIN ? [D.cr.code, D.cr.r] : [p[0], p[1]]); }
  var reel = $('reel'); reel.innerHTML = items.map(function (x) { return '<div class="it"><div class="ib" style="' + grad('case') + '">' + svg(x[0].charAt(0) === 'k' ? 'blade' : 'gift') + '</div><b>' + esc(itemName(x[0])) + '</b><small class="t' + x[1] + '">' + esc(L('rar')[x[1]]) + '</small><div class="rb r' + x[1] + '"></div></div>'; }).join('');
  var box = reel.parentNode, W = 128, target = WIN * W + 60 - box.clientWidth / 2 + Math.floor(Math.random() * 60) - 30, start = null, dur = 5200, last = -1;
  function ease(t) { return 1 - Math.pow(1 - t, 4); }
  function step(ts) {
    if (!start) start = ts; var t = Math.min(1, (ts - start) / dur), x = target * ease(t);
    reel.style.transform = 'translateX(' + (-x) + 'px)'; var idx = Math.floor((x + box.clientWidth / 2) / W); if (idx !== last) { last = idx; SND.tick(); }
    if (t < 1) requestAnimationFrame(step); else done();
  }
  function done() {
    var r = D.cr.r, col = ['#9aa0a8', '#3c8cff', '#a646ff', '#ffbe28', '#ff2a2a'][r];
    $('winBox').innerHTML = '<div class="win" style="background:linear-gradient(160deg,' + col + '33,transparent);border:1px solid ' + col + '"><div class="rr t' + r + '">' + esc(L('rar')[r]) + '</div><h2>' + esc(L('got')) + ': ' + esc(itemName(D.cr.code)) + '</h2></div>';
    SND.win(r); if (r >= 3) confetti(col);
    banner(L('got'), itemName(D.cr.code), 'gift', col);
  }
  setTimeout(function () { requestAnimationFrame(step); }, 350);
}
R.daily = function () {
  var h = '<div class="days">', today = D.claimed ? Math.max(1, D.streak) : D.streak + 1;
  for (var i = 1; i <= 7; i++) {
    var ap = 20 + 10 * i, vc = 1 + Math.floor(i / 2), cls = i < today || (i === today && D.claimed) ? 'done' : i === today ? 'now' : '';
    h += '<div class="day ' + cls + '"><b>' + esc(L('day')) + ' ' + i + '</b><strong>' + ap + ' AP</strong><small>+' + vc + ' VC</small></div>';
  }
  h += '</div>';
  return card(L('daily') + ' - ' + L('streak') + ': ' + D.streak, h + '<p style="margin-top:12px">' + esc(D.claimed ? L('claimed') + ' - ' + F('dailyWait', hms(D.next)) : L('dailyReady')) + '</p>' + cmd(D.lang === 'tr' ? '/gunluk' : '/daily'));
};
R.zup = function () {
  var names = ZCLS[D.lang], h = '<div class="zups">';
  names.forEach(function (n, i) { var lv = D.zlv[i] | 0, p = ''; for (var k = 0; k < 5; k++) p += '<i' + (k < lv ? ' class="on"' : '') + '></i>'; h += '<div class="zu' + (i === D.zc ? ' cur' : '') + '"><b>' + esc(n) + '</b> <span class="muted">' + esc(L('level')) + ' ' + lv + '/5</span><div class="pips">' + p + '</div></div>'; });
  return card(L('zup'), '<p class="muted" style="margin-bottom:10px">' + esc(L('zupHow')) + '</p>' + h + '</div>' + cmd('/yukselt'));
};
R.trade = function () { return card(L('trade'), '<p>' + esc(L('tradeHow')) + '</p>' + cmd(D.lang === 'tr' ? '/takas' : '/trade')) + R.inv(); };
R.set = function () {
  var dark = store('theme') !== 'light', h = '';
  h += '<div class="set"><span>' + esc(L('theme')) + '</span><div class="seg"><span data-set="dark" class="' + (dark ? 'on' : '') + '">' + esc(L('dark')) + '</span><span data-set="light" class="' + (dark ? '' : 'on') + '">' + esc(L('light')) + '</span></div></div>';
  h += '<div class="set"><span>' + esc(L('sound')) + '</span><div class="sw' + (soundOn ? ' on' : '') + '" data-set="snd"></div></div>';
  h += '<div class="set"><span>' + esc(L('notif')) + '</span><div class="sw' + (notifOn ? ' on' : '') + '" data-set="ntf"></div></div>';
  h += '<div class="set"><span>' + esc(L('lang')) + '</span><div class="seg"><span data-set="tr" class="' + (D.lang === 'tr' ? 'on' : '') + '">Turkce</span><span data-set="en" class="' + (D.lang === 'en' ? 'on' : '') + '">English</span></div></div>';
  var w = '<div class="wps">'; L('wpNames').forEach(function (n, i) { w += '<div class="wpt wp' + i + (i === WP ? ' on' : '') + '" data-wp="' + i + '">' + (i === 7 ? emblem() : '') + '<small>' + esc(n) + '</small></div>'; }); w += '</div>';
  var acc = store('acc') || ACCS[0]; w += '<div class="ccl" style="margin-top:12px">' + esc(L('accent')) + '</div><div class="ccacc">' + ACCS.map(function (c) { return '<span data-acc="' + c + '" class="' + (c === acc ? 'on' : '') + '" style="background:' + c + '"></span>'; }).join('') + '</div>';
  return card(L('set'), h) + card(L('wall'), w) + '<div class="cce" data-app="about" style="margin:0 0 12px">' + svg('about') + esc(L('about')) + '</div>' + card('', '<p class="muted">' + (D.lang === 'tr' ? 'Oyun ici ayarlar' : 'In-game settings') + '</p>' + cmd(D.lang === 'tr' ? '/ayarlar  /dil  /stil' : '/settings  /lang  /style'));
};
R.adm = function () {
  if (D.role < 1) return card('', '<p>' + esc(L('adminOnly')) + '</p>');
  var h = card('', '<div class="stats">' + stat(Math.floor(D.up / 60) + ' ' + L('hours') + ' ' + (D.up % 60) + ' ' + L('min'), L('uptime')) + stat(D.svp + '/' + D.mx, L('players')) + stat(D.map, L('map')) + stat(D.round, L('round')) + '</div>');
  var a = [['amx_menu', D.lang === 'tr' ? 'oyuncu islemleri' : 'player actions'], ['/yonetim', D.lang === 'tr' ? 'Vexmira yonetim menusu (modlar, boss, event)' : 'Vexmira admin menu (modes, boss, events)'], ['amx_kick <isim>', 'kick'], ['amx_ban <isim> <dk>', 'ban'], ['amx_slay <isim>', 'slay'], ['amx_map <harita>', D.lang === 'tr' ? 'harita degistir' : 'change map'], ['vex_plan', D.lang === 'tr' ? 'bu haritanin round plani' : "this map's round plan"], ['vex_fastdl_files', 'FastDL']];
  h += card(L('cmds'), '<div class="cmds">' + a.map(function (x) { return '<div><b>' + esc(x[0]) + '</b>' + esc(x[1]) + '</div>'; }).join('') + '</div>');
  if (D.role >= 2) {
    var f = [['vex_reset_top', D.lang === 'tr' ? 'Top15 sifirla' : 'reset Top15'], ['vex_reset_time', D.lang === 'tr' ? 'sure siralamasini sifirla' : 'reset playtime top'], ['vex_reset_ach', D.lang === 'tr' ? 'basarim siralamasini sifirla' : 'reset achievement top'],
      ['vex_give_vc <isim> <miktar>', 'VexCoin'], ['vex_give_ap <isim> <miktar>', 'AP'], ['vex_give_ach <isim> <0-29>', L('ach')], ['vex_give_case <isim> <0-3>', L('case')], ['vex_vip_add <isim> <gun> <1|2>', 'VIP / ELITE'], ['vex_boss_build', D.lang === 'tr' ? 'dev boss dosyalari' : 'giant boss files']];
    h += card(L('founder'), '<div class="warn">' + (D.lang === 'tr' ? 'Bu islemler geri alinamaz. Konsoldan (rcon) calistir.' : 'These actions cannot be undone. Run them from the console (rcon).') + '</div><div class="cmds">' + f.map(function (x) { return '<div><b>' + esc(x[0]) + '</b>' + esc(x[1]) + '</div>'; }).join('') + '</div>');
  }
  return h;
};
R.about = function () { return card('', '<div class="about"><div class="lg">' + LOGO() + '</div><p><b>VEXMIRA</b> &middot; iPad 6.0</p><p class="muted" style="margin:6px 0">' + esc(L('credit')) + ': <b style="color:var(--acc)">smurfsexy</b></p><p class="muted">' + esc(D.map) + ' &middot; ' + esc(L('round')) + ' ' + esc(D.round) + '</p>' + (D.ts ? '<p class="muted">' + esc(F('updated', Math.max(0, Math.round((Date.now() / 1000 - D.ts) / 60)))) + '</p>' : '') + '</div>'); };

R.store = function () {
  var h = '<div class="feat"><div class="sq" style="' + grad('g2048') + '">' + svg('g2048') + '</div><div><small>' + esc(L('featured')) + '</small><h2>' + esc(L('g2048')) + '</h2><p>' + esc(L('d_g2048')) + '</p></div>' + storeBtn('g2048') + '</div>';
  CATS.forEach(function (c) {
    h += '<h3 class="sth">' + esc(L(c[0])) + '</h3><div class="apps">';
    c[1].forEach(function (a) { h += '<div class="appr"><div class="sq" style="' + grad(a) + '">' + svg(a) + '</div><div class="ad"><b>' + esc(L(a)) + '</b><small>' + esc(L('d_' + a)) + '</small><span class="stars">&#9733;&#9733;&#9733;&#9733;&#9733;</span></div>' + storeBtn(a) + '</div>'; });
    h += '</div>';
  });
  return h;
};
function storeBtn(a) {
  if (CORE.indexOf(a) >= 0) return '<span class="gbtn core">' + esc(L('core')) + '</span>';
  if (INST.indexOf(a) >= 0) return '<span class="gbtn" data-open="' + a + '">' + esc(L('openB')) + '</span>';
  return '<span class="gbtn get" data-get="' + a + '">' + esc(L('get')) + '</span>';
}
var GAME = null;
R.game = function () { return '<div class="gwrap"><canvas id="gcv"></canvas><div class="ghud"><span id="gScore">0</span><span id="gBest"></span></div></div>'; };
function startGame() {
  var cv = $('gcv'); if (!cv) return; var W = cv.width = cv.clientWidth, H = cv.height = cv.clientHeight, cx = cv.getContext('2d');
  var best = num(store('flap')), g = { y: H / 2, v: 0, pipes: [], t: 0, score: 0, state: 0 }, gap = Math.max(110, H * 0.3), spd = Math.max(2.4, W / 300);
  $('gBest').textContent = L('best') + ': ' + best;
  function reset() { g.y = H / 2; g.v = 0; g.pipes = []; g.t = 0; g.score = 0; g.state = 0; $('gScore').textContent = '0'; }
  function flap() { if (g.state === 2) { reset(); return; } if (g.state === 0) g.state = 1; g.v = -H * 0.011; tone(660, 0.07, 'triangle', 0.06, 0, 990); }
  GAME = { flap: flap, stop: false };
  function bat(x, y, a) {
    cx.save(); cx.translate(x, y); cx.rotate(Math.max(-0.5, Math.min(0.9, g.v / 10)));
    var wing = Math.sin(a / 3) * 8; cx.fillStyle = '#1a0a10'; cx.strokeStyle = '#e3243b'; cx.lineWidth = 2;
    cx.beginPath(); cx.moveTo(-4, 0); cx.quadraticCurveTo(-18, -10 - wing, -28, -2 + wing); cx.quadraticCurveTo(-18, 2, -8, 6); cx.closePath(); cx.fill(); cx.stroke();
    cx.beginPath(); cx.moveTo(4, 0); cx.quadraticCurveTo(18, -10 - wing, 28, -2 + wing); cx.quadraticCurveTo(18, 2, 8, 6); cx.closePath(); cx.fill(); cx.stroke();
    cx.beginPath(); cx.ellipse(0, 2, 9, 11, 0, 0, Math.PI * 2); cx.fill(); cx.stroke();
    cx.fillStyle = '#ff3040'; cx.shadowColor = '#ff0020'; cx.shadowBlur = 8; cx.fillRect(-5, -2, 3, 3); cx.fillRect(2, -2, 3, 3); cx.restore();
  }
  function pipe(x, top, bot) {
    var gr = cx.createLinearGradient(x, 0, x + 64, 0); gr.addColorStop(0, '#16300a'); gr.addColorStop(0.5, '#3f7a12'); gr.addColorStop(1, '#0f2406');
    cx.fillStyle = gr; cx.fillRect(x, 0, 64, top); cx.fillRect(x, bot, 64, H - bot);
    cx.fillStyle = '#5bb61a'; cx.fillRect(x - 5, top - 18, 74, 18); cx.fillRect(x - 5, bot, 74, 18);
    cx.fillStyle = 'rgba(200,16,46,.75)'; for (var i = 0; i < 3; i++) { cx.fillRect(x + 10 + i * 18, top - 4, 5, 14 + (i % 2) * 10); }
  }
  (function loop() {
    if (!$('gcv') || GAME.stop) return;
    cx.clearRect(0, 0, W, H);
    var sky = cx.createLinearGradient(0, 0, 0, H); sky.addColorStop(0, '#12040a'); sky.addColorStop(1, '#030103'); cx.fillStyle = sky; cx.fillRect(0, 0, W, H);
    cx.fillStyle = 'rgba(255,230,200,.85)'; cx.beginPath(); cx.arc(W * 0.8, H * 0.2, Math.min(W, H) * 0.08, 0, Math.PI * 2); cx.fill();
    cx.fillStyle = 'rgba(80,0,16,.35)'; for (var m = 0; m < 6; m++) { var mx = ((m * 180 - g.t * 0.4) % (W + 200) + W + 200) % (W + 200) - 100; cx.beginPath(); cx.moveTo(mx, H); cx.lineTo(mx + 90, H * 0.72); cx.lineTo(mx + 180, H); cx.fill(); }
    if (g.state === 1) {
      g.t++; g.v += H * 0.0006; g.y += g.v;
      if (g.t % Math.round(95 / (spd / 2.4)) === 1) { var top = 40 + Math.random() * (H - gap - 80); g.pipes.push({ x: W + 10, top: top, ok: false }); }
      g.pipes.forEach(function (p) { p.x -= spd; if (!p.ok && p.x + 64 < W * 0.3) { p.ok = true; g.score++; $('gScore').textContent = g.score; tone(1320, 0.06, 'sine', 0.06); } });
      g.pipes = g.pipes.filter(function (p) { return p.x > -80; });
      var bx = W * 0.3;
      g.pipes.forEach(function (p) { if (bx + 14 > p.x && bx - 14 < p.x + 64 && (g.y - 10 < p.top || g.y + 10 > p.top + gap)) g.state = 2; });
      if (g.y > H - 8 || g.y < 0) g.state = 2;
      if (g.state === 2) { tone(180, 0.5, 'sawtooth', 0.08, 0, 60); if (g.score > best) { best = g.score; store('flap', best); $('gBest').textContent = L('best') + ': ' + best; } }
    }
    g.pipes.forEach(function (p) { pipe(p.x, p.top, p.top + gap); });
    bat(W * 0.3, g.y, g.t + (g.state === 0 ? Date.now() / 30 : 0));
    cx.textAlign = 'center'; cx.fillStyle = '#fff'; cx.font = 'bold ' + Math.round(H / 18) + 'px Arial';
    if (g.state === 0) cx.fillText(L('tapStart'), W / 2, H * 0.72);
    if (g.state === 2) { cx.fillStyle = 'rgba(0,0,0,.55)'; cx.fillRect(0, 0, W, H); cx.fillStyle = '#e3243b'; cx.font = 'bold ' + Math.round(H / 10) + 'px Arial Black,Arial'; cx.fillText(L('over'), W / 2, H * 0.42); cx.fillStyle = '#fff'; cx.font = Math.round(H / 18) + 'px Arial'; cx.fillText(L('score') + ': ' + g.score + '   ' + L('best') + ': ' + best, W / 2, H * 0.55); cx.fillText(L('tapStart'), W / 2, H * 0.66); }
    requestAnimationFrame(loop);
  })();
}
// ------------------------------------------------------------------ extra apps
function tr(a, b) { return D.lang === 'tr' ? a : b; }
var MODES = [
  ['Enfeksiyon', 'Infection', 'Tek zombi baslar, salgin enfekte ettikce yayilir.', 'One zombie starts, the plague spreads with every infection.'],
  ['Coklu Enfeksiyon', 'Multi Infection', 'Basta birden fazla zombi vardir.', 'Several zombies from the very start.'],
  ['Nemesis', 'Nemesis', 'Tek vurusta olduren dev zombi. [R] atilma, [F] ofke.', 'A huge zombie that kills in one hit. [R] leap, [F] rage.'],
  ['Assassin', 'Assassin', 'Karanlikta avlanan, cok hizli ve tek vurusta olduren zombi.', 'A very fast one-hit zombie hunting in the dark.'],
  ['Survivor', 'Survivor', 'Tek silahli kahraman tum zombilere karsi.', 'One armed hero against all the zombies.'],
  ['Sniper', 'Sniper', 'Tek atista olduren AWPli keskin nisanci.', 'One sniper with a one-shot AWP.'],
  ['Swarm', 'Swarm', 'Yari zombi, enfeksiyon yok, sadece kan.', 'Half zombies, no infection, only blood.'],
  ['Plague', 'Plague', 'Survivor + Nemesis + zombiler insanlara karsi.', 'Survivor + Nemesis + zombies against humans.'],
  ['Armageddon', 'Armageddon', 'Nemesis ordusu Survivor ordusuna karsi.', 'Nemesis army against Survivor army.'],
  ['BOSS', 'BOSS', '3 faz, 5 yetenek. Renkli halkalara dikkat, herkes birlikte savasir.', '3 phases, 5 skills. Watch the colored circles, everyone fights together.']
];
var TIPS = [
  ['Lazer mayinini koridorlara ve kapilara kur: /lazerkur', 'Plant laser mines in corridors and doors: /plant'],
  ['Zombiyken enfekte etmek +1, oldurmek +2 gelisim puani verir.', 'As a zombie, infecting gives +1 and killing +2 upgrade points.'],
  ['Kafaya vurus daha cok hasar ve daha cok geri itme yapar.', 'Headshots deal more damage and more knockback.'],
  ['Her gun gir, 7 gunluk seriyi tamamla: /gunluk', 'Log in every day and finish the 7-day streak: /daily'],
  ['Nadir esyalar sunucudaki herkese duyurulur. Kabus Kasasi en sansli kasadir.', 'Rare drops are announced to everyone. The Nightmare Case has the best odds.']
];
R.guide = function () {
  var h = card(L('modes'), '<div class="glist">' + MODES.map(function (m, i) { return '<div class="gi"><span class="gn">' + (i + 1) + '</span><div><b>' + esc(tr(m[0], m[1])) + '</b><small>' + esc(tr(m[2], m[3])) + '</small></div></div>'; }).join('') + '</div>');
  var zc = ZCLS[D.lang] || ZCLS.tr;
  h += card(L('classes'), '<div class="zchips">' + zc.map(function (n) { return '<span>' + esc(n) + '</span>'; }).join('') + '</div>' + cmd(tr('/sinif', '/class')));
  h += card(L('tips'), '<div class="glist">' + TIPS.map(function (t) { return '<div class="gi"><span class="gn">&#10148;</span><div><small style="color:var(--txt);font-size:12.5px">' + esc(tr(t[0], t[1])) + '</small></div></div>'; }).join('') + '</div>');
  return h;
};
var CMDS = [
  ['ipad', 'tablet', 'Tableti acar', 'Opens the tablet'], ['menu', 'menu', 'Ana menu', 'Main menu'], ['shop', 'market', 'Esya marketi', 'Item shop'], ['vcmarket', 'coinmarket', 'VexCoin marketi', 'VexCoin market'],
  ['guns', 'silah', 'Silah menusu', 'Weapon menu'], ['sw', 'ozelsilah', 'Ozel silahlar', 'Special weapons'], ['class', 'sinif', 'Zombi sinifi sec', 'Pick a zombie class'], ['knives', 'bicaklar', 'Bicaklar', 'Knives'],
  ['wings', 'kanat', 'Kanatlar', 'Wings'], ['pet', 'pet', 'Petler', 'Pets'], ['trail', 'iz', 'Izler', 'Trails'], ['cosmetic', 'kozmetik', 'Kozmetik', 'Cosmetics'],
  ['plant', 'lazerkur', 'Lazer mayini kur', 'Plant a laser mine'], ['take', 'lazersok', 'Lazer mayinini sok', 'Take a laser mine back'], ['case', 'kasa', 'Kasa ac', 'Open a case'], ['trade', 'takas', 'Takas', 'Trade'],
  ['daily', 'gunluk', 'Gunluk odul', 'Daily reward'], ['quest', 'gorev', 'Gorevler', 'Quests'], ['achievements', 'basarimlar', 'Basarimlar', 'Achievements'], ['top15', 'top15', 'En iyi 15', 'Top 15'],
  ['toptime', 'sure', 'Sure siralamasi', 'Playtime top'], ['rank', 'rutbe', 'Rutben', 'Your rank'], ['stats', 'istatistik', 'Istatistik', 'Stats'], ['vip', 'vipmenu', 'VIP menusu', 'VIP menu'],
  ['settings', 'ayarlar', 'Ayarlar', 'Settings'], ['lang', 'dil', 'Dil secimi', 'Language'], ['rtv', 'haritadegis', 'Harita oylamasi', 'Rock the vote'], ['nextmap', 'sonrakiharita', 'Sonraki harita', 'Next map'],
  ['unstuck', 'takildim', 'Sikistiysan kurtar', 'Get unstuck'], ['rules', 'kurallar', 'Kurallar', 'Rules'], ['help', 'yardim', 'Yardim', 'Help'], ['discord', 'iletisim', 'Iletisim', 'Contact']
];
R.cmds = function () {
  return card('', '<div class="cmds">' + CMDS.map(function (c) { return '<div><b>/' + esc(D.lang === 'tr' ? c[1] : c[0]) + '</b>' + esc(tr(c[2], c[3])) + '</div>'; }).join('') + '</div>');
};
// music: procedural horror ambience (WebAudio)
var MUS = { i: -1, nodes: [], timers: [], an: null, out: null };
function musStop() {
  MUS.timers.forEach(function (t) { clearInterval(t); }); MUS.timers = [];
  MUS.nodes.forEach(function (n) { try { n.stop(); } catch (e) {} try { n.disconnect(); } catch (e) {} }); MUS.nodes = []; MUS.i = -1;
}
function musPlay(i) {
  musStop(); var c = ac(); if (!c) return; if (c.resume) c.resume(); MUS.i = i;
  var out = c.createGain(); out.gain.value = 0; out.gain.linearRampToValueAtTime(0.55, c.currentTime + 2);
  var an = c.createAnalyser(); an.fftSize = 128; out.connect(an); an.connect(c.destination); MUS.an = an; MUS.out = out; MUS.nodes.push(out, an);
  function osc(type, f, g, dest) { var o = c.createOscillator(), gg = c.createGain(); o.type = type; o.frequency.value = f; gg.gain.value = g; o.connect(gg); gg.connect(dest || out); o.start(); MUS.nodes.push(o, gg); return { o: o, g: gg }; }
  function noise(g, type, fc, q) { var b = c.createBuffer(1, c.sampleRate * 2, c.sampleRate), d = b.getChannelData(0); for (var k = 0; k < d.length; k++) d[k] = Math.random() * 2 - 1; var s = c.createBufferSource(); s.buffer = b; s.loop = true; var f = c.createBiquadFilter(); f.type = type; f.frequency.value = fc; f.Q.value = q || 0.7; var gg = c.createGain(); gg.gain.value = g; s.connect(f); f.connect(gg); gg.connect(out); s.start(); MUS.nodes.push(s, f, gg); return { f: f, g: gg }; }
  function note(f, d, type, vol, when) { var t = c.currentTime + (when || 0), o = c.createOscillator(), g = c.createGain(); o.type = type; o.frequency.value = f; g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(vol, t + 0.02); g.gain.exponentialRampToValueAtTime(0.0001, t + d); o.connect(g); g.connect(out); o.start(t); o.stop(t + d + 0.05); }
  function lfo(param, rate, depth) { var o = c.createOscillator(), g = c.createGain(); o.frequency.value = rate; g.gain.value = depth; o.connect(g); g.connect(param); o.start(); MUS.nodes.push(o, g); }
  var AM = [220, 246.9, 261.6, 293.7, 329.6, 349.2, 392];
  if (i === 0) {
    var lp = c.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 300; lp.connect(out); MUS.nodes.push(lp);
    osc('sawtooth', 55, 0.08, lp); osc('sawtooth', 55.3, 0.08, lp); osc('sine', 82.4, 0.08); lfo(lp.frequency, 0.07, 180);
    noise(0.04, 'lowpass', 500);
    MUS.timers.push(setInterval(function () { var f = AM[Math.floor(Math.random() * AM.length)] * (Math.random() < 0.5 ? 1 : 2); note(f, 2.2, 'sine', 0.07); note(f * 1.5, 2.2, 'sine', 0.025, 0.3); }, 2600));
  } else if (i === 1) {
    osc('sine', 880, 0.012).o.detune.value = 8; osc('sine', 659, 0.012); noise(0.02, 'bandpass', 2400, 4);
    var beat = function () { note(62, 0.32, 'sine', 0.55); note(55, 0.36, 'sine', 0.42, 0.26); };
    beat(); MUS.timers.push(setInterval(beat, 1050));
  } else if (i === 2) {
    noise(0.16, 'bandpass', 1300, 0.6); noise(0.08, 'highpass', 5000); osc('sine', 49, 0.07); osc('triangle', 73.4, 0.03);
    MUS.timers.push(setInterval(function () { if (Math.random() < 0.45) { var th = noise(0, 'lowpass', 180); var t = c.currentTime; th.g.gain.setValueAtTime(0, t); th.g.gain.linearRampToValueAtTime(0.7, t + 0.08); th.g.gain.exponentialRampToValueAtTime(0.001, t + 3.5); } }, 5200));
  } else {
    var CH = [[220, 261.6, 329.6], [174.6, 220, 261.6], [130.8, 196, 261.6], [196, 246.9, 293.7]], ci = 0;
    var chord = function () { CH[ci % 4].forEach(function (f) { note(f, 4.2, 'triangle', 0.05); note(f / 2, 4.2, 'sine', 0.04); }); ci++; };
    chord(); MUS.timers.push(setInterval(chord, 4000));
    MUS.timers.push(setInterval(function () { note(AM[Math.floor(Math.random() * AM.length)] * 4, 1.4, 'sine', 0.035); }, 900));
    noise(0.02, 'lowpass', 900);
  }
}
R.music = function () {
  var tk = L('tracks'), h = '<div class="mus"><canvas id="mviz"></canvas><div class="mnow"><small>' + esc(L('np')) + '</small><b>' + esc(MUS.i >= 0 ? tk[MUS.i] : '-') + '</b></div></div><div class="tracks">';
  tk.forEach(function (n, i) { var on = MUS.i === i; h += '<div class="trk' + (on ? ' on' : '') + '" data-mus="' + i + '"><span class="tb" style="' + grad(['music', 'prof', 'case', 'inv'][i]) + '">' + svg(on ? 'pause' : 'play') + '</span><div><b>' + esc(n) + '</b><small>VEXMIRA Ambience &middot; ' + ['4:12', '3:30', '5:05', '4:48'][i] + '</small></div></div>'; });
  return h + '</div>';
};
function musViz() {
  var cv = $('mviz'); if (!cv) return; var W = cv.width = cv.clientWidth, H = cv.height = cv.clientHeight, cx = cv.getContext('2d'), arr = new Uint8Array(64);
  (function f() {
    if (!$('mviz') || cur !== 'music') return;
    cx.clearRect(0, 0, W, H);
    if (MUS.an && MUS.i >= 0) MUS.an.getByteFrequencyData(arr); else for (var k = 0; k < 64; k++) arr[k] = 0;
    var bw = W / 40;
    for (var j = 0; j < 40; j++) { var v = arr[j + 2] / 255, bh = Math.max(3, v * H * 0.9), gr = cx.createLinearGradient(0, H, 0, H - bh); gr.addColorStop(0, ICOL.music.split(',')[1]); gr.addColorStop(1, ICOL.music.split(',')[0]); cx.fillStyle = gr; cx.fillRect(j * bw + 2, H - bh, bw - 4, bh); }
    requestAnimationFrame(f);
  })();
}
R.notes = function () { return '<textarea id="notesTa" class="notes" placeholder="' + esc(L('notesPh')) + '">' + esc(store('notes') || '') + '</textarea>'; };
var CALC = { v: '0', a: null, op: null, fresh: true };
R.calc = function () {
  var k = [['C', 'fn'], ['+/-', 'fn'], ['%', 'fn'], ['/', 'op'], ['7'], ['8'], ['9'], ['*', 'op'], ['4'], ['5'], ['6'], ['-', 'op'], ['1'], ['2'], ['3'], ['+', 'op'], ['0', 'z'], ['.'], ['=', 'op']];
  return '<div class="calc"><div class="cdisp" id="cdisp">' + esc(CALC.v) + '</div><div class="ckeys">' + k.map(function (x) { return '<span class="ck ' + (x[1] || '') + '" data-calc="' + x[0] + '">' + (x[0] === '*' ? '&times;' : x[0] === '/' ? '&divide;' : x[0]) + '</span>'; }).join('') + '</div></div>';
};
function calcKey(k) {
  var C = CALC, cur2 = parseFloat(C.v);
  function run() { if (C.op === null || C.a === null) return cur2; var r = C.op === '+' ? C.a + cur2 : C.op === '-' ? C.a - cur2 : C.op === '*' ? C.a * cur2 : cur2 === 0 ? 0 : C.a / cur2; return Math.round(r * 1e10) / 1e10; }
  if (/^[0-9]$/.test(k)) { C.v = (C.fresh || C.v === '0') ? k : (C.v.length < 12 ? C.v + k : C.v); C.fresh = false; }
  else if (k === '.') { if (C.fresh) { C.v = '0.'; C.fresh = false; } else if (C.v.indexOf('.') < 0) C.v += '.'; }
  else if (k === 'C') { C.v = '0'; C.a = null; C.op = null; C.fresh = true; }
  else if (k === '+/-') C.v = String(-cur2);
  else if (k === '%') C.v = String(cur2 / 100);
  else if (k === '=') { C.v = String(run()); C.a = null; C.op = null; C.fresh = true; }
  else { if (!C.fresh) C.a = C.op ? run() : cur2; else if (C.a === null) C.a = cur2; C.v = String(C.a); C.op = k; C.fresh = true; }
  var d = $('cdisp'); if (d) d.textContent = C.v;
}
// ------------------------------------------------------------------ games
function gameHud(id) { return '<div class="ghud"><span id="gScore">0</span><span id="gBest"></span></div>'; }
function pads() { return '<div class="gpads"><span data-dir="3">&#9664;</span><span data-dir="0">&#9650;</span><span data-dir="2">&#9660;</span><span data-dir="1">&#9654;</span></div>'; }
R.snake = function () { return '<div class="gwrap"><canvas id="scv"></canvas>' + gameHud() + '<div class="ghint">' + esc(L('hintSnake')) + '</div>' + pads() + '</div>'; };
function startSnake() {
  var cv = $('scv'); if (!cv) return; var W = cv.width = cv.clientWidth, H = cv.height = cv.clientHeight, cx = cv.getContext('2d');
  var cs = Math.max(14, Math.floor(Math.min(W / 28, H / 18))), CW = Math.floor(W / cs), CH = Math.floor(H / cs), ox = (W - CW * cs) / 2, oy = (H - CH * cs) / 2;
  var best = num(store('snake')), s, dir, nd, food, dead, score, last = 0, run = false;
  $('gBest').textContent = L('best') + ': ' + best;
  function place() { do { food = { x: Math.floor(Math.random() * CW), y: Math.floor(Math.random() * CH) }; } while (s.some(function (p) { return p.x === food.x && p.y === food.y; })); }
  function reset() { s = [{ x: 6, y: Math.floor(CH / 2) }, { x: 5, y: Math.floor(CH / 2) }, { x: 4, y: Math.floor(CH / 2) }]; dir = 1; nd = 1; dead = false; score = 0; $('gScore').textContent = '0'; place(); }
  reset();
  function turn(d) { if (dead) { reset(); run = true; return; } run = true; if ((d + 2) % 4 !== dir) nd = d; }
  GAME = { stop: false, dir: turn, key: function (k) { var m = { 38: 0, 87: 0, 39: 1, 68: 1, 40: 2, 83: 2, 37: 3, 65: 3 }; if (m[k] !== undefined) { turn(m[k]); return true; } if (k === 32) { turn(dir); return true; } return false; }, tap: function () { turn(dir); } };
  function draw() {
    cx.fillStyle = '#07080a'; cx.fillRect(0, 0, W, H);
    cx.strokeStyle = 'rgba(255,255,255,.03)'; for (var gx = 0; gx <= CW; gx++) { cx.beginPath(); cx.moveTo(ox + gx * cs, oy); cx.lineTo(ox + gx * cs, oy + CH * cs); cx.stroke(); } for (var gy = 0; gy <= CH; gy++) { cx.beginPath(); cx.moveTo(ox, oy + gy * cs); cx.lineTo(ox + CW * cs, oy + gy * cs); cx.stroke(); }
    cx.shadowColor = '#ff2846'; cx.shadowBlur = 14; cx.fillStyle = '#ff3550'; cx.beginPath(); cx.arc(ox + food.x * cs + cs / 2, oy + food.y * cs + cs / 2, cs * 0.36, 0, 7); cx.fill(); cx.shadowBlur = 0;
    s.forEach(function (p, i) { var t = i / s.length; cx.fillStyle = 'rgb(' + Math.round(86 - 50 * t) + ',' + Math.round(224 - 120 * t) + ',' + Math.round(122 - 70 * t) + ')'; var r = cs * 0.18, x = ox + p.x * cs + 1, y = oy + p.y * cs + 1, w = cs - 2; cx.beginPath(); cx.moveTo(x + r, y); cx.arcTo(x + w, y, x + w, y + w, r); cx.arcTo(x + w, y + w, x, y + w, r); cx.arcTo(x, y + w, x, y, r); cx.arcTo(x, y, x + w, y, r); cx.fill(); });
    cx.textAlign = 'center'; cx.fillStyle = '#fff'; cx.font = 'bold ' + Math.round(H / 16) + 'px Arial';
    if (!run && !dead) cx.fillText(L('tapStart'), W / 2, H * 0.4);
    if (dead) { cx.fillStyle = 'rgba(0,0,0,.55)'; cx.fillRect(0, 0, W, H); cx.fillStyle = '#ff3550'; cx.fillText(L('over'), W / 2, H * 0.42); cx.fillStyle = '#fff'; cx.font = Math.round(H / 20) + 'px Arial'; cx.fillText(L('score') + ': ' + score + '   ' + L('best') + ': ' + best, W / 2, H * 0.52); }
  }
  (function loop(ts) {
    if (!$('scv') || GAME.stop) return;
    if (run && !dead && ts - last > Math.max(60, 120 - score * 2)) {
      last = ts; dir = nd; var h = { x: s[0].x + [0, 1, 0, -1][dir], y: s[0].y + [-1, 0, 1, 0][dir] };
      if (h.x < 0 || h.y < 0 || h.x >= CW || h.y >= CH || s.some(function (p) { return p.x === h.x && p.y === h.y; })) { dead = true; run = false; tone(160, 0.5, 'sawtooth', 0.08, 0, 60); if (score > best) { best = score; store('snake', best); $('gBest').textContent = L('best') + ': ' + best; } }
      else { s.unshift(h); if (h.x === food.x && h.y === food.y) { score++; $('gScore').textContent = score; tone(1100, 0.06, 'sine', 0.06, 0, 1500); place(); } else s.pop(); }
    }
    draw(); requestAnimationFrame(loop);
  })(0);
}
R.g2048 = function () { return '<div class="g48"><div class="g48h"><div><small>' + esc(L('score')) + '</small><b id="gScore">0</b></div><div><small>' + esc(L('best')) + '</small><b id="gBest">0</b></div><span class="gbtn get" data-gs="1">' + esc(L('again')) + '</span></div><div class="g48b" id="g48b"></div><div class="ghint">' + esc(L('hint2048')) + '</div>' + pads() + '</div>'; };
function start2048() {
  var B, score, best = num(store('2048')), over;
  function add() { var e = []; B.forEach(function (v, i) { if (!v) e.push(i); }); if (e.length) B[e[Math.floor(Math.random() * e.length)]] = Math.random() < 0.9 ? 2 : 4; }
  function reset() { B = []; for (var i = 0; i < 16; i++) B.push(0); score = 0; over = false; add(); add(); draw(); }
  function draw() { var el = $('g48b'); if (!el) return; el.innerHTML = B.map(function (v) { return '<div class="c48 v' + Math.min(v, 4096) + '">' + (v || '') + '</div>'; }).join('') + (over ? '<div class="g48o">' + esc(L('over')) + '</div>' : ''); $('gScore').textContent = score; $('gBest').textContent = best; }
  function move(d) {
    if (over) return; var moved = false;
    for (var a = 0; a < 4; a++) {
      var idx = []; for (var b = 0; b < 4; b++) idx.push(d === 0 ? b * 4 + a : d === 2 ? (3 - b) * 4 + a : d === 3 ? a * 4 + b : a * 4 + (3 - b));
      var line = idx.map(function (i) { return B[i]; }).filter(function (v) { return v; }), out = [];
      for (var k = 0; k < line.length; k++) { if (line[k] === line[k + 1]) { out.push(line[k] * 2); score += line[k] * 2; k++; } else out.push(line[k]); }
      while (out.length < 4) out.push(0);
      idx.forEach(function (i, j) { if (B[i] !== out[j]) moved = true; B[i] = out[j]; });
    }
    if (moved) { add(); tone(520 + Math.min(score, 2000) / 4, 0.05, 'triangle', 0.05); if (score > best) { best = score; store('2048', best); } }
    var can = B.some(function (v) { return !v; }); for (var i = 0; i < 16 && !can; i++) { if (i % 4 < 3 && B[i] === B[i + 1]) can = true; if (i < 12 && B[i] === B[i + 4]) can = true; }
    if (!can) { over = true; tone(160, 0.5, 'sawtooth', 0.06, 0, 70); }
    draw();
  }
  GAME = { stop: false, dir: move, start: reset, key: function (k) { var m = { 38: 0, 87: 0, 39: 1, 68: 1, 40: 2, 83: 2, 37: 3, 65: 3 }; if (m[k] !== undefined) { move(m[k]); return true; } return false; } };
  var sx = null, sy = null, bd = $('g48b');
  if (bd) { bd.addEventListener('mousedown', function (e) { sx = e.clientX; sy = e.clientY; }); bd.addEventListener('mouseup', function (e) { if (sx === null) return; var dx = e.clientX - sx, dy = e.clientY - sy; sx = null; if (Math.max(Math.abs(dx), Math.abs(dy)) < 24) return; move(Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2 : 0)); }); }
  reset();
}
R.whack = function () { var h = '<div class="wk"><div class="wkh"><div><small>' + esc(L('score')) + '</small><b id="gScore">0</b></div><div><small>' + esc(L('timeLeft')) + '</small><b id="wkT">30</b></div><div><small>' + esc(L('best')) + '</small><b id="gBest">0</b></div><span class="gbtn get" data-gs="1">' + esc(L('start')) + '</span></div><div class="wkg">'; for (var i = 0; i < 9; i++) h += '<div class="hole" data-hole="' + i + '"><i class="zb"></i></div>'; return h + '</div></div>'; };
function startWhack() {
  var best = num(store('whack')), score = 0, tl = 0, live = -1, timer = null, spawn = null;
  $('gBest').textContent = best;
  function show() { var hs = document.querySelectorAll('.hole'); for (var i = 0; i < hs.length; i++) hs[i].className = 'hole' + (i === live ? ' up' : ''); }
  function next() { if (tl <= 0) return; var n; do { n = Math.floor(Math.random() * 9); } while (n === live); live = n; show(); clearTimeout(spawn); spawn = setTimeout(next, Math.max(420, 900 - score * 15)); }
  function end() { clearInterval(timer); clearTimeout(spawn); live = -1; show(); tone(200, 0.4, 'sawtooth', 0.06, 0, 90); if (score > best) { best = score; store('whack', best); } $('gBest').textContent = best; banner(L('whack'), L('score') + ': ' + score, 'whack', ICOL.whack.split(',')[1]); }
  function start() { score = 0; tl = 30; $('gScore').textContent = '0'; $('wkT').textContent = '30'; clearInterval(timer); timer = setInterval(function () { if (!$('wkT') || GAME.stop) { clearInterval(timer); clearTimeout(spawn); return; } tl--; $('wkT').textContent = tl; if (tl <= 0) end(); }, 1000); next(); }
  GAME = { stop: false, start: start, hit: function (i) { if (i === live && tl > 0) { score++; $('gScore').textContent = score; tone(300, 0.08, 'square', 0.07, 0, 90); var h = document.querySelectorAll('.hole')[i]; h.className = 'hole hit'; live = -1; clearTimeout(spawn); spawn = setTimeout(next, 220); } } };
}
var STARTERS = { game: function () { startGame(); }, snake: startSnake, g2048: start2048, whack: startWhack, music: musViz };

// ------------------------------------------------------------------ home (widgets + grid + folder + edit mode)
var cur = null, EDIT = false, ACCS = ['#e3243b', '#ff6a2b', '#ffc23a', '#3ddc84', '#2fb8ff', '#8b5cff', '#ff4fa0'];
function applyAccent() { var a = store('acc'); document.documentElement.style.setProperty('--acc', ACCS.indexOf(a) >= 0 ? a : ''); if (ACCS.indexOf(a) < 0) document.documentElement.style.removeProperty('--acc'); }
function applyBright() { var b = num(store('br'), 100); $('screen').style.filter = b < 100 ? 'brightness(' + (b / 100) + ')' : ''; }
function icoHtml(a, badges, dock) {
  if (a === 'games') { var gs = GAMES.filter(installed); return '<div class="ico" data-fold="games"><div class="sq fold">' + gs.slice(0, 4).map(function (g) { return '<i style="' + grad(g) + '">' + svg(g) + '</i>'; }).join('') + '</div><span>' + esc(L('games')) + '</span></div>'; }
  var rm = (EDIT && !dock && CORE.indexOf(a) < 0) ? '<em class="rmx" data-rm="' + a + '">&minus;</em>' : '';
  return '<div class="ico" data-app="' + a + '"><div class="sq" style="' + grad(a) + '">' + svg(a) + (badges[a] ? '<span class="badge">' + badges[a] + '</span>' : '') + '</div>' + rm + '<span>' + esc(L(a)) + '</span></div>';
}
function homeApps() {
  var list = APPS.filter(function (a) { return DOCK.indexOf(a) < 0 && GAMES.indexOf(a) < 0 && installed(a) && a !== 'about'; });
  if (GAMES.some(installed)) list.push('games');
  if (D.role >= 1) list.push('adm');
  return list;
}
function widgets() {
  var pct = Math.max(0, Math.min(100, D.xn > 0 ? Math.round(D.xp * 100 / D.xn) : 100));
  var w = '<div class="wg wprof" data-app="prof"><div class="wh"><div class="ava sm" style="' + avaColor(D.lv) + '">' + esc(initials(D.name)) + '</div><div class="wn"><b>' + esc(D.name) + (D.vip ? '<span class="vip">' + (D.vip === 2 ? 'ELITE' : 'VIP') + '</span>' : '') + '</b><small>' + esc(L('level')) + ' ' + D.lv + (D.rank ? ' &middot; #' + D.rank : '') + '</small></div></div>' +
    '<div class="bar"><i style="width:' + pct + '%"></i></div><div class="wrow"><span><i class="dot" style="background:var(--gold)"></i>' + fmt(D.vc) + ' VC</span><span><i class="dot" style="background:var(--acc2)"></i>' + fmt(D.ap) + ' AP</span><span class="muted">' + pct + '% ' + esc(L('xp')) + '</span></div></div>';
  w += '<div class="wg wsrv">' + ichip('map', L('map'), D.map || '-', '#ff4d5e') + ichip('flag', L('round'), D.round || '-', '#ffc23a') + ichip('users', L('online'), D.on + '/' + D.mx, '#43e0a0') + '</div>';
  if (D.top.length) w += '<div class="wg wtop" data-app="top"><h4>' + esc(L('top3')) + '</h4>' + D.top.slice(0, 3).map(function (r, i) { return '<div class="t3">' + medal(i) + '<b>' + esc(r.n) + '</b><small>' + esc(L('level')) + ' ' + esc(r.lv) + '</small></div>'; }).join('') + '</div>';
  return '<div class="wcol">' + w + '</div>';
}
function renderHome() {
  var badges = { daily: D.claimed ? 0 : 1, 'case': D.cr ? 1 : 0 };
  var h = '<div class="hello"><h1>' + esc(L('hello')) + ', <b>' + esc(D.name) + '</b></h1><div class="hact">' +
    (EDIT ? '<span class="pill on" data-ui="done">' + esc(L('done')) + '</span>' : '<span class="pill" data-ui="cc">' + svg('brush') + esc(L('custom')) + '</span>') + '</div></div>';
  h += '<div class="hbody' + (EDIT ? ' edit' : '') + '">' + widgets() + '<div class="grid">' + homeApps().map(function (a) { return icoHtml(a, badges); }).join('') + '</div></div>';
  h += '<div class="dock">' + DOCK.map(function (a) { return icoHtml(a, badges, true); }).join('') + '</div>';
  $('home').innerHTML = h;
}
function overlay(id, html) {
  var o = $(id); if (!o) { o = document.createElement('div'); o.id = id; $('screen').appendChild(o); }
  o.className = 'ov ' + id; o.innerHTML = html; setTimeout(function () { o.className = 'ov ' + id + ' show'; }, 10);
}
function closeOv(id) { var o = $(id); if (o) { o.className = 'ov ' + id; } }
function openFolder() {
  var gs = GAMES.filter(installed);
  overlay('fold', '<div class="fp"><h3>' + esc(L('games')) + '</h3><div class="fgrid">' + gs.map(function (g) { return icoHtml(g, {}); }).join('') + '</div></div>');
  SND.open();
}
function ccHtml() {
  var dark = store('theme') !== 'light', acc = store('acc') || ACCS[0], br = num(store('br'), 100);
  function tile(k, ic, on, lab, val) { return '<div class="cct' + (on ? ' on' : '') + '" data-set="' + k + '"><i>' + svg(ic) + '</i><b>' + esc(lab) + '</b><small>' + esc(val) + '</small></div>'; }
  var h = '<div class="ccp"><div class="cch"><b>' + esc(L('cc')) + '</b><span class="x" data-ui="ccx">&times;</span></div><div class="ccg">' +
    tile(dark ? 'light' : 'dark', dark ? 'moon' : 'sun', dark, L('theme'), dark ? L('dark') : L('light')) + tile('snd', 'vol', soundOn, L('sound'), soundOn ? 'ON' : 'OFF') +
    tile('ntf', 'bell', notifOn, L('notif'), notifOn ? 'ON' : 'OFF') + tile(D.lang === 'tr' ? 'en' : 'tr', 'globe', true, L('lang'), D.lang === 'tr' ? 'Turkce' : 'English') + '</div>';
  h += '<div class="ccs"><i>' + svg('bright') + '</i><input id="ccBr" type="range" min="45" max="100" value="' + br + '"></div>';
  h += '<div class="ccl">' + esc(L('accent')) + '</div><div class="ccacc">' + ACCS.map(function (c) { return '<span data-acc="' + c + '" class="' + (c === acc ? 'on' : '') + '" style="background:' + c + '"></span>'; }).join('') + '</div>';
  h += '<div class="ccl">' + esc(L('wall')) + '</div><div class="ccwp">' + L('wpNames').map(function (n, i) { return '<div class="wpt wp' + i + (i === WP ? ' on' : '') + '" data-wp="' + i + '" title="' + esc(n) + '">' + (i === 7 ? emblem() : '') + '<small>' + esc(n) + '</small></div>'; }).join('') + '</div>';
  if (MUS.i >= 0) h += '<div class="ccm"><i style="' + grad('music') + '">' + svg('music') + '</i><div><small>' + esc(L('np')) + '</small><b>' + esc(L('tracks')[MUS.i]) + '</b></div><span class="gbtn" data-ui="mstop">' + esc(L('stop')) + '</span></div>';
  h += '<div class="cce" data-ui="edit">' + svg('grid') + esc(L('edit')) + '</div></div>';
  return h;
}
function openCC() { overlay('cc', ccHtml()); var r = $('ccBr'); if (r) r.addEventListener('input', function () { store('br', r.value); applyBright(); }); SND.open(); }
function refreshCC() { var o = $('cc'); if (o && o.className.indexOf('show') >= 0) { o.innerHTML = ccHtml(); var r = $('ccBr'); if (r) r.addEventListener('input', function () { store('br', r.value); applyBright(); }); } }
function setWall() { var w = $('wall'); w.className = 'wall wp' + WP + (cur ? ' blur' : ''); w.innerHTML = WP === 7 ? '<div class="wlogo">' + emblem() + '</div>' : ''; }
function openApp(a, noSound) {
  if (!R[a]) a = 'prof'; closeOv('fold'); closeOv('cc'); EDIT = false; cur = a;
  if (GAME) GAME.stop = true; GAME = null;
  $('appTitle').textContent = L(a); $('appIco').style.cssText = grad(a); $('appIco').innerHTML = svg(a);
  $('backTxt').textContent = L('home'); $('appRight').textContent = D.role >= 2 ? (D.lang === 'tr' ? 'Kurucu' : 'Founder') : D.role === 1 ? 'Admin' : '';
  $('appBody').innerHTML = R[a](); $('appBody').scrollTop = 0; $('appBody').className = 'app-body' + (GAMES.indexOf(a) >= 0 || a === 'calc' || a === 'notes' ? ' full' : '');
  $('app').className = 'app open'; $('home').className = 'home hide'; setWall();
  if (!noSound) SND.open();
  if (a === 'case') runReel();
  if (STARTERS[a]) setTimeout(STARTERS[a], 60);
}
function goHome() { if (GAME) { GAME.stop = true; GAME = null; } closeOv('fold'); closeOv('cc'); var was = cur; cur = null; $('app').className = 'app'; $('home').className = 'home'; setWall(); if (was) SND.close(); renderHome(); }
function rerender() { applyTheme(); applyAccent(); renderHome(); if (cur) { $('appBody').innerHTML = R[cur](); $('appTitle').textContent = L(cur); $('backTxt').textContent = L('home'); if (STARTERS[cur] && cur !== 'game') STARTERS[cur](); } $('lockHint').textContent = L('unlock'); clock(); refreshCC(); }
function unlock(page) { var lk = $('lock'); if (lk.className.indexOf('off') >= 0) return; lk.className = 'lock off'; $('screen').className = 'screen'; $('home').className = 'home'; SND.unlock(); if (page && page !== 'home') openApp(page, true); notifications(); }
function notifications() {
  var d = 300;
  if (DEMO) { banner('DEMO', L('demo'), 'about', '#a06400', d); d += 900; }
  if (!D.claimed) { banner(L('daily'), L('dailyReady'), 'daily', ICOL.daily.split(',')[1], d); d += 900; }
  if (D.vip && D.vd > 0 && D.vd <= 3) { banner('VIP', F('vipDays', D.vd), 'ach', '#b37800', d); d += 900; }
}

// ------------------------------------------------------------------ confetti
function confetti(col) {
  var cv = $('fx'), cx = cv.getContext('2d'), W = cv.width = cv.clientWidth, H = cv.height = cv.clientHeight, P = [], cols = [col, '#ffffff', '#ffd34a', '#e3243b', '#7cff3a'];
  for (var i = 0; i < 160; i++) P.push({ x: W / 2, y: H / 3, vx: (Math.random() - 0.5) * 12, vy: Math.random() * -10 - 2, s: 3 + Math.random() * 5, c: cols[i % cols.length], r: Math.random() * 6, life: 0 });
  var t0 = Date.now();
  (function f() { cx.clearRect(0, 0, W, H); P.forEach(function (p) { p.vy += 0.25; p.x += p.vx; p.y += p.vy; p.r += 0.2; cx.save(); cx.translate(p.x, p.y); cx.rotate(p.r); cx.fillStyle = p.c; cx.fillRect(-p.s / 2, -p.s / 4, p.s, p.s / 2); cx.restore(); }); if (Date.now() - t0 < 3500) requestAnimationFrame(f); else cx.clearRect(0, 0, W, H); })();
}

// ------------------------------------------------------------------ events
var LP = { t: null, fired: false };
function findAttr(el, names) { while (el && el !== document.body && el.getAttribute) { for (var i = 0; i < names.length; i++) if (el.getAttribute(names[i]) !== null) return el; el = el.parentNode; } return null; }
document.addEventListener('mousedown', function (e) {
  LP.fired = false; clearTimeout(LP.t);
  if (cur || $('lock').className.indexOf('off') < 0) return;
  if (!findAttr(e.target, ['data-app', 'data-fold'])) return;
  LP.t = setTimeout(function () { if (!EDIT) { EDIT = true; LP.fired = true; SND.tick(); renderHome(); } }, 600);
});
document.addEventListener('mouseup', function () { clearTimeout(LP.t); });
document.addEventListener('click', function (e) {
  ac();
  if ($('lock').className.indexOf('off') < 0) { unlock(D.page); return; }
  if (LP.fired) { LP.fired = false; return; }
  if (GAME && GAME.flap && e.target && e.target.id === 'gcv') { GAME.flap(); return; }
  if (GAME && GAME.tap && e.target && e.target.id === 'scv') { GAME.tap(); return; }
  var ov = findAttr(e.target, ['id']);
  var el = findAttr(e.target, ['data-rm', 'data-get', 'data-open', 'data-ui', 'data-fold', 'data-app', 'data-tab', 'data-case', 'data-set', 'data-wp', 'data-acc', 'data-mus', 'data-calc', 'data-dir', 'data-hole', 'data-gs']);
  if (!el) {
    var t = e.target;
    if (t && t.className && typeof t.className === 'string' && t.className.indexOf('ov ') === 0) { closeOv(t.id); if (t.id === 'cc') SND.close(); }
    else if (EDIT && !cur && !findAttr(e.target, ['data-app'])) { EDIT = false; renderHome(); }
    return;
  }
  var v;
  if ((v = el.getAttribute('data-rm')) !== null) { if (CORE.indexOf(v) >= 0) return; INST = INST.filter(function (x) { return x !== v; }); saveInst(); SND.close(); if (cur === 'store') $('appBody').innerHTML = R.store(); renderHome(); if ($('fold') && $('fold').className.indexOf('show') >= 0) openFolder(); return; }
  if (el.getAttribute('data-get') !== null || el.getAttribute('data-open') !== null) { storeAct(el); return; }
  if ((v = el.getAttribute('data-ui'))) {
    if (v === 'cc') openCC(); else if (v === 'ccx') { closeOv('cc'); SND.close(); }
    else if (v === 'done') { EDIT = false; SND.click(); renderHome(); }
    else if (v === 'edit') { closeOv('cc'); EDIT = true; SND.tick(); if (cur) goHome(); else renderHome(); }
    else if (v === 'mstop') { musStop(); refreshCC(); if (cur === 'music') $('appBody').innerHTML = R.music(), musViz(); }
    return;
  }
  if (el.getAttribute('data-fold') !== null) { if (EDIT) return; openFolder(); return; }
  if ((v = el.getAttribute('data-app'))) { if (EDIT) { SND.tick(); return; } openApp(v); return; }
  if ((v = el.getAttribute('data-dir')) !== null) { if (GAME && GAME.dir) GAME.dir(num(v)); return; }
  if ((v = el.getAttribute('data-hole')) !== null) { if (GAME && GAME.hit) GAME.hit(num(v)); return; }
  if (el.getAttribute('data-gs') !== null) { if (GAME && GAME.start) GAME.start(); SND.click(); return; }
  if ((v = el.getAttribute('data-calc')) !== null) { SND.tick(); calcKey(v); return; }
  if ((v = el.getAttribute('data-mus')) !== null) { v = num(v); if (MUS.i === v) musStop(); else musPlay(v); $('appBody').innerHTML = R.music(); musViz(); return; }
  SND.click();
  if ((v = el.getAttribute('data-tab'))) { invTab = v; $('appBody').innerHTML = R[cur](); return; }
  if ((v = el.getAttribute('data-case')) !== null) { caseSel = num(v); var keep = D.cr; D.cr = null; $('appBody').innerHTML = R['case'](); D.cr = keep; return; }
  if ((v = el.getAttribute('data-wp')) !== null) { WP = num(v) % 8; store('wp', WP); setWall(); if (cur === 'set') $('appBody').innerHTML = R.set(); refreshCC(); return; }
  if ((v = el.getAttribute('data-acc')) !== null) { store('acc', v); applyAccent(); refreshCC(); if (cur === 'set') $('appBody').innerHTML = R.set(); return; }
  if ((v = el.getAttribute('data-set'))) {
    if (v === 'dark' || v === 'light') store('theme', v);
    else if (v === 'snd') { soundOn = !soundOn; store('snd', soundOn ? '1' : '0'); }
    else if (v === 'ntf') { notifOn = !notifOn; store('ntf', notifOn ? '1' : '0'); }
    else if (v === 'tr' || v === 'en') { D.lang = v; store('lang', v); }
    rerender(); return;
  }
});
document.addEventListener('input', function (e) { if (e.target && e.target.id === 'notesTa') store('notes', e.target.value); });
function storeAct(b) {
  var a;
  if ((a = b.getAttribute('data-open'))) { openApp(a); return; }
  if ((a = b.getAttribute('data-get'))) {
    b.className = 'gbtn busy'; b.innerHTML = '<i class="ring"></i>'; tone(880, 0.08, 'sine', 0.06);
    setTimeout(function () { if (INST.indexOf(a) < 0) INST.push(a); saveInst(); SND.notif(); banner(L('installed'), L(a), a, ICOL[a] ? ICOL[a].split(',')[1] : '#2f80ed'); if (cur === 'store') $('appBody').innerHTML = R.store(); renderHome(); }, 1400);
  }
}
document.addEventListener('contextmenu', function (e) { e.preventDefault(); if ($('lock').className.indexOf('off') < 0) return; var o = $('cc'), f = $('fold'); if (o && o.className.indexOf('show') >= 0) { closeOv('cc'); return; } if (f && f.className.indexOf('show') >= 0) { closeOv('fold'); return; } if (EDIT) { EDIT = false; renderHome(); return; } if (cur) goHome(); else banner('VEXMIRA', L('exitHint'), 'about', '#555'); });
document.addEventListener('keydown', function (e) {
  if (e.target && e.target.id === 'notesTa') { if (e.keyCode === 27) goHome(); return; }
  if (GAME && GAME.flap && (e.keyCode === 32 || e.keyCode === 38)) { e.preventDefault(); GAME.flap(); return; }
  if (GAME && GAME.key && GAME.key(e.keyCode)) { e.preventDefault(); return; }
  if (cur === 'calc') { var m = { 13: '=', 8: 'C', 187: '=', 107: '+', 109: '-', 106: '*', 111: '/', 190: '.' }, k = e.keyCode >= 48 && e.keyCode <= 57 ? String(e.keyCode - 48) : e.keyCode >= 96 && e.keyCode <= 105 ? String(e.keyCode - 96) : m[e.keyCode]; if (k) { calcKey(k); return; } }
  if (e.keyCode === 27) goHome();
});
$('backBtn').addEventListener('click', function (e) { e.stopPropagation(); goHome(); });
$('homebar').addEventListener('click', function (e) { e.stopPropagation(); if ($('lock').className.indexOf('off') < 0) unlock(D.page); else goHome(); });
$('status').addEventListener('click', function (e) { if ($('lock').className.indexOf('off') < 0) return; e.stopPropagation(); openCC(); });

// ------------------------------------------------------------------ boot
applyTheme(); applyAccent(); applyBright(); setWall(); $('screen').className = 'screen locked'; $('lockLogo').innerHTML = LOGO(); $('lockHint').textContent = L('unlock');
$('lockNote').textContent = D.claimed ? '' : L('dailyReady');
if (DEMO) $('demo').style.display = 'block';
renderHome(); clock(); setInterval(clock, 10000);
$('home').className = 'home hide';
if (D.page && D.page !== 'home') { $('lock').className = 'lock off'; $('screen').className = 'screen'; $('home').className = 'home'; openApp(D.page, true); }
else { setTimeout(function () { SND.drone(); }, 400); }
})();
