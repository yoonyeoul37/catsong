# 오늘의 카드가 곡 목록과 같이 바로 나오게
#  - 지금: 곡 정보(제목·가수·사진)를 '전부' 다 읽어야 카드가 나옴 → 곡이 많으면 한참 뒤
#  - 바꾼 뒤: 카드에 나올 곡의 정보부터 먼저 읽음 → 띠는 목록과 같이 바로, 글자는 곧바로 스르르
#  - 시간대 추천 · 팁 · 내일 알람 카드는 곡 정보가 필요 없어서 바로 나옴
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


mp, home = one("music_provider.dart"), one("home_screen.dart")
mp_s, mp_c = read(mp)
hm_s, hm_c = read(home)

if "readFirst" in mp_s:
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
mp_s = rep(mp_s, '''  bool _metaLoading = false; // 2단계: 곡 정보(제목·가수)를 뒤에서 읽는 중
  bool get metaLoading => _metaLoading;
''', '''  bool _metaLoading = false; // 2단계: 곡 정보(제목·가수)를 뒤에서 읽는 중
  bool get metaLoading => _metaLoading;
  final Set<String> _metaDone = {}; // 2단계에서 정보를 다 읽은 곡
  final List<String> _metaFirst = []; // 먼저 읽어 줄 곡 (홈 오늘의 카드에 나올 곡)

  /// 이 곡 정보(제목·가수·사진)를 다 읽었는지
  bool metaReady(Song s) => !_metaLoading || (s.uri != null && _metaDone.contains(s.uri));

  /// 이 곡들 정보부터 먼저 읽기 (오늘의 카드가 목록과 같이 바로 나오게)
  void readFirst(Iterable<Song> list) {
    for (final s in list) {
      final u = s.uri;
      if (u != null && !_metaDone.contains(u) && !_metaFirst.contains(u)) _metaFirst.add(u);
    }
  }
''', "music_provider.dart: 먼저 읽을 곡 받기")

mp_s = rep(mp_s, '''      _metaLoading = true;
      int updateCount = 0;
      for (final song in _songs) {
        if (song.uri == null) continue;
''', '''      _metaLoading = true;
      _metaDone.clear();
      int updateCount = 0;
      final pending = List<Song>.from(_songs);
      final byUri = {for (final s in pending) if (s.uri != null) s.uri!: s};
      final taken = <String>{};
      var next = 0;
      while (true) {
        // 오늘의 카드에 나올 곡부터 먼저, 나머지는 목록 순서대로
        Song? pick;
        var first = false;
        while (_metaFirst.isNotEmpty && pick == null) {
          final u = _metaFirst.removeAt(0);
          if (!taken.contains(u)) pick = byUri[u];
          first = pick != null;
        }
        if (pick == null) {
          while (next < pending.length && taken.contains(pending[next].uri)) {
            next++;
          }
          if (next >= pending.length) break;
          pick = pending[next++];
        }
        final Song song = pick!;
        if (song.uri == null) continue;
        taken.add(song.uri!);
''', "music_provider.dart: 카드 곡부터 먼저 읽기")

mp_s = rep(mp_s, '''        updateCount++;
        // 10개마다 한 번씩 업데이트
        if (updateCount % 10 == 0) {
          notifyListeners();
        }
      }
''', '''        updateCount++;
        _metaDone.add(song.uri!);
        // 10개마다 한 번씩 업데이트 (카드 곡은 읽자마자 바로)
        if (first || updateCount % 10 == 0) {
          notifyListeners();
        }
      }
''', "music_provider.dart: 카드 곡을 읽으면 바로 화면에 알리기")

# ───────── home_screen.dart ─────────
hm_s = rep(hm_s, '''    if (music.metaLoading || _showFavorites || _showRecent || _isSelectionMode) return clean;
''', '''    if (_showFavorites || _showRecent || _isSelectionMode) return clean; // 곡 정보를 다 안 읽어도 바로
''', "home_screen.dart: 곡 정보를 다 기다리지 않기")

hm_s = rep(hm_s, '''    final weekTop = kind == 2 ? music.weekTopSong : null;
''', '''    final weekTop = kind == 2 ? music.weekTopSong : null;
    final cardSongs = <Song>[]; // 카드에 나오는 곡 (이 곡 정보부터 먼저 읽기)
''', "home_screen.dart: 카드에 나올 곡 모으기")

hm_s = rep(hm_s, '''      final i = songs.indexWhere((x) => x.uri == s.uri);
''', '''      final i = songs.indexWhere((x) => x.uri == s.uri);
      cardSongs.add(s);
''', "home_screen.dart: 오늘의 한 곡")

hm_s = rep(hm_s, '''      icon = Icons.history_rounded;
''', '''      cardSongs.addAll(notPlayed.take(3));
      icon = Icons.history_rounded;
''', "home_screen.dart: 한 달 동안 안 들은 곡")

hm_s = rep(hm_s, '''      final top = weekTop!;
''', '''      final top = weekTop!;
      cardSongs.add(top);
''', "home_screen.dart: 최근 7일 기록")

hm_s = rep(hm_s, '''    return Container(
      // 모서리·그림자 없이 양옆 끝까지
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      decoration: BoxDecoration(color: card),
      child: Row(
''', '''    // 카드에 나올 곡 정보를 아직 못 읽었으면: 그 곡부터 먼저 읽고, 그동안 띠만 (다 읽으면 글자가 스르르)
    final ready = cardSongs.every(music.metaReady);
    if (!ready) music.readFirst(cardSongs);
    return Container(
      // 모서리·그림자 없이 양옆 끝까지
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      decoration: BoxDecoration(color: card),
      child: AnimatedOpacity(
        opacity: ready ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Row(
''', "home_screen.dart: 띠는 바로, 글자는 곡 정보 읽으면 스르르")

hm_s = rep(hm_s, '''            onPressed: _closeDailyCard,
            icon: Icon(Icons.close_rounded, color: sub, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
    );
  }
''', '''            onPressed: _closeDailyCard,
            icon: Icon(Icons.close_rounded, color: sub, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
      ),
    );
  }
''', "home_screen.dart: 괄호 닫기")

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)

for p, s, c in ((mp, mp_s, mp_c), (home, hm_s, hm_c)):
    if c:
        s = s.replace("\n", "\r\n")
    open(p, "wb").write(s.encode("utf-8"))
print()
print("다 됐어요!")
