# -*- coding: utf-8 -*-
# 제주MBC: 앱이 소리를 못 내는 이유 찾기 — 소리 조각 안이 실제로 무슨 형식인지 + 다른 주소(공식 생방송 페이지·aac) 찾기
# (앱 코드는 안 건드려요)   실행: python radio_probe42.py  →  radio_probe42_result.txt
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


def get(url, n=None):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://jejumbc.com/'}),
                               timeout=15, context=ctx())
    raw = r.read(n) if n else r.read()
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), raw


def first_uri(text, base):
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            return urllib.parse.urljoin(base, line)


def kind(b):
    # 소리 조각 앞부분으로 형식 맞히기
    if b[:1] == b'\x47':
        return 'MPEG-TS (ts 묶음)'
    if b[:3] == b'ID3':
        return 'ID3 꼬리표 + ' + kind(b[10 + ((b[6] & 0x7f) << 21 | (b[7] & 0x7f) << 14 | (b[8] & 0x7f) << 7 | (b[9] & 0x7f)):]) if len(b) > 20 else 'ID3'
    if b[:2] in (b'\xff\xf1', b'\xff\xf9'):
        return 'AAC(ADTS)'
    if b[:2] in (b'\xff\xfb', b'\xff\xfa', b'\xff\xf3', b'\xff\xf2', b'\xff\xe3'):
        return 'MP3'
    return '모름 ' + b[:8].hex()


def look(url):
    try:
        st, final, ct, raw = get(url, 100000)
        head = raw[:4000].decode('utf-8', 'ignore')
        if '#EXTM3U' not in head:
            return f'X m3u8 아님 ({st} {ct[:20]})'
        lines = ' / '.join(l for l in head.splitlines()[:8])
        nxt = first_uri(head, final)
        if '#EXT-X-STREAM-INF' in head:
            _, f2, _, r2 = get(nxt, 100000)
            h2 = r2[:4000].decode('utf-8', 'ignore')
            lines += ' ‖ ' + ' / '.join(h2.splitlines()[:8])
            nxt = first_uri(h2, f2)
        _, _, ct3, seg = get(nxt, 30000)
        return f'OK 조각 {len(seg)}바이트 · 서버가 말한 형식 {ct3} · 실제 형식 {kind(seg)}\n       목록: {lines[:400]}'
    except Exception as e:
        return f'X {str(e)[:60]}'


log('■ 1) 지금 주소 (소리 조각 안 형식)')
for u in ['https://wowza.jejumbc.com/live/_definst_/mp3:radio1/playlist.m3u8',
          'https://wowza.jejumbc.com/live/_definst_/mp3:radio2/playlist.m3u8']:
    log(f'  {u}\n     → {look(u)}')
log('■ 2) 비슷한 다른 주소')
for name in ['radio1', 'radio2', 'aac:radio1', 'aac:radio2', 'mp4:radio1', 'mp4:radio2']:
    for app in ['live/_definst_', 'live']:
        u = f'https://wowza.jejumbc.com/{app}/{name}/playlist.m3u8'
        log(f'  {u}\n     → {look(u)}')
log('■ 3) 제주MBC 생방송 페이지의 공식 주소')
STREAM = re.compile(r'(?:https?:)?//[^\s"\'<>\\]+?(?:\.m3u8|/playlist)(?:\?[^\s"\'<>\\]*)?', re.I)
for p in ['https://jejumbc.com/OnAir', 'https://jejumbc.com/OnAir/FM', 'https://jejumbc.com/OnAir/FM4U', 'https://jejumbc.com/']:
    try:
        _, final, _, raw = get(p)
        t = raw.decode('utf-8', 'ignore')
        found = sorted(set(m.group(0) for m in STREAM.finditer(t)))
        log(f'  {p} → 주소 {len(found)}개')
        for f in found:
            v = ('https:' + f) if f.startswith('//') else f
            v2 = v if v.endswith('.m3u8') else v + '.m3u8'
            log(f'     {v2}\n       → {look(v2)}')
    except Exception as e:
        log(f'  {p} → X {str(e)[:50]}')

with open('radio_probe42_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe42_result.txt 를 올려 주세요')
