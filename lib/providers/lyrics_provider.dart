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

  // ───── 직접 넣은 가사 (노래마다 저장, 인터넷 가사보다 먼저) ─────
  bool _manual = false;
  bool get hasManual => _manual;

  /// 고치기 창에 넣을 지금 가사 (시간 있는 가사는 [00:12.34] 모양 그대로)
  String get editableText {
    if (_lyrics.isNotEmpty && !isEstimated) {
      String two(int n) => n.toString().padLeft(2, '0');
      return _lyrics.map((l) {
        final t = l.time;
        return '[${two(t.inMinutes)}:${two(t.inSeconds % 60)}.${two((t.inMilliseconds % 1000) ~/ 10)}]${l.text}';
      }).join('\n');
    }
    return _plainLyrics;
  }

  // ───── 시간 없는 가사 → 노래 길이로 시간표를 짐작해서 만들기 (대충 맞춤) ─────
  String _estimatedFor = '';
  bool get isEstimated => _estimatedFor.isNotEmpty && _estimatedFor == _currentSongKey;

  void ensureEstimated(Duration duration) {
    if (_lyrics.isNotEmpty || _plainLyrics.trim().isEmpty) return;
    final total = duration.inMilliseconds;
    if (total < 20000) return; // 노래 길이를 아직 모르면 다음에
    // 줄 나누기 (빈 줄 여러 개는 하나로)
    final lines = <String>[];
    for (final l in _plainLyrics.replaceAll('\r', '').split('\n').map((s) => s.trim())) {
      if (l.isEmpty && (lines.isEmpty || lines.last.isEmpty)) continue;
      lines.add(l);
    }
    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    if (lines.isEmpty) return;
    // 전주(앞 10%)·끝(8%) 빼고, 글자 수 비율대로 나누기 (빈 줄은 간주로 조금 쉼)
    final start = (total * 0.10).clamp(5000, 25000).toDouble();
    final end = total * 0.92;
    final weights = [for (final l in lines) l.isEmpty ? 6.0 : (l.length < 4 ? 4.0 : l.length.toDouble())];
    final sum = weights.fold<double>(0, (a, b) => a + b);
    var t = start;
    final out = <LyricsLine>[];
    for (var i = 0; i < lines.length; i++) {
      out.add(LyricsLine(time: Duration(milliseconds: t.round()), text: lines[i]));
      t += (end - start) * weights[i] / sum;
    }
    _lyrics = out;
    _estimatedFor = _currentSongKey;
  }

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
    _manual = false;
    notifyListeners();

    try {
      // ⓪ 직접 넣은 가사가 있으면 제일 먼저
      final manual = await _readManual(songKey);
      if (manual != null && _applyText(manual)) {
        _manual = true;
        return;
      }

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

      // 한국 가수·한글 제목이면 한글 가사만 (로마자 발음 가사는 안 씀)
      final wantHangul = _hangul.hasMatch(c.title) || _hangul.hasMatch(c.artist);

      // ① 전에 찾아둔 가사가 있으면 인터넷 없이 바로 (↻ 다시 찾기면 새로 찾기)
      if (!force) {
        final cached = await _readCache(songKey);
        final cachedText = (cached?['syncedLyrics'] ?? cached?['plainLyrics'] ?? '').toString();
        // 예전에 저장된 로마자 가사는 버리고 새로 찾기
        if (cached != null && !(wantHangul && _looksRomanized(cachedText)) && _applyFound(cached)) return;
      }

      // ② 세 가지 방법을 동시에 찾기 (느리거나 서버가 아프면 알아서 한 번 더)
      final t = Uri.encodeComponent(c.title);
      final a = Uri.encodeComponent(c.artist);
      final res = await Future.wait([
        _getJson('https://lrclib.net/api/get?artist_name=$a&track_name=$t'),
        _getJson('https://lrclib.net/api/search?track_name=$t&artist_name=$a'),
        _getJson('https://lrclib.net/api/search?track_name=$t'),
        // 가수+제목을 통째로 검색 (영어 제목인 한국 노래도 한글 가사가 걸리게)
        _getJson('https://lrclib.net/api/search?q=${Uri.encodeComponent('${c.artist} ${c.title}')}'),
      ]);
      final cands = <Map>[];
      if (res[0] is Map) cands.add({...(res[0] as Map), '_exact': true}); // 가수+제목이 정확히 맞은 것
      for (final r in res.skip(1)) {
        if (r is List) cands.addAll(r.whereType<Map>());
      }

      // ③ 맞는 노래만 골라서 제일 잘 맞는 것 (엉뚱한 노래 막기 · 한글 노래는 한글 가사 먼저)
      final best = _pickBest(c.title, c.artist, cands);
      if (best != null && _applyFound(best)) {
        _saveCache(songKey, best);
      } else if (res.every((r) => r == null)) {
        _errorMessage = AppLocale.current?.lyricsErrorNetwork ?? '인터넷 연결을 확인해주세요';
      } else {
        _errorMessage = AppLocale.current?.lyricsErrorNotFound ?? '가사를 찾을 수 없습니다';
      }
    } catch (e) {
      _errorMessage = AppLocale.current?.lyricsErrorNetwork ?? '인터넷 연결을 확인해주세요';
      debugPrint('가사 로딩 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────── 가사 찾기 도우미 ─────────
  static final _hangul = RegExp(r'[가-힣]');

  /// 한국 노래를 영어 발음으로 적은 가사인지 ("nan haengbok-hae" 같은)
  /// 로마자 한국어는 eo·eu·ae가 아주 많이 나오고, 진짜 영어 가사는 거의 안 나와요
  static final _romaHint = RegExp(r'eo|eu|ae');
  static const _romaWords = {
    'nan', 'neol', 'nae', 'neo', 'naega', 'geu', 'uri', 'sarang', 'maeum', 'haengbok',
    'dasi', 'hana', 'ani', 'gatchi', 'neoui', 'naui', 'eopseo', 'isseo', 'jigeum', 'oneul',
  };
  bool _looksRomanized(String text) {
    if (text.isEmpty || _hangul.hasMatch(text)) return false;
    final body = text.replaceAll(RegExp(r'\[[^\]]*\]'), ' ').toLowerCase(); // [00:12.34] 시간 빼기
    final words = RegExp(r'[a-z]+').allMatches(body).map((m) => m.group(0)!).toList();
    if (words.length < 20) return false;
    final hits = words.where((w) => _romaWords.contains(w) || _romaHint.hasMatch(w)).length;
    return hits / words.length >= 0.15;
  }

  /// 비교용: 소문자 + 괄호 내용·기호·띄어쓰기 빼기
  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[\(\[].*?[\)\]]'), '')
      .replaceAll(RegExp(r'[^0-9a-z가-힣ぁ-んァ-ン一-龥]'), '');

  /// 인터넷에서 받아오기 — 실패하면 1초 쉬고 한 번 더. 못 받으면 null, 없으면 빈 목록
  Future<dynamic> _getJson(String url) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
        if (r.statusCode == 404) return <dynamic>[];
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  /// 후보 중에서 제일 잘 맞는 가사 고르기 (맞는 게 없으면 null — 엉뚱한 가사보다 "못 찾음"이 나아서)
  Map? _pickBest(String title, String artist, List<Map> cands) {
    final nt = _norm(title), na = _norm(artist);
    final artistUnknown =
        na.isEmpty || artist.contains('알 수 없') || na.contains('unknown') || na.contains('various');
    final wantHangul = _hangul.hasMatch(title) || _hangul.hasMatch(artist);
    Map? best;
    var bestScore = -999999;
    // 제목이 똑같은 후보들의 가수 목록 (한 명뿐이면 그 노래가 거의 확실)
    final exactArtists = <String>{
      for (final m in cands)
        if (_norm((m['trackName'] ?? '').toString()) == nt &&
            ((m['syncedLyrics'] ?? m['plainLyrics'] ?? '').toString().trim().isNotEmpty))
          _norm((m['artistName'] ?? '').toString()),
    };
    final seen = <String>{};
    for (final m in cands) {
      final synced = (m['syncedLyrics'] ?? '').toString();
      final plain = (m['plainLyrics'] ?? '').toString();
      final text = synced.trim().isNotEmpty ? synced : plain;
      if (text.trim().isEmpty) continue;
      if (!seen.add('${m['id']}|${m['trackName']}|${m['artistName']}')) continue;
      final ct = _norm((m['trackName'] ?? '').toString());
      final ca = _norm((m['artistName'] ?? '').toString());
      final exact = m['_exact'] == true;
      final artistOk = exact || (!artistUnknown && ca.isNotEmpty && (ca.contains(na) || na.contains(ca)));
      final titleOk = exact || (ct.isNotEmpty && (ct == nt || ct.contains(nt) || nt.contains(ct)));
      // 엉뚱한 노래 막기: 가수·제목이 맞아야 함 (가수를 모르면 제목이 똑같아야)
      // 유튜브 곡처럼 가수 칸이 채널 이름이어도: 제목이 똑같은 노래가 한 가수 것뿐이면 인정
      final onlyOneSong = ct == nt && exactArtists.length == 1;
      if (!(artistOk && titleOk) && !(artistUnknown && ct == nt) && !onlyOneSong) continue;
      // 한국 노래인데 영어 발음(로마자)으로 적은 가사면 아예 안 씀
      if (wantHangul && _looksRomanized(text)) continue;
      var score = 0;
      if (exact) score += 20;
      if (artistOk) score += 50;
      if (ct == nt) score += 20;
      if (synced.trim().isNotEmpty) score += 45; // 시간 있는 가사를 훨씬 먼저 (지금 부르는 줄 보여주기)
      if (wantHangul) score += _hangul.hasMatch(text) ? 30 : -40; // 한글 노래는 한글 가사 먼저 (로마자 피하기)
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  /// 고른 가사를 화면용으로 넣기
  bool _applyFound(Map m) {
    final synced = (m['syncedLyrics'] ?? '').toString();
    final plain = (m['plainLyrics'] ?? '').toString();
    if (synced.trim().isNotEmpty) {
      final parsed = _parseLrc(synced);
      if (parsed.isNotEmpty) {
        _lyrics = parsed;
        _hasLyrics = true;
        return true;
      }
    }
    if (plain.trim().isNotEmpty) {
      _plainLyrics = plain;
      _hasLyrics = true;
      return true;
    }
    return false;
  }

  /// 글 하나를 가사로 넣기 ([00:12] 같은 시간이 있으면 노래에 맞춰 나오는 가사)
  bool _applyText(String text) {
    final isLrc = RegExp(r'\[\d{1,2}:\d{2}').hasMatch(text);
    return _applyFound(isLrc ? {'syncedLyrics': text, 'plainLyrics': text} : {'plainLyrics': text});
  }

  Future<String?> _readManual(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('lyricsManual_$key');
      return (s == null || s.trim().isEmpty) ? null : s;
    } catch (_) {
      return null;
    }
  }

  /// 직접 넣은 가사 저장 → 바로 화면에
  Future<void> saveManualLyrics(String title, String artist, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final key = '$title-$artist';
    final p = await SharedPreferences.getInstance();
    await p.setString('lyricsManual_$key', t);
    _currentSongKey = key;
    _lyrics = [];
    _plainLyrics = '';
    _estimatedFor = '';
    _errorMessage = '';
    _currentLineIndex = 0;
    _isLoading = false;
    _hasLyrics = false;
    _manual = _applyText(t);
    notifyListeners();
  }

  /// 직접 넣은 가사 지우기 → 인터넷에서 다시 찾기
  Future<void> deleteManualLyrics(String title, String artist, {String? filePath}) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('lyricsManual_$title-$artist');
    _manual = false;
    _estimatedFor = '';
    await fetchLyrics(title, artist, filePath: filePath, force: true);
  }

  /// 찾은 가사는 폰에 저장 → 다음엔 인터넷 없이 바로
  Future<void> _saveCache(String key, Map m) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('lyricsCache2_$key',
          jsonEncode({'syncedLyrics': m['syncedLyrics'], 'plainLyrics': m['plainLyrics']}));
    } catch (_) {}
  }

  Future<Map?> _readCache(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('lyricsCache2_$key');
      return s == null ? null : jsonDecode(s) as Map;
    } catch (_) {
      return null;
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
    int newIndex = -1; // 첫 줄 시간 전(전주)에는 아무 줄도 아님
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