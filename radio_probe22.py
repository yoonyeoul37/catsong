# -*- coding: utf-8 -*-
# 국내 방송 주소 더 찾기 (앱 코드는 안 건드려요)
#  1) 지방 TBN · 지방 극동방송: 이미 아는 주소 모양에 지역 이름만 바꿔서 실제로 나오는지
#  2) 지역 민방 · 지방 CBS 등: 홈페이지 온에어 화면 안의 방송 주소(m3u8) 찾기
# 실행: python radio_probe22.py  →  radio_probe22_result.txt 가 생겨요 (몇 분 걸려요)
import re, ssl, urllib.request, urllib.parse, concurrent.futures as cf

UA = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36'
out = []


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, n=None, timeout=12, referer=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=timeout, context=ctx())
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), (r.read(n) if n else r.read())


def test_stream(url):
    try:
        st, final, ct, head = get(url, 2048, 10)
        txt = head[:300].decode('latin-1', 'ignore')
        ok = st == 200 and ('#EXTM3U' in txt or 'audio' in ct or 'mpegurl' in ct.lower())
        return 'OK' if ok else f'?({st} {ct[:25]})'
    except Exception as e:
        return f'X({str(e)[:45]})'


# ── 1) 주소 모양 맞춰 보기 ──
tbn = ['busan', 'daegu', 'gwangju', 'daejeon', 'gangwon', 'jeonbuk', 'gyeongnam', 'chungbuk', 'chungnam', 'jeju',
       'gyeongbuk', 'jeonnam', 'seoul', 'gyeongin', 'ulsan']
febc = ['seoul', 'jeju', 'busan', 'daegu', 'gwangju', 'daejeon', 'changwon', 'ulsan', 'pohang', 'mokpo', 'yeongdong',
        'gangwon', 'jeonbuk', 'jeonju', 'suncheon', 'yeosu', 'chuncheon', 'cheongju', 'gyeongin', 'incheon']
cands = [('TBN ' + r, f'http://radio2.tbn.or.kr:1935/{r}/myStream/playlist.m3u8') for r in tbn]
cands += [('극동방송 ' + r, f'http://mlive2.febc.net:1935/live/{r}fm/playlist.m3u8') for r in febc]
cands += [('극동방송 ' + r + ' (am)', f'http://mlive2.febc.net:1935/live/{r}am/playlist.m3u8') for r in ['seoul']]
log('■ 1) 주소 모양 맞춰 보기')
with cf.ThreadPoolExecutor(10) as ex:
    for (name, url), res in zip(cands, ex.map(lambda c: test_stream(c[1]), cands)):
        log(f'  {res} | {name} | {url}')

# ── 2) 홈페이지 안의 방송 주소 찾기 ──
sites = [
    ('KNN 부산', ['https://www.knn.co.kr/', 'https://m.knn.co.kr/']),
    ('TBC 대구', ['https://www.tbc.co.kr/', 'https://m.tbc.co.kr/']),
    ('KBC 광주', ['https://www.ikbc.co.kr/', 'https://m.ikbc.co.kr/']),
    ('TJB 대전', ['https://www.tjb.co.kr/']),
    ('UBC 울산', ['https://www.ubc.co.kr/']),
    ('CJB 청주', ['https://www.cjb.co.kr/']),
    ('G1 강원', ['https://www.g1tv.co.kr/']),
    ('JIBS 제주', ['https://www.jibs.co.kr/']),
    ('전주MBC', ['https://www.jmbc.co.kr/']),
    ('여수MBC', ['https://www.ysmbc.co.kr/']),
    ('원주MBC', ['https://www.wjmbc.co.kr/']),
    ('MBC강원영동', ['https://www.mbceg.co.kr/']),
    ('부산CBS', ['https://busan.cbs.co.kr/']),
    ('원음방송', ['https://www.wbsi.kr/', 'http://www.wbsi.kr/']),
    ('GFN 광주영어방송', ['https://www.gfn.or.kr/']),
]
STREAM = re.compile(r'(https?:)?//[^\s"\'<>]+?\.m3u8[^\s"\'<>]*|(https?:)?//[^\s"\'<>]+?(?:\.pls|/listen|/stream)[^\s"\'<>]*', re.I)
log('■ 2) 홈페이지 안의 방송 주소')


def scan(site):
    name, homes = site
    lines = [f'  ── {name}']
    for home in homes:
        try:
            st, final, ct, raw = get(home, timeout=15)
            html = raw.decode('utf-8', 'replace')
        except Exception as e:
            lines.append(f'    {home} → X({str(e)[:50]})')
            continue
        lines.append(f'    {home} → {st} · 글자 수 {len(html)}')
        found = sorted(set(m.group(0) for m in STREAM.finditer(html)))
        links = sorted(set(urllib.parse.urljoin(final, h) for h in re.findall(r'href=["\']([^"\'#]+)["\']', html)
                           if re.search(r'onair|on_air|live|radio|라디오|fm', h, re.I)))[:12]
        for f in found[:10]:
            u = ('https:' + f) if f.startswith('//') else f
            lines.append(f'    주소 후보 {test_stream(u)} | {u}')
        for l in links:
            lines.append(f'    온에어·라디오 링크 {l}')
        # 온에어 링크 한 단계 더 들어가서 주소 찾기
        for l in links[:4]:
            try:
                _, _, _, raw2 = get(l, timeout=12, referer=final)
                h2 = raw2.decode('utf-8', 'replace')
            except Exception:
                continue
            for f in sorted(set(m.group(0) for m in STREAM.finditer(h2)))[:6]:
                u = ('https:' + f) if f.startswith('//') else f
                lines.append(f'      └ {l} 안 주소 {test_stream(u)} | {u}')
        if found or links:
            break
    return lines


with cf.ThreadPoolExecutor(5) as ex:
    for lines in ex.map(scan, sites):
        for l in lines:
            log(l)

with open('radio_probe22_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe22_result.txt 를 올려 주세요')
