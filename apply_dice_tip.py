# -*- coding: utf-8 -*-
# 라디오 사진 카드: 주사위 안내 말풍선 (A안)
#  - 들어오고 0.6초 뒤, 주사위 왼쪽에 먹색 말풍선 "던져보세요!" + 주사위 데굴 흔들기 → 3초 뒤 사라짐
#  - 주사위를 한 번이라도 눌렀거나, 말풍선을 5번 봤으면 다시 안 나옴
#  - 주사위 버튼 바탕: 흰색 → 베이지 (크림 띠 위에서 또렷하게)
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

if '_diceTip' in s:
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

rep('말풍선 기억 칸',
    "  bool _diceIntro = false; // 처음 한 번만 가운데 큰 카드\n",
    "  bool _diceIntro = false; // 처음 한 번만 가운데 큰 카드\n"
    "  bool _diceTip = false; // 주사위 옆 말풍선 \"던져보세요!\"\n"
    "  double _diceWiggle = 0; // 주사위 데굴 (돌린 정도)\n"
    "\n"
    "  /// 주사위를 아직 안 눌렀으면, 들어올 때 5번까지 말풍선 + 데굴\n"
    "  Future<void> _maybeShowDiceTip() async {\n"
    "    final p = await SharedPreferences.getInstance();\n"
    "    if ((p.getInt('radioDiceCount') ?? 0) > 0) return;\n"
    "    final shown = p.getInt('radioDiceTipShown') ?? 0;\n"
    "    if (shown >= 5) return;\n"
    "    await Future.delayed(const Duration(milliseconds: 600));\n"
    "    if (!mounted || _diceIntro || _mode != _ViewMode.all) return; // 처음 큰 카드가 떠 있으면 안 보여줌\n"
    "    await p.setInt('radioDiceTipShown', shown + 1);\n"
    "    setState(() {\n"
    "      _diceTip = true;\n"
    "      _diceWiggle = -0.06;\n"
    "    });\n"
    "    for (final (ms, w) in const [(170, 0.05), (340, -0.03), (500, 0.0)]) {\n"
    "      Future.delayed(Duration(milliseconds: ms), () {\n"
    "        if (mounted) setState(() => _diceWiggle = w);\n"
    "      });\n"
    "    }\n"
    "    Future.delayed(const Duration(seconds: 3), () {\n"
    "      if (mounted) setState(() => _diceTip = false);\n"
    "    });\n"
    "  }\n")

rep('들어올 때 말풍선 확인',
    "        _diceIntro = !(p.getBool('radioDiceIntroSeen') ?? false);\n"
    "      });\n"
    "    });\n",
    "        _diceIntro = !(p.getBool('radioDiceIntroSeen') ?? false);\n"
    "      });\n"
    "      _maybeShowDiceTip();\n"
    "    });\n")

rep('주사위 누르면 말풍선 바로 닫기',
    "  Future<void> _openDice() async {\n"
    "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n",
    "  Future<void> _openDice() async {\n"
    "    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
    "    if (_diceTip) setState(() => _diceTip = false);\n")

rep('주사위 버튼: 베이지 바탕 + 왼쪽 말풍선 + 데굴',
    "                      GestureDetector(\n"
    "                        behavior: HitTestBehavior.opaque,\n"
    "                        onTap: _openDice,\n"
    "                        child: Container(\n"
    "                          width: 38,\n"
    "                          height: 38,\n"
    "                          alignment: Alignment.center,\n"
    "                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), shape: BoxShape.circle),\n"
    "                          child: const RollDiceIcon(size: 21, color: ink),\n"
    "                        ),\n"
    "                      ),\n",
    "                      Stack(\n"
    "                        clipBehavior: Clip.none,\n"
    "                        children: [\n"
    "                          GestureDetector(\n"
    "                            behavior: HitTestBehavior.opaque,\n"
    "                            onTap: _openDice,\n"
    "                            child: AnimatedRotation(\n"
    "                              turns: _diceWiggle,\n"
    "                              duration: const Duration(milliseconds: 160),\n"
    "                              curve: Curves.easeInOut,\n"
    "                              child: Container(\n"
    "                                width: 38,\n"
    "                                height: 38,\n"
    "                                alignment: Alignment.center,\n"
    "                                // 크림 띠 위에서 또렷하게: 홈 바탕과 같은 베이지\n"
    "                                decoration: const BoxDecoration(color: Color(0xFFEDE7DA), shape: BoxShape.circle),\n"
    "                                child: const RollDiceIcon(size: 21, color: ink),\n"
    "                              ),\n"
    "                            ),\n"
    "                          ),\n"
    "                          // 주사위 왼쪽 말풍선 \"던져보세요!\" (사진을 안 가리게 띠 안에서 옆으로)\n"
    "                          Positioned(\n"
    "                            right: 46,\n"
    "                            top: 0,\n"
    "                            bottom: 0,\n"
    "                            child: IgnorePointer(\n"
    "                              child: AnimatedOpacity(\n"
    "                                opacity: _diceTip ? 1 : 0,\n"
    "                                duration: const Duration(milliseconds: 280),\n"
    "                                child: AnimatedSlide(\n"
    "                                  offset: _diceTip ? Offset.zero : const Offset(0.08, 0),\n"
    "                                  duration: const Duration(milliseconds: 280),\n"
    "                                  curve: Curves.easeOutCubic,\n"
    "                                  child: Center(\n"
    "                                    child: Row(\n"
    "                                      mainAxisSize: MainAxisSize.min,\n"
    "                                      children: [\n"
    "                                        Container(\n"
    "                                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),\n"
    "                                          decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(11)),\n"
    "                                          child: const Text('던져보세요!',\n"
    "                                              textScaler: TextScaler.noScaling,\n"
    "                                              style: TextStyle(\n"
    "                                                  color: Color(0xFFF4EFE5), fontSize: 12, fontWeight: FontWeight.w700)),\n"
    "                                        ),\n"
    "                                        // 꼬리 (주사위 쪽)\n"
    "                                        Transform.translate(\n"
    "                                          offset: const Offset(-5, 0),\n"
    "                                          child: Transform.rotate(\n"
    "                                            angle: 0.785398,\n"
    "                                            child: Container(\n"
    "                                              width: 9,\n"
    "                                              height: 9,\n"
    "                                              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(2)),\n"
    "                                            ),\n"
    "                                          ),\n"
    "                                        ),\n"
    "                                      ],\n"
    "                                    ),\n"
    "                                  ),\n"
    "                                ),\n"
    "                              ),\n"
    "                            ),\n"
    "                          ),\n"
    "                        ],\n"
    "                      ),\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
