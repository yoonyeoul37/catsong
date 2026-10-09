# -*- coding: utf-8 -*-
# 아침 알람 3단계 (마무리)
# ① 알람 소리 크기 막대: 알람이 울릴 때 폰 미디어 볼륨을 이 크기로 → 끄면 원래대로 (기본 70%)
# ② 폰을 껐다 켜도(앱 업데이트해도) 알람이 다시 예약
# ③ 10분 동안 안 끄면 5분 쉬고 다시 · 모두 3번까지 (다시 울릴 땐 처음부터 조금 더 크게)
# ④ 인터넷도 안 되고 폰에 노래도 없으면 폰 기본 알람 소리 (자연이 15초 안에 안 나와도 노래로)
# ⑤ 알람이 켜져 있으면 저녁 7시부터 홈 오늘의 카드에 "내일 오전 7:00에 깨워 드릴게요" [바꾸기]
# - alarm_service.dart · alarm_ring_screen.dart · AlarmReceiver.kt 는 새 내용으로 바꿔요 (모두 알람 전용 파일)
# (apply_alarm_fix3.py 까지 실행한 뒤에)
import os, sys, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')
SERVICE = os.path.join(LIB, 'services', 'alarm_service.dart')
RING = os.path.join(LIB, 'screens', 'alarm_ring_screen.dart')
SCREEN = os.path.join(LIB, 'screens', 'alarm_screen.dart')
HOME = os.path.join(LIB, 'screens', 'home_screen.dart')
MANIFEST = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'AndroidManifest.xml')

