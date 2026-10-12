# -*- coding: utf-8 -*-
# 끝인사 B안: 'Paransori' + 소리 막대 + 장면별 한 줄 인사 (6군데 모두)
# + 외국 화면에선 끝인사 목소리 안 틀기 + 첫인사 글자 위치 위로 (h*0.22 → 0.13)
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

WIDGET = r'''import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/greeting_images.dart';

/// 끝인사 글자: 'Paransori'가 떠오르고 → 소리 막대가 자라 숨 쉬다 잦아들고
/// → 한 줄 인사 → 글자 사이가 벌어지며 흐려짐 (첫인사와 짝, 7초)
class FarewellTitle extends StatefulWidget {
  const FarewellTitle({super.key});

  @override
  State<FarewellTitle> createState() => _FarewellTitleState();
}

class _FarewellTitleState extends State<FarewellTitle> with SingleTickerProviderStateMixin {
  static const _total = 7.0; // 초
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 7000))..forward();

  // 첫인사와 같은 소리 막대
  static const _barH = <int>[4, 7, 11, 16, 10, 20, 14, 24, 18, 12, 22, 15, 9, 17, 11, 6, 13, 8, 5, 4];
  static const _barColors = <Color>[Color(0xFFFF9A70), Color(0xFFEE978B), Color(0xFFDE94A6), Color(0xFFCD91C1), Color(0xFFBC8EDC), Color(0xFFB492F1), Color(0xFFC5AAF4), Color(0xFFD5C2F7), Color(0xFFE6DBFA), Color(0xFFF7F3FD), Color(0xFFF2FAF3), Color(0xFFD9F0DA), Color(0xFFBFE6C1), Color(0xFFA6DCA9), Color(0xFF8CD290), Color(0xFF99C786), Color(0xFFB3BC80), Color(0xFFCCB17B), Color(0xFFE6A575), Color(0xFFFF9A70)];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // 0~7초 중 [from]~[to]초 구간의 진행(0~1)
  double _seg(double from, double to, [Curve curve = Curves.linear]) {
    final sec = _c.value * _total;
    return curve.transform(((sec - from) / (to - from)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final line = farewellLine(context);
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final tin = _seg(0.6, 1.8, Curves.easeOutCubic); // 글자 떠오름
            final tout = _seg(4.6, 6.2, Curves.easeIn); // 글자 흐려짐
            final sin = _seg(1.6, 2.6, Curves.easeOutCubic); // 한 줄 인사
            final sout = _seg(4.8, 6.2, Curves.easeIn);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: h * 0.13, // 첫인사와 같은 자리
                  child: Column(
                    children: [
                      Opacity(
                        opacity: (tin * (1 - tout)).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - tin)),
                          child: Text(
                            'Paransori',
                            textAlign: TextAlign.center,
                            textScaler: TextScaler.noScaling,
                            style: GoogleFonts.quicksand(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5 + 4.5 * tout,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 소리 막대: 가운데서 자라고 → 숨 쉬듯 → 잦아듦
                      SizedBox(
                        height: 34,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < _barH.length; i++) ...[
                              if (i > 0) const SizedBox(width: 3.5),
                              Builder(builder: (_) {
                                final d = (i - 10) * (i - 10) * 0.006;
                                final grow = _seg(1.2 + d, 1.8 + d, Curves.easeOutBack);
                                final shrink = _seg(4.4 + d, 5.2 + d, Curves.easeIn);
                                final sec = _c.value * _total;
                                final phase = (((sec - 2.2) / 1.1) + i * 0.07) % 1.0;
                                final breathe = sec > 2.2 && sec < 4.4
                                    ? 1 - 0.45 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                                    : 1.0;
                                final bh = (2 + (_barH[i] * 1.25 - 2) * grow) * breathe * (1 - 0.92 * shrink);
                                return Opacity(
                                  opacity: (1 - 0.7 * shrink).clamp(0.0, 1.0),
                                  child: Container(
                                    width: 3,
                                    height: bh.clamp(2.0, 40.0),
                                    decoration: BoxDecoration(
                                      color: _barColors[i],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: (sin * (1 - sout)).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - sin)),
                          child: Text(
                            line,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 1)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
'''

LINE_FN = r'''
/// 끝인사 한 줄 인사: 오늘 장면에 맞게 (한국어 화면은 한국어, 그 밖은 영어)
String farewellLine(BuildContext context) {
  const ko = ['좋은 음악과 함께한 하루였어요', '오늘 하루도 수고했어요', '편안한 밤 되세요', '푹 자고 내일 만나요'];
  const en = ['What a day with good music', 'You did great today', 'Have a peaceful night', 'Sleep well, see you tomorrow'];
  return (_lang(context) == 'ko' ? ko : en)[_scene];
}
'''

