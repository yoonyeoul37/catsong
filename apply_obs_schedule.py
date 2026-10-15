# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 OBS 라디오 넣기
# 실행: python apply_obs_schedule.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["import json, sys, datetime, urllib.request, urllib.parse, os, re, html as htmllib", "import json, sys, ssl, datetime, urllib.request, urllib.parse, os, re, html as htmllib"], ["def fetch(url, referer, ajax=False):\\n    h = {\'User-Agent\': UA, \'Referer\': referer, \'Accept-Language\': \'ko-KR,ko;q=0.9\'}\\n    if ajax:\\n        h[\'X-Requested-With\'] = \'XMLHttpRequest\'\\n    req = urllib.request.Request(url, headers=h)\\n    with urllib.request.urlopen(req, timeout=30) as r:", "def old_ssl():\\n    # 옛날 보안 방식 홈페이지(OBS)도 열 수 있게 (편성표 읽기만 함)\\n    c = ssl.create_default_context()\\n    c.set_ciphers(\'DEFAULT@SECLEVEL=0\')\\n    c.options |= getattr(ssl, \'OP_LEGACY_SERVER_CONNECT\', 0x4)\\n    return c\\n\\n\\ndef fetch(url, referer, ajax=False, old=False):\\n    h = {\'User-Agent\': UA, \'Referer\': referer, \'Accept-Language\': \'ko-KR,ko;q=0.9\'}\\n    if ajax:\\n        h[\'X-Requested-With\'] = \'XMLHttpRequest\'\\n    req = urllib.request.Request(url, headers=h)\\n    with urllib.request.urlopen(req, timeout=30, context=old_ssl() if old else None) as r:"], ["    return {\'국악FM\': week}\\n", "    return {\'국악FM\': week}\\n\\n\\n# ───────── OBS 라디오 (경인방송과 같은 모양의 편성표) ─────────\\ndef obs_day(d):\\n    page = fetch(f\'https://www.obs.co.kr/schedule/?type=radio&year={d.year}&month={d.month:02d}&day={d.day:02d}\',\\n                 \'https://www.obs.co.kr/schedule/?type=radio\', old=True)\\n    i = page.find(\'tbl_radio_schedule\')\\n    table = page[i:] if i >= 0 else page\\n    progs = []\\n    for row in re.findall(r\'<tr[^>]*>(.*?)</tr>\', table, re.S):\\n        t = re.search(r\'class=\\"[^\\"]*\\\\btime\\"[^>]*>\\\\s*(\\\\d{1,2}:\\\\d{2})\', row)\\n        n = re.search(r\'font-weight:\\\\s*bold[^>]*>(.*?)</div>\', row, re.S)\\n        if not (t and n):\\n            continue\\n        title = text_of(n.group(1))\\n        if not title:\\n            continue\\n        p = {\'title\': title, \'start\': t.group(1).zfill(5), \'end\': \'\'}\\n        img = re.search(r\'<img src=\\"([^\\"]*/admin/data/program/[^\\"]+)\\"\', row)\\n        if img:\\n            u = img.group(1)\\n            p[\'image\'] = u if u.startswith(\'http\') else \'https://www.obs.co.kr\' + u\\n        progs.append(p)\\n    return clean_day(progs)\\n\\n\\ndef obs():\\n    week = {}\\n    start = today_kst()\\n    for k in range(7):  # 일주일치: 요일 칸마다 가까운 날\\n        d = start + datetime.timedelta(days=k)\\n        key = day_key(d)\\n        if key in week:\\n            continue\\n        try:\\n            progs = obs_day(d)\\n        except Exception as e:\\n            print(f\'  (OBS {d} 못 가져옴: {e})\')\\n            continue\\n        if len(progs) >= 5:\\n            week[key] = progs\\n    return {\'OBS 라디오\': week} if week else {}\\n\\n"], ["(\'JTV\', jtv), (\'국악FM\', gugak)]", "(\'JTV\', jtv), (\'국악FM\', gugak), (\'OBS\', obs)]"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if "('OBS', obs)" in t:
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
