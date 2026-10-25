/* VEXMIRA PAD5 - tablet server (relay listener, limited replies, leaderboard file)
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
   Cvars (here): vex_pad5_reply_day, vex_pad5_reply_gap, vex_pad5_board.
   Commands: vex_pad5 (status). */
#include <amxmodx>
#include <sockets>

#define PLUGIN "VEXMIRA PAD5"
#define VERSION "5.0"

native vxc_tab_action(const msg[]);
native vxc_tab_link(ready,topic[],len);
native vxc_board(board,row,out[],len);

// ---------------------------------------------------------------- listener (commands from tablets)
#define L_IDLE 0
#define L_CONN 1
#define L_STREAM 2
new g_lSock,g_lState,Float:g_lNext,Float:g_lLast,g_lFails,g_lErr,bool:g_lReady;
new g_lBuf[4096],g_lLen,g_lRx,g_szTopic[40];

// ---------------------------------------------------------------- replies (limited)
#define RQ 24
new g_qTopic[RQ][64],g_qBody[RQ][1500],g_qOwner[RQ],Float:g_qAt[RQ],g_qHead,g_qN;
new g_rSock,g_rState,Float:g_rT,g_rSent,g_rFail,g_r429,g_rDropped,Float:g_rPauseUntil;
new g_dayCount,g_dayNo,Float:g_fLastReply[33];
new g_pDay,g_pGap,g_pBoard,g_pOn,g_pHost,g_pPort;

