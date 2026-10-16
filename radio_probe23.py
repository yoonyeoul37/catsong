# -*- coding: utf-8 -*-
# 지역 민방 · 지방 MBC 온에어 페이지가 소리를 어디서 불러오는지 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe23.py  →  radio_probe23_result.txt 가 생겨요 (몇 분 걸려요)
import re, ssl, urllib.request, urllib.parse, concurrent.futures as cf

UA = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, n=None, timeout=12, referer=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=timeout, context=ctx())
    raw = r.read(n) if n else r.read()
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), raw


def text(raw):
    for enc in ('utf-8', 'euc-kr'):
        try:
            return raw.decode(enc)
        except Exception:
            pass
    return raw.decode('utf-8', 'replace')


def test_stream(url, referer=None):
    try:
        st, _, ct, head = get(url, 2048, 10, referer)
        t = head[:300].decode('latin-1', 'ignore')
        ok = st == 200 and ('#EXTM3U' in t or 'audio' in ct or 'mpegurl' in ct.lower())
        return 'OK' if ok else f'?({st} {ct[:25]})'
    except Exception as e:
        return f'X({str(e)[:40]})'


STREAM = re.compile(r'(?:https?:)?//[^\s"\'<>\\]+?(?:\.m3u8|\.sdp|/playlist|\.pls|\.aac|\.mp3)(?:\?[^\s"\'<>\\]*)?', re.I)
HINT = re.compile(r'm3u8|rtmp|streamlock|wowza|:1935|hls|\.sdp|live_?stream|radio_?url|stream_?url|audioUrl|fmUrl|liveUrl', re.I)

PAGES = [
    ('KNN 부산', ['https://www.knn.co.kr/onair', 'https://www.knn.co.kr/radio']),
    ('TBC 대구', ['https://www.tbc.co.kr/onair/?mid=6_190', 'https://www.tbc.co.kr/fm']),
    ('KBC 광주', ['https://www.ikbc.co.kr/onair', 'https://www.ikbc.co.kr/radio/main']),
    ('TJB 대전', ['https://m.tjb.co.kr/onair-main.php']),
    ('UBC 울산', ['https://www.ubc.co.kr/onair/', 'https://www.ubc.co.kr/radio/']),
    ('G1 강원', ['https://www.g1tv.co.kr/radio']),
    ('JIBS 제주', ['https://www.jibs.co.kr/radio/viewRadioMain?channelId=0']),
    ('CJB 청주', ['https://www.cjb.co.kr/', 'https://m.cjb.co.kr/']),
    ('여수MBC', ['https://ysmbc.co.kr/OnAir']),
    ('원주MBC', ['https://www.wjmbc.co.kr/radio/fm.html', 'https://www.wjmbc.co.kr/radio/am.html']),
    ('MBC강원영동', ['https://www.mbceg.co.kr/', 'https://www.mbceg.co.kr/onair']),
]


def scan(item):
    name, pages = item
    L = [f'■ {name}']
    for page in pages:
        try:
            st, final, ct, raw = get(page, timeout=15)
            html = text(raw)
        except Exception as e:
            L.append(f'  {page} → X({str(e)[:50]})')
            continue
        L.append(f'  {page} → {st} ({final}) · 글자 수 {len(html)}')
        if len(html) < 800:
            L.append('    (페이지 전체) ' + re.sub(r'\s+', ' ', html)[:700])
        # iframe · 스크립트
        frames = [urllib.parse.urljoin(final, s) for s in re.findall(r'<iframe[^>]+src=["\']([^"\']+)', html, re.I)]
        scripts = [urllib.parse.urljoin(final, s) for s in re.findall(r'<script[^>]+src=["\']([^"\']+)', html, re.I)]
        for f in frames[:5]:
            L.append(f'    iframe {f}')
        sources = [('페이지', final, html)]
        for u in frames[:3] + [s for s in scripts if urllib.parse.urlparse(s).netloc == urllib.parse.urlparse(final).netloc][:8]:
            try:
                _, f2, _, r2 = get(u, timeout=12, referer=final)
                sources.append((u.split('/')[-1][:40] or u, f2, text(r2)))
            except Exception:
                pass
        seen = set()
        for label, base, body in sources:
            for m in STREAM.finditer(body):
                u = m.group(0)
                u = ('https:' + u) if u.startswith('//') else u
                if u in seen:
                    continue
                seen.add(u)
                L.append(f'    [{label}] 주소 {test_stream(u, final)} | {u}')
            for m in list(HINT.finditer(body))[:6]:
                ctx_ = re.sub(r'\s+', ' ', body[max(0, m.start() - 120): m.end() + 160])
                L.append(f'    [{label}] 단서 … {ctx_}')
    return L


out = []
with cf.ThreadPoolExecutor(4) as ex:
    for L in ex.map(scan, PAGES):
        for l in L:
            print(l)
            out.append(l)

with open('radio_probe23_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe23_result.txt 를 올려 주세요')
