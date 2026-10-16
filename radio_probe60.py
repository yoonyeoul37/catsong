# -*- coding: utf-8 -*-
# 공동체 라디오 편성표 그림 내려받기 (마포FM · 전주FM · 성서공동체FM)
# 그림은 timetable_imgs 폴더에 저장돼요
# (앱 코드는 안 건드려요)   실행: python radio_probe60.py  →  radio_probe60_result.txt
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


for tag, u in [('mapo', 'https://www.mapofm.net/timetable'), ('jeonju', 'https://www.jcfm.kr/untitled-7')]:
    log(f'■ {tag} {u}')
    try:
        f, t = get(u)
        log(f'  그림 {save_imgs(tag, f, t, only=r"uploadedFiles")}개')
    except Exception as e:
        log(f'  못 가져옴 {e}')

log('■ 성서공동체FM')
for u in ['https://www.ssfm.kr/']:
    try:
        f, t = get(u)
        log(f'  {f} · 글자 {len(t)}')
        links = []
        for h, a in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S):
            a = flat(re.sub(r'<[^>]+>', ' ', a)).strip()
            full = urllib.parse.urljoin(f, h)
            if 'ssfm' in full and full not in [l for l, _ in links]:
                links.append((full, a))
        for full, a in links[:60]:
            log(f'  링크 [{a[:20]}] {full}')
        for m in re.finditer(r'<i?frame[^>]+src=["\']([^"\']+)', t):
            log(f'  프레임 {m.group(1)}')
        cand = [l for l, a in links if re.search(r'편성|시간표|time|sche|program|프로그램', l + a, re.I)]
        for c in cand[:4]:
            try:
                f2, t2 = get(c, f)
                log(f'  ── {c}')
                log(f'  그림 {save_imgs("seongseo", f2, t2)}개')
            except Exception as e:
                log(f'  {c} → X {e}')
    except Exception as e:
        log(f'  못 가져옴 {e}')

with open('radio_probe60_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe60_result.txt 와 timetable_imgs 폴더 안 그림들을 올려 주세요')
