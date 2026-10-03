// Minimal offline libsteam_api.so replacement for the headless Vexmira TEST server.
//
// The real libsteam_api.so needs the Steam client runtime (steamclient.so), which cannot be
// downloaded here (Steam CDN blocked), so ReHLDS aborts with "Unable to initialize Steam".
// This stub implements only what ReHLDS 3.x calls on a dedicated LAN server (-insecure, sv_lan 1):
// SteamGameServer_Init succeeds, the ISteamGameServer object accepts every setter, never sends
// packets, hands out unique anonymous SteamIDs for fake clients (bots), and reports
// SteamServersConnected once. Client-side interfaces return NULL.
//
// Built against ReHLDS' own Steam SDK headers (rehlds/public/steam) so the vtable layout matches.
// NOT for production servers - test harness only.
#include <string.h>
#include <stdio.h>
#include <vector>
// ReHLDS' copy of the SDK expects these from its archtypes.h
typedef signed char int8;
typedef short int16;
typedef unsigned short uint16;
typedef int int32;
typedef unsigned int uint32;
typedef long long int64;
typedef unsigned long long uint64;
#include "steam_gameserver.h"
#include "isteamapps.h"

#define EXPORT extern "C" __attribute__((visibility("default")))

static std::vector<CCallbackBase *> g_callbacks;
static bool g_connectedSent = false;
static uint32 g_nextAnon = 1;

class StubGameServer : public ISteamGameServer
{
public:
	bool InitGameServer(uint32, uint16, uint16, uint32, AppId_t, const char *) { return true; }
	void SetProduct(const char *) {}
	void SetGameDescription(const char *) {}
	void SetModDir(const char *) {}
	void SetDedicatedServer(bool) {}
	void LogOn(const char *, const char *) {}
	void LogOnAnonymous() {}
	void LogOff() {}
	bool BLoggedOn() { return true; }
	bool BSecure() { return false; }
	CSteamID GetSteamID() { return CSteamID(1u, k_EUniversePublic, k_EAccountTypeAnonGameServer); }
	bool WasRestartRequested() { return false; }
	void SetMaxPlayerCount(int) {}
	void SetBotPlayerCount(int) {}
	void SetServerName(const char *) {}
	void SetMapName(const char *) {}
	void SetPasswordProtected(bool) {}
	void SetSpectatorPort(uint16) {}
	void SetSpectatorServerName(const char *) {}
	void ClearAllKeyValues() {}
	void SetKeyValue(const char *, const char *) {}
	void SetGameTags(const char *) {}
	void SetGameData(const char *) {}
	void SetRegion(const char *) {}
	bool SendUserConnectAndAuthenticate(uint32, const void *, uint32, CSteamID *pSteamIDUser)
	{
		if (pSteamIDUser)
			*pSteamIDUser = CSteamID(g_nextAnon++, k_EUniversePublic, k_EAccountTypeAnonUser);
		return true;
	}
	CSteamID CreateUnauthenticatedUserConnection() { return CSteamID(g_nextAnon++, k_EUniversePublic, k_EAccountTypeAnonUser); }
	void SendUserDisconnect(CSteamID) {}
	bool BUpdateUserData(CSteamID, const char *, uint32) { return true; }
	HAuthTicket GetAuthSessionTicket(void *, int, uint32 *pcb) { if (pcb) *pcb = 0; return 0; }
	EBeginAuthSessionResult BeginAuthSession(const void *, int, CSteamID) { return k_EBeginAuthSessionResultOK; }
	void EndAuthSession(CSteamID) {}
	void CancelAuthTicket(HAuthTicket) {}
	EUserHasLicenseForAppResult UserHasLicenseForApp(CSteamID, AppId_t) { return k_EUserHasLicenseResultHasLicense; }
	bool RequestUserGroupStatus(CSteamID, CSteamID) { return false; }
	void GetGameplayStats() {}
	SteamAPICall_t GetServerReputation() { return 0; }
	uint32 GetPublicIP() { return 0x7F000001; }
	bool HandleIncomingPacket(const void *, int, uint32, uint16) { return true; }
	int GetNextOutgoingPacket(void *, int, uint32 *, uint16 *) { return 0; }
	void EnableHeartbeats(bool) {}
	void SetHeartbeatInterval(int) {}
	void ForceHeartbeat() {}
	SteamAPICall_t AssociateWithClan(CSteamID) { return 0; }
	SteamAPICall_t ComputeNewPlayerCompatibility(CSteamID) { return 0; }
};

class StubApps : public ISteamApps
{
public:
	bool BIsSubscribed() { return true; }
	bool BIsLowViolence() { return false; }
	bool BIsCybercafe() { return false; }
	bool BIsVACBanned() { return false; }
	const char *GetCurrentGameLanguage() { return "english"; }
	const char *GetAvailableGameLanguages() { return "english"; }
	bool BIsSubscribedApp(AppId_t) { return true; }
	bool BIsDlcInstalled(AppId_t) { return false; }
	uint32 GetEarliestPurchaseUnixTime(AppId_t) { return 0; }
	bool BIsSubscribedFromFreeWeekend() { return false; }
	int GetDLCCount() { return 0; }
	bool BGetDLCDataByIndex(int, AppId_t *, bool *, char *, int) { return false; }
	void InstallDLC(AppId_t) {}
	void UninstallDLC(AppId_t) {}
	void RequestAppProofOfPurchaseKey(AppId_t) {}
	bool GetCurrentBetaName(char *n, int c) { if (n && c) n[0] = 0; return false; }
	bool MarkContentCorrupt(bool) { return false; }
	uint32 GetInstalledDepots(DepotId_t *, uint32) { return 0; }
	uint32 GetAppInstallDir(AppId_t, char *f, uint32 c) { if (f && c) f[0] = 0; return 0; }
	SteamAPICall_t RegisterActivationCode(const char *) { return 0; }
};

