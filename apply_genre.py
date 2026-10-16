# -*- coding: utf-8 -*-
# 음악 장르 정렬 넣기: 정렬 버튼 제목 → 가수 → 장르 → 제목
# 고치는 파일 4개: MainActivity.kt / song.dart / music_provider.dart / home_screen.dart
import io, os, sys

def find_kt():
    for root, _, files in os.walk('android'):
        for n in files:
            if n.endswith('.kt'):
                p = os.path.join(root, n)
                try:
                    if 'private fun getSongMetadata' in io.open(p, encoding='utf-8').read():
                        return p
                except Exception:
                    pass
    return None

kt = find_kt()
if not kt:
    print('❌ android 폴더에서 getSongMetadata 가 있는 .kt 파일을 못 찾았어요 (lib 폴더가 있는 곳에서 돌려 주세요)'); sys.exit(1)
FILES = {
    'kt': kt,
    'song': 'lib/models/song.dart',
    'mp': 'lib/providers/music_provider.dart',
    'home': 'lib/screens/home_screen.dart',
}
data, crlf = {}, {}
for k, p in FILES.items():
    try:
        raw = io.open(p, 'r', encoding='utf-8', newline='').read()
    except FileNotFoundError:
        print('❌ 파일이 없어요:', p); sys.exit(1)
    crlf[k] = '\r\n' in raw
    data[k] = raw.replace('\r\n', '\n')

if 'bool _byGenre' in data['home'] and 'genreKey' in data['song']:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
def rep(k, name, old, new):
    global ok
    s = data[k]
    if s.count(old) == 1:
        data[k] = s.replace(old, new); print('✔', name); return
    print('❌', name, '(찾을 코드를 못 찾음)' if s.count(old) == 0 else '(같은 코드가 여러 군데)'); ok = False

# ───────── 1) Kotlin: 장르도 같이 보내기
rep('kt', 'Kotlin: 장르 읽기',
"""            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val rawArt = retriever.embeddedPicture""",
"""            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val genre = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_GENRE) // 장르 (없으면 null)
            val rawArt = retriever.embeddedPicture""")
rep('kt', 'Kotlin: 장르 보내기',
"""                "duration" to duration?.toLongOrNull(), "albumArt" to albumArt)""",
"""                "duration" to duration?.toLongOrNull(), "albumArt" to albumArt, "genre" to genre)""")

# ───────── 2) song.dart: 장르 칸 + 정리
rep('song', 'song: 장르 칸',
"""  DateTime? lastPlayedAt;
""",
"""  DateTime? lastPlayedAt;
  String genre = ''; // 노래 파일에 적힌 장르 (그대로)
""")
rep('song', 'song: 장르 정리 함수',
"""  String get titleDisplay {
    if (title.isNotEmpty) return title;
    return AppLocale.current?.noTitle ?? '제목 없음';
  }
""",
"""  String get titleDisplay {
    if (title.isNotEmpty) return title;
    return AppLocale.current?.noTitle ?? '제목 없음';
  }

  // ───── 장르 ─────
  String? _genreFrom;
  String _genreKeyCache = '';

  /// 묶을 때 쓰는 장르 이름 ('' = 장르 없음 → 기타)
  String get genreKey {
    if (_genreFrom != genre) {
      _genreFrom = genre;
      _genreKeyCache = _cleanGenre(genre);
    }
    return _genreKeyCache;
  }

  /// 화면에 보이는 장르 이름 (없으면 '기타')
  String get genreDisplay =>
      genreKey.isNotEmpty ? genreKey : (AppLocale.current?.categoryEtc ?? '기타');

  // ID3 번호 장르 (예: '(13)' → Pop)
  static const _id3 = {
    0: 'Blues', 1: 'Classic Rock', 2: 'Country', 3: 'Dance', 4: 'Disco', 5: 'Funk',
    7: 'Hip-Hop', 8: 'Jazz', 9: 'Metal', 10: 'New Age', 11: 'Oldies', 13: 'Pop',
    14: 'R&B', 15: 'Rap', 16: 'Reggae', 17: 'Rock', 18: 'Techno', 20: 'Alternative',
    24: 'Soundtrack', 26: 'Ambient', 28: 'Vocal', 32: 'Classical', 33: 'Instrumental',
    35: 'House', 52: 'Electronic', 98: 'Easy Listening',
  };
  // 비슷한 이름 하나로 (공백·-·_·. 빼고 소문자로 비교)
  static const _same = {
    'kpop': 'K-Pop', 'koreanpop': 'K-Pop', '가요': 'K-Pop', '국내가요': 'K-Pop', '케이팝': 'K-Pop',
    'jpop': 'J-Pop', 'cpop': 'C-Pop', 'hiphop': 'Hip-Hop', 'rnb': 'R&B', 'r&b': 'R&B',
    'randb': 'R&B', 'edm': 'EDM', 'ost': 'OST', 'soundtrack': 'Soundtrack',
  };
  static const _none = {'', 'unknown', '<unknown>', 'other', 'others', 'genre', 'none', 'unknowngenre', '기타'};

  static String _cleanGenre(String raw) {
    var g = raw.trim();
    if (g.isEmpty) return '';
    // 여러 장르가 같이 적혀 있으면 첫 번째만 (Pop; Dance / Pop/Dance)
    g = g.split(RegExp(r'[;,/|]')).first.trim();
    // ID3 번호: (13) 또는 13
    final m = RegExp(r'^\\((\\d+)\\)(.*)$').firstMatch(g);
    if (m != null) {
      final rest = m.group(2)!.trim();
      g = rest.isNotEmpty ? rest : (_id3[int.parse(m.group(1)!)] ?? '');
    } else if (RegExp(r'^\\d+$').hasMatch(g)) {
      g = _id3[int.parse(g)] ?? '';
    }
    final low = g.toLowerCase().replaceAll(RegExp(r'[\\s\\-_.]'), '');
    if (_none.contains(low)) return '';
    final same = _same[low];
    if (same != null) return same;
    // 영어는 대소문자만 다른 것도 같게 (POP, pop → Pop)
    if (RegExp(r'^[A-Za-z ]+$').hasMatch(g)) {
      return g
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }
    return g;
  }
""")

