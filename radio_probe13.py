# -*- coding: utf-8 -*-
# BBS 불교방송: 새 편성표 주소(ajaxSch.html)가 막히는지, 모양이 어떤지 (앱 코드는 안 건드려요)
# 실행: python radio_probe13.py  →  radio_probe13_result.txt 가 생겨요
import re, ssl, time, datetime, urllib.request, urllib.parse, http.cookiejar

out = []
today = datetime.date.today()
MOBILE = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'


def log(s=''):
    print(s)
    out.append(str(s))


def session():
    cj = http.cookiejar.CookieJar()
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj), urllib.request.HTTPSHandler(context=c))


def get(op, url, data=None, extra=None):
    h = {'User-Agent': MOBILE, 'Accept-Language': 'ko-KR,ko;q=0.9', 'Referer': 'https://m.bbsi.co.kr/M/?ACT=SCHEDULE'}
    if extra:
        h.update(extra)
    body = urllib.parse.urlencode(data).encode() if data is not None else None
    if body is not None:
        h['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
    try:
        r = op.open(urllib.request.Request(url, headers=h, data=body), timeout=20)
        return r.status, r.read().decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:200]


URL = 'https://m.bbsi.co.kr/M/sub/06_schedule/ajaxSch.html'
param = {'Gubun': 'RADIO', 'SchDate': f'{today:%Y-%m-%d}'}
ajax = {'X-Requested-With': 'XMLHttpRequest', 'Accept': '*/*'}
tests = [
    ('POST + 쿠키 없이', False, 'POST', ajax),
    ('POST + 쿠키 먼저', True, 'POST', ajax),
    ('GET + 쿠키 먼저', True, 'GET', ajax),
    ('POST + 쿠키 먼저 (ajax 표시 없이)', True, 'POST', {}),
]
best = ''
for name, warm, method, extra in tests:
    op = session()
    if warm:
        get(op, 'https://m.bbsi.co.kr/M/?ACT=SCHEDULE')
        time.sleep(0.5)
    if method == 'POST':
        st, txt = get(op, URL, param, extra)
    else:
        st, txt = get(op, URL + '?' + urllib.parse.urlencode(param), None, extra)
    blocked = 'Detect client IP' in txt
    times = re.findall(r'\b\d{2}:\d{2}\b', re.sub(r'<script.*?</script>', '', txt, flags=re.S))
    log(f'[{name}] 상태 {st} · 글자 수 {len(txt)} · 차단화면 {"예" if blocked else "아니오"} · 시간 글자 {len(times)}개')
    if blocked:
        log('  ' + re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', txt))[:200])
    elif len(txt) > len(best):
        best = txt
    time.sleep(1)

log('=' * 60)
log('[가장 긴 결과 앞부분]')
log(best[:5000])
log('--- 사진 후보 ---')
for u in re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', best)[:20]:
    log('  ' + u)

with open('radio_probe13_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe13_result.txt 를 올려 주세요')
