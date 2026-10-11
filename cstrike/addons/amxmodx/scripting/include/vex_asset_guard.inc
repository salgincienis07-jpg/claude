#if defined _vex_asset_guard_included
    #endinput
#endif
#define _vex_asset_guard_included

// v4.1 asset guard (per plugin, never global).
//
// v4.0.2 checked ~300 files of the WHOLE package in every plugin and called set_fail_state() when a
// single one was missing (stock Half-Life files such as sound/fvox/*.wav included, which live in
// valve/ and were not even found because file_exists() ran without the Valve file system). One
// missing file disabled the main plugin and all 12 item plugins at once -> every purchase said
// "you can't buy this right now".
//
// Now every plugin precaches through these helpers:
//   VexPcModel()   - model / sprite. Missing or damaged (bad header) -> skipped + logged.
//                    A missing .mdl marks THIS plugin incomplete (VexAssetInit() disables only it,
//                    with the file name in the reason: amxx plugins / vex_diagnose show it).
//                    A missing .spr (HUD/effect sprite) is not fatal: the effect is just not drawn.
//   VexPcSound()   - sound (path without "sound/"). Missing -> skipped + logged (never fatal).
//   VexPcGeneric() - download-only file. Missing -> skipped + logged (never fatal).
// All checks use the Valve file system (cstrike, cstrike_downloads, valve, *.pak).

new g_szVexMissing[128], g_iVexMissing;
new Trie:g_tVexPc = Invalid_Trie;

stock bool:VexAssetGuard() { return true; }   // kept for older call sites (no global check any more)

stock bool:VexAssetExists(const path[])
{
    return file_exists(path, true) ? true : false;
}

stock bool:VexAssetValid(const path[])
{
    if (!VexAssetExists(path)) return false;
    new expected;
    if (containi(path, ".mdl") != -1) expected = 0x54534449;      // IDST
    else if (containi(path, ".spr") != -1) expected = 0x50534449; // IDSP
    else if (containi(path, ".wav") != -1) expected = 0x46464952; // RIFF
    else return true;
    new fp = fopen(path, "rb", true);
    if (!fp) return true;   // exists but the FS refused to open it here: let the engine decide
    new magic;
    fread(fp, magic, BLOCK_INT);
    fclose(fp);
    return magic == expected;
}

stock bool:VexPrecached(const path[])
{
    return g_tVexPc != Invalid_Trie && TrieKeyExists(g_tVexPc, path);
}

stock VexPcMark(const path[])
{
    if (g_tVexPc == Invalid_Trie) g_tVexPc = TrieCreate();
    TrieSetCell(g_tVexPc, path, 1);
}

stock VexPcModel(const path[])
{
    if (!path[0]) return 0;
    if (!VexAssetValid(path))
    {
        new bool:fatal = containi(path, ".mdl") != -1;
        log_amx("[VexAsset] %s: %s%s", VexAssetExists(path) ? "DAMAGED (bad header, re-upload in binary mode)" : "MISSING",
            path, fatal ? "" : " (effect only, not fatal)");
        if (fatal)
        {
            if (!g_iVexMissing) copy(g_szVexMissing, charsmax(g_szVexMissing), path);
            g_iVexMissing++;
        }
        return 0;
    }
    VexPcMark(path);
    return precache_model(path);
}

stock VexPcSound(const path[])
{
    if (!path[0]) return 0;
    new full[160];
    formatex(full, charsmax(full), "sound/%s", path);
    if (!VexAssetValid(full))
    {
        log_amx("[VexAsset] MISSING sound (skipped, not fatal): %s", full);
        return 0;
    }
    return precache_sound(path);
}

stock VexPcGeneric(const path[])
{
    if (!path[0]) return 0;
    if (!VexAssetExists(path))
    {
        log_amx("[VexAsset] MISSING download file (skipped, not fatal): %s", path);
        return 0;
    }
    VexPcMark(path);
    return precache_generic(path);
}

// Call FIRST in plugin_init(): a plugin whose own models are missing disables itself (only itself),
// before it registers hooks that would set an unprecached model (= server crash).
stock VexAssetInit()
{
    if (!g_iVexMissing) return;
    new error[192];
    formatex(error, charsmax(error), "%d model(s) missing or damaged, first: %s - upload it (binary) to cstrike/", g_iVexMissing, g_szVexMissing);
    set_fail_state(error);
}
