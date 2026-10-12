new g_CommunityComponents[13]; // Stored as plugin index + 1; zero means unavailable.
public CommunityRegisterComponent(plugin, params)
{
    new component=get_param(1);
    if(component<1 || component>13) return 0;
    if(g_CommunityComponents[component-1] && g_CommunityComponents[component-1]!=plugin+1)
    {
        log_amx("[Community] Duplicate component %d: disable the older plugin copy",component);
        return 0;
    }
    g_CommunityComponents[component-1]=plugin+1;
    return 1;
}
CommunityPluginIndex(const plugin[])
{
    for(new i=0;i<6;i++) if(equal(plugin,COMMUNITY_WP[i])) { if(g_CommunityComponents[i]) return g_CommunityComponents[i]-1; break; }
    for(new i=0;i<4;i++) if(equal(plugin,COMMUNITY_KP[i])) { if(g_CommunityComponents[i+6]) return g_CommunityComponents[i+6]-1; break; }
    if(equal(plugin,"vex_minigun.amxx")) if(g_CommunityComponents[12]) return g_CommunityComponents[12]-1;
    if(equal(plugin,"vex_hev.amxx")) if(g_CommunityComponents[10]) return g_CommunityComponents[10]-1;
    if(equal(plugin,"vex_jetpack.amxx")) if(g_CommunityComponents[11]) return g_CommunityComponents[11]-1;
    new filename[128],name[96],version[32],author[64],status[32];
    for(new k=0;k<get_pluginsnum();k++) {
        get_plugin(k,filename,charsmax(filename),name,charsmax(name),version,charsmax(version),author,charsmax(author),status,charsmax(status));
        new delta=strlen(filename)-strlen(plugin);
        if(plugin[0] && delta>=0 && equal(filename[delta],plugin) && (equal(status,"running") || equal(status,"debug"))) return k;
    }
    return -1;
}
CommunityCall(const plugin[], const func[], id)
{
    if(!plugin[0]) return 0;
    new index=CommunityPluginIndex(plugin);
    if(index<0) {
        // Exact/suffix discovery repairs older component adapters and panel-prefixed filenames.
        new filename[128],name[96],version[32],author[64],status[32];
        for(new k=0;k<get_pluginsnum();k++) {
            get_plugin(k,filename,charsmax(filename),name,charsmax(name),version,charsmax(version),author,charsmax(author),status,charsmax(status));
            new delta=strlen(filename)-strlen(plugin);
            if(delta>=0 && equal(filename[delta],plugin) && (equal(status,"running") || equal(status,"debug"))) { index=k; break; }
        }
    }
    if(index<0) return 0;
    new function=get_func_id(func,index);
    if(function<0 || callfunc_begin_i(function,index)!=1) return 0;
    callfunc_push_int(id);
    return callfunc_end();
}
CommunityAlive(id) { return is_user_alive(id) && !g_bZombie[id] && !g_bSurvivor[id] && !g_bSniper[id] && !g_bBoss[id] && !g_bMinion[id]; }
CommunityRemoveWeapons(id) { for (new i=0;i<6;i++) CommunityCall(COMMUNITY_WP[i], "vex_remove", id); CommunityCall("vex_minigun.amxx","vex_remove",id); CommunityRemoveShots(id); }
CommunityRemoveKnives(id) { for (new i=0;i<4;i++) CommunityCall(COMMUNITY_KP[i], "vex_remove", id); }
CommunityReset(id)
{
    CommunityRemoveWeapons(id); CommunityRemoveKnives(id);
    CommunityCall("vex_jetpack.amxx", "vex_remove", id);
    CommunityCall("vex_hev.amxx", "vex_remove", id);
    CommunityCall("vex_minigun.amxx", "vex_remove", id);
    remove_task(id + 64000);
}
CommunityExtra(id)
{
    if (!is_user_alive(id)) return 0;
    new w=get_user_weapon(id);
    if(w==CSW_M249 && CommunityCall("vex_minigun.amxx","vex_has",id)) return 1;
    static const BASE[6]={CSW_M249,CSW_AK47,CSW_AWP,CSW_M4A1,CSW_M249,CSW_M4A1};
    for (new i=0;i<6;i++) if (w==BASE[i] && CommunityCall(COMMUNITY_WP[i],"vex_has",id)) return 1;
    return 0;
}
public CommunityNativeZombie(plugin, params) { new id=get_param(1); return id<1 || id>32 || !is_user_connected(id) || g_bZombie[id]; }
public CommunityNativeWeapon(plugin, params) { new id=get_param(1); return id>=1 && id<=32 ? CommunityExtra(id):0; }
public CommunityNativeKnife(plugin, params)
{
    new id=get_param(1);
    return id>=1 && id<=32 && CommunityAlive(id) && !CommunityCall("vex_jetpack.amxx","vex_has",id) && !CommunityCall("vex_hev.amxx","vex_has",id);
}
public CommunityNativeRestore(plugin, params)
{
    new id=get_param(1);
    if (id>=1 && id<=32 && is_user_alive(id) && !g_bZombie[id]) { ApplyHumanModel(id); remove_task(id+64000); set_task(0.2,"CommunityApplyKnife",id+64000); }
    return 1;
}
CommunityWeaponMenu(id)
{
    new title[320], line[160]; VexHead(id,title,charsmax(title),"MENU_SPECIAL");
    new menu=VexMenuCreate(title,"menu_special_handler");
    for(new i=0;i<6;i++) { formatex(line,charsmax(line),"\y%s \r[%d AP]",COMMUNITY_WN[i],COMMUNITY_COST[i]); MenuAdd(menu,line,i); }
    MenuFinish(id,menu);
}
CommunityBuyWeapon(id,i)
{
    if(i<0 || i>=6 || !CommunityAlive(id)) { Chat(id,"SHOP_UNAVAIL"); return; }
    if(CommunityCall(COMMUNITY_WP[i],"vex_has",id)) { Chat(id,"SHOP_ALREADY"); return; }
    if(g_iAP[id]<COMMUNITY_COST[i]) { Chat(id,"SHOP_NOAP"); return; }
    new index=CommunityPluginIndex(COMMUNITY_WP[i]);
    if(index<0 || get_func_id("vex_give",index)<0) {
        client_print_color(id,print_team_default,"^4[Vexmira]^1 %s eklentisi hazir degil. Yonetici: vex_status",COMMUNITY_WN[i]);
        log_amx("[Community] unavailable component %s; run vex_status",COMMUNITY_WP[i]); return;
    }
    // Drop before clearing flags, so upstream SetModel writes its pickup impulse.
    rg_drop_items_by_slot(id, PRIMARY_WEAPON_SLOT);
    CommunityRemoveWeapons(id);
    if(!CommunityCall(COMMUNITY_WP[i],"vex_give",id)) { Chat(id,"SHOP_UNAVAIL"); return; }
    AddAP(id,-COMMUNITY_COST[i],false,false); PlayKey(id,"SHOP_BUY");
}
CommunityBuyGear(id,i)
{
    if(!CommunityAlive(id)) { Chat(id,"SHOP_UNAVAIL"); return; }
    new price=i?60:80;
    if(g_iAP[id]<price) { Chat(id,"SHOP_NOAP"); return; }
    new plugin[32]; copy(plugin,charsmax(plugin),i?"vex_hev.amxx":"vex_jetpack.amxx");
    if(CommunityCall(plugin,"vex_has",id)) { Chat(id,"SHOP_ALREADY"); return; }
    if(!CommunityCall(plugin,"vex_give",id)) { Chat(id,"SHOP_UNAVAIL"); return; }
    CommunityRemoveKnives(id); AddAP(id,-price,false,false); PlayKey(id,"SHOP_BUY");
}
CommunityCoinMenu(id,c)
{
    new title[128],line[160];
    formatex(title,charsmax(title),"\yVEXMIRA COMMUNITY^n\r%s | %d Vex Coin",c?"Bicak Koleksiyonu":"CT Gorunumleri",g_iVC[id]);
    new menu=VexMenuCreate(title,"CommunityCoinHandler");
    MenuAdd(menu,"\yStandart / Kapat",c*10);
    for(new i=0;i<5;i++) {
        formatex(line,charsmax(line),"\y%s \r[%s | %d VC]",c?COMMUNITY_KN[i]:COMMUNITY_CN[i],g_iCommunitySel[id][c]==i+1?"KUSANILDI":(g_iCommunityOwned[id][c]&(1<<i)?"SAHIP":"KALICI"),COMMUNITY_COIN[c][i]);
        MenuAdd(menu,line,c*10+i+1);
    }
    MenuFinish(id,menu);
}
public CommunityCoinHandler(id,menu,item)
{
    if(item<0) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new sel=MenuInfo(menu,item); menu_destroy(menu); new c=sel/10,v=sel%10;
    if(c<0 || c>1 || v<0 || v>5) return PLUGIN_HANDLED;
    if(v && !(g_iCommunityOwned[id][c] & (1<<(v-1)))) {
        new cost=COMMUNITY_COIN[c][v-1];
        if(g_iVC[id]<cost) { Chat(id,"COS_NOVC",cost); CommunityCoinMenu(id,c); return PLUGIN_HANDLED; }
        g_iVC[id]-=cost; g_iCommunityOwned[id][c]|=1<<(v-1); PlayKey(id,"SHOP_BUY");
    }
    g_iCommunitySel[id][c]=v; SaveData(id);
    if(CommunityAlive(id)) {
        if(!c && !CommunityCall("vex_hev.amxx","vex_has",id)) ApplyHumanModel(id);
        else if(c) CommunityApplyKnife(id+64000);
    }
    CommunityCoinMenu(id,c); return PLUGIN_HANDLED;
}
public CommunityApplyKnife(taskid)
{
    new id=taskid-64000;
    if(id<1 || id>32 || !CommunityAlive(id)) return;
    CommunityRemoveKnives(id);
    if(CommunityCall("vex_jetpack.amxx","vex_has",id) || CommunityCall("vex_hev.amxx","vex_has",id)) return;
    new v=g_iCommunitySel[id][1];
    if(v==5) { new ent=get_member(id,m_pActiveItem); if(!is_nullent(ent) && get_user_weapon(id)==CSW_KNIFE) ExecuteHamB(Ham_Item_Deploy,ent); }
    else if(v && (g_iCommunityOwned[id][1] & (1<<(v-1)))) CommunityCall(COMMUNITY_KP[v-1],"vex_give",id);
    else { new ent=get_member(id,m_pActiveItem); if(!is_nullent(ent) && get_user_weapon(id)==CSW_KNIFE) ExecuteHamB(Ham_Item_Deploy,ent); }
}
CommunityPrecache()
{
    new path[128];
    for(new i=0;i<5;i++) { formatex(path,charsmax(path),"models/player/%s/%s.mdl",COMMUNITY_CT[i],COMMUNITY_CT[i]); if(file_exists(path,true)) precache_model(path); else log_amx("[Community] EKSIK model: %s (bu CT gorunumu kapali)",path); }
    precache_generic("models/player/vex_halo/vex_haloT.mdl");
    precache_model("models/vexmira/community/knives/v_butterfly.mdl");
    precache_model("models/zombie_plague/v_grenade_infect.mdl");
}
CommunityCosOrigin(ent,id,c,i)
{
    new Float:o[3],Float:a[3]; get_entvar(id,var_origin,o); get_entvar(id,var_angles,a);
    if(g_iCmAtt[c][i]==CMA_BONE) {
        engfunc(EngFunc_SetOrigin,ent,o); a[0]=0.0; a[2]=0.0;
        set_entvar(ent,var_angles,a); return;
    }
    new Float:y=a[1]*0.0174532925;
    o[0]+=g_fCmOfs[c][i][0]*floatcos(y)-g_fCmOfs[c][i][1]*floatsin(y);
    o[1]+=g_fCmOfs[c][i][0]*floatsin(y)+g_fCmOfs[c][i][1]*floatcos(y);
    o[2]+=g_fCmOfs[c][i][2];
    if(c!=1 && (get_entvar(id,var_flags)&FL_DUCKING)) o[2]-=18.0;
    a[0]=g_fCmAng[c][i][0]; a[1]+=g_fCmAng[c][i][1]; a[2]=g_fCmAng[c][i][2];
    if(c==2 && i==2) a[1]+=get_gametime()*30.0;
    engfunc(EngFunc_SetOrigin,ent,o); set_entvar(ent,var_angles,a);
}

public CommunityNativeJetpack(plugin, params) { new id=get_param(1); return id>=1 && id<=32 ? CommunityCall("vex_jetpack.amxx","vex_has",id):0; }

CommunityRemoveShots(id)
{
    static const CLS[3][]={"vex_plasma_ball","vex_bow_arrow","vex_sal_flame"};
    for(new i=0;i<3;i++) {
        new ent=-1;
        while((ent=engfunc(EngFunc_FindEntityByString,ent,"classname",CLS[i]))>0) {
            if(!pev_valid(ent)) continue;
            new owner=i==2?pev(ent,pev_owner):pev(ent,pev_iuser1);
            if(owner==id) set_pev(ent,pev_flags,pev(ent,pev_flags)|FL_KILLME);
        }
    }
}

public CommunityNativePrepareJet(plugin, params) { new id=get_param(1); if(id>=1 && id<=32) CommunityRemoveKnives(id); return 1; }
CommunityCtReady(i)
{
    new path[128]; formatex(path,charsmax(path),"models/player/%s/%s.mdl",COMMUNITY_CT[i],COMMUNITY_CT[i]);
    return file_exists(path,true);
}
