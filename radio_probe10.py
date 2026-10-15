# -*- coding: utf-8 -*-
# BBS 불교방송 편성표: 어떤 접속 방식이면 보안 차단 안 되는지 확인 (앱 코드는 안 건드려요)
# 실행: python radio_probe10.py  →  radio_probe10_result.txt 가 생겨요
import re, ssl, time, datetime, urllib.request, http.cookiejar

out = []
today = datetime.date.today()
MOBILE = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'
PC = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'


def log(s=''):
    print(s)
    out.append(str(s))


def opener():
    cj = http.cookiejar.CookieJar()
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE  # 앱과 같게 (BBS 인증서 문제 무시)
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj), urllib.request.HTTPSHandler(context=c)), cj


def get(op, url, headers):
    try:
        r = op.open(urllib.request.Request(url, headers=headers), timeout=20)
        raw = r.read()
        return r.status, raw.decode('utf-8', 'replace')
    except Exception as e:
        return None, str(e)[:200]


def report(name, st, txt):
    blocked = 'Detect client IP' in txt
    progs = re.findall(r'<div class="program( onairbox)?">', txt)
    log(f'  [{name}] 상태 {st} · 글자 수 {len(txt)} · 차단화면 {"예" if blocked else "아니오"} · 프로그램 칸 {len(progs)}개')
    if blocked or not progs:
        log('    ' + re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', txt))[:600])


def try_flow(title, ua, extra):
    log('=' * 60)
    log(f'■ {title}')
    op, cj = opener()
    base = {'User-Agent': ua, 'Accept-Language': 'ko-KR,ko;q=0.9',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'}
    base.update(extra)
    st, txt = get(op, 'https://m.bbsi.co.kr/M/?ACT=RADIO_FM', base)
    log(f'  메인 페이지 상태 {st} · 글자 수 {len(txt)} · 차단화면 {"예" if "Detect client IP" in txt else "아니오"} · 쿠키 {[c.name for c in cj]}')
    time.sleep(1)
    h = dict(base, **{'Referer': 'https://m.bbsi.co.kr/M/?ACT=RADIO_FM', 'X-Requested-With': 'XMLHttpRequest',
                      'Accept': '*/*'})
    url = f'https://m.bbsi.co.kr/M/ajaxSchedule.html?CODE=WWW&SchGubun=RADIO&SchDate={today:%Y-%m-%d}'
    st, txt = get(op, url, h)
    report('편성표', st, txt)
    if st and 'Detect client IP' not in txt:
        i = txt.find('<div class="program')
        log('  --- 첫 프로그램 칸 ---')
        log(txt[i:i + 800])
    time.sleep(1)


try_flow('앱과 같은 방식 (짧은 휴대폰 UA)', 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36', {})
try_flow('진짜 휴대폰 크롬 UA', MOBILE, {})
try_flow('PC 크롬 UA', PC, {})
try_flow('휴대폰 크롬 + 브라우저 헤더 더', MOBILE, {'Sec-Fetch-Site': 'same-origin', 'Sec-Fetch-Mode': 'navigate',
                                             'Upgrade-Insecure-Requests': '1'})

# PC 홈페이지 편성표도 확인
log('=' * 60)
log('■ PC 홈페이지')
op, _ = opener()
for u in ['https://www.bbsi.co.kr/', 'https://www.bbsi.co.kr/schedule/', 'https://www.bbsi.co.kr/HOME/schedule/']:
    st, txt = get(op, u, {'User-Agent': PC, 'Accept-Language': 'ko-KR,ko;q=0.9'})
    log(f'  {u} → 상태 {st} · 글자 수 {len(txt)} · 차단화면 {"예" if "Detect client IP" in txt else "아니오"}')
    if st:
        for href in sorted(set(re.findall(r'href=["\']([^"\']*(?:[Ss]chedule|편성|SCH)[^"\']*)["\']', txt)))[:10]:
            log('    링크 ' + href)
    time.sleep(1)

with open('radio_probe10_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe10_result.txt 를 올려 주세요')
