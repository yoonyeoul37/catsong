# -*- coding: utf-8 -*-
# 안드로이드 오토 (차 화면) — 1단계: 목록 · 재생 · 음성 명령
#  - 탭 4개: 라디오(즐겨찾기 먼저 · 국내는 방송사 색 칸 / 해외는 고른 나라 인기 방송) · 음악(목록) ·
#           자연소리(앱 사진 바둑판 · 위에 지금 듣기 좋은) · 팟캐스트(최근 → 구독 → 나라별 인기 → 회차)
#  - 음성 명령: "파란소리에서 ○○ 틀어 줘" (방송 · 자연소리 · 곡 · 최근 팟캐스트에서 찾아서)
#  - 팟캐스트: 차 화면 · 알림창 버튼이 15초 뒤로 / 30초 앞으로 모양으로 (되감기·빨리 감기 자리)
#  - 구글 규칙: 저절로 재생 안 함 (차 블루투스에 연결돼도 '이어서 듣기'가 저절로 틀지 않게) · 목록은 저장해 둔 것 먼저
# 새 파일: car_browse.dart · ArtProvider.kt · automotive_app_desc.xml · 아이콘 3개
# 고치는 파일: pubspec.yaml · main.dart · player_provider.dart · radio_provider.dart · radio_korea_screen2.dart ·
#             headset_resume.dart · MainActivity.kt · AndroidManifest.xml
# 프로젝트 폴더(C:\apps\mp3_player_new)에서 실행 / 하나라도 못 찾으면 ❌ 띄우고 아무것도 저장 안 함
import os
import sys

MAIN = os.path.join('android', 'app', 'src', 'main')
KT = os.path.join(MAIN, 'kotlin', 'com', 'example', 'mp3_player')
RES = os.path.join(MAIN, 'res')

ok = True
files = {}
ORIG = {}


def fail(msg):
    global ok
    ok = False
    print('❌ ' + msg)


def load(path):
    if path in files:
        return files[path][0]
    if not os.path.exists(path):
        fail(path + ' 파일이 없어요 (프로젝트 폴더에서 실행했는지 확인)')
        return None
    with open(path, 'rb') as f:
        raw = f.read().decode('utf-8')
    files[path] = [raw.replace('\r\n', '\n'), '\r\n' in raw]
    ORIG[path] = files[path][0]
    return files[path][0]


def rep(path, old, new, label):
    t = load(path)
    if t is None:
        return
    n = t.count(old)
    name = os.path.basename(path)
    if n != 1:
        fail(f'{name} — {label}: 찾을 코드를 못 찾았어요' if n == 0 else f'{name} — {label}: 같은 코드가 {n}군데라 못 고쳐요')
        return
    files[path][0] = t.replace(old, new)
    print(f'✔ {name} — {label}')


PUB = 'pubspec.yaml'
MAIN_D = os.path.join('lib', 'main.dart')
PP = os.path.join('lib', 'providers', 'player_provider.dart')
RP = os.path.join('lib', 'providers', 'radio_provider.dart')
RK = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
HR = os.path.join('lib', 'services', 'headset_resume.dart')
CAR = os.path.join('lib', 'services', 'car_browse.dart')
MA = os.path.join(KT, 'MainActivity.kt')
ART = os.path.join(KT, 'ArtProvider.kt')
MAN = os.path.join(MAIN, 'AndroidManifest.xml')
DESC = os.path.join(RES, 'xml', 'automotive_app_desc.xml')

if os.path.exists(CAR):
    print('이미 적용돼 있어요')
    sys.exit(0)

