# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 CPBC 가톨릭 넣기
# 실행: python apply_cpbc_schedule.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["    return {\'BBS 불교방송\': week}\\n", "    return {\'BBS 불교방송\': week}\\n\\n\\n# ───────── CPBC 가톨릭 (라디오 편성 데이터: 날짜마다, 05시 ~ 다음 날 새벽) ─────────\\ndef cpbc_items(data):\\n    # 편성 칸들이 들어 있는 목록 찾기\\n    if isinstance(data, list):\\n        return data\\n    if isinstance(data, dict):\\n        for v in data.values():\\n            if isinstance(v, list) and v and isinstance(v[0], dict) and \'startTime\' in v[0]:\\n                return v\\n    return []\\n\\n\\ndef cpbc():\\n    by_date = {}\\n    start = today_kst()\\n    for k in range(-1, 7):  # 어제 것도: 어제 편성의 \'25:00\'이 오늘 새벽 1시\\n        d = start + datetime.timedelta(days=k)\\n        try:\\n            data = get_json(f\'https://static.apis.cpbc.co.kr/radio-api/schedule/01/{d:%Y%m%d}\', \'https://www.cpbc.co.kr/\')\\n        except Exception as e:\\n            if k >= 0:\\n                print(f\'  (CPBC {d} 못 가져옴: {e})\')\\n            continue\\n        for it in cpbc_items(data):\\n            prog = it.get(\'program\') or {}\\n            title = (prog.get(\'title\') or \'\').strip()\\n            st, en = (it.get(\'startTime\') or \'\'), (it.get(\'endTime\') or \'\')\\n            if not (title and re.match(r\'\\\\d{1,2}:\\\\d{2}$\', st) and re.match(r\'\\\\d{1,2}:\\\\d{2}$\', en)):\\n                continue\\n            if \'방송시간이 아닙니다\' in title:\\n                continue\\n            sh, eh = int(st.split(\':\')[0]), int(en.split(\':\')[0])\\n            day = d + datetime.timedelta(days=1) if sh >= 24 else d  # 25:03 → 다음 날 01:03\\n            p = {\'title\': title, \'start\': f\'{sh % 24:02d}:{st[-2:]}\', \'end\': f\'{eh % 24:02d}:{en[-2:]}\'}\\n            img = (prog.get(\'images\') or {}).get(\'horizontal\') or (prog.get(\'images\') or {}).get(\'square\')\\n            if img:\\n                p[\'image\'] = img\\n            by_date.setdefault(day, []).append(p)\\n    week = {}\\n    for k in range(7):  # 요일 칸마다 가까운 날\\n        d = start + datetime.timedelta(days=k)\\n        key = day_key(d)\\n        if key in week or d not in by_date:\\n            continue\\n        progs = clean_day(by_date[d])\\n        if len(progs) >= 5:\\n            week[key] = progs\\n    return {\'CPBC 가톨릭\': week} if week else {}\\n"], ["(\'OBS\', obs), (\'BBS\', bbs)]", "(\'OBS\', obs), (\'BBS\', bbs), (\'CPBC\', cpbc)]"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if "('CPBC', cpbc)" in t:
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
