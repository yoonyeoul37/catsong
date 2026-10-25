# -*- coding: utf-8 -*-
# 수도권 방송 주소 찾기 2차 (1차에서 못 찾은 것)
#  - Radio Browser는 한국(KR) 방송만
#  - 공식 홈페이지 + 그 안의 '온에어·듣기·라이브' 링크·자바스크립트 파일까지 한 단계 더 들어가서 찾기
#  - 짧은 주소(bit.ly 등)는 끝까지 따라가기
#  - 공동체라디오가 쓰는 주소 모양(radiostream.communityradio.kr/○○1 등)도 시험
#  → '수도권 방송 찾기 결과 2.txt'
import json, re, ssl, urllib.parse, urllib.request

UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'
CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

CR = 'http://radiostream.communityradio.kr/'
IP = 'http://115.85.182.39/'
TARGETS = [
    ('WBS 원음방송 서울 89.7', ['원음', 'WBS 원음'],
     ['http://www.wbsi.kr/', 'https://www.wbsi.kr/', 'https://m.wbsi.kr/'], []),
    ('관악FM 100.3', ['관악'],
     ['http://www.radiogfm.net/', 'https://gwanakfm.com/', 'http://www.gfm.kr/'],
     [CR + 'gfm1', CR + 'gafm1', IP + 'gfm', IP + 'gwanakfm']),
    ('성남FM 90.7', ['성남'],
     ['https://cradio.kr/seongnamfm/', 'http://www.snfm.kr/', 'https://snfm.kr/'],
     [CR + 'snfm1', IP + 'snfm', IP + 'sbnfm']),
    ('서대문FM(MyFM) 91.3', ['서대문'],
     ['http://bit.ly/sdmfmnow', 'https://www.sdmradio.net/'],
     [CR + 'sdmfm1', IP + 'sdmfm', IP + 'myfm']),
    ('구리FM 105.7', ['구리'],
     ['http://www.gurifm.co.kr/', 'https://gurifm.co.kr/', 'http://gurifm.com/'],
     [CR + 'gurifm1', CR + 'grfm1', IP + 'gurifm']),
    ('광주FM 88.9 (공동체, 덤)', ['광주FM'], ['https://kjfm.communityradio.kr/'], [CR + 'kjfm1']),
    ('단원FM (안산 공동체, 덤)', ['단원'], ['https://dwfm.communityradio.kr/'], [CR + 'dwfm1']),
    ('라디오코리아 AM1540 (LA)', [],
     ['https://www.radiokorea.com/', 'https://radio.radiokorea.com/', 'https://www.radiokorea.com/radio/'], []),
]

API = 'https://de1.api.radio-browser.info/json/stations/search?countrycode=KR&limit=40&name='
STREAM_RE = re.compile(r'''https?://[^\s"'<>\\]+?(?:\.m3u8|\.pls|\.m3u|\.mp3|\.aac|/;|:\d{3,5}/[^\s"'<>\\]*)''', re.I)
LINK_RE = re.compile(r'''(?:href|src)\s*=\s*["']([^"']+)["']''', re.I)
HINT = ('onair', 'on_air', 'live', 'listen', 'player', 'radio', 'stream', '듣기', 'play')


def get(url, n=300000, timeout=10):
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=timeout, context=CTX) as r:
        return r.geturl(), r.headers.get('Content-Type', ''), r.read(n)


def scan(url, depth=0, seen=None):
    seen = seen if seen is not None else set()
    if url in seen or len(seen) > 25:
        return set()
    seen.add(url)
    found = set()
    try:
        final, ct, b = get(url)
    except Exception:
        return found
    if final != url and STREAM_RE.fullmatch(final):
        found.add(final)
    t = b.decode('utf-8', 'ignore')
    found |= set(m.group(0) for m in STREAM_RE.finditer(t))
    if depth < 1:
        for l in LINK_RE.findall(t):
            u = urllib.parse.urljoin(final, l)
            low = u.lower()
            if low.endswith('.js') or any(h in low for h in HINT):
                if not re.search(r'\.(png|jpg|gif|css|svg|ico|woff2?)(\?|$)', low):
                    found |= scan(u, depth + 1, seen)
    return found


def browser(term):
    out = []
    try:
        _, _, b = get(API + urllib.parse.quote(term))
        for s in json.loads(b.decode('utf-8', 'ignore')):
            u = s.get('url_resolved') or s.get('url') or ''
            if u:
                out.append((s.get('name', '').strip(), u))
    except Exception:
        pass
    return out


def check(url, depth=0):
    try:
        final, ct, b = get(url, n=8192, timeout=10)
        head = b[:2000].decode('utf-8', 'ignore')
        if '#EXTM3U' in head:
            return True, 'HLS(m3u8)'
        if ('[playlist]' in head.lower() or url.lower().split('?')[0].endswith(('.pls', '.m3u'))) and depth == 0:
            for u in re.findall(r'https?://\S+', head)[:3]:
                ok, why = check(u.strip(), 1)
                if ok:
                    return True, '목록 파일 → ' + u.strip()
            return False, '목록 파일 안 주소가 안 나옴'
        if ct.startswith(('audio/', 'application/ogg', 'video/mp2t')) or 'mpeg' in ct or 'aac' in ct:
            return True, '소리 (%s)' % ct
        if len(b) >= 4000 and not head.lstrip().startswith('<'):
            return True, '데이터 (%s)' % (ct or '종류 모름')
        return False, '소리 아님 (%s)' % (ct or '빈 응답')
    except Exception as e:
        return False, '연결 안 됨 (%s)' % str(e)[:60]


def main():
    lines = []
    for name, terms, pages, guesses in TARGETS:
        print('\n■ ' + name)
        lines.append('■ ' + name)
        cands = []
        for t in terms:
            cands += [('목록:' + n, u) for n, u in browser(t)]
        for p in pages:
            cands += [('홈페이지:' + p, u) for u in sorted(scan(p))]
        cands += [('추측', u) for u in guesses]
        seen, good = set(), 0
        for src, u in cands:
            if u in seen:
                continue
            seen.add(u)
            ok, why = check(u)
            row = '  %s %s\n      %s · %s' % ('✔' if ok else '❌', u, src, why)
            print(row)
            lines.append(row)
            good += ok
        if not good:
            lines.append('  (소리 나오는 주소 없음)')
        lines.append('')
    with open('수도권 방송 찾기 결과 2.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print('\n✔ 다 됐어요 → "수도권 방송 찾기 결과 2.txt" 를 보내 주세요')


main()
