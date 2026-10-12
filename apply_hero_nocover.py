# -*- coding: utf-8 -*-
# 라디오 맨 위 사진 카드: 글자 띠가 사진(라디오)을 가리지 않게
#  사진은 위쪽에만, 글자는 그 아래 크림 띠에 (카드 높이 150 → 180)
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('radio_korea_screen2.dart')
if not path:
    print('❌ lib 폴더에서 radio_korea_screen2.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if '// 사진은 글자 띠 위에만' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

rep('카드 높이 150 → 180',
    "      child: Container(\n        height: 150,\n        margin: const EdgeInsets.only(bottom: 8),\n",
    "      child: Container(\n        height: 180,\n        margin: const EdgeInsets.only(bottom: 8),\n")

rep('사진은 글자 띠 위쪽에만 (시작)',
    "              Image.asset(\n"
    "                _heroImageNow(), // 아침·낮·저녁·밤 사진\n",
    "              Positioned(\n"
    "                left: 0,\n"
    "                right: 0,\n"
    "                top: 0,\n"
    "                bottom: 68, // 사진은 글자 띠 위에만 (라디오가 안 가려지게)\n"
    "                child: Image.asset(\n"
    "                _heroImageNow(), // 아침·낮·저녁·밤 사진\n")

rep('사진은 글자 띠 위쪽에만 (끝)',
    "                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD5E1EC)),\n"
    "              ),\n",
    "                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD5E1EC)),\n"
    "              ),\n"
    "              ),\n")

rep('글자 띠: 크림색 (사진 아래)',
    "              // 홈 카드와 같은 유리 띠\n"
    "              Positioned(\n"
    "                left: 0,\n"
    "                right: 0,\n"
    "                bottom: 0,\n"
    "                child: Container(\n"
    "                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),\n"
    "                  decoration: BoxDecoration(\n"
    "                    color: Colors.white.withOpacity(0.45),\n"
    "                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.65))),\n"
    "                  ),\n",
    "              // 사진 아래 크림 띠 (잠시 쉬어가요 카드와 같은 색)\n"
    "              Positioned(\n"
    "                left: 0,\n"
    "                right: 0,\n"
    "                bottom: 0,\n"
    "                child: Container(\n"
    "                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),\n"
    "                  decoration: const BoxDecoration(\n"
    "                    color: Color(0xFFFBF8F2),\n"
    "                  ),\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
