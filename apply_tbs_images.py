# -*- coding: utf-8 -*-
# 편성표 만드는 파일(tools/make_schedule.py)에 TBS 프로그램 사진 넣기
# 실행: python apply_tbs_images.py   (프로젝트 폴더에서)
import os, sys, json
P = os.path.join('tools', 'make_schedule.py')
EDITS = json.loads('[["def tbs():\\n    out = {}\\n    for station, path in ((\'TBS FM\', \'fm\'), (\'TBS eFM\', \'eFm\')):\\n        try:\\n            progs = tbs_one(path)\\n        except Exception as e:\\n            print(f\'  ({station} 못 가져옴: {e})\')\\n            continue\\n        if len(progs) >= 5:\\n            out[station] = {day_key(today_kst()): progs}\\n    return out", "DAYS = {\'월\': 0, \'화\': 1, \'수\': 2, \'목\': 3, \'금\': 4, \'토\': 5, \'일\': 6,\\n        \'mon\': 0, \'tue\': 1, \'wed\': 2, \'thu\': 3, \'fri\': 4, \'sat\': 5, \'sun\': 6,\\n        \'周一\': 0, \'周二\': 1, \'周三\': 2, \'周四\': 3, \'周五\': 4, \'周六\': 5, \'周日\': 6}\\n\\n\\ndef tbs_programs(list_path):\\n    # 프로그램 목록 화면: 사진 · 이름 · 요일 · 시간  (예: 함춘호의 포크송 월-금 10:00-12:00)\\n    page = fetch(f\'https://tbs.seoul.kr/{list_path}\', \'https://tbs.seoul.kr/\')\\n    page = re.sub(r\'<script.*?</script>|<style.*?</style>\', \'\', page, flags=re.S | re.I)\\n    out = []\\n    parts = re.split(r\'(?=<img\\\\s)\', page)\\n    for part in parts:\\n        src = re.match(r\'<img[^>]+src=[\\"\\\\\']([^\\"\\\\\']*/common/images/thumb/[^\\"\\\\\']+)[\\"\\\\\']\', part)\\n        if not src:\\n            continue\\n        text = text_of(part[part.find(\'>\') + 1:])\\n        tm = re.search(r\'(\\\\d{1,2}:\\\\d{2})\\\\s*[-~]\\\\s*(\\\\d{1,2}:\\\\d{2})\', text)\\n        if not tm:\\n            continue\\n        head = text[:tm.start()]\\n        dm = re.search(r\'(周[一二三四五六日]|[월화수목금토일]|Mon|Tue|Wed|Thu|Fri|Sat|Sun)\\\\s*(?:-|~|至)\\\\s*\'\\n                       r\'(周[一二三四五六日]|[월화수목금토일]|Mon|Tue|Wed|Thu|Fri|Sat|Sun)\', head, re.I)\\n        days = set(range(7))\\n        if dm:\\n            a, b = DAYS[dm.group(1).lower() if dm.group(1)[0].isascii() else dm.group(1)], \\\\\\n                   DAYS[dm.group(2).lower() if dm.group(2)[0].isascii() else dm.group(2)]\\n            days = set(range(a, b + 1)) if a <= b else set(range(a, 7)) | set(range(0, b + 1))\\n            head = head[:dm.start()]\\n        name = head.strip(\' ,\')\\n        img = src.group(1).replace(\'//\', \'/\').replace(\'https:/\', \'https://\').replace(\'http:/\', \'http://\')\\n        out.append({\'name\': name, \'start\': tm.group(1).zfill(5), \'end\': tm.group(2).zfill(5), \'days\': days,\\n                    \'image\': img if img.startswith(\'http\') else \'https://tbs.seoul.kr\' + img})\\n    return out\\n\\n\\ndef tbs_images(progs, plist, day):\\n    def key(t):\\n        return re.sub(r\'[\\\\s,.·!?~\\\\-()（）]\', \'\', t).lower()\\n\\n    def mins(t):\\n        return int(t[:2]) * 60 + int(t[3:5])\\n    for p in progs:\\n        # 1) 이름이 맞으면 (재방송 포함)\\n        for q in plist:\\n            words = [w for w in re.split(r\'\\\\s+\', q[\'name\']) if len(w) >= 2]\\n            name_hit = key(q[\'name\']) and (key(q[\'name\']) in key(p[\'title\']) or key(p[\'title\']) in key(q[\'name\']))\\n            tail_hit = len(words) >= 2 and key(\' \'.join(words[-2:])) in key(p[\'title\'])  # \\"Summer Lee Diverse Voices\\"\\n            if name_hit or tail_hit:\\n                p[\'image\'] = q[\'image\']\\n                break\\n        if p.get(\'image\'):\\n            continue\\n        # 2) 요일 · 시간이 맞으면 (4시간 넘는 긴 칸은 빼고)\\n        for q in plist:\\n            s, e = mins(q[\'start\']), mins(q[\'end\'])\\n            if e <= s or e - s > 240 or day.weekday() not in q[\'days\']:\\n                continue\\n            if s <= mins(p[\'start\']) < e:\\n                p[\'image\'] = q[\'image\']\\n                break\\n\\n\\ndef tbs():\\n    out = {}\\n    for station, path, list_path in ((\'TBS FM\', \'fm\', \'fm/programsDay.do\'),\\n                                     (\'TBS eFM\', \'eFm\', \'eFm/programsDaily.do\')):\\n        try:\\n            progs = tbs_one(path)\\n        except Exception as e:\\n            print(f\'  ({station} 못 가져옴: {e})\')\\n            continue\\n        try:\\n            tbs_images(progs, tbs_programs(list_path), today_kst())\\n        except Exception as e:\\n            print(f\'  ({station} 사진 못 가져옴: {e})\')\\n        if len(progs) >= 5:\\n            out[station] = {day_key(today_kst()): progs}\\n    return out"]]')
if not os.path.isfile(P):
    print('❌ tools/make_schedule.py 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if "def tbs_programs(" in t:
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