CAR_DART = '''import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/locale_holder.dart';
import '../models/radio_station.dart';
import '../models/song.dart';
import '../podcast/podcast.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import '../screens/radio_korea_screen2.dart' show koreanStationsForCar;
import '../utils/device_country.dart';
import '../utils/nature_sound_catalog.dart';
import 'headset_resume.dart';

/// 안드로이드 오토(차 화면) 목록 · 재생 · 음성 명령
/// 탭 4개: 라디오 · 음악 · 자연소리 · 팟캐스트 (구글 규칙: 탭은 4개까지, 아이콘은 흰색 한 가지 색)
/// - 목록은 폰에 있는 것/저장해 둔 것을 먼저 바로 보여 주고(10초 규칙), 인터넷에서 새로 받으면 바꿔 끼움
/// - 차에 연결돼도 저절로 틀지 않음 (사용자가 누르거나 말할 때만)
/// 칸 그림은 ArtProvider(안드로이드 쪽)가 그려 줌: content://kr.ssing.catsong.art/...
class CarBrowse {
  static PlayerProvider? _pp;
  static RadioProvider? _radio;
  static MusicProvider? _music;

  /// 차 화면이 마지막으로 목록을 물어본 때 (이어폰 '이어서 듣기'가 차에서 저절로 틀지 않게)
  static DateTime _lastAsk = DateTime(2000);
  static bool get inCarRecently => DateTime.now().difference(_lastAsk) < const Duration(minutes: 30);

  static void init(PlayerProvider pp, RadioProvider radio, MusicProvider music) {
    _pp = pp;
    _radio = radio;
    _music = music;
    // 차 화면이 앱보다 먼저 물어봤으면(차에서 처음 켤 때) 다시 물어보게
    for (final t in [AudioService.browsableRootId, tabRadio, tabMusic, tabNature, tabPodcast]) {
      _changed(t);
    }
  }

  // ───── 목록 바뀜 알리기 (인터넷에서 새로 받으면 차 화면이 다시 물어봄) ─────
  static final Map<String, BehaviorSubject<Map<String, dynamic>>> _subjects = {};
  static ValueStream<Map<String, dynamic>> subscribe(String parent) =>
      _subjects.putIfAbsent(parent, () => BehaviorSubject.seeded(<String, dynamic>{}));
  static void _changed(String parent) => _subjects[parent]?.add(<String, dynamic>{});

  // ───── 아이디 ─────
  static const tabRadio = 'tab_radio';
  static const tabMusic = 'tab_music';
  static const tabNature = 'tab_nature';
  static const tabPodcast = 'tab_podcast';

  // ───── 칸 모양 (구글 규칙의 이름표) ─────
  static const _group = 'android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT';
  static Map<String, dynamic> _style({int? browsable, int? playable}) => {
        if (browsable != null) AndroidContentStyle.browsableHintKey: browsable,
        if (playable != null) AndroidContentStyle.playableHintKey: playable,
      };
  static const _grid = AndroidContentStyle.gridItemHintValue;
  static const _list = AndroidContentStyle.listItemHintValue;

  /// 차 화면 맨 위(뿌리)에 붙이는 값 — main.dart AudioServiceConfig 에서 씀
  static const rootExtras = <String, dynamic>{
    AndroidContentStyle.supportedKey: true,
    AndroidContentStyle.browsableHintKey: AndroidContentStyle.listItemHintValue,
    AndroidContentStyle.playableHintKey: AndroidContentStyle.listItemHintValue,
    'android.media.browse.SEARCH_SUPPORTED': true, // 차 화면 검색 · 음성 명령
  };

  // ───── 칸 그림 주소 (ArtProvider) ─────
  static const _auth = 'content://kr.ssing.catsong.art';
  static Uri _icon(String drawable) => Uri.parse('android.resource://kr.ssing.catsong/drawable/$drawable');
  static Uri _tile(String big, String small, int color) => Uri.parse(
      '$_auth/tile?t=${Uri.encodeQueryComponent(big)}&s=${Uri.encodeQueryComponent(small)}&c=${color.toRadixString(16)}');
  static Uri _web(String url, String name, int color) => Uri.parse(
      '$_auth/web?u=${Uri.encodeQueryComponent(url)}&t=${Uri.encodeQueryComponent(name)}&c=${color.toRadixString(16)}');
  static Uri _asset(String asset) => Uri.parse('$_auth/asset?p=${Uri.encodeQueryComponent(asset)}');

  /// 해외 방송·팟캐스트처럼 정해진 색이 없을 때: 이름으로 차분한 색 하나 (방송사별 색과 어울리는 톤)
  static const _calm = [0xFF14356B, 0xFF4A1E5C, 0xFF7A1F1F, 0xFF0D4C6E, 0xFF1E4A2E, 0xFF6B4A12, 0xFF33405A, 0xFF6A3B22];
  static int _colorOf(String s) => _calm[s.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff) % _calm.length];

  // ═════════ 목록 ═════════
  static Future<List<MediaItem>> children(String parent) async {
    _lastAsk = DateTime.now();
    try {
      if (parent == AudioService.browsableRootId) return _root();
      if (parent == AudioService.recentRootId) return _recentRoot();
      if (parent == tabRadio) return await _radioTab();
      if (parent == tabMusic) return _musicTab();
      if (parent == tabNature) return _natureTab();
      if (parent == tabPodcast) return await _podcastTab();
      if (parent.startsWith('ml:')) return await _musicList(parent.substring(3));
      if (parent.startsWith('ps:')) return await _episodes(parent.substring(3));
    } catch (e) {
      debugPrint('차 화면 목록 오류($parent): $e');
    }
    return const [];
  }

  static List<MediaItem> _root() => [
        MediaItem(id: tabRadio, title: tr.catRadio, playable: false, artUri: _icon('paran_ic_radio'),
            extras: _style(playable: _grid)),
        MediaItem(id: tabMusic, title: tr.catMusic, playable: false, artUri: _icon('paran_ic_music'),
            extras: _style(browsable: _list, playable: _list)),
        MediaItem(id: tabNature, title: tr.natureSounds, playable: false, artUri: _icon('paran_ic_leaf'),
            extras: _style(playable: _grid)),
        MediaItem(id: tabPodcast, title: podText('팟캐스트', 'Podcasts'), playable: false,
            artUri: _icon('paran_ic_podcast'), extras: _style(browsable: _grid, playable: _list)),
      ];

  /// 차 화면 '최근' (구글이 처음에 이어서 듣기로 보여 줄 때) — 마지막에 듣던 것 하나
  static List<MediaItem> _recentRoot() {
    final radio = _radio, pp = _pp;
    final st = radio?.currentStation;
    if (st != null) {
      _radioLists['rc'] = [st];
      return [_stationItem(st, 'rc')];
    }
    final song = pp?.currentSong;
    if (song != null && song.uri != null) return [_songItem(song, 'all')];
    return const [];
  }

  // ───── 라디오 ─────
  /// 라디오 목록 (아이디 → 방송) — 누르면 같은 묶음 안에서 앞뒤로 넘기기
  static final Map<String, List<RadioStation>> _radioLists = {};

  static MediaItem _stationItem(RadioStation s, String listKey, {String? group, Uri? art, String? sub}) => MediaItem(
        id: 'r:$listKey|${s.stationUuid}',
        title: s.name,
        displaySubtitle: sub,
        artist: sub,
        playable: true,
        artUri: art ?? _stationArt(s),
        extras: group == null ? null : {_group: group},
      );

  static Uri _stationArt(RadioStation s) {
    final k = _krArt[s.stationUuid];
    if (k != null) return k;
    final logo = s.logoUrl ?? '';
    final c = _colorOf(s.name);
    if (logo.startsWith('http')) return _web(logo, s.name, c);
    return _tile(_initials(s.name), '', c);
  }

  static String _initials(String name) {
    final w = name.trim().split(RegExp(r'\\s+')).where((x) => x.isNotEmpty).toList();
    if (w.isEmpty) return '';
    final first = w.first;
    return first.length <= 4 ? first : first.substring(0, 1).toUpperCase();
  }

  static final Map<String, Uri> _krArt = {};

  static List<RadioStation> _korean() {
    final out = <RadioStation>[];
    for (final (st, big, small, color) in koreanStationsForCar()) {
      _krArt[st.stationUuid] = _tile(big, small, color);
      out.add(st);
    }
    return out;
  }

  static String get _country => (DeviceCountry.radioCountry() ?? 'US').toUpperCase();

  static Future<List<MediaItem>> _radioTab() async {
    final radio = _radio;
    if (radio == null) return const [];
    final items = <MediaItem>[];
    final kr = _country == 'KR';
    final korean = kr ? _korean() : const <RadioStation>[];
    // 즐겨찾기 먼저
    final favs = radio.favorites.toList();
    for (final s in favs) {
      if (s.countryCode == 'KR') {
        final i = korean.indexWhere((k) => k.name == s.name);
        if (i >= 0) _krArt[s.stationUuid] = _krArt[korean[i].stationUuid]!;
      }
    }
    _radioLists['rf'] = favs;
    for (final s in favs) {
      items.add(_stationItem(s, 'rf', group: tr.favorites));
    }
    // 그다음: 국내 방송 전체 / 해외는 고른 나라 인기 방송
    if (kr) {
      _radioLists['rk'] = korean;
      for (final s in korean) {
        items.add(_stationItem(s, 'rk', group: tr.all));
      }
    } else {
      final top = await _overseasTop(_country);
      _radioLists['ro'] = top;
      for (final s in top) {
        items.add(_stationItem(s, 'ro', group: tr.popularTab, sub: s.genre.isEmpty ? null : s.genre));
      }
    }
    return items;
  }

  /// 해외 인기 방송: 폰에 저장해 둔 것 바로 → 뒤에서 새로 받아 바꿔 끼움 (저장된 게 없으면 6초까지 기다림)
  static final Map<String, List<RadioStation>> _topMem = {};
  static final Set<String> _topFetching = {};

  static Future<List<RadioStation>> _overseasTop(String cc) async {
    final mem = _topMem[cc];
    if (mem != null) return mem;
    List<RadioStation>? saved;
    var fresh = false;
    try {
      final raw = (await SharedPreferences.getInstance()).getString('car_top_$cc');
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        saved = [for (final x in (j['list'] as List)) RadioStation.fromJson(Map<String, dynamic>.from(x))];
        fresh = DateTime.now().millisecondsSinceEpoch - ((j['at'] as int?) ?? 0) < 86400000;
      }
    } catch (_) {}
    if (saved != null && saved.isNotEmpty) {
      _topMem[cc] = saved;
      if (!fresh) _refreshTop(cc);
      return saved;
    }
    final f = _refreshTop(cc);
    var slow = false;
    final got = await f.timeout(const Duration(seconds: 6), onTimeout: () {
      slow = true;
      return const [];
    });
    if (slow) {
      f.then((l) {
        if (l.isNotEmpty) _changed(tabRadio); // 늦게 오면 그때 바꿔 끼우기
      });
    }
    return got;
  }

  static Future<List<RadioStation>> _refreshTop(String cc) async {
    if (!_topFetching.add(cc)) return _topMem[cc] ?? const [];
    try {
      final list = await _radio!.fetchTopForCar(cc);
      if (list.isNotEmpty) {
        final had = _topMem[cc] != null;
        _topMem[cc] = list;
        try {
          (await SharedPreferences.getInstance()).setString('car_top_$cc',
              jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'list': [for (final s in list) s.toJson()]}));
        } catch (_) {}
        if (had) _changed(tabRadio); // 저장된 걸 먼저 보여 줬으면 → 새 목록으로 바꿔 끼우기
      }
      return list;
    } catch (_) {
      return const [];
    } finally {
      _topFetching.remove(cc);
    }
  }

  // ───── 음악 ─────
  static MediaItem _songItem(Song s, String listKey, {String? group}) => MediaItem(
        id: 'm:$listKey|${s.uri}',
        title: s.titleDisplay,
        artist: s.artistDisplay,
        playable: true,
        extras: group == null ? null : {_group: group},
      );

  static List<MediaItem> _musicTab() {
    final m = _music;
    if (m != null && m.allSongs.isEmpty && !m.isLoading) {
      m.initialize().then((_) => _changed(tabMusic)); // 처음이면 곡 불러오고 다시
    }
    MediaItem folder(String id, String title, {String? sub}) => MediaItem(
        id: 'ml:$id', title: title, displaySubtitle: sub, artist: sub, playable: false,
        extras: _style(browsable: _list, playable: _list));
    final all = m?.allSongs.length ?? 0;
    return [
      folder('recent', tr.homeRecentHeader),
      folder('fav', tr.favorites),
      folder('all', tr.all, sub: all > 0 ? '$all' : null),
      folder('artists', tr.artists),
      folder('genres', tr.genre),
    ];
  }

  static Future<List<Song>> _songsOf(String key) async {
    final m = _music;
    if (m == null) return const [];
    if (m.allSongs.isEmpty) {
      if (!m.isLoading) m.initialize();
      for (var k = 0; k < 24 && m.allSongs.isEmpty; k++) {
        await Future.delayed(const Duration(milliseconds: 250)); // 6초까지
      }
    }
    if (key == 'recent') return m.recentSongs.where((s) => s.uri != null).take(50).toList();
    if (key == 'fav') return m.favorites.where((s) => s.uri != null).toList();
    if (key == 'all') return (await HeadsetResume.screenOrder(m.allSongs)).where((s) => s.uri != null).toList();
    if (key.startsWith('a:')) {
      final name = key.substring(2);
      return m.allSongs.where((s) => s.uri != null && s.artistDisplay == name).toList();
    }
    if (key.startsWith('g:')) {
      final g = key.substring(2);
      return m.allSongs.where((s) => s.uri != null && s.genreDisplay == g).toList();
    }
    return const [];
  }

  static Future<List<MediaItem>> _musicList(String key) async {
    final m = _music;
    if (m == null) return const [];
    if (key == 'artists' || key == 'genres') {
      await _songsOf('none'); // 곡 불러오기만
      final counts = <String, int>{};
      for (final s in m.allSongs) {
        if (s.uri == null) continue;
        final k = key == 'artists' ? s.artistDisplay : s.genreDisplay;
        counts[k] = (counts[k] ?? 0) + 1;
      }
      final names = counts.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return [
        for (final n in names)
          MediaItem(
              id: 'ml:${key == 'artists' ? 'a' : 'g'}:$n',
              title: n,
              displaySubtitle: '${counts[n]}',
              artist: '${counts[n]}',
              playable: false,
              extras: _style(playable: _list)),
      ];
    }
    final songs = await _songsOf(key);
    return [for (final s in songs.take(500)) _songItem(s, key)];
  }

  // ───── 자연소리 ─────
  static List<MediaItem> _natureTab() {
    final items = <MediaItem>[];
    MediaItem item(Map<String, String> s, String group, {String? art}) => MediaItem(
          id: '${art == null ? 'n' : 'nn'}:${s['name']}', // 위 '지금 듣기 좋은'은 아이디를 따로 (같은 아이디 두 번이면 헷갈림)
          title: natureName(s['name']!),
          playable: true,
          artUri: _asset(art ?? MediaArt.natureImage(s['name']!)),
          extras: {_group: group},
        );
    // 지금 듣기 좋은 (자연소리 화면과 같은 규칙: 아침 새소리 · 낮 파도/시냇물 번갈아 · 저녁 모닥불 · 밤 빗소리)
    final h = DateTime.now().hour;
    final cat = (h >= 5 && h < 11)
        ? '새소리'
        : (h >= 11 && h < 17)
            ? ((DateTime.now().millisecondsSinceEpoch ~/ 86400000).isEven ? '파도소리' : '시냇물')
            : (h >= 17 && h < 22)
                ? '모닥불'
                : '빗소리';
    final hero = switch (cat) {
      '새소리' => 'assets/nature_hero_morning.jpg',
      '파도소리' => 'assets/nature_hero_wave.jpg',
      '시냇물' => 'assets/nature_hero_stream.jpg',
      '모닥불' => 'assets/nature_hero_evening.jpg',
      _ => 'assets/nature_hero_night.jpg',
    };
    final order = PlayerProvider.natureSoundOrder;
    final nice = order.where((s) => s['name'] == cat).toList();
    if (nice.isNotEmpty) items.add(item(nice.first, tr.niceNow, art: hero));
    for (final s in order) {
      items.add(item(s, tr.all));
    }
    return items;
  }

  // ───── 팟캐스트 ─────
  static final Map<String, PodcastShow> _shows = {};

  static Future<List<MediaItem>> _podcastTab() async {
    final pod = PodcastPlayer.instance;
    final items = <MediaItem>[];
    // 최근에 들은 회차 (듣던 곳부터 이어서)
    for (final r in pod.recent.take(5)) {
      _shows[r.show.id] = r.show;
      items.add(_episodeItem(r.show, r.episode, group: tr.homeRecentHeader));
    }
    // 구독한 팟캐스트
    for (final s in pod.subs.values) {
      _shows[s.id] = s;
      items.add(_showItem(s, podText('구독', 'Subscribed')));
    }
    // 나라별 인기 (저장해 둔 순위는 바로 · 없으면 6초까지)
    final cc = _country;
    List<PodcastShow> top = const [];
    try {
      top = await PodcastApi.top(cc).timeout(const Duration(seconds: 6));
    } catch (_) {
      PodcastApi.top(cc).then((_) => _changed(tabPodcast)).catchError((_) {});
    }
    for (final s in top.take(40)) {
      if (pod.subs.containsKey(s.id)) continue;
      _shows[s.id] = s;
      items.add(_showItem(s, podText('인기 팟캐스트', 'Top podcasts')));
    }
    return items;
  }

  static MediaItem _showItem(PodcastShow s, String group) => MediaItem(
        id: 'ps:${s.id}',
        title: s.title,
        displaySubtitle: s.author,
        artist: s.author,
        playable: false,
        artUri: s.art.startsWith('http') ? _web(s.art, s.title, _colorOf(s.title)) : _tile(_initials(s.title), '', _colorOf(s.title)),
        extras: {_group: group, ..._style(playable: _list)},
      );

  static MediaItem _episodeItem(PodcastShow s, PodcastEpisode e, {String? group}) {
    final art = e.art.isNotEmpty ? e.art : s.art;
    return MediaItem(
      id: 'pe:${s.id}|${e.guid}',
      title: e.title,
      displaySubtitle: s.title,
      artist: s.title,
      playable: true,
      duration: e.durationSec > 0 ? Duration(seconds: e.durationSec) : null,
      artUri: art.startsWith('http') ? _web(art, s.title, _colorOf(s.title)) : null,
      extras: group == null ? null : {_group: group},
    );
  }

  /// 회차 목록: 폰에 저장된 것 바로 → 뒤에서 새로 받아 바꿔 끼움
  static final Map<String, List<PodcastEpisode>> _eps = {};

  static Future<List<MediaItem>> _episodes(String showId) async {
    final s0 = _shows[showId];
    if (s0 == null) return const [];
    PodcastShow s = s0;
    List<PodcastEpisode>? eps = _eps[showId];
    if (eps == null) {
      try {
        s = await PodcastApi.withFeed(s, _country).timeout(const Duration(seconds: 5));
        _shows[showId] = s;
      } catch (_) {}
      eps = await PodcastApi.savedEpisodes(s);
      final show = s;
      final fetch = PodcastApi.episodes(show, refresh: eps != null).then((fresh) {
        final had = _eps[showId] != null;
        _eps[showId] = fresh;
        if (had) _changed('ps:$showId');
        return fresh;
      });
      if (eps == null) {
        try {
          eps = await fetch.timeout(const Duration(seconds: 7));
        } catch (_) {
          fetch.then((_) => _changed('ps:$showId')).catchError((_) {});
          eps = const [];
        }
      } else {
        fetch.catchError((_) => <PodcastEpisode>[]);
      }
      if (eps.isNotEmpty) _eps[showId] = eps; // 못 받았으면 다음에 다시 받기
    }
    return [for (final e in eps.take(100)) _episodeItem(s, e)];
  }

  // ═════════ 재생 (사용자가 누른 것만) ═════════
  static Future<void> play(String id) async {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return;
    try {
      if (id.startsWith('r:')) {
        final rest = id.substring(2);
        final bar = rest.indexOf('|');
        final key = rest.substring(0, bar), uuid = rest.substring(bar + 1);
        var list = _radioLists[key];
        if (list == null || list.isEmpty) {
          await _radioTab(); // 앱이 막 켜졌으면 목록부터
          list = _radioLists[key] ?? const [];
        }
        final i = list.indexWhere((s) => s.stationUuid == uuid);
        if (i < 0) return;
        radio.setQueue(list, i); // 앞뒤 버튼 → 같은 묶음 안에서
        await radio.playStation(list[i]);
      } else if (id.startsWith('m:')) {
        final rest = id.substring(2);
        final bar = rest.indexOf('|');
        final key = rest.substring(0, bar), uri = rest.substring(bar + 1);
        final songs = await _songsOf(key);
        final i = songs.indexWhere((s) => s.uri == uri);
        if (i >= 0) await pp.playFromList(songs, i);
      } else if (id.startsWith('n:') || id.startsWith('nn:')) {
        final name = id.substring(id.indexOf(':') + 1);
        final s = PlayerProvider.natureSoundOrder.where((x) => x['name'] == name).toList();
        if (s.isNotEmpty) await pp.playNatureSound(s.first['assetPath']!, name);
      } else if (id.startsWith('pe:')) {
        final rest = id.substring(3);
        final bar = rest.indexOf('|');
        final showId = rest.substring(0, bar), guid = rest.substring(bar + 1);
        final pod = PodcastPlayer.instance;
        // 최근에 들은 회차면 그대로 (듣던 곳부터 이어서)
        for (final r in pod.recent) {
          if (r.show.id == showId && r.episode.guid == guid) {
            await pod.play(r.show, r.episode);
            return;
          }
        }
        final s = _shows[showId];
        final e = (_eps[showId] ?? const <PodcastEpisode>[]).where((x) => x.guid == guid).toList();
        if (s != null && e.isNotEmpty) await pod.play(s, e.first);
      }
    } catch (e) {
      debugPrint('차 화면 재생 오류($id): $e');
    }
  }

  // ═════════ 음성 명령 · 검색 ═════════
  /// 소리 나는 대로 비슷하게 (말로 한 한글 ↔ 방송 이름의 영어)
  static const _alias = {
    '클래식': 'classic', '쿨': 'cool', '해피': 'happy', '파워': 'power', '러브': 'love',
    '케이비에스': 'kbs', '엠비씨': 'mbc', '에스비에스': 'sbs', '이비에스': 'ebs', '씨비에스': 'cbs',
    '에프엠': 'fm', '포유': '4u', '제일': '제1', '일라디오': '1라디오', '이에프엠': '2fm',
  };

  static String _norm(String s) {
    var t = s.toLowerCase();
    _alias.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'[\\s\\.\\-·_()]'), '');
  }

  static int _score(String query, String name) {
    final q = _norm(query), n = _norm(name);
    if (q.isEmpty || n.isEmpty) return 0;
    if (q == n) return 100;
    if (n.contains(q)) return 85 - (n.length - q.length).clamp(0, 30);
    if (q.contains(n)) return 70 - (q.length - n.length).clamp(0, 30);
    return 0;
  }

  /// 찾을 수 있는 것 전부 (아이디, 이름, 그림 붙은 항목)
  static Future<List<(int, MediaItem)>> _find(String query) async {
    final out = <(int, MediaItem)>[];
    void add(int sc, MediaItem it) {
      if (sc >= 50) out.add((sc, it));
    }
    final radio = _radio;
    if (radio != null) {
      if (_radioLists.isEmpty) await _radioTab();
      final seen = <String>{};
      for (final key in ['rf', 'rk', 'ro']) {
        for (final s in _radioLists[key] ?? const <RadioStation>[]) {
          if (!seen.add(s.stationUuid)) continue;
          add(_score(query, s.name) + 3, _stationItem(s, key)); // 라디오를 조금 먼저
        }
      }
    }
    for (final s in PlayerProvider.natureSoundOrder) {
      final n = s['name']!;
      final sc = [_score(query, n), _score(query, natureName(n))].reduce((a, b) => a > b ? a : b);
      add(sc, MediaItem(id: 'n:$n', title: natureName(n), playable: true, artUri: _asset(MediaArt.natureImage(n))));
    }
    final m = _music;
    if (m != null) {
      for (final s in m.allSongs) {
        if (s.uri == null) continue;
        final sc = [_score(query, s.titleDisplay), _score(query, '${s.titleDisplay} ${s.artistDisplay}'),
          _score(query, s.artistDisplay) - 10].reduce((a, b) => a > b ? a : b);
        add(sc, _songItem(s, 'all'));
      }
    }
    final pod = PodcastPlayer.instance;
    for (final r in pod.recent) {
      _shows[r.show.id] = r.show;
      add(_score(query, r.show.title), _episodeItem(r.show, r.episode));
    }
    out.sort((a, b) => b.$1.compareTo(a.$1));
    return out;
  }

  /// 차 화면 검색 결과
  static Future<List<MediaItem>> search(String query) async {
    _lastAsk = DateTime.now();
    try {
      return [for (final r in (await _find(query)).take(30)) r.$2];
    } catch (_) {
      return const [];
    }
  }

  /// 아무것도 안 나올 때만 마지막에 듣던 것 (나오는 중에 누르면 멈추는 버튼이라 그냥 부르면 안 됨)
  static void _resumeIfIdle() {
    final pp = _pp, radio = _radio;
    final busy = (pp?.isPlaying ?? false) || (radio?.isPlaying ?? false) || (radio?.isLoading ?? false);
    if (!busy) HeadsetResume.widgetPlay();
  }

  /// "파란소리에서 ○○ 틀어 줘" — 아무 말 없이 "파란소리 틀어 줘"면 마지막에 듣던 것
  static Future<void> playFromSearch(String query) async {
    _lastAsk = DateTime.now();
    final q = query.trim();
    if (q.isEmpty) {
      _resumeIfIdle();
      return;
    }
    try {
      final found = await _find(q);
      if (found.isEmpty) {
        _resumeIfIdle(); // 못 찾으면 마지막에 듣던 것 (이미 나오는 중이면 그대로)
        return;
      }
      await play(found.first.$2.id);
    } catch (e) {
      debugPrint('음성 명령 오류: $e');
    }
  }
}
'''
ART_KT = '''package kr.ssing.catsong

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/// 안드로이드 오토(차 화면) 칸 그림
/// 차 화면은 인터넷 주소 그림을 직접 못 읽어서, 앱이 그림 파일로 만들어 건네줌
///  - tile  : 방송사 색 칸 + 큰 글자(KBS) + 작은 글자(Classic FM) — 앱 방송사별 칸과 같은 느낌
///  - web   : 인터넷 그림(해외 방송 로고 · 팟캐스트 그림)을 받아서 (못 받으면 색 칸)
///  - asset : 앱 안의 사진 (자연소리 등)
/// 한 번 만든 그림은 cache/car_art 에 저장해서 다음엔 바로
class ArtProvider : ContentProvider() {

    override fun onCreate() = true
    override fun getType(uri: Uri) = "image/png"
    override fun query(u: Uri, p: Array<out String>?, s: String?, a: Array<out String>?, o: String?): Cursor? = null
    override fun insert(u: Uri, v: ContentValues?): Uri? = null
    override fun delete(u: Uri, s: String?, a: Array<out String>?) = 0
    override fun update(u: Uri, v: ContentValues?, s: String?, a: Array<out String>?) = 0

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor? {
        val ctx = context ?: return null
        if (mode != "r") return null // 읽기만
        val dir = File(ctx.cacheDir, "car_art").apply { mkdirs() }
        val key = Integer.toHexString(uri.toString().hashCode()) + "_" + uri.toString().length
        val f = File(dir, "$key.png")
        if (!f.exists() || f.length() == 0L) {
            val bmp = try {
                when (uri.path?.trim('/')) {
                    "tile" -> tile(uri.getQueryParameter("t") ?: "", uri.getQueryParameter("s") ?: "", color(uri))
                    "web" -> web(uri.getQueryParameter("u") ?: "", color(uri))
                        ?: tile(initials(uri.getQueryParameter("t") ?: ""), "", color(uri))
                    "asset" -> asset(uri.getQueryParameter("p") ?: "")
                    else -> null
                }
            } catch (_: Exception) {
                null
            } ?: return null
            val tmp = File(dir, "$key.tmp")
            tmp.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
            tmp.renameTo(f)
            bmp.recycle()
            trim(dir)
        }
        return ParcelFileDescriptor.open(f, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    private fun color(uri: Uri): Int = try {
        (uri.getQueryParameter("c") ?: "ff3a342a").toLong(16).toInt() or 0xFF000000.toInt()
    } catch (_: Exception) {
        0xFF3A342A.toInt()
    }

    private fun initials(name: String): String {
        val w = name.trim().split(Regex("\\\\s+")).firstOrNull() ?: return ""
        return if (w.length <= 4) w else w.substring(0, 1).uppercase()
    }

    /// 색 칸: 위 왼쪽이 조금 밝은 그라데이션 + 오른쪽 위 연한 동그라미 + 아래 왼쪽 글자
    private fun tile(big: String, small: String, c: Int): Bitmap {
        val n = 256
        val b = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        val light = mix(c, 0xFFFFFFFF.toInt(), 0.10f)
        cv.drawRect(0f, 0f, n.toFloat(), n.toFloat(), Paint().apply {
            shader = LinearGradient(0f, 0f, n.toFloat(), n.toFloat(), light, c, Shader.TileMode.CLAMP)
        })
        cv.drawCircle(n - 18f, 18f, 66f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x14FFFFFF })
        val bold = Typeface.create("sans-serif", Typeface.BOLD)
        if (small.isEmpty()) {
            // 글자 하나뿐 (해외 방송 첫 글자 등): 가운데 크게
            val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFFFFFFF.toInt(); typeface = bold; textAlign = Paint.Align.CENTER
                textSize = if (big.length <= 1) 120f else 72f
            }
            fit(p, big, n - 40f)
            val fm = p.fontMetrics
            cv.drawText(big, n / 2f, n / 2f - (fm.ascent + fm.descent) / 2f, p)
        } else {
            val pb = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xFFFFFFFF.toInt(); typeface = bold; textSize = 64f }
            val ps = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0xD9FFFFFF.toInt(); textSize = 30f }
            fit(pb, big, n - 44f)
            fit(ps, small, n - 44f)
            cv.drawText(big, 22f, n - 62f, pb)
            cv.drawText(small, 22f, n - 22f, ps)
        }
        return b
    }

    /// 글자가 칸보다 길면 줄이기
    private fun fit(p: Paint, s: String, max: Float) {
        while (p.textSize > 14f && p.measureText(s) > max) p.textSize -= 2f
    }

    private fun mix(a: Int, b: Int, t: Float): Int {
        fun ch(sh: Int) = (((a shr sh) and 0xFF) * (1 - t) + ((b shr sh) and 0xFF) * t).toInt()
        return (0xFF shl 24) or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
    }

    /// 인터넷 그림 받기 (4초 안에, 2MB까지) — 작은 로고는 색 칸 가운데에 얹기
    private fun web(url: String, c: Int): Bitmap? {
        if (!url.startsWith("http://") && !url.startsWith("https://")) return null
        val con = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 4000; readTimeout = 4000; instanceFollowRedirects = true
            setRequestProperty("User-Agent", "Paransori/1.0 (Android)")
        }
        val bytes = try {
            if (con.responseCode !in 200..299) return null
            con.inputStream.use { ins ->
                val out = java.io.ByteArrayOutputStream()
                val buf = ByteArray(16 * 1024)
                while (true) {
                    val r = ins.read(buf)
                    if (r < 0) break
                    out.write(buf, 0, r)
                    if (out.size() > 2 * 1024 * 1024) return null
                }
                out.toByteArray()
            }
        } finally {
            con.disconnect()
        }
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, o)
        if (o.outWidth <= 0) return null
        var s = 1
        while (maxOf(o.outWidth, o.outHeight) / (s * 2) >= 512) s *= 2
        val src = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
            BitmapFactory.Options().apply { inSampleSize = s }) ?: return null
        return if (maxOf(src.width, src.height) < 160) onTile(src, c) else square(src, 512)
    }

    /// 작은 로고: 흰 칸 가운데에 (로고가 잘 보이게)
    private fun onTile(src: Bitmap, c: Int): Bitmap {
        val n = 256
        val b = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888)
        val cv = Canvas(b)
        cv.drawColor(0xFFF4EFE5.toInt())
        val side = (n * 0.62f)
        val k = side / maxOf(src.width, src.height)
        val w = src.width * k
        val h = src.height * k
        cv.drawBitmap(src, null, RectF((n - w) / 2f, (n - h) / 2f, (n + w) / 2f, (n + h) / 2f),
            Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG))
        src.recycle()
        return b
    }

    /// 가운데를 네모로 잘라 크기 맞추기
    private fun square(src: Bitmap, max: Int): Bitmap {
        val side = minOf(src.width, src.height)
        val l = (src.width - side) / 2
        val t = (src.height - side) / 2
        val n = minOf(max, side)
        val b = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888)
        Canvas(b).drawBitmap(src, Rect(l, t, l + side, t + side), Rect(0, 0, n, n), Paint(Paint.FILTER_BITMAP_FLAG))
        src.recycle()
        return b
    }

    /// 앱 안 사진 (assets/…) — 네모로 잘라 512까지
    private fun asset(path: String): Bitmap? {
        if (!path.startsWith("assets/") || path.contains("..")) return null
        val ctx = context ?: return null
        val full = "flutter_assets/$path"
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        ctx.assets.open(full).use { BitmapFactory.decodeStream(it, null, o) }
        var s = 1
        while (minOf(o.outWidth, o.outHeight) / (s * 2) >= 512) s *= 2
        val src = ctx.assets.open(full).use {
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = s })
        } ?: return null
        return square(src, 512)
    }

    /// 저장 그림이 너무 많으면 오래된 것부터 지우기 (300개까지)
    private fun trim(dir: File) {
        val fs = dir.listFiles() ?: return
        if (fs.size <= 300) return
        fs.sortedBy { it.lastModified() }.take(fs.size - 300).forEach { it.delete() }
    }
}
'''


