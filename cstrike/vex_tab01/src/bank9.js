// ================================================================== v9: Vexmira Bank + Season Pass
// Server side: vex_bank.sma. Data arrives in the tablet address (bk, bp, bq, bh). Every action is shown
// at once (same rules as the server) and the server's answer corrects the data if something changed.
IC.bank='<path d="M3 9.5L12 4l9 5.5"/><path d="M4.5 9.5h15M5.5 10v8M9.5 10v8M14.5 10v8M18.5 10v8M3.5 18.5h17M2.5 21h19"/>';
IC.pass='<path d="M3.5 7.5a2 2 0 0 0 2-2h13a2 2 0 0 0 2 2v3a2 2 0 0 0 0 3v3a2 2 0 0 0-2 2h-13a2 2 0 0 0-2-2v-3a2 2 0 0 0 0-3z"/><path d="M14.5 6v12" stroke-dasharray="1.6 2"/><path d="M8 10.5l1 2 2 .3-1.5 1.4.4 2-1.9-1-1.9 1 .4-2L5 12.8l2-.3z"/>';
IC.loan='<rect x="2.5" y="6" width="19" height="12" rx="2.2"/><circle cx="12" cy="12" r="2.6"/><path d="M6 9v6M18 9v6"/>';
IC.hist='<path d="M3.5 12a8.5 8.5 0 1 0 2.5-6"/><path d="M3.5 4v4h4M12 7.5V12l3 2"/>';
IC.down='<path d="M12 4v14M6 12l6 6 6-6"/>';
IC.up='<path d="M12 20V6M6 12l6-6 6 6"/>';
IC.snow='<path d="M12 2.5v19M3.8 7.2l16.4 9.6M3.8 16.8l16.4-9.6M9.5 4l2.5 2.5L14.5 4M9.5 20l2.5-2.5 2.5 2.5"/>';
ICOL.bank='#2f6bff,#0b1f5c';ICOL.daily='#ffb340,#b4237a';
(function(){var t=T.tr,e=T.en;t.bank='Vexmira Bank';e.bank='Vexmira Bank';t.daily='Sezon Bileti';e.daily='Season Pass';t.dailyReady='Günlük giriş ödülün ve görevlerin hazır';e.dailyReady='Your login reward and missions are ready';})();
if(CATALOG.indexOf('bank')<0)CATALOG.splice(CATALOG.indexOf('daily')+1,0,'bank');
if(CORE.indexOf('bank')<0)CORE.push('bank');
CATS[0][1].push('bank');
var BK={d:[0,0],left:[0,0],score:500,blk:false,frz:[0,0],lim:[0,0],sent:[0,0],dmax:[300,3000],minlv:3,late:[false,false],prin:[0,0],t:Date.now(),ok:false};
var BP={s:1,xp:0,tx:750,f:[0,0],p:[0,0],prem:false,days:30,price:300,ok:false},BQ={d:[],w:[],reset:0,t:Date.now(),ok:false},BH=null,BH_T=0;
var BCUR=['VC','AP'];
X4.bt='home';X4.bcur='v';X4.blc='v';X4.blp='0';X4.bconf='';X4.bto='';X4.bpall='';
function bkC(k){return k==='a'?1:0;}
function bkBal(c){return c?D.ap:D.vc;}
function bkSendable(c){return Math.max(0,bkBal(c)-BK.d[c]);}
function bkDayLeft(c){return Math.max(0,BK.dmax[c]-BK.sent[c]);}
function bkLeft(c){return BK.left[c]-Math.floor((Date.now()-BK.t)/1000);}
function bkDur(s){var tr=D.lang==='tr';if(s<=0)return tr?'vadesi geçti':'overdue';var d=Math.floor(s/86400),h=Math.floor(s%86400/3600),m=Math.floor(s%3600/60);return d?d+(tr?' gün ':'d ')+h+(tr?' sa':'h'):h?h+(tr?' sa ':'h ')+m+(tr?' dk':'m'):m+(tr?' dk':'m');}
function bkAgo(s){var tr=D.lang==='tr';return s<60?(tr?'şimdi':'now'):s<3600?Math.floor(s/60)+(tr?' dk':'m'):s<86400?Math.floor(s/3600)+(tr?' sa':'h'):Math.floor(s/86400)+(tr?' gün':'d');}
function bkPlan(c,p){return {days:c?(p?3:1):(p?7:3),pct:p?20:10};}
function bkScoreName(s){var tr=D.lang==='tr';return s>=800?(tr?'Mükemmel':'Excellent'):s>=600?(tr?'Çok iyi':'Very good'):s>=450?(tr?'İyi':'Good'):s>=250?(tr?'Orta':'Fair'):(tr?'Riskli':'Risky');}
function bkScoreCol(s){return s>=600?'#30d158':s>=450?'#0a84ff':s>=250?'#ff9f0a':'#ff453a';}
function bkAcct(){var h=0,s=String(D.name||'');for(var i=0;i<s.length;i++)h=(h*31+s.charCodeAt(i))%100000000;var n=('00000000'+h).slice(-8);return n.slice(0,4)+' '+n.slice(4);}
function bkInt(v){v=String(v==null?'':v).replace(/[^0-9]/g,'');return v?Math.min(100000000,parseInt(v,10)):0;}
function bkVal(id){var e=$(id);return e?bkInt(e.value):0;}
// ---- data from the address
(function(){var hu=hashU;hashU=function(o){var u=hu(o),c;
  if(o.bk!==undefined){c=String(o.bk).split('~').map(function(x){return num(x);});u.bk={d:[c[0],c[2]],left:[c[1],c[3]],score:c[4],blk:c[5]===1,frz:[c[6],c[7]],lim:[c[8],c[9]],sent:[c[10],c[11]],dmax:[c[12],c[13]],minlv:c[14],late:[c[15]===1,c[16]===1],prin:[c[17],c[18]],t:Date.now(),ok:true};}
  if(o.bp!==undefined){c=String(o.bp).split('~').map(function(x){return num(x);});u.bp={s:c[0],xp:c[1],tx:Math.max(1,c[2]),f:[c[3],c[4]],p:[c[5],c[6]],prem:c[7]===1,days:c[8],price:c[9],ok:true};}
  if(o.bq!==undefined){var q=String(o.bq).split('~'),parts=String(q[0]).split('|'),mm=function(s){return String(s||'').split(',').filter(function(x){return x;}).map(function(r){var a=r.split('.');return [num(a[0]),num(a[1]),num(a[2]),num(a[3]),num(a[4])];});};u.bq={d:mm(parts[0]),w:mm(parts[1]),reset:num(q[1]),t:Date.now(),ok:true};}
  if(o.bh!==undefined)u.bh=rows(o.bh,function(r){return [num(r[0]),num(r[1]),num(r[2]),num(r[3]),dec(r[4]||'')];});
  return u;};})();
