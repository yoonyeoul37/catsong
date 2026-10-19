import 'package:flutter/material.dart';
import '../utils/title_font.dart';
import 'logo_eq_bars.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/locale_holder.dart';

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


/// 메뉴 첫 화면 위쪽 (라디오·자연소리·휴식과 집중): 제목(프리텐다드 SemiBold) + 오른쪽 작은 소리 막대를 한 묶음으로 가운데
/// 아래에 작은 영문 부제(RADIO · NATURE SOUNDS · REST & FOCUS) — 나라별 라디오는 영문 대신 국기 + 나라 ▾
class MenuTitle extends StatelessWidget {
  final String title; // 홈 카드 이름 (라디오 · 자연 · 휴식 · 집중) — 위쪽엔 전용 이름으로 바꿔 보여 줌
  final String sub; // 홈 카드 설명
  final bool isDark;
  final Widget? subWidget; // 영문 부제 대신 넣을 것 (나라별 라디오: 국기 + 나라 ▾)
  final VoidCallback? onTap; // 누르면 (나라별 라디오: 나라 고르기)
  const MenuTitle({super.key, required this.title, required this.sub, required this.isDark, this.subWidget, this.onTap});

  /// 위쪽 제목 (홈 카드 이름은 그대로 두고 여기만): 라디오 · 자연소리 · 휴식과 집중
  String _headTitle() {
    if (title == tr.catRadio) return tr.menuHeadRadio;
    if (title == tr.catNature) return tr.menuHeadNature;
    if (title == tr.catRest) return tr.menuHeadRest;
    return title;
  }

  /// 영문 부제 — 제목이 이미 같은 영어면(Radio / RADIO) 같은 말 두 번 대신 PARANSORI
  String? _capsFor(String head) {
    String? c;
    if (title == tr.catRadio) c = 'RADIO';
    if (title == tr.catNature) c = 'NATURE SOUNDS';
    if (title == tr.catRest) c = 'REST & FOCUS';
    if (c == null) return null;
    String letters(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return letters(head) == letters(c) ? 'PARANSORI' : c;
  }

  @override
  Widget build(BuildContext context) {
    // 제목: 순검정 대신 부드러운 먹색 (다크는 크림색)
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF2B2722);
    final head = _headTitle();
    final caps = subWidget == null ? _capsFor(head) : null;

    // 제목 + 소리 막대 (한 묶음)
    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: LogoShine(
            base: ink,
            glow: isDark ? const Color(0xFFA8A29A) : const Color(0xFF968F85),
            child: Text(
              head,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling, // 로고처럼 글자 크기 설정과 상관없이 고정
              style: TextStyle(
                fontFamily: 'PretendardTitle',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: -0.3,
                height: 1.15,
                color: ink,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Padding(
          padding: EdgeInsets.only(bottom: 4), // 막대 바닥을 글자 바닥선에 맞춤
          child: LogoEqBars(),
        ),
      ],
    );

    final col = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        titleRow,
        const SizedBox(height: 3),
        if (caps != null)
          // 영문 부제: 작고 은은한 회색, 자간은 고정(지나치게 넓지 않게), 가운데
          Text(
            caps,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: GoogleFonts.quicksand(
              color: ink.withOpacity(0.45),
              fontSize: 9,
              height: 1.0,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          // 나라별 라디오(국기 + 나라 ▾) 등: 길면 넘치지 않게 살짝 작아짐
          FittedBox(
            fit: BoxFit.scaleDown,
            child: subWidget ??
                Text(
                  sub.replaceAll(RegExp(r'\s*[\x28（][^\x29）]*[\x29）]\s*$'), ''),
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(color: ink.withOpacity(0.5), fontSize: 11.5, height: 1.2),
                ),
          ),
      ],
    );
    if (onTap == null) return col;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: col);
  }
}
