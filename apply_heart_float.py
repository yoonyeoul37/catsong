# -*- coding: utf-8 -*-
# 재생 화면 하트: 켤 때 하트가 통통 + 작은 하트 셋이 위로 떠올라요 (A안)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PATH = 'lib/screens/player_screen.dart'
MARK = 'class _HeartButton '

EDITS = [
('하트 버튼 바꾸기',
"""              IconButton(
                onPressed: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  musicProvider.toggleFavorite(song);
                  // (하트가 바로 바뀌어서 따로 알림 없음)
                },
                icon: Icon(
                  isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: isFav ? const Color(0xFFE05A4F) : baseColor.withOpacity(0.6),
                  size: 20,
                ),
              ),""",
"""              // 하트: 켤 때 통통 + 작은 하트 셋이 위로 떠올라요
              _HeartButton(
                isFav: isFav,
                offColor: baseColor.withOpacity(0.6),
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  musicProvider.toggleFavorite(song);
                },
              ),"""),
('하트 효과 만들기',
"""class _BreathingText extends StatefulWidget {""",
"""/// 재생 화면 하트: 켤 때만 하트가 통통 튀고 작은 하트 셋이 흔들리며 위로 떠올라요 (끌 때는 조용히)
class _HeartButton extends StatefulWidget {
  final bool isFav;
  final Color offColor;
  final VoidCallback onTap;
  const _HeartButton({required this.isFav, required this.offColor, required this.onTap});

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton> with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE05A4F);
  static const _total = 1240.0; // ms (마지막 작은 하트가 끝날 때까지)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1240));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 하트 통통: 1 → 1.35 → 0.9 → 1 (처음 0.45초)
  double _pop(double ms) {
    if (!_c.isAnimating) return 1;
    final t = (ms / 450).clamp(0.0, 1.0);
    if (t < 0.35) return 1 + 0.35 * Curves.easeOut.transform(t / 0.35);
    if (t < 0.65) return 1.35 - 0.45 * ((t - 0.35) / 0.3);
    return 0.9 + 0.1 * ((t - 0.65) / 0.35);
  }

  /// 작은 하트 하나: 1초 동안 위로 74 올라가며 커졌다가 흐려짐
  Widget _mini(double ms, double startMs, double dx) {
    final t = (ms - startMs) / 1000;
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final e = Curves.easeOut.transform(t);
    final op = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
    final wobble = math.sin(t * math.pi * 2) * 3; // 좌우로 살짝 흔들림
    return Transform.translate(
      offset: Offset(dx * e + wobble, -74 * e),
      child: Transform.scale(
        scale: 0.4 + 0.6 * e,
        child: Opacity(
          opacity: op.clamp(0.0, 1.0),
          child: const Icon(CupertinoIcons.heart_fill, color: _red, size: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!widget.isFav) _c.forward(from: 0); // 켤 때만
        widget.onTap();
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final ms = _c.value * _total;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_c.isAnimating) ...[
                  _mini(ms, 0, -14),
                  _mini(ms, 120, 4),
                  _mini(ms, 240, 16),
                ],
                Transform.scale(
                  scale: _pop(ms),
                  child: Icon(
                    widget.isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: widget.isFav ? _red : widget.offColor,
                    size: 20,
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

class _BreathingText extends StatefulWidget {"""),
]

def main():
    try:
        raw = open(PATH, 'rb').read().decode('utf-8')
    except FileNotFoundError:
        print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
        s = s.replace(old, new); print(f'✔ {name}')
    for o, c in ('{}', '()', '[]'):
        if (s.count(o) - s.count(c)) != (raw.count(o) - raw.count(c)):
            print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('저장했어요 ✔')

main()