(function(){var au=applyU;applyU=function(u){if(u.bk)BK=u.bk;if(u.bp)BP=u.bp;if(u.bq)BQ=u.bq;if(u.bh){BH=u.bh;BH_T=Date.now();}D.bk9=[BK.d,BK.blk,BK.frz,BK.sent,BK.score,BP.xp,BP.f,BP.p,BP.prem,BQ.d,BQ.w,BH?BH.length:0,BH&&BH[0]?BH[0][3]:0];au(u);};})();
if(LIVE_APPS.indexOf('bank')<0)LIVE_APPS.push('bank');
// ---- bank screens
function bkCard(c){
  var tr=D.lang==='tr',v=bkBal(c),name=esc(D.name||'');
  return '<div class="bkcard '+(c?'ap':'vc')+'"><div class="bkc1"><span class="bklogo">'+emblem()+'</span><b>VEXMIRA</b><em>'+(c?'AMMO PACK':'VEXCOIN')+'</em></div>'+
    '<div class="bkchip"><i></i></div><div class="bkbal"><small>'+esc(tr?'Kullanılabilir bakiye':'Available balance')+'</small><strong>'+fmtFull(v)+' <i>'+BCUR[c]+'</i></strong></div>'+
    '<div class="bkc3"><span>'+name+'</span><span>•••• '+bkAcct().slice(-4)+(c?'1':'0')+'</span></div></div>';
}
function fmtFull(n){n=num(n);var s=String(Math.abs(n)),o='';while(s.length>3){o='.'+s.slice(-3)+o;s=s.slice(0,-3);}return (n<0?'-':'')+s+o;}
function bkBlockBox(){
  if(!BK.blk&&!BK.frz[0]&&!BK.frz[1])return '';var tr=D.lang==='tr';
  var debt=[];for(var c=0;c<2;c++)if(BK.d[c]&&BK.late[c])debt.push(fmtFull(BK.d[c])+' '+BCUR[c]);
  return '<div class="bkblock"><div class="bkbi">'+svg('lock')+'</div><div><b>'+esc(BK.blk?(tr?'Hesabın bloke':'Account blocked'):(tr?'Dondurulan bakiye':'Frozen balance'))+'</b><p>'+
    esc(BK.blk?(tr?'Vadesi geçen kredi borcu: ':'Overdue loan debt: ')+debt.join(' · ')+(tr?'. Kazandığın her şey önce borca gider, kalanı bankada dondurulur. Borç kapanınca geri gelir.':'. Everything you earn pays the debt first, the rest is frozen in the bank and comes back when the debt is paid.'):'')+
    '</p><div class="bkfz">'+svg('snow')+esc((tr?'Dondurulan: ':'Frozen: ')+fmtFull(BK.frz[0])+' VC · '+fmtFull(BK.frz[1])+' AP')+'</div></div></div>';
}
function bkTabs(){var tr=D.lang==='tr';return x4segv([['home',tr?'Hesabım':'Account'],['send',tr?'Transfer':'Transfer'],['loan',tr?'Kredi':'Credit'],['hist',tr?'Geçmiş':'History']],'bt');}
R.bank=function(){
  var tr=D.lang==='tr',h='';if(X4._bt!==X4.bt){X4._bt=X4.bt;X4.bconf='';}
  h+='<div class="bkhead"><div class="bkhl"><span class="bkbrand" style="'+grad('bank')+'">'+svg('bank')+'</span><div><h1>Vexmira Bank</h1><p>'+esc(tr?'Bireysel hesap · ':'Personal account · ')+'TR'+bkAcct().replace(' ','')+' 9'+'</p></div></div>'+
    '<div class="bkhr"><small>'+esc(tr?'Kredi notu':'Credit score')+'</small><b style="color:'+bkScoreCol(BK.score)+'">'+BK.score+'</b></div></div>';
  h+=bkBlockBox()+bkTabs();
  if(!BK.ok)h+='<div class="x4warn"><div class="x4ci">'+x4ic('bank','blue')+'</div><span>'+esc(tr?'Banka bilgisi sunucudan bekleniyor (vex_bank eklentisi). Tableti /ipad ile yeniden aç.':'Waiting for bank data from the server (vex_bank plugin). Reopen the tablet with /ipad.')+'</span></div>';
  if(X4.bt==='send')h+=bkSend();else if(X4.bt==='loan')h+=bkLoanTab();else if(X4.bt==='hist')h+=bkHist();else h+=bkHome();
  return x4wrap(h+x4f9());
};
function x4f9(){return '<div class="x4f">'+esc(D.lang==='tr'?'Vexmira Bank · tüm işlemler sunucuda doğrulanır ve kayıt altına alınır.':'Vexmira Bank · every operation is verified and logged on the server.')+'</div>';}
function bkHome(){
  var tr=D.lang==='tr',h='<div class="bkcards">'+bkCard(0)+bkCard(1)+'</div>';
  h+='<div class="bkqa">'+[['send','send',tr?'Para gönder':'Send money','blue'],['loan','loan',tr?'Kredi çek':'Get credit','green'],['loan','down',tr?'Borç öde':'Repay','orange'],['hist','hist',tr?'Hesap hareketleri':'Activity','gray']].map(function(q){return '<div class="bkq" data-x4="bt='+q[0]+'"><span class="bkqi">'+x4ic(q[1],q[3])+'</span><b>'+esc(q[2])+'</b></div>';}).join('')+'</div>';
  var rows='';
  for(var c=0;c<2;c++)if(BK.d[c])rows+=x4row(x4ic('loan',BK.late[c]?'red':'green'),esc((tr?'Açık kredi · ':'Open loan · ')+BCUR[c]),esc((tr?'Kalan borç ':'Debt left ')+fmtFull(BK.d[c])+' '+BCUR[c]+' · '+(BK.late[c]?(tr?'GECİKMEDE':'OVERDUE'):(tr?'vade: ':'due in ')+bkDur(bkLeft(c)))),svg('chev'),'data-x4="bt=loan"','nav');
  if(!rows)rows=x4row(x4ic('check','green'),esc(tr?'Borcun yok':'No debt'),esc(tr?'Kredi limitin: ':'Credit limit: ')+fmtFull(BK.lim[0])+' VC · '+fmtFull(BK.lim[1])+' AP','');
  h+=x4sec(tr?'Krediler':'Credit',rows);
  var sc=BK.score;
  h+=x4sec(tr?'Hesap özeti':'Summary',
    x4row(x4ic('chart','indigo'),esc(tr?'Kredi notu':'Credit score'),esc(bkScoreName(sc)+' · '+sc+' / 1000')+x4bar(sc/10),'')+
    x4row(x4ic('send','blue'),esc(tr?'Bugünkü transfer limiti':'Transfer limit today'),esc(fmtFull(bkDayLeft(0))+' VC · '+fmtFull(bkDayLeft(1))+' AP '+(tr?'kaldı':'left')),'')+
    x4row(x4ic('lock','gray'),esc(tr?'Güvenlik':'Security'),esc(tr?'Komutlar imzalı · transfer sadece oyundaki oyunculara · borçla alınan para gönderilemez':'Signed commands · transfers only to players in game · borrowed money cannot be sent'),''));
  return h;
}
function bkSend(){
  var tr=D.lang==='tr',c=bkC(X4.bcur),list=others(true),h='',sel=num(X4.bto),selP=null;
  list.forEach(function(p){if(p[0]===sel)selP=p;});
  if(!selP)X4.bto='';
  h+='<div class="x4s">'+esc(tr?'1 · Alıcı (oyundaki oyuncular)':'1 · Receiver (players in game)')+'</div>';
  if(!list.length)h+='<div class="x4g">'+x4empty('friends','blue',tr?'Oyunda başka oyuncu yok':'No other players in game',tr?'Transfer sadece şu an oyunda olan oyunculara yapılır.':'Transfers go only to players who are in the game now.')+'</div>';
  else h+='<div class="x4g bkppl">'+list.map(function(p){var on=p[0]===sel;return '<div class="bkp'+(on?' on':'')+'" data-x4="bto='+p[0]+'">'+x4ava(p[1],p[3],'sm',p[4]&16)+'<b>'+esc(p[1])+'</b><small>Lv '+p[3]+'</small>'+(on?'<i class="bkok">'+svg('check')+'</i>':'')+'</div>';}).join('')+'</div>';
  h+='<div class="x4s">'+esc(tr?'2 · Tutar':'2 · Amount')+'</div><div class="x4g x4pad bkform">'+x4segv([['v','VexCoin'],['a','AmmoPack']],'bcur')+
    '<div class="bkamt"><input id="bkAmt" type="text" inputmode="numeric" maxlength="9" placeholder="0" value="'+(X4.bamt||'')+'"><span>'+BCUR[c]+'</span></div>'+
    '<div class="bkchips">'+(c?[50,100,250,500]:[10,25,50,100]).map(function(v){return '<span data-bkamt="'+v+'">'+v+'</span>';}).join('')+'<span data-bkamt="max">'+esc(tr?'Tümü':'Max')+'</span></div>'+
    '<div class="bkinfo"><span>'+esc(tr?'Gönderilebilir':'Sendable')+'<b>'+fmtFull(bkSendable(c))+' '+BCUR[c]+'</b></span><span>'+esc(tr?'Bugün kalan limit':'Limit left today')+'<b>'+fmtFull(bkDayLeft(c))+' '+BCUR[c]+'</b></span></div>'+
    (BK.d[c]?'<p class="bknote">'+esc(tr?'Bu para biriminde '+fmtFull(BK.d[c])+' '+BCUR[c]+' borcun var; borcu aşan bakiyeni gönderebilirsin.':'You owe '+fmtFull(BK.d[c])+' '+BCUR[c]+'; you can send only the balance above your debt.')+'</p>':'')+
    (X4.bconf==='send'&&selP?bkConfirm(tr?'Transferi onayla':'Confirm transfer',(tr?selP[1]+' adlı oyuncuya ':'Send ')+fmtFull(num(X4.bamt))+' '+BCUR[c]+(tr?' gönderilecek.':' to '+selP[1]+'.'),'send'):
     '<span class="x4b big'+(selP?'':' dis')+'" data-bk="send">'+esc(selP?(tr?'Devam et':'Continue'):(tr?'Önce alıcı seç':'Pick a receiver first'))+'</span>')+'</div>';
  return h;
}
function bkConfirm(title,text,what){var tr=D.lang==='tr';return '<div class="bkconf"><b>'+esc(title)+'</b><p>'+esc(text)+'</p><div class="bkcb"><span class="x4b" data-bk="cancel">'+esc(tr?'Vazgeç':'Cancel')+'</span><span class="x4b g" data-bk="ok'+what+'">'+esc(tr?'Onayla':'Confirm')+'</span></div></div>';}
function bkLoanTab(){
  var tr=D.lang==='tr',h='',sc=BK.score;
  h+='<div class="bkscore"><div class="bkg"><b style="color:'+bkScoreCol(sc)+'">'+sc+'</b><small>/ 1000</small></div><div class="bkst"><b>'+esc(tr?'Kredi notun: ':'Credit score: ')+esc(bkScoreName(sc))+'</b>'+x4bar(sc/10)+
    '<p>'+esc(tr?'Zamanında ödeme +40 · gecikme −150 · limitin notuna göre %50–%150 arası değişir.':'On time +40 · late −150 · your limit moves between 50% and 150% with your score.')+'</p></div></div>';
  for(var c=0;c<2;c++){
    if(!BK.d[c])continue;
    var left=bkLeft(c),late=BK.late[c];
    h+='<div class="x4s">'+esc((tr?'Açık kredi · ':'Open loan · ')+(c?'AmmoPack':'VexCoin'))+'</div><div class="x4g x4pad bkloan'+(late?' late':'')+'">'+
      '<div class="bkld"><div><small>'+esc(tr?'Kalan borç':'Debt left')+'</small><b>'+fmtFull(BK.d[c])+' '+BCUR[c]+'</b></div><div><small>'+esc(tr?'Çekilen':'Borrowed')+'</small><b>'+fmtFull(BK.prin[c])+' '+BCUR[c]+'</b></div><div><small>'+esc(tr?'Vade':'Due')+'</small><b class="'+(late||left<43200?'warn':'')+'">'+esc(late?(tr?'Gecikmede':'Overdue'):bkDur(left))+'</b></div></div>'+
      (late?'<p class="bknote red">'+esc(tr?'Vade geçti: %10 gecikme cezası eklendi ve hesap bloke. Kazancın otomatik olarak borca gidiyor.':'Overdue: a 10% late fee was added and the account is blocked. Your income pays the debt automatically.')+'</p>':'')+
      '<div class="bkamt sm"><input id="bkPay'+c+'" type="text" inputmode="numeric" maxlength="9" placeholder="'+esc(tr?'Tutar (boş = tamamı)':'Amount (empty = all)')+'"><span>'+BCUR[c]+'</span></div>'+
      '<span class="x4b big g" data-bk="pay'+c+'">'+esc(tr?'Borç öde':'Repay')+'</span></div>';
  }
  var lc=bkC(X4.blc);
  h+='<div class="x4s">'+esc(tr?'Yeni kredi':'New credit')+'</div><div class="x4g x4pad bkform">'+x4segv([['v','VexCoin'],['a','AmmoPack']],'blc');
  var why='';
  if(BK.blk)why=tr?'Hesabın bloke. Önce gecikmiş borcunu kapat.':'Account blocked. Pay the overdue debt first.';
  else if(BK.d[lc])why=tr?'Bu para biriminde zaten açık kredin var.':'You already have a loan in this currency.';
  else if(D.lv<BK.minlv)why=(tr?'Kredi için en az seviye ':'Credit needs level ')+BK.minlv+'.';
  else if(BK.score<250)why=tr?'Kredi notun 250\'nin altında.':'Credit score below 250.';
  var lim=BK.lim[lc],min=lc?50:10;
  if(!why&&lim<min)why=tr?'Kredi limitin yetersiz.':'Credit limit too low.';
  if(why)h+='<p class="bknote">'+esc(why)+'</p>';
  else{
    var amt=Math.min(lim,Math.max(min,num(X4.blamt)||Math.floor(lim/2)));X4.blamt=String(amt);
    h+='<div class="bklim"><span>'+esc(tr?'Kredi limitin':'Your limit')+'</span><b>'+fmtFull(lim)+' '+BCUR[lc]+'</b></div>'+
      '<div class="bkamt"><input id="bkLoanAmt" type="text" inputmode="numeric" maxlength="9" value="'+amt+'"><span>'+BCUR[lc]+'</span></div>'+
      '<div class="bkchips">'+[25,50,75,100].map(function(p){return '<span data-bkla="'+Math.max(min,Math.floor(lim*p/100))+'">%'+p+'</span>';}).join('')+'</div>'+
      '<div class="bkplans">'+[0,1].map(function(p){var pl=bkPlan(lc,p),tot=amt+Math.floor(amt*pl.pct/100);return '<div class="bkplan'+(X4.blp===String(p)?' on':'')+'" data-x4="blp='+p+'"><b>'+pl.days+' '+esc(tr?'gün':'days')+'</b><small>'+esc(tr?'Faiz %':'Interest ')+pl.pct+(tr?'':'%')+'</small><em>'+esc(tr?'Geri ödeme':'Repay')+' '+fmtFull(tot)+' '+BCUR[lc]+'</em></div>';}).join('')+'</div>'+
      (X4.bconf==='loan'?bkConfirm(tr?'Krediyi onayla':'Confirm credit',(tr?fmtFull(amt)+' '+BCUR[lc]+' hesabına yatacak. '+bkPlan(lc,num(X4.blp)).days+' gün içinde '+fmtFull(amt+Math.floor(amt*bkPlan(lc,num(X4.blp)).pct/100))+' '+BCUR[lc]+' geri ödemelisin, yoksa hesabın bloke olur.':fmtFull(amt)+' '+BCUR[lc]+' will be paid out. Repay '+fmtFull(amt+Math.floor(amt*bkPlan(lc,num(X4.blp)).pct/100))+' '+BCUR[lc]+' within '+bkPlan(lc,num(X4.blp)).days+' days or the account gets blocked.'),'loan'):
       '<span class="x4b big" data-bk="loan">'+esc(tr?'Kredi çek':'Get credit')+'</span>');
  }
  h+='</div>';
  h+=x4sec(tr?'Kurallar':'Rules',x4row(x4ic('about','gray'),esc(tr?'Vade geçerse':'If you are late'),esc(tr?'%10 gecikme cezası, kredi notu −150, hesap bloke: kazancın otomatik borca gider, kalan bakiyen dondurulur ve hiçbir şey alamazsın. Borç kapanınca bloke kalkar, dondurulan bakiye geri gelir.':'10% late fee, score −150, account blocked: income pays the debt, the rest is frozen and you cannot buy anything. When the debt is paid the block is lifted and the frozen balance comes back.'),'')+
    x4row(x4ic('time','blue'),esc(tr?'Vadeler':'Terms'),esc(tr?'VexCoin: 3 gün %10 · 7 gün %20 — AmmoPack: 1 gün %10 · 3 gün %20 (gerçek zaman, oyunda olmasan da işler)':'VexCoin: 3 days 10% · 7 days 20% — AmmoPack: 1 day 10% · 3 days 20% (real time, also while you are offline)'),''));
  return h;
}
var BKH_K={1:['up','red'],2:['down','green'],3:['loan','blue'],4:['check','green'],5:['about','red'],6:['snow','teal'],7:['snow','green'],8:['pass','purple']};
function bkHist(){
  var tr=D.lang==='tr';
  if(!BH||Date.now()-BH_T>30000){if(!DEMO&&LIVE.on&&Date.now()-(bkHist.t||0)>8000){bkHist.t=Date.now();sendRaw('view','bank');}}
  if(!BH)return x4sec('',x4empty('hist','gray',tr?'Hesap hareketleri yükleniyor':'Loading activity',tr?'Sunucudan son işlemler isteniyor…':'Asking the server for recent activity…'));
  if(!BH.length)return x4sec('',x4empty('hist','gray',tr?'Henüz işlem yok':'No activity yet',tr?'Transfer, kredi ve sezon bileti işlemlerin burada görünür.':'Transfers, credit and season pass purchases show up here.'));
  var N={1:tr?'Giden transfer':'Sent',2:tr?'Gelen transfer':'Received',3:tr?'Kredi kullanıldı':'Loan paid out',4:tr?'Borç ödemesi':'Repayment',5:tr?'Gecikme cezası':'Late fee',6:tr?'Bloke: borca giden':'Blocked: paid to debt',7:tr?'Bloke iadesi':'Unfrozen',8:tr?'Sezon Bileti Premium':'Season Pass Premium'};
  var plus={2:1,3:1,7:1};
  return x4sec(tr?'Son işlemler':'Recent activity',BH.map(function(r){var k=BKH_K[r[0]]||['about','gray'],age=r[3]+Math.floor((Date.now()-BH_T)/1000);
    return x4row(x4ic(k[0],k[1]),esc(N[r[0]]||'?')+(r[4]?' · '+esc(r[4]):''),esc(bkAgo(age)+(tr?' önce':' ago')),'<b class="bkamtv '+(plus[r[0]]?'pos':'neg')+'">'+(plus[r[0]]?'+':'−')+fmtFull(r[1])+' '+BCUR[r[2]?1:0]+'</b>');}).join(''));
}
// ---- actions (shown at once, the server confirms)
function bkAct(name,a,b,c){if(!LIVE.on||!LIVE.tk||!LIVE.rt){toast(D.lang==='tr'?'Tablet oyundan açılmadı. Oyunda /ipad yaz.':'Open the tablet in game with /ipad.',false);return 0;}return x5act(name,a,b,c);}
function bkHistAdd(k,amt,c,nm){if(!BH)return;BH.unshift([k,amt,c,0,nm||'']);BH_T=Date.now();if(BH.length>8)BH.length=8;}
document.addEventListener('click',function(e){
  var el=findAttr(e.target,['data-bk','data-bkamt','data-bkla','data-bp']);if(!el||!cur)return;
  var tr=D.lang==='tr',v;
  if((v=el.getAttribute('data-bkamt'))!==null){var c=bkC(X4.bcur),n=v==='max'?Math.min(bkSendable(c),bkDayLeft(c)):num(v);X4.bamt=String(n);var i=$('bkAmt');if(i)i.value=n;SND.click();return;}
  if((v=el.getAttribute('data-bkla'))!==null){X4.blamt=v;X4.bconf='';x4re();SND.click();return;}
  if((v=el.getAttribute('data-bp'))!==null){bpClick(v);return;}
  v=el.getAttribute('data-bk');
  if(v==='cancel'){X4.bconf='';x4re();SND.click();return;}
  if(v==='send'){
    var cs=bkC(X4.bcur),amt=bkVal('bkAmt'),to=num(X4.bto);X4.bamt=amt?String(amt):'';
    if(!to){toast(tr?'Önce alıcıyı seç':'Pick a receiver first',false);return;}
    if(BK.blk){toast(tr?'Hesabın bloke: önce borcunu öde':'Account blocked: pay your debt first',false);return;}
    if(D.lv<BK.minlv){toast((tr?'Transfer için gereken seviye: ':'Level needed to send: ')+BK.minlv,false);return;}
    if(amt<1){toast(tr?'Tutar gir':'Enter an amount',false);return;}
    if(amt>bkDayLeft(cs)){toast((tr?'Günlük limitin kaldı: ':'Daily limit left: ')+fmtFull(bkDayLeft(cs))+' '+BCUR[cs],false);return;}
    if(amt>bkSendable(cs)){toast((tr?'Gönderilebilir bakiye: ':'Sendable balance: ')+fmtFull(bkSendable(cs))+' '+BCUR[cs],false);return;}
    if(Date.now()<(bkAct.next||0)){toast(tr?'İki transfer arası 3 saniye bekle':'Wait 3 seconds between transfers',false);return;}
    X4.bconf='send';x4re();SND.click();return;}
  if(v==='oksend'){
    var c2=bkC(X4.bcur),a2=num(X4.bamt),to2=num(X4.bto),nm=plName(to2);X4.bconf='';
    if(!bkAct('bksend',to2,X4.bcur,a2))return;
    if(c2)D.ap-=a2;else D.vc-=a2;BK.sent[c2]+=a2;bkAct.next=Date.now()+3000;bkHistAdd(1,a2,c2,nm);X4.bamt='';
    SND.win(1);x5ok((tr?nm+' adlı oyuncuya ':'Sent to '+nm+': ')+fmtFull(a2)+' '+BCUR[c2]+(tr?' gönderildi':''));x4re();return;}
  if(v==='loan'){X4.blamt=String(bkVal('bkLoanAmt')||X4.blamt);var lc=bkC(X4.blc),la=num(X4.blamt),lim=BK.lim[lc],mn=lc?50:10;
    if(la<mn||la>lim){toast((tr?'Kredi tutarı: ':'Loan amount: ')+mn+'–'+fmtFull(lim)+' '+BCUR[lc],false);return;}
    X4.bconf='loan';x4re();SND.click();return;}
  if(v==='okloan'){
    var c3=bkC(X4.blc),a3=num(X4.blamt),pl=bkPlan(c3,num(X4.blp));X4.bconf='';
    if(!bkAct('bkloan',X4.blc,a3,X4.blp))return;
    if(c3)D.ap+=a3;else D.vc+=a3;BK.d[c3]=a3+Math.floor(a3*pl.pct/100);BK.prin[c3]=a3;BK.left[c3]=pl.days*86400+Math.floor((Date.now()-BK.t)/1000);BK.late[c3]=false;bkHistAdd(3,a3,c3,'');
    SND.win(2);x5ok((tr?'Kredi hesabına yattı: +':'Credit paid out: +')+fmtFull(a3)+' '+BCUR[c3]);x4re();return;}
  if(v==='pay0'||v==='pay1'){
    var c4=v==='pay1'?1:0,want=bkVal('bkPay'+c4),bal=bkBal(c4),pay=Math.min(want>0?want:BK.d[c4],BK.d[c4],bal);
    if(pay<1){toast(tr?'Bakiyen yok':'No balance',false);return;}
    if(!bkAct('bkpay',c4?'a':'v',want>0?pay:0,''))return;
    if(c4)D.ap-=pay;else D.vc-=pay;BK.d[c4]-=pay;bkHistAdd(4,pay,c4,'');
    if(!BK.d[c4]){BK.late[c4]=false;BK.prin[c4]=0;if(!BK.late[0]&&!BK.late[1])BK.blk=false;}
    SND.win(1);x5ok(BK.d[c4]?(tr?'Ödendi: ':'Paid: ')+fmtFull(pay)+' '+BCUR[c4]:(tr?'Kredi kapandı':'Loan closed'));x4re();return;}
},false);
// ---- season pass (replaces the daily reward screen; the login reward stays inside it)
var BP_TIERS=40;
function bpReward(t,prem){if(!prem)return t%5===0?{k:1,a:5+Math.floor(t/5)*3}:{k:0,a:40+10*t};return t%10===0?{k:2,a:t/10-1}:{k:1,a:4+Math.floor(t/2)};}
function bpTier(){return Math.min(BP_TIERS,Math.floor(BP.xp/BP.tx));}
function bpGot(t,prem){var m=prem?BP.p:BP.f,w=Math.floor((t-1)/32),b=(t-1)%32;return ((m[w]|0)&(1<<b))!==0;}
function bpSet(t,prem){var m=prem?BP.p:BP.f,w=Math.floor((t-1)/32),b=(t-1)%32;m[w]=(m[w]|0)|(1<<b);}
function bpCaseName(i){var c=caseData()[i]||{};return c[D.lang]||c.en||'Case';}
function bpRwTxt(r){return r.k===2?bpCaseName(r.a):fmtFull(r.a)+' '+(r.k?'VC':'AP');}
function bpClaimable(){var n=0,top=bpTier();for(var t=1;t<=top;t++){if(!bpGot(t,0)&&bpReward(t,0).k!==2)n++;if(BP.prem&&!bpGot(t,1)&&bpReward(t,1).k!==2)n++;}return n;}
var MNAME={0:['Zombi öldür','Kill zombies'],1:['İnsan enfekte et','Infect humans'],2:['Kafadan vuruş','Headshots'],3:['Round kazan','Win rounds'],4:['Oyna','Play'],5:['Boss öldür','Kill a boss'],9:['Günlük girişini al','Claim your login reward']};
var MICON={0:['skull','red'],1:['fire','green'],2:['target','orange'],3:['crown','yellow'],4:['time','blue'],5:['bolt','purple'],9:['daily','pink']};
var WNAME={0:['Haftalık avcı: zombi öldür','Weekly hunter: kill zombies'],1:['Haftalık salgın: enfekte et','Weekly outbreak: infect'],2:['Haftalık mesai: oyna','Weekly shift: play']};
function bpMission(m,weekly){
  var tr=D.lang==='tr',type=m[0],prog=m[1],tg=m[2],done=m[4]===1,name=weekly?WNAME[type]:MNAME[type],ic=weekly?[['skull','red'],['fire','green'],['time','blue']][type]:(MICON[type]||['target','gray']);
  var isTime=(!weekly&&type===4)||(weekly&&type===2),unit=isTime?(weekly?3600:60):1,u=isTime?(weekly?(tr?' sa':' h'):(tr?' dk':' min')):'';
  var pTxt=Math.floor(prog/unit)+' / '+Math.floor(tg/unit)+u;
  return '<div class="bpm'+(done?' done':'')+'"><div class="bpmi">'+x4ic(ic[0],ic[1])+'</div><div class="bpmt"><b>'+esc(name?(tr?name[0]:name[1]):'?')+(type===9&&!weekly?'':' · '+esc(Math.floor(tg/unit)+u))+'</b>'+x4bar(tg?prog*100/tg:0,done?'g':'')+'<small>'+esc(done?(tr?'Tamamlandı':'Completed'):pTxt)+'</small></div><div class="bpmx">'+(done?svg('check'):'+'+m[3]+' XP')+'</div></div>';
}
R.daily=function(){
  var tr=D.lang==='tr',h='',top=bpTier(),inT=BP.xp-top*BP.tx,maxed=top>=BP_TIERS;
  h+='<div class="bphero"><div class="bph1"><span class="bpbadge" style="'+grad('daily')+'">'+svg('pass')+'</span><div><small>'+esc((tr?'SEZON ':'SEASON ')+BP.s+' · '+BP.days+(tr?' gün kaldı':' days left'))+'</small><h1>'+esc(tr?'Sezon Bileti':'Season Pass')+'</h1></div>'+
    (BP.prem?'<span class="bpprem on">PREMIUM</span>':'')+'</div>'+
    '<div class="bplv"><div class="bplvn"><small>'+esc(tr?'Seviye':'Tier')+'</small><b>'+top+'</b><em>/ '+BP_TIERS+'</em></div><div class="bplvb">'+x4bar(maxed?100:inT*100/BP.tx,'gold')+'<small>'+esc(maxed?(tr?'Sezon tamamlandı!':'Season complete!'):fmtFull(inT)+' / '+fmtFull(BP.tx)+' XP · '+(tr?'sonraki seviye ':'next tier ')+(top+1))+'</small></div></div></div>';
  if(!BP.ok)h+='<div class="x4warn"><div class="x4ci">'+x4ic('pass','orange')+'</div><span>'+esc(tr?'Sezon verisi sunucudan bekleniyor (vex_bank eklentisi).':'Waiting for season data from the server (vex_bank plugin).')+'</span></div>';
  if(!BP.prem)h+='<div class="bpbuy"><div><b>'+esc(tr?'Premium Sezon Bileti':'Premium Season Pass')+'</b><p>'+esc(tr?'Her seviyede ekstra VexCoin ve 10/20/30/40. seviyelerde ücretsiz kasa (Bronz → Kabus).':'Extra VexCoin on every tier and a free case on tiers 10/20/30/40 (Bronze → Nightmare).')+'</p></div>'+
    (X4.bpconf==='1'?'<div class="bkcb"><span class="x4b" data-bp="nobuy">'+esc(tr?'Vazgeç':'Cancel')+'</span><span class="x4b g" data-bp="buy">'+esc((tr?'Onayla · ':'Confirm · ')+BP.price+' VC')+'</span></div>':'<span class="x4b gold" data-bp="ask">'+esc((tr?'Premium al · ':'Get Premium · ')+BP.price+' VC')+'</span>')+'</div>';
  var cl=bpClaimable();if(cl)h+='<span class="x4b big g" data-bp="all">'+esc((tr?'Tüm ödülleri al (':'Claim all rewards (')+cl+')')+'</span>';
  // missions
  var reset=BQ.reset-Math.floor((Date.now()-BQ.t)/1000);
  h+='<div class="x4s">'+esc(tr?'Günlük görevler':'Daily missions')+'<span class="bpreset">'+esc((tr?'yenilenir ':'resets in ')+hms(reset))+'</span></div><div class="x4g">'+(BQ.d.length?BQ.d.map(function(m){return bpMission(m,false);}).join(''):'<div class="bpm"><div class="bpmt"><small>'+esc(tr?'Görevler yükleniyor…':'Loading missions…')+'</small></div></div>')+'</div>';
  // login reward (the old daily reward, unchanged on the server)
  var day=D.dailyNext||Math.min(7,D.claimed?Math.max(1,D.streak):D.streak+1),rw=D.rewards&&D.rewards[day-1];
  h+='<div class="x4g bplogin"><div class="bpld">'+[1,2,3,4,5,6,7].map(function(i){var done=i<day||(i===day&&D.claimed);return '<i class="'+(done?'d':i===day?'n':'')+'">'+i+'</i>';}).join('')+'</div>'+
    (D.claimed?'<p>'+esc((tr?'Bugünkü giriş ödülü alındı · sonraki: ':'Login reward claimed · next: '))+'<span id="dailyCountdown">'+esc(hms(D.next))+'</span></p>':'<span class="x4b big g" data-daily="1">'+esc((tr?'Günlük giriş ödülünü al':'Claim login reward')+(rw?' · +'+fmt(rw[0])+' AP +'+fmt(rw[1])+' VC':''))+'</span>')+'</div>';
  if(BQ.w.length)h+='<div class="x4s">'+esc(tr?'Haftalık görevler':'Weekly missions')+'</div><div class="x4g">'+BQ.w.map(function(m){return bpMission(m,true);}).join('')+'</div>';
  // tiers
  var from=X4.bpall==='1'?1:Math.max(1,Math.min(top,BP_TIERS-5)),to=X4.bpall==='1'?BP_TIERS:Math.min(BP_TIERS,from+5);
  h+='<div class="x4s">'+esc(tr?'Ödüller':'Rewards')+'<span class="bpreset" data-x4="bpall='+(X4.bpall==='1'?'':'1')+'">'+esc(X4.bpall==='1'?(tr?'Daralt':'Collapse'):(tr?'Tüm 40 seviye':'All 40 tiers'))+'</span></div><div class="x4g bptr"><div class="bptrh"><span></span><b>'+esc(tr?'Ücretsiz':'Free')+'</b><b class="pr">Premium</b></div>';
  for(var t=from;t<=to;t++){
    var rf=bpReward(t,0),rp=bpReward(t,1),reach=t<=top;
    h+='<div class="bpt'+(reach?' r':'')+(t===top+1?' nx':'')+'"><span class="bptn">'+t+'</span>'+bpCell(t,0,rf,reach)+bpCell(t,1,rp,reach)+'</div>';
  }
  h+='</div>';
  return x4wrap(h+'<div class="x4f">'+esc(tr?'Görev ilerlemesi oyunda otomatik sayılır. Yeni sezon her 30 günde başlar; ilerleme ve Premium sıfırlanır.':'Mission progress counts automatically in game. A new season starts every 30 days; progress and Premium reset.')+'</div>');
};
function bpCell(t,prem,r,reach){
  var tr=D.lang==='tr',got=bpGot(t,prem),lock=prem&&!BP.prem,st=got?'got':(reach&&!lock?'can':'');
  var ic=r.k===2?(tr?'KASA':'CASE'):r.k===1?'VC':'AP';
  return '<div class="bpc '+(prem?'p ':'')+st+'"'+(st==='can'?' data-bp="c'+t+'.'+prem+'"':'')+'><span class="bpci k'+r.k+'">'+ic+'</span><b>'+esc(bpRwTxt(r))+'</b><small>'+esc(got?(tr?'Alındı':'Claimed'):lock?(tr?'Premium':'Premium'):reach?(tr?'Al':'Claim'):(tr?'Kilitli':'Locked'))+'</small></div>';
}
function bpClick(v){
  var tr=D.lang==='tr';
  if(v==='ask'){X4.bpconf='1';x4re();SND.click();return;}
  if(v==='nobuy'){X4.bpconf='';x4re();SND.click();return;}
  if(v==='buy'){X4.bpconf='';if(BK.blk){toast(tr?'Hesabın bloke: önce borcunu öde':'Account blocked: pay your debt first',false);return;}
    if(D.vc-BK.d[0]<BP.price){toast((tr?'Premium için gereken (borç hariç): ':'Premium needs (debt excluded): ')+BP.price+' VC',false);x4re();return;}
    if(!bkAct('bpprem','','',''))return;D.vc-=BP.price;BP.prem=true;bkHistAdd(8,BP.price,0,'');SND.win(3);x5ok(tr?'Premium Sezon Bileti açıldı!':'Premium Season Pass unlocked!');x4re();return;}
  if(v==='all'){var top=bpTier(),ap=0,vc=0;if(!bkAct('bpall','','',''))return;
    for(var t=1;t<=top;t++)for(var p=0;p<2;p++){if(p&&!BP.prem)continue;var r=bpReward(t,p);if(r.k===2||bpGot(t,p))continue;bpSet(t,p);if(r.k)vc+=r.a;else ap+=r.a;}
    D.ap+=ap;D.vc+=vc;SND.win(2);x5ok((tr?'Ödüller alındı · +':'Rewards claimed · +')+fmtFull(ap)+' AP · +'+fmtFull(vc)+' VC');x4re();return;}
  if(v.charAt(0)==='c'){var q=v.slice(1).split('.'),tt=num(q[0]),pr=num(q[1]),rw=bpReward(tt,pr);
    if(tt>bpTier()||bpGot(tt,pr)||(pr&&!BP.prem))return;
    if(!bkAct('bpclaim',tt,pr,''))return;bpSet(tt,pr);
    if(rw.k===2){SND.click();x5ok((tr?'Ücretsiz kasa açılıyor: ':'Opening free case: ')+bpCaseName(rw.a));}
    else{if(rw.k)D.vc+=rw.a;else D.ap+=rw.a;SND.win(1);x5ok((tr?'Ödül alındı · +':'Reward claimed · +')+bpRwTxt(rw));}
    // only the tapped cell and the "claim all" button change: no full redraw
    var cell=document.querySelector('[data-bp="'+v+'"]');
    if(cell){cell.className='bpc '+(pr?'p ':'')+'got';cell.removeAttribute('data-bp');var sm=cell.getElementsByTagName('small')[0];if(sm)sm.textContent=tr?'Alındı':'Claimed';
      var all=document.querySelector('[data-bp="all"]'),n=bpClaimable();if(all){if(n)all.textContent=(tr?'Tüm ödülleri al (':'Claim all rewards (')+n+')';else all.parentNode.removeChild(all);}
      LIVE_SIG='';return;}
    x4re();return;}
}
// a free case from the pass: the case result arrives like a normal case opening
(function(){var orr=onResult;onResult=function(name,res){var p=String(res||'').split('~');
  if(name==='bpclaim'&&p[0]==='ok'&&p[1]==='case'){D.cr={c:num(p[2]),code:p[3],r:num(p[4]),live:1};caseSel=D.cr.c;banner(D.lang==='tr'?'Ücretsiz kasa':'Free case',D.lang==='tr'?'Kasalar uygulamasında açılıyor':'Opening in the Cases app','case','#ff2d55');setTimeout(function(){if(cur==='daily')openApp('case');},900);return;}
  if((name==='bksend'||name==='bkloan'||name==='bkpay'||name==='bpprem'||name==='bpclaim'||name==='bpall')&&p[0]!=='ok'){X4.bconf='';}
  return orr(name,res);};})();
