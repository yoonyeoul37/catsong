import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/alarm_ring_screen.dart';

/// 아침 알람 하나 (시간 · 요일 · 깨울 소리)
class ParanAlarm {
  bool enabled;
  int hour;
  int minute;
  List<int> days; // 1=월 … 7=일, 비어 있으면 한 번만
  String kind; // music_all · music_fav · playlist · radio · nature
  String? refId; // 재생목록 id · 자연 이름
  String label; // 화면에 보여줄 이름 (예: 즐겨찾기 섞어 듣기)
  Map<String, dynamic>? station; // 라디오 채널
  double volume; // 알람 소리 크기 (0.2 ~ 1.0, 폰 미디어 볼륨을 이 크기로)

  ParanAlarm({
    this.enabled = true,
    this.hour = 7,
    this.minute = 0,
    List<int>? days,
    this.kind = 'music_all',
    this.refId,
    this.label = '음악 전체 랜덤',
    this.station,
    this.volume = 0.7,
  }) : days = days ?? [1, 2, 3, 4, 5];

  ParanAlarm copy() => ParanAlarm(
        enabled: enabled,
        hour: hour,
        minute: minute,
        days: List.of(days),
        kind: kind,
        refId: refId,
        label: label,
        station: station == null ? null : Map<String, dynamic>.from(station!),
        volume: volume,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'days': days,
        'kind': kind,
        'refId': refId,
        'label': label,
        'station': station,
        'volume': volume,
      };

  factory ParanAlarm.fromJson(Map<String, dynamic> j) => ParanAlarm(
        enabled: j['enabled'] == true,
        hour: (j['hour'] as num?)?.toInt() ?? 7,
        minute: (j['minute'] as num?)?.toInt() ?? 0,
        days: [for (final d in (j['days'] as List? ?? const [])) (d as num).toInt()],
        kind: j['kind']?.toString() ?? 'music_all',
        refId: j['refId']?.toString(),
        label: j['label']?.toString() ?? '음악 전체 랜덤',
        station: j['station'] is Map ? Map<String, dynamic>.from(j['station'] as Map) : null,
        volume: ((j['volume'] as num?)?.toDouble() ?? 0.7).clamp(0.2, 1.0),
      );
}

/// 아침 알람: 저장 · 폰 알람 시계에 예약 · 울릴 때 알람 화면 띄우기
class AlarmService {
  static const _ch = MethodChannel('kr.ssing.catsong/alarm');
  static const _key = 'paranAlarm';
  static const _snoozeKey = 'paranAlarmSnooze';
  static const _autoKey = 'paranAlarmAuto'; // 안 꺼서 저절로 다시 울린 횟수

  /// 어느 화면에서든 알람 화면을 띄우기 위한 열쇠 (MaterialApp에 연결)
  static final navKey = GlobalKey<NavigatorState>();

  /// 지금 알람 (없으면 null) — 더보기 메뉴 카드가 이걸 보고 바뀜
  static final ValueNotifier<ParanAlarm?> alarm = ValueNotifier(null);

  /// 알람 때문에 앱이 켜졌는지 (첫인사·인트로 건너뛰기)
  static bool launchedByAlarm = false;
  static bool _ringing = false;

  /// 알람 화면이 뜰 때 부르기 (첫인삿말 멈추기용)
  static VoidCallback? onRingStart;

