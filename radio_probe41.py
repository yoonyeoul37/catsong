# -*- coding: utf-8 -*-
# 춘천MBC 표준FM · 울산MBC 새 방송 주소 확인 (앱 코드는 안 건드려요)
# 실행: python radio_probe41.py  →  radio_probe41_result.txt
import re, ssl, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'
out = []


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    return c


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, n=None, ref=None):
    h = {'User-Agent': UA}
    if ref:
        h['Referer'] = ref
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=15, context=ctx())
    raw = r.read(n) if n else r.read()
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), raw


def first_uri(text, base):
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            return urllib.parse.urljoin(base, line)


def check(url):
    try:
        st, final, ct, raw = get(url, 100000)
        head = raw[:4000].decode('utf-8', 'ignore')
        if '#EXTM3U' not in head:
            return f'X m3u8 아님 ({st} {ct[:20]})'
        nxt = first_uri(head, final)
        if '#EXT-X-STREAM-INF' in head:
            _, f2, _, r2 = get(nxt, 100000)
            nxt = first_uri(r2[:4000].decode('utf-8', 'ignore'), f2)
        _, _, ct3, seg = get(nxt, 20000)
        return f'OK 소리 조각 {len(seg)}바이트 ({ct3[:20]})' if len(seg) > 500 else f'X 조각 작음 {len(seg)}'
    except Exception as e:
        return f'X {str(e)[:60]}'


STREAM = re.compile(r'(?:https?:)?//[^\s"\'<>\\]+?(?:\.m3u8|/playlist)(?:\?[^\s"\'<>\\]*)?', re.I)

log('■ 춘천MBC: 홈페이지에 있던 주소 + .m3u8 붙여 보기')
for u in ['https://stream.chmbc.co.kr/radio1/fm1_aac/playlist.m3u8', 'https://stream.chmbc.co.kr/live_radio2/fm1_aac/playlist.m3u8',
          'https://stream.chmbc.co.kr/radio1/fm2_aac/playlist.m3u8', 'https://stream.chmbc.co.kr/radio2/fm1_aac/playlist.m3u8',
          'https://stream.chmbc.co.kr/radio1/fm1/playlist.m3u8', 'https://stream.chmbc.co.kr/live_radio/fm2_aac/playlist.m3u8']:
    log(f'  {u} → {check(u)}')
log('■ 춘천MBC: 홈페이지 재생 스크립트(player.js)와 홈 화면에서 어느 주소가 표준FM/음악FM인지')
for p in ['https://cdn.jsdelivr.net/gh/puzzlecompany/chmbc-assets@97938f1/js/player.js', 'https://chmbc.co.kr/']:
    try:
        _, _, _, raw = get(p, ref='https://chmbc.co.kr/')
        t = raw.decode('utf-8', 'ignore')
        for m in re.finditer(r'stream\.chmbc\.co\.kr[^\s"\'<>]*', t):
            log(f'  [{p.split("/")[-1] or "홈"}] … ' + re.sub(r'\s+', ' ', t[max(0, m.start() - 250): m.end() + 80]))
    except Exception as e:
        log(f'  {p} → X {str(e)[:50]}')

log('■ 울산MBC: 생방송 페이지(표준FM · FM4U)의 주소')
for p in ['https://www.usmbc.co.kr/OnAir/FM', 'https://www.usmbc.co.kr/OnAir/FM4U']:
    try:
        _, final, _, raw = get(p, ref='https://www.usmbc.co.kr/')
        t = raw.decode('utf-8', 'ignore')
        found = sorted(set(m.group(0) for m in STREAM.finditer(t)))
        log(f'  {p} → 주소 {len(found)}개')
        for f in found:
            v = ('https:' + f) if f.startswith('//') else f
            log(f'     {v} → {check(v)}')
            if not v.endswith('.m3u8'):
                log(f'     {v}.m3u8 → {check(v + ".m3u8")}')
    except Exception as e:
        log(f'  {p} → X {str(e)[:50]}')

with open('radio_probe41_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe41_result.txt 를 올려 주세요')
