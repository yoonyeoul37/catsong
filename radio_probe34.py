# -*- coding: utf-8 -*-
# 지역 MBC 3차: 제주·대전처럼 '날짜별 라디오 편성표'가 있는 같은 모양 홈페이지 6곳 (앱 코드는 안 건드려요)
# 실행: python radio_probe34.py  →  radio_probe34_result.txt
import re, ssl, time, urllib.request, urllib.parse, concurrent.futures as cf

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'


def ctx():
    c = ssl.create_default_context()
    c.check_hostname = False
    c.verify_mode = ssl.CERT_NONE
    return c


def get(url, referer=None):
    h = {'User-Agent': UA, 'Accept-Language': 'ko-KR,ko;q=0.9'}
    if referer:
        h['Referer'] = referer
    r = urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=15, context=ctx())
    return r.geturl(), r.read().decode('utf-8', 'replace')


def text(t):
    t = re.sub(r'<script.*?</script>|<style.*?</style>', ' ', t, flags=re.S | re.I)
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', t)).strip()


SITES = [('제주MBC', 'https://jejumbc.com', ['/FMTimetable', '/FM4UTimetable']),
         ('대전MBC', 'https://tjmbc.co.kr', ['/ProgrammingTable']),
         ('대구MBC', 'https://dgmbc.com', ['/FMTimetable', '/FM4UTimetable']),
         ('광주MBC', 'https://kjmbc.co.kr', ['/Timetable']),
         ('목포MBC', 'https://www.mpmbc.co.kr', ['/TimeTable']),
         ('울산MBC', 'https://www.usmbc.co.kr', ['/TVTimeTable'])]


def scan(item):
    name, base, paths = item
    L = [f'■ {name}']
    first = True
    for p in paths:
        try:
            final, t = get(base + p)
        except Exception as e:
            L.append(f'  {p} → X {str(e)[:50]}')
            continue
        tx = text(t)
        times = re.findall(r'\b(?:[01]?\d|2[0-3]):[0-5]\d\b', tx)
        L.append(f'  {p} → {final} · 글자 수 {len(t)} · 시간 {len(times)}개')
        # 탭 · 날짜 링크 (라디오 편성표 진짜 주소 찾기)
        hrefs = []
        for h, a in re.findall(r'<a[^>]+href=["\']([^"\'#]+)["\'][^>]*>(.*?)</a>', t, re.S | re.I):
            a = re.sub(r'<[^>]+>|\s+', ' ', a).strip()
            if re.search(r'FM|편성|Timetable|TimeTable|Programming|\d{1,2}\.\d{1,2}|prev|next|date|day', h + ' ' + a, re.I):
                hrefs.append(f'[{a[:15]}] {h}')
        for h in list(dict.fromkeys(hrefs))[:25]:
            L.append('    링크 ' + h)
        # 날짜 바꾸는 단서 (onclick, data-*, 스크립트 안 주소)
        for m in sorted(set(re.findall(r'(?:onclick|data-[\w-]+)=["\']([^"\']*(?:date|Date|day|20\d{6}|20\d\d-\d\d-\d\d)[^"\']*)["\']', t)))[:10]:
            L.append('    날짜 단서 ' + m)
        for m in sorted(set(re.findall(r'["\'](/[A-Za-z/]*(?:Timetable|TimeTable|Programming|Schedule)[^"\']*)["\']', t)))[:15]:
            L.append('    주소 단서 ' + m)
        if first and len(times) >= 8:
            # 한 줄(시간·제목·로컬방송 표시)이 HTML로 어떻게 생겼는지
            i = t.find(times[3]) if len(times) > 3 else t.find(times[0])
            L.append('    --- HTML 한 줄 모양 ---')
            L.append('    ' + re.sub(r'\s+', ' ', t[max(0, i - 700): i + 900]))
            first = False
        time.sleep(0.3)
    return L


out = []
with cf.ThreadPoolExecutor(3) as ex:
    for L in ex.map(scan, SITES):
        for l in L:
            print(l)
            out.append(l)

with open('radio_probe34_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe34_result.txt 를 올려 주세요')
