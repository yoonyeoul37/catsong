import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../l10n/locale_holder.dart';

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

  Future<void> fetchLyrics(String title, String artist, {String? filePath}) async {
    final songKey = '$title-$artist';
    if (songKey == _currentSongKey && (_hasLyrics || _isLoading)) return;
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

      final url = Uri.parse(
          'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(artist)}&track_name=${Uri.encodeComponent(title)}');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

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
    int newIndex = 0;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time <= position) {
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