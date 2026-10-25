/* VEX BANK - Vexmira Bank (VexCoin / AmmoPack accounts, transfers, credit) + Season Pass
   Tablet & mod: smurfsexy

   Everything is decided here on the server; the tablet only shows the data and sends signed requests
   (vx2, checked by vex_tab01). Money moves only through the core native vxc_wal9, which changes a wallet
   all-or-nothing (never below 0, never overflows) and saves the player at once.

   BANK
   - Transfers: to a player who is in the game now (human, not you). Daily limit per currency.
     Money you borrowed cannot be sent away: you can send only what you hold above your open debt.
   - Credit: one loan per currency. The limit follows your level and your credit score (0-1000, start 500).
     Earning speed on this server (measured from the reward cvars): ~400-600 AP and ~10-25 VC per hour
     of play. So an AP loan is about one hour of play and is due in 1 or 3 days, a VC loan is a few hours
     of play and is due in 3 or 7 days.
   - Late: when the due time passes the debt gets a 10% late fee, the score drops by 150 and the account
     is BLOCKED: everything the player earns or holds pays the debt first, the rest is frozen in the bank
     (so the player cannot buy anything). When the debt is paid the frozen money comes back.
   SEASON PASS (replaces the old daily reward screen; the daily login reward itself stays)
   - 40 tiers, a new season every 30 days. XP from daily missions (3 + login) and weekly missions (3).
   - Free and premium rewards (premium is bought with VexCoin). Rewards are computed by the same
     formula on the tablet, so the tablet always shows the right numbers.

   Needs: vxcore_v4 (natives vxc_wal9, vxc_note9, vxc_res9, vxc_push9, vxc_stat9, vxc_case9, vxc_tab_value,
   vxc_tab_key, forwards vxc_bank9 / vxc_snap9), vex_tab01, nvault.
   Commands (rcon): vex_bank <name> (info), vex_bank_clear <name> (clear debt and block),
   vex_bank_due <name> <seconds> (move the due time), vex_bp_xp <name> <xp> (season pass XP). */
#include <amxmodx>
#include <amxmisc>
#include <nvault>

#define PLUGIN "VEXMIRA BANK"
#define VERSION "9.0"

native vxc_tab_value(id,field,cat=0,ix=0);
native vxc_tab_key(id,out[],len);
native vxc_wal9(id,dvc,dap);
native vxc_note9(id,const text[],sound=1);
native vxc_res9(id,const text[]);
native vxc_push9(id);
native vxc_stat9(id,field);
native vxc_case9(id,tier);

#define CV 0            // currency index: VexCoin
#define CA 1            // currency index: AmmoPack
#define HN 8            // history entries kept per account
#define TIERS 40
#define S0 20750        // first season starts on this day (days since 1970, Turkey time) = 24 Oct 2026
#define SLEN 30         // season length in days
#define VXDAY ((get_systime()+10800)/86400)

// stat fields from the core (vxc_stat9)
#define ST_KILL 0
#define ST_INF 1
#define ST_HS 2
#define ST_WIN 3
#define ST_BOSS 4
#define ST_PLAY 5
#define ST_LVL 6
#define ST_DAILY 7
#define ST_TR 8

// daily mission pool: stat, target, xp  (3 are picked per day for each player, + the login mission)
new const DM[6][3]={{ST_KILL,12,300},{ST_INF,5,300},{ST_HS,6,300},{ST_WIN,4,300},{ST_PLAY,1800,300},{ST_BOSS,1,400}};
#define LOGIN_XP 200
// weekly missions: stat, target, xp
new const WM[3][3]={{ST_KILL,80,1500},{ST_INF,30,1500},{ST_PLAY,18000,2000}};

new g_hV=INVALID_HANDLE;
new bool:g_bOk[33],g_szAcc[33][40];
new g_iDebt[33][2],g_iDue[33][2],g_iPrin[33][2],bool:g_bLate[33][2],g_iScore[33],g_iFrz[33][2];
new g_iAuto[33][2],g_iTxDay[33],g_iTxSent[33][2],Float:g_fTxNext[33],Float:g_fActNext[33];
new g_szHist[33][HN][64],g_iHistN[33];
new g_iSeason[33],g_iBpXp[33],g_iBpF[33][2],g_iBpP[33][2],bool:g_bPrem[33];
new g_iMDay[33],g_iMBase[33][6],g_iMDone[33],g_iMPick[33][3];
new g_iWWeek[33],g_iWBase[33][6],g_iWDone[33];
new g_pDayVC,g_pDayAP,g_pMinLv,g_pTierXp,g_pPremVC,g_pFee;
new g_iStatTx,g_iStatLoan,g_iStatLate;

public plugin_init()
{
register_plugin(PLUGIN,VERSION,"smurfsexy");
g_pDayVC=register_cvar("vex_bank_day_vc","300");     // max VexCoin a player can send per day
g_pDayAP=register_cvar("vex_bank_day_ap","3000");    // max AmmoPack a player can send per day
g_pMinLv=register_cvar("vex_bank_min_level","3");    // level needed to send money or take credit (stops fresh alt accounts)
g_pTierXp=register_cvar("vex_bp_tier_xp","750");     // season pass XP per tier (40 tiers)
g_pPremVC=register_cvar("vex_bp_premium_vc","300");  // season pass premium price (VexCoin)
g_pFee=register_cvar("vex_bank_fee","0");            // transfer fee in percent (0 = free)
register_concmd("vex_bank","cmd_Info",ADMIN_RCON,"<name> - bank account of a player");
register_concmd("vex_bank_clear","cmd_Clear",ADMIN_RCON,"<name> - clear the debt and the block of a player");
register_concmd("vex_bank_due","cmd_Due",ADMIN_RCON,"<name> <seconds> - move the due time of a player's loans (support / tests)");
register_concmd("vex_bp_xp","cmd_BpXp",ADMIN_RCON,"<name> <xp> - give season pass XP");
g_hV=nvault_open("vexmira_bank9");
set_task(0.2,"task_Sweep",552000,_,_,"b");
set_task(2.0,"task_Tick",552001,_,_,"b");
}
public plugin_end(){for(new id=1;id<=32;id++)if(g_bOk[id])Save(id);if(g_hV!=INVALID_HANDLE)nvault_close(g_hV);log_amx("[BANK] harita sonu: transfer=%d kredi=%d gecikme=%d",g_iStatTx,g_iStatLoan,g_iStatLate);}
public client_putinserver(id){Clear(id);}
public client_disconnected(id){if(g_bOk[id])Save(id);Clear(id);}
Clear(id)
{
g_bOk[id]=false;g_szAcc[id][0]=0;g_iAuto[id][0]=0;g_iAuto[id][1]=0;g_iHistN[id]=0;g_fTxNext[id]=0.0;g_fActNext[id]=0.0;g_bPrem[id]=false;
for(new c=0;c<2;c++){g_iDebt[id][c]=0;g_iDue[id][c]=0;g_iPrin[id][c]=0;g_bLate[id][c]=false;g_iFrz[id][c]=0;g_iTxSent[id][c]=0;g_iBpF[id][c]=0;g_iBpP[id][c]=0;}
g_iScore[id]=500;g_iTxDay[id]=0;g_iSeason[id]=0;g_iBpXp[id]=0;g_iMDay[id]=0;g_iMDone[id]=0;g_iWWeek[id]=0;g_iWDone[id]=0;
}

