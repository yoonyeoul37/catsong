# -*- coding: utf-8 -*-
# 춘천MBC 지역 프로그램 사진: 홈페이지 라디오 프로그램 페이지에서 가져오기 (김지후의 정오의 희망곡 · 이브닝 강원 등)
# 실행: python apply_chmbc_pics.py
import os, sys

EDITS = {
    'make_schedule.py': [('def same_name(a, b):', 'def chmbc_cards():\n    """춘천MBC 라디오 프로그램 페이지들 (이름 · 요일 · 시간 · 사진) — 지역 프로그램 사진용"""\n    base = \'https://chmbc.co.kr\'\n    if base in LOCAL_CARDS:\n        return LOCAL_CARDS[base]\n    cards = []\n    try:\n        page = fetch(base + \'/programme_list/Radio\', base + \'/\')\n        links = list(dict.fromkeys(re.findall(r\'href=["\\\'](?:https://chmbc\\.co\\.kr)?(/programme/[^"\\\'#?]+)["\\\']\', page)))\n        for path in links[:20]:\n            try:\n                t = fetch(base + path, base + \'/programme_list/Radio\')\n            except Exception:\n                continue\n            title = re.search(r\'property=["\\\']og:title["\\\']\\s+content=["\\\']([^"\\\']*)\', t)\n            img = re.search(r\'property=["\\\']og:image["\\\']\\s+content=["\\\']([^"\\\']*)\', t)\n            if not (title and img and \'Radio\' in title.group(1)):  # TV 프로그램은 빼기\n                continue\n            name = re.sub(r\'\\s*:+\\s*Radio.*$\', \'\', htmllib.unescape(title.group(1))).strip()\n            m = re.search(r\'([월화수목금토일])\\s*-\\s*([월화수목금토일])\\s*(\\d{1,2})시\\s*(\\d{1,2})분\', text_of(t))\n            if not m:\n                continue\n            a, b = WEEKDAY_IDX[m.group(1)], WEEKDAY_IDX[m.group(2)]\n            cards.append((mbc_key(name), set(range(a, b + 1)), int(m.group(3)) * 60 + int(m.group(4)), img.group(1)))\n    except Exception as e:\n        print(f\'  (춘천MBC 프로그램 사진 못 가져옴: {e})\')\n    LOCAL_CARDS[base] = cards\n    return cards\n\n\ndef same_name(a, b):'), ("        cards = mbcnet_cards('{0.scheme}://{0.netloc}'.format(urllib.parse.urlsplit(ch))) if fn is mbcnet_day else []", "        cards = (mbcnet_cards('{0.scheme}://{0.netloc}'.format(urllib.parse.urlsplit(ch))) if fn is mbcnet_day\n                 else chmbc_cards() if fn is chmbc_day else [])")],
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
