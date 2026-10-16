# -*- coding: utf-8 -*-
# 부산MBC 표준FM · FM4U 소리 안 나오는 이유 찾기: 지금 주소 확인 + 홈페이지 생방송 화면의 새 주소 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe36.py  →  radio_probe36_result.txt
import re, ssl, urllib.request, urllib.parse

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


def get(url, n=None, referer='https://busanmbc.co.kr/'):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': referer}), timeout=15, context=ctx())
    raw = r.read(n) if n else r.read()
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), raw


def text(raw):
    for enc in ('utf-8', 'euc-kr'):
        try:
            return raw.decode(enc)
        except Exception:
            pass
    return raw.decode('utf-8', 'replace')


def test(url):
    try:
        st, final, ct, raw = get(url, 3000)
        t = raw[:600].decode('latin-1', 'ignore')
        ok = '#EXTM3U' in t or 'audio' in ct
        return f'{"OK" if ok else "?"} {st} {ct[:30]} | {re.sub(chr(10), " / ", t[:250])}'
    except Exception as e:
        return f'X {str(e)[:80]}'


log('■ 1) 앱에 있는 지금 주소')
for name, u in [('표준FM', 'https://stream.bsmbc.com/live/BusanMBC_AM_onairstream.sbhhqc/playlist.m3u8'),
                ('FM4U', 'https://stream.bsmbc.com/live/mp4:BusanMBC.Live-FM-0415/playlist.m3u8')]:
    log(f'  {name}: {test(u)}')

log('■ 2) 홈페이지 생방송 화면에서 새 주소 찾기')
STREAM = re.compile(r'(?:https?:)?//[^\s"\'<>\\]+?(?:\.m3u8|\.sdp|/playlist|\.pls|\.aac|\.mp3)(?:\?[^\s"\'<>\\]*)?', re.I)
pages = ['https://busanmbc.co.kr/index.asp']
try:
    _, final, _, raw = get(pages[0])
    t = text(raw)
    for m in re.finditer(r'RadioShow|onair|OnAir|radio_pop|live', t):
        log('  [홈 단서] … ' + re.sub(r'\s+', ' ', t[max(0, m.start() - 150): m.end() + 250]))
        if len(out) > 40:
            break
    for h in re.findall(r'(?:href|src|open\()\s*=?\s*["\']([^"\']*(?:onair|OnAir|radio|live|oar0)[^"\']*)["\']', t)[:20]:
        v = urllib.parse.urljoin(final, h)
        if v not in pages:
            pages.append(v)
    for s in re.findall(r'<script[^>]+src=["\']([^"\']+)', t):
        v = urllib.parse.urljoin(final, s)
        if 'busanmbc' in v and v not in pages:
            pages.append(v)
except Exception as e:
    log(f'  홈 못 가져옴 {e}')
pages += ['https://busanmbc.co.kr/06_oar/oar01.asp', 'https://busanmbc.co.kr/06_oar/oar02.asp', 'https://busanmbc.co.kr/06_oar/oar03.asp']
seen = set()
for p in pages[:30]:
    if p in seen:
        continue
    seen.add(p)
    try:
        st, final, ct, raw = get(p)
        t = text(raw)
    except Exception as e:
        log(f'  {p} → X {str(e)[:50]}')
        continue
    found = sorted(set(m.group(0) for m in STREAM.finditer(t)))
    log(f'  {p} → {st} · 글자 수 {len(t)} · 주소 {len(found)}개')
    for f in found[:8]:
        u = ('https:' + f) if f.startswith('//') else f
        log(f'     {u}  →  {test(u)}')

with open('radio_probe36_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe36_result.txt 를 올려 주세요')
