# -*- coding: utf-8 -*-
# 지역 MBC 덮어쓰기 추가: 울산MBC 표준FM · FM4U, 대구MBC 표준FM (지역 프로그램 시간 + 지역 사진)
# 실행: python apply_mbc_overlay2.py
import os, sys

EDITS = {
    'make_schedule.py': [("    '안동MBC 표준FM': ('FM', [\n", "    '울산MBC 표준FM': ('FM', [\n        ('월-금', '14:20', '16:00', '배윤호, 이남미의 확깨는 라디오',\n         'https://www.usmbc.co.kr/storage/program/controller/usmbc/2025/10/13/104752-3A81-8788-5C52-W9DDLTY3AXN605B2HR6B.jpg'),\n        ('월-금', '18:05', '19:00', '김연경의 퇴근길 톡톡',\n         'https://www.usmbc.co.kr/storage/program/controller/usmbc/2020/03/02/101655-6B56-E495-4006-9QAH2BZKSSRQU48YYSP5.jpg'),\n    ]),\n    '울산MBC FM4U': ('FM4U', [\n        ('월-금', '12:00', '14:00', '정오의 희망곡 박성은입니다',\n         'https://www.usmbc.co.kr/storage/program/controller/usmbc/2024/01/29/095810-0610-AF94-C547-R8BVA9CZXGGWV625S8JN.jpg'),\n    ]),\n    '대구MBC 표준FM': ('FM', [\n        ('월-금', '08:30', '08:35', '달구벌만평',\n         'https://dgmbc.com/storage/program/2021/07/27/174847-0335-49FF-9035-80RQHPQ67GXP4BUOXS6A.jpg'),\n        ('월-금', '08:35', None, '여론현장',\n         'https://dgmbc.com/storage/program/2022/09/05/091026-9C84-D424-BBF2-8TU3J9ORGJEM1ZL9QAYS.jpg'),\n        ('월-금', '14:20', '16:00', '즐거운 오후2시',\n         'https://dgmbc.com/storage/program/former_MBC_ALPHA/dg/2019/12/ddcde87fb6b3d81bc65b1d90e0850f8460e6862ee5de2eef9558cee514459ad4573006bd3778b6ec1bbddd4939bde845de7b006e3449878a356f0eed6ba7ff2b.jpg'),\n    ]),\n    '안동MBC 표준FM': ('FM', [\n")],
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
    cnt = lambda x: [x.count(ch) - x.count(cl) for ch, cl in ('()', '{}', '[]')]
    before = cnt(t)
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
    elif cnt(t) != before:  # 고치기 전과 괄호 짝이 같아야 함
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
