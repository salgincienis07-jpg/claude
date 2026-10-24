/* VEXMIRA iPad 6.0 - opened by the game in the MOTD window. Data comes in the URL hash (see CONTRACT.md),
   item / achievement names from items.js (written by the server). Tablet & Mod: smurfsexy */
(function () {
'use strict';
// ---------------------------------------------------------------- CS 1.6 MOTD (Chromium 18) compatibility
(function () {
  var w = window;
  if (!w.requestAnimationFrame) w.requestAnimationFrame = w.webkitRequestAnimationFrame || function (f) { return setTimeout(function () { f(Date.now()); }, 16); };
  if (!w.AudioContext && w.webkitAudioContext) w.AudioContext = w.webkitAudioContext;
  var AC = w.AudioContext;
  if (AC) {
    var P = AC.prototype;
    if (!P.createGain && P.createGainNode) P.createGain = P.createGainNode;
    ['createOscillator', 'createBufferSource'].forEach(function (fn) {
      var orig = P[fn]; if (!orig) return;
      P[fn] = function () { var n = orig.call(this); if (!n.start && n.noteOn) n.start = function (t) { this.noteOn(t || 0); }; if (!n.stop && n.noteOff) n.stop = function (t) { this.noteOff(t || 0); }; return n; };
    });
  }
  var C2 = w.CanvasRenderingContext2D;
  if (C2 && !C2.prototype.ellipse) C2.prototype.ellipse = function (x, y, rx, ry, r, a0, a1, ccw) { this.save(); this.translate(x, y); this.rotate(r); this.scale(rx, ry); this.arc(0, 0, 1, a0, a1, ccw); this.restore(); };
})();
var $ = function (id) { return document.getElementById(id); };
function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }
function num(v, d) { var n = parseInt(v, 10); return isNaN(n) ? (d || 0) : n; }
function fmt(n) { n = num(n); return n >= 1000000 ? (n / 1000000).toFixed(1) + 'M' : n >= 10000 ? (n / 1000).toFixed(1) + 'K' : String(n); }
var MEM = {};
function store(k,v){if(v!==undefined){MEM[k]=String(v);try{localStorage.setItem('vx624_'+k,v);}catch(e){}return MEM[k];}if(Object.prototype.hasOwnProperty.call(MEM,k))return MEM[k];try{return MEM[k]=localStorage.getItem('vx624_'+k);}catch(e){return null;}}

// ------------------------------------------------------------------ data
function parseHash() {
  var h = (location.hash || '').replace(/^#/, ''), o = {};
  if (!h) return null;
  h.split('&').forEach(function (p) { var i = p.indexOf('='); if (i > 0) o[p.slice(0, i)] = p.slice(i + 1); });
  return o;
}
function dec(s) { try { return decodeURIComponent(s || ''); } catch (e) { return s || ''; } }
var RAW = parseHash(), DEMO = !RAW || !RAW.n;
if(DEMO)RAW={l:'tr',n:'',pg:'home'};
var D = {
  lang: (dec(RAW.l) || store('lang') || 'tr') === 'en' ? 'en' : 'tr', page: dec(RAW.pg) || 'home', name: dec(RAW.n) || 'Player', sid: dec(RAW.s),
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
  cat_games: 'Oyunlar', cat_tools: 'Araclar', cat_server: 'Sunucu', cat_social: 'Sosyal',
  msg: 'Mesajlar', friends: 'Arkadaslar', notif: 'Bildirimler', adm: 'Yonetim', d_msg: 'Oyuncularla mesajlas', d_friends: 'Arkadas ekle, engelle', d_notif: 'Tum bildirimlerin', d_adm: 'Yonetim paneli', top3: 'En iyiler', np: 'Simdi caliyor', tracks: ['Karanlik Koridor', 'Kalp Atisi', 'Kanli Yagmur', 'Sisli Gece'], stop: 'Durdur',
  modes: 'Oyun Modlari', classes: 'Zombi Siniflari', tips: 'Ipuclari', notesPh: 'Buraya yaz... (otomatik kaydedilir)', timeLeft: 'Sure', start: 'Basla', again: 'Tekrar', hint2048: 'Ok tuslari ile kaydir', hintSnake: 'Ok tuslari / WASD ile yonlendir',
  widgetHint: 'Duzenlemek icin bir simgeye basili tut', xp: 'XP'
}, {
  guide: 'Guide', cmds: 'Commands', music: 'Music', notes: 'Notes', calc: 'Calculator', snake: 'Vex Snake', g2048: 'Vex 2048', whack: 'Zombie Hunt', games: 'Games',
  d_guide: 'Modes, zombie classes, tips', d_cmds: 'Every chat command in one place', d_music: 'Horror ambience tracks', d_notes: 'Your own notes', d_calc: 'Quick maths', d_snake: 'Classic snake, dark theme', d_g2048: 'Merge tiles, reach 2048', d_whack: 'Hit as many zombies as you can in 30 s',
  cc: 'Control Center', accent: 'Accent color', bright: 'Brightness', edit: 'Edit home screen', done: 'Done', custom: 'Customize', wpNames: ['Crimson Fog', 'Abyss', 'Toxic', 'Hexgrid', 'Ember', 'Violet Dawn', 'Midnight', 'Vexmira'],
  cat_games: 'Games', cat_tools: 'Tools', cat_server: 'Server', cat_social: 'Social',
  msg: 'Messages', friends: 'Friends', notif: 'Notifications', adm: 'Admin', d_msg: 'Message other players', d_friends: 'Add or block players', d_notif: 'All your notifications', d_adm: 'Admin panel', top3: 'Top players', np: 'Now playing', tracks: ['Dark Corridor', 'Heartbeat', 'Blood Rain', 'Foggy Night'], stop: 'Stop',
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
  msg: '<path d="M4 5.5h16v10H9l-4 4v-4H4z"/><path d="M8 9h8M8 12h5"/>',
  friends: '<circle cx="8.5" cy="8" r="3.2"/><path d="M2.5 20c.7-3.3 3.1-5 6-5s5.3 1.7 6 5"/><path d="M16 4.5a3.2 3.2 0 0 1 0 6.3M17.5 14.5c2 .7 3.3 2.3 3.8 5"/>',
  notif: '<path d="M6 9a6 6 0 0 1 12 0c0 6.5 2.5 8 2.5 8h-17S6 15.5 6 9M10 20.5h4"/><circle cx="18" cy="6" r="3" fill="currentColor" stroke="none"/>',
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
var ICOL = {market:'#29b987,#08785d',
  prof: '#ff5468,#9a0f26', top: '#ffb547,#c2540a', time: '#5aaeff,#1747b0', ach: '#ffd862,#c98400', achtop: '#ff7d5c,#a8261c',
  inv: '#ad7bff,#4c1fae', 'case': '#ff4f7b,#8e0b3f', daily: '#43e0a0,#0b7a50', zup: '#a2e65c,#2c7710', trade: '#45d9d2,#0b6f7c',
  set: '#a3acb7,#3b424c', adm: '#ff5a5a,#7c0a12', about: '#6c7280,#20242c', store: '#5aaeff,#5b36f2', game: '#ff9147,#c4310c',
  guide: '#7c8bff,#2c2fa3', cmds: '#4a505c,#111317', music: '#ff6492,#b3124c', notes: '#ffd34d,#d48f00', calc: '#ff9f2e,#4a2a0a',
  snake: '#56e07a,#147a30', g2048: '#ffbf5a,#cf6a0c', whack: '#c75cff,#5c0f9c', games: '#3b3346,#15111c',
  msg: '#2fb8ff,#0b4a8f', friends: '#5ad1a0,#0b6b4a', notif: '#ff6a8a,#8a0f30'
};
function svg(k) { return '<svg viewBox="0 0 24 24">' + (IC[k] || IC.about) + '</svg>'; }
function lg(a, c0, c1) { return 'background:' + c1 + ';background:-webkit-linear-gradient(' + (90 - a) + 'deg,' + c0 + ',' + c1 + ')'; }
function rgba(hex, a) { var h = hex.replace('#', ''); if (h.length === 3) h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2); return 'rgba(' + parseInt(h.substr(0, 2), 16) + ',' + parseInt(h.substr(2, 2), 16) + ',' + parseInt(h.substr(4, 2), 16) + ',' + a + ')'; }
function grad(k) { var c = (ICOL[k] || ICOL.about).split(','); return lg(160, c[0], c[1]); }
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
function tone(f,d,type,vol,when,slide){
 if(!soundOn)return;try{var a=ac();if(!a)return;var t=a.currentTime+(when||0),o=a.createOscillator(),g=a.createGain?a.createGain():a.createGainNode();
 var types={sine:0,square:1,sawtooth:2,triangle:3};o.type=typeof o.type==='number'?types[type||'sine']:(type||'sine');
 o.frequency.setValueAtTime(f,t);if(slide)o.frequency.exponentialRampToValueAtTime(slide,t+d);
 g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(vol||.05,t+.01);g.gain.exponentialRampToValueAtTime(.0001,t+d);
 o.connect(g);g.connect(a.destination);(o.start||o.noteOn).call(o,t);(o.stop||o.noteOff).call(o,t+d+.05);
 }catch(e){soundOn=false;}
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
var THEME = {
  dark: { bg: '#07070a', card: 'rgba(22,20,26,.86)', card2: 'rgba(38,34,44,.9)', line: 'rgba(255,255,255,.09)', txt: '#ece7ee', sub: '#9a90a0', acc: '#007aff', acc2: '#7cff3a', gold: '#ffc23a', glass: 'rgba(18,16,22,.72)', shadow: '0 8px 24px rgba(0,0,0,.5)' },
  light: { bg: '#f2eef2', card: 'rgba(255,255,255,.9)', card2: 'rgba(244,240,246,.96)', line: 'rgba(0,0,0,.09)', txt: '#1d1820', sub: '#6c6270', acc: '#007aff', acc2: '#2d9c12', gold: '#b37800', glass: 'rgba(255,255,255,.78)', shadow: '0 8px 20px rgba(40,0,10,.16)' }
};
var PALETTE = {};
function colors(root){var a=(root||document).querySelectorAll('[style*="var(--"]');for(var i=0;i<a.length;i++)a[i].setAttribute("style",a[i].getAttribute("style").replace(/var\(--([a-z0-9]+)\)/g,function(m,k){return PALETTE[k]||m;}));}
T.tr.market='Pazar';T.en.market='Market';T.tr.d_market='Oyuncu pazarı';T.en.d_market='Player market';
var ACC_NOW = '#e3243b';
function applyTheme() {
  var light = store('theme') === 'light', t = THEME[light ? 'light' : 'dark'], a = store('acc'), vals = {};
  for (var k in t) vals[k] = t[k];
  if (a && /^#[0-9a-fA-F]{6}$/.test(a)) vals.acc = a;
  PALETTE=vals; ACC_NOW = vals.acc;
  document.documentElement.setAttribute('data-theme', light ? 'light' : 'dark'); document.documentElement.lang = D.lang;
  var css = ((window.VXCSS || '') + (window.VXFIXCSS || '')).replace(/var\(--([a-z0-9]+)\)/g, function (m, k) { return vals[k] != null ? vals[k] : m; });
  var st = document.getElementById('vxcss');
  if (!st) { st = document.createElement('style'); st.id = 'vxcss'; document.getElementsByTagName('head')[0].appendChild(st); }
  st.textContent = css;
}
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
    b.innerHTML = '<div><div class="bi" style="background:' + (color || ACC_NOW) + '">' + svg(icon || 'bell') + '</div></div><div class="bt"><b>' + esc(title) + '</b><span>' + esc(text) + '</span></div>';
    var bs=$('banners');while(bs.children.length>=2)bs.removeChild(bs.firstChild);bs.appendChild(b);SND.notif();
    setTimeout(function () { b.className = 'bn out'; setTimeout(function () { if (b.parentNode) b.parentNode.removeChild(b); }, 450); }, 4200);
  }, delay || 0);
}
function hms(s) { s = Math.max(0, s | 0); return pad(Math.floor(s / 3600)) + ':' + pad(Math.floor(s % 3600 / 60)); }

// ------------------------------------------------------------------ apps
var CATALOG = ['prof', 'top', 'time', 'ach', 'achtop', 'inv', 'case', 'daily', 'zup', 'market', 'trade', 'msg', 'friends', 'notif', 'guide', 'cmds', 'music', 'notes', 'calc', 'game', 'snake', 'g2048', 'whack', 'set', 'store', 'about'];
var CATS = [['cat_server', ['prof', 'top', 'time', 'ach', 'achtop', 'inv', 'case', 'daily', 'zup', 'trade']], ['cat_social', ['msg', 'friends', 'notif']], ['cat_games', ['game', 'snake', 'g2048', 'whack']], ['cat_tools', ['guide', 'cmds', 'music', 'notes', 'calc']]];
var GAMES = ['game', 'snake', 'g2048', 'whack'];
var CORE = ['store', 'set', 'about', 'adm','market'], DEF = ['prof', 'top', 'ach', 'inv', 'case', 'daily', 'zup', 'market', 'trade', 'msg', 'friends', 'notif', 'guide', 'music', 'game', 'snake'];
var INST = (function () { var v = store('apps6'); try { v = v ? JSON.parse(v) : null; } catch (e) { v = null; } return v || DEF.slice(); })();
function installed(a) { return CORE.indexOf(a) >= 0 || INST.indexOf(a) >= 0 || a === D.page; }
function saveInst() { store('apps6', JSON.stringify(INST)); }
var APPS = CATALOG;
var DOCK = ['prof', 'case', 'store', 'set'];
function cmd(c) { return '<div class="cmd">' + esc(L('type')) + ': <b>' + esc(c) + '</b></div>'; }
function card(t, body) { return '<div class="card">' + (t ? '<h3>' + esc(t) + '</h3>' : '') + body + '</div>'; }
function stat(v, l) { return '<div class="stat"><div><b>' + esc(v) + '</b><span>' + esc(l) + '</span></div></div>'; }
function avaColor(lv) { var c = lv >= 75 ? '#ffb000,#a33a00' : lv >= 50 ? '#b04aff,#3d0a6e' : lv >= 25 ? '#2f80ed,#0b2c66' : '#c8102e,#4a0510'; c = c.split(','); return lg(145, c[0], c[1]); }
function initials(n) { var p = n.replace(/[^A-Za-z0-9 ]/g, '').trim().split(/\s+/); return ((p[0] || '?').charAt(0) + (p[1] ? p[1].charAt(0) : '')).toUpperCase(); }
function medal(i) { return '<span class="medal ' + (i < 3 ? 'm' + (i + 1) : '') + '">' + (i + 1) + '</span>'; }
function board(rows, cols, valFn) {
  if (!rows.length) return '<p class="muted">' + esc(L('noData')) + '</p>';
  var h = '<table class="lb"><tr><th>#</th><th>' + esc(L('name')) + '</th>' + cols.map(function (c) { return '<th>' + esc(c) + '</th>'; }).join('') + '</tr>';
  rows.forEach(function (r, i) { h += '<tr class="' + (r.n === D.name ? 'me' : '') + '"><td>' + medal(i) + '</td><td class="n">' + esc(r.n) + '</td>' + valFn(r).map(function (v) { return '<td>' + esc(v) + '</td>'; }).join('') + '</tr>'; });
  return h + '</table>';
}
function ichip(ic, label, val, col) { return '<div class="ichip"><span class="ii" style="background:' + rgba(col, 0.16) + ';color:' + col + '">' + svg(ic) + '</span><span class="iv"><small>' + esc(label) + '</small><b>' + esc(val) + '</b></span></div>'; }
var R = {};
R.prof = function () {
  var pct = Math.max(0, Math.min(100, D.xn > 0 ? Math.round(D.xp * 100 / D.xn) : 100));
  var steam = D.sid ? '<a class="lnk" href="https://steamcommunity.com/profiles/' + esc(D.sid) + '" target="_blank">' + esc(L('steam')) + ' &rsaquo;</a>' : '';
  return card('', '<div class="prof"><div><div class="ava" style="' + avaColor(D.lv) + '">' + esc(initials(D.name)) + '</div></div><div class="pi"><h2>' + esc(D.name) + (D.vip ? '<span class="vip">' + (D.vip === 2 ? 'ELITE' : 'VIP') + '</span>' : '') +
    '</h2><div class="sub">' + esc(L('level')) + ' ' + D.lv + (D.rank ? ' &middot; #' + D.rank + ' ' + esc(L('rank')) : '') + (D.vip && D.vd ? ' &middot; ' + esc(F('vipDays', D.vd)) : '') + '</div>' +
    '<div class="bar"><i style="width:' + pct + '%"></i></div><div class="sub">XP ' + fmt(D.xp) + ' / ' + fmt(D.xn) + ' &nbsp; ' + steam + '</div></div></div>') +
    card('', '<div class="stats">' + stat(fmt(D.k), L('kills')) + stat(fmt(D.inf), L('infs')) + stat(fmt(D.hs), L('hs')) + stat(fmt(D.w), L('wins')) + stat(fmt(D.b), L('boss')) + stat(fmt(D.d), L('deaths')) +
      stat(Math.floor(D.pt / 60) + ' ' + L('hours'), L('play')) + stat(achCount() + '/' + achList().length, L('ach')) + '</div>') +
    card('', '<div class="stats">' + stat(fmt(D.ap), 'AP') + stat(fmt(D.vc), 'VexCoin') + stat(D.streak, L('streak')) + stat(D.on + '/' + D.mx, L('online')) + '</div>' + cmd('/istatistik'));
};
var CROWN = '<svg viewBox="0 0 30 22"><path d="M2 19 L4 6 L10 12 L15 3 L20 12 L26 6 L28 19 Z" fill="#ffd25a" stroke="#a86a00" stroke-width="1.4" stroke-linejoin="round"/><circle cx="15" cy="3" r="2" fill="#fff3c4"/><rect x="3" y="18" width="24" height="3" rx="1" fill="#e0a400"/></svg>';
var TOPM = 'top';
function topRows(mode) {
  if (mode === 'time') return D.tt.map(function (r) { var m = num(r.v); return { n: r.n, v: m, main: Math.floor(m / 60) + ' ' + L('hours'), sub: (m % 60) + ' ' + L('min'), lv: '' }; });
  if (mode === 'achtop') return D.at.map(function (r) { return { n: r.n, v: num(r.v), main: r.v + '/' + achList().length, sub: L('ach'), lv: '' }; });
  return D.top.map(function (r) { return { n: r.n, v: num(r.k) + num(r.lv) * 1000, main: fmt(r.k), sub: L('kills'), lv: r.lv }; });
}
function leader(mode) {
  var rows = topRows(mode), h = '';
  var titles = { top: L('top'), time: L('time'), achtop: L('achtop') };
  h += '<div class="seasonbar"><div><h2>' + esc(titles[mode]) + '<small>' + esc(D.lang === 'tr' ? 'Sezon yarisi - ilk 3 her hafta duyurulur' : 'Season race - top 3 announced every week') + '</small></h2></div><div class="tabsw">' +
    ['top', 'time', 'achtop'].map(function (m) { return '<span class="tab' + (m === mode ? ' on' : '') + '" data-top="' + m + '">' + esc(m === 'top' ? 'Top 15' : m === 'time' ? (D.lang === 'tr' ? 'Sure' : 'Time') : L('ach')) + '</span>'; }).join('') + '</div></div>';
  if (!rows.length) return h + card('', '<p class="muted">' + esc(L('noData')) + '</p>');
  var pod = '<div class="podium">';
  [1, 0, 2].forEach(function (i) {
    var r = rows[i]; if (!r) return;
    pod += '<div class="pod p' + (i + 1) + '"><div class="pa" style="' + avaColor(i === 0 ? 80 : i === 1 ? 55 : 30) + '">' + (i === 0 ? '<span class="crown">' + CROWN + '</span>' : '') + esc(initials(r.n)) + '</div><b>' + esc(r.n) + (r.n === D.name ? ' &#9733;' : '') + '</b><small>' + esc(r.main) + (r.lv ? ' &middot; Lv ' + esc(r.lv) : '') + '</small><div class="ped">' + (i + 1) + '</div></div>';
  });
  pod += '</div>';
  var max = rows[0].v || 1, list = '<div class="race">';
  rows.forEach(function (r, i) {
    if (i < 3) return;
    var pct = Math.max(4, Math.round(r.v * 100 / max));
    list += '<div class="rw' + (r.n === D.name ? ' me' : '') + '"><div class="rk">' + (i + 1) + '</div><div class="ra"><div style="' + avaColor(i < 6 ? 40 : 10) + '">' + esc(initials(r.n)) + '</div></div><div class="rn"><b>' + esc(r.n) + (r.lv ? '<span class="lvchip">Lv ' + esc(r.lv) + '</span>' : '') + '</b><div class="rbar"><i style="width:' + pct + '%"></i></div></div><div class="rv"><strong>' + esc(r.main) + '</strong>' + esc(r.sub) + '</div></div>';
  });
  list += '</div>';
  return h + pod + list + cmd(mode === 'top' ? '/top15' : mode === 'time' ? '/toptime' : '/basarimtop');
}
R.top = function () { return leader(TOPM = 'top'); };
R.time = function () { return leader(TOPM = 'time'); };
R.achtop = function () { return leader(TOPM = 'achtop'); };
function achCount() { var n = 0; for (var i = 0; i < 31; i++) if (D.ach & (1 << i)) n++; return n; }
R.ach=function(){var a=achList(),claimed=D.claimedMask|0,h='<div class="achs">';a.forEach(function(x,i){var unlocked=(D.ach&(1<<i))!==0,paid=(claimed&(1<<i))!==0,reward=D.achReward;h+='<div class="ach'+(unlocked?' on':'')+'"><div class="ac"><div class="achline"><span class="achstar">'+(paid?'✓':unlocked?'★':'○')+'</span><div><b>'+esc(x.n)+'</b><small>'+esc(x.d)+'</small></div></div><div class="achfoot"><span>'+ (reward?fmt(reward[0])+' VC · '+fmt(reward[1])+' AP':'—')+'</span><button class="gbtn" '+(unlocked&&!paid&&D.claimedMask!==undefined?'data-achclaim="'+i+'"':'disabled')+'>'+esc(paid?tr('Alındı','Claimed'):unlocked?tr('Ödülü al','Claim reward'):tr('Kilitli','Locked'))+'</button></div></div></div>';});return card(tr('Başarımlar','Achievements')+' · '+achCount()+'/'+a.length,h+'</div>');};
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
    h += '<div class="it' + (own ? '' : ' no') + '"' + (own ? ' data-eq="' + invTab + '.' + i + '.' + (eq ? 1 : 0) + '"' : '') + '><div class="ic">' + (eq ? '<span class="eq">' + esc(L('equipped')) + '</span>' : '') + '<div class="ib" style="' + grad(invTab === 'k' ? 'case' : invTab === 'w' ? 'ach' : invTab === 'p' ? 'daily' : 'inv') + '">' + svg(invTab === 'k' ? 'blade' : invTab === 'p' ? 'prof' : 'inv') + '</div><b>' + esc(itemName(invTab + (i + 1))) + '</b><small class="t' + r + '">' + esc(L('rar')[r]) + (it.vc ? ' &middot; ' + it.vc + ' VC' : '') + '</small><div class="rb r' + r + '"></div></div></div>';
  }
  return card(L('inv'), h + '</div>' + cmd(D.lang === 'tr' ? '/envanter  /kozmetik  /bicak' : '/inventory  /cosmetic  /knife'));
};
var caseSel = 0;
var TIERS = [
  { c0: '#d28a48', c1: '#6a3510', band: '#8a8f99', glow: 'rgba(210,138,72,.55)', tag: 'BRONZE', tagc: '#b06a2e' },
  { c0: '#e9edf3', c1: '#6f7884', band: '#3e444c', glow: 'rgba(200,215,235,.5)', tag: 'SILVER', tagc: '#7d8794' },
  { c0: '#ffd968', c1: '#a86400', band: '#5a3a00', glow: 'rgba(255,200,60,.6)', tag: 'GOLD', tagc: '#c98a00' },
  { c0: '#ff3b5c', c1: '#2a0008', band: '#111', glow: 'rgba(255,40,70,.7)', tag: 'NIGHTMARE', tagc: '#b0102c' }];
