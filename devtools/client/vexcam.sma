/* vexcam - render-client camera helper for the Vexmira TEST server only (devtools/client).
 *
 * Positions every real (non-bot, non-HLTV) client - normally the Xash3D render client that
 * devtools/client/shot.py connects - so it can take screenshots from exact spots. Server
 * console commands only; nothing is precached, no game state is changed except the camera
 * client itself (and the optional freeze of a target).
 *
 *   vexcam_pos <x> <y> <z> <pitch> <yaw>          fixed camera (pitch > 0 looks down)
 *   vexcam_look <target> [dist] [height] [yawoff] [aimz] [track]
 *        target: boss | #<userid> | ent:<index> | <name part>
 *        boss  = owner of the overhead boss-bar entity (iuser2 == 'VXOH', model *bossbar*)
 *        camera = aim point (target origin + aimz) + dist along target yaw + yawoff, + height,
 *        pulled in front of walls; track 1 re-aims every 0.05 s until vexcam_stop
 *   vexcam_stop                                    stop tracking
 *   vexcam_freeze <target> <0|1>                   FL_FROZEN on/off (pose a bot for a shot)
 *   vexcam_status                                  print cameras, boss + its overhead entities
 *
 * Spectators are switched to free roaming (iuser1 3); a live camera client becomes an
 * invisible, non-solid, god-mode noclip ghost.
 */
#include <amxmodx>
#include <fakemeta>

#define OVH_MAGIC 0x56584F48
#define OBS_ROAMING 3
#define TASK_TRACK 7301

new g_szTrack[64];
new Float:g_fTrack[5];

public plugin_init()
{
    register_plugin("vexcam (devtools render camera)", "1.0", "vexmira devtools");
    register_srvcmd("vexcam_pos", "cmd_pos");
    register_srvcmd("vexcam_look", "cmd_look");
    register_srvcmd("vexcam_stop", "cmd_stop");
    register_srvcmd("vexcam_freeze", "cmd_freeze");
    register_srvcmd("vexcam_status", "cmd_status");
}

bool:IsCam(id)
{
    return is_user_connected(id) && !is_user_bot(id) && !is_user_hltv(id);
}

PlaceCam(id, const Float:o[3], const Float:a[3])
{
    if (is_user_alive(id))
    {
        set_pev(id, pev_movetype, MOVETYPE_NOCLIP);
        set_pev(id, pev_solid, SOLID_NOT);
        set_pev(id, pev_takedamage, DAMAGE_NO);
        set_pev(id, pev_effects, pev(id, pev_effects) | EF_NODRAW);
    }
    else if (pev(id, pev_iuser1) != OBS_ROAMING)
    {
        set_pev(id, pev_iuser1, OBS_ROAMING);
        set_pev(id, pev_iuser2, 0);
        set_pev(id, pev_iuser3, 0);
    }
    engfunc(EngFunc_SetOrigin, id, o);
    set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
    new Float:ang[3];
    ang[0] = a[0];
    ang[1] = a[1];
    ang[2] = 0.0;
    set_pev(id, pev_angles, ang);
    set_pev(id, pev_v_angle, ang);
    set_pev(id, pev_fixangle, 1);
}

PlaceAll(const Float:o[3], const Float:a[3])
{
    new n;
    for (new id = 1; id <= get_maxplayers(); id++)
    {
        if (!IsCam(id))
            continue;
        PlaceCam(id, o, a);
        n++;
    }
    return n;
}

public cmd_pos()
{
    if (read_argc() < 6)
    {
        server_print("[vexcam] usage: vexcam_pos <x> <y> <z> <pitch> <yaw>");
        return PLUGIN_HANDLED;
    }
    new Float:o[3], Float:a[3];
    for (new i = 0; i < 3; i++)
        o[i] = read_argv_float(i + 1);
    a[0] = read_argv_float(4);
    a[1] = read_argv_float(5);
    remove_task(TASK_TRACK);
    new n = PlaceAll(o, a);
    server_print("[vexcam] pos %.1f %.1f %.1f ang %.1f %.1f -> %d camera client(s)", o[0], o[1], o[2], a[0], a[1], n);
    return PLUGIN_HANDLED;
}

