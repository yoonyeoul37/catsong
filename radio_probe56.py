# -*- coding: utf-8 -*-
# 아리랑 라디오 2차: 데이터 부를 때 넣는 값 찾기 + 에러 내용 보기
# (앱 코드는 안 건드려요)   실행: python radio_probe56.py  →  radio_probe56_result.txt
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

log('■ 1) 화면 조각 파일들에서 부를 때 넣는 값 찾기')
f, t = get('https://www.arirang.com/radio')
m = re.search(r'src=["\']([^"\']*/static/js/main\.[\w]+\.chunk\.js)', t)
main = urllib.parse.urljoin(f, m.group(1))
_, j = get(main, f)
names = {}
for mm in re.finditer(r'\{(\d+:"[0-9a-f]{8}"(?:,\d+:"[0-9a-f]{8}")+)\}', j):
    for k, v in re.findall(r'(\d+):"([0-9a-f]{8})"', mm.group(1)):
        names[k] = v
log(f'  조각 파일 {len(names)}개')
seen = set()
for k, v in names.items():
    u = f'https://www.arirang.com/static/js/{k}.{v}.chunk.js'
    try:
        _, c = get(u, f)
    except Exception:
        continue
    for mm in re.finditer(r'(?:program_id|channel_id|menu_id|category_id|channel|onair|schedule|is_radio|program_type|media_type|radio_id)\s*:', c):
        snip = flat(c[max(0, mm.start() - 120): mm.end() + 160])
        key = snip[100:200]
        if key in seen:
            continue
        seen.add(key)
        if re.search(r'[Rr]adio|RADIO|program', snip):
            log(f'  [{k}] … {snip}')
    time.sleep(0.1)

log('■ 2) 넣는 값 바꿔 보며 프로그램 목록 부르기 (에러 내용 포함)')
tries = [{}, {'page': 1}, {'channel': 'radio'}, {'channel_id': 3}, {'menu_id': 3}, {'type': 'radio'},
         {'program_type': 'RADIO'}, {'is_radio': True}, {'lang': 'en'}, {'page': 1, 'page_size': 50, 'channel': 'RADIO'}]
for d in tries:
    log(f'  program/list {json.dumps(d)} → {flat(post("/v1.0/open/program/list", d))[:500]}')
for d in [{}, {'lang': 'en'}, {'menu_type': 'radio'}]:
    log(f'  menu/list {json.dumps(d)} → {flat(post("/v1.0/open/menu/list", d))[:800]}')
    log(f'  category/list {json.dumps(d)} → {flat(post("/v1.0/open/category/list", d))[:800]}')

with open('radio_probe56_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe56_result.txt 를 올려 주세요')
