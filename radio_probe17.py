# -*- coding: utf-8 -*-
# CPBC · TBN · BeFM 편성표 주소 더 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe17.py  →  radio_probe17_result.txt 가 생겨요
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []


def log(s=''):
    print(s)
    out.append(str(s))


def ctx():
    c = ssl.create_default_context()
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, referer=None):
    try:
        h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
        if referer:
            h['Referer'] = referer
        r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=20, context=ctx())
        raw = r.read()
        m = re.search(r'charset=([\w-]+)', r.headers.get('Content-Type', ''), re.I) \
            or re.search(r'charset=["\']?([\w-]+)', raw[:3000].decode('ascii', 'ignore'), re.I)
        try:
            return r.status, r.geturl(), raw.decode(m.group(1) if m else 'utf-8', 'replace')
        except LookupError:
            return r.status, r.geturl(), raw.decode('utf-8', 'replace')
    except Exception as e:
        return None, url, str(e)[:200]


def around_time(html, after=2500):
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', html, flags=re.S | re.I)
    m = re.search(r'\b\d{2}:\d{2}\b', body)
    return body[max(0, m.start() - 600): m.start() + after] if m else '  (시간 모양 글자 없음)'


# ── CPBC: 홈 화면 스크립트 안의 데이터 주소 ──
log('#' * 60)
log('■ CPBC')
for js in ['https://www.cpbc.co.kr/javascript/cpbc-home-desktop-1.0.0.min.js',
           'https://static.cpbc.co.kr/gnb/javascript/cpbc-gnb-desktop-1.0.0.js',
           'https://static.cpbc.co.kr/player/javascript/cpbc-player-1.0.0.js']:
    st, _, t = get(js, 'https://www.cpbc.co.kr/')
    log(f'  {js} → 상태 {st} · 글자 수 {len(t)}')
    if not st:
        continue
    urls = sorted(set(re.findall(r'["\'`]((?:https?:)?//[a-zA-Z0-9.\-]*cpbc[a-zA-Z0-9.\-]*(?:/[^"\'`\s]*)?)["\'`]', t)))
    for u in urls[:40]:
        log('    주소 ' + u)
    for m in re.finditer(r'[Ss]chedule|편성|timetable|onair|OnAir', t):
        log('    … ' + re.sub(r'\s+', ' ', t[max(0, m.start() - 150): m.end() + 150]))
        if m.start() > 0 and len(out) > 400:
            break
    time.sleep(0.5)

# ── TBN: main.tbn 과 편성표 ──
log('#' * 60)
log('■ TBN')
st, final, t = get('https://www.tbn.or.kr/main.tbn')
log(f'  main.tbn → 상태 {st} ({final}) · 글자 수 {len(t)}')
if st:
    for href, text in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S | re.I):
        tx = re.sub(r'<[^>]+>|\s+', ' ', text).strip()
        if re.search(r'편성|sch|경인|울산|gyeong|ulsan', href + tx, re.I):
            log(f'    링크 [{tx[:20]}] {urllib.parse.urljoin(final, href)}')
    links = [urllib.parse.urljoin(final, h) for h, x in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S | re.I)
             if '편성' in re.sub(r'<[^>]+>', '', x) or re.search(r'sch', h, re.I)]
    for u in links[:2]:
        time.sleep(1)
        st2, _, t2 = get(u, final)
        log(f'  [편성표 후보] {u} → 상태 {st2} · 글자 수 {len(t2)}')
        if st2:
            for h in sorted(set(re.findall(r'["\']([^"\'\s]*(?:ajax|json|[Ss]ch)[^"\'\s]*)["\']', t2)))[:15]:
                log('    데이터 주소 후보 ' + h)
            log(around_time(t2))

# ── BeFM: 편성표 ──
log('#' * 60)
log('■ BeFM')
st, final, t = get('https://www.befm.or.kr/main.php?lang=ko')
log(f'  홈 → 상태 {st} · 글자 수 {len(t)}')
if st:
    for href, text in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S | re.I):
        tx = re.sub(r'<[^>]+>|\s+', ' ', text).strip()
        if re.search(r'편성|schedule|timetable|sch|program', href + ' ' + tx, re.I):
            log(f'    링크 [{tx[:25]}] {urllib.parse.urljoin(final, href)}')
for u in ['https://www.befm.or.kr/sub/template.php?midx=7&lang=ko', 'https://www.befm.or.kr/sub/schedule.php?lang=ko']:
    time.sleep(1)
    st, _, t = get(u, 'https://www.befm.or.kr/')
    log(f'  [후보] {u} → 상태 {st} · 글자 수 {len(t)}')
    if st:
        log(around_time(t, 1500))

with open('radio_probe17_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe17_result.txt 를 올려 주세요')
