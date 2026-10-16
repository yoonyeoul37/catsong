# -*- coding: utf-8 -*-
# 지역 MBC 덮어쓰기: 부산(표준·FM4U) · 포항 · 경남 · 충북(표준·FM4U) · 안동 = 서울 MBC 편성 + 지역 프로그램 시간
# (apply_mbc_regional2.py 다음에 실행)   실행: python apply_mbc_overlay.py
import os, sys

EDITS = {
    'make_schedule.py': [("def mbc_regional():\n    start = today_kst()\n    days = []  # 요일 칸마다 가까운 날\n    for k in range(7):\n        d = start + datetime.timedelta(days=k)\n        if day_key(d) not in [day_key(x) for x in days]:\n            days.append(d)\n    fetch_days = sorted(set(days) | {x - datetime.timedelta(days=1) for x in days})  # 전날 '24시~'가 그날 새벽\n    out = {}\n    for station, fn, ch in MBC_REGIONAL:\n        by_date = {}\n        for d in fetch_days:\n            try:\n                rows = fn(ch, d)\n            except Exception as e:\n                print(f'  ({station} {d} 못 가져옴: {e})')\n                continue\n            for day, hm, title in rows:\n                p = {'title': title, 'start': hm, 'end': ''}\n                img = mbc_image(title)\n                if img:\n                    p['image'] = img\n                by_date.setdefault(day, {})[hm] = p\n        week = {}\n        for d in days:\n            progs = clean_day(list(by_date.get(d, {}).values()))\n            if len(progs) >= 5:\n                week[day_key(d)] = progs\n        if week:\n            out[station] = week\n    return out", 'def mbc_regional():\n    start = today_kst()\n    days = []  # 요일 칸마다 가까운 날\n    for k in range(7):\n        d = start + datetime.timedelta(days=k)\n        if day_key(d) not in [day_key(x) for x in days]:\n            days.append(d)\n    fetch_days = sorted(set(days) | {x - datetime.timedelta(days=1) for x in days})  # 전날 \'24시~\'가 그날 새벽\n    out = {}\n    for station, fn, ch in MBC_REGIONAL:\n        by_date = {}\n        for d in fetch_days:\n            try:\n                rows = fn(ch, d)\n            except Exception as e:\n                print(f\'  ({station} {d} 못 가져옴: {e})\')\n                continue\n            for day, hm, title in rows:\n                p = {\'title\': title, \'start\': hm, \'end\': \'\'}\n                img = mbc_image(title)\n                if img:\n                    p[\'image\'] = img\n                by_date.setdefault(day, {})[hm] = p\n        week = {}\n        for d in days:\n            progs = clean_day(list(by_date.get(d, {}).values()))\n            if len(progs) >= 5:\n                week[day_key(d)] = progs\n        if week:\n            out[station] = week\n    return out\n\n\n# ───────── 지역 MBC 덮어쓰기: 서울 MBC 편성 + 지역 프로그램 시간만 바꿔 넣기 ─────────\n# (지역 편성표를 바로 읽을 수 없는 곳. 지역 홈페이지 프로그램 소개에 적힌 시간으로 직접 정리 — 개편 때 고쳐야 함)\n# (요일, 시작, 끝, 제목, 사진)  끝이 None이면 25분 넘게 지난 뒤 처음 오는 서울 프로그램 시작까지\nWEEK = {\'매일\': range(7), \'월-금\': range(5), \'토\': [5], \'일\': [6], \'토일\': [5, 6]}\nMBC_OVERLAY = {\n    \'부산MBC 표준FM\': (\'FM\', [\n        (\'월-금\', \'08:00\', \'09:00\', \'생방송 자갈치 아지매\', None),\n        (\'토\', \'08:05\', \'08:35\', \'우리 영화볼래요?\', None),\n        (\'토\', \'08:35\', \'08:57\', \'라디오 시민세상\', None),\n        (\'매일\', \'15:05\', \'16:00\', \'오후만세\', None),\n        (\'월-금\', \'18:05\', \'19:00\', \'생방송 오늘 저녁, 부산입니다\', None),\n    ]),\n    \'부산MBC FM4U\': (\'FM4U\', [\n        (\'매일\', \'11:00\', \'12:00\', \'안희성의 가정 음악실\', None),\n        (\'매일\', \'12:00\', None, \'정오의 희망곡 (부산MBC)\', \'https://busanmbc.co.kr/upload/editor/20260421165259.jpg\'),\n    ]),\n    \'포항MBC 표준FM\': (\'FM\', [\n        (\'월-금\', \'18:05\', \'19:00\', \'라디오열린세상\',\n         \'https://www.phmbc.co.kr/contents/program_info/open_world/1585542303.jpg\'),\n    ]),\n    \'MBC경남 표준FM\': (\'FM\', [\n        (\'월-금\', \'07:00\', \'09:00\', \'FM 아침의 행진\', None),\n        (\'월-금\', \'08:30\', None, \'좋은 아침\', None),\n        (\'월-금\', \'12:00\', None, \'정오의 희망곡 김군입니다\', None),\n        (\'월-금\', \'15:05\', None, \'The 즐거운 오후 3시\', None),\n        (\'월-금\', \'18:05\', None, \'생방송 라디오 광장\', None),\n    ]),\n    \'MBC충북 표준FM\': (\'FM\', [\n        (\'월-금\', \'11:05\', \'11:57\', \'시사ON\', None),\n        (\'월-금\', \'18:05\', \'20:00\', "임규호의 \'저녁N\'", None),\n    ]),\n    \'MBC충북 FM4U\': (\'FM4U\', [\n        (\'매일\', \'12:00\', \'13:57\', \'완벽한 하루\', None),\n        (\'토일\', \'16:00\', \'18:00\', \'주말의 발견\', None),\n    ]),\n    \'안동MBC 표준FM\': (\'FM\', [\n        (\'월-금\', \'18:05\', \'19:00\', \'라디오 오늘\', None),\n    ]),\n}\n\n\ndef hm2m(s):\n    return int(s[:2]) * 60 + int(s[3:5])\n\n\ndef m2hm(m):\n    return f\'{m // 60 % 24:02d}:{m % 60:02d}\'\n\n\ndef mbc_seoul_day(stype, fetch_days):\n    """서울 MBC 날짜별 편성: {날짜: [(시작분, 끝분, 제목, 사진)]} — 24시 넘으면 다음 날"""\n    by = {}\n    for d in fetch_days:\n        try:\n            data = get_json(f\'https://control.imbc.com/Schedule/Radio/Time?sType={stype}&broadDate={d:%Y%m%d}\',\n                            \'https://www.imbc.com/\')\n        except Exception as e:\n            print(f\'  (서울 MBC {stype} {d} 못 가져옴: {e})\')\n            continue\n        for it in data if isinstance(data, list) else []:\n            st, en = str(it.get(\'StartTime\') or \'\'), str(it.get(\'EndTime\') or \'\')\n            t = (it.get(\'Title\') or \'\').strip()\n            if not (t and len(st) == 4 and len(en) == 4 and st.isdigit() and en.isdigit()):\n                continue\n            s = int(st[:2]) * 60 + int(st[2:])\n            e = int(en[:2]) * 60 + int(en[2:])\n            if e <= s:\n                e += 1440\n            day = d + datetime.timedelta(days=s // 1440)\n            img = (it.get(\'Photo\') or \'\').strip()\n            img = \'https:\' + img if img.startswith(\'//\') else img\n            by.setdefault(day, {})[s % 1440] = (s % 1440, s % 1440 + (e - s), t, img)\n    return {k: sorted(v.values()) for k, v in by.items()}\n\n\ndef mbc_overlay():\n    start = today_kst()\n    days = []\n    for k in range(7):\n        d = start + datetime.timedelta(days=k)\n        if day_key(d) not in [day_key(x) for x in days]:\n            days.append(d)\n    fetch_days = sorted(set(days) | {x - datetime.timedelta(days=1) for x in days})\n    seoul = {s: mbc_seoul_day(s, fetch_days) for s in (\'FM\', \'FM4U\')}\n    out = {}\n    for station, (stype, locals_) in MBC_OVERLAY.items():\n        week = {}\n        for d in days:\n            progs = [list(p) for p in seoul[stype].get(d, [])]  # [시작, 끝, 제목, 사진] (분)\n            if len(progs) < 5:\n                continue\n            for wk, s_hm, e_hm, title, img in sorted(locals_, key=lambda x: x[1]):\n                if d.weekday() not in WEEK[wk]:\n                    continue\n                s = hm2m(s_hm)\n                if e_hm:\n                    e = hm2m(e_hm)\n                else:  # 끝 시간이 안 적힌 지역 프로그램: 25분 넘게 지난 뒤 처음 시작하는 서울 프로그램까지\n                    e = next((p[0] for p in progs if p[0] >= s + 25), s + 60)\n                new = []\n                for p in progs:\n                    if p[1] <= s or p[0] >= e:  # 안 겹침\n                        new.append(p)\n                        continue\n                    if p[0] < s:  # 앞부분만 남기기\n                        new.append([p[0], s, p[2], p[3]])\n                    if p[1] > e:  # 뒷부분 이어서\n                        new.append([e, p[1], p[2], p[3]])\n                new.append([s, e, title, img or \'\'])\n                progs = sorted(new)\n            items = []\n            for s, e, t, img in progs:\n                p = {\'title\': t, \'start\': m2hm(s), \'end\': m2hm(e)}\n                if img:\n                    p[\'image\'] = img\n                items.append(p)\n            items = clean_day(items)\n            if len(items) >= 5:\n                week[day_key(d)] = items\n        if week:\n            out[station] = week\n    return out'), ("('TBN', tbn), ('지역 MBC', mbc_regional)]", "('TBN', tbn), ('지역 MBC', mbc_regional), ('지역 MBC 덮어쓰기', mbc_overlay)]")],
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
