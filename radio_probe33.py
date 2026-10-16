# -*- coding: utf-8 -*-
# 지역 MBC 2차: 지역 프로그램마다 '어느 채널(표준FM/FM4U)' · '몇 시~몇 시'인지 + 대구·대전·제주 진짜 홈페이지
# (앱 코드는 안 건드려요)   실행: python radio_probe33.py  →  radio_probe33_result.txt
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


def text(t):
    t = re.sub(r'<script.*?</script>|<style.*?</style>|<header.*?</header>|<nav.*?</nav>|<footer.*?</footer>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


KEY = re.compile(r'방송\s*시간|방송\s*일시|표준\s*FM|FM4U|음악\s*FM|\d{2,3}\.\d\s*MHz|\d{1,2}\s*:\s*\d{2}\s*[~\-–]\s*\d{1,2}\s*:\s*\d{2}')

PROGRAMS = {
    '부산MBC': ['https://busanmbc.co.kr/03_rad/rad01_view.asp?ct=' + n for n in '6 7 8 12 13 9 11'.split()],
    '울산MBC': ['https://www.usmbc.co.kr/RadioProgram/' + n + '/home' for n in '161 160 159'.split()],
    'MBC경남': ['https://mbcgn.kr/03_rad/rad01_view.asp?ct=' + n for n in '16 53 12 62 10 11'.split()],
    '포항MBC': ['https://www.phmbc.co.kr/www/radio/' + n + '/program_guide' for n in 'morning_show request_line_at_noon open_world'.split()],
    '광주MBC': ['https://kjmbc.co.kr/RadioProgram/' + n + '/home' for n in '98 92 17 18'.split()],
    '목포MBC': ['https://www.mpmbc.co.kr/RadioProgram/' + n + '/home' for n in '40 105 101 41'.split()],
    'MBC충북': ['https://mbccb.co.kr/rb/?r=home&c=75/' + n for n in '838 611 843 96 742 604 653 623'.split()],
}
HOMES = [('대구MBC', 'https://dgmbc.com/'), ('대전MBC', 'https://tjmbc.co.kr/'), ('제주MBC', 'https://jejumbc.com/'),
         ('안동MBC', 'https://andongmbc.co.kr/main/radio/radio_today.php?m=1')]


def prog_scan(item):
    name, urls = item
    L = [f'■ {name}']
    for u in urls:
        try:
            f, t = get(u)
        except Exception as e:
            L.append(f'  {u} → X {str(e)[:40]}')
            continue
        tx = text(t)
        h = re.search(r'<title>(.*?)</title>', t, re.S | re.I)
        title = re.sub(r'\s+', ' ', h.group(1)).strip()[:50] if h else '?'
        L.append(f'  [{title}] {u}')
        seen = 0
        for m in KEY.finditer(tx):
            L.append('     … ' + tx[max(0, m.start() - 50): m.end() + 70])
            seen += 1
            if seen >= 5:
                break
        time.sleep(0.2)
    return L


def home_scan(item):
    name, home = item
    L = [f'■ {name} {home}']
    try:
        final, t = get(home)
    except Exception as e:
        L.append(f'  X {str(e)[:60]}')
        return L
    L.append(f'  → {final} · 글자 수 {len(t)}')
    if len(t) < 2000:
        L.append('  (페이지 전체) ' + re.sub(r'\s+', ' ', t)[:500])
    links = []
    for href, txt in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S | re.I):
        txt = re.sub(r'<[^>]+>|\s+', ' ', txt).strip()
        if re.search(r'편성|schedule|timetable|라디오|radio', href + ' ' + txt, re.I):
            v = urllib.parse.urljoin(final, href)
            if v not in [x[0] for x in links]:
                links.append((v, txt[:20]))
    for v, txt in links[:20]:
        L.append(f'  링크 [{txt}] {v}')
    for v, txt in [x for x in links if re.search(r'편성|schedule|timetable', x[0] + x[1], re.I)][:4]:
        try:
            f2, t2 = get(v, final)
        except Exception as e:
            L.append(f'  [열어 봄] {v} → X {str(e)[:40]}')
            continue
        tx = text(t2)
        times = re.findall(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b|\d{1,2}시\s*\d{1,2}분', tx)
        L.append(f'  [열어 봄] {v} → 시간 글자 {len(times)}개')
        if len(times) >= 8:
            i = tx.find(times[0])
            L.append('     ' + tx[max(0, i - 200): i + 700])
    if 'radio_today' in home:
        tx = text(t)
        i = max(tx.find('라디오 오늘'), 0)
        L.append('  (본문) ' + tx[i: i + 1500])
    return L


out = []
with cf.ThreadPoolExecutor(4) as ex:
    for L in list(ex.map(prog_scan, PROGRAMS.items())) + list(ex.map(home_scan, HOMES)):
        for l in L:
            print(l)
            out.append(l)

with open('radio_probe33_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe33_result.txt 를 올려 주세요')
