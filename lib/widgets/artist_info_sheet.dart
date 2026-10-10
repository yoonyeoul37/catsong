import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song.dart';
import '../providers/theme_provider.dart';

/// 재생 화면: 가수 이름 누르기 / 위로 밀기 → 가수·곡 정보 카드
/// 정보: Deezer(곡·앨범·가수 사진) · MusicBrainz(작사·작곡, 결성) · Wikipedia(소개)
/// 찾은 정보는 폰에 30일 저장 → 다음엔 바로 떠요
Future<void> showArtistInfo(BuildContext context, Song song) async {
  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => _ArtistInfoBody(song: song, scroll: scroll),
    ),
  );
}

// ───────────────────────── 정보 모음 ─────────────────────────

class _Album {
  final String title;
  final String cover;
  final String year;
  final String kind; // 앨범 · 싱글 · EP
  _Album(this.title, this.cover, this.year, this.kind);
  Map<String, dynamic> toJson() => {'t': title, 'c': cover, 'y': year, 'k': kind};
  static _Album fromJson(Map m) =>
      _Album('${m['t'] ?? ''}', '${m['c'] ?? ''}', '${m['y'] ?? ''}', '${m['k'] ?? ''}');
}

class _Info {
  String artist = '';
  String? picture; // 가수 사진
  String? type; // 솔로 · 그룹
  String? country;
  String? formed; // 그룹 결성 연도
  String? genre;
  int? albumCount;
  String? bio;
  String? bioUrl;
  bool bioTranslated = false; // 영어 소개를 자동 번역했는지
  String? album; // 이 곡이 실린 앨범
  String? albumCover;
  String? release; // 2019-07-12
  int? trackNo;
  Map<String, List<String>> credits = {}; // 작사 · 작곡 · 편곡 ...
  bool creditsDone = false;
  List<_Album> albums = [];

  bool get empty => picture == null && album == null && bio == null && albums.isEmpty && type == null;

  /// 가장 오래된 앨범 연도 (첫 앨범)
  String? get firstYear {
    final ys = albums.map((a) => a.year).where((y) => y.length == 4).toList()..sort();
    return ys.isEmpty ? null : ys.first;
  }

  Map<String, dynamic> toJson() => {
        'artist': artist,
        'picture': picture,
        'type': type,
        'country': country,
        'formed': formed,
        'genre': genre,
        'albumCount': albumCount,
        'bio': bio,
        'bioUrl': bioUrl,
        'bioTranslated': bioTranslated,
        'album': album,
        'albumCover': albumCover,
        'release': release,
        'trackNo': trackNo,
        'credits': credits,
        'creditsDone': creditsDone,
        'albums': albums.map((a) => a.toJson()).toList(),
      };

  static _Info fromJson(Map m) {
    final i = _Info()
      ..artist = '${m['artist'] ?? ''}'
      ..picture = m['picture'] as String?
      ..type = m['type'] as String?
      ..country = m['country'] as String?
      ..formed = m['formed'] as String?
      ..genre = m['genre'] as String?
      ..albumCount = (m['albumCount'] as num?)?.toInt()
      ..bio = m['bio'] as String?
      ..bioUrl = m['bioUrl'] as String?
      ..bioTranslated = m['bioTranslated'] == true
      ..album = m['album'] as String?
      ..albumCover = m['albumCover'] as String?
      ..release = m['release'] as String?
      ..trackNo = (m['trackNo'] as num?)?.toInt()
      ..creditsDone = m['creditsDone'] == true;
    final c = m['credits'];
    if (c is Map) {
      c.forEach((k, v) {
        if (v is List) i.credits['$k'] = v.map((e) => '$e').toList();
      });
    }
    final al = m['albums'];
    if (al is List) i.albums = al.whereType<Map>().map(_Album.fromJson).toList();
    return i;
  }
}

class _ArtistApi {
  static const _ua = {'User-Agent': 'Paransori/1.0 (info@knexm.com)', 'Accept': 'application/json'};
  static final _music = RegExp(
      r'가수|밴드|그룹|음악|작곡|래퍼|보컬|싱어|듀오|아이돌|singer|band|musician|rapper|group|duo|composer|songwriter|DJ|producer|vocalist|idol',
      caseSensitive: false);

