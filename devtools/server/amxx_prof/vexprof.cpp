// vexprof.cpp - TEST-SERVER-ONLY instrumentation for AMX Mod X 1.10 (never shipped to players).
// Built into a separate amxmodx_mm_i386.so by devtools/server/amxx_prof/build.sh; see README.md there.
//
//  * Plugin profiler: with  amx_perflog_ms < 0  every public call made by the engine / modules / tasks
//    (amx_ExecPerf: forwards, ReAPI / Ham / Fakemeta hooks, set_task, menus ...) is timed and
//    aggregated per (plugin, public): calls, total, max. The plugin keeps running JIT-compiled
//    (no "debug" flag needed), so the numbers are the real production cost incl. natives.
//  * Network messages (env VEX_MSGSTATS=1 at server start): MessageBegin/Write*/MessageEnd are
//    wrapped for AMXX core and every metamod plugin / AMXX module loaded after it (fakemeta,
//    reapi, hamsandwich ...): count + payload bytes per (message type, TE sub-type, destination).
//  * Entity census: used edicts per classname.
//  * Server command  amx_profdump [reset]  prints everything as "[vexprof] ..." console lines.
#include <chrono>
#include <string.h>
#include "amxmodx.h"
#include "CPlugin.h"

using vex_clock = std::chrono::steady_clock;

struct VexProfSlot
{
	AMX *amx;
	int index;
	unsigned long long count, total_ns, max_ns;
	char name[sNAMEMAX + 1];
	char plugin[64];
};

#define VEXPROF_SLOTS 8192
static VexProfSlot g_VexProf[VEXPROF_SLOTS];
static vex_clock::time_point g_VexProfStart = vex_clock::now();

int vexprof_Exec(AMX *amx, cell *retval, int index)
{
	vex_clock::time_point t1 = vex_clock::now();
	int err = amx_Exec(amx, retval, index);
	unsigned long long ns = (unsigned long long)std::chrono::duration_cast<std::chrono::nanoseconds>(vex_clock::now() - t1).count();
	unsigned int h = ((unsigned int)((size_t)amx >> 4) * 2654435761u + (unsigned int)index) & (VEXPROF_SLOTS - 1);
	for (int i = 0; i < VEXPROF_SLOTS; i++)
	{
		VexProfSlot &s = g_VexProf[(h + i) & (VEXPROF_SLOTS - 1)];
		if (s.amx == amx && s.index == index)
		{
			s.count++;
			s.total_ns += ns;
			if (ns > s.max_ns)
				s.max_ns = ns;
			return err;
		}
		if (!s.amx)
		{
			s.amx = amx;
			s.index = index;
			s.count = 1;
			s.total_ns = ns;
			s.max_ns = ns;
			s.name[0] = '\0';
			if (index >= 0)
				amx_GetPublic(amx, index, s.name);
			if (!s.name[0])
				snprintf(s.name, sizeof(s.name), "id%d", index);
			CPluginMngr::CPlugin *pl = g_plugins.findPluginFast(amx);
			snprintf(s.plugin, sizeof(s.plugin), "%s", (pl && pl->getName()) ? pl->getName() : "?");
			return err;
		}
	}
	return err;
}

// ------------------------------------------------------------------ network messages
static enginefuncs_t g_VexEng;            // the real functions
static bool g_VexMsgOn = false;
struct VexMsgStat { unsigned long long count, bytes; };
static VexMsgStat g_VexMsgT[256][10];      // [msg type][dest]          (everything but SVC_TEMPENTITY)
static VexMsgStat g_VexMsgTE[256][10];     // [TE sub-type][dest]       (SVC_TEMPENTITY = 23)
static int g_VexType = -1, g_VexDest = 0, g_VexSub = -1, g_VexBytes = 0;
static bool g_VexIn = false;

static void vex_MessageBegin(int dest, int type, const float *o, edict_t *ed)
{
	g_VexIn = true;
	g_VexType = type & 255;
	g_VexDest = (dest >= 0 && dest < 10) ? dest : 9;
	g_VexSub = -1;
	g_VexBytes = 0;
	g_VexEng.pfnMessageBegin(dest, type, o, ed);
}
static void vex_MessageEnd(void)
{
	if (g_VexIn)
	{
		VexMsgStat &s = (g_VexType == 23) ? g_VexMsgTE[g_VexSub < 0 ? 255 : g_VexSub][g_VexDest] : g_VexMsgT[g_VexType][g_VexDest];
		s.count++;
		s.bytes += g_VexBytes;
		g_VexIn = false;
	}
	g_VexEng.pfnMessageEnd();
}
static void vex_WriteByte(int v)
{
	if (g_VexIn)
	{
		if (g_VexType == 23 && g_VexSub < 0)
			g_VexSub = v & 255;
		g_VexBytes += 1;
	}
	g_VexEng.pfnWriteByte(v);
}
static void vex_WriteChar(int v) { if (g_VexIn) g_VexBytes += 1; g_VexEng.pfnWriteChar(v); }
static void vex_WriteShort(int v) { if (g_VexIn) g_VexBytes += 2; g_VexEng.pfnWriteShort(v); }
static void vex_WriteLong(int v) { if (g_VexIn) g_VexBytes += 4; g_VexEng.pfnWriteLong(v); }
static void vex_WriteAngle(float v) { if (g_VexIn) g_VexBytes += 1; g_VexEng.pfnWriteAngle(v); }
static void vex_WriteCoord(float v) { if (g_VexIn) g_VexBytes += 2; g_VexEng.pfnWriteCoord(v); }
static void vex_WriteString(const char *v) { if (g_VexIn) g_VexBytes += (v ? (int)strlen(v) : 0) + 1; g_VexEng.pfnWriteString(v); }
static void vex_WriteEntity(int v) { if (g_VexIn) g_VexBytes += 2; g_VexEng.pfnWriteEntity(v); }

