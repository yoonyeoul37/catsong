# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 TBS 사진을 제목으로만 맞추기
# 실행: python apply_tbs_images2.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["def tbs_images(progs, plist, day):\\n    def key(t):\\n        return re.sub(r\'[\\\\s,.·!?~\\\\-()（）]\', \'\', t).lower()\\n\\n    def mins(t):\\n        return int(t[:2]) * 60 + int(t[3:5])\\n    for p in progs:\\n        # 1) 이름이 맞으면 (재방송 포함)\\n        for q in plist:\\n            words = [w for w in re.split(r\'\\\\s+\', q[\'name\']) if len(w) >= 2]\\n            name_hit = key(q[\'name\']) and (key(q[\'name\']) in key(p[\'title\']) or key(p[\'title\']) in key(q[\'name\']))\\n            tail_hit = len(words) >= 2 and key(\' \'.join(words[-2:])) in key(p[\'title\'])  # \\"Summer Lee Diverse Voices\\"\\n            if name_hit or tail_hit:\\n                p[\'image\'] = q[\'image\']\\n                break\\n        if p.get(\'image\'):\\n            continue\\n        # 2) 요일 · 시간이 맞으면 (4시간 넘는 긴 칸은 빼고)\\n        for q in plist:\\n            s, e = mins(q[\'start\']), mins(q[\'end\'])\\n            if e <= s or e - s > 240 or day.weekday() not in q[\'days\']:\\n                continue\\n            if s <= mins(p[\'start\']) < e:\\n                p[\'image\'] = q[\'image\']\\n                break", "def tbs_images(progs, plist, day):\\n    # 제목으로만 맞추기 (시간으로 맞추면 편성이 바뀐 날 다른 프로그램 사진이 붙어서 안 씀)\\n    def key(t):\\n        return re.sub(r\'[\\\\s,.·!?~\\\\-()（）]\', \'\', t).lower()\\n    for p in progs:\\n        t = key(p[\'title\'])\\n        for q in plist:\\n            words = [w for w in re.split(r\'\\\\s+\', q[\'name\']) if w]\\n            cands = [q[\'name\']]\\n            if len(words) >= 2:\\n                cands.append(\' \'.join(words[-2:]))  # \\"Summer Lee Diverse Voices\\" → \\"Diverse Voices\\"\\n            if words and len(key(words[-1])) >= 4:\\n                cands.append(words[-1])  # \\"강지연의 머니특별시\\" → \\"머니특별시\\"\\n            cands += re.findall(r\'\\\\(([^)]{4,})\\\\)\', q[\'name\'])  # \\"首尔, 我來了 (Coming to Seoul)\\" → \\"Coming to Seoul\\"\\n            if any(key(c) and (key(c) in t or t in key(c)) for c in cands):\\n                p[\'image\'] = q[\'image\']\\n                break"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if "제목으로만 맞추기" in t:
    print('이미 적용돼 있어요'); sys.exit(0)
for i, (o, n) in enumerate(EDITS, 1):
    if t.count(o) != 1:
        print(f'❌ {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
    t = t.replace(o, n)
    print(f'✔ {i}번 고침')
try:
    compile(t, P, 'exec')
except SyntaxError as e:
    print(f'❌ 고친 뒤 코드가 맞지 않아요 ({e}) — 아무것도 저장 안 했어요'); sys.exit(1)
if crlf:
    t = t.replace('\n', '\r\n')
with open(P, 'w', encoding='utf-8', newline='') as f:
    f.write(t)
print('완료! 이제 python tools/make_schedule.py 를 실행해 주세요')
