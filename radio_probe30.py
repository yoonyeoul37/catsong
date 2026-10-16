# -*- coding: utf-8 -*-
# 지역 MBC 1차: 춘천 · 울산 · 안동 · 부산 라디오 편성표가 어디서 불러와지는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe30.py  →  radio_probe30_result.txt 가 생겨요
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


def get(url, referer=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=20, context=ctx())
    raw = r.read()
    for enc in ('utf-8', 'euc-kr'):
        try:
            return r.geturl(), raw.decode(enc)
        except Exception:
            pass
    return r.geturl(), raw.decode('utf-8', 'replace')


def flat(s):
    return re.sub(r'\s+', ' ', s).strip()


AJAX = re.compile(r'\$\.(?:ajax|get|post|getJSON)|fetch\(|axios|XMLHttpRequest|url\s*[:=]', re.I)
TIMES = re.compile(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b|\b(?:[01]?\d|2[0-3])\s*시\s*[0-5]?\d?\s*분?')

PAGES = [
    ('춘천MBC 음악FM', 'https://chmbc.co.kr/guide2/channel/radio'),
    ('춘천MBC 표준FM', 'https://chmbc.co.kr/guide2/channel/radio2'),
    ('울산MBC 표준FM', 'https://www.usmbc.co.kr/StandardFMProgramming'),
    ('울산MBC FM4U', 'https://www.usmbc.co.kr/FM4UProgramming'),
    ('안동MBC 라디오', 'https://www.andongmbc.co.kr/main/radio/radioTable.php'),
    ('부산MBC 라디오', 'https://busanmbc.co.kr/06_oar/oar05.asp'),
]

for name, url in PAGES:
    log('#' * 70)
    try:
        final, t = get(url)
    except Exception as e:
        log(f'■ {name} 못 가져옴: {e}')
        continue
    host = urllib.parse.urlparse(final).netloc
    log(f'■ {name} {final} · 글자 수 {len(t)}')
    # 1) 화면 글자에 시간이 있나
    body = re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)
    txt = flat(re.sub(r'<[^>]+>', ' ', body))
    times = TIMES.findall(txt)
    log(f'  화면 글자 속 시간 {len(times)}개 {times[:8]}')
    i = max(txt.find('편성'), 0)
    log('  화면 글자(편성 근처): ' + txt[i: i + 700])
    # 2) 표 · 그림 · iframe
    for f in re.findall(r'<iframe[^>]+src=["\']([^"\']+)', t, re.I)[:5]:
        log(f'  iframe {urllib.parse.urljoin(final, f)}')
    imgs = [u for u in re.findall(r'<img[^>]+src=["\']([^"\']+)', body, re.I)
            if re.search(r'sch|table|pyeon|편성|time|radio|upload|data', u, re.I)]
    for u in imgs[:8]:
        log(f'  그림 {urllib.parse.urljoin(final, u)}')
    # 3) 페이지 안 스크립트에서 데이터 부르는 곳
    for s in re.findall(r'<script[^>]*>(.*?)</script>', t, re.S | re.I):
        if AJAX.search(s) and len(s) < 20000:
            for m in list(AJAX.finditer(s))[:4]:
                log('  [안 스크립트] … ' + flat(s[max(0, m.start() - 200): m.end() + 400]))
    # 4) 같은 사이트 스크립트 파일에서 데이터 부르는 곳
    for src in re.findall(r'<script[^>]+src=["\']([^"\']+)', t, re.I):
        u = urllib.parse.urljoin(final, src)
        if urllib.parse.urlparse(u).netloc != host or re.search(r'jquery|bootstrap|swiper|slick|gsap|lib/', u, re.I):
            continue
        try:
            _, js = get(u, final)
        except Exception:
            continue
        hits = [m for m in AJAX.finditer(js)]
        hits = [m for m in hits if re.search(r'sched|table|radio|program|편성|guide|time', js[max(0, m.start() - 300): m.end() + 300], re.I)]
        if hits:
            log(f'  [스크립트 파일] {u}')
            for m in hits[:4]:
                log('    … ' + flat(js[max(0, m.start() - 200): m.end() + 400]))
        time.sleep(0.2)
    # 5) 주소 단서
    for a in sorted(set(re.findall(r'["\'](/[^"\'\s]*(?:ajax|api|json|Ajax|Api|Json|schedule|Schedule|timetable|TimeTable|guide)[^"\'\s]*)["\']', t)))[:15]:
        log(f'  주소 단서 {a}')
    time.sleep(0.5)

with open('radio_probe30_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe30_result.txt 를 올려 주세요')
