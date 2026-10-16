# -*- coding: utf-8 -*-
# 아리랑 라디오: 프로그램 목록 데이터 주소 찾기 (주소 앞부분 · 부르는 방법)
# (앱 코드는 안 건드려요)   실행: python radio_probe55.py  →  radio_probe55_result.txt
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
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


def get(url, ref=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if ref:
        h['Referer'] = ref
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=20, context=ctx())
    raw = r.read()
    for enc in ('utf-8', 'euc-kr'):
        try:
            return r.geturl(), raw.decode(enc)
        except Exception:
            pass
    return r.geturl(), raw.decode('utf-8', 'replace')


def flat(s):
    return re.sub(r'\s+', ' ', s)


def body(t):
    return re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)


import json

MAIN = 'https://www.arirang.com/static/js/main.9ff58b66.chunk.js'
log('■ 1) 스크립트 안에서 데이터 서버 주소 찾기')
try:
    f, t = get('https://www.arirang.com/radio')
    m = re.search(r'src=["\']([^"\']*/static/js/main\.[\w]+\.chunk\.js)', t)
    if m:
        MAIN = urllib.parse.urljoin(f, m.group(1))
    _, j = get(MAIN, f)
    log(f'  {MAIN} · 글자 {len(j)}')
    for k in ['/v1.0/open/program/list', '/v1.0/open/program/detail', 'baseURL', 'REACT_APP', 'apiUrl', 'API_URL', 'axios.create', '.arirang.com']:
        for m in list(re.finditer(re.escape(k), j))[:3]:
            log(f'  [{k}] … ' + flat(j[max(0, m.start() - 300): m.end() + 300]))
except Exception as e:
    log(f'  못 가져옴 {e}')

log('■ 2) 프로그램 목록 불러 보기')
hosts = ['https://www.arirang.com', 'https://api.arirang.com', 'https://apis.arirang.com', 'https://webapi.arirang.com', 'https://mapi.arirang.com', 'https://webdev.arirang.com']
for h in hosts:
    for path, data in [('/v1.0/open/program/list', None), ('/v1.0/open/program/list', {'channel': 'RADIO'}),
                       ('/v1.0/open/program/list?channel=RADIO', None), ('/v1.0/open/category/list', None)]:
        u = h + path
        try:
            hd = {'User-Agent': UA, 'Referer': 'https://www.arirang.com/radio', 'Origin': 'https://www.arirang.com',
                  'Accept': 'application/json'}
            body_ = None
            if data is not None:
                hd['Content-Type'] = 'application/json'
                body_ = json.dumps(data).encode()
            r = urllib.request.urlopen(urllib.request.Request(u, headers=hd, data=body_), timeout=15, context=ctx())
            t = r.read().decode('utf-8', 'replace')
            log(f'  {"POST" if body_ else "GET"} {u} → {len(t)}자 · {flat(t[:600])}')
        except Exception as e:
            log(f'  {"POST" if data is not None else "GET"} {u} → X {e}')

with open('radio_probe55_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe55_result.txt 를 올려 주세요')
