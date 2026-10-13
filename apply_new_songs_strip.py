# 새로 들어온 곡: 위 카드(오늘의 카드)는 그대로 + 바로 아래 한 줄 띠 (1번 시안)
#  - 띠: 사진 3장 겹쳐서 · "새로 들어온 곡 3" · 곡 이름 · ▶ 바로 재생 · 띠 누르면 새 곡 목록
#  - 곡 목록: 새 곡 제목 옆 작은 점
#  - apply_new_songs.py 를 이미 실행했어도, 안 했어도 이것 하나만 실행하면 됨
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


mp, tile, home = one("music_provider.dart"), one("song_list_tile.dart"), one("home_screen.dart")
mp_s, mp_c = read(mp)
tl_s, tl_c = read(tile)
hm_s, hm_c = read(home)

if "_buildNewSongsStrip" in hm_s:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True


def rep(src, old, new, what):
    """new 가 이미 들어 있으면 건너뜀 (apply_new_songs.py 를 먼저 실행한 경우)"""
    global ok
    if new in src:
        print(f"✔ {what} (이미 들어 있음)")
        return src
    if src.count(old) != 1:
        print(f"❌ {what} (찾을 코드 {src.count(old)}곳)")
        ok = False
        return src
    print(f"✔ {what}")
    return src.replace(old, new)


mp_s = rep(mp_s, '  List<String> _recentSongUris = [];\n', "  // ───── 새로 들어온 곡 ─────\n  // 곡 경로 → 앱이 처음 본 시각(ms). 0 = 이 기능이 생기기 전부터 있던 곡 (새 곡 아님)\n  Map<String, int> _firstSeen = {};\n  bool _seenLoaded = false;\n\n  Future<void> _updateFirstSeen(List<Song> found) async {\n    final prefs = await SharedPreferences.getInstance();\n    final first = !prefs.containsKey('song_first_seen'); // 처음이면 지금 있는 곡은 전부 '예전 곡'\n    if (!_seenLoaded) {\n      try {\n        final raw = prefs.getString('song_first_seen');\n        if (raw != null) {\n          final Map decoded = jsonDecode(raw);\n          _firstSeen = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));\n        }\n      } catch (_) {}\n      _seenLoaded = true;\n    }\n    final now = DateTime.now().millisecondsSinceEpoch;\n    for (final s in found) {\n      final u = s.uri;\n      if (u != null) _firstSeen.putIfAbsent(u, () => first ? 0 : now);\n    }\n    // (지운 곡도 기억은 남겨 둠 → 폴더가 잠깐 안 보였다 다시 보여도 새 곡으로 안 뜸)\n    await prefs.setString('song_first_seen', jsonEncode(_firstSeen));\n  }\n\n  /// 새로 들어온 곡인지: 처음 본 지 7일 안 + 그 뒤로 30초 이상 안 들음\n  bool isNewSong(Song s) {\n    final u = s.uri;\n    if (u == null) return false;\n    final seen = _firstSeen[u] ?? 0;\n    if (seen <= 0) return false;\n    if (DateTime.now().millisecondsSinceEpoch - seen > const Duration(days: 7).inMilliseconds) return false;\n    return (_lastPlayed[u] ?? 0) < seen;\n  }\n\n  /// 새로 들어온 곡 (최근 들어온 순, 최대 10곡, 녹음 빼고)\n  List<Song> get newSongs {\n    final out = _songs.where((s) => !isCallRecordingPath(s.uri) && isNewSong(s)).toList()\n      ..sort((a, b) => (_firstSeen[b.uri] ?? 0).compareTo(_firstSeen[a.uri] ?? 0));\n    return out.length > 10 ? out.sublist(0, 10) : out;\n  }\n\n  List<String> _recentSongUris = [];\n", 'music_provider.dart: 새 곡 기억·판단')
mp_s = rep(mp_s, '      await _loadRecentSongs();\n      _isLoading = false;\n', '      if (foundSongs.isNotEmpty) await _updateFirstSeen(foundSongs); // 새로 들어온 곡 찾기\n      await _loadRecentSongs();\n      _isLoading = false;\n', 'music_provider.dart: 곡을 찾을 때마다 새 곡 확인')
tl_s = rep(tl_s, '    final trimmed = context.select<MusicProvider, bool>((m) => m.isTrimmedWithOriginal(song));\n', '    final trimmed = context.select<MusicProvider, bool>((m) => m.isTrimmedWithOriginal(song));\n    final isNew = context.select<MusicProvider, bool>((m) => m.isNewSong(song)); // 새로 들어온 곡\n', 'song_list_tile.dart: 새 곡인지 보기')
tl_s = rep(tl_s, '                  hlText(\n                    song.titleDisplay,\n                    highlight,\n                    TextStyle(\n                      color: isCurrentSong ? primaryColor : baseColor,\n                      fontSize: 15,\n                      fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,\n                    ),\n                    primaryColor,\n                  ),\n', '                  Row(\n                    children: [\n                      Flexible(\n                        child: hlText(\n                          song.titleDisplay,\n                          highlight,\n                          TextStyle(\n                            color: isCurrentSong ? primaryColor : baseColor,\n                            fontSize: 15,\n                            fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,\n                          ),\n                          primaryColor,\n                        ),\n                      ),\n                      // 새로 들어온 곡: 제목 옆 작은 점 (한 번 듣거나 7일 지나면 사라짐)\n                      if (isNew) ...[\n                        const SizedBox(width: 6),\n                        Container(\n                          width: 7,\n                          height: 7,\n                          decoration: BoxDecoration(\n                            color: pointColorOf(context, onDark: isDarkMode),\n                            shape: BoxShape.circle,\n                          ),\n                        ),\n                      ],\n                    ],\n                  ),\n', 'song_list_tile.dart: 제목 옆 점')
hm_s = rep(hm_s, "import '../utils/no_album_helper.dart';\n", "import '../utils/no_album_helper.dart';\nimport '../utils/point_color.dart';\n", 'home_screen.dart: 포인트 색 불러오기')