def filled(comment, d):
    return f'''<?xml version="1.0" encoding="utf-8"?>
<!-- {comment} -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path android:fillColor="#FFFFFFFF" android:pathData="{d}" />
</vector>
'''


NEW = [
    (CAR, CAR_DART, '차 화면 목록 · 재생 · 음성 명령'),
    (ART, ART_KT, '차 화면 칸 그림 (방송사 색 칸 · 로고 · 사진)'),
    (DESC, '''<?xml version="1.0" encoding="utf-8"?>
<!-- 안드로이드 오토: 음악·라디오(미디어) 앱 -->
<automotiveApp>
    <uses name="media" />
</automotiveApp>
''', '안드로이드 오토 앱 종류 (미디어)'),
    (os.path.join(RES, 'drawable', 'paran_ic_podcast.xml'), filled('팟캐스트 탭 (흰색 한 가지 색)',
        'M14,12c0,0.74 -0.4,1.38 -1,1.72V22h-2v-8.28c-0.6,-0.35 -1,-0.98 -1,-1.72 0,-1.1 0.9,-2 2,-2s2,0.9 2,2zM12,6c-3.31,0 -6,2.69 -6,6 0,1.74 0.75,3.31 1.94,4.4l1.42,-1.42C8.53,14.25 8,13.19 8,12c0,-2.21 1.79,-4 4,-4s4,1.79 4,4c0,1.19 -0.53,2.25 -1.36,2.98l1.42,1.42C17.25,15.31 18,13.74 18,12c0,-3.31 -2.69,-6 -6,-6zM12,2C6.48,2 2,6.48 2,12c0,2.85 1.2,5.41 3.11,7.24l1.42,-1.42C4.98,16.36 4,14.29 4,12c0,-4.41 3.59,-8 8,-8s8,3.59 8,8c0,2.29 -0.98,4.36 -2.53,5.82l1.42,1.42C20.8,17.41 22,14.85 22,12c0,-5.52 -4.48,-10 -10,-10z'),
     '팟캐스트 탭 아이콘'),
    (os.path.join(RES, 'drawable', 'paran_ic_back15.xml'), filled('팟캐스트 15초 뒤로',
        'M12,5V1L7,6l5,5V7c3.31,0 6,2.69 6,6s-2.69,6 -6,6 -6,-2.69 -6,-6H4c0,4.42 3.58,8 8,8s8,-3.58 8,-8 -3.58,-8 -8,-8z'),
     '15초 뒤로 아이콘'),
    (os.path.join(RES, 'drawable', 'paran_ic_fwd30.xml'), filled('팟캐스트 30초 앞으로',
        'M12,5V1l5,5 -5,5V7c-3.31,0 -6,2.69 -6,6s2.69,6 6,6 6,-2.69 6,-6h2c0,4.42 -3.58,8 -8,8s-8,-3.58 -8,-8 3.58,-8 8,-8z'),
     '30초 앞으로 아이콘'),
]
for p, _, _ in NEW:
    if os.path.exists(p):
        fail(os.path.basename(p) + ' 파일이 벌써 있어요 — 덮어쓰지 않으려고 멈춰요')

