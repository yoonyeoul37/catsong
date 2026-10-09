# -*- coding: utf-8 -*-
# 2단계: 재생 기록
# - 곡: 30초 이상(1분보다 짧은 곡은 절반 이상) 들어야 재생 횟수 +1 · "최근에 들었어요"에 들어감
#   (앞뒤로 넘긴 시간은 안 셈, 한 곡 반복은 다시 30초 들으면 또 +1)
# - 라디오 · 자연소리: 30초 이상 들어야 "최근에 들었어요"에 들어감
# - 곡마다 언제 들었는지 저장 (홈 카드: 한 달 동안 안 들은 곡 · 최근 7일 기록용)
# - 덤: 디버깅(flutter run) 중 오류는 Crashlytics에 안 보내기
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PLAYER = os.path.join(ROOT, 'lib', 'providers', 'player_provider.dart')
MUSIC = os.path.join(ROOT, 'lib', 'providers', 'music_provider.dart')
RADIO = os.path.join(ROOT, 'lib', 'providers', 'radio_provider.dart')
MAIN = os.path.join(ROOT, 'lib', 'main.dart')

PLAYER_EDITS = [
    ('곡: 들은 시간 재는 부품',
     "  DateTime _startedAt = DateTime(2000); // 곡을 막 튼 시각\n",
     "  DateTime _startedAt = DateTime(2000); // 곡을 막 튼 시각\n"
     "\n"
     "  // ───── 들은 기록: 30초 이상(1분보다 짧은 곡은 절반 이상) 들어야 재생 횟수·최근에 넣음 ─────\n"
     "  Song? _listenSong; // 지금 재고 있는 곡\n"
     "  int _listenMs = 0; // 실제로 들은 시간\n"
     "  int _lastPosMs = 0;\n"
     "  bool _listenCounted = false; // 이번에 이미 셌는지\n"
     "  Timer? _natureTimer;\n"
     "\n"
     "  void _startListen(Song song) {\n"
     "    _listenSong = song;\n"
     "    _listenMs = 0;\n"
     "    _lastPosMs = 0;\n"
     "    _listenCounted = false;\n"
     "  }\n"
     "\n"
     "  void _trackListen(Duration pos) {\n"
     "    final song = _listenSong;\n"
     "    final p = pos.inMilliseconds;\n"
     "    final d = p - _lastPosMs;\n"
     "    _lastPosMs = p;\n"
     "    if (song == null || _listenCounted || !_player.playing) return;\n"
     "    if (d <= 0 || d > 2000) return; // 앞뒤로 넘긴 건 안 셈\n"
     "    _listenMs += d;\n"
     "    final total = _duration.inMilliseconds > 0 ? _duration.inMilliseconds : song.duration;\n"
     "    final need = total > 0 && total < 60000 ? total ~/ 2 : 30000;\n"
     "    if (_listenMs >= need) {\n"
     "      _listenCounted = true;\n"
     "      onSongPlayed?.call(song);\n"
     "    }\n"
     "  }\n"),
    ('곡: 재생 위치가 바뀔 때마다 들은 시간 더하기',
     "    _player.positionStream.listen((position) {\n"
     "      _position = position;\n",
     "    _player.positionStream.listen((position) {\n"
     "      _position = position;\n"
     "      _trackListen(position); // 30초 이상 들으면 기록\n"),
    ('곡: 한 곡 반복은 다시 30초 들으면 +1',
     "        // 한 곡 반복도 끝까지 한 번 들을 때마다 재생 횟수 +1\n"
     "        final song = currentSong;\n"
     "        if (song != null) onSongPlayed?.call(song);\n",
     "        // 한 곡 반복: 다시 30초 이상 들으면 또 +1\n"
     "        final song = currentSong;\n"
     "        if (song != null) _startListen(song);\n"),
    ('곡: 틀자마자 세지 않기',
     "      onSongPlayed?.call(song);\n"
     "      onSongChanged?.call(song);\n",
     "      _startListen(song); // 틀자마자 세지 않고, 30초 이상 들으면 기록\n"
     "      onSongChanged?.call(song);\n"),
    ('자연소리: 30초 이상 들어야 최근에',
     "    onNaturePlayed?.call(assetPath, displayName);\n",
     "    _listenSong = null;\n"
     "    // 30초 이상 들었을 때만 \"최근에 들었어요\"에 넣기\n"
     "    _natureTimer?.cancel();\n"
     "    _natureTimer = Timer(const Duration(seconds: 30), () {\n"
     "      if (_natureSoundName == displayName && _player.playing) {\n"
     "        onNaturePlayed?.call(assetPath, displayName);\n"
     "      }\n"
     "    });\n"),
]

