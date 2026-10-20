import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/player_provider.dart';
import '../l10n/locale_holder.dart';
import 'podcast_text.dart';

/// 팟캐스트 글자: 한국어면 한국어 / 그 밖은 번역표(podcast_text.dart) → 없으면 영어
String podText(String ko, String en) {
  final l = tr.localeName;
  if (l.startsWith('ko')) return ko;
  return podTr[ko]?[podLangOf(l)] ?? en;
}

/// 숫자·이름이 들어가는 글자: '{n}일 전'처럼 자리를 비워 두고 값을 넣기
String podFmt(String ko, String en, Map<String, Object> v) {
  var t = podText(ko, en);
  v.forEach((key, x) => t = t.replaceAll('{$key}', '$x'));
  return t;
}

// ───────────────────────── 자료 ─────────────────────────

class PodcastShow {
  final String id; // 애플 팟캐스트 번호
  final String title;
  final String author;
  final String art;
  final String feedUrl;
  final String genre;
  const PodcastShow({
    required this.id,
    required this.title,
    this.author = '',
    this.art = '',
    this.feedUrl = '',
    this.genre = '',
  });

  PodcastShow copyWith({String? art, String? feedUrl, String? title, String? author}) => PodcastShow(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        art: art ?? this.art,
        feedUrl: feedUrl ?? this.feedUrl,
        genre: genre,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'author': author, 'art': art, 'feedUrl': feedUrl, 'genre': genre};

  factory PodcastShow.fromJson(Map<String, dynamic> j) => PodcastShow(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        author: '${j['author'] ?? ''}',
        art: '${j['art'] ?? ''}',
        feedUrl: '${j['feedUrl'] ?? ''}',
        genre: '${j['genre'] ?? ''}',
      );
}

class PodcastEpisode {
  final String guid;
  final String title;
  final String url; // 소리 파일 주소
  final DateTime? published;
  final int durationSec;
  final String art;
  final String desc;
  const PodcastEpisode({
    required this.guid,
    required this.title,
    required this.url,
    this.published,
    this.durationSec = 0,
    this.art = '',
    this.desc = '',
  });

  Map<String, dynamic> toJson() => {
        'guid': guid,
        'title': title,
        'url': url,
        'published': published?.millisecondsSinceEpoch,
        'dur': durationSec,
        'art': art,
      };

  factory PodcastEpisode.fromJson(Map<String, dynamic> j) => PodcastEpisode(
        guid: '${j['guid'] ?? ''}',
        title: '${j['title'] ?? ''}',
        url: '${j['url'] ?? ''}',
        published: j['published'] is int ? DateTime.fromMillisecondsSinceEpoch(j['published']) : null,
        durationSec: j['dur'] is int ? j['dur'] : 0,
        art: '${j['art'] ?? ''}',
        desc: '${j['desc'] ?? ''}',
      );
}

// ───────────────────────── 가져오기 (애플 팟캐스트 순위·검색 + 회차 목록 RSS) ─────────────────────────

class PodcastApi {
  static const _ua = {'User-Agent': 'Paransori/1.0 (Android; podcast)'};
  static final Map<String, List<PodcastShow>> _charts = {};
  static final Map<String, List<PodcastEpisode>> _episodes = {};
  static final Map<String, PodcastShow> _shows = {}; // 회차 목록에서 읽은 그림·이름으로 채운 것
  static final Map<String, String> _feedOf = {}; // 애플 번호 → 회차 목록 주소 (폰에도 저장)
  static bool _feedOfLoaded = false;

  static Future<void> _loadFeedOf() async {
    if (_feedOfLoaded) return;
    _feedOfLoaded = true;
    try {
      final raw = (await SharedPreferences.getInstance()).getString('pod_feed_ids');
      if (raw != null) (jsonDecode(raw) as Map).forEach((k, v) => _feedOf['$k'] = '$v');
    } catch (_) {}
  }

