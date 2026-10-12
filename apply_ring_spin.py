# -*- coding: utf-8 -*-
# 홈 강조 색상 카드: 색 고리가 나타날 때 스르륵 한 바퀴 돌고 멈춤
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

SPIN = '''

/// 색 고리: 카드가 나타나면 잠깐 있다가 스르륵 한 바퀴 돌고 멈춤
class _SpinRing extends StatefulWidget {
  final Color hole;
  const _SpinRing({required this.hole});

  @override
  State<_SpinRing> createState() => _SpinRingState();
}

class _SpinRingState extends State<_SpinRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic),
      child: CustomPaint(painter: _ColorRingPainter(hole: widget.hole)),
    );
  }
}'''

EDITS = [
    ("색 고리를 도는 고리로",
     "            child: CustomPaint(painter: _ColorRingPainter(hole: card)),\n",
     "            child: _SpinRing(hole: card),\n"),
    ("도는 고리 만들기",
     "  bool shouldRepaint(covariant _ColorRingPainter old) => old.hole != hole;\n}",
     "  bool shouldRepaint(covariant _ColorRingPainter old) => old.hole != hole;\n}" + SPIN),
]
TEST_LINE = "    await prefs.remove('color_tip_done'); await prefs.remove('color_tip_shown'); prefs.setInt('app_launch_count', 2); // ★테스트용\n"

p = find('home_screen.dart')
if not p:
    print('❌ home_screen.dart 파일을 못 찾았어요'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
t = raw.replace('\r\n', '\n')
if 'class _SpinRing' in t:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for name, a, b in EDITS:
    if t.count(a) == 1:
        t = t.replace(a, b); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % t.count(a))
if ok and not all(t.count(x) == t.count(y) for x, y in ('()', '{}', '[]')):
    ok = False; print('❌ 괄호 개수가 안 맞아요')
if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)
shutil.copyfile(p, p + '.bak')
if crlf:
    t = t.replace('\n', '\r\n')
open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
