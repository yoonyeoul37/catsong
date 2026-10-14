# 오늘 밤 고칠 것 한 번에
#  1) 음악 재생화면 · 가사 화면 왼쪽 위 화살표 → 집 아이콘 (누르면 홈으로)
#  2) 미니플레이어(음악 · 라디오) 높이 80 → 72 로 살짝 낮게
#  3) 미니플레이어 제목이 길면 좌우로 천천히 흐르게 (짧으면 그대로)
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


def read(p):
    raw = open(p, "rb").read().decode("utf-8")
    return raw.replace("\r\n", "\n"), "\r\n" in raw


F = {n: one(n) for n in ("player_screen.dart", "lyrics_screen.dart", "mini_player.dart", "radio_mini_player.dart")}
S = {n: read(p) for n, p in F.items()}
src = {n: v[0] for n, v in S.items()}

if "class _MiniTitle" in src["mini_player.dart"]:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True


def rep(n, old, new, what):
    global ok
    if src[n].count(old) != 1:
        print(f"❌ {n}: {what} (찾을 코드 {src[n].count(old)}곳)")
        ok = False
        return
    src[n] = src[n].replace(old, new)
    print(f"✔ {n}: {what}")


# ── 1) 집 아이콘 ──
rep("player_screen.dart", """          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: baseColor, size: 18),
          ),
""", """          IconButton(
            // 집 아이콘: 누르면 홈으로 (중간 화면 다 닫고 맨 처음 화면으로)
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.home_rounded, color: baseColor, size: 24),
          ),
""", "왼쪽 위 화살표 → 집 아이콘 (홈으로)")

rep("lyrics_screen.dart", """          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _ink, size: 30),
          ),
""", """          // 집 아이콘: 누르면 홈으로 (재생화면도 같이 닫고 맨 처음 화면으로)
          leading: IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: Icon(Icons.home_rounded, color: _ink, size: 24),
          ),
""", "왼쪽 위 화살표 → 집 아이콘 (홈으로)")

# ── 2) 높이 80 → 72 ──
for n in ("mini_player.dart", "radio_mini_player.dart"):
    rep(n, """          child: Container(
            height: 80,
""", """          child: Container(
            height: 72, // 살짝 낮게 (예전 80)
""", "높이 80 → 72")

# ── 3) 긴 제목 흐르게 ──
MINI_TITLE = '''

/// 제목이 칸보다 길면 좌우로 천천히 흐르게 (짧으면 그냥 글자)
class _MiniTitle extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _MiniTitle(this.text, this.style);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (tp.width <= c.maxWidth) {
        return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      }
      return SizedBox(
        width: c.maxWidth,
        height: tp.height,
        child: Marquee(
          key: ValueKey(text), // 곡이 바뀌면 처음부터
          text: text,
          style: style,
          velocity: 28, // 천천히
          blankSpace: 48,
          startAfter: const Duration(seconds: 2), // 2초 보여 주고 출발
          pauseAfterRound: const Duration(seconds: 2), // 한 바퀴 돌면 2초 쉬기
          fadingEdgeStartFraction: 0.06,
          fadingEdgeEndFraction: 0.06,
          showFadingOnlyWhenScrolling: true,
        ),
      );
    });
  }
}
'''

rep("mini_player.dart", "import 'package:flutter/material.dart';\n",
    "import 'package:flutter/material.dart';\nimport 'package:marquee/marquee.dart';\n", "흐르는 글자 불러오기")
rep("mini_player.dart", """                              Text(
                                song.titleDisplay,
                                style: TextStyle(
                                    color: baseColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
""", """                              // 제목이 길면 좌우로 흐르게
                              _MiniTitle(
                                song.titleDisplay,
                                const TextStyle(
                                    color: baseColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
""", "긴 제목 흐르게")
src["mini_player.dart"] = src["mini_player.dart"].rstrip("\n") + MINI_TITLE
print("✔ mini_player.dart: 흐르는 제목 만들기")

rep("radio_mini_player.dart", "import 'package:flutter/material.dart';\n",
    "import 'package:flutter/material.dart';\nimport 'package:marquee/marquee.dart';\n", "흐르는 글자 불러오기")
rep("radio_mini_player.dart", """                              Text(
                                station.name,
                                style: TextStyle(
                                  color: baseColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
""", """                              // 방송 이름이 길면 좌우로 흐르게
                              _MiniTitle(
                                station.name,
                                const TextStyle(
                                  color: baseColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
""", "긴 방송 이름 흐르게")
src["radio_mini_player.dart"] = src["radio_mini_player.dart"].rstrip("\n") + MINI_TITLE
print("✔ radio_mini_player.dart: 흐르는 제목 만들기")

for n, s in src.items():
    for x, y in (("{", "}"), ("(", ")"), ("[", "]")):
        if s.count(x) != s.count(y):
            print(f"❌ {n}: 괄호 {x}{y} 짝이 안 맞아요")
            ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)
for n, p in F.items():
    s = src[n]
    if S[n][1]:
        s = s.replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
