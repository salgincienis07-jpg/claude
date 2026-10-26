/* VEX TAB06 - tablet server (relay listener, limited replies, leaderboard file)
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
   Cvars (here): vex_tab06_reply_day, vex_tab06_reply_gap, vex_tab06_board.
   Commands: vex_tab06 (status). */
#include <amxmodx>
#include <amxmisc>
#include <sockets>
#pragma dynamic 32768   // v10.3: a tablet command + the core's nested reply used to overflow the default 16 KB stack

#define PLUGIN "VEXMIRA TAB06"
#define VERSION "10.5"

native vxc_tab_action(const msg[]);
native vxc_tab_link(ready,topic[],len);
native vxc_board(board,row,out[],len);
native vxc_tab_tok(id,out[],len);
native vxc_reset(what);
native vxc_tab_reopen(id);
native vxc_tab_snap(id,out[],len);
native vxc_tab_mq(id,st);
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
new g_rSent,g_rFail,g_r429,g_rDropped,Float:g_rPauseUntil,g_r429Row;
// ntfy.sh allows each IP a burst of ~60 requests, then 1 every 5 s: stay below it instead of getting 429
new Float:g_fTok=40.0,Float:g_fTokAt;
new g_dayCount,g_dayNo,Float:g_fLastReply[33];
// v10.3: server -> tablet data goes into the game server's own web folder (vex_tab06/d/<secret name>.js):
// no relay limits, works the same with 32 players. ntfy replies only for a tablet that reports it cannot
// read that folder (cvar vex_tab06_ntfy_reply 1 = always send them too).
new g_iDSeq[33],g_szDName[33][24],bool:g_bRelayPl[33],g_pNtfy,g_pFiles,g_dWrites,g_dFail,g_iReopen;
new Float:g_qMade[48];
new g_pDay,g_pGap,g_pBoard,g_pOn,g_pHost,g_pPort;
// ---------------------------------------------------------------- v10.5 MQTT link (no daily limit)
// One TCP connection to a public MQTT broker. Answers go to vx5/<topic>/r/<secret name of the tablet>,
// encrypted with that tablet's key; commands come in on vx5/<topic>/c (signed like on ntfy).
#define MQ_OUT 65536
new g_mSock,g_mState,Float:g_mNext,Float:g_mLast,Float:g_mPing,Float:g_mT0,g_mFails,g_mErr;
new g_mOut[MQ_OUT],g_mOutH,g_mOutN,g_mIn[4200],g_mInN,g_mSkip;
new bool:g_mRxOk,g_mTest[16],g_mPub,g_mRx,g_mDrop,g_mRxSec,Float:g_mRxT;
new bool:g_bMqPl[33],g_mSeq[33],Float:g_fMqDue[33],g_mRR;
new g_pMq,g_pMqHost,g_pMqPort;

