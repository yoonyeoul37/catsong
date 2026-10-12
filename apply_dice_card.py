# -*- coding: utf-8 -*-
# 라디오 사진 카드 ↔ 주사위 연결
#  주사위로 나온 방송이 카드에 그대로 남음: 이름표 '주사위가 고른 방송' + 그 방송 이름·프로그램
#  화면을 나갔다 오면 다시 '지금 듣기 좋은'
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

if '_diceChoice' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)
if '_nowNiceCard' not in s:
    print('❌ 먼저 apply_radio_kr_b.py를 적용해야 해요. 아무것도 저장 안 했어요.')
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

rep('주사위가 고른 방송 기억 칸',
    "  bool _diceIntro = false; // 처음 한 번만 가운데 큰 카드\n",
    "  bool _diceIntro = false; // 처음 한 번만 가운데 큰 카드\n"
    "  String? _diceChoice; // 주사위로 나온 방송 (카드에 그대로 보여줌)\n")

rep('주사위 판이 닫히길 기다리기',
    "    showRadioDice(context, _dicePool(), onOpen: (st) {\n",
    "    await showRadioDice(context, _dicePool(), onOpen: (st) {\n")

rep('주사위 판 닫히면 카드를 나온 방송으로',
    "    });\n"
    "  }\n"
    "\n"
    "  Future<void> _closeDiceIntro() async {\n",
    "    });\n"
    "    // 판이 닫히면: 주사위로 나와서 듣고 있는 방송을 카드에 그대로\n"
    "    if (!mounted) return;\n"
    "    final cur = context.read<RadioProvider>().currentStation?.name;\n"
    "    if (cur != null && koreanStations.any((k) => k.name == cur)) {\n"
    "      setState(() => _diceChoice = cur);\n"
    "    }\n"
    "  }\n"
    "\n"
    "  Future<void> _closeDiceIntro() async {\n")

rep('카드: 주사위 방송이 있으면 그걸로',
    "    final i = _pickNiceIndex(radio);\n",
    "    final diceI = _diceChoice == null ? -1 : koreanStations.indexWhere((k) => k.name == _diceChoice);\n"
    "    final i = diceI >= 0 ? diceI : _pickNiceIndex(radio);\n")

rep("이름표: '주사위가 고른 방송'",
    "                            Text('지금 듣기 좋은',\n",
    "                            Text(diceI >= 0 ? '주사위가 고른 방송' : '지금 듣기 좋은',\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
