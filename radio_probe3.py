# -*- coding: utf-8 -*-
# CBS 편성표 데이터에 프로그램 사진이 들어 있는지 보기 (앱 코드는 안 건드려요)
# 실행: python radio_probe3.py  →  radio_probe3_result.txt 가 생겨요
import json, re, ssl, urllib.request

UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36'
out = []

def log(s=''):
    print(s)
    out.append(str(s))

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': UA, 'Referer': 'https://www.cbs.co.kr/schedule',
                                               'X-Requested-With': 'XMLHttpRequest'})
    with urllib.request.urlopen(req, timeout=30, context=ssl.create_default_context()) as r:
        return r.read().decode('utf-8', errors='replace')

data = json.loads(get('https://www.cbs.co.kr/schedule/radio/ajax'))
log('맨 위 이름들: ' + ', '.join(f'{k}({len(v) if isinstance(v, list) else type(v).__name__})' for k, v in data.items()))
dates = {}
for k, v in data.items():
    if isinstance(v, list):
        for it in v:
            if isinstance(it, dict):
                dates.setdefault(k, set()).add(it.get('date'))
for k, ds in dates.items():
    log(f'{k} 날짜들: {sorted(d for d in ds if d)}')

shown = 0
for k, v in data.items():
    if not isinstance(v, list):
        continue
    for it in v:
        if isinstance(it, dict) and it.get('program'):
            log('=' * 60)
            log(f'[{k}] 프로그램 정보가 있는 칸 하나 (그대로)')
            log(json.dumps(it, ensure_ascii=False, indent=1)[:3000])
            shown += 1
            break
    if shown >= 2:
        break

log('=' * 60)
html = get('https://www.cbs.co.kr/program/home/cbs_P000222')
for m in re.finditer(r'<meta[^>]+property=["\']og:image["\'][^>]*>', html):
    log('프로그램 홈 대표 사진: ' + m.group(0))
for m in list(re.finditer(r'<img[^>]+src=["\']([^"\']+)["\']', html))[:12]:
    log('프로그램 홈 사진 후보: ' + m.group(1))

with open('radio_probe3_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe3_result.txt 를 올려 주세요')
