import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext;
import '../widgets/paran_dialog.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import 'cast_service.dart';
import '../providers/recent_content_provider.dart';
import '../providers/music_provider.dart';
import '../models/recent_content_entry.dart';
import '../models/radio_station.dart';
import '../l10n/locale_holder.dart';
import '../utils/nature_sound_catalog.dart';

/// 이어폰·블루투스를 연결하면 듣던 것 이어서 듣기
/// 0 끄기 · 1 알림으로 묻기 · 2 바로 재생 (작게 시작해서 천천히 커짐)
class HeadsetResume {
  static final mode = ValueNotifier<int>(0);
  static List<String> get names => [tr.headsetOff, tr.headsetAsk, tr.headsetPlay];
  static const _ch = MethodChannel('kr.ssing.catsong/media');
  static PlayerProvider? _pp;
  static RadioProvider? _radio;
  static Timer? _fade;

  static Future<void> init(PlayerProvider pp, RadioProvider radio) async {
    _pp = pp;
    _radio = radio;
    try {
      final p = await SharedPreferences.getInstance();
      mode.value = p.getInt('headsetResumeMode') ?? 0;
    } catch (_) {}
  }

  /// 배터리 사용 "제한 없음" 부탁 — 필요한 기능을 켤 때만, 기능마다 한 번만
  /// (이미 제한 없음이면 안 물어봄)
  static Future<void> askBattery(BuildContext context, String key, String why) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool('battery_ask_$key') ?? false) return;
      final optimized = await _ch.invokeMethod('isBatteryOptimized');
      if (optimized != true || !context.mounted) return;
      await p.setBool('battery_ask_$key', true);
      final go = await showParanConfirm(
        context,
        title: tr.batteryTitle,
        message: why,
        confirmLabel: tr.allowAction,
        cancelLabel: tr.later,
      );
      if (go) await _ch.invokeMethod('requestBatteryOptimization');
    } catch (_) {}
  }

  static Future<void> setMode(int m) async {
    mode.value = m;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('headsetResumeMode', m);
    } catch (_) {}
  }

  /// 이어서 들을 게 있으면 (종류, 이름) — 없으면 null
  static (String, String)? _target() {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return null;
    if (CastService.instance.isConnected) return null; // TV로 듣는 중
    if (pp.volumeLocked) return null; // 알람 울리는 중
    if (pp.isPlaying || radio.isPlaying || radio.isLoading) return null; // 이미 듣는 중
    final st = radio.currentStation;
    if (st != null) return ('radio', st.name);
    final nature = pp.natureSoundName;
    if (nature != null) return ('nature', natureName(nature));
    final song = pp.currentSong;
    if (song != null) return ('music', '${song.titleDisplay} · ${song.artistDisplay}');
    return null;
  }

  /// 안드로이드에서 오는 신호 (연결됨 / 알림의 재생 누름)
  static Future<void> onCall(String method) async {
    if (method == 'onHeadsetResume') {
      await _resume();
      return;
    }
    if (method != 'onHeadsetConnected' || mode.value == 0) return;
    final t = _target();
    if (t == null) return;
    if (mode.value == 1) {
      try {
        await _ch.invokeMethod('showHeadsetAsk', {'title': tr.resumeAsk, 'text': t.$2});
      } catch (_) {}
    } else {
      await Future.delayed(const Duration(milliseconds: 900)); // 소리 길이 이어폰으로 바뀔 시간
      await _resume();
    }
  }

  static Future<void> _resume() async {
    final t = _target();
    final pp = _pp, radio = _radio;
    if (t == null || pp == null || radio == null) return;
    _fade?.cancel();
    try {
      switch (t.$1) {
        case 'radio':
          await radio.setAlarmVolume(0.05);
          await radio.playStation(radio.currentStation!);
          _rampUp((v) => radio.setAlarmVolume(v));
        case 'nature':
          await pp.player.setVolume(0.05);
          pp.resumeNatureSound(); // 기다리지 않음 (기다리면 소리 키우기가 시작 안 됨)
          _rampUp((v) => pp.player.setVolume(v));
        default:
          final full = pp.normGain; // 곡마다 소리 크기 맞추기 값까지만
          await pp.player.setVolume(0.05 * full);
          pp.togglePlayPause(); // 기다리지 않음 (기다리면 소리 키우기가 시작 안 됨)
          _rampUp((v) => pp.player.setVolume(v * full));
      }
    } catch (e) {
      debugPrint('이어서 듣기 오류: $e');
    }
  }

  // ───── 홈 위젯 재생 버튼 ─────
  static RecentContentProvider? _recent;
  static MusicProvider? _music;
  static void attachRecent(RecentContentProvider r, MusicProvider m) {
    _recent = r;
    _music = m;
    // 마지막에 튼 것 기억 (30초 안 들었어도) → 위젯 재생 버튼이 이걸 이어서
    _radio?.addListener(_rememberLast);
    _pp?.addListener(_rememberLast);
    r.addListener(saveWidgetList); // 최근 목록이 바뀌면 4×3 위젯 아래 줄도
    saveWidgetList();
  }

  static String _lastKey = '';
  static void _rememberLast() {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return;
    String key;
    Map<String, dynamic> data;
    final st = radio.currentStation;
    final song = pp.currentSong;
    final nature = pp.natureSoundName;
    if (radio.isPlaying && st != null) {
      key = 'radio|${st.stationUuid}';
      data = {'type': 'radio', 'station': st.toJson()};
      final js = jsonEncode(st.toJson());
      SharedPreferences.getInstance().then((p) => p.setString('widget_last_radio', js));
    } else if (pp.isPlaying && nature != null) {
      final i = PlayerProvider.natureSoundOrder.indexWhere((s) => s['name'] == nature);
      if (i < 0) return;
      key = 'nature|$nature';
      SharedPreferences.getInstance().then((p) => p.setString('widget_last_nature', nature));
      data = {'type': 'nature', 'name': nature, 'path': PlayerProvider.natureSoundOrder[i]['assetPath']};
    } else if (pp.isPlaying && song?.uri != null) {
      key = 'music|${song!.uri}';
      data = {'type': 'music', 'uri': song.uri};
    } else {
      return;
    }
    if (key == _lastKey) return; // 바뀔 때만 저장
    _lastKey = key;
    final isMusic = data['type'] == 'music';
    SharedPreferences.getInstance().then((p) => p.setBool('w_music', isMusic)); // 위젯 섞기·반복 보이기
    SharedPreferences.getInstance().then((p) => p.setString('widget_last_played', jsonEncode(data)));
    // 4×3 위젯 아래 줄: 지금 듣는 종류에 맞춰 다시 고르기
    final kind = data['type'] as String;
    SharedPreferences.getInstance().then((p) => p.setString('w_kind', kind)).then((_) => saveWidgetList());
  }

  /// 기억해 둔 '마지막에 튼 것' 틀기 (못 틀면 false)
  static Future<bool> _playSaved(Map<String, dynamic> d, RecentContentProvider r) async {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return false;
    switch (d['type']) {
      case 'radio':
        final st = RadioStation.fromJson(Map<String, dynamic>.from(d['station'] as Map));
        // 다음·이전용 목록: 이 방송 + 최근에 들은 다른 방송들
        final list = <RadioStation>[st];
        for (final x in r.entries) {
          if (x.type == RecentContentType.radio && x.stationData != null) {
            try {
              final s = RadioStation.fromJson(x.stationData!);
              if (s.stationUuid != st.stationUuid) list.add(s);
            } catch (_) {}
          }
        }
        radio.setQueue(list, 0);
        await radio.playStation(st);
        return true;
      case 'nature':
        await pp.playNatureSound(d['path'] as String, d['name'] as String);
        return true;
      case 'music':
        final m = _music;
        if (m == null) return false;
        for (var k = 0; k < 40 && m.allSongs.isEmpty; k++) {
          await Future.delayed(const Duration(milliseconds: 250));
        }
        final all = m.songs.isNotEmpty ? m.songs : m.allSongs;
        final i = all.indexWhere((s) => s.uri == d['uri']);
        if (i < 0) return false;
        await pp.playFromList(all, i); // 그 곡부터 목록 순서대로 계속
        return true;
    }
    return false;
  }

  /// 위젯 재생 버튼: 듣는 중이면 멈춤, 멈춰 있으면 이어서,
  /// 앱을 켜고 아무것도 안 틀었으면 '최근에 들었어요' 맨 앞의 것
  static DateTime _lastWidgetPlay = DateTime(2000);

  /// 위젯 아래 버튼: 음악(내 목록 첫 곡부터) · 라디오(마지막에 듣던 방송) · 자연(마지막에 듣던 소리)
  /// 같은 종류가 이미 나오고 있으면 → 멈춤 / 다시
  static Future<void> widgetPlayKind(String kind) async {
    final pp = _pp, radio = _radio, r = _recent;
    if (pp == null || radio == null || r == null) return;
    _lastWidgetPlay = DateTime.now(); // 재생 버튼 신호가 같이 와도 겹치지 않게
    if (kind.startsWith('recent:')) {
      await _playRecent(kind.substring(7), pp, radio, r); // 4×3 위젯 '최근에 들었어요' 줄
      return;
    }
    final nowRadio = radio.isPlaying || radio.isLoading;
    final nowNature = pp.isPlaying && pp.natureSoundName != null;
    final nowMusic = pp.isPlaying && pp.natureSoundName == null && pp.currentSong != null;
    try {
      switch (kind) {
        case 'music':
          if (nowMusic) {
            await pp.togglePlayPause(); // 듣는 중이면 멈춤
            return;
          }
          final m = _music;
          if (m == null) return;
          if (m.allSongs.isEmpty && !m.isLoading) m.initialize();
          for (var k = 0; k < 40 && m.allSongs.isEmpty; k++) {
            await Future.delayed(const Duration(milliseconds: 250));
          }
          final all = m.songs.isNotEmpty ? m.songs : m.allSongs;
          if (all.isNotEmpty) pp.playFromList(all, 0); // 첫 곡부터 목록 순서대로
          break;
        case 'radio':
          if (nowRadio) {
            await radio.togglePlayPause();
            return;
          }
          // 마지막에 듣던 방송 (없으면 최근에 들은 방송) + 다음·이전용 목록
          final list = <RadioStation>[];
          final rp = await SharedPreferences.getInstance();
          final saved = rp.getString('widget_last_radio');
          if (saved != null) {
            try {
              list.add(RadioStation.fromJson(Map<String, dynamic>.from(jsonDecode(saved) as Map)));
            } catch (_) {}
          }
          for (final x in r.entries) {
            if (x.type == RecentContentType.radio && x.stationData != null) {
              try {
                final s = RadioStation.fromJson(x.stationData!);
                if (!list.any((e) => e.stationUuid == s.stationUuid)) list.add(s);
              } catch (_) {}
            }
          }
          // 그래도 없으면 라디오 화면의 최근 목록 → 즐겨찾기
          for (final s in [...radio.recentlyListened, ...radio.favorites]) {
            if (!list.any((e) => e.stationUuid == s.stationUuid)) list.add(s);
          }
          if (list.isEmpty) return;
          radio.setQueue(list, 0);
          await radio.playStation(list.first);
          break;
        case 'nature':
          if (nowNature) {
            await pp.pauseNatureSound();
            return;
          }
          // 마지막에 듣던 자연 소리 (없으면 첫 번째 자연 소리)
          final np = await SharedPreferences.getInstance();
          final name = np.getString('widget_last_nature');
          final order = PlayerProvider.natureSoundOrder;
          final i = order.indexWhere((s) => s['name'] == name);
          final pick = order[i >= 0 ? i : 0];
          pp.playNatureSound(pick['assetPath']!, pick['name']!);
          break;
      }
    } catch (err) {
      debugPrint('위젯 버튼 재생 오류: $err');
    }
  }
  /// 4×3 위젯 아래 3줄 고르기 — 지금 듣는 종류에 맞춰 (지금 나오는 것은 빼고)
  /// 음악 → 최근 곡 · 라디오 → 최근 방송 (모자라면 라디오 최근·즐겨찾기) · 자연 → 최근 자연 (모자라면 다른 자연소리)
  static Future<void> saveWidgetList() async {
    final pp = _pp, radio = _radio, r = _recent;
    if (pp == null || radio == null || r == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      final kind = p.getString('w_kind') ?? (r.entries.isNotEmpty ? r.entries.first.type.name : 'music');
      final items = <Map<String, String>>[];
      void add(String type, String key, String title, String sub) {
        if (items.length >= 3 || key.isEmpty || items.any((x) => x['key'] == key)) return;
        items.add({'type': type, 'key': key, 'title': title, 'subtitle': sub});
      }

      if (kind == 'radio') {
        final now = radio.currentStation?.stationUuid;
        for (final x in r.entries) {
          if (x.type == RecentContentType.radio && x.key != now) add('radio', x.key, x.title, x.subtitle);
        }
        for (final s in [...radio.recentlyListened, ...radio.favorites]) {
          if (s.stationUuid == now) continue;
          add('radio', s.stationUuid, s.name, (s.country?.isNotEmpty ?? false) ? s.country! : tr.catRadio);
        }
      } else if (kind == 'nature') {
        final now = pp.natureSoundName;
        for (final x in r.entries) {
          if (x.type == RecentContentType.nature && x.title != now) add('nature', x.key, natureName(x.title), tr.natureSounds);
        }
        for (final s in PlayerProvider.natureSoundOrder) {
          if (s['name'] == now) continue;
          add('nature', s['assetPath']!, natureName(s['name']!), tr.natureSounds);
        }
      } else {
        final now = pp.natureSoundName == null ? pp.currentSong?.uri : null;
        // 지운 곡은 빼기 (곡 목록을 불러온 뒤에만)
        final m = _music;
        final have = (m == null || m.allSongs.isEmpty) ? null : {for (final s in m.allSongs) s.uri};
        for (final x in r.entries) {
          if (x.type == RecentContentType.music && x.key != now && (have == null || have.contains(x.key))) {
            add('music', x.key, x.title, x.subtitle);
          }
        }
      }
      await p.setString('w_list', jsonEncode(items));
      await _ch.invokeMethod('refreshWidget');
    } catch (_) {}
  }

  /// 4×3 위젯 '최근에 들었어요' 줄 ("종류|키"): 그것 바로 틀기
  /// 이미 나오고 있는 거면 멈춤 · 다시
  static Future<void> _playRecent(
      String id, PlayerProvider pp, RadioProvider radio, RecentContentProvider r) async {
    final cut = id.indexOf('|');
    if (cut < 0) return;
    final type = id.substring(0, cut);
    final key = id.substring(cut + 1);
    // 앱을 막 켰으면 기록이 불러와질 때까지 잠깐 기다리기
    for (var i = 0; i < 25 && r.entries.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    RecentContentEntry? e;
    for (final x in r.entries) {
      if (x.type.name == type && x.key == key) {
        e = x;
        break;
      }
    }
    if (e == null) {
      // 최근 기록에 없는 줄 (라디오 최근·즐겨찾기, 다른 자연소리에서 채운 것)
      try {
        if (type == 'radio') {
          for (final s in [...radio.recentlyListened, ...radio.favorites]) {
            if (s.stationUuid == key) {
              await _playSaved({'type': 'radio', 'station': s.toJson()}, r);
              return;
            }
          }
        } else if (type == 'nature') {
          for (final s in PlayerProvider.natureSoundOrder) {
            if (s['assetPath'] == key) {
              await pp.playNatureSound(key, s['name']!);
              return;
            }
          }
        }
      } catch (err) {
        debugPrint('위젯 최근 재생 오류: $err');
      }
      return;
    }
    try {
      switch (e.type) {
        case RecentContentType.radio:
          if (radio.currentStation?.stationUuid == key && (radio.isPlaying || radio.isLoading)) {
            await radio.togglePlayPause();
            return;
          }
          if (e.stationData == null) return;
          await _playSaved({'type': 'radio', 'station': e.stationData}, r);
        case RecentContentType.nature:
          if (pp.isPlaying && pp.natureSoundName == e.title) {
            await pp.pauseNatureSound();
            return;
          }
          if (e.natureAssetPath == null) return;
          await pp.playNatureSound(e.natureAssetPath!, e.title);
        case RecentContentType.music:
          if (pp.natureSoundName == null && pp.currentSong?.uri == key) {
            await pp.togglePlayPause(); // 같은 곡이면 멈춤 · 이어서
            return;
          }
          final m = _music;
          if (m != null && m.allSongs.isEmpty && !m.isLoading) m.initialize();
          await _playSaved({'type': 'music', 'uri': key}, r); // 그 곡부터 목록 순서대로
        case RecentContentType.sleep:
        case RecentContentType.podcast: // 팟캐스트는 이 기록에 안 들어감 (홈에서만 따로 섞어 보여 줌)
          break;
      }
    } catch (err) {
      debugPrint('위젯 최근 재생 오류: $err');
    }
  }

  static Future<void> widgetPlay() async {
    final pp = _pp, radio = _radio;
    if (pp == null || radio == null) return;
    if (CastService.instance.isConnected) {
      await pp.togglePlayPause(); // TV로 듣는 중
      return;
    }
    if (radio.isPlaying || radio.isLoading) {
      await radio.togglePlayPause();
      return;
    }
    if (pp.isPlaying) {
      if (pp.natureSoundName != null) {
        await pp.pauseNatureSound();
      } else {
        await pp.togglePlayPause();
      }
      return;
    }
    if (_target() != null) {
      await _resume(); // 멈춰 둔 것 이어서 (작게 시작해서 천천히)
      return;
    }
    // 위젯 표시와 재생 버튼 신호가 거의 같이 오면 한 번만
    if (DateTime.now().difference(_lastWidgetPlay).inMilliseconds < 2000) return;
    _lastWidgetPlay = DateTime.now();
    await _playLastRecent();
  }

  /// 이번에 켜고 아무것도 안 틀었으면: 최근에 들었어요 맨 앞의 것
  static Future<void> _playLastRecent() async {
    final r = _recent, pp = _pp, radio = _radio;
    if (r == null || pp == null || radio == null) return;
    // 먼저: 마지막에 튼 것 (30초 안 들었어도) — 없거나 못 틀면 아래 '최근에 들었어요' 맨 앞
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString('widget_last_played');
      if (saved != null && await _playSaved(Map<String, dynamic>.from(jsonDecode(saved) as Map), r)) return;
    } catch (err) {
      debugPrint('위젯 마지막 재생 오류: $err');
    }
    // 앱을 막 켰으면 기록이 불러와질 때까지 잠깐 기다리기
    for (var i = 0; i < 25 && r.entries.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (r.entries.isEmpty) return;
    final e = r.entries.first;
    try {
      switch (e.type) {
        case RecentContentType.radio:
          // 다음·이전으로 넘길 수 있게: 최근에 들은 방송들을 목록으로 묶어서 틀기
          final stations = <RadioStation>[];
          for (final x in r.entries) {
            if (x.type == RecentContentType.radio && x.stationData != null) {
              try {
                stations.add(RadioStation.fromJson(x.stationData!));
              } catch (_) {}
            }
          }
          if (stations.isEmpty) break;
          radio.setQueue(stations, 0);
          await radio.playStation(stations.first);
          break;
        case RecentContentType.nature:
          if (e.natureAssetPath != null) await pp.playNatureSound(e.natureAssetPath!, e.title);
          break;
        case RecentContentType.music:
          final m = _music;
          if (m == null) return;
          // 곡 목록을 다 불러올 때까지 잠깐 기다리기
          for (var i = 0; i < 40 && m.allSongs.isEmpty; i++) {
            await Future.delayed(const Duration(milliseconds: 250));
          }
          // 마지막 곡부터 시작해서 내 음악 목록 순서대로 계속 (한 곡만 나오고 끝나지 않게)
          final all = m.songs.isNotEmpty ? m.songs : m.allSongs;
          final i = all.indexWhere((s) => s.uri == e.songUri);
          if (i >= 0) await pp.playFromList(all, i);
          break;
        case RecentContentType.sleep:
        case RecentContentType.podcast: // 팟캐스트는 이 기록에 안 들어감 (홈에서만 따로 섞어 보여 줌)
          break;
      }
    } catch (err) {
      debugPrint('위젯 재생 오류: $err');
    }
  }

  /// 3초 동안 천천히 원래 크기로 (처음엔 아주 천천히)
  static void _rampUp(void Function(double v) set) {
    var step = 0;
    _fade = Timer.periodic(const Duration(milliseconds: 150), (t) {
      step++;
      final x = (step / 20).clamp(0.0, 1.0);
      set(0.05 + 0.95 * x * x);
      if (step >= 20) t.cancel();
    });
  }
}
