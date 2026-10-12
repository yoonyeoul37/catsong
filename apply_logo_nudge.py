# -*- coding: utf-8 -*-
# 홈 로고(한국어): 전체를 살짝 아래로 + 영어 Paransori 조금 더 진하게
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('home_screen.dart')
if not path:
    print('❌ lib 폴더에서 home_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if '// 로고 전체를 살짝 아래로' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)
if "for (final ch in 'Paransori'.split(''))" not in s:
    print('❌ 먼저 apply_logo_span.py를 적용해야 해요. 아무것도 저장 안 했어요.')
    sys.exit(1)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

rep('로고 전체를 살짝 아래로 (시작)',
    "                ? IntrinsicWidth(\n",
    "                ? Padding(\n"
    "                    // 로고 전체를 살짝 아래로 (오른쪽 아이콘들과 높이 맞춤)\n"
    "                    padding: const EdgeInsets.only(top: 4),\n"
    "                    child: IntrinsicWidth(\n")

rep('로고 전체를 살짝 아래로 (끝)',
    "                    ),\n"
    "                  )\n"
    "                : Column(\n"
    "                    // 해외",
    "                    ),\n"
    "                  ),\n"
    "                  )\n"
    "                : Column(\n"
    "                    // 해외")

rep('영어 Paransori 조금 더 진하게',
    "                                          color: logoInk.withOpacity(0.55),\n"
    "                                          fontSize: 12,\n",
    "                                          color: logoInk.withOpacity(0.75),\n"
    "                                          fontSize: 12,\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
