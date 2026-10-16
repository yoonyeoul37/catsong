# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 TBN 프로그램 사진 넣기
# 실행: python apply_tbn_images.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["    for hh, mm, title in re.findall(r\'<tr>\\\\s*<td>\\\\s*(\\\\d{1,2})\\\\s*</td>\\\\s*<td>\\\\s*(\\\\d{1,2})\\\\s*</td>\\\\s*\'\\n                                    r\'<td[^>]*>.*?<strong>(.*?)</strong>\', table, re.S):\\n        h = int(hh)\\n        title = text_of(title)\\n        if title:\\n            rows.append((d + datetime.timedelta(days=h // 24), f\'{h % 24:02d}:{int(mm):02d}\', title))\\n    return rows\\n", "    for hh, mm, link, title in re.findall(r\'<tr>\\\\s*<td>\\\\s*(\\\\d{1,2})\\\\s*</td>\\\\s*<td>\\\\s*(\\\\d{1,2})\\\\s*</td>\\\\s*\'\\n                                          r\'<td[^>]*>(.*?)<strong>(.*?)</strong>\', table, re.S):\\n        h = int(hh)\\n        title = text_of(title)\\n        seq = re.search(r\'forum_seq=(\\\\d+)\', link)  # 프로그램 소개 페이지 번호 (사진 찾을 때 씀)\\n        if title:\\n            rows.append((d + datetime.timedelta(days=h // 24), f\'{h % 24:02d}:{int(mm):02d}\', title,\\n                         seq.group(1) if seq else \'\'))\\n    return rows\\n\\n\\nTBN_PICS = {}  # 프로그램 번호 → 사진 (같은 프로그램은 한 번만 가져오기)\\n\\n\\ndef tbn_image(seq):\\n    \\"\\"\\"프로그램 소개 페이지 위쪽의 큰 배경 사진\\"\\"\\"\\n    if not seq:\\n        return \'\'\\n    if seq not in TBN_PICS:\\n        TBN_PICS[seq] = \'\'\\n        try:\\n            page = fetch(f\'https://www.tbn.or.kr/program/main.tbn?forum_seq={seq}&area_code=6\',\\n                         \'https://www.tbn.or.kr/main.tbn\', insecure=True)\\n            m = re.search(r\'class=\\"program-bg\\"[^>]*background-image\\\\s*:\\\\s*url\\\\(([^)]+)\\\\)\', page)\\n            if m:\\n                TBN_PICS[seq] = urllib.parse.urljoin(\'https://www.tbn.or.kr/\', m.group(1).strip(\'\\\\\'\\" \'))\\n        except Exception as e:\\n            print(f\'  (TBN 사진 {seq} 못 가져옴: {e})\')\\n    return TBN_PICS[seq]\\n\\n\\ndef tbn_item(title, hm, seq):\\n    p = {\'title\': title, \'start\': hm, \'end\': \'\'}\\n    img = tbn_image(seq)\\n    if img:\\n        p[\'image\'] = img\\n    return p\\n"], ["            for day, hm, title in national.get(d, []):\\n                by_date.setdefault(day, {}).setdefault(hm, {\'title\': title, \'start\': hm, \'end\': \'\'})\\n            for day, hm, title in local:  # 같은 시간이면 지역 방송이 우선\\n                by_date.setdefault(day, {})[hm] = {\'title\': title, \'start\': hm, \'end\': \'\'}\\n", "            for day, hm, title, seq in national.get(d, []):\\n                if hm not in by_date.get(day, {}):\\n                    by_date.setdefault(day, {})[hm] = tbn_item(title, hm, seq)\\n            for day, hm, title, seq in local:  # 같은 시간이면 지역 방송이 우선\\n                by_date.setdefault(day, {})[hm] = tbn_item(title, hm, seq)\\n"], ["    \\"\\"\\"그날 그 지역 편성표 칸들: (날짜, \'HH:MM\', 제목) — 24시 넘으면 다음 날\\"\\"\\"", "    \\"\\"\\"그날 그 지역 편성표 칸들: (날짜, \'HH:MM\', 제목, 프로그램 번호) — 24시 넘으면 다음 날\\"\\"\\""]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if 'def tbn_image' in t:
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
