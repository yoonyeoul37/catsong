# -*- coding: utf-8 -*-
# 지역 MBC 12곳: 라디오 프로그램 소개 페이지에 '방송 시간'이 적혀 있는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe32.py  →  radio_probe32_result.txt 가 생겨요 (몇 분 걸려요)
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
    t = re.sub(r'<script.*?</script>|<style.*?</style>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


# 방송 시간처럼 보이는 글자: "월~금 12:00~14:00", "매일 오후 2시", "평일 06:05" 등
WHEN = re.compile(r'(?:월|화|수|목|금|토|일|매일|평일|주말|월요일|토요일|일요일)[^가-힣]{0,3}[^.\n]{0,25}?'
                  r'(?:\d{1,2}\s*:\s*\d{2}|(?:오전|오후|낮|밤|저녁|아침)?\s*\d{1,2}\s*시(?:\s*\d{1,2}\s*분)?)'
                  r'(?:\s*[~\-–]\s*(?:\d{1,2}\s*:\s*\d{2}|(?:오전|오후)?\s*\d{1,2}\s*시(?:\s*\d{1,2}\s*분)?))?')

STATIONS = [
    ('부산MBC', ['https://busanmbc.co.kr/03_rad/rad01.asp'], r'rad01_view\.asp\?[^"\']*ct=\d+'),
    ('울산MBC', ['https://www.usmbc.co.kr/RadioProgram'], r'/RadioProgram/[^"\']+'),
    ('MBC경남', ['https://mbcgn.kr/03_rad/rad01.asp'], r'rad01_view\.asp\?[^"\']*ct=\d+'),
    ('안동MBC', ['https://andongmbc.co.kr/main/radio/radio_today.php?m=1', 'https://www.andongmbc.co.kr/main/radio/radio.php'],
     r'radio[^"\']*\.php\?[^"\']*(?:no|wr_id|pg|code)=\w+'),
    ('대구MBC', ['https://www.dgmbc.com/'], r'(?:radio|program)[^"\']*'),
    ('포항MBC', ['https://www.phmbc.co.kr/www/radio'], r'/www/radio/[a-z_0-9]+/program_guide'),
    ('광주MBC', ['https://kjmbc.co.kr/RadioProgram'], r'/(?:RadioProgram|Radio)[^"\']*/[^"\']+'),
    ('목포MBC', ['https://www.mpmbc.co.kr/RadioProgram'], r'/(?:RadioProgram|Radio)[^"\']*/[^"\']+'),
    ('전주MBC', ['https://www.jmbc.co.kr/program/radio', 'https://www.jmbc.co.kr/program'], r'/program/(?:sfm|fm|radio|rfm)[^"\']*'),
    ('대전MBC', ['https://www.tjmbc.co.kr/'], r'(?:radio|program)[^"\']*'),
    ('MBC충북', ['https://mbccb.co.kr/rb/?r=home&c=75'], r'\?r=home&(?:amp;)?c=75/\d+'),
    ('제주MBC', ['https://www.jejumbc.com/'], r'(?:radio|program)[^"\']*'),
]


def scan(item):
    name, lists, pat = item
    L = [f'■ {name}']
    progs = []
    for u in lists:
        try:
            final, t = get(u)
        except Exception as e:
            L.append(f'  목록 {u} → X {str(e)[:60]}')
            continue
        L.append(f'  목록 {u} → {final} · 글자 수 {len(t)}')
        if len(t) < 2000:  # 빈 페이지: 다른 주소로 넘기는 곳
            L.append('    (페이지 전체) ' + re.sub(r'\s+', ' ', t)[:600])
        tx = text(t)
        hits = WHEN.findall(tx)
        L.append(f'    목록 안 방송 시간 글자 {len(hits)}개 {hits[:12]}')
        for m in re.finditer(pat, t):
            v = urllib.parse.urljoin(final, m.group(0).replace('&amp;', '&'))
            if v not in progs and urllib.parse.urlparse(v).netloc == urllib.parse.urlparse(final).netloc:
                progs.append(v)
    L.append(f'  프로그램 페이지 후보 {len(progs)}개')
    for v in progs[:14]:
        try:
            f2, t2 = get(v)
        except Exception as e:
            L.append(f'    {v} → X {str(e)[:40]}')
            continue
        tx = text(t2)
        title = re.search(r'<title>(.*?)</title>', t2, re.S | re.I)
        hits = WHEN.findall(tx)
        L.append(f'    [{re.sub(chr(10), " ", title.group(1)).strip()[:40] if title else "?"}] {v}')
        L.append(f'      방송 시간 글자 {hits[:4]}')
        time.sleep(0.2)
    return L


out = []
with cf.ThreadPoolExecutor(4) as ex:
    for L in ex.map(scan, STATIONS):
        for l in L:
            print(l)
            out.append(l)

with open('radio_probe32_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe32_result.txt 를 올려 주세요')
