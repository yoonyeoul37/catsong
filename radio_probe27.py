# -*- coding: utf-8 -*-
# 편성표 찾기: MBC 올댓뮤직 · CBS JOY4U · 극동방송 AM · 제주극동방송 (앱 코드는 안 건드려요)
# 실행: python radio_probe27.py  →  radio_probe27_result.txt 가 생겨요
import re, ssl, json, time, datetime, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE
today = datetime.date.today()


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, referer=None, ajax=False):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    if ajax:
        h['X-Requested-With'] = 'XMLHttpRequest'
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=20, context=c)
    return r.read().decode('utf-8', 'replace')


def body(t):
    return re.sub(r'<script.*?</script>|<style.*?</style>', '', t, flags=re.S | re.I)


# ── 1) MBC 올댓뮤직: 앱이 쓰는 MBC 편성표 주소에 채널 이름만 바꿔 보기 ──
log('■ 1) MBC 올댓뮤직')
for s in ['FM', 'CHM', 'CH', 'ATM', 'ALLTHAT', 'AllThatMusic', 'chm', 'ALL', 'CHMUSIC', 'MUSIC']:
    url = f'https://control.imbc.com/Schedule/Radio/Time?sType={s}&broadDate={today:%Y%m%d}'
    try:
        t = get(url, 'https://www.imbc.com/')
        try:
            d = json.loads(t)
            items = d if isinstance(d, list) else next((v for v in d.values() if isinstance(v, list)), []) if isinstance(d, dict) else []
            names = [str(i.get('Title') or i.get('ProgramTitle') or i.get('title') or '') for i in items if isinstance(i, dict)][:6]
            keys = list(items[0].keys())[:20] if items and isinstance(items[0], dict) else []
            log(f'  sType={s}: {len(items)}개 · {names}')
            if s == 'FM':
                log(f'     (FM 칸 이름들: {keys})')
        except Exception:
            log(f'  sType={s}: JSON 아님 · {t[:150]!r}')
    except Exception as e:
        log(f'  sType={s}: 못 가져옴 {e}')
    time.sleep(0.3)
try:
    t = get('https://www.imbc.com/broad/radio/', 'https://www.imbc.com/')
    for m in sorted(set(re.findall(r'[^"\'\s]*(?:allthat|chm|CHM|올댓)[^"\'\s<]*', t)))[:20]:
        log(f'  iMBC 라디오 페이지 단서: {m}')
except Exception as e:
    log(f'  iMBC 라디오 페이지 못 가져옴 {e}')

# ── 2) CBS JOY4U: 앱이 쓰는 CBS 편성표 데이터에 JOY4U가 있는지 ──
log('■ 2) CBS JOY4U')
try:
    d = json.loads(get('https://www.cbs.co.kr/schedule/radio/ajax', 'https://www.cbs.co.kr/schedule', ajax=True))
    media = {}
    for k, items in (d.items() if isinstance(d, dict) else []):
        if isinstance(items, list):
            for it in items:
                if isinstance(it, dict):
                    m = it.get('media') or {}
                    media.setdefault((m.get('id'), m.get('name')), []).append(it.get('name'))
    for (mid, mname), names in media.items():
        log(f'  방송 {mid} {mname}: {len(names)}개 · {names[:4]}')
except Exception as e:
    log(f'  CBS 편성표 못 가져옴 {e}')
for u in ['https://www.cbs.co.kr/schedule', 'https://www.cbs.co.kr/radio/joy4u', 'https://joy4u.cbs.co.kr/']:
    try:
        t = get(u, 'https://www.cbs.co.kr/')
        hits = sorted(set(re.findall(r'[^"\'\s]*(?:joy|JOY|radio00\d|cmc)[^"\'\s<]*', t)))[:15]
        log(f'  {u} → 글자 수 {len(t)} · 단서 {hits}')
    except Exception as e:
        log(f'  {u} → 못 가져옴 {e}')

# ── 3) 극동방송 AM · 제주: 서울 편성표 페이지의 채널 탭/주소 찾기 ──
log('■ 3) 극동방송 AM · 제주')
for u in ['https://seoul.febc.net/radio/schedule', 'https://jeju.febc.net/radio/schedule', 'https://jeju.febc.net/',
          'https://seoul.febc.net/radio/schedule?channel=AM', 'https://seoul.febc.net/radio/schedule?type=am']:
    try:
        t = get(u, u.split('/radio')[0] + '/')
        b = body(t)
        n = b.count('accordion-item component-collapse')
        times = re.findall(r'<span class="time">(\d{1,2}:\d{2})</span>', b)
        tits = [re.sub(r'<[^>]+>|\s+', ' ', x).strip() for x in re.findall(r'<p class="tit">(.*?)</p>', b, re.S)][:6]
        log(f'  {u} → 글자 수 {len(t)} · 칸 {n}개 · 시간 {len(times)}개 · 첫 프로그램 {tits}')
        links = sorted(set(re.findall(r'href="([^"]*(?:schedule|am|AM|channel|jeju)[^"]*)"', b)))[:20]
        for l in links:
            log(f'     링크 {l}')
        tabs = re.findall(r'<(?:button|a|li)[^>]*>\s*(?:<[^>]+>)*\s*([^<]{0,20}(?:AM|FM|표준|음악|제주)[^<]{0,20})<', b)[:15]
        if tabs:
            log(f'     탭 글자 {tabs}')
    except Exception as e:
        log(f'  {u} → 못 가져옴 {e}')
    time.sleep(0.3)

with open('radio_probe27_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe27_result.txt 를 올려 주세요')
