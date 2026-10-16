# -*- coding: utf-8 -*-
# 장르 정렬: 위에 장르 칸(글자 + 가는 밑줄) + 장르 줄 ▶ 섞어 듣기
# 고치는 파일: lib/screens/home_screen.dart
import io, sys
PATH = 'lib/screens/home_screen.dart'
try:
    raw = io.open(PATH, 'r', encoding='utf-8', newline='').read()
except FileNotFoundError:
    print('❌ 파일이 없어요:', PATH); sys.exit(1)
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')
if '_genreFilter' in src:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'bool _byGenre' not in src:
    print('❌ apply_genre.py 를 먼저 돌려 주세요'); sys.exit(1)

ok = True
def rep(name, old, new):
    global src, ok
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name); return
    print('❌', name, '(찾을 코드를 못 찾음)' if n == 0 else '(같은 코드가 여러 군데)'); ok = False

rep('상태: 고른 장르·장르 줄 높이',
"""  Map<String, int> _genreCounts = const {}; // 장르별 곡 수
""",
"""  Map<String, int> _genreCounts = const {}; // 장르별 곡 수
  String? _genreFilter; // 장르 칸에서 고른 장르 (null = 전체)
  Map<String, List<Song>> _genreSongs = const {}; // 장르 줄 이름 → 곡 (▶ 섞어 듣기용)
  static const double _genreHeaderH = 40; // 장르 줄 높이 (▶ 버튼 들어가게 가수 줄보다 조금 높게)
""")
rep('바뀜 확인에 고른 장르 넣기',
"""(_byGenre ? 7 : 0) + lang.hashCode;""",
"""(_byGenre ? 7 : 0) + (_genreFilter?.hashCode ?? 0) + lang.hashCode;""")
rep('고른 장르만 보이기',
"""      final counts = <String, int>{};
      for (final k in keys) {""",
"""      final counts = <String, int>{};
      final songsByLabel = <String, List<Song>>{};
      // 장르 칸에서 하나 고르면 그 장르만 (전체 보기에서만)
      final f = (_showFavorites || _showRecent) ? null : _genreFilter;
      final shown = (f != null && byG.containsKey(f)) ? [f] : keys;
      for (final k in shown) {""")
rep('장르 줄 곡 기억 ①',
"""        counts[label] = list.length;
""",
"""        counts[label] = list.length;
        songsByLabel[label] = list;
""")
rep('장르 줄 곡 기억 ②',
"""      _genreCounts = counts;
""",
"""      _genreCounts = counts;
      _genreSongs = songsByLabel;
""")
rep('위치 계산 ① (장르 줄 높이)',
"""(e.$2 == -2 || e.$2 == -4 ? _artistHeaderH : rowH)""",
"""(e.$2 == -2 ? _artistHeaderH : (e.$2 == -4 ? _genreHeaderH : rowH))""")
rep('위치 계산 ② (장르 줄 높이)',
"""(t == -2 || t == -4 ? _artistHeaderH : rowH)""",
"""(t == -2 ? _artistHeaderH : (t == -4 ? _genreHeaderH : rowH))""")
rep('정렬 바꾸면 고른 장르 풀기',
"""      _byArtist = artist;
      _byGenre = genre;
      _indexFingerprint = -1;""",
"""      _byArtist = artist;
      _byGenre = genre;
      _genreFilter = null;
      _indexFingerprint = -1;""")

