# 파란소리: 가사 한 번에 찾기 (동시 검색·자동 재시도·폰에 저장) + 엉뚱한 가사 막기 + 한글 가사 먼저
# 실행: C:\apps\mp3_player_new 에서  python apply_lyrics_fetch.py
import os, sys, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass
ROOT = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(ROOT, "lib", "providers", "lyrics_provider.dart")
if not os.path.exists(P):
    print("[실패] lib/providers/lyrics_provider.dart 를 못 찾았어요.")
    sys.exit(1)
with open(P, "r", encoding="utf-8", newline="") as f:
    raw = f.read()
nl = "\r\n" if "\r\n" in raw else "\n"
s = raw.replace("\r\n", "\n")
if "_pickBest(" in s:
    print("[참고] 이미 바뀌어 있어요. 그대로 둘게요.")
    sys.exit(0)
BLOCK = r"""      // [MV]·(Official…) 같은 군더더기를 떼고 검색
      final c = SongTitleCleaner.clean(title, artist);

      // ① 전에 찾아둔 가사가 있으면 인터넷 없이 바로 (↻ 다시 찾기면 새로 찾기)
      if (!force) {
        final cached = await _readCache(songKey);
        if (cached != null && _applyFound(cached)) return;
      }

      // ② 세 가지 방법을 동시에 찾기 (느리거나 서버가 아프면 알아서 한 번 더)
      final t = Uri.encodeComponent(c.title);
      final a = Uri.encodeComponent(c.artist);
      final res = await Future.wait([
        _getJson('https://lrclib.net/api/get?artist_name=$a&track_name=$t'),
        _getJson('https://lrclib.net/api/search?track_name=$t&artist_name=$a'),
        _getJson('https://lrclib.net/api/search?track_name=$t'),
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
"""
HELPERS = r"""  // ───────── 가사 찾기 도우미 ─────────
  static final _hangul = RegExp(r'[가-힣]');

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
      if (!(artistOk && titleOk) && !(artistUnknown && ct == nt)) continue;
      var score = 0;
      if (exact) score += 60;
      if (artistOk) score += 50;
      if (ct == nt) score += 20;
      if (synced.trim().isNotEmpty) score += 10;
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

  /// 찾은 가사는 폰에 저장 → 다음엔 인터넷 없이 바로
  Future<void> _saveCache(String key, Map m) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('lyricsCache_$key',
          jsonEncode({'syncedLyrics': m['syncedLyrics'], 'plainLyrics': m['plainLyrics']}));
    } catch (_) {}
  }

  Future<Map?> _readCache(String key) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('lyricsCache_$key');
      return s == null ? null : jsonDecode(s) as Map;
    } catch (_) {
      return null;
    }
  }

"""
START = "      // [MV]·(Official…) 같은 군더더기를 떼고 검색"
END = "    } catch (e) {"
i = s.find(START)
j = s.find(END, i) if i >= 0 else -1
k = s.find("  List<LyricsLine> _parseLrc(String lrc) {")
if i < 0 or j < 0 or k < 0:
    print("[실패] 바꿀 곳을 못 찾아서 아무것도 안 바꿨어요. 이 메시지를 보내주세요.")
    sys.exit(1)
# 다시 찾기(force)가 없으면 같이 넣기
if "bool force" not in s:
    old = "Future<void> fetchLyrics(String title, String artist, {String? filePath}) async {"
    if old not in s:
        print("[실패] fetchLyrics 줄을 못 찾았어요. 이 메시지를 보내주세요.")
        sys.exit(1)
    s = s.replace(old, "Future<void> fetchLyrics(String title, String artist, {String? filePath, bool force = false}) async {")
    s = s.replace("if (songKey == _currentSongKey && (_hasLyrics || _isLoading)) return;",
                  "if (!force && songKey == _currentSongKey && (_hasLyrics || _isLoading)) return;")
    i = s.find(START); j = s.find(END, i); k = s.find("  List<LyricsLine> _parseLrc(String lrc) {")
if "shared_preferences.dart" not in s:
    s = s.replace("import 'package:http/http.dart' as http;\n",
                  "import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';\n", 1)
    i = s.find(START); j = s.find(END, i); k = s.find("  List<LyricsLine> _parseLrc(String lrc) {")
s = s[:i] + BLOCK + s[j:]
k = s.find("  List<LyricsLine> _parseLrc(String lrc) {")
s = s[:k] + HELPERS + s[k:]
B = os.path.join(ROOT, "backup_lyrics_fetch", "providers")
os.makedirs(B, exist_ok=True)
shutil.copy2(P, os.path.join(B, "lyrics_provider.dart"))
with open(P, "w", encoding="utf-8", newline="") as f:
    f.write(s.replace("\n", nl) if nl == "\r\n" else s)
print("[완료] 바꿨어요: providers/lyrics_provider.dart")
print("\n[끝] 끝! 이제  flutter run  으로 확인해 주세요.")
print("   문제가 있으면 backup_lyrics_fetch 폴더의 원본으로 되돌릴 수 있어요.")