// Overhead entity of type "bossbar" -> its owner (the boss player); 0 if none
FindBoss(&bar = 0)
{
    new model[64];
    for (new e = get_maxplayers() + 1; e < global_get(glb_maxEntities); e++)
    {
        if (!pev_valid(e) || pev(e, pev_iuser2) != OVH_MAGIC)
            continue;
        pev(e, pev_model, model, charsmax(model));
        if (containi(model, "bossbar") < 0)
            continue;
        new owner = pev(e, pev_iuser1);
        if (owner >= 1 && owner <= get_maxplayers() && is_user_alive(owner))
        {
            bar = e;
            return owner;
        }
    }
    return 0;
}

ResolveTarget(const arg[])
{
    if (equali(arg, "boss"))
        return FindBoss();
    if (arg[0] == '#')
    {
        new uid = str_to_num(arg[1]);
        for (new id = 1; id <= get_maxplayers(); id++)
            if (is_user_connected(id) && get_user_userid(id) == uid)
                return id;
        return 0;
    }
    if (equali(arg, "ent:", 4))
    {
        new e = str_to_num(arg[4]);
        return pev_valid(e) ? e : 0;
    }
    new name[32];
    for (new id = 1; id <= get_maxplayers(); id++)
    {
        if (!is_user_connected(id))
            continue;
        get_user_name(id, name, charsmax(name));
        if (containi(name, arg) >= 0)
            return id;
    }
    return 0;
}

bool:LookAt(const target[], const Float:p[5], bool:quiet)
{
    new t = ResolveTarget(target);
    if (!t)
    {
        if (!quiet)
            server_print("[vexcam] look: target '%s' not found", target);
        return false;
    }
    new Float:dist = p[0], Float:height = p[1], Float:yawoff = p[2], Float:aimz = p[3];
    new Float:to[3], Float:aim[3], Float:va[3], Float:cam[3];
    pev(t, pev_origin, to);
    pev(t, t <= get_maxplayers() ? pev_v_angle : pev_angles, va);
    aim[0] = to[0];
    aim[1] = to[1];
    aim[2] = to[2] + aimz;
    new Float:yaw = (va[1] + yawoff) * M_PI / 180.0;
    cam[0] = aim[0] + floatcos(yaw) * dist;
    cam[1] = aim[1] + floatsin(yaw) * dist;
    cam[2] = aim[2] + height;
    // keep the camera in front of walls: trace aim -> cam, stop 16 units short of a hit
    new tr = create_tr2();
    engfunc(EngFunc_TraceLine, aim, cam, IGNORE_MONSTERS, t, tr);
    new Float:frac;
    get_tr2(tr, TR_flFraction, frac);
    free_tr2(tr);
    new Float:len = floatsqroot(dist * dist + height * height);
    if (frac < 1.0 && len > 1.0)
    {
        new Float:k = floatmax(0.05, frac - 16.0 / len);
        for (new i = 0; i < 3; i++)
            cam[i] = aim[i] + (cam[i] - aim[i]) * k;
    }
    new Float:d[3], Float:ang[3];
    for (new i = 0; i < 3; i++)
        d[i] = aim[i] - cam[i];
    new Float:hyp = floatsqroot(d[0] * d[0] + d[1] * d[1]);
    ang[0] = floatatan2(-d[2], hyp, degrees);
    ang[1] = floatatan2(d[1], d[0], degrees);
    new n = PlaceAll(cam, ang);
    if (!quiet)
        server_print("[vexcam] look %s (ent %d) at %.1f %.1f %.1f from %.1f %.1f %.1f ang %.1f %.1f trace %.2f -> %d camera client(s)",
            target, t, aim[0], aim[1], aim[2], cam[0], cam[1], cam[2], ang[0], ang[1], frac, n);
    return true;
}

