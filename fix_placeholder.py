# -*- coding: utf-8 -*-
# 숫자 들어가는 문구 6개: 기준 파일(app_ko.arb)에 "숫자"라고 알려 주기
import os, sys, json
p = os.path.join('lib', 'l10n', 'app_ko.arb')
KEYS = ['deleteSongsTitle', 'deletedSongsToast', 'cleanTitle', 'dailyNotPlayedTitle', 'dailyWeekCount']
with open(p, 'r', encoding='utf-8', newline='') as f: t = f.read()
d = json.loads(t)
miss = [k for k in KEYS if k not in d]
if miss:
    print('❌ 홈 번역이 아직 안 들어가 있어요:', ', '.join(miss)); sys.exit(1)
todo = [k for k in KEYS if '@' + k not in d]
if not todo:
    print('이미 적용돼 있어요'); sys.exit(0)
nl = '\r\n' if '\r\n' in t else '\n'
lines = ['  %s: {"placeholders": {"count": {"type": "int"}}}' % json.dumps('@' + k) for k in todo]
body = t.rstrip()[:-1].rstrip()
new = body + ',' + nl + (',' + nl).join(lines) + nl + '}' + (nl if t.endswith('\n') else '')
json.loads(new)
with open(p, 'w', encoding='utf-8', newline='') as f: f.write(new)
print('✔ app_ko.arb 숫자 표시 %d개' % len(todo))
