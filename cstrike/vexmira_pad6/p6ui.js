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
function store(k,v){if(v!==undefined){MEM[k]=String(v);try{localStorage.setItem('vx4_'+k,v);}catch(e){}return MEM[k];}if(Object.prototype.hasOwnProperty.call(MEM,k))return MEM[k];try{return MEM[k]=localStorage.getItem('vx4_'+k);}catch(e){return null;}}

var PREFK=['lang','theme','acc','br','wp','snd','ntf'];
(function(){var m=/[#&]pf=([^&]*)/.exec(location.hash||'');if(!m)return;var v=m[1].split('*');for(var i=0;i<PREFK.length;i++)if(v[i]!==undefined&&v[i]!=='')store(PREFK[i],PREFK[i]==='acc'?'#'+v[i]:v[i]);})();
function prefStr(){return PREFK.map(function(k){var v=store(k);v=v==null?'':String(v);if(k==='acc')v=v.replace('#','');return v.replace(/[^A-Za-z0-9.\-]/g,'');}).join('*');}
var PREF_T=null;function savePref(){clearTimeout(PREF_T);PREF_T=setTimeout(function(){if(LIVE&&LIVE.on&&LIVE.tk)sendRaw('pref',prefStr());},700);}
// ------------------------------------------------------------------ data
function parseHash() {
  var h = (location.hash || '').replace(/^#/, ''), o = {};
  if (!h) return null;
  h.split('&').forEach(function (p) { var i = p.indexOf('='); if (i > 0) o[p.slice(0, i)] = p.slice(i + 1); });
  return o;
}
function dec(s) { try { return decodeURIComponent(s || ''); } catch (e) { return s || ''; } }
var RAW = parseHash(), DEMO = !RAW || !RAW.n || !RAW.tk || RAW.tk.length < 8 || !(+RAW.uid > 0) || !RAW.rt; // only a server-made address opens the tablet
if(DEMO){try{history.replaceState(null,'',location.pathname);}catch(e){}RAW={l:'tr',n:'',pg:'home'};}
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
  tr: { home: 'Ana Ekran', hello: 'Hoş geldin', unlock: 'Kilidi açmak için dokun', prof: 'Profil', top: 'Top 15', time: 'Süre Sıralaması', ach: 'Başarımlar', achtop: 'Başarım Top', inv: 'Envanter',
    'case': 'Kasalar', daily: 'Günlük Ödül', zup: 'Zombi Gelişim', trade: 'Takas', set: 'Ayarlar', adm: 'Yönetim', about: 'Hakkında', level: 'Seviye', kills: 'Öldürme', infs: 'Enfeksiyon',
    deaths: 'Ölüm', hs: 'Kafa', wins: 'Galibiyet', boss: 'Boss', play: 'Oynama', hours: 'saat', min: 'dk', rank: 'Sıralama', type: 'Oyunda yaz', steam: 'Steam profili', online: 'çevrimiçi',
    map: 'Harita', round: 'Round', vipDays: 'VIP: {0} gün kaldı', dailyReady: 'Günlük ödülün hazır!', dailyWait: 'Sıradaki ödül: {0}', newAch: 'Başarım', you: 'Sen', name: 'Oyuncu', val: 'Değer',
    noData: 'Henüz kayıt yok', unlocked: 'açıldı', locked: 'kilitli', owned: 'sahip', equipped: 'TAKILI', all: 'Tümü', knives: 'Bıçaklar', skins: 'Karakterler', wings: 'Kanatlar', pets: 'Petler',
    kfx: 'Öldürme Efekti', lasers: 'Lazerler', trails: 'İzler', chances: 'Düşme ihtimalleri', open: 'Kasa aç', opening: 'Kasa açılıyor...', got: 'Kazandın', dup: 'Zaten vardı: VC iade edildi',
    rar: ['Sıradan', 'Nadir', 'Destansı', 'Efsanevi', 'Mitik'], day: 'Gün', streak: 'Seri', claim: 'Ödülünü al', claimed: 'Bugünkü ödül alındı', points: 'Puan', current: 'Şu anki sınıfın',
    zupHow: 'Zombiyken insan enfekte et (+1) ya da öldür (+2). Seviye atladıkça yeteneklerin güçlenir.', tradeHow: 'Takas sistemi: sunucudaki bir oyuncuyu seç, vereceğin eşyayı seç; karşı taraf ya kendi eşyasını verir ya da hediye olarak kabul eder. Tüm takaslar kayıt altındadır.',
    theme: 'Tema', dark: 'Karanlık', light: 'Aydınlık', sound: 'Sesler', notif: 'Bildirimler', lang: 'Dil', wall: 'Duvar kağıdı', adminOnly: 'Bu bölüm sadece yönetim içindir.',
    founder: 'Kurucu işlemleri', uptime: 'Çalışma süresi', players: 'Oyuncu', cmds: 'Komutlar', credit: 'Tablet ve mod', back: 'Geri', demo: 'Örnek veriler gösteriliyor', vipDrop: 'VIP sadece Kabus Kasasından düşük ihtimalle çıkar',
    updated: 'Güncellendi: {0} dk önce', store: 'App Store', game: 'Vex Kanat', get: 'AL', openB: 'AÇ', remove: 'Kaldır', installed: 'Yüklü', installing: 'Yükleniyor', featured: 'Günün Uygulaması',
    exitHint: 'Sağ tik: geri  |  Çıkmak için: ESC / Tamam', tapStart: 'Başlamak için tıkla', best: 'En iyi', score: 'Skor', over: 'Oyun bitti', core: 'Sistem uygulaması',
    d_prof: 'Seviyen, istatistiklerin, Steam profilin', d_top: 'Sunucunun en iyi 15 oyuncusu', d_time: 'En çok oynayanlar', d_ach: '30 başarım ve ödülleri', d_achtop: 'Başarım yarışması', d_inv: 'Bıçak, kanat, pet ve efektlerin',
    d_case: 'Kasa aç, efsanevi eşya kazan', d_daily: '7 günlük ödül serisi', d_zup: 'Zombi sınıflarını geliştir', d_trade: 'Oyuncularla eşya takası', d_game: 'Boruların arasından uç, rekor kır', d_set: 'Tema, ses, duvar kağıdı', d_adm: 'Yönetim paneli', d_about: 'Vexmira hakkında', d_store: 'Uygulama indir' },
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
  guide: 'Rehber', cmds: 'Komutlar', music: 'Müzik', notes: 'Notlar', calc: 'Hesap Makinesi', snake: 'Vex Yılan', g2048: 'Vex 2048', whack: 'Zombi Avı', games: 'Oyunlar',
  d_guide: 'Modlar, zombi sınıfları, ipuçları', d_cmds: 'Tüm sohbet komutları tek yerde', d_music: 'Korku atmosferi müzikleri', d_notes: 'Kendi notların', d_calc: 'Hızlı hesap', d_snake: 'Klasik yılan, karanlık temada', d_g2048: 'Kutuları birleştir, 2048e ulaş', d_whack: '30 saniyede en çok zombiyi vur',
  cc: 'Kontrol Merkezi', accent: 'Vurgu rengi', bright: 'Parlaklık', edit: 'Ana ekranı düzenle', done: 'Bitti', custom: 'Özelleştir', wpNames: ['Kızıl Sis', 'Uçurum', 'Zehir', 'Altıgen', 'Kor', 'Mor Şafak', 'Gece Mavisi', 'Vexmira'],
  cat_games: 'Oyunlar', cat_tools: 'Araçlar', cat_server: 'Sunucu', cat_social: 'Sosyal',
  msg: 'Mesajlar', friends: 'Arkadaşlar', notif: 'Bildirimler', adm: 'Yönetim', d_msg: 'Oyuncularla mesajlaş', d_friends: 'Arkadaş ekle, engelle', d_notif: 'Tüm bildirimlerin', d_adm: 'Yönetim paneli', top3: 'En iyiler', np: 'Şimdi çalıyor', tracks: ['Karanlık Koridor', 'Kalp Atisi', 'Kanlı Yagmur', 'Sisli Gece'], stop: 'Durdur',
  modes: 'Oyun Modları', classes: 'Zombi Sınıfları', tips: 'İpuçları', notesPh: 'Buraya yaz... (otomatik kaydedilir)', timeLeft: 'Süre', start: 'Başla', again: 'Tekrar', hint2048: 'Ok tuşları ile kaydır', hintSnake: 'Ok tuşları / WASD ile yonlendir',
  widgetHint: 'Düzenlemek için bir simgeye basılı tut', xp: 'XP'
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
  var css = ((window.VXCSS || '') + (window.VXFIXCSS || '') + (window.VXIOSCSS || '')).replace(/var\(--([a-z0-9]+)\)/g, function (m, k) { return vals[k] != null ? vals[k] : m; });
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
    ['top', 'time', 'achtop'].map(function (m) { return '<span class="tab' + (m === mode ? ' on' : '') + '" data-top="' + m + '">' + esc(m === 'top' ? 'Top 15' : m === 'time' ? (D.lang === 'tr' ? 'Süre' : 'Time') : L('ach')) + '</span>'; }).join('') + '</div></div>';
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
  return card(L('set'), h) + card(L('wall'), w) + '<div class="cce" data-app="about" style="margin:0 0 12px">' + svg('about') + esc(L('about')) + '</div>' + card('', '<p class="muted">' + (D.lang === 'tr' ? 'Oyun içi ayarlar' : 'In-game settings') + '</p>' + cmd(D.lang === 'tr' ? '/ayarlar  /dil  /stil' : '/settings  /lang  /style'));
};
R.adm = function () {
  if (D.role < 1) return card('', '<p>' + esc(L('adminOnly')) + '</p>');
  var h = card('', '<div class="stats">' + stat(Math.floor(D.up / 60) + ' ' + L('hours') + ' ' + (D.up % 60) + ' ' + L('min'), L('uptime')) + stat(D.svp + '/' + D.mx, L('players')) + stat(D.map, L('map')) + stat(D.round, L('round')) + '</div>');
  var a = [['amx_menu', D.lang === 'tr' ? 'oyuncu işlemleri' : 'player actions'], ['/yonetim', D.lang === 'tr' ? 'Vexmira yönetim menüsü (modlar, boss, event)' : 'Vexmira admin menu (modes, boss, events)'], ['amx_kick <isim>', 'kick'], ['amx_ban <isim> <dk>', 'ban'], ['amx_slay <isim>', 'slay'], ['amx_map <harita>', D.lang === 'tr' ? 'harita değiştir' : 'change map'], ['vex_plan', D.lang === 'tr' ? 'bu haritanın round planı' : "this map's round plan"], ['vex_fastdl_files', 'FastDL']];
  h += card(L('cmds'), '<div class="cmds">' + a.map(function (x) { return '<div><p><b>' + esc(x[0]) + '</b>' + esc(x[1]) + '</p></div>'; }).join('') + '</div>');
  if (D.role >= 2) {
    var f = [['vex_reset_top', D.lang === 'tr' ? 'Top15 sıfırla' : 'reset Top15'], ['vex_reset_time', D.lang === 'tr' ? 'sure sıralamasını sıfırla' : 'reset playtime top'], ['vex_reset_ach', D.lang === 'tr' ? 'başarım sıralamasını sıfırla' : 'reset achievement top'],
      ['vex_give_vc <isim> <miktar>', 'VexCoin'], ['vex_give_ap <isim> <miktar>', 'AP'], ['vex_give_ach <isim> <0-29>', L('ach')], ['vex_give_case <isim> <0-3>', L('case')], ['vex_vip_add <isim> <gun> <1|2>', 'VIP / ELITE'], ['vex_boss_build', D.lang === 'tr' ? 'dev boss dosyalari' : 'giant boss files']];
    h += card(L('founder'), '<div class="warn">' + (D.lang === 'tr' ? 'Bu işlemler geri alınamaz. Konsoldan (rcon) çalıştır.' : 'These actions cannot be undone. Run them from the console (rcon).') + '</div><div class="cmds">' + f.map(function (x) { return '<div><p><b>' + esc(x[0]) + '</b>' + esc(x[1]) + '</p></div>'; }).join('') + '</div>');
  }
  return h;
};
R.about = function () { return card('', '<div class="about"><div class="lg">' + LOGO() + '</div><p><b>VEXMIRA</b> &middot; PAD 4.0</p><p class="muted" style="margin:6px 0">' + esc(L('credit')) + ': <b style="color:var(--acc)">smurfsexy</b></p><p class="muted">' + esc(D.map) + ' &middot; ' + esc(L('round')) + ' ' + esc(D.round) + '</p>' + (D.ts ? '<p class="muted">' + esc(F('updated', Math.max(0, Math.round((Date.now() / 1000 - D.ts) / 60)))) + '</p>' : '') + '</div>'); };

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
  h += card(L('classes'), '<div class="zchips">' + zc.map(function (n) { return '<span>' + esc(n) + '</span>'; }).join('') + '</div>' + cmd(tr('/sınıf', '/class')));
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
  var h = '<div class="hello nohi"><h1></h1><div class="hact">' +
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
    tile('ntf', 'bell', notifOn, L('notif'), notifOn ? 'ON' : 'OFF') + tile(D.lang === 'tr' ? 'en' : 'tr', 'globe', true, L('lang'), D.lang === 'tr' ? 'Türkçe' : 'English') + '</div>';
  h += '<div class="ccs"><i>' + svg('bright') + '</i><input id="ccBr" type="range" min="45" max="100" value="' + br + '"></div>';
  h += '<div class="ccl">' + esc(L('accent')) + '</div><div class="ccacc">' + ACCS.map(function (c) { return '<span data-acc="' + c + '" class="' + (c === acc ? 'on' : '') + '" style="background:' + c + '"></span>'; }).join('') + '</div>';
  h += '<div class="ccl">' + esc(L('wall')) + '</div><div class="ccwp">' + L('wpNames').map(function (n, i) { return '<div class="wpt' + (i === WP ? ' on' : '') + '" data-wp="' + i + '"><div class="w wp' + i + '">' + (i === 7 ? emblem() : '') + '<small>' + esc(n) + '</small></div></div>'; }).join('') + '</div>';
  if (MUS.i >= 0) h += '<div class="ccm"><i style="' + grad('music') + '">' + svg('music') + '</i><div><small>' + esc(L('np')) + '</small><b>' + esc(L('tracks')[MUS.i]) + '</b></div><span class="gbtn" data-ui="mstop">' + esc(L('stop')) + '</span></div>';
  h += '<div class="cce" data-ui="edit">' + svg('grid') + esc(L('edit')) + '</div></div>';
  return h;
}
function openCC() { overlay('cc', ccHtml()); var r = $('ccBr'); if (r) r.addEventListener('input', function () { store('br', r.value); applyBright();savePref(); }); SND.open(); }
function refreshCC() { var o = $('cc'); if (o && o.className.indexOf('show') >= 0) { o.innerHTML = ccHtml(); var r = $('ccBr'); if (r) r.addEventListener('input', function () { store('br', r.value); applyBright(); }); } }
function setWall() { var w = $('wall'); w.className = 'wall wp' + WP + (cur ? ' blur' : ''); w.innerHTML = ''; }
function openApp(a, noSound) {
  if (!R[a]) a = 'prof'; closeOv('fold'); closeOv('cc'); EDIT = false; cur = a;
  stopGame();
  $('appTitle').textContent = L(a); $('appIco').style.cssText = grad(a); $('appIco').innerHTML = svg(a);
  $('backTxt').textContent = L('home'); $('appRight').textContent = D.role >= 2 ? (D.lang === 'tr' ? 'Kurucu' : 'Founder') : D.role === 1 ? 'Admin' : '';
  $('appBody').innerHTML = R[a](); $('appBody').scrollTop = 0; $('appBody').className = 'app-body' + (GAMES.indexOf(a) >= 0 || a === 'calc' || a === 'notes' ? ' full' : '');
  $('app').className = 'app open'; $('home').className = 'home hide'; setWall();
  if (!noSound) SND.open();
  if (a === 'case') runReel();
  wantData(a);
  if(STARTERS[a]){var epoch=EPOCH;setTimeout(function(){if(epoch!==EPOCH||cur!==a)return;try{STARTERS[a]();}catch(e){stopGame();toast(tr('Oyun başlatılamadı. Ana ekrana dönebilirsin.','Game could not start. You can return home.'),false);}},30);} colors($('appBody'));
}
function goHome() { stopGame(); closeOv('fold'); closeOv('cc'); var was = cur; cur = null; $('app').className = 'app'; $('home').className = 'home'; setWall(); if (was) SND.close(); renderHome(); }
function rerender() { stopGame(); applyTheme(); applyAccent(); renderHome(); if (cur) { $('appBody').innerHTML = R[cur](); $('appTitle').textContent = L(cur); $('backTxt').textContent = L('home'); if (STARTERS[cur]) STARTERS[cur](); colors($('appBody')); } $('lockHint').textContent = L('unlock'); clock(); refreshCC(); }
function unlock(page) { if (DEMO) return; var lk = $('lock'); if (lk.className.indexOf('off') >= 0) return; lk.className = 'lock off'; $('screen').className = 'screen'; $('home').className = 'home'; SND.unlock(); if (page && page !== 'home') openApp(page, true); notifications(); }
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
  var el = findAttr(e.target, ['data-rm', 'data-get', 'data-open', 'data-ui', 'data-fold', 'data-app', 'data-tab', 'data-top', 'data-case', 'data-openc', 'data-daily', 'data-eq', 'data-set', 'data-wp', 'data-acc', 'data-mus', 'data-calc', 'data-dir', 'data-hole', 'data-gs', 'data-chat', 'data-send', 'data-fadd', 'data-facc', 'data-fdel', 'data-block', 'data-unblock', 'data-toffer', 'data-tgive', 'data-tacc', 'data-tdec', 'data-admtab', 'data-admp', 'data-adm', 'data-map','data-zperk','data-achclaim','data-marketcode','data-mktab','data-mkcat','data-mkstep','data-mkpick','data-marketlist','data-marketbuy','data-marketcancel','data-marketconfirm','data-marketabort','data-linktest','data-x4']);
  if (!el) {
    var t = e.target;
    if (t && t.className && typeof t.className === 'string' && t.className.indexOf('ov ') === 0) { closeOv(t.id); if (t.id === 'cc') SND.close(); }
    else if (EDIT && !cur && !findAttr(e.target, ['data-app'])) { EDIT = false; renderHome(); }
    return;
  }
  var v;
  if(el.getAttribute('data-linktest')!==null){act('ping');return;}
  if((v=el.getAttribute('data-x4'))!==null){var kv=v.split('=');X4[kv[0]]=kv[1];x4re();SND.click();return;}
  if((v=el.getAttribute('data-mktab'))!==null){MK_TAB=v;MARKET_CONFIRM=0;mkRender(true);return;}
  if((v=el.getAttribute('data-mkcat'))!==null){MK_CAT=v;mkRender(false);return;}
  if((v=el.getAttribute('data-mkpick'))!==null){MARKET_CODE=MARKET_CODE===v?'':v;mkRender(false);return;}
  if((v=el.getAttribute('data-mkstep'))!==null){var pi=$('marketPrice');MK_PRICE=Math.max(1,Math.min(100000000,(v.charAt(0)==='='?num(v.slice(1)):num(pi?pi.value:MK_PRICE)+num(v))));mkRender(false);return;}
  if((v=el.getAttribute('data-achclaim'))!==null){act('claimach',num(v));return;}
  if((v=el.getAttribute('data-marketcode'))!==null){MARKET_CODE=v;mkRender(false);return;}
  if((v=el.getAttribute('data-marketlist'))!==null){var price=$('marketPrice');if(price)MK_PRICE=num(price.value,MK_PRICE);if(MARKET_CODE&&price){if(!/^[0-9]{1,9}$/.test(price.value)){toast(tr('Fiyat pozitif bir tam sayı olmalı.','Price must be a positive integer.'),false);return;}act('marketlist',MARKET_CODE,price.value);}return;}
  if((v=el.getAttribute('data-marketbuy'))!==null){MARKET_CONFIRM=num(v);mkRender(false);return;}
  if((v=el.getAttribute('data-marketconfirm'))!==null){if(act('marketbuy',MARKET_CONFIRM)){MARKET_CONFIRM=0;mkRender(false);}return;}
  if((v=el.getAttribute('data-marketabort'))!==null){MARKET_CONFIRM=0;mkRender(false);return;}
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
  if (el.getAttribute('data-daily') !== null) { act('daily', '', '', '', D.lang === 'tr' ? '/günlük' : '/daily'); SND.click(); return; }
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
    var q = v.split('|');
    if (q[0] === 'reset') { var w = num(q[1]); if (RESET_ARM !== w || Date.now() - RESET_T > 5000) { RESET_ARM = w; RESET_T = Date.now(); SND.tick(); x5render(); return; } RESET_ARM = -1; act('adm', 'reset', w, '', null); x5render(); return; }
    act('adm', q[0], q[1] || '', q[2] || '', null); return;
  }
  if ((v = el.getAttribute('data-calc')) !== null) { SND.tick(); calcKey(v); return; }
  if ((v = el.getAttribute('data-mus')) !== null) { v = num(v); if (MUS.i === v) musStop(); else musPlay(v); $('appBody').innerHTML = R.music(); musViz(); return; }
  SND.click();
  if ((v = el.getAttribute('data-top'))) { $('appBody').innerHTML = leader(v); return; }
  if ((v = el.getAttribute('data-tab'))) { invTab = v; $('appBody').innerHTML = R[cur](); return; }
  if ((v = el.getAttribute('data-case')) !== null) { caseSel = num(v); var keep = D.cr; D.cr = null; $('appBody').innerHTML = R['case'](); D.cr = keep; return; }
  if ((v = el.getAttribute('data-wp')) !== null) { WP = num(v) % 8; store('wp', WP);savePref(); setWall(); if (cur === 'set') $('appBody').innerHTML = R.set(); refreshCC(); return; }
  if ((v = el.getAttribute('data-acc')) !== null) { store('acc', v); applyAccent();savePref(); refreshCC(); if (cur === 'set') $('appBody').innerHTML = R.set(); return; }
  if ((v = el.getAttribute('data-set'))) {
    if (v === 'dark' || v === 'light') {store('theme', v);savePref();}
    else if (v === 'snd') { soundOn = !soundOn; store('snd', soundOn ? '1' : '0');savePref(); }
    else if (v === 'ntf') { notifOn = !notifOn; store('ntf', notifOn ? '1' : '0');savePref(); }
    else if (v === 'tr' || v === 'en') { D.lang = v; store('lang', v);if(LIVE.on&&LIVE.tk)sendRaw('lang',v);savePref(); }
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
var MARKET=[],MARKET_CODE='',MARKET_CONFIRM=0,RESET_ARM=-1,RESET_T=0;
var LIVE = { tk: dec(RAW.tk), uid: num(RAW.uid), rt: dec(RAW.rt), rh: dec(RAW.rh), on: num(RAW.rl) === 1, seq: 0, pend: {}, fileOk: false, polls: 0, fast: 0, sent: 0, rx: 0, sse: 0 };
var PL = [], FR = [], MS = [], NT = [], OF = [], MAPS = [];
function hexs(str) { var u = unescape(encodeURIComponent(str)), h = ''; for (var i = 0; i < u.length; i++) { var c = u.charCodeAt(i).toString(16); h += (c.length < 2 ? '0' : '') + c; } return h; }
function nextSeq() { var s = Math.floor(Date.now() / 100) % 1000000000; if (s <= LIVE.seq) s = LIVE.seq + 1; LIVE.seq = s; return s; }
function toast(t, ok) { banner(ok === false ? (D.lang === 'tr' ? 'İşlem yapılamadı' : 'Action failed') : 'iPad', t, ok === false ? 'about' : 'bell', ok === false ? '#c8102e' : '#1f8a4c'); }
function relayBase(){return (location.protocol==='https:'?'https://':'http://')+LIVE.rh.replace(location.protocol==='https:'?/:80$/:/$^/,'')+'/'+LIVE.rt;}
// One GET "image beacon" per command (ntfy publish endpoint). The game server listens on the same
// topic and runs the command; the fresh data comes back inside the tablet address (#hash).
function beacon(msg){var url=relayBase()+'/publish?message='+encodeURIComponent(msg)+'&title=vx&cache=no&t='+Date.now();LIVE.sent++;try{var x=new XMLHttpRequest();x.open('GET',url,true);x.onreadystatechange=function(){if(x.readyState!==4)return;if(x.status>=200&&x.status<300)LIVE.okSend=Date.now();else if(x.status===429)LIVE.rate=Date.now();else{var img=new Image();img.src=url;}};x.send();}catch(e){var img=new Image();img.src=url;}}
// SHA-256 (UTF-8). Commands are signed with the player's secret key; the key itself never leaves the tablet.
function sha256(m){m=unescape(encodeURIComponent(m));var K=[],H=[],i,j,P=2;function fr(x){return (x-Math.floor(x))*4294967296|0;}
for(i=0;i<64;P++){for(j=2;j*j<=P;j++)if(P%j===0)break;if(j*j>P){if(i<8)H[i]=fr(Math.pow(P,1/2));K[i++]=fr(Math.pow(P,1/3));}}
var l=m.length,w=[],W=new Array(64),a,b,c,d,e,f,g,h,t1,t2;m+='\x80';while(m.length%64!==56)m+='\x00';
for(i=0;i<m.length;i++)w[i>>2]|=m.charCodeAt(i)<<(24-(i%4)*8);w.push(0);w.push(l*8|0);
function R(x,n){return (x>>>n)|(x<<(32-n));}
for(j=0;j<w.length;j+=16){a=H[0];b=H[1];c=H[2];d=H[3];e=H[4];f=H[5];g=H[6];h=H[7];
for(i=0;i<64;i++){if(i<16)W[i]=w[j+i]|0;else W[i]=(R(W[i-2],17)^R(W[i-2],19)^(W[i-2]>>>10))+W[i-7]+(R(W[i-15],7)^R(W[i-15],18)^(W[i-15]>>>3))+W[i-16]|0;
t1=h+(R(e,6)^R(e,11)^R(e,25))+((e&f)^(~e&g))+K[i]+W[i]|0;t2=(R(a,2)^R(a,13)^R(a,22))+((a&b)^(a&c)^(b&c))|0;h=g;g=f;f=e;e=d+t1|0;d=c;c=b;b=a;a=t1+t2|0;}
H[0]=H[0]+a|0;H[1]=H[1]+b|0;H[2]=H[2]+c|0;H[3]=H[3]+d|0;H[4]=H[4]+e|0;H[5]=H[5]+f|0;H[6]=H[6]+g|0;H[7]=H[7]+h|0;}
var o='';for(i=0;i<8;i++)o+=('00000000'+(H[i]>>>0).toString(16)).slice(-8);return o;}
function clean5(v){return v==null?'':String(v).replace(/[~\r\n\t]/g,' ').replace(/[\uD800-\uDFFF]/g,'');}
function sendRaw(name,a,b,c){if(!LIVE.on||!LIVE.tk||!LIVE.rt||!LIVE.uid)return 0;var s=nextSeq(),body=[LIVE.uid,s,name,clean5(a),clean5(b),clean5(c)].join('~');beacon('vx2~'+body+'~'+sha256(LIVE.tk+'|'+body).slice(0,20));return s;}
// Every action shows its result on the tablet at once (see the PAD5/PAD6 block); the server only
// confirms in the background. A refusal from the server shows a short note and the data is corrected.
function act(name, a, b, c, cmdHint) {
  if (!LIVE.on || !LIVE.tk || !LIVE.rt) { toast(tr('Tablet oyundan açılmadı. Oyunda /ipad yaz.','Open the tablet in game with /ipad.'), false); return 0; }
  var now=Date.now();for(var pk in LIVE.pend)if(now-LIVE.pend[pk].t>30000)delete LIVE.pend[pk];
  var s=sendRaw(name,a,b,c);if(!s)return 0;LIVE.pend[s]={name:name,hint:cmdHint,t:now,quiet:1};store('pend',s+'~'+name+'~'+now);
  return s;
}
function busy(on) { var b = $('busy'); if (!b) { b = document.createElement('div'); b.id = 'busy'; b.className = 'busy'; b.innerHTML = '<i class="ring"></i>'; $('screen').appendChild(b); } b.style.display = on ? 'block' : 'none'; }
// ---- data from the tablet address (sent by the server on open and after every action)
function rows(s,f){if(!s)return [];return String(s).split(';').filter(function(r){return r!=='';}).map(function(r){return f(r.split('~'));});}
function hashU(o){
  var has=function(k){return Object.prototype.hasOwnProperty.call(o,k);},u={me:num(o.uid),ack:num(o.ack),res:dec(o.res),ap:num(o.ap),vc:num(o.vc),lv:num(o.lv,1),xp:num(o.xp),xn:num(o.xn,1),un:num(o.un),dy:dec(o.dy),iv:dec(o.iv),eq:dec(o.eq),enabled:num(o.rl),link:num(o.lk),map:dec(o.mp),round:dec(o.rd),mx:num(o.mx,32),pg:dec(o.pg)};
  if(has('l'))u.lang=o.l==='en'?'en':'tr';
  var st=String(o.st||'').split('.');u.stats={k:num(st[0]),inf:num(st[1]),d:num(st[2]),hs:num(st[3]),w:num(st[4]),b:num(st[5]),pt:num(st[6]),vip:num(st[7]),vd:num(st[8]),rank:num(st[9]),ach:num(st[10]),on:num(o.on),role:num(o.r)};
  if(has('cm'))u.claimed=num(o.cm);if(has('ar')){var ar=String(o.ar).split('~');u.achReward=[num(ar[0]),num(ar[1])];}
  if(has('dl'))u.daily=rows(o.dl,function(c){return [num(c[0]),num(c[1]),num(c[2])];});if(has('dn'))u.dn=num(o.dn);
  if(has('zu'))u.zup=String(o.zu).split(';').map(function(r){var c=r.split('~'),out=[];for(var i=0;i<6;i++)out.push(num(c[i]));return out;});
  if(has('t'))u.top=rows(o.t,function(c){return {n:dec(c[0]),lv:num(c[1]),k:num(c[2])};});
  if(has('tt'))u.tt=rows(o.tt,function(c){return {n:dec(c[0]),v:num(c[1])};});
  if(has('at'))u.at=rows(o.at,function(c){return {n:dec(c[0]),v:num(c[1])};});
  if(has('mk'))u.market=rows(o.mk,function(c){return [num(c[0]),num(c[1]),dec(c[2]),c[3],num(c[4])];});
  if(has('ms'))u.ms=rows(o.ms,function(c){return [num(c[0]),dec(c[1]),dec(c[2]),num(c[3]),num(c[4])];});
  if(has('nt'))u.nt=rows(o.nt,function(c){return [dec(c[0]),num(c[1])];});
  if(has('fr'))u.fr=rows(o.fr,function(c){return [dec(c[0]),num(c[1])];});
  if(has('of'))u.of=rows(o.of,function(c){return [num(c[0]),num(c[1]),dec(c[2]),c[3],c[4],num(c[5])];});
  if(has('pl'))u.pl=rows(o.pl,function(c){return [num(c[0]),dec(c[1]),num(c[2]),num(c[3]),num(c[4])];});
  if(has('maps'))u.maps=String(o.maps).split(';').filter(function(x){return x;});
  return u;
}
var GOT={};
function takeHash(first){
  var o=parseHash();if(!o||!o.n)return;var u=hashU(o);if(u.pg)GOT[u.pg]=Date.now();
  // result of the action that triggered this update (also when the page was reloaded)
  var pend=String(store('pend')||'').split('~'),pseq=num(pend[0]);
  if(pseq&&u.ack>=pseq&&!LIVE.pend[pseq])LIVE.pend[pseq]={name:pend[1]||'',t:Date.now()};
  if(pseq&&u.ack>=pseq)store('pend','');
  LIVE.fileOk=true;applyU(u);
}
window.addEventListener('hashchange',function(){takeHash(false);},false);
// ---- live replies: the open MOTD window ignores new addresses, so the server answers on this tablet's
// own relay channel (<topic>_<token>). EventSource push; polling fallback for old browsers.
function hashStr(str){var o={};String(str||'').replace(/^#/,'').split('&').forEach(function(p){var i=p.indexOf('=');if(i>0)o[p.slice(0,i)]=p.slice(i+1);});return o;}
function takeReply(str){var o=hashStr(str);if(!o.n||(o.tk&&dec(o.tk)!==LIVE.tk))return;var u=hashU(o);if(u.pg)GOT[u.pg]=Date.now();LIVE.fileOk=true;LIVE.rx++;if(u.ack){var pend=String(store('pend')||'').split('~');if(num(pend[0])&&u.ack>=num(pend[0]))store('pend','');}applyU(u);}
function replyUrl(kind){return relayBase()+'_'+LIVE.tk+'/'+kind;}
function listen(){
  if(DEMO||!LIVE.on||!LIVE.tk||!LIVE.rt)return;
  if(window.EventSource){try{var es=new EventSource(replyUrl('sse'));LIVE.es=es;
    es.onopen=function(){LIVE.sse=1;linkDot();};
    es.onmessage=function(e){var d;try{d=JSON.parse(e.data);}catch(x){return;}if(d.event&&d.event!=='message')return;if(d.id)LIVE.lastId=d.id;takeReply(d.message||'');};
    es.onerror=function(){LIVE.sse=0;linkDot();};
    return;}catch(err){}}
  (function poll(){var x;try{x=new XMLHttpRequest();x.open('GET',replyUrl('json')+'?poll=1&since='+(LIVE.lastId||Math.floor(Date.now()/1000)-2),true);x.onreadystatechange=function(){if(x.readyState!==4)return;if(x.status===200)String(x.responseText||'').split('\n').forEach(function(l){if(!l)return;try{var d=JSON.parse(l);if(d.event==='message'){LIVE.lastId=d.id;takeReply(d.message);}}catch(e){}});};x.send();}catch(e){}
    var busyNow=false;for(var k in LIVE.pend)busyNow=true;setTimeout(poll,busyNow?900:3000);})();
}
var NEED=['msg','friends','notif','trade','adm','zup','market','top','time','achtop'];
function wantData(a){if(NEED.indexOf(a)<0||DEMO)return;if(GOT[a]&&Date.now()-GOT[a]<15000)return;sendRaw('view',a);}
function buildStatus624(){var b=$('build624');if(b)b.textContent='PAD 6.0 · '+(LIVE.fileOk?(LIVE.ready?tr('CANLI','LIVE'):tr('VERİ VAR','DATA OK')):tr('/ipad ile aç','open with /ipad'));}
function linkDot() { buildStatus624(); var d = $('linkDot'); if (d) {d.title=LIVE.fileOk?(LIVE.ready?tr('Sunucu bağlantısı hazır','Server link ready'):tr('Veri okunuyor, komut bağlantısı bekleniyor','Reading data; waiting for command link')):tr('Canlı veri dosyası okunamıyor','Live data file unavailable'); d.className = 'ldot ' + (LIVE.fileOk ? (LIVE.ready ? 'g' : 'y') : 'r'); } }
function typing() { var a = document.activeElement; return a && (a.tagName === 'INPUT' || a.tagName === 'TEXTAREA'); }
var HOME_SIG='', LIVE_SIG='';
var REEL_RUN = false;
function applyU(u) {
  if(u.me&&LIVE.uid&&u.me!==LIVE.uid)return;if(u.pl)D.on=u.pl.length;if(u.lang&&u.lang!==D.lang&&!store('lang')){D.lang=u.lang;applyTheme();}if(u.enabled!==undefined)LIVE.on=u.enabled===1;LIVE.ready=u.link===1;linkDot();
  if(u.map)D.map=u.map;if(u.round)D.round=u.round;if(u.mx)D.mx=u.mx;if(u.claimed!==undefined)D.claimedMask=u.claimed|0;if(u.achReward)D.achReward=u.achReward;if(u.market)MARKET=u.market;if(u.zup)D.zup=u.zup;if(u.daily)D.rewards=u.daily;if(u.dn)D.dailyNext=u.dn;if(u.top)D.top=u.top;if(u.tt)D.tt=u.tt;if(u.at)D.at=u.at;if(u.stats)for(var stat in u.stats)if(Object.prototype.hasOwnProperty.call(D,stat))D[stat]=u.stats[stat];
  D.ap = u.ap; D.vc = u.vc; D.lv = u.lv; D.xp = u.xp; D.xn = u.xn; D.iv = masks(u.iv); D.eq = masks(u.eq);
  var dy = String(u.dy).split('~'); D.streak = num(dy[0]); D.claimed = num(dy[1]) === 1; D.next = num(dy[2]);
  if(u.pl)PL=u.pl;if(u.fr)FR=u.fr;if(u.ms)MS=u.ms;if(u.nt)NT=u.nt;if(u.of)OF=u.of;if(u.maps)MAPS=u.maps;D.un = u.un | 0;
  if (u.me) LIVE.uid = u.me;
  var acked = false;
  for (var k in LIVE.pend) if (num(k) <= u.ack) { acked = LIVE.pend[k]; delete LIVE.pend[k]; }
  if (acked) { busy(false); var rs=String(u.res || ''); if(!acked.quiet||rs.indexOf('ok~')!==0||rs.indexOf('ok~case')===0) onResult(acked.name, rs); }
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
  var M = {ping:tr?'Sunucudan cevap alındı':'Server replied',market:tr?'Pazar işlemi tamamlandı':'Market action complete',claimach:tr?'Başarım ödülü alındı':'Achievement reward claimed', daily: tr ? 'Günlük ödül alındı' : 'Daily reward claimed', equip: tr ? 'Kuşanıldı' : 'Equipped', msg: tr ? 'Mesaj gönderildi' : 'Message sent',
    fadd: tr ? 'Arkadaşlık isteği gönderildi' : 'Friend request sent', facc: tr ? 'Arkadaş eklendi' : 'Friend added', fdel: tr ? 'Arkadaş silindi' : 'Friend removed',
    block: tr ? 'Engellendi' : 'Blocked', unblock: tr ? 'Engel kalktı' : 'Unblocked', trade: tr ? 'Takas teklifi gönderildi' : 'Trade offer sent',
    tacc: tr ? 'Takas tamamlandı' : 'Trade complete', tdec: tr ? 'Teklif reddedildi' : 'Offer declined', adm: tr ? 'Yönetim işlemi uygulandı' : 'Admin action done',
    rr: tr ? 'Round yeniden başlıyor' : 'Round restarting', map: tr ? 'Harita değişiyor' : 'Map changing', say: tr ? 'Duyuru gönderildi' : 'Announcement sent' };
  if (p[1] !== 'seen' && p[1] !== 'ping') toast(M[p[1]] || M[name] || 'OK', true);
  if (name === 'daily'||name==='claimach') SND.win(2);
}
// ------------------------------------------------------------------ list helpers
function plName(uid) { for (var i = 0; i < PL.length; i++) if (PL[i][0] === uid) return PL[i][1]; return '?'; }
function others(noBots) { return PL.filter(function (p) { return !(p[4] & 32) && !(noBots && (p[4] & 64)); }); }
function ago(ts) { var s = Math.max(0, Math.floor(Date.now() / 1000) - ts), tr = D.lang === 'tr'; if (s < 60) return s + 's'; if (s < 3600) return Math.floor(s / 60) + (tr ? 'dk' : 'm'); return Math.floor(s / 3600) + (tr ? 'sa' : 'h'); }
function prow(p, right) {
  var tr = D.lang === 'tr', team = p[2] === 2 ? (tr ? 'Zombi' : 'Zombie') : p[2] === 1 ? (tr ? 'İnsan' : 'Human') : (tr ? 'İzleyici' : 'Spec');
  return '<div class="prow"><div><div class="pa2" style="' + avaColor(p[3]) + '">' + esc(initials(p[1])) + '</div></div><div class="pn"><b>' + esc(p[1]) + (p[4] & 4 ? ' <span class="lvchip">ADM</span>' : '') + (p[4] & 1 ? ' <span class="lvchip fr">&#9733;</span>' : '') + '</b><small>Lv ' + p[3] + ' &middot; ' + esc(team) + '</small></div><div class="pr">' + right + '</div></div>';
}
function offMsg() { return '<p class="muted off">' + esc(D.lang === 'tr' ? 'Canlı bağlantı kapalı - oyunda /ipad yazarak aç.' : 'Live link is off - type /ipad in game.') + '</p>'; }
// ------------------------------------------------------------------ messages
var CHAT = 0;
R.msg = function () {
  var tr = D.lang === 'tr', h = '';
  if (CHAT) {
    var nm = plName(CHAT), list = MS.filter(function (m) { return m[0] === CHAT; });
    h += '<div class="chathdr"><span class="lnk" data-chat="0">&lsaquo; ' + esc(tr ? 'Sohbetler' : 'Chats') + '</span><b>' + esc(nm) + '</b></div><div class="bubbles">';
    if (!list.length) h += '<p class="muted" style="text-align:center;padding:20px 0">' + esc(tr ? 'İlk mesajı sen yaz' : 'Say hi') + '</p>';
    list.forEach(function (m) { h += '<div class="bub ' + (m[4] ? 'out' : 'in') + '"><p>' + esc(m[2]) + '</p><small>' + ago(m[3]) + '</small></div>'; });
    h += '</div><div class="compose"><input id="msgIn" maxlength="110" placeholder="' + esc(tr ? 'Mesaj yaz...' : 'Message...') + '"><span class="gbtn get" data-send="' + CHAT + '">&#10148;</span></div>';
    return '<div class="chatwrap">' + h + '</div>';
  }
  var ppl = {};
  MS.forEach(function (m) { if (!ppl[m[0]] || ppl[m[0]][3] < m[3]) ppl[m[0]] = m; });
  var ids = Object.keys(ppl).sort(function (a, b) { return ppl[b][3] - ppl[a][3]; });
  h += card(tr ? 'Mesajlar' : 'Messages', ids.length ? ids.map(function (uid) { var m = ppl[uid]; return '<div class="chatrow" data-chat="' + uid + '"><div class="pa2" style="' + avaColor(0) + '">' + esc(initials(m[1])) + '</div><div class="ci"><b>' + esc(m[1]) + '</b><small>' + (m[4] ? (tr ? 'Sen: ' : 'You: ') : '') + esc(m[2]) + '</small></div><span class="t">' + ago(m[3]) + '</span></div>'; }).join('') : '<p class="muted">' + esc(tr ? 'Henüz mesaj yok. Oyuncular sekmesinden birine yaz.' : 'No messages yet. Message a player from the Players tab.') + '</p>');
  var pl = others(true);
  h += card(tr ? 'Oyuncular' : 'Players', pl.length ? pl.map(function (p) { return prow(p, p[4] & 2 ? '<span class="muted">&#128683;</span>' : '<span class="gbtn" data-chat="' + p[0] + '">' + esc(tr ? 'Yaz' : 'Chat') + '</span>'); }).join('') : '<p class="muted">' + esc(tr ? 'Başka oyuncu yok' : 'No other players') + '</p>');
  return (LIVE.on ? '' : offMsg()) + h;
};
// ------------------------------------------------------------------ friends
R.friends = function () {
  var tr = D.lang === 'tr', h = '';
  var reqs = others(true).filter(function (p) { return p[4] & 8; });
  if (reqs.length) h += card(tr ? 'Arkadaşlık istekleri' : 'Friend requests', reqs.map(function (p) { return prow(p, '<span class="gbtn get" data-facc="' + p[0] + '">' + esc(tr ? 'Kabul' : 'Accept') + '</span>'); }).join(''));
  h += card(tr ? 'Arkadaşlar' : 'Friends', FR.length ? FR.map(function (f) { return '<div class="prow"><div><div class="pa2 ' + (f[1] ? 'on' : 'off') + '" style="' + avaColor(0) + '">' + esc(initials(f[0])) + '</div></div><div class="pn"><b>' + esc(f[0]) + '</b><small>' + esc(f[1] ? (tr ? 'Çevrimiçi' : 'Online') : (tr ? 'Çevrimdışı' : 'Offline')) + '</small></div><div class="pr">' + (f[1] ? '<span class="gbtn" data-chat="' + f[1] + '">' + esc(tr ? 'Yaz' : 'Chat') + '</span>' : '') + '</div></div>'; }).join('') : '<p class="muted">' + esc(tr ? 'Henüz arkadaşın yok' : 'No friends yet') + '</p>');
  var pl = others(true).filter(function (p) { return !(p[4] & 1) && !(p[4] & 8); });
  h += card(tr ? 'Oyuncu ekle' : 'Add players', pl.length ? pl.map(function (p) { return prow(p, (p[4] & 2) ? '<span class="rbtn" data-unblock="' + p[0] + '">' + esc(tr ? 'Engeli kaldır' : 'Unblock') + '</span>' : '<span class="gbtn" data-fadd="' + p[0] + '">+ ' + esc(tr ? 'Ekle' : 'Add') + '</span> <span class="rbtn" data-block="' + p[0] + '">' + esc(tr ? 'Engelle' : 'Block') + '</span>'); }).join('') : '<p class="muted">' + esc(tr ? 'Eklenecek oyuncu yok' : 'No players to add') + '</p>');
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
  if (inc.length) h += card(tr ? 'Gelen teklifler' : 'Incoming offers', inc.map(function (o) { return '<div class="offer"><div class="oi">' + svg('trade') + '</div><div class="od"><b>' + esc(o[2]) + '</b><small>' + esc(tr ? 'Veriyor' : 'Gives') + ': ' + esc(itemName(o[3])) + (o[4] !== '-' ? ' &middot; ' + esc(tr ? 'İstiyor' : 'Wants') + ': ' + esc(itemName(o[4])) : ' &middot; ' + esc(tr ? 'Hediye' : 'Gift')) + '</small></div><div class="oa"><span class="gbtn get" data-tacc="' + o[0] + '">' + esc(tr ? 'Al' : 'Accept') + '</span><span class="rbtn" data-tdec="' + o[0] + '">' + esc(tr ? 'Red' : 'Decline') + '</span></div></div>'; }).join(''));
  if (out.length) h += card(tr ? 'Gönderdiğin teklifler' : 'Your offers', out.map(function (o) { return '<div class="offer"><div class="oi">' + svg('trade') + '</div><div class="od"><b>' + esc(o[2]) + '</b><small>' + esc(itemName(o[3])) + (o[4] !== '-' ? ' &rarr; ' + esc(itemName(o[4])) : ' &middot; ' + esc(tr ? 'Hediye' : 'Gift')) + '</small></div><div class="oa"><span class="muted">' + esc(tr ? 'Bekliyor' : 'Pending') + '</span></div></div>'; }).join(''));
  h += card(tr ? 'Takas başlat' : 'Start a trade', '<p class="muted" style="margin-bottom:8px">' + esc(tr ? 'Bir eşyanı seç, sonra oyuncuyu seç. Karşı taraf tabletinden kabul eder.' : 'Pick one of your items, then a player. They accept on their tablet.') + '</p>' + tradePick());
  return (LIVE.on ? '' : offMsg()) + h;
};
function tradePick() {
  var tr = D.lang === 'tr', h = '<div class="tsel"><b>' + esc(tr ? '1) Eşyan' : '1) Your item') + '</b><div class="trow">';
  var cats = ['k', 'c', 'w', 'p', 'f', 'z', 't'], any = false;
  cats.forEach(function (ct) { var n = catList(ct).length || 16; for (var i = 0; i < n; i++) { if (!((D.iv[ct] | 0) & (1 << i))) continue; var code = ct + (i + 1), on = tradeSel === code; any = true; h += '<span class="tchip' + (on ? ' on' : '') + '" data-tgive="' + code + '">' + esc(itemName(code)) + '</span>'; } });
  if (!any) h += '<span class="muted">' + esc(tr ? 'Takas edilecek eşyan yok' : 'No items to trade') + '</span>';
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
  var h = '<div class="admhello"><div class="pa2" style="' + avaColor(80) + '">' + esc(initials(D.name)) + '</div><div><b>' + esc(tr ? 'Hoş geldin, ' : 'Welcome, ') + esc(D.name) + '</b><small>' + esc(founder ? (tr ? 'Kurucu - tam yetki' : 'Founder - full access') : (tr ? 'Admin' : 'Admin')) + '</small></div></div>';
  h += '<div class="tabs">' + [['players', tr ? 'Oyuncular' : 'Players'], ['server', tr ? 'Sunucu' : 'Server']].map(function (t) { return '<span class="tab' + (admTab === t[0] ? ' on' : '') + '" data-admtab="' + t[0] + '">' + esc(t[1]) + '</span>'; }).join('') + '</div>';
  if (admTab === 'server') {
    h += card(tr ? 'Sunucu işlemleri' : 'Server actions', '<div class="admgrid">' +
      '<span class="abtn" data-adm="rr">' + svg('time') + (tr ? 'Round restart' : 'Round restart') + '</span>' +
      '<span class="abtn" data-adm="saynow">' + svg('bell') + (tr ? 'Duyuru yap' : 'Announce') + '</span></div>' +
      '<div class="admrow"><input id="admSay" maxlength="100" placeholder="' + esc(tr ? 'Duyuru metni...' : 'Announcement...') + '"></div>');
    if (founder) {
      var RS = [[4, tr ? 'Top 15' : 'Top 15'], [0, tr ? 'Oynama süresi' : 'Playtime'], [2, tr ? 'Başarımlar' : 'Achievements'], [1, tr ? 'İstatistikler' : 'Stats'], [5, tr ? 'Tüm sıralamalar' : 'All leaderboards'], [3, tr ? 'Günlük ödüller' : 'Daily rewards']];
      h += card(tr ? 'Herkes için sıfırla (sadece kurucu)' : 'Reset for everyone (founder only)', '<div class="admgrid rsgrid">' + RS.map(function (r) { var arm = RESET_ARM === r[0] && Date.now() - RESET_T < 5000; return '<span class="abtn rsbtn' + (arm ? ' arm' : '') + '" data-adm="reset|' + r[0] + '">' + svg('about') + esc(arm ? (tr ? 'Emin misin? Tekrar dokun' : 'Sure? Tap again') : r[1]) + '</span>'; }).join('') + '</div><p class="muted">' + esc(tr ? 'Oyunda olmayanlar da girişte sıfırlanır. Geri alınamaz.' : 'Offline players are reset when they join. Cannot be undone.') + '</p>');
    }
    h += card(tr ? 'Harita değiştir' : 'Change map', '<div class="maps">' + (MAPS.length ? MAPS.map(function (m) { return '<span class="mchip" data-map="' + esc(m) + '">' + esc(m) + '</span>'; }).join('') : '<span class="muted">' + esc(tr ? 'Harita listesi yükleniyor...' : 'Loading maps...') + '</span>') + '</div>');
    return h;
  }
  var sel = admSel ? PL.filter(function (p) { return p[0] === admSel; })[0] : null;
  if (!sel) admSel = 0;
  h += card(tr ? 'Oyuncu seç' : 'Select a player', others(false).map(function (p) { return '<div class="prow' + (p[0] === admSel ? ' on' : '') + '" data-admp="' + p[0] + '"><div><div class="pa2" style="' + avaColor(p[3]) + '">' + esc(initials(p[1])) + '</div></div><div class="pn"><b>' + esc(p[1]) + (p[4] & 4 ? ' <span class="lvchip">ADM</span>' : '') + '</b><small>Lv ' + p[3] + ' &middot; ' + (p[2] === 2 ? (tr ? 'Zombi' : 'Zombie') : p[2] === 1 ? (tr ? 'İnsan' : 'Human') : 'Spec') + '</small></div><div class="pr">' + (p[0] === admSel ? '&#10003;' : '') + '</div></div>'; }).join('') || '<p class="muted">' + esc(tr ? 'Oyuncu yok' : 'No players') + '</p>');
  if (sel) {
    var u = sel[0];
    h += card((tr ? 'İşlem: ' : 'Action on: ') + sel[1], '<div class="admgrid">' +
      '<span class="abtn" data-adm="slay|' + u + '">' + svg('blade') + 'Slay</span>' +
      '<span class="abtn" data-adm="team|' + u + '">' + svg('users') + (tr ? 'Takım değiş' : 'Swap team') + '</span>' +
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
var MK_TAB='shop',MK_CAT='all',MK_PRICE=250;
var MK_CATS=['k','c','w','p','f','t','z'];
var MK_META={k:['Bıçak','Knife'],c:['Karakter','Skin'],w:['Kanat','Wings'],p:['Pet','Pet'],f:['Öldürme efekti','Kill FX'],t:['İz','Trail'],z:['Lazer','Laser']};
var MK_ICO={k:'<path d="M3 21l7-7"/><path d="M9.5 14.5l9-9c1.6 2.4 1.2 5.6-.9 7.7l-4.6 4.6z"/>',c:'<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4-6 8-6s7 2 8 6"/>',w:'<path d="M12 10C9 6 5 4.5 2 5.5c1 5 4.5 8 10 8.5 5.5-.5 9-3.5 10-8.5-3-1-7 .5-10 4.5z"/><path d="M12 10v9"/>',p:'<circle cx="7.5" cy="8" r="2"/><circle cx="16.5" cy="8" r="2"/><circle cx="4.5" cy="13" r="1.8"/><circle cx="19.5" cy="13" r="1.8"/><path d="M12 12.5c-3 0-5 3.2-5 5.2 0 1.8 2 2.8 5 2.8s5-1 5-2.8c0-2-2-5.2-5-5.2z"/>',f:'<path d="M12 2l2.4 7.2L22 12l-7.6 2.6L12 22l-2.4-7.4L2 12l7.6-2.8z"/>',t:'<path d="M3 17c4 0 4.5-10 9-10s5 10 9 10"/><path d="M3 21h18" opacity=".5"/>',z:'<path d="M2 12h17"/><circle cx="3" cy="12" r="1.6"/><path d="M16 7l5 5-5 5"/>'};
var MK_RAR=[['#8e8e93','#3a3a3c'],['#30d158','#0f3d1c'],['#0a84ff','#0b2c55'],['#bf5af2','#3a1450'],['#ff9f0a','#4d2c00']];
function mkRar(code){var l=catList(code.charAt(0)),it=l[num(code.slice(1))-1];return it&&it.r!=null?Math.max(0,Math.min(4,num(it.r))):0;}
function mkIcon(code,size){var c=code.charAt(0),r=MK_RAR[mkRar(code)];return '<span class="mkic" style="width:'+size+'px;height:'+size+'px;background:-webkit-linear-gradient(135deg,'+r[0]+','+r[1]+');background:linear-gradient(135deg,'+r[0]+','+r[1]+')"><svg viewBox="0 0 24 24">'+(MK_ICO[c]||MK_ICO.k)+'</svg></span>';}
function mkRarName(code){var n=(T[D.lang]&&T[D.lang].rar)||T.tr.rar;return n[mkRar(code)]||'';}
function mkOwned(){var o=[];MK_CATS.forEach(function(c){catList(c).forEach(function(x,i){if((D.iv[c]||0)&(1<<i))o.push(c+(i+1));});});return o;}
function mkRender(top){var b=$('appBody');if(!b||cur!=='market')return;var st=b.scrollTop;b.innerHTML=R.market();colors(b);b.scrollTop=top?0:st;}
R.market=function(){
  var tr2=function(a,b){return D.lang==='tr'?a:b;},mine=MARKET.filter(function(m){return m[1]===LIVE.uid;}),shop=MARKET.filter(function(m){return m[1]!==LIVE.uid;});
  var h='<div class="mk"><div class="mkhero"><div class="mkhl"><span class="mkapp">'+svg('market')+'</span><div><h1>'+tr2('Pazar','Market')+'</h1><p>'+tr2('Oyuncular arası VexCoin pazarı','Player-to-player VexCoin market')+'</p></div></div><div class="mkbal"><small>'+tr2('Bakiyen','Balance')+'</small><b>'+fmt(D.vc)+' <i>VC</i></b></div></div>';
  h+='<div class="mkseg">'+[['shop',tr2('Vitrin','Browse'),shop.length],['sell',tr2('Satış yap','Sell'),0],['mine',tr2('İlanlarım','My listings'),mine.length]].map(function(t){return '<span class="'+(MK_TAB===t[0]?'on':'')+'" data-mktab="'+t[0]+'">'+esc(t[1])+(t[2]?' <em>'+t[2]+'</em>':'')+'</span>';}).join('')+'</div>';
  function chips(list){var cnt={all:list.length};list.forEach(function(code){var c=code.charAt(0);cnt[c]=(cnt[c]||0)+1;});return '<div class="mkchips">'+['all'].concat(MK_CATS).filter(function(c){return c==='all'||cnt[c];}).map(function(c){return '<span class="'+(MK_CAT===c?'on':'')+'" data-mkcat="'+c+'">'+(c==='all'?'':'<svg viewBox="0 0 24 24">'+MK_ICO[c]+'</svg>')+esc(c==='all'?tr2('Tümü','All'):MK_META[c][D.lang==='tr'?0:1])+' <em>'+cnt[c]+'</em></span>';}).join('')+'</div>';}
  if(MK_TAB==='shop'){
    var codes=shop.map(function(m){return m[3];});if(MK_CAT!=='all'&&codes.join(',').indexOf(MK_CAT)<0)MK_CAT='all';
    h+=chips(codes);
    var list=shop.filter(function(m){return MK_CAT==='all'||m[3].charAt(0)===MK_CAT;});
    h+=list.length?'<div class="mkgrid">'+list.map(function(m){var poor=D.vc<m[4];return '<div class="mkc"><div class="mktop">'+mkIcon(m[3],52)+'<span class="mkr" style="color:'+MK_RAR[mkRar(m[3])][0]+'">'+esc(mkRarName(m[3]))+'</span></div><b class="mkn">'+esc(itemName(m[3]))+'</b><small class="mkm">'+esc(MK_META[m[3].charAt(0)]?MK_META[m[3].charAt(0)][D.lang==='tr'?0:1]:'')+'</small><div class="mks"><span class="mka" style="'+avaColor(m[1])+'">'+esc(initials(m[2]))+'</span>'+esc(m[2])+'</div><div class="mkf"><b>'+fmt(m[4])+' <i>VC</i></b><button class="mkbuy'+(poor?' dis':'')+'" '+(poor?'disabled':'data-marketbuy="'+m[0]+'"')+'>'+esc(poor?tr2('Yetersiz','Too pricey'):tr2('Satın al','Buy'))+'</button></div></div>';}).join('')+'</div>'
      :'<div class="mkempty">'+mkIcon('k1',64)+'<b>'+tr2('Vitrin şu an boş','Nothing for sale yet')+'</b><p>'+tr2('Çevrimiçi oyuncular eşya koyduğunda burada görünür. İlk ilanı sen ver!','Items appear here when online players list them. Be the first!')+'</p><button class="mkbtn" data-mktab="sell">'+tr2('Satış yap','Sell an item')+'</button></div>';
  } else if(MK_TAB==='sell'){
    var own=mkOwned();if(MK_CAT!=='all'&&own.join(',').indexOf(MK_CAT)<0)MK_CAT='all';
    h+=chips(own);
    var ol=own.filter(function(code){return MK_CAT==='all'||code.charAt(0)===MK_CAT;});
    h+=ol.length?'<div class="mkpick">'+ol.map(function(code){return '<div class="mkp'+(MARKET_CODE===code?' on':'')+'" data-mkpick="'+code+'">'+mkIcon(code,44)+'<b>'+esc(itemName(code))+'</b><small style="color:'+MK_RAR[mkRar(code)][0]+'">'+esc(mkRarName(code))+'</small>'+(MARKET_CODE===code?'<span class="mkok">✓</span>':'')+'</div>';}).join('')+'</div>'
      :'<div class="mkempty">'+mkIcon('w1',64)+'<b>'+tr2('Satılabilir eşyan yok','No items to sell')+'</b><p>'+tr2('Kasa açarak ya da mağazadan eşya kazan.','Win items from cases or the shop.')+'</p><button class="mkbtn" data-app="case">'+tr2('Kasalara git','Open cases')+'</button></div>';
    if(ol.length){var sel=MARKET_CODE;h+='<div class="mkprice"><div class="mkpl"><small>'+tr2('Seçilen eşya','Selected item')+'</small><b>'+esc(sel?itemName(sel):tr2('Yukarıdan bir eşya seç','Pick an item above'))+'</b></div><div class="mkstep"><span data-mkstep="-100">−</span><input id="marketPrice" type="number" min="1" max="100000000" value="'+MK_PRICE+'"><span data-mkstep="100">+</span><i>VC</i></div><div class="mkq">'+[100,250,500,1000,2500].map(function(q){return '<span class="'+(MK_PRICE===q?'on':'')+'" data-mkstep="='+q+'">'+fmt(q)+'</span>';}).join('')+'</div><button class="mkbtn big'+(sel?'':' dis')+'" '+(sel?'data-marketlist="1"':'disabled')+'>'+tr2('İlana koy','List for sale')+'</button><p class="mknote">'+tr2('İlanlar sen çevrimiçiyken görünür · en fazla 8 ilan · satış olunca bildirim gelir','Listings show while you are online · max 8 · you get a notification on sale')+'</p></div>';}
  } else {
    h+=mine.length?'<div class="mklist">'+mine.map(function(m){return '<div class="mkrow">'+mkIcon(m[3],44)+'<div class="mkrd"><b>'+esc(itemName(m[3]))+'</b><small>'+fmt(m[4])+' VC · '+esc(mkRarName(m[3]))+'</small></div><button class="mkcancel" data-marketcancel="'+m[0]+'">'+tr2('Kaldır','Remove')+'</button></div>';}).join('')+'</div>'
      :'<div class="mkempty">'+mkIcon('p1',64)+'<b>'+tr2('Aktif ilanın yok','No active listings')+'</b><p>'+tr2('Satış yap sekmesinden bir eşya listele.','List an item from the Sell tab.')+'</p><button class="mkbtn" data-mktab="sell">'+tr2('Satış yap','Sell an item')+'</button></div>';
  }
  var sel2=MARKET.filter(function(m){return m[0]===MARKET_CONFIRM;})[0];
  if(sel2)h+='<div class="mksheet"><div class="mksh">'+mkIcon(sel2[3],64)+'<b>'+esc(itemName(sel2[3]))+'</b><small>'+esc(sel2[2])+' · '+esc(mkRarName(sel2[3]))+'</small><div class="mkshp"><span>'+tr2('Fiyat','Price')+'</span><b>'+fmt(sel2[4])+' VC</b></div><div class="mkshp"><span>'+tr2('Sonra kalan','Balance after')+'</span><b>'+fmt(D.vc-sel2[4])+' VC</b></div><button class="mkbtn big" data-marketconfirm="1">'+tr2('Satın al','Buy now')+'</button><button class="mkbtn big ghost" data-marketabort="1">'+tr2('Vazgeç','Cancel')+'</button></div></div>';
  return h+'</div>';
};
var oldSettings622=R.set;R.set=function(){var ok=LIVE.fileOk&&!DEMO;return oldSettings622()+card(tr('Canlı bağlantı','Live connection'),'<div class="linkhealth"><p><span class="ldot '+(ok?(LIVE.ready?'g':'y'):'r')+'"></span> '+(ok?tr('Oyun verisi sunucudan geldi','Game data received from the server'):tr('Oyun verisi yok – tableti oyunda /ipad ile aç','No game data – open the tablet in game with /ipad'))+'</p><p>'+tr('Komut kanalı: ','Command channel: ')+(LIVE.ready?tr('sunucu dinliyor','server listening'):tr('sunucu bağlanıyor','server connecting'))+' · '+tr('gönderilen: ','sent: ')+LIVE.sent+'</p><p>'+tr('Cevap kanalı: ','Reply channel: ')+(LIVE.sse?tr('bağlı','connected'):tr('bağlanıyor','connecting'))+' · '+tr('alınan: ','received: ')+LIVE.rx+'</p><p class="muted">VEXMIRA PAD 6.0</p><button class="gbtn get" data-linktest="1">'+tr('Bağlantıyı sına','Test connection')+'</button></div>');};
// ------------------------------------------------------------------ PAD 6.0: every app in the iPadOS style of the Market app
// (large-title hero, segmented controls, inset grouped lists, card grids). Same data and the same actions as before.
var X4={achf:'all',trt:'',zf:'all'};
IC.coin='<circle cx="12" cy="12" r="8.5"/><path d="M14.8 9.2c-.6-.9-1.6-1.4-2.8-1.4-1.6 0-2.8.8-2.8 2.1 0 2.9 5.8 1.5 5.8 4.3 0 1.3-1.3 2.2-3 2.2-1.3 0-2.4-.6-3-1.5M12 6v1.8M12 16.4v1.8"/>';
IC.bolt='<path d="M13 2.5L4.5 13.5H11l-1 8 8.5-11H12z"/>';
IC.fire='<path d="M12 21.5c-4 0-6.5-2.7-6.5-6.2 0-3.7 2.9-5.6 3.6-9.8 2.4 1.5 3.4 3.6 3.4 5.4 1-.6 1.7-1.8 1.9-3.2 2.4 2 4.1 4.6 4.1 7.6 0 3.5-2.5 6.2-6.5 6.2z"/>';
IC.target='<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4"/><path d="M12 1.5v4M12 18.5v4M1.5 12h4M18.5 12h4"/>';
IC.skull='<path d="M12 3c-4.4 0-7.5 3-7.5 7.2 0 2.6 1.3 4.3 2.8 5.3V19h9.4v-3.5c1.5-1 2.8-2.7 2.8-5.3C19.5 6 16.4 3 12 3z"/><circle cx="9" cy="11" r="1.6"/><circle cx="15" cy="11" r="1.6"/><path d="M10.5 19v2M13.5 19v2"/>';
IC.crown='<path d="M3.5 18.5L2.5 7l5.5 4.5L12 4l4 7.5L21.5 7l-1 11.5z"/><path d="M3.5 18.5h17"/>';
IC.lock='<rect x="5" y="10.5" width="14" height="10" rx="2.2"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>';
IC.check='<path d="M5 12.5l4.5 4.5L19 7.5"/>';
IC.send='<path d="M3.5 11.5L20.5 4l-6.5 16.5-3-6.5z"/><path d="M11 14l9.5-10"/>';
IC.plus='<path d="M12 5v14M5 12h14"/>';
IC.link='<path d="M10 14a4.5 4.5 0 0 0 6.4 0l3-3a4.5 4.5 0 0 0-6.4-6.4l-1 1"/><path d="M14 10a4.5 4.5 0 0 0-6.4 0l-3 3a4.5 4.5 0 0 0 6.4 6.4l1-1"/>';
IC.paint='<circle cx="12" cy="12" r="8.5"/><circle cx="8.3" cy="10" r="1.3"/><circle cx="12" cy="7.6" r="1.3"/><circle cx="15.7" cy="10" r="1.3"/><path d="M13 16.5a2 2 0 1 1-2-2"/>';
IC.photo='<rect x="3" y="5" width="18" height="14" rx="2.5"/><circle cx="9" cy="10" r="1.8"/><path d="M3.5 17l5-4.5 4 3.5 3-2.5 5 4"/>';
IC.chart='<path d="M4 20.5V10M9.5 20.5V4M15 20.5v-7M20.5 20.5V8"/>';
IC.chev='<path d="M9.5 6l6 6-6 6"/>';
var X4C={red:'#ff6961,#c41a1f',orange:'#ffb340,#d46a00',yellow:'#ffe066,#d9a400',green:'#5be07f,#1f9a45',teal:'#5ee0d6,#118a8a',blue:'#5ab0ff,#0a5fd6',indigo:'#8e8cff,#3b35c9',purple:'#d18aff,#8a2bc9',pink:'#ff7aa8,#c8174f',gray:'#a3a8b2,#4b515c'};
function x4t(a,b){return D.lang==='tr'?a:b;}
function x4ic(k,col){var c=(X4C[col]||col||ICOL[k]||ICOL.about).split(',');return '<span class="x4i" style="'+lg(160,c[0],c[1])+'">'+svg(k)+'</span>';}
function x4hero(app,title,sub,right){return '<div class="x4h"><div class="x4hl"><span class="x4a" style="'+grad(app)+'">'+svg(app)+'</span><div class="x4ht"><h1>'+esc(title)+'</h1><p>'+esc(sub)+'</p></div></div>'+(right?'<div class="x4hr">'+right+'</div>':'')+'</div>';}
function x4bal(label,val,unit,col){return '<small>'+esc(label)+'</small><b style="color:'+(col||'#ffd60a')+'">'+esc(val)+(unit?' <i>'+esc(unit)+'</i>':'')+'</b>';}
function x4seg(items,attr,curv){return '<div class="mkseg">'+items.map(function(t){return '<span class="'+(curv===t[0]?'on':'')+'" '+attr+'="'+t[0]+'">'+esc(t[1])+(t[2]?' <em>'+t[2]+'</em>':'')+'</span>';}).join('')+'</div>';}
function x4sec(t,body,foot){return (t?'<div class="x4s">'+esc(t)+'</div>':'')+'<div class="x4g">'+body+'</div>'+(foot?'<div class="x4f">'+foot+'</div>':'');}
function x4row(icon,title,sub,right,attrs,cls){return '<div class="x4r'+(cls?' '+cls:'')+'"'+(attrs?' '+attrs:'')+'>'+(icon?'<div class="x4rc">'+icon+'</div>':'')+'<div class="x4rt"><b>'+title+'</b>'+(sub?'<small>'+sub+'</small>':'')+'</div>'+(right?'<div class="x4rr">'+right+'</div>':'')+'</div>';}
function x4ava(name,lv,cls,dot){return '<span class="x4av'+(cls?' '+cls:'')+'" style="'+avaColor(lv)+'">'+esc(initials(name||'?'))+(dot?'<i class="x4on"></i>':'')+'</span>';}
function x4btn(label,attrs,kind){return '<span class="x4b'+(kind?' '+kind:'')+'" '+(attrs||'')+'>'+esc(label)+'</span>';}
function x4pill(t,c){return '<span class="x4p'+(c?' '+c:'')+'">'+t+'</span>';}
function x4segv(items,key){return '<div class="mkseg">'+items.map(function(t){return '<span class="'+(X4[key]===t[0]?'on':'')+'" data-x4="'+key+'='+t[0]+'">'+esc(t[1])+(t[2]?' <em>'+t[2]+'</em>':'')+'</span>';}).join('')+'</div>';}
function x4bar(pct,cls){return '<div class="x4bar'+(cls?' '+cls:'')+'"><i style="width:'+Math.max(0,Math.min(100,pct))+'%"></i></div>';}
function x4kpis(list){return '<div class="x4k">'+list.map(function(k){return '<div class="x4kc"><div>'+x4ic(k[0],k[1])+'<b>'+esc(k[2])+'</b><small>'+esc(k[3])+'</small></div></div>';}).join('')+'</div>';}
function x4empty(icon,col,title,text,btn){return '<div class="mkempty x4e"><span class="x4eic">'+x4ic(icon,col)+'</span><b>'+esc(title)+'</b><p>'+esc(text)+'</p>'+(btn||'')+'</div>';}
function x4cmd(c){return '<div class="x4f">'+esc(x4t('Oyunda da yazabilirsin: ','Also works in chat: '))+'<code>'+esc(c)+'</code></div>';}
function x4off(){return LIVE.on?'':'<div class="x4warn"><div class="x4ci">'+x4ic('link','orange')+'</div><span>'+esc(x4t('Canlı bağlantı kurulamadı. Tableti oyunda /ipad yazarak aç.','Live link is off. Open the tablet in game with /ipad.'))+'</span></div>';}
function x4wrap(h){return '<div class="x4">'+h+'</div>';}
function x4re(){var b=$('appBody');if(!b||!cur||!R[cur])return;var st=b.scrollTop;b.innerHTML=R[cur]();colors(b);b.scrollTop=st;}
function x4item(code,size){return mkIcon(code,size||44);}
function x4rar(code){var r=mkRar(code);return '<span style="color:'+MK_RAR[r][0]+'">'+esc(mkRarName(code))+'</span>';}
function x4team(t){return t===2?x4t('Zombi','Zombie'):t===1?x4t('İnsan','Human'):x4t('İzleyici','Spectator');}

// ---- profile
R.prof=function(){
  var pct=Math.max(0,Math.min(100,D.xn>0?Math.round(D.xp*100/D.xn):100));
  var h='<div class="x4pc"><div class="x4pcl">'+x4ava(D.name,D.lv,'big')+'</div><div class="x4pcm"><h1>'+esc(D.name)+(D.vip?x4pill(D.vip===2?'ELITE':'VIP','y'):'')+'</h1><p>'+esc(x4t('Seviye ','Level '))+D.lv+(D.rank?' · #'+D.rank+' '+esc(x4t('sırada','rank')):'')+(D.vip&&D.vd?' · '+esc(F('vipDays',D.vd)):'')+'</p>'+x4bar(pct,'w')+'<small>XP '+fmt(D.xp)+' / '+fmt(D.xn)+' · %'+pct+'</small></div><div class="x4pcr"><small>'+esc(x4t('Seviye','Level'))+'</small><b>'+D.lv+'</b></div></div>';
  h+='<div class="x4s">'+esc(x4t('Savaş istatistikleri','Combat stats'))+'</div>'+x4kpis([['blade','red',fmt(D.k),L('kills')],['zup','green',fmt(D.inf),L('infs')],['target','orange',fmt(D.hs),L('hs')],['top','yellow',fmt(D.w),L('wins')],['crown','purple',fmt(D.b),L('boss')],['skull','gray',fmt(D.d),L('deaths')],['time','blue',Math.floor(D.pt/60)+' '+L('hours'),L('play')],['ach','indigo',achCount()+'/'+achList().length,L('ach')]]);
  var kd=D.d>0?(D.k/D.d).toFixed(2):fmt(D.k);
  h+=x4sec(x4t('Cüzdan ve durum','Wallet and status'),
    x4row(x4ic('coin','yellow'),'VexCoin',esc(x4t('Pazar, kasa ve mağaza parası','Market, case and shop money')),'<b class="x4v y">'+fmt(D.vc)+'</b>')+
    x4row(x4ic('bolt','blue'),'AP',esc(x4t('Silah ve eşya puanı','Ammo packs')),'<b class="x4v">'+fmt(D.ap)+'</b>')+
    x4row(x4ic('fire','orange'),esc(L('streak')),esc(x4t('Günlük giriş serisi','Daily login streak')),'<b class="x4v">'+D.streak+'</b>','data-app="daily"')+
    x4row(x4ic('chart','teal'),esc(x4t('Öldürme / ölüm','Kill / death')),esc(x4t('Oran','Ratio')),'<b class="x4v">'+kd+'</b>')+
    x4row(x4ic('users','green'),esc(L('online')),esc(D.map||''),'<b class="x4v">'+D.on+'/'+D.mx+'</b>')+
    (D.sid?'<a class="x4r x4lnk" href="https://steamcommunity.com/profiles/'+esc(D.sid)+'" target="_blank"><div class="x4rc">'+x4ic('link','gray')+'</div><div class="x4rt"><b>'+esc(L('steam'))+'</b></div><div class="x4rr">'+svg('chev')+'</div></a>':''),
    esc(x4t('Detaylı istatistik için ','For detailed stats type '))+'<code>/istatistik</code>');
  return x4wrap(h);
};

// ---- leaderboards (top / time / achtop)
leader=function(mode){
  TOPM=mode;var rows=topRows(mode),me=-1;rows.forEach(function(r,i){if(r.n===D.name)me=i;});
  var titles={top:L('top'),time:L('time'),achtop:L('achtop')};
  var h=x4hero(mode==='time'?'time':mode==='achtop'?'achtop':'top',titles[mode],x4t('Sezon yarışı · ilk 3 her hafta duyurulur','Season race · top 3 announced weekly'),me>=0?x4bal(x4t('Senin sıran','Your rank'),'#'+(me+1),'','#0a84ff'):'');
  h+=x4seg([['top','Top 15'],['time',x4t('Oynama süresi','Playtime')],['achtop',L('ach')]],'data-top',mode);
  if(!rows.length)return x4wrap(h+x4empty('top','orange',x4t('Sıralama boş','No ranking yet'),x4t('Sunucuda oynandıkça burası dolar.','Fills up as people play.')));
  var pod='<div class="podium">';
  [1,0,2].forEach(function(i){var r=rows[i];if(!r)return;pod+='<div class="pod p'+(i+1)+'"><div class="pa" style="'+avaColor(i===0?80:i===1?55:30)+'">'+(i===0?'<span class="crown">'+CROWN+'</span>':'')+esc(initials(r.n))+'</div><b>'+esc(r.n)+(r.n===D.name?' &#9733;':'')+'</b><small>'+esc(r.main)+(r.lv?' · Lv '+esc(r.lv):'')+'</small><div class="ped">'+(i+1)+'</div></div>';});
  h+=pod+'</div>';
  var max=rows[0].v||1,list='';
  rows.forEach(function(r,i){if(i<3)return;list+=x4row('<span class="x4rk">'+(i+1)+'</span>'+x4ava(r.n,i<6?40:10,'sm'),esc(r.n)+(r.lv?x4pill('Lv '+esc(r.lv)):''),x4bar(Math.max(4,Math.round(r.v*100/max))),'<b class="x4v">'+esc(r.main)+'</b><small class="x4vs">'+esc(r.sub)+'</small>','',r.n===D.name?'rk me':'rk');});
  if(list)h+=x4sec(x4t('Sıralama','Standings'),list);
  return x4wrap(h+x4cmd(mode==='top'?'/top15':mode==='time'?'/toptime':'/basarimtop'));
};

// ---- achievements
R.ach=function(){
  var a=achList(),claimed=D.claimedMask|0,rw=D.achReward,open=0,ready=0;
  a.forEach(function(x,i){var u=(D.ach&(1<<i))!==0;if(u)open++;if(u&&!(claimed&(1<<i))&&D.claimedMask!==undefined)ready++;});
  var pct=a.length?Math.round(open*100/a.length):0;
  var h=x4hero('ach',x4t('Başarımlar','Achievements'),open+'/'+a.length+x4t(' açıldı',' unlocked')+(ready?' · '+ready+x4t(' ödül seni bekliyor',' rewards waiting'):''),x4bal(x4t('Tamamlandı','Complete'),'%'+pct,'','#ffd60a'));
  h+=x4bar(pct,'big y');
  h+=x4segv([['all',x4t('Tümü','All'),a.length],['ready',x4t('Ödül al','Claim'),ready],['open',x4t('Açılan','Unlocked'),open],['lock',x4t('Kilitli','Locked'),a.length-open]],'achf');
  var g='';
  a.forEach(function(x,i){
    var u=(D.ach&(1<<i))!==0,paid=(claimed&(1<<i))!==0,can=u&&!paid&&D.claimedMask!==undefined;
    if(X4.achf==='ready'&&!can)return;if(X4.achf==='open'&&!u)return;if(X4.achf==='lock'&&u)return;
    var badge=paid?x4ic('check','green'):u?x4ic('ach','yellow'):x4ic('lock','gray');
    g+='<div class="x4cc"><div class="x4ac'+(u?'':' lk')+'"><div class="x4ach"><div class="x4ci">'+badge+'</div><div><b>'+esc(x.n)+'</b><small>'+esc(x.d||'')+'</small></div></div><div class="x4acf"><span>'+(rw?x4pill(fmt(rw[0])+' VC','y')+x4pill(fmt(rw[1])+' AP','b'):'')+'</span>'+(can?x4btn(x4t('Ödülü al','Claim'),'data-achclaim="'+i+'"','g'):x4btn(paid?x4t('Alındı','Claimed'):u?x4t('Açıldı','Unlocked'):x4t('Kilitli','Locked'),'','dis'))+'</div></div></div>';
  });
  h+=g?'<div class="x4cg">'+g+'</div>':x4empty('ach','yellow',x4t('Burada başarım yok','Nothing here'),x4t('Başka bir filtre seç.','Pick another filter.'));
  return x4wrap(h+x4cmd(x4t('/basarimlar','/achievements')));
};

// ---- inventory
R.inv=function(){
  var cats=MK_CATS.filter(function(c){return catList(c).length||(D.iv[c]|0);});
  if(cats.indexOf(invTab)<0)invTab=cats[0]||'k';
  var total=0,eqn=0;cats.forEach(function(c){for(var b=0;b<31;b++)if((D.iv[c]|0)&(1<<b))total++;if(D.eq[c]|0)eqn++;});
  var h=x4hero('inv',x4t('Envanter','Inventory'),total+x4t(' eşya · ',' items · ')+eqn+x4t(' takılı',' equipped'),x4bal(x4t('Bakiyen','Balance'),fmt(D.vc),'VC'));
  h+='<div class="mkchips">'+cats.map(function(c){var o=0;for(var b=0;b<31;b++)if((D.iv[c]|0)&(1<<b))o++;return '<span class="'+(invTab===c?'on':'')+'" data-tab="'+c+'"><svg viewBox="0 0 24 24">'+MK_ICO[c]+'</svg>'+esc(MK_META[c][D.lang==='tr'?0:1])+' <em>'+o+'</em></span>';}).join('')+'</div>';
  var list=catList(invTab),n=list.length,g='';
  if(!n){for(var b=0;b<16;b++)if((D.iv[invTab]|0)&(1<<b))n=b+1;}
  for(var i=0;i<n;i++){
    var it=list[i]||{},own=((D.iv[invTab]|0)&(1<<i))!==0,eq=(D.eq[invTab]|0)===i+1,code=invTab+(i+1);
    if(it.ok===0&&!own)continue;
    g+='<div class="x4cc c3"><div class="x4it'+(own?'':' no')+(eq?' eq':'')+'"><div class="x4itt">'+x4item(code,52)+(eq?x4pill(x4t('TAKILI','EQUIPPED'),'g'):own?'':'<span class="x4lk">'+svg('lock')+'</span>')+'</div><b>'+esc(itemName(code))+'</b><small>'+x4rar(code)+(it.vc?' · '+it.vc+' VC':'')+'</small>'+(own?x4btn(eq?x4t('Çıkar','Unequip'):x4t('Tak','Equip'),'data-eq="'+invTab+'.'+i+'.'+(eq?1:0)+'"',eq?'gh':''):x4btn(x4t('Kasadan / mağazadan','From cases / shop'),'','dis'))+'</div></div>';
  }
  h+=g?'<div class="x4cg">'+g+'</div>':x4empty('inv','purple',x4t('Bu kategori boş','This category is empty'),x4t('Kasa açarak ya da pazardan eşya kazan.','Win items from cases or the market.'),x4btn(x4t('Kasalara git','Open cases'),'data-app="case"'));
  return x4wrap(h+x4cmd(x4t('/envanter  /kozmetik  /bicak','/inventory  /cosmetic  /knife')));
};

// ---- cases: same crates and reel, new header
R['case']=function(){
  var cs=caseData(),c=cs[caseSel]||cs[0],price=c.vc|0,can=D.vc>=price;
  var h=x4hero('case',x4t('Kasalar','Cases'),x4t('Kasa aç, nadir eşyalar kazan','Open cases, win rare items'),x4bal(x4t('Bakiyen','Balance'),fmt(D.vc),'VC'));
  if(D.cr)h+='<div class="x4g x4stage"><div id="cstage" class="casestage shake"><div class="rays">'+RAYS+'</div><div class="big">'+crate(D.cr.c)+'</div></div><div class="reelbox" id="rbox" style="display:none"><div class="needle"></div><div id="reel" class="reel"></div></div><div id="winBox"></div></div>';
  h+='<div class="x4s">'+esc(x4t('Kasa seç','Pick a case'))+'</div><div class="x4g x4pad"><div class="cases">';
  cs.forEach(function(k,i){var t=TIERS[i]||TIERS[0];h+='<div class="case'+(i===caseSel?' sel':'')+'" data-case="'+i+'"><div class="ci"><span class="tier" style="background:'+t.tagc+'">'+t.tag+'</span><div class="cbx"><div class="glow" style="background:-webkit-radial-gradient(50% 50%,circle closest-side,'+t.glow+',rgba(0,0,0,0))"></div>'+crate(i)+'</div><b>'+esc(k[D.lang]||k.en)+'</b><small>'+(k.vc|0)+' VC</small></div></div>';});
  h+='</div></div>';
  h+='<span class="x4b big'+(can?'':' dis')+'" data-openc="'+caseSel+'">'+esc(can?x4t('Aç','Open')+' · '+(c[D.lang]||c.en)+' · '+price+' VC':x4t('Yetersiz bakiye','Not enough VC')+' · '+price+' VC')+'</span>';
  var loot=(c.loot||[]).slice(),rn=L('rar');
  if(loot.length){for(var r=4;r>=0;r--){var g=loot.filter(function(l){return (l[1]|0)===r;});if(!g.length)continue;var sum=0;g.forEach(function(l){sum+=Number(l[2])||0;});g.sort(function(a,b){return a[2]-b[2];});
    h+='<div class="x4s"><span style="color:'+RCOL[r]+'">●</span> '+esc(rn[r]||'')+' · %'+sum.toFixed(2)+'</div><div class="x4g"><div class="x4lt">'+g.map(function(l){return '<div class="x4lc"><span class="mkic" style="width:30px;height:30px;'+lg(135,RCOL[r],'#15121a')+'"><svg viewBox="0 0 24 24">'+(MK_ICO[String(l[0]).charAt(0)]||IC.gift)+'</svg></span><b>'+esc(itemName(l[0]))+'</b><em>%'+Number(l[2]).toFixed(2)+'</em></div>';}).join('')+'</div></div>';}}
  else h+=x4empty('case','pink',x4t('Düşme oranları yükleniyor','Loading drop rates'),x4t('Sunucu cevap verdiğinde kasa içeriği görünür.','Contents appear when the server answers.'));
  h+='<div class="x4f">'+esc(L('vipDrop'))+'</div>';
  return x4wrap(h+x4cmd(x4t('/kasa','/case')));
};

// ---- daily reward
R.daily=function(){
  var today=D.dailyNext||Math.min(7,D.claimed?Math.max(1,D.streak):D.streak+1);
  var h=x4hero('daily',x4t('Günlük Ödül','Daily Reward'),x4t('7 gün üst üste gir, büyük ödülü al','Log in 7 days in a row for the big prize'),x4bal(L('streak'),D.streak,x4t('gün','days'),'#ff9f0a'));
  h+='<div class="x4dy">';
  for(var i=1;i<=7;i++){
    var rw=D.rewards&&D.rewards[i-1],done=i<today||(i===today&&D.claimed),now=i===today&&!D.claimed;
    h+='<div class="x4d'+(done?' done':now?' now':'')+(i===7?' big':'')+'"><div><small>'+i+'. '+esc(L('day'))+'</small><span class="x4dg">'+svg(done?'check':i===7?'crown':'gift')+'</span><b>'+(rw?fmt(rw[0]):'—')+' AP</b><em>+'+(rw?fmt(rw[1]):'—')+' VC</em></div></div>';
  }
  h+='</div>';
  if(D.claimed)h+='<div class="x4note"><div class="x4ci">'+x4ic('time','blue')+'</div><div><b>'+esc(L('claimed'))+'</b><small>'+esc(x4t('Sonraki ödül: ','Next reward in: '))+'<span id="dailyCountdown">'+esc(hms(D.next))+'</span></small></div></div>';
  else h+='<span class="x4b g big" data-daily="1">'+esc(L('claim'))+(D.rewards&&D.rewards[today-1]?' · '+fmt(D.rewards[today-1][0])+' AP + '+fmt(D.rewards[today-1][1])+' VC':'')+'</span>';
  h+=x4sec(x4t('Nasıl çalışır','How it works'),
    x4row(x4ic('daily','green'),esc(x4t('Her gün bir kez al','Claim once a day')),esc(x4t('Ödül her gece 00:00\'da (Türkiye saati) yenilenir.','Resets every night at 00:00 Turkey time.')),'')+
    x4row(x4ic('fire','orange'),esc(x4t('Seriyi bozma','Keep the streak')),esc(x4t('Bir gün kaçırırsan seri 1. güne döner.','Miss a day and the streak restarts.')),'')+
    x4row(x4ic('crown','yellow'),esc(x4t('7. gün büyük ödül','Day 7 jackpot')),esc(x4t('En yüksek AP ve VexCoin 7. gündedir.','Day 7 pays the most AP and VexCoin.')),''));
  return x4wrap(h+x4cmd(x4t('/gunluk','/daily')));
};

// ---- zombie upgrades
R.zup=function(){
  var names=ZCLS[D.lang]||ZCLS.tr;
  if(!D.zup)return x4wrap(x4hero('zup',x4t('Zombi Gelişim','Zombie Upgrades'),x4t('24 zombi sınıfı','24 zombie classes'),'')+x4empty('zup','green',x4t('Gelişim verisi bekleniyor','Waiting for upgrade data'),x4t('Sunucu cevap verdiğinde sınıfların burada görünür. Ayarlar > Canlı bağlantı ile kontrol et.','Your classes appear when the server answers. Check Settings > Live connection.'),x4btn(x4t('Bağlantıyı sına','Test connection'),'data-linktest="1"')));
  var rows=D.zup,totFree=0,cards='',per=[x4t('Bekleme','Cooldown'),x4t('Menzil','Range'),x4t('Hasar','Damage')],pic=['time','target','blade'],pcol=['blue','teal','red'];
  for(var i=0;i<24;i++){var z=rows[i]||[D.zlv[i]||0,0,0,0,0,0];var free=Math.max(0,z[0]-z[2]-z[3]-z[4]);totFree+=free;
    if(X4.zf==='free'&&!free)continue;
    var pct=z[5]?Math.round(z[1]*100/z[5]):100;
    cards+='<div class="x4cc"><div class="x4zc"><div class="x4zh"><div class="x4ci"><span class="x4zl" style="'+avaColor(z[0]*5)+'">'+esc((names[i]||'?').charAt(0))+'</span></div><div><b>'+esc(names[i]||('Class '+(i+1)))+'</b><small>'+esc(x4t('Seviye ','Level '))+z[0]+' · '+z[1]+'/'+(z[5]||'MAX')+'</small></div>'+(free?x4pill('+'+free,'g'):'')+'</div>'+x4bar(pct,'g')+
      per.map(function(n,k){return '<div class="x4zp"><div class="x4ci">'+x4ic(pic[k],pcol[k])+'</div><span class="x4zn">'+esc(n)+'</span><b>'+z[k+2]+'</b><span class="x4plus'+(free?'':' dis')+'"'+(free?' data-zperk="'+i+'.'+k+'"':'')+'>+</span></div>';}).join('')+'</div></div>';}
  var h=x4hero('zup',x4t('Zombi Gelişim','Zombie Upgrades'),x4t('Enfekte et +1 · öldür +2 gelişim puanı','Infect +1 · kill +2 upgrade points'),x4bal(x4t('Boş puan','Free points'),totFree,'','#30d158'));
  h+=x4segv([['all',x4t('Tüm sınıflar','All classes'),24],['free',x4t('Puanı olanlar','With points')]],'zf');
  h+=cards?'<div class="x4cg">'+cards+'</div>':x4empty('zup','green',x4t('Boş puanın yok','No free points'),x4t('Zombiyken enfekte ederek ve öldürerek puan kazan.','Earn points by infecting and killing as a zombie.'));
  return x4wrap(h+x4cmd(x4t('/sinif','/class')));
};

// ---- trade
R.trade=function(){
  var inc=OF.filter(function(o){return o[5]===1;}),out=OF.filter(function(o){return o[5]===0;});
  if(!X4.trt)X4.trt=inc.length?'in':'new';
  var h=x4off()+x4hero('trade',x4t('Takas','Trade'),x4t('Eşyanı seç, oyuncuya teklif et; karşı taraf tabletinden kabul eder.','Pick an item, offer it; they accept on their tablet.'),'');
  h+=x4segv([['in',x4t('Gelen','Incoming'),inc.length],['out',x4t('Gönderilen','Sent'),out.length],['new',x4t('Yeni takas','New trade')]],'trt');
  if(X4.trt==='in'){
    h+=inc.length?x4sec('',inc.map(function(o){return x4row(x4item(o[3],40),esc(o[2])+' <span class="x4dim">'+esc(x4t('veriyor','gives'))+'</span> '+esc(itemName(o[3])),o[4]!=='-'?esc(x4t('Karşılığında istiyor: ','Wants: '))+esc(itemName(o[4])):esc(x4t('Hediye – karşılık istemiyor','Gift – nothing asked')),x4btn(x4t('Kabul','Accept'),'data-tacc="'+o[0]+'"','g')+x4btn(x4t('Reddet','Decline'),'data-tdec="'+o[0]+'"','red'));}).join('')):x4empty('trade','teal',x4t('Gelen teklif yok','No incoming offers'),x4t('Biri sana takas teklif ettiğinde burada ve oyunda iPad bildirimi olarak görünür.','Offers show up here and as an iPad alert in game.'));
  }else if(X4.trt==='out'){
    h+=out.length?x4sec('',out.map(function(o){return x4row(x4item(o[3],40),esc(itemName(o[3])),esc(x4t('Alıcı: ','To: '))+esc(o[2])+(o[4]!=='-'?' · '+esc(itemName(o[4])):''),x4pill(x4t('Bekliyor','Pending'),'y'));}).join('')):x4empty('trade','teal',x4t('Gönderilen teklif yok','No sent offers'),x4t('Yeni takas sekmesinden teklif gönder.','Send one from the New trade tab.'),x4btn(x4t('Yeni takas','New trade'),'data-x4="trt=new"'));
  }else{
    var own=mkOwned();
    h+='<div class="x4s">'+esc(x4t('1. Vereceğin eşya','1. Item to give'))+'</div>';
    h+=own.length?'<div class="mkpick">'+own.map(function(code){return '<div class="mkp'+(tradeSel===code?' on':'')+'" data-tgive="'+code+'">'+mkIcon(code,44)+'<b>'+esc(itemName(code))+'</b><small style="color:'+MK_RAR[mkRar(code)][0]+'">'+esc(mkRarName(code))+'</small>'+(tradeSel===code?'<span class="mkok">✓</span>':'')+'</div>';}).join('')+'</div>':x4empty('inv','purple',x4t('Takas edilecek eşyan yok','No items to trade'),x4t('Kasa açarak eşya kazan.','Win items from cases.'),x4btn(x4t('Kasalara git','Open cases'),'data-app="case"'));
    if(own.length){var pl=others(true);
      h+='<div class="x4s">'+esc(x4t('2. Kime','2. To whom'))+(tradeSel?' · '+esc(itemName(tradeSel)):'')+'</div>';
      h+=x4sec('',pl.length?pl.map(function(p){return x4row(x4ava(p[1],p[3]),esc(p[1]),'Lv '+p[3]+' · '+esc(x4team(p[2])),tradeSel?x4btn(x4t('Teklif et','Offer'),'data-toffer="'+p[0]+'"'):x4btn(x4t('Önce eşya seç','Pick an item'),'','dis'));}).join(''):x4row(x4ic('users','gray'),esc(x4t('Sunucuda başka oyuncu yok','No other players online')),'',''));}
  }
  return x4wrap(h+x4cmd(x4t('/takas','/trade')));
};

// ---- messages
var x4oldMsg=R.msg;
R.msg=function(){
  if(CHAT)return x4oldMsg();
  var ppl={};MS.forEach(function(m){if(!ppl[m[0]]||ppl[m[0]][3]<m[3])ppl[m[0]]=m;});
  var ids=Object.keys(ppl).sort(function(a,b){return ppl[b][3]-ppl[a][3];}),pl=others(true);
  var h=x4off()+x4hero('msg',x4t('Mesajlar','Messages'),ids.length+x4t(' sohbet · ',' chats · ')+pl.length+x4t(' oyuncu çevrimiçi',' players online'),'');
  h+=ids.length?x4sec(x4t('Sohbetler','Chats'),ids.map(function(uid){var m=ppl[uid];return x4row(x4ava(m[1],20,'',!!plName(num(uid))&&plName(num(uid))!=='?'),esc(m[1]),(m[4]?esc(x4t('Sen: ','You: ')):'')+esc(m[2]),'<small class="x4vs">'+ago(m[3])+'</small>'+svg('chev'),'data-chat="'+uid+'"','nav');}).join('')):x4empty('msg','blue',x4t('Henüz mesaj yok','No messages yet'),x4t('Aşağıdan bir oyuncu seçip ilk mesajı yaz.','Pick a player below and say hi.'));
  h+=x4sec(x4t('Çevrimiçi oyuncular','Online players'),pl.length?pl.map(function(p){return x4row(x4ava(p[1],p[3],'',true),esc(p[1])+(p[4]&4?x4pill('ADM','r'):'')+(p[4]&1?x4pill('★','y'):''),'Lv '+p[3]+' · '+esc(x4team(p[2])),p[4]&2?x4pill(x4t('Engelli','Blocked'),'r'):x4btn(x4t('Yaz','Message'),'data-chat="'+p[0]+'"'));}).join(''):x4row(x4ic('users','gray'),esc(x4t('Başka oyuncu yok','No other players')),'',''));
  return x4wrap(h);
};

// ---- friends
R.friends=function(){
  var reqs=others(true).filter(function(p){return p[4]&8;}),onl=FR.filter(function(f){return f[1];}).length;
  var h=x4off()+x4hero('friends',x4t('Arkadaşlar','Friends'),FR.length+x4t(' arkadaş · ',' friends · ')+onl+x4t(' çevrimiçi',' online'),reqs.length?x4bal(x4t('İstek','Requests'),reqs.length,'','#ff375f'):'');
  if(reqs.length)h+=x4sec(x4t('Arkadaşlık istekleri','Friend requests'),reqs.map(function(p){return x4row(x4ava(p[1],p[3]),esc(p[1]),'Lv '+p[3]+' · '+esc(x4t('seni eklemek istiyor','wants to add you')),x4btn(x4t('Kabul et','Accept'),'data-facc="'+p[0]+'"','g'));}).join(''));
  var fl=FR.slice().sort(function(a,b){return (b[1]?1:0)-(a[1]?1:0);});
  h+=fl.length?x4sec(x4t('Arkadaşların','Your friends'),fl.map(function(f){return x4row(x4ava(f[0],30,f[1]?'':'x4of',!!f[1]),esc(f[0]),f[1]?'<span class="x4gr">● '+esc(x4t('Çevrimiçi','Online'))+'</span>':esc(x4t('Çevrimdışı','Offline')),f[1]?x4btn(x4t('Mesaj','Message'),'data-chat="'+f[1]+'"','gh'):'');}).join('')):x4empty('friends','green',x4t('Henüz arkadaşın yok','No friends yet'),x4t('Aşağıdan çevrimiçi oyuncuları ekleyebilirsin.','Add online players below.'));
  var pl=others(true).filter(function(p){return !(p[4]&1)&&!(p[4]&8);});
  h+=x4sec(x4t('Oyuncu ekle','Add players'),pl.length?pl.map(function(p){return x4row(x4ava(p[1],p[3]),esc(p[1]),'Lv '+p[3]+' · '+esc(x4team(p[2])),(p[4]&2)?x4btn(x4t('Engeli kaldır','Unblock'),'data-unblock="'+p[0]+'"','gh'):x4btn('+ '+x4t('Ekle','Add'),'data-fadd="'+p[0]+'"')+x4btn(x4t('Engelle','Block'),'data-block="'+p[0]+'"','red'));}).join(''):x4row(x4ic('users','gray'),esc(x4t('Eklenecek oyuncu yok','No players to add')),'',''));
  return x4wrap(h);
};

// ---- notifications
function x4nkind(t){t=String(t).toLowerCase();if(/mesaj|message/.test(t))return ['msg','blue'];if(/pazar|market|sat/.test(t))return ['market','green'];if(/arkada|friend/.test(t))return ['friends','teal'];if(/takas|trade|teklif|offer/.test(t))return ['trade','teal'];if(/kasa|case/.test(t))return ['case','pink'];if(/ba[sş]ar|achiev/.test(t))return ['ach','yellow'];if(/admin|ban|kick/.test(t))return ['adm','red'];return ['bell','red'];}
R.notif=function(){
  if(LIVE.tk)act('seen','','','',null);
  var h=x4hero('notif',x4t('Bildirimler','Notifications'),NT.length?NT.length+x4t(' bildirim',' notifications'):x4t('Her şey yolunda','All caught up'),'');
  h+=NT.length?x4sec(x4t('Son bildirimler','Recent'),NT.slice().reverse().map(function(n){var k=x4nkind(n[0]);return x4row(x4ic(k[0],k[1]),esc(n[0]),'','<small class="x4vs">'+ago(n[1])+'</small>');}).join(''),esc(x4t('Tablet kapalıyken gelenler oyunda iPad kartı olarak da görünür (Ayarlar > Bildirimler).','When the tablet is closed they also pop up in game (Settings > Notifications).'))):x4empty('notif','pink',x4t('Bildirim yok','No notifications'),x4t('Mesaj, arkadaşlık isteği, takas ve pazar satışları burada görünür.','Messages, friend requests, trades and market sales show up here.'));
  return x4wrap(h);
};

// ---- settings (iPadOS Settings layout)
R.set=function(){
  var dark=store('theme')!=='light',acc=store('acc')||ACCS[0],ok=LIVE.fileOk&&!DEMO;
  var h='<div class="x4set">';
  h+=x4sec('',x4row(x4ava(D.name,D.lv,'md'),esc(D.name)+(D.vip?x4pill(D.vip===2?'ELITE':'VIP','y'):''),esc(x4t('Seviye ','Level '))+D.lv+' · '+fmt(D.vc)+' VC · '+fmt(D.ap)+' AP',svg('chev'),'data-app="prof"','nav big'));
  h+=x4sec(x4t('Görünüm','Appearance'),
    x4row(x4ic(dark?'moon':'sun',dark?'indigo':'orange'),esc(L('theme')),'','<div class="seg"><span data-set="dark" class="'+(dark?'on':'')+'">'+esc(L('dark'))+'</span><span data-set="light" class="'+(dark?'':'on')+'">'+esc(L('light'))+'</span></div>')+
    x4row(x4ic('paint','pink'),esc(L('accent')),'','<div class="ccacc">'+ACCS.map(function(c){return '<span data-acc="'+c+'" class="'+(c===acc?'on':'')+'" style="background:'+c+'"></span>';}).join('')+'</div>'));
  h+=x4sec(x4t('Ses ve bildirimler','Sound and alerts'),
    x4row(x4ic('vol','red'),esc(L('sound')),esc(x4t('Tablet sesleri ve oyundaki iPad bildirim sesi','Tablet sounds and the in-game alert sound')),'<div class="sw'+(soundOn?' on':'')+'" data-set="snd"></div>')+
    x4row(x4ic('bell','red'),esc(L('notif')),esc(x4t('Tablet kapalıyken oyunda sağ üstte iPad kartı','In-game iPad card while the tablet is closed')),'<div class="sw'+(notifOn?' on':'')+'" data-set="ntf"></div>'),
    esc(x4t('Bu tercihler sunucuda saklanır, harita değişince kaybolmaz.','Saved on the server, kept across map changes.')));
  h+=x4sec(L('lang'),x4row(x4ic('globe','blue'),esc(x4t('Tablet ve oyun dili','Tablet and game language')),'','<div class="seg"><span data-set="tr" class="'+(D.lang==='tr'?'on':'')+'">Türkçe</span><span data-set="en" class="'+(D.lang==='en'?'on':'')+'">English</span></div>'));
  var w='<div class="wps">';L('wpNames').forEach(function(n,i){w+='<div class="wpt'+(i===WP?' on':'')+'" data-wp="'+i+'"><div class="w wp'+i+'">'+(i===7?emblem():'')+'<small>'+esc(n)+'</small></div></div>';});w+='</div>';
  h+=x4sec(L('wall'),'<div class="x4pad">'+w+'</div>');
  h+=x4sec(x4t('Canlı bağlantı','Live connection'),
    x4row(x4ic('dl',ok?'green':'red'),esc(x4t('Oyun verisi','Game data')),esc(ok?x4t('Sunucudan geldi','Received from the server'):x4t('Yok – tableti oyunda /ipad ile aç','Missing – open the tablet in game with /ipad')),'<span class="ldot '+(ok?'g':'r')+'"></span>')+
    x4row(x4ic('send',LIVE.ready?'green':'orange'),esc(x4t('Komut kanalı','Command channel')),esc((LIVE.ready?x4t('Sunucu dinliyor','Server listening'):x4t('Bağlanıyor','Connecting'))+' · '+x4t('gönderilen ','sent ')+LIVE.sent),'<span class="ldot '+(LIVE.ready?'g':'y')+'"></span>')+
    x4row(x4ic('msg',LIVE.sse?'green':'orange'),esc(x4t('Cevap kanalı','Reply channel')),esc((LIVE.sse?x4t('Bağlı','Connected'):x4t('Bağlanıyor','Connecting'))+' · '+x4t('alınan ','received ')+LIVE.rx),'<span class="ldot '+(LIVE.sse?'g':'y')+'"></span>')+
    x4row(x4ic('bolt','blue'),esc(x4t('Bağlantıyı sına','Test connection')),esc(x4t('Sunucuya ping gönderir, cevap 1-3 sn içinde gelir.','Pings the server; the answer arrives in 1-3 s.')),x4btn(x4t('Sına','Test'),'data-linktest="1"')));
  h+=x4sec('',x4row(x4ic('about','gray'),esc(L('about')),'VEXMIRA PAD 6.0',svg('chev'),'data-app="about"','nav')+x4row(x4ic('cmds','gray'),esc(L('cmds')),esc(x4t('Oyun içi ayarlar: /ayarlar /dil /stil','In-game settings: /settings /lang /style')),svg('chev'),'data-app="cmds"','nav'));
  return x4wrap(h+'</div>');
};

// ---- about
R.about=function(){
  var mins=D.ts?Math.max(0,Math.round((Date.now()/1000-D.ts)/60)):-1;
  var h='<div class="x4ab"><div class="lg">'+LOGO()+'</div><p>'+esc(x4t('Zombi sunucusu tableti','Zombie server tablet'))+' · PAD 6.0</p></div>';
  h+=x4sec(x4t('Bu cihaz','This device'),
    x4row('',esc(x4t('Sürüm','Version')),'','<span class="x4vs">PAD 6.0</span>')+
    x4row('',esc(L('map')),'','<span class="x4vs">'+esc(D.map)+'</span>')+
    x4row('',esc(L('round')),'','<span class="x4vs">'+esc(D.round)+'</span>')+
    x4row('',esc(L('players')),'','<span class="x4vs">'+D.on+'/'+D.mx+'</span>')+
    (mins>=0?x4row('',esc(x4t('Veri güncellendi','Data updated')),'','<span class="x4vs">'+esc(F('updated',mins))+'</span>'):'')+
    x4row('',esc(x4t('Bağlantı','Link')),'','<span class="x4vs">'+esc(LIVE.sse?x4t('Canlı','Live'):x4t('Bekleniyor','Waiting'))+'</span>'));
  h+=x4sec(x4t('Yapımcı','Credits'),x4row(x4ic('brush','pink'),esc(L('credit')),'','<b style="color:var(--acc)">smurfsexy</b>'));
  return x4wrap(h);
};

// ---- App Store, guide, commands, admin: same functions, new header and lists
var x4oldStore=R.store;
R.store=function(){return x4wrap(x4hero('store','App Store',x4t('Uygulama ekle, kaldır, keşfet','Get, remove and discover apps'),'')+x4oldStore());};
MODES=[
  ['Enfeksiyon','Infection','Tek zombi başlar, salgın enfekte ettikçe yayılır.','One zombie starts, the plague spreads with every infection.'],
  ['Çoklu Enfeksiyon','Multi Infection','Başta birden fazla zombi vardır.','Several zombies from the very start.'],
  ['Nemesis','Nemesis','Tek vuruşta öldüren dev zombi. [R] atılma, [F] öfke.','A huge zombie that kills in one hit. [R] leap, [F] rage.'],
  ['Assassin','Assassin','Karanlıkta avlanan, çok hızlı ve tek vuruşta öldüren zombi.','A very fast one-hit zombie hunting in the dark.'],
  ['Survivor','Survivor','Tek silahlı kahraman tüm zombilere karşı.','One armed hero against all the zombies.'],
  ['Sniper','Sniper','Tek atışta öldüren AWP\'li keskin nişancı.','One sniper with a one-shot AWP.'],
  ['Swarm','Swarm','Yarı zombi, enfeksiyon yok, sadece kan.','Half zombies, no infection, only blood.'],
  ['Plague','Plague','Survivor + Nemesis + zombiler insanlara karşı.','Survivor + Nemesis + zombies against humans.'],
  ['Armageddon','Armageddon','Nemesis ordusu Survivor ordusuna karşı.','Nemesis army against Survivor army.'],
  ['BOSS','BOSS','3 faz, 5 yetenek. Renkli halkalara dikkat, herkes birlikte savaşır.','3 phases, 5 skills. Watch the colored circles, everyone fights together.']];
TIPS=[
  ['Lazer mayınını koridorlara ve kapılara kur: /lazerkur','Plant laser mines in corridors and doors: /plant'],
  ['Zombiyken enfekte etmek +1, öldürmek +2 gelişim puanı verir.','As a zombie, infecting gives +1 and killing +2 upgrade points.'],
  ['Kafaya vuruş daha çok hasar ve daha çok geri itme yapar.','Headshots deal more damage and more knockback.'],
  ['Her gün gir, 7 günlük seriyi tamamla: /gunluk','Log in every day and finish the 7-day streak: /daily'],
  ['Nadir eşyalar sunucudaki herkese duyurulur. Kabus Kasası en şanslı kasadır.','Rare drops are announced to everyone. The Nightmare Case has the best odds.']];
R.guide=function(){
  var mc=['green','teal','red','purple','blue','orange','yellow','pink','indigo','red'];
  var h=x4hero('guide',x4t('Rehber','Guide'),x4t('Modlar, zombi sınıfları ve ipuçları','Modes, zombie classes and tips'),'');
  h+=x4sec(L('modes'),MODES.map(function(m,i){return x4row('<span class="x4i x4n" style="'+lg(160,X4C[mc[i]].split(',')[0],X4C[mc[i]].split(',')[1])+'">'+(i+1)+'</span>',esc(tr(m[0],m[1])),esc(tr(m[2],m[3])),'');}).join(''));
  var zc=ZCLS[D.lang]||ZCLS.tr;
  h+=x4sec(L('classes'),'<div class="x4pad"><div class="zchips">'+zc.map(function(n){return '<span>'+esc(n)+'</span>';}).join('')+'</div></div>',esc(x4t('Sınıf seçmek için ','To pick a class type '))+'<code>'+esc(tr('/sinif','/class'))+'</code>');
  h+=x4sec(L('tips'),TIPS.map(function(t,i){return x4row(x4ic(['zup','target','target','daily','case'][i],['yellow','green','orange','green','pink'][i]),esc(tr(t[0],t[1])),'','');}).join(''));
  return x4wrap(h);
};
var CMDG=[[['Genel','General'],'cmds','gray',['ipad','menu','settings','lang','help','rules','discord']],[['Market ve eşyalar','Shop and items'],'market','green',['shop','vcmarket','guns','sw','knives','wings','pet','trail','cosmetic','case','trade']],[['Oyun','Gameplay'],'game','orange',['class','plant','take','unstuck','rtv','nextmap']],[['İlerleme','Progress'],'top','yellow',['daily','quest','achievements','top15','toptime','rank','stats','vip']]];
var CMDTR={'ipad':'Tableti açar',menu:'Ana menü',shop:'Eşya marketi',vcmarket:'VexCoin marketi',guns:'Silah menüsü',sw:'Özel silahlar','class':'Zombi sınıfı seç',knives:'Bıçaklar',wings:'Kanatlar',pet:'Petler',trail:'İzler',cosmetic:'Kozmetik',plant:'Lazer mayını kur',take:'Lazer mayınını sök','case':'Kasa aç',trade:'Takas',daily:'Günlük ödül',quest:'Görevler',achievements:'Başarımlar',top15:'En iyi 15',toptime:'Süre sıralaması',rank:'Rütben',stats:'İstatistik',vip:'VIP menüsü',settings:'Ayarlar',lang:'Dil seçimi',rtv:'Harita oylaması',nextmap:'Sonraki harita',unstuck:'Sıkıştıysan kurtar',rules:'Kurallar',help:'Yardım',discord:'İletişim'};
R.cmds=function(){
  var by={};CMDS.forEach(function(c){by[c[0]]=c;});
  var h=x4hero('cmds',x4t('Komutlar','Commands'),x4t('Sohbete yazılan komutlar · ','Chat commands · ')+CMDS.length,'');
  CMDG.forEach(function(g){h+=x4sec(tr(g[0][0],g[0][1]),'<div class="x4c2">'+g[3].filter(function(k){return by[k];}).map(function(k){var c=by[k];return '<div class="x4cm"><code>/'+esc(D.lang==='tr'?c[1]:c[0])+'</code><small>'+esc(D.lang==='tr'?(CMDTR[k]||c[2]):c[3])+'</small></div>';}).join('')+'</div>');});
  return x4wrap(h);
};
var x4oldAdm=R.adm;
R.adm=function(){
  if(D.role<1)return x4wrap(x4hero('adm',x4t('Yönetim','Admin'),'','')+x4empty('adm','red',x4t('Yetki gerekli','Admins only'),L('adminOnly')));
  var founder=D.role>=2;
  return '<div class="x4 x4adm">'+x4hero('adm',x4t('Yönetim','Admin'),(founder?x4t('Kurucu · tam yetki','Founder · full access'):'Admin')+' · '+esc(D.name),x4bal(L('players'),others(false).length+'/'+D.mx,'','#30d158'))+x4seg([['players',x4t('Oyuncular','Players')],['server',x4t('Sunucu','Server')]],'data-admtab',admTab)+x4oldAdm()+'</div>';
};
// ------------------------------------------------------------------ PAD5: instant tablet (no waiting for the server)
// The free relay only allows ~250 server messages a day, so the server barely answers any more:
// - all personal data (daily, zombie upgrades, top 15, case results) comes inside the tablet address,
// - daily / upgrade / equip / achievement / case are shown at once here and the server does the same,
// - leaderboards for playtime and achievements come from g5.js (written by the server).
var PR=[null,null,null,null];
var x5hashU=hashU;
hashU=function(o){var u=x5hashU(o);if(o.pr){u.pr=String(dec(o.pr)).split(',').map(function(x){var q=x.split(':');return q[0]?{code:q[0],r:num(q[1])}:null;});}return u;};
var x5applyU=applyU;
applyU=function(u){if(u.pr)PR=u.pr;x5applyU(u);};
NEED=['msg','friends','notif','trade','adm','market','top','time','achtop'];
wantData=function(a){if(NEED.indexOf(a)<0||DEMO)return;if(GOT[a]&&Date.now()-GOT[a]<20000)return;GOT[a]=Date.now();sendRaw('view',a);};
// one request per command; a second (image) request only when the first could not leave the browser
beacon=function(msg){var url=relayBase()+'/publish?message='+encodeURIComponent(msg)+'&title=vx&cache=no&t='+Date.now();LIVE.sent++;try{var x=new XMLHttpRequest();x.open('GET',url,true);x.onreadystatechange=function(){if(x.readyState!==4)return;if(x.status>=200&&x.status<300)LIVE.okSend=Date.now();else if(x.status===429)LIVE.rate=Date.now();else if(x.status===0){var img=new Image();img.src=url;}};x.send();}catch(e){var img=new Image();img.src=url;}};
// replies: one long EventSource; old browsers poll every 6 s (the relay refills one request per 5 s)
listen=function(){
  if(DEMO||!LIVE.on||!LIVE.tk||!LIVE.rt)return;
  if(window.EventSource){try{var es=new EventSource(replyUrl('sse'));LIVE.es=es;
    es.onopen=function(){LIVE.sse=1;linkDot();};
    es.onmessage=function(e){var d;try{d=JSON.parse(e.data);}catch(x){return;}if(d.event&&d.event!=='message')return;if(d.id)LIVE.lastId=d.id;takeReply(d.message||'');};
    es.onerror=function(){LIVE.sse=0;linkDot();};
    return;}catch(err){}}
  (function poll(){var x;try{x=new XMLHttpRequest();x.open('GET',replyUrl('json')+'?poll=1&since='+(LIVE.lastId||Math.floor(Date.now()/1000)-2),true);x.onreadystatechange=function(){if(x.readyState!==4)return;if(x.status===200)String(x.responseText||'').split('\n').forEach(function(l){if(!l)return;try{var d=JSON.parse(l);if(d.event==='message'){LIVE.lastId=d.id;takeReply(d.message);}}catch(e){}});};x.send();}catch(e){}
    setTimeout(poll,6000);})();
};
function x5render(){var b=$('appBody');if(!b||!cur||!R[cur]||GAME)return;var st=b.scrollTop;b.innerHTML=R[cur]();colors(b);b.scrollTop=st;LIVE_SIG='';}
function x5ok(t){banner('iPad',t,'bell','#1f8a4c');}
function x5unhex(h){var s='';for(var i=0;i+1<h.length;i+=2)s+='%'+h.substr(i,2);try{return decodeURIComponent(s);}catch(e){return '';}}
function x5trMidnight(){var now=Math.floor(Date.now()/1000);return 86400-((now+10800)%86400);}
var x5act=act,X5_INSTANT=['daily','zperk','equip','claimach','pref','lang','seen','msg','fadd','facc','fdel','block','unblock','marketlist','marketbuy','marketcancel','trade','tacc','tdec','adm'];
function x6own(code,on){if(!code||code==='-')return;var c=code.charAt(0),i=num(code.slice(1));if(MK_CATS.indexOf(c)<0||i<1)return;D.iv[c]=on?((D.iv[c]|0)|(1<<(i-1))):((D.iv[c]|0)&~(1<<(i-1)));if(!on&&D.eq&&num(D.eq[c])===i)D.eq[c]=0;}
function x6has(code){var c=code.charAt(0),i=num(code.slice(1));return i>0&&((D.iv[c]|0)&(1<<(i-1)))!==0;}
function x6mk(id){for(var i=0;i<MARKET.length;i++)if(MARKET[i][0]===id)return i;return -1;}
act=function(name,a,b,c,hint){
  var tr=D.lang==='tr';
  if(name==='case')return x5case(num(a),hint);
  if(X5_INSTANT.indexOf(name)<0)return x5act(name,a,b,c,hint);
  if(!LIVE.on||!LIVE.tk||!LIVE.rt){toast(tr?'Tablet oyundan açılmadı. Oyunda /ipad yaz.':'Open the tablet in game with /ipad.',false);return 0;}
  if(name==='daily'){
    if(D.claimed){toast(tr?'Bugünkü ödül zaten alındı. Sonraki ödül: '+hms(D.next):'Already claimed today. Next: '+hms(D.next),false);return 0;}
    var day=D.dailyNext||1,rw=D.rewards&&D.rewards[day-1];
    if(rw){D.ap+=rw[0];D.vc+=rw[1];}
    D.claimed=true;D.streak=day;D.next=x5trMidnight();
    SND.win(2);x5ok((tr?'Günlük ödül alındı':'Daily reward claimed')+(rw?' · +'+fmt(rw[0])+' AP · +'+fmt(rw[1])+' VC':''));
  }else if(name==='zperk'){
    var z=D.zup&&D.zup[num(a)];if(!z){toast(tr?'Gelişim verisi yok':'No upgrade data',false);return 0;}
    var free=Math.max(0,z[0]-z[2]-z[3]-z[4]);if(!free){toast(tr?'Bu sınıfta boş puan yok':'No free points for this class',false);return 0;}
    z[num(b)+2]++;SND.click();x5ok(tr?'Gelişim puanı verildi':'Upgrade point spent');
  }else if(name==='equip'){
    D.eq[a]=c===1||c==='1'?0:num(b);SND.click();x5ok(c===1||c==='1'?(tr?'Çıkarıldı':'Unequipped'):(tr?'Kuşanıldı':'Equipped'));
  }else if(name==='claimach'){
    var i=num(a);if((D.claimedMask|0)&(1<<i)){toast(tr?'Bu ödül zaten alındı':'Already claimed',false);return 0;}
    D.claimedMask=(D.claimedMask|0)|(1<<i);if(D.achReward){D.vc+=D.achReward[0];D.ap+=D.achReward[1];}SND.win(2);x5ok(tr?'Başarım ödülü alındı':'Achievement reward claimed');
  }else if(name==='marketlist'){
    var code=String(a),price=num(b);if(!x6has(code)){toast(tr?'Bu eşya sende yok':'You do not own this item',false);return 0;}
    var mine=MARKET.filter(function(m){return m[1]===LIVE.uid;}).length;if(mine>=8){toast(tr?'En fazla 8 ilan verebilirsin':'Up to 8 listings',false);return 0;}
    x6own(code,false);MARKET.push([-Date.now()%100000,LIVE.uid,D.name,code,price]);MARKET_CODE='';SND.buy?SND.buy():SND.click();x5ok((tr?'İlan yayında · ':'Listed · ')+fmt(price)+' VC');
  }else if(name==='marketbuy'){
    var k=x6mk(num(a)),m=MARKET[k];if(!m){toast(tr?'Bu ilan artık yok':'Listing is gone',false);return 0;}
    if(D.vc<m[4]){toast((tr?'Yetersiz VexCoin: ':'Not enough VexCoin: ')+fmt(m[4])+' VC',false);return 0;}
    if(x6has(m[3])){toast(tr?'Bu eşya zaten sende':'You already own this',false);return 0;}
    D.vc-=m[4];x6own(m[3],true);MARKET.splice(k,1);SND.win(2);x5ok((tr?'Satın alındı · -':'Bought · -')+fmt(m[4])+' VC');
  }else if(name==='marketcancel'){
    var k2=x6mk(num(a)),m2=MARKET[k2];if(!m2)return 0;if(m2[0]<0){toast(tr?'İlan kaydediliyor, bir saniye…':'Saving the listing, one second…',false);return 0;}
    if(x6has(m2[3]))D.vc+=m2[4];else x6own(m2[3],true);MARKET.splice(k2,1);SND.click();x5ok(tr?'İlan kaldırıldı, eşya geri geldi':'Listing removed, item returned');
  }else if(name==='trade'){
    if(b&&b!=='-'&&!x6has(String(b))){toast(tr?'Bu eşya sende yok':'You do not own this item',false);return 0;}
    OF.push([-1,num(a),plName(num(a)),String(b||'-'),String(c||'-'),0]);SND.click();x5ok(tr?'Takas teklifi gönderildi':'Trade offer sent');
  }else if(name==='tacc'||name==='tdec'){
    var oi=-1;for(var q=0;q<OF.length;q++)if(OF[q][0]===num(a))oi=q;var of=OF[oi];
    if(oi>=0){if(name==='tacc'&&of[5]===1){x6own(of[4],false);x6own(of[3],true);}OF.splice(oi,1);}
    SND[name==='tacc'?'win':'click'](2);x5ok(name==='tacc'?(tr?'Takas tamamlandı':'Trade complete'):(tr?'Teklif reddedildi':'Offer declined'));
  }else if(name==='adm'){
    var AM={reset:tr?'Sıfırlandı (herkes için)':'Reset for everyone',map:tr?'Harita değişiyor: ':'Changing map: ',rr:tr?'Round yeniden başlıyor':'Round restarting',say:tr?'Duyuru gönderildi':'Announcement sent'};
    if(a==='reset'){var w=num(b);if(w===4||w===5)D.top=[];if(w===0||w===5)D.tt=[];if(w===2||w===5)D.at=[];if(w===2)D.ach=0;if(w===3){D.claimed=false;D.streak=0;D.dailyNext=1;}}
    SND.click();x5ok((AM[a]||(tr?'Yönetim işlemi uygulandı':'Admin action done'))+(a==='map'?b:''));
  }else if(name==='msg'){
    var txt=x5unhex(b);if(!txt)return 0;MS.push([num(a),plName(num(a)),txt,Math.floor(Date.now()/1000),1]);SND.click();
  }else if(name==='fadd'||name==='facc'||name==='fdel'||name==='block'||name==='unblock'){
    var M={fadd:tr?'Arkadaşlık isteği gönderildi':'Friend request sent',facc:tr?'Arkadaş eklendi':'Friend added',fdel:tr?'Arkadaş silindi':'Friend removed',block:tr?'Engellendi':'Blocked',unblock:tr?'Engel kalktı':'Unblocked'};
    PL.forEach(function(p){if(p[0]!==num(a))return;if(name==='fadd'||name==='facc')p[4]=(p[4]|1)&~8;if(name==='fdel')p[4]&=~1;if(name==='block')p[4]=(p[4]|2)&~1;if(name==='unblock')p[4]&=~2;});
    if(name==='facc'||name==='fadd'){var nm=plName(num(a)),has=false;FR.forEach(function(f){if(f[0]===nm)has=true;});if(!has&&name==='facc')FR.push([nm,num(a)]);}
    SND.click();x5ok(M[name]);
  }
  var s=sendRaw(name,a,b,c);
  if(name!=='pref'&&name!=='lang'&&name!=='seen')x5render();
  if(!cur){HOME_SIG='';renderHome();}
  return s;
};
// cases: the server keeps the next item of every case ready (and saved), so the reel starts at once
function x5case(t,hint){
  var tr=D.lang==='tr',cs=caseData(),c=cs[t]||cs[0],price=c.vc|0,p=PR[t];
  if(REEL_RUN)return 0;
  if(D.vc<price){toast(tr?'Yetersiz VexCoin: '+price+' VC gerekli':'Not enough VexCoin: '+price+' VC needed',false);return 0;}
  if(!p||!p.code||!LIVE.on||!LIVE.tk)return x5act('case',t,'','',hint);
  var s=sendRaw('case',t,p.code,'');
  D.vc-=price;PR[t]=null;
  var cat=p.code.charAt(0),ix=num(p.code.slice(1));
  if(MK_CATS.indexOf(cat)>=0&&ix>0){var had=(D.iv[cat]|0)&(1<<(ix-1));if(had){var it=catList(cat)[ix-1];D.vc+=Math.max(10,Math.floor(((it&&it.vc)|0)/2));}else D.iv[cat]=(D.iv[cat]|0)|(1<<(ix-1));}
  else if(cat==='$')D.vc+=num(p.code.slice(1));else if(cat==='a')D.ap+=num(p.code.slice(1));
  D.cr={c:t,code:p.code,r:p.r};caseSel=t;
  if(cur==='case'){$('appBody').innerHTML=R['case']();colors($('appBody'));REEL_RUN=true;runReel();setTimeout(function(){REEL_RUN=false;LIVE_SIG='';},10500);}
  return s;
}
// leaderboards written by the server (playtime / achievements); the copy on the web host can be a few minutes old
(function(){try{var sc=document.createElement('script');sc.src='g6.js?t='+Math.floor(Date.now()/300000);sc.onload=function(){var g=window.VXG;if(!g)return;
  var r2=function(s){return rows(s,function(c){return {n:dec(c[0]),v:num(c[1])};});};
  var t=rows(g.t,function(c){return {n:dec(c[0]),lv:num(c[1]),k:num(c[2])};});if(t.length>(D.top||[]).length)D.top=t;
  if(g.tt)D.tt=r2(g.tt);if(g.at)D.at=r2(g.at);
  if(cur==='top'||cur==='time'||cur==='achtop')x5render();};document.getElementsByTagName('head')[0].appendChild(sc);}catch(e){}})();
// Drag the content, preserving clicks until a movement threshold is crossed.
(function(){var drag=null,suppress=0,inertia=0;document.addEventListener('mousedown',function(e){if(e.button!==0)return;inertia++;var el=e.target;if(/^(INPUT|TEXTAREA|SELECT|CANVAS)$/.test(el.tagName))return;while(el&&el!==document.body){if(el.scrollHeight>el.clientHeight+4&&(el.id==='appBody'||el.className==='hbody'||String(el.className).indexOf('hbody ')===0||el.className==='bubbles')){drag={el:el,y:e.clientY,last:e.clientY,t:Date.now(),v:0,moved:false};break;}el=el.parentNode;}},false);
document.addEventListener('mousemove',function(e){if(!drag)return;var dy=e.clientY-drag.last,dt=Math.max(1,Date.now()-drag.t);if(Math.abs(e.clientY-drag.y)>6)drag.moved=true;if(drag.moved){clearTimeout(LP.t);drag.el.scrollTop-=dy;drag.v=-dy/dt;drag.last=e.clientY;drag.t=Date.now();e.preventDefault();}},false);
document.addEventListener('mouseup',function(){if(!drag)return;var d=drag;drag=null;if(!d.moved)return;suppress=Date.now()+120;var epoch=++inertia,appEpoch=EPOCH,last=Date.now();function step(){if(appEpoch!==EPOCH||epoch!==inertia||Math.abs(d.v)<.03||!document.body.contains(d.el))return;var now=Date.now(),prev=d.el.scrollTop;d.el.scrollTop+=d.v*Math.min(32,now-last);last=now;d.v*=.88;if(d.el.scrollTop===prev)return;requestAnimationFrame(step);}requestAnimationFrame(step);},false);
document.addEventListener('click',function(e){if(Date.now()<suppress){e.preventDefault();e.stopImmediatePropagation();}},true);})();
// CS2-style case opening: the crate unlocks (latches + hiss), the reel spins fast, slows down with
// clicking ticks, slides a little past the mark and settles back, then the item is revealed in its rarity colour.
var CS6={
  latch:function(w){tone(1900,.03,'square',.05,w);tone(620,.06,'square',.05,w+.02,300);},
  hiss:function(w){for(var i=0;i<6;i++)tone(3200-i*300,.09,'sawtooth',.012,w+i*.05,2400-i*300);},
  whoosh:function(){tone(180,.5,'sawtooth',.03,0,900);tone(90,.6,'sine',.05,0,60);},
  tick:function(v){tone(2300,.018,'square',.03+.02*v);tone(1150,.02,'triangle',.02,.004);},
  land:function(){tone(420,.12,'triangle',.07);tone(210,.18,'sine',.06,.02);},
  reveal:function(r){var b=[330,392,440,523,587][r]||392;tone(b/2,.6,'sine',.07,0,b);for(var i=0;i<3+r*2;i++)tone(b*Math.pow(1.189,i%6)*(i>5?2:1),.28,i%2?'triangle':'sine',.05+.01*r,.12+i*.07);if(r>=3){tone(b*4,.9,'sine',.04,.5,b*6);tone(b*3,.9,'triangle',.04,.6,b*4.5);}}
};
runReel=function(){
  if(!D.cr||!$('reel'))return;
  var st=$('cstage'),ep=EPOCH,alive=function(){return ep===EPOCH&&$('cstage')&&cur==='case';};
  st.className='casestage shake6';
  CS6.latch(0.15);CS6.latch(0.45);CS6.latch(0.75);CS6.hiss(0.9);
  setTimeout(function(){if(!alive())return;st.className='casestage open6';CS6.whoosh();},1050);
  setTimeout(function(){if(!alive())return;st.style.display='none';$('rbox').style.display='block';$('rbox').className='reelbox spin6';spin();},1550);
  function spin(){
    var cs=caseData(),c=cs[D.cr.c]||cs[0],pool=(c.loot&&c.loot.length)?c.loot:[[D.cr.code,D.cr.r,1]],items=[],WIN=52;
    for(var i=0;i<60;i++){var p=pool[Math.floor(Math.random()*pool.length)];items.push(i===WIN?[D.cr.code,D.cr.r]:[p[0],p[1]]);}
    var reel=$('reel');reel.innerHTML=items.map(function(x){return '<div class="it r6'+x[1]+'"><div class="ic"><div class="ib" style="'+lg(160,RCOL[x[1]],'#15121a')+'">'+svg(x[0].charAt(0)==='k'?'blade':'gift')+'</div><b>'+esc(itemName(x[0]))+'</b><small class="t'+x[1]+'">'+esc(L('rar')[x[1]])+'</small><div class="rb r'+x[1]+'"></div></div></div>';}).join('');
    var box=reel.parentNode,W=128,half=box.clientWidth/2,stop=WIN*W+64-half+Math.floor(Math.random()*70)-35,over=Math.min(46,Math.max(18,W*0.28)),start=null,dur=6400,back=520,last=-1,lastT=0;
    function ease(t){return 1-Math.pow(1-t,3.2);}
    function put(x){reel.style.webkitTransform=reel.style.transform='translateX('+(-x)+'px)';var idx=Math.floor((x+half)/W);if(idx!==last){last=idx;var now=Date.now();if(now-lastT>28){lastT=now;CS6.tick(Math.min(1,(now-start)/dur));}}}
    function step(){
      if(!alive())return;var now=Date.now();if(!start)start=now;var t=Math.min(1,(now-start)/dur);
      put((stop+over)*ease(t));
      if(t<1){requestAnimationFrame(step);return;}
      var s0=now;(function settle(){if(!alive())return;var k=Math.min(1,(Date.now()-s0)/back),e=k*k*(3-2*k);put(stop+over-over*e);if(k<1)requestAnimationFrame(settle);else done(reel.children[WIN]);})();
    }
    requestAnimationFrame(step);
  }
  function done(el){
    var r=D.cr.r,col=RCOL[r];CS6.land();
    if(el)el.className+=' won6';$('rbox').className='reelbox stop6';
    setTimeout(function(){if(!alive())return;
      var fl=document.createElement('div');fl.className='flash6';fl.style.background='-webkit-radial-gradient(50% 50%,circle,'+rgba(col,.75)+','+rgba(col,0)+' 70%)';$('screen').appendChild(fl);setTimeout(function(){if(fl.parentNode)fl.parentNode.removeChild(fl);},900);
      $('winBox').innerHTML='<div class="win win6 w6r'+r+'" style="background:'+rgba(col,0.16)+';border:1px solid '+col+';-webkit-box-shadow:0 0 34px '+rgba(col,.55)+';box-shadow:0 0 34px '+rgba(col,.55)+'"><div class="rays6"></div><div class="wic" style="'+lg(160,col,'#15121a')+'">'+svg(D.cr.code.charAt(0)==='k'?'blade':'gift')+'</div><div class="rr t'+r+'">'+esc(L('rar')[r])+'</div><h2>'+esc(L('got'))+': '+esc(itemName(D.cr.code))+'</h2></div>';
      CS6.reveal(r);if(r>=2)confetti(col);banner(L('got'),itemName(D.cr.code),'gift',col);
    },380);
  }
};
// light theme: the status bar is dark text only over an open app (the home wallpaper is always dark)
(function(){var oa=openApp,gh=goHome;openApp=function(a,n){oa(a,n);$('status').className='status onapp';};goHome=function(){gh();$('status').className='status';};})();
// One tap: the lock opens on press, an app opens on release (matched by app name, so a home refresh
// between press and release can no longer swallow the tap); the browser's own click is then ignored.
(function(){var T=null,skip=0;
document.addEventListener('mousedown',function(e){if(e.button!==0)return;T=null;
if($('lock').className.indexOf('off')<0){if(DEMO)return;ac();unlock(D.page);skip=Date.now()+450;e.preventDefault();return;}
var el=findAttr(e.target,['data-app']);if(el&&!EDIT)T={a:el.getAttribute('data-app'),x:e.clientX,y:e.clientY};},true);
document.addEventListener('mouseup',function(e){var t=T;T=null;if(!t||LP.fired||EDIT||e.button!==0)return;if(Math.abs(e.clientX-t.x)>10||Math.abs(e.clientY-t.y)>10)return;clearTimeout(LP.t);skip=Date.now()+450;ac();openApp(t.a);},true);
document.addEventListener('click',function(e){if(Date.now()<skip){e.preventDefault();e.stopImmediatePropagation();}},true);})();
// ------------------------------------------------------------------ boot
applyTheme(); applyAccent(); applyBright(); setWall(); $('screen').className = 'screen locked'; $('lockLogo').innerHTML = LOGO(); $('lockHint').textContent = L('unlock');
$('lockNote').textContent = D.claimed ? '' : L('dailyReady');
if(DEMO){$('lockNote').textContent=tr('Bu tablet sadece oyunun içinden açılır.','This tablet only opens inside the game.');$('lockHint').textContent=tr('Sunucuda /ipad yaz','Type /ipad on the server');$('home').innerHTML='';$('screen').className='screen locked guard';}
$('demo').style.display='none';
takeHash(true);
setTimeout(listen,150);
renderHome(); clock(); setInterval(clock, 10000);
$('home').className = 'home hide';
if (GAMES.indexOf(D.page)>=0)D.page='home';
if (RAW.nl && (!D.page || D.page === 'home')) { $('lock').className = 'lock off'; $('screen').className = 'screen'; $('home').className = 'home'; }
else if (D.page && D.page !== 'home') { $('lock').className = 'lock off'; $('screen').className = 'screen'; $('home').className = 'home'; openApp(D.page, true); }
else { setTimeout(function () { SND.drone(); }, 400); }
})();