public cmd_look()
{
    if (read_argc() < 2)
    {
        server_print("[vexcam] usage: vexcam_look <boss|#userid|ent:N|name> [dist 220] [height 40] [yawoff 0] [aimz 40] [track 0]");
        return PLUGIN_HANDLED;
    }
    new target[64];
    read_argv(1, target, charsmax(target));
    new Float:p[5] = {220.0, 40.0, 0.0, 40.0, 0.0};
    for (new i = 0; i < 5; i++)
        if (read_argc() > i + 2)
            p[i] = read_argv_float(i + 2);
    remove_task(TASK_TRACK);
    if (LookAt(target, p, false) && p[4] > 0.0)
    {
        copy(g_szTrack, charsmax(g_szTrack), target);
        g_fTrack = p;
        set_task(0.05, "task_track", TASK_TRACK, _, _, "b");
    }
    return PLUGIN_HANDLED;
}

public task_track()
{
    if (!LookAt(g_szTrack, g_fTrack, true))
        remove_task(TASK_TRACK);
}

public cmd_stop()
{
    remove_task(TASK_TRACK);
    server_print("[vexcam] tracking stopped");
    return PLUGIN_HANDLED;
}

public cmd_freeze()
{
    new target[64];
    read_argv(1, target, charsmax(target));
    new t = ResolveTarget(target);
    if (!t)
    {
        server_print("[vexcam] freeze: target '%s' not found", target);
        return PLUGIN_HANDLED;
    }
    new on = read_argv_int(2);
    new fl = pev(t, pev_flags);
    set_pev(t, pev_flags, on ? (fl | FL_FROZEN) : (fl & ~FL_FROZEN));
    set_pev(t, pev_velocity, Float:{0.0, 0.0, 0.0});
    server_print("[vexcam] freeze %s (ent %d) = %d", target, t, on);
    return PLUGIN_HANDLED;
}

public cmd_status()
{
    new name[32], Float:o[3], Float:a[3];
    for (new id = 1; id <= get_maxplayers(); id++)
    {
        if (!IsCam(id))
            continue;
        get_user_name(id, name, charsmax(name));
        pev(id, pev_origin, o);
        pev(id, pev_v_angle, a);
        server_print("[vexcam] cam %d '%s' team %d alive %d iuser1 %d origin %.1f %.1f %.1f ang %.1f %.1f",
            id, name, get_user_team(id), is_user_alive(id), pev(id, pev_iuser1), o[0], o[1], o[2], a[0], a[1]);
    }
    new bar;
    new boss = FindBoss(bar);
    if (!boss)
    {
        server_print("[vexcam] boss none");
        return PLUGIN_HANDLED;
    }
    new model[64], Float:hp, Float:mins[3], Float:maxs[3];
    get_user_name(boss, name, charsmax(name));
    pev(boss, pev_origin, o);
    pev(boss, pev_health, hp);
    pev(boss, pev_mins, mins);
    pev(boss, pev_maxs, maxs);
    pev(boss, pev_model, model, charsmax(model));
    server_print("[vexcam] boss %d '%s' hp %.0f origin %.1f %.1f %.1f hull z %.1f..%.1f model %s",
        boss, name, hp, o[0], o[1], o[2], mins[2], maxs[2], model);
    for (new e = get_maxplayers() + 1; e < global_get(glb_maxEntities); e++)
    {
        if (!pev_valid(e) || pev(e, pev_iuser2) != OVH_MAGIC || pev(e, pev_iuser1) != boss)
            continue;
        new Float:eo[3], Float:fr, Float:sc;
        pev(e, pev_origin, eo);
        pev(e, pev_frame, fr);
        pev(e, pev_scale, sc);
        pev(e, pev_model, model, charsmax(model));
        server_print("[vexcam] overhead ent %d %s frame %.0f scale %.2f origin %.1f %.1f %.1f (+%.1f above boss origin) nodraw %d",
            e, model, fr, sc, eo[0], eo[1], eo[2], eo[2] - o[2], (pev(e, pev_effects) & EF_NODRAW) ? 1 : 0);
    }
    return PLUGIN_HANDLED;
}
