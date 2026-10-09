import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import '../models/radio_station.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/radio_provider.dart';
import '../services/alarm_service.dart';

/// 알람이 울릴 때 화면 (잠금화면 위로 뜸) (RING_V3)
/// - 폰 미디어 볼륨을 알람 소리 크기로 맞추고, 고른 소리를 작게 시작해서 30초쯤 동안 천천히 키움
/// - 10분 동안 안 끄면 5분 쉬고 다시 (모두 3번까지, 다시 울릴 땐 처음부터 조금 더 크게)
/// - 인터넷도 안 되고 노래도 없으면 폰 기본 알람 소리
class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  static const _bg1 = Color(0xFF2B2926);
  static const _bg2 = Color(0xFF1C1A17);
  static const _cream = Color(0xFFF3EFE7);
  static const _ink = Color(0xFF17140F);
  static const _sub = Color(0xFFB8B0A2);
  static const _days = ['월', '화', '수', '목', '금', '토', '일'];

  Timer? _clock;
  Timer? _fade;
  double _vol = 0.15;
  bool _radio = false; // 라디오로 울리는 중
  bool _nature = false; // 자연으로 울리는 중
  bool _system = false; // 폰 기본 알람 소리로 울리는 중
  bool _done = false;
  double? _origVol; // 알람 전 폰 미디어 볼륨 (끄면 돌려놓기)
  Timer? _auto; // 10분 지나도 안 끄면 5분 뒤 다시
  LoopMode? _prevLoop; // 한 곡 반복 전 반복 설정 (알람 끝나면 돌려놓기)
  late final ParanAlarm _a = AlarmService.alarm.value?.copy() ?? ParanAlarm();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _fade?.cancel();
    _auto?.cancel();
    super.dispose();
  }

  // ───── 소리 ─────

  Future<void> _setVol(double v) async {
    try {
      if (_radio) {
        await context.read<RadioProvider>().setAlarmVolume(v);
      } else {
        await context.read<PlayerProvider>().player.setVolume(v);
      }
    } catch (_) {}
  }

  /// 노래 목록 기다리기 (알람으로 앱이 막 켜졌으면 곡을 불러오는 중이라)
  Future<List<Song>> _songs() async {
    final music = context.read<MusicProvider>();
    final pl = context.read<PlaylistProvider>();
    for (var i = 0; i < 20 && music.allSongs.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return const [];
    List<Song> list = music.allSongs;
    if (_a.kind == 'song') {
      // 한 곡 (지워졌으면 아래에서 전체 곡으로)
      final found = music.allSongs.where((s) => s.uri == _a.refId);
      list = found.isNotEmpty ? [found.first] : const [];
    } else if (_a.kind == 'music_fav') {
      list = music.favorites;
    } else if (_a.kind == 'playlist') {
      for (var i = 0; i < 10; i++) {
        final found = pl.playlists.where((p) => p.id == _a.refId);
        if (found.isNotEmpty && found.first.songs.isNotEmpty) {
          list = found.first.songs;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (list.isEmpty) list = music.allSongs; // 비어 있으면 전체 곡으로
    return List<Song>.from(list)..shuffle();
  }

  Future<void> _start() async {
    final player = context.read<PlayerProvider>();
    final radio = context.read<RadioProvider>();
    player.volumeLocked = true; // 울리는 동안은 알람이 소리 크기를 정함
    // 저절로 다시 울리는 거면 처음부터 조금 더 크게
    final round = await AlarmService.autoRound();
    _vol = (0.15 + 0.3 * round).clamp(0.15, 1.0);
    // 폰 미디어 볼륨을 알람 소리 크기로 (끄면 원래대로)
    _origVol = await AlarmService.getMusicVolume();
    await AlarmService.setMusicVolume(_a.volume);
    // 10분 지나도 안 끄면 5분 뒤 다시
    _auto = Timer(const Duration(minutes: 10), _autoLater);
    if (!mounted || _done) return;
    var ok = false;
    try {
      if (_a.kind == 'radio' && _a.station != null) {
        _radio = true;
        await _setVol(_vol);
        final st = RadioStation.fromJson(Map<String, dynamic>.from(_a.station!));
        radio.setQueue([st], 0);
        await radio.playStation(st);
        ok = true;
        // 15초 지나도 안 나오면 (인터넷 문제) 폰에 있는 노래로
        Future.delayed(const Duration(seconds: 15), () {
          if (mounted && !_done && _radio && !radio.isPlaying) _fallback();
        });
      } else if (_a.kind == 'nature') {
        _nature = true;
        await _setVol(_vol);
        final n = PlayerProvider.natureSoundOrder.firstWhere((m) => m['name'] == _a.refId,
            orElse: () => PlayerProvider.natureSoundOrder.firstWhere((m) => m['name'] == '새소리'));
        await player.playNatureSound(n['assetPath']!, n['name']!);
        ok = true;
        // 15초 지나도 안 나오면 (인터넷 문제) 폰에 있는 노래로
        Future.delayed(const Duration(seconds: 15), () {
          if (mounted && !_done && _nature && !player.player.playing) _fallback();
        });
      } else {
        final songs = await _songs();
        if (!mounted || _done) return;
        if (songs.isNotEmpty) {
          await _setVol(_vol);
          // 한 곡이면 끌 때까지 반복
          if (_a.kind == 'song' && songs.length == 1 && songs.first.uri == _a.refId) {
            _prevLoop = player.loopMode;
            player.setLoopMode(LoopMode.one);
          }
          await player.playFromList(songs, 0);
          ok = true;
        }
      }
    } catch (_) {}
    if (!ok && mounted && !_done) await _fallback();
    // 30초쯤 동안 천천히 크게
    _fade = Timer.periodic(const Duration(seconds: 1), (t) {
      _vol = math.min(1.0, _vol + 0.03);
      _setVol(_vol);
      if (_vol >= 1.0) t.cancel();
    });
  }

  /// 원래 소리가 안 될 때: 폰에 있는 노래 → 그것도 없으면 폰 기본 알람 소리
  Future<void> _fallback() async {
    final player = context.read<PlayerProvider>();
    if (_radio) {
      try {
        await context.read<RadioProvider>().stopRadioAndClear();
        await context.read<RadioProvider>().setAlarmVolume(1.0);
      } catch (_) {}
      _radio = false;
    }
    await _setVol(_vol);
    final all = List<Song>.from(context.read<MusicProvider>().allSongs)..shuffle();
    try {
      if (_nature) {
        await player.stopNatureSound();
        _nature = false;
      }
      if (all.isNotEmpty) {
        await player.playFromList(all, 0);
      } else {
        _system = true;
        await AlarmService.playFallback();
      }
    } catch (_) {}
  }

  Future<void> _stopSound() async {
    final player = context.read<PlayerProvider>();
    try {
      if (_system) {
        await AlarmService.stopFallback();
      } else if (_radio) {
        await context.read<RadioProvider>().stopRadioAndClear();
      } else if (_nature) {
        await player.stopNatureSound();
      } else {
        await player.player.pause();
      }
    } catch (_) {}
  }

  /// 소리 크기 원래대로 (다음에 들을 때 작게 나오지 않게)
  /// [phone] = 폰 미디어 볼륨도 알람 전으로 (계속 들을 때는 그대로)
  Future<void> _restoreVol({bool phone = true}) async {
    try {
      final pp = context.read<PlayerProvider>();
      pp.volumeLocked = false;
      await pp.player.setVolume(pp.normGain); // 곡마다 소리 크기 맞춘 크기로
      await context.read<RadioProvider>().setAlarmVolume(1.0);
    } catch (_) {}
    if (phone && _origVol != null) await AlarmService.setMusicVolume(_origVol!);
    if (_prevLoop != null && mounted) {
      context.read<PlayerProvider>().setLoopMode(_prevLoop!);
      _prevLoop = null;
    }
  }

  // ───── 버튼 ─────

  Future<void> _off() async {
    if (_done) return;
    _done = true;
    HapticFeedback.mediumImpact();
    _fade?.cancel();
    _auto?.cancel();
    await _stopSound();
    await _restoreVol();
    await AlarmService.dismiss();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _later() async {
    if (_done) return;
    _done = true;
    HapticFeedback.mediumImpact();
    _fade?.cancel();
    _auto?.cancel();
    await _stopSound();
    await _restoreVol();
    await AlarmService.snooze();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _keep() async {
    if (_done) return;
    _done = true;
    _fade?.cancel();
    _auto?.cancel();
    if (_system) await AlarmService.stopFallback(); // 기본 알람 소리는 계속 듣기 없음
    await _restoreVol(phone: false); // 소리는 그대로, 폰 볼륨도 지금 크기 그대로
    await AlarmService.dismiss();
    if (mounted) Navigator.pop(context);
  }

  /// 10분 동안 안 끄면: 5분 쉬고 다시 (3번째도 안 끄면 그만)
  Future<void> _autoLater() async {
    if (_done) return;
    _done = true;
    _fade?.cancel();
    await _stopSound();
    await _restoreVol();
    await AlarmService.autoSnooze();
    if (mounted) Navigator.pop(context);
  }

  IconData get _icon {
    if (_a.kind == 'radio') return Icons.radio_rounded;
    if (_a.kind == 'nature') return Icons.forest_outlined;
    if (_a.kind == 'playlist') return Icons.queue_music_rounded;
    if (_a.kind == 'music_fav') return Icons.favorite_border_rounded;
    if (_a.kind == 'song') return Icons.music_note_rounded;
    return Icons.shuffle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour < 12 ? '오전' : '오후';
    final greet = now.hour < 12 ? '좋은 아침이에요' : '알람 시간이에요';
    return PopScope(
      canPop: false, // 뒤로가기로 실수로 닫히지 않게
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: _bg2,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: _bg2,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bg1, _bg2],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Text(greet,
                        style: TextStyle(
                            color: _cream.withOpacity(0.75), fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(ampm,
                            style: const TextStyle(color: _sub, fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        Text('$h:${now.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: _cream,
                                fontSize: 72,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -1.5,
                                height: 1.1)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${now.month}월 ${now.day}일 ${_days[now.weekday - 1]}요일',
                        style: const TextStyle(color: _sub, fontSize: 15)),
                    const Spacer(flex: 2),
                    // 깨우는 소리
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon, size: 18, color: _sub),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(_a.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _cream, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _off,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cream,
                          foregroundColor: _ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text('끄기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _later,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _cream,
                          side: BorderSide(color: _cream.withOpacity(0.3), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text('5분 뒤 다시', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _keep,
                      style: TextButton.styleFrom(foregroundColor: _sub),
                      child: const Text('알람 끄고 계속 듣기', style: TextStyle(fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