SCREENS = ['home_screen.dart', 'player_screen.dart', 'nature_sounds_screen.dart',
           'nature_sound_detail_screen.dart', 'radio_player_screen.dart', 'sound_mix_screen.dart']
IMP_A = "import '../utils/greeting_images.dart';\n"
IMP_B = "import '../utils/greeting_images.dart';\nimport '../widgets/farewell_title.dart';\n"
CHILD_A = "              alignment: Alignment.center,\n              child: const SizedBox.shrink(),"
CHILD_B = "              alignment: Alignment.center,\n              child: const FarewellTitle(), // Paransori + 소리 막대 + 한 줄 인사"
VOICE_A = "    if (context.read<ThemeProvider>().voiceGreetingEnabled) {\n      final farewellPlayer = AudioPlayer();"
VOICE_B = "    if (langCode == 'ko' && context.read<ThemeProvider>().voiceGreetingEnabled) { // 목소리는 한국어만\n      final farewellPlayer = AudioPlayer();"
VOICE_DONE = "if (langCode == 'ko' && context.read<ThemeProvider>().voiceGreetingEnabled)"

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw

def diff(t):
    return [t.count(x) - t.count(y) for x, y in ('()', '{}', '[]')]

gp = find('greeting_images.dart')
mp = os.path.join(LIB, 'main.dart')
wp = os.path.join(LIB, 'widgets', 'farewell_title.dart')
if os.path.exists(wp):
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
out = {}

print('[greeting_images.dart]')
if not gp:
    ok = False; print('  ❌ 파일을 못 찾았어요')
else:
    g, gc = load(gp)
    if '_scene' in g and '_lang(' in g and 'farewellLine' not in g:
        out[gp] = (g.rstrip('\n') + '\n' + LINE_FN, gc); print('  ✔ 장면별 한 줄 인사')
    else:
        ok = False; print('  ❌ 장면별 한 줄 인사 (예전 내용과 달라요)')

print('[main.dart]')
m, mc = load(mp)
a = "                top: h * 0.22, // 파란 하늘 자리"
if m.count(a) == 1:
    out[mp] = (m.replace(a, "                top: h * 0.13, // 사람·소품과 안 겹치게 위쪽 빈 곳"), mc); print('  ✔ 첫인사 글자 위로')
else:
    ok = False; print('  ❌ 첫인사 글자 위로 (찾은 개수: %d)' % m.count(a))

for s in SCREENS:
    p = find(s)
    print('[%s]' % s)
    if not p:
        ok = False; print('  ❌ 파일을 못 찾았어요'); continue
    t, c = load(p)
    t0 = t
    for name, x, y in (('끝인사 글자 연결', IMP_A, IMP_B), ('끝인사 글자 넣기', CHILD_A, CHILD_B)):
        if t.count(x) == 1:
            t = t.replace(x, y); print('  ✔', name)
        else:
            ok = False; print('  ❌', name, '(찾은 개수: %d)' % t.count(x))
    if VOICE_DONE in t or "if (langCode == 'ko' && context.read<ThemeProvider>().voiceGreetingEnabled)" in t:
        print('  ✔ 목소리는 한국어만 (이미 돼 있음)')
    elif t.count(VOICE_A) == 1:
        t = t.replace(VOICE_A, VOICE_B); print('  ✔ 목소리는 한국어만')
    else:
        ok = False; print('  ❌ 목소리는 한국어만 (찾은 개수: %d)' % t.count(VOICE_A))
    if diff(t) != diff(t0):
        ok = False; print('  ❌ 괄호 개수가 안 맞아요')
    out[p] = (t, c)

wt = WIDGET
if diff(wt) != [0, 0, 0]:
    ok = False; print('❌ 새 파일 괄호가 안 맞아요')

if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)

os.makedirs(os.path.dirname(wp), exist_ok=True)
open(wp, 'wb').write(WIDGET.replace('\n', '\r\n').encode('utf-8'))
print('\n✔ 새 파일: lib/widgets/farewell_title.dart')
for p, (t, c) in out.items():
    shutil.copyfile(p, p + '.bak')
    if c:
        t = t.replace('\n', '\r\n')
    open(p, 'wb').write(t.encode('utf-8'))
print('\n완료!')
