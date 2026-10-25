/* vx_loadtest - TEST SERVER ONLY (not shipped). Measures what 32 players using the tablet at the same
   moment cost the game server.
   vxlt_wave <act> [a] [b]  : runs the tablet action for EVERY connected player (bots too) in one server
                              frame through the core's own action path (vex_tablet_selftest), and logs how
                              many milliseconds the whole wave took.
   vxlt_replies <n>         : queues n tablet replies at once in vex_tab02 (same as n players asking for
                              market / trade data in the same second) and logs when the queue is empty.
   Every second it logs the worst server frame gap seen (ms) so lag spikes show up. */
#include <amxmodx>
#include <fakemeta>

new g_iLastTick, g_iWorst, g_iFrames, g_iWaveN;

public plugin_init()
{
	register_plugin("vx_loadtest", "1.0", "vexmira devtools");
	register_srvcmd("vxlt_wave", "cmd_Wave");
	register_srvcmd("vxlt_replies", "cmd_Replies");
	register_forward(FM_StartFrame, "fw_Frame", 1);
	set_task(1.0, "task_Report", 0, _, _, "b");
}

public fw_Frame()
{
	new t = tickcount();
	if (g_iLastTick)
	{
		new d = t - g_iLastTick;
		if (d > g_iWorst) g_iWorst = d;
	}
	g_iLastTick = t;
	g_iFrames++;
}

public task_Report()
{
	log_amx("[vxlt] frames/s=%d worst_frame_gap_ms=%d", g_iFrames, g_iWorst);
	g_iFrames = 0; g_iWorst = 0;
}

public cmd_Wave()
{
	new act[24], a[24], b[24];
	read_argv(1, act, charsmax(act)); read_argv(2, a, charsmax(a)); read_argv(3, b, charsmax(b));
	new t0 = tickcount(), n;
	for (new p = 1; p <= MaxClients; p++)
	{
		if (!is_user_connected(p)) continue;
		server_cmd("vex_tablet_selftest %d %s %s %s x home", get_user_userid(p), act, a[0] ? a : "x", b[0] ? b : "x");
		n++;
	}
	server_exec();
	g_iWaveN++;
	log_amx("[vxlt] wave %d act=%s players=%d took_ms=%d", g_iWaveN, act, n, tickcount() - t0);
	return PLUGIN_HANDLED;
}

public cmd_Replies()
{
	new s[8]; read_argv(1, s, charsmax(s));
	new n = clamp(str_to_num(s), 1, 32), t0 = tickcount(), body[1400];
	for (new i = 0; i < 1300; i++) body[i] = 'a' + (i % 26);
	body[1300] = 0;
	for (new k = 1; k <= n; k++)
	{
		new topic[48]; formatex(topic, charsmax(topic), "vxloadtest_%d", k);
		if (callfunc_begin("vxc_reply", "vex_tab02.amxx") != 1) { log_amx("[vxlt] vex_tab02 not found"); return PLUGIN_HANDLED; }
		callfunc_push_int(k);
		callfunc_push_str(topic, false);
		callfunc_push_str(body, false);
		callfunc_end();
	}
	log_amx("[vxlt] queued %d replies in %d ms (send progress: vex_tab02)", n, tickcount() - t0);
	return PLUGIN_HANDLED;
}