  /// 나라별 인기 순위 — 한 번 본 나라는 폰에 저장해서 바로 (하루 지나면 새로 · 인터넷이 안 되면 저장된 것)
  static Future<List<PodcastShow>> top(String country, {int n = 50}) async {
    final cc = country.toLowerCase();
    final hit = _charts[cc];
    if (hit != null) return hit;
    List<PodcastShow>? saved;
    var fresh = false;
    try {
      final raw = (await SharedPreferences.getInstance()).getString('pod_chart_$cc');
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        saved = [for (final x in (j['list'] as List)) PodcastShow.fromJson(Map<String, dynamic>.from(x))];
        final at = DateTime.fromMillisecondsSinceEpoch(j['at'] is int ? j['at'] : 0);
        fresh = DateTime.now().difference(at) < const Duration(hours: 24);
        if (saved.isEmpty) saved = null;
      }
    } catch (_) {}
    if (saved != null && fresh) return _charts[cc] = saved; // 하루 안에 받은 것 → 바로
    try {
      final list = await _fetchTop(cc, n);
      _saveChart(cc, list);
      return _charts[cc] = list;
    } catch (_) {
      if (saved != null) return _charts[cc] = saved; // 못 받으면 예전 순위라도
      rethrow;
    }
  }

  static Future<void> _saveChart(String cc, List<PodcastShow> list) async {
    try {
      if (list.isEmpty) return;
      (await SharedPreferences.getInstance()).setString('pod_chart_$cc',
          jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'list': [for (final x in list) x.toJson()]}));
    } catch (_) {}
  }

  static Future<List<PodcastShow>> _fetchTop(String cc, int n) async {
    final r = await http
        .get(Uri.parse('https://rss.applemarketingtools.com/api/v2/$cc/podcasts/top/$n/podcasts.json'), headers: _ua)
        .timeout(const Duration(seconds: 6)); // 순위가 없는 나라는 빨리 미국 순위로
    if (r.statusCode != 200) throw Exception('chart ${r.statusCode}');
    final res = (jsonDecode(utf8.decode(r.bodyBytes))['feed']['results'] as List?) ?? const [];
    final list = <PodcastShow>[
      for (final x in res)
        PodcastShow(
          id: '${x['id'] ?? ''}',
          title: '${x['name'] ?? ''}',
          author: '${x['artistName'] ?? ''}',
          art: '${x['artworkUrl100'] ?? ''}'.replaceAll('100x100', '300x300'),
          genre: (x['genres'] is List && (x['genres'] as List).isNotEmpty)
              ? '${(x['genres'] as List).first['name'] ?? ''}'
              : '',
        ),
    ];
    if (list.isEmpty) throw Exception('chart empty');
    return list;
  }

  static final Map<String, List<PodcastShow>> _searches = {}; // 앱 켜져 있는 동안 같은 검색은 바로

  /// 검색 (그 나라 스토어에서)
  static Future<List<PodcastShow>> search(String term, String country) async {
    final key = '${country.toLowerCase()}|$term';
    final hit = _searches[key];
    if (hit != null) return hit;
    final list = await _search(term, country);
    if (_searches.length > 40) _searches.remove(_searches.keys.first);
    return _searches[key] = list;
  }

  static Future<List<PodcastShow>> _search(String term, String country) async {
    final u = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'media': 'podcast',
      'country': country.toLowerCase(),
      'limit': '30',
    });
    final r = await http.get(u, headers: _ua).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('search ${r.statusCode}');
    final res = (jsonDecode(utf8.decode(r.bodyBytes))['results'] as List?) ?? const [];
    return [
      for (final x in res)
        if ('${x['feedUrl'] ?? ''}'.isNotEmpty)
          PodcastShow(
            id: '${x['collectionId'] ?? ''}',
            title: '${x['collectionName'] ?? ''}',
            author: '${x['artistName'] ?? ''}',
            art: '${x['artworkUrl600'] ?? x['artworkUrl100'] ?? ''}',
            feedUrl: '${x['feedUrl']}',
            genre: '${x['primaryGenreName'] ?? ''}',
          ),
    ];
  }

  /// 순위에서 고른 건 회차 목록 주소가 없어서 한 번 더 물어봄
  static Future<PodcastShow> withFeed(PodcastShow s, String country) async {
    if (s.feedUrl.isNotEmpty) return s;
    await _loadFeedOf();
    final known = _feedOf[s.id];
    if (known != null && known.isNotEmpty) return s.copyWith(feedUrl: known); // 전에 물어본 것 → 바로
    final u = Uri.https('itunes.apple.com', '/lookup', {'id': s.id, 'entity': 'podcast', 'country': country.toLowerCase()});
    final r = await http.get(u, headers: _ua).timeout(const Duration(seconds: 15));
    final res = (jsonDecode(utf8.decode(r.bodyBytes))['results'] as List?) ?? const [];
    if (res.isEmpty || '${res.first['feedUrl'] ?? ''}'.isEmpty) throw Exception('no feed');
    final x = res.first;
    final feed = '${x['feedUrl']}';
    _feedOf[s.id] = feed;
    try {
      if (_feedOf.length > 300) _feedOf.remove(_feedOf.keys.first);
      (await SharedPreferences.getInstance()).setString('pod_feed_ids', jsonEncode(_feedOf));
    } catch (_) {}
    return s.copyWith(feedUrl: feed, art: '${x['artworkUrl600'] ?? s.art}');
  }

  static PodcastShow? showInfo(String id) => _shows[id];

  /// 회차 목록 (최신 200개까지)
  static Future<List<PodcastEpisode>> episodes(PodcastShow s, {bool refresh = false}) async {
    final hit = _episodes[s.feedUrl];
    if (hit != null && !refresh) return hit;
    final r = await http.get(Uri.parse(s.feedUrl), headers: _ua).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('feed ${r.statusCode}');
    // 큰 파일 읽기는 뒤에서 (화면이 멈칫하지 않게)
    final parsed = await compute(_parseFeed, (r.bodyBytes as List<int>, s.art));
    final info = s.copyWith(
      art: s.art.isNotEmpty ? s.art : parsed.$1,
      title: s.title.isNotEmpty ? s.title : parsed.$2,
    );
    _shows[s.id] = info;
    final list = parsed.$3;
    _saveFeed(s.feedUrl, info, list); // 다음에 바로 보이게 폰에 저장
    return _episodes[s.feedUrl] = list;
  }

  /// 폰에 저장해 둔 회차 목록 (한 번 연 팟캐스트) — 없으면 null
  static Future<List<PodcastEpisode>?> savedEpisodes(PodcastShow s) async {
    if (s.feedUrl.isEmpty) return null;
    final hit = _episodes[s.feedUrl];
    if (hit != null) return hit;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_feedKey(s.feedUrl));
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final info = j['show'];
      if (info is Map) _shows[s.id] = PodcastShow.fromJson(Map<String, dynamic>.from(info));
      final eps = [for (final x in (j['eps'] as List)) PodcastEpisode.fromJson(Map<String, dynamic>.from(x))];
      return eps.isEmpty ? null : eps;
    } catch (_) {
      return null;
    }
  }

  /// 회차 목록 저장 (최근 연 20개까지 · 설명 글자는 맨 위 회차만 → 작게)
  static Future<void> _saveFeed(String feedUrl, PodcastShow info, List<PodcastEpisode> eps) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final key = _feedKey(feedUrl);
      await sp.setString(
          key,
          jsonEncode({
            'show': info.toJson(),
            'eps': [for (var i = 0; i < eps.length; i++) i == 0 ? {...eps[i].toJson(), 'desc': eps[i].desc} : eps[i].toJson()],
          }));
      final keys = (sp.getStringList('pod_feed_keys') ?? <String>[])
        ..remove(key)
        ..insert(0, key);
      while (keys.length > 20) {
        await sp.remove(keys.removeLast());
      }
      await sp.setStringList('pod_feed_keys', keys);
    } catch (_) {}
  }

  /// 주소 → 짧은 저장 이름 (언제나 같은 값)
  static String _feedKey(String url) {
    var h = 0x811c9dc5;
    for (final c in url.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return 'pod_feed_${h.toRadixString(16)}';
  }

  static XmlElement? _child(XmlElement? e, String qname) {
    if (e == null) return null;
    for (final c in e.childElements) {
      if (c.name.qualified == qname) return c;
    }
    return null;
  }

  static String? _attr(XmlElement? e, String name) {
    final v = e?.getAttribute(name)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static int _parseDuration(String s) {
    s = s.trim();
    if (s.isEmpty) return 0;
    if (!s.contains(':')) return int.tryParse(s.split('.').first) ?? 0;
    final p = s.split(':').map((x) => int.tryParse(x.trim()) ?? 0).toList();
    var sec = 0;
    for (final v in p) {
      sec = sec * 60 + v;
    }
    return sec;
  }

  static const _mon = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};

  static DateTime? _parseDate(String s) {
    final m = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})[A-Za-z]*\s+(\d{4})').firstMatch(s);
    if (m != null) {
      final mo = _mon[m.group(2)!.toLowerCase()];
      if (mo != null) return DateTime(int.parse(m.group(3)!), mo, int.parse(m.group(1)!));
    }
    final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (iso != null) return DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    return null;
  }

  static String _plain(String html) {
    final t = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return t.length > 400 ? '${t.substring(0, 400)}…' : t;
  }
}