  /// 앱 켤 때 한 번 (runApp 전에)
  static Future<void> init() async {
    _ch.setMethodCallHandler((call) async {
      // 약관 페이지의 홈 버튼 → 앱 홈 화면까지 돌아가기
      if (call.method == 'goHome') {
        navKey.currentState?.popUntil((r) => r.isFirst);
        return null;
      }
      if (call.method == 'alarmFired') {
        try {
          await _ch.invokeMethod('takeLaunchAlarm'); // 다음에 켤 때 또 울리지 않게
        } catch (_) {}
        showRing();
      }
      return null;
    });
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s != null) alarm.value = ParanAlarm.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {}
    try {
      launchedByAlarm = await _ch.invokeMethod('takeLaunchAlarm') == true;
    } catch (_) {}
    // 혹시 예약이 지워졌어도 다시 걸어두기 (울려서 켜진 거면 다음 알람으로)
    final a = alarm.value;
    if (a != null && a.enabled && !launchedByAlarm) _scheduleNext(a);
  }

  /// 다음에 울릴 시각 (꺼져 있거나 못 찾으면 null)
  static DateTime? nextTime(ParanAlarm a, [DateTime? from]) {
    if (!a.enabled) return null;
    final now = from ?? DateTime.now();
    for (var d = 0; d <= 7; d++) {
      final t = DateTime(now.year, now.month, now.day + d, a.hour, a.minute);
      if (t.isAfter(now) && (a.days.isEmpty || a.days.contains(t.weekday))) return t;
    }
    return null;
  }

  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  /// 예: 오전 7:00
  static String timeText(int hour, int minute) {
    final ampm = hour < 12 ? '오전' : '오후';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$ampm $h:${minute.toString().padLeft(2, '0')}';
  }

  /// 예: 내일 오전 7:00 / 월요일 오전 7:00
  static String nextLabel(ParanAlarm a) {
    final t = nextTime(a);
    if (t == null) return '';
    final now = DateTime.now();
    final diff = DateTime(t.year, t.month, t.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final day = diff == 0 ? '오늘' : (diff == 1 ? '내일' : '${_dayNames[t.weekday - 1]}요일');
    return '$day ${timeText(t.hour, t.minute)}';
  }

  /// 예: 평일 · 주말 · 매일 · 한 번만 · 월 수 금
  static String daysText(List<int> days) {
    final s = days.toSet();
    if (s.isEmpty) return '한 번만';
    if (s.length == 7) return '매일';
    if (s.length == 5 && s.containsAll([1, 2, 3, 4, 5])) return '평일';
    if (s.length == 2 && s.containsAll([6, 7])) return '주말';
    return [for (var d = 1; d <= 7; d++) if (s.contains(d)) _dayNames[d - 1]].join(' ');
  }

  static Future<bool> canExact() async {
    try {
      return await _ch.invokeMethod('canExact') != false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openExactSettings() async {
    try {
      await _ch.invokeMethod('openExactSettings');
    } catch (_) {}
  }

  /// 안드로이드 14 이상: 잠금화면 위로 알람 화면 띄우기(전체 화면 알림) 허용됐는지
  static Future<bool> canFullScreen() async {
    try {
      return await _ch.invokeMethod('canFullScreen') != false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openFullScreenSettings() async {
    try {
      await _ch.invokeMethod('openFullScreenSettings');
    } catch (_) {}
  }

  /// 저장 + 예약. 권한(알람 및 리마인더)이 없으면 false
  static Future<bool> save(ParanAlarm a) async {
    alarm.value = a.copy();
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(a.toJson()));
    await p.remove(_snoozeKey);
    if (!a.enabled) {
      await _cancel();
      return true;
    }
    if (!await canExact()) return false;
    return _scheduleNext(a);
  }

  static Future<bool> _scheduleNext(ParanAlarm a) async {
    final p = await SharedPreferences.getInstance();
    // 5분 뒤 다시가 남아 있으면 그게 먼저
    final snooze = p.getInt(_snoozeKey) ?? 0;
    final t = snooze > DateTime.now().millisecondsSinceEpoch
        ? DateTime.fromMillisecondsSinceEpoch(snooze)
        : nextTime(a);
    if (t == null) {
      await _cancel();
      return true;
    }
    try {
      // 시간 규칙도 같이 넘김 → 폰을 껐다 켜도 다시 예약할 수 있게
      return await _ch.invokeMethod('schedule', {
            'at': t.millisecondsSinceEpoch,
            'hour': a.hour,
            'minute': a.minute,
            'days': a.days.join(','),
          }) !=
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _cancel() async {
    try {
      await _ch.invokeMethod('cancel');
    } catch (_) {}
  }

  /// 지금 화면이 알람으로 열렸는지 폰에 직접 물어보기 (신호가 늦게 와도 확실하게)
  static Future<bool> isAlarmIntent() async {
    try {
      return await _ch.invokeMethod('isAlarmIntent') == true;
    } catch (_) {
      return false;
    }
  }

  /// 알람 화면 띄우기 (화면이 아직 준비 안 됐으면 조금 기다렸다가)
  static Future<void> showRing() async {
    if (_ringing) return;
    _ringing = true;
    launchedByAlarm = true; // 리뷰·업데이트 창도 안 띄우게
    onRingStart?.call(); // 첫인삿말 바로 멈추기
    for (var i = 0; i < 20 && navKey.currentState == null; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    final nav = navKey.currentState;
    if (nav == null) {
      _ringing = false;
      return;
    }
    await nav.push(MaterialPageRoute(builder: (_) => const AlarmRingScreen(), fullscreenDialog: true));
    _ringing = false;
  }

  /// [끄기] · [계속 듣기]: 한 번만이면 끄고, 반복이면 다음 알람 예약
  static Future<void> dismiss() async {
    try {
      await _ch.invokeMethod('ringDone');
    } catch (_) {}
    final p = await SharedPreferences.getInstance();
    await p.remove(_snoozeKey);
    await p.remove(_autoKey);
    final a = alarm.value;
    if (a == null) return;
    if (a.days.isEmpty) {
      a.enabled = false;
      await save(a);
    } else {
      await _scheduleNext(a);
    }
  }

  // ───── 알람 소리 크기 · 기본 알람 소리 (안드로이드 쪽) ─────

  /// 폰 미디어 볼륨 (0.0 ~ 1.0)
  static Future<double?> getMusicVolume() async {
    try {
      return (await _ch.invokeMethod('getMusicVolume') as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMusicVolume(double v) async {
    try {
      await _ch.invokeMethod('setMusicVolume', {'v': v});
    } catch (_) {}
  }

  /// 폰 기본 알람 소리 (인터넷도 안 되고 노래도 없을 때)
  static Future<void> playFallback() async {
    try {
      await _ch.invokeMethod('playFallback');
    } catch (_) {}
  }

  static Future<void> stopFallback() async {
    try {
      await _ch.invokeMethod('stopFallback');
    } catch (_) {}
  }

  /// [5분 뒤 다시]
  static Future<void> snooze() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_autoKey);
    await _snoozeRaw();
  }

  /// 지금 몇 번째로 저절로 다시 울리는 건지 (0 = 처음)
  static Future<int> autoRound() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_autoKey) ?? 0;
  }

  /// 10분 울려도 안 끄면: 5분 쉬고 다시 (모두 3번까지), 3번째도 안 끄면 그만
  static Future<void> autoSnooze() async {
    final p = await SharedPreferences.getInstance();
    final r = (p.getInt(_autoKey) ?? 0) + 1;
    if (r >= 3) {
      await dismiss();
      return;
    }
    await p.setInt(_autoKey, r);
    await _snoozeRaw();
  }

  static Future<void> _snoozeRaw() async {
    try {
      await _ch.invokeMethod('ringDone');
    } catch (_) {}
    final at = DateTime.now().add(const Duration(minutes: 5));
    final p = await SharedPreferences.getInstance();
    await p.setInt(_snoozeKey, at.millisecondsSinceEpoch);
    try {
      await _ch.invokeMethod('schedule', {'at': at.millisecondsSinceEpoch});
    } catch (_) {}
  }
}

