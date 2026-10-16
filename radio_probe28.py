# -*- coding: utf-8 -*-
# 편성표 찾기 2: 극동방송 AM(서울 페이지 안 FM/AM 나누기) · MBC 올댓뮤직 (앱 코드는 안 건드려요)
# 실행: python radio_probe28.py  →  radio_probe28_result.txt 가 생겨요
import re, ssl, time, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []
c = ssl.create_default_context()
c.check_hostname = False
c.verify_mode = ssl.CERT_NONE


def log(s=''):
    print(s)
    out.append(str(s))


def get(url, referer=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=20, context=c)
    return r.read().decode('utf-8', 'replace')


def flat(s):
    return re.sub(r'\s+', ' ', s)


# ── 1) 극동방송 서울 편성표: FM/AM 구분 단서 ──
log('■ 1) 극동방송 서울 편성표 페이지')
t = re.sub(r'<style.*?</style>', '', get('https://seoul.febc.net/radio/schedule', 'https://seoul.febc.net/'), flags=re.S | re.I)
first = t.find('accordion-item component-collapse')
log(f'  첫 편성 칸 위치 {first}')
log('  --- 첫 칸 앞부분 (탭·채널 이름이 여기 있을 가능성) ---')
log(flat(t[max(0, first - 3500): first]))
# 편성 칸들이 어느 큰 묶음 안에 있는지: 칸마다 바로 앞에 나온 id/class/data-* 묶음 이름
log('  --- 칸마다 시간 · 제목 · 앞쪽 묶음 표시 ---')
marks = [(m.start(), m.group(0)) for m in re.finditer(r'(?:id|data-[\w-]+|class)="[^"]*(?:tab|pane|channel|am|fm|AM|FM|panel|swiper)[^"]*"', t)]
for m in re.finditer(r'accordion-item component-collapse', t):
    seg = t[m.start(): m.start() + 2500]
    tm = re.search(r'<span class="time">(\d{1,2}:\d{2})</span>', seg)
    ti = re.search(r'<p class="tit">(.*?)</p>', seg, re.S)
    prev = [x for x in marks if x[0] < m.start()]
    log(f'  {tm.group(1) if tm else "?"} · {flat(re.sub("<[^>]+>", "", ti.group(1))).strip() if ti else "?"} · 앞 표시: {prev[-1][1] if prev else "-"}')
# 스크립트 안의 편성표 주소 단서
for s in sorted(set(re.findall(r'["\'](/[^"\']*(?:schedule|Schedule)[^"\']*)["\']', t)))[:20]:
    log(f'  주소 단서 {s}')
for s in sorted(set(re.findall(r'[^\s"\'<>]{0,40}(?:1188|106\.9|AM|am)[^\s"\'<>]{0,40}', re.sub(r'<script.*?</script>', '', t, flags=re.S))))[:30]:
    log(f'  AM 단서 {s}')

# ── 2) MBC 올댓뮤직: iMBC 라디오 페이지에서 올댓뮤직 주변 ──
log('■ 2) MBC 올댓뮤직')
for u in ['https://www.imbc.com/broad/radio/', 'https://mini.imbc.com/', 'https://www.imbc.com/broad/radio/allthatmusic/']:
    try:
        t2 = get(u, 'https://www.imbc.com/')
    except Exception as e:
        log(f'  {u} → 못 가져옴 {e}')
        continue
    log(f'  {u} → 글자 수 {len(t2)}')
    for m in list(re.finditer(r'allthat|올댓|chm|CHM', t2))[:8]:
        log('    … ' + flat(t2[max(0, m.start() - 250): m.end() + 250]))
    time.sleep(0.3)

with open('radio_probe28_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe28_result.txt 를 올려 주세요')
