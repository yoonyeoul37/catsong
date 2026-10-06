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
  const LookupResult(this.title, this.artist, this.album, this.artUrl, this.thumbUrl);
}

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
      if (title.isEmpty || art.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue; // 같은 것 빼기
      out.add(LookupResult(title, artist, album, art, thumb));
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
      if (title.isEmpty || small.isEmpty) continue;
      if (!seen.add('$title|$artist|$album')) continue;
      out.add(LookupResult(title, artist, album, small.replaceAll('100x100bb', '600x600bb'), small));
    }
    debugPrint('곡 찾기 결과(애플): ${out.length}개');
    return out;
  } catch (e) {
    debugPrint('곡 찾기 오류(애플): $e');
    return [];
  }
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