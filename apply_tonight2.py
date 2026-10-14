# 오늘 밤 고칠 것 2
#  1) 집 아이콘을 누르면 곡 목록이 아니라 메인 홈(음악·라디오·자연·수면 화면)으로
#  2) 음악 미니플레이어: 총 시간(0:00 / 3:45)이 잘리지 않게
#  3) 라디오 미니플레이어: ⏮ 이전 · ⏭ 다음 방송 버튼 넣기 (음악 미니플레이어와 같은 모양)
#  (먼저 apply_tonight.py 를 실행했어야 해요)
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


NAMES = ("home_screen.dart", "player_screen.dart", "lyrics_screen.dart", "mini_player.dart", "radio_mini_player.dart")
F = {n: one(n) for n in NAMES}
S = {n: read(p) for n, p in F.items()}
src = {n: v[0] for n, v in S.items()}

if "goHome" in src["home_screen.dart"]:
    print("이미 적용돼 있어요")
    sys.exit(0)
if "class _MiniTitle" not in src["mini_player.dart"]:
    print("❌ 먼저 apply_tonight.py 를 실행해 주세요")
    sys.exit(1)

ok = True


def rep(n, old, new, what):
    global ok
    if src[n].count(old) != 1:
        print(f"❌ {n}: {what} (찾을 코드 {src[n].count(old)}곳)")
        ok = False
        return
    src[n] = src[n].replace(old, new)
    print(f"✔ {n}: {what}")


# ── 1) 메인 홈으로 ──
rep("home_screen.dart", """class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
""", """class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// 재생화면·가사 화면의 집 아이콘: 값을 바꾸면 메인 홈(음악·라디오·자연·수면)으로
  static final ValueNotifier<int> goHome = ValueNotifier(0);
""", "메인 홈으로 가는 신호 만들기")

rep("home_screen.dart", """    WidgetGo.target.addListener(_onWidgetGo); // 앱이 켜져 있을 때 위젯 바로가기
""", """    WidgetGo.target.addListener(_onWidgetGo); // 앱이 켜져 있을 때 위젯 바로가기
    HomeScreen.goHome.addListener(_onGoHome); // 집 아이콘 → 메인 홈
""", "신호 듣기")

rep("home_screen.dart", """    WidgetGo.target.removeListener(_onWidgetGo);
""", """    WidgetGo.target.removeListener(_onWidgetGo);
    HomeScreen.goHome.removeListener(_onGoHome);
""", "신호 정리")

rep("home_screen.dart", """  void _onWidgetGo() {
""", """  /// 집 아이콘: 곡 목록·즐겨찾기·최근·검색을 다 닫고 메인 홈 화면으로
  void _onGoHome() {
    if (!mounted) return;
    if (_isSearching) {
      _searchController.clear();
      context.read<MusicProvider>().clearSearch();
    }
    setState(() {
      _isSearching = false;
      _showMusicLibrary = false;
      _showFavorites = false;
      _showRecent = false;
      _showCalls = false;
      _currentTabIndex = 0;
    });
  }

  void _onWidgetGo() {
""", "메인 홈으로 바꾸는 코드")

for n, ic in (("player_screen.dart", "            icon: const Icon(Icons.home_rounded, color: baseColor, size: 24),\n"),
              ("lyrics_screen.dart", "            icon: Icon(Icons.home_rounded, color: _ink, size: 24),\n")):
    rep(n, """              Navigator.of(context).popUntil((r) => r.isFirst);
            },
""" + ic, """              Navigator.of(context).popUntil((r) => r.isFirst);
              HomeScreen.goHome.value++; // 곡 목록이 아니라 메인 홈으로
            },
""" + ic, "집 아이콘 → 메인 홈")
    rep(n, "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'home_screen.dart';\n", "홈 화면 불러오기")

# ── 2) 총 시간 안 잘리게 ──
rep("mini_player.dart", """                                  // 녹음처럼 버튼이 많거나 작은 폰에서도 넘치지 않게
                                  Flexible(
                                    child: Text(
                                      '${playerProvider.formatDuration(playerProvider.position)} / ${playerProvider.formatDuration(playerProvider.duration)}',
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                          color: baseColor.withOpacity(0.38),
                                          fontSize: 11),
                                    ),
                                  ),
""", """                                  // 시간은 늘 다 보이게 (좁으면 가수 이름이 줄어듦)
                                  Text(
                                    '${playerProvider.formatDuration(playerProvider.position)} / ${playerProvider.formatDuration(playerProvider.duration)}',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                        color: baseColor.withOpacity(0.38),
                                        fontSize: 11),
                                  ),
""", "총 시간이 잘리지 않게")

# ── 3) 라디오 ⏮ ⏭ ──
rep("radio_mini_player.dart", """    const baseColor = Color(0xFFF4EFE5);
    const ink = Color(0xFF17140F);

    return GestureDetector(""", """    const baseColor = Color(0xFFF4EFE5);
    const ink = Color(0xFF17140F);

    // ⏮ ⏭ : 지금 목록에서 이전·다음 방송 (끝이면 처음으로)
    void step(int d) {
      final queue = radioProvider.currentQueue;
      if (queue.isEmpty) return;
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      final idx = radioProvider.currentQueueIndex;
      final n = (idx + d) % queue.length;
      final newIdx = n < 0 ? n + queue.length : n;
      radioProvider.setQueue(queue, newIdx);
      radioProvider.playStation(queue[newIdx]);
    }
    final canStep = radioProvider.currentQueue.length > 1;

    return GestureDetector(""", "이전·다음 코드")

rep("radio_mini_player.dart", """                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            radioProvider.togglePlayPause();
                          },""", """                        // 이전 방송 (음악 미니플레이어와 같은 모양)
                        if (canStep)
                          IconButton(
                            onPressed: () => step(-1),
                            icon: Icon(Icons.skip_previous, color: baseColor.withOpacity(0.7)),
                            iconSize: 26,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            radioProvider.togglePlayPause();
                          },""", "⏮ 이전 버튼")

rep("radio_mini_player.dart", """                        // × (닫기): 재생 중에도 누르면 바로 멈추고 닫힘
                        IconButton(
                          onPressed: () => _close(context),""", """                        // 다음 방송
                        if (canStep)
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
