import 'package:flutter/material.dart';
import '../utils/title_font.dart';

/// 로고·제목 글자 위로 은은한 빛이 왼쪽 → 오른쪽으로 계속 지나감 (색 없이 회색/흰색)
/// 홈 로고 "파란"과 같은 움직임 — 라디오·자연·휴식 제목에도 같이 씀
class LogoShine extends StatefulWidget {
  final Widget child;
  final Color base; // 글자 색
  final Color glow; // 지나가는 빛 색
  const LogoShine({super.key, required this.child, required this.base, required this.glow});

  @override
  State<LogoShine> createState() => _LogoShineState();
}

class _LogoShineState extends State<LogoShine> with SingleTickerProviderStateMixin {
  // 3.5초마다 빛이 쉬지 않고 계속 흘러감 (홈 로고와 같게)
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final x = -0.5 + _c.value * 2.0; // 빛 위치: 왼쪽 밖 → 오른쪽 밖
        final base = widget.base;
        final glow = widget.glow;
        final mid = Color.lerp(base, glow, 0.55)!;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: const Alignment(-1, -0.4), // 살짝 비스듬히
            end: const Alignment(1, 0.4),
            colors: [base, base, mid, glow, mid, base, base],
            stops: [
              0,
              (x - 0.38).clamp(0.0, 1.0),
              (x - 0.16).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.16).clamp(0.0, 1.0),
              (x + 0.38).clamp(0.0, 1.0),
              1,
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}


/// 메뉴 첫 화면 위쪽 (라디오·자연·휴식): 앱 아이콘 + 제목(회색 빛) / 아래 설명 한 줄
/// 홈 로고(아이콘 + 파란소리 / PARANSORI)와 같은 짜임
class MenuTitle extends StatelessWidget {
  final String title; // 홈 카드 이름 (라디오 · 자연 · 휴식 · 집중)
  final String sub; // 홈 카드 설명
  final bool isDark;
  final Widget? subWidget; // 설명 글 대신 넣을 것 (나라별 라디오: 국기 + 나라 ▾)
  final VoidCallback? onTap; // 누르면 (나라별 라디오: 나라 고르기)
  const MenuTitle({super.key, required this.title, required this.sub, required this.isDark, this.subWidget, this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white : Colors.black;
    // 위쪽은 이름표라서 '(준비중)' 같은 끝 괄호는 빼기
    final shortSub = sub.replaceAll(RegExp(r'\s*[\x28（][^\x29）]*[\x29）]\s*$'), '');
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 앱 아이콘 (홈 로고와 같은 모양, 포인트 색과 상관없이 고정)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/logo_icon.png',
              width: 32, height: 32, filterQuality: FilterQuality.medium),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 위로만 회색 빛 (다크 모드는 흰 글자 위로 연한 회색 빛)
              LogoShine(
                base: base,
                glow: isDark ? const Color(0xFFA8A29A) : const Color(0xFF968F85),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling, // 로고처럼 글자 크기 설정과 상관없이 고정
                  style: titleFont(color: base, fontSize: 20, letterSpacing: 0.3),
                ),
              ),
              // 설명 한 줄 (또는 넣어 준 것): 긴 언어는 넘치지 않게 살짝 작아짐
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: subWidget ??
                    Text(
                      shortSub,
                      maxLines: 1,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(color: base.withOpacity(0.5), fontSize: 11.5, height: 1.2),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: row);
  }
}
