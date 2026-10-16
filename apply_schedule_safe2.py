# -*- coding: utf-8 -*-
# 편성표 만들기 안전하게 (apply_tbn_wait.py + apply_schedule_safe.py 합친 것 — 이것 하나만 실행)
#  · TBN 사이트가 응답 없으면 오래 안 기다리고, 못 가져온 TBN 방송은 예전 편성표 그대로
#  · 원하는 방송국만 골라 돌리기: python tools/make_schedule.py 지역MBC
# 실행: python apply_schedule_safe2.py
import os, sys

EDITS = {
    'make_schedule.py': [("    page = fetch(f'https://www.tbn.or.kr/broadcast/program.tbn?area_code=6&page_code={page_code}&today={d:%Y%m%d}',\n                 'https://www.tbn.or.kr/main.tbn', insecure=True)\n", "    time.sleep(0.3)  # TBN 사이트가 막지 않게 조금씩 쉬면서\n    page = fetch(f'https://www.tbn.or.kr/broadcast/program.tbn?area_code=6&page_code={page_code}&today={d:%Y%m%d}',\n                 'https://www.tbn.or.kr/main.tbn', insecure=True, timeout=15)\n"), ("        except Exception as e:\n            print(f'  (TBN 본부 {d} 못 가져옴: {e})')\n    out = {}\n", "        except Exception as e:\n            print(f'  (TBN 본부 {d} 못 가져옴: {e})')\n            print('  (TBN 사이트가 응답이 없어요 — TBN은 예전 편성표 그대로 둬요)')\n            return {}  # 본부 편성이 하루라도 빠지면 틀린 편성이 되니까 이번엔 TBN 전체를 건너뜀\n    out = {}\n"), ("    for station, code in TBN_AREAS.items():\n        by_date = {}\n        for d in fetch_days:\n            try:\n                local = tbn_table(code, d)\n            except Exception as e:\n                print(f'  ({station} {d} 못 가져옴: {e})')\n                local = []\n", "    for station, code in TBN_AREAS.items():\n        if TBN_FAILS[0] >= 6:  # TBN 사이트가 계속 응답이 없으면 남은 곳은 기다리지 않기\n            print(f'  ({station} 못 가져와서 예전 편성표 그대로 둬요)')\n            continue\n        by_date, failed = {}, False\n        for d in fetch_days:\n            try:\n                local = tbn_table(code, d)\n                TBN_FAILS[0] = 0\n            except Exception as e:\n                TBN_FAILS[0] += 1\n                print(f'  ({station} {d} 못 가져옴: {e})')\n                failed = True  # 지역 편성이 빠지면 틀린 편성이 되니까 이 방송은 예전 것 그대로\n                break\n"), ("        week = {}\n        for d in days:\n            progs = clean_day(list(by_date.get(d, {}).values()))\n            if len(progs) >= 5:\n                week[day_key(d)] = progs\n        if week:\n            out[station] = week\n    first = out.get('TBN 경인교통', {})", "        if failed:\n            print(f'  ({station} 예전 편성표 그대로 둬요)')\n            continue\n        week = {}\n        for d in days:\n            progs = clean_day(list(by_date.get(d, {}).values()))\n            if len(progs) >= 5:\n                week[day_key(d)] = progs\n        if week:\n            out[station] = week\n    first = out.get('TBN 경인교통', {})"), ('    ok = 0\n    for name, fn in SOURCES:\n        try:', "    ok = 0\n    # 일부만 돌리기: python tools/make_schedule.py 지역MBC TBN  (아무것도 안 쓰면 전부)\n    only = [a.replace(' ', '') for a in sys.argv[1:]]\n    for name, fn in SOURCES:\n        if only and name.replace(' ', '') not in only:\n            continue\n        try:")],
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
