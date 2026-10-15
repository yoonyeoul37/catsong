# -*- coding: utf-8 -*-
# CBS 편성표 페이지 모양 자세히 보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe2.py  →  radio_probe2_result.txt 가 생겨요
import re, ssl, urllib.request, urllib.parse, time, datetime

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
CTX = ssl.create_default_context()
out = []

def log(s=''):
    print(s)
    out.append(s)

def get(url, data=None, extra=None):
    try:
        h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9', 'Referer': 'https://www.cbs.co.kr/schedule'}
        if extra:
            h.update(extra)
        body = urllib.parse.urlencode(data).encode() if data else None
        req = urllib.request.Request(url, data=body, headers=h)
        with urllib.request.urlopen(req, timeout=15, context=CTX) as r:
            return r.status, r.headers.get('Content-Type', ''), r.read().decode('utf-8', errors='replace')
    except Exception as e:
        return None, '', str(e)[:200]

today = datetime.date.today()
sat = today + datetime.timedelta(days=(5 - today.weekday()) % 7)
pages = [
    ('음악FM 오늘', f'https://www.cbs.co.kr/schedule?type=musicFm&date={today:%Y%m%d}'),
    ('음악FM 토요일', f'https://www.cbs.co.kr/schedule?type=musicFm&date={sat:%Y%m%d}'),
    ('표준FM 오늘', f'https://www.cbs.co.kr/schedule?type=fm&date={today:%Y%m%d}'),
]
for name, url in pages:
    log('=' * 60)
    log(f'[{name}] {url}')
    st, ct, html = get(url)
    log(f'  상태 {st} · {ct} · 글자 수 {len(html)}')
    if not st:
        log('  ' + html)
        continue
    m = re.search(r'\d{2}:\d{2}', re.sub(r'<script.*?</script>', '', html, flags=re.S))
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', html, flags=re.S)
    i = body.find(m.group(0)) if m else -1
    log('  --- 첫 시간 근처 HTML (그대로) ---')
    log(body[max(0, i - 1500): i + 2500] if i >= 0 else '  시간을 못 찾음')
    time.sleep(1)

log('=' * 60)
log('[데이터 주소 시험]')
for url, data in [
    ('https://www.cbs.co.kr/schedule/radio/ajax', None),
    ('https://www.cbs.co.kr/schedule/radio/ajax', {'type': 'musicFm', 'date': f'{today:%Y%m%d}'}),
    ('https://www.cbs.co.kr/schedule/all/ajax', None),
    (f'https://www.cbs.co.kr/schedule/radio/ajax?type=musicFm&date={today:%Y%m%d}', None),
]:
    st, ct, txt = get(url, data, {'X-Requested-With': 'XMLHttpRequest'})
    log(f'  {"POST" if data else "GET"} {url} {data or ""} → 상태 {st} · {ct} · 글자 수 {len(txt)}')
    log('    ' + txt[:1200].replace('\n', ' '))
    time.sleep(1)

with open('radio_probe2_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe2_result.txt 를 올려 주세요')
