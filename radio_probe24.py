# -*- coding: utf-8 -*-
# TBN 편성표: 편성표 페이지가 실제로 어디서 데이터를 불러오는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe24.py  →  radio_probe24_result.txt 가 생겨요
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, referer='https://www.tbn.or.kr/main.tbn', data=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9', 'Referer': referer}
    body = urllib.parse.urlencode(data).encode() if data is not None else None
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers=h, data=body), timeout=20, context=c)
        raw = r.read()
        for enc in ('utf-8', 'euc-kr'):
            try:
                return r.status, r.geturl(), raw.decode(enc)
            except Exception:
                pass
        return r.status, r.geturl(), raw.decode('utf-8', 'replace')
    except Exception as e:
        return None, url, str(e)[:200]


for area in ['6', '1']:
    url = f'https://www.tbn.or.kr/broadcast/program.tbn?BOARD_ID=P001&page_code=1&area_code={area}'
    st, final, t = get(url)
    log('#' * 60)
    log(f'■ 편성표 페이지 area_code={area} → {st} · 글자 수 {len(t)}')
    if not st:
        log(t)
        continue
    log('--- 페이지 전체 (스타일 빼고) ---')
    log(re.sub(r'<style.*?</style>', '', t, flags=re.S | re.I)[:6000])
    for s in sorted(set(re.findall(r'<script[^>]+src=["\']([^"\']+)', t))):
        log('  스크립트 ' + s)
    for f in sorted(set(re.findall(r'<iframe[^>]+src=["\']([^"\']+)', t))):
        log('  iframe ' + f)
    time.sleep(1)

# 공통 스크립트 안에서 편성표 부르는 곳
for js in ['https://www.tbn.or.kr/js/common.js', 'https://www.tbn.or.kr/js/default.js', 'https://www.tbn.or.kr/js/board.js']:
    st, _, t = get(js)
    log('=' * 60)
    log(f'{js} → {st} · 글자 수 {len(t)}')
    for m in re.finditer(r'[Ss]chedule|program|편성|\.tbn', t):
        log('  … ' + re.sub(r'\s+', ' ', t[max(0, m.start() - 120): m.end() + 160]))
        if len(out) > 600:
            break
    time.sleep(0.5)

# 후보 주소들
cands = ['https://www.tbn.or.kr/broadcast/schedule.tbn?area_code=6',
         'https://www.tbn.or.kr/broadcast/program_list.tbn?area_code=6',
         'https://www.tbn.or.kr/broadcast/timetable.tbn?area_code=6',
         'https://www.tbn.or.kr/broadcast/program.tbn?BOARD_ID=P001&page_code=2&area_code=6',
         'https://www.tbn.or.kr/broadcast/program.tbn?BOARD_ID=P002&page_code=1&area_code=6',
         'https://m.tbn.or.kr/']
for u in cands:
    st, final, t = get(u)
    times = re.findall(r'\b\d{2}:\d{2}\b', re.sub(r'<script.*?</script>', '', t, flags=re.S))
    log('=' * 60)
    log(f'[후보] {u} → {st} ({final}) · 글자 수 {len(t)} · 시간 글자 {len(times)}개')
    if st and times:
        body = re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)
        i = body.find(times[0])
        log(body[max(0, i - 800): i + 2500])
    time.sleep(0.7)

with open('radio_probe24_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe24_result.txt 를 올려 주세요')
