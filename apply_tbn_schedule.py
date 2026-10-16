# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 TBN 교통방송 12곳 넣기
# 실행: python apply_tbn_schedule.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["    return {\'CPBC 가톨릭\': week} if week else {}\\n", "    return {\'CPBC 가톨릭\': week} if week else {}\\n\\n\\n# ───────── TBN 교통방송 (본부 편성 + 지역 편성 합치기) ─────────\\nTBN_AREAS = {  # 앱의 방송 이름 → TBN 편성표 지역 번호(page_code)\\n    \'TBN 경인교통\': 6, \'TBN 부산교통\': 2, \'TBN 광주교통\': 3, \'TBN 대구교통\': 4, \'TBN 대전교통\': 5,\\n    \'TBN 울산교통\': 9, \'TBN 강원교통\': 7, \'TBN 충북교통\': 13, \'TBN 충남교통\': 14, \'TBN 전북교통\': 8,\\n    \'TBN 경남교통\': 10, \'TBN 제주교통\': 12,\\n}\\n\\n\\ndef tbn_table(page_code, d):\\n    \\"\\"\\"그날 그 지역 편성표 칸들: (날짜, \'HH:MM\', 제목) — 24시 넘으면 다음 날\\"\\"\\"\\n    page = fetch(f\'https://www.tbn.or.kr/broadcast/program.tbn?area_code=6&page_code={page_code}&today={d:%Y%m%d}\',\\n                 \'https://www.tbn.or.kr/main.tbn\', insecure=True)\\n    i = page.find(\'프로그램소개 - 시, 분, 프로그램명\')\\n    table = page[i:page.find(\'</table>\', i)] if i >= 0 else \'\'\\n    rows = []\\n    for hh, mm, title in re.findall(r\'<tr>\\\\s*<td>\\\\s*(\\\\d{1,2})\\\\s*</td>\\\\s*<td>\\\\s*(\\\\d{1,2})\\\\s*</td>\\\\s*\'\\n                                    r\'<td[^>]*>.*?<strong>(.*?)</strong>\', table, re.S):\\n        h = int(hh)\\n        title = text_of(title)\\n        if title:\\n            rows.append((d + datetime.timedelta(days=h // 24), f\'{h % 24:02d}:{int(mm):02d}\', title))\\n    return rows\\n\\n\\ndef tbn():\\n    start = today_kst()\\n    days = []  # 요일 칸마다 가까운 날 (월~목 · 금 · 토 · 일)\\n    for k in range(7):\\n        d = start + datetime.timedelta(days=k)\\n        if day_key(d) not in [day_key(x) for x in days]:\\n            days.append(d)\\n    fetch_days = sorted(set(days) | {x - datetime.timedelta(days=1) for x in days})  # 전날 \'24시~\'가 그날 새벽\\n    national = {}\\n    for d in fetch_days:\\n        try:\\n            national[d] = tbn_table(1, d)  # 본부(전국) 편성\\n        except Exception as e:\\n            print(f\'  (TBN 본부 {d} 못 가져옴: {e})\')\\n    out = {}\\n    for station, code in TBN_AREAS.items():\\n        by_date = {}\\n        for d in fetch_days:\\n            try:\\n                local = tbn_table(code, d)\\n            except Exception as e:\\n                print(f\'  ({station} {d} 못 가져옴: {e})\')\\n                local = []\\n            for day, hm, title in national.get(d, []):\\n                by_date.setdefault(day, {}).setdefault(hm, {\'title\': title, \'start\': hm, \'end\': \'\'})\\n            for day, hm, title in local:  # 같은 시간이면 지역 방송이 우선\\n                by_date.setdefault(day, {})[hm] = {\'title\': title, \'start\': hm, \'end\': \'\'}\\n        week = {}\\n        for d in days:\\n            progs = clean_day(list(by_date.get(d, {}).values()))\\n            if len(progs) >= 5:\\n                week[day_key(d)] = progs\\n        if week:\\n            out[station] = week\\n    first = out.get(\'TBN 경인교통\', {}).get(day_key(start), [])\\n    if first:  # 확인용: 경인 오늘 편성 한눈에\\n        print(\'  (TBN 경인 오늘) \' + \' / \'.join(f\\"{p[\'start\']} {p[\'title\']}\\" for p in first))\\n    return out\\n"], ["(\'BBS\', bbs), (\'CPBC\', cpbc)]", "(\'BBS\', bbs), (\'CPBC\', cpbc), (\'TBN\', tbn)]"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if "('TBN', tbn)" in t:
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
