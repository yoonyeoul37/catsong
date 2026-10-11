# -*- coding: utf-8 -*-
# 첫인사 화면: 사진이 아주 천천히 다가오고, 'Paransori'(홈 로고와 같은 Quicksand)가 위로 떠오르며 나타남
# 지금은 한국어만 글자를 얹음 (다른 언어 사진엔 글자가 이미 들어 있어서)
import sys, glob, os, shutil

NAME = 'main.dart'
hits = [h for h in glob.glob(os.path.join('lib', NAME)) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ lib/{NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'class _IntroView' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('Quicksand 글꼴 불러오기',
"import 'package:cached_network_image/cached_network_image.dart';\n",
"import 'package:cached_network_image/cached_network_image.dart';\nimport 'package:google_fonts/google_fonts.dart';\n"),
('첫인사 화면 → 움직이는 화면으로',
"""          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                introAssetPath(context),
                fit: BoxFit.cover, // 화면 꽉 채우기 (위아래 검은 칸 없애기)
              ),
            ],
          ),""",
"""          body: _IntroView(
            path: introAssetPath(context),
            // 새 사진(글자 없음)은 한국어만 → 'Paransori'를 코드로 얹기
            showTitle: Localizations.localeOf(context).languageCode == 'ko',
          ),"""),
('움직이는 첫인사 화면 만들기',
"class _WavePainter extends CustomPainter {",
"""/// 첫인사 화면: 사진이 아주 천천히 다가오고, 'Paransori'가 아래에서 떠오르며 나타남
class _IntroView extends StatefulWidget {
  final String path;
  final bool showTitle;
  const _IntroView({required this.path, required this.showTitle});

  @override
  State<_IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<_IntroView> with SingleTickerProviderStateMixin {
  // 첫인사가 3초라서 3초 동안 움직임
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 사진: 3초 동안 6%만 살짝 다가오기
    final zoom = Tween(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    // 글자: 0.4초 뒤부터 1.4초 동안 떠오르기 (글자 사이도 천천히 모임)
    final t = CurvedAnimation(parent: _c, curve: const Interval(0.13, 0.6, curve: Curves.easeOutCubic));
    final h = MediaQuery.sizeOf(context).height;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: zoom,
          builder: (_, child) => Transform.scale(scale: zoom.value, child: child),
          child: Image.asset(widget.path, fit: BoxFit.cover), // 화면 꽉 채우기
        ),
        if (widget.showTitle)
          Positioned(
            left: 0,
            right: 0,
            top: h * 0.22, // 파란 하늘 자리
            child: AnimatedBuilder(
              animation: t,
              builder: (_, __) => Opacity(
                opacity: t.value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - t.value)),
                  child: Text(
                    'Paransori',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling, // 글자 크기 설정과 상관없이 고정
                    style: GoogleFonts.quicksand( // 홈 로고와 같은 글꼴
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4 + 6 * (1 - t.value),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')
shutil.copy(path, path + '.bak_intro')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_intro)')
