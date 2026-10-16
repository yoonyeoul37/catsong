# -*- coding: utf-8 -*-
# 아리랑 라디오 3차: '언어선택' 값 찾아서 프로그램 목록 받아 보기
# (앱 코드는 안 건드려요)   실행: python radio_probe57.py  →  radio_probe57_result.txt
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

log('■ 언어 값 찾기 (프로그램 타입은 RADIO 로)')
ok = None
for lk in ['language', 'lang_code', 'language_code', 'lang_type', 'language_type', 'lan', 'locale', 'lang_cd', 'language_id', 'lang_id']:
    for lv in ['en', 'EN', 'eng', 'ENG', 'ko', 1]:
        d = {'program_type': 'RADIO', lk: lv}
        r = post('/v1.0/open/program/list', d)
        short = flat(r)[:160]
        log(f'  {json.dumps(d)} → {short}')
        if not r.startswith('X'):
            ok = d
            break
    if ok:
        break

if ok:
    log(f'■ 성공한 값 {json.dumps(ok)} — 결과 앞부분')
    r = post('/v1.0/open/program/list', ok)
    log('  ' + flat(r)[:6000])
    for pt in ['radio', 'Radio', 'RADIO_PROGRAM']:
        d = dict(ok, program_type=pt)
        log(f'  {json.dumps(d)} → {flat(post("/v1.0/open/program/list", d))[:200]}')
else:
    log('■ 못 찾음')

with open('radio_probe57_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe57_result.txt 를 올려 주세요')
