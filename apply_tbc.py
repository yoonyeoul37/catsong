# -*- coding: utf-8 -*-
# TBC 드림FM 편성표·사진 추가 (+ 춘천 FM4U '오후의 발견'에 MBC강원영동 사진)
# 편성표 만드는 파일 + 상세페이지 편성표 아이콘     실행: python apply_tbc.py
import os, sys

EDITS = {
    'make_schedule.py': [('\n\ndef fill_images(week):', '\n\n# ───────── TBC 드림FM (대구, 날짜별 FM 편성표 · SBS 파워FM 프로그램은 SBS 사진 빌려 쓰기) ─────────\ndef tbc_day(d):\n    page = fetch(f\'https://www.tbc.co.kr/schedule/?mid=7_181&sYear={d.year}&sMonth={d.month}&sDate={d.day}\',\n                 \'https://www.tbc.co.kr/schedule\')\n    rows = []\n    for hh, mm, cell in re.findall(r\'<tr>\\s*<td[^>]*>\\s*(\\d{1,2}):(\\d{2})\\s*</td>\\s*<td[^>]*>(.*?)</td>\\s*</tr>\', page, re.S):\n        title = re.sub(r\'\\s*\\d+부$\', \'\', text_of(cell)).strip()\n        if title:\n            h = int(hh)\n            rows.append((d + datetime.timedelta(days=h // 24), f\'{h % 24:02d}:{mm}\', title))\n    return rows\n\n\ndef tbc_pics():\n    """TBC 라디오 프로그램 페이지 맨 위 사진 (비교용 이름 → 사진)"""\n    pics = []\n    try:\n        page = fetch(\'https://www.tbc.co.kr/fm/?mid=3\', \'https://www.tbc.co.kr/\')\n        names = {}\n        for mid, a in re.findall(r\'href=["\\\'][^"\\\']*fm/\\?mid=(3_\\d+_\\d+)["\\\'][^>]*>(.*?)</a>\', page, re.S):\n            a = text_of(a)\n            if a and mid not in names:\n                names[mid] = a\n        for mid, name in names.items():\n            try:\n                t = fetch(f\'https://www.tbc.co.kr/fm/?mid={mid}\', \'https://www.tbc.co.kr/fm/?mid=3\')\n            except Exception:\n                continue\n            m = re.search(r\'<img[^>]+src=["\\\']([^"\\\']*/uploads/program/top_fm_[^"\\\'?]+)\', t)\n            if m:\n                pics.append((mbc_key(name), urllib.parse.urljoin(\'https://www.tbc.co.kr/\', m.group(1))))\n    except Exception as e:\n        print(f\'  (TBC 프로그램 사진 못 가져옴: {e})\')\n    return pics\n\n\ndef tbc():\n    start = today_kst()\n    days = []\n    for k in range(7):\n        d = start + datetime.timedelta(days=k)\n        if day_key(d) not in [day_key(x) for x in days]:\n            days.append(d)\n    by_date = {}\n    for d in sorted(set(days) | {x - datetime.timedelta(days=1) for x in days}):\n        try:\n            for day, hm, title in tbc_day(d):\n                by_date.setdefault(day, {})[hm] = {\'title\': title, \'start\': hm, \'end\': \'\'}\n        except Exception as e:\n            print(f\'  (TBC {d} 못 가져옴: {e})\')\n    pics = tbc_pics()\n    week = {}\n    for d in days:\n        progs = clean_day(list(by_date.get(d, {}).values()))\n        merged = []\n        for p in progs:  # 1부·2부가 이어지면 한 칸으로\n            if merged and merged[-1][\'title\'] == p[\'title\'] and merged[-1][\'end\'] == p[\'start\']:\n                merged[-1][\'end\'] = p[\'end\']\n            else:\n                merged.append(p)\n        for p in merged:  # TBC 자체 프로그램 사진\n            k = mbc_key(p[\'title\'])\n            for pk, img in pics:\n                if same_name(k, pk):\n                    p[\'image\'] = img\n                    break\n        if len(merged) >= 5:\n            week[day_key(d)] = merged\n    sbs_images(week)  # 김영철의 파워FM 등 SBS 프로그램은 SBS 사진\n    return {\'TBC 드림FM\': week} if week else {}\n\n\ndef fill_images(week):'), ("('지역 MBC 덮어쓰기', mbc_overlay)]", "('지역 MBC 덮어쓰기', mbc_overlay), ('TBC', tbc)]"), ('    LOCAL_CARDS[base] = cards\n    return cards\n\n\ndef same_name(a, b):', "    # 춘천 FM4U가 받아 내보내는 MBC강원영동 프로그램 (매일 16:00 오후의 발견)\n    cards.append((mbc_key('오후의 발견'), set(range(7)), 16 * 60,\n                  'https://www.mbceg.co.kr/uploads/program/2025/12/7d329c2d7e8c4d4d68f08d41e9d94c41.jpg'))\n    LOCAL_CARDS[base] = cards\n    return cards\n\n\ndef same_name(a, b):")],
    'radio_player_screen.dart': [("        name == 'CPBC 가톨릭' ||", "        name == 'CPBC 가톨릭' ||\n        name == 'TBC 드림FM' ||")],
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
