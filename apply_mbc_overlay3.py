# -*- coding: utf-8 -*-
# 지역 MBC 덮어쓰기 추가: 전주MBC 표준FM · FM4U, 안동MBC FM4U (+ 안동 표준FM 주말 트로트세상)
# 실행: python apply_mbc_overlay3.py
import os, sys

EDITS = {
    'make_schedule.py': [("WEEK = {'매일': range(7), '월-금': range(5), '토': [5], '일': [6], '토일': [5, 6]}", "WEEK = {'매일': range(7), '월-금': range(5), '월-토': range(6), '토': [5], '일': [6], '토일': [5, 6]}"), ("    '안동MBC 표준FM': ('FM', [\n        ('월-금', '18:05', '19:00', '라디오 오늘', None),\n    ]),\n", "    '안동MBC 표준FM': ('FM', [\n        ('월-금', '18:05', '19:00', '라디오 오늘', None),\n        ('토일', '14:05', '16:00', '즐거운 트로트세상', None),\n    ]),\n    '안동MBC FM4U': ('FM4U', [\n        ('매일', '12:00', '14:00', '정오의 희망곡 (안동MBC)', None),\n    ]),\n    '전주MBC 표준FM': ('FM', [\n        ('매일', '10:05', '11:00', '여성시대 (전주MBC)', 'https://www.jmbc.co.kr/uploads/pgm/sfm_000002_top_m.jpg'),\n        ('월-금', '11:05', None, '오늘의 발견', 'https://www.jmbc.co.kr/uploads/pgm/sfm_260330_top_m.jpg'),\n        ('월-금', '18:05', '19:00', '귀가번쩍 여섯시', 'https://www.jmbc.co.kr/uploads/pgm/sfm_000007_top_m.jpg'),\n        ('월-금', '19:20', '19:50', '뉴스 & 이슈', 'https://www.jmbc.co.kr/uploads/pgm/sfm_000006_top_m.jpg'),\n    ]),\n    '전주MBC FM4U': ('FM4U', [\n        ('매일', '07:00', '09:00', 'FM모닝쇼 김차동입니다', 'https://www.jmbc.co.kr/uploads/pgm/fm_000001_top_m_200914.png'),\n        ('일', '11:00', '12:00', '국악이 좋다', 'https://www.jmbc.co.kr/uploads/pgm/fm_000004_top_m.jpg'),\n        ('월-금', '12:00', None, '다윤이의 정오의 희망곡', 'https://www.jmbc.co.kr/uploads/pgm/fm_000002_top_m.jpg'),\n        ('토', '12:00', '14:00', '오프로드 이영래입니다', 'https://www.jmbc.co.kr/uploads/pgm/fm_22112503_top_m.jpg'),\n        ('월-토', '18:00', '20:00', '식스센스', 'https://www.jmbc.co.kr/uploads/pgm/fm_24110101_top_m.jpg'),\n        ('일', '19:00', '20:00', '이유있는 클래식', 'https://www.jmbc.co.kr/uploads/pgm/fm_000003_top_m.jpg'),\n    ]),\n")],
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
