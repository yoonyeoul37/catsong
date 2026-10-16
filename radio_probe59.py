# -*- coding: utf-8 -*-
# 아리랑 라디오 5차: 화면 조각 파일에서 program_type 옆 값 이름 찾기 + 남은 이름 넣어 보기
# (앱 코드는 안 건드려요)   실행: python radio_probe59.py  →  radio_probe59_result.txt
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
log('■ 1) 첫 화면 안 조각 파일 목록')
inline = ' '.join(re.findall(r'<script>(.*?)</script>', t, re.S))
pairs = {}
for blk in re.findall(r'\{(\d+:"[0-9a-f]{6,10}"(?:,\d+:"[0-9a-f]{6,10}")*)\}', inline):
    for k, v in re.findall(r'(\d+):"([0-9a-f]{6,10})"', blk):
        pairs[k] = v
log(f'  조각 {len(pairs)}개 · {list(pairs.items())[:8]}')
found = []
for k, v in pairs.items():
    for u in [f'https://www.arirang.com/static/js/{k}.{v}.chunk.js']:
        try:
            _, c = get(u, f)
        except Exception:
            continue
        for m in list(re.finditer(r'program_type', c))[:3]:
            snip = flat(c[max(0, m.start() - 300): m.end() + 300])
            found.append(snip)
            log(f'  [{k}] … {snip}')
    time.sleep(0.05)
log(f'  program_type 찾은 곳 {len(found)}개')

log('■ 2) 남은 이름 넣어 보기')
ok = None
for lk in ['lang', 'mode', 'langType', 'langCode', 'language_kind', 'lang_kind', 'site_lang', 'language_mode', 'lang_mode', 'nation']:
    for lv in ['en', 'ko', 'EN', 'KO', 'eng', 'kor']:
        d = {'program_type': 'RADIO', lk: lv}
        r = post('/v1.0/open/program/list', d)
        if '언어선택은 필수' in r:
            continue
        log(f'  {json.dumps(d)} → {flat(r)[:200]}')
        if not r.startswith('X'):
            ok = d
            break
    if ok:
        break
if ok:
    log(f'■ 성공 {json.dumps(ok)} — 결과 앞부분')
    log('  ' + flat(post('/v1.0/open/program/list', ok))[:6000])
else:
    log('■ 이름 못 찾음')

with open('radio_probe59_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe59_result.txt 를 올려 주세요')
