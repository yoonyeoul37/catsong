# -*- coding: utf-8 -*-
# 전주MBC 라디오 프로그램 이름 · 시간 · 사진 + 전주 라디오 편성표 페이지가 데이터를 부르는 곳 + 안동 FM4U·표준FM 프로그램 사진
# (앱 코드는 안 건드려요)   실행: python radio_probe47.py  →  radio_probe47_result.txt
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


def get(url, ref=None, data=None, ajax=False):
    h = {'User-Agent': UA}
    if ref:
        h['Referer'] = ref
    if ajax:
        h['X-Requested-With'] = 'XMLHttpRequest'
    body = urllib.parse.urlencode(data).encode() if data else None
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h, data=body), timeout=15, context=ctx())
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


log('■ 1) 전주MBC 라디오 프로그램 (fm_ = FM4U?, sfm_ = 표준FM?)')
for code in ['fm_000001', 'fm_000002', 'fm_000003', 'fm_000004', 'fm_210215', 'fm_22112501', 'fm_22112502', 'fm_22112503',
             'fm_24110101', 'sfm_000002', 'sfm_000006', 'sfm_000007', 'sfm_230417', 'sfm_260330']:
    u = f'https://www.jmbc.co.kr/program/{code}'
    try:
        f, t = get(u, 'https://www.jmbc.co.kr/')
    except Exception as e:
        log(f'  {code} → X {e}')
        continue
    og = dict(re.findall(r'property=["\']og:(title|description|image)["\']\s+content=["\']([^"\']*)', t))
    heads = [re.sub(r'<[^>]+>|\s+', ' ', h).strip() for h in re.findall(r'<h[1-4][^>]*>(.*?)</h[1-4]>', t, re.S)]
    heads = [h for h in heads if h and len(h) < 40][:5]
    tx = text(t)
    i = tx.find('방송')
    log(f'  {code} · og:title {og.get("title")!r} · 제목후보 {heads}')
    log(f'     사진 {og.get("image")} · 설명 {(og.get("description") or "")[:80]!r}')
    m = re.search(r'(?:방송\s*시간|방송\s*일시|매일|평일|월\s*[~\-]\s*[금토]|토요일|일요일)[^.]{0,60}', tx)
    log(f'     시간 글자: {m.group(0) if m else "-"}')
    time.sleep(0.2)

log('■ 2) 전주MBC 라디오 편성표 페이지(/schedule/sfm · /schedule/fm4u) 안 스크립트')
for u in ['https://www.jmbc.co.kr/schedule/sfm', 'https://www.jmbc.co.kr/schedule/fm4u']:
    try:
        f, t = get(u, 'https://www.jmbc.co.kr/')
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    log(f'  {u} · 글자 수 {len(t)}')
    for s in re.findall(r'<script[^>]*>(.*?)</script>', t, re.S):
        if re.search(r'ajax|fetch|url|schedule', s, re.I) and len(s) < 15000:
            for m in re.finditer(r'ajax|fetch\(|url\s*:|\.get\(|\.post\(|schedule', s, re.I):
                log('    … ' + re.sub(r'\s+', ' ', s[max(0, m.start() - 150): m.end() + 300]))
                break
    for a in sorted(set(re.findall(r'["\'](/[^"\']*(?:ajax|api|json|schedule|Schedule)[^"\']*)["\']', t)))[:15]:
        log(f'    주소 단서 {a}')
    body = text(t)
    i = max(body.find('편성'), 0)
    log('    (본문) ' + body[i: i + 600])

log('■ 3) 안동MBC 프로그램 페이지 사진')
for u in ['https://www.andongmbc.co.kr/main/radio/radio_noon.php?m=2', 'https://www.andongmbc.co.kr/main/radio/radio_teuroteu.php?m=3',
          'https://www.andongmbc.co.kr/main/radio/radio_musicwalk.php?m=5', 'https://www.andongmbc.co.kr/main/radio/radio_today.php?m=1']:
    try:
        f, t = get(u)
    except Exception as e:
        log(f'  {u} → X {e}')
        continue
    imgs = [urllib.parse.urljoin(f, x) for x in re.findall(r'<img[^>]+src=["\']([^"\']+)', t)
            if not re.search(r'logo|icon|btn|sns|subvisual|seo_img|ytimg|/img/common', x, re.I)]
    tx = text(t)
    m = re.search(r'방송\s*시간[^가-힣]{0,5}[^.]{0,60}', tx)
    log(f'  {u}')
    log(f'     시간 {m.group(0) if m else "-"}')
    for x in imgs[:4]:
        log(f'     사진 {x}')

with open('radio_probe47_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe47_result.txt 를 올려 주세요')
