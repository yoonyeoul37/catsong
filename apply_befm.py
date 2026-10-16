# -*- coding: utf-8 -*-
# BeFM 편성표·사진 추가 (apply_tbc.py 먼저 적용돼 있어야 해요)
# 편성표 만드는 파일 + 상세페이지 편성표 아이콘     실행: python apply_befm.py
import os, sys

EDITS = {
    'make_schedule.py': [('\n\ndef fill_images(week):', '\n\n# ───────── BeFM 부산영어방송 (요일별 시간표 · 프로그램 사진) ─────────\ndef befm_get(url):\n    # 옛날 보안 방식 + 인증서 확인 안 함 (편성표 읽기만 함)\n    try:\n        return fetch(url, \'https://www.befm.or.kr/\', old=True)\n    except Exception:\n        c = old_ssl()\n        c.check_hostname = False\n        c.verify_mode = ssl.CERT_NONE\n        req = urllib.request.Request(url, headers={\'User-Agent\': UA, \'Referer\': \'https://www.befm.or.kr/\'})\n        with urllib.request.urlopen(req, timeout=30, context=c) as r:\n            return r.read().decode(\'utf-8\', errors=\'replace\')\n\n\nBEFM_TAB = {0: \'mon\', 1: \'tue-thu\', 2: \'tue-thu\', 3: \'tue-thu\', 4: \'fri\', 5: \'sat\', 6: \'sun\'}\n\n\ndef befm():\n    page = befm_get(\'https://www.befm.or.kr/sub/template.php?midx=37&lang=ko\')\n    pics = {}\n    try:\n        cards = befm_get(\'https://www.befm.or.kr/sub/template.php?midx=35&lang=ko\')\n        for pg, img in re.findall(r\'href=["\\\']/program/main\\.php\\?pg=(\\w+)["\\\'][^>]*>\\s*<div class="img_box">\\s*<img src=["\\\']([^"\\\']+)\', cards):\n            pics[pg] = urllib.parse.urljoin(\'https://www.befm.or.kr/\', img)\n    except Exception as e:\n        print(f\'  (BeFM 프로그램 사진 못 가져옴: {e})\')\n    tabs = {}\n    parts = re.split(r\'<div class="schedule_con_box" id="([\\w-]+)"\', page)\n    for i in range(1, len(parts) - 1, 2):\n        progs = []\n        for hm, link, title in re.findall(r\'<th scope="row">.*?(\\d{2}:\\d{2})\\s*</th>\\s*<td>\\s*<a href=["\\\']([^"\\\']*)["\\\'][^>]*>(.*?)</a>\', parts[i + 1], re.S):\n            title = re.sub(r\'^\\[\\s*\\w\\s*\\]\\s*\', \'\', text_of(title))\n            title = re.sub(r\'\\s*\\(RE\\)$\', \' (재)\', title).strip()\n            if not title:\n                continue\n            p = {\'title\': title, \'start\': hm, \'end\': \'\'}\n            m = re.search(r\'pg=(\\w+)\', link)\n            if m and m.group(1) in pics:\n                p[\'image\'] = pics[m.group(1)]\n            progs.append(p)\n        if len(progs) >= 5:\n            tabs[parts[i]] = clean_day(progs)\n    week = {}\n    start = today_kst()\n    for k in range(7):\n        d = start + datetime.timedelta(days=k)\n        key = day_key(d)\n        if key not in week and BEFM_TAB[d.weekday()] in tabs:\n            week[key] = tabs[BEFM_TAB[d.weekday()]]\n    return {\'BeFM\': week} if week else {}\n\n\ndef fill_images(week):'), ("('TBC', tbc)]", "('TBC', tbc), ('BeFM', befm)]")],
    'radio_player_screen.dart': [("        name == 'TBC 드림FM' ||", "        name == 'TBC 드림FM' ||\n        name == 'BeFM' ||")],
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
