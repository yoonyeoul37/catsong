# -*- coding: utf-8 -*-
# 장르 화면 정리: 장르 줄 ▶ 없애기 · 위 ▶/⤨ 하나로 (고른 장르만 재생/섞기) · 장르 하나 고르면 장르 줄 숨기기
# 고치는 파일: lib/screens/home_screen.dart
import io, sys
PATH = 'lib/screens/home_screen.dart'
try:
    raw = io.open(PATH, 'r', encoding='utf-8', newline='').read()
except FileNotFoundError:
    print('❌ 파일이 없어요:', PATH); sys.exit(1)
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')
if '_playListNow(' in src:
    print('이미 적용돼 있어요'); sys.exit(0)
if '_genreFilter' not in src:
    print('❌ apply_genre_bar.py 를 먼저 돌려 주세요'); sys.exit(1)

ok = True
def rep(name, old, new):
    global src, ok
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name); return
    print('❌', name, '(찾을 코드를 못 찾음)' if n == 0 else '(같은 코드가 여러 군데)'); ok = False

# 1) 장르 줄: ▶ 없이 글자만 (가수 줄과 같은 모양) — 함수 통째로 (▶ 위치를 고쳤든 안 고쳤든 그대로 됨)
START = '  /// 장르 정렬일 때 장르 이름 줄: 장르 + 곡 수 + ▶ (이 장르만 섞어서 듣기)\n'
END = "  /// '발라드 4곡 섞어서 재생' (5개 언어)\n"
NEW = r'''  /// 장르 정렬일 때 장르 이름 줄: 장르 + 곡 수 (가수 줄과 같은 모양, 재생은 위 ▶·⤨로)
  Widget _buildGenreHeader(String genre, bool isDark) {
    final count = _genreCounts[genre] ?? 0;
    return SizedBox(
      height: _genreHeaderH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 12, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(genre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF17140F),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(width: 6),
            Text('$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.7),
                  fontSize: 11,
                )),
          ],
        ),
      ),
    );
  }

  /// 위 ▶·⤨가 틀 곡: 장르 하나 골랐으면 그 장르 곡만, 아니면 전체
  List<Song> _playListNow(List<Song> all) {
    if (_byGenre && _genreFilter != null && _genreSongs.length == 1) {
      return _genreSongs.values.first;
    }
    return all;
  }

'''
if src.count(START) == 1 and src.count(END) == 1 and src.index(START) < src.index(END):
    src = src[:src.index(START)] + NEW + src[src.index(END):]
    print('✔ 장르 줄 ▶ 없애기 (글자만)')
else:
    print('❌ 장르 줄 함수 (찾을 코드를 못 찾음)'); ok = False

rep('장르 줄 높이를 가수 줄과 같게',
"""  static const double _genreHeaderH = 40; // 장르 줄 높이 (▶ 버튼 들어가게 가수 줄보다 조금 높게)""",
"""  static const double _genreHeaderH = 30; // 장르 줄 높이 (가수 줄과 같게)""")

# 2) 장르 하나 골랐으면 장르 줄 숨기기 (위 칸에 이미 보이니까)
rep('장르 하나 고르면 장르 줄 숨기기',
"""        entries.add((label, -4)); // 장르 줄
""",
"""        if (shown.length > 1) entries.add((label, -4)); // 장르 줄 (하나만 골랐으면 위 칸에 보이니 생략)
""")

# 3) 위 ▶ / ⤨ : 고른 장르만
rep('위 ▶: 고른 장르만 재생',
"""                      if (musicProvider.songs.isNotEmpty) {
                        context.read<PlayerProvider>().playFromList(musicProvider.songs, 0);
                      }""",
"""                      final list = _playListNow(musicProvider.songs); // 장르 골랐으면 그 장르만
                      if (list.isNotEmpty) {
                        context.read<PlayerProvider>().playFromList(list, 0);
                      }""")
rep('위 ⤨: 고른 장르만 섞기',
"""                      if (musicProvider.songs.isNotEmpty) {
                        final songs = List<Song>.from(musicProvider.songs)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0);
                      }""",
"""                      final list = _playListNow(musicProvider.songs); // 장르 골랐으면 그 장르만
                      if (list.isNotEmpty) {
                        final songs = List<Song>.from(list)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0);
                        // 장르 골랐으면 '힙합 8곡 섞어서 재생' 안내
                        if (!identical(list, musicProvider.songs) && _genreSongs.isNotEmpty) {
                          showParanToast(context, _genreShuffleText(_genreSongs.keys.first, songs.length),
                              duration: const Duration(milliseconds: 1500));
                        }
                      }""")

if not ok:
    print('\n아무것도 저장하지 않았어요. 지금 파일을 다시 보내 주세요.'); sys.exit(1)
out = src.replace('\n', '\r\n') if crlf else src
io.open(PATH, 'w', encoding='utf-8', newline='').write(out)
print('\n저장했어요 ✔')