/// 회차 목록 파일 읽기 (뒤에서 따로 돌아감) → (그림, 이름, 회차들)
(String, String, List<PodcastEpisode>) _parseFeed((List<int>, String) input) {
  final doc = XmlDocument.parse(utf8.decode(input.$1, allowMalformed: true));
  final channel = doc.findAllElements('channel').first;
  final showArt = PodcastApi._attr(PodcastApi._child(channel, 'itunes:image'), 'href') ??
      PodcastApi._child(PodcastApi._child(channel, 'image'), 'url')?.innerText.trim() ??
      input.$2;
  final showTitle = PodcastApi._child(channel, 'title')?.innerText.trim() ?? '';
  final list = <PodcastEpisode>[];
  for (final it in channel.findElements('item')) {
    final enc = PodcastApi._child(it, 'enclosure');
    final url = PodcastApi._attr(enc, 'url') ?? '';
    if (url.isEmpty) continue;
    final guid = PodcastApi._child(it, 'guid')?.innerText.trim() ?? '';
    list.add(PodcastEpisode(
      guid: guid.isNotEmpty ? guid : url,
      title: PodcastApi._child(it, 'title')?.innerText.trim() ?? '',
      url: url,
      published: PodcastApi._parseDate(PodcastApi._child(it, 'pubDate')?.innerText ?? ''),
      durationSec: PodcastApi._parseDuration(PodcastApi._child(it, 'itunes:duration')?.innerText ?? ''),
      art: PodcastApi._attr(PodcastApi._child(it, 'itunes:image'), 'href') ?? showArt,
      desc: PodcastApi._plain(
          PodcastApi._child(it, 'description')?.innerText ?? PodcastApi._child(it, 'itunes:summary')?.innerText ?? ''),
    ));
    if (list.length >= 200) break;
  }
  return (showArt, showTitle, list);
}