# ───────── 3) music_provider.dart: 받은 장르 넣기
rep('mp', 'music_provider: 장르 넣기',
"""            song.duration = (metadata['duration'] as int?) ?? song.duration;
""",
"""            song.duration = (metadata['duration'] as int?) ?? song.duration;
            song.genre = (metadata['genre'] as String?) ?? song.genre; // 장르
""")

# ───────── 4) home_screen.dart
rep('home', 'home: 장르 정렬 상태',
"""  static const double _artistHeaderH = 30; // 가수 이름 줄 높이
""",
"""  static const double _artistHeaderH = 30; // 가수 이름 줄 높이
  // 장르 정렬 (제목 → 가수 → 장르 → 제목): 장르일 땐 초성 막대 없이 장르 줄로 묶음
  bool _byGenre = false;
  Map<String, int> _genreCounts = const {}; // 장르별 곡 수
""")
rep('home', 'home: 바뀜 확인에 장르 넣기 ①',
"""    var fp = songs.length * 2 + (_byArtist ? 1 : 0) + lang.hashCode;""",
"""    var fp = songs.length * 2 + (_byArtist ? 1 : 0) + (_byGenre ? 7 : 0) + lang.hashCode;""")
rep('home', 'home: 바뀜 확인에 장르 넣기 ②',
"""      fp = (fp * 31 + s.titleDisplay.hashCode + (_byArtist ? s.artistDisplay.hashCode : 0)) & 0x3fffffff;""",
"""      fp = (fp * 31 + s.titleDisplay.hashCode + (_byArtist ? s.artistDisplay.hashCode : 0) +
              (_byGenre ? s.genreKey.hashCode : 0)) & 0x3fffffff;""")
