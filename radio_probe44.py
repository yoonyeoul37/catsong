# -*- coding: utf-8 -*-
# 지역 KBS 사진 2차: 사진 주소가 진짜 프로그램 사진인지, 같은 기본 그림이 반복되는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe44.py  →  radio_probe44_result.txt (1~2분)
import re, ssl, json, datetime, urllib.request, concurrent.futures as cf

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
c = ssl.create_default_context()
today = datetime.date.today()
LOCALS = {'00': '서울', '10': '부산', '20': '창원', '21': '진주', '30': '대구', '31': '안동', '32': '포항', '40': '광주',
          '41': '목포', '43': '순천', '50': '전주', '60': '대전', '70': '청주', '80': '춘천', '81': '강릉', '82': '원주', '90': '제주'}
CHANNELS = {'21': '1라디오', '22': '해피FM', '24': '1FM'}


def sched(local, ch):
    url = ('https://static.api.kbs.co.kr/mediafactory/v1/schedule/weekly?rtype=json'
           f'&local_station_code={local}&channel_code={ch}'
           f'&program_planned_date_from={today:%Y%m%d}&program_planned_date_to={today:%Y%m%d}')
    try:
        r = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=15, context=c)
        data = json.loads(r.read().decode('utf-8', 'ignore'))
    except Exception as e:
        return (local, ch, None, str(e)[:60])
    items = []
    for d in data if isinstance(data, list) else []:
        items += d.get('schedules') or []
    return (local, ch, items, None)


def key(t):
    return re.sub(r'[\s,.·!?~\-<>《》〈〉()\[\]]', '', t or '').lower()


jobs = [(l, ch) for l in LOCALS for ch in CHANNELS]
with cf.ThreadPoolExecutor(8) as ex:
    res = list(ex.map(lambda j: sched(*j), jobs))

out = []
from collections import Counter
allimgs = Counter()
for local, ch, items, err in res:
    for s_ in items or []:
        allimgs[s_.get('image_w') or ''] += 1
out.append('■ 가장 많이 반복되는 사진 주소 (같은 기본 그림인지 보기)')
for u, n in allimgs.most_common(12):
    out.append(f'  {n}번 · {u}')
for local, ch, items, err in res:
    if (local, ch) in (('10', '21'), ('00', '21'), ('90', '22')) and items:
        out.append(f'■ KBS {LOCALS[local]} {CHANNELS[ch]} 오늘 편성 · 사진')
        for s_ in items:
            out.append(f"  {s_.get('service_start_time') or s_.get('program_planned_start_time')} {s_.get('program_title')} | {s_.get('image_w')}")
print('\n'.join(out))
with open('radio_probe44_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe44_result.txt 를 올려 주세요')