NEW_SERVICE = "import 'dart:convert';\nimport 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\nimport '../screens/alarm_ring_screen.dart';\n\n/// 아침 알람 하나 (시간 · 요일 · 깨울 소리)\nclass ParanAlarm {\n  bool enabled;\n  int hour;\n  int minute;\n  List<int> days; // 1=월 … 7=일, 비어 있으면 한 번만\n  String kind; // music_all · music_fav · playlist · radio · nature\n  String? refId; // 재생목록 id · 자연 이름\n  String label; // 화면에 보여줄 이름 (예: 즐겨찾기 섞어 듣기)\n  Map<String, dynamic>? station; // 라디오 채널\n  double volume; // 알람 소리 크기 (0.2 ~ 1.0, 폰 미디어 볼륨을 이 크기로)\n\n  ParanAlarm({\n    this.enabled = true,\n    this.hour = 7,\n    this.minute = 0,\n    List<int>? days,\n    this.kind = 'music_all',\n    this.refId,\n    this.label = '음악 전체 랜덤',\n    this.station,\n    this.volume = 0.7,\n  }) : days = days ?? [1, 2, 3, 4, 5];\n\n  ParanAlarm copy() => ParanAlarm(\n        enabled: enabled,\n        hour: hour,\n        minute: minute,\n        days: List.of(days),\n        kind: kind,\n        refId: refId,\n        label: label,\n        station: station == null ? null : Map<String, dynamic>.from(station!),\n        volume: volume,\n      );\n\n  Map<String, dynamic> toJson() => {\n        'enabled': enabled,\n        'hour': hour,\n        'minute': minute,\n        'days': days,\n        'kind': kind,\n        'refId': refId,\n        'label': label,\n        'station': station,\n        'volume': volume,\n      };\n\n  factory ParanAlarm.fromJson(Map<String, dynamic> j) => ParanAlarm(\n        enabled: j['enabled'] == true,\n        hour: (j['hour'] as num?)?.toInt() ?? 7,\n        minute: (j['minute'] as num?)?.toInt() ?? 0,\n        days: [for (final d in (j['days'] as List? ?? const [])) (d as num).toInt()],\n        kind: j['kind']?.toString() ?? 'music_all',\n        refId: j['refId']?.toString(),\n        label: j['label']?.toString() ?? '음악 전체 랜덤',\n        station: j['station'] is Map ? Map<String, dynamic>.from(j['station'] as Map) : null,\n        volume: ((j['volume'] as num?)?.toDouble() ?? 0.7).clamp(0.2, 1.0),\n      );\n}\n\n/// 아침 알람: 저장 · 폰 알람 시계에 예약 · 울릴 때 알람 화면 띄우기\nclass AlarmService {\n  static const _ch = MethodChannel('kr.ssing.catsong/alarm');\n  static const _key = 'paranAlarm';\n  static const _snoozeKey = 'paranAlarmSnooze';\n  static const _autoKey = 'paranAlarmAuto'; // 안 꺼서 저절로 다시 울린 횟수\n\n  /// 어느 화면에서든 알람 화면을 띄우기 위한 열쇠 (MaterialApp에 연결)\n  static final navKey = GlobalKey<NavigatorState>();\n\n  /// 지금 알람 (없으면 null) — 더보기 메뉴 카드가 이걸 보고 바뀜\n  static final ValueNotifier<ParanAlarm?> alarm = ValueNotifier(null);\n\n  /// 알람 때문에 앱이 켜졌는지 (첫인사·인트로 건너뛰기)\n  static bool launchedByAlarm = false;\n  static bool _ringing = false;\n\n  /// 알람 화면이 뜰 때 부르기 (첫인삿말 멈추기용)\n  static VoidCallback? onRingStart;\n\n  /// 앱 켤 때 한 번 (runApp 전에)\n  static Future<void> init() async {\n    _ch.setMethodCallHandler((call) async {\n      if (call.method == 'alarmFired') {\n        try {\n          await _ch.invokeMethod('takeLaunchAlarm'); // 다음에 켤 때 또 울리지 않게\n        } catch (_) {}\n        showRing();\n      }\n      return null;\n    });\n    try {\n      final p = await SharedPreferences.getInstance();\n      final s = p.getString(_key);\n      if (s != null) alarm.value = ParanAlarm.fromJson(jsonDecode(s) as Map<String, dynamic>);\n    } catch (_) {}\n    try {\n      launchedByAlarm = await _ch.invokeMethod('takeLaunchAlarm') == true;\n    } catch (_) {}\n    // 혹시 예약이 지워졌어도 다시 걸어두기 (울려서 켜진 거면 다음 알람으로)\n    final a = alarm.value;\n    if (a != null && a.enabled && !launchedByAlarm) _scheduleNext(a);\n  }\n\n  /// 다음에 울릴 시각 (꺼져 있거나 못 찾으면 null)\n  static DateTime? nextTime(ParanAlarm a, [DateTime? from]) {\n    if (!a.enabled) return null;\n    final now = from ?? DateTime.now();\n    for (var d = 0; d <= 7; d++) {\n      final t = DateTime(now.year, now.month, now.day + d, a.hour, a.minute);\n      if (t.isAfter(now) && (a.days.isEmpty || a.days.contains(t.weekday))) return t;\n    }\n    return null;\n  }\n\n  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];\n\n  /// 예: 오전 7:00\n  static String timeText(int hour, int minute) {\n    final ampm = hour < 12 ? '오전' : '오후';\n    final h = hour % 12 == 0 ? 12 : hour % 12;\n    return '$ampm $h:${minute.toString().padLeft(2, '0')}';\n  }\n\n  /// 예: 내일 오전 7:00 / 월요일 오전 7:00\n  static String nextLabel(ParanAlarm a) {\n    final t = nextTime(a);\n    if (t == null) return '';\n    final now = DateTime.now();\n    final diff = DateTime(t.year, t.month, t.day).difference(DateTime(now.year, now.month, now.day)).inDays;\n    final day = diff == 0 ? '오늘' : (diff == 1 ? '내일' : '${_dayNames[t.weekday - 1]}요일');\n    return '$day ${timeText(t.hour, t.minute)}';\n  }\n\n  /// 예: 평일 · 주말 · 매일 · 한 번만 · 월 수 금\n  static String daysText(List<int> days) {\n    final s = days.toSet();\n    if (s.isEmpty) return '한 번만';\n    if (s.length == 7) return '매일';\n    if (s.length == 5 && s.containsAll([1, 2, 3, 4, 5])) return '평일';\n    if (s.length == 2 && s.containsAll([6, 7])) return '주말';\n    return [for (var d = 1; d <= 7; d++) if (s.contains(d)) _dayNames[d - 1]].join(' ');\n  }\n\n  static Future<bool> canExact() async {\n    try {\n      return await _ch.invokeMethod('canExact') != false;\n    } catch (_) {\n      return true;\n    }\n  }\n\n  static Future<void> openExactSettings() async {\n    try {\n      await _ch.invokeMethod('openExactSettings');\n    } catch (_) {}\n  }\n\n  /// 안드로이드 14 이상: 잠금화면 위로 알람 화면 띄우기(전체 화면 알림) 허용됐는지\n  static Future<bool> canFullScreen() async {\n    try {\n      return await _ch.invokeMethod('canFullScreen') != false;\n    } catch (_) {\n      return true;\n    }\n  }\n\n  static Future<void> openFullScreenSettings() async {\n    try {\n      await _ch.invokeMethod('openFullScreenSettings');\n    } catch (_) {}\n  }\n\n  /// 저장 + 예약. 권한(알람 및 리마인더)이 없으면 false\n  static Future<bool> save(ParanAlarm a) async {\n    alarm.value = a.copy();\n    final p = await SharedPreferences.getInstance();\n    await p.setString(_key, jsonEncode(a.toJson()));\n    await p.remove(_snoozeKey);\n    if (!a.enabled) {\n      await _cancel();\n      return true;\n    }\n    if (!await canExact()) return false;\n    return _scheduleNext(a);\n  }\n\n  static Future<bool> _scheduleNext(ParanAlarm a) async {\n    final p = await SharedPreferences.getInstance();\n    // 5분 뒤 다시가 남아 있으면 그게 먼저\n    final snooze = p.getInt(_snoozeKey) ?? 0;\n    final t = snooze > DateTime.now().millisecondsSinceEpoch\n        ? DateTime.fromMillisecondsSinceEpoch(snooze)\n        : nextTime(a);\n    if (t == null) {\n      await _cancel();\n      return true;\n    }\n    try {\n      // 시간 규칙도 같이 넘김 → 폰을 껐다 켜도 다시 예약할 수 있게\n      return await _ch.invokeMethod('schedule', {\n            'at': t.millisecondsSinceEpoch,\n            'hour': a.hour,\n            'minute': a.minute,\n            'days': a.days.join(','),\n          }) !=\n          false;\n    } catch (_) {\n      return false;\n    }\n  }\n\n  static Future<void> _cancel() async {\n    try {\n      await _ch.invokeMethod('cancel');\n    } catch (_) {}\n  }\n\n  /// 지금 화면이 알람으로 열렸는지 폰에 직접 물어보기 (신호가 늦게 와도 확실하게)\n  static Future<bool> isAlarmIntent() async {\n    try {\n      return await _ch.invokeMethod('isAlarmIntent') == true;\n    } catch (_) {\n      return false;\n    }\n  }\n\n  /// 알람 화면 띄우기 (화면이 아직 준비 안 됐으면 조금 기다렸다가)\n  static Future<void> showRing() async {\n    if (_ringing) return;\n    _ringing = true;\n    launchedByAlarm = true; // 리뷰·업데이트 창도 안 띄우게\n    onRingStart?.call(); // 첫인삿말 바로 멈추기\n    for (var i = 0; i < 20 && navKey.currentState == null; i++) {\n      await Future.delayed(const Duration(milliseconds: 300));\n    }\n    final nav = navKey.currentState;\n    if (nav == null) {\n      _ringing = false;\n      return;\n    }\n    await nav.push(MaterialPageRoute(builder: (_) => const AlarmRingScreen(), fullscreenDialog: true));\n    _ringing = false;\n  }\n\n  /// [끄기] · [계속 듣기]: 한 번만이면 끄고, 반복이면 다음 알람 예약\n  static Future<void> dismiss() async {\n    try {\n      await _ch.invokeMethod('ringDone');\n    } catch (_) {}\n    final p = await SharedPreferences.getInstance();\n    await p.remove(_snoozeKey);\n    await p.remove(_autoKey);\n    final a = alarm.value;\n    if (a == null) return;\n    if (a.days.isEmpty) {\n      a.enabled = false;\n      await save(a);\n    } else {\n      await _scheduleNext(a);\n    }\n  }\n\n  // ───── 알람 소리 크기 · 기본 알람 소리 (안드로이드 쪽) ─────\n\n  /// 폰 미디어 볼륨 (0.0 ~ 1.0)\n  static Future<double?> getMusicVolume() async {\n    try {\n      return (await _ch.invokeMethod('getMusicVolume') as num?)?.toDouble();\n    } catch (_) {\n      return null;\n    }\n  }\n\n  static Future<void> setMusicVolume(double v) async {\n    try {\n      await _ch.invokeMethod('setMusicVolume', {'v': v});\n    } catch (_) {}\n  }\n\n  /// 폰 기본 알람 소리 (인터넷도 안 되고 노래도 없을 때)\n  static Future<void> playFallback() async {\n    try {\n      await _ch.invokeMethod('playFallback');\n    } catch (_) {}\n  }\n\n  static Future<void> stopFallback() async {\n    try {\n      await _ch.invokeMethod('stopFallback');\n    } catch (_) {}\n  }\n\n  /// [5분 뒤 다시]\n  static Future<void> snooze() async {\n    final p = await SharedPreferences.getInstance();\n    await p.remove(_autoKey);\n    await _snoozeRaw();\n  }\n\n  /// 지금 몇 번째로 저절로 다시 울리는 건지 (0 = 처음)\n  static Future<int> autoRound() async {\n    final p = await SharedPreferences.getInstance();\n    return p.getInt(_autoKey) ?? 0;\n  }\n\n  /// 10분 울려도 안 끄면: 5분 쉬고 다시 (모두 3번까지), 3번째도 안 끄면 그만\n  static Future<void> autoSnooze() async {\n    final p = await SharedPreferences.getInstance();\n    final r = (p.getInt(_autoKey) ?? 0) + 1;\n    if (r >= 3) {\n      await dismiss();\n      return;\n    }\n    await p.setInt(_autoKey, r);\n    await _snoozeRaw();\n  }\n\n  static Future<void> _snoozeRaw() async {\n    try {\n      await _ch.invokeMethod('ringDone');\n    } catch (_) {}\n    final at = DateTime.now().add(const Duration(minutes: 5));\n    final p = await SharedPreferences.getInstance();\n    await p.setInt(_snoozeKey, at.millisecondsSinceEpoch);\n    try {\n      await _ch.invokeMethod('schedule', {'at': at.millisecondsSinceEpoch});\n    } catch (_) {}\n  }\n}\n\n"
NEW_RING = "import 'dart:async';\nimport 'dart:math' as math;\nimport 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\nimport 'package:provider/provider.dart';\nimport '../models/radio_station.dart';\nimport '../models/song.dart';\nimport '../providers/music_provider.dart';\nimport '../providers/player_provider.dart';\nimport '../providers/playlist_provider.dart';\nimport '../providers/radio_provider.dart';\nimport '../services/alarm_service.dart';\n\n/// 알람이 울릴 때 화면 (잠금화면 위로 뜸) (RING_V3)\n/// - 폰 미디어 볼륨을 알람 소리 크기로 맞추고, 고른 소리를 작게 시작해서 30초쯤 동안 천천히 키움\n/// - 10분 동안 안 끄면 5분 쉬고 다시 (모두 3번까지, 다시 울릴 땐 처음부터 조금 더 크게)\n/// - 인터넷도 안 되고 노래도 없으면 폰 기본 알람 소리\nclass AlarmRingScreen extends StatefulWidget {\n  const AlarmRingScreen({super.key});\n\n  @override\n  State<AlarmRingScreen> createState() => _AlarmRingScreenState();\n}\n\nclass _AlarmRingScreenState extends State<AlarmRingScreen> {\n  static const _bg1 = Color(0xFF2B2926);\n  static const _bg2 = Color(0xFF1C1A17);\n  static const _cream = Color(0xFFF3EFE7);\n  static const _ink = Color(0xFF17140F);\n  static const _sub = Color(0xFFB8B0A2);\n  static const _days = ['월', '화', '수', '목', '금', '토', '일'];\n\n  Timer? _clock;\n  Timer? _fade;\n  double _vol = 0.15;\n  bool _radio = false; // 라디오로 울리는 중\n  bool _nature = false; // 자연으로 울리는 중\n  bool _system = false; // 폰 기본 알람 소리로 울리는 중\n  bool _done = false;\n  double? _origVol; // 알람 전 폰 미디어 볼륨 (끄면 돌려놓기)\n  Timer? _auto; // 10분 지나도 안 끄면 5분 뒤 다시\n  late final ParanAlarm _a = AlarmService.alarm.value?.copy() ?? ParanAlarm();\n\n  @override\n  void initState() {\n    super.initState();\n    _clock = Timer.periodic(const Duration(seconds: 1), (_) {\n      if (mounted) setState(() {});\n    });\n    WidgetsBinding.instance.addPostFrameCallback((_) => _start());\n  }\n\n  @override\n  void dispose() {\n    _clock?.cancel();\n    _fade?.cancel();\n    _auto?.cancel();\n    super.dispose();\n  }\n\n  // ───── 소리 ─────\n\n  Future<void> _setVol(double v) async {\n    try {\n      if (_radio) {\n        await context.read<RadioProvider>().setAlarmVolume(v);\n      } else {\n        await context.read<PlayerProvider>().player.setVolume(v);\n      }\n    } catch (_) {}\n  }\n\n  /// 노래 목록 기다리기 (알람으로 앱이 막 켜졌으면 곡을 불러오는 중이라)\n  Future<List<Song>> _songs() async {\n    final music = context.read<MusicProvider>();\n    final pl = context.read<PlaylistProvider>();\n    for (var i = 0; i < 20 && music.allSongs.isEmpty; i++) {\n      await Future.delayed(const Duration(milliseconds: 500));\n    }\n    if (!mounted) return const [];\n    List<Song> list = music.allSongs;\n    if (_a.kind == 'music_fav') {\n      list = music.favorites;\n    } else if (_a.kind == 'playlist') {\n      for (var i = 0; i < 10; i++) {\n        final found = pl.playlists.where((p) => p.id == _a.refId);\n        if (found.isNotEmpty && found.first.songs.isNotEmpty) {\n          list = found.first.songs;\n          break;\n        }\n        await Future.delayed(const Duration(milliseconds: 500));\n      }\n    }\n    if (list.isEmpty) list = music.allSongs; // 비어 있으면 전체 곡으로\n    return List<Song>.from(list)..shuffle();\n  }\n\n  Future<void> _start() async {\n    final player = context.read<PlayerProvider>();\n    final radio = context.read<RadioProvider>();\n    // 저절로 다시 울리는 거면 처음부터 조금 더 크게\n    final round = await AlarmService.autoRound();\n    _vol = (0.15 + 0.3 * round).clamp(0.15, 1.0);\n    // 폰 미디어 볼륨을 알람 소리 크기로 (끄면 원래대로)\n    _origVol = await AlarmService.getMusicVolume();\n    await AlarmService.setMusicVolume(_a.volume);\n    // 10분 지나도 안 끄면 5분 뒤 다시\n    _auto = Timer(const Duration(minutes: 10), _autoLater);\n    if (!mounted || _done) return;\n    var ok = false;\n    try {\n      if (_a.kind == 'radio' && _a.station != null) {\n        _radio = true;\n        await _setVol(_vol);\n        final st = RadioStation.fromJson(Map<String, dynamic>.from(_a.station!));\n        radio.setQueue([st], 0);\n        await radio.playStation(st);\n        ok = true;\n        // 15초 지나도 안 나오면 (인터넷 문제) 폰에 있는 노래로\n        Future.delayed(const Duration(seconds: 15), () {\n          if (mounted && !_done && _radio && !radio.isPlaying) _fallback();\n        });\n      } else if (_a.kind == 'nature') {\n        _nature = true;\n        await _setVol(_vol);\n        final n = PlayerProvider.natureSoundOrder.firstWhere((m) => m['name'] == _a.refId,\n            orElse: () => PlayerProvider.natureSoundOrder.firstWhere((m) => m['name'] == '새소리'));\n        await player.playNatureSound(n['assetPath']!, n['name']!);\n        ok = true;\n        // 15초 지나도 안 나오면 (인터넷 문제) 폰에 있는 노래로\n        Future.delayed(const Duration(seconds: 15), () {\n          if (mounted && !_done && _nature && !player.player.playing) _fallback();\n        });\n      } else {\n        final songs = await _songs();\n        if (!mounted || _done) return;\n        if (songs.isNotEmpty) {\n          await _setVol(_vol);\n          await player.playFromList(songs, 0);\n          ok = true;\n        }\n      }\n    } catch (_) {}\n    if (!ok && mounted && !_done) await _fallback();\n    // 30초쯤 동안 천천히 크게\n    _fade = Timer.periodic(const Duration(seconds: 1), (t) {\n      _vol = math.min(1.0, _vol + 0.03);\n      _setVol(_vol);\n      if (_vol >= 1.0) t.cancel();\n    });\n  }\n\n  /// 원래 소리가 안 될 때: 폰에 있는 노래 → 그것도 없으면 폰 기본 알람 소리\n  Future<void> _fallback() async {\n    final player = context.read<PlayerProvider>();\n    if (_radio) {\n      try {\n        await context.read<RadioProvider>().stopRadioAndClear();\n        await context.read<RadioProvider>().setAlarmVolume(1.0);\n      } catch (_) {}\n      _radio = false;\n    }\n    await _setVol(_vol);\n    final all = List<Song>.from(context.read<MusicProvider>().allSongs)..shuffle();\n    try {\n      if (_nature) {\n        await player.stopNatureSound();\n        _nature = false;\n      }\n      if (all.isNotEmpty) {\n        await player.playFromList(all, 0);\n      } else {\n        _system = true;\n        await AlarmService.playFallback();\n      }\n    } catch (_) {}\n  }\n\n  Future<void> _stopSound() async {\n    final player = context.read<PlayerProvider>();\n    try {\n      if (_system) {\n        await AlarmService.stopFallback();\n      } else if (_radio) {\n        await context.read<RadioProvider>().stopRadioAndClear();\n      } else if (_nature) {\n        await player.stopNatureSound();\n      } else {\n        await player.player.pause();\n      }\n    } catch (_) {}\n  }\n\n  /// 소리 크기 원래대로 (다음에 들을 때 작게 나오지 않게)\n  /// [phone] = 폰 미디어 볼륨도 알람 전으로 (계속 들을 때는 그대로)\n  Future<void> _restoreVol({bool phone = true}) async {\n    try {\n      await context.read<PlayerProvider>().player.setVolume(1.0);\n      await context.read<RadioProvider>().setAlarmVolume(1.0);\n    } catch (_) {}\n    if (phone && _origVol != null) await AlarmService.setMusicVolume(_origVol!);\n  }\n\n  // ───── 버튼 ─────\n\n  Future<void> _off() async {\n    if (_done) return;\n    _done = true;\n    HapticFeedback.mediumImpact();\n    _fade?.cancel();\n    _auto?.cancel();\n    await _stopSound();\n    await _restoreVol();\n    await AlarmService.dismiss();\n    if (mounted) Navigator.pop(context);\n  }\n\n  Future<void> _later() async {\n    if (_done) return;\n    _done = true;\n    HapticFeedback.mediumImpact();\n    _fade?.cancel();\n    _auto?.cancel();\n    await _stopSound();\n    await _restoreVol();\n    await AlarmService.snooze();\n    if (mounted) Navigator.pop(context);\n  }\n\n  Future<void> _keep() async {\n    if (_done) return;\n    _done = true;\n    _fade?.cancel();\n    _auto?.cancel();\n    if (_system) await AlarmService.stopFallback(); // 기본 알람 소리는 계속 듣기 없음\n    await _restoreVol(phone: false); // 소리는 그대로, 폰 볼륨도 지금 크기 그대로\n    await AlarmService.dismiss();\n    if (mounted) Navigator.pop(context);\n  }\n\n  /// 10분 동안 안 끄면: 5분 쉬고 다시 (3번째도 안 끄면 그만)\n  Future<void> _autoLater() async {\n    if (_done) return;\n    _done = true;\n    _fade?.cancel();\n    await _stopSound();\n    await _restoreVol();\n    await AlarmService.autoSnooze();\n    if (mounted) Navigator.pop(context);\n  }\n\n  IconData get _icon {\n    if (_a.kind == 'radio') return Icons.radio_rounded;\n    if (_a.kind == 'nature') return Icons.forest_outlined;\n    if (_a.kind == 'playlist') return Icons.queue_music_rounded;\n    if (_a.kind == 'music_fav') return Icons.favorite_border_rounded;\n    return Icons.shuffle_rounded;\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final now = DateTime.now();\n    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;\n    final ampm = now.hour < 12 ? '오전' : '오후';\n    final greet = now.hour < 12 ? '좋은 아침이에요' : '알람 시간이에요';\n    return PopScope(\n      canPop: false, // 뒤로가기로 실수로 닫히지 않게\n      child: AnnotatedRegion<SystemUiOverlayStyle>(\n        value: const SystemUiOverlayStyle(\n          statusBarColor: Colors.transparent,\n          statusBarIconBrightness: Brightness.light,\n          systemNavigationBarColor: _bg2,\n          systemNavigationBarIconBrightness: Brightness.light,\n        ),\n        child: Scaffold(\n          backgroundColor: _bg2,\n          body: Container(\n            decoration: const BoxDecoration(\n              gradient: LinearGradient(\n                begin: Alignment.topCenter,\n                end: Alignment.bottomCenter,\n                colors: [_bg1, _bg2],\n              ),\n            ),\n            child: SafeArea(\n              child: Padding(\n                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),\n                child: Column(\n                  children: [\n                    const Spacer(flex: 3),\n                    Text(greet,\n                        style: TextStyle(\n                            color: _cream.withOpacity(0.75), fontSize: 16, fontWeight: FontWeight.w500)),\n                    const SizedBox(height: 10),\n                    Row(\n                      mainAxisAlignment: MainAxisAlignment.center,\n                      crossAxisAlignment: CrossAxisAlignment.baseline,\n                      textBaseline: TextBaseline.alphabetic,\n                      children: [\n                        Text(ampm,\n                            style: const TextStyle(color: _sub, fontSize: 18, fontWeight: FontWeight.w500)),\n                        const SizedBox(width: 6),\n                        Text('$h:${now.minute.toString().padLeft(2, '0')}',\n                            style: const TextStyle(\n                                color: _cream,\n                                fontSize: 72,\n                                fontWeight: FontWeight.w300,\n                                letterSpacing: -1.5,\n                                height: 1.1)),\n                      ],\n                    ),\n                    const SizedBox(height: 6),\n                    Text('${now.month}월 ${now.day}일 ${_days[now.weekday - 1]}요일',\n                        style: const TextStyle(color: _sub, fontSize: 15)),\n                    const Spacer(flex: 2),\n                    // 깨우는 소리\n                    Container(\n                      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),\n                      decoration: BoxDecoration(\n                        color: Colors.white.withOpacity(0.06),\n                        borderRadius: BorderRadius.circular(16),\n                        border: Border.all(color: Colors.white.withOpacity(0.08)),\n                      ),\n                      child: Row(\n                        mainAxisSize: MainAxisSize.min,\n                        children: [\n                          Icon(_icon, size: 18, color: _sub),\n                          const SizedBox(width: 8),\n                          Flexible(\n                            child: Text(_a.label,\n                                maxLines: 1,\n                                overflow: TextOverflow.ellipsis,\n                                style: const TextStyle(color: _cream, fontSize: 14, fontWeight: FontWeight.w600)),\n                          ),\n                        ],\n                      ),\n                    ),\n                    const Spacer(flex: 3),\n                    SizedBox(\n                      width: double.infinity,\n                      height: 58,\n                      child: ElevatedButton(\n                        onPressed: _off,\n                        style: ElevatedButton.styleFrom(\n                          backgroundColor: _cream,\n                          foregroundColor: _ink,\n                          elevation: 0,\n                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),\n                        ),\n                        child: const Text('끄기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),\n                      ),\n                    ),\n                    const SizedBox(height: 10),\n                    SizedBox(\n                      width: double.infinity,\n                      height: 54,\n                      child: OutlinedButton(\n                        onPressed: _later,\n                        style: OutlinedButton.styleFrom(\n                          foregroundColor: _cream,\n                          side: BorderSide(color: _cream.withOpacity(0.3), width: 1.2),\n                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),\n                        ),\n                        child: const Text('5분 뒤 다시', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),\n                      ),\n                    ),\n                    const SizedBox(height: 6),\n                    TextButton(\n                      onPressed: _keep,\n                      style: TextButton.styleFrom(foregroundColor: _sub),\n                      child: const Text('알람 끄고 계속 듣기', style: TextStyle(fontSize: 13.5)),\n                    ),\n                  ],\n                ),\n              ),\n            ),\n          ),\n        ),\n      ),\n    );\n  }\n}\n"
NEW_RECEIVER = 'package kr.ssing.catsong\n\nimport android.app.AlarmManager\nimport android.app.KeyguardManager\nimport android.app.Notification\nimport android.app.NotificationChannel\nimport android.app.NotificationManager\nimport android.app.PendingIntent\nimport android.content.BroadcastReceiver\nimport android.content.Context\nimport android.content.Intent\nimport android.media.AudioAttributes\nimport android.media.RingtoneManager\nimport android.os.Build\nimport android.os.PowerManager\nimport java.util.Calendar\n\n/// 아침 알람 시간이 되면 폰이 이걸 깨움 (ALARM_MARK_V2, ALARM_MARK_V3)\n/// 안드로이드는 꺼져 있는 앱이 화면을 마음대로 띄우는 걸 막아서,\n/// "전체 화면 알림"으로 잠금화면 위에 알람 화면을 띄움\n/// - 화면이 꺼져 있으면: 기본 알람 소리 없이 조용히 알람 화면만 열고 → 고른 노래·라디오가 나옴\n///   (혹시 1분 안에 알람 화면이 안 열리면 기본 알람 소리로 한 번 더 = 꼭 깨우기)\n/// - 폰을 쓰는 중이면: 위에 알람 알림 + 기본 알람 소리 (누르면 알람 화면)\nclass AlarmReceiver : BroadcastReceiver() {\n    companion object {\n        const val CHANNEL_ID = "paran_alarm" // 소리 있는 알림\n        const val QUIET_CHANNEL_ID = "paran_alarm_quiet" // 소리 없는 알림 (바로 알람 화면이 열릴 때)\n        const val NOTI_ID = 7102\n        const val ACTION_FIRE = "kr.ssing.catsong.ALARM_FIRE"\n        const val ACTION_BACKUP = "kr.ssing.catsong.ALARM_BACKUP"\n\n        /// 알람 화면 열기 (MainActivity + paranAlarm 표시)\n        fun activityIntent(ctx: Context): PendingIntent {\n            val i = Intent(ctx, MainActivity::class.java).apply {\n                action = "kr.ssing.catsong.ALARM"\n                putExtra("paranAlarm", true)\n                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)\n            }\n            return PendingIntent.getActivity(\n                ctx, 7100, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT\n            )\n        }\n\n        private fun backupIntent(ctx: Context): PendingIntent {\n            val i = Intent(ctx, AlarmReceiver::class.java).apply { action = ACTION_BACKUP }\n            return PendingIntent.getBroadcast(\n                ctx, 7103, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT\n            )\n        }\n\n        fun cancelNotification(ctx: Context) {\n            try {\n                (ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTI_ID)\n            } catch (_: Exception) {}\n        }\n\n        // ───── 예약 기억 (폰을 껐다 켜도 다시 예약하려고) ─────\n        private const val PREFS = "paran_alarm_native"\n\n        /// 시간이 되면 이 AlarmReceiver를 깨우는 예약표\n        fun firePendingIntent(ctx: Context): PendingIntent {\n            val i = Intent(ctx, AlarmReceiver::class.java).apply { action = ACTION_FIRE }\n            return PendingIntent.getBroadcast(\n                ctx, 7100, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT\n            )\n        }\n\n        fun saveAt(ctx: Context, at: Long) {\n            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putLong("at", at).apply()\n        }\n\n        fun saveRule(ctx: Context, hour: Int, minute: Int, days: String) {\n            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()\n                .putInt("hour", hour).putInt("minute", minute).putString("days", days).apply()\n        }\n\n        fun clearRule(ctx: Context) {\n            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()\n        }\n\n        /// 폰이 켜진 뒤: 기억해둔 알람 다시 예약 (지난 시간이면 다음 요일로)\n        fun reschedule(ctx: Context) {\n            val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)\n            val at = p.getLong("at", 0L)\n            if (at == 0L) return\n            var t = at\n            val now = System.currentTimeMillis()\n            if (t <= now) {\n                val days = (p.getString("days", "") ?: "").split(\',\').mapNotNull { it.trim().toIntOrNull() }\n                if (days.isEmpty()) return // 한 번만 울리는 알람인데 이미 지남\n                val hour = p.getInt("hour", 7)\n                val minute = p.getInt("minute", 0)\n                var found = 0L\n                for (d in 0..7) {\n                    val c = Calendar.getInstance().apply {\n                        add(Calendar.DAY_OF_YEAR, d)\n                        set(Calendar.HOUR_OF_DAY, hour)\n                        set(Calendar.MINUTE, minute)\n                        set(Calendar.SECOND, 0)\n                        set(Calendar.MILLISECOND, 0)\n                    }\n                    val dow = c.get(Calendar.DAY_OF_WEEK)\n                    val day = if (dow == Calendar.SUNDAY) 7 else dow - 1 // 1=월 … 7=일\n                    if (c.timeInMillis > now && days.contains(day)) {\n                        found = c.timeInMillis\n                        break\n                    }\n                }\n                if (found == 0L) return\n                t = found\n            }\n            try {\n                val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager\n                val show = PendingIntent.getActivity(\n                    ctx, 7101, Intent(ctx, MainActivity::class.java),\n                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT\n                )\n                am.setAlarmClock(AlarmManager.AlarmClockInfo(t, show), firePendingIntent(ctx))\n                saveAt(ctx, t)\n            } catch (e: Exception) {\n                android.util.Log.e("ParanAlarm", "다시 예약 실패: ${e.message}")\n            }\n        }\n\n        // ───── 폰 기본 알람 소리 (인터넷도 안 되고 노래도 없을 때) ─────\n        private var ringtone: android.media.Ringtone? = null\n\n        fun playFallback(ctx: Context) {\n            stopFallback()\n            try {\n                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)\n                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)\n                val r = RingtoneManager.getRingtone(ctx, uri) ?: return\n                r.audioAttributes = AudioAttributes.Builder()\n                    .setUsage(AudioAttributes.USAGE_ALARM)\n                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)\n                    .build()\n                if (Build.VERSION.SDK_INT >= 28) r.isLooping = true\n                r.play()\n                ringtone = r\n            } catch (e: Exception) {\n                android.util.Log.e("ParanAlarm", "기본 알람 소리 실패: ${e.message}")\n            }\n        }\n\n        fun stopFallback() {\n            try {\n                ringtone?.stop()\n            } catch (_: Exception) {}\n            ringtone = null\n        }\n\n        /// 알람 화면이 열렸으면 "1분 뒤 한 번 더"는 취소\n        fun cancelBackup(ctx: Context) {\n            try {\n                (ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(backupIntent(ctx))\n            } catch (_: Exception) {}\n        }\n    }\n\n    override fun onReceive(ctx: Context, intent: Intent) {\n        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager\n        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)\n            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)\n\n        // 화면이 꺼져 있거나 잠겨 있고, 전체 화면 알림이 허용돼 있으면 → 바로 알람 화면이 열리니까 조용히\n        val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager\n        val km = ctx.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager\n        val inUse = pm.isInteractive && !km.isKeyguardLocked\n        val fsiOk = if (Build.VERSION.SDK_INT >= 34) nm.canUseFullScreenIntent() else true\n        val quiet = intent.action != ACTION_BACKUP && !inUse && fsiOk\n\n        if (Build.VERSION.SDK_INT >= 26) {\n            if (nm.getNotificationChannel(CHANNEL_ID) == null) {\n                val ch = NotificationChannel(CHANNEL_ID, "아침 알람", NotificationManager.IMPORTANCE_HIGH).apply {\n                    description = "파란소리 아침 알람"\n                    // 알람 소리로 (무음·진동 모드에서도 들리게)\n                    setSound(alarmUri, AudioAttributes.Builder()\n                        .setUsage(AudioAttributes.USAGE_ALARM)\n                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)\n                        .build())\n                    enableVibration(true)\n                    vibrationPattern = longArrayOf(0, 600, 400, 600)\n                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC\n                }\n                nm.createNotificationChannel(ch)\n            }\n            if (nm.getNotificationChannel(QUIET_CHANNEL_ID) == null) {\n                val ch = NotificationChannel(QUIET_CHANNEL_ID, "아침 알람 (화면 열기)", NotificationManager.IMPORTANCE_HIGH).apply {\n                    description = "잠금화면 위로 알람 화면을 열 때"\n                    setSound(null, null)\n                    enableVibration(false)\n                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC\n                }\n                nm.createNotificationChannel(ch)\n            }\n        }\n\n        val pi = activityIntent(ctx)\n        val b = if (Build.VERSION.SDK_INT >= 26) {\n            Notification.Builder(ctx, if (quiet) QUIET_CHANNEL_ID else CHANNEL_ID)\n        } else {\n            @Suppress("DEPRECATION")\n            Notification.Builder(ctx).setPriority(Notification.PRIORITY_MAX).apply {\n                if (!quiet) {\n                    setSound(alarmUri, android.media.AudioManager.STREAM_ALARM)\n                    setVibrate(longArrayOf(0, 600, 400, 600))\n                }\n            }\n        }\n        b.setSmallIcon(R.mipmap.ic_launcher)\n            .setContentTitle("아침 알람")\n            .setContentText("눌러서 알람 화면 열기")\n            .setCategory(Notification.CATEGORY_ALARM)\n            .setVisibility(Notification.VISIBILITY_PUBLIC)\n            .setFullScreenIntent(pi, true)\n            .setContentIntent(pi)\n            .setOngoing(true)\n            .setAutoCancel(true)\n        val n = b.build()\n        if (!quiet) n.flags = n.flags or Notification.FLAG_INSISTENT // 알람 화면을 열 때까지 계속 울림\n        try {\n            nm.notify(NOTI_ID, n)\n        } catch (e: SecurityException) {\n            android.util.Log.e("ParanAlarm", "알림 권한 없음: ${e.message}")\n        }\n\n        // 조용히 띄웠는데 1분 안에 알람 화면이 안 열리면 → 기본 알람 소리로 한 번 더\n        if (quiet) {\n            try {\n                val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager\n                val at = System.currentTimeMillis() + 60_000L\n                if (Build.VERSION.SDK_INT >= 23) {\n                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, backupIntent(ctx))\n                } else {\n                    am.setExact(AlarmManager.RTC_WAKEUP, at, backupIntent(ctx))\n                }\n            } catch (_: Exception) {}\n        }\n\n        // 앱이 화면에 떠 있으면 바로 알람 화면으로 (꺼져 있으면 위 알림이 대신 띄움)\n        try {\n            ctx.startActivity(Intent(ctx, MainActivity::class.java).apply {\n                action = "kr.ssing.catsong.ALARM"\n                putExtra("paranAlarm", true)\n                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)\n            })\n        } catch (_: Exception) {}\n    }\n}\n\n/// 폰을 껐다 켜거나 앱을 업데이트하면 안드로이드가 예약을 지워서 → 다시 예약\nclass AlarmBootReceiver : BroadcastReceiver() {\n    override fun onReceive(ctx: Context, intent: Intent) {\n        when (intent.action) {\n            Intent.ACTION_BOOT_COMPLETED,\n            "android.intent.action.QUICKBOOT_POWERON",\n            Intent.ACTION_MY_PACKAGE_REPLACED -> AlarmReceiver.reschedule(ctx)\n        }\n    }\n}\n'