OLD_PLACE = '            // 새로 들어온 곡이 있으면 그 줄 (오늘의 카드 자리), 없으면 원래대로\n            if (!_showFavorites && !_showRecent && !_isSelectionMode && !_isSearching &&\n                musicProvider.newSongs.isNotEmpty)\n              _buildNewSongsRow(musicProvider, isDarkMode)\n            else\n              _buildTopCard(musicProvider, isDarkMode), // 정리할 곡 있으면 정리 카드, 없으면 오늘의 카드\n'
ORIG_PLACE = '            _buildTopCard(musicProvider, isDarkMode), // 정리할 곡 있으면 정리 카드, 없으면 오늘의 카드\n'
NEW_PLACE = '            _buildTopCard(musicProvider, isDarkMode), // 정리할 곡 있으면 정리 카드, 없으면 오늘의 카드\n            // 새로 들어온 곡: 위 카드 바로 아래 한 줄 띠 (위 카드는 그대로)\n            if (!_showFavorites && !_showRecent && !_isSelectionMode && !_isSearching &&\n                musicProvider.newSongs.isNotEmpty)\n              _buildNewSongsStrip(musicProvider, isDarkMode),\n'
OLD_METHOD = "  /// 새로 들어온 곡: 가로 카드 (사진 모서리에 포인트 색 점) · 누르면 그 곡부터 새 곡끼리 이어서\n  Widget _buildNewSongsRow(MusicProvider music, bool isDark) {\n    final list = music.newSongs;\n    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);\n    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFEDE7DA); // 점 테두리 = 바탕색\n    final point = pointColorOf(context);\n    void play(int i) {\n      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n      context.read<PlayerProvider>().playFromList(list, i);\n    }\n\n    return Padding(\n      padding: const EdgeInsets.only(top: 12),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Padding(\n            padding: const EdgeInsets.fromLTRB(16, 0, 10, 6),\n            child: Row(\n              children: [\n                Text('새로 들어온 곡',\n                    style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                const SizedBox(width: 5),\n                Text('${list.length}',\n                    style: TextStyle(color: point, fontSize: 15, fontWeight: FontWeight.w800)),\n                const Spacer(),\n                GestureDetector(\n                  behavior: HitTestBehavior.opaque,\n                  onTap: () => play(0),\n                  child: Padding(\n                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),\n                    child: Row(\n                      mainAxisSize: MainAxisSize.min,\n                      children: [\n                        Text('모두 재생', style: TextStyle(color: sub, fontSize: 12.5)),\n                        Icon(Icons.play_arrow_rounded, size: 18, color: sub),\n                      ],\n                    ),\n                  ),\n                ),\n              ],\n            ),\n          ),\n          SizedBox(\n            height: 156,\n            child: ListView.separated(\n              scrollDirection: Axis.horizontal,\n              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), // 위 4: 모서리 점이 안 잘리게\n              itemCount: list.length,\n              separatorBuilder: (_, __) => const SizedBox(width: 12),\n              itemBuilder: (context, i) {\n                final s = list[i];\n                return GestureDetector(\n                  onTap: () => play(i),\n                  child: SizedBox(\n                    width: 92,\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        Stack(\n                          clipBehavior: Clip.none,\n                          children: [\n                            _cardArt(s, 92, isDark),\n                            Positioned(\n                              right: -3,\n                              top: -3,\n                              child: Container(\n                                width: 13,\n                                height: 13,\n                                decoration: BoxDecoration(\n                                  color: point,\n                                  shape: BoxShape.circle,\n                                  border: Border.all(color: bg, width: 2.5),\n                                ),\n                              ),\n                            ),\n                          ],\n                        ),\n                        const SizedBox(height: 6),\n                        Text(s.titleDisplay,\n                            maxLines: 1,\n                            overflow: TextOverflow.ellipsis,\n                            style: TextStyle(color: ink, fontSize: 12.5)),\n                        Text(s.artistDisplay,\n                            maxLines: 1,\n                            overflow: TextOverflow.ellipsis,\n                            style: TextStyle(color: sub, fontSize: 10.5)),\n                      ],\n                    ),\n                  ),\n                );\n              },\n            ),\n          ),\n          Container(height: 1, margin: const EdgeInsets.fromLTRB(16, 2, 16, 0), color: ink.withOpacity(0.06)),\n        ],\n      ),\n    );\n  }\n\n"
ANCHOR = '  /// 오늘의 카드 왼쪽: 곡 앨범 사진 (없으면 글자 타일)\n'
STRIP = "  /// 새로 들어온 곡 한 줄 띠: 사진 3장 겹쳐서 + 이름 · ▶ 바로 재생 · 띠 누르면 새 곡 목록\n  Widget _buildNewSongsStrip(MusicProvider music, bool isDark) {\n    final list = music.newSongs;\n    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);\n    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n    final card = isDark ? const Color(0xFF32302C) : Colors.white;\n    final point = pointColorOf(context);\n    void play(int i) {\n      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n      context.read<PlayerProvider>().playFromList(list, i);\n    }\n\n    // 작은 사진 (띠 색 테두리 → 겹쳐도 또렷하게)\n    Widget thumb(Song s) => Container(\n          width: 32,\n          height: 32,\n          decoration: BoxDecoration(\n            borderRadius: BorderRadius.circular(8),\n            border: Border.all(color: card, width: 2),\n          ),\n          child: ClipRRect(\n            borderRadius: BorderRadius.circular(6),\n            child: s.albumArt != null\n                ? Image.memory(Uint8List.fromList(s.albumArt!),\n                    width: 28, height: 28, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: 84)\n                : NoArtTile(title: s.titleDisplay, colorKey: s.uri ?? s.titleDisplay, size: 28, isDark: isDark),\n          ),\n        );\n    final shown = list.take(3).toList();\n\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),\n      child: Material(\n        color: card,\n        borderRadius: BorderRadius.circular(14),\n        child: InkWell(\n          borderRadius: BorderRadius.circular(14),\n          onTap: () => _showNewSongsSheet(list, isDark),\n          child: Padding(\n            padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),\n            child: Row(\n              children: [\n                SizedBox(\n                  width: 32.0 + (shown.length - 1) * 21,\n                  height: 32,\n                  child: Stack(\n                    children: [\n                      for (var i = shown.length - 1; i >= 0; i--)\n                        Positioned(left: i * 21.0, child: thumb(shown[i])),\n                    ],\n                  ),\n                ),\n                const SizedBox(width: 10),\n                Expanded(\n                  child: Column(\n                    crossAxisAlignment: CrossAxisAlignment.start,\n                    mainAxisSize: MainAxisSize.min,\n                    children: [\n                      Text.rich(\n                        TextSpan(children: [\n                          const TextSpan(text: '새로 들어온 곡 '),\n                          TextSpan(text: '${list.length}', style: TextStyle(color: point)),\n                        ]),\n                        style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w700),\n                      ),\n                      const SizedBox(height: 1),\n                      Text(list.map((s) => s.titleDisplay).join(' · '),\n                          maxLines: 1,\n                          overflow: TextOverflow.ellipsis,\n                          style: TextStyle(color: sub, fontSize: 11)),\n                    ],\n                  ),\n                ),\n                const SizedBox(width: 8),\n                // ▶ 새 곡 바로 재생\n                GestureDetector(\n                  onTap: () => play(0),\n                  child: Container(\n                    width: 34,\n                    height: 34,\n                    decoration: BoxDecoration(color: ink, shape: BoxShape.circle),\n                    child: Icon(Icons.play_arrow_rounded,\n                        size: 22, color: isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5)),\n                  ),\n                ),\n              ],\n            ),\n          ),\n        ),\n      ),\n    );\n  }\n\n  /// 띠를 누르면: 새로 들어온 곡 목록 (누르면 그 곡부터 새 곡끼리 이어서)\n  void _showNewSongsSheet(List<Song> list, bool isDark) {\n    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);\n    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n    final point = pointColorOf(context);\n    showParanSheet(\n      context,\n      title: '새로 들어온 곡',\n      builder: (ctx, setSheet) => ConstrainedBox(\n        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),\n        child: SingleChildScrollView(\n          child: ParanCard(\n            children: [\n              for (var i = 0; i < list.length; i++)\n                InkWell(\n                  onTap: () {\n                    Navigator.pop(ctx);\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    context.read<PlayerProvider>().playFromList(list, i);\n                  },\n                  child: Padding(\n                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),\n                    child: Row(\n                      children: [\n                        _cardArt(list[i], 40, isDark),\n                        const SizedBox(width: 12),\n                        Expanded(\n                          child: Column(\n                            crossAxisAlignment: CrossAxisAlignment.start,\n                            children: [\n                              Text(list[i].titleDisplay,\n                                  maxLines: 1,\n                                  overflow: TextOverflow.ellipsis,\n                                  style: TextStyle(color: ink, fontSize: 14)),\n                              const SizedBox(height: 2),\n                              Text(list[i].artistDisplay,\n                                  maxLines: 1,\n                                  overflow: TextOverflow.ellipsis,\n                                  style: TextStyle(color: sub, fontSize: 11.5)),\n                            ],\n                          ),\n                        ),\n                        Container(\n                          width: 7,\n                          height: 7,\n                          decoration: BoxDecoration(color: point, shape: BoxShape.circle),\n                        ),\n                      ],\n                    ),\n                  ),\n                ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n\n"

# 자리: 가로 카드판(먼저 실행한 경우)이든 원래 줄이든 → 위 카드 + 띠
if hm_s.count(OLD_PLACE) == 1:
    hm_s = hm_s.replace(OLD_PLACE, NEW_PLACE)
    print("✔ home_screen.dart: 가로 카드 자리 → 위 카드 + 한 줄 띠")
else:
    hm_s = rep(hm_s, ORIG_PLACE, NEW_PLACE, "home_screen.dart: 위 카드 아래 한 줄 띠 자리")

# 가로 카드 코드가 있으면 빼기
if hm_s.count(OLD_METHOD) == 1:
    hm_s = hm_s.replace(OLD_METHOD, "")
    print("✔ home_screen.dart: 가로 카드 코드 뺌")

hm_s = rep(hm_s, ANCHOR, STRIP + ANCHOR, "home_screen.dart: 한 줄 띠 · 새 곡 목록 만들기")

if "import '../utils/point_color.dart';" not in tl_s:
    print("❌ song_list_tile.dart: point_color.dart 를 안 불러와요")
    ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)

for p, s, c in ((mp, mp_s, mp_c), (tile, tl_s, tl_c), (home, hm_s, hm_c)):
    if c:
        s = s.replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
