# -*- coding: utf-8 -*-
# 국내 라디오 편성표 페이지 살펴보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe.py  →  같은 폴더에 radio_probe_result.txt 가 생겨요
import re, ssl, urllib.request, urllib.parse, time

SITES = [
    ('CBS', 'https://www.cbs.co.kr/radio'),
    ('CBS(모바일)', 'https://m.cbs.co.kr/radio'),
    ('YTN 라디오', 'https://radio.ytn.co.kr/'),
    ('국악방송', 'https://www.gugakfm.co.kr/'),
    ('TBS', 'https://tbs.seoul.kr/'),
    ('CPBC 가톨릭', 'https://www.cpbc.co.kr/'),
    ('FEBC 극동방송', 'https://www.febc.net/'),
    ('OBS', 'https://www.obs.co.kr/'),
    ('경인방송', 'https://www.ifm.kr/'),
    ('TBN', 'https://www.tbn.or.kr/'),
    ('부산MBC', 'https://www.busanmbc.co.kr/'),
]
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
CTX = ssl.create_default_context()
out = []

def log(s=''):
    print(s)
    out.append(s)

def get(url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'})
        with urllib.request.urlopen(req, timeout=15, context=CTX) as r:
            raw = r.read()
            ct = r.headers.get('Content-Type', '')
            enc = 'utf-8'
            m = re.search(r'charset=([\w-]+)', ct)
            if m:
                enc = m.group(1)
            try:
                text = raw.decode(enc, errors='replace')
            except LookupError:
                text = raw.decode('utf-8', errors='replace')
            return r.status, r.geturl(), text
    except Exception as e:
        return None, url, str(e)[:200]

def links(base, html):
    found = []
    for m in re.finditer(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', html, re.S | re.I):
        href, label = m.group(1), re.sub(r'<[^>]+>', '', m.group(2)).strip()
        if href.startswith('javascript'):
            continue
        if '편성' in label or re.search(r'sched|timetable|pgm|program', href, re.I):
            found.append((label[:30], urllib.parse.urljoin(base, href)))
    seen, uniq = set(), []
    for l, u in found:
        if u not in seen:
            seen.add(u)
            uniq.append((l, u))
    return uniq[:6]

def api_hints(html):
    hints = set()
    for m in re.finditer(r'["\']((?:https?:)?//[^"\']+|/[^"\'\s]+)["\']', html):
        u = m.group(1)
        if re.search(r'\.json|/api/|ajax|schedule|sched|timetable|onair|pgm', u, re.I) and len(u) < 200:
            hints.add(u)
    return sorted(hints)[:15]

def times_sample(html):
    text = re.sub(r'<script.*?</script>|<style.*?</style>', ' ', html, flags=re.S | re.I)
    text = re.sub(r'<[^>]+>', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    hits = re.findall(r'(\d{1,2}:\d{2})\s*(?:~\s*\d{1,2}:\d{2})?\s*([가-힣A-Za-z][^0-9]{2,25})', text)
    return hits[:6]

for name, url in SITES:
    log('=' * 60)
    log(f'[{name}] {url}')
    st, final, html = get(url)
    if st is None:
        log(f'  접속 실패: {html}')
        continue
    log(f'  상태 {st} · 실제 주소 {final} · 글자 수 {len(html)}')
    for l, u in links(final, html):
        log(f'  편성 링크 후보: {l} → {u}')
    for h in api_hints(html):
        log(f'  데이터 주소 후보: {h}')
    # 편성 링크를 두 개까지 직접 열어 보기
    for l, u in links(final, html)[:2]:
        time.sleep(1)
        st2, final2, html2 = get(u)
        log(f'  ▶ 열어 봄: {u} → 상태 {st2} · 글자 수 {len(html2) if st2 else 0}')
        if st2:
            for t in times_sample(html2):
                log(f'     시간표처럼 보이는 글: {t[0]} {t[1].strip()}')
            for h in api_hints(html2):
                log(f'     데이터 주소 후보: {h}')
    time.sleep(1)

with open('radio_probe_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe_result.txt 를 올려 주세요')
