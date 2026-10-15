# -*- coding: utf-8 -*-
# 편성표 찾은 방송국 자세히 보기 + CPBC·TBN 편성표 주소 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe6.py  →  radio_probe6_result.txt 가 생겨요
import re, ssl, time, datetime, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
today = datetime.date.today()
tomorrow = today + datetime.timedelta(days=1)


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, referer=None):
    try:
        h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
        if referer:
            h['Referer'] = referer
        req = urllib.request.Request(url, headers=h)
        with urllib.request.urlopen(req, timeout=20, context=ssl.create_default_context()) as r:
            raw = r.read()
            enc = 'utf-8'
            m = re.search(r'charset=([\w-]+)', r.headers.get('Content-Type', ''), re.I) \
                or re.search(r'charset=["\']?([\w-]+)', raw[:3000].decode('ascii', 'ignore'), re.I)
            if m:
                enc = m.group(1)
            try:
                return r.status, raw.decode(enc, errors='replace')
            except LookupError:
                return r.status, raw.decode('utf-8', errors='replace')
    except Exception as e:
        return None, str(e)[:200]


def body_of(html):
    return re.sub(r'<script.*?</script>|<style.*?</style>', '', html, flags=re.S | re.I)


def around(html, pat, before=300, after=2500):
    b = body_of(html)
    m = re.search(pat, b)
    if not m:
        return '  (못 찾음: ' + pat + ')'
    return b[max(0, m.start() - before): m.start() + after]


def js_func(html, name, n=1200):
    i = html.find('function ' + name)
    return html[i:i + n] if i >= 0 else f'  (함수 {name} 없음)'


def show(title, url, referer=None, pat=r'\b\d{2}:\d{2}\b', after=2500, funcs=(), imgs=False, raw=False):
    log('=' * 70)
    log(f'[{title}] {url}')
    st, txt = get(url, referer)
    log(f'  상태 {st} · 글자 수 {len(txt)}')
    if not st:
        log('  ' + txt)
        return txt
    if raw:
        log(txt[:after])
    else:
        log(around(txt, pat, after=after))
    for f in funcs:
        log(f'  --- 함수 {f} ---')
        log(js_func(txt, f))
    if imgs:
        log('  --- 사진 후보 ---')
        for u in re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', txt)[:25]:
            log('  ' + u)
    time.sleep(1)
    return txt


# ── CPBC · TBN: 홈페이지 안 링크 전부 (편성표 주소 찾기) ──
for name, home in [('CPBC', 'https://www.cpbc.co.kr/'), ('TBN', 'https://www.tbn.or.kr/')]:
    log('#' * 70)
    log(f'■ {name} 홈페이지 링크 · 스크립트')
    st, txt = get(home)
    log(f'  상태 {st} · 글자 수 {len(txt)}')
    if st:
        hrefs = sorted(set(re.findall(r'href=["\']([^"\'#]+)["\']', txt)))
        for h in hrefs:
            if re.search(r'radio|sch|편성|program|onair|live', h, re.I):
                log('  링크 ' + h)
        for s in sorted(set(re.findall(r'<script[^>]+src=["\']([^"\']+)["\']', txt)))[:15]:
            log('  스크립트 ' + s)
        for s in sorted(set(re.findall(r'["\'](/[^"\'\s]*(?:sch|Sch|편성)[^"\'\s]*)["\']', txt)))[:15]:
            log('  주소 후보 ' + s)
    time.sleep(1)

for u in ['https://www.cpbc.co.kr/radio/schedule', 'https://www.cpbc.co.kr/schedule',
          'https://www.cpbc.co.kr/schedule/radio', 'https://www.cpbc.co.kr/radio']:
    show('CPBC 추측 주소', u, 'https://www.cpbc.co.kr/', after=1500)

# ── FEBC 극동방송 ──
log('#' * 70)
t = show('FEBC 오늘', 'https://seoul.febc.net/radio/schedule', 'https://seoul.febc.net/',
         pat=r'class="time"', after=600, funcs=('fnCalendarDate',))
if t:
    items = re.findall(r'<span class="time">(\d{2}:\d{2})</span>.*?<img src="([^"]+)".*?<p class="tit">(.*?)</p>',
                       body_of(t), re.S)
    log(f'  ▶ 시간·사진·제목 묶음 {len(items)}개 (처음 40개)')
    for tm, img, ti in items[:40]:
        log(f'    {tm} | {ti.strip()} | {img}')
show('FEBC 내일 (date)', f'https://seoul.febc.net/radio/schedule?date={tomorrow:%Y-%m-%d}', 'https://seoul.febc.net/',
     pat=r'class="time"', after=400)

# ── 국악FM ──
log('#' * 70)
g = show('국악 편성 페이지 함수', 'https://www.igbf.kr/gugak_web/?sub_num=786', 'https://www.igbf.kr/',
         pat=r'id="schedule"', after=200, funcs=('goSchedulePage', 'RadioSchedule', 'WeeklySchedule'))
for q in [f'{today:%Y%m%d}', f'{today:%Y-%m-%d}', '']:
    show(f'국악 ajax today={q}', f'https://www.igbf.kr/gugak_web/radio/ajax/radio_schedule_action.jsp?today={q}',
         'https://www.igbf.kr/gugak_web/?sub_num=786', raw=True, after=1500)
show('국악 프로그램 페이지(사진)', 'https://www.igbf.kr/gugak_web/radio/radio_program_main_sub.jsp?idx=RD2015002113&sub_num=787',
     'https://www.igbf.kr/', pat=r'<img', after=800, imgs=True)

# ── TBS FM · eFM ──
log('#' * 70)
for u in ['https://tbs.seoul.kr/fm/schedule.do', 'https://tbs.seoul.kr/eFm/schedule.do']:
    show('TBS', u, 'https://tbs.seoul.kr/', after=2500, funcs=('fn_getScheduleByWeek',), imgs=True)

# ── JTV 매직FM ──
log('#' * 70)
show('JTV 라디오', 'https://www.jtv.co.kr/page/00027.php?t=radio', 'https://www.jtv.co.kr/',
     pat=r'class="time"', after=2500, imgs=True)

with open('radio_probe6_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe6_result.txt 를 올려 주세요')
