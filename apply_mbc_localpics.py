# -*- coding: utf-8 -*-
# 지역 MBC 프로그램 사진: 제주·대전·광주·목포 홈페이지 프로그램 목록에서 지역 프로그램 사진 가져오기
# 실행: python apply_mbc_localpics.py
import os, sys

EDITS = {
    'make_schedule.py': [('import json, sys, ssl, time, datetime, urllib.request, urllib.parse, os, re, html as htmllib', 'import json, sys, ssl, time, datetime, difflib, urllib.request, urllib.parse, os, re, html as htmllib'), ('MBC_REGIONAL = [  # 앱의 방송 이름, 그날 편성 가져오는 함수, 채널', '# 지역 홈페이지 \'라디오 프로그램\' 목록 카드: (비교용 이름, 요일들, 시작 분, 사진) — 지역 프로그램 사진용\nLOCAL_CARDS = {}\nWEEKDAY_IDX = {\'월\': 0, \'화\': 1, \'수\': 2, \'목\': 3, \'금\': 4, \'토\': 5, \'일\': 6}\n\n\ndef mbcnet_cards(base):\n    """제주·대전·광주·목포MBC (같은 모양 홈페이지)의 라디오 프로그램 목록"""\n    if base in LOCAL_CARDS:\n        return LOCAL_CARDS[base]\n    cards = []\n    try:\n        page = fetch(base + \'/RadioProgram\', base + \'/\')\n        for inner in re.findall(r\'<a[^>]+href=["\\\'][^"\\\']*/RadioProgram/\\d+/home["\\\'][^>]*>(.*?)</a>\', page, re.S):\n            img = re.search(r\'<img[^>]+src=["\\\']([^"\\\']+)\', inner)\n            m = re.match(r\'(.*?)\\s+((?:[월화수목금토일]\\s*)+)\\s*(\\d{1,2})시\\s*(\\d{1,2})분\', text_of(inner))\n            if img and m:\n                cards.append((mbc_key(m.group(1)), {WEEKDAY_IDX[x] for x in re.findall(\'[월화수목금토일]\', m.group(2))},\n                              int(m.group(3)) * 60 + int(m.group(4)), urllib.parse.urljoin(base + \'/\', img.group(1))))\n    except Exception as e:\n        print(f\'  ({base} 프로그램 사진 못 가져옴: {e})\')\n    LOCAL_CARDS[base] = cards\n    return cards\n\n\ndef same_name(a, b):\n    """비교용 이름 둘이 같은 프로그램인지: 4글자 넘게 겹치면 (예: 임서영과김준규의… ↔ 임서영김준규의…)"""\n    if len(a) < 4 or len(b) < 4:\n        return False\n    m = difflib.SequenceMatcher(None, a, b).find_longest_match(0, len(a), 0, len(b))\n    return m.size >= min(6, len(a), len(b))\n\n\ndef local_pics(progs, d, cards):\n    """지역 프로그램이면 지역 사진으로 (서울 사진보다 먼저) — 요일 맞고, 이름 겹치고, 시작 시간이 90분 안"""\n    for p in progs:\n        k = mbc_key(p[\'title\'])\n        s = int(p[\'start\'][:2]) * 60 + int(p[\'start\'][3:5])\n        for ck, wds, cm, img in cards:\n            if d.weekday() in wds and abs(s - cm) <= 90 and same_name(k, ck):\n                p[\'image\'] = img\n                break\n\n\nMBC_REGIONAL = [  # 앱의 방송 이름, 그날 편성 가져오는 함수, 채널'), ("    for station, fn, ch in MBC_REGIONAL:\n        by_date = {}\n        for d in fetch_days:\n            try:\n                rows = fn(ch, d)\n            except Exception as e:\n                print(f'  ({station} {d} 못 가져옴: {e})')\n                continue\n            for day, hm, title in rows:\n                p = {'title': title, 'start': hm, 'end': ''}\n                img = mbc_image(title)\n                if img:\n                    p['image'] = img\n                by_date.setdefault(day, {})[hm] = p\n        week = {}\n        for d in days:\n            progs = clean_day(list(by_date.get(d, {}).values()))\n            if len(progs) >= 5:\n                week[day_key(d)] = progs\n        if week:\n            out[station] = week\n    return out\n", "    for station, fn, ch in MBC_REGIONAL:\n        by_date = {}\n        # 지역 프로그램 사진 (제주·대전·광주·목포: 홈페이지 프로그램 목록)\n        cards = mbcnet_cards('{0.scheme}://{0.netloc}'.format(urllib.parse.urlsplit(ch))) if fn is mbcnet_day else []\n        for d in fetch_days:\n            try:\n                rows = fn(ch, d)\n            except Exception as e:\n                print(f'  ({station} {d} 못 가져옴: {e})')\n                continue\n            for day, hm, title in rows:\n                p = {'title': title, 'start': hm, 'end': ''}\n                img = mbc_image(title)\n                if img:\n                    p['image'] = img\n                by_date.setdefault(day, {})[hm] = p\n        week = {}\n        for d in days:\n            progs = clean_day(list(by_date.get(d, {}).values()))\n            if cards:\n                local_pics(progs, d, cards)\n            if len(progs) >= 5:\n                week[day_key(d)] = progs\n        if week:\n            out[station] = week\n    return out\n")],
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
