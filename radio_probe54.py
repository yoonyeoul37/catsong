# -*- coding: utf-8 -*-
# 마지막 파보기: MBC 올댓뮤직(iMBC 편성 주소) · 극동방송 AM 편성 탭 · 아리랑 데이터 주소 · 공동체 라디오 글자 편성
# (앱 코드는 안 건드려요)   실행: python radio_probe54.py  →  radio_probe54_result.txt
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


import datetime
today = datetime.date.today()

# ── 1) 올댓뮤직: 서울 MBC가 쓰는 편성 주소에 채널 이름만 바꿔 보기 ──
log('■ 1) MBC 올댓뮤직 (iMBC 편성 주소)')
for st in ['CHM', 'chm', 'ALLTHAT', 'AllThatMusic', 'ATM', 'MUSIC', 'CH3', 'FM3', 'DMB']:
    try:
        _, t = get(f'https://control.imbc.com/Schedule/Radio/Time?sType={st}&broadDate={today:%Y%m%d}', 'https://www.imbc.com/')
        n = t.count('"Title"')
        log(f'  sType={st} → 프로그램 {n}개 · {flat(t[:300])}')
    except Exception as e:
        log(f'  sType={st} → X {e}')
for u in ['https://www.imbc.com/broad/radio/fm/schedule/index.html', 'https://radio.imbc.com/', 'https://mini.imbc.com/']:
    try:
        f, t = get(u, 'https://www.imbc.com/')
        hits = sorted(set(re.findall(r'sType=\w+|[Cc]hannel["\']?\s*[:=]\s*["\']\w+["\']|allthat\w*|CHM\w*', t)))
        log(f'  {u} → {f} · 단서 {hits[:20]}')
    except Exception as e:
        log(f'  {u} → X {e}')

# ── 2) 극동방송 AM: 편성표 페이지 안 AM / 채널 탭 ──
log('■ 2) 극동방송 AM')
for u in ['https://seoul.febc.net/radio/schedule', 'https://www.febc.net/radio/schedule', 'https://seoul.febc.net/radio/schedule?channel=am',
          'https://seoul.febc.net/radio/schedule?type=AM', 'https://www.febc.net/']:
    try:
        f, t = get(u)
        b = body(t)
        log(f'  ── {u} → {f} · 글자 {len(t)} · 시간 {len(re.findall(r"<span class=.time.>", t))}개')
        for h, a in re.findall(r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', b, re.S):
            a = flat(re.sub(r'<[^>]+>', ' ', a)).strip()
            if re.search(r'AM|1188|에이엠|채널|channel|schedule|편성', h + a, re.I):
                log(f'     링크 [{a[:20]}] {h}')
        for m in re.finditer(r'AM\s*1188|1188|AM', b):
            log('     … ' + flat(re.sub(r'<[^>]+>', ' ', b[max(0, m.start() - 150): m.end() + 150]))[:200])
            break
    except Exception as e:
        log(f'  {u} → X {e}')

# ── 3) 아리랑: 첫 화면이 부르는 스크립트 안의 주소 (주소 앞부분 없는 것까지) ──
log('■ 3) 아리랑')
try:
    f, t = get('https://www.arirang.com/radio')
    scripts = [urllib.parse.urljoin(f, s) for s in re.findall(r'<script[^>]+src=["\']([^"\']+)', t)]
    log(f'  스크립트 {scripts}')
    for js in scripts:
        try:
            _, j = get(js, f)
        except Exception as e:
            log(f'  {js} → X {e}')
            continue
        hits = sorted(set(re.findall(r'["\'`]((?:https?:)?//[\w.-]+(?:/[^"\'`\s]*)?|/[\w./-]*(?:api|Api|API|v\d|schedule|Schedule|radio|Radio|program)[\w./-]*)["\'`]', j)))
        log(f'  {js} · 글자 {len(j)} · 주소 {len(hits)}개')
        for x in hits[:60]:
            log(f'    {x}')
except Exception as e:
    log(f'  못 가져옴 {e}')

# ── 4) 공동체 라디오: 글자로 된 편성/프로그램 페이지가 있는지 ──
log('■ 4) 공동체 라디오 메뉴')
for u in ['https://www.mapofm.net/', 'https://www.jcfm.kr/', 'http://www.ssfm.kr/', 'https://ssfm.kr/']:
    try:
        f, t = get(u)
        log(f'  ── {u} → {f}')
        for h, a in re.findall(r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', t, re.S):
            a = flat(re.sub(r'<[^>]+>', ' ', a)).strip()
            if re.search(r'편성|프로그램|시간표|program|schedule', h + a, re.I):
                log(f'     링크 [{a[:20]}] {urllib.parse.urljoin(f, h)}')
    except Exception as e:
        log(f'  {u} → X {e}')

with open('radio_probe54_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe54_result.txt 를 올려 주세요')
