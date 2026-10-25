/* VEX TAB8 - tablet server (relay listener, limited replies, leaderboard file)
   Tablet & mod: smurfsexy

   Why a separate plugin:
   - The tablet sends its commands through the public ntfy.sh relay (each player's own internet).
   - ntfy.sh allows about 250 published messages per day per IP. When the game server answered every
     tablet action there, the server IP hit that limit and every later answer was dropped for hours.
   - PAD5 therefore sends almost nothing: all data the tablet needs travels inside the tablet address
     (core, Snap4), the tablet shows daily/upgrade/equip/case results at once, and only a few requests
     (market, trade, messages, admin, connection test) get an answer - with a daily budget below the limit.

   Needs: vxcore_v4 (natives vxc_tab_action / vxc_tab_link / vxc_board), sockets module.
   Cvars (core): vex_tablet_relay, vex_tablet_relay_host, vex_tablet_relay_port, vex_tablet_topic.
   Cvars (here): vex_tab8_reply_day, vex_tab8_reply_gap, vex_tab8_board.
   Commands: vex_tab8 (status). */
#include <amxmodx>
#include <sockets>

#define PLUGIN "VEXMIRA TAB8"
#define VERSION "6.0"

native vxc_tab_action(const msg[]);
native vxc_tab_link(ready,topic[],len);
native vxc_board(board,row,out[],len);
native vxc_tab_tok(id,out[],len);
native vxc_reset(what);
new g_iSeq6[33];

// ---------------------------------------------------------------- listener (commands from tablets)
#define L_IDLE 0
#define L_CONN 1
#define L_STREAM 2
new g_lSock,g_lState,Float:g_lNext,Float:g_lLast,g_lFails,g_lErr,bool:g_lReady;
new g_lBuf[4096],g_lLen,g_lRx,g_lBad,g_szTopic[40];

// ---------------------------------------------------------------- replies (limited)
#define RQ 48
#define NS 4   // parallel senders: 32 answers in the same second leave in ~2-3 s instead of ~12 s
new g_qTopic[RQ][64],g_qBody[RQ][1500],g_qOwner[RQ],Float:g_qAt[RQ],g_qHead,g_qN;
new g_sSock[NS],g_sState[NS],Float:g_sT[NS],g_sReq[NS][1800],g_sLen[NS];
new g_rSent,g_rFail,g_r429,g_rDropped,Float:g_rPauseUntil;
new g_dayCount,g_dayNo,Float:g_fLastReply[33];
new g_pDay,g_pGap,g_pBoard,g_pOn,g_pHost,g_pPort;

public plugin_init()
{
register_plugin(PLUGIN,VERSION,"smurfsexy");
g_pDay=register_cvar("vex_tab8_reply_day","220");   // max answers per day from this server (ntfy.sh limit is ~250)
g_pGap=register_cvar("vex_tab8_reply_gap","2.0");   // min seconds between two answers to the same player (later data is merged)
g_pBoard=register_cvar("vex_tab8_board","1");
register_cvar("vex_tab8_ingame_only","1");       // 1 = tablet page refuses to run in a normal web browser (only the game's MOTD browser)       // 1 = write vex_tab8/g8.js (leaderboards) every 2 min
register_concmd("vex_tab8","cmd_Status",ADMIN_RCON,"- TAB8 tablet status");
set_task(0.05,"task_Net",551000,_,_,"b");
set_task(5.0,"task_Board",551001);
set_task(120.0,"task_Board",551002,_,_,"b");
DayLoad();
}
public plugin_cfg()
{
g_pOn=get_cvar_pointer("vex_tablet_relay");g_pHost=get_cvar_pointer("vex_tablet_relay_host");g_pPort=get_cvar_pointer("vex_tablet_relay_port");
}
public plugin_end()
{
if(g_lSock>0)socket_close(g_lSock);
for(new k=0;k<NS;k++)if(g_sSock[k]>0)socket_close(g_sSock[k]);
DaySave();
}
public client_disconnected(id){g_fLastReply[id]=0.0;g_iSeq6[id]=0;}
public client_putinserver(id){g_iSeq6[id]=0;}

