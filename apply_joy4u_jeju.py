# -*- coding: utf-8 -*-
# 편성표 추가: CBS JOY4U · FEBC 제주극동방송 (편성표 만드는 파일 + 상세페이지 편성표 아이콘)
# 실행: python apply_joy4u_jeju.py   (프로젝트 폴더에서)
import os, sys

EDITS = {
    'make_schedule.py': [("CBS_MEDIA = {'radio001': 'CBS 음악FM', 'radio002': 'CBS 표준FM'}", "CBS_MEDIA = {'radio001': 'CBS 음악FM', 'radio002': 'CBS 표준FM', 'radio003': 'CBS JOY4U'}"), ("def febc():\n    page = fetch('https://seoul.febc.net/radio/schedule', 'https://seoul.febc.net/')\n", 'def febc():\n    out = {}\n    for station, base in [(\'FEBC 극동방송\', \'https://seoul.febc.net\'), (\'FEBC 제주극동방송\', \'https://jeju.febc.net\')]:\n        try:\n            clean = febc_day(base)\n        except Exception as e:\n            print(f\'  ({station} 못 가져옴: {e})\')\n            continue\n        if len(clean) >= 5:\n            out[station] = {day_key(today_kst()): clean}\n    return out\n\n\ndef febc_day(base):\n    """극동방송 지역 홈페이지의 오늘 편성표 (서울 · 제주 모양이 같음)"""\n    page = fetch(base + \'/radio/schedule\', base + \'/\')\n'), ("            img = 'https://seoul.febc.net' + img\n", '            img = base + img\n'), ("    clean = clean_day(progs)\n    return {'FEBC 극동방송': {day_key(today_kst()): clean}} if len(clean) >= 5 else {}\n", '    return clean_day(progs)  # 오늘 편성 (방송 이름은 febc()에서 붙임)\n')],
    'radio_player_screen.dart': [
        ("""        name == 'FEBC 극동방송' ||
""", """        name == 'FEBC 극동방송' ||
        name == 'FEBC 제주극동방송' ||
"""),
    ],
}


def find(name):
    for root, _, files in list(os.walk('tools')) + list(os.walk('lib')):
        if name in files:
            return os.path.join(root, name)
    return None


done = {}
total = 0
for name, edits in EDITS.items():
    p = find(name)
    if not p:
        print(f'❌ {name} 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요) — 아무것도 저장 안 했어요'); sys.exit(1)
    with open(p, 'r', encoding='utf-8', newline='') as f:
        t = f.read()
    crlf = '\r\n' in t
    t = t.replace('\r\n', '\n')
    n = 0
    for i, (o, new) in enumerate(edits, 1):
        if new in t:
            continue
        if t.count(o) != 1:
            print(f'❌ {name} {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
        t = t.replace(o, new)
        print(f'✔ {name} {i}번 고침')
        n += 1
    if name.endswith('.py'):
        try:
            compile(t, p, 'exec')
        except SyntaxError as e:
            print(f'❌ {name} 고친 뒤 코드가 맞지 않아요 ({e}) — 아무것도 저장 안 했어요'); sys.exit(1)
    elif t.count('(') != t.count(')') or t.count('{') != t.count('}') or t.count('[') != t.count(']'):
        print(f'❌ {name} 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
    done[p] = (t, crlf, n)
    total += n

if total == 0:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, (t, crlf, n) in done.items():
    if n:
        with open(p, 'w', encoding='utf-8', newline='') as f:
            f.write(t.replace('\n', '\r\n') if crlf else t)
print('완료!')