rep('home', 'home: 장르로 묶기',
"""    _indexFingerprint = fp;
""",
"""    _indexFingerprint = fp;
    if (_byGenre) {
      // 장르 정렬: 곡 많은 장르부터, 장르 없는 곡(기타)은 맨 아래, 장르 안에서는 제목순
      final byG = <String, List<Song>>{};
      for (final s in songs) {
        byG.putIfAbsent(s.genreKey, () => []).add(s);
      }
      final keys = byG.keys.where((k) => k.isNotEmpty).toList()
        ..sort((a, b) {
          final c = byG[b]!.length.compareTo(byG[a]!.length);
          return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
        });
      if (byG.containsKey('')) keys.add('');
      final ordered = <Song>[];
      final entries = <(String?, int)>[];
      final counts = <String, int>{};
      for (final k in keys) {
        final list = byG[k]!
          ..sort((a, b) => a.titleDisplay.toLowerCase().compareTo(b.titleDisplay.toLowerCase()));
        final label = list.first.genreDisplay;
        counts[label] = list.length;
        entries.add((label, -4)); // 장르 줄
        for (final s in list) {
          entries.add((null, ordered.length));
          ordered.add(s);
        }
      }
      _indexSongs = ordered;
      _indexCounts = const {};
      _genreCounts = counts;
      _indexEntries = entries;
      return;
    }
""")
rep('home', 'home: 위치 계산 ① (장르 줄 높이)',
"""e.$2 == -1 ? _indexHeaderH : (e.$2 == -2 ? _artistHeaderH : rowH)""",
"""e.$2 == -1 ? _indexHeaderH : (e.$2 == -2 || e.$2 == -4 ? _artistHeaderH : rowH)""")
rep('home', 'home: 위치 계산 ② (장르 줄 높이)',
"""t == -1 ? _indexHeaderH : (t == -2 ? _artistHeaderH : rowH)""",
"""t == -1 ? _indexHeaderH : (t == -2 || t == -4 ? _artistHeaderH : rowH)""")
rep('home', 'home: 장르 정렬 저장·장르 줄·글자',
"""  /// 가수 정렬일 때 가수 이름 줄: 가수 + 곡 수
""",
"""  /// 정렬 바꾸기 (제목 / 가수 / 장르) — 기억해 둠
  Future<void> _setSortMode({required bool artist, required bool genre}) async {
    if (artist == _byArtist && genre == _byGenre) return;
    setState(() {
      _byArtist = artist;
      _byGenre = genre;
      _indexFingerprint = -1;
    });
    if (_songListController.hasClients) _songListController.jumpTo(0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('song_sort_by_artist', artist);
    await prefs.setBool('song_sort_by_genre', genre);
  }

  /// '장르' / '장르별로 정렬했어요' (5개 언어)
  String _genreText(BuildContext c, bool toast) {
    final l = Localizations.localeOf(c);
    final k = l.languageCode == 'zh'
        ? ((l.scriptCode == 'Hant' || l.countryCode == 'TW' || l.countryCode == 'HK') ? 'tw' : 'cn')
        : l.languageCode;
    const label = {'ko': '장르', 'ja': 'ジャンル', 'tw': '類型', 'cn': '类型'};
    const done = {'ko': '장르별로 정렬했어요', 'ja': 'ジャンル別に並べ替えました', 'tw': '已依類型排序', 'cn': '已按类型排序'};
    return toast ? (done[k] ?? 'Sorted by genre') : (label[k] ?? 'Genre');
  }

  /// 장르 정렬일 때 장르 이름 줄: 장르 + 곡 수 (가수 줄과 같은 모양)
  Widget _buildGenreHeader(String genre, bool isDark) {
    final count = _genreCounts[genre] ?? 0;
    return SizedBox(
      height: _artistHeaderH,
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

  /// 가수 정렬일 때 가수 이름 줄: 가수 + 곡 수
""")
rep('home', 'home: 지난번 정렬 불러오기',
"""      final v = p.getBool('song_sort_by_artist') ?? false;
      if (mounted && v != _byArtist) {
        setState(() {
          _byArtist = v;
          _indexFingerprint = -1;
        });
      }""",
"""      final v = p.getBool('song_sort_by_artist') ?? false;
      final g = (p.getBool('song_sort_by_genre') ?? false) && !v;
      if (mounted && (v != _byArtist || g != _byGenre)) {
        setState(() {
          _byArtist = v;
          _byGenre = g;
          _indexFingerprint = -1;
        });
      }""")
rep('home', 'home: 정렬 버튼 누르기 (제목 → 가수 → 장르)',
"""                      final next = !_byArtist;
                      _setSortByArtist(next);
                      showParanToast(context, next ? tr.sortedByArtist : tr.sortedByTitle,
                          duration: const Duration(milliseconds: 1500));""",
"""                      // 제목 → 가수 → 장르 → 제목 (장르가 적힌 곡이 하나도 없으면 장르는 건너뜀)
                      final hasGenre = musicProvider.allSongs.any((s) => s.genreKey.isNotEmpty);
                      final toArtist = !_byArtist && !_byGenre;
                      final toGenre = _byArtist && hasGenre;
                      _setSortMode(artist: toArtist, genre: toGenre);
                      showParanToast(
                          context,
                          toArtist
                              ? tr.sortedByArtist
                              : (toGenre ? _genreText(context, true) : tr.sortedByTitle),
                          duration: const Duration(milliseconds: 1500));""")
rep('home', 'home: 정렬 버튼 글자',
"""Text(_byArtist ? tr.sortArtist : tr.sortTitle,""",
"""Text(_byArtist ? tr.sortArtist : (_byGenre ? _genreText(context, false) : tr.sortTitle),""")
rep('home', 'home: 장르 정렬일 땐 초성 막대 없이 묶기',
"""              final showIndexBar = listSongs.length >= 30 && !_isSearching;
              // 가수 정렬이면 곡이 적어도 가수별로 묶어서 보여줌
              final grouped = showIndexBar || (_byArtist && !_isSearching);""",
"""              // 장르 정렬은 장르 줄로 묶어서 초성 막대 없음
              final showIndexBar = listSongs.length >= 30 && !_isSearching && !_byGenre;
              // 가수·장르 정렬이면 곡이 적어도 묶어서 보여줌
              final grouped = showIndexBar || ((_byArtist || _byGenre) && !_isSearching);""")
rep('home', 'home: 목록에 장르 줄 그리기',
"""                    if (entry.$2 == -2) {
                      return _buildArtistHeader(entry.$1!, isDarkList); // 가수 이름 줄
                    }""",
"""                    if (entry.$2 == -2) {
                      return _buildArtistHeader(entry.$1!, isDarkList); // 가수 이름 줄
                    }
                    if (entry.$2 == -4) {
                      return _buildGenreHeader(entry.$1!, isDarkList); // 장르 줄
                    }""")

if not ok:
    print('\n아무것도 저장하지 않았어요. 지금 파일들을 다시 보내 주세요.'); sys.exit(1)
for k, p in FILES.items():
    out = data[k].replace('\n', '\r\n') if crlf[k] else data[k]
    io.open(p, 'w', encoding='utf-8', newline='').write(out)
print('\n저장했어요 ✔  (Kotlin 파일:', kt, ')')
