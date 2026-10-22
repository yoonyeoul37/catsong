import 'dart:async';
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
import '../screens/radio_korea_screen2.dart' show koreanStationsForCar, koreanCarGroups, koreanCarGroupOf;
import '../screens/radio_country_stations_screen.dart' show radioGenresOf, radioGenreLabel;
import '../utils/device_country.dart';
import '../utils/nature_sound_catalog.dart';
import '../utils/no_album_helper.dart';
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
  /// 색 칸 + 흰 아이콘 (음악 탭 폴더)
  static Uri _iconTile(String kind, int color) => Uri.parse('$_auth/icon?k=$kind&c=${color.toRadixString(16)}');

  /// 곡 앨범 사진 (k: 앱에서 바꾼 사진 파일 이름 · v: 사진이 바뀌면 새로 그리게 · p: 사진 없을 때 고양이 사진)
  static Uri _songArt(Song s) {
    final u = s.uri ?? '';
    return Uri.parse('$_auth/song?u=${Uri.encodeQueryComponent(u)}&k=${u.hashCode.abs()}'
        '&v=${s.albumArt?.length ?? 0}&p=${Uri.encodeQueryComponent(noAlbumImagePath(u.isEmpty ? s.title : u))}');
  }

  /// 음악 탭 폴더 색 (앱 포인트 색과 어울리는 차분한 색)
  static const _musicColors = {
    'shuffle': 0xFF4B56B8, 'recent': 0xFF2E6B5E, 'fav': 0xFF9C3D52,
    'all': 0xFF2F5E9E, 'artist': 0xFF7A5230, 'genre': 0xFF5E4785,
  };
  static Uri _musicIcon(String kind) => _iconTile(kind, _musicColors[kind]!);

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
      if (parent.startsWith('rb:') || parent.startsWith('rg:')) return await _radioFolder(parent);
      if (parent.startsWith('ps:')) return await _episodes(parent.substring(3));
    } catch (e) {
      debugPrint('차 화면 목록 오류($parent): $e');
    }
    return const [];
  }

  // 탭 순서: 앱 화면과 같게 (음악 · 라디오 · 팟캐스트 · 자연소리)
  static List<MediaItem> _root() => [
        MediaItem(id: tabMusic, title: tr.catMusic, playable: false, artUri: _icon('paran_ic_music'),
            extras: _style(browsable: _list, playable: _list)),
        MediaItem(id: tabRadio, title: tr.catRadio, playable: false, artUri: _icon('paran_ic_radio'),
            extras: _style(playable: _grid)),
        MediaItem(id: tabPodcast, title: podText('팟캐스트', 'Podcasts'), playable: false,
            artUri: _icon('paran_ic_podcast'), extras: _style(browsable: _grid, playable: _list)),
        MediaItem(id: tabNature, title: tr.natureSounds, playable: false, artUri: _icon('paran_ic_leaf'),
            extras: _style(playable: _grid)),
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

  /// 차 화면 재생 화면 그림: 차에 연결돼 있으면 지금 방송의 목록 그림(방송사 색 칸 · 로고), 아니면 null (시간대 사진)
  static Uri? nowPlayingArt() {
    if (!inCarRecently) return null;
    final st = _radio?.currentStation;
    if (st == null) return null;
    // 앱 라디오 재생 화면과 같게: 지금 하는 프로그램 사진이 있으면 그 사진 (편성표에서 받은 것)
    final img = _radio?.currentProgram?['image'];
    if (img is String && img.startsWith('http')) return _web(img, st.name, _colorOf(st.name));
    if (st.countryCode == 'KR' && !_krArt.containsKey(st.stationUuid)) {
      final korean = _korean();
      final i = korean.indexWhere((k) => k.name == st.name);
      if (i >= 0) _krArt[st.stationUuid] = _krArt[korean[i].stationUuid]!;
    }
    return _stationArt(st);
  }

  static String _initials(String name) {
    final w = name.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
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

  /// 라디오 탭: 최근에 들었어요 → 즐겨찾기 → 폴더 (국내 방송사별 · 해외 장르)
  /// 운전 중에는 차 화면이 목록을 짧게만 보여 줘서, 한 줄로 길게 두지 않고 폴더로 나눔
  /// (최근·즐겨찾기가 없으면 그 줄은 안 보임)
  static Future<List<MediaItem>> _radioTab() async {
    final radio = _radio;
    if (radio == null) return const [];
    final items = <MediaItem>[];
    final kr = _country == 'KR';
    final korean = _korean(); // 국내 방송은 해외에서도 최근·즐겨찾기에 있으면 방송사별 칸 그림으로
    void krArt(List<RadioStation> list) {
      for (final s in list) {
        if (s.countryCode != 'KR') continue;
        final i = korean.indexWhere((k) => k.name == s.name);
        if (i >= 0) _krArt[s.stationUuid] = _krArt[korean[i].stationUuid]!;
      }
    }

    // 최근에 들었어요 (5개까지)
    final recent = radio.recentlyListened.take(5).toList();
    krArt(recent);
    _radioLists['rr'] = recent;
    for (final s in recent) {
      items.add(_stationItem(s, 'rr', group: tr.homeRecentHeader));
    }
    // 즐겨찾기
    final favs = radio.favorites.toList();
    krArt(favs);
    _radioLists['rf'] = favs;
    for (final s in favs) {
      items.add(_stationItem(s, 'rf', group: tr.favorites));
    }
    if (kr) {
      // 국내: 방송사별 폴더 (KBS · MBC · SBS · EBS · CBS · TBN · 종교 · 지역 민방 · 공동체)
      _radioLists['rk'] = korean;
      final byKey = <String, List<RadioStation>>{};
      for (final s in korean) {
        byKey.putIfAbsent(koreanCarGroupOf(s.name), () => []).add(s);
      }
      for (final (key, label, color) in koreanCarGroups()) {
        final list = byKey[key];
        if (list == null || list.isEmpty) continue;
        _radioLists['rb:$key'] = list;
        items.add(_folderItem('rb:$key', label, list.length, _tile(label, '', color), tr.byBroadcaster));
      }
    } else {
      // 해외: 장르 폴더 (앱 해외 라디오 '장르' 칩과 같은 묶음 · 방송 많은 장르부터 10개 · 나머지는 기타)
      final top = await _overseasTop(_country);
      _radioLists['ro'] = top;
      final byG = <String, List<RadioStation>>{};
      for (final s in top) {
        for (final g in radioGenresOf(s)) {
          byG.putIfAbsent(g, () => []).add(s);
        }
      }
      final keys = byG.keys.where((k) => byG[k]!.length >= 2).toList()
        ..sort((a, b) => byG[b]!.length.compareTo(byG[a]!.length));
      final shown = keys.take(10).toList();
      if (shown.isEmpty) {
        // 장르 정보가 거의 없는 나라: 예전처럼 인기 방송 한 묶음
        for (final s in top) {
          items.add(_stationItem(s, 'ro', group: tr.popularTab, sub: s.genre.isEmpty ? null : s.genre));
        }
        return items;
      }
      final inFolder = <String>{
        for (final k in shown)
          for (final s in byG[k]!) s.stationUuid,
      };
      for (final k in shown) {
        final label = radioGenreLabel(k);
        _radioLists['rg:$k'] = byG[k]!;
        items.add(_folderItem('rg:$k', label, byG[k]!.length, _tile(label, '', _colorOf(k)), tr.genre));
      }
      final etc = top.where((s) => !inFolder.contains(s.stationUuid)).toList();
      if (etc.isNotEmpty) {
        _radioLists['rg:기타'] = etc;
        items.add(_folderItem('rg:기타', tr.categoryEtc, etc.length, _tile(tr.categoryEtc, '', 0xFF3A342A), tr.genre));
      }
    }
    return items;
  }

  /// 폴더 칸 (누르면 그 방송사·장르 방송만 — 칸 모양으로)
  static MediaItem _folderItem(String id, String title, int n, Uri art, String group) => MediaItem(
        id: id,
        title: title,
        displaySubtitle: '$n',
        artist: '$n',
        playable: false,
        artUri: art,
        extras: {_group: group, ..._style(playable: _grid)},
      );

  /// 폴더 안 (방송사별 · 장르)
  static Future<List<MediaItem>> _radioFolder(String key) async {
    var list = _radioLists[key];
    if (list == null) {
      await _radioTab(); // 앱이 막 켜졌으면 목록부터
      list = _radioLists[key] ?? const <RadioStation>[];
    }
    final genre = key.startsWith('rg:');
    return [for (final s in list) _stationItem(s, key, sub: genre && s.genre.isNotEmpty ? s.genre : null)];
  }

  /// 라디오 목록이 바뀌면 라디오 탭 + 열어 둔 장르 폴더도 다시
  static void _changedRadio() {
    _changed(tabRadio);
    for (final k in _subjects.keys.where((k) => k.startsWith('rg:')).toList()) {
      _changed(k);
    }
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
        if (l.isNotEmpty) _changedRadio(); // 늦게 오면 그때 바꿔 끼우기
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
        if (had) _changedRadio(); // 저장된 걸 먼저 보여 줬으면 → 새 목록으로 바꿔 끼우기
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
        artUri: _songArt(s),
        extras: group == null ? null : {_group: group},
      );

  static List<MediaItem> _musicTab() {
    final m = _music;
    if (m != null && m.allSongs.isEmpty && !m.isLoading) {
      m.initialize().then((_) => _changed(tabMusic)); // 처음이면 곡 불러오고 다시
    }
    MediaItem folder(String id, String title, String icon, {String? sub}) => MediaItem(
        id: 'ml:$id', title: title, displaySubtitle: sub, artist: sub, playable: false,
        artUri: _musicIcon(icon), extras: _style(browsable: _list, playable: _list));
    final all = m?.allSongs.length ?? 0;
    return [
      // 맨 위: 랜덤 재생 (누르면 내 곡 전체를 섞어서 바로 — 음악 화면 랜덤 듣기와 같음, 곡이 없으면 안 보임)
      if (all > 0)
        MediaItem(
            id: 'mshuffle', title: tr.shufflePlay, displaySubtitle: '$all', artist: '$all', playable: true,
            artUri: _musicIcon('shuffle')),
      folder('recent', tr.homeRecentHeader, 'recent'),
      folder('fav', tr.favorites, 'fav'),
      folder('all', tr.all, 'all', sub: all > 0 ? '$all' : null),
      folder('artists', tr.artists, 'artist'),
      folder('genres', tr.genre, 'genre'),
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
              artUri: _tile(key == 'artists' ? _initials(n) : n, '', _colorOf(n)), // 이름 글자 색 칸
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
      } else if (id == 'mshuffle') {
        final songs = List<Song>.from(await _songsOf('all'))..shuffle();
        if (songs.isNotEmpty) await pp.playFromList(songs, 0);
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
    return t.replaceAll(RegExp(r'[\s\.\-·_()]'), '');
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
      for (final key in ['rr', 'rf', 'rk', 'ro']) {
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
      final list = [for (final r in (await _find(query)).take(30)) r.$2];
      // 확인용: 차 화면이 보낸 글자(글자 번호까지)와 찾은 개수
      debugPrint('차 화면 검색: "$query" [${query.runes.map((r) => r.toRadixString(16)).join(' ')}] → ${list.length}개');
      return list;
    } catch (e) {
      debugPrint('차 화면 검색 오류: $e');
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