/// '오늘' · '어제' · '3일 전' · '10월 3일' / 'Today' · 'Yesterday' · '3 days ago' · '2025.10.3'
String podDateText(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days <= 0) return podText('오늘', 'Today');
  if (days == 1) return podText('어제', 'Yesterday');
  if (days < 7) return podFmt('{n}일 전', '{n} days ago', {'n': days});
  if (d.year == now.year) return podFmt('{m}월 {d}일', '{m}/{d}', {'m': d.month, 'd': d.day});
  return '${d.year}.${d.month}.${d.day}';
}

/// '1시간 5분' · '31분' / '1h 5m' · '31m'
String podDurText(int sec) {
  if (sec <= 0) return '';
  final h = sec ~/ 3600, m = (sec % 3600) ~/ 60;
  if (h > 0) return podFmt('{h}시간 {m}분', '{h}h {m}m', {'h': h, 'm': m});
  return podFmt('{m}분', '{m}m', {'m': m < 1 ? 1 : m});
}

/// 재생 시간 '12:40' · '1:02:05'
String podClock(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

// ───────────────────────── 재생 (음악 재생기를 같이 씀 → 알림창·이어폰 버튼 그대로) ─────────────────────────

/// 홈 '최근에 들었어요'용 팟캐스트 기록 하나
class PodRecent {
  final PodcastShow show;
  final PodcastEpisode episode;
  final DateTime at;
  const PodRecent(this.show, this.episode, this.at);
}

class PodcastPlayer extends ChangeNotifier {
  PodcastPlayer._();
  static final PodcastPlayer instance = PodcastPlayer._();

  PlayerProvider? _pp;
  PodcastShow? show;
  PodcastEpisode? episode;
  bool _mine = false; // 지금 재생기를 팟캐스트가 쓰는 중
  double speed = 1.0;
  Timer? _saveTick;
  /// 재생 위치가 바뀔 때마다 (미니플레이어·재생 화면만 듣기 — 목록은 안 다시 그려서 스크롤이 부드럽게)
  final ValueNotifier<int> tick = ValueNotifier(0);
  String _stateKey = '';

  final Map<String, int> _pos = {}; // 회차별 들은 곳 (ms)
  final Set<String> _done = {}; // 끝까지 들은 회차
  final List<PodRecent> recent = []; // 홈 '최근에 들었어요'용 (30초 넘게 들은 회차, 최근 10개)
  Timer? _recentTimer;
  // ── 수면 타이머 (라디오와 같게: 끝나기 1분 전부터 천천히 작게 → 멈춤) ──
  Timer? _sleepTimer;
  Timer? _sleepCountdown;
  Duration? sleepRemaining;
  final ValueNotifier<Duration?> sleepTick = ValueNotifier<Duration?>(null); // 남은 시간 글자만
  bool _sleepFading = false;
  bool get isSleepTimerActive => _sleepTimer != null;

  PodcastShow? lastShow; // 이어 듣기
  PodcastEpisode? lastEpisode;

  bool get active => _mine && episode != null;
  AudioPlayer? get _p => _pp?.player;
  bool get isPlaying => active && (_p?.playing ?? false);
  bool get isLoading {
    final ps = _p?.processingState;
    return active && (ps == ProcessingState.loading || ps == ProcessingState.buffering);
  }

  Duration get position => active ? (_p?.position ?? Duration.zero) : Duration.zero;
  Duration get duration {
    final d = active ? _p?.duration : null;
    return d ?? Duration(seconds: episode?.durationSec ?? 0);
  }

  // ── 구독(하트) ──
  final Map<String, PodcastShow> subs = {}; // 구독한 팟캐스트 (넣은 순서)
  final Map<String, String> _seen = {}; // 팟캐스트별로 마지막에 본 최신 회차
  final Set<String> newOnes = {}; // 새 회차가 올라온 구독
  bool _checked = false;

  bool isSub(String id) => subs.containsKey(id);

  void toggleSub(PodcastShow s, {String? latestGuid}) {
    if (subs.remove(s.id) == null) {
      subs[s.id] = s;
      if (latestGuid != null) _seen[s.id] = latestGuid; // 지금 회차까지는 본 걸로
    } else {
      newOnes.remove(s.id);
    }
    _persist();
    notifyListeners();
  }

  /// 회차 목록을 열면: 새 회차 표시 지우기 + 구독 정보(그림·주소) 새로
  void markSeen(PodcastShow s, List<PodcastEpisode> eps) {
    if (eps.isEmpty) return;
    _seen[s.id] = eps.first.guid;
    if (subs.containsKey(s.id)) subs[s.id] = s;
    newOnes.remove(s.id);
    _persist();
    notifyListeners();
  }

  /// 구독한 팟캐스트에 새 회차가 왔는지 (앱 켜고 팟캐스트 탭을 처음 열 때 한 번)
  Future<void> checkNewOnce() async {
    if (_checked) return;
    _checked = true;
    for (final s in subs.values.toList()) {
      if (s.feedUrl.isEmpty) continue;
      try {
        final eps = await PodcastApi.episodes(s, refresh: true);
        if (eps.isEmpty) continue;
        final seen = _seen[s.id];
        if (seen == null) {
          _seen[s.id] = eps.first.guid;
        } else if (seen != eps.first.guid) {
          newOnes.add(s.id);
        }
      } catch (_) {}
    }
    _persist();
    notifyListeners();
  }

  int savedMs(String guid) => _pos[guid] ?? 0;
  bool isDone(String guid) => _done.contains(guid);

  void attach(PlayerProvider pp) {
    _pp = pp;
    pp.addListener(_onPlayer);
    pp.player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed && active) {
        final g = episode!.guid;
        _done.add(g);
        _pos.remove(g);
        pp.player.pause();
        _persist();
        notifyListeners();
        _playNextOlder(); // 같은 팟캐스트에서 아직 안 들은 바로 이전 회차로
      }
    });
    _load();
  }

  /// 다 들으면: 같은 팟캐스트에서 바로 이전(더 오래된) 회차 중 아직 안 들은 것으로 이어서
  Future<void> _playNextOlder() async {
    final s = show, e = episode;
    if (s == null || e == null || s.feedUrl.isEmpty) return;
    var eps = PodcastApi._episodes[s.feedUrl] ?? await PodcastApi.savedEpisodes(s);
    if (eps == null) {
      try {
        eps = await PodcastApi.episodes(s);
      } catch (_) {
        return; // 인터넷이 안 되면 그냥 멈춘 채로
      }
    }
    // 기다리는 동안 다른 걸 틀었으면 그만
    if (!active || episode?.guid != e.guid) return;
    final i = eps.indexWhere((x) => x.guid == e.guid);
    if (i < 0) return;
    for (var j = i + 1; j < eps.length; j++) {
      if (!_done.contains(eps[j].guid)) {
        await play(s, eps[j]);
        return;
      }
    }
  }

  /// 음악·자연소리를 틀면 팟캐스트는 비켜 줌
  void _onPlayer() {
    final pp = _pp;
    if (pp == null || !_mine) return;
    if (pp.currentSong != null || pp.natureSoundName != null || !pp.podcastActive) {
      _savePos();
      _mine = false;
      _saveTick?.cancel();
      cancelSleepTimer(); // 음악 쪽은 음악 타이머가 따로 있음
      notifyListeners();
      return;
    }
    tick.value++; // 재생 위치 → 미니플레이어·재생 화면만
    final key = '${episode?.guid}|$isPlaying|$isLoading';
    if (key != _stateKey) {
      _stateKey = key;
      notifyListeners(); // 재생·멈춤·불러오는 중이 바뀔 때만 목록도
    }
  }

  Future<void> play(PodcastShow s, PodcastEpisode e) async {
    final pp = _pp;
    if (pp == null) return;
    if (_mine) _savePos();
    pp.preparePodcast(onBack: () => seekBy(-15), onForward: () => seekBy(30));
    show = s;
    episode = e;
    _mine = true;
    lastShow = s;
    lastEpisode = e;
    notifyListeners();
    final h = pp.audioHandler;
    if (h is SimpleAudioHandler) {
      final art = e.art.isNotEmpty ? e.art : s.art;
      h.updateMediaItem(MediaItem(
        id: e.url,
        title: e.title,
        artist: s.title,
        album: podText('파란소리 팟캐스트', 'Paransori Podcasts'),
        duration: e.durationSec > 0 ? Duration(seconds: e.durationSec) : null,
        artUri: art.startsWith('http') ? Uri.tryParse(art) : null,
      ));
    }
    try {
      final p = pp.player;
      await p.setAudioSource(AudioSource.uri(Uri.parse(e.url)));
      await p.setLoopMode(LoopMode.off);
      await p.setVolume(1.0);
      await p.setSpeed(speed);
      final at = _done.contains(e.guid) ? 0 : (_pos[e.guid] ?? 0);
      if (at > 5000) await p.seek(Duration(milliseconds: at - 2000)); // 듣던 곳 2초 앞부터
      _done.remove(e.guid);
      p.play(); // 기다리지 않기 (just_audio의 재생은 멈출 때까지 안 끝나서, 기다리면 아래 저장·기록이 시작 안 됨)
    } catch (err) {
      debugPrint('팟캐스트 재생 오류: $err');
    }
    _saveTick?.cancel();
    _saveTick = Timer.periodic(const Duration(seconds: 5), (_) => _savePos());
    // 30초 넘게 들으면 홈 '최근에 들었어요'에
    _recentTimer?.cancel();
    _recentTimer = Timer(const Duration(seconds: 30), () {
      if (active && episode?.guid == e.guid && isPlaying) _addRecent(s, e);
    });
    _persist();
  }

  void _addRecent(PodcastShow s, PodcastEpisode e) {
    recent.removeWhere((r) => r.episode.guid == e.guid);
    recent.insert(0, PodRecent(s, e, DateTime.now()));
    if (recent.length > 10) recent.removeRange(10, recent.length);
    _persist();
    notifyListeners();
  }

  Future<void> toggle() async {
    final p = _p;
    if (p == null) return;
    final s = show ?? lastShow, e = episode ?? lastEpisode;
    // 라디오를 틀어서 재생기가 비었거나 다른 걸 듣고 있었으면 → 이 회차를 듣던 곳부터 다시
    if (!active || p.processingState == ProcessingState.idle) {
      if (s != null && e != null) await play(s, e);
      return;
    }
    if (p.playing) {
      await p.pause();
      _savePos();
    } else {
      await p.play();
    }
  }

  Future<void> seekBy(int sec) async {
    final p = _p;
    if (p == null || !active) return;
    var to = p.position + Duration(seconds: sec);
    if (to < Duration.zero) to = Duration.zero;
    final d = p.duration;
    if (d != null && to > d - const Duration(seconds: 1)) to = d - const Duration(seconds: 1);
    await p.seek(to);
    _savePos();
  }

  Future<void> seekTo(Duration d) async {
    if (!active) return;
    await _p?.seek(d);
    _savePos();
  }

  void setSleepTimer(Duration d) {
    cancelSleepTimer();
    sleepRemaining = d;
    sleepTick.value = d;
    _sleepTimer = Timer(d, () async {
      final p = _p;
      if (p != null && active) {
        await p.pause();
        _savePos();
      }
      cancelSleepTimer(); // 소리 크기도 원래대로
    });
    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = sleepRemaining;
      if (r == null || r.inSeconds <= 0) return;
      sleepRemaining = r - const Duration(seconds: 1);
      final left = sleepRemaining!.inSeconds;
      // 끝나기 1분 전부터 천천히 작게 (뚝 끊겨서 잠이 깨지 않게)
      if (left < 60 && active) {
        _sleepFading = true;
        _p?.setVolume((left / 60).clamp(0.0, 1.0).toDouble());
      }
      sleepTick.value = sleepRemaining;
      if (left % 60 == 59) notifyListeners(); // 'N분' 표시는 분이 바뀔 때만
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    if (_sleepTimer == null && _sleepCountdown == null) return;
    if (_sleepFading) {
      _sleepFading = false;
      _p?.setVolume(1.0);
    }
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    _sleepTimer = null;
    _sleepCountdown = null;
    sleepRemaining = null;
    sleepTick.value = null;
    notifyListeners();
  }

  static const speeds = [1.0, 1.25, 1.5, 2.0, 0.8];
  Future<void> nextSpeed() async {
    final i = speeds.indexOf(speed);
    speed = speeds[(i + 1) % speeds.length];
    if (active) await _p?.setSpeed(speed);
    _persist();
    notifyListeners();
  }

  /// 미니플레이어 ×: 멈추고 알림창도 정리 (듣던 곳은 기억)
  Future<void> close() async {
    final pp = _pp;
    if (pp == null) return;
    _savePos();
    _saveTick?.cancel();
    cancelSleepTimer();
    final s = show, e = episode;
    _mine = false;
    episode = null;
    show = null;
    pp.podcastActive = false;
    await pp.player.stop();
    pp.dismissMediaNotification(resume: (s == null || e == null) ? null : () => play(s, e));
    notifyListeners();
  }

  void _savePos() {
    final e = episode;
    final p = _p;
    if (e == null || p == null || !_mine) return;
    final ms = p.position.inMilliseconds;
    if (ms < 3000) return;
    final d = p.duration?.inMilliseconds ?? e.durationSec * 1000;
    if (d > 0 && ms > d - 30000) {
      _done.add(e.guid); // 끝 30초 안이면 다 들은 걸로
      _pos.remove(e.guid);
    } else {
      _pos[e.guid] = ms;
    }
    _persist();
  }

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final pos = sp.getString('pod_pos');
      if (pos != null) {
        (jsonDecode(pos) as Map).forEach((k, v) {
          if (v is int) _pos['$k'] = v;
        });
      }
      _done.addAll(sp.getStringList('pod_done') ?? const []);
      speed = sp.getDouble('pod_speed') ?? 1.0;
      final subsRaw = sp.getString('pod_subs');
      if (subsRaw != null) {
        for (final j in (jsonDecode(subsRaw) as List)) {
          final s = PodcastShow.fromJson(Map<String, dynamic>.from(j));
          if (s.id.isNotEmpty) subs[s.id] = s;
        }
      }
      final seenRaw = sp.getString('pod_seen');
      if (seenRaw != null) {
        (jsonDecode(seenRaw) as Map).forEach((k, v) => _seen['$k'] = '$v');
      }
      final recRaw = sp.getString('pod_recent');
      if (recRaw != null) {
        for (final j in (jsonDecode(recRaw) as List)) {
          final m = Map<String, dynamic>.from(j);
          recent.add(PodRecent(
            PodcastShow.fromJson(Map<String, dynamic>.from(m['show'])),
            PodcastEpisode.fromJson(Map<String, dynamic>.from(m['ep'])),
            DateTime.tryParse('${m['at']}') ?? DateTime.now(),
          ));
        }
      }
      final last = sp.getString('pod_last');
      if (last != null) {
        final j = jsonDecode(last) as Map<String, dynamic>;
        lastShow = PodcastShow.fromJson(Map<String, dynamic>.from(j['show']));
        lastEpisode = PodcastEpisode.fromJson(Map<String, dynamic>.from(j['ep']));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final sp = await SharedPreferences.getInstance();
      // 너무 많아지지 않게 최근 300개만
      if (_pos.length > 300) {
        final keys = _pos.keys.toList();
        for (final k in keys.take(_pos.length - 300)) {
          _pos.remove(k);
        }
      }
      await sp.setString('pod_pos', jsonEncode(_pos));
      await sp.setStringList('pod_done', _done.toList().reversed.take(500).toList());
      await sp.setDouble('pod_speed', speed);
      await sp.setString('pod_recent',
          jsonEncode([for (final r in recent) {'show': r.show.toJson(), 'ep': r.episode.toJson(), 'at': r.at.toIso8601String()}]));
      await sp.setString('pod_subs', jsonEncode([for (final s in subs.values) s.toJson()]));
      await sp.setString('pod_seen', jsonEncode(_seen));
      if (lastShow != null && lastEpisode != null) {
        await sp.setString('pod_last', jsonEncode({'show': lastShow!.toJson(), 'ep': lastEpisode!.toJson()}));
      }
    } catch (_) {}
  }
}