# ───── pubspec.yaml ─────
rep(PUB, '''  audio_service: ^0.18.15
''', '''  audio_service: ^0.18.15
  rxdart: '>=0.26.0 <0.29.0' # 차 화면 목록 바뀜 알리기 (audio_service가 이미 쓰는 것)
''', '차 화면용 rxdart (audio_service와 같은 범위)')

# ───── main.dart ─────
rep(MAIN_D, '''import 'services/headset_resume.dart';
''', '''import 'services/headset_resume.dart';
import 'services/car_browse.dart';
''', '차 화면 불러오기')
rep(MAIN_D, '''      preloadArtwork: false,
''', '''      preloadArtwork: false,
      androidBrowsableRootExtras: CarBrowse.rootExtras, // 안드로이드 오토: 칸 모양 · 검색 지원
''', '안드로이드 오토 칸 모양 · 검색 켜기')
rep(MAIN_D, '''  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것
''', '''  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것
  CarBrowse.init(playerProvider, radioProvider, musicProvider); // 안드로이드 오토 (차 화면)
''', '차 화면 연결')

# ───── player_provider.dart (알림창·차 화면과 이어진 곳) ─────
rep(PP, '''import '../services/headset_resume.dart';
''', '''import '../services/headset_resume.dart';
import '../services/car_browse.dart';
import 'package:rxdart/rxdart.dart' show ValueStream;
''', '차 화면 불러오기')
rep(PP, '''      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],''', '''      controls: [
        // 팟캐스트: 15초 뒤로 · 30초 앞으로 모양 (차 화면 · 알림창 둘 다)
        _podcastMode ? _back15 : MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        _podcastMode ? _fwd30 : MediaControl.skipToNext,
      ],''', '팟캐스트 버튼 모양 (15초 · 30초)')
