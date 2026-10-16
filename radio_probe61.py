# -*- coding: utf-8 -*-
# 공동체 라디오 2차: 전주FM 편성표 원본 크기 그림 · 성서공동체FM 진짜 홈페이지(scnfm.or.kr) 편성표
# 그림은 timetable_imgs 폴더에 저장돼요
# (앱 코드는 안 건드려요)   실행: python radio_probe61.py  →  radio_probe61_result.txt
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


import os
os.makedirs('timetable_imgs', exist_ok=True)


def save_imgs(tag, page_url, t, only=None):
    n = 0
    seen = set()
    for x in re.findall(r'<img[^>]+(?:src|data-src)=["\']([^"\']+)', t):
        u = urllib.parse.urljoin(page_url, x if not x.startswith('//') else 'https:' + x)
        if u in seen or re.search(r'logo|icon|btn|sns|blank|\.svg|\.gif', u, re.I):
            continue
        if only and not re.search(only, u):
            continue
        seen.add(u)
        try:
            raw = urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent': UA, 'Referer': page_url}), timeout=20, context=ctx()).read()
        except Exception as e:
            log(f'  X {u} {e}')
            continue
        if len(raw) < 30000:  # 작은 그림(버튼 등)은 빼기
            continue
        ext = os.path.splitext(urllib.parse.urlparse(u).path)[1] or '.jpg'
        n += 1
        name = f'timetable_imgs/{tag}_{n}{ext}'
        open(name, 'wb').write(raw)
        log(f'  저장 {name} ({len(raw)//1024}KB) ← {u}')
    return n


log('■ 전주FM 원본 크기 그림')
for u in ['https://contents.sixshop.com/uploadedFiles/207956/default/image_1788224630991.png']:
    try:
        raw = urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent': UA, 'Referer': 'https://www.jcfm.kr/'}), timeout=30, context=ctx()).read()
        open('timetable_imgs/jeonju_big.png', 'wb').write(raw)
        log(f'  저장 timetable_imgs/jeonju_big.png ({len(raw)//1024}KB)')
    except Exception as e:
        log(f'  X {e}')

log('■ 성서공동체FM (scnfm.or.kr)')
for home in ['http://scnfm.or.kr/', 'https://scnfm.or.kr/', 'http://www.scnfm.or.kr/']:
    try:
        f, t = get(home)
    except Exception as e:
        log(f'  {home} → X {e}')
        continue
    log(f'  {home} → {f} · 글자 {len(t)}')
    links = []
    for h, a in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S):
        a = flat(re.sub(r'<[^>]+>', ' ', a)).strip()
        full = urllib.parse.urljoin(f, h)
        if 'scnfm' in full and full not in [l for l, _ in links]:
            links.append((full, a))
    for full, a in links[:80]:
        log(f'  링크 [{a[:20]}] {full}')
    cand = [l for l, a in links if re.search(r'편성|시간표|time|sche|프로그램', l + a, re.I)]
    for c in cand[:5]:
        try:
            f2, t2 = get(c, f)
            tx = flat(re.sub(r'<[^>]+>', ' ', body(t2)))
            tm = re.findall(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b', tx)
            log(f'  ── {c} · 시간 글자 {len(tm)}개')
            if len(tm) > 10:
                i = tx.find(tm[0])
                log('     ' + tx[max(0, i - 300): i + 3000])
            log(f'  그림 {save_imgs("seongseo", f2, t2)}개')
        except Exception as e:
            log(f'  {c} → X {e}')
    break

with open('radio_probe61_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe61_result.txt 와 timetable_imgs 폴더 안 그림들을 올려 주세요')