function caseColors(c) { var t = TIERS[c] || TIERS[0]; return t.c0 + ',' + t.c1; }
function crate(i) {
  var t = TIERS[i] || TIERS[0], u = 'cr' + (++LGN);
  return '<svg viewBox="0 0 120 98"><defs><linearGradient id="' + u + 'a" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="' + t.c0 + '"/><stop offset="1" stop-color="' + t.c1 + '"/></linearGradient>' +
    '<linearGradient id="' + u + 'b" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity=".35"/><stop offset=".5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".35"/></linearGradient></defs>' +
    '<ellipse cx="60" cy="92" rx="46" ry="5" fill="#000" opacity=".45"/>' +
    '<path d="M14 40 L106 40 L100 88 L20 88 Z" fill="url(#' + u + 'a)" stroke="#000" stroke-opacity=".4"/>' +
    '<path d="M14 40 L106 40 L100 88 L20 88 Z" fill="url(#' + u + 'b)"/>' +
    '<path d="M10 26 Q60 12 110 26 L110 42 L10 42 Z" fill="url(#' + u + 'a)" stroke="#000" stroke-opacity=".4"/>' +
    '<path d="M10 26 Q60 12 110 26" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="2"/>' +
    '<rect x="26" y="26" width="9" height="62" fill="' + t.band + '" opacity=".85"/><rect x="85" y="26" width="9" height="62" fill="' + t.band + '" opacity=".85"/>' +
    '<rect x="10" y="40" width="100" height="5" fill="' + t.band + '" opacity=".9"/>' +
    '<rect x="48" y="44" width="24" height="24" rx="5" fill="#15121a" stroke="' + t.c0 + '" stroke-width="2"/>' +
    '<path d="M53 49 h4.5 L60 59 L62.5 49 H67 L62 64 H58 Z" fill="#fff"/>' +
    '<path d="M18 46 L30 46 M90 46 L102 46" stroke="#fff" stroke-opacity=".25" stroke-width="2"/></svg>';
}
var RAYS = '<svg viewBox="0 0 420 420">' + (function () { var p = ''; for (var i = 0; i < 18; i++) { var a = i * 20 * Math.PI / 180, b = (i * 20 + 8) * Math.PI / 180; p += '<path d="M210 210 L' + (210 + 210 * Math.cos(a)).toFixed(1) + ' ' + (210 + 210 * Math.sin(a)).toFixed(1) + ' L' + (210 + 210 * Math.cos(b)).toFixed(1) + ' ' + (210 + 210 * Math.sin(b)).toFixed(1) + ' Z" fill="#fff" opacity=".08"/>'; } return p; })() + '</svg>';
function caseData() {
  var c = (VX.cases && VX.cases.length) ? VX.cases : [{ tr: 'Bronz Kasa', en: 'Bronze Case', vc: 150, loot: [] }, { tr: 'Gumus Kasa', en: 'Silver Case', vc: 350, loot: [] }, { tr: 'Altin Kasa', en: 'Gold Case', vc: 700, loot: [] }, { tr: 'Kabus Kasasi', en: 'Nightmare Case', vc: 1200, loot: [] }];
  return c;
}
var RCOL = ['#9aa0a8', '#3c8cff', '#a646ff', '#ffbe28', '#ff2a2a'];
R['case'] = function () {
  var cs = caseData(), h = '<div class="cases">';
  cs.forEach(function (c, i) {
    var t = TIERS[i] || TIERS[0];
    h += '<div class="case' + (i === caseSel ? ' sel' : '') + '" data-case="' + i + '"><div class="ci"><span class="tier" style="background:' + t.tagc + '">' + t.tag + '</span><div class="cbx"><div class="glow" style="background:-webkit-radial-gradient(50% 50%,circle closest-side,' + t.glow + ',rgba(0,0,0,0))"></div>' + crate(i) + '</div><b>' + esc(c[D.lang] || c.en) + '</b><small>' + c.vc + ' VC</small></div></div>';
  });
  h += '</div>';
  var stage = '';
  if (D.cr) {
    stage = card(L('opening'), '<div id="cstage" class="casestage shake"><div class="rays">' + RAYS + '</div><div class="big">' + crate(D.cr.c) + '</div></div><div class="reelbox" id="rbox" style="display:none"><div class="needle"></div><div id="reel" class="reel"></div></div><div id="winBox"></div>');
  }
  var c = cs[caseSel], loot = (c.loot || []).slice().sort(function (a, b) { return b[1] - a[1]; }), lh = '<div class="loot">';
  loot.forEach(function (l) { lh += '<div><p style="border-left-color:' + RCOL[l[1]] + '"><span class="t' + l[1] + '">' + esc(itemName(l[0])) + '</span><b>' + Number(l[2]).toFixed(2) + '%</b></p></div>'; });
  lh += '</div>';
    var canBuy = D.vc >= (c.vc | 0);
  var open = '<div class="caseact"><div class="cabal">' + fmt(D.vc) + ' VC</div><span class="gbtn get big' + (canBuy ? '' : ' dis') + '" data-openc="' + caseSel + '">' + esc(L('open')) + ' - ' + (c.vc | 0) + ' VC</span></div>';
  return stage + card(L('case'), h + open) + card(L('chances') + ' - ' + (c[D.lang] || c.en), (loot.length ? lh : '<p class="muted">' + esc(L('noData')) + '</p>') + '<p class="muted" style="margin-top:8px">' + esc(L('vipDrop')) + '</p>');
};
function runReel() {
  if (!D.cr || !$('reel')) return;
  var st = $('cstage');
  tone(90, 1.1, 'sawtooth', 0.04, 0, 140);
  setTimeout(function () { if (!$('cstage')) return; st.className = 'casestage open'; tone(880, 0.25, 'sine', 0.08, 0, 1760); }, 1100);
  setTimeout(function () { if (!$('cstage')) return; st.style.display = 'none'; $('rbox').style.display = 'block'; spin(); }, 1700);
  function spin() {
    var cs = caseData(), c = cs[D.cr.c] || cs[0], pool = (c.loot && c.loot.length) ? c.loot : [[D.cr.code, D.cr.r, 1]], items = [], WIN = 38;
    for (var i = 0; i < 46; i++) { var p = pool[Math.floor(Math.random() * pool.length)]; items.push(i === WIN ? [D.cr.code, D.cr.r] : [p[0], p[1]]); }
    var reel = $('reel'); reel.innerHTML = items.map(function (x) { return '<div class="it"><div class="ic"><div class="ib" style="' + lg(160, RCOL[x[1]], '#15121a') + '">' + svg(x[0].charAt(0) === 'k' ? 'blade' : 'gift') + '</div><b>' + esc(itemName(x[0])) + '</b><small class="t' + x[1] + '">' + esc(L('rar')[x[1]]) + '</small><div class="rb r' + x[1] + '"></div></div></div>'; }).join('');
    var box = reel.parentNode, W = 128, target = WIN * W + 60 - box.clientWidth / 2 + Math.floor(Math.random() * 60) - 30, start = null, dur = 5200, last = -1;
    function ease(t) { return 1 - Math.pow(1 - t, 4); }
    function step(ts) {
      if (!start) start = ts; var t = Math.min(1, (ts - start) / dur), x = target * ease(t);
      reel.style.webkitTransform = reel.style.transform = 'translateX(' + (-x) + 'px)'; var idx = Math.floor((x + box.clientWidth / 2) / W); if (idx !== last) { last = idx; SND.tick(); }
      if (t < 1) setTimeout(step,33); else done();
    }
    requestAnimationFrame(step);
  }
  function done() {
    var r = D.cr.r, col = RCOL[r];
    $('winBox').innerHTML = '<div class="win" style="background:' + rgba(col, 0.18) + ';border:1px solid ' + col + '"><div class="rr t' + r + '">' + esc(L('rar')[r]) + '</div><h2>' + esc(L('got')) + ': ' + esc(itemName(D.cr.code)) + '</h2></div>';
    SND.win(r); if (r >= 2) confetti(col);
    banner(L('got'), itemName(D.cr.code), 'gift', col);
  }
}
R.daily = function () {
  var h = '<div class="days">', today = D.dailyNext || Math.min(7,D.claimed ? Math.max(1,D.streak) : D.streak+1);
  for (var i = 1; i <= 7; i++) {
    var reward=D.rewards&&D.rewards[i-1],ap=reward?reward[0]:null,vc=reward?reward[1]:null,cls = i < today || (i === today && D.claimed) ? 'done' : i === today ? 'now' : '';
    h += '<div class="day ' + cls + '"><div><b>' + esc(L('day')) + ' ' + i + '</b><strong>' + (ap===null?'—':fmt(ap)) + ' AP</strong><small>+' + (vc===null?'—':fmt(vc)) + ' VC</small></div></div>';
  }
  h += '</div>';
    var act2 = D.claimed ? '<p class="muted" style="margin-top:12px">' + esc(L('claimed')+' - ')+ '<span id="dailyCountdown">'+esc(hms(D.next))+'</span>' + '</p>' : '<div class="caseact"><span class="gbtn get big" data-daily="1">' + esc(L('claim')) + '</span></div>';
  return card(L('daily') + ' - ' + L('streak') + ': ' + D.streak, h + act2);
};
R.zup=function(){if(!D.zup)return card(L('zup'),'<p>'+tr('Canlı gelişim verisi bekleniyor. Bağlantı durumunu kontrol et.','Waiting for live upgrade data. Check connection status.')+'</p>');var rows=D.zup||[],names=ZCLS[D.lang]||ZCLS.tr,h='';for(var i=0;i<24;i++){var z=rows[i]||[D.zlv[i]||0,0,0,0,0,0,0],free=Math.max(0,z[0]-z[2]-z[3]-z[4]);h+=card(esc(names[i]||('Class '+(i+1))),'<p>'+tr('Seviye','Level')+' '+z[0]+' · '+tr('Gelişim','Progress')+' '+z[1]+'/'+(z[5]||'MAX')+' · <b>'+free+' '+tr('boş puan','free points')+'</b></p><div class="perkrow">'+[tr('Bekleme','Cooldown'),tr('Menzil','Range'),tr('Hasar','Damage')].map(function(n,k){return '<button class="gbtn" '+(free?'data-zperk="'+i+'.'+k+'"':'disabled')+'>'+esc(n)+' '+z[k+2]+' +</button>';}).join('')+'</div>');}return h;};
R.trade = function () { return card(L('trade'), '<p>' + esc(L('tradeHow')) + '</p>' + cmd(D.lang === 'tr' ? '/takas' : '/trade')) + R.inv(); };
R.set = function () {
  var dark = store('theme') !== 'light', h = '';
  h += '<div class="set"><span>' + esc(L('theme')) + '</span><div class="seg"><span data-set="dark" class="' + (dark ? 'on' : '') + '">' + esc(L('dark')) + '</span><span data-set="light" class="' + (dark ? '' : 'on') + '">' + esc(L('light')) + '</span></div></div>';
  h += '<div class="set"><span>' + esc(L('sound')) + '</span><div class="sw' + (soundOn ? ' on' : '') + '" data-set="snd"></div></div>';
  h += '<div class="set"><span>' + esc(L('notif')) + '</span><div class="sw' + (notifOn ? ' on' : '') + '" data-set="ntf"></div></div>';
  h += '<div class="set"><span>' + esc(L('lang')) + '</span><div class="seg"><span data-set="tr" class="' + (D.lang === 'tr' ? 'on' : '') + '">Turkce</span><span data-set="en" class="' + (D.lang === 'en' ? 'on' : '') + '">English</span></div></div>';
  var w = '<div class="wps">'; L('wpNames').forEach(function (n, i) { w += '<div class="wpt' + (i === WP ? ' on' : '') + '" data-wp="' + i + '"><div class="w wp' + i + '">' + (i === 7 ? emblem() : '') + '<small>' + esc(n) + '</small></div></div>'; }); w += '</div>';
  var acc = store('acc') || ACCS[0]; w += '<div class="ccl" style="margin-top:12px">' + esc(L('accent')) + '</div><div class="ccacc">' + ACCS.map(function (c) { return '<span data-acc="' + c + '" class="' + (c === acc ? 'on' : '') + '" style="background:' + c + '"></span>'; }).join('') + '</div>';
  return card(L('set'), h) + card(L('wall'), w) + '<div class="cce" data-app="about" style="margin:0 0 12px">' + svg('about') + esc(L('about')) + '</div>' + card('', '<p class="muted">' + (D.lang === 'tr' ? 'Oyun ici ayarlar' : 'In-game settings') + '</p>' + cmd(D.lang === 'tr' ? '/ayarlar  /dil  /stil' : '/settings  /lang  /style'));
};
R.adm = function () {
  if (D.role < 1) return card('', '<p>' + esc(L('adminOnly')) + '</p>');
  var h = card('', '<div class="stats">' + stat(Math.floor(D.up / 60) + ' ' + L('hours') + ' ' + (D.up % 60) + ' ' + L('min'), L('uptime')) + stat(D.svp + '/' + D.mx, L('players')) + stat(D.map, L('map')) + stat(D.round, L('round')) + '</div>');
  var a = [['amx_menu', D.lang === 'tr' ? 'oyuncu islemleri' : 'player actions'], ['/yonetim', D.lang === 'tr' ? 'Vexmira yonetim menusu (modlar, boss, event)' : 'Vexmira admin menu (modes, boss, events)'], ['amx_kick <isim>', 'kick'], ['amx_ban <isim> <dk>', 'ban'], ['amx_slay <isim>', 'slay'], ['amx_map <harita>', D.lang === 'tr' ? 'harita degistir' : 'change map'], ['vex_plan', D.lang === 'tr' ? 'bu haritanin round plani' : "this map's round plan"], ['vex_fastdl_files', 'FastDL']];
  h += card(L('cmds'), '<div class="cmds">' + a.map(function (x) { return '<div><p><b>' + esc(x[0]) + '</b>' + esc(x[1]) + '</p></div>'; }).join('') + '</div>');
  if (D.role >= 2) {
    var f = [['vex_reset_top', D.lang === 'tr' ? 'Top15 sifirla' : 'reset Top15'], ['vex_reset_time', D.lang === 'tr' ? 'sure siralamasini sifirla' : 'reset playtime top'], ['vex_reset_ach', D.lang === 'tr' ? 'basarim siralamasini sifirla' : 'reset achievement top'],
      ['vex_give_vc <isim> <miktar>', 'VexCoin'], ['vex_give_ap <isim> <miktar>', 'AP'], ['vex_give_ach <isim> <0-29>', L('ach')], ['vex_give_case <isim> <0-3>', L('case')], ['vex_vip_add <isim> <gun> <1|2>', 'VIP / ELITE'], ['vex_boss_build', D.lang === 'tr' ? 'dev boss dosyalari' : 'giant boss files']];
    h += card(L('founder'), '<div class="warn">' + (D.lang === 'tr' ? 'Bu islemler geri alinamaz. Konsoldan (rcon) calistir.' : 'These actions cannot be undone. Run them from the console (rcon).') + '</div><div class="cmds">' + f.map(function (x) { return '<div><p><b>' + esc(x[0]) + '</b>' + esc(x[1]) + '</p></div>'; }).join('') + '</div>');
  }
  return h;
};
R.about = function () { return card('', '<div class="about"><div class="lg">' + LOGO() + '</div><p><b>VEXMIRA</b> &middot; PAD 6.2.4</p><p class="muted" style="margin:6px 0">' + esc(L('credit')) + ': <b style="color:var(--acc)">smurfsexy</b></p><p class="muted">' + esc(D.map) + ' &middot; ' + esc(L('round')) + ' ' + esc(D.round) + '</p>' + (D.ts ? '<p class="muted">' + esc(F('updated', Math.max(0, Math.round((Date.now() / 1000 - D.ts) / 60)))) + '</p>' : '') + '</div>'); };

