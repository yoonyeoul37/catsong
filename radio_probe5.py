# -*- coding: utf-8 -*-
# 남은 국내 라디오 편성표가 어디 있는지 찾아보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe5.py  →  radio_probe5_result.txt 가 생겨요
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []

SITES = [
    ('CPBC 가톨릭', ['https://www.cpbc.co.kr/', 'https://radio.cpbc.co.kr/']),
    ('FEBC 극동방송', ['https://www.febc.net/', 'https://seoul.febc.net/']),
    ('국악FM', ['https://www.gugakfm.co.kr/', 'https://www.igbf.kr/']),
    ('TBS', ['https://tbs.seoul.kr/', 'https://www.tbs.seoul.kr/']),
    ('OBS 라디오', ['https://www.obs.co.kr/']),
    ('TBN', ['https://www.tbn.or.kr/']),
    ('BeFM', ['https://www.befm.or.kr/']),
    ('JTV 매직FM', ['https://www.jtv.co.kr/']),
]
KEYS = re.compile(r'편성|schedule|timetable|sch_|/sch', re.I)


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
                return r.status, r.geturl(), raw.decode(enc, errors='replace')
            except LookupError:
                return r.status, r.geturl(), raw.decode('utf-8', errors='replace')
    except Exception as e:
        return None, url, str(e)[:200]


def schedule_links(base, html):
    found = []
    for href, text in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', html, re.S | re.I):
        t = re.sub(r'<[^>]+>|\s+', ' ', text).strip()
        if KEYS.search(href) or '편성' in t:
            u = urllib.parse.urljoin(base, href)
            if u.startswith('http') and u not in [f[0] for f in found]:
                found.append((u, t[:30]))
    return found[:8]


def around_time(html, after=2500):
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', html, flags=re.S | re.I)
    m = re.search(r'\b\d{2}:\d{2}\b', body)
    if not m:
        return None
    i = m.start()
    return body[max(0, i - 600): i + after]


def script_hints(html):
    # 페이지가 데이터를 따로 불러오는 주소 후보
    hints = set(re.findall(r'["\']([^"\'\s]*(?:ajax|json|api|Schedule|schedule)[^"\'\s]*)["\']', html))
    return sorted(h for h in hints if len(h) < 150)[:15]


for name, homes in SITES:
    log('#' * 70)
    log(f'■ {name}')
    links = []
    for home in homes:
        st, final, txt = get(home)
        log(f'  홈 {home} → 상태 {st} ({final})')
        if not st:
            log('    ' + txt)
            continue
        links = schedule_links(final, txt)
        if links:
            break
    if not links:
        log('  편성표 링크를 못 찾음')
        continue
    for u, t in links:
        log(f'  링크: [{t}] {u}')
    for u, _ in links[:3]:
        time.sleep(1)
        st, final, txt = get(u, u)
        log('  ' + '-' * 60)
        log(f'  [편성표 후보] {u} → 상태 {st} · 글자 수 {len(txt)}')
        if not st:
            log('    ' + txt)
            continue
        hints = script_hints(txt)
        if hints:
            log('  --- 데이터 주소 후보 ---')
            for h in hints:
                log('    ' + h)
        part = around_time(txt)
        if part:
            log('  --- 첫 시간 근처 HTML ---')
            log(part)
            break
        log('  (시간 모양 글자 없음)')
    time.sleep(1)

with open('radio_probe5_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe5_result.txt 를 올려 주세요')