KT_EDITS = [
    ('MainActivity: 예약할 때 시간 규칙도 기억',
     "                    \"schedule\" -> {\n"
     "                        val at = (call.argument<Any>(\"at\") as? Number)?.toLong() ?: 0L\n"
     "                        result.success(if (at > 0) scheduleParanAlarm(at) else false)\n"
     "                    }\n",
     "                    \"schedule\" -> {\n"
     "                        val at = (call.argument<Any>(\"at\") as? Number)?.toLong() ?: 0L\n"
     "                        val ok = at > 0 && scheduleParanAlarm(at)\n"
     "                        if (ok) {\n"
     "                            // 폰을 껐다 켜도 다시 예약할 수 있게 기억\n"
     "                            AlarmReceiver.saveAt(this@MainActivity, at)\n"
     "                            val h = (call.argument<Any>(\"hour\") as? Number)?.toInt()\n"
     "                            val m = (call.argument<Any>(\"minute\") as? Number)?.toInt()\n"
     "                            if (h != null && m != null) {\n"
     "                                AlarmReceiver.saveRule(this@MainActivity, h, m, call.argument<String>(\"days\") ?: \"\")\n"
     "                            }\n"
     "                        }\n"
     "                        result.success(ok)\n"
     "                    }\n"),
    ('MainActivity: 알람 끄면 기억도 지우기',
     "                    \"cancel\" -> {\n"
     "                        cancelParanAlarm()\n",
     "                    \"cancel\" -> {\n"
     "                        cancelParanAlarm()\n"
     "                        AlarmReceiver.clearRule(this@MainActivity)\n"),
    ('MainActivity: 폰 볼륨 · 기본 알람 소리',
     "                    \"isAlarmIntent\" -> {\n",
     "                    \"getMusicVolume\" -> {\n"
     "                        // 폰 미디어 볼륨 (0.0 ~ 1.0)\n"
     "                        val am = getSystemService(AUDIO_SERVICE) as AudioManager\n"
     "                        val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)\n"
     "                        result.success(if (max > 0) am.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max else 0.0)\n"
     "                    }\n"
     "                    \"setMusicVolume\" -> {\n"
     "                        val v = (call.argument<Any>(\"v\") as? Number)?.toDouble() ?: 0.7\n"
     "                        try {\n"
     "                            val am = getSystemService(AUDIO_SERVICE) as AudioManager\n"
     "                            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)\n"
     "                            am.setStreamVolume(AudioManager.STREAM_MUSIC, Math.round(v.coerceIn(0.0, 1.0) * max).toInt(), 0)\n"
     "                        } catch (_: Exception) {}\n"
     "                        result.success(true)\n"
     "                    }\n"
     "                    \"playFallback\" -> {\n"
     "                        AlarmReceiver.playFallback(this@MainActivity)\n"
     "                        result.success(true)\n"
     "                    }\n"
     "                    \"stopFallback\" -> {\n"
     "                        AlarmReceiver.stopFallback()\n"
     "                        result.success(true)\n"
     "                    }\n"
     "                    \"isAlarmIntent\" -> {\n"),
    ('MainActivity: 알람 끝나면 기본 알람 소리도 끄기',
     "                        AlarmReceiver.cancelNotification(this@MainActivity)\n"
     "                        intent?.setAction(android.content.Intent.ACTION_MAIN) // 알람 표시 지우기\n",
     "                        AlarmReceiver.cancelNotification(this@MainActivity)\n"
     "                        AlarmReceiver.stopFallback()\n"
     "                        intent?.setAction(android.content.Intent.ACTION_MAIN) // 알람 표시 지우기\n"),
]