Host(out[],len){out[0]=0;if(g_pHost)get_pcvar_string(g_pHost,out,len);if(!out[0])copy(out,len,"ntfy.sh");}
Port(){new p=g_pPort?get_pcvar_num(g_pPort):80;return p>0?p:80;}
bool:RelayOn(){return !g_pOn||get_pcvar_num(g_pOn)!=0;}

public task_Net()
{
Listen();
Send();
}

// ---------------------------------------------------------------- listener
Listen()
{
new Float:now=get_gametime();
if(!RelayOn()){if(g_lSock>0)LDrop(now);return;}
if(!g_szTopic[0]){vxc_tab_link(-1,g_szTopic,charsmax(g_szTopic));if(!g_szTopic[0])return;}
switch(g_lState)
{
case L_IDLE:
{
if(now<g_lNext)return;
new host[64];Host(host,63);
g_lSock=socket_open(host,Port(),SOCKET_TCP,g_lErr,SOCK_NON_BLOCKING);
if(g_lSock<=0){g_lSock=0;g_lFails++;g_lNext=now+floatmin(60.0,3.0*float(g_lFails));if(g_lFails<=3)log_amx("[TAB8] relay baglanamadi (%s hata %d), tekrar denenecek",host,g_lErr);return;}
g_lState=L_CONN;g_lLast=now;
}
case L_CONN:
{
if(socket_is_writable(g_lSock,0))
{
new host[64],req[256];Host(host,63);
formatex(req,charsmax(req),"GET /%s/json HTTP/1.0^r^nHost: %s^r^nUser-Agent: vex-tab8/8.0^r^nAccept: application/x-ndjson^r^nConnection: close^r^n^r^n",g_szTopic,host);
if(socket_send2(g_lSock,req,strlen(req))!=strlen(req)){LDrop(now);return;}
g_lState=L_STREAM;g_lLast=now;g_lLen=0;
if(g_lFails)log_amx("[TAB8] relay baglandi (%s)",host);
g_lFails=0;
}
else if(now-g_lLast>10.0)LDrop(now);
}
case L_STREAM:
{
new loops;
while(loops++<8&&socket_is_readable(g_lSock,0))
{
new got=socket_recv(g_lSock,g_lBuf[g_lLen],charsmax(g_lBuf)-g_lLen);
if(got<=0){LDrop(now);return;}
g_lLen+=got;g_lBuf[g_lLen]=0;g_lLast=now;
LLines();
if(g_lState!=L_STREAM)return;
if(g_lLen>=charsmax(g_lBuf)-8)g_lLen=0;
}
if(now-g_lLast>90.0)LDrop(now); // ntfy sends a keepalive every 45 s
}
}
}
LDrop(Float:now)
{
if(g_lSock>0)socket_close(g_lSock);
if(g_lReady){g_lReady=false;vxc_tab_link(0,g_szTopic,charsmax(g_szTopic));}
g_lSock=0;g_lState=L_IDLE;g_lNext=now+2.0;g_lLen=0;
}
LLines()
{
new start=0;
for(new i=0;i<g_lLen;i++)
{
if(g_lBuf[i]!=10)continue;
g_lBuf[i]=0;
LLine(g_lBuf[start]);
if(g_lState!=L_STREAM)return;
start=i+1;
}
if(start>0)
{
new rest=g_lLen-start;
for(new k=0;k<rest;k++)g_lBuf[k]=g_lBuf[start+k];
g_lLen=rest;g_lBuf[rest]=0;
}
}
LLine(const line[])
{
if(equal(line,"HTTP/",5)){if(str_to_num(line[9])!=200){log_amx("[TAB8] relay HTTP %c%c%c - komut kanali hazir degil",line[9],line[10],line[11]);LDrop(get_gametime());}return;}
if(containi(line,"^"event^":^"open^"")!=-1){g_lReady=true;vxc_tab_link(1,g_szTopic,charsmax(g_szTopic));log_amx("[TAB8] komut kanali hazir (%s)",g_szTopic);return;}
if(containi(line,"^"event^":^"message^"")==-1)return;
new p=containi(line,"^"message^":^"");
if(p==-1)return;
p+=11;
new msg[512],o;
// JSON string -> raw UTF-8 bytes (ntfy escapes quotes, backslashes, < > & and control chars)
for(new i=p;line[i]&&line[i]!='"'&&o<charsmax(msg)-4;i++)
{
if(line[i]!='\'){msg[o++]=line[i];continue;}
i++;
switch(line[i])
{
case 'n':msg[o++]=10;
case 'r':msg[o++]=13;
case 't':msg[o++]=9;
case 'b','f':msg[o++]=' ';
case 'u':
{
new c=0;for(new k=1;k<=4;k++){new h=line[i+k];c*=16;if('0'<=h<='9')c+=h-'0';else if('a'<=h<='f')c+=h-'a'+10;else if('A'<=h<='F')c+=h-'A'+10;else{g_lBad++;return;}}
i+=4;
if(c<0x80)msg[o++]=c;
else if(c<0x800){msg[o++]=0xC0|(c>>6);msg[o++]=0x80|(c&0x3F);}
else{msg[o++]=0xE0|(c>>12);msg[o++]=0x80|((c>>6)&0x3F);msg[o++]=0x80|(c&0x3F);}
}
case 0:break;
default:msg[o++]=line[i];
}
}
msg[o]=0;
if(!equal(msg,"vx2~",4)){g_lBad++;return;} // old unsigned format (carried the secret key) is refused
g_lRx++;
Verified(msg);
}
// Signed command: vx2~<userid>~<seq>~<act>~<a>~<b>~<c>~<mac>
// mac = first 20 hex chars of sha256(<player's secret key> "|" <everything between "vx2~" and "~mac">).
// The secret key only travels inside that player's own tablet address, never over the public relay,
// so someone reading the relay can neither act for another player nor reuse an old command.
Verified(const msg[])
{
new p=strlen(msg)-1;
while(p>4&&msg[p]!='~')p--;
if(p<=4||strlen(msg[p+1])!=20){g_lBad++;return;}
new body[480];copy(body,min(charsmax(body),p-4),msg[4]);
new uid=str_to_num(body),id=0;
for(new i=1;i<=MaxClients;i++)if(is_user_connected(i)&&!is_user_bot(i)&&get_user_userid(i)==uid){id=i;break;}
if(!id){g_lBad++;return;}
new tk[16];if(!vxc_tab_tok(id,tk,charsmax(tk))){g_lBad++;return;}
new src[512],hex[72];formatex(src,charsmax(src),"%s|%s",tk,body);
hash_string(src,Hash_Sha256,hex,charsmax(hex));
if(!equali(hex,msg[p+1],20)){g_lBad++;return;}
// trusted path into the core: vx1~<key>~<seq>~<act>~... (the userid is dropped)
new q=contain(body,"~");if(q<0){g_lBad++;return;}
new seq=str_to_num(body[q+1]);if(seq<=g_iSeq6[id]){g_lBad++;return;} // an old (copied) command is never run twice
g_iSeq6[id]=seq;
new f[6][100],n=0,o=0;for(new i=0;body[i]&&n<6;i++){if(body[i]=='~'){f[n][o]=0;n++;o=0;continue;}if(o<99)f[n][o++]=body[i];}if(n<6)f[n][o]=0;
if(equal(f[2],"adm")&&equal(f[3],"reset")){AdminReset(id,str_to_num(f[4]));return;}
if(equal(f[2],"ua")){new nm[32];get_user_name(id,nm,31);log_amx("[TAB8] %s tablet tarayicisi: %s",nm,f[3]);return;} // which browser the game uses (for vex_tab8_ingame_only)
new out[512];formatex(out,charsmax(out),"vx1~%s%s",tk,body[q]);
vxc_tab_action(out);
}

// Founder-only (rcon flag) resets for everyone, from the tablet's admin app.
// 0 playtime, 1 stats, 2 achievements, 3 daily reward, 4 top15, 5 all leaderboards
AdminReset(id,what)
{
if(!(get_user_flags(id)&ADMIN_RCON)||what<0||what>5)return;
new an[32];get_user_name(id,an,31);
switch(what)
{
case 0,1,2,3:vxc_reset(what);
case 4:server_cmd("vex_reset_top");
case 5:{server_cmd("vex_reset_top");server_cmd("vex_reset_time");server_cmd("vex_reset_ach");}
}
static const W[][]={"oynama suresi","istatistikler","basarimlar","gunluk oduller","Top 15","tum siralamalar"};
client_print(0,print_chat,"[VEXMIRA] Kurucu %s herkesin %s verisini sifirladi.",an,W[what]);
log_amx("[TAB8] %s reset %d (%s)",an,what,W[what]);
}

// ---------------------------------------------------------------- replies
// Core calls this (forward vxc_reply) for the few actions that need server data back.
public vxc_reply(id,const topic[],const body[])
{
if(!topic[0]||!body[0])return;
DayRoll();
if(g_dayCount>=get_pcvar_num(g_pDay)||get_gametime()<g_rPauseUntil){g_rDropped++;return;}
for(new k=0;k<g_qN;k++){new q=(g_qHead+k)%RQ;if(equal(g_qTopic[q],topic)){copy(g_qBody[q],1499,body);return;}} // newest data wins, no extra message
// a player who just got an answer waits a moment; the newest data then goes out as one message
new Float:now=get_gametime(),Float:at=now;
if(1<=id<=32&&g_fLastReply[id]>0.0)at=floatmax(now,g_fLastReply[id]+get_pcvar_float(g_pGap));
if(g_qN>=RQ){g_qHead=(g_qHead+1)%RQ;g_qN--;g_rDropped++;}
new q=(g_qHead+g_qN)%RQ;copy(g_qTopic[q],63,topic);copy(g_qBody[q],1499,body);g_qOwner[q]=id;g_qAt[q]=at;g_qN++;
if(1<=id<=32)g_fLastReply[id]=at;
}
Send()
{
new Float:now=get_gametime();
for(new k=0;k<NS;k++)Slot(k,now);
}
// take the first due queue entry (others may still wait for their per-player gap)
bool:Pop(out[],len)
{
new due=-1;
for(new k=0;k<g_qN;k++){new q=(g_qHead+k)%RQ;if(get_gametime()>=g_qAt[q]){due=q;break;}}
if(due<0)return false;
new host[64];Host(host,63);
formatex(out,len,"POST /%s HTTP/1.0^r^nHost: %s^r^nContent-Type: text/plain^r^nX-Cache: no^r^nContent-Length: %d^r^nConnection: close^r^n^r^n%s",g_qTopic[due],host,strlen(g_qBody[due]),g_qBody[due]);
// close the gap in the ring
new q=due;while(q!=g_qHead){new pq=(q+RQ-1)%RQ;copy(g_qTopic[q],63,g_qTopic[pq]);copy(g_qBody[q],1499,g_qBody[pq]);g_qOwner[q]=g_qOwner[pq];g_qAt[q]=g_qAt[pq];q=pq;}
g_qHead=(g_qHead+1)%RQ;g_qN--;
return true;
}
Slot(k,Float:now)
{
switch(g_sState[k])
{
case 0:
{
if(!g_qN||now<g_sT[k])return;
if(!Pop(g_sReq[k],charsmax(g_sReq[])))return;
g_sLen[k]=strlen(g_sReq[k]);
new host[64],err;Host(host,63);
g_sSock[k]=socket_open(host,Port(),SOCKET_TCP,err,SOCK_NON_BLOCKING);
if(g_sSock[k]<=0){g_sSock[k]=0;g_rFail++;g_sT[k]=now+2.0;return;}
g_sState[k]=1;g_sT[k]=now;
}
case 1:
{
if(socket_is_writable(g_sSock[k],0)){socket_send2(g_sSock[k],g_sReq[k],g_sLen[k]);g_rSent++;g_dayCount++;g_sState[k]=2;g_sT[k]=now;}
else if(now-g_sT[k]>4.0){socket_close(g_sSock[k]);g_sSock[k]=0;g_sState[k]=0;g_rFail++;g_sT[k]=now+1.0;}
}
case 2:
{
if(socket_is_readable(g_sSock[k],0))
{
new head[64];socket_recv(g_sSock[k],head,63);
if(contain(head," 429")!=-1){g_r429++;g_rPauseUntil=now+600.0;log_amx("[TAB8] ntfy gunluk/ani limit (429) - cevaplar 10 dk duraklatildi; tablet verisi yine acilista gelir");}
socket_close(g_sSock[k]);g_sSock[k]=0;g_sState[k]=0;g_sT[k]=now;
}
else if(now-g_sT[k]>3.0){socket_close(g_sSock[k]);g_sSock[k]=0;g_sState[k]=0;g_sT[k]=now;}
}
}
}
// daily budget, counted on Turkey's calendar day like ntfy's rolling day (saved across map changes)
DayRoll(){new d=(get_systime()+10800)/86400;if(d!=g_dayNo){g_dayNo=d;g_dayCount=0;}}
DayLoad(){new f=fopen("addons/amxmodx/data/vex_tab8_day.txt","rt");if(f){new l[32],a[12],b[12];fgets(f,l,31);fclose(f);parse(l,a,11,b,11);g_dayNo=str_to_num(a);g_dayCount=str_to_num(b);}DayRoll();}
DaySave(){new f=fopen("addons/amxmodx/data/vex_tab8_day.txt","wt");if(f){fprintf(f,"%d %d^n",g_dayNo,g_dayCount);fclose(f);}}

// ---------------------------------------------------------------- leaderboards file (FastDL copy may lag)
public task_Board()
{
DaySave();
if(!get_pcvar_num(g_pBoard))return;
if(!dir_exists("vex_tab8"))mkdir("vex_tab8");
new f=fopen("vex_tab8/g8.js","wt");
if(!f)return;
new row[160],k;
fprintf(f,"window.VXG={ts:%d",get_systime());
static const KEY[3][]={"t","tt","at"};
for(new b=0;b<3;b++)
{
fprintf(f,",%s:^"",KEY[b]);
for(k=0;k<15&&vxc_board(b,k,row,charsmax(row));k++)fprintf(f,"%s%s",k?";":"",row);
fputs(f,"^"");
}
fputs(f,"};^n");
fclose(f);
}

// ---------------------------------------------------------------- status
public cmd_Status(id,level,cid)
{
if(!(get_user_flags(id)&ADMIN_RCON)&&id)return PLUGIN_HANDLED;
new host[64];Host(host,63);DayRoll();
console_print(id,"[TAB8] relay=%s:%d topic=%s dinleniyor=%d (1 olmali) gelen komut=%d reddedilen(imzasiz/sahte)=%d hata=%d",host,Port(),g_szTopic,g_lReady,g_lRx,g_lBad,g_lFails);
console_print(id,"[TAB8] cevap: bugun %d/%d gonderildi, atlanan %d, 429=%d, sirada %d",g_dayCount,get_pcvar_num(g_pDay),g_rDropped,g_r429,g_qN);
console_print(id,"[TAB8] veriler tablet adresinde gelir; cevap sadece pazar/takas/mesaj/yonetim/test icin gonderilir");
return PLUGIN_HANDLED;
}
