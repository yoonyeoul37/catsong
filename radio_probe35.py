# -*- coding: utf-8 -*-
# 지역 MBC 덮어쓰기용: 부산·포항·충북·경남·안동 지역 프로그램의 채널 · 방송 시간 · 사진 (앱 코드는 안 건드려요)
# 실행: python radio_probe35.py  →  radio_probe35_result.txt
import re, ssl, time, urllib.request, urllib.parse, concurrent.futures as cf

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, n=None):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}),
                               timeout=15, context=ctx())
    raw = r.read(n) if n else r.read()
    if n:
        return r.status, r.headers.get('Content-Type', ''), r.headers.get('Content-Length', '?')
    for enc in ('utf-8', 'euc-kr'):
        try:
            return r.geturl(), raw.decode(enc)
        except Exception:
            pass
    return r.geturl(), raw.decode('utf-8', 'replace')


def text(t):
    t = re.sub(r'<script.*?</script>|<style.*?</style>|<header.*?</header>|<nav.*?</nav>|<footer.*?</footer>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


WHEN = re.compile(r'(?:방송\s*(?:시간|일시|채널)?\s*:?\s*)?(?:월|화|수|목|금|토|일|매일|평일|주말)[^.\n]{0,30}?'
                  r'\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?)'
                  r'(?:\s*[~\-–]\s*(?:오전|오후|낮|밤)?\s*\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?))?')
CH = re.compile(r'표준\s*FM[^가-힣]{0,12}|FM4U[^가-힣]{0,12}|음악\s*FM[^가-힣]{0,12}|제[12]\s*FM[^가-힣]{0,12}|\d{2,3}\.\d\s*MHz')
SKIP_IMG = re.compile(r'logo|icon|btn|bullet|blank|/common/|sns|banner_top|arrow|ico_|_ico|top_|footer|quick|kakao|facebook|insta|youtube|qr', re.I)

PAGES = {
    '부산MBC': ['https://busanmbc.co.kr/03_rad/rad01_view.asp?ct=' + n for n in '6 7 8 12 13 9 11'.split()],
    '포항MBC': ['https://www.phmbc.co.kr/www/radio/' + n + '/program_guide' for n in 'morning_show request_line_at_noon open_world'.split()],
    'MBC충북': ['https://mbccb.co.kr/rb/?r=home&c=75/' + n for n in '838 611 843 96 742 604 653 623'.split()],
    'MBC경남': ['https://mbcgn.kr/03_rad/rad01_view.asp?ct=' + n for n in '16 12 62 10 11'.split()],
    '안동MBC': ['https://andongmbc.co.kr/main/radio/radio_today.php?m=' + n for n in '1 2 3 4 5 6'.split()],
}


def scan(item):
    name, urls = item
    L = [f'■ {name}']
    for u in urls:
        try:
            f, t = get(u)
        except Exception as e:
            L.append(f'  {u} → X {str(e)[:40]}')
            continue
        tx = text(t)
        title = re.search(r'<title>(.*?)</title>', t, re.S | re.I)
        title = re.sub(r'\s+', ' ', title.group(1)).strip()[:60] if title else '?'
        L.append(f'  [{title}] {u}')
        L.append(f'     시간: {list(dict.fromkeys(WHEN.findall(tx)))[:4]}')
        L.append(f'     채널: {list(dict.fromkeys(m.strip() for m in CH.findall(tx)))[:4]}')
        og = re.findall(r'property=["\']og:image["\']\s+content=["\']([^"\']+)', t)
        if og:
            L.append(f'     og:image {og[0]}')
        imgs = []
        for m in re.finditer(r'<img[^>]+src=["\']([^"\']+)["\']', t, re.I):
            v = urllib.parse.urljoin(f, m.group(1))
            if not SKIP_IMG.search(v) and v not in imgs and not v.endswith('.gif'):
                imgs.append(v)
        for v in imgs[:4]:
            try:
                st, ct, ln = get(v, 1024)
                L.append(f'     사진 {v}  ({st} {ct} {ln}바이트)')
            except Exception as e:
                L.append(f'     사진 {v}  (X {str(e)[:30]})')
        time.sleep(0.2)
    return L


out = []
with cf.ThreadPoolExecutor(4) as ex:
    for L in ex.map(scan, PAGES.items()):
        for l in L:
            print(l)
            out.append(l)

with open('radio_probe35_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe35_result.txt 를 올려 주세요')