MANIFEST_EDITS = [
    ('AndroidManifest: 폰 켜지면 알람 다시 예약',
     "            android:name=\".AlarmReceiver\"\n"
     "            android:exported=\"false\" />\n",
     "            android:name=\".AlarmReceiver\"\n"
     "            android:exported=\"false\" />\n"
     "        <!-- 아침 알람: 폰을 껐다 켜거나 앱을 업데이트하면 다시 예약 -->\n"
     "        <receiver\n"
     "            android:name=\".AlarmBootReceiver\"\n"
     "            android:exported=\"true\">\n"
     "            <intent-filter>\n"
     "                <action android:name=\"android.intent.action.BOOT_COMPLETED\"/>\n"
     "                <action android:name=\"android.intent.action.QUICKBOOT_POWERON\"/>\n"
     "                <action android:name=\"android.intent.action.MY_PACKAGE_REPLACED\"/>\n"
     "            </intent-filter>\n"
     "        </receiver>\n"),
]

SCREEN_EDITS = [
    ('알람 화면: 알람 소리 크기 막대',
     "                    ], padding: const EdgeInsets.fromLTRB(0, 14, 0, 14)),\n",
     "                    ], padding: const EdgeInsets.fromLTRB(0, 14, 0, 14)),\n"
     "                    // 알람 소리 크기 (폰 소리를 줄여 놔도 이 크기로)\n"
     "                    box([\n"
     "                      head('알람 소리 크기', '${(_a.volume * 100).round()}%'),\n"
     "                      const SizedBox(height: 6),\n"
     "                      Row(\n"
     "                        children: [\n"
     "                          Icon(Icons.volume_down_rounded, size: 20, color: hint),\n"
     "                          Expanded(\n"
     "                            child: SliderTheme(\n"
     "                              data: SliderTheme.of(context).copyWith(\n"
     "                                trackHeight: 3,\n"
     "                                activeTrackColor: point,\n"
     "                                inactiveTrackColor: line,\n"
     "                                thumbColor: point,\n"
     "                                overlayColor: point.withOpacity(0.1),\n"
     "                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),\n"
     "                              ),\n"
     "                              child: Slider(\n"
     "                                value: _a.volume.clamp(0.2, 1.0),\n"
     "                                min: 0.2,\n"
     "                                max: 1.0,\n"
     "                                divisions: 8,\n"
     "                                onChanged: (v) => setState(() => _a.volume = v),\n"
     "                              ),\n"
     "                            ),\n"
     "                          ),\n"
     "                          Icon(Icons.volume_up_rounded, size: 20, color: hint),\n"
     "                        ],\n"
     "                      ),\n"
     "                      Text('폰 소리를 줄여 놔도 이 크기로 울리고, 끄면 원래대로 돌아가요',\n"
     "                          style: TextStyle(color: hint, fontSize: 12)),\n"
     "                    ]),\n"),
]