public plugin_init()
{
register_plugin(PLUGIN,VERSION,"smurfsexy");
g_pDay=register_cvar("vex_tab06_reply_day","220");   // max answers per day from this server (ntfy.sh limit is ~250)
g_pGap=register_cvar("vex_tab06_reply_gap","2.0");   // min seconds between two answers to the same player (later data is merged)
g_pBoard=register_cvar("vex_tab06_board","1");
g_pNtfy=register_cvar("vex_tab06_ntfy_reply","1");  // answers over the relay (fast); when it is full the tablet reopens with fresh data
g_pFiles=register_cvar("vex_tab06_files","0");     // 1 = also write vex_tab06/d/*.js (only useful when the web folder shows server files at once)
register_cvar("vex_tab06_ingame_only","1");
g_pMq=register_cvar("vex_tab06_mqtt","1");                       // 1 = MQTT link on (answers without daily limit)
g_pMqHost=register_cvar("vex_tab06_mqtt_host","broker.emqx.io");  // broker for the game server (plain TCP)
g_pMqPort=register_cvar("vex_tab06_mqtt_port","1883");
register_cvar("vex_tab06_mqtt_ws","ws://broker.emqx.io:8083/mqtt"); // same broker for the tablet (WebSocket)       // 1 = tablet page refuses to run in a normal web browser (only the game's MOTD browser)       // 1 = write vex_tab06/g02.js (leaderboards) every 2 min
register_concmd("vex_tab06","cmd_Status",ADMIN_RCON,"- TAB06 tablet status");
set_task(0.05,"task_Net",551000,_,_,"b");
set_task(5.0,"task_Board",551001);
set_task(120.0,"task_Board",551002,_,_,"b");
DayLoad();
}
public plugin_cfg()
{
DataDirInit();
g_pOn=get_cvar_pointer("vex_tablet_relay");g_pHost=get_cvar_pointer("vex_tablet_relay_host");g_pPort=get_cvar_pointer("vex_tablet_relay_port");
}
public plugin_end()
{
if(g_lSock>0)socket_close(g_lSock);
if(g_mSock>0)socket_close(g_mSock);
for(new k=0;k<NS;k++)if(g_sSock[k]>0)socket_close(g_sSock[k]);
DaySave();
}
public client_disconnected(id){g_fLastReply[id]=0.0;g_bMqPl[id]=false;g_fMqDue[id]=0.0;vxc_tab_mq(id,0);g_iSeq6[id]=0;DataDrop(id);}
public client_putinserver(id){g_iSeq6[id]=0;g_bMqPl[id]=false;g_mSeq[id]=0;g_fMqDue[id]=0.0;g_iDSeq[id]=0;g_bRelayPl[id]=false;g_szDName[id][0]=0;}

Host(out[],len){out[0]=0;if(g_pHost)get_pcvar_string(g_pHost,out,len);if(!out[0])copy(out,len,"ntfy.sh");}
Port(){new p=g_pPort?get_pcvar_num(g_pPort):80;return p>0?p:80;}
bool:RelayOn(){return !g_pOn||get_pcvar_num(g_pOn)!=0;}

