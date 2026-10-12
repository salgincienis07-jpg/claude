// 4.3 menu style (one place for every menu):
//   title     : "\yVEXMIRA  \w<TITLE>" + \d info line with \y values
//   item      : name in \w, short description in \d, tags right-aligned (\R):
//               price \y ([35 AP] / [100 VC]), owned / equipped / info \d,
//               \r ONLY for warnings (not enough AP/VC, locked), selected marker "\y*"
//   separators: \d     numbers: \y     back / next / exit: \w
new g_iMenuFor;   // player the menu being built is for (set by VexHead), 0 = unknown

stock bool:ZcIsCode(c) { return c == 'w' || c == 'y' || c == 'r' || c == 'd' || c == 'R'; }

stock VexMenuColor(const src[], dst[], len, const lead[] = "\w")
{
    if (src[0] == '\' || src[0] == '^n')
        copy(dst, len, src);
    else
        formatex(dst, len, "%s%s", lead, src);
}

new g_szMenuLast[512];   // son menu basligi (test araci vexprobe callfunc ile okur)
new g_iMenuTitleLen, g_iMenuItemBytes, g_iMenuItemCnt;   // v3.4: istemci menu siniri (~511 bayt) icin otomatik sayfalama
new bool:g_bMenuNoPage;

stock VexMenuCreate(const title[], const handler[])
{
    new t[512];
    VexMenuColor(title, t, charsmax(t), "\w");
    copy(g_szMenuLast, charsmax(g_szMenuLast), t);
    g_iMenuTitleLen = strlen(t);
    g_iMenuItemBytes = 0;
    g_iMenuItemCnt = 0;
    g_bMenuNoPage = false;
    return menu_create(t, handler);
}

// Gelistirici testi: son olusturulan menunun basligini loglar (devtools/server/vexprobe)
public VexDbgMenuTitle()
{
    new t[600];
    copy(t, charsmax(t), g_szMenuLast);
    replace_string(t, charsmax(t), "^n", " | ");
    log_amx("[menu-title] len=%d %s", strlen(g_szMenuLast), t);
}

stock VexAddText(menu, const text[], slot = 1)
{
    new t[192];
    VexMenuColor(text, t, charsmax(t), "\d");
    replace_string(t, charsmax(t), "\r", "\d");
    replace_string(t, charsmax(t), "\w", "\d");
    menu_addtext(menu, t, slot);
}

stock bool:ZcHasWord(const s[], const w[]) { return containi(s, w) != -1; }

// colour of one [tag] (content without brackets)
stock ZcTagColor(const c[])
{
    if (ZcHasWord(c, "KILIT") || ZcHasWord(c, "LOCK") || ZcHasWord(c, "YETERSIZ") || ZcHasWord(c, "NOT ENOUGH")
        || ZcHasWord(c, "GEREKLI") || ZcHasWord(c, "REQUIRED"))
        return 'r';
    if (ZcHasWord(c, "SAHIP") || ZcHasWord(c, "OWNED") || ZcHasWord(c, "KUSANIL") || ZcHasWord(c, "EQUIPPED")
        || ZcHasWord(c, "AKTIF") || ZcHasWord(c, "ACTIVE") || ZcHasWord(c, "SECILI") || ZcHasWord(c, "SELECTED"))
        return 'd';
    new t[32]; copy(t, charsmax(t), c); trim(t);
    if (equali(t, "ON") || equali(t, "ACIK")) return 'y';
    if (equali(t, "OFF") || equali(t, "KAPALI")) return 'd';
    // price: "<n> AP" / "<n> VC" / "<n> Coin"
    new num = -1, bool:ap = false, bool:vc = false;
    for (new i = 0; c[i]; i++)
    {
        if (c[i] >= '0' && c[i] <= '9')
        {
            if (num < 0) num = 0;
            if (num < 100000000) num = num * 10 + (c[i] - '0');
            new j = i + 1; while (c[j] == ' ') j++;
            if (!(c[j] >= '0' && c[j] <= '9'))
            {
                if (equali(c[j], "AP", 2)) ap = true;
                else if (equali(c[j], "VC", 2) || equali(c[j], "COIN", 4)) vc = true;
                if (ap || vc) break;
                num = -1;
            }
        }
    }
    if ((ap || vc) && num >= 0)
    {
        new p = g_iMenuFor;
        if (p >= 1 && p <= 32 && is_user_connected(p) && ((ap && g_iAP[p] < num) || (vc && g_iVC[p] < num)))
            return 'r';
        return 'y';
    }
    return 'd';
}

stock ZcStyleItem(const src[], dst[], len)
{
    new plain[192], n, nameEnd = -1, bool:hadText;
    for (new i = 0; src[i] && n < charsmax(plain); i++)
    {
        if (src[i] == '\' && ZcIsCode(src[i + 1]))
        {
            if (hadText && nameEnd < 0) nameEnd = n;
            i++;
            continue;
        }
        if (src[i] == '[' && nameEnd < 0 && hadText) nameEnd = n;
        if (src[i] == '(' && nameEnd < 0 && hadText)
        {
            new j = i + 1; while (src[j] && src[j] != ')') j++;
            if (src[j] == ')' && j - i - 1 > 3) nameEnd = n;   // "(Items, Special Guns)" -> description; "(VIP)" stays in the name
        }
        plain[n++] = src[i];
        if (src[i] != ' ') hadText = true;
    }
    plain[n] = 0;
    if (nameEnd < 0) nameEnd = n;

    new name[96], desc[160], tags[160], dn, tn;
    new k = min(nameEnd, charsmax(name));
    copy(name, k, plain);
    trim(name);
    new bool:star;
    for (new i = nameEnd; i < n; i++)
    {
        if (plain[i] == '[')
        {
            new close = -1;
            for (new j = i + 1; j < n; j++) if (plain[j] == ']') { close = j; break; }
            if (close > i)
            {
                new c[64]; copy(c, min(close - i - 1, charsmax(c)), plain[i + 1]);
                new ct[64]; copy(ct, charsmax(ct), c); trim(ct);
                if (equal(ct, "*")) { star = true; i = close; continue; }
                if (equali(ct, "R") || equali(ct, "E") || equali(ct, "F") || equali(ct, "G"))
                {
                    // key hint inside a description: keep it there
                    dn += formatex(desc[dn], charsmax(desc) - dn, "[%s]", ct);
                    i = close;
                    continue;
                }
                tn += formatex(tags[tn], charsmax(tags) - tn, "%s\%c[%s]", tn ? " " : "", ZcTagColor(ct), ct);
                i = close;
                continue;
            }
        }
        if (dn < charsmax(desc)) desc[dn++] = plain[i];
    }
    desc[dn] = 0;
    trim(desc);
    new o = formatex(dst, len, "\w%s", name);
    if (star) o += formatex(dst[o], len - o, " \y*");
    if (equal(desc, "(!)")) o += formatex(dst[o], len - o, " \y(!)");
    else if (desc[0]) o += formatex(dst[o], len - o, " \d%s", desc);
    if (tags[0]) o += formatex(dst[o], len - o, "\R%s", tags);
}

stock MenuAdd(menu, const text[], value)
{
    new info[8], t[192];
    num_to_str(value, info, charsmax(info));
    ZcStyleItem(text, t, charsmax(t));
    g_iMenuItemBytes += strlen(t) + 9;   // "\y1.\w " + "^n"
    g_iMenuItemCnt++;
    menu_additem(menu, t, info);
}
