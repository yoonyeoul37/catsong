# -*- coding: utf-8 -*-
# MBC 소리 문제 2차 (앱 코드는 안 건드려요)
#  1) 제주MBC: 컴퓨터에선 되는데 앱에선 안 됨 → 앱이 붙여 보내는 'Referer/Origin: imbc.com' 때문인지 시험
#  2) 춘천MBC 표준FM · 울산MBC 표준FM: 주소가 404 → 홈페이지 생방송 화면에서 새 주소 찾기
# 실행: python radio_probe40.py  →  radio_probe40_result.txt
import re, ssl, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'
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


def get(url, n=None, headers=None, timeout=12):
    h = {'User-Agent': UA}
    h.update(headers or {})
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=timeout, context=ctx())
    raw = r.read(n) if n else r.read()
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), raw


def first_uri(text, base):
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            return urllib.parse.urljoin(base, line)


def check(url, headers=None):
    try:
        st, final, ct, raw = get(url, 100000, headers)
        head = raw[:4000].decode('utf-8', 'ignore')
        if '#EXTM3U' not in head:
            return f'X m3u8 아님 ({st} {ct[:20]})'
        nxt = first_uri(head, final)
        if '#EXT-X-STREAM-INF' in head:
            _, f2, _, r2 = get(nxt, 100000, headers)
            nxt = first_uri(r2[:4000].decode('utf-8', 'ignore'), f2)
        _, _, ct3, seg = get(nxt, 20000, headers)
        return f'OK 소리 조각 {len(seg)}바이트' if len(seg) > 500 else f'X 조각 작음 {len(seg)}'
    except Exception as e:
        return f'X {str(e)[:60]}'


IMBC = {'Referer': 'https://www.imbc.com/', 'Origin': 'https://www.imbc.com'}
log('■ 1) 앱처럼 imbc.com 표시를 붙였을 때 vs 안 붙였을 때 (지역 MBC 전부)')
for name, u in [('제주MBC 표준FM', 'https://wowza.jejumbc.com/live/_definst_/mp3:radio1/playlist.m3u8'),
                ('제주MBC FM4U', 'https://wowza.jejumbc.com/live/_definst_/mp3:radio2/playlist.m3u8'),
                ('춘천MBC FM4U', 'https://stream.chmbc.co.kr/live_radio2/fm1/playlist.m3u8'),
                ('안동MBC 표준FM', 'https://live.andongmbc.co.kr/live/amlive/playlist.m3u8'),
                ('광주MBC 표준FM', 'https://media.kjmbc.co.kr/hls/amlive/GWANGJU-MBC-AM/playlist.m3u8'),
                ('목포MBC 표준FM', 'https://vod.mpmbc.co.kr/live/encoder-am/playlist.m3u8'),
                ('대전MBC 표준FM', 'https://ns1.tjmbc.co.kr/live_am/live_am.stream/playlist.m3u8'),
                ('대구MBC 표준FM', 'https://5ee1ec6f32118.streamlock.net/amradio/am/playlist.m3u8'),
                ('전주MBC 표준FM', 'https://live.jmbc.co.kr/live/am_live.m3u8')]:
    log(f'  {name}: 표시 없음 → {check(u)}  |  imbc 표시 → {check(u, IMBC)}')

STREAM = re.compile(r'(?:https?:)?//[^\s"\'<>\\]+?(?:\.m3u8|\.sdp|/playlist)(?:\?[^\s"\'<>\\]*)?', re.I)


def hunt(name, pages, guesses):
    log(f'■ {name}: 새 주소 찾기')
    seen = set()
    for p in pages:
        try:
            _, final, _, raw = get(p, headers={'Referer': p})
            t = raw.decode('utf-8', 'ignore')
        except Exception as e:
            log(f'  {p} → X {str(e)[:50]}')
            continue
        found = sorted(set(m.group(0) for m in STREAM.finditer(t)))
        log(f'  {p} → 글자 수 {len(t)} · 주소 {len(found)}개')
        for f in found:
            v = ('https:' + f) if f.startswith('//') else f
            if v not in seen:
                seen.add(v)
                log(f'     {v} → {check(v)}')
        for h in re.findall(r'(?:href|src)=["\']([^"\']*(?:onair|OnAir|live|Live|radio2|STDFM|player)[^"\']*)["\']', t)[:8]:
            log(f'     링크 {urllib.parse.urljoin(final, h)}')
    for v in guesses:
        if v not in seen:
            log(f'  [추측] {v} → {check(v)}')


hunt('춘천MBC 표준FM',
     ['https://chmbc.co.kr/', 'https://chmbc.co.kr/onair/radio2', 'https://chmbc.co.kr/onair/radio', 'https://chmbc.co.kr/onair'],
     ['https://stream.chmbc.co.kr/live_radio2/fm2/playlist.m3u8', 'https://stream.chmbc.co.kr/live_radio/fm1/playlist.m3u8',
      'https://stream.chmbc.co.kr/live_radio1/fm2/playlist.m3u8', 'https://stream.chmbc.co.kr/live_radio3/fm2/playlist.m3u8',
      'https://stream.chmbc.co.kr/live_radio/am/playlist.m3u8', 'https://stream.chmbc.co.kr/live_radio2/fm/playlist.m3u8'])
hunt('울산MBC 표준FM',
     ['https://www.usmbc.co.kr/OnAir', 'https://www.usmbc.co.kr/'],
     ['https://5ddfd163bd00d.streamlock.net/STDFM/STDFM.stream/playlist.m3u8', 'https://5ddfd163bd00d.streamlock.net/STDFM/_definst_/STDFM/playlist.m3u8',
      'https://5ddfd163bd00d.streamlock.net/FM4U/FM4U/playlist.m3u8', 'https://5ddfd163bd00d.streamlock.net/STFM/STFM/playlist.m3u8'])

with open('radio_probe40_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe40_result.txt 를 올려 주세요')
