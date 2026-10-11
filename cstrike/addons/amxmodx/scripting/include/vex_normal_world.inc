CommunityNormalPrecache()
{
    precache_model("models/vexmira/community/normal/p_ak47.mdl");
    precache_model("models/vexmira/community/normal/p_aug.mdl");
    precache_model("models/vexmira/community/normal/p_awp.mdl");
    precache_model("models/vexmira/community/normal/p_c4.mdl");
    precache_model("models/vexmira/community/normal/p_deagle.mdl");
    precache_model("models/vexmira/community/normal/p_elite.mdl");
    precache_model("models/vexmira/community/normal/p_famas.mdl");
    precache_model("models/vexmira/community/normal/p_fiveseven.mdl");
    precache_model("models/vexmira/community/normal/p_flashbang.mdl");
    precache_model("models/vexmira/community/normal/p_g3sg1.mdl");
    precache_model("models/vexmira/community/normal/p_galil.mdl");
    precache_model("models/vexmira/community/normal/p_glock18.mdl");
    precache_model("models/vexmira/community/normal/p_hegrenade.mdl");
    precache_model("models/vexmira/community/normal/p_knife.mdl");
    precache_model("models/vexmira/community/normal/p_m249.mdl");
    precache_model("models/vexmira/community/normal/p_m3.mdl");
    precache_model("models/vexmira/community/normal/p_m4a1.mdl");
    precache_model("models/vexmira/community/normal/p_mac10.mdl");
    precache_model("models/vexmira/community/normal/p_mp5.mdl");
    precache_model("models/vexmira/community/normal/p_p228.mdl");
    precache_model("models/vexmira/community/normal/p_p90.mdl");
    precache_model("models/vexmira/community/normal/p_scout.mdl");
    precache_model("models/vexmira/community/normal/p_sg550.mdl");
    precache_model("models/vexmira/community/normal/p_sg552.mdl");
    precache_model("models/vexmira/community/normal/p_smokegrenade.mdl");
    precache_model("models/vexmira/community/normal/p_tmp.mdl");
    precache_model("models/vexmira/community/normal/p_ump45.mdl");
    precache_model("models/vexmira/community/normal/p_usp.mdl");
    precache_model("models/vexmira/community/normal/p_xm1014.mdl");
    precache_model("models/vexmira/community/normal/w_ak47.mdl");
    precache_model("models/vexmira/community/normal/w_aug.mdl");
    precache_model("models/vexmira/community/normal/w_awp.mdl");
    precache_model("models/vexmira/community/normal/w_backpack.mdl");
    precache_model("models/vexmira/community/normal/w_c4.mdl");
    precache_model("models/vexmira/community/normal/w_deagle.mdl");
    precache_model("models/vexmira/community/normal/w_elite.mdl");
    precache_model("models/vexmira/community/normal/w_famas.mdl");
    precache_model("models/vexmira/community/normal/w_fiveseven.mdl");
    precache_model("models/vexmira/community/normal/w_flashbang.mdl");
    precache_model("models/vexmira/community/normal/w_g3sg1.mdl");
    precache_model("models/vexmira/community/normal/w_galil.mdl");
    precache_model("models/vexmira/community/normal/w_glock18.mdl");
    precache_model("models/vexmira/community/normal/w_hegrenade.mdl");
    precache_model("models/vexmira/community/normal/w_knife.mdl");
    precache_model("models/vexmira/community/normal/w_m249.mdl");
    precache_model("models/vexmira/community/normal/w_m3.mdl");
    precache_model("models/vexmira/community/normal/w_m4a1.mdl");
    precache_model("models/vexmira/community/normal/w_mac10.mdl");
    precache_model("models/vexmira/community/normal/w_mp5.mdl");
    precache_model("models/vexmira/community/normal/w_p228.mdl");
    precache_model("models/vexmira/community/normal/w_p90.mdl");
    precache_model("models/vexmira/community/normal/w_scout.mdl");
    precache_model("models/vexmira/community/normal/w_sg550.mdl");
    precache_model("models/vexmira/community/normal/w_sg552.mdl");
    precache_model("models/vexmira/community/normal/w_shield.mdl");
    precache_model("models/vexmira/community/normal/w_smokegrenade.mdl");
    precache_model("models/vexmira/community/normal/w_tmp.mdl");
    precache_model("models/vexmira/community/normal/w_ump45.mdl");
    precache_model("models/vexmira/community/normal/w_usp.mdl");
    precache_model("models/vexmira/community/normal/w_xm1014.mdl");
}
CommunityWorldModel(ent,const model[])
{
    new current[128]; get_entvar(ent,var_model,current,charsmax(current));
    if (!equal(current,model)) return 0; // upstream CSO SetModel already chose its own pickup model
    if (equal(model,"models/w_ak47.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_ak47.mdl"); return 1; }
    if (equal(model,"models/w_aug.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_aug.mdl"); return 1; }
    if (equal(model,"models/w_awp.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_awp.mdl"); return 1; }
    if (equal(model,"models/w_backpack.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_backpack.mdl"); return 1; }
    if (equal(model,"models/w_c4.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_c4.mdl"); return 1; }
    if (equal(model,"models/w_deagle.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_deagle.mdl"); return 1; }
    if (equal(model,"models/w_elite.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_elite.mdl"); return 1; }
    if (equal(model,"models/w_famas.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_famas.mdl"); return 1; }
    if (equal(model,"models/w_fiveseven.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_fiveseven.mdl"); return 1; }
    if (equal(model,"models/w_g3sg1.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_g3sg1.mdl"); return 1; }
    if (equal(model,"models/w_galil.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_galil.mdl"); return 1; }
    if (equal(model,"models/w_glock18.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_glock18.mdl"); return 1; }
    if (equal(model,"models/w_knife.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_knife.mdl"); return 1; }
    if (equal(model,"models/w_m249.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_m249.mdl"); return 1; }
    if (equal(model,"models/w_m3.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_m3.mdl"); return 1; }
    if (equal(model,"models/w_m4a1.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_m4a1.mdl"); return 1; }
    if (equal(model,"models/w_mac10.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_mac10.mdl"); return 1; }
    if (equal(model,"models/w_mp5.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_mp5.mdl"); return 1; }
    if (equal(model,"models/w_p228.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_p228.mdl"); return 1; }
    if (equal(model,"models/w_p90.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_p90.mdl"); return 1; }
    if (equal(model,"models/w_scout.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_scout.mdl"); return 1; }
    if (equal(model,"models/w_sg550.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_sg550.mdl"); return 1; }
    if (equal(model,"models/w_sg552.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_sg552.mdl"); return 1; }
    if (equal(model,"models/w_shield.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_shield.mdl"); return 1; }
    if (equal(model,"models/w_tmp.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_tmp.mdl"); return 1; }
    if (equal(model,"models/w_ump45.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_ump45.mdl"); return 1; }
    if (equal(model,"models/w_usp.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_usp.mdl"); return 1; }
    if (equal(model,"models/w_xm1014.mdl")) { CommunitySetWorld(ent,"models/vexmira/community/normal/w_xm1014.mdl"); return 1; }
    return 0;
}

CommunitySetWorld(ent,const path[])
{
    new Float:mins[3],Float:maxs[3]; get_entvar(ent,var_mins,mins); get_entvar(ent,var_maxs,maxs);
    engfunc(EngFunc_SetModel,ent,path); engfunc(EngFunc_SetSize,ent,mins,maxs);
}
