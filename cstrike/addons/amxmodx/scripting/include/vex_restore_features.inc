// Vexmira 4.1: optional legacy resources, light notifications and native-model inspect.
new g_iInspectSeq[31][2], Float:g_fInspectTime[31][2], Float:g_fInspectReady[33];
new g_iButterflyInspect=-1, Float:g_fButterflyInspect;
new Float:g_fLightNoteReady[33];

CommunityRestoreResource(const key[], const value[])
{
    new path[192];
    if(contain(value,"models/")==0 || contain(value,"sprites/")==0) copy(path,charsmax(path),value);
    else if(containi(value,".wav")!=-1 || containi(value,".mp3")!=-1) formatex(path,charsmax(path),"sound/%s",value);
    else if(containi(key,"MODEL")!=-1) formatex(path,charsmax(path),"models/player/%s/%s.mdl",value,value);
    else return;
    if(!file_exists(path,true)) { log_to_file("vex_restore.log","[Restore] optional original absent: %s -> %s; current resource kept",key,path); return; }
    if(!CommunityLegacyFileOk(path)) { log_to_file("vex_restore.log","[Restore] invalid/incomplete original: %s -> %s; fallback kept",key,path); return; }
    ResSet(key,value);
    if(equal(key,"LASERMINE_MODEL")) {
        ResSet("LASERMINE_ANGLES","0 0 0"); ResSet("LASERMINE_OFFSET","0.3");
        ResSet("LASERMINE_EMITTER","10.3 0 0"); ResSet("LASERMINE_BODY","0");
        ResSet("LASERMINE_SEQUENCE","0"); ResSet("LASERMINE_SEQNAME","idle");
        ResSet("LASERMINE_DEPLOY_SEQ","deploy");
    }
}

public CommunityEffectMenu(id)
{
    new title[320],item[96]; VexHead(id,title,charsmax(title),"COS_MENU");
    new menu=VexMenuCreate(title,"menu_cos_handler");
    static const keys[3][]={"COS_CAT_TRAIL","COS_CAT_KFX","COS_CAT_IFX"};
    for(new i=0;i<3;i++) { formatex(item,charsmax(item),"\y%L",id,keys[i]); MenuAdd(menu,item,i); }
    MenuFinish(id,menu);
}
public CommunityModelsCommand(id) { CommunityCoinMenu(id,0); return PLUGIN_HANDLED; }
public CommunityKnivesCommand(id) { CommunityCoinMenu(id,1); return PLUGIN_HANDLED; }
public CommunityGameDescription() { forward_return(FMV_STRING,"Vexmira Zombie | CSO + Boss"); return FMRES_SUPERCEDE; }

public CommunityCheckComponents() { CommunityStatus(0,0,0); }
public CommunityStatus(id,level,cid)
{
    if(id && !cmd_access(id,level,cid,1)) return PLUGIN_HANDLED;
    console_print(id,"VEXMIRA %s | %d slots | inspect + 5x collection | map vote 30",VERSION,g_iMax);
    static const filenames[13][]={"vex_janus7.amxx","vex_plasma.amxx","vex_thunderbolt.amxx","vex_ethereal.amxx","vex_salamander.amxx","vex_bow.amxx","vex_dragonsword.amxx","vex_katana.amxx","vex_lightsaber.amxx","vex_horseaxe.amxx","vex_hev.amxx","vex_jetpack.amxx","vex_minigun.amxx"};
    for(new c=0;c<13;c++) {
        new index=CommunityPluginIndex(filenames[c]);
        new file[128],name[96],ver[32],author[64],status[32];
        if(index>=0) get_plugin(index,file,charsmax(file),name,charsmax(name),ver,charsmax(ver),author,charsmax(author),status,charsmax(status));
        console_print(id,"%s: %s (%s)",filenames[c],index>=0?status:"MISSING",file);
        if(index<0 || !(equal(status,"running") || equal(status,"debug"))) log_amx("[Community] NOT READY: %s status=%s filename=%s",filenames[c],status,file);
    }
    console_print(id,"Cosmetics ready: wings=%d pets=%d hats=%d; bosses=%d",g_iCmN[0],g_iCmN[1],g_iCmN[2],g_iBossLoadN);
    return PLUGIN_HANDLED;
}

