CommunityNormalPrecache()
{
    VexPcModel("models/vexmira/community/normal/p_ak47.mdl");
    VexPcModel("models/vexmira/community/normal/p_aug.mdl");
    VexPcModel("models/vexmira/community/normal/p_awp.mdl");
    VexPcModel("models/vexmira/community/normal/p_c4.mdl");
    VexPcModel("models/vexmira/community/normal/p_deagle.mdl");
    VexPcModel("models/vexmira/community/normal/p_elite.mdl");
    VexPcModel("models/vexmira/community/normal/p_famas.mdl");
    VexPcModel("models/vexmira/community/normal/p_fiveseven.mdl");
    VexPcModel("models/vexmira/community/normal/p_flashbang.mdl");
    VexPcModel("models/vexmira/community/normal/p_g3sg1.mdl");
    VexPcModel("models/vexmira/community/normal/p_galil.mdl");
    VexPcModel("models/vexmira/community/normal/p_glock18.mdl");
    VexPcModel("models/vexmira/community/normal/p_hegrenade.mdl");
    VexPcModel("models/vexmira/community/normal/p_knife.mdl");
    VexPcModel("models/vexmira/community/normal/p_m249.mdl");
    VexPcModel("models/vexmira/community/normal/p_m3.mdl");
    VexPcModel("models/vexmira/community/normal/p_m4a1.mdl");
    VexPcModel("models/vexmira/community/normal/p_mac10.mdl");
    VexPcModel("models/vexmira/community/normal/p_mp5.mdl");
    VexPcModel("models/vexmira/community/normal/p_p228.mdl");
    VexPcModel("models/vexmira/community/normal/p_p90.mdl");
    VexPcModel("models/vexmira/community/normal/p_scout.mdl");
    VexPcModel("models/vexmira/community/normal/p_sg550.mdl");
    VexPcModel("models/vexmira/community/normal/p_sg552.mdl");
    VexPcModel("models/vexmira/community/normal/p_smokegrenade.mdl");
    VexPcModel("models/vexmira/community/normal/p_tmp.mdl");
    VexPcModel("models/vexmira/community/normal/p_ump45.mdl");
    VexPcModel("models/vexmira/community/normal/p_usp.mdl");
    VexPcModel("models/vexmira/community/normal/p_xm1014.mdl");
    VexPcModel("models/vexmira/community/normal/w_ak47.mdl");
    VexPcModel("models/vexmira/community/normal/w_aug.mdl");
    VexPcModel("models/vexmira/community/normal/w_awp.mdl");
    VexPcModel("models/vexmira/community/normal/w_backpack.mdl");
    VexPcModel("models/vexmira/community/normal/w_c4.mdl");
    VexPcModel("models/vexmira/community/normal/w_deagle.mdl");
    VexPcModel("models/vexmira/community/normal/w_elite.mdl");
    VexPcModel("models/vexmira/community/normal/w_famas.mdl");
    VexPcModel("models/vexmira/community/normal/w_fiveseven.mdl");
    VexPcModel("models/vexmira/community/normal/w_flashbang.mdl");
    VexPcModel("models/vexmira/community/normal/w_g3sg1.mdl");
    VexPcModel("models/vexmira/community/normal/w_galil.mdl");
    VexPcModel("models/vexmira/community/normal/w_glock18.mdl");
    VexPcModel("models/vexmira/community/normal/w_hegrenade.mdl");
    VexPcModel("models/vexmira/community/normal/w_knife.mdl");
    VexPcModel("models/vexmira/community/normal/w_m249.mdl");
    VexPcModel("models/vexmira/community/normal/w_m3.mdl");
    VexPcModel("models/vexmira/community/normal/w_m4a1.mdl");
    VexPcModel("models/vexmira/community/normal/w_mac10.mdl");
    VexPcModel("models/vexmira/community/normal/w_mp5.mdl");
    VexPcModel("models/vexmira/community/normal/w_p228.mdl");
    VexPcModel("models/vexmira/community/normal/w_p90.mdl");
    VexPcModel("models/vexmira/community/normal/w_scout.mdl");
    VexPcModel("models/vexmira/community/normal/w_sg550.mdl");
    VexPcModel("models/vexmira/community/normal/w_sg552.mdl");
    VexPcModel("models/vexmira/community/normal/w_shield.mdl");
    VexPcModel("models/vexmira/community/normal/w_smokegrenade.mdl");
    VexPcModel("models/vexmira/community/normal/w_tmp.mdl");
    VexPcModel("models/vexmira/community/normal/w_ump45.mdl");
    VexPcModel("models/vexmira/community/normal/w_usp.mdl");
    VexPcModel("models/vexmira/community/normal/w_xm1014.mdl");
}
CommunityWorldModel(ent,const model[])
{
    new current[128]; get_entvar(ent,var_model,current,charsmax(current));
    if (!equal(current,model)) return 0; // upstream CSO SetModel already chose its own pickup model
    if (equal(model,"models/w_ak47.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_ak47.mdl");
    if (equal(model,"models/w_aug.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_aug.mdl");
    if (equal(model,"models/w_awp.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_awp.mdl");
    if (equal(model,"models/w_backpack.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_backpack.mdl");
    if (equal(model,"models/w_c4.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_c4.mdl");
    if (equal(model,"models/w_deagle.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_deagle.mdl");
    if (equal(model,"models/w_elite.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_elite.mdl");
    if (equal(model,"models/w_famas.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_famas.mdl");
    if (equal(model,"models/w_fiveseven.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_fiveseven.mdl");
    if (equal(model,"models/w_g3sg1.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_g3sg1.mdl");
    if (equal(model,"models/w_galil.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_galil.mdl");
    if (equal(model,"models/w_glock18.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_glock18.mdl");
    if (equal(model,"models/w_knife.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_knife.mdl");
    if (equal(model,"models/w_m249.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_m249.mdl");
    if (equal(model,"models/w_m3.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_m3.mdl");
    if (equal(model,"models/w_m4a1.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_m4a1.mdl");
    if (equal(model,"models/w_mac10.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_mac10.mdl");
    if (equal(model,"models/w_mp5.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_mp5.mdl");
    if (equal(model,"models/w_p228.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_p228.mdl");
    if (equal(model,"models/w_p90.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_p90.mdl");
    if (equal(model,"models/w_scout.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_scout.mdl");
    if (equal(model,"models/w_sg550.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_sg550.mdl");
    if (equal(model,"models/w_sg552.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_sg552.mdl");
    if (equal(model,"models/w_shield.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_shield.mdl");
    if (equal(model,"models/w_tmp.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_tmp.mdl");
    if (equal(model,"models/w_ump45.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_ump45.mdl");
    if (equal(model,"models/w_usp.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_usp.mdl");
    if (equal(model,"models/w_xm1014.mdl")) return CommunitySetWorld(ent,"models/vexmira/community/normal/w_xm1014.mdl");
    return 0;
}

CommunitySetWorld(ent,const path[])
{
    if (!VexPrecached(path)) return 0;   // v4.1: file missing on the server -> keep the stock world model
    new Float:mins[3],Float:maxs[3]; get_entvar(ent,var_mins,mins); get_entvar(ent,var_maxs,maxs);
    engfunc(EngFunc_SetModel,ent,path); engfunc(EngFunc_SetSize,ent,mins,maxs);
    return 1;
}