# 장르 줄(▶ 포함) + 장르 칸 + 섞어 듣기 — 장르 줄 함수를 통째로 바꿈
START = '  /// 장르 정렬일 때 장르 이름 줄: 장르 + 곡 수 (가수 줄과 같은 모양)\n'
END = '  /// 가수 정렬일 때 가수 이름 줄: 가수 + 곡 수\n'
NEW = r'''  /// 장르 정렬일 때 장르 이름 줄: 장르 + 곡 수 + ▶ (이 장르만 섞어서 듣기)
  Widget _buildGenreHeader(String genre, bool isDark) {
    final count = _genreCounts[genre] ?? 0;
    final baseColor = isDark ? Colors.white : Colors.black;
    return SizedBox(
      height: _genreHeaderH,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 14, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            const Spacer(),
            // ▶ 이 장르만 섞어서 듣기 (아티스트 목록 ▶와 같은 모양)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _playGenreShuffled(genre),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, size: 18, color: baseColor.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 장르 줄 ▶: 그 장르 곡만 섞어서 재생 (보이는 목록 순서는 그대로)
  void _playGenreShuffled(String label) {
    final list = _genreSongs[label];
    if (list == null || list.isEmpty) return;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final songs = List<Song>.from(list)..shuffle();
    context.read<PlayerProvider>().playFromList(songs, 0, isPlayAllAction: true);
    showParanToast(context, _genreShuffleText(label, songs.length),
        duration: const Duration(milliseconds: 1500));
  }

  /// '발라드 4곡 섞어서 재생' (5개 언어)
  String _genreShuffleText(String label, int n) {
    final l = Localizations.localeOf(context);
    final k = l.languageCode == 'zh'
        ? ((l.scriptCode == 'Hant' || l.countryCode == 'TW' || l.countryCode == 'HK') ? 'tw' : 'cn')
        : l.languageCode;
    return switch (k) {
      'ko' => '$label $n곡 섞어서 재생',
      'ja' => '$label $n曲をシャッフル再生',
      'tw' => '隨機播放 $label・$n 首',
      'cn' => '随机播放 $label・$n 首',
      _ => 'Shuffling $label · $n songs',
    };
  }

  /// 장르 고르기 (null = 전체)
  void _setGenreFilter(String? key) {
    if (key == _genreFilter) return;
    setState(() {
      _genreFilter = key;
      _indexFingerprint = -1;
    });
    if (_songListController.hasClients) _songListController.jumpTo(0);
  }

  /// 장르 정렬일 때 목록 위 장르 칸: 글자 + 가는 밑줄 (옆으로 밀기)
  Widget _buildGenreBar(Color baseColor, List<Song> songs) {
    final counts = <String, int>{};
    final labels = <String, String>{};
    for (final s in songs) {
      final k = s.genreKey;
      counts[k] = (counts[k] ?? 0) + 1;
      labels[k] ??= s.genreDisplay;
    }
    final keys = counts.keys.where((k) => k.isNotEmpty).toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
      });
    if (counts.containsKey('')) keys.add(''); // 기타는 맨 끝
    final cur = (_genreFilter != null && counts.containsKey(_genreFilter)) ? _genreFilter : null;
    final point = Theme.of(context).colorScheme.primary;

    Widget item(String text, int? n, bool on, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 18),
          padding: const EdgeInsets.only(top: 8, bottom: 7),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: on ? point : Colors.transparent, width: 2),
            ),
          ),
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: text,
                style: TextStyle(
                  color: on ? baseColor : baseColor.withOpacity(0.5),
                  fontSize: 13.5,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                )),
            if (n != null)
              TextSpan(
                  text: ' $n',
                  style: TextStyle(color: baseColor.withOpacity(on ? 0.5 : 0.32), fontSize: 11)),
          ])),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.08))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          item(tr.all, null, cur == null, () => _setGenreFilter(null)),
          for (final k in keys) item(labels[k]!, counts[k], cur == k, () => _setGenreFilter(k)),
        ]),
      ),
    );
  }

'''
if src.count(START) == 1 and src.count(END) == 1 and src.index(START) < src.index(END):
    src = src[:src.index(START)] + NEW + src[src.index(END):]
    print('✔ 장르 줄 ▶ · 섞어 듣기 · 장르 칸')
else:
    print('❌ 장르 줄 함수 (찾을 코드를 못 찾음)'); ok = False

rep('장르 정렬일 땐 맨 위 새 곡 칸 없이 (장르별로만)',
"""              final newOnes = (!_isSearching && !_showFavorites && !_showRecent)""",
"""              final newOnes = (!_isSearching && !_showFavorites && !_showRecent && !_byGenre)""")
rep('목록 위에 장르 칸 넣기',
"""            Expanded(
              child: Builder(builder: (context) {
              // 빠른 이동 막대: 30곡 이상이고 검색 중이 아닐 때만""",
"""            // 장르 정렬일 때만: 장르 칸 (전체 보기에서)
            if (_byGenre && !_isSearching && !_showFavorites && !_showRecent)
              _buildGenreBar(baseColor, musicProvider.songs),
            Expanded(
              child: Builder(builder: (context) {
              // 빠른 이동 막대: 30곡 이상이고 검색 중이 아닐 때만""")

if not ok:
    print('\n아무것도 저장하지 않았어요. 지금 파일을 다시 보내 주세요.'); sys.exit(1)
out = src.replace('\n', '\r\n') if crlf else src
io.open(PATH, 'w', encoding='utf-8', newline='').write(out)
print('\n저장했어요 ✔')