R.store = function () {
  var h = '<div class="feat"><div><div class="sq" style="' + grad('g2048') + '">' + svg('g2048') + '</div></div><div class="fd"><small>' + esc(L('featured')) + '</small><h2>' + esc(L('g2048')) + '</h2><p>' + esc(L('d_g2048')) + '</p></div><div class="fb">' + storeBtn('g2048') + '</div></div>';
  CATS.forEach(function (c) {
    h += '<h3 class="sth">' + esc(L(c[0])) + '</h3><div class="apps">';
    c[1].forEach(function (a) { h += '<div class="appr"><div class="ar"><div><div class="sq" style="' + grad(a) + '">' + svg(a) + '</div></div><div class="ad"><b>' + esc(L(a)) + '</b><small>' + esc(L('d_' + a)) + '</small><span class="stars">&#9733;&#9733;&#9733;&#9733;&#9733;</span></div><div class="ab">' + storeBtn(a) + '</div></div></div>'; });
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
function startGame() { var epoch=EPOCH,lastPaint=Date.now();
  var cv = $('gcv'); if (!cv) return; var W = cv.width = Math.max(280,cv.clientWidth), H = cv.height = Math.max(170,cv.clientHeight), cx = cv.getContext('2d');
  var best = num(store('flap')), g = { y: H / 2, v: 0, pipes: [], t: 0, score: 0, state: 0 }, gap = Math.max(110, H * 0.3), spd = Math.max(2.4, W / 300);
  $('gBest').textContent = L('best') + ': ' + best;
  function reset() { g.y = H / 2; g.v = 0; g.pipes = []; g.t = 0;g.units=0;g.spawnAt=0; g.score = 0; g.state = 0; $('gScore').textContent = '0'; }
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
    if(epoch!==EPOCH || !$('gcv') || !GAME || GAME.stop) return;
    cx.clearRect(0, 0, W, H);
    var sky = cx.createLinearGradient(0, 0, 0, H); sky.addColorStop(0, '#12040a'); sky.addColorStop(1, '#030103'); cx.fillStyle = sky; cx.fillRect(0, 0, W, H);
    cx.fillStyle = 'rgba(255,230,200,.85)'; cx.beginPath(); cx.arc(W * 0.8, H * 0.2, Math.min(W, H) * 0.08, 0, Math.PI * 2); cx.fill();
    cx.fillStyle = 'rgba(80,0,16,.35)'; for (var m = 0; m < 6; m++) { var mx = ((m * 180 - g.t * 0.4) % (W + 200) + W + 200) % (W + 200) - 100; cx.beginPath(); cx.moveTo(mx, H); cx.lineTo(mx + 90, H * 0.72); cx.lineTo(mx + 180, H); cx.fill(); }
    if (g.state === 1) {
      var scale=Math.min(2.5,Math.max(.5,(Date.now()-lastPaint)/16.667));lastPaint=Date.now();g.units=(g.units||0)+scale;g.t=Math.floor(g.units);g.v += H * 0.0006*scale; g.y += g.v*scale;
      if (!g.spawnAt || g.units>=g.spawnAt) {g.spawnAt=g.units+Math.round(95/(spd/2.4)); var top = 40 + Math.random() * (H - gap - 80); g.pipes.push({ x: W + 10, top: top, ok: false }); }
      g.pipes.forEach(function (p) { p.x -= spd*scale; if (!p.ok && p.x + 64 < W * 0.3) { p.ok = true; g.score++; $('gScore').textContent = g.score; tone(1320, 0.06, 'sine', 0.06); } });
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
    setTimeout(loop,33);
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
  return card('', '<div class="cmds">' + CMDS.map(function (c) { return '<div><p><b>/' + esc(D.lang === 'tr' ? c[1] : c[0]) + '</b>' + esc(tr(c[2], c[3])) + '</p></div>'; }).join('') + '</div>');
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
  tk.forEach(function (n, i) { var on = MUS.i === i; h += '<div class="trk' + (on ? ' on' : '') + '" data-mus="' + i + '"><div class="tr"><div><span class="tb" style="display:block;' + grad(['music', 'prof', 'case', 'inv'][i]) + '">' + svg(on ? 'pause' : 'play') + '</span></div><div class="tt"><b>' + esc(n) + '</b><small>VEXMIRA Ambience &middot; ' + ['4:12', '3:30', '5:05', '4:48'][i] + '</small></div></div></div>'; });
  return h + '</div>';
};
var VIZ_ID=0;
function musViz() {var viz=++VIZ_ID;
  var cv = $('mviz'); if (!cv) return; var W = cv.width = Math.max(280,cv.clientWidth), H = cv.height = Math.max(170,cv.clientHeight), cx = cv.getContext('2d'), arr = new Uint8Array(64);
  (function f() {
    if (viz!==VIZ_ID || !$('mviz') || cur !== 'music') return;
    cx.clearRect(0, 0, W, H);
    if (MUS.an && MUS.i >= 0) MUS.an.getByteFrequencyData(arr); else for (var k = 0; k < 64; k++) arr[k] = 0;
    var bw = W / 40;
    for (var j = 0; j < 40; j++) { var v = arr[j + 2] / 255, bh = Math.max(3, v * H * 0.9), gr = cx.createLinearGradient(0, H, 0, H - bh); gr.addColorStop(0, ICOL.music.split(',')[1]); gr.addColorStop(1, ICOL.music.split(',')[0]); cx.fillStyle = gr; cx.fillRect(j * bw + 2, H - bh, bw - 4, bh); }
    setTimeout(f,33);
  })();
}
R.notes = function () { return '<textarea id="notesTa" class="notes" placeholder="' + esc(L('notesPh')) + '">' + esc(store('notes') || '') + '</textarea>'; };
var CALC = { v: '0', a: null, op: null, fresh: true };
R.calc = function () {
  var k = [['C', 'fn'], ['+/-', 'fn'], ['%', 'fn'], ['/', 'op'], ['7'], ['8'], ['9'], ['*', 'op'], ['4'], ['5'], ['6'], ['-', 'op'], ['1'], ['2'], ['3'], ['+', 'op'], ['0', 'z'], ['.'], ['=', 'op']];
  return '<div class="calc"><div class="cdisp" id="cdisp">' + esc(CALC.v) + '</div><div class="ckeys">' + k.map(function (x) { return '<span class="ck ' + (x[1] || '') + '" data-calc="' + x[0] + '"><span>' + (x[0] === '*' ? '&times;' : x[0] === '/' ? '&divide;' : x[0]) + '</span></span>'; }).join('') + '</div></div>';
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
function startSnake() { var epoch=EPOCH;
  var cv = $('scv'); if (!cv) return; var W = cv.width = Math.max(280,cv.clientWidth), H = cv.height = Math.max(170,cv.clientHeight), cx = cv.getContext('2d');
  var cs = Math.max(14, Math.floor(Math.min(W / 28, H / 18))), CW = Math.floor(W / cs), CH = Math.floor(H / cs), ox = (W - CW * cs) / 2, oy = (H - CH * cs) / 2;
  var best = num(store('snake')), s, dir, nd, food, dead, score, last = 0, run = false;
  $('gBest').textContent = L('best') + ': ' + best;
  function place() { if(s.length>=CW*CH){dead=true;run=false;return;} do { food = { x: Math.floor(Math.random() * CW), y: Math.floor(Math.random() * CH) }; } while (s.some(function (p) { return p.x === food.x && p.y === food.y; })); }
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
    if(epoch!==EPOCH || !$('scv') || !GAME || GAME.stop) return;
    if (run && !dead && ts - last > Math.max(60, 120 - score * 2)) {
      last = ts; dir = nd; var h = { x: s[0].x + [0, 1, 0, -1][dir], y: s[0].y + [-1, 0, 1, 0][dir] };
      if (h.x < 0 || h.y < 0 || h.x >= CW || h.y >= CH || s.some(function (p) { return p.x === h.x && p.y === h.y; })) { dead = true; run = false; tone(160, 0.5, 'sawtooth', 0.08, 0, 60); if (score > best) { best = score; store('snake', best); $('gBest').textContent = L('best') + ': ' + best; } }
      else { s.unshift(h); if (h.x === food.x && h.y === food.y) { score++; $('gScore').textContent = score; tone(1100, 0.06, 'sine', 0.06, 0, 1500); place(); } else s.pop(); }
    }
    draw(); setTimeout(function(){loop(Date.now());},50);
  })(Date.now());
}
R.g2048 = function () { return '<div class="g48"><div class="g48h"><div><small>' + esc(L('score')) + '</small><b id="gScore">0</b></div><div><small>' + esc(L('best')) + '</small><b id="gBest">0</b></div><span class="gbtn get" data-gs="1">' + esc(L('again')) + '</span></div><div class="g48b" id="g48b"></div><div class="ghint">' + esc(L('hint2048')) + '</div>' + pads() + '</div>'; };
function start2048() {
  var B, score, best = num(store('2048')), over;
  function add() { var e = []; B.forEach(function (v, i) { if (!v) e.push(i); }); if (e.length) B[e[Math.floor(Math.random() * e.length)]] = Math.random() < 0.9 ? 2 : 4; }
  function reset() { B = []; for (var i = 0; i < 16; i++) B.push(0); score = 0; over = false; add(); add(); draw(); }
  function draw() { var el = $('g48b'); if (!el) return; el.innerHTML = B.map(function (v) { return '<div class="c48 v' + Math.min(v, 4096) + '"><i>' + (v || '') + '</i></div>'; }).join('') + (over ? '<div class="g48o">' + esc(L('over')) + '</div>' : ''); $('gScore').textContent = score; $('gBest').textContent = best; }
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
R.whack = function () { var h = '<div class="wk"><div class="wkh"><div><small>' + esc(L('score')) + '</small><b id="gScore">0</b></div><div><small>' + esc(L('timeLeft')) + '</small><b id="wkT">30</b></div><div><small>' + esc(L('best')) + '</small><b id="gBest">0</b></div><span class="gbtn get" data-gs="1">' + esc(L('start')) + '</span></div><div class="wkg">'; for (var i = 0; i < 9; i++) h += '<div class="hole" data-hole="' + i + '"><div><i class="zb"></i></div></div>'; return h + '</div></div>'; };
function startWhack() {
  var best = num(store('whack')), score = 0, tl = 0, live = -1, timer = null, spawn = null;
  $('gBest').textContent = best;
  function show() { var hs = document.querySelectorAll('.hole'); for (var i = 0; i < hs.length; i++) hs[i].className = 'hole' + (i === live ? ' up' : ''); }
  function next() { if (tl <= 0) return; var n; do { n = Math.floor(Math.random() * 9); } while (n === live); live = n; show(); clearTimeout(spawn); spawn = setTimeout(next, Math.max(420, 900 - score * 15)); }
  function end() { clearInterval(timer); clearTimeout(spawn); live = -1; show(); tone(200, 0.4, 'sawtooth', 0.06, 0, 90); if (score > best) { best = score; store('whack', best); } $('gBest').textContent = best; banner(L('whack'), L('score') + ': ' + score, 'whack', ICOL.whack.split(',')[1]); }
  function start() { score = 0; tl = 30; $('gScore').textContent = '0'; $('wkT').textContent = '30'; clearInterval(timer); timer = setInterval(function () { if (!$('wkT') || !GAME || GAME.stop) { clearInterval(timer); clearTimeout(spawn); return; } tl--; $('wkT').textContent = tl; if (tl <= 0) end(); }, 1000); next(); }
  GAME = { stop: false, dispose:function(){clearInterval(timer);clearTimeout(spawn);}, start: start, hit: function (i) { if (i === live && tl > 0) { score++; $('gScore').textContent = score; tone(300, 0.08, 'square', 0.07, 0, 90); var h = document.querySelectorAll('.hole')[i]; h.className = 'hole hit'; live = -1; clearTimeout(spawn); spawn = setTimeout(next, 220); } } };
}
var STARTERS = { game: function () { startGame(); }, snake: startSnake, g2048: start2048, whack: startWhack, music: musViz, msg: function () { var i = $('msgIn'); if (i && CHAT) i.focus(); var b = document.getElementsByClassName('bubbles')[0]; if (b) b.scrollTop = b.scrollHeight; } };

// ------------------------------------------------------------------ home (widgets + grid + folder + edit mode)
var EPOCH=0;function stopGame(){EPOCH++;if(GAME){GAME.stop=true;if(GAME.dispose)GAME.dispose();GAME=null;}}
var cur = null, EDIT = false, ACCS = ['#e3243b', '#ff6a2b', '#ffc23a', '#3ddc84', '#2fb8ff', '#8b5cff', '#ff4fa0'];
function applyAccent() {}
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
  var badges = { daily: D.claimed ? 0 : 1, 'case': D.cr ? 1 : 0, notif: D.un | 0, trade: OF.filter(function (o) { return o[5] === 1; }).length, msg: MS.filter(function (m) { return !m[4]; }).length ? 0 : 0 };
  var h = '<div class="hello"><h1>' + esc(L('hello')) + ', <b>' + esc(D.name) + '</b></h1><div class="hact">' +
    '<span class="ldot" id="linkDot"></span>' + (EDIT ? '<span class="pill on" data-ui="done">' + esc(L('done')) + '</span>' : '<span class="pill" data-ui="cc">' + svg('brush') + esc(L('custom')) + '</span>') + '</div></div>';
  h += '<div class="hbody' + (EDIT ? ' edit' : '') + '">' + widgets() + '<div class="grid">' + homeApps().map(function (a) { return icoHtml(a, badges); }).join('') + '</div></div>';
  h += '<div class="dock"><div class="dockin">' + DOCK.map(function (a) { return icoHtml(a, badges, true); }).join('') + '</div></div>';
  $('home').innerHTML = h; colors($('home')); HOME_SIG=JSON.stringify([D.lv,D.xp,D.xn,D.ap,D.vc,D.claimed,D.un,D.on,D.lang,D.round,D.map,D.rank,D.role,OF]);
  if (typeof linkDot === 'function') linkDot();
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
  function tile(k, ic, on, lab, val) { return '<div class="cct' + (on ? ' on' : '') + '" data-set="' + k + '"><div><i>' + svg(ic) + '</i><b>' + esc(lab) + '</b><small>' + esc(val) + '</small></div></div>'; }
  var h = '<div class="ccp"><div class="cch"><b>' + esc(L('cc')) + '</b><span class="x" data-ui="ccx">&times;</span></div><div class="ccg">' +
    tile(dark ? 'light' : 'dark', dark ? 'moon' : 'sun', dark, L('theme'), dark ? L('dark') : L('light')) + tile('snd', 'vol', soundOn, L('sound'), soundOn ? 'ON' : 'OFF') +
    tile('ntf', 'bell', notifOn, L('notif'), notifOn ? 'ON' : 'OFF') + tile(D.lang === 'tr' ? 'en' : 'tr', 'globe', true, L('lang'), D.lang === 'tr' ? 'Turkce' : 'English') + '</div>';
  h += '<div class="ccs"><i>' + svg('bright') + '</i><input id="ccBr" type="range" min="45" max="100" value="' + br + '"></div>';
  h += '<div class="ccl">' + esc(L('accent')) + '</div><div class="ccacc">' + ACCS.map(function (c) { return '<span data-acc="' + c + '" class="' + (c === acc ? 'on' : '') + '" style="background:' + c + '"></span>'; }).join('') + '</div>';
  h += '<div class="ccl">' + esc(L('wall')) + '</div><div class="ccwp">' + L('wpNames').map(function (n, i) { return '<div class="wpt' + (i === WP ? ' on' : '') + '" data-wp="' + i + '"><div class="w wp' + i + '">' + (i === 7 ? emblem() : '') + '<small>' + esc(n) + '</small></div></div>'; }).join('') + '</div>';
  if (MUS.i >= 0) h += '<div class="ccm"><i style="' + grad('music') + '">' + svg('music') + '</i><div><small>' + esc(L('np')) + '</small><b>' + esc(L('tracks')[MUS.i]) + '</b></div><span class="gbtn" data-ui="mstop">' + esc(L('stop')) + '</span></div>';
  h += '<div class="cce" data-ui="edit">' + svg('grid') + esc(L('edit')) + '</div></div>';
  return h;
}
function openCC() { overlay('cc', ccHtml()); var r = $('ccBr'); if (r) r.addEventListener('input', function () { store('br', r.value); applyBright(); }); SND.open(); }
function refreshCC() { var o = $('cc'); if (o && o.className.indexOf('show') >= 0) { o.innerHTML = ccHtml(); var r = $('ccBr'); if (r) r.addEventListener('input', function () { store('br', r.value); applyBright(); }); } }
function setWall() { var w = $('wall'); w.className = 'wall wp' + WP + (cur ? ' blur' : ''); w.innerHTML = WP === 7 ? '<div class="wlogo">' + emblem() + '</div>' : ''; }
function openApp(a, noSound) {
  if (!R[a]) a = 'prof'; closeOv('fold'); closeOv('cc'); EDIT = false; cur = a;
  stopGame();
  $('appTitle').textContent = L(a); $('appIco').style.cssText = grad(a); $('appIco').innerHTML = svg(a);
  $('backTxt').textContent = L('home'); $('appRight').textContent = D.role >= 2 ? (D.lang === 'tr' ? 'Kurucu' : 'Founder') : D.role === 1 ? 'Admin' : '';
  $('appBody').innerHTML = R[a](); $('appBody').scrollTop = 0; $('appBody').className = 'app-body' + (GAMES.indexOf(a) >= 0 || a === 'calc' || a === 'notes' ? ' full' : '');
  $('app').className = 'app open'; $('home').className = 'home hide'; setWall();
  if (!noSound) SND.open();
  if (a === 'case') runReel();
  if(STARTERS[a]){var epoch=EPOCH;setTimeout(function(){if(epoch!==EPOCH||cur!==a)return;try{STARTERS[a]();}catch(e){stopGame();toast(tr('Oyun baslatilamadi. Ana ekrana donebilirsin.','Game could not start. You can return home.'),false);}},30);} colors($('appBody'));
}
function goHome() { stopGame(); closeOv('fold'); closeOv('cc'); var was = cur; cur = null; $('app').className = 'app'; $('home').className = 'home'; setWall(); if (was) SND.close(); renderHome(); }
function rerender() { stopGame(); applyTheme(); applyAccent(); renderHome(); if (cur) { $('appBody').innerHTML = R[cur](); $('appTitle').textContent = L(cur); $('backTxt').textContent = L('home'); if (STARTERS[cur]) STARTERS[cur](); colors($('appBody')); } $('lockHint').textContent = L('unlock'); clock(); refreshCC(); }
function unlock(page) { var lk = $('lock'); if (lk.className.indexOf('off') >= 0) return; lk.className = 'lock off'; $('screen').className = 'screen'; $('home').className = 'home'; SND.unlock(); if (page && page !== 'home') openApp(page, true); notifications(); }
function notifications() {
  var d = 300;
  if(DEMO)return;
  if (!D.claimed) { banner(L('daily'), L('dailyReady'), 'daily', ICOL.daily.split(',')[1], d); d += 900; }
  if (D.vip && D.vd > 0 && D.vd <= 3) { banner('VIP', F('vipDays', D.vd), 'ach', '#b37800', d); d += 900; }
}

// ------------------------------------------------------------------ confetti
function confetti(col) {
  var cv = $('fx'), cx = cv.getContext('2d'), W = cv.width = Math.max(280,cv.clientWidth), H = cv.height = Math.max(170,cv.clientHeight), P = [], cols = [col, '#ffffff', '#ffd34a', '#e3243b', '#7cff3a'];
  for (var i = 0; i < 36; i++) P.push({ x: W / 2, y: H / 3, vx: (Math.random() - 0.5) * 12, vy: Math.random() * -10 - 2, s: 3 + Math.random() * 5, c: cols[i % cols.length], r: Math.random() * 6, life: 0 });
  var t0 = Date.now();
  (function f() { cx.clearRect(0, 0, W, H); P.forEach(function (p) { p.vy += 0.25; p.x += p.vx; p.y += p.vy; p.r += 0.2; cx.save(); cx.translate(p.x, p.y); cx.rotate(p.r); cx.fillStyle = p.c; cx.fillRect(-p.s / 2, -p.s / 4, p.s, p.s / 2); cx.restore(); }); if (Date.now() - t0 < 3500) setTimeout(f,33); else cx.clearRect(0, 0, W, H); })();
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
  var el = findAttr(e.target, ['data-rm', 'data-get', 'data-open', 'data-ui', 'data-fold', 'data-app', 'data-tab', 'data-top', 'data-case', 'data-openc', 'data-daily', 'data-eq', 'data-set', 'data-wp', 'data-acc', 'data-mus', 'data-calc', 'data-dir', 'data-hole', 'data-gs', 'data-chat', 'data-send', 'data-fadd', 'data-facc', 'data-fdel', 'data-block', 'data-unblock', 'data-toffer', 'data-tgive', 'data-tacc', 'data-tdec', 'data-admtab', 'data-admp', 'data-adm', 'data-map','data-zperk','data-achclaim','data-marketcode','data-marketlist','data-marketbuy','data-marketcancel','data-marketconfirm','data-marketabort','data-linktest']);
  if (!el) {
    var t = e.target;
    if (t && t.className && typeof t.className === 'string' && t.className.indexOf('ov ') === 0) { closeOv(t.id); if (t.id === 'cc') SND.close(); }
    else if (EDIT && !cur && !findAttr(e.target, ['data-app'])) { EDIT = false; renderHome(); }
    return;
  }
  var v;
  if(el.getAttribute('data-linktest')!==null){act('ping');return;}
  if((v=el.getAttribute('data-achclaim'))!==null){act('claimach',num(v));return;}
  if((v=el.getAttribute('data-marketcode'))!==null){MARKET_CODE=v;$('appBody').innerHTML=R.market();colors($('appBody'));return;}
  if((v=el.getAttribute('data-marketlist'))!==null){var price=$('marketPrice');if(MARKET_CODE&&price){if(!/^[0-9]{1,9}$/.test(price.value)){toast(tr('Fiyat pozitif bir tam sayı olmalı.','Price must be a positive integer.'),false);return;}act('marketlist',MARKET_CODE,price.value);}return;}
  if((v=el.getAttribute('data-marketbuy'))!==null){MARKET_CONFIRM=num(v);$('appBody').innerHTML=R.market();colors($('appBody'));$('appBody').scrollTop=0;return;}
  if((v=el.getAttribute('data-marketconfirm'))!==null){if(act('marketbuy',MARKET_CONFIRM)){MARKET_CONFIRM=0;$('appBody').innerHTML=R.market();colors($('appBody'));}return;}
  if((v=el.getAttribute('data-marketabort'))!==null){MARKET_CONFIRM=0;$('appBody').innerHTML=R.market();colors($('appBody'));return;}
  if((v=el.getAttribute('data-marketcancel'))!==null){act('marketcancel',num(v));return;}
  if((v=el.getAttribute('data-zperk'))!==null){var zp=v.split('.');act('zperk',zp[0],zp[1]);return;}
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
  // ---- live-link apps ----
  if ((v = el.getAttribute('data-chat')) !== null) { CHAT = num(v); $('appBody').innerHTML = R.msg(); if (CHAT && STARTERS.msg) STARTERS.msg(); SND.click(); return; }
  if ((v = el.getAttribute('data-send')) !== null) { var inp = $('msgIn'); if (inp && inp.value.replace(/^\s+|\s+$/g, '')) { act('msg', num(v), hexs(inp.value), '', '/ipad'); inp.value = ''; } return; }
  if ((v = el.getAttribute('data-fadd')) !== null) { act('fadd', num(v), '', '', '/ipad'); SND.click(); return; }
  if ((v = el.getAttribute('data-facc')) !== null) { act('facc', num(v)); SND.click(); return; }
  if ((v = el.getAttribute('data-fdel')) !== null) { act('fdel', num(v)); SND.click(); return; }
  if ((v = el.getAttribute('data-block')) !== null) { act('block', num(v)); SND.click(); return; }
  if ((v = el.getAttribute('data-unblock')) !== null) { act('unblock', num(v)); SND.click(); return; }
  if ((v = el.getAttribute('data-openc')) !== null) { if (REEL_RUN) return; act('case', num(v), '', '', D.lang === 'tr' ? '/kasa' : '/case'); SND.click(); return; }
  if (el.getAttribute('data-daily') !== null) { act('daily', '', '', '', D.lang === 'tr' ? '/gunluk' : '/daily'); SND.click(); return; }
  if ((v = el.getAttribute('data-eq')) !== null) { var q = v.split('.'); act('equip', q[0], num(q[1]) + 1, q[2] === '1' ? 1 : 0, D.lang === 'tr' ? '/kozmetik' : '/cosmetic'); SND.click(); return; }
  if ((v = el.getAttribute('data-tgive')) !== null) { tradeSel = (tradeSel === v ? null : v); $('appBody').innerHTML = R.trade(); SND.click(); return; }
  if ((v = el.getAttribute('data-toffer')) !== null) { if (tradeSel) { act('trade', num(v), tradeSel, '-', '/takas'); tradeSel = null; } SND.click(); return; }
  if ((v = el.getAttribute('data-tacc')) !== null) { act('tacc', num(v)); SND.click(); return; }
  if ((v = el.getAttribute('data-tdec')) !== null) { act('tdec', num(v)); SND.click(); return; }
  if ((v = el.getAttribute('data-admtab'))) { admTab = v; $('appBody').innerHTML = R.adm(); SND.click(); return; }
  if ((v = el.getAttribute('data-admp')) !== null) { admSel = (admSel === num(v) ? 0 : num(v)); $('appBody').innerHTML = R.adm(); SND.click(); return; }
  if ((v = el.getAttribute('data-map'))) { act('adm', 'map', v, '', 'amx_map ' + v); SND.click(); return; }
  if ((v = el.getAttribute('data-adm'))) {
    SND.click();
    if (v === 'saynow') { var si = $('admSay'); if (si && si.value) act('adm', 'say', hexs(si.value), '', null); return; }
    var q = v.split('|'); act('adm', q[0], q[1] || '', q[2] || '', null); return;
  }
  if ((v = el.getAttribute('data-calc')) !== null) { SND.tick(); calcKey(v); return; }
  if ((v = el.getAttribute('data-mus')) !== null) { v = num(v); if (MUS.i === v) musStop(); else musPlay(v); $('appBody').innerHTML = R.music(); musViz(); return; }
  SND.click();
  if ((v = el.getAttribute('data-top'))) { $('appBody').innerHTML = leader(v); return; }
  if ((v = el.getAttribute('data-tab'))) { invTab = v; $('appBody').innerHTML = R[cur](); return; }
  if ((v = el.getAttribute('data-case')) !== null) { caseSel = num(v); var keep = D.cr; D.cr = null; $('appBody').innerHTML = R['case'](); D.cr = keep; return; }
  if ((v = el.getAttribute('data-wp')) !== null) { WP = num(v) % 8; store('wp', WP); setWall(); if (cur === 'set') $('appBody').innerHTML = R.set(); refreshCC(); return; }
  if ((v = el.getAttribute('data-acc')) !== null) { store('acc', v); applyAccent(); refreshCC(); if (cur === 'set') $('appBody').innerHTML = R.set(); return; }
  if ((v = el.getAttribute('data-set'))) {
    if (v === 'dark' || v === 'light') store('theme', v);
    else if (v === 'snd') { soundOn = !soundOn; store('snd', soundOn ? '1' : '0'); }
    else if (v === 'ntf') { notifOn = !notifOn; store('ntf', notifOn ? '1' : '0'); }
    else if (v === 'tr' || v === 'en') { D.lang = v; store('lang', v);if(LIVE.on&&LIVE.tk)act('lang',v); }
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

// ================================================================== 6.2 LIVE LINK (actions + live data)
// The tablet sends actions to the game server through a public message relay (ntfy.sh, a plain GET
// "image beacon" that works in the CS 1.6 MOTD browser). The server validates the per-player token,
// runs the action, and writes the result + live data to u/<token>.js, which the tablet re-reads every
// 2 seconds. No account, no secret stored in the page. Tablet & mod: smurfsexy
var MARKET=[],MARKET_CODE='',MARKET_CONFIRM=0;
var LIVE = { tk: dec(RAW.tk), uid: num(RAW.uid), rt: dec(RAW.rt), rh: dec(RAW.rh), on: num(RAW.rl) === 1, seq: 0, pend: {}, fileOk: false, polls: 0, fast: 0 };
var PL = [], FR = [], MS = [], NT = [], OF = [], MAPS = [];
function hexs(str) { var u = unescape(encodeURIComponent(str)), h = ''; for (var i = 0; i < u.length; i++) { var c = u.charCodeAt(i).toString(16); h += (c.length < 2 ? '0' : '') + c; } return h; }
function nextSeq() { var s = Math.floor(Date.now() / 100) % 1000000000; if (s <= LIVE.seq) s = LIVE.seq + 1; LIVE.seq = s; return s; }
function toast(t, ok) { banner(ok === false ? (D.lang === 'tr' ? 'Islem yapilamadi' : 'Action failed') : 'iPad', t, ok === false ? 'about' : 'bell', ok === false ? '#c8102e' : '#1f8a4c'); }
function act(name, a, b, c, cmdHint) {
  if (!LIVE.on || !LIVE.tk || !LIVE.rt) { toast(tr('Canlı bağlantı kapalı. Sunucu bağlantısı kontrol edilmeli.','Live link is off. Check the server connection.'), false); return 0; }
  if(!LIVE.fileOk||!LIVE.ready){toast(tr('Canlı veri veya komut bağlantısı hazır değil. Ayarlar > Canlı bağlantı bölümünü kontrol et.','Live data or command stream is not ready. Check Settings > Live connection.'),false);return 0;}
  for(var pk in LIVE.pend){toast(tr('Onceki islem bekleniyor.','Waiting for the previous action.'),false);return 0;}
  var s = nextSeq(), msg = ['vx1', LIVE.tk, s, name, a == null ? '' : a, b == null ? '' : b, c == null ? '' : c].join('~');
  LIVE.pend[s]={name:name,hint:cmdHint};
  var img = new Image();var base=(location.protocol==='https:'?'https://':'http://')+LIVE.rh.replace(location.protocol==='https:'?/:80$/:/$^/,'')+'/'+LIVE.rt;function beacon(){img.src=base+'/publish?message='+encodeURIComponent(msg)+'&title=vx&cache=no';}try{var xhr=new XMLHttpRequest();xhr.open('POST',base+'?cache=no',true);xhr.setRequestHeader('Content-Type','text/plain;charset=UTF-8');xhr.onreadystatechange=function(){if(xhr.readyState!==4||!LIVE.pend[s])return;if(xhr.status===0)beacon();else if(xhr.status<200||xhr.status>=300){delete LIVE.pend[s];busy(false);toast(tr('Aracı bağlantı HTTP ','Relay HTTP ')+xhr.status,false);}};xhr.send(msg);}catch(netError){beacon();}
  LIVE.pend[s].beacon=img;setTimeout(function(){if(LIVE.pend[s])beacon();},1800);img.onerror=function(){/* ntfy returns JSON, so image decode errors are expected */};
  LIVE.fast = Date.now() + 9000; busy(true);
  setTimeout(function () { if (LIVE.pend[s]) { delete LIVE.pend[s]; busy(false); toast(tr('Sunucudan işlem onayı alınamadı. Sonuç henüz doğrulanmadı.','No server acknowledgement. The result is not confirmed yet.'), false); } }, 12000);
  return s;
}
function busy(on) { var b = $('busy'); if (!b) { b = document.createElement('div'); b.id = 'busy'; b.className = 'busy'; b.innerHTML = '<i class="ring"></i>'; $('screen').appendChild(b); } b.style.display = on ? 'block' : 'none'; }
function pollU() {
  if (!LIVE.tk || LIVE.loading) return;LIVE.loading=true;var pollTimer=setTimeout(function(){LIVE.loading=false;},5000);
  window.VXU=null;var old = $('vxu'); if (old) old.parentNode.removeChild(old);
  var s = document.createElement('script'); s.id = 'vxu'; s.src = 'state624_' + LIVE.tk + '.js?t=' + Date.now();
  s.onload = function () { clearTimeout(pollTimer);LIVE.loading=false; LIVE.fileOk=!!(window.VXU&&window.VXU.me===LIVE.uid&&window.VXU.proto===624);LIVE.dataError=LIVE.fileOk?'':tr('Canlı veri dosyası geçersiz veya eski sürüm.','Invalid live data or an old server version.');if(LIVE.fileOk)applyU(window.VXU);linkDot(); };
  s.onerror = function () { clearTimeout(pollTimer);LIVE.loading=false; LIVE.fileOk = false;LIVE.dataError=tr('Canlı veri dosyası yüklenemedi.','Live data file failed to load.'); linkDot(); };
  document.getElementsByTagName('head')[0].appendChild(s);
}
(function loopU() { LIVE.polls++; pollU(); setTimeout(loopU, Date.now() < LIVE.fast ? 450 : 2500); })();
function buildStatus624(){var b=$('build624');if(b)b.textContent='PAD 6.2.4 · '+(LIVE.fileOk?(LIVE.ready?'CANLI':'VERİ VAR'):'VERİ BEKLENİYOR');}
function linkDot() { buildStatus624(); var d = $('linkDot'); if (d) {d.title=LIVE.fileOk?(LIVE.ready?tr('Sunucu bağlantısı hazır','Server link ready'):tr('Veri okunuyor, komut bağlantısı bekleniyor','Reading data; waiting for command link')):tr('Canlı veri dosyası okunamıyor','Live data file unavailable'); d.className = 'ldot ' + (LIVE.fileOk ? (LIVE.ready ? 'g' : 'y') : 'r'); } }
function typing() { var a = document.activeElement; return a && (a.tagName === 'INPUT' || a.tagName === 'TEXTAREA'); }
var HOME_SIG='', LIVE_SIG='';
var REEL_RUN = false;
function applyU(u) {
  if(u.me&&LIVE.uid&&u.me!==LIVE.uid)return;D.on=(u.pl||[]).length;if(u.lang&&u.lang!==D.lang){D.lang=u.lang;store('lang',D.lang);applyTheme();}if(u.enabled!==undefined)LIVE.on=u.enabled===1;LIVE.ready=u.link===1;LIVE.serverTime=num(u.v);linkDot();
  if(u.map)D.map=u.map;if(u.round)D.round=u.round;if(u.mx)D.mx=u.mx;if(u.claimed!==undefined)D.claimedMask=u.claimed|0;if(u.achReward)D.achReward=u.achReward;if(u.market)MARKET=u.market;if(u.zup)D.zup=u.zup;if(u.daily)D.rewards=u.daily;if(u.dn)D.dailyNext=u.dn;if(u.top)D.top=u.top;if(u.tt)D.tt=u.tt;if(u.at)D.at=u.at;if(u.stats)for(var stat in u.stats)if(Object.prototype.hasOwnProperty.call(D,stat))D[stat]=u.stats[stat];
  D.ap = u.ap; D.vc = u.vc; D.lv = u.lv; D.xp = u.xp; D.xn = u.xn; D.iv = masks(u.iv); D.eq = masks(u.eq);
  var dy = String(u.dy).split('~'); D.streak = num(dy[0]); D.claimed = num(dy[1]) === 1; D.next = num(dy[2]);
  PL = u.pl || []; FR = u.fr || []; MS = u.ms || []; NT = u.nt || []; OF = u.of || []; MAPS = u.maps || MAPS; D.un = u.un | 0;
  if (u.me) LIVE.uid = u.me;
  var acked = false;
  for (var k in LIVE.pend) if (num(k) <= u.ack) { acked = LIVE.pend[k]; delete LIVE.pend[k]; }
  if (acked) { busy(false); onResult(acked.name, String(u.res || '')); }
  var snap={};for(var dk in D)if(dk!=='next')snap[dk]=D[dk];var liveSig=JSON.stringify([cur,snap,PL,FR,MS,NT,OF,MARKET]);var counter=$('dailyCountdown');if(counter)counter.textContent=hms(D.next);if (!typing() && !REEL_RUN && cur && LIVE_APPS.indexOf(cur) >= 0 && !GAME && liveSig!==LIVE_SIG) { LIVE_SIG=liveSig;var st = $('appBody').scrollTop; $('appBody').innerHTML = R[cur](); $('appBody').scrollTop = st;colors($('appBody')); }
  if (!cur) { var sig=JSON.stringify([D.lv,D.xp,D.xn,D.ap,D.vc,D.claimed,D.un,D.on,D.lang,D.round,D.map,D.rank,D.role,OF]);if(sig!==HOME_SIG){HOME_SIG=sig;renderHome();} }
}
var LIVE_APPS = ['msg', 'friends', 'notif', 'trade', 'adm', 'daily', 'inv', 'prof', 'top', 'zup','ach','market','set'];
function onResult(name, res) {
  var p = res.split('~'), ok = p[0] === 'ok', tr = D.lang === 'tr';
  if (!ok) { toast(p.slice(1).join(' ') || (tr ? 'Hata' : 'Error'), false); return; }
  if (name === 'case' && p[1] === 'case') {
    D.cr = { c: num(p[2]), code: p[3], r: num(p[4]) }; caseSel = D.cr.c;
    if (cur === 'case') { $('appBody').innerHTML = R['case'](); REEL_RUN = true; runReel(); setTimeout(function () { REEL_RUN = false; }, 8000); }
    return;
  }
  var M = {ping:tr?'Sunucudan cevap alındı':'Server replied',market:tr?'Pazar işlemi tamamlandı':'Market action complete',claimach:tr?'Başarım ödülü alındı':'Achievement reward claimed', daily: tr ? 'Gunluk odul alindi' : 'Daily reward claimed', equip: tr ? 'Kusanildi' : 'Equipped', msg: tr ? 'Mesaj gonderildi' : 'Message sent',
    fadd: tr ? 'Arkadaslik istegi gonderildi' : 'Friend request sent', facc: tr ? 'Arkadas eklendi' : 'Friend added', fdel: tr ? 'Arkadas silindi' : 'Friend removed',
    block: tr ? 'Engellendi' : 'Blocked', unblock: tr ? 'Engel kalkti' : 'Unblocked', trade: tr ? 'Takas teklifi gonderildi' : 'Trade offer sent',
    tacc: tr ? 'Takas tamamlandi' : 'Trade complete', tdec: tr ? 'Teklif reddedildi' : 'Offer declined', adm: tr ? 'Yonetim islemi uygulandi' : 'Admin action done',
    rr: tr ? 'Round yeniden basliyor' : 'Round restarting', map: tr ? 'Harita degisiyor' : 'Map changing', say: tr ? 'Duyuru gonderildi' : 'Announcement sent' };
  if (p[1] !== 'seen' && p[1] !== 'ping') toast(M[p[1]] || M[name] || 'OK', true);
  if (name === 'daily'||name==='claimach') SND.win(2);
}
// ------------------------------------------------------------------ list helpers
function plName(uid) { for (var i = 0; i < PL.length; i++) if (PL[i][0] === uid) return PL[i][1]; return '?'; }
function others(noBots) { return PL.filter(function (p) { return !(p[4] & 32) && !(noBots && (p[4] & 64)); }); }
function ago(ts) { var s = Math.max(0, Math.floor(Date.now() / 1000) - ts), tr = D.lang === 'tr'; if (s < 60) return s + 's'; if (s < 3600) return Math.floor(s / 60) + (tr ? 'dk' : 'm'); return Math.floor(s / 3600) + (tr ? 'sa' : 'h'); }
function prow(p, right) {
  var tr = D.lang === 'tr', team = p[2] === 2 ? (tr ? 'Zombi' : 'Zombie') : p[2] === 1 ? (tr ? 'Insan' : 'Human') : (tr ? 'Izleyici' : 'Spec');
  return '<div class="prow"><div><div class="pa2" style="' + avaColor(p[3]) + '">' + esc(initials(p[1])) + '</div></div><div class="pn"><b>' + esc(p[1]) + (p[4] & 4 ? ' <span class="lvchip">ADM</span>' : '') + (p[4] & 1 ? ' <span class="lvchip fr">&#9733;</span>' : '') + '</b><small>Lv ' + p[3] + ' &middot; ' + esc(team) + '</small></div><div class="pr">' + right + '</div></div>';
}
function offMsg() { return '<p class="muted off">' + esc(D.lang === 'tr' ? 'Canli baglanti kapali - oyunda /ipad yazarak ac.' : 'Live link is off - type /ipad in game.') + '</p>'; }
// ------------------------------------------------------------------ messages
var CHAT = 0;
R.msg = function () {
  var tr = D.lang === 'tr', h = '';
  if (CHAT) {
    var nm = plName(CHAT), list = MS.filter(function (m) { return m[0] === CHAT; });
    h += '<div class="chathdr"><span class="lnk" data-chat="0">&lsaquo; ' + esc(tr ? 'Sohbetler' : 'Chats') + '</span><b>' + esc(nm) + '</b></div><div class="bubbles">';
    if (!list.length) h += '<p class="muted" style="text-align:center;padding:20px 0">' + esc(tr ? 'Ilk mesaji sen yaz' : 'Say hi') + '</p>';
    list.forEach(function (m) { h += '<div class="bub ' + (m[4] ? 'out' : 'in') + '"><p>' + esc(m[2]) + '</p><small>' + ago(m[3]) + '</small></div>'; });
    h += '</div><div class="compose"><input id="msgIn" maxlength="110" placeholder="' + esc(tr ? 'Mesaj yaz...' : 'Message...') + '"><span class="gbtn get" data-send="' + CHAT + '">&#10148;</span></div>';
    return '<div class="chatwrap">' + h + '</div>';
  }
  var ppl = {};
  MS.forEach(function (m) { if (!ppl[m[0]] || ppl[m[0]][3] < m[3]) ppl[m[0]] = m; });
  var ids = Object.keys(ppl).sort(function (a, b) { return ppl[b][3] - ppl[a][3]; });
  h += card(tr ? 'Mesajlar' : 'Messages', ids.length ? ids.map(function (uid) { var m = ppl[uid]; return '<div class="chatrow" data-chat="' + uid + '"><div class="pa2" style="' + avaColor(0) + '">' + esc(initials(m[1])) + '</div><div class="ci"><b>' + esc(m[1]) + '</b><small>' + (m[4] ? (tr ? 'Sen: ' : 'You: ') : '') + esc(m[2]) + '</small></div><span class="t">' + ago(m[3]) + '</span></div>'; }).join('') : '<p class="muted">' + esc(tr ? 'Henuz mesaj yok. Oyuncular sekmesinden birine yaz.' : 'No messages yet. Message a player from the Players tab.') + '</p>');
  var pl = others(true);
  h += card(tr ? 'Oyuncular' : 'Players', pl.length ? pl.map(function (p) { return prow(p, p[4] & 2 ? '<span class="muted">&#128683;</span>' : '<span class="gbtn" data-chat="' + p[0] + '">' + esc(tr ? 'Yaz' : 'Chat') + '</span>'); }).join('') : '<p class="muted">' + esc(tr ? 'Baska oyuncu yok' : 'No other players') + '</p>');
  return (LIVE.on ? '' : offMsg()) + h;
};
// ------------------------------------------------------------------ friends
R.friends = function () {
  var tr = D.lang === 'tr', h = '';
  var reqs = others(true).filter(function (p) { return p[4] & 8; });
  if (reqs.length) h += card(tr ? 'Arkadaslik istekleri' : 'Friend requests', reqs.map(function (p) { return prow(p, '<span class="gbtn get" data-facc="' + p[0] + '">' + esc(tr ? 'Kabul' : 'Accept') + '</span>'); }).join(''));
  h += card(tr ? 'Arkadaslar' : 'Friends', FR.length ? FR.map(function (f) { return '<div class="prow"><div><div class="pa2 ' + (f[1] ? 'on' : 'off') + '" style="' + avaColor(0) + '">' + esc(initials(f[0])) + '</div></div><div class="pn"><b>' + esc(f[0]) + '</b><small>' + esc(f[1] ? (tr ? 'Cevrimici' : 'Online') : (tr ? 'Cevrimdisi' : 'Offline')) + '</small></div><div class="pr">' + (f[1] ? '<span class="gbtn" data-chat="' + f[1] + '">' + esc(tr ? 'Yaz' : 'Chat') + '</span>' : '') + '</div></div>'; }).join('') : '<p class="muted">' + esc(tr ? 'Henuz arkadasin yok' : 'No friends yet') + '</p>');
  var pl = others(true).filter(function (p) { return !(p[4] & 1) && !(p[4] & 8); });
  h += card(tr ? 'Oyuncu ekle' : 'Add players', pl.length ? pl.map(function (p) { return prow(p, (p[4] & 2) ? '<span class="rbtn" data-unblock="' + p[0] + '">' + esc(tr ? 'Engeli kaldir' : 'Unblock') + '</span>' : '<span class="gbtn" data-fadd="' + p[0] + '">+ ' + esc(tr ? 'Ekle' : 'Add') + '</span> <span class="rbtn" data-block="' + p[0] + '">' + esc(tr ? 'Engelle' : 'Block') + '</span>'); }).join('') : '<p class="muted">' + esc(tr ? 'Eklenecek oyuncu yok' : 'No players to add') + '</p>');
  return (LIVE.on ? '' : offMsg()) + h;
};
// ------------------------------------------------------------------ notifications
R.notif = function () {
  var tr = D.lang === 'tr';
  if (LIVE.tk) act('seen', '', '', '', null);
  var h = NT.length ? NT.slice().reverse().map(function (n) { return '<div class="ntf"><span class="ni">' + svg('bell') + '</span><div><b>' + esc(n[0]) + '</b><small>' + ago(n[1]) + '</small></div></div>'; }).join('') : '<p class="muted">' + esc(tr ? 'Bildirim yok' : 'No notifications') + '</p>';
  return card(tr ? 'Bildirimler' : 'Notifications', h);
};
// ------------------------------------------------------------------ trade (live)
var tradeSel = null;
R.trade = function () {
  var tr = D.lang === 'tr', h = '';
  var inc = OF.filter(function (o) { return o[5] === 1; }), out = OF.filter(function (o) { return o[5] === 0; });
  if (inc.length) h += card(tr ? 'Gelen teklifler' : 'Incoming offers', inc.map(function (o) { return '<div class="offer"><div class="oi">' + svg('trade') + '</div><div class="od"><b>' + esc(o[2]) + '</b><small>' + esc(tr ? 'Veriyor' : 'Gives') + ': ' + esc(itemName(o[3])) + (o[4] !== '-' ? ' &middot; ' + esc(tr ? 'Istiyor' : 'Wants') + ': ' + esc(itemName(o[4])) : ' &middot; ' + esc(tr ? 'Hediye' : 'Gift')) + '</small></div><div class="oa"><span class="gbtn get" data-tacc="' + o[0] + '">' + esc(tr ? 'Al' : 'Accept') + '</span><span class="rbtn" data-tdec="' + o[0] + '">' + esc(tr ? 'Red' : 'Decline') + '</span></div></div>'; }).join(''));
  if (out.length) h += card(tr ? 'Gonderdigin teklifler' : 'Your offers', out.map(function (o) { return '<div class="offer"><div class="oi">' + svg('trade') + '</div><div class="od"><b>' + esc(o[2]) + '</b><small>' + esc(itemName(o[3])) + (o[4] !== '-' ? ' &rarr; ' + esc(itemName(o[4])) : ' &middot; ' + esc(tr ? 'Hediye' : 'Gift')) + '</small></div><div class="oa"><span class="muted">' + esc(tr ? 'Bekliyor' : 'Pending') + '</span></div></div>'; }).join(''));
  h += card(tr ? 'Takas baslat' : 'Start a trade', '<p class="muted" style="margin-bottom:8px">' + esc(tr ? 'Bir esyani sec, sonra oyuncuyu sec. Karsi taraf tabletinden kabul eder.' : 'Pick one of your items, then a player. They accept on their tablet.') + '</p>' + tradePick());
  return (LIVE.on ? '' : offMsg()) + h;
};
function tradePick() {
  var tr = D.lang === 'tr', h = '<div class="tsel"><b>' + esc(tr ? '1) Esyan' : '1) Your item') + '</b><div class="trow">';
  var cats = ['k', 'c', 'w', 'p', 'f', 'z', 't'], any = false;
  cats.forEach(function (ct) { var n = catList(ct).length || 16; for (var i = 0; i < n; i++) { if (!((D.iv[ct] | 0) & (1 << i))) continue; var code = ct + (i + 1), on = tradeSel === code; any = true; h += '<span class="tchip' + (on ? ' on' : '') + '" data-tgive="' + code + '">' + esc(itemName(code)) + '</span>'; } });
  if (!any) h += '<span class="muted">' + esc(tr ? 'Takas edilecek esyan yok' : 'No items to trade') + '</span>';
  h += '</div></div>';
  if (tradeSel) {
    var pl = others(true);
    h += '<div class="tsel"><b>' + esc(tr ? '2) Kime' : '2) To whom') + ' (' + esc(itemName(tradeSel)) + ')</b><div>' + (pl.length ? pl.map(function (p) { return prow(p, '<span class="gbtn" data-toffer="' + p[0] + '">' + esc(tr ? 'Teklif et' : 'Offer') + '</span>'); }).join('') : '<p class="muted">' + esc(tr ? 'Oyuncu yok' : 'No players') + '</p>') + '</div></div>';
  }
  return h;
}
// ------------------------------------------------------------------ admin panel (live)
var admSel = 0, admTab = 'players';
R.adm = function () {
  var tr = D.lang === 'tr', founder = D.role >= 2;
  if (D.role < 1) return card('', '<p>' + esc(L('adminOnly')) + '</p>');
  var h = '<div class="admhello"><div class="pa2" style="' + avaColor(80) + '">' + esc(initials(D.name)) + '</div><div><b>' + esc(tr ? 'Hos geldin, ' : 'Welcome, ') + esc(D.name) + '</b><small>' + esc(founder ? (tr ? 'Kurucu - tam yetki' : 'Founder - full access') : (tr ? 'Admin' : 'Admin')) + '</small></div></div>';
  h += '<div class="tabs">' + [['players', tr ? 'Oyuncular' : 'Players'], ['server', tr ? 'Sunucu' : 'Server']].map(function (t) { return '<span class="tab' + (admTab === t[0] ? ' on' : '') + '" data-admtab="' + t[0] + '">' + esc(t[1]) + '</span>'; }).join('') + '</div>';
  if (admTab === 'server') {
    h += card(tr ? 'Sunucu islemleri' : 'Server actions', '<div class="admgrid">' +
      '<span class="abtn" data-adm="rr">' + svg('time') + (tr ? 'Round restart' : 'Round restart') + '</span>' +
      '<span class="abtn" data-adm="saynow">' + svg('bell') + (tr ? 'Duyuru yap' : 'Announce') + '</span></div>' +
      '<div class="admrow"><input id="admSay" maxlength="100" placeholder="' + esc(tr ? 'Duyuru metni...' : 'Announcement...') + '"></div>');
    h += card(tr ? 'Harita degistir' : 'Change map', '<div class="maps">' + (MAPS.length ? MAPS.map(function (m) { return '<span class="mchip" data-map="' + esc(m) + '">' + esc(m) + '</span>'; }).join('') : '<span class="muted">' + esc(tr ? 'Harita listesi yukleniyor...' : 'Loading maps...') + '</span>') + '</div>');
    return h;
  }
  var sel = admSel ? PL.filter(function (p) { return p[0] === admSel; })[0] : null;
  if (!sel) admSel = 0;
  h += card(tr ? 'Oyuncu sec' : 'Select a player', others(false).map(function (p) { return '<div class="prow' + (p[0] === admSel ? ' on' : '') + '" data-admp="' + p[0] + '"><div><div class="pa2" style="' + avaColor(p[3]) + '">' + esc(initials(p[1])) + '</div></div><div class="pn"><b>' + esc(p[1]) + (p[4] & 4 ? ' <span class="lvchip">ADM</span>' : '') + '</b><small>Lv ' + p[3] + ' &middot; ' + (p[2] === 2 ? (tr ? 'Zombi' : 'Zombie') : p[2] === 1 ? (tr ? 'Insan' : 'Human') : 'Spec') + '</small></div><div class="pr">' + (p[0] === admSel ? '&#10003;' : '') + '</div></div>'; }).join('') || '<p class="muted">' + esc(tr ? 'Oyuncu yok' : 'No players') + '</p>');
  if (sel) {
    var u = sel[0];
    h += card((tr ? 'Islem: ' : 'Action on: ') + sel[1], '<div class="admgrid">' +
      '<span class="abtn" data-adm="slay|' + u + '">' + svg('blade') + 'Slay</span>' +
      '<span class="abtn" data-adm="team|' + u + '">' + svg('users') + (tr ? 'Takim degis' : 'Swap team') + '</span>' +
      '<span class="abtn" data-adm="resp|' + u + '">' + svg('zup') + (tr ? 'Diril' : 'Respawn') + '</span>' +
      '<span class="abtn" data-adm="freeze|' + u + '">' + svg('time') + (tr ? 'Dondur' : 'Freeze') + '</span>' +
      '<span class="abtn" data-adm="kick|' + u + '">' + svg('dl') + 'Kick</span>' +
      (D.role >= 2 ? '<span class="abtn warn2" data-adm="ban|' + u + '|1440">' + svg('adm') + 'Ban 1g</span>' : '') + '</div>');
    if (founder) h += card(tr ? 'Hediye (kurucu)' : 'Gift (founder)', '<div class="admgrid">' +
      '<span class="abtn" data-adm="vc|' + u + '|1000">+1000 VC</span><span class="abtn" data-adm="vc|' + u + '|5000">+5000 VC</span>' +
      '<span class="abtn" data-adm="ap|' + u + '|500">+500 AP</span><span class="abtn" data-adm="vip|' + u + '|7">VIP 7g</span></div>');
  }
  return h;
};

document.addEventListener('click',function(){setTimeout(function(){colors(document);},0);});
IC.market=IC.trade;
R.market=function(){var h='<div class="marketintro"><b>'+tr('Oyuncu pazarı','Player market')+'</b><p>'+tr('Çevrimiçi oyuncuların eşyalarını VexCoin ile al. İlanlar harita ve bağlantı oturumu boyunca geçerlidir.','Buy online players’ items with VexCoin. Listings last for the map and connection session.')+'</p></div>';
var selected=MARKET.filter(function(m){return m[0]===MARKET_CONFIRM;})[0];if(selected)h+=card(tr('Satın almayı onayla','Confirm purchase'),'<p>'+esc(itemName(selected[3]))+' · <b>'+fmt(selected[4])+' VC</b></p><div style="margin-top:12px"><button class="gbtn" data-marketconfirm="1">'+tr('Satın al','Confirm')+'</button> <button class="tchip" data-marketabort="1">'+tr('Vazgeç','Cancel')+'</button></div>');
var own='';['k','c','w','p','f','t','z'].forEach(function(c){catList(c).forEach(function(x,i){if((D.iv[c]||0)&(1<<i)){var code=c+(i+1);own+='<button class="tchip '+(MARKET_CODE===code?'on':'')+'" data-marketcode="'+code+'">'+esc(itemName(code))+'</button>';}});});
h+=card(tr('Satışa koy','Create listing'),'<div class="marketitems">'+(own||esc(tr('Satılabilir eşyan yok.','No tradable items.')))+'</div><div class="marketform"><input id="marketPrice" type="number" min="1" max="100000000" value="100" aria-label="VexCoin"><span>VC</span><button class="gbtn" data-marketlist="1" '+(MARKET_CODE?'':'disabled')+'>'+tr('İlan oluştur','List item')+'</button></div>');
var cards=MARKET.map(function(m){var mine=m[1]===LIVE.uid;return '<div class="marketcard"><div class="marketicon">'+svg('inv')+'</div><div class="marketdetail"><b>'+esc(itemName(m[3]))+'</b><small>'+esc(m[2])+'</small><strong>'+fmt(m[4])+' VC</strong></div><button class="gbtn" '+(mine?'data-marketcancel':'data-marketbuy')+'="'+m[0]+'">'+tr(mine?'Kaldır':'Satın al',mine?'Cancel':'Buy')+'</button></div>';}).join('');return h+card(tr('Aktif ilanlar','Active listings'),cards||'<p class="muted">'+tr('Henüz ilan yok.','No listings yet.')+'</p>');};
var oldSettings622=R.set;R.set=function(){return oldSettings622()+card(tr('Canlı bağlantı','Live connection'),'<div class="linkhealth"><p>'+tr('Veri dosyası: ','Data file: ')+(LIVE.fileOk?tr('doğrulandı','validated'):esc(LIVE.dataError||tr('bekleniyor','waiting')))+'</p><p>'+tr('Komut akışı: ','Command stream: ')+(LIVE.ready?tr('hazır','ready'):tr('henüz doğrulanmadı','not confirmed'))+'</p><p>PAD 6.2.4 · protokol 624</p><p>'+tr('Son dosya: ','Last file: ')+esc('state624_'+LIVE.tk+'.js')+'</p><button class="gbtn get" data-linktest="1">'+tr('Bağlantıyı sına','Test connection')+'</button></div>');};
// Drag the content, preserving clicks until a movement threshold is crossed.
(function(){var drag=null,suppress=0,inertia=0;document.addEventListener('mousedown',function(e){if(e.button!==0)return;inertia++;var el=e.target;if(/^(INPUT|TEXTAREA|SELECT|CANVAS)$/.test(el.tagName))return;while(el&&el!==document.body){if(el.scrollHeight>el.clientHeight+4&&(el.id==='appBody'||el.className==='hbody'||String(el.className).indexOf('hbody ')===0||el.className==='bubbles')){drag={el:el,y:e.clientY,last:e.clientY,t:Date.now(),v:0,moved:false};break;}el=el.parentNode;}},false);
document.addEventListener('mousemove',function(e){if(!drag)return;var dy=e.clientY-drag.last,dt=Math.max(1,Date.now()-drag.t);if(Math.abs(e.clientY-drag.y)>6)drag.moved=true;if(drag.moved){clearTimeout(LP.t);drag.el.scrollTop-=dy;drag.v=-dy/dt;drag.last=e.clientY;drag.t=Date.now();e.preventDefault();}},false);
document.addEventListener('mouseup',function(){if(!drag)return;var d=drag;drag=null;if(!d.moved)return;suppress=Date.now()+120;var epoch=++inertia,appEpoch=EPOCH,last=Date.now();function step(){if(appEpoch!==EPOCH||epoch!==inertia||Math.abs(d.v)<.03||!document.body.contains(d.el))return;var now=Date.now(),prev=d.el.scrollTop;d.el.scrollTop+=d.v*Math.min(32,now-last);last=now;d.v*=.88;if(d.el.scrollTop===prev)return;requestAnimationFrame(step);}requestAnimationFrame(step);},false);
document.addEventListener('click',function(e){if(Date.now()<suppress){e.preventDefault();e.stopImmediatePropagation();}},true);})();
// ------------------------------------------------------------------ boot
applyTheme(); applyAccent(); applyBright(); setWall(); $('screen').className = 'screen locked'; $('lockLogo').innerHTML = LOGO(); $('lockHint').textContent = L('unlock');
$('lockNote').textContent = D.claimed ? '' : L('dailyReady');
$('demo').style.display='none';
renderHome(); clock(); setInterval(clock, 10000);
$('home').className = 'home hide';
if (GAMES.indexOf(D.page)>=0)D.page='home';
if (D.page && D.page !== 'home') { $('lock').className = 'lock off'; $('screen').className = 'screen'; $('home').className = 'home'; openApp(D.page, true); }
else { setTimeout(function () { SND.drone(); }, 400); }
})();