static StubGameServer g_gs;
static StubApps g_apps;

// ---- game server API
EXPORT bool SteamGameServer_Init(uint32, uint16, uint16, uint16, EServerMode, const char *) { return true; }
EXPORT bool SteamGameServer_InitSafe(uint32, uint16, uint16, uint16, EServerMode, const char *) { return true; }
EXPORT ISteamGameServer *SteamGameServer() { return &g_gs; }
EXPORT ISteamUtils *SteamGameServerUtils() { return NULL; }
EXPORT ISteamNetworking *SteamGameServerNetworking() { return NULL; }
EXPORT ISteamGameServerStats *SteamGameServerStats() { return NULL; }
EXPORT ISteamHTTP *SteamGameServerHTTP() { return NULL; }
EXPORT ISteamApps *SteamGameServerApps() { return &g_apps; }
EXPORT void SteamGameServer_Shutdown() {}
EXPORT bool SteamGameServer_BSecure() { return false; }
EXPORT uint64 SteamGameServer_GetSteamID() { return g_gs.GetSteamID().ConvertToUint64(); }
EXPORT HSteamPipe SteamGameServer_GetHSteamPipe() { return 1; }
EXPORT HSteamUser SteamGameServer_GetHSteamUser() { return 1; }
EXPORT void SteamGameServer_RunCallbacks()
{
	if (g_connectedSent)
		return;
	g_connectedSent = true;
	SteamServersConnected_t data;
	for (size_t i = 0; i < g_callbacks.size(); i++)
	{
		CCallbackBase *cb = g_callbacks[i];
		if (cb && cb->GetICallback() == SteamServersConnected_t::k_iCallback)
			cb->Run(&data);
	}
}

// ---- client API (dedicated server uses only a few of these)
EXPORT bool SteamAPI_Init() { return true; }
EXPORT bool SteamAPI_InitSafe() { return true; }
EXPORT void SteamAPI_Shutdown() {}
EXPORT bool SteamAPI_IsSteamRunning() { return false; }
EXPORT bool SteamAPI_RestartAppIfNecessary(uint32) { return false; }
EXPORT void SteamAPI_RunCallbacks() {}
EXPORT void SteamAPI_RegisterCallback(CCallbackBase *pCallback, int iCallback)
{
	(void)iCallback;
	g_callbacks.push_back(pCallback);
}
EXPORT void SteamAPI_UnregisterCallback(CCallbackBase *pCallback)
{
	for (size_t i = 0; i < g_callbacks.size(); i++)
		if (g_callbacks[i] == pCallback)
			g_callbacks[i] = NULL;
}
EXPORT void SteamAPI_RegisterCallResult(CCallbackBase *, SteamAPICall_t) {}
EXPORT void SteamAPI_UnregisterCallResult(CCallbackBase *, SteamAPICall_t) {}
EXPORT void SteamAPI_SetBreakpadAppID(uint32) {}
EXPORT void SteamAPI_UseBreakpadCrashHandler(char const *, char const *, char const *, bool, void *, void *) {}
EXPORT void SteamAPI_WriteMiniDump(uint32, void *, uint32) {}
EXPORT void SteamAPI_SetMiniDumpComment(const char *) {}
EXPORT ISteamClient *SteamClient() { return NULL; }
EXPORT ISteamUser *SteamUser() { return NULL; }
EXPORT ISteamFriends *SteamFriends() { return NULL; }
EXPORT ISteamUtils *SteamUtils() { return NULL; }
EXPORT ISteamMatchmaking *SteamMatchmaking() { return NULL; }
EXPORT ISteamUserStats *SteamUserStats() { return NULL; }
EXPORT ISteamApps *SteamApps() { return &g_apps; }
EXPORT ISteamNetworking *SteamNetworking() { return NULL; }
EXPORT ISteamMatchmakingServers *SteamMatchmakingServers() { return NULL; }
EXPORT ISteamRemoteStorage *SteamRemoteStorage() { return NULL; }
EXPORT ISteamScreenshots *SteamScreenshots() { return NULL; }
EXPORT ISteamHTTP *SteamHTTP() { return NULL; }
EXPORT ISteamUnifiedMessages *SteamUnifiedMessages() { return NULL; }
EXPORT HSteamPipe SteamAPI_GetHSteamPipe() { return 1; }
EXPORT HSteamUser SteamAPI_GetHSteamUser() { return 1; }
EXPORT HSteamPipe GetHSteamPipe() { return 1; }
EXPORT HSteamUser GetHSteamUser() { return 1; }
EXPORT HSteamUser Steam_GetHSteamUserCurrent() { return 1; }
EXPORT const char *SteamAPI_GetSteamInstallPath() { return ""; }
EXPORT void Steam_RunCallbacks(HSteamPipe, bool) {}
EXPORT void Steam_RegisterInterfaceFuncs(void *) {}
