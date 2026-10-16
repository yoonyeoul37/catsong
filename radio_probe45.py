# -*- coding: utf-8 -*-
# 울산MBC · 대구MBC 지역 라디오 프로그램: 이름 · 채널 · 방송 시간 · 사진 (덮어쓰기용, 앱 코드는 안 건드려요)
# 실행: python radio_probe45.py  →  radio_probe45_result.txt
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE


def log(s=''):
    print(s)
    out.append(str(s))


def get(url):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=15, context=c)
    return r.geturl(), r.read().decode('utf-8', 'replace')


def text(t):
    t = re.sub(r'<script.*?</script>|<style.*?</style>|<header.*?</header>|<nav.*?</nav>|<footer.*?</footer>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


KEY = re.compile(r'방송\s*시간|방송\s*일시|주파수|표준\s*FM|FM4U|\d{2,3}\.\d\s*M[Hh]z|(?:월|화|수|목|금|토|일|매일|평일|주말)[ ~\-화수목금토일]{0,12}\s*(?:AM|PM|오전|오후)?\s*\d{1,2}\s*[:시]\s*\d{0,2}')

for site, base in [('울산MBC', 'https://www.usmbc.co.kr'), ('대구MBC', 'https://dgmbc.com')]:
    log('#' * 70)
    log(f'■ {site}')
    try:
        final, t = get(base + '/RadioProgram')
    except Exception as e:
        log(f'  목록 못 가져옴 {e}')
        continue
    # 목록 카드: 프로그램 링크 · 이름 · 사진 · 요일/시간
    cards = re.findall(r'<a[^>]+href=["\'](/RadioProgram/\d+/home)["\'][^>]*>(.*?)</a>', t, re.S)
    seen = []
    for href, inner in cards:
        if href in seen:
            continue
        seen.append(href)
        img = re.search(r'<img[^>]+src=["\']([^"\']+)', inner)
        log(f'  카드 {href} · {text(inner)[:120]} · 사진 {urllib.parse.urljoin(final, img.group(1)) if img else "-"}')
    for href in seen[:12]:
        u = urllib.parse.urljoin(final, href)
        try:
            f2, t2 = get(u)
        except Exception as e:
            log(f'  {u} → X {e}')
            continue
        tx = text(t2)
        name = re.search(r'<h\d[^>]*>\s*([^<]{2,40})\s*</h\d>', t2)
        og = re.findall(r'property=["\']og:(?:title|image)["\']\s+content=["\']([^"\']+)', t2)
        log(f'  ── {u}')
        log(f'     제목 후보: {name.group(1).strip() if name else "?"} · og {og[:2]}')
        hits = []
        for m in KEY.finditer(tx):
            s = tx[max(0, m.start() - 40): m.end() + 60]
            if s not in hits:
                hits.append(s)
            if len(hits) >= 4:
                break
        for s in hits:
            log(f'     … {s}')
        imgs = [urllib.parse.urljoin(f2, x) for x in re.findall(r'<img[^>]+src=["\']([^"\']+)', t2)
                if re.search(r'upload|file|data|program|thumb', x, re.I) and not re.search(r'logo|icon|btn|sns', x, re.I)]
        for x in imgs[:3]:
            log(f'     사진 {x}')
        time.sleep(0.3)

with open('radio_probe45_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe45_result.txt 를 올려 주세요')
