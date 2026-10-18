"""OpenGameArt helper: search (CC0 / CC-BY only), read an art page (title, author, licenses, files), download."""
import html
import json
import os
import re
import subprocess
import sys
import urllib.parse

BASE = 'https://opengameart.org'
TYPES = {'music': 12, 'sfx': 13}
LIC = {'cc0': 4, 'ccby3': 2, 'ccby4': 17981}
CACHE = os.environ.get('OGA_CACHE', '/tmp/claude-0/-home-user-claude/75b34835-cf97-54a7-be23-70299b8b0f9d/scratchpad/snd534/cache')


def get(url, out=None):
    os.makedirs(CACHE, exist_ok=True)
    key = os.path.join(CACHE, re.sub(r'[^A-Za-z0-9._-]', '_', url)[-180:])
    if out is None:
        if not os.path.exists(key):
            subprocess.run(['curl', '-sL', '-m', '60', url, '-o', key], check=False)
        return open(key, encoding='utf-8', errors='ignore').read() if os.path.exists(key) else ''
    subprocess.run(['curl', '-sL', '-m', '180', url, '-o', out], check=False)
    return out


def search(keys, kind='sfx', lic=('cc0',), page=0):
    q = [('keys', keys), ('field_art_type_tid[]', TYPES[kind]), ('sort_by', 'count'), ('sort_order', 'DESC'), ('page', page)]
    q += [('field_art_licenses_tid[]', LIC[l]) for l in lic]
    t = get(BASE + '/art-search-advanced?' + urllib.parse.urlencode(q))
    slugs = []
    for s in re.findall(r'<span class="art-preview-title"><a href="/content/([^"]+)"', t) or re.findall(r'href="/content/([^"]+)"', t):
        if s not in slugs and s not in ('faq',) and 'art-challenge' not in s:
            slugs.append(s)
    return slugs


def page(slug):
    t = get(BASE + '/content/' + slug)
    title = html.unescape((re.findall(r'<h2>([^<]+)</h2>', t) or [''])[0]).strip()
    author = (re.findall(r'Author:.*?<a href="/users/([^"]+)"', t, re.S) or [''])[0]
    lics = sorted(set(re.findall(r'license-name">([^<]+)<', t)))
    files = [html.unescape(u) for u in re.findall(r'href="(https://opengameart.org/sites/default/files/[^"]+)"', t)]
    files = [f for f in files if re.search(r'\.(ogg|wav|mp3|flac|zip)$', f, re.I)]
    tags = re.findall(r'href="/art-search\?keys=([^"]+)"', t)
    return dict(slug=slug, title=title, author=author, licenses=lics, files=list(dict.fromkeys(files)), tags=tags[:15])


if __name__ == '__main__':
    kind, keys = sys.argv[1], ' '.join(sys.argv[2:])
    for s in search(keys, kind)[:12]:
        p = page(s)
        print(json.dumps(dict(p, files=[os.path.basename(f) for f in p['files']][:6])))
