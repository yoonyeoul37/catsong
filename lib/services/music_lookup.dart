import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// 인터넷에서 찾은 곡 정보
class LookupResult {
  final String title;
  final String artist;
  final String album;
  final String artUrl; // 앨범 사진 (큰 사이즈)
  final String thumbUrl; // 목록에 보여줄 작은 사진
  final int durationSec; // 노래 길이 (한글 제목 찾을 때 씀)
  final String? origTitle; // 한글로 바꿨으면 원래 영어 제목
  final String? origArtist; // 한글로 바꿨으면 원래 영어 가수 이름
  const LookupResult(this.title, this.artist, this.album, this.artUrl, this.thumbUrl,
      {this.durationSec = 0, this.origTitle, this.origArtist});

  bool get koreanized => origTitle != null || origArtist != null;
}

final _hangul = RegExp(r'[가-힣]');

/// 제목·가수로 곡 찾기
/// 1) 디저(한국 노래 많음) → 2) 못 찾으면 애플(미국 스토어) → 3) 그래도 없으면 제목만으로 다시
Future<List<LookupResult>> lookupSong(String title, String artist) async {
  final t = title.trim();
  final a = artist.trim();
  final unknown = a.isEmpty || a.contains('알 수 없') || a.toLowerCase().contains('unknown');
  final term = unknown ? t : '$a $t';

  var list = await _deezer(term);
  if (list.isEmpty) list = await _itunes(term);
  if (list.isEmpty && !unknown) {
    list = await _deezer(t);
    if (list.isEmpty) list = await _itunes(t);
  }
  return list;
}

