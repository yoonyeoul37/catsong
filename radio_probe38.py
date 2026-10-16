# -*- coding: utf-8 -*-
# MBC경남 표준FM 소리 안 나오는 이유 찾기: 지금 주소 확인 + 홈페이지 생방송 화면의 주소 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe38.py  →  radio_probe38_result.txt
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


def get(url, n=None, referer='https://mbcgn.kr/', timeout=20):
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
        st, final, ct, t = get(url, 3000, timeout=20)
        ok = '#EXTM3U' in t or 'audio' in ct
        return f'{"OK" if ok else "?"} {st} {ct[:30]} | {re.sub(chr(10), " / ", t[:300])}'
    except Exception as e:
        return f'X {str(e)[:80]}'


log('■ 1) 앱에 있는 지금 주소')
u = 'https://624a79c87201d.streamlock.net/MBCFM/TV2.stream/playlist.m3u8'
log(f'  {u} → {test(u)}')
# 같은 서버의 다른 이름 시험 (TV2 → 라디오 이름일 수 있어서)
for name in ['FM.stream', 'AM.stream', 'radio.stream', 'RADIO.stream', 'SFM.stream', 'fm1.stream', 'TV1.stream', 'TV3.stream']:
    v = f'https://624a79c87201d.streamlock.net/MBCFM/{name}/playlist.m3u8'
    log(f'  {v} → {test(v)}')

log('■ 2) 홈페이지에서 생방송 페이지 · 방송 주소 찾기')
todo = ['https://mbcgn.kr/index.asp', 'https://mbcgn.kr/06_oar/oar01.asp', 'https://mbcgn.kr/06_oar/oar02.asp',
        'https://mbcgn.kr/06_oar/oar03.asp', 'https://mbcgn.kr/01_oar/oar01.asp', 'https://mbcgn.kr/01_oar/oar02.asp']
seen = set()
while todo and len(seen) < 18:
    p = todo.pop(0)
    if p in seen:
        continue
    seen.add(p)
    try:
        st, final, ct, t = get(p)
    except Exception as e:
        log(f'  {p} → X {str(e)[:50]}')
        continue
    found = sorted(set(m.group(0) for m in STREAM.finditer(t)))
    log(f'  {p} → {st} {final} · 글자 수 {len(t)} · 주소 {len(found)}개')
    if len(t) < 1500:
        log('    (전체) ' + re.sub(r'\s+', ' ', t)[:600])
    for f in found[:8]:
        v = ('https:' + f) if f.startswith('//') else f
        log(f'    방송 주소 {v} → {test(v)}')
    if 'index.asp' in p:
        for h, a in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S):
            a = re.sub(r'<[^>]+>|\s+', ' ', a).strip()
            if re.search(r'onair|생방송|표준|FM|라디오', h + ' ' + a, re.I) and 'oar' in h:
                todo.append(urllib.parse.urljoin(final, h))
        for m in re.finditer(r'function\s+RadioShow|streamlock|m3u8', t):
            log('    [홈 단서] … ' + re.sub(r'\s+', ' ', t[max(0, m.start() - 150): m.end() + 300]))

with open('radio_probe38_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe38_result.txt 를 올려 주세요')
