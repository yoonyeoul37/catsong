# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 TBN 사진: 응답 없을 때 다시 시도 · 예전 사진 쓰기
# 실행: python apply_tbn_images2.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["import json, sys, ssl, datetime, urllib.request, urllib.parse, os, re, html as htmllib", "import json, sys, ssl, time, datetime, urllib.request, urllib.parse, os, re, html as htmllib"], ["def fetch(url, referer, ajax=False, old=False, data=None, insecure=False):", "def fetch(url, referer, ajax=False, old=False, data=None, insecure=False, timeout=30):"], ["timeout=30, context=ctx", "timeout=timeout, context=ctx"], ["def tbn_image(seq):\\n    \\"\\"\\"프로그램 소개 페이지 위쪽의 큰 배경 사진\\"\\"\\"\\n    if not seq:\\n        return \'\'\\n    if seq not in TBN_PICS:\\n        TBN_PICS[seq] = \'\'\\n        try:\\n            page = fetch(f\'https://www.tbn.or.kr/program/main.tbn?forum_seq={seq}&area_code=6\',\\n                         \'https://www.tbn.or.kr/main.tbn\', insecure=True)\\n            m = re.search(r\'class=\\"program-bg\\"[^>]*background-image\\\\s*:\\\\s*url\\\\(([^)]+)\\\\)\', page)\\n            if m:\\n                TBN_PICS[seq] = urllib.parse.urljoin(\'https://www.tbn.or.kr/\', m.group(1).strip(\'\\\\\'\\" \'))\\n        except Exception as e:\\n            print(f\'  (TBN 사진 {seq} 못 가져옴: {e})\')\\n    return TBN_PICS[seq]\\n", "TBN_OLD = {}  # 예전 schedule.json의 TBN 사진 (제목 → 사진): 이번에 못 가져오면 이걸로\\nTBN_FAILS = [0]  # 연달아 못 가져온 횟수\\n\\n\\ndef tbn_image(seq, title=\'\'):\\n    \\"\\"\\"프로그램 소개 페이지 위쪽의 큰 배경 사진 (못 가져오면 예전 사진)\\"\\"\\"\\n    if seq and seq not in TBN_PICS:\\n        TBN_PICS[seq] = \'\'\\n        if TBN_FAILS[0] >= 6:  # 계속 응답이 없으면 TBN이 막은 것 — 더 기다리지 않기\\n            pass\\n        else:\\n            err = None\\n            for wait in (0.5, 5):  # 잠깐 쉬고 가져오기 · 안 되면 5초 쉬고 한 번 더\\n                time.sleep(wait)\\n                try:\\n                    page = fetch(f\'https://www.tbn.or.kr/program/main.tbn?forum_seq={seq}&area_code=6\',\\n                                 \'https://www.tbn.or.kr/main.tbn\', insecure=True, timeout=15)\\n                    m = re.search(r\'class=\\"program-bg\\"[^>]*background-image\\\\s*:\\\\s*url\\\\(([^)]+)\\\\)\', page)\\n                    if m:\\n                        TBN_PICS[seq] = urllib.parse.urljoin(\'https://www.tbn.or.kr/\', m.group(1).strip(\'\\\\\'\\" \'))\\n                    TBN_FAILS[0] = 0\\n                    err = None\\n                    break\\n                except Exception as e:\\n                    TBN_FAILS[0] += 1\\n                    err = e\\n            if err:\\n                print(f\'  (TBN 사진 {seq} 못 가져옴: {err})\')\\n                if TBN_FAILS[0] >= 6:\\n                    print(\'  (TBN 사진 페이지가 계속 응답이 없어요 — 나머지는 예전 사진으로 둬요)\')\\n    return TBN_PICS.get(seq) or TBN_OLD.get(title, \'\')\\n"], ["    img = tbn_image(seq)\\n", "    img = tbn_image(seq, title)\\n"], ["    days = []  # 요일 칸마다 가까운 날 (월~목 · 금 · 토 · 일)\\n", "    try:  # 예전에 받아 둔 TBN 사진 (이번에 못 가져온 프로그램용)\\n        with open(OUT, encoding=\'utf-8\') as f:\\n            for st, wk in json.load(f).items():\\n                if st.startswith(\'TBN \'):\\n                    for progs in wk.values():\\n                        for p in progs:\\n                            if p.get(\'image\'):\\n                                TBN_OLD.setdefault(p[\'title\'], p[\'image\'])\\n    except Exception:\\n        pass\\n    days = []  # 요일 칸마다 가까운 날 (월~목 · 금 · 토 · 일)\\n"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if 'TBN_OLD' in t:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'def tbn_image' not in t:
    print('❌ apply_tbn_images.py 를 먼저 실행해 주세요'); sys.exit(1)
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
