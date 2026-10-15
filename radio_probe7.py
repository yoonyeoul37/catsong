# -*- coding: utf-8 -*-
# TBS 프로그램 사진 · CPBC 편성표 주소 · 국악FM 편성표 데이터 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe7.py  →  radio_probe7_result.txt 가 생겨요
import re, ssl, time, datetime, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
today = datetime.date.today()


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, referer=None, data=None):
    try:
        h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
        if referer:
            h['Referer'] = referer
        body = urllib.parse.urlencode(data).encode() if data is not None else None
        req = urllib.request.Request(url, headers=h, data=body)
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


def links(html, pat):
    return sorted(set(h for h in re.findall(r'href=["\']([^"\'#]+)["\']', html) if re.search(pat, h)))


def imgs(html):
    return [u for u in re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', html)
            if not re.search(r'/common/images/|btn|ico|logo', u, re.I)]


# ───── TBS: FM 화면 · 프로그램 소개 페이지 ─────
log('#' * 70)
log('■ TBS 프로그램 사진')
prog_links = []
for page in ['https://tbs.seoul.kr/fm/index.do', 'https://tbs.seoul.kr/fm/schedule.do',
             'https://tbs.seoul.kr/eFm/index.do', 'https://tbs.seoul.kr/eFm/schedule.do']:
    st, txt = get(page, 'https://tbs.seoul.kr/')
    log(f'  {page} → 상태 {st} · 글자 수 {len(txt)}')
    if not st:
        continue
    ls = links(txt, r'/cont/|programId|program')
    log(f'    프로그램 링크 {len(ls)}개 (처음 25개)')
    for l in ls[:25]:
        log('      ' + l)
    prog_links += [urllib.parse.urljoin(page, l) for l in ls]
    ims = imgs(txt)
    log(f'    사진 후보 {len(ims)}개 (처음 15개)')
    for u in ims[:15]:
        log('      ' + u)
    time.sleep(1)
seen = []
for u in prog_links:
    if u not in seen and ('/fm/' in u.lower() or 'efm' in u.lower() or 'radio' in u.lower()):
        seen.append(u)
for u in seen[:3]:
    st, txt = get(u, 'https://tbs.seoul.kr/fm/schedule.do')
    log('  ' + '-' * 60)
    log(f'  [프로그램 페이지] {u} → 상태 {st}')
    if st:
        t = re.search(r'<title>(.*?)</title>', txt, re.S)
        log('    제목: ' + (t.group(1).strip() if t else ''))
        og = re.search(r'og:image["\'][^>]+content=["\']([^"\']+)', txt)
        log('    og:image: ' + (og.group(1) if og else '없음'))
        for im in imgs(txt)[:12]:
            log('      사진 ' + im)
    time.sleep(1)

# ───── CPBC: 홈페이지가 스크립트로 만들어져서 스크립트 안 주소 찾기 ─────
log('#' * 70)
log('■ CPBC')
st, home = get('https://www.cpbc.co.kr/')
log(home[:932] if st else home)
st, js = get('https://www.cpbc.co.kr/javascript/cpbc-app.js', 'https://www.cpbc.co.kr/')
log(f'  cpbc-app.js → 상태 {st} · 글자 수 {len(js)}')
if st:
    found = sorted(set(re.findall(r'["\'`]([^"\'`\s]*(?:schedule|Schedule|편성|onair|OnAir|radio|Radio)[^"\'`\s]*)["\'`]', js)))
    for f in found[:60]:
        if len(f) < 160:
            log('    ' + f)
    apis = sorted(set(re.findall(r'https?://[a-zA-Z0-9.\-]+(?:/[^"\'`\s]*)?', js)))
    log('  --- 스크립트 안 인터넷 주소 ---')
    for a in apis[:40]:
        log('    ' + a)
time.sleep(1)

# ───── 국악FM: 편성표 데이터 (진짜 목록을 주는 곳) ─────
log('#' * 70)
log('■ 국악FM')
base = 'https://www.igbf.kr/gugak_web/radio/ajax/'
for q in [f'{today:%Y%m%d}', f'{today:%Y-%m-%d}', '0']:
    for method in ('GET', 'POST'):
        st, txt = get(base + f'radio_schedule_process.jsp?today={q}', 'https://www.igbf.kr/gugak_web/?sub_num=786',
                      data={} if method == 'POST' else None)
        log(f'  [{method} today={q}] 상태 {st} · 글자 수 {len(txt)}')
        log('  ' + txt[:1500].replace('\n', ' ')[:1500])
        time.sleep(1)
st, txt = get('https://www.igbf.kr/gugak_web/?sub_num=786', 'https://www.igbf.kr/')
if st:
    i = txt.find('showScheduleList')
    log('  --- showScheduleList 근처 ---')
    log(txt[max(0, i - 300): i + 1500] if i >= 0 else '  (없음)')
st, txt = get('https://www.igbf.kr/gugak_web/radio/radio_program_main_sub.jsp?idx=RD2015002113&sub_num=787', 'https://www.igbf.kr/')
if st:
    i = txt.find('/DataFiles/Radio/PROG/')
    log('  --- 프로그램 사진 근처 ---')
    log(txt[max(0, i - 500): i + 300] if i >= 0 else '  (없음)')

with open('radio_probe7_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe7_result.txt 를 올려 주세요')
