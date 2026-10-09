# -*- coding: utf-8 -*-
# "Paran" 숨쉬기를 포인트 색으로 + 가사 화면 유리 카드의 Paransori에도 숨쉬기 넣기
# (기본 파란소리 색이면 지금 하늘색 그대로)
import os, sys

P = "lib/screens/player_screen.dart"
L = "lib/screens/lyrics_screen.dart"

EDITS = [
    # ── 재생화면: 숨쉬는 색을 포인트 색에서 만들기 ──
    (P,
"""  @override
  Widget build(BuildContext context) {
    final base = widget.style.color ?? _dim;
    return TweenAnimationBuilder<double>(
      // 재생 중 1 → 일시정지 0 (원래 색으로 부드럽게)""",
"""  @override
  Widget build(BuildContext context) {
    // 포인트 색 따라가기 (기본 파란소리 색이면 원래 하늘색 그대로)
    final point = context.watch<ThemeProvider>().primaryColor;
    final isDefault = point.value == 0xFF2589E8;
    final isInk = point.computeLuminance() < 0.08; // 먹색처럼 아주 어두운 색은 사진 위에서 안 보여서 흰빛으로
    final dim = isDefault
        ? _dim
        : isInk
            ? Colors.white.withOpacity(0.55)
            : point.withOpacity(0.7);
    final bright = isDefault
        ? _bright
        : isInk
            ? Colors.white.withOpacity(0.95)
            : Color.lerp(point, Colors.white, 0.45)!.withOpacity(0.8);
    final glow = isDefault ? const Color(0xFF7FB8F0) : bright.withOpacity(1);
    final base = isDefault
        ? (widget.style.color ?? _dim)
        : isInk
            ? Colors.white.withOpacity(0.7)
            : Color.lerp(point, Colors.white, 0.3)!.withOpacity(0.8);
    return TweenAnimationBuilder<double>(
      // 재생 중 1 → 일시정지 0 (원래 색으로 부드럽게)"""),
    (P,
"""          final breath = Color.lerp(_dim, _bright, t)!;""",
"""          final breath = Color.lerp(dim, bright, t)!;"""),
    (P,
"""                  color: const Color(0xFF7FB8F0).withOpacity(0.25 * t * f),""",
"""                  color: glow.withOpacity(0.25 * t * f),"""),

    # ── 가사 화면: 워터마크를 숨쉬는 글씨로 ──
    (L,
"""  Widget _watermark(BuildContext context, {double scale = 1}) {
    final c = _ink.withOpacity(_light ? 0.72 : 0.88); // 더 잘 보이게
    final shadow = _light ? const <Shadow>[] : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)];
    // 영어 이름은 앱 전체 Quicksand로 통일 (바로 세움)
    return Text(
      'Paransori',
      style: GoogleFonts.quicksand(
          color: c,
          fontSize: 16 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8 * scale,
          shadows: shadow),
    );
  }""",
"""  Widget _watermark(BuildContext context, {double scale = 1, bool moving = false}) {
    final c = _ink.withOpacity(_light ? 0.72 : 0.88); // 더 잘 보이게
    final shadow = _light ? const <Shadow>[] : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)];
    // 영어 이름은 앱 전체 Quicksand로 통일 (바로 세움)
    final style = GoogleFonts.quicksand(
        color: c,
        fontSize: 16 * scale,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8 * scale,
        shadows: shadow);
    // "Paran"만 숨쉬기 (재생 중일 때만) — 재생화면처럼 포인트 색 따라가기
    final point = context.watch<ThemeProvider>().primaryColor;
    final Color accent;
    if (point.value == 0xFF2589E8) {
      accent = _light ? const Color(0xFF2589E8) : const Color(0xFF7FB8F0); // 기본: 지금 하늘색
    } else if (point.computeLuminance() < 0.08) {
      accent = _light ? point : Colors.white; // 먹색 같은 아주 어두운 색
    } else {
      accent = _light ? point : Color.lerp(point, Colors.white, 0.35)!;
    }
    return _ParanBreath(style: style, accent: accent, moving: moving);
  }"""),
    (L,
"""                          child: Opacity(opacity: 0.85, child: _watermark(context, scale: 0.78)),""",
"""                          child: Opacity(
                              opacity: 0.85,
                              child: _watermark(context, scale: 0.78, moving: playerProvider.isPlaying)),"""),
]

# 가사 화면 맨 아래에 붙일 숨쉬는 글씨
L_APPEND_MARK = "class _ParanBreath extends StatefulWidget"
L_APPEND = """

/// "Paransori" 중 "Paran"만 숨쉬듯 천천히 색이 바뀌는 글씨 (재생 중일 때만)
class _ParanBreath extends StatefulWidget {
  final TextStyle style;
  final Color accent;
  final bool moving;
  const _ParanBreath({required this.style, required this.accent, required this.moving});

  @override
  State<_ParanBreath> createState() => _ParanBreathState();
}

class _ParanBreathState extends State<_ParanBreath> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600), // 재생화면과 같은 빠르기
  );

  @override
  void initState() {
    super.initState();
    if (widget.moving) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ParanBreath old) {
    super.didUpdateWidget(old);
    if (widget.moving && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.moving && old.moving) {
      // 멈추면 원래 색으로 부드럽게
      _c.animateTo(0, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        final base = widget.style.color ?? Colors.white;
        return Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Paran', style: TextStyle(color: Color.lerp(base, widget.accent, t))),
            const TextSpan(text: 'sori'),
          ]),
          style: widget.style,
        );
      },
    );
  }
}
"""

texts, crlf = {}, {}
ok, done = True, 0
for path, old, new in EDITS:
    name = os.path.basename(path)
    if path not in texts:
        if not os.path.exists(path):
            print(f"❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)")
            ok = False
            texts[path] = None
            continue
        raw = open(path, "rb").read().decode("utf-8")
        crlf[path] = "\r\n" in raw
        texts[path] = raw.replace("\r\n", "\n")
    t = texts[path]
    if t is None:
        continue
    c = t.count(old)
    if c == 1:
        texts[path] = t.replace(old, new)
        print(f"✔ {name}")
        done += 1
    elif c == 0 and new in t:
        print(f"✔ {name} - 이미 적용돼 있어요")
    else:
        print(f"❌ {name} - 고칠 곳을 못 찾았어요 ({c}곳)")
        ok = False

if ok and texts.get(L) is not None:
    if L_APPEND_MARK in texts[L]:
        print("✔ lyrics_screen.dart (숨쉬는 글씨) - 이미 적용돼 있어요")
    else:
        texts[L] = texts[L].rstrip("\n") + "\n" + L_APPEND
        print("✔ lyrics_screen.dart (숨쉬는 글씨 추가)")
        done += 1

if not ok:
    print("\n❌ 문제가 있어서 아무것도 저장하지 않았어요")
    sys.exit(1)
if done == 0:
    print("\n이미 적용돼 있어요")
    sys.exit(0)
for path, t in texts.items():
    out = t.replace("\n", "\r\n") if crlf[path] else t
    open(path, "wb").write(out.encode("utf-8"))
print(f"\n✔ 모두 저장했어요 ({done}곳)")
