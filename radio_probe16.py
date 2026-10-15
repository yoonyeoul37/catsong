# -*- coding: utf-8 -*-
# 국방FM: 앱이 받는 편성 데이터에 사진 주소가 있는지 (앱 코드는 안 건드려요)
# 실행: python radio_probe16.py  →  radio_probe16_result.txt 가 생겨요
import json, re, ssl, urllib.request

out = []


def log(s=''):
    print(s)
    out.append(str(s))


req = urllib.request.Request(
    'https://radio.dema.mil.kr/web/api/v1/media/fm/nowProgram/ajaxList.do',
    data=json.dumps({'sort_type': 'TIME', 'program_type': '', 'select_type': ''}).encode(),
    headers={'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
             'Referer': 'https://radio.dema.mil.kr/web/radio/main.do', 'Content-Type': 'application/json'})
data = json.loads(urllib.request.urlopen(req, timeout=20, context=ssl.create_default_context()).read().decode('utf-8'))
m = data.get('map') or {}
log('map 안의 이름들: ' + ', '.join(m.keys()))

IMG = re.compile(r'\.(jpg|jpeg|png|gif|webp)|img|image|icon|photo|thumb|file|path', re.I)


def interesting(d):
    return {k: v for k, v in d.items() if v not in (None, '', 0) and (IMG.search(k) or (isinstance(v, str) and IMG.search(v)))}


cur = m.get('timeTableExt') or {}
log('=' * 60)
log('[지금 방송 timeTableExt] 제목: ' + str(cur.get('fm_program_title')))
for k, v in interesting(cur).items():
    log(f'  {k} = {v}')

lst = m.get('fmNowHomeList') or []
log('=' * 60)
log(f'[편성 목록 fmNowHomeList] {len(lst)}개')
for it in lst[:40]:
    log(f"- {it.get('homepage_nm')} | {it.get('regular_brodcasting')}")
    for k, v in interesting(it).items():
        log(f'    {k} = {v}')

# 다른 목록에도 사진이 있는지
for k, v in m.items():
    if isinstance(v, list) and k != 'fmNowHomeList' and v and isinstance(v[0], dict):
        log('=' * 60)
        log(f'[다른 목록 {k}] {len(v)}개 · 첫 칸 사진 관련: {interesting(v[0])}')

with open('radio_probe16_result.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print('\n완료! radio_probe16_result.txt 를 올려 주세요')
