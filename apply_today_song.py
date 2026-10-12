# -*- coding: utf-8 -*-
# 홈 '오늘의 곡': 날짜 랜덤 → 듣기 기록으로 고르기
#  - 이 시간대(아침·낮·저녁·밤)에 자주 듣던 곡
#  - 예전에 즐겨 듣다가 한 달 넘게 안 들은 곡
#  둘을 날마다 번갈아, 기록이 없으면 예전처럼 랜덤
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

names = ['music_provider.dart', 'home_screen.dart']
paths, files = {}, {}
for n in names:
    p = find_file(n)
    if not p:
        print('❌ lib 폴더에서', n, '을(를) 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
        sys.exit(1)
    paths[n] = p
    with open(p, 'rb') as f:
        raw = f.read().decode('utf-8')
    files[n] = [raw.replace('\r\n', '\n'), '\r\n' in raw]

if 'songsOftenAt' in files['music_provider.dart'][0]:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
def rep(n, title, old, new):
    global ok
    src = files[n][0]
    if src.count(old) == 1:
        files[n][0] = src.replace(old, new)
        print('✔', n, '-', title)
    else:
        print('❌', n, '-', title, '— 코드를 못 찾았어요')
        ok = False

M = 'music_provider.dart'
rep(M, '시간대별 기록 칸 만들기',
    "  List<String> _playLog = []; // \"시각ms|곡경로\" (최근 7일만)\n",
    "  List<String> _playLog = []; // \"시각ms|곡경로\" (최근 7일만)\n"
    "  // 곡 경로 → [아침, 낮, 저녁, 밤] 들은 횟수 (홈 '오늘의 곡': 이 시간에 자주 듣던 곡)\n"
    "  Map<String, List<int>> _slotPlays = {};\n"
    "\n"
    "  /// 시간대: 0 아침(5~11시) · 1 낮(11~17시) · 2 저녁(17~22시) · 3 밤(22~5시)\n"
    "  static int slotOf(DateTime t) {\n"
    "    final h = t.hour;\n"
    "    if (h >= 5 && h < 11) return 0;\n"
    "    if (h >= 11 && h < 17) return 1;\n"
    "    if (h >= 17 && h < 22) return 2;\n"
    "    return 3;\n"
    "  }\n"
    "\n"
    "  void _addSlotPlay(String uri, DateTime t) {\n"
    "    final c = _slotPlays.putIfAbsent(uri, () => [0, 0, 0, 0]);\n"
    "    c[slotOf(t)]++;\n"
    "  }\n")

rep(M, '시간대별 기록 불러오기 (처음엔 최근 7일 기록으로 채움)',
    "    _playLog = prefs.getStringList('play_log') ?? [];\n"
    "    _prunePlayLog();\n"
    "  }\n",
    "    _playLog = prefs.getStringList('play_log') ?? [];\n"
    "    _prunePlayLog();\n"
    "    try {\n"
    "      final raw = prefs.getString('slot_plays');\n"
    "      if (raw != null) {\n"
    "        final Map decoded = jsonDecode(raw);\n"
    "        _slotPlays = decoded.map((k, v) => MapEntry(\n"
    "            k.toString(), (v as List).map((e) => (e as num).toInt()).toList()));\n"
    "      } else {\n"
    "        // 처음 한 번: 지금까지의 최근 7일 기록으로 시작\n"
    "        for (final e in _playLog) {\n"
    "          final i = e.indexOf('|');\n"
    "          final ms = int.tryParse(i < 0 ? '' : e.substring(0, i));\n"
    "          if (ms == null) continue;\n"
    "          _addSlotPlay(e.substring(i + 1), DateTime.fromMillisecondsSinceEpoch(ms));\n"
    "        }\n"
    "      }\n"
    "    } catch (_) {}\n"
    "  }\n")

rep(M, '시간대별 기록 저장',
    "    await prefs.setStringList('play_log', _playLog);\n"
    "  }\n",
    "    await prefs.setStringList('play_log', _playLog);\n"
    "    await prefs.setString('slot_plays', jsonEncode(_slotPlays));\n"
    "  }\n")

rep(M, '들을 때 시간대 기록 남기기',
    "      _playLog.add('$now|${song.uri}');\n",
    "      _playLog.add('$now|${song.uri}');\n"
    "      _addSlotPlay(song.uri!, DateTime.now());\n")

rep(M, '이 시간에 자주 듣던 곡 · 오랜만에 듣는 곡 찾기',
    "  List<String> _recentSongUris = [];\n",
    "  /// 이 시간대에 자주(2번 이상) 들은 곡, 많이 들은 순\n"
    "  List<Song> songsOftenAt(int slot) {\n"
    "    final out = <(Song, int)>[];\n"
    "    for (final s in _songs) {\n"
    "      if (s.uri == null || isCallRecordingPath(s.uri)) continue;\n"
    "      final n = _slotPlays[s.uri!]?[slot] ?? 0;\n"
    "      if (n >= 2) out.add((s, n));\n"
    "    }\n"
    "    out.sort((a, b) => b.$2.compareTo(a.$2));\n"
    "    return [for (final e in out) e.$1];\n"
    "  }\n"
    "\n"
    "  /// 예전에 즐겨(2번 이상) 듣다가 이 기간 동안 안 들은 곡, 많이 들은 순\n"
    "  List<Song> songsMissed(Duration d) {\n"
    "    final cut = DateTime.now().subtract(d).millisecondsSinceEpoch;\n"
    "    return _songs\n"
    "        .where((s) =>\n"
    "            s.uri != null &&\n"
    "            !isCallRecordingPath(s.uri) &&\n"
    "            (_playCounts[s.uri!] ?? 0) >= 2 &&\n"
    "            (_lastPlayed[s.uri!] ?? 0) < cut)\n"
    "        .toList()\n"
    "      ..sort((a, b) => playCountOf(b).compareTo(playCountOf(a)));\n"
    "  }\n"
    "\n"
    "  List<String> _recentSongUris = [];\n")

H = 'home_screen.dart'
rep(H, "'오늘의 곡' 고르는 방식",
    "      // ① 오늘의 한 곡 (같은 날은 같은 곡)\n"
    "      final i = math.Random(day).nextInt(songs.length);\n"
    "      final s = songs[i];\n"
    "      icon = Icons.album_outlined;\n"
    "      label = '오늘의 곡';\n",
    "      // ① 오늘의 한 곡: 듣기 기록으로 고르기\n"
    "      //    이 시간대에 자주 듣던 곡 / 예전에 즐겨 듣다 한 달 넘게 안 들은 곡을 날마다 번갈아\n"
    "      //    (기록이 없으면 예전처럼 날짜로 하나, 같은 날·같은 시간대엔 같은 곡)\n"
    "      final slot = MusicProvider.slotOf(now);\n"
    "      final often = music.songsOftenAt(slot).take(5).toList();\n"
    "      final missed = music.songsMissed(const Duration(days: 30)).take(10).toList();\n"
    "      final preferOften = (day + slot) % 2 == 0;\n"
    "      final Song s;\n"
    "      if (often.isNotEmpty && (preferOften || missed.isEmpty)) {\n"
    "        s = often[math.Random(day * 4 + slot).nextInt(often.length)];\n"
    "        label = '${const ['아침에', '낮에', '저녁에', '밤에'][slot]} 자주 듣던 곡';\n"
    "      } else if (missed.isNotEmpty) {\n"
    "        s = missed[math.Random(day).nextInt(missed.length)];\n"
    "        label = '오랜만에 듣는 곡';\n"
    "      } else {\n"
    "        s = songs[math.Random(day).nextInt(songs.length)];\n"
    "        label = '오늘의 곡';\n"
    "      }\n"
    "      final i = songs.indexWhere((x) => x.uri == s.uri);\n"
    "      icon = Icons.album_outlined;\n")

rep(H, '듣기 버튼',
    "      onAction = () => context.read<PlayerProvider>().playFromList(songs, i);\n",
    "      onAction = () => context.read<PlayerProvider>().playFromList(i >= 0 ? songs : [s], i >= 0 ? i : 0);\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

for n, p in paths.items():
    src, crlf = files[n]
    shutil.copy(p, p + '.bak')
    if crlf:
        src = src.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(src.encode('utf-8'))
print('저장했어요 (2개 파일)')
