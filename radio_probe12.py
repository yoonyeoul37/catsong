# -*- coding: utf-8 -*-
# BBS 불교방송: 편성표를 실제로 불러오는 주소 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe12.py  →  radio_probe12_result.txt 가 생겨요
import re, ssl, time, urllib.request, urllib.parse, http.cookiejar

out = []
PC = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
MOBILE = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'


def log(s=''):
    print(s)
    out.append(str(s))


cj = http.cookiejar.CookieJar()
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj), urllib.request.HTTPSHandler(context=c))


def get(url, ua=MOBILE, referer=None):
    h = {'User-Agent': ua, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    try:
        r = op.open(urllib.request.Request(url, headers=h), timeout=20)
        return r.status, r.read().decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:200]


def calls(txt):
    # 자바스크립트 안에서 데이터를 부르는 곳 (url: ..., $.get/$.post/$.ajax, fetch)
    found = []
    for m in re.finditer(r'(url\s*:\s*["\'][^"\']+["\']|\$\.(?:get|post|ajax|getJSON)\s*\(\s*["\'][^"\']+["\']|fetch\(\s*["\'][^"\']+["\']|\.load\(\s*["\'][^"\']+["\'])', txt):
        s = txt[max(0, m.start() - 150): m.end() + 250].replace('\n', ' ')
        found.append(re.sub(r'\s+', ' ', s))
    return found


def show(title, url, ua=MOBILE, referer=None, dump=0):
    log('=' * 60)
    st, txt = get(url, ua, referer)
    blocked = 'Detect client IP' in txt
    log(f'■ {title} {url} → 상태 {st} · 글자 수 {len(txt)} · 차단화면 {"예" if blocked else "아니오"}')
    if not st or blocked:
        log('  ' + txt[:300])
        return ''
    for s in calls(txt)[:15]:
        log('  부르는 곳: ' + s)
    scripts = sorted(set(re.findall(r'<script[^>]+src=["\']([^"\']+)["\']', txt)))
    for s in scripts:
        log('  스크립트 ' + s)
    if dump:
        body = re.sub(r'<style.*?</style>', '', txt, flags=re.S | re.I)
        m = re.search(r'\b\d{2}:\d{2}\b', re.sub(r'<script.*?</script>', '', body, flags=re.S))
        log('  --- 앞부분 ---')
        log(body[:dump])
    time.sleep(1)
    return txt


base = 'https://m.bbsi.co.kr'
show('모바일 첫 화면(쿠키)', base + '/M/?ACT=RADIO_FM')
t = show('모바일 라디오 편성표 조각', base + '/M/sub/06_schedule/schedule.html', referer=base + '/M/?ACT=SCHEDULE', dump=4000)
show('모바일 편성표 화면', base + '/M/?ACT=SCHEDULE')

# PC 첫 화면 스크립트들 안에서 편성표 부르는 곳
st, pc = get('https://www.bbsi.co.kr/?ACT=SCHEDULE', PC)
for s in calls(pc)[:15]:
    log('  PC 부르는 곳: ' + s)
for src in sorted(set(re.findall(r'<script[^>]+src=["\']([^"\']+)["\']', pc))):
    if 'cdnjs' in src or 'google' in src:
        continue
    u = urllib.parse.urljoin('https://www.bbsi.co.kr/', src)
    st, js = get(u, PC, 'https://www.bbsi.co.kr/?ACT=SCHEDULE')
    found = [x for x in calls(js) if re.search(r'[Ss]chedule|SCH|Program|ONAIR|OnAir', x)]
    log(f'  PC 스크립트 {u} → 상태 {st} · 글자 수 {len(js)} · 편성 관련 {len(found)}개')
    for f in found[:10]:
        log('    ' + f[:500])
    time.sleep(0.5)

with open('radio_probe12_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe12_result.txt 를 올려 주세요')
