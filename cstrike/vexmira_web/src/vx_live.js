// ================================================================== 6.2 LIVE LINK (actions + live data)
// The tablet sends actions to the game server through a public message relay (ntfy.sh, a plain GET
// "image beacon" that works in the CS 1.6 MOTD browser). The server validates the per-player token,
// runs the action, and writes the result + live data to u/<token>.js, which the tablet re-reads every
// 2 seconds. No account, no secret stored in the page. Tablet & mod: smurfsexy
var LIVE = { tk: dec(RAW.tk), uid: num(RAW.uid), rt: dec(RAW.rt), rh: dec(RAW.rh), on: num(RAW.rl) === 1, seq: 0, pend: {}, fileOk: false, polls: 0, fast: 0 };
var PL = [], FR = [], MS = [], NT = [], OF = [], MAPS = [];
function hexs(str) { var u = unescape(encodeURIComponent(str)), h = ''; for (var i = 0; i < u.length; i++) { var c = u.charCodeAt(i).toString(16); h += (c.length < 2 ? '0' : '') + c; } return h; }
function nextSeq() { var s = Math.floor(Date.now() / 100) % 1000000000; if (s <= LIVE.seq) s = LIVE.seq + 1; LIVE.seq = s; return s; }
function toast(t, ok) { banner(ok === false ? (D.lang === 'tr' ? 'Islem yapilamadi' : 'Action failed') : 'iPad', t, ok === false ? 'about' : 'bell', ok === false ? '#c8102e' : '#1f8a4c'); }
function act(name, a, b, c, cmdHint) {
  if (!LIVE.on || !LIVE.tk || !LIVE.rt) { toast((D.lang === 'tr' ? 'Canli baglanti kapali. Oyunda yaz: ' : 'Live link off. Type in game: ') + (cmdHint || '/ipad'), false); return 0; }
  var s = nextSeq(), msg = ['vx1', LIVE.tk, s, name, a == null ? '' : a, b == null ? '' : b, c == null ? '' : c].join('~');
  var img = new Image();
  img.src = 'http://' + LIVE.rh + '/' + LIVE.rt + '/publish?message=' + encodeURIComponent(msg) + '&title=vx';
  LIVE.pend[s] = { name: name, hint: cmdHint };
  LIVE.fast = Date.now() + 9000; busy(true);
  setTimeout(function () { if (LIVE.pend[s]) { delete LIVE.pend[s]; busy(false); toast((D.lang === 'tr' ? 'Sunucudan yanit gelmedi. ' : 'No answer from the server. ') + (cmdHint ? ((D.lang === 'tr' ? 'Oyunda yaz: ' : 'Type in game: ') + cmdHint) : ''), false); } }, 12000);
  return s;
}
function busy(on) { var b = $('busy'); if (!b) { b = document.createElement('div'); b.id = 'busy'; b.className = 'busy'; b.innerHTML = '<i class="ring"></i>'; $('screen').appendChild(b); } b.style.display = on ? 'block' : 'none'; }
function pollU() {
  if (!LIVE.tk) return;
  var old = $('vxu'); if (old) old.parentNode.removeChild(old);
  var s = document.createElement('script'); s.id = 'vxu'; s.src = 'u_' + LIVE.tk + '.js?t=' + Date.now();
  s.onload = function () { LIVE.fileOk = true; if (window.VXU) applyU(window.VXU); };
  s.onerror = function () { LIVE.fileOk = false; linkDot(); };
  document.getElementsByTagName('head')[0].appendChild(s);
}
(function loopU() { LIVE.polls++; pollU(); setTimeout(loopU, Date.now() < LIVE.fast ? 700 : 2000); })();
function linkDot() { var d = $('linkDot'); if (d) { d.className = 'ldot ' + (LIVE.fileOk ? (LIVE.on ? 'g' : 'y') : 'r'); } }
function typing() { var a = document.activeElement; return a && (a.tagName === 'INPUT' || a.tagName === 'TEXTAREA'); }
var REEL_RUN = false;
function applyU(u) {
  linkDot();
  D.ap = u.ap; D.vc = u.vc; D.lv = u.lv; D.xp = u.xp; D.xn = u.xn; D.iv = masks(u.iv); D.eq = masks(u.eq);
  var dy = String(u.dy).split('~'); D.streak = num(dy[0]); D.claimed = num(dy[1]) === 1; D.next = num(dy[2]);
  PL = u.pl || []; FR = u.fr || []; MS = u.ms || []; NT = u.nt || []; OF = u.of || []; MAPS = u.maps || MAPS; D.un = u.un | 0;
  if (u.me) LIVE.uid = u.me;
  var acked = false;
  for (var k in LIVE.pend) if (num(k) <= u.ack) { acked = LIVE.pend[k]; delete LIVE.pend[k]; }
  if (acked) { busy(false); onResult(acked.name, String(u.res || '')); }
  if (!typing() && !REEL_RUN && cur && LIVE_APPS.indexOf(cur) >= 0 && !GAME) { var st = $('appBody').scrollTop; $('appBody').innerHTML = R[cur](); $('appBody').scrollTop = st; }
  if (!cur) renderHome();
}
var LIVE_APPS = ['msg', 'friends', 'notif', 'trade', 'adm', 'daily', 'inv', 'prof', 'top'];
function onResult(name, res) {
  var p = res.split('~'), ok = p[0] === 'ok', tr = D.lang === 'tr';
  if (!ok) { toast(p.slice(1).join(' ') || (tr ? 'Hata' : 'Error'), false); return; }
  if (name === 'case' && p[1] === 'case') {
    D.cr = { c: num(p[2]), code: p[3], r: num(p[4]) }; caseSel = D.cr.c;
    if (cur === 'case') { $('appBody').innerHTML = R['case'](); REEL_RUN = true; runReel(); setTimeout(function () { REEL_RUN = false; }, 8000); }
    return;
  }
  var M = { daily: tr ? 'Gunluk odul alindi' : 'Daily reward claimed', equip: tr ? 'Kusanildi' : 'Equipped', msg: tr ? 'Mesaj gonderildi' : 'Message sent',
    fadd: tr ? 'Arkadaslik istegi gonderildi' : 'Friend request sent', facc: tr ? 'Arkadas eklendi' : 'Friend added', fdel: tr ? 'Arkadas silindi' : 'Friend removed',
    block: tr ? 'Engellendi' : 'Blocked', unblock: tr ? 'Engel kalkti' : 'Unblocked', trade: tr ? 'Takas teklifi gonderildi' : 'Trade offer sent',
    tacc: tr ? 'Takas tamamlandi' : 'Trade complete', tdec: tr ? 'Teklif reddedildi' : 'Offer declined', adm: tr ? 'Yonetim islemi uygulandi' : 'Admin action done',
    rr: tr ? 'Round yeniden basliyor' : 'Round restarting', map: tr ? 'Harita degisiyor' : 'Map changing', say: tr ? 'Duyuru gonderildi' : 'Announcement sent' };
  if (p[1] !== 'seen' && p[1] !== 'ping') toast(M[p[1]] || M[name] || 'OK', true);
  if (name === 'daily') SND.win(2);
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