bool:TR(id){return vxc_stat9(id,ST_TR)!=0;}
CUR(c){new s[4];copy(s,3,c==CV?"VC":"AP");return s;}

// ---------------------------------------------------------------- storage
// one line per account: numbers separated by spaces, history in its own key
Load(id)
{
if(g_bOk[id]||g_hV==INVALID_HANDLE||is_user_bot(id))return;
new key[40];if(!vxc_tab_key(id,key,charsmax(key))||!key[0])return; // core data not loaded yet
Clear(id);copy(g_szAcc[id],charsmax(g_szAcc[]),key);
new k[56],v[512];formatex(k,charsmax(k),"b_%s",key);
if(nvault_get(g_hV,k,v,charsmax(v)))
{
new f[40][16],n=0,o=0;
for(new i=0;v[i]&&n<40;i++){if(v[i]==' '){f[n][o]=0;n++;o=0;continue;}if(o<15)f[n][o++]=v[i];}
if(n<40){f[n][o]=0;n++;}
new x=0;
#define NX (x<n?str_to_num(f[x++]):0)
g_iDebt[id][0]=NX;g_iDue[id][0]=NX;g_iPrin[id][0]=NX;g_bLate[id][0]=NX!=0;
g_iDebt[id][1]=NX;g_iDue[id][1]=NX;g_iPrin[id][1]=NX;g_bLate[id][1]=NX!=0;
g_iScore[id]=clamp(NX,0,1000);g_iFrz[id][0]=NX;g_iFrz[id][1]=NX;
g_iTxDay[id]=NX;g_iTxSent[id][0]=NX;g_iTxSent[id][1]=NX;
g_iSeason[id]=NX;g_iBpXp[id]=NX;g_iBpF[id][0]=NX;g_iBpF[id][1]=NX;g_iBpP[id][0]=NX;g_iBpP[id][1]=NX;g_bPrem[id]=NX!=0;
g_iMDay[id]=NX;for(new s=0;s<6;s++)g_iMBase[id][s]=NX;g_iMDone[id]=NX;
g_iWWeek[id]=NX;for(new s=0;s<6;s++)g_iWBase[id][s]=NX;g_iWDone[id]=NX;
for(new c=0;c<2;c++){if(g_iDebt[id][c]<0)g_iDebt[id][c]=0;if(g_iFrz[id][c]<0)g_iFrz[id][c]=0;if(!g_iDebt[id][c])g_bLate[id][c]=false;}
}
formatex(k,charsmax(k),"h_%s",key);
if(nvault_get(g_hV,k,v,charsmax(v)))
{
new o=0;g_iHistN[id]=0;
for(new i=0;;i++){if(v[i]=='|'||!v[i]){if(o&&g_iHistN[id]<HN){g_szHist[id][g_iHistN[id]][o]=0;g_iHistN[id]++;}o=0;if(!v[i])break;continue;}if(g_iHistN[id]<HN&&o<63)g_szHist[id][g_iHistN[id]][o++]=v[i];}
}
g_bOk[id]=true;
Season(id);Missions(id,false);
// a loan that fell due while the player was away
for(new c=0;c<2;c++)if(g_iDebt[id][c]&&!g_bLate[id][c]&&get_systime()>g_iDue[id][c])Late(id,c);
for(new c=0;c<2;c++)if(g_iDebt[id][c]&&!g_bLate[id][c]&&g_iDue[id][c]-get_systime()<43200)
{new t[120];formatex(t,charsmax(t),TR(id)?"Banka: %d %s kredinin vadesi %d saat icinde doluyor":"Bank: your %d %s loan is due in %d hours",g_iDebt[id][c],CUR(c),max(1,(g_iDue[id][c]-get_systime())/3600));vxc_note9(id,t,1);}
}
Save(id)
{
if(!g_bOk[id]||g_hV==INVALID_HANDLE||!g_szAcc[id][0])return;
new k[56],v[512],n;
n=formatex(v,charsmax(v),"%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
g_iDebt[id][0],g_iDue[id][0],g_iPrin[id][0],g_bLate[id][0],g_iDebt[id][1],g_iDue[id][1],g_iPrin[id][1],g_bLate[id][1],
g_iScore[id],g_iFrz[id][0],g_iFrz[id][1],g_iTxDay[id],g_iTxSent[id][0],g_iTxSent[id][1],
g_iSeason[id],g_iBpXp[id],g_iBpF[id][0],g_iBpF[id][1],g_iBpP[id][0],g_iBpP[id][1],g_bPrem[id],g_iMDay[id],g_iMBase[id][0]);
for(new s=1;s<6;s++)n+=formatex(v[n],charsmax(v)-n," %d",g_iMBase[id][s]);
n+=formatex(v[n],charsmax(v)-n," %d %d",g_iMDone[id],g_iWWeek[id]);
for(new s=0;s<6;s++)n+=formatex(v[n],charsmax(v)-n," %d",g_iWBase[id][s]);
n+=formatex(v[n],charsmax(v)-n," %d",g_iWDone[id]);
formatex(k,charsmax(k),"b_%s",g_szAcc[id]);nvault_set(g_hV,k,v);
new h[600],m;for(new i=0;i<g_iHistN[id];i++)m+=formatex(h[m],charsmax(h)-m,"%s%s",i?"|":"",g_szHist[id][i]);
formatex(k,charsmax(k),"h_%s",g_szAcc[id]);nvault_set(g_hV,k,h);
}
// history entry: kind.amount.currency.time.name   kind: 1 sent 2 received 3 loan 4 repay 5 late fee 6 frozen 7 unfrozen 8 pass
Hist(id,kind,amt,c,const other[])
{
if(!g_bOk[id])return;
new cut[16];copy(cut,12,other);while(strlen(cut)>0&&(cut[strlen(cut)-1]&0xC0)==0x80)cut[strlen(cut)-1]=0;new nm[40];Enc(cut,nm,charsmax(nm));
if(g_iHistN[id]>=HN){for(new i=1;i<HN;i++)copy(g_szHist[id][i-1],63,g_szHist[id][i]);g_iHistN[id]=HN-1;}
formatex(g_szHist[id][g_iHistN[id]],63,"%d.%d.%d.%d.%s",kind,amt,c,get_systime(),nm);g_iHistN[id]++;
}
Enc(const s[],d[],len)
{
static const HX[]="0123456789ABCDEF";new o=0;
for(new i=0;s[i]&&o<len-3;i++){new c=s[i]&0xFF;if((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_')d[o++]=c;else{d[o++]='%';d[o++]=HX[c>>4];d[o++]=HX[c&15];}}
d[o]=0;
}

// ---------------------------------------------------------------- credit rules
Level(id){return max(0,vxc_stat9(id,ST_LVL));}
Limit(id,c)
{
new lv=Level(id),base=(c==CV)?min(300,20+2*lv):min(2500,150+20*lv);
return base*(500+g_iScore[id])/1000; // score 0 -> 50%, 500 -> 100%, 1000 -> 150%
}
// plan 0 short / 1 long: days and interest percent
PlanDays(c,p){return c==CV?(p?7:3):(p?3:1);}
PlanPct(p){return p?20:10;}
MinLoan(c){return c==CV?10:50;}
bool:Blocked(id){return (g_iDebt[id][0]&&g_bLate[id][0])||(g_iDebt[id][1]&&g_bLate[id][1]);}
Late(id,c)
{
if(!g_iDebt[id][c]||g_bLate[id][c])return;
g_bLate[id][c]=true;new fee=max(1,g_iDebt[id][c]/10);g_iDebt[id][c]+=fee;g_iScore[id]=max(0,g_iScore[id]-150);g_iStatLate++;
Hist(id,5,fee,c,"");
new t[140];formatex(t,charsmax(t),TR(id)?"Banka: kredinin vadesi gecti, hesabin BLOKE. Borc %d %s. Kazandigin her sey once borca gider.":"Bank: your loan is overdue, account BLOCKED. Debt %d %s. Everything you earn pays the debt first.",g_iDebt[id][c],CUR(c));
vxc_note9(id,t,1);client_print(id,print_chat,"[VEXMIRA BANK] %s",t);
new nm[32];get_user_name(id,nm,31);log_amx("[BANK] %s gecikti: %d %s borc, bloke",nm,g_iDebt[id][c],CUR(c));
Save(id);
}
// blocked account: balances pay the late debt, the rest is frozen; when the debt is gone the frozen money returns
public task_Sweep()
{
for(new id=1;id<=32;id++)
{
if(!g_bOk[id]||!is_user_connected(id))continue;
new bool:bl=Blocked(id);
if(!bl&&!g_iFrz[id][0]&&!g_iFrz[id][1])continue;
new vc=vxc_tab_value(id,0),ap=vxc_tab_value(id,1);if(vc<0||ap<0)continue;
if(bl)
{
new bal[2];bal[0]=vc;bal[1]=ap;new take[2],paid[2];
for(new c=0;c<2;c++){if(g_iDebt[id][c]&&g_bLate[id][c]){paid[c]=min(bal[c],g_iDebt[id][c]);bal[c]-=paid[c];}take[c]=paid[c]+bal[c];}
if(!take[0]&&!take[1])continue;
if(!vxc_wal9(id,-take[0],-take[1]))continue;
for(new c=0;c<2;c++){g_iDebt[id][c]-=paid[c];g_iFrz[id][c]+=bal[c];g_iAuto[id][c]+=paid[c];}
if(!Blocked(id))Unblock(id);
else{Save(id);vxc_push9(id);}
}
else if(g_iFrz[id][0]||g_iFrz[id][1])Unblock(id);
}
}
Unblock(id)
{
for(new c=0;c<2;c++)if(!g_iDebt[id][c])g_bLate[id][c]=false;
if(Blocked(id))return;
new f0=g_iFrz[id][0],f1=g_iFrz[id][1];
if((f0||f1)&&vxc_wal9(id,f0,f1)){g_iFrz[id][0]=0;g_iFrz[id][1]=0;if(f0)Hist(id,7,f0,CV,"");if(f1)Hist(id,7,f1,CA,"");}
for(new c=0;c<2;c++)if(g_iAuto[id][c]){Hist(id,6,g_iAuto[id][c],c,"");g_iAuto[id][c]=0;}
g_iScore[id]=min(1000,g_iScore[id]+10);
vxc_note9(id,TR(id)?"Banka: borcun kapandi, bloke kalkti. Dondurulan bakiye iade edildi.":"Bank: debt paid, block lifted. Frozen balance returned.",1);
new nm[32];get_user_name(id,nm,31);log_amx("[BANK] %s bloke kalkti (iade %d VC %d AP)",nm,f0,f1);
Save(id);vxc_push9(id);
}

// ---------------------------------------------------------------- tablet actions (core forward)
Res(id,const fmt[],any:...){new s[160];vformat(s,charsmax(s),fmt,3);vxc_res9(id,s);}
public vxc_bank9(id,const act[],const a[],const b[],const c[])
{
if(!(1<=id<=32)||!is_user_connected(id))return;
if(!g_bOk[id])Load(id);
new bool:tr=TR(id);
if(!g_bOk[id]){Res(id,"err~%s",tr?"Banka hesabi yukleniyor, birazdan tekrar dene":"Bank account loading, try again");return;}
if(equal(act,"bksend"))Send(id,str_to_num(a),b[0]=='a'?CA:CV,str_to_num(c));
else if(equal(act,"bkloan"))Loan(id,a[0]=='a'?CA:CV,str_to_num(b),str_to_num(c));
else if(equal(act,"bkpay"))Pay(id,a[0]=='a'?CA:CV,str_to_num(b));
else if(equal(act,"bpprem"))Premium(id);
else if(equal(act,"bpclaim"))Claim(id,str_to_num(a),str_to_num(b));
else if(equal(act,"bpall"))ClaimAll(id);
else if(equal(act,"bkview"))Res(id,"ok~bkview");
else if(equal(act,"bkadm"))AdminBank(id,a,str_to_num(b),c);
else Res(id,"err~%s",tr?"Bilinmeyen banka islemi":"Unknown bank action");
}
DayRoll(id){new d=VXDAY;if(g_iTxDay[id]!=d){g_iTxDay[id]=d;g_iTxSent[id][0]=0;g_iTxSent[id][1]=0;}}
DayMax(c){return max(0,get_pcvar_num(c==CV?g_pDayVC:g_pDayAP));}
Send(id,uid,c,amt)
{
new bool:tr=TR(id),t=0;
for(new p=1;p<=32;p++)if(is_user_connected(p)&&get_user_userid(p)==uid){t=p;break;}
if(t==id){Res(id,"err~%s",tr?"Kendine para gonderemezsin":"You cannot send money to yourself");return;}
if(!t||is_user_bot(t)||is_user_hltv(t)){Res(id,"err~%s",tr?"Oyuncu oyunda degil":"Player is not in the game");return;}
if(!g_bOk[t])Load(t);
if(!g_bOk[t]||vxc_tab_value(t,0)<0){Res(id,"err~%s",tr?"Alicinin hesabi hazir degil":"Receiver account not ready");return;}
if(Blocked(id)){Res(id,"err~%s",tr?"Hesabin bloke: once borcunu ode":"Account blocked: pay your debt first");return;}
if(Level(id)<get_pcvar_num(g_pMinLv)){Res(id,"err~%s %d",tr?"Transfer icin gereken seviye:":"Level needed to send:",get_pcvar_num(g_pMinLv));return;}
if(amt<1||amt>100000000){Res(id,"err~%s",tr?"Gecersiz tutar":"Invalid amount");return;}
if(get_gametime()<g_fTxNext[id]){Res(id,"err~%s",tr?"Iki transfer arasi 3 saniye bekle":"Wait 3 seconds between transfers");return;}
DayRoll(id);
if(g_iTxSent[id][c]+amt>DayMax(c)){Res(id,"err~%s %d %s",tr?"Gunluk transfer limitin kaldi:":"Daily transfer limit left:",max(0,DayMax(c)-g_iTxSent[id][c]),CUR(c));return;}
new bal=vxc_tab_value(id,c),fee=amt*clamp(get_pcvar_num(g_pFee),0,50)/100;
if(bal<0){Res(id,"err~%s",tr?"Hesap hazir degil":"Account not ready");return;}
if(bal-g_iDebt[id][c]<amt+fee){Res(id,"err~%s %d %s",tr?"Gonderilebilir bakiye (borc haric):":"Sendable balance (debt excluded):",max(0,bal-g_iDebt[id][c]-fee),CUR(c));return;}
if(!vxc_wal9(id,c==CV?-(amt+fee):0,c==CA?-(amt+fee):0)){Res(id,"err~%s",tr?"Bakiye degisti, tekrar dene":"Balance changed, try again");return;}
if(!vxc_wal9(t,c==CV?amt:0,c==CA?amt:0)){vxc_wal9(id,c==CV?amt+fee:0,c==CA?amt+fee:0);Res(id,"err~%s",tr?"Alici bu tutari alamiyor, iade edildi":"Receiver cannot take this amount, refunded");return;}
g_iTxSent[id][c]+=amt;g_fTxNext[id]=get_gametime()+3.0;g_iStatTx++;
new n1[32],n2[32];get_user_name(id,n1,31);get_user_name(t,n2,31);
Hist(id,1,amt,c,n2);Hist(t,2,amt,c,n1);Save(id);Save(t);
new msg[160];
formatex(msg,charsmax(msg),TR(t)?"Banka: %s sana %d %s gonderdi":"Bank: %s sent you %d %s",n1,amt,CUR(c));vxc_note9(t,msg,1);
if(Blocked(t))client_print(t,print_chat,TR(t)?"[VEXMIRA BANK] Hesabin bloke: gelen para once borcuna gider.":"[VEXMIRA BANK] Account blocked: incoming money pays your debt first.");
if(tr)formatex(msg,charsmax(msg),"%s kisisine %d %s gonderildi",n2,amt,CUR(c));else formatex(msg,charsmax(msg),"%d %s sent to %s",amt,CUR(c),n2);
client_print(id,print_chat,"[VEXMIRA BANK] %s",msg);
log_amx("[BANK] TRANSFER %s -> %s : %d %s (ucret %d)",n1,n2,amt,CUR(c),fee);
Res(id,"ok~bksend");
}
Loan(id,c,amt,plan)
{
new bool:tr=TR(id);plan=plan?1:0;
if(Blocked(id)){Res(id,"err~%s",tr?"Hesabin bloke: once borcunu ode":"Account blocked: pay your debt first");return;}
if(g_iDebt[id][c]){Res(id,"err~%s",tr?"Bu para biriminde acik kredin var":"You already have a loan in this currency");return;}
if(Level(id)<get_pcvar_num(g_pMinLv)){Res(id,"err~%s %d",tr?"Kredi icin gereken seviye:":"Level needed for credit:",get_pcvar_num(g_pMinLv));return;}
if(g_iScore[id]<250){Res(id,"err~%s",tr?"Kredi notun yetersiz (en az 250)":"Credit score too low (min 250)");return;}
new lim=Limit(id,c);
if(amt<MinLoan(c)||amt>lim){Res(id,"err~%s %d-%d %s",tr?"Kredi tutari:":"Loan amount:",MinLoan(c),lim,CUR(c));return;}
if(!vxc_wal9(id,c==CV?amt:0,c==CA?amt:0)){Res(id,"err~%s",tr?"Hesap hazir degil":"Account not ready");return;}
g_iPrin[id][c]=amt;g_iDebt[id][c]=amt+amt*PlanPct(plan)/100;g_iDue[id][c]=get_systime()+PlanDays(c,plan)*86400;g_bLate[id][c]=false;g_iStatLoan++;
Hist(id,3,amt,c,"");Save(id);
new nm[32],t[160];get_user_name(id,nm,31);
formatex(t,charsmax(t),tr?"Banka: %d %s kredi hesabina yatti. Geri odeme %d %s, vade %d gun.":"Bank: %d %s loan paid out. Repay %d %s within %d days.",amt,CUR(c),g_iDebt[id][c],CUR(c),PlanDays(c,plan));
vxc_note9(id,t,0);
log_amx("[BANK] KREDI %s: %d %s (geri %d, %d gun)",nm,amt,CUR(c),g_iDebt[id][c],PlanDays(c,plan));
Res(id,"ok~bkloan");
}
Pay(id,c,amt)
{
new bool:tr=TR(id);
if(!g_iDebt[id][c]){Res(id,"err~%s",tr?"Bu para biriminde borcun yok":"No debt in this currency");return;}
new bal=vxc_tab_value(id,c);if(bal<=0){Res(id,"err~%s",tr?"Bakiyen yok":"No balance");return;}
new pay=amt>0?min(amt,g_iDebt[id][c]):g_iDebt[id][c];pay=min(pay,bal);
if(pay<1){Res(id,"err~%s",tr?"Gecersiz tutar":"Invalid amount");return;}
if(!vxc_wal9(id,c==CV?-pay:0,c==CA?-pay:0)){Res(id,"err~%s",tr?"Bakiye degisti, tekrar dene":"Balance changed, try again");return;}
g_iDebt[id][c]-=pay;Hist(id,4,pay,c,"");
if(!g_iDebt[id][c])
{
new bool:wasLate=g_bLate[id][c];g_bLate[id][c]=false;g_iPrin[id][c]=0;
if(!wasLate)g_iScore[id]=min(1000,g_iScore[id]+40);
vxc_note9(id,tr?"Banka: kredin kapandi. Kredi notun yukseldi.":"Bank: loan closed. Credit score raised.",0);
if(!Blocked(id)&&(g_iFrz[id][0]||g_iFrz[id][1]))Unblock(id);
}
Save(id);
Res(id,"ok~bkpay");
}

// ---------------------------------------------------------------- season pass
SeasonNow(){return max(1,(VXDAY-S0)/SLEN+1);}
SeasonLeft(){new d=VXDAY-S0;if(d<0)return SLEN;return SLEN-(d%SLEN);}
Season(id)
{
new s=SeasonNow();
if(g_iSeason[id]!=s){g_iSeason[id]=s;g_iBpXp[id]=0;g_iBpF[id][0]=0;g_iBpF[id][1]=0;g_iBpP[id][0]=0;g_iBpP[id][1]=0;g_bPrem[id]=false;}
}
Tier(id){return min(TIERS,g_iBpXp[id]/max(1,get_pcvar_num(g_pTierXp)));}
// reward of a tier (same formula on the tablet). kind: 0 AP, 1 VC, 2 free case (amount = case tier)
Reward(t,prem,&kind,&amt)
{
if(!prem){if(t%5==0){kind=1;amt=5+(t/5)*3;}else{kind=0;amt=40+10*t;}return;}
if(t%10==0){kind=2;amt=t/10-1;}else{kind=1;amt=4+t/2;}
}
bool:Got(id,t,prem){new w=(t-1)/32,b=(t-1)%32;return ((prem?g_iBpP[id][w]:g_iBpF[id][w])&(1<<b))!=0;}
SetGot(id,t,prem){new w=(t-1)/32,b=(t-1)%32;if(prem)g_iBpP[id][w]|=(1<<b);else g_iBpF[id][w]|=(1<<b);}
Premium(id)
{
new bool:tr=TR(id),cost=max(0,get_pcvar_num(g_pPremVC));Season(id);
if(g_bPrem[id]){Res(id,"err~%s",tr?"Premium zaten acik":"Premium already active");return;}
if(Blocked(id)){Res(id,"err~%s",tr?"Hesabin bloke: once borcunu ode":"Account blocked: pay your debt first");return;}
new bal=vxc_tab_value(id,CV);
if(bal-g_iDebt[id][CV]<cost){Res(id,"err~%s %d VC",tr?"Premium icin gereken (borc haric):":"Premium needs (debt excluded):",cost);return;}
if(!vxc_wal9(id,-cost,0)){Res(id,"err~%s",tr?"Bakiye degisti, tekrar dene":"Balance changed, try again");return;}
g_bPrem[id]=true;Hist(id,8,cost,CV,"");Save(id);
vxc_note9(id,tr?"Sezon Bileti Premium acildi!":"Season Pass Premium unlocked!",0);
new nm[32];get_user_name(id,nm,31);log_amx("[BANK] %s sezon bileti premium aldi (%d VC)",nm,cost);
Res(id,"ok~bpprem");
}
bool:Give(id,t,prem)
{
new kind,amt;Reward(t,prem,kind,amt);
if(kind==2)return vxc_case9(id,amt)!=0;
return vxc_wal9(id,kind==1?amt:0,kind==0?amt:0)!=0;
}
Claim(id,t,prem)
{
new bool:tr=TR(id);Season(id);prem=prem?1:0;
if(t<1||t>TIERS){Res(id,"err~%s",tr?"Gecersiz seviye":"Invalid tier");return;}
if(t>Tier(id)){Res(id,"err~%s",tr?"Bu seviyeye henuz ulasmadin":"Tier not reached yet");return;}
if(prem&&!g_bPrem[id]){Res(id,"err~%s",tr?"Premium odul: once Premium al":"Premium reward: buy Premium first");return;}
if(Got(id,t,prem)){Res(id,"err~%s",tr?"Bu odul zaten alindi":"Already claimed");return;}
SetGot(id,t,prem);Save(id); // marked first: a second request can never pay twice
new kind,amt;Reward(t,prem,kind,amt);
if(!Give(id,t,prem)){if(prem)g_iBpP[id][(t-1)/32]&=~(1<<((t-1)%32));else g_iBpF[id][(t-1)/32]&=~(1<<((t-1)%32));Save(id);Res(id,"err~%s",tr?"Odul verilemedi, tekrar dene":"Reward failed, try again");return;}
if(kind!=2)Res(id,"ok~bpclaim");
}
ClaimAll(id)
{
new bool:tr=TR(id),n,top=Tier(id);Season(id);
for(new t=1;t<=top;t++)for(new prem=0;prem<2;prem++)
{
if(prem&&!g_bPrem[id])continue;
new kind,amt;Reward(t,prem,kind,amt);
if(kind==2||Got(id,t,prem))continue; // cases are opened one by one (the reel shows them)
SetGot(id,t,prem);
if(Give(id,t,prem))n++;else{if(prem)g_iBpP[id][(t-1)/32]&=~(1<<((t-1)%32));else g_iBpF[id][(t-1)/32]&=~(1<<((t-1)%32));}
}
Save(id);
if(n)Res(id,"ok~bpall");else Res(id,"err~%s",tr?"Alinacak odul yok":"Nothing to claim");
}
// missions: progress = core counter now - counter when the day/week started
Missions(id,bool:notify)
{
if(!g_bOk[id])return;
new st[6];for(new s=0;s<6;s++){st[s]=vxc_stat9(id,s);if(st[s]<0)return;}
new d=VXDAY,w=(d+3)/7,ch;
if(g_iMDay[id]!=d){g_iMDay[id]=d;for(new s=0;s<6;s++)g_iMBase[id][s]=st[s];g_iMDone[id]=0;ch=1;}
if(g_iWWeek[id]!=w){g_iWWeek[id]=w;for(new s=0;s<6;s++)g_iWBase[id][s]=st[s];g_iWDone[id]=0;ch=1;}
for(new s=0;s<6;s++){if(st[s]<g_iMBase[id][s])g_iMBase[id][s]=st[s];if(st[s]<g_iWBase[id][s])g_iWBase[id][s]=st[s];} // an admin reset never gives negative progress
Pick(id);
new gain;
for(new k=0;k<3;k++){new m=g_iMPick[id][k];if(g_iMDone[id]&(1<<k))continue;if(st[DM[m][0]]-g_iMBase[id][DM[m][0]]>=DM[m][1]){g_iMDone[id]|=(1<<k);gain+=DM[m][2];ch=1;if(notify)Done(id,DM[m][2]);}}
if(!(g_iMDone[id]&8)&&vxc_stat9(id,ST_DAILY)==1){g_iMDone[id]|=8;gain+=LOGIN_XP;ch=1;if(notify)Done(id,LOGIN_XP);}
for(new k=0;k<3;k++){if(g_iWDone[id]&(1<<k))continue;if(st[WM[k][0]]-g_iWBase[id][WM[k][0]]>=WM[k][1]){g_iWDone[id]|=(1<<k);gain+=WM[k][2];ch=1;if(notify)Done(id,WM[k][2]);}}
if(gain){Season(id);new before=Tier(id);g_iBpXp[id]=min(g_iBpXp[id]+gain,TIERS*max(1,get_pcvar_num(g_pTierXp)));if(Tier(id)>before&&notify){new t[96];formatex(t,charsmax(t),TR(id)?"Sezon Bileti: seviye %d! Odulunu tabletten al.":"Season Pass: tier %d! Claim it on the tablet.",Tier(id));vxc_note9(id,t,1);}}
if(ch)Save(id);
}
Done(id,xp){new t[80];formatex(t,charsmax(t),TR(id)?"Gorev tamamlandi: +%d sezon XP":"Mission complete: +%d season XP",xp);client_print(id,print_chat,"[VEXMIRA] %s",t);}
// the 3 daily missions of this player today (different players get different sets)
Pick(id)
{
new seed=g_iMDay[id]*7;for(new i=0;g_szAcc[id][i];i++)seed=seed*31+g_szAcc[id][i];
seed&=0x7FFFFFFF;new used,k;
for(new start=seed%6,step=0;k<3&&step<12;step++){new m=(start+step*(1+(seed/7)%5))%6;if(used&(1<<m)){m=0;while(used&(1<<m))m++;}used|=(1<<m);g_iMPick[id][k++]=m;}
}
public task_Tick()
{
for(new id=1;id<=32;id++)
{
if(!is_user_connected(id)||is_user_bot(id))continue;
if(!g_bOk[id]){Load(id);continue;}
for(new c=0;c<2;c++)if(g_iDebt[id][c]&&!g_bLate[id][c]&&get_systime()>g_iDue[id][c])Late(id,c);
Season(id);Missions(id,true);
}
}

// ---------------------------------------------------------------- tablet data (core forward, inside the tablet address)
// bk = vcDebt~vcLeftSec~apDebt~apLeftSec~score~blocked~frzVC~frzAP~limVC~limAP~sentVC~sentAP~dayVC~dayAP~minLv~lateVC~lateAP~prinVC~prinAP
// bp = season~xp~tierXp~f0~f1~p0~p1~premium~daysLeft~premPrice
// bq = daily(type.prog.target.xp.done ...),login|weekly...   bh (bank app only) = history rows
public vxc_snap9(id,const app[],buf[],len)
{
if(!g_bOk[id])Load(id);
if(!g_bOk[id])return;
DayRoll(id);Season(id);
new now=get_systime(),n;
n=formatex(buf,len,"&bk=%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d~%d",
g_iDebt[id][0],g_iDebt[id][0]?g_iDue[id][0]-now:0,g_iDebt[id][1],g_iDebt[id][1]?g_iDue[id][1]-now:0,g_iScore[id],Blocked(id),g_iFrz[id][0],g_iFrz[id][1],
Limit(id,CV),Limit(id,CA),g_iTxSent[id][0],g_iTxSent[id][1],DayMax(CV),DayMax(CA),get_pcvar_num(g_pMinLv),g_bLate[id][0],g_bLate[id][1],g_iPrin[id][0],g_iPrin[id][1]);
n+=formatex(buf[n],len-n,"&bp=%d~%d~%d~%d~%d~%d~%d~%d~%d~%d",g_iSeason[id],g_iBpXp[id],get_pcvar_num(g_pTierXp),g_iBpF[id][0],g_iBpF[id][1],g_iBpP[id][0],g_iBpP[id][1],g_bPrem[id],SeasonLeft(),get_pcvar_num(g_pPremVC));
new st[6],ok=1;for(new s=0;s<6;s++){st[s]=vxc_stat9(id,s);if(st[s]<0)ok=0;}
if(ok&&!equal(app,"bank"))
{
n+=formatex(buf[n],len-n,"&bq=");
for(new k=0;k<3;k++){new m=g_iMPick[id][k],s=DM[m][0];n+=formatex(buf[n],len-n,"%s%d.%d.%d.%d.%d",k?",":"",m,clamp(st[s]-g_iMBase[id][s],0,DM[m][1]),DM[m][1],DM[m][2],(g_iMDone[id]>>k)&1);}
n+=formatex(buf[n],len-n,",9.%d.1.%d.%d|",(g_iMDone[id]>>3)&1,LOGIN_XP,(g_iMDone[id]>>3)&1);
for(new k=0;k<3;k++){new s=WM[k][0];n+=formatex(buf[n],len-n,"%s%d.%d.%d.%d.%d",k?",":"",k,clamp(st[s]-g_iWBase[id][s],0,WM[k][1]),WM[k][1],WM[k][2],(g_iWDone[id]>>k)&1);}
n+=formatex(buf[n],len-n,"~%d",86400-((now+10800)%86400));
}
if(equal(app,"adm")&&(get_user_flags(id)&(ADMIN_BAN|ADMIN_RCON)))
{
// ba = uid~debtVC~debtAP~blocked~frozenVC~frozenAP~score~leftVC~leftAP;...  (players with any bank state; others are clean)
new first=1,cnt;
for(new p=1;p<=32&&cnt<14&&n<len-60;p++)
{
if(!is_user_connected(p)||is_user_bot(p)||!g_bOk[p])continue;
if(!g_iDebt[p][0]&&!g_iDebt[p][1]&&!g_iFrz[p][0]&&!g_iFrz[p][1]&&g_iScore[p]==500)continue;
n+=formatex(buf[n],len-n,"%s%d~%d~%d~%d~%d~%d~%d~%d~%d",first?"&ba=":";",get_user_userid(p),g_iDebt[p][0],g_iDebt[p][1],Blocked(p),g_iFrz[p][0],g_iFrz[p][1],g_iScore[p],g_iDebt[p][0]?g_iDue[p][0]-now:0,g_iDebt[p][1]?g_iDue[p][1]-now:0);first=0;cnt++;
}
}
if(equal(app,"bank")&&g_iHistN[id])
{
n+=formatex(buf[n],len-n,"&bh=");
for(new i=g_iHistN[id]-1,f=1,cnt=0;i>=0&&cnt<5&&n<len-80;i--,f=0,cnt++)
{
// time is sent as "seconds ago" so the tablet clock does not matter
new p[5][40],q=0,o=0;for(new j=0;g_szHist[id][i][j]&&q<5;j++){if(g_szHist[id][i][j]=='.'&&q<4){p[q][o]=0;q++;o=0;continue;}if(o<39)p[q][o++]=g_szHist[id][i][j];}if(q<5)p[q][o]=0;
n+=formatex(buf[n],len-n,"%s%s~%s~%s~%d~%s",f?"":";",p[0],p[1],p[2],max(0,now-str_to_num(p[3])),p[4]);
}
}
}

// ---------------------------------------------------------------- admin
Find(id,const arg[]){new t=cmd_target(id,arg,CMDTARGET_ALLOW_SELF|CMDTARGET_NO_BOTS);return t;}
public cmd_Info(id,level,cid)
{
if(!cmd_access(id,level,cid,2))return PLUGIN_HANDLED;
new a[32];read_argv(1,a,31);new t=Find(id,a);if(!t)return PLUGIN_HANDLED;
if(!g_bOk[t])Load(t);
new nm[32];get_user_name(t,nm,31);
console_print(id,"[BANK] %s hesap=%s not=%d bloke=%d",nm,g_szAcc[t],g_iScore[t],Blocked(t));
for(new c=0;c<2;c++)console_print(id,"[BANK]  %s: borc=%d vade=%d sn gecikme=%d dondurulan=%d limit=%d bugun gonderilen=%d",CUR(c),g_iDebt[t][c],g_iDebt[t][c]?g_iDue[t][c]-get_systime():0,g_bLate[t][c],g_iFrz[t][c],Limit(t,c),g_iTxSent[t][c]);
console_print(id,"[BANK]  sezon %d xp=%d seviye=%d premium=%d",g_iSeason[t],g_iBpXp[t],Tier(t),g_bPrem[t]);
return PLUGIN_HANDLED;
}
public cmd_Clear(id,level,cid)
{
if(!cmd_access(id,level,cid,2))return PLUGIN_HANDLED;
new a[32];read_argv(1,a,31);new t=Find(id,a);if(!t)return PLUGIN_HANDLED;
if(!g_bOk[t])Load(t);if(!g_bOk[t])return PLUGIN_HANDLED;
for(new c=0;c<2;c++){g_iDebt[t][c]=0;g_bLate[t][c]=false;g_iPrin[t][c]=0;}
Unblock(t);Save(t);
new an[32],nm[32];get_user_name(id,an,31);get_user_name(t,nm,31);
log_amx("[BANK] %s, %s hesabinin borcunu / blokesini sildi",an,nm);console_print(id,"[BANK] %s temizlendi",nm);
return PLUGIN_HANDLED;
}
public cmd_Due(id,level,cid)
{
if(!cmd_access(id,level,cid,3))return PLUGIN_HANDLED;
new a[32],b[16];read_argv(1,a,31);read_argv(2,b,15);new t=Find(id,a);if(!t)return PLUGIN_HANDLED;
if(!g_bOk[t])Load(t);if(!g_bOk[t])return PLUGIN_HANDLED;
for(new c=0;c<2;c++)if(g_iDebt[t][c]&&!g_bLate[t][c])g_iDue[t][c]=get_systime()+str_to_num(b);
Save(t);console_print(id,"[BANK] vade guncellendi");return PLUGIN_HANDLED;
}
public cmd_BpXp(id,level,cid)
{
if(!cmd_access(id,level,cid,3))return PLUGIN_HANDLED;
new a[32],b[16];read_argv(1,a,31);read_argv(2,b,15);new t=Find(id,a);if(!t)return PLUGIN_HANDLED;
if(!g_bOk[t])Load(t);if(!g_bOk[t])return PLUGIN_HANDLED;
Season(t);g_iBpXp[t]=clamp(g_iBpXp[t]+str_to_num(b),0,TIERS*max(1,get_pcvar_num(g_pTierXp)));Save(t);
console_print(id,"[BANK] sezon xp=%d seviye=%d",g_iBpXp[t],Tier(t));return PLUGIN_HANDLED;
}

// ---------------------------------------------------------------- tablet admin app (Yonetim > oyuncu > Vexmira Bank)
// admin (ban flag): unblock / clear debt, +1 day due.  founder (rcon flag): give / take VC or AP, set credit score.
// spec: v<amount> / a<amount> (give, take) or the score (score)
AdminBank(id,const op[],uid,const spec[])
{
new bool:tr=TR(id),fl=get_user_flags(id);
new bool:founder=(fl&ADMIN_RCON)!=0,bool:admin=founder||(fl&ADMIN_BAN)!=0;
if(!admin){Res(id,"err~%s",tr?"Yetkin yok":"No permission");return;}
new t=0;for(new p=1;p<=32;p++)if(is_user_connected(p)&&!is_user_bot(p)&&get_user_userid(p)==uid){t=p;break;}
if(!t){Res(id,"err~%s",tr?"Oyuncu oyunda degil":"Player is not in the game");return;}
if(!g_bOk[t])Load(t);
if(!g_bOk[t]){Res(id,"err~%s",tr?"Oyuncunun hesabi hazir degil":"Player account not ready");return;}
new an[32],tn[32],msg[160];get_user_name(id,an,31);get_user_name(t,tn,31);
if(equal(op,"unblock"))
{
new d0=g_iDebt[t][0],d1=g_iDebt[t][1];
for(new c=0;c<2;c++){g_iDebt[t][c]=0;g_bLate[t][c]=false;g_iPrin[t][c]=0;}
Unblock(t);Save(t);
log_amx("[BANK] ADMIN %s: %s borcu silindi / bloke kalkti (%d VC %d AP)",an,tn,d0,d1);
formatex(msg,charsmax(msg),TR(t)?"Banka: yonetici %s borcunu sildi, hesabin acildi":"Bank: admin %s cleared your debt, account unlocked",an);vxc_note9(t,msg,1);
Res(id,"ok~bkadm");return;
}
if(equal(op,"extend"))
{
new n;for(new c=0;c<2;c++)if(g_iDebt[t][c]&&!g_bLate[t][c]){g_iDue[t][c]+=86400;n++;}
if(!n){Res(id,"err~%s",tr?"Uzatilacak (vadesi gecmemis) kredi yok":"No running loan to extend");return;}
Save(t);log_amx("[BANK] ADMIN %s: %s kredi vadesi +1 gun",an,tn);
formatex(msg,charsmax(msg),TR(t)?"Banka: yonetici %s kredi vadeni 1 gun uzatti":"Bank: admin %s extended your loan by 1 day",an);vxc_note9(t,msg,1);
Res(id,"ok~bkadm");return;
}
if(!founder){Res(id,"err~%s",tr?"Bu islem sadece kurucu icindir":"Founder only");return;}
if(equal(op,"score"))
{
new v=str_to_num(spec);if(v<0||v>1000){Res(id,"err~%s",tr?"Kredi notu 0-1000 olmali":"Score must be 0-1000");return;}
g_iScore[t]=v;Save(t);log_amx("[BANK] ADMIN %s: %s kredi notu = %d",an,tn,v);
Res(id,"ok~bkadm");return;
}
new c=spec[0]=='a'?CA:CV,amt=str_to_num(spec[1]);
if((spec[0]!='a'&&spec[0]!='v')||amt<1||amt>1000000){Res(id,"err~%s",tr?"Gecersiz tutar (1 - 1.000.000)":"Invalid amount (1 - 1,000,000)");return;}
if(equal(op,"give"))
{
if(!vxc_wal9(t,c==CV?amt:0,c==CA?amt:0)){Res(id,"err~%s",tr?"Bakiye eklenemedi":"Could not add balance");return;}
log_amx("[BANK] ADMIN %s: %s hesabina +%d %s",an,tn,amt,CUR(c));
formatex(msg,charsmax(msg),TR(t)?"Banka: yonetici %s hesabina %d %s ekledi":"Bank: admin %s added %d %s to your account",an,amt,CUR(c));vxc_note9(t,msg,1);
Res(id,"ok~bkadm");return;
}
if(equal(op,"take"))
{
new bal=vxc_tab_value(t,c);if(bal<0){Res(id,"err~%s",tr?"Hesap hazir degil":"Account not ready");return;}
new take=min(amt,bal);if(take<1){Res(id,"err~%s",tr?"Oyuncunun bu bakiyesi yok":"Player has no balance of this kind");return;}
if(!vxc_wal9(t,c==CV?-take:0,c==CA?-take:0)){Res(id,"err~%s",tr?"Bakiye alinamadi":"Could not take balance");return;}
log_amx("[BANK] ADMIN %s: %s hesabindan -%d %s",an,tn,take,CUR(c));
formatex(msg,charsmax(msg),TR(t)?"Banka: yonetici %s hesabindan %d %s aldi":"Bank: admin %s took %d %s from your account",an,take,CUR(c));vxc_note9(t,msg,1);
Res(id,"ok~bkadm");return;
}
Res(id,"err~%s",tr?"Bilinmeyen islem":"Unknown action");
}
