# 가사 화면 배경에도 색감 넣기: 컬러 · 흑백 · 세피아 · 필름 (음악 재생화면 파란포토와 똑같이)
#  - 가사 배경 창 맨 아래에 색감 줄 (지금 사진으로 작게 미리보기)
#  - 고른 색감은 기억 (lyricsBgTone) · 파란소리 사진 · 내 사진 모두
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")


def one(name):
    hits = []
    for d, dirs, files in os.walk(os.path.join(ROOT, "lib")):
        dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
        if name in files:
            hits.append(os.path.normpath(os.path.join(d, name)))
    if len(hits) != 1:
        print(f"❌ {name} 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요'}")
        sys.exit(1)
    return hits[0]


p = one("lyrics_screen.dart")
raw = open(p, "rb").read().decode("utf-8")
crlf = "\r\n" in raw
s = raw.replace("\r\n", "\n")

if "lyricsBgTone" in s:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True


def rep(old, new, what):
    global s, ok
    if s.count(old) != 1:
        print(f"❌ {what} (찾을 코드 {s.count(old)}곳)")
        ok = False
        return
    s = s.replace(old, new)
    print(f"✔ {what}")


# 1. 색감 기억 칸
rep("""  static bool _myLight = false; // 내 사진이 밝은지 (밝으면 먹색 글자, 어두우면 흰 글자)
""", """  static bool _myLight = false; // 내 사진이 밝은지 (밝으면 먹색 글자, 어두우면 흰 글자)
  static int _tone = 0; // 배경 색감: 0 컬러 · 1 흑백 · 2 세피아 · 3 필름 (파란포토와 같게)
""", "색감 기억 칸 만들기")

# 2. 켤 때 고른 색감 읽기
rep("""      final s = (p.getInt('lyricsTextSize') ?? 1).clamp(0, 2);
      if (s != _sizeStep && mounted) setState(() => _sizeStep = s);
""", """      final s = (p.getInt('lyricsTextSize') ?? 1).clamp(0, 2);
      if (s != _sizeStep && mounted) setState(() => _sizeStep = s);
      final t = (p.getInt('lyricsBgTone') ?? 0).clamp(0, 3);
      if (t != _tone && mounted) setState(() => _tone = t);
""", "켤 때 고른 색감 읽기")

# 3. 배경 사진에 색감 입히기
rep("""            if (_myBg != null)
              // 내 사진 배경 (화면 크기만큼만 풀기)
              RepaintBoundary(
                child: Image.file(File(_myBg!),
                    fit: BoxFit.cover,
                    cacheWidth: 1080,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF14110C))),
              )
            else if (_bg != 0)
              // 배경 사진은 한 번만 그리고 고정 (가사가 바뀔 때마다 다시 안 그리게)
              RepaintBoundary(
                child: CachedNetworkImage(
                  imageUrl: _bgUrl(_bg),
                  fit: BoxFit.cover,
                  memCacheWidth: 1080, // 화면 크기만큼만
                  useOldImageOnUrlChange: true,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (_, __) => Container(color: const Color(0xFF14110C)),
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF14110C)),
                ),
              ),
""", """            if (_myBg != null)
              // 내 사진 배경 (화면 크기만큼만 풀기) + 고른 색감
              RepaintBoundary(
                child: _toned(Image.file(File(_myBg!),
                    fit: BoxFit.cover,
                    cacheWidth: 1080,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF14110C)))),
              )
            else if (_bg != 0)
              // 배경 사진은 한 번만 그리고 고정 (가사가 바뀔 때마다 다시 안 그리게) + 고른 색감
              RepaintBoundary(
                child: _toned(CachedNetworkImage(
                  imageUrl: _bgUrl(_bg),
                  fit: BoxFit.cover,
                  memCacheWidth: 1080, // 화면 크기만큼만
                  useOldImageOnUrlChange: true,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (_, __) => Container(color: const Color(0xFF14110C)),
                  errorWidget: (_, __, ___) => Container(color: const Color(0xFF14110C)),
                )),
              ),
""", "배경 사진에 색감 입히기")

