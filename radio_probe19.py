# -*- coding: utf-8 -*-
# EBS FM · EBS 반디: 앱이 받는 편성 데이터에 사진 주소가 있는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe19.py  →  radio_probe19_result.txt 가 생겨요
import json, re, ssl, urllib.request

out = []


def log(s=''):
    print(s)
    out.append(str(s))


IMG = re.compile(r'\.(jpg|jpeg|png|gif|webp)|img|image|thumb|photo|poster|banner|file|path', re.I)


def interesting(d):
    return {k: v for k, v in d.items()
            if v not in (None, '', 0) and (IMG.search(k) or (isinstance(v, str) and IMG.search(v)))}


for name, code in [('EBS FM', 'FM'), ('EBS 반디', 'IRADIO')]:
    log('#' * 60)
    url = f'https://www.ebs.co.kr/onair/scheduleNew.json?channelCodeString={code}&mode=newlist'
    try:
        raw = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'}),
                                     timeout=20, context=ssl.create_default_context()).read().decode('utf-8', 'replace')
        data = json.loads(raw)
    except Exception as e:
        log(f'■ {name} 못 가져옴: {e}')
        continue
    log(f'■ {name} · 맨 위 이름들: {", ".join(data.keys()) if isinstance(data, dict) else type(data)}')
    now = data.get('nowProgram') or {}
    log(f"[지금 방송] {now.get('title')} · 이름들: {', '.join(now.keys())}")
    for k, v in interesting(now).items():
        log(f'    {k} = {v}')
    progs = data.get('program') or []
    log(f'[편성 목록] {len(progs)}개')
    if progs:
        log('  첫 칸 이름들: ' + ', '.join(progs[0].keys()))
    for it in progs[:20]:
        log(f"  - {it.get('start')}~{it.get('end')} {it.get('title')}")
        for k, v in interesting(it).items():
            log(f'      {k} = {v}')

with open('radio_probe19_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe19_result.txt 를 올려 주세요')
