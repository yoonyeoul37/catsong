# -*- coding: utf-8 -*-
# 부산MBC 2차: 생방송 페이지(짧은 563글자)가 어디로 보내는지 따라가서 방송 주소 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe37.py  →  radio_probe37_result.txt
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


def get(url, n=None, referer='https://busanmbc.co.kr/', timeout=20):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': referer}), timeout=timeout, context=ctx())
    raw = r.read(n) if n else r.read()
    t = None
    for enc in ('utf-8', 'euc-kr'):
        try:
            t = raw.decode(enc)
            break
        except Exception:
            pass
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), t or raw.decode('utf-8', 'replace')


STREAM = re.compile(r'(?:https?:)?//[^\s"\'<>\\]+?(?:\.m3u8|\.sdp|/playlist|\.pls|\.aac|\.mp3)(?:\?[^\s"\'<>\\]*)?', re.I)


def test(url):
    try:
        st, final, ct, t = get(url, 3000, timeout=25)
        ok = '#EXTM3U' in t or 'audio' in ct
        return f'{"OK" if ok else "?"} {st} {ct[:30]} | {re.sub(chr(10), " / ", t[:200])}'
    except Exception as e:
        return f'X {str(e)[:80]}'


todo = ['https://busanmbc.co.kr/06_oar/oar02.asp', 'https://busanmbc.co.kr/06_oar/oar03.asp',
        'https://m.busanmbc.co.kr/', 'https://busanmbc.co.kr/m/index.asp']
seen = set()
while todo and len(seen) < 15:
    u = todo.pop(0)
    if u in seen:
        continue
    seen.add(u)
    try:
        st, final, ct, t = get(u)
    except Exception as e:
        log(f'■ {u} → X {str(e)[:60]}')
        continue
    log(f'■ {u} → {st} {final} · 글자 수 {len(t)}')
    if len(t) < 3000:
        log('  (전체) ' + re.sub(r'\s+', ' ', t))
    for f in sorted(set(m.group(0) for m in STREAM.finditer(t)))[:8]:
        v = ('https:' + f) if f.startswith('//') else f
        log(f'  방송 주소 {v} → {test(v)}')
    # 다음으로 따라갈 곳: location.href / window.open / iframe / 라디오 관련 링크
    for h in re.findall(r'(?:location\.href|location\.replace|window\.open)\s*\(?\s*=?\s*["\']([^"\']+)["\']|<iframe[^>]+src=["\']([^"\']+)', t):
        v = urllib.parse.urljoin(final, h[0] or h[1])
        todo.append(v)
        log(f'  → 따라감 {v}')
    for h in re.findall(r'href=["\']([^"\']*(?:radio|Radio|onair|OnAir|live|Live|fm|FM)[^"\']*)["\']', t)[:10]:
        v = urllib.parse.urljoin(final, h)
        if 'busanmbc' in v or 'bsmbc' in v:
            todo.append(v)

log('■ 지금 주소 한 번 더 (기다리는 시간 늘려서) · http 로도')
for u in ['https://stream.bsmbc.com/live/BusanMBC_AM_onairstream.sbhhqc/playlist.m3u8',
          'http://stream.bsmbc.com/live/BusanMBC_AM_onairstream.sbhhqc/playlist.m3u8',
          'https://stream.bsmbc.com/live/mp4:BusanMBC.Live-FM-0415/playlist.m3u8',
          'http://stream.bsmbc.com:1935/live/mp4:BusanMBC.Live-FM-0415/playlist.m3u8']:
    log(f'  {u} → {test(u)}')

with open('radio_probe37_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe37_result.txt 를 올려 주세요')
