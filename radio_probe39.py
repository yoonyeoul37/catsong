# -*- coding: utf-8 -*-
# 국내 라디오 전체 소리 점검: 앱 목록(radio_korea_screen2.dart)의 방송 주소를 하나씩 열어서 실제 소리 조각까지 받아지는지
# (앱 코드는 안 건드려요 — 읽기만 해요)
# 실행: 프로젝트 폴더에서 python radio_probe39.py  →  radio_probe39_result.txt (2~3분)
import os, re, ssl, json, urllib.request, urllib.parse, concurrent.futures as cf

UA = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'


def find_file():
    for root, _, files in os.walk('lib'):
        if 'radio_korea_screen2.dart' in files:
            return os.path.join(root, 'radio_korea_screen2.dart')
    return None


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    c.options |= getattr(ssl, 'OP_LEGACY_SERVER_CONNECT', 0x4)
    return c


def get(url, n=None, timeout=12):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=timeout, context=ctx())
    raw = r.read(n) if n else r.read()
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), raw


def first_uri(text, base):
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            return urllib.parse.urljoin(base, line)
    return None


def check_stream(url):
    """주소 → 실제 소리 조각까지. 돌려줌: (OK/X, 설명)"""
    st, final, ct, raw = get(url, 200000)
    head = raw[:4000].decode('utf-8', 'ignore')
    if '#EXTM3U' in head:
        nxt = first_uri(head, final)
        if not nxt:
            return 'X', 'm3u8 안이 비어 있음'
        if '#EXT-X-STREAM-INF' in head:  # 화질별 목록 → 첫 번째 목록 다시
            st2, final2, _, raw2 = get(nxt, 200000)
            head2 = raw2[:4000].decode('utf-8', 'ignore')
            nxt = first_uri(head2, final2)
            if not nxt:
                return 'X', '세부 m3u8 안이 비어 있음'
        st3, _, ct3, seg = get(nxt, 20000)
        return ('OK', f'소리 조각 {len(seg)}바이트 ({ct3[:20]})') if len(seg) > 500 else ('X', f'소리 조각이 너무 작음 {len(seg)}')
    if 'audio' in ct or 'mpeg' in ct or 'aac' in ct or 'ogg' in ct or len(raw) > 5000:
        return 'OK', f'바로 소리 {len(raw)}바이트 ({ct[:20]})'
    if '[playlist]' in head.lower() or 'File1=' in head:
        m = re.search(r'File1=(\S+)', head)
        return check_stream(m.group(1)) if m else ('X', 'pls 안이 비어 있음')
    return 'X', f'알 수 없는 응답 {st} {ct[:25]} {head[:60]!r}'


def resolve(url):
    """앱이 하는 것처럼 먼저 진짜 주소 받기 (MBC 서울 · KBS)"""
    if any(k in url for k in ('mbcsfm.pls', 'mbcfm.pls', 'mbcatm.pls')):
        ch = 'sfm' if 'mbcsfm' in url else 'chm' if 'mbcatm' in url else 'mfm'
        _, _, _, raw = get(f'https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel={ch}')
        return raw.decode('utf-8', 'ignore').strip()
    if 'cfpwwwapi.kbs.co.kr' in url:
        _, _, _, raw = get(url)
        data = json.loads(raw.decode('utf-8', 'ignore'))
        items = data.get('channel_item') if isinstance(data, dict) else None
        if items:
            return items[0].get('service_url') or url
    return url


def one(item):
    name, url = item
    try:
        real = resolve(url)
        res, why = check_stream(real)
    except Exception as e:
        res, why = 'X', str(e)[:70]
    return name, res, why, url


path = find_file()
if not path:
    print('❌ radio_korea_screen2.dart 를 못 찾았어요 — 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요')
    raise SystemExit(1)
src = open(path, encoding='utf-8').read()
stations = []
for line in src.splitlines():
    if line.strip().startswith('//'):
        continue  # 숨겨 둔 방송은 빼기
    m = re.search(r"_KStation\(name: '([^']+)'.*?streamUrl: '([^']+)'", line)
    if m:
        stations.append((m.group(1), m.group(2)))
print(f'국내 방송 {len(stations)}개 점검 시작 (2~3분)…')

with cf.ThreadPoolExecutor(10) as ex:
    results = list(ex.map(one, stations))

bad = [r for r in results if r[1] != 'OK']
out = [f'■ 국내 방송 {len(results)}개 중 소리 OK {len(results) - len(bad)}개 · 안 됨 {len(bad)}개', '', '■ 안 되는 방송']
for name, res, why, url in bad:
    out.append(f'  ❌ {name} | {why} | {url}')
out += ['', '■ 되는 방송']
for name, res, why, url in results:
    if res == 'OK':
        out.append(f'  ✅ {name} | {why}')
print('\n'.join(out))
with open('radio_probe39_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe39_result.txt 를 올려 주세요')
