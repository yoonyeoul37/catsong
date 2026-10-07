import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/locale_holder.dart';
import '../utils/song_title_cleaner.dart';

class LyricsLine {
  final Duration time;
  final String text;

  LyricsLine({required this.time, required this.text});
}

class LyricsProvider extends ChangeNotifier {
  List<LyricsLine> _lyrics = [];
  String _plainLyrics = '';
  bool _isLoading = false;
  bool _hasLyrics = false;
  String _errorMessage = '';
  int _currentLineIndex = 0;
  String _currentSongKey = '';

  List<LyricsLine> get lyrics => _lyrics;
  String get plainLyrics => _plainLyrics;
  bool get isLoading => _isLoading;
  bool get hasLyrics => _hasLyrics;
  String get errorMessage => _errorMessage;
  int get currentLineIndex => _currentLineIndex;
  String get currentSongKey => _currentSongKey;

  // ───── 박자 맞추기 (노래마다 기억, +면 가사가 빨리 나옴) ─────
  int _offsetMs = 0;
  int get offsetMs => _offsetMs;

  Future<void> _loadOffset(String key) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt('lyricsOffset_$key') ?? 0;
    if (v != _offsetMs) {
      _offsetMs = v;
      notifyListeners();
    }
  }

  Future<void> nudgeOffset(int ms) async {
    _offsetMs = (_offsetMs + ms).clamp(-10000, 10000);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('lyricsOffset_$_currentSongKey', _offsetMs);
  }

  Future<void> resetOffset() async {
    _offsetMs = 0;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove('lyricsOffset_$_currentSongKey');
  }

  Future<void> fetchLyrics(String title, String artist, {String? filePath, bool force = false}) async {
    final songKey = '$title-$artist';
    _loadOffset(songKey); // 이 노래에 맞춰둔 박자 불러오기
    // ↻ 다시 찾기(force)면 이미 가져온 가사가 있어도 다시 찾기
    if (!force && songKey == _currentSongKey && (_hasLyrics || _isLoading)) return;
    _currentSongKey = songKey;
    _isLoading = true;
    _hasLyrics = false;
    _lyrics = [];
    _plainLyrics = '';
    _errorMessage = '';
    _currentLineIndex = 0;
    notifyListeners();

    try {
      if (filePath != null) {
        final lrcPath = filePath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc');
        final lrcFile = File(lrcPath);
        if (await lrcFile.exists()) {
          final content = await lrcFile.readAsString();
          _lyrics = _parseLrc(content);
          if (_lyrics.isNotEmpty) {
            _hasLyrics = true;
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }

      // [MV]·(Official…) 같은 군더더기를 떼고 검색
      final c = SongTitleCleaner.clean(title, artist);
      final url = Uri.parse(
          'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(c.artist)}&track_name=${Uri.encodeComponent(c.title)}');

      var response = await http.get(url).timeout(const Duration(seconds: 10));

      // 못 찾으면 제목만으로 한 번 더 (가수 이름이 비슷한 것 먼저, 없으면 가사 있는 첫 번째)
      if (response.statusCode == 404) {
        final s = await http
            .get(Uri.parse('https://lrclib.net/api/search?track_name=${Uri.encodeComponent(c.title)}'))
            .timeout(const Duration(seconds: 10));
        if (s.statusCode == 200) {
          final withLyrics = (jsonDecode(s.body) as List)
              .cast<Map>()
              .where((e) => ((e['syncedLyrics'] ?? e['plainLyrics']) ?? '').toString().isNotEmpty)
              .toList();
          final al = c.artist.toLowerCase();
          final hit = withLyrics.firstWhere(
            (e) {
              final n = (e['artistName'] ?? '').toString().toLowerCase();
              return n.isNotEmpty && (n.contains(al) || al.contains(n));
            },
            orElse: () => withLyrics.isNotEmpty ? withLyrics.first : <dynamic, dynamic>{},
          );
          if (hit.isNotEmpty) {
            response = http.Response(jsonEncode(hit), 200,
                headers: {'content-type': 'application/json; charset=utf-8'});
          }
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final syncedLyrics = data['syncedLyrics'] as String?;
        final plainLyrics = data['plainLyrics'] as String?;

        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          _lyrics = _parseLrc(syncedLyrics);
          _hasLyrics = true;
        } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
          _plainLyrics = plainLyrics;
          _hasLyrics = true;
        } else {
          _errorMessage = AppLocale.current?.lyricsErrorNotFound ?? '가사를 찾을 수 없습니다';
        }
      } else if (response.statusCode == 404) {
        _errorMessage = AppLocale.current?.lyricsErrorNotFound ?? '가사를 찾을 수 없습니다';
      } else {
        _errorMessage = AppLocale.current?.lyricsErrorLoadFailed ?? '가사 로딩 실패';
      }
    } catch (e) {
      _errorMessage = AppLocale.current?.lyricsErrorNetwork ?? '인터넷 연결을 확인해주세요';
      debugPrint('가사 로딩 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<LyricsLine> _parseLrc(String lrc) {
    final lines = lrc.split('\n');
    final List<LyricsLine> result = [];
    final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lines) {
      final match = timeRegex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!.padRight(3, '0'));
        final text = match.group(4)!.trim();
        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: ms,
        );
        result.add(LyricsLine(time: time, text: text));
      }
    }
    return result;
  }

  void updateCurrentLine(Duration position) {
    if (_lyrics.isEmpty) return;
    // 화면이 바뀌는 데 걸리는 만큼 0.4초 미리 + 사용자가 맞춘 만큼
    final pos = position + Duration(milliseconds: 400 + _offsetMs);
    int newIndex = 0;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= pos) {
        newIndex = i;
      } else {
        break;
      }
    }
    if (newIndex != _currentLineIndex) {
      _currentLineIndex = newIndex;
      notifyListeners();
    }
  }

  void clearLyrics() {
    _lyrics = [];
    _plainLyrics = '';
    _hasLyrics = false;
    _errorMessage = '';
    _currentLineIndex = 0;
    _currentSongKey = '';
    notifyListeners();
  }
}