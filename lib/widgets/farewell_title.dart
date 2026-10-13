import 'package:flutter/material.dart';
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
                                      // 밤 버전: 첫인사와 같은 색을 밝게 (어두운 사진 위에서 보이게)
                                      // 'Paransori' 글자와 같은 흰색 한 가지로 (사진과 안 튀게)
                                      color: Colors.white.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
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