rep(PP, '''  @override
  Future<void> onTaskRemoved() async {''', '''  // ───── 안드로이드 오토 (차 화면) ─────
  // 기본 '되감기 · 빨리 감기' 자리에 15초 · 30초 아이콘 (안드로이드 13 이상은 차 화면 · 알림창 버튼으로, 그 밑은 알림창 버튼으로)
  static const _back15 = MediaControl(androidIcon: 'drawable/paran_ic_back15', label: '-15s', action: MediaAction.rewind);
  static const _fwd30 = MediaControl(androidIcon: 'drawable/paran_ic_fwd30', label: '+30s', action: MediaAction.fastForward);

  @override
  Future<void> rewind() async => onPodcastBack?.call();

  @override
  Future<void> fastForward() async => onPodcastForward?.call();

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId, [Map<String, dynamic>? options]) =>
      CarBrowse.children(parentMediaId);

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) =>
      CarBrowse.subscribe(parentMediaId);

  @override
  Future<List<MediaItem>> search(String query, [Map<String, dynamic>? extras]) => CarBrowse.search(query);

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) => CarBrowse.play(mediaId);

  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) => CarBrowse.playFromSearch(query);

  @override
  Future<void> onTaskRemoved() async {''', '차 화면 목록 · 재생 · 음성 명령 받기')

