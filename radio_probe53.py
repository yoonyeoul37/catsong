# -*- coding: utf-8 -*-
# BeFM 시간표 · 프로그램 카드 HTML 모양 (옛날 보안 방식으로 접속)
# (앱 코드는 안 건드려요)   실행: python radio_probe53.py  →  radio_probe53_result.txt
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


for midx, key in [(37, '00:00'), (35, 'fileupload/program')]:
    log(f'■ BeFM midx={midx}')
    try:
        f, t = get(f'https://www.befm.or.kr/sub/template.php?midx={midx}&lang=ko')
        b = body(t)
        i = b.find(key)
        log(f'  글자 수 {len(t)} · 위치 {i}')
        log('  ' + flat(b[max(0, i - 2000): i + 4000]))
    except Exception as e:
        log(f'  못 가져옴 {e}')

with open('radio_probe53_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe53_result.txt 를 올려 주세요')
