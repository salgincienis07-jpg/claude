// wbyokomo classic Jetpack+Bazooka, Vexmira economy/lifecycle adaptation.
new Float:fFuelClock[33], Float:fFuelRemainder[33];
#include <vex_community>
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <engine>
#include <xs>
#define SoundFire "vexmira/community/jetpack/rocket.wav"
#define SoundTravel "vexmira/community/jetpack/travel.wav"
#define SoundFly "vexmira/community/jetpack/fly.wav"
#define SoundBlow "vexmira/community/jetpack/blow.wav"
#define SoundPickup "vexmira/meme/discord.wav"
#define ModelRocket "models/vexmira/community/jetpack/rpgrocket.mdl"
#define ModelJetpack_P "models/vexmira/community/jetpack/p_jetpack.mdl"
#define ModelJetpack_W "models/vexmira/community/jetpack/w_jetpack.mdl"
#define ModelJetpack_V "models/vexmira/community/jetpack/v_jetpack.mdl"
#define ClassJetpack "gg_jetpack"
#define ClassJetpack_P "gg_jetpack_p"
#define ClassRocket "gg_bazooka"
#define ItemName "Jetpack+Bazooka"
#define ItemCost 2500
#define RocketSpeed 3000
#define RocketRadius 150.0
#define RocketDamage 250.0
#define JpFwdSpeed 400
#define JpUpVelocity 200.0
#define MaxGas 3000
#define IconGreenGas 299
#define IconYellowGas 200
#define IconRedGas 100
#define FlameAndSoundRate 6
//Uncomment this to fully disable knockback
//#define DISABLE_ALL_KNOCKBACK
//Uncomment this to make dropped jetpack bouncing
//#define MAKE_JETPACK_BOUNCING
//Uncomment this to allow player to drop their jetpack
#define ALLOW_DROP_JETPACK
//Uncomment this to enable death effect (gibs and blood) killed by rocket
//#define MAKE_DEATH_EFFECT
//Uncomment this to enable status icon
//#define MAKE_STATUS_ICON
new iGas[33], Float:fLastShot[33], bool:bHasJetpack[33], SprTrail, SprExplode, SprRing, SprFlame, iMsgScreenShake
#if defined MAKE_DEATH_EFFECT
new bool:bKilledByRocket[33]
#endif
#if defined MAKE_STATUS_ICON
new iMsgStatusIcon
#endif
const PDATA_SAFE = 2
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX_WEAPONS = 4
public plugin_precache()
{
    SprTrail = precache_model("sprites/smoke.spr")
    SprExplode = precache_model("sprites/zerogxplode.spr")
    SprRing = precache_model("sprites/shockwave.spr")
    SprFlame = precache_model("sprites/xfireball3.spr")
    precache_model(ModelRocket)
    precache_model(ModelJetpack_P)
    precache_model(ModelJetpack_W)
    precache_model(ModelJetpack_V)
    precache_sound(SoundFire)
    precache_sound(SoundTravel)
    precache_sound(SoundFly)
    precache_sound(SoundBlow)
    precache_sound(SoundPickup)
}
public plugin_init()
{
    register_plugin(ItemName, "0.0.1", "wbyokomo") //30.October.2014 04:21PM
    register_event("HLTV", "OnNewRound", "a", "1=0", "2=0")
    RegisterHam(Ham_Killed, "player", "OnKilled")
    //RegisterHam(Ham_Killed, "player", "OnKilled", 0, true) //this is for new amx183devbuild only
    RegisterHam(Ham_Item_Deploy, "weapon_knife", "OnDeployKnifePost", 1)
    register_touch(ClassJetpack, "player", "OnTouchJetPack")
    register_touch(ClassRocket, "*", "OnTouchRocket")
    register_forward(FM_ClientDisconnect, "OnClientDisconnect")
    register_forward(FM_CmdStart, "OnCmdStart")
    iMsgScreenShake = get_user_msgid("ScreenShake")
    #if defined MAKE_STATUS_ICON
    iMsgStatusIcon = get_user_msgid("StatusIcon")
    #endif
    #if defined ALLOW_DROP_JETPACK
    register_clcmd("drop_jp", "CmdDropJetPack")
    register_clcmd("drop", "CommunityDrop")
    #endif
}
#if defined ALLOW_DROP_JETPACK
public CmdDropJetPack(id)
{
    if(!is_user_alive(id) || !bHasJetpack[id]) return PLUGIN_HANDLED;
    CreateWorldJetPack(id)
    RemovePlayerJetPack(id)
    bHasJetpack[id] = false
    #if defined MAKE_STATUS_ICON
    DrawColoredIcon(id)
    #endif
    vex_restore_appearance(id);
    return PLUGIN_HANDLED;
}
#endif
public CmdBuyJetPack(id)
{
    if(!is_user_alive(id)) return PLUGIN_HANDLED;
    if(bHasJetpack[id])
    {
        client_print(id, print_chat, "[JETPACK] You already have this item.")
        return PLUGIN_HANDLED;
    }
    new money = cs_get_user_money(id)
    if(money < ItemCost)
    {
        client_print(id, print_chat, "[JETPACK] Not enough CASH to purchase this item.")
        return PLUGIN_HANDLED;
    }
    CreateJetPack(id, 1)
    client_print(id, print_chat, "[JETPACK] Jetpack satın aldın. Uçmak için '4Ctrl+Space' tuşlarına bas.")
    client_print(id, print_chat, "[JETPACK] Roket atmak için farenin '4Sağ Tuşuna' bas.")
    emit_sound(id, CHAN_STATIC, SoundPickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    cs_set_user_money(id, money-ItemCost)
    return PLUGIN_CONTINUE; //let others see /jp in chat, so they know you purchase a Jetpack
}
public OnNewRound()
{
    remove_entity_name(ClassJetpack)
    remove_entity_name(ClassRocket)
    for(new id=1;id<=32;id++) { RemovePlayerJetPack(id); ResetPlayerData(id); }
}
public client_putinserver(id)
{
    ResetPlayerData(id)
}
public OnClientDisconnect(id)
{
    if(bHasJetpack[id])
    {
        RemovePlayerJetPack(id)
        ResetPlayerData(id)
    }
}
public OnKilled(id, atk, gibs)
{
    if(bHasJetpack[id])
    {
        CreateWorldJetPack(id)
        ResetPlayerData(id)
        RemovePlayerJetPack(id)
        #if defined MAKE_STATUS_ICON
        DrawColoredIcon(id)
        #endif
    }
    #if defined MAKE_DEATH_EFFECT
    if(bKilledByRocket[id])
    {
        SetHamParamInteger(3, 2)
        new Float:fOrigin[3]; pev(id, pev_origin, fOrigin);
        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
        write_byte(TE_LAVASPLASH)
        engfunc(EngFunc_WriteCoord, fOrigin[0])
        engfunc(EngFunc_WriteCoord, fOrigin[1])
        engfunc(EngFunc_WriteCoord, fOrigin[2])
        message_end()
        bKilledByRocket[id] = false
    }
    #endif
}
public OnCmdStart(id, uc_handle, random_seed)
{
    if(!is_user_alive(id) || vex_is_zombie(id) || !bHasJetpack[id]) return;
    if (get_user_weapon(id) != CSW_KNIFE) return;
    new Float:now = get_gametime();
    new Float:dt = floatclamp(now - fFuelClock[id], 0.0, 0.1);
    fFuelClock[id] = now;
    static button; button = get_uc(uc_handle, UC_Buttons);
    if((iGas[id] > 0) && (button & IN_DUCK) && (button & IN_JUMP))
    {
        static Float:Velocity[3]
        velocity_by_aim(id, JpFwdSpeed, Velocity)
        Velocity[2] = JpUpVelocity
        entity_set_vector(id, EV_VEC_velocity, Velocity)
        fFuelRemainder[id] += dt * 250.0;
        new use = floatround(fFuelRemainder[id], floatround_floor);
        fFuelRemainder[id] -= float(use);
        iGas[id] = max(0, iGas[id] - use);
        if(random(FlameAndSoundRate) == 2) //make random chance to draw flame & play sound to reduce lag, send MSG_PVS instead of MSG_BROADCAST
        {
            if(iGas[id] > 160) emit_sound(id, CHAN_WEAPON, SoundFly, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
            else emit_sound(id, CHAN_WEAPON, SoundBlow, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
            static Float:Origin[3]
            entity_get_vector(id, EV_VEC_origin, Origin)
            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
            write_byte(TE_SPRITE)
            engfunc(EngFunc_WriteCoord, Origin[0])
            engfunc(EngFunc_WriteCoord, Origin[1])
            engfunc(EngFunc_WriteCoord, Origin[2])
            write_short(SprFlame)
            write_byte(8)
            write_byte(200)
            message_end()
        }
    }
    else if(button & IN_ATTACK2)
    {
        static Float:ctime; ctime = get_gametime();
        if(fLastShot[id] < ctime)
        {
            fLastShot[id] = ctime+10.0
            CmdRocket(id)
        }
    }
    else if(button & IN_USE)
    {
        static Float:fVelocity[3]; entity_get_vector(id, EV_VEC_velocity, fVelocity);
        if(fVelocity[2] < 0.0)
        {
            fVelocity[2] = -60.0
            entity_set_vector(id, EV_VEC_velocity, fVelocity)
        }
    }
    else if((iGas[id] < MaxGas) && !(button & IN_DUCK) && !(button & IN_JUMP))
    {
        fFuelRemainder[id] += dt * 125.0;
        new gain = floatround(fFuelRemainder[id], floatround_floor);
        fFuelRemainder[id] -= float(gain);
        iGas[id] = min(MaxGas, iGas[id] + gain);
    }
    //draw colored icon based on gas amount
    #if defined MAKE_STATUS_ICON
    if(iGas[id] == IconGreenGas) DrawColoredIcon(id, 1, 0, 255, 0);
    else if(iGas[id] == IconYellowGas) DrawColoredIcon(id, 1, 255, 255, 0);
    else if(iGas[id] == IconRedGas) DrawColoredIcon(id, 1, 255, 0, 0);
    #endif
}
#if defined MAKE_STATUS_ICON
DrawColoredIcon(id, mode=0, r=0, g=0, b=0)
{
    if(!mode)
    {
        message_begin(MSG_ONE, iMsgStatusIcon, _, id)
        write_byte(0)
        write_string("item_longjump")
        message_end()
    }
    else
    {
        message_begin(MSG_ONE, iMsgStatusIcon, _, id)
        write_byte(1) //mode
        write_string("item_longjump")
        write_byte(r) //r
        write_byte(g) //g
        write_byte(b) //b
        message_end()
    }
}
#endif
public OnDeployKnifePost(ent)
{
    if(pev_valid(ent) == PDATA_SAFE)
    {
        new id = get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
        if(pev_valid(id) && bHasJetpack[id]) set_pev(id, pev_viewmodel2, ModelJetpack_V);
    }
}
public OnTouchJetPack(ent, id)
{
    if(is_valid_ent(ent) && is_user_connected(id))
    {
        if(!is_user_alive(id) || vex_is_zombie(id) || bHasJetpack[id]) return PLUGIN_HANDLED;
        new fuel = entity_get_int(ent, EV_INT_iuser4);
        entity_set_int(ent, EV_INT_solid, SOLID_NOT)
        remove_entity(ent)
        vex_prepare_jetpack(id);
        CreateJetPack(id, 0)
        iGas[id] = clamp(fuel, 0, MaxGas);
        engclient_cmd(id, "weapon_knife");
        set_pev(id, pev_viewmodel2, ModelJetpack_V);
        client_print(id, print_chat, "[JETPACK] You got a Jetpack, fly like a BOSS. Hold 'JUMP+DUCK' to fly.")
        client_print(id, print_chat, "[JETPACK] Press mouse 'RIGHT-CLICK' to shoot rocket.")
        emit_sound(id, CHAN_STATIC, SoundPickup, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    }
    return PLUGIN_CONTINUE;
}
public OnTouchRocket(ent, id)
{
    if(!is_valid_ent(ent)) return;
    entity_set_int(ent, EV_INT_solid, SOLID_NOT)
    emit_sound(ent, CHAN_VOICE, SoundTravel, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM) //stop rocket loop sound
    new Float:atkOrigin[3]
    entity_get_vector(ent, EV_VEC_origin, atkOrigin)
    //explosion
    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, atkOrigin, 0)
    write_byte(TE_EXPLOSION)
    engfunc(EngFunc_WriteCoord, atkOrigin[0])
    engfunc(EngFunc_WriteCoord, atkOrigin[1])
    engfunc(EngFunc_WriteCoord, atkOrigin[2])
    write_short(SprExplode)
    write_byte(30)
    write_byte(30)
    write_byte(10)
    message_end()
    //ring
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, atkOrigin, 0)
    write_byte(TE_BEAMCYLINDER)
    engfunc(EngFunc_WriteCoord, atkOrigin[0])
    engfunc(EngFunc_WriteCoord, atkOrigin[1])
    engfunc(EngFunc_WriteCoord, atkOrigin[2])
    engfunc(EngFunc_WriteCoord, atkOrigin[0])
    engfunc(EngFunc_WriteCoord, atkOrigin[1])
    engfunc(EngFunc_WriteCoord, atkOrigin[2]+500.0)
    write_short(SprRing)
    write_byte(0)
    write_byte(0)
    write_byte(5)
    write_byte(30)
    write_byte(0)
    write_byte(224)
    write_byte(224)
    write_byte(224)
    write_byte(255)
    write_byte(0)
    message_end()
    //get attacker
    new attacker = entity_get_edict(ent, EV_ENT_owner)
    if(attacker < 1 || attacker > 32 || !is_user_alive(attacker) || vex_is_zombie(attacker) || entity_get_int(ent, EV_INT_iuser3) != get_user_userid(attacker))
    {
        remove_entity(ent)
        return;
    }
    //get victim
    new victim = -1
    while((victim = engfunc(EngFunc_FindEntityInSphere, victim, atkOrigin, RocketRadius)) != 0)
    {
        if(victim < 1 || victim > 32 || !is_user_alive(victim) || !vex_is_zombie(victim)) continue; //not alive
        if(cs_get_user_team(attacker) == cs_get_user_team(victim)) continue; //friendly fire
        //damage calculation
        new Float:fOrigin[3], Float:fDistance, Float:fDamage
        pev(victim, pev_origin, fOrigin)
        fDistance = get_distance_f(fOrigin, atkOrigin)
        fDamage = RocketDamage - floatmul(RocketDamage, floatdiv(fDistance, RocketRadius))
        fDamage *= 1.0
        if(fDamage < 1.0) continue;
        //screen shake
        message_begin(MSG_ONE_UNRELIABLE, iMsgScreenShake, _, victim)
        write_short((1<<12)*8)
        write_short((1<<12)*3)
        write_short((1<<12)*18)
        message_end()
        //do damage & knockback
        #if !defined DISABLE_ALL_KNOCKBACK
        xs_vec_sub(fOrigin, atkOrigin, fOrigin)
        xs_vec_mul_scalar(fOrigin, fDamage * 0.7, fOrigin)
        if(xs_vec_len(fOrigin) > 0.01) xs_vec_mul_scalar(fOrigin, RocketDamage / xs_vec_len(fOrigin), fOrigin)
        set_pev(victim, pev_velocity, fOrigin)
        #endif
        #if defined MAKE_DEATH_EFFECT
        new Float:fHealth; pev(victim, pev_health, fHealth);
        fHealth = fHealth - fDamage
        if(fHealth <= 0.0)
        {
            //this is much simple but gibs velocity is not awesome, so we move to Ham_Killed to set gibs death
            /*ExecuteHamB(Ham_Killed, victim, attacker, 2)
            pev(victim, pev_origin, fOrigin)
            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
            write_byte(TE_LAVASPLASH)
            engfunc(EngFunc_WriteCoord, fOrigin[0])
            engfunc(EngFunc_WriteCoord, fOrigin[1])
            engfunc(EngFunc_WriteCoord, fOrigin[2])
            message_end()*/
            bKilledByRocket[victim] = true
        }
        #endif
        ExecuteHamB(Ham_TakeDamage, victim, ent, attacker, fDamage, DMG_BULLET)
        //debug chat to see damage done
        //client_print(attacker, print_chat, "Rocket damage: %f -- Victim: %d", fDamage, victim)
    }
    remove_entity(ent)
}
CreateJetPack(id, fullgas)
{
    new ent = create_entity("info_target")
    if(!is_valid_ent(ent)) return;
    bHasJetpack[id] = true
    if(fullgas) iGas[id] = MaxGas;
    new Float:Origin[3]
    entity_get_vector(id, EV_VEC_origin, Origin)
    entity_set_string(ent, EV_SZ_classname, ClassJetpack_P)
    entity_set_model(ent, ModelJetpack_P)
    entity_set_origin(ent, Origin)
    entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW)
    entity_set_edict(ent, EV_ENT_aiment, id)
    entity_set_int(ent, EV_INT_solid, SOLID_NOT)
    entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
    entity_set_edict(ent, EV_ENT_owner, id)
}
CreateWorldJetPack(id)
{
    new ent = create_entity("info_target")
    if(!is_valid_ent(ent)) return;
    new Float:Aim[3], Float:Origin[3], iColor[3]
    velocity_by_aim(id, 32, Aim)
    entity_get_vector(id, EV_VEC_origin, Origin)
    Origin[0] += 2*Aim[0]
    Origin[1] += 2*Aim[1]
    entity_set_string(ent, EV_SZ_classname, ClassJetpack)
    entity_set_int(ent, EV_INT_iuser4, iGas[id]);
    entity_set_model(ent, ModelJetpack_W)
    #if defined MAKE_JETPACK_BOUNCING
    entity_set_int(ent, EV_INT_movetype, MOVETYPE_BOUNCE)
    #else
    entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
    #endif
    entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER)
    entity_set_size(ent, Float:{-8.0, -8.0, -8.0}, Float:{8.0, 8.0, 8.0})
    entity_set_float(ent, EV_FL_gravity, 1.25)
    entity_set_vector(ent, EV_VEC_origin, Origin)
    velocity_by_aim(id, 400, Aim)
    entity_set_vector(ent, EV_VEC_velocity, Aim)
    iColor[0] = random_num(16,255)
    iColor[1] = random(255)
    iColor[2] = random(255)
    set_rendering(ent, kRenderFxGlowShell, iColor[0], iColor[1], iColor[2], kRenderNormal, 0)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW)
    write_short(ent)
    write_short(SprTrail)
    write_byte(10)
    write_byte(5)
    write_byte(iColor[0])
    write_byte(iColor[1])
    write_byte(iColor[2])
    write_byte(192)
    message_end()
}
CmdRocket(id)
{
    new ent = create_entity("info_target")
    if(!is_valid_ent(ent)) return;
    new Float:origin[3], Float:velocity[3]
    entity_get_vector(id, EV_VEC_origin, origin)
    origin[2] += 16.0
    entity_set_string(ent, EV_SZ_classname, ClassRocket)
    entity_set_model(ent, ModelRocket)
    entity_set_origin(ent, origin)
    entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
    entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
    entity_set_size(ent, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
    entity_set_edict(ent, EV_ENT_owner, id)
    entity_set_int(ent, EV_INT_iuser3, get_user_userid(id));
    velocity_by_aim(id, RocketSpeed, velocity)
    entity_set_vector(ent, EV_VEC_velocity,    velocity)
    vector_to_angle(velocity, origin)
    entity_set_vector(ent, EV_VEC_angles, origin)
    entity_set_int(ent, EV_INT_effects, EF_LIGHT)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_BEAMFOLLOW)
    write_short(ent)
    write_short(SprTrail)
    write_byte(30)
    write_byte(5)
    write_byte(224)
    write_byte(224)
    write_byte(224)
    write_byte(192)
    message_end()
    emit_sound(id, CHAN_STATIC, SoundFire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    emit_sound(ent, CHAN_VOICE, SoundTravel, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
RemovePlayerJetPack(id)
{
    new ent = -1
    while((ent = find_ent_by_class(ent, ClassJetpack_P)))
    {
        if(!is_valid_ent(ent)) continue;
        if(entity_get_edict(ent, EV_ENT_owner) != id) continue;
        remove_entity(ent)
    }
}
ResetPlayerData(id)
{
    bHasJetpack[id] = false
    fLastShot[id] = 0.0
    iGas[id] = MaxGas
    fFuelClock[id] = get_gametime(); fFuelRemainder[id] = 0.0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

public vex_has(id) { return bHasJetpack[id]; }
public vex_give(id) {
    if (!is_user_alive(id) || vex_is_zombie(id) || bHasJetpack[id]) return 0;
    vex_prepare_jetpack(id);
    CreateJetPack(id, 1); fFuelClock[id] = get_gametime(); fFuelRemainder[id] = 0.0;
    if (!bHasJetpack[id]) return 0;
    engclient_cmd(id, "weapon_knife"); set_pev(id, pev_viewmodel2, ModelJetpack_V);
    return 1;
}
public vex_remove(id) { RemovePlayerJetPack(id); ResetPlayerData(id); return 1; }
public vex_infected(id) { if (bHasJetpack[id]) CreateWorldJetPack(id); vex_remove(id); return 1; }
public CommunityDrop(id) {
    if (!bHasJetpack[id] || get_user_weapon(id) != CSW_KNIFE) return PLUGIN_CONTINUE;
    CmdDropJetPack(id); vex_restore_appearance(id); return PLUGIN_HANDLED;
}
