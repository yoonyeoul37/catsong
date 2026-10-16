# -*- coding: utf-8 -*-
# 남은 방송 2차: 원주MBC 프로그램 사진 · 강원영동 라디오 · TBC 드림FM 라디오 편성 · BeFM 시간표 · 아리랑 · 마포FM/전주FM 프로그램
# (앱 코드는 안 건드려요)   실행: python radio_probe51.py  →  radio_probe51_result.txt
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
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=15, context=ctx())
    raw = r.read()
    for enc in ('utf-8', 'euc-kr'):
        try:
            return r.geturl(), raw.decode(enc)
        except Exception:
            pass
    return r.geturl(), raw.decode('utf-8', 'replace')


def text(t):
    t = re.sub(r'<script.*?</script>|<style.*?</style>|<header.*?</header>|<nav.*?</nav>|<footer.*?</footer>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).replace('&nbsp;', ' ').strip()


def imgs_of(t, base, skip=r'logo|icon|btn|sns|bnr_|banner|common|blank|search|all\.png'):
    return [urllib.parse.urljoin(base, x) for x in re.findall(r'<img[^>]+src=["\']([^"\']+)', t) if not re.search(skip, x, re.I)]


WHEN = re.compile(r'(?:월|화|수|목|금|토|일|매일|평일|주말)[^.\n]{0,25}?\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?)'
                  r'(?:\s*[~\-–]\s*(?:오전|오후)?\s*\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?))?')

# ── 1) 원주MBC 라디오 프로그램 목록 → 소개 페이지 (이름 · 시간 · 사진) ──
log('■ 1) 원주MBC')
try:
    final, t = get('https://www.wjmbc.co.kr/radio/prog.html')
    codes = list(dict.fromkeys(re.findall(r'prog_intro\.html\?pgcode=(\w+)', t)))
    log(f'  프로그램 {len(codes)}개: {codes}')
    for i, code in enumerate(codes[:16]):
        u = f'https://www.wjmbc.co.kr/radio/prog_intro.html?pgcode={code}'
        try:
            f, t2 = get(u, final)
        except Exception as e:
            log(f'  {code} → X {e}')
            continue
        tx = text(t2)
        tt = re.search(r'<title>(.*?)</title>', t2, re.S)
        og = dict(re.findall(r'property=["\']og:(title|image)["\']\s+content=["\']([^"\']*)', t2))
        log(f'  ── {code} · 제목 {(tt.group(1).strip() if tt else "?")[:50]} · og {og}')
        chs = list(dict.fromkeys(re.findall(r'표준\s*FM|음악\s*FM|FM4U', tx)))[:3]
        log(f'     시간 {list(dict.fromkeys(WHEN.findall(tx)))[:3]} · 채널 {chs}')
        for x in imgs_of(t2, f)[:3]:
            log(f'     사진 {x}')
        time.sleep(0.2)
except Exception as e:
    log(f'  못 가져옴 {e}')

# ── 2) MBC강원영동 라디오 프로그램 · 라디오 편성표 탭 ──
log('■ 2) MBC강원영동')
for u in ['https://www.mbceg.co.kr/program/radio_06', 'https://www.mbceg.co.kr/program/radio_03', 'https://www.mbceg.co.kr/schedule/cp_depart']:
    try:
        f, t = get(u)
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    tx = text(t)
    log(f'  ── {u}')
    if 'schedule' in u:
        for h, a in re.findall(r'<a[^>]+href=["\']([^"\']*schedule[^"\']*)["\'][^>]*>(.*?)</a>', t, re.S)[:20]:
            label = re.sub(r'<[^>]+>|\s+', ' ', a).strip()[:15]
            log(f'     링크 [{label}] {urllib.parse.urljoin(f, h)}')
        for m in re.finditer(r'(?:onclick|data-[\w-]+)=["\']([^"\']*(?:FM|fm|radio|tab)[^"\']*)["\']', t):
            log(f'     단서 {m.group(1)[:120]}')
    else:
        tt = re.search(r'<title>(.*?)</title>', t, re.S)
        log(f'     제목 {(tt.group(1).strip() if tt else "?")[:50]} · 시간 {list(dict.fromkeys(WHEN.findall(tx)))[:4]}')
        for x in imgs_of(t, f)[:4]:
            log(f'     사진 {x}')

# ── 3) TBC 드림FM: 편성표 페이지의 라디오 탭 · 라디오 프로그램 목록 ──
log('■ 3) TBC 드림FM')
for u in ['https://www.tbc.co.kr/schedule', 'https://www.tbc.co.kr/fm/?mid=3']:
    try:
        f, t = get(u)
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    log(f'  ── {u} · 글자 수 {len(t)}')
    for h, a in re.findall(r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', t, re.S):
        a = re.sub(r'<[^>]+>|\s+', ' ', a).strip()
        if re.search(r'FM|fm|라디오|radio|드림', h + a) and ('schedule' in h or 'fm' in h):
            log(f'     링크 [{a[:20]}] {urllib.parse.urljoin(f, h)}')
    for m in re.finditer(r'(?:onclick|data-[\w-]+)=["\']([^"\']*(?:fm|FM|radio|tab|type)[^"\']*)["\']', t):
        log(f'     단서 {m.group(1)[:120]}')
    if 'fm' in u:
        for x in imgs_of(t, f)[:8]:
            log(f'     사진 {x}')

# ── 4) BeFM 프로그램 시간표 ──
log('■ 4) BeFM')
for u in ['https://www.befm.or.kr/sub/template.php?midx=37&lang=ko', 'https://www.befm.or.kr/sub/template.php?midx=35&lang=ko']:
    try:
        f, t = get(u)
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    tx = text(t)
    tm = re.findall(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b', tx)
    log(f'  ── {u} · 시간 {len(tm)}개')
    i = tx.find(tm[0]) if tm else 0
    log('     ' + tx[max(0, i - 200): i + 1200])
    for x in imgs_of(t, f)[:6]:
        log(f'     사진 {x}')

# ── 5) 아리랑 라디오: 페이지 안 데이터 주소 ──
log('■ 5) 아리랑 라디오')
try:
    f, t = get('https://www.arirang.com/radio')
    for a in sorted(set(re.findall(r'["\'](https?://[^"\']*(?:api|json|schedule|Schedule)[^"\']*|/[^"\']*(?:api|json|schedule|Schedule)[^"\']*)["\']', t)))[:20]:
        log(f'  주소 단서 {a}')
    for s in re.findall(r'<script[^>]+src=["\']([^"\']+)', t)[:10]:
        log(f'  스크립트 {urllib.parse.urljoin(f, s)}')
except Exception as e:
    log(f'  못 가져옴 {e}')

# ── 6) 마포FM · 전주FM 프로그램 소개 (시간 글자가 있는지) ──
log('■ 6) 공동체 라디오 프로그램 소개')
for u in ['https://www.mapofm.net/program', 'https://www.jcfm.kr/untitled-8', 'https://www.mapofm.net/timetable', 'https://www.jcfm.kr/untitled-7']:
    try:
        f, t = get(u)
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    tx = text(t)
    w = list(dict.fromkeys(WHEN.findall(tx)))
    tm = re.findall(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b', tx)
    log(f'  ── {u} · 요일+시간 {len(w)}개 {w[:6]} · 시간 {len(tm)}개')
    big = [x for x in re.findall(r'<img[^>]+src=["\']([^"\']+)', t) if 'uploadedFiles' in x]
    log(f'     올린 그림 {len(big)}개 {big[:3]}')

with open('radio_probe51_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe51_result.txt 를 올려 주세요')
