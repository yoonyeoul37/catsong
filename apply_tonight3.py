# 자연소리 · 소리 믹스 미니플레이어도 음악·라디오와 똑같이
#  - 높이 80 → 72
#  - 자연소리: ⏮ 이전 · ⏭ 다음 자연소리 버튼 + 이름이 길면 좌우로 흐르게
#  - 소리 믹스: 아래 줄(섞은 소리 이름들)이 길면 좌우로 흐르게 (믹스는 이전·다음이 없어서 버튼은 안 넣음)
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


NAMES = ("nature_mini_player.dart", "sound_mix_mini_player.dart")
F = {n: one(n) for n in NAMES}
S = {n: read(p) for n, p in F.items()}
src = {n: v[0] for n, v in S.items()}

if "class _MiniTitle" in src["nature_mini_player.dart"]:
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


MINI_TITLE = '''

/// 글자가 칸보다 길면 좌우로 천천히 흐르게 (짧으면 그냥 글자) — 음악·라디오 미니플레이어와 같음
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
          key: ValueKey(text),
          text: text,
          style: style,
          velocity: 28,
          blankSpace: 48,
          startAfter: const Duration(seconds: 2),
          pauseAfterRound: const Duration(seconds: 2),
          fadingEdgeStartFraction: 0.06,
          fadingEdgeEndFraction: 0.06,
          showFadingOnlyWhenScrolling: true,
        ),
      );
    });
  }
}
'''

for n in NAMES:
    rep(n, """          child: Container(
            height: 80,
""", """          child: Container(
            height: 72, // 음악·라디오 미니플레이어와 같은 높이 (예전 80)
""", "높이 80 → 72")
    rep(n, "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:marquee/marquee.dart';\n", "흐르는 글자 불러오기")
    src[n] = src[n].rstrip("\n") + MINI_TITLE
    print(f"✔ {n}: 흐르는 글자 만들기")

# ── 자연소리 ──
rep("nature_mini_player.dart", """    final icon = (meta?['icon'] as IconData?) ?? Icons.eco_rounded;

    return GestureDetector(""", """    final icon = (meta?['icon'] as IconData?) ?? Icons.eco_rounded;

    // ⏮ ⏭ : 자연소리 목록에서 이전·다음 (끝이면 처음으로)
    void step(int d) {
      final order = PlayerProvider.natureSoundOrder;
      if (order.isEmpty) return;
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      final i = order.indexWhere((s) => s['name'] == name);
      var n = ((i < 0 ? 0 : i) + d) % order.length;
      if (n < 0) n += order.length;
      final s = order[n];
      context.read<PlayerProvider>().playNatureSound(s['assetPath']!, s['name']!);
    }

    return GestureDetector(""", "이전·다음 코드")

rep("nature_mini_player.dart", """                        Text(isPlaying ? '$name 재생 중' : '$name 일시정지',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
""", """                        // 이름이 길면 좌우로 흐르게
                        _MiniTitle(isPlaying ? '$name 재생 중' : '$name 일시정지',
                            const TextStyle(
                                color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
""", "긴 이름 흐르게")

rep("nature_mini_player.dart", """                  GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (isPlaying) {""", """                  // 이전 자연소리 (음악 미니플레이어와 같은 모양)
                  IconButton(
                    onPressed: () => step(-1),
                    icon: Icon(Icons.skip_previous, color: baseColor.withOpacity(0.7)),
                    iconSize: 26,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (isPlaying) {""", "⏮ 이전 버튼")

rep("nature_mini_player.dart", """                  // × (닫기): 재생 중에도 누르면 바로 멈추고 닫힘
                  IconButton(
                    onPressed: () => _close(context),""", """                  // 다음 자연소리
                  IconButton(
                    onPressed: () => step(1),
                    icon: Icon(Icons.skip_next, color: baseColor.withOpacity(0.7)),
                    iconSize: 26,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  // × (닫기): 재생 중에도 누르면 바로 멈추고 닫힘
                  IconButton(
                    onPressed: () => _close(context),""", "⏭ 다음 버튼")

# ── 소리 믹스 ──
rep("sound_mix_mini_player.dart", """                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12)),
""", """                        // 섞은 소리 이름이 길면 좌우로 흐르게
                        _MiniTitle(subtitle, TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12)),
""", "긴 소리 이름 줄 흐르게")

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
