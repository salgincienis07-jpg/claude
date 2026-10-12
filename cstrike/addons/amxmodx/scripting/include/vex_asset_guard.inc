// Only a missing/damaged MODEL or SPRITE of a weapon plugin is fatal (precaching it would crash the server).
// Sounds, .txt HUD files and textures only warn. The core plugin never disables itself.
stock bool:VexGuardFatal(const scope[], const path[])
{
    if(equal(scope,"vexmira_zombie")) return false;
    return containi(path,".mdl")!=-1 || containi(path,".spr")!=-1;
}
// Checks only this plugin's required assets; optional restored paths are independently validated.
stock bool:VexAssetGuard(const scope[])
{
    new required[192],sample[4];
    if(equal(scope,"vex_salamander")) {
        static const paths[][]={
            "models/p_salamander.mdl",
            "models/v_salamander.mdl",
            "models/w_salamander.mdl",
            "sound/weapons/flamegun-1.wav",
            "sound/weapons/flamegun_clipin1.wav",
            "sound/weapons/flamegun_clipin2.wav",
            "sound/weapons/flamegun_clipout1.wav",
            "sound/weapons/flamegun_clipout2.wav",
            "sound/weapons/flamegun_draw.wav",
            "sprites/vex_community/salamander/640hud59_2.spr",
            "sprites/vex_community/salamander/640hud60_2.spr",
            "sprites/vex_community/salamander/640hud7_2.spr",
            "sprites/vex_community/salamander/flame_burn01.spr",
            "sprites/vex_community/salamander/flame_puff01.spr",
            "sprites/weapon_flamethrower.txt"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_janus7")) {
        static const paths[][]={
            "models/p_janus7.mdl",
            "models/v_janus7.mdl",
            "models/w_janus7.mdl",
            "sound/weapons/change1_ready.wav",
            "sound/weapons/janus7_change1.wav",
            "sound/weapons/janus7_change2.wav",
            "sound/weapons/janus7_shoot.wav",
            "sound/weapons/janus7_shoot2.wav",
            "sound/weapons/mg3_clipin.wav",
            "sound/weapons/mg3_clipout.wav",
            "sound/weapons/mg3_close.wav",
            "sound/weapons/mg3_open.wav",
            "sprites/vex_community/janus7/640hud12_2.spr",
            "sprites/vex_community/janus7/640hud7_2.spr",
            "sprites/vex_community/janus7/640hud99_2.spr",
            "sprites/weapon_janus7.txt"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_hev")) {
        static const paths[][]={
            "models/hev_weapons/p_wrench.mdl",
            "models/hev_weapons/v_ak47.mdl",
            "models/hev_weapons/v_aug.mdl",
            "models/hev_weapons/v_awp.mdl",
            "models/hev_weapons/v_deagle.mdl",
            "models/hev_weapons/v_famas.mdl",
            "models/hev_weapons/v_g3sg1.mdl",
            "models/hev_weapons/v_galil.mdl",
            "models/hev_weapons/v_glock18.mdl",
            "models/hev_weapons/v_m249.mdl",
            "models/hev_weapons/v_m3.mdl",
            "models/hev_weapons/v_m4a1.mdl",
            "models/hev_weapons/v_mp5.mdl",
            "models/hev_weapons/v_p228.mdl",
            "models/hev_weapons/v_p90.mdl",
            "models/hev_weapons/v_sg550.mdl",
            "models/hev_weapons/v_tmp.mdl",
            "models/hev_weapons/v_ump45.mdl",
            "models/hev_weapons/v_usp.mdl",
            "models/hev_weapons/v_wrench.mdl",
            "models/hev_weapons/v_xm1014.mdl",
            "models/player/hev_zombie/hev_zombie.mdl",
            "models/v_hev.mdl",
            "models/v_hev_adrenaline_injector.mdl",
            "models/v_hev_zombie.mdl",
            "sound/Zombi/Zombi_Female_Headdown.wav",
            "sound/Zombi/Zombi_Female_Headup.wav",
            "sound/Zombi/Zombi_Female_Laugh.wav",
            "sound/fvox/flatline.wav",
            "sound/fvox/health_critical.wav",
            "sound/fvox/hevSuit_get_infected_alert2.wav",
            "sound/fvox/hev_logon.wav",
            "sound/fvox/morphine_shot.wav",
            "sound/fvox/power_restored.wav",
            "sound/items/cliprelease1.wav",
            "sound/jb_engine_b1/shop/syringe_hit.wav",
            "sound/jb_engine_b1/shop/syringe_use.wav",
            "sound/player/pl_long_jump_1.wav",
            "sound/weapons/G_MZC_MP7_CLIPIN.wav",
            "sound/weapons/G_MZC_MP7_CLIPOUT.wav",
            "sound/weapons/G_RELOAD_MP7.wav",
            "sound/weapons/boltpull1.wav",
            "sound/weapons/clipin1.wav",
            "sound/weapons/clipout1.wav",
            "sound/weapons/de_deploy.wav",
            "sound/weapons/g36_boltback.wav",
            "sound/weapons/g36_boltforward.wav",
            "sound/weapons/g36_draw.wav",
            "sound/weapons/g36_magin.wav",
            "sound/weapons/g36_magout.wav",
            "sound/weapons/movement1.wav",
            "sound/weapons/movement2.wav",
            "sound/weapons/movement3.wav",
            "sound/weapons/null.wav",
            "sound/weapons/p345/p345_magin.wav",
            "sound/weapons/p345/p345_magout.wav",
            "sound/weapons/p345/p345_magplace.wav",
            "sound/weapons/p345/p345_slide.wav",
            "sound/weapons/slideback1.wav",
            "sound/weapons/wrench_deploy.wav",
            "sound/weapons/wrench_hit.wav",
            "sound/weapons/wrench_hitwall.wav",
            "sound/weapons/wrench_slash.wav",
            "sound/weapons/wrench_stab.wav"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_ethereal")) {
        static const paths[][]={
            "models/p_ethereal.mdl",
            "models/v_ethereal2.mdl",
            "models/w_ethereal.mdl",
            "sound/weapons/ethereal-1.wav",
            "sound/weapons/ethereal_draw.wav",
            "sound/weapons/ethereal_idle1.wav",
            "sound/weapons/ethereal_reload.wav",
            "sprites/vex_community/ethereal/640hud74_2.spr",
            "sprites/vex_community/ethereal/640hud7_2.spr",
            "sprites/vex_community/ethereal/muzzleflash7.spr",
            "sprites/weapon_ethereal.txt"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_plasma")) {
        static const paths[][]={
            "models/p_plasmagun.mdl",
            "models/v_plasmagun2.mdl",
            "models/w_plasmagun.mdl",
            "sound/weapons/plasmagun-1.wav",
            "sound/weapons/plasmagun_clipin1.wav",
            "sound/weapons/plasmagun_clipin2.wav",
            "sound/weapons/plasmagun_clipout.wav",
            "sound/weapons/plasmagun_draw.wav",
            "sound/weapons/plasmagun_exp.wav",
            "sound/weapons/plasmagun_idle.wav",
            "sprites/vex_community/plasma/640hud3_2.spr",
            "sprites/vex_community/plasma/640hud91_2.spr",
            "sprites/vex_community/plasma/muzzleflash27.spr",
            "sprites/vex_community/plasma/plasmaball.spr",
            "sprites/vex_community/plasma/plasmabomb.spr",
            "sprites/weapon_plasmagun.txt"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_katana")) {
        static const paths[][]={
            "models/p_katanad.mdl",
            "models/v_katanad.mdl",
            "sound/weapons/katanad_draw.wav",
            "sound/weapons/katanad_hit1.wav",
            "sound/weapons/katanad_hit2.wav",
            "sound/weapons/katanad_hitwall.wav",
            "sound/weapons/katanad_slash1.wav",
            "sound/weapons/katanad_slash2.wav",
            "sound/weapons/katanad_slash3.wav",
            "sound/weapons/katanad_stab.wav",
            "sound/weapons/katanad_stab_miss.wav"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_bow")) {
        static const paths[][]={
            "models/arrow.mdl",
            "models/p_bow.mdl",
            "models/p_bow_empty.mdl",
            "models/v_bow.mdl",
            "models/w_bow.mdl",
            "sound/weapons/bow_charge_finish1.wav",
            "sound/weapons/bow_charge_shoot1_empty.wav",
            "sound/weapons/bow_charge_shoot2.wav",
            "sound/weapons/bow_charge_start1.wav",
            "sound/weapons/bow_charge_start2.wav",
            "sound/weapons/bow_draw.wav",
            "sound/weapons/bow_shoot1.wav",
            "sprites/vex_community/bow/640hud12_2.spr",
            "sprites/vex_community/bow/640hud98_2.spr",
            "sprites/weapon_bow.txt"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_lightsaber")) {
        static const paths[][]={
            "models/p_sfsword_off.mdl",
            "models/p_sfsword_on.mdl",
            "models/v_sfsword.mdl",
            "sound/weapons/sfsword_draw.wav",
            "sound/weapons/sfsword_hit1.wav",
            "sound/weapons/sfsword_hit2.wav",
            "sound/weapons/sfsword_idle.wav",
            "sound/weapons/sfsword_midslash1.wav",
            "sound/weapons/sfsword_midslash2.wav",
            "sound/weapons/sfsword_midslash3.wav",
            "sound/weapons/sfsword_off.wav",
            "sound/weapons/sfsword_off_hit.wav",
            "sound/weapons/sfsword_off_slash1.wav",
            "sound/weapons/sfsword_on.wav",
            "sound/weapons/sfsword_stab.wav",
            "sound/weapons/sfsword_wall1.wav",
            "sound/weapons/sfsword_wall2.wav"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_minigun")) {
        static const paths[][]={
            "models/p_m134x.mdl",
            "models/shell2x.mdl",
            "models/shellx.mdl",
            "models/v_m134x.mdl",
            "models/w_m134x.mdl",
            "sound/weapons/m134-1.wav",
            "sound/weapons/m134_clipoff.wav",
            "sound/weapons/m134_clipon.wav",
            "sound/weapons/m134_pinpull.wav",
            "sound/weapons/m134_spindown.wav",
            "sound/weapons/m134_spinup.wav",
            "sprites/640hud26_2.spr",
            "sprites/640hud35_2.spr"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_jetpack")) {
        static const paths[][]={
            "models/vexmira/community/jetpack/p_jetpack.mdl",
            "models/vexmira/community/jetpack/rpgrocket.mdl",
            "models/vexmira/community/jetpack/v_jetpack.mdl",
            "models/vexmira/community/jetpack/w_jetpack.mdl",
            "sound/vexmira/community/jetpack/blow.wav",
            "sound/vexmira/community/jetpack/fly.wav",
            "sound/vexmira/community/jetpack/rocket.wav",
            "sound/vexmira/community/jetpack/travel.wav",
            "sound/vexmira/meme/discord.wav"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vexmira_zombie")) {
        static const paths[][]={
            "models/player/vex_gign/vex_gign.mdl",
            "models/player/vex_gsg9/vex_gsg9.mdl",
            "models/player/vex_halo/vex_halo.mdl",
            "models/player/vex_halo/vex_haloT.mdl",
            "models/player/vex_soldier/vex_soldier.mdl",
            "models/player/vex_spetsnaz/vex_spetsnaz.mdl",
            "models/vexmira/community/knives/v_butterfly.mdl",
            "models/vexmira/community/normal/p_ak47.mdl",
            "models/vexmira/community/normal/p_aug.mdl",
            "models/vexmira/community/normal/p_awp.mdl",
            "models/vexmira/community/normal/p_c4.mdl",
            "models/vexmira/community/normal/p_deagle.mdl",
            "models/vexmira/community/normal/p_elite.mdl",
            "models/vexmira/community/normal/p_famas.mdl",
            "models/vexmira/community/normal/p_fiveseven.mdl",
            "models/vexmira/community/normal/p_flashbang.mdl",
            "models/vexmira/community/normal/p_g3sg1.mdl",
            "models/vexmira/community/normal/p_galil.mdl",
            "models/vexmira/community/normal/p_glock18.mdl",
            "models/vexmira/community/normal/p_hegrenade.mdl",
            "models/vexmira/community/normal/p_knife.mdl",
            "models/vexmira/community/normal/p_m249.mdl",
            "models/vexmira/community/normal/p_m3.mdl",
            "models/vexmira/community/normal/p_m4a1.mdl",
            "models/vexmira/community/normal/p_mac10.mdl",
            "models/vexmira/community/normal/p_mp5.mdl",
            "models/vexmira/community/normal/p_p228.mdl",
            "models/vexmira/community/normal/p_p90.mdl",
            "models/vexmira/community/normal/p_scout.mdl",
            "models/vexmira/community/normal/p_sg550.mdl",
            "models/vexmira/community/normal/p_sg552.mdl",
            "models/vexmira/community/normal/p_smokegrenade.mdl",
            "models/vexmira/community/normal/p_tmp.mdl",
            "models/vexmira/community/normal/p_ump45.mdl",
            "models/vexmira/community/normal/p_usp.mdl",
            "models/vexmira/community/normal/p_xm1014.mdl",
            "models/vexmira/community/normal/v_ak47.mdl",
            "models/vexmira/community/normal/v_aug.mdl",
            "models/vexmira/community/normal/v_awp.mdl",
            "models/vexmira/community/normal/v_deagle.mdl",
            "models/vexmira/community/normal/v_galil.mdl",
            "models/vexmira/community/normal/v_knife.mdl",
            "models/vexmira/community/normal/v_m249.mdl",
            "models/vexmira/community/normal/v_m4a1.mdl",
            "models/vexmira/community/normal/v_mp5.mdl",
            "models/vexmira/community/normal/v_sg550.mdl",
            "models/vexmira/community/normal/v_sg552.mdl",
            "models/vexmira/community/normal/v_xm1014.mdl",
            "models/vexmira/community/normal/w_ak47.mdl",
            "models/vexmira/community/normal/w_aug.mdl",
            "models/vexmira/community/normal/w_awp.mdl",
            "models/vexmira/community/normal/w_backpack.mdl",
            "models/vexmira/community/normal/w_c4.mdl",
            "models/vexmira/community/normal/w_deagle.mdl",
            "models/vexmira/community/normal/w_elite.mdl",
            "models/vexmira/community/normal/w_famas.mdl",
            "models/vexmira/community/normal/w_fiveseven.mdl",
            "models/vexmira/community/normal/w_flashbang.mdl",
            "models/vexmira/community/normal/w_g3sg1.mdl",
            "models/vexmira/community/normal/w_galil.mdl",
            "models/vexmira/community/normal/w_glock18.mdl",
            "models/vexmira/community/normal/w_hegrenade.mdl",
            "models/vexmira/community/normal/w_knife.mdl",
            "models/vexmira/community/normal/w_m249.mdl",
            "models/vexmira/community/normal/w_m3.mdl",
            "models/vexmira/community/normal/w_m4a1.mdl",
            "models/vexmira/community/normal/w_mac10.mdl",
            "models/vexmira/community/normal/w_mp5.mdl",
            "models/vexmira/community/normal/w_p228.mdl",
            "models/vexmira/community/normal/w_p90.mdl",
            "models/vexmira/community/normal/w_scout.mdl",
            "models/vexmira/community/normal/w_sg550.mdl",
            "models/vexmira/community/normal/w_sg552.mdl",
            "models/vexmira/community/normal/w_shield.mdl",
            "models/vexmira/community/normal/w_smokegrenade.mdl",
            "models/vexmira/community/normal/w_tmp.mdl",
            "models/vexmira/community/normal/w_ump45.mdl",
            "models/vexmira/community/normal/w_usp.mdl",
            "models/vexmira/community/normal/w_xm1014.mdl",
            "models/zombie_plague/v_grenade_infect.mdl"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_dragonsword")) {
        static const paths[][]={
            "models/p_dragonsword.mdl",
            "models/v_dragonsword2.mdl",
            "sound/weapons/dragonsword_draw.wav",
            "sound/weapons/dragonsword_hit1.wav",
            "sound/weapons/dragonsword_hit2.wav",
            "sound/weapons/dragonsword_idle.wav",
            "sound/weapons/dragonsword_slash1.wav",
            "sound/weapons/dragonsword_slash2.wav",
            "sound/weapons/dragonsword_stab.wav",
            "sound/weapons/dragonsword_stab_hit.wav",
            "sound/weapons/dragonsword_wall.wav"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_thunderbolt")) {
        static const paths[][]={
            "models/p_sfsniper.mdl",
            "models/v_sfsightB.mdl",
            "models/v_sfsightR.mdl",
            "models/v_sfsniperF.mdl",
            "models/w_sfsniper.mdl",
            "sound/weapons/sfsniper-1.wav",
            "sound/weapons/sfsniper_draw.wav",
            "sound/weapons/sfsniper_idle.wav",
            "sound/weapons/sfsniper_insight1.wav",
            "sound/weapons/sfsniper_zoom.wav",
            "sprites/vex_community/thunderbolt/640hud10_2.spr",
            "sprites/vex_community/thunderbolt/640hud2_2.spr",
            "sprites/vex_community/thunderbolt/640hud81_2.spr",
            "sprites/weapon_sfsniperF.txt"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    if(equal(scope,"vex_horseaxe")) {
        static const paths[][]={
            "models/p_horseaxe.mdl",
            "models/v_horseaxe.mdl",
            "sound/weapons/tomahawk_draw.wav",
            "sound/weapons/tomahawk_slash1.wav",
            "sound/weapons/tomahawk_slash1_hit.wav",
            "sound/weapons/tomahawk_slash2.wav",
            "sound/weapons/tomahawk_slash2_hit.wav",
            "sound/weapons/tomahawk_stab_hit.wav",
            "sound/weapons/tomahawk_stab_miss.wav",
            "sound/weapons/tomahawk_wall.wav"
        };
        for(new i=0;i<sizeof paths;i++) {
            if(!file_exists(paths[i],true) || file_size(paths[i])<4) {
                formatex(required,charsmax(required),"Missing asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue;
            }
            if(containi(paths[i],".mdl")!=-1 || containi(paths[i],".spr")!=-1 || containi(paths[i],".wav")!=-1) {
                new fp=fopen(paths[i],"rb"); if(!fp) continue;
                fread_blocks(fp,sample,4,BLOCK_CHAR); fclose(fp);
                new bool:ok=(containi(paths[i],".mdl")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='T'):
                    (containi(paths[i],".spr")!=-1)?(sample[0]=='I' && sample[1]=='D' && sample[2]=='S' && sample[3]=='P'):
                    (sample[0]=='R' && sample[1]=='I' && sample[2]=='F' && sample[3]=='F');
                if(!ok) { formatex(required,charsmax(required),"Damaged asset: %s",paths[i]); if(VexGuardFatal(scope,paths[i])) { log_amx("[AssetGuard] %s -> %s.amxx kapatildi (bu dosyayi sunucuya ve FastDL e yukle)",required,scope); set_fail_state(required); return false; } log_amx("[AssetGuard] UYARI %s (%s) - eklenti calismaya devam ediyor",required,scope); continue; }
            }
        }
    }
    return true;
}
