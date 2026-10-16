# -*- coding: utf-8 -*-
# 지역 MBC 13개 방송국: 라디오 편성표 페이지 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe29.py  →  radio_probe29_result.txt 가 생겨요 (몇 분 걸려요)
import re, ssl, time, urllib.request, urllib.parse, concurrent.futures as cf

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, referer=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=15, context=ctx())
    raw = r.read()
    for enc in ('utf-8', 'euc-kr'):
        try:
            return r.geturl(), raw.decode(enc)
        except Exception:
            pass
    return r.geturl(), raw.decode('utf-8', 'replace')


def clean(t):
    return re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)


STATIONS = [
    ('부산MBC', 'https://www.busanmbc.co.kr/'),
    ('울산MBC', 'https://www.usmbc.co.kr/'),
    ('MBC경남', 'https://www.mbcgn.kr/'),
    ('안동MBC', 'https://www.andongmbc.co.kr/'),
    ('대구MBC', 'https://www.dgmbc.com/'),
    ('포항MBC', 'https://www.phmbc.co.kr/'),
    ('광주MBC', 'https://www.kjmbc.co.kr/'),
    ('목포MBC', 'https://www.mpmbc.co.kr/'),
    ('전주MBC', 'https://www.jmbc.co.kr/'),
    ('대전MBC', 'https://www.tjmbc.co.kr/'),
    ('MBC충북', 'https://www.mbccb.co.kr/'),
    ('춘천MBC', 'https://www.chmbc.co.kr/'),
    ('제주MBC', 'https://www.jejumbc.com/'),
]
GUESS = ['radio/schedule', 'schedule/radio', 'schedule?type=radio', 'radio/timetable', 'radio', 'schedule']


def scan(item):
    name, home = item
    L = [f'■ {name} {home}']
    try:
        final, t = get(home)
    except Exception as e:
        L.append(f'  홈 못 가져옴: {str(e)[:80]}')
        return L
    L.append(f'  홈 → {final} · 글자 수 {len(t)}')
    links = []
    for href, txt in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S | re.I):
        txt = re.sub(r'<[^>]+>|\s+', ' ', txt).strip()
        if re.search(r'편성|schedule|timetable|라디오|radio', href + ' ' + txt, re.I):
            links.append((urllib.parse.urljoin(final, href), txt[:20]))
    seen = []
    for u, txt in links:
        if u not in [s[0] for s in seen]:
            seen.append((u, txt))
    for u, txt in seen[:25]:
        L.append(f'  링크 [{txt}] {u}')
    # 편성 쪽 링크 + 흔한 주소 열어서 시간 글자 수 세기
    cands = [u for u, txt in seen if re.search(r'편성|schedule|timetable', u + txt, re.I)][:6]
    cands += [urllib.parse.urljoin(final, g) for g in GUESS]
    done = set()
    for u in cands:
        if u in done:
            continue
        done.add(u)
        try:
            f2, t2 = get(u, final)
        except Exception as e:
            L.append(f'  [시도] {u} → X {str(e)[:50]}')
            continue
        b = clean(t2)
        times = re.findall(r'\b([01]?\d|2[0-3]):[0-5]\d\b', b)
        has_radio = '라디오' in b or 'FM' in b
        L.append(f'  [시도] {u} → {f2} · 시간 글자 {len(times)}개 · 라디오 글자 {"있음" if has_radio else "없음"}')
        if len(times) >= 8:
            m = re.search(r'\b(?:0?[5-9]|1\d):[0-5]\d\b', b)
            i = m.start() if m else 0
            L.append('    ' + re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', b[max(0, i - 300): i + 900])))
            for a in sorted(set(re.findall(r'(?:href|src)=["\']([^"\']*(?:ajax|json|api|Schedule|schedule)[^"\']*)["\']', t2)))[:8]:
                L.append(f'    주소 단서 {a}')
        time.sleep(0.3)
    return L


out = []
with cf.ThreadPoolExecutor(5) as ex:
    for L in ex.map(scan, STATIONS):
        for l in L:
            print(l)
            out.append(l)

with open('radio_probe29_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe29_result.txt 를 올려 주세요')
