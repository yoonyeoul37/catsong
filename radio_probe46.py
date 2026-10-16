# -*- coding: utf-8 -*-
# 전주MBC(표준FM·FM4U) · 안동MBC FM4U: 지역 라디오 프로그램 이름 · 채널 · 시간 · 사진 찾기 (앱 코드는 안 건드려요)
# 실행: python radio_probe46.py  →  radio_probe46_result.txt
import re, ssl, time, urllib.request, urllib.parse

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    c.set_ciphers('DEFAULT@SECLEVEL=0')
    return c


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, ref=None):
    h = {'User-Agent': UA}
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


WHEN = re.compile(r'(?:방송\s*(?:시간|일시)\s*:?\s*)?(?:월|화|수|목|금|토|일|매일|평일|주말)[^.\n]{0,30}?'
                  r'\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?)'
                  r'(?:\s*[~\-–]\s*(?:오전|오후|낮|밤)?\s*\d{1,2}\s*(?::\s*\d{2}|시(?:\s*\d{1,2}\s*분)?))?')
CH = re.compile(r'표준\s*FM[^가-힣]{0,10}|FM4U[^가-힣]{0,10}|음악\s*FM[^가-힣]{0,10}|제[12]\s*FM[^가-힣]{0,10}|\d{2,3}\.\d\s*MHz')

# ── 1) 전주MBC ──
log('■ 1) 전주MBC')
try:
    final, home = get('https://www.jmbc.co.kr/')
    progs = sorted(set(urllib.parse.urljoin(final, h) for h in re.findall(r'href=["\'](/program/[a-z]+_\d+)[^"\']*["\']', home)))
    log(f'  홈의 프로그램 페이지 {len(progs)}개')
    for p in progs:
        log(f'    {p}')
    # 편성표 페이지가 데이터를 어디서 부르는지
    f2, sch = get('https://www.jmbc.co.kr/schedule/tv', final)
    for m in re.finditer(r'(?:url\s*[:=]|\$\.(?:ajax|get|post)|fetch\()\s*\(?\s*["\']([^"\']+)["\']', sch):
        log(f'  [편성표 페이지 스크립트 주소] {m.group(1)}')
    for a in sorted(set(re.findall(r'["\'](/schedule[^"\']*)["\']', sch)))[:15]:
        log(f'  [편성표 주소 단서] {a}')
    for v in ['https://www.jmbc.co.kr/schedule/sfm', 'https://www.jmbc.co.kr/schedule/fm', 'https://www.jmbc.co.kr/schedule/am',
              'https://www.jmbc.co.kr/schedule/radio1', 'https://www.jmbc.co.kr/schedule/fm4u']:
        try:
            f3, t3 = get(v, final)
            tm = re.findall(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b', text(t3))
            log(f'  [추측] {v} → {f3} · 시간 {len(tm)}개')
        except Exception as e:
            log(f'  [추측] {v} → X {str(e)[:40]}')
    for p in progs[:20]:
        try:
            f4, t4 = get(p, final)
        except Exception as e:
            log(f'  {p} → X {str(e)[:40]}')
            continue
        tx = text(t4)
        title = re.search(r'<title>(.*?)</title>', t4, re.S)
        og = re.findall(r'property=["\']og:image["\']\s+content=["\']([^"\']+)', t4)
        log(f'  ── {p} [{re.sub(chr(10), " ", title.group(1)).strip()[:50] if title else "?"}]')
        log(f'     시간 {list(dict.fromkeys(WHEN.findall(tx)))[:3]} · 채널 {list(dict.fromkeys(x.strip() for x in CH.findall(tx)))[:3]} · og:image {og[:1]}')
        time.sleep(0.2)
except Exception as e:
    log(f'  전주 못 가져옴 {e}')

# ── 2) 안동MBC 라디오 목록 ──
log('■ 2) 안동MBC 라디오 프로그램 목록')
for u in ['https://www.andongmbc.co.kr/main/radio/radio.php', 'https://andongmbc.co.kr/main/radio/radio_replay_category.php?no=150']:
    try:
        final, t = get(u)
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    tx = text(t)
    i = max(tx.find('라디오 프로그램'), 0)
    log(f'  {u}')
    log('    (본문) ' + tx[i: i + 2500])
    for h, inner in re.findall(r'<a[^>]+href=["\']([^"\']*(?:radio|replay)[^"\']*\?[^"\']*)["\'][^>]*>(.*?)</a>', t, re.S)[:40]:
        s = text(inner)
        if s and len(s) < 80:
            log(f'    링크 [{s}] {urllib.parse.urljoin(final, h)}')

with open('radio_probe46_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe46_result.txt 를 올려 주세요')
