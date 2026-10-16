# -*- coding: utf-8 -*-
# 한국 라디오 방송 주소 찾기: 라디오 브라우저(전 세계 라디오 목록)에 있는 한국 방송 전부 + 지금 실제로 나오는지
# (앱 코드는 안 건드려요)  실행: python radio_probe21.py  →  radio_probe21_result.txt 가 생겨요 (몇 분 걸려요)
import json, ssl, urllib.request, concurrent.futures as cf

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, n=None, timeout=12):
    r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=timeout, context=ctx)
    return r.status, r.geturl(), r.headers.get('Content-Type', ''), (r.read(n) if n else r.read())


stations = []
for server in ['de1.api.radio-browser.info', 'nl1.api.radio-browser.info', 'at1.api.radio-browser.info']:
    try:
        _, _, _, raw = get(f'https://{server}/json/stations/bycountrycodeexact/KR?hidebroken=false&limit=2000', timeout=30)
        stations = json.loads(raw)
        log(f'라디오 브라우저({server}) 한국 방송 {len(stations)}개')
        break
    except Exception as e:
        log(f'  ({server} 안 됨: {e})')


def check(s):
    url = s.get('url_resolved') or s.get('url') or ''
    try:
        st, final, ct, head = get(url, 2048, timeout=10)
        txt = head[:200].decode('latin-1', 'ignore')
        ok = st == 200 and ('#EXTM3U' in txt or 'audio' in ct or 'mpegurl' in ct.lower() or 'octet' in ct)
        return s, url, ('OK' if ok else f'?({st} {ct[:30]})')
    except Exception as e:
        return s, url, f'X({str(e)[:40]})'


with cf.ThreadPoolExecutor(12) as ex:
    results = list(ex.map(check, stations))

results.sort(key=lambda r: (r[2] != 'OK', r[0].get('name', '')))
log('=' * 70)
log('결과 | 이름 | 주소 | 라디오브라우저 마지막 확인 | 표(votes)')
for s, url, res in results:
    log(f"{res} | {s.get('name', '').strip()} | {url} | {s.get('lastcheckok')} | {s.get('votes')}")

with open('radio_probe21_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe21_result.txt 를 올려 주세요')