CommunityInspectRead(const path[], bool:butterfly=false, weapon=0)
{
    new f=fopen(path,"rb"); if(!f) return;
    new count,offset; fseek(f,164,SEEK_SET); fread(f,count,BLOCK_INT); fread(f,offset,BLOCK_INT);
    if(count<1 || count>256 || offset<244) { fclose(f); return; }
    for(new i=0;i<count;i++) {
        new label[33],Float:fps,frames;
        fseek(f,offset+i*176,SEEK_SET); fread_blocks(f,label,32,BLOCK_CHAR); label[32]=0;
        if(containi(label,"inspect")==-1) continue;
        fseek(f,offset+i*176+32,SEEK_SET); fread(f,_:fps,BLOCK_INT);
        fseek(f,offset+i*176+56,SEEK_SET); fread(f,frames,BLOCK_INT);
        new Float:dur=floatclamp(float(frames)/floatmax(fps,1.0),0.5,10.0);
        if(butterfly) { g_iButterflyInspect=i; g_fButterflyInspect=dur; break; }
        new slot=(containi(label,"unsil")!=-1)?1:0;
        if(g_iInspectSeq[weapon][slot]<0) { g_iInspectSeq[weapon][slot]=i; g_fInspectTime[weapon][slot]=dur; }
    }
    fclose(f);
}
CommunityInspectPrecache()
{
    for(new w=1;w<31;w++) {
        g_iInspectSeq[w][0]=-1; g_iInspectSeq[w][1]=-1;
        if(g_szWepV[w][0]) CommunityInspectRead(g_szWepV[w],false,w);
    }
    CommunityInspectRead("models/vexmira/community/knives/v_butterfly.mdl",true);
}
public CommunityInspectCommand(id) { CommunityInspect(id); return PLUGIN_HANDLED; }
CommunityInspect(id)
{
    if(!CommunityAlive(id) || CommunityExtra(id) || CommunityCall("vex_hev.amxx","vex_has",id)) return 0;
    new weapon=get_member(id,m_pActiveItem); if(is_nullent(weapon)) return 0;
    new w=get_user_weapon(id); if(w<1 || w>30) return 0;
    if(w==CSW_KNIFE && (CommunityCall("vex_jetpack.amxx","vex_has",id) || (g_iCommunitySel[id][1]>0 && g_iCommunitySel[id][1]!=5))) return 0;
    new bool:butterfly=w==CSW_KNIFE && g_iCommunitySel[id][1]==5;
    new weaponState=get_member(weapon,m_Weapon_iWeaponState);
    new slot=((w==CSW_M4A1 && !(weaponState&WPNSTATE_M4A1_SILENCED)) || (w==CSW_USP && !(weaponState&WPNSTATE_USP_SILENCED)))?1:0;
    new seq=butterfly?g_iButterflyInspect:g_iInspectSeq[w][slot];
    if(seq<0) { slot=0; seq=g_iInspectSeq[w][0]; }
    if(seq<0) return 0;
    // F consumes the flashlight impulse even while busy; no attack is delayed by inspect.
    if(get_gametime()<g_fInspectReady[id] || get_member(weapon,m_Weapon_fInReload)
        || get_member(weapon,m_Weapon_fInSpecialReload) || Float:get_member(id,m_flNextAttack)>0.0
        || Float:get_member(weapon,m_Weapon_flNextPrimaryAttack)>0.0
        || (get_entvar(id,var_button)&(IN_ATTACK|IN_ATTACK2|IN_RELOAD))) return 1;
    new Float:dur=butterfly?g_fButterflyInspect:g_fInspectTime[w][slot];
    set_entvar(id,var_weaponanim,seq);
    message_begin(MSG_ONE,SVC_WEAPONANIM,_,id); write_byte(seq); write_byte(get_entvar(weapon,var_body)); message_end();
    set_member(weapon,m_Weapon_flTimeWeaponIdle,dur); g_fInspectReady[id]=get_gametime()+0.7;
    return 1;
}

bool:CommunityLightNotify(id,note,arg)
{
    if(!is_user_connected(id) || is_user_bot(id) || !(get_pcvar_num(g_pCsoNotes)&CSO_BIT[note])) return false;
    if(get_gametime()<g_fLightNoteReady[id]) return true;
    new text[96];
    static const labels[CN_TOTAL][]={"KILL","DOUBLE KILL","TRIPLE KILL","MULTI KILL","MEGA KILL","HEADSHOT","KNIFE KILL","GRENADE KILL","MVP","HUMANS WIN","ZOMBIES WIN","BOSS INCOMING","INFECTION","NEMESIS","ASSASSIN","SURVIVOR","LAST HUMAN","LEVEL UP","ROUND","FIRST BLOOD","BOSS DEFEATED","INFECTED","LAST 10 SECONDS"};
    if(note<0 || note>=CN_TOTAL) return false;
    if(note==CN_ROUND) formatex(text,charsmax(text),"ROUND %d",arg);
    else copy(text,charsmax(text),labels[note]);
    set_hudmessage(255,190,50,-1.0,CSO_PRIO[note]<=2?0.36:0.22,0,0.0,1.8,0.15,0.4,3);
    show_hudmessage(id,"%s",text); g_fLightNoteReady[id]=get_gametime()+0.8;
    return true;
}

CommunityExtraEventPrecache()
{
    precache_generic("sound/vexmira/meme/oof.wav");
    precache_generic("sound/vexmira/meme/taco.wav");
}


