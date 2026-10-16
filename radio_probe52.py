# -*- coding: utf-8 -*-
# 남은 방송 3차: TBC 드림FM 라디오 편성표 모양 · BeFM 시간표/프로그램 HTML 모양 · 아리랑 편성 데이터 주소
# (앱 코드는 안 건드려요)   실행: python radio_probe52.py  →  radio_probe52_result.txt
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
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


# ── 1) TBC 드림FM 편성표 ──
log('■ 1) TBC 드림FM 편성표 (/schedule/?mid=7_181)')
try:
    f, t = get('https://www.tbc.co.kr/schedule/?mid=7_181&end=', 'https://www.tbc.co.kr/schedule')
    b = body(t)
    m = re.search(r'\b(0[5-9]|1\d):[0-5]\d\b', b)
    i = m.start() if m else 0
    log(f'  글자 수 {len(t)} · 첫 시간 위치 {i}')
    log('  --- HTML 모양 ---')
    log('  ' + flat(b[max(0, i - 1500): i + 2500]))
    for h in sorted(set(re.findall(r'href=["\']([^"\']*mid=7_181[^"\']*)["\']', t)))[:12]:
        log(f'  날짜 링크 {h}')
except Exception as e:
    log(f'  못 가져옴 {e}')
log('■ TBC 드림FM 프로그램 페이지 사진')
for mid in ['3_71_72', '3_257_258', '3_86_87', '3_92_93', '3_230_231', '3_98_99', '3_104_107', '3_108_109', '3_300_301', '3_316_317']:
    try:
        f, t = get(f'https://www.tbc.co.kr/fm/?mid={mid}', 'https://www.tbc.co.kr/fm/?mid=3')
    except Exception as e:
        log(f'  {mid} → X {e}')
        continue
    og = dict(re.findall(r'property=["\']og:(title|image)["\']\s+content=["\']([^"\']*)', t))
    imgs = [urllib.parse.urljoin(f, x) for x in re.findall(r'<img[^>]+src=["\']([^"\']+)', body(t))
            if re.search(r'upload|data|file|program|prog', x, re.I) and not re.search(r'logo|icon|btn|search|all\.png', x, re.I)]
    tx = flat(re.sub(r'<[^>]+>', ' ', body(t)))
    w = re.findall(r'(?:월|화|수|목|금|토|일|매일|평일|주말|MON|SAT)[^.\n]{0,20}?\d{1,2}\s*(?::\s*\d{2}|시)', tx)
    log(f'  {mid} · og {og} · 시간 {w[:3]}')
    for x in imgs[:3]:
        log(f'     사진 {x}')
    time.sleep(0.2)

# ── 2) BeFM ──
log('■ 2) BeFM 시간표 HTML 모양 (midx=37)')
try:
    f, t = get('https://www.befm.or.kr/sub/template.php?midx=37&lang=ko')
    b = body(t)
    i = b.find('00:00')
    log('  ' + flat(b[max(0, i - 1500): i + 1800]))
except Exception as e:
    log(f'  못 가져옴 {e}')
log('■ BeFM 프로그램 카드 HTML 모양 (midx=35)')
try:
    f, t = get('https://www.befm.or.kr/sub/template.php?midx=35&lang=ko')
    b = body(t)
    i = b.find('fileupload/program')
    log('  ' + flat(b[max(0, i - 800): i + 2200]))
except Exception as e:
    log(f'  못 가져옴 {e}')

# ── 3) 아리랑: 화면 스크립트 안의 데이터 주소 ──
log('■ 3) 아리랑 스크립트 안 주소')
for js in ['https://www.arirang.com/static/js/main.9ff58b66.chunk.js', 'https://www.arirang.com/static/js/12.a4e9c97e.chunk.js']:
    try:
        _, t = get(js, 'https://www.arirang.com/radio')
    except Exception as e:
        log(f'  {js} → X {e}')
        continue
    found = sorted(set(re.findall(r'["\'`](https?://[^"\'`\s]{6,120})["\'`]', t)))
    found = [x for x in found if re.search(r'api|schedule|radio|epg|timetable', x, re.I)]
    log(f'  {js} · 글자 수 {len(t)} · 주소 {len(found)}개')
    for x in found[:25]:
        log(f'    {x}')
    for m in list(re.finditer(r'[Ss]chedule|timetable|epg', t))[:6]:
        log('    … ' + flat(t[max(0, m.start() - 150): m.end() + 200]))

with open('radio_probe52_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe52_result.txt 를 올려 주세요')
