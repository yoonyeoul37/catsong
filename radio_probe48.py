# -*- coding: utf-8 -*-
# 지역 MBC 프로그램 사진 찾기: 제주·대전·광주·목포(울산·대구와 같은 모양) · 춘천 · 충북 · 안동
# (앱 코드는 안 건드려요)   실행: python radio_probe48.py  →  radio_probe48_result.txt
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    return c


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, ref=None):
    h = {'User-Agent': UA}
    if ref:
        h['Referer'] = ref
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=15, context=ctx())
    raw = r.read()
    for enc in ('utf-8', 'euc-kr'):
        try:
            return r.geturl(), raw.decode(enc)
        except Exception:
            pass
    return r.geturl(), raw.decode('utf-8', 'replace')


def size(url):
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}, method='HEAD'), timeout=10, context=ctx())
        return f'{r.status} {r.headers.get("Content-Type", "")[:12]} {int(r.headers.get("Content-Length") or 0) // 1024}KB'
    except Exception as e:
        return f'X {str(e)[:30]}'


def text(t):
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


# ── 1) 울산·대구와 같은 모양: /RadioProgram 목록 카드 (이름 · 요일 시간 · 사진) ──
for site, base, extra in [('제주MBC', 'https://jejumbc.com', ['/Radio_ING', '/RadioJejusGeneration']),
                          ('대전MBC', 'https://tjmbc.co.kr', []),
                          ('광주MBC', 'https://kjmbc.co.kr', []),
                          ('목포MBC', 'https://www.mpmbc.co.kr', [])]:
    log('#' * 70)
    log(f'■ {site}')
    for path in ['/RadioProgram', '/RadioProgram/active'] + extra:
        try:
            final, t = get(base + path)
        except Exception as e:
            log(f'  {path} → X {str(e)[:50]}')
            continue
        cards = re.findall(r'<a[^>]+href=["\']([^"\']*/(?:RadioProgram|Radio_ING|Radio)[^"\']*/\d+/home)["\'][^>]*>(.*?)</a>', t, re.S)
        log(f'  {path} → {final} · 카드 {len(cards)}개')
        seen = set()
        for href, inner in cards:
            if href in seen:
                continue
            seen.add(href)
            img = re.search(r'<img[^>]+src=["\']([^"\']+)', inner) or re.search(r'url\(["\']?([^"\')]+)', inner)
            iu = urllib.parse.urljoin(final, img.group(1)) if img else ''
            log(f'    {text(inner)[:70]} | {iu} ({size(iu) if iu else "-"})')
        time.sleep(0.3)

# ── 2) 춘천MBC: 라디오 프로그램 목록 ──
log('#' * 70)
log('■ 춘천MBC')
try:
    final, t = get('https://chmbc.co.kr/programme_list/Radio')
    log(f'  목록 → {final} · 글자 수 {len(t)}')
    blocks = re.findall(r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>\s*(?:<[^>]+>\s*)*<img[^>]+src=["\']([^"\']+)["\'][^>]*>(.*?)</a>', t, re.S)
    for href, src, rest in blocks[:40]:
        name = text(rest)[:50]
        alt = re.search(r'alt=["\']([^"\']*)', rest)
        log(f'    {name or (alt.group(1) if alt else "?")} | {urllib.parse.urljoin(final, href)} | {src} ({size(src)})')
    if not blocks:
        for m in re.finditer(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*alt=["\']([^"\']*)', t):
            log(f'    [그림] {m.group(2)} | {m.group(1)}')
except Exception as e:
    log(f'  못 가져옴 {e}')

# ── 3) 충북MBC: 라디오 메뉴 카드 사진 (작은 사진이 있는지) ──
log('#' * 70)
log('■ MBC충북')
try:
    final, t = get('https://mbccb.co.kr/rb/?r=home&c=75')
    for m in re.finditer(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*?(?:alt=["\']([^"\']*))?', t):
        u = urllib.parse.urljoin(final, m.group(1))
        if re.search(r'files|upload|thumb|program', u, re.I):
            log(f'    [그림] {m.group(2) or ""} | {u} ({size(u)})')
except Exception as e:
    log(f'  못 가져옴 {e}')

with open('radio_probe48_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe48_result.txt 를 올려 주세요')