# ───── radio_provider.dart ─────
rep(RP, '''  Future<void> fetchTopStations(String countryCode, {int limit = 200, int retryCount = 0}) async {''', '''  /// 차 화면(안드로이드 오토)용 나라별 인기 방송 — 화면에 보이는 목록은 건드리지 않음
  Future<List<RadioStation>> fetchTopForCar(String countryCode, {int limit = 60}) async {
    List<String> servers;
    try {
      servers = await _getApiServers();
    } catch (_) {
      return const [];
    }
    for (final server in servers) {
      try {
        final uri = Uri.https(server, '/json/stations/bycountrycodeexact/$countryCode', {
          'order': 'clickcount',
          'reverse': 'true',
          'limit': '${limit * 2}',
          'hidebroken': 'true',
          'lastcheckok': '1',
          'codec': 'MP3,AAC,AAC+,OGG',
        });
        final response = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;
        final List<dynamic> data = json.decode(response.body);
        final keys = <String>{};
        final out = <RadioStation>[];
        for (final j in data) {
          final s = RadioStation.fromJson(j as Map<String, dynamic>);
          if (s.streamUrl.isEmpty || _isBlocked(s)) continue; // 안 나오는 방송 빼기
          final key = _nameKey(s.name);
          if (key.isEmpty || !keys.add(key)) continue; // 같은 방송은 인기 많은 쪽 하나만
          out.add(s);
          if (out.length >= limit) break;
        }
        _mergeFavoriteFlags(out);
        return out;
      } catch (_) {}
    }
    return const [];
  }

  Future<void> fetchTopStations(String countryCode, {int limit = 200, int retryCount = 0}) async {''',
    '차 화면용 해외 인기 방송 받기')

