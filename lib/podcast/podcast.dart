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

/// 팟캐스트 글자: 한국어면 한국어, 그 밖은 영어 (번역은 3단계에서 23개 언어로)
String podText(String ko, String en) => tr.localeName.startsWith('ko') ? ko : en;

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
      );
}

// ───────────────────────── 가져오기 (애플 팟캐스트 순위·검색 + 회차 목록 RSS) ─────────────────────────

class PodcastApi {
  static const _ua = {'User-Agent': 'Paransori/1.0 (Android; podcast)'};
  static final Map<String, List<PodcastShow>> _charts = {};
  static final Map<String, List<PodcastEpisode>> _episodes = {};
  static final Map<String, PodcastShow> _shows = {}; // 회차 목록에서 읽은 그림·이름으로 채운 것

  /// 나라별 인기 순위 (앱 켜져 있는 동안 한 번만 받음)
  static Future<List<PodcastShow>> top(String country, {int n = 50}) async {
    final cc = country.toLowerCase();
    final hit = _charts[cc];
    if (hit != null) return hit;
    final r = await http
        .get(Uri.parse('https://rss.applemarketingtools.com/api/v2/$cc/podcasts/top/$n/podcasts.json'), headers: _ua)
        .timeout(const Duration(seconds: 15));
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
    return _charts[cc] = list;
  }

  /// 검색 (그 나라 스토어에서)
  static Future<List<PodcastShow>> search(String term, String country) async {
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
    final u = Uri.https('itunes.apple.com', '/lookup', {'id': s.id, 'entity': 'podcast', 'country': country.toLowerCase()});
    final r = await http.get(u, headers: _ua).timeout(const Duration(seconds: 15));
    final res = (jsonDecode(utf8.decode(r.bodyBytes))['results'] as List?) ?? const [];
    if (res.isEmpty || '${res.first['feedUrl'] ?? ''}'.isEmpty) throw Exception('no feed');
    final x = res.first;
    return s.copyWith(feedUrl: '${x['feedUrl']}', art: '${x['artworkUrl600'] ?? s.art}');
  }

  static PodcastShow? showInfo(String id) => _shows[id];

  /// 회차 목록 (최신 200개까지)
  static Future<List<PodcastEpisode>> episodes(PodcastShow s, {bool refresh = false}) async {
    final hit = _episodes[s.feedUrl];
    if (hit != null && !refresh) return hit;
    final r = await http.get(Uri.parse(s.feedUrl), headers: _ua).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('feed ${r.statusCode}');
    final doc = XmlDocument.parse(utf8.decode(r.bodyBytes, allowMalformed: true));
    final channel = doc.findAllElements('channel').first;
    final showArt = _attr(_child(channel, 'itunes:image'), 'href') ??
        _child(_child(channel, 'image'), 'url')?.innerText.trim() ??
        s.art;
    _shows[s.id] = s.copyWith(
      art: s.art.isNotEmpty ? s.art : showArt,
      title: s.title.isNotEmpty ? s.title : (_child(channel, 'title')?.innerText.trim() ?? ''),
    );
    final list = <PodcastEpisode>[];
    for (final it in channel.findElements('item')) {
      final enc = _child(it, 'enclosure');
      final url = _attr(enc, 'url') ?? '';
      if (url.isEmpty) continue;
      final title = _child(it, 'title')?.innerText.trim() ?? '';
      list.add(PodcastEpisode(
        guid: (_child(it, 'guid')?.innerText.trim().isNotEmpty ?? false) ? _child(it, 'guid')!.innerText.trim() : url,
        title: title,
        url: url,
        published: _parseDate(_child(it, 'pubDate')?.innerText ?? ''),
        durationSec: _parseDuration(_child(it, 'itunes:duration')?.innerText ?? ''),
        art: _attr(_child(it, 'itunes:image'), 'href') ?? showArt,
        desc: _plain(_child(it, 'description')?.innerText ?? _child(it, 'itunes:summary')?.innerText ?? ''),
      ));
      if (list.length >= 200) break;
    }
    return _episodes[s.feedUrl] = list;
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

/// '오늘' · '어제' · '3일 전' · '10월 3일' / 'Today' · 'Yesterday' · '3 days ago' · '2025.10.3'
String podDateText(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days <= 0) return podText('오늘', 'Today');
  if (days == 1) return podText('어제', 'Yesterday');
  if (days < 7) return podText('$days일 전', '$days days ago');
  if (d.year == now.year) return podText('${d.month}월 ${d.day}일', '${d.month}/${d.day}');
  return '${d.year}.${d.month}.${d.day}';
}

/// '1시간 5분' · '31분' / '1h 5m' · '31m'
String podDurText(int sec) {
  if (sec <= 0) return '';
  final h = sec ~/ 3600, m = (sec % 3600) ~/ 60;
  if (h > 0) return podText('$h시간 $m분', '${h}h ${m}m');
  return podText('${m < 1 ? 1 : m}분', '${m < 1 ? 1 : m}m');
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
      }
    });
    _load();
  }

  /// 음악·자연소리를 틀면 팟캐스트는 비켜 줌
  void _onPlayer() {
    final pp = _pp;
    if (pp == null || !_mine) return;
    if (pp.currentSong != null || pp.natureSoundName != null || !pp.podcastActive) {
      _savePos();
      _mine = false;
      _saveTick?.cancel();
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