// a case won from the pass (or from the menu) that has not been shown yet plays when the Cases app opens
(function(){var oa=openApp;openApp=function(a,n){oa(a,n);if(a==='case'&&D.cr&&D.cr.live&&!REEL_RUN&&$('reelcv')){REEL_RUN=true;setTimeout(runReel,0);setTimeout(function(){REEL_RUN=false;LIVE_SIG='';},9800);}};})();
// typed amounts survive a redraw (e.g. picking a receiver after typing)
document.addEventListener('keyup',function(e){var t=e.target;if(!t||!t.id)return;if(t.id==='bkAmt')X4.bamt=String(bkInt(t.value)||'');else if(t.id==='bkLoanAmt')X4.blamt=String(bkInt(t.value)||'');},false);
// v10: something new from another player (message, friend request, trade offer, money) while the tablet
// is open -> an iPad banner + sound at once (the data itself arrives with the same update)
(function(){var last=-1,lack=0,au=applyU;applyU=function(u){au(u);var own=u.ack>lack;if(u.ack>lack)lack=u.ack;if(!u.nt||!u.nt.length)return;var top=0,txt='';
  u.nt.forEach(function(n){if(n[1]>top){top=n[1];txt=n[0];}});
  if(last<0){last=top;return;}
  if(top>last&&own){last=top;return;} // the answer to the player's own action already showed its note
  if(top>last){last=top;var k=x4nkind(txt);banner(D.lang==='tr'?'Yeni bildirim':'New notification',txt,k[0],(X4C[k[1]]||'#0a84ff,#0a84ff').split(',')[1]);SND.notif();if(!cur){HOME_SIG='';renderHome();}}};})();