HOME_EDITS = [
    ('홈: 알람 불러오기',
     "import '../widgets/paran_dialog.dart';\n",
     "import '../widgets/paran_dialog.dart';\n"
     "import '../services/alarm_service.dart';\n"
     "import 'alarm_screen.dart';\n"),
    ('홈 카드: 저녁엔 내일 알람 알려주기',
     "    if (kind == 2 && (weekCount == 0 || weekTop == null)) kind = 3;\n",
     "    if (kind == 2 && (weekCount == 0 || weekTop == null)) kind = 3;\n"
     "    // 아침 알람이 켜져 있으면 저녁 7시부터는 내일 알람 알려주기\n"
     "    final alarm = AlarmService.alarm.value;\n"
     "    final alarmNext = alarm != null && alarm.enabled && now.hour >= 19 ? AlarmService.nextLabel(alarm) : '';\n"
     "    if (alarmNext.isNotEmpty) kind = 5;\n"),
    ('홈 카드: 알람 카드',
     "    } else {\n"
     "      // ③ 기능 알려주기 (돌아올 때마다 다른 팁)\n",
     "    } else if (kind == 5) {\n"
     "      // ⑥ 내일 아침 알람\n"
     "      icon = Icons.alarm_rounded;\n"
     "      title = '$alarmNext에 깨워 드릴게요';\n"
     "      subLine = Text(alarm!.label,\n"
     "          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));\n"
     "      action = '바꾸기';\n"
     "      onAction = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()));\n"
     "    } else {\n"
     "      // ③ 기능 알려주기 (돌아올 때마다 다른 팁)\n"),
]


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def read(p):
    return open(p, 'rb').read().decode('utf-8')