# ───── radio_korea_screen2.dart ─────
rep(RK, '''List<RadioStation> koreanRadioStations() =>
    koreanStationsSorted.map(_RadioKoreaScreenState._toRadioStation).toList();
''', '''List<RadioStation> koreanRadioStations() =>
    koreanStationsSorted.map(_RadioKoreaScreenState._toRadioStation).toList();

/// 차 화면(안드로이드 오토)용 국내 방송: (방송, 칸 큰 글자, 칸 작은 글자, 칸 색)
/// 라디오 화면 순서 그대로 · 칸 색은 '방송사별' 칸과 같은 색
List<(RadioStation, String, String, int)> koreanStationsForCar() => [
      for (final k in koreanStationsSorted)
        (
          _RadioKoreaScreenState._toRadioStation(k),
          k.broadcaster == '공동체' ? k.name.split(' ').first : k.broadcaster,
          [
            k.broadcaster != '공동체' && k.name.startsWith(k.broadcaster)
                ? k.name.substring(k.broadcaster.length).trim()
                : k.name,
            if (k.subLabel.isNotEmpty && k.subLabel != '서울') k.subLabel,
          ].where((x) => x.isNotEmpty).join(' · '),
          (_BroadcasterGridScreen._cardColors[_BroadcasterGridScreen._keyOf(k.broadcaster)] ??
                  const Color(0xFF3A342A))
              .value,
        ),
    ];
''', '차 화면용 국내 방송 (방송사 색 칸)')