# 4. 가사 배경 창 아래에 색감 줄 + 색감 그리는 코드
rep("""      },
    );
  }

  // 오른쪽 위 버튼 묶음: 자주 쓰는 것만 밖에, 나머지는 ⋮ 안으로 (유리 알약 하나에)
""", """      },
      // 색감: 아래에 고정 (사진을 밀어도 늘 보이게 — 파란포토 창과 같게)
      footer: (ctx, setSheet) => _toneBar(setSheet),
    );
  }

  /// 색감 고르기 (파란포토 창과 같은 모양): 지금 배경을 컬러 · 흑백 · 세피아 · 필름으로 작게 미리보기
  Widget _toneBar(StateSetter setSheet) {
    final dark = context.read<ThemeProvider>().isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    Widget photo() => _myBg != null
        ? Image.file(File(_myBg!),
            fit: BoxFit.cover,
            cacheWidth: 200,
            errorBuilder: (_, __, ___) => Container(color: const Color(0x22000000)))
        : _bg != 0
            ? CachedNetworkImage(
                imageUrl: _bgUrl(_bg),
                fit: BoxFit.cover,
                memCacheWidth: 200,
                placeholder: (_, __) => Container(color: const Color(0x22000000)),
                errorWidget: (_, __, ___) => Container(color: const Color(0x22000000)),
              )
            : Container(color: AppTheme.background);
    return Row(
      children: [
        for (final t in const [(0, '컬러'), (1, '흑백'), (2, '세피아'), (3, '필름')]) ...[
          if (t.$1 > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                setState(() => _tone = t.$1);
                setSheet(() {});
                SharedPreferences.getInstance().then((p) => p.setInt('lyricsBgTone', t.$1));
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 46,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _tone == t.$1 ? ink : Colors.transparent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox.expand(child: _toned(photo(), t.$1)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(t.$2,
                      style: TextStyle(
                          color: _tone == t.$1 ? ink : sub,
                          fontSize: 11.5,
                          fontWeight: _tone == t.$1 ? FontWeight.w800 : FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 배경에 색감 입히기 (only: 미리보기용) — 파란포토와 같은 값
  Widget _toned(Widget child, [int? only]) {
    final f = only ?? _tone;
    if (f == 1) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }
    if (f == 2) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }
    if (f == 3) {
      // 필름: 바랜 따뜻한 색 + 가장자리 어둡게 + 필름 입자
      return Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.7016, 0.1803, 0.0182, 0, 19,
              0.0524, 0.8099, 0.0178, 0, 17,
              0.0464, 0.1562, 0.5774, 0, 19,
              0, 0, 0, 1, 0,
            ]),
            child: child,
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.0,
                  colors: [Colors.transparent, Color(0x73000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _LyricsGrainPainter()),
            ),
          ),
        ],
      );
    }
    return child;
  }

  // 오른쪽 위 버튼 묶음: 자주 쓰는 것만 밖에, 나머지는 ⋮ 안으로 (유리 알약 하나에)
""", "가사 배경 창에 색감 줄 넣기")

# 5. 필름 입자 (파란포토와 같은 무늬)
s = s.rstrip("\n") + """

/// 필름 입자: 화면 위에 아주 옅은 점들을 한 번만 그림 (파란포토 필름과 같은 무늬)
class _LyricsGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final count = (size.width * size.height / 160).round();
    final light = Paint();
    final dark = Paint();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = 0.04 + rnd.nextDouble() * 0.07;
      final p = rnd.nextBool()
          ? (light..color = Colors.white.withOpacity(a))
          : (dark..color = Colors.black.withOpacity(a));
      canvas.drawRect(Rect.fromLTWH(x, y, 1.3, 1.3), p);
    }
  }

  @override
  bool shouldRepaint(_LyricsGrainPainter old) => false;
}
"""
print("✔ 필름 입자 그리기 넣기")

if "import 'dart:math' as math;" not in s:
    print("❌ dart:math 를 안 불러와요")
    ok = False
for nm, x, y in (("{}", "{", "}"), ("()", "(", ")"), ("[]", "[", "]")):
    if s.count(x) != s.count(y):
        print(f"❌ 괄호 {nm} 짝이 안 맞아요")
        ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)
if crlf:
    s = s.replace("\n", "\r\n")
open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
