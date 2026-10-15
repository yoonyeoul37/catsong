# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 BBS 불교방송 넣기
# 실행: python apply_bbs_schedule.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["def fetch(url, referer, ajax=False, old=False):\\n    h = {\'User-Agent\': UA, \'Referer\': referer, \'Accept-Language\': \'ko-KR,ko;q=0.9\'}\\n    if ajax:\\n        h[\'X-Requested-With\'] = \'XMLHttpRequest\'\\n    req = urllib.request.Request(url, headers=h)\\n    with urllib.request.urlopen(req, timeout=30, context=old_ssl() if old else None) as r:", "def no_check_ssl():\\n    # 인증서 설정이 잘못된 홈페이지(BBS)용 — 앱도 BBS만 이렇게 열었어요 (편성표 읽기만 함)\\n    c = ssl.create_default_context()\\n    c.check_hostname = False\\n    c.verify_mode = ssl.CERT_NONE\\n    return c\\n\\n\\ndef fetch(url, referer, ajax=False, old=False, data=None, insecure=False):\\n    h = {\'User-Agent\': UA, \'Referer\': referer, \'Accept-Language\': \'ko-KR,ko;q=0.9\'}\\n    if ajax:\\n        h[\'X-Requested-With\'] = \'XMLHttpRequest\'\\n    body = urllib.parse.urlencode(data).encode() if data is not None else None\\n    if body is not None:\\n        h[\'Content-Type\'] = \'application/x-www-form-urlencoded; charset=UTF-8\'\\n    req = urllib.request.Request(url, headers=h, data=body)\\n    ctx = old_ssl() if old else no_check_ssl() if insecure else None\\n    with urllib.request.urlopen(req, timeout=30, context=ctx) as r:"], ["    return {\'OBS 라디오\': week} if week else {}\\n", "    return {\'OBS 라디오\': week} if week else {}\\n\\n\\n# ───────── BBS 불교방송 (모바일 편성표: 날짜마다) ─────────\\nBBS = \'https://m.bbsi.co.kr/M/\'\\n\\n\\ndef bbs_day(d):\\n    page = fetch(BBS + \'sub/06_schedule/ajaxSch.html\', BBS + \'?ACT=SCHEDULE\', ajax=True,\\n                 data={\'Gubun\': \'RADIO\', \'SchDate\': f\'{d:%Y-%m-%d}\'}, insecure=True)\\n    progs = []\\n    for li in re.findall(r\'<li>(.*?)</li>\', page, re.S):\\n        se = re.search(r\'(\\\\d{1,2}:\\\\d{2})\\\\s*~\\\\s*(\\\\d{1,2}:\\\\d{2})\', li)  # 주석 안 \\"04:00 ~ 04:30\\"\\n        t = re.search(r\'<span class=\\"time\\">\\\\s*(\\\\d{1,2}:\\\\d{2})\', li)\\n        n = re.search(r\'<span class=\\"txt\\">(.*?)</span>\', li, re.S)\\n        if not (t and n):\\n            continue\\n        title = text_of(n.group(1))\\n        if not title:\\n            continue\\n        p = {\'title\': title, \'start\': t.group(1).zfill(5), \'end\': se.group(2).zfill(5) if se else \'\'}\\n        code = re.search(r\'ProgramCode=(\\\\d+)\', li)\\n        if code:\\n            p[\'code\'] = code.group(1)\\n        progs.append(p)\\n    return clean_day(progs)\\n\\n\\ndef bbs_images(codes):\\n    # 프로그램 홈 화면에 있는 프로그램 사진 (없으면 기본 이미지)\\n    pics = {}\\n    for code in codes:\\n        try:\\n            page = fetch(f\'https://www.bbsi.co.kr/?ACT=RADIO&MODE=HOME&ProgramCode={code}\', \'https://www.bbsi.co.kr/\',\\n                         insecure=True)\\n        except Exception:\\n            continue\\n        m = re.search(r\'(https?:)?//m\\\\.bbsi\\\\.co\\\\.kr/M/UploadProgramImg/[\\\\w.\\\\-]+\', page)\\n        if m:\\n            u = m.group(0)\\n            pics[code] = u if u.startswith(\'http\') else \'https:\' + u\\n    return pics\\n\\n\\ndef bbs():\\n    week = {}\\n    start = today_kst()\\n    for k in range(7):  # 일주일치: 요일 칸마다 가까운 날\\n        d = start + datetime.timedelta(days=k)\\n        key = day_key(d)\\n        if key in week:\\n            continue\\n        try:\\n            progs = bbs_day(d)\\n        except Exception as e:\\n            print(f\'  (BBS {d} 못 가져옴: {e})\')\\n            continue\\n        if len(progs) >= 5:\\n            week[key] = progs\\n    if not week:\\n        return {}\\n    pics = bbs_images(sorted({p[\'code\'] for v in week.values() for p in v if p.get(\'code\')}))\\n    for progs in week.values():\\n        for p in progs:\\n            code = p.pop(\'code\', None)\\n            if code in pics:\\n                p[\'image\'] = pics[code]\\n    return {\'BBS 불교방송\': week}\\n"], ["(\'국악FM\', gugak), (\'OBS\', obs)]", "(\'국악FM\', gugak), (\'OBS\', obs), (\'BBS\', bbs)]"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if "('BBS', bbs)" in t:
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