/// 디저 검색 (가입·키 필요 없음)
Future<List<LookupResult>> _deezer(String term) async {
  if (term.isEmpty) return [];
  try {
    final url = Uri.parse('https://api.deezer.com/search?q=${Uri.encodeQueryComponent(term)}&limit=8');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    debugPrint('곡 찾기(디저): "$term" → ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
    final out = <LookupResult>[];
    final seen = <String>{};
    for (final r in (data['data'] as List? ?? []).cast<Map>()) {
      final title = (r['title'] ?? '').toString();
      final artist = ((r['artist'] as Map?)?['name'] ?? '').toString();
      final albumMap = (r['album'] as Map?) ?? {};
      final album = (albumMap['title'] ?? '').toString();
      final art = (albumMap['cover_xl'] ?? albumMap['cover_big'] ?? '').toString();
      final thumb = (albumMap['cover_medium'] ?? art).toString();
      final dur = (r['duration'] is num) ? (r['duration'] as num).toInt() : 0;
      if (title.isEmpty || art.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue; // 같은 것 빼기
      out.add(LookupResult(title, artist, album, art, thumb, durationSec: dur));
    }
    debugPrint('곡 찾기 결과(디저): ${out.length}개');
    return out;
  } catch (e) {
    debugPrint('곡 찾기 오류(디저): $e');
    return [];
  }
}

/// 애플 검색 (한국 스토어는 노래 판매가 없어서 미국 스토어로)
Future<List<LookupResult>> _itunes(String term) async {
  if (term.isEmpty) return [];
  try {
    final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeQueryComponent(term)}&entity=song&country=US&limit=8');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    debugPrint('곡 찾기(애플): "$term" → ${res.statusCode}');
    if (res.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map;
    final out = <LookupResult>[];
    final seen = <String>{};
    for (final r in (data['results'] as List? ?? []).cast<Map>()) {
      final title = (r['trackName'] ?? '').toString();
      final artist = (r['artistName'] ?? '').toString();
      final album = (r['collectionName'] ?? '').toString();
      final small = (r['artworkUrl100'] ?? '').toString();
      final dur = (r['trackTimeMillis'] is num) ? (r['trackTimeMillis'] as num).toInt() ~/ 1000 : 0;
      if (title.isEmpty || small.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue;
      out.add(LookupResult(title, artist, album, small.replaceAll('100x100bb', '600x600bb'), small,
          durationSec: dur));
    }
    debugPrint('곡 찾기 결과(애플): ${out.length}개');
    return out;
  } catch (e) {
    debugPrint('곡 찾기 오류(애플): $e');
    return [];
  }
}

// ───────── 뮤직브레인즈: 영어로 된 한국 가수·제목 → 한글 ─────────
// 무료라 1초에 한 번만 물어볼 수 있어서 순서대로 천천히

DateTime _mbLast = DateTime(2000);

Future<Map?> _mbGet(String url) async {
  final wait = 1100 - DateTime.now().difference(_mbLast).inMilliseconds;
  if (wait > 0) await Future.delayed(Duration(milliseconds: wait));
  _mbLast = DateTime.now();
  try {
    final res = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Paransori/1.0 (info@knexm.com)', // 뮤직브레인즈는 이름표가 필요해요
    }).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
  } catch (e) {
    debugPrint('뮤직브레인즈 오류: $e');
    return null;
  }
}

/// 영어 가수 이름 → (한글 이름, 뮤직브레인즈 번호). 못 찾으면 (null, null)
Future<(String?, String?)> _mbArtist(String latin) async {
  final name = latin.trim();
  if (name.isEmpty) return (null, null);
  final q = Uri.encodeQueryComponent('artist:"$name" OR alias:"$name"');
  final data = await _mbGet('https://musicbrainz.org/ws/2/artist/?query=$q&fmt=json&limit=5');
  if (data == null) return (null, null);
  for (final a in (data['artists'] as List? ?? []).cast<Map>()) {
    if ((a['score'] ?? 0) < 85) continue; // 이름이 거의 같은 사람만
    final id = (a['id'] ?? '').toString();
    final n = (a['name'] ?? '').toString();
    if (_hangul.hasMatch(n)) return (n, id);
    for (final al in (a['aliases'] as List? ?? []).cast<Map>()) {
      final an = (al['name'] ?? '').toString();
      if (_hangul.hasMatch(an)) return (an, id);
    }
    return (null, id); // 같은 사람인데 한글 이름이 없음
  }
  return (null, null);
}

/// 영어로 된 한국 가수 이름 → 한글 이름 (Kim Hyun Sik → 김현식). 못 찾으면 null
Future<String?> koreanArtistName(String latin) async {
  if (_hangul.hasMatch(latin)) return null;
  final (ko, _) = await _mbArtist(latin);
  return ko;
}

/// 그 가수의 노래 중 길이가 같은 노래의 한글 제목 찾기 (Like Rain, Like Music → 비처럼 음악처럼)
Future<String?> _mbKoreanTitle(String artistId, int durationSec) async {
  if (artistId.isEmpty || durationSec <= 0) return null;
  final lo = (durationSec - 3) * 1000, hi = (durationSec + 3) * 1000;
  final q = Uri.encodeQueryComponent('arid:$artistId AND dur:[$lo TO $hi]');
  final data = await _mbGet('https://musicbrainz.org/ws/2/recording/?query=$q&fmt=json&limit=10');
  if (data == null) return null;
  for (final r in (data['recordings'] as List? ?? []).cast<Map>()) {
    final t = (r['title'] ?? '').toString();
    if (_hangul.hasMatch(t)) return t;
  }
  return null;
}

/// 찾은 곡의 가수·제목이 영어면 한글로 바꾼 것 (못 바꾸면 그대로)
Future<LookupResult> koreanize(LookupResult r) async {
  if (_hangul.hasMatch(r.title) && _hangul.hasMatch(r.artist)) return r; // 이미 한글
  var t = r.title, a = r.artist;
  String? artistId;
  if (!_hangul.hasMatch(a)) {
    final (ko, id) = await _mbArtist(a);
    artistId = id;
    if (ko != null) a = ko;
  }
  // 한국 가수일 때만 제목도 찾아보기 (외국 노래는 그대로)
  if (!_hangul.hasMatch(t) && _hangul.hasMatch(a) && artistId != null) {
    final kt = await _mbKoreanTitle(artistId, r.durationSec);
    if (kt != null) t = kt;
  }
  if (t == r.title && a == r.artist) return r;
  return LookupResult(t, a, r.album, r.artUrl, r.thumbUrl,
      durationSec: r.durationSec,
      origTitle: t != r.title ? r.title : null,
      origArtist: a != r.artist ? r.artist : null);
}

/// 앨범 사진 받아오기
Future<List<int>?> downloadArt(String url) async {
  try {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    return res.statusCode == 200 ? res.bodyBytes : null;
  } catch (_) {
    return null;
  }
}
