# 새로 들어온 곡 표시
#  - 음악 목록 위: '새로 들어온 곡' 가로 카드 (사진 모서리에 포인트 색 점) + 모두 재생
#  - 곡 목록: 새 곡 제목 옆에 작은 점
#  - 새 곡 = 앱이 처음 본 지 7일 안 + 그 뒤로 30초 이상 안 들은 곡
#    (이 기능이 처음 들어갈 때 이미 있던 곡은 새 곡 아님)
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

if "isNewSong" in mp_s:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True


def rep(src, old, new, what):
    global ok
    if src.count(old) != 1:
        print(f"❌ {what} (찾을 코드 {src.count(old)}곳)")
        ok = False
        return src
    print(f"✔ {what}")
    return src.replace(old, new)


# ───────── music_provider.dart ─────────
mp_s = rep(mp_s, '''  List<String> _recentSongUris = [];
''', '''  // ───── 새로 들어온 곡 ─────
  // 곡 경로 → 앱이 처음 본 시각(ms). 0 = 이 기능이 생기기 전부터 있던 곡 (새 곡 아님)
  Map<String, int> _firstSeen = {};
  bool _seenLoaded = false;

  Future<void> _updateFirstSeen(List<Song> found) async {
    final prefs = await SharedPreferences.getInstance();
    final first = !prefs.containsKey('song_first_seen'); // 처음이면 지금 있는 곡은 전부 '예전 곡'
    if (!_seenLoaded) {
      try {
        final raw = prefs.getString('song_first_seen');
        if (raw != null) {
          final Map decoded = jsonDecode(raw);
          _firstSeen = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        }
      } catch (_) {}
      _seenLoaded = true;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final s in found) {
      final u = s.uri;
      if (u != null) _firstSeen.putIfAbsent(u, () => first ? 0 : now);
    }
    // (지운 곡도 기억은 남겨 둠 → 폴더가 잠깐 안 보였다 다시 보여도 새 곡으로 안 뜸)
    await prefs.setString('song_first_seen', jsonEncode(_firstSeen));
  }

  /// 새로 들어온 곡인지: 처음 본 지 7일 안 + 그 뒤로 30초 이상 안 들음
  bool isNewSong(Song s) {
    final u = s.uri;
    if (u == null) return false;
    final seen = _firstSeen[u] ?? 0;
    if (seen <= 0) return false;
    if (DateTime.now().millisecondsSinceEpoch - seen > const Duration(days: 7).inMilliseconds) return false;
    return (_lastPlayed[u] ?? 0) < seen;
  }

  /// 새로 들어온 곡 (최근 들어온 순, 최대 10곡, 녹음 빼고)
  List<Song> get newSongs {
    final out = _songs.where((s) => !isCallRecordingPath(s.uri) && isNewSong(s)).toList()
      ..sort((a, b) => (_firstSeen[b.uri] ?? 0).compareTo(_firstSeen[a.uri] ?? 0));
    return out.length > 10 ? out.sublist(0, 10) : out;
  }

  List<String> _recentSongUris = [];
''', "music_provider.dart: 새 곡 기억·판단")

mp_s = rep(mp_s, '''      await _loadRecentSongs();
      _isLoading = false;
''', '''      if (foundSongs.isNotEmpty) await _updateFirstSeen(foundSongs); // 새로 들어온 곡 찾기
      await _loadRecentSongs();
      _isLoading = false;
''', "music_provider.dart: 곡을 찾을 때마다 새 곡 확인")

# ───────── song_list_tile.dart ─────────
tl_s = rep(tl_s, '''    final trimmed = context.select<MusicProvider, bool>((m) => m.isTrimmedWithOriginal(song));
''', '''    final trimmed = context.select<MusicProvider, bool>((m) => m.isTrimmedWithOriginal(song));
    final isNew = context.select<MusicProvider, bool>((m) => m.isNewSong(song)); // 새로 들어온 곡
''', "song_list_tile.dart: 새 곡인지 보기")

tl_s = rep(tl_s, '''                  hlText(
                    song.titleDisplay,
                    highlight,
                    TextStyle(
                      color: isCurrentSong ? primaryColor : baseColor,
                      fontSize: 15,
                      fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                    ),
                    primaryColor,
                  ),
''', '''                  Row(
                    children: [
                      Flexible(
                        child: hlText(
                          song.titleDisplay,
                          highlight,
                          TextStyle(
                            color: isCurrentSong ? primaryColor : baseColor,
                            fontSize: 15,
                            fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                          ),
                          primaryColor,
                        ),
                      ),
                      // 새로 들어온 곡: 제목 옆 작은 점 (한 번 듣거나 7일 지나면 사라짐)
                      if (isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: pointColorOf(context, onDark: isDarkMode),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
''', "song_list_tile.dart: 제목 옆 점")

# ───────── home_screen.dart ─────────
hm_s = rep(hm_s, '''import '../utils/no_album_helper.dart';
''', '''import '../utils/no_album_helper.dart';
import '../utils/point_color.dart';
''', "home_screen.dart: 포인트 색 불러오기")

hm_s = rep(hm_s, '''            _buildTopCard(musicProvider, isDarkMode), // 정리할 곡 있으면 정리 카드, 없으면 오늘의 카드
''', '''            // 새로 들어온 곡이 있으면 그 줄 (오늘의 카드 자리), 없으면 원래대로
            if (!_showFavorites && !_showRecent && !_isSelectionMode && !_isSearching &&
                musicProvider.newSongs.isNotEmpty)
              _buildNewSongsRow(musicProvider, isDarkMode)
            else
              _buildTopCard(musicProvider, isDarkMode), // 정리할 곡 있으면 정리 카드, 없으면 오늘의 카드
''', "home_screen.dart: 새 곡 줄 자리")

hm_s = rep(hm_s, '''  /// 오늘의 카드 왼쪽: 곡 앨범 사진 (없으면 글자 타일)
''', '''  /// 새로 들어온 곡: 가로 카드 (사진 모서리에 포인트 색 점) · 누르면 그 곡부터 새 곡끼리 이어서
  Widget _buildNewSongsRow(MusicProvider music, bool isDark) {
    final list = music.newSongs;
    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFEDE7DA); // 점 테두리 = 바탕색
    final point = pointColorOf(context);
    void play(int i) {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      context.read<PlayerProvider>().playFromList(list, i);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 6),
            child: Row(
              children: [
                Text('새로 들어온 곡',
                    style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(width: 5),
                Text('${list.length}',
                    style: TextStyle(color: point, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => play(0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('모두 재생', style: TextStyle(color: sub, fontSize: 12.5)),
                        Icon(Icons.play_arrow_rounded, size: 18, color: sub),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0), // 위 4: 모서리 점이 안 잘리게
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final s = list[i];
                return GestureDetector(
                  onTap: () => play(i),
                  child: SizedBox(
                    width: 92,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _cardArt(s, 92, isDark),
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: point,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bg, width: 2.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(s.titleDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ink, fontSize: 12.5)),
                        Text(s.artistDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: sub, fontSize: 10.5)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, margin: const EdgeInsets.fromLTRB(16, 2, 16, 0), color: ink.withOpacity(0.06)),
        ],
      ),
    );
  }

  /// 오늘의 카드 왼쪽: 곡 앨범 사진 (없으면 글자 타일)
''', "home_screen.dart: 새 곡 가로 카드 만들기")

# song_list_tile 에 point_color 가 불러와져 있는지
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