static void vex_Wrap(enginefuncs_t *t)
{
	t->pfnMessageBegin = vex_MessageBegin;
	t->pfnMessageEnd = vex_MessageEnd;
	t->pfnWriteByte = vex_WriteByte;
	t->pfnWriteChar = vex_WriteChar;
	t->pfnWriteShort = vex_WriteShort;
	t->pfnWriteLong = vex_WriteLong;
	t->pfnWriteAngle = vex_WriteAngle;
	t->pfnWriteCoord = vex_WriteCoord;
	t->pfnWriteString = vex_WriteString;
	t->pfnWriteEntity = vex_WriteEntity;
}

// called from GiveFnptrsToDll right after AMXX copied the table
void vexprof_InstallMsgHooks(enginefuncs_t *fromEngine, enginefuncs_t *amxxCopy)
{
	const char *e = getenv("VEX_MSGSTATS");
	if (!e || !e[0] || e[0] == '0')
		return;
	memcpy(&g_VexEng, fromEngine, sizeof(enginefuncs_t));
	vex_Wrap(amxxCopy);       // AMXX core natives (message_begin, client_print*, hud, dhud ...)
	vex_Wrap(fromEngine);     // shared metamod plugin table: modules attached later (fakemeta engfunc ...)
	g_VexMsgOn = true;
}

// ------------------------------------------------------------------ dump
struct VexRow { int i; unsigned long long key; };

static int vex_cmp_prof(const void *a, const void *b)
{
	const VexProfSlot *x = &g_VexProf[*(const int *)a], *y = &g_VexProf[*(const int *)b];
	return (x->total_ns < y->total_ns) ? 1 : (x->total_ns > y->total_ns ? -1 : 0);
}

void vexprof_Dump(bool reset)
{
	double sec = std::chrono::duration_cast<std::chrono::microseconds>(vex_clock::now() - g_VexProfStart).count() / 1e6;
	if (sec < 0.001)
		sec = 0.001;
	static int idx[VEXPROF_SLOTS];
	int n = 0;
	unsigned long long all_ns = 0;
	for (int i = 0; i < VEXPROF_SLOTS; i++)
	{
		if (g_VexProf[i].amx)
		{
			idx[n++] = i;
			all_ns += g_VexProf[i].total_ns;
		}
	}
	qsort(idx, n, sizeof(int), vex_cmp_prof);
	print_srvconsole("[vexprof] window %.1f s, game time %.1f, publics %d, plugin time %.1f ms (%.3f ms/s)\n",
		sec, gpGlobals ? gpGlobals->time : 0.0f, n, all_ns / 1e6, all_ns / 1e6 / sec);
	for (int k = 0; k < n; k++)
	{
		VexProfSlot &s = g_VexProf[idx[k]];
		print_srvconsole("[vexprof] fn %s %s calls=%llu total_ms=%.3f avg_us=%.2f max_us=%.1f\n",
			s.plugin, s.name, s.count, s.total_ns / 1e6, s.total_ns / 1e3 / (double)s.count, s.max_ns / 1e3);
	}
	if (g_VexMsgOn)
	{
		for (int t = 0; t < 256; t++)
			for (int d = 0; d < 10; d++)
			{
				if (g_VexMsgT[t][d].count)
				{
					const char *nm = (t >= 64) ? GET_USER_MSG_NAME(PLID, t, NULL) : NULL;
					print_srvconsole("[vexprof] msg type=%d name=%s dest=%d count=%llu bytes=%llu\n",
						t, nm ? nm : "-", d, g_VexMsgT[t][d].count, g_VexMsgT[t][d].bytes);
				}
				if (g_VexMsgTE[t][d].count)
					print_srvconsole("[vexprof] te sub=%d dest=%d count=%llu bytes=%llu\n",
						t, d, g_VexMsgTE[t][d].count, g_VexMsgTE[t][d].bytes);
			}
	}
	// entity census
	if (gpGlobals)
	{
		struct { const char *cls; int n; } tab[256];
		int nt = 0, used = 0;
		for (int i = 0; i < gpGlobals->maxEntities; i++)
		{
			edict_t *ed = INDEXENT(i);
			if (!ed || ed->free)
				continue;
			used++;
			const char *c = ed->v.classname ? STRING(ed->v.classname) : "(none)";
			int j;
			for (j = 0; j < nt; j++)
				if (!strcmp(tab[j].cls, c))
					break;
			if (j == nt && nt < 256)
			{
				tab[nt].cls = c;
				tab[nt].n = 0;
				nt++;
			}
			if (j < nt)
				tab[j].n++;
		}
		print_srvconsole("[vexprof] edicts used=%d max=%d\n", used, gpGlobals->maxEntities);
		for (int j = 0; j < nt; j++)
			print_srvconsole("[vexprof] ent %s %d\n", tab[j].cls, tab[j].n);
	}
	print_srvconsole("[vexprof] end\n");
	if (reset)
	{
		memset(g_VexProf, 0, sizeof(g_VexProf));
		memset(g_VexMsgT, 0, sizeof(g_VexMsgT));
		memset(g_VexMsgTE, 0, sizeof(g_VexMsgTE));
		g_VexProfStart = vex_clock::now();
	}
}

void vexprof_Cmd(void)
{
	const char *a = CMD_ARGV(1);
	vexprof_Dump(a && !strcmp(a, "reset"));
}
