# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 TBN 사이트가 응답 없을 때 오래 기다리지 않기
# 실행: python apply_tbn_wait.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["    page = fetch(f\'https://www.tbn.or.kr/broadcast/program.tbn?area_code=6&page_code={page_code}&today={d:%Y%m%d}\',\\n                 \'https://www.tbn.or.kr/main.tbn\', insecure=True)\\n", "    time.sleep(0.3)  # TBN 사이트가 막지 않게 조금씩 쉬면서\\n    page = fetch(f\'https://www.tbn.or.kr/broadcast/program.tbn?area_code=6&page_code={page_code}&today={d:%Y%m%d}\',\\n                 \'https://www.tbn.or.kr/main.tbn\', insecure=True, timeout=15)\\n"], ["    for d in fetch_days:\\n        try:\\n            national[d] = tbn_table(1, d)  # 본부(전국) 편성\\n        except Exception as e:\\n            print(f\'  (TBN 본부 {d} 못 가져옴: {e})\')\\n", "    for n, d in enumerate(fetch_days):\\n        try:\\n            national[d] = tbn_table(1, d)  # 본부(전국) 편성\\n        except Exception as e:\\n            print(f\'  (TBN 본부 {d} 못 가져옴: {e})\')\\n            if not national and n >= 1:  # 처음 두 번 다 안 되면 사이트가 막힌 것 — 더 기다리지 않기\\n                print(\'  (TBN 사이트가 응답이 없어요 — TBN은 예전 편성표 그대로 둬요)\')\\n                return {}\\n"], ["            try:\\n                local = tbn_table(code, d)\\n            except Exception as e:\\n                print(f\'  ({station} {d} 못 가져옴: {e})\')\\n                local = []\\n", "            local = []\\n            if TBN_FAILS[0] < 6:  # 계속 응답이 없으면 지역 편성은 건너뛰기 (본부 편성만)\\n                try:\\n                    local = tbn_table(code, d)\\n                    TBN_FAILS[0] = 0\\n                except Exception as e:\\n                    TBN_FAILS[0] += 1\\n                    print(f\'  ({station} {d} 못 가져옴: {e})\')\\n"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if '처음 두 번 다 안 되면' in t:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'TBN_OLD' not in t:
    print('❌ apply_tbn_images2.py 를 먼저 실행해 주세요'); sys.exit(1)
if False:
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