MUSIC_EDITS = [
    ('기록: 처음에 불러오기',
     "      await _loadPlayCounts();\n",
     "      await _loadPlayCounts();\n"
     "      await _loadPlayHistory(); // 언제 들었는지\n"),
    ('기록: 언제 들었는지 저장하는 부품',
     "  Future<void> _savePlayCounts() async {\n"
     "    final prefs = await SharedPreferences.getInstance();\n"
     "    await prefs.setString('play_counts', jsonEncode(_playCounts));\n"
     "  }\n",
     "  Future<void> _savePlayCounts() async {\n"
     "    final prefs = await SharedPreferences.getInstance();\n"
     "    await prefs.setString('play_counts', jsonEncode(_playCounts));\n"
     "  }\n"
     "\n"
     "  // ───── 언제 들었는지 (홈 카드: 한 달 동안 안 들은 곡 · 최근 7일 기록) ─────\n"
     "  Map<String, int> _lastPlayed = {}; // 곡 경로 → 마지막으로 들은 시각(ms)\n"
     "  List<String> _playLog = []; // \"시각ms|곡경로\" (최근 7일만)\n"
     "\n"
     "  Future<void> _loadPlayHistory() async {\n"
     "    final prefs = await SharedPreferences.getInstance();\n"
     "    try {\n"
     "      final raw = prefs.getString('last_played');\n"
     "      if (raw != null) {\n"
     "        final Map decoded = jsonDecode(raw);\n"
     "        _lastPlayed = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));\n"
     "      }\n"
     "    } catch (_) {}\n"
     "    _playLog = prefs.getStringList('play_log') ?? [];\n"
     "    _prunePlayLog();\n"
     "  }\n"
     "\n"
     "  void _prunePlayLog() {\n"
     "    final cut = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;\n"
     "    _playLog.removeWhere((e) => (int.tryParse(e.split('|').first) ?? 0) < cut);\n"
     "  }\n"
     "\n"
     "  Future<void> _savePlayHistory() async {\n"
     "    final prefs = await SharedPreferences.getInstance();\n"
     "    await prefs.setString('last_played', jsonEncode(_lastPlayed));\n"
     "    await prefs.setStringList('play_log', _playLog);\n"
     "  }\n"
     "\n"
     "  /// 최근 7일 동안 들은 횟수\n"
     "  int get weekPlayCount {\n"
     "    _prunePlayLog();\n"
     "    return _playLog.length;\n"
     "  }\n"
     "\n"
     "  /// 최근 7일 동안 가장 많이 들은 곡 (없으면 null)\n"
     "  Song? get weekTopSong {\n"
     "    _prunePlayLog();\n"
     "    final counts = <String, int>{};\n"
     "    for (final e in _playLog) {\n"
     "      final i = e.indexOf('|');\n"
     "      if (i < 0) continue;\n"
     "      final uri = e.substring(i + 1);\n"
     "      counts[uri] = (counts[uri] ?? 0) + 1;\n"
     "    }\n"
     "    String? best;\n"
     "    var most = 0;\n"
     "    for (final c in counts.entries) {\n"
     "      if (c.value > most) {\n"
     "        most = c.value;\n"
     "        best = c.key;\n"
     "      }\n"
     "    }\n"
     "    if (best == null) return null;\n"
     "    for (final s in _songs) {\n"
     "      if (s.uri == best) return s;\n"
     "    }\n"
     "    return null;\n"
     "  }\n"
     "\n"
     "  /// 이 기간 동안 안 들은 곡 (한 번도 안 들은 곡 포함, 녹음 제외)\n"
     "  List<Song> songsNotPlayedFor(Duration d) {\n"
     "    final cut = DateTime.now().subtract(d).millisecondsSinceEpoch;\n"
     "    return _songs\n"
     "        .where((s) => s.uri != null && !isCallRecordingPath(s.uri) && (_lastPlayed[s.uri!] ?? 0) < cut)\n"
     "        .toList();\n"
     "  }\n"),
    ('기록: 들을 때마다 시각 남기기',
     "      _playCounts[song.uri!] = (_playCounts[song.uri!] ?? 0) + 1;\n"
     "      _savePlayCounts();\n",
     "      _playCounts[song.uri!] = (_playCounts[song.uri!] ?? 0) + 1;\n"
     "      _savePlayCounts();\n"
     "      final now = DateTime.now().millisecondsSinceEpoch;\n"
     "      _lastPlayed[song.uri!] = now;\n"
     "      _playLog.add('$now|${song.uri}');\n"
     "      _prunePlayLog();\n"
     "      _savePlayHistory();\n"),
]

RADIO_EDITS = [
    ('라디오: 30초 재는 타이머',
     "  void Function(RadioStation station)? onStationPlayed;\n",
     "  void Function(RadioStation station)? onStationPlayed;\n"
     "  Timer? _playedTimer; // 30초 이상 들었을 때만 최근에 넣기\n"),
    ('라디오: 30초 이상 들어야 최근에',
     "    onStationPlayed?.call(station);\n\n    try {\n",
     "    // 30초 이상 들었을 때만 \"최근에 들었어요\"에 넣기\n"
     "    _playedTimer?.cancel();\n"
     "    _playedTimer = Timer(const Duration(seconds: 30), () {\n"
     "      if (_currentStation?.stationUuid == station.stationUuid && isPlaying) {\n"
     "        onStationPlayed?.call(station);\n"
     "      }\n"
     "    });\n\n"
     "    try {\n"),
]

MAIN_EDITS = [
    ('Crashlytics: 디버깅 오류는 안 보내기 (1)',
     "import 'package:firebase_crashlytics/firebase_crashlytics.dart';\n",
     "import 'package:firebase_crashlytics/firebase_crashlytics.dart';\n"
     "import 'package:flutter/foundation.dart' show kDebugMode;\n"),
    ('Crashlytics: 디버깅 오류는 안 보내기 (2)',
     "    await Firebase.initializeApp();\n",
     "    await Firebase.initializeApp();\n"
     "    // 디버깅(flutter run) 중 오류는 안 보내고, 스토어에서 받은 앱 오류만 기록\n"
     "    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);\n"),
]

MARK = '_trackListen'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    for p in (PLAYER, MUSIC, RADIO, MAIN):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(PLAYER, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in ((PLAYER, PLAYER_EDITS), (MUSIC, MUSIC_EDITS), (RADIO, RADIO_EDITS), (MAIN, MAIN_EDITS)):
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if path == MAIN and new.split('\n')[1] in text and old in text and 'kDebugMode' in text \
                    and ('setCrashlyticsCollectionEnabled' in text if '(2)' in name else True):
                print('✔', name, '(이미 돼 있음)')
                continue
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
