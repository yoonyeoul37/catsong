# -*- coding: utf-8 -*-
# 수도권 + 미국 한인 라디오: 방송 주소 찾기 + 소리 나오는지 확인
#  1) Radio Browser(공개 라디오 목록)에서 이름으로 찾기
#  2) 방송국 공식 홈페이지에서 방송 주소 찾기
#  3) 찾은 주소마다 실제로 소리가 오는지 확인 → '수도권 방송 찾기 결과.txt'
# 인터넷만 되면 됨 (설치할 것 없음)
import json, re, ssl, sys, urllib.parse, urllib.request

UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'
CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

# 방송: (이름, Radio Browser 검색어들, 공식 홈페이지들)
TARGETS = [
    ('WBS 원음방송 서울 89.7', ['원음', 'WBS'], ['https://www.wbsi.kr/', 'https://wbsi.kr/onair/']),
    ('관악FM 100.3', ['관악', 'GFM'], ['https://www.radiogfm.net/', 'http://radiogfm.net/']),
    ('성남FM 90.7', ['성남', 'Seongnam', 'Bundang'], ['https://cradio.kr/seongnamfm/', 'https://www.snfm.kr/']),
    ('서대문FM(MyFM) 91.3', ['서대문', 'MyFM', 'Seodaemun'], ['https://www.sdmradio.net/']),
    ('구리FM 105.7', ['구리', 'Guri'], ['https://www.gurifm.com/', 'https://gurifm.kr/']),
    ('라디오코리아 AM1540 (LA)', ['Radio Korea', 'KMPC', '라디오코리아'], ['https://www.radiokorea.com/']),
    ('라디오서울 AM1650 (LA)', ['Radio Seoul', 'KFOX', '라디오서울'], ['https://www.radioseoul1650.com/', 'https://radioseoul.com/']),
]

API = 'https://de1.api.radio-browser.info/json/stations/byname/'
URL_RE = re.compile(r'''https?://[^\s"'<>\\]+?(?:\.m3u8|\.pls|\.m3u|\.mp3|\.aac|/;|:\d{3,5}/[^\s"'<>\\]*)''', re.I)


def get(url, n=200000, timeout=10):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=timeout, context=CTX) as r:
        return r.headers.get('Content-Type', ''), r.read(n)


def from_browser(term):
    out = []
    try:
        _, b = get(API + urllib.parse.quote(term) + '?limit=30')
        for s in json.loads(b.decode('utf-8', 'ignore')):
            cc = (s.get('countrycode') or '').upper()
            if cc not in ('KR', 'US', ''):
                continue
            u = s.get('url_resolved') or s.get('url') or ''
            if u:
                out.append((s.get('name', '').strip(), u))
    except Exception as e:
        print('   (목록 검색 실패: %s)' % e)
    return out


def from_page(url):
    try:
        _, b = get(url)
        t = b.decode('utf-8', 'ignore')
        return sorted(set(m.group(0) for m in URL_RE.finditer(t)))
    except Exception:
        return []


def check(url, depth=0):
    """소리가 오면 (True, 설명)"""
    try:
        ct, b = get(url, n=8192, timeout=10)
        head = b[:2000].decode('utf-8', 'ignore')
        if '#EXTM3U' in head:
            return True, 'HLS(m3u8) 응답'
        if ('[playlist]' in head.lower() or url.lower().endswith(('.pls', '.m3u'))) and depth == 0:
            inner = re.findall(r'https?://\S+', head)
            for u in inner[:3]:
                ok, why = check(u.strip(), 1)
                if ok:
                    return True, '목록 파일 → ' + u.strip()
            return False, '목록 파일인데 안쪽 주소가 안 나옴'
        if ct.startswith(('audio/', 'application/ogg', 'video/mp2t')) or 'mpeg' in ct or 'aac' in ct:
            return True, '소리 응답 (%s)' % ct
        if len(b) >= 4000 and not head.lstrip().startswith('<'):
            return True, '데이터 응답 (%s)' % (ct or '종류 모름')
        return False, '소리가 아님 (%s)' % (ct or '빈 응답')
    except Exception as e:
        return False, '연결 안 됨 (%s)' % str(e)[:60]


def main():
    lines = []
    for name, terms, pages in TARGETS:
        print('\n■ ' + name)
        lines.append('■ ' + name)
        cands = []
        for t in terms:
            for n, u in from_browser(t):
                cands.append(('목록:' + n, u))
        for p in pages:
            for u in from_page(p):
                cands.append(('홈페이지:' + p, u))
        seen, found = set(), 0
        for src, u in cands:
            if u in seen:
                continue
            seen.add(u)
            ok, why = check(u)
            mark = '✔' if ok else '❌'
            row = '  %s %s\n      %s · %s' % (mark, u, src, why)
            print(row)
            lines.append(row)
            found += ok
        if not cands:
            print('  ❌ 주소를 못 찾았어요')
            lines.append('  ❌ 주소를 못 찾았어요')
        elif not found:
            lines.append('  (소리 나오는 주소 없음)')
        lines.append('')
    with open('수도권 방송 찾기 결과.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print('\n✔ 다 됐어요 → "수도권 방송 찾기 결과.txt" 를 보내 주세요')


main()
