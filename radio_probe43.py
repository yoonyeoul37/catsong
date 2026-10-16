# -*- coding: utf-8 -*-
# 지역 KBS 사진 점검: 지역 편성표에서 사진 없는 프로그램이 몇 개인지, 서울 KBS 사진을 빌려 쓸 수 있는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe43.py  →  radio_probe43_result.txt (1~2분)
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
seoul_pics = {}
for local, ch, items, err in res:
    if local == '00' and items:
        for s in items:
            if s.get('image_w'):
                seoul_pics.setdefault(key(s.get('program_title')), s['image_w'])
sample_keys = None
miss_titles = {}
tot = {'all': 0, 'pic': 0, 'borrow': 0, 'miss': 0}
for local, ch, items, err in res:
    if local == '00':
        continue
    name = f'KBS {LOCALS[local]} {CHANNELS[ch]}'
    if err:
        out.append(f'  {name}: 못 가져옴 {err}')
        continue
    if not items:
        out.append(f'  {name}: 편성 0개 (이 채널 없음)')
        continue
    if sample_keys is None:
        sample_keys = list(items[0].keys())
    n = len(items)
    pic = sum(1 for s in items if s.get('image_w'))
    borrow = [s for s in items if not s.get('image_w') and key(s.get('program_title')) in seoul_pics]
    miss = [s for s in items if not s.get('image_w') and key(s.get('program_title')) not in seoul_pics]
    tot['all'] += n
    tot['pic'] += pic
    tot['borrow'] += len(borrow)
    tot['miss'] += len(miss)
    out.append(f'  {name}: 프로그램 {n}개 · 사진 있음 {pic} · 서울 사진 빌리기 가능 {len(borrow)} · 사진 없음 {len(miss)}')
    for s in miss:
        t = s.get('program_title') or ''
        miss_titles.setdefault(t, []).append(name)
        if len(miss_titles[t]) == 1:
            extra = {k: s.get(k) for k in ('program_code', 'program_id', 'program_url', 'homepage_url', 'image_h', 'image_w', 'program_genre') if k in s}
            out.append(f'      사진 없음: {t} · {extra}')

head = [f'■ 오늘 지역 KBS 라디오 전체: 프로그램 {tot["all"]}개 · 사진 있음 {tot["pic"]} · 서울 사진 빌리기 가능 {tot["borrow"]} · 사진 없음 {tot["miss"]}',
        f'■ 편성 한 칸에 들어 있는 정보 이름: {sample_keys}', '']
out = head + out
print('\n'.join(out))
with open('radio_probe43_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe43_result.txt 를 올려 주세요')