public task_Net()
{
Listen();
Send();
MqTick();
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
if(g_lSock<=0){g_lSock=0;g_lFails++;g_lNext=now+floatmin(60.0,3.0*float(g_lFails));if(g_lFails<=3)log_amx("[TAB06] relay baglanamadi (%s hata %d), tekrar denenecek",host,g_lErr);return;}
g_lState=L_CONN;g_lLast=now;
}
case L_CONN:
{
if(socket_is_writable(g_lSock,0))
{
new host[64],req[256];Host(host,63);
formatex(req,charsmax(req),"GET /%s/json HTTP/1.0^r^nHost: %s^r^nUser-Agent: vex-tab01/8.0^r^nAccept: application/x-ndjson^r^nConnection: close^r^n^r^n",g_szTopic,host);
if(socket_send2(g_lSock,req,strlen(req))!=strlen(req)){LDrop(now);return;}
g_lState=L_STREAM;g_lLast=now;g_lLen=0;
if(g_lFails)log_amx("[TAB06] relay baglandi (%s)",host);
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
if(equal(line,"HTTP/",5)){if(str_to_num(line[9])!=200){log_amx("[TAB06] relay HTTP %c%c%c - komut kanali hazir degil",line[9],line[10],line[11]);LDrop(get_gametime());}return;}
if(containi(line,"^"event^":^"open^"")!=-1){g_lReady=true;vxc_tab_link(1,g_szTopic,charsmax(g_szTopic));log_amx("[TAB06] komut kanali hazir (%s)",g_szTopic);return;}
if(containi(line,"^"event^":^"message^"")==-1)return;
new p=containi(line,"^"message^":^"");
if(p==-1)return;
p+=11;
static msg[512];new o;
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
static body[480];copy(body,min(charsmax(body),p-4),msg[4]);
new uid=str_to_num(body),id=0;
for(new i=1;i<=MaxClients;i++)if(is_user_connected(i)&&!is_user_bot(i)&&get_user_userid(i)==uid){id=i;break;}
if(!id){g_lBad++;return;}
new tk[16];if(!vxc_tab_tok(id,tk,charsmax(tk))){g_lBad++;return;}
static src[512],hex[72];formatex(src,charsmax(src),"%s|%s",tk,body);
hash_string(src,Hash_Sha256,hex,charsmax(hex));
if(!equali(hex,msg[p+1],20)){g_lBad++;return;}
// trusted path into the core: vx1~<key>~<seq>~<act>~... (the userid is dropped)
new q=contain(body,"~");if(q<0){g_lBad++;return;}
new seq=str_to_num(body[q+1]);if(seq<=g_iSeq6[id]){g_lBad++;return;} // an old (copied) command is never run twice
g_iSeq6[id]=seq;
if(!g_iDSeq[id]&&get_pcvar_num(g_pFiles))DataWrite(id,""); // first command: the tablet learns that its data file works
static f[6][100];new n=0,o=0;for(new i=0;body[i]&&n<6;i++){if(body[i]=='~'){f[n][o]=0;n++;o=0;continue;}if(o<99)f[n][o++]=body[i];}if(n<6)f[n][o]=0;
if(equal(f[2],"adm")&&equal(f[3],"reset")){AdminReset(id,str_to_num(f[4]));return;}
if(equal(f[2],"mq")){g_bMqPl[id]=str_to_num(f[3])!=0&&g_mState==4;vxc_tab_mq(id,g_bMqPl[id]?1:0);if(g_bMqPl[id])g_fMqDue[id]=get_gametime()+0.05;return;} // tablet listens on MQTT: full answers there
if(equal(f[2],"ua")){new nm[32];get_user_name(id,nm,31);log_amx("[TAB06] %s tablet tarayicisi: %s",nm,f[3]);if(get_pcvar_num(g_pFiles))DataWrite(id,"");return;} // + first (empty) data file: the tablet sees the folder works
if(equal(f[2],"relay")){g_bRelayPl[id]=str_to_num(f[3])!=0;new nm[32];get_user_name(id,nm,31);log_amx("[TAB06] %s tableti veri klasorunu okuyamiyor -> ntfy cevaplari acildi (vex_tab06_web adresini kontrol et)",nm);return;} // which browser the game uses (for vex_tab06_ingame_only)
static out[512];formatex(out,charsmax(out),"vx1~%s%s",tk,body[q]);
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
log_amx("[TAB06] %s reset %d (%s)",an,what,W[what]);
}

// ---------------------------------------------------------------- replies
// Core calls this (forward vxc_reply) for the few actions that need server data back.
public vxc_reply(id,const topic[],const body[])
{
if(!topic[0]||!body[0])return;
if(1<=id<=32&&g_bMqPl[id]&&g_mState==4){if(g_fMqDue[id]<=0.0)g_fMqDue[id]=get_gametime()+0.06;return;} // v10.5: newest full data over MQTT
if(1<=id<=32&&get_pcvar_num(g_pFiles))DataWrite(id,body);
if(!get_pcvar_num(g_pNtfy)&&!(1<=id<=32&&g_bRelayPl[id]))return;
DayRoll();
if(g_dayCount>=get_pcvar_num(g_pDay)||get_gametime()<g_rPauseUntil){g_rDropped++;if(1<=id<=32&&vxc_tab_reopen(id))g_iReopen++;return;} // relay full: fresh data in the tablet address instead
for(new k=0;k<g_qN;k++){new q=(g_qHead+k)%RQ;if(equal(g_qTopic[q],topic)){copy(g_qBody[q],1499,body);return;}} // newest data wins, no extra message
// a player who just got an answer waits a moment; the newest data then goes out as one message
new Float:now=get_gametime(),Float:at=now;
if(1<=id<=32&&g_fLastReply[id]>0.0)at=floatmax(now,g_fLastReply[id]+get_pcvar_float(g_pGap));
if(g_qN>=RQ){g_qHead=(g_qHead+1)%RQ;g_qN--;g_rDropped++;}
new q=(g_qHead+g_qN)%RQ;copy(g_qTopic[q],63,topic);copy(g_qBody[q],1499,body);g_qOwner[q]=id;g_qAt[q]=at;g_qMade[q]=now;g_qN++;
if(1<=id<=32)g_fLastReply[id]=at;
}
Send()
{
new Float:now=get_gametime();
// an answer that waited more than 8 s (relay busy / waiting after 429): open that tablet with fresh data instead
for(new k=0;k<g_qN;k++)
{
new q=(g_qHead+k)%RQ;
if(now-g_qMade[q]<8.0)continue;
new who=g_qOwner[q];
if(1<=who<=32&&vxc_tab_reopen(who)){g_iReopen++;QDel(q);k--;}
}
for(new k=0;k<NS;k++)Slot(k,now);
}
QDel(due)
{
new q=due;while(q!=g_qHead){new pq=(q+RQ-1)%RQ;copy(g_qTopic[q],63,g_qTopic[pq]);copy(g_qBody[q],1499,g_qBody[pq]);g_qOwner[q]=g_qOwner[pq];g_qAt[q]=g_qAt[pq];g_qMade[q]=g_qMade[pq];q=pq;}
g_qHead=(g_qHead+1)%RQ;g_qN--;
}
// take the first due queue entry (others may still wait for their per-player gap)
bool:Pop(out[],len)
{
new due=-1;
for(new k=0;k<g_qN;k++){new q=(g_qHead+k)%RQ;if(get_gametime()>=g_qAt[q]){due=q;break;}}
if(due<0)return false;
new host[64];Host(host,63);
formatex(out,len,"POST /%s HTTP/1.0^r^nHost: %s^r^nContent-Type: text/plain^r^nX-Cache: no^r^nContent-Length: %d^r^nConnection: close^r^n^r^n%s",g_qTopic[due],host,strlen(g_qBody[due]),g_qBody[due]);
QDel(due);
return true;
}
Slot(k,Float:now)
{
switch(g_sState[k])
{
case 0:
{
if(!g_qN||now<g_sT[k]||now<g_rPauseUntil)return;
g_fTok=floatmin(40.0,g_fTok+(now-g_fTokAt)/5.5);g_fTokAt=now;
if(g_fTok<1.0)return; // waits in the queue (newest data per tablet is merged), nothing is lost
if(!Pop(g_sReq[k],charsmax(g_sReq[])))return;
g_fTok-=1.0;
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
if(contain(head," 429")!=-1){g_r429++;g_r429Row++;new Float:w=floatmin(600.0,30.0*float(1<<min(5,g_r429Row-1)));g_rPauseUntil=now+w;g_fTok=0.0;log_amx("[TAB06] ntfy limit (429) - cevaplar %.0f sn bekletiliyor; oyuncular yine sohbet + iPad kartiyla haber alir",w);}
else g_r429Row=0;
socket_close(g_sSock[k]);g_sSock[k]=0;g_sState[k]=0;g_sT[k]=now;
}
else if(now-g_sT[k]>3.0){socket_close(g_sSock[k]);g_sSock[k]=0;g_sState[k]=0;g_sT[k]=now;}
}
}
}
// daily budget, counted on Turkey's calendar day like ntfy's rolling day (saved across map changes)
DayRoll(){new d=(get_systime()+10800)/86400;if(d!=g_dayNo){g_dayNo=d;g_dayCount=0;}}
DayLoad(){new f=fopen("addons/amxmodx/data/vex_tab06_day.txt","rt");if(f){new l[32],a[12],b[12];fgets(f,l,31);fclose(f);parse(l,a,11,b,11);g_dayNo=str_to_num(a);g_dayCount=str_to_num(b);}DayRoll();}
DaySave(){new f=fopen("addons/amxmodx/data/vex_tab06_day.txt","wt");if(f){fprintf(f,"%d %d^n",g_dayNo,g_dayCount);fclose(f);}}

// ---------------------------------------------------------------- leaderboards file (FastDL copy may lag)
public task_Board()
{
DaySave();
if(!get_pcvar_num(g_pBoard))return;
if(!dir_exists("vex_tab06"))mkdir("vex_tab06");
new f=fopen("vex_tab06/g02.js","wt");
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
console_print(id,"[TAB06] relay=%s:%d topic=%s dinleniyor=%d (1 olmali) gelen komut=%d reddedilen(imzasiz/sahte)=%d hata=%d",host,Port(),g_szTopic,g_lReady,g_lRx,g_lBad,g_lFails);
console_print(id,"[TAB06] cevap: bugun %d/%d gonderildi, atlanan %d, 429=%d, sirada %d",g_dayCount,get_pcvar_num(g_pDay),g_rDropped,g_r429,g_qN);
new nr=0;for(new p=1;p<=32;p++)if(g_bRelayPl[p])nr++;
new nm=0;for(new p=1;p<=32;p++)if(g_bMqPl[p])nm++;
console_print(id,"[TAB06] MQTT %s:%d durum=%d (4=bagli) komut alma=%s | gonderilen %d, gelen komut %d, atlanan %d | MQTT tableti: %d",MqHostS(),get_pcvar_num(g_pMqPort),g_mState,g_mRxOk?"evet":"hayir",g_mPub,g_mRx,g_mDrop,nm);
console_print(id,"[TAB06] relay dolu/gecikince yeni veriyle acilan tablet: %d | veri dosyasi: %s (yazilan %d, hata %d) | ntfy cevabi: %s, %d",g_iReopen,get_pcvar_num(g_pFiles)?"acik":"kapali",g_dWrites,g_dFail,get_pcvar_num(g_pNtfy)?"acik":"kapali",nr);
return PLUGIN_HANDLED;
}

// ---------------------------------------------------------------- v10.3 data files (server -> tablet)
DataDirInit()
{
if(!dir_exists("vex_tab06"))mkdir("vex_tab06");
if(!dir_exists("vex_tab06/d"))mkdir("vex_tab06/d");
// no directory listing on the web server (index file + apache rule); file names are secret anyway
if(!file_exists("vex_tab06/d/index.html")){new f1=fopen("vex_tab06/d/index.html","wt");if(f1){fputs(f1,"<!doctype html><title>403</title>");fclose(f1);}}
if(!file_exists("vex_tab06/d/.htaccess")){new f2=fopen("vex_tab06/d/.htaccess","wt");if(f2){fputs(f2,"Options -Indexes^n");fclose(f2);}}
// old files from the last map: nobody reads them any more
new fn[64],path[96],len=0,h=open_dir("vex_tab06/d",fn,charsmax(fn));
if(!h)return;
do{len=strlen(fn);if((len>3&&equal(fn[len-3],".js"))||(len>4&&equal(fn[len-4],".tmp"))){formatex(path,charsmax(path),"vex_tab06/d/%s",fn);delete_file(path);}}while(next_file(h,fn,charsmax(fn)));
close_dir(h);
}
// name = first 16 hex of sha256(<secret key>|d02): only that tablet knows it, the key itself is not in the name
bool:DataName(id)
{
if(g_szDName[id][0])return true;
new tk[16];if(!vxc_tab_tok(id,tk,charsmax(tk))||!tk[0])return false;
static src[40],hex[72];formatex(src,charsmax(src),"%s|d02",tk);hash_string(src,Hash_Sha256,hex,charsmax(hex));
copy(g_szDName[id],16,hex);
return true;
}
// The file is locked to its tablet: the secret key (tk) is never written and the rest is XOR-encrypted with
// sha256(<key>|k02|<seq>|<block>) - a new key stream for every write. Without the key the file is just hex.
DataWrite(id,const body[])
{
if(!is_user_connected(id)||is_user_bot(id)||!DataName(id))return;
new tk[16];if(!vxc_tab_tok(id,tk,charsmax(tk))||!tk[0])return;
static path[64],tmp[64],plain[1500],hexo[3004],src[64],kh[72];
formatex(path,charsmax(path),"vex_tab06/d/%s.js",g_szDName[id]);
formatex(tmp,charsmax(tmp),"vex_tab06/d/%s.tmp",g_szDName[id]);
// copy without the tk=... field
new o=0,i=0;
while(body[i]&&o<charsmax(plain))
{
if((i==0||body[i-1]=='&')&&body[i]=='t'&&body[i+1]=='k'&&body[i+2]=='=')
{
while(body[i]&&body[i]!='&')i++;
if(body[i]=='&')i++;
continue;
}
plain[o++]=body[i++];
}
if(o>0&&plain[o-1]=='&')o--;
plain[o]=0;
new seq=++g_iDSeq[id],blk=-1,h=0;
static const HX[]="0123456789abcdef";
for(i=0;i<o&&h<charsmax(hexo)-2;i++)
{
if(i/32!=blk){blk=i/32;formatex(src,charsmax(src),"%s|k02|%d|%d",tk,seq,blk);hash_string(src,Hash_Sha256,kh,charsmax(kh));}
new k=HexByte(kh[(i%32)*2],kh[(i%32)*2+1]),c=(plain[i]&0xFF)^k;
hexo[h++]=HX[c>>4];hexo[h++]=HX[c&15];
}
hexo[h]=0;
new fp=fopen(tmp,"wt");
if(!fp){g_dFail++;if(g_dFail<=3)log_amx("[TAB06] veri dosyasi yazilamadi: %s",tmp);return;}
fprintf(fp,"vxD(%d,^"%s^");",seq,hexo);
fclose(fp);
// replace in one step: the web server never hands out a half written file
if(file_exists(path))delete_file(path);
if(!rename_file(tmp,path,1)){g_dFail++;return;}
g_dWrites++;
}
HexByte(a,b){return (HexN(a)<<4)|HexN(b);}
HexN(c){if('0'<=c<='9')return c-'0';if('a'<=c<='f')return c-'a'+10;if('A'<=c<='F')return c-'A'+10;return 0;}
DataDrop(id)
{
if(!g_szDName[id][0])return;
new path[64];formatex(path,charsmax(path),"vex_tab06/d/%s.js",g_szDName[id]);
if(file_exists(path))delete_file(path);
g_szDName[id][0]=0;g_iDSeq[id]=0;g_bRelayPl[id]=false;
}

// ================================================================ v10.5 MQTT
MqHostS(){static h[64];get_pcvar_string(g_pMqHost,h,63);return h;}
MqDrop(const why[])
{
if(g_mSock>0)socket_close(g_mSock);
if(g_mState==4||g_mFails<3)log_amx("[TAB06] MQTT baglantisi kapandi (%s), tekrar denenecek - bu arada ntfy kullaniliyor",why);
new bool:was=g_mState==4;
g_mSock=0;g_mState=0;g_mOutH=0;g_mOutN=0;g_mInN=0;g_mSkip=0;g_mRxOk=false;g_mFails++;
g_mNext=get_gametime()+floatmin(60.0,3.0*float(g_mFails));
if(was){vxc_tab_mq(0,0);for(new p=1;p<=32;p++){g_bMqPl[p]=false;g_fMqDue[p]=0.0;}}
}
MqB(b){if(g_mOutH+g_mOutN>=MQ_OUT)return 0;g_mOut[g_mOutH+g_mOutN]=b&0xFF;g_mOutN++;return 1;}
MqLen(n){do{new d=n%128;n/=128;if(n>0)d|=128;MqB(d);}while(n>0);}
MqStr(const t[]){new l=strlen(t);MqB(l>>8);MqB(l);for(new i=0;i<l;i++)MqB(t[i]);}
bool:MqRoom(need){if(g_mOutH>0&&g_mOutH+g_mOutN+need>=MQ_OUT){for(new i=0;i<g_mOutN;i++)g_mOut[i]=g_mOut[g_mOutH+i];g_mOutH=0;}return g_mOutH+g_mOutN+need<MQ_OUT;}
bool:MqPublish(const topic[],const pay[])
{
new tl=strlen(topic),pl=strlen(pay),rem=2+tl+pl;
if(!MqRoom(rem+6)){g_mDrop++;return false;}
MqB(0x30);MqLen(rem);MqStr(topic);for(new i=0;i<pl;i++)MqB(pay[i]);
g_mPub++;return true;
}
MqFlush()
{
if(g_mOutN<=0||!socket_is_writable(g_mSock,0))return;
new sent=socket_send2(g_mSock,g_mOut[g_mOutH],g_mOutN);
if(sent>0){g_mOutH+=sent;g_mOutN-=sent;if(g_mOutN<=0){g_mOutH=0;g_mOutN=0;}}
}
MqTick()
{
new Float:now=get_gametime();
if(!get_pcvar_num(g_pMq)||!g_szTopic[0]){if(g_mSock>0)MqDrop("kapatildi");return;}
switch(g_mState)
{
case 0:
{
if(now<g_mNext)return;
g_mSock=socket_open(MqHostS(),get_pcvar_num(g_pMqPort),SOCKET_TCP,g_mErr,SOCK_NON_BLOCKING);
if(g_mSock<=0){g_mSock=0;g_mState=0;g_mFails++;g_mNext=now+floatmin(60.0,3.0*float(g_mFails));if(g_mFails<=3)log_amx("[TAB06] MQTT baglanamadi (%s hata %d)",MqHostS(),g_mErr);return;}
g_mState=1;g_mT0=now;
}
case 1:
{
if(socket_is_writable(g_mSock,0))
{
new cid[32];formatex(cid,31,"vxs%d%d",get_systime()%100000,random_num(1000,9999));
MqB(0x10);MqLen(10+2+strlen(cid));MqB(0);MqB(4);MqB('M');MqB('Q');MqB('T');MqB('T');MqB(4);MqB(2);MqB(0);MqB(60);MqStr(cid);
g_mState=2;g_mT0=now;g_mLast=now;
}
else if(now-g_mT0>10.0)MqDrop("zaman asimi");
}
default:
{
MqRead(now);
if(!g_mSock)return;
if(g_mState<4&&now-g_mT0>12.0){MqDrop("cevap yok");return;}
if(g_mState==4)
{
if(now-g_mPing>30.0){g_mPing=now;if(MqRoom(4)){MqB(0xC0);MqB(0);}}
if(now-g_mLast>80.0){MqDrop("sessiz");return;}
MqPlayers(now);
}
MqFlush();
}
}
}
MqRead(Float:now)
{
new loops;
while(loops++<8&&socket_is_readable(g_mSock,0))
{
new room=charsmax(g_mIn)-g_mInN;if(room<64){MqDrop("buyuk paket");return;}
for(new z=g_mInN;z<charsmax(g_mIn);z++)g_mIn[z]=0; // AMXX 1.9 may stop copying at a zero byte: the rest must read as 0, not old data
new got=socket_recv(g_mSock,g_mIn[g_mInN],room);
if(got<=0){MqDrop("sunucu kapatti");return;}
for(new i=0;i<got;i++)g_mIn[g_mInN+i]&=0xFF;
g_mInN+=got;g_mLast=now;
MqParse();
if(!g_mSock)return;
}
}
MqCut(k){for(new i=k;i<g_mInN;i++)g_mIn[i-k]=g_mIn[i];g_mInN-=k;}
MqParse()
{
for(;;)
{
if(g_mSkip>0){new k=min(g_mSkip,g_mInN);MqCut(k);g_mSkip-=k;if(g_mSkip>0)return;}
if(g_mInN<2)return;
new m=1,rem=0,i=1,c;
do{if(i>=g_mInN||i>4)return;c=g_mIn[i++];rem+=(c&127)*m;m*=128;}while(c&128);
new total=i+rem,type=g_mIn[0];
if(total>charsmax(g_mIn)-8){g_mSkip=total;continue;} // too big for a command: skipped
if(g_mInN<total)return;
switch(type&0xF0)
{
case 0x20:
{
if(g_mIn[i+1]!=0){log_amx("[TAB06] MQTT broker reddetti (kod %d)",g_mIn[i+1]);MqCut(total);MqDrop("red");return;}
new t[80];formatex(t,79,"vx5/%s/c",g_szTopic);
MqB(0x82);MqLen(2+2+strlen(t)+1);MqB(0);MqB(1);MqStr(t);MqB(0);
g_mState=3;
}
case 0x90:
{
g_mState=4;g_mFails=0;g_mPing=get_gametime();vxc_tab_mq(0,1);
log_amx("[TAB06] MQTT bagli (%s) - cevaplar sinirsiz",MqHostS());
new t[80];formatex(t,79,"vx5/%s/c",g_szTopic);formatex(g_mTest,15,"vxt~%d",random_num(100000,999999));MqPublish(t,g_mTest);
}
case 0x30:
{
new tl=(g_mIn[i]<<8)|g_mIn[i+1],p=i+2+tl;if(type&6)p+=2;
static msg[512];new o=0;for(new k=p;k<total&&o<charsmax(msg);k++)msg[o++]=g_mIn[k];msg[o]=0;
if(equal(msg,g_mTest)){if(!g_mRxOk){g_mRxOk=true;vxc_tab_mq(0,2);}}
else if(equal(msg,"vx2~",4))
{
new Float:now=get_gametime();if(now-g_mRxT>1.0){g_mRxT=now;g_mRxSec=0;}
if(++g_mRxSec<=60){g_mRx++;Verified(msg);}
}
}
}
MqCut(total);
if(!g_mSock)return;
}
}
// newest full data for tablets that asked (max 4 per tick: 32 tablets in 0.4 s, no lag spike)
MqPlayers(Float:now)
{
new done;
for(new k=0;k<32&&done<4;k++)
{
g_mRR=g_mRR%32+1;new id=g_mRR;
if(g_fMqDue[id]<=0.0||now<g_fMqDue[id])continue;
g_fMqDue[id]=0.0;done++;
if(!g_bMqPl[id]||!is_user_connected(id))continue;
MqSendSnap(id);
}
}
// payload "<seq>.<text>": every printable char is shifted by a key stream sha256(<key>|k05|<seq>|<block>),
// a new stream per message; the key itself (tk) is never sent. Only this tablet can read it.
MqSendSnap(id)
{
new tk[16];if(!vxc_tab_tok(id,tk,charsmax(tk))||!tk[0])return;
static plain[6100],pay[6200],src[64],kh[72],topic[96];
if(vxc_tab_snap(id,plain,charsmax(plain))<=0)return;
static name[72];formatex(src,charsmax(src),"%s|r05",tk);hash_string(src,Hash_Sha256,name,charsmax(name));name[16]=0;
formatex(topic,charsmax(topic),"vx5/%s/r/%s",g_szTopic,name);
new seq=++g_mSeq[id],o=formatex(pay,charsmax(pay),"%d.",seq),blk=-1,j=0;
for(new i=0;plain[i]&&o<charsmax(pay);i++)
{
if((i==0||plain[i-1]=='&')&&plain[i]=='t'&&plain[i+1]=='k'&&plain[i+2]=='='){while(plain[i+1]&&plain[i+1]!='&')i++;if(plain[i+1]=='&')i++;continue;}
if(j/32!=blk){blk=j/32;formatex(src,charsmax(src),"%s|k05|%d|%d",tk,seq,blk);hash_string(src,Hash_Sha256,kh,charsmax(kh));}
new c=plain[i]&0xFF,k=HexByte(kh[(j%32)*2],kh[(j%32)*2+1])%95;j++;
pay[o++]=(c>=32&&c<=126)?32+((c-32+k)%95):'?';
}
pay[o]=0;
MqPublish(topic,pay);
}