CommunityAdminEquipment(id)
{
    if(!(get_user_flags(id)&ADMIN_BAN)) return;
    new title[320],line[96]; VexHead(id,title,charsmax(title),"ADMM_4");
    new menu=VexMenuCreate(title,"CommunityAdminEquipmentHandler");
    for(new i=0;i<6;i++) { formatex(line,charsmax(line),"\y%s \d[Ucretsiz ver]",COMMUNITY_WN[i]); MenuAdd(menu,line,i); }
    MenuAdd(menu,"\yJetpack + Bazooka",10); MenuAdd(menu,"\yHEV Suit",11);
    MenuAdd(menu,"\ySurvivor Minigun \d[Survivor gerekli]",12); MenuFinish(id,menu);
}
public CommunityAdminEquipmentHandler(id,menu,item)
{
    if(item<0 || !(get_user_flags(id)&ADMIN_BAN)) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new sel=MenuInfo(menu,item); menu_destroy(menu);
    new target=find_player_ex(FindPlayer_MatchUserId,g_iAdmTarget[id]);
    if(!target || !is_user_alive(target)) { Chat(id,"ADM_GONE"); return PLUGIN_HANDLED; }
    new ok;
    if(sel>=0 && sel<6) ok=VxGive(target,sel);
    else if(sel==12) ok=CommunityCall("vex_minigun.amxx","vex_give",target);
    else if(CommunityAlive(target)) {
        CommunityRemoveKnives(target);
        ok=CommunityCall(sel==10?"vex_jetpack.amxx":"vex_hev.amxx","vex_give",target);
    }
    console_print(id,"[Vexmira] equipment grant: target=%d selection=%d success=%d",target,sel,ok);
    log_to_file("vexmira_admin.log","equipment admin=%d target=%d selection=%d success=%d",get_user_userid(id),get_user_userid(target),sel,ok);
    CommunityAdminEquipment(id); return PLUGIN_HANDLED;
}

new Float:g_fCmNativeRate[CM_CATS][CM_MAX];
CommunityCosMetadata(c,i)
{
    new fp=fopen(g_szCmMdl[c][i],"rb"); if(!fp) return;
    new count,offset,frames,Float:fps;
    fseek(fp,164,SEEK_SET); fread(fp,count,BLOCK_INT); fread(fp,offset,BLOCK_INT);
    if(count<1 || count>256) { fclose(fp); return; }
    g_iCmSeq[c][i]=clamp(g_iCmSeq[c][i],0,count-1);
    new seq=offset+g_iCmSeq[c][i]*176;
    fseek(fp,seq+32,SEEK_SET); fread(fp,_:fps,BLOCK_INT);
    fseek(fp,seq+56,SEEK_SET); fread(fp,frames,BLOCK_INT); fclose(fp);
    g_fCmNativeRate[c][i]=frames>1 ? floatmax(fps,0.0)*256.0/float(frames-1) : 0.0;
}
CommunityCosAnimate(ent,c,i,Float:now)
{
    new Float:last=Float:get_entvar(ent,var_fuser1);
    set_entvar(ent,var_fuser1,now);
    if(last<=0.0 || g_fCmNativeRate[c][i]<=0.0) return;
    new Float:frame=Float:get_entvar(ent,var_frame)+floatclamp(now-last,0.0,0.25)*g_fCmNativeRate[c][i]*g_fCmFps[c][i];
    while(frame>=256.0) frame-=256.0;
    set_entvar(ent,var_frame,frame); set_entvar(ent,var_animtime,now);
}

bool:CommunityLegacyFileOk(const path[])
{
    new fp=fopen(path,"rb",true); if(!fp) return false;
    new magic,version,bytes,stored,textures,groups;
    fread(fp,magic,BLOCK_INT); fread(fp,version,BLOCK_INT);
    fseek(fp,0,SEEK_END); bytes=ftell(fp);
    if(containi(path,".mdl")!=-1) {
        if(magic!=0x54534449 || version!=10 || bytes<244) { fclose(fp); return false; }
        fseek(fp,72,SEEK_SET); fread(fp,stored,BLOCK_INT);
        fseek(fp,172,SEEK_SET); fread(fp,groups,BLOCK_INT);
        fseek(fp,180,SEEK_SET); fread(fp,textures,BLOCK_INT); fclose(fp);
        if(stored>bytes || stored<244 || groups<1 || groups>32) return false;
        new sibling[192],base[160]; copy(base,charsmax(base),path); base[strlen(base)-4]=0;
        if(!textures) { formatex(sibling,charsmax(sibling),"%sT.mdl",base); if(!file_exists(sibling,true)) return false; }
        for(new n=1;n<groups;n++) { formatex(sibling,charsmax(sibling),"%s%02d.mdl",base,n); if(!file_exists(sibling,true)) return false; }
        return true;
    }
    fclose(fp);
    if(containi(path,".spr")!=-1) return magic==0x50534449 && version==2 && bytes>42;
    if(containi(path,".wav")!=-1) return magic==0x46464952 && bytes>44;
    return bytes>0;
}