def main():
    hits = glob.glob(os.path.join(ROOT, 'android', 'app', 'src', 'main', 'kotlin', '**', 'MainActivity.kt'),
                     recursive=True)
    if len(hits) != 1:
        print('❌ MainActivity.kt 를 못 찾았어요 (android/app/src/main/kotlin 안)')
        sys.exit(1)
    act = hits[0]
    rec = os.path.join(os.path.dirname(act), 'AlarmReceiver.kt')
    for p in (SERVICE, RING, SCREEN, HOME, MANIFEST, rec):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if 'ALARM_MARK_V3' in read(rec):
        print('이미 적용돼 있어요')
        return
    # 알람 전용 파일 3개가 예상한 버전인지 확인 (다르면 덮어쓰지 않음)
    ok = True
    if 'ALARM_MARK_V2' not in read(rec):
        print('❌ AlarmReceiver.kt 가 예상과 달라요 (apply_alarm_fix2.py 먼저)')
        ok = False
    if 'isAlarmIntent' not in read(SERVICE):
        print('❌ alarm_service.dart 가 예상과 달라요 (apply_alarm_fix3.py 먼저)')
        ok = False
    if '알람 끄고 계속 듣기' not in read(RING):
        print('❌ alarm_ring_screen.dart 가 예상과 달라요')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)

    out = []
    for path, edits, check in ((act, KT_EDITS, True), (MANIFEST, MANIFEST_EDITS, False),
                               (SCREEN, SCREEN_EDITS, True), (HOME, HOME_EDITS, True)):
        raw = read(path)
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if check and before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    for name, content in (('alarm_service.dart', NEW_SERVICE), ('alarm_ring_screen.dart', NEW_RING),
                          ('AlarmReceiver.kt', NEW_RECEIVER)):
        if not balanced(content):
            print('❌ 괄호가 안 맞아요:', name)
            ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    for path, content, name in ((SERVICE, NEW_SERVICE, 'alarm_service.dart'),
                                (RING, NEW_RING, 'alarm_ring_screen.dart'),
                                (rec, NEW_RECEIVER, 'AlarmReceiver.kt')):
        crlf = '\r\n' in read(path)
        open(path, 'wb').write((content.replace('\n', '\r\n') if crlf else content).encode('utf-8'))
        print('✔ 새 내용으로:', name)
    print('\n다 바꿨어요. 앱을 완전히 끄고 flutter run 으로 다시 켠 뒤, 알람을 한 번 더 저장해 주세요.')


if __name__ == '__main__':
    main()
