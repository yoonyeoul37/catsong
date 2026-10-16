# -*- coding: utf-8 -*-
# 아리랑 라디오 4차: 화면 코드에서 실제로 보내는 값 이름 보기
# (앱 코드는 안 건드려요)   실행: python radio_probe58.py  →  radio_probe58_result.txt
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

def post(path, data):
    hd = {'User-Agent': UA, 'Referer': 'https://www.arirang.com/radio', 'Origin': 'https://www.arirang.com',
          'Accept': 'application/json, text/plain, */*', 'Content-Type': 'application/json'}
    try:
        r = urllib.request.urlopen(urllib.request.Request('https://www.arirang.com' + path, headers=hd, data=json.dumps(data).encode()), timeout=15, context=ctx())
        return r.read().decode('utf-8', 'replace')
    except urllib.error.HTTPError as e:
        return f'X {e.code} ' + e.read().decode('utf-8', 'replace')[:400]
    except Exception as e:
        return f'X {e}'

f, t = get('https://www.arirang.com/radio')
srcs = [urllib.parse.urljoin(f, x) for x in re.findall(r'src=["\']([^"\']*/static/js/[^"\']+\.js)', t)]
log(f'■ 스크립트 {srcs}')
for u in srcs:
    _, j = get(u, f)
    log(f'■ {u} · 글자 {len(j)}')
    n = 0
    for k in ['program_type', 'RADIO', 'lang', 'language', 'schedule', 'onair', 'on_air']:
        for m in list(re.finditer(k, j))[:4]:
            log(f'  [{k}] … ' + flat(j[max(0, m.start() - 250): m.end() + 250]))
            n += 1
    log(f'  (찾은 곳 {n}개)')
# 화면 조각 파일 이름 모양 보기
for u in srcs:
    _, j = get(u, f)
    for m in list(re.finditer(r'static/js/|\.chunk\.js|chunk', j))[:3]:
        log(f'  [조각] … ' + flat(j[max(0, m.start() - 300): m.end() + 300]))

with open('radio_probe58_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe58_result.txt 를 올려 주세요')
