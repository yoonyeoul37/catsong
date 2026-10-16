# -*- coding: utf-8 -*-
# 춘천MBC 라디오 프로그램 페이지: 이름 · 방송 시간 · 채널 · 사진 (앱 코드는 안 건드려요)
# 실행: python radio_probe49.py  →  radio_probe49_result.txt
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
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://chmbc.co.kr/'}),
                               timeout=15, context=c)
    return r.geturl(), r.read().decode('utf-8', 'replace')


def text(t):
    t = re.sub(r'<script.*?</script>|<style.*?</style>|<header.*?</header>|<nav.*?</nav>|<footer.*?</footer>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


final, page = get('https://chmbc.co.kr/programme_list/Radio')
links = []
for h in re.findall(r'href=["\']((?:https://chmbc\.co\.kr)?/programme/[^"\'#?]+)["\']', page):
    u = urllib.parse.urljoin(final, h)
    if u not in links:
        links.append(u)
log(f'■ 춘천MBC 라디오 프로그램 페이지 {len(links)}개')
# 목록 화면에서 카드 글자 (이름 · 시간이 같이 있는지)
for u in links:
    i = page.find(u.replace('https://chmbc.co.kr', ''))
    log(f'  [목록 카드 글자] {text(page[i - 200: i + 900])[:220]}')
for u in links[:15]:
    try:
        f, t = get(u)
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    og = dict(re.findall(r'property=["\']og:(title|image|description)["\']\s+content=["\']([^"\']*)', t))
    tt = re.search(r'<title>(.*?)</title>', t, re.S)
    tx = text(t)
    when = re.findall(r'(?:월|화|수|목|금|토|일|매일|평일|주말)[^.\n]{0,25}?\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?)'
                      r'(?:\s*[~\-–]\s*\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?))?', tx)
    ch = re.findall(r'표준\s*FM|음악\s*FM|FM4U|\d{2,3}\.\d\s*MHz', tx)
    log(f'  ── {u}')
    log(f'     제목 {tt.group(1).strip()[:60] if tt else "?"} · og:title {og.get("title")!r}')
    log(f'     시간 {list(dict.fromkeys(when))[:4]} · 채널 {list(dict.fromkeys(ch))[:4]}')
    log(f'     og:image {og.get("image")}')
    time.sleep(0.3)

with open('radio_probe49_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe49_result.txt 를 올려 주세요')