  static Future<Map?> _get(String url) async {
    try {
      final r = await http.get(Uri.parse(url), headers: _ua).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      return d is Map ? d : null;
    } catch (_) {
      return null;
    }
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s\(\)\[\]\-_.,·!?~]'), '');

  static bool _sameArtist(String a, String b) {
    final x = _norm(a), y = _norm(b);
    if (x.isEmpty || y.isEmpty) return false;
    return x == y || x.contains(y) || y.contains(x);
  }

  // ── Deezer: 곡 · 앨범 · 가수 사진 · 앨범 목록 ──
  static Future<void> deezer(_Info info, String title, String artist) async {
    final q1 = 'artist:"$artist" track:"$title"';
    var s = await _get('https://api.deezer.com/search?limit=8&q=${Uri.encodeQueryComponent(q1)}');
    var list = (s?['data'] as List?)?.whereType<Map>().toList() ?? [];
    if (list.isEmpty) {
      s = await _get('https://api.deezer.com/search?limit=8&q=${Uri.encodeQueryComponent('$artist $title')}');
      list = (s?['data'] as List?)?.whereType<Map>().toList() ?? [];
    }
    Map? hit;
    for (final t in list) {
      final an = '${(t['artist'] as Map?)?['name'] ?? ''}';
      if (_sameArtist(an, artist)) {
        hit = t;
        break;
      }
    }
    int? artistId;
    if (hit != null) {
      final track = await _get('https://api.deezer.com/track/${hit['id']}');
      if (track != null) {
        final al = track['album'] as Map?;
        info.album = (al?['title'] as String?)?.trim();
        info.albumCover = al?['cover_xl'] as String? ?? al?['cover_big'] as String?;
        final rd = '${track['release_date'] ?? al?['release_date'] ?? ''}';
        if (rd.length >= 10 && !rd.startsWith('0000')) info.release = rd.substring(0, 10);
        final tp = track['track_position'];
        if (tp is num && tp > 0) info.trackNo = tp.toInt();
        artistId = ((track['artist'] as Map?)?['id'] as num?)?.toInt();
        final albumId = (al?['id'] as num?)?.toInt();
        if (albumId != null) {
          final album = await _get('https://api.deezer.com/album/$albumId');
          final g = ((album?['genres'] as Map?)?['data'] as List?)?.whereType<Map>().toList();
          if (g != null && g.isNotEmpty) info.genre = '${g.first['name']}';
        }
      }
    } else {
      // 곡은 못 찾아도 가수는 찾아보기
      final a = await _get('https://api.deezer.com/search/artist?limit=5&q=${Uri.encodeQueryComponent(artist)}');
      for (final x in (a?['data'] as List?)?.whereType<Map>() ?? const <Map>[]) {
        if (_sameArtist('${x['name'] ?? ''}', artist)) {
          artistId = (x['id'] as num?)?.toInt();
          break;
        }
      }
    }
    if (artistId == null) return;
    final ar = await _get('https://api.deezer.com/artist/$artistId');
    if (ar != null) {
      final pic = ar['picture_xl'] as String? ?? ar['picture_big'] as String?;
      // 디저 기본 그림(사진 없음)은 빼기
      if (pic != null && !pic.contains('/artist//')) info.picture = pic;
      final n = ar['nb_album'];
      if (n is num && n > 0) info.albumCount = n.toInt();
      final name = '${ar['name'] ?? ''}'.trim();
      if (name.isNotEmpty) info.artist = name;
    }
    final als = await _get('https://api.deezer.com/artist/$artistId/albums?limit=60');
    final seen = <String>{};
    final out = <_Album>[];
    for (final x in (als?['data'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      final t = '${x['title'] ?? ''}'.trim();
      if (t.isEmpty || !seen.add(_norm(t))) continue;
      final rd = '${x['release_date'] ?? ''}';
      final kind = switch ('${x['record_type'] ?? ''}') {
        'album' => '앨범',
        'single' => '싱글',
        'ep' => 'EP',
        'compile' => '모음집',
        _ => '',
      };
      out.add(_Album(t, '${x['cover_medium'] ?? x['cover'] ?? ''}', rd.length >= 4 ? rd.substring(0, 4) : '', kind));
    }
    out.sort((a, b) => b.year.compareTo(a.year)); // 최신 앨범부터
    info.albums = out.take(15).toList();
  }

  static String _normAlbum(String s) => _norm(s
      .replaceAll(RegExp(r'\s*[\(\[].*?[\)\]]'), '')
      .replaceAll(RegExp(r'\s+-\s+(single|ep)$', caseSensitive: false), ''));

  /// 앨범 더 찾기: 애플(한국 스토어) + 뮤직브레인즈 → 디저 목록에 없는 것만 더하기
  static Future<void> moreAlbums(_Info info, String artist) async {
    final seen = info.albums.map((a) => _normAlbum(a.title)).toSet();
    final more = <_Album>[];
    void add(String title, String cover, String date, String kind) {
      final t = title.replaceAll(RegExp(r'\s+-\s+(Single|EP)$'), '').trim();
      final k = _normAlbum(t);
      if (t.isEmpty || k.isEmpty || !seen.add(k)) return;
      more.add(_Album(t, cover, date.length >= 4 ? date.substring(0, 4) : '', kind));
    }

    // 애플 (한국 스토어: 옛날 한국 앨범이 많아요)
    final s = await _get('https://itunes.apple.com/search?entity=musicArtist&country=KR&limit=5'
        '&term=${Uri.encodeQueryComponent(artist)}');
    int? appleId;
    for (final a in (s?['results'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      if (_sameArtist('${a['artistName'] ?? ''}', artist)) {
        appleId = (a['artistId'] as num?)?.toInt();
        break;
      }
    }
    if (appleId != null) {
      final l = await _get('https://itunes.apple.com/lookup?id=$appleId&entity=album&country=KR&limit=200');
      for (final c in (l?['results'] as List?)?.whereType<Map>() ?? const <Map>[]) {
        if (c['wrapperType'] != 'collection') continue;
        final name = '${c['collectionName'] ?? ''}';
        final n = (c['trackCount'] as num?)?.toInt() ?? 0;
        final kind = name.endsWith(' - Single') || (n > 0 && n <= 3)
            ? '싱글'
            : name.endsWith(' - EP')
                ? 'EP'
                : '앨범';
        add(name, '${c['artworkUrl100'] ?? ''}'.replaceAll('100x100bb', '300x300bb'), '${c['releaseDate'] ?? ''}',
            kind);
      }
    }

    // 뮤직브레인즈 (1초에 한 번만)
    await Future.delayed(const Duration(milliseconds: 1100));
    final q = Uri.encodeQueryComponent('artist:"$artist"');
    final m = await _get('https://musicbrainz.org/ws/2/release-group?query=$q&fmt=json&limit=60');
    for (final g in (m?['release-groups'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      if (((g['score'] as num?) ?? 0) < 80) continue;
      final credit = ((g['artist-credit'] as List?)?.whereType<Map>() ?? const <Map>[])
          .map((x) => '${x['name'] ?? (x['artist'] as Map?)?['name'] ?? ''}')
          .join(' ');
      if (!_sameArtist(credit, artist)) continue;
      final pt = '${g['primary-type'] ?? ''}';
      final st = ((g['secondary-types'] as List?) ?? const []).map((e) => '$e').toList();
      final kind = st.contains('Compilation')
          ? '모음집'
          : st.contains('Live')
              ? '라이브'
              : pt == 'Single'
                  ? '싱글'
                  : pt == 'EP'
                      ? 'EP'
                      : '앨범';
      add('${g['title'] ?? ''}', 'https://coverartarchive.org/release-group/${g['id']}/front-250',
          '${g['first-release-date'] ?? ''}', kind);
    }

    if (more.isEmpty) return;
    final all = [...info.albums, ...more]..sort((a, b) => b.year.compareTo(a.year)); // 최신부터
    info.albums = all.take(40).toList();
    if ((info.albumCount ?? 0) < info.albums.length) info.albumCount = info.albums.length;
  }

  // ── Wikipedia: 짧은 소개 ──
  static Future<Map?> _wikiSummary(String lang, String title, {bool check = true}) async {
    final d = await _get('https://$lang.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}');
    if (d == null || d['type'] != 'standard') return null;
    final text = '${d['extract'] ?? ''}'.trim();
    if (text.isEmpty) return null;
    if (check && !_music.hasMatch('${d['description'] ?? ''} $text')) return null; // 가수 문서가 아니면 건너뛰기
    return d;
  }

  static void _useWiki(_Info info, Map d) {
    info.bio = '${d['extract'] ?? ''}'.trim();
    info.bioUrl = ((d['content_urls'] as Map?)?['mobile'] as Map?)?['page'] as String?;
    info.picture ??= (d['thumbnail'] as Map?)?['source'] as String?;
  }

  /// 소개: ① 폰 언어 문서 → ② 영어 문서에 연결된 폰 언어 문서 → ③ 영어 소개를 자동 번역
  static Future<void> wiki(_Info info, String artist, String lang) async {
    final mine = await _wikiSummary(lang, artist);
    if (mine != null) {
      _useWiki(info, mine);
      return;
    }
    final en = await _wikiSummary('en', artist);
    if (en == null) return;
    if (lang == 'en') {
      _useWiki(info, en);
      return;
    }
    // 영어 문서에 연결된 한국어(폰 언어) 문서 찾기 (예: Coldplay → 콜드플레이)
    final enTitle = '${en['title'] ?? artist}';
    final ll = await _get('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=langlinks'
        '&lllang=$lang&redirects=1&titles=${Uri.encodeQueryComponent(enTitle)}');
    String? local;
    final pages = (ll?['query'] as Map?)?['pages'] as Map?;
    for (final p in pages?.values ?? const []) {
      final links = (p is Map) ? p['langlinks'] as List? : null;
      if (links != null && links.isNotEmpty && links.first is Map) {
        local = '${(links.first as Map)['*'] ?? ''}'.trim();
        break;
      }
    }
    if (local != null && local.isNotEmpty) {
      final d = await _wikiSummary(lang, local, check: false);
      if (d != null) {
        _useWiki(info, d);
        return;
      }
    }
    // 그래도 없으면 영어 소개를 번역 (안 되면 영어 그대로)
    _useWiki(info, en);
    final t = await _translate(info.bio!, 'en', lang);
    if (t != null && t.isNotEmpty) {
      info.bio = t;
      info.bioTranslated = true;
    }
  }

  /// 무료 번역 (MyMemory) — 한 번에 500자까지라 문장 단위로 나눠서
  static Future<String?> _translate(String text, String from, String to) async {
    final parts = <String>[];
    var cur = '';
    for (final s in text.split(RegExp(r'(?<=[.!?])\s+'))) {
      if (cur.isNotEmpty && cur.length + s.length + 1 > 450) {
        parts.add(cur);
        cur = '';
      }
      cur = cur.isEmpty ? s : '$cur $s';
    }
    if (cur.isNotEmpty) parts.add(cur);
    final out = <String>[];
    for (final p in parts.take(4)) {
      final q = p.length > 480 ? p.substring(0, 480) : p;
      final d = await _get('https://api.mymemory.translated.net/get?langpair=$from%7C$to'
          '&de=info@knexm.com&q=${Uri.encodeQueryComponent(q)}');
      final status = d?['responseStatus'];
      final t = '${(d?['responseData'] as Map?)?['translatedText'] ?? ''}'.trim();
      if (t.isEmpty || (status is num && status != 200) || t.toUpperCase().contains('MYMEMORY')) return null;
      out.add(t);
    }
    return out.isEmpty ? null : out.join(' ');
  }

  // ── MusicBrainz: 솔로/그룹 · 나라 · 결성 연도 ──
  static const _countries = {
    'KR': '대한민국', 'US': '미국', 'GB': '영국', 'JP': '일본', 'CA': '캐나다', 'AU': '호주',
    'SE': '스웨덴', 'FR': '프랑스', 'DE': '독일', 'CN': '중국', 'TW': '대만', 'IE': '아일랜드',
    'NO': '노르웨이', 'NZ': '뉴질랜드', 'IT': '이탈리아', 'ES': '스페인', 'BR': '브라질', 'HK': '홍콩',
  };

  static Future<void> mbArtist(_Info info, String artist) async {
    final q = Uri.encodeQueryComponent('artist:"$artist"');
    final d = await _get('https://musicbrainz.org/ws/2/artist/?query=$q&fmt=json&limit=3');
    final list = (d?['artists'] as List?)?.whereType<Map>().toList() ?? [];
    if (list.isEmpty) return;
    final a = list.first;
    if (((a['score'] as num?) ?? 0) < 90) return;
    final t = '${a['type'] ?? ''}';
    if (t == 'Person') info.type = '솔로';
    if (t == 'Group') info.type = '그룹';
    final c = '${a['country'] ?? ''}';
    if (c.isNotEmpty) info.country = _countries[c] ?? c;
    final begin = '${(a['life-span'] as Map?)?['begin'] ?? ''}';
    if (t == 'Group' && begin.length >= 4) info.formed = begin.substring(0, 4);
  }

  // ── MusicBrainz: 작사 · 작곡 · 편곡 (있을 때만) ──
  static const _roles = {
    'lyricist': '작사',
    'composer': '작곡',
    'writer': '작사·작곡',
    'arranger': '편곡',
    'producer': '프로듀서',
  };

  static void _addRels(_Info info, List? rels) {
    for (final r in rels?.whereType<Map>() ?? const <Map>[]) {
      final role = _roles['${r['type'] ?? ''}'];
      final name = '${(r['artist'] as Map?)?['name'] ?? ''}'.trim();
      if (role == null || name.isEmpty) continue;
      final l = info.credits.putIfAbsent(role, () => []);
      if (!l.contains(name)) l.add(name);
    }
  }

  static Future<void> credits(_Info info, String title, String artist) async {
    final q = Uri.encodeQueryComponent('recording:"$title" AND artist:"$artist"');
    final s = await _get('https://musicbrainz.org/ws/2/recording/?query=$q&fmt=json&limit=3');
    final recs = (s?['recordings'] as List?)?.whereType<Map>().toList() ?? [];
    if (recs.isEmpty || ((recs.first['score'] as num?) ?? 0) < 90) return;
    await Future.delayed(const Duration(milliseconds: 1100)); // 뮤직브레인즈: 1초에 한 번만
    final rec = await _get('https://musicbrainz.org/ws/2/recording/${recs.first['id']}?inc=work-rels+artist-rels&fmt=json');
    if (rec == null) return;
    _addRels(info, rec['relations'] as List?);
    String? workId;
    for (final r in (rec['relations'] as List?)?.whereType<Map>() ?? const <Map>[]) {
      if (r['work'] is Map) {
        workId = '${(r['work'] as Map)['id']}';
        break;
      }
    }
    if (workId == null) return;
    await Future.delayed(const Duration(milliseconds: 1100));
    final work = await _get('https://musicbrainz.org/ws/2/work/$workId?inc=artist-rels&fmt=json');
    _addRels(info, work?['relations'] as List?);
  }
}

// ───────────────────────── 화면 ─────────────────────────

class _ArtistInfoBody extends StatefulWidget {
  final Song song;
  final ScrollController scroll;
  const _ArtistInfoBody({required this.song, required this.scroll});

  @override
  State<_ArtistInfoBody> createState() => _ArtistInfoBodyState();
}

class _ArtistInfoBodyState extends State<_ArtistInfoBody> {
  _Info? _info;
  bool _loading = true;
  bool _bioOpen = false;

  String get _title => widget.song.titleDisplay.trim();
  String get _artist => widget.song.artistDisplay.trim();
  bool get _unknownArtist =>
      _artist.isEmpty || _artist.contains('알 수 없') || _artist.toLowerCase().contains('unknown');
  String get _key => 'artistInfo3:${_artist.toLowerCase()}|${_title.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool fresh = false}) async {
    final lang = Localizations.localeOf(context).languageCode;
    if (fresh) {
      setState(() {
        _loading = true;
        _info = null;
      });
    }
    if (_unknownArtist) {
      await Future<void>.delayed(Duration.zero);
      if (mounted) setState(() => _loading = false);
      return;
    }
    final p = await SharedPreferences.getInstance();
    // 1) 저장해 둔 정보 (30일)
    if (!fresh) {
      try {
        final raw = p.getString(_key);
        if (raw != null) {
          final m = jsonDecode(raw) as Map;
          final at = DateTime.tryParse('${m['at']}');
          if (at != null && DateTime.now().difference(at).inDays < 30) {
            final i = _Info.fromJson(m['info'] as Map);
            if (mounted) {
              setState(() {
                _info = i;
                _loading = false;
              });
            }
            if (!i.creditsDone) _loadCredits(i, p);
            return;
          }
        }
      } catch (_) {}
    }
    // 2) 인터넷에서 찾기 (곡·가수 사진 / 소개 / 솔로·그룹 동시에)
    final info = _Info()..artist = _artist;
    await Future.wait([
      _ArtistApi.deezer(info, _title, _artist),
      _ArtistApi.wiki(info, _artist, lang),
      _ArtistApi.mbArtist(info, _artist),
    ]);
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
    if (!info.empty) _loadCredits(info, p);
  }

  /// 작사·작곡은 조금 늦게 (뮤직브레인즈가 천천히 받아야 해서)
  Future<void> _loadCredits(_Info info, SharedPreferences p) async {
    // 앨범 더 찾기 (애플·뮤직브레인즈) → 화면에 바로 반영
    await _ArtistApi.moreAlbums(info, _artist);
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 1100));
    await _ArtistApi.credits(info, _title, _artist);
    info.creditsDone = true;
    try {
      await p.setString(_key, jsonEncode({'at': DateTime.now().toIso8601String(), 'info': info.toJson()}));
    } catch (_) {}
    if (mounted) setState(() {});
  }

  static String _date(String ymd) {
    final p = ymd.split('-');
    if (p.length < 3) return ymd;
    return '${p[0]}년 ${int.tryParse(p[1]) ?? p[1]}월 ${int.tryParse(p[2]) ?? p[2]}일';
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDarkMode;
    final bg = d ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = d ? const Color(0xFF32302C) : Colors.white;
    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    final hint = d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = d ? const Color(0xFF4A4640) : const Color(0xFFEEE9DF);
    final line2 = d ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    final info = _info;

    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(t, style: TextStyle(color: hint, fontSize: 12, fontWeight: FontWeight.w700)),
        );

    final children = <Widget>[
      Center(
        child: Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: hint.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
        ),
      ),
    ];

    if (_loading) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: ink)),
            const SizedBox(height: 14),
            Text('${widget.song.artistDisplay} 정보를 찾는 중…', style: TextStyle(color: hint, fontSize: 13)),
          ],
        ),
      ));
    } else if (info == null || info.empty) {
      // 못 찾았을 때
      children.add(Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.travel_explore_rounded, color: hint, size: 40),
            const SizedBox(height: 14),
            Text('이 곡의 정보를 찾지 못했어요',
                style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              _unknownArtist ? '곡 정보 수정에서 가수 이름을 넣으면 찾을 수 있어요' : '가수 이름이나 제목이 정확하면 더 잘 찾아요',
              textAlign: TextAlign.center,
              style: TextStyle(color: hint, fontSize: 12.5),
            ),
            if (!_unknownArtist) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _load(fresh: true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: card,
                    foregroundColor: ink,
                    side: BorderSide(color: line2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: const Text('다시 찾기', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ));
    } else {
      // ── 가수 머리 ──
      final metaParts = <String>[
        if (info.type != null) info.type!,
        if (info.country != null) info.country!,
        if (info.formed != null)
          '${info.formed}년 결성'
        else if (info.firstYear != null)
          '첫 앨범 ${info.firstYear}년',
      ];
      children.add(Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 64,
              height: 64,
              child: info.picture != null
                  ? CachedNetworkImage(
                      imageUrl: info.picture!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _initial(info.artist, card, hint),
                    )
                  : _initial(info.artist, card, hint),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.artist.isEmpty ? _artist : info.artist,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(metaParts.join(' · '), style: TextStyle(color: hint, fontSize: 12.5)),
                ],
              ],
            ),
          ),
        ],
      ));
      final chips = <String>[
        if (info.genre != null) info.genre!,
        if (info.albumCount != null) '앨범 ${info.albumCount}장',
      ];
      if (chips.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(999)),
                  child: Text(c, style: TextStyle(color: sub, fontSize: 12)),
                ),
            ],
          ),
        ));
      }
      if (info.bio != null) {
        children.add(GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _bioOpen = !_bioOpen),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  alignment: Alignment.topCenter,
                  child: Text(info.bio!,
                      maxLines: _bioOpen ? null : 3,
                      overflow: _bioOpen ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 13.5, height: 1.65)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_bioOpen ? '접기' : '더 보기',
                        style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    if (info.bioTranslated) ...[
                      const Spacer(),
                      Text('자동 번역', style: TextStyle(color: hint, fontSize: 11.5)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ));
      }

      // ── 지금 듣는 곡 ──
      final rows = <(String, String)>[
        if (info.release != null) ('발매일', _date(info.release!)),
        for (final role in const ['작사', '작곡', '작사·작곡', '편곡', '프로듀서'])
          if (info.credits[role] != null) (role, info.credits[role]!.join(', ')),
        if (info.genre != null) ('장르', info.genre!),
      ];
      final albumLine = [
        if (info.album != null && info.album!.isNotEmpty) '《${info.album}》',
        if (info.trackNo != null) '${info.trackNo}번째 곡',
      ].join(' · ');
      final localArt = widget.song.albumArt;
      children.add(section('지금 듣는 곡'));
      children.add(Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: localArt != null
                        ? Image.memory(Uint8List.fromList(localArt), fit: BoxFit.cover, cacheWidth: 168)
                        : info.albumCover != null
                            ? CachedNetworkImage(imageUrl: info.albumCover!, fit: BoxFit.cover)
                            : Container(color: line, child: Icon(Icons.music_note_rounded, color: hint)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.song.titleDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
                      if (albumLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(albumLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: hint, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (rows.isNotEmpty || !info.creditsDone) ...[
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: line),
              const SizedBox(height: 10),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(r.$1, style: TextStyle(color: hint, fontSize: 12.5)),
                      ),
                      Expanded(child: Text(r.$2, style: TextStyle(color: ink, fontSize: 13.5))),
                    ],
                  ),
                ),
              if (!info.creditsDone)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: hint)),
                      const SizedBox(width: 8),
                      Text('작사·작곡 찾는 중…', style: TextStyle(color: hint, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ));

      // ── 이 가수의 앨범 ──
      if (info.albums.isNotEmpty) {
        children.add(section('이 가수의 앨범'));
        children.add(SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: info.albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final a = info.albums[i];
              return SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: a.cover.isEmpty
                            ? Container(color: line)
                            : CachedNetworkImage(
                                imageUrl: a.cover,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(color: line),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    Text([a.year, a.kind].where((s) => s.isNotEmpty).join(' · '),
                        maxLines: 1, style: TextStyle(color: hint, fontSize: 11.5)),
                  ],
                ),
              );
            },
          ),
        ));
      }

      // ── 출처 ──
      children.add(Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          children: [
            Text('정보: Deezer · MusicBrainz · Wikipedia',
                textAlign: TextAlign.center, style: TextStyle(color: hint, fontSize: 11.5)),
            const SizedBox(height: 2),
            Text('찾지 못한 항목은 보이지 않아요',
                textAlign: TextAlign.center, style: TextStyle(color: hint, fontSize: 11.5)),
            if (info.bioUrl != null)
              TextButton(
                onPressed: () async {
                  try {
                    await launchUrl(Uri.parse(info.bioUrl!), mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                style: TextButton.styleFrom(foregroundColor: sub),
                child: const Text('Wikipedia에서 더 보기 ›', style: TextStyle(fontSize: 12.5)),
              ),
          ],
        ),
      ));
    }

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: ListView(
        controller: widget.scroll,
        padding: EdgeInsets.fromLTRB(16, 10, 16, 24 + MediaQuery.of(context).padding.bottom),
        children: children,
      ),
    );
  }

  /// 사진 없으면 이름 첫 글자
  Widget _initial(String name, Color card, Color hint) {
    final n = name.trim().isEmpty ? _artist : name.trim();
    return Container(
      color: card,
      alignment: Alignment.center,
      child: Text(n.isEmpty ? '?' : n.characters.first.toUpperCase(),
          style: TextStyle(color: hint, fontSize: 26, fontWeight: FontWeight.w700)),
    );
  }
}
