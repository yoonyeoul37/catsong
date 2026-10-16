# -*- coding: utf-8 -*-
# 지역 MBC 편성표: 춘천MBC 표준FM · FM4U (서울 MBC와 같은 프로그램은 서울 사진 빌려 쓰기)
# 실행: python apply_mbc_regional.py   (프로젝트 폴더에서)
import os, sys

EDITS = {
    'make_schedule.py': [('    first = out.get(\'TBN 경인교통\', {}).get(day_key(start), [])\n    if first:  # 확인용: 경인 오늘 편성 한눈에\n        print(\'  (TBN 경인 오늘) \' + \' / \'.join(f"{p[\'start\']} {p[\'title\']}" for p in first))\n    return out\n', '    first = out.get(\'TBN 경인교통\', {}).get(day_key(start), [])\n    if first:  # 확인용: 경인 오늘 편성 한눈에\n        print(\'  (TBN 경인 오늘) \' + \' / \'.join(f"{p[\'start\']} {p[\'title\']}" for p in first))\n    return out\n\n\n# ───────── 지역 MBC (서울 MBC와 같은 프로그램은 서울 사진 빌려 쓰기) ─────────\nMBC_PICS = {}\n\n\ndef mbc_key(t):\n    # "김종배의 시선집중 1,2 부" · "정오의 희망곡 김지후입니다 (춘천MBC)" → 비교용 글자\n    t = htmllib.unescape(t)\n    t = re.sub(r\'\\((?:[^)]*MBC[^)]*|재|재방송)\\)\', \'\', t)\n    t = re.sub(r\'\\d+(?:\\s*,\\s*\\d+)*\\s*부\', \'\', t)\n    return re.sub(r\'[\\s,.·!?~\\-&;:()\\[\\]]\', \'\', t).lower()\n\n\ndef mbc_seoul_pics():\n    """서울 MBC 표준FM · FM4U 일주일치 프로그램 사진 (제목 → 사진)"""\n    if MBC_PICS:\n        return MBC_PICS\n    d = today_kst()\n    for k in range(-1, 7):\n        day = d + datetime.timedelta(days=k)\n        for s in (\'FM\', \'FM4U\'):\n            try:\n                data = get_json(f\'https://control.imbc.com/Schedule/Radio/Time?sType={s}&broadDate={day:%Y%m%d}\',\n                                \'https://www.imbc.com/\')\n            except Exception:\n                continue\n            for it in data if isinstance(data, list) else []:\n                t, img = (it.get(\'Title\') or \'\').strip(), (it.get(\'Photo\') or \'\').strip()\n                if t and img:\n                    MBC_PICS.setdefault(mbc_key(t), \'https:\' + img if img.startswith(\'//\') else img)\n    MBC_PICS.setdefault(\'\', \'\')\n    return MBC_PICS\n\n\ndef mbc_image(title):\n    k = mbc_key(title)\n    pics = mbc_seoul_pics()\n    if len(k) < 4:  # "뉴스"처럼 짧은 이름은 헷갈려서 안 씀\n        return \'\'\n    if pics.get(k):\n        return pics[k]\n    # 이름 앞뒤가 조금 다른 경우 ("시선집중" ↔ "김종배의 시선집중"): 긴 쪽이 짧은 쪽을 품으면 같은 프로그램\n    best = max((sk for sk in pics if len(sk) >= 4 and (sk in k or k in sk)), key=len, default=\'\')\n    return pics.get(best, \'\')\n\n\ndef chmbc_day(channel, d):\n    """춘천MBC 그날 편성 (radio2=표준FM, radio=음악FM): (날짜, \'HH:MM\', 제목) — 24시 넘으면 다음 날"""\n    page = fetch(f\'https://chmbc.co.kr/guide2/channel/{channel}/date/{d:%Y-%m-%d}\', \'https://chmbc.co.kr/\')\n    rows = []\n    for hh, mm, title in re.findall(r\'left_section[^"]*">.*?<i>(\\d{1,2})시\\s*(\\d{1,2})분</i>.*?\'\n                                    r\'class="title-wrap">(.*?)<div id="guidetype"\', page, re.S):\n        h = int(hh)\n        title = text_of(title)\n        if title:\n            rows.append((d + datetime.timedelta(days=h // 24), f\'{h % 24:02d}:{int(mm):02d}\', title))\n    return rows\n\n\nMBC_REGIONAL = [  # 앱의 방송 이름, 그날 편성 가져오는 함수, 채널\n    (\'춘천MBC 표준FM\', chmbc_day, \'radio2\'),\n    (\'춘천MBC FM4U\', chmbc_day, \'radio\'),\n]\n\n\ndef mbc_regional():\n    start = today_kst()\n    days = []  # 요일 칸마다 가까운 날\n    for k in range(7):\n        d = start + datetime.timedelta(days=k)\n        if day_key(d) not in [day_key(x) for x in days]:\n            days.append(d)\n    fetch_days = sorted(set(days) | {x - datetime.timedelta(days=1) for x in days})  # 전날 \'24시~\'가 그날 새벽\n    out = {}\n    for station, fn, ch in MBC_REGIONAL:\n        by_date = {}\n        for d in fetch_days:\n            try:\n                rows = fn(ch, d)\n            except Exception as e:\n                print(f\'  ({station} {d} 못 가져옴: {e})\')\n                continue\n            for day, hm, title in rows:\n                p = {\'title\': title, \'start\': hm, \'end\': \'\'}\n                img = mbc_image(title)\n                if img:\n                    p[\'image\'] = img\n                by_date.setdefault(day, {})[hm] = p\n        week = {}\n        for d in days:\n            progs = clean_day(list(by_date.get(d, {}).values()))\n            if len(progs) >= 5:\n                week[day_key(d)] = progs\n        if week:\n            out[station] = week\n    return out\n'), ("('CPBC', cpbc), ('TBN', tbn)]", "('CPBC', cpbc), ('TBN', tbn), ('지역 MBC', mbc_regional)]")],
    'radio_provider.dart': [("      final isKbsMbcSbs = station.name.contains('KBS') ||\n          station.name.contains('MBC') ||\n          station.name.contains('SBS');", "      final isKbsMbcSbs = station.name.contains('KBS') ||\n          _mbcChannelTypes.containsKey(station.name) || // 서울 MBC만 (지역 MBC는 편성표 파일 사용)\n          station.name.contains('SBS');")],
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