public plugin_init()
{
register_plugin(PLUGIN,VERSION,"smurfsexy");
g_pDay=register_cvar("vex_pad5_reply_day","220");   // max answers per day from this server (ntfy.sh limit is ~250)
g_pGap=register_cvar("vex_pad5_reply_gap","2.0");   // min seconds between two answers to the same player (later data is merged)
g_pBoard=register_cvar("vex_pad5_board","1");       // 1 = write vexmira_pad5/g5.js (leaderboards) every 2 min
register_concmd("vex_pad5","cmd_Status",ADMIN_RCON,"- PAD5 tablet status");
set_task(0.1,"task_Net",551000,_,_,"b");
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
if(g_rSock>0)socket_close(g_rSock);
DaySave();
}
public client_disconnected(id){g_fLastReply[id]=0.0;}

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
if(g_lSock<=0){g_lSock=0;g_lFails++;g_lNext=now+floatmin(60.0,3.0*float(g_lFails));if(g_lFails<=3)log_amx("[PAD5] relay baglanamadi (%s hata %d), tekrar denenecek",host,g_lErr);return;}
g_lState=L_CONN;g_lLast=now;
}
case L_CONN:
{
if(socket_is_writable(g_lSock,0))
{
new host[64],req[256];Host(host,63);
formatex(req,charsmax(req),"GET /%s/json HTTP/1.0^r^nHost: %s^r^nUser-Agent: vexmira-pad5/5.0^r^nAccept: application/x-ndjson^r^nConnection: close^r^n^r^n",g_szTopic,host);
if(socket_send2(g_lSock,req,strlen(req))!=strlen(req)){LDrop(now);return;}
g_lState=L_STREAM;g_lLast=now;g_lLen=0;
if(g_lFails)log_amx("[PAD5] relay baglandi (%s)",host);
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
if(equal(line,"HTTP/",5)){if(str_to_num(line[9])!=200){log_amx("[PAD5] relay HTTP %c%c%c - komut kanali hazir degil",line[9],line[10],line[11]);LDrop(get_gametime());}return;}
if(containi(line,"^"event^":^"open^"")!=-1){g_lReady=true;vxc_tab_link(1,g_szTopic,charsmax(g_szTopic));log_amx("[PAD5] komut kanali hazir (%s)",g_szTopic);return;}
if(containi(line,"^"event^":^"message^"")==-1)return;
new p=containi(line,"^"message^":^"");
if(p==-1)return;
p+=11;
new msg[512],o;
for(new i=p;line[i]&&line[i]!='"'&&o<charsmax(msg);i++)msg[o++]=line[i];
msg[o]=0;
if(!equal(msg,"vx1~",4))return;
g_lRx++;
vxc_tab_action(msg);
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
switch(g_rState)
{
case 0:
{
if(!g_qN||now<g_rT)return;
// first entry that is due (entries of other players are not held up by a waiting one)
new due=-1;for(new k=0;k<g_qN;k++){new q=(g_qHead+k)%RQ;if(now>=g_qAt[q]){due=k;break;}}
if(due<0)return;
if(due>0){static tb[1500];new a=g_qHead,b=(g_qHead+due)%RQ,tt[64],to,Float:ta;copy(tt,63,g_qTopic[a]);copy(tb,1499,g_qBody[a]);to=g_qOwner[a];ta=g_qAt[a];copy(g_qTopic[a],63,g_qTopic[b]);copy(g_qBody[a],1499,g_qBody[b]);g_qOwner[a]=g_qOwner[b];g_qAt[a]=g_qAt[b];copy(g_qTopic[b],63,tt);copy(g_qBody[b],1499,tb);g_qOwner[b]=to;g_qAt[b]=ta;}
new host[64],err;Host(host,63);
g_rSock=socket_open(host,Port(),SOCKET_TCP,err,SOCK_NON_BLOCKING);
if(g_rSock<=0){g_rSock=0;g_rFail++;g_rT=now+2.0;return;}
g_rState=1;g_rT=now;
}
case 1:
{
if(socket_is_writable(g_rSock,0))
{
static req[1800];new host[64];Host(host,63);
new q=g_qHead,bl=strlen(g_qBody[q]);
new n=formatex(req,charsmax(req),"POST /%s HTTP/1.0^r^nHost: %s^r^nContent-Type: text/plain^r^nX-Cache: no^r^nContent-Length: %d^r^nConnection: close^r^n^r^n%s",g_qTopic[q],host,bl,g_qBody[q]);
socket_send2(g_rSock,req,n);
g_qHead=(g_qHead+1)%RQ;g_qN--;g_rSent++;g_dayCount++;
g_rState=2;g_rT=now;
}
else if(now-g_rT>4.0){socket_close(g_rSock);g_rSock=0;g_rState=0;g_rFail++;g_rT=now+1.0;}
}
case 2:
{
if(socket_is_readable(g_rSock,0))
{
new head[64];socket_recv(g_rSock,head,63);
if(contain(head," 429")!=-1){g_r429++;g_rPauseUntil=now+600.0;log_amx("[PAD5] ntfy gunluk/ani limit (429) - cevaplar 10 dk duraklatildi; tablet verisi yine acilista gelir");}
socket_close(g_rSock);g_rSock=0;g_rState=0;g_rT=now+0.2;
}
else if(now-g_rT>3.0){socket_close(g_rSock);g_rSock=0;g_rState=0;g_rT=now;}
}
}
}
// daily budget, counted on Turkey's calendar day like ntfy's rolling day (saved across map changes)
DayRoll(){new d=(get_systime()+10800)/86400;if(d!=g_dayNo){g_dayNo=d;g_dayCount=0;}}
DayLoad(){new f=fopen("addons/amxmodx/data/vexmira_pad5_day.txt","rt");if(f){new l[32],a[12],b[12];fgets(f,l,31);fclose(f);parse(l,a,11,b,11);g_dayNo=str_to_num(a);g_dayCount=str_to_num(b);}DayRoll();}
DaySave(){new f=fopen("addons/amxmodx/data/vexmira_pad5_day.txt","wt");if(f){fprintf(f,"%d %d^n",g_dayNo,g_dayCount);fclose(f);}}

// ---------------------------------------------------------------- leaderboards file (FastDL copy may lag)
public task_Board()
{
DaySave();
if(!get_pcvar_num(g_pBoard))return;
if(!dir_exists("vexmira_pad5"))mkdir("vexmira_pad5");
new f=fopen("vexmira_pad5/g5.js","wt");
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
console_print(id,"[PAD5] relay=%s:%d topic=%s dinleniyor=%d (1 olmali) gelen komut=%d hata=%d",host,Port(),g_szTopic,g_lReady,g_lRx,g_lFails);
console_print(id,"[PAD5] cevap: bugun %d/%d gonderildi, atlanan %d, 429=%d, sirada %d",g_dayCount,get_pcvar_num(g_pDay),g_rDropped,g_r429,g_qN);
console_print(id,"[PAD5] veriler tablet adresinde gelir; cevap sadece pazar/takas/mesaj/yonetim/test icin gonderilir");
return PLUGIN_HANDLED;
}