# ───── headset_resume.dart ─────
rep(HR, '''import '../screens/radio_korea_screen2.dart' show koreanRadioStations;
''', '''import '../screens/radio_korea_screen2.dart' show koreanRadioStations;
import 'car_browse.dart';
''', '차 화면 불러오기')
rep(HR, '''    if (method != 'onHeadsetConnected' || mode.value == 0) return;
''', '''    if (method != 'onHeadsetConnected' || mode.value == 0) return;
    if (CarBrowse.inCarRecently) return; // 차(안드로이드 오토)에 연결 중이면 저절로 틀지 않기 (구글 규칙)
''', '차에 연결 중이면 이어서 듣기 안 하기')
rep(HR, '''  static Future<List<Song>> _screenOrder(List<Song> songs) async {''', '''  /// 차 화면 '전체 곡'도 음악 화면과 같은 순서로
  static Future<List<Song>> screenOrder(List<Song> songs) => _screenOrder(songs);

  static Future<List<Song>> _screenOrder(List<Song> songs) async {''', '음악 화면 순서 같이 쓰기')

# ───── MainActivity.kt (이어폰 연결 알아채기) ─────
rep(MA, '''            if (added == null || added.none { it.isSink && isHeadset(it.type) }) return
''', '''            if (added == null || added.none { it.isSink && isHeadset(it.type) }) return
            // 차(안드로이드 오토 · 차 블루투스)면 저절로 틀지 않기 (구글 차 앱 규칙: 자동 재생 금지)
            if (added.any { it.isSink && isHeadset(it.type) && isCar(it) }) return
''', '차 블루투스는 이어서 듣기 안 하기')
rep(MA, '''    fun start(ctx: android.content.Context, ch: MethodChannel) {
        channel = ch
''', '''    private var appCtx: android.content.Context? = null

    /// 차인지: 폰이 차 모드(안드로이드 오토)거나, 블루투스 기기 종류가 차 오디오·핸즈프리
    private fun isCar(d: AudioDeviceInfo): Boolean {
        val ctx = appCtx ?: return false
        try {
            val ui = ctx.getSystemService(android.content.Context.UI_MODE_SERVICE) as android.app.UiModeManager
            if (ui.currentModeType == android.content.res.Configuration.UI_MODE_TYPE_CAR) return true
        } catch (_: Exception) {}
        if (d.type != AudioDeviceInfo.TYPE_BLUETOOTH_A2DP || Build.VERSION.SDK_INT < 28) return false
        return try {
            val bm = ctx.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as android.bluetooth.BluetoothManager
            val c = bm.adapter?.getRemoteDevice(d.address)?.bluetoothClass?.deviceClass
            c == android.bluetooth.BluetoothClass.Device.AUDIO_VIDEO_CAR_AUDIO ||
                c == android.bluetooth.BluetoothClass.Device.AUDIO_VIDEO_HANDSFREE
        } catch (_: Exception) {
            false // 블루투스 권한이 없으면 모름 → 앱 쪽(차 화면이 목록을 물어봤는지)으로 한 번 더 막음
        }
    }

    fun start(ctx: android.content.Context, ch: MethodChannel) {
        channel = ch
        appCtx = ctx.applicationContext
''', '차인지 알아보기')

# ───── AndroidManifest.xml ─────
rep(MAN, '''        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>''', '''        <!-- 안드로이드 오토: 음악·라디오(미디어) 앱으로 알리기 -->
        <meta-data
            android:name="com.google.android.gms.car.application"
            android:resource="@xml/automotive_app_desc" />

        <!-- 안드로이드 오토 칸 그림 (차 화면이 읽어 가는 그림 파일, 읽기만) -->
        <provider
            android:name=".ArtProvider"
            android:authorities="kr.ssing.catsong.art"
            android:exported="true" />

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>''', '안드로이드 오토 등록 · 칸 그림 주는 곳')


# ───── keep.xml (이름으로만 부르는 아이콘이 출시 빌드에서 빠지지 않게) ─────
rep(os.path.join(RES, 'raw', 'keep.xml'), '''tools:keep="@raw/water_drop,@raw/water_drop_low"''',
    '''tools:keep="@raw/water_drop,@raw/water_drop_low,@drawable/paran_ic_back15,@drawable/paran_ic_fwd30,@drawable/paran_ic_podcast"''',
    '새 아이콘 출시 빌드에서 지키기')

# ───── 확인 ─────
def gaps(t):
    return [t.count(a) - t.count(b) for a, b in ('{}', '()', '[]')]

if ok:
    for p in (MAIN_D, PP, RP, RK, HR, MA):
        if gaps(files[p][0]) != gaps(ORIG[p]):
            fail(os.path.basename(p) + ' — 괄호가 안 맞아요')
    for name, body in (('car_browse.dart', CAR_DART), ('ArtProvider.kt', ART_KT)):
        if gaps(body) != [0, 0, 0]:
            fail(name + ' — 괄호가 안 맞아요')

if not ok:
    print('\n아무것도 저장 안 했어요.')
    sys.exit(1)

for p, body, label in NEW:
    os.makedirs(os.path.dirname(p), exist_ok=True)
    files[p] = [body, True]
    print(f'✔ 새 파일 {os.path.basename(p)} — {label}')
for p, (body, crlf) in files.items():
    if crlf:
        body = body.replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(body.encode('utf-8'))
print('\n다 됐어요! 다음은 PC에서 DHU(차 화면 흉내)로 확인해요.')
