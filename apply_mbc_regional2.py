# -*- coding: utf-8 -*-
# 지역 MBC 편성표 추가: 제주(표준FM·FM4U) · 대전(표준FM) · 광주(표준FM·FM4U) · 목포(표준FM)
# (apply_mbc_regional.py 다음에 실행)   실행: python apply_mbc_regional2.py
import os, sys

EDITS = {
    'make_schedule.py': [("            rows.append((d + datetime.timedelta(days=h // 24), f'{h % 24:02d}:{int(mm):02d}', title))\n    return rows\n\n\nMBC_REGIONAL = [", '            rows.append((d + datetime.timedelta(days=h // 24), f\'{h % 24:02d}:{int(mm):02d}\', title))\n    return rows\n\n\ndef mbcnet_day(base, d):\n    """제주·대전·광주·목포MBC (같은 모양 홈페이지) 그날 편성: base = \'.../FM\' 또는 \'.../FM4U\'\n    한 페이지가 새벽 5시~다음 날 새벽이라, 시간이 거꾸로 가면(23:05 → 00:00) 다음 날로 넘김"""\n    page = fetch(f\'{base}/{d:%Y-%m-%d}\', base)\n    rows, day, last = [], d, -1\n    for hh, mm, title in re.findall(r\'<li class="order\\d*">\\s*<(?:a|div)\\b[^>]*>\\s*<strong>\\s*(\\d{1,2}):(\\d{2})\\s*</strong>\'\n                                    r\'\\s*<p>(.*?)</p>\', page, re.S):\n        m = int(hh) * 60 + int(mm)\n        if m < last and day == d:\n            day = d + datetime.timedelta(days=1)\n        last = m\n        title = text_of(title)\n        if title:\n            rows.append((day, f\'{int(hh) % 24:02d}:{mm}\', title))\n    return rows\n\n\nMBC_REGIONAL = ['), ("    ('춘천MBC FM4U', chmbc_day, 'radio'),\n]", "    ('춘천MBC FM4U', chmbc_day, 'radio'),\n    ('제주MBC 표준FM', mbcnet_day, 'https://jejumbc.com/FMTimetable/FM'),\n    ('제주MBC FM4U', mbcnet_day, 'https://jejumbc.com/FMTimetable/FM4U'),\n    ('대전MBC 표준FM', mbcnet_day, 'https://tjmbc.co.kr/ProgramScheduleTV/FM'),\n    ('광주MBC 표준FM', mbcnet_day, 'https://kjmbc.co.kr/Timetable/FM'),\n    ('광주MBC FM4U', mbcnet_day, 'https://kjmbc.co.kr/Timetable/FM4U'),\n    ('목포MBC 표준FM', mbcnet_day, 'https://www.mpmbc.co.kr/TVTimetable/FM'),\n]")],
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
