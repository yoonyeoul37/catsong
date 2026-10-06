import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../providers/player_provider.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/paran_toast.dart';

/// 지금 녹음 중인 파일 (되살리기에서 건드리지 않게)
String? activeRecordingPath;

String _stamp(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.year % 100)}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}';
}

/// 녹음 중인 파일을 두는 앱 전용 폴더 (캐시처럼 지워지지 않는 곳)
Future<Directory> recordingWorkDir() async {
  String? base;
  try {
    base = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<String>('appFilesDir');
  } catch (_) {}
  final d = Directory('${base ?? Directory.systemTemp.path}/recording');
  if (!await d.exists()) await d.create(recursive: true);
  return d;
}

/// 녹음 중에 앱이 꺼져서 저장 못 한 녹음을 되살려 저장 → 되살린 개수 (녹음 탭 열 때 실행)
Future<int> recoverUnsavedRecordings() async {
  const ch = MethodChannel('kr.ssing.catsong/media');
  var n = 0;
  try {
    final dir = await recordingWorkDir();
    await for (final e in dir.list()) {
      if (e is! File || !e.path.endsWith('.aac')) continue;
      if (e.path == activeRecordingPath) continue; // 지금 녹음 중인 건 건드리지 않기
      if (await e.length() < 4096) {
        await e.delete(); // 너무 짧으면 버리기
        continue;
      }
      final stem = e.path.split('rec_').last.replaceAll('.aac', '');
      final saved = await ch.invokeMethod<String>('saveRecording', {'path': e.path, 'name': '녹음 (복구) $stem'});
      if (saved != null) {
        await e.delete();
        n++;
      }
    }
  } catch (_) {}
  return n;
}

/// 파란소리 녹음기 (음성 녹음)
/// 녹음 → 일시정지·이어서 → 완료하면 Recordings/Paransori 폴더에 저장
class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

enum _RecState { idle, recording, paused, saving }

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('kr.ssing.catsong/media');
  static const _blue = Color(0xFF2589E8);
  static const _sky = Color(0xFF7FB8F0);
  static const _red = Color(0xFFFF4D57);

  final _rec = AudioRecorder();
  _RecState _state = _RecState.idle;
  final _watch = Stopwatch();
  Timer? _tick;
  StreamSubscription<Amplitude>? _ampSub;
  final List<double> _levels = []; // 소리 크기 기록 (파형)
  String? _tmpPath; // 녹음 중인 파일 (.aac: 끊겨도 그때까지는 살아 있음)
  RandomAccessFile? _raf; // 받는 대로 바로 파일에 씀
  StreamSubscription<Uint8List>? _dataSub;
  StreamSubscription<RecordState>? _stateSub;
  bool _byUser = false; // 사용자가 직접 누른 일시정지/이어서인지
  bool _interrupted = false; // 전화 등으로 자동 일시정지된 상태
  Duration? _limit; // 타이머: 이만큼 녹음되면 자동 저장 (null = 없음)

  // 화면 열 때 바로 만들어 둠 (녹음 안 하고 닫을 때 생기던 오류 방지)
  late final AnimationController _pulse = _makePulse();
  AnimationController _makePulse() => AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  // 알림창 버튼(일시정지·이어서·완료)을 받는 통로
  static const _actions = MethodChannel('kr.ssing.catsong/recording');

  @override
  void initState() {
    super.initState();
    _pulse; // 깜빡이 장치를 여기서 미리 만들기
    _actions.setMethodCallHandler((call) async {
      if (call.method != 'action' || !mounted) return;
      switch (call.arguments as String?) {
        case 'pause':
          if (_state == _RecState.recording) await _togglePause();
          break;
        case 'resume':
          if (_state == _RecState.paused) await _togglePause();
          break;
        case 'finish':
          await _finish();
          break;
      }
    });
  }

  @override
  void dispose() {
    _actions.setMethodCallHandler(null);
    _dataSub?.cancel();
    _stateSub?.cancel();
    _closeFile(); // 저장 안 하고 닫혔으면 파일은 남겨둠 → 다음에 되살림
    _tick?.cancel();
    _ampSub?.cancel();
    _pulse.dispose();
    _svc('stop');
    _rec.dispose();
    super.dispose();
  }

  // ───────── 녹음 시작 ─────────
  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    if (!await _rec.hasPermission()) {
      if (!mounted) return;
      showParanToast(context, '녹음하려면 마이크 권한이 필요해요');
      return;
    }
    // 알림창에 "녹음 중"을 보여주려면 알림 권한이 필요해요 (안드로이드 13+)
    try {
      final st = await Permission.notification.request();
      if (!st.isGranted && mounted) {
        showParanToast(context, '알림을 허용하면 알림창에서 녹음 중인 걸 볼 수 있어요');
      }
    } catch (_) {}
    // 음악이 나오고 있으면 잠깐 멈추기
    try {
      if (mounted) context.read<PlayerProvider>().player.pause();
    } catch (_) {}

    // 안전 저장: 앱 전용 폴더에 .aac로 받는 즉시 써둠 → 앱이 꺼져도 그때까지 녹음이 남음
    final dir = await recordingWorkDir();
    _tmpPath = '${dir.path}/rec_${_stamp(DateTime.now())}.aac';
    _raf = File(_tmpPath!).openSync(mode: FileMode.append);
    activeRecordingPath = _tmpPath;
    final stream = await _rec.startStream(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        // 전화 등이 끼어들면 자동 일시정지 → 끝나면 자동으로 이어서
        audioInterruption: AudioInterruptionMode.pauseResume,
      ),
    );
    _dataSub = stream.listen((data) {
      try {
        _raf?.writeFromSync(data);
      } catch (_) {}
    });
    // 전화가 와서 녹음기가 스스로 멈추거나 다시 시작하면 화면·알림도 맞춰주기
    _stateSub = _rec.onStateChanged().listen((st) {
      if (!mounted || _byUser) return;
      if (st == RecordState.pause && _state == _RecState.recording) {
        _watch.stop();
        setState(() {
          _state = _RecState.paused;
          _interrupted = true;
        });
        _svc('pause');
      } else if (st == RecordState.record && _state == _RecState.paused && _interrupted) {
        _watch.start();
        setState(() {
          _state = _RecState.recording;
          _interrupted = false;
        });
        _svc('resume');
      }
    });
    _watch
      ..reset()
      ..start();
    _svc('start'); // 알림창에 "녹음 중" → 앱을 나가도 계속 녹음
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      // 타이머 시간만큼 녹음됐으면 자동 저장
      if (_limit != null && _state == _RecState.recording && _watch.elapsed >= _limit!) {
        _finish();
        return;
      }
      if (mounted) setState(() {});
    });
    _ampSub = _rec.onAmplitudeChanged(const Duration(milliseconds: 80)).listen((a) {
      // -50dB(조용) ~ 0dB(큼) → 0~1
      final v = ((a.current + 50) / 50).clamp(0.04, 1.0).toDouble();
      _levels.add(v);
      if (_levels.length > 160) _levels.removeAt(0);
    });
    setState(() => _state = _RecState.recording);
  }

  // ───────── 일시정지 / 이어서 ─────────
  Future<void> _togglePause() async {
    HapticFeedback.selectionClick();
    _byUser = true; // 직접 누른 거라 전화 끼어들기로 착각하지 않게
    _interrupted = false;
    Future.delayed(const Duration(milliseconds: 600), () => _byUser = false);
    if (_state == _RecState.recording) {
      await _rec.pause();
      _watch.stop();
      setState(() => _state = _RecState.paused);
      _svc('pause');
    } else if (_state == _RecState.paused) {
      await _rec.resume();
      _watch.start();
      setState(() => _state = _RecState.recording);
      _svc('resume');
    }
  }

  // ───────── 완료 → 저장 ─────────
  Future<void> _finish() async {
    if (_state == _RecState.idle || _state == _RecState.saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _state = _RecState.saving);
    _tick?.cancel();
    _ampSub?.cancel();
    _watch.stop();
    await _rec.stop();
    await _dataSub?.cancel();
    _closeFile();
    _svc('stop');
    final path = _tmpPath;
    if (path == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    // 이름: 녹음 251006_110930 (녹음 시작 시각)
    final name = '녹음 ${path.split('rec_').last.replaceAll('.aac', '')}';
    String? saved;
    try {
      saved = await _channel.invokeMethod<String>('saveRecording', {'path': path, 'name': name});
    } catch (e, st) {
      // 저장 실패 이유를 Crashlytics에 남기기 (스토어 버전에서도 원인 확인용)
      FirebaseCrashlytics.instance.recordError(e, st, reason: '녹음 저장 실패');
    }
    // 저장에 성공했을 때만 지움 (실패하면 남겨뒀다가 다음에 되살림)
    if (saved != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    activeRecordingPath = null;
    if (!mounted) return;
    Navigator.pop(context, saved);
  }

  // ───────── 취소 (녹음 버리기) ─────────
  Future<void> _cancel() async {
    if (_state == _RecState.idle) {
      Navigator.pop(context);
      return;
    }
    if (_state == _RecState.saving) return;
    final wasRecording = _state == _RecState.recording;
    if (wasRecording) await _togglePause();
    if (!mounted) return;
    final ok = await showParanConfirm(
      context,
      title: '녹음을 지울까요?',
      message: '지금까지 녹음한 내용이 저장되지 않아요.',
      confirmLabel: '지우기',
      cancelLabel: '계속 녹음',
      danger: true,
    );
    if (ok != true) {
      if (wasRecording) await _togglePause();
      return;
    }
    _tick?.cancel();
    _ampSub?.cancel();
    await _rec.stop();
    await _dataSub?.cancel();
    _closeFile();
    _svc('stop');
    try {
      if (_tmpPath != null) await File(_tmpPath!).delete();
    } catch (_) {}
    activeRecordingPath = null;
    if (mounted) Navigator.pop(context);
  }

  void _closeFile() {
    try {
      _raf?.closeSync();
    } catch (_) {}
    _raf = null;
  }

  /// 알림창 "녹음 중" 켜기·바꾸기·끄기 (start / pause / resume / stop)
  void _svc(String action) {
    _channel.invokeMethod('recordingService', {
      'action': action,
      'base': DateTime.now().millisecondsSinceEpoch - _watch.elapsedMilliseconds,
      'elapsed': _watch.elapsedMilliseconds,
    }).catchError((_) {});
  }

  String get _timeText {
    final ms = _watch.elapsedMilliseconds;
    final h = ms ~/ 3600000;
    final m = (ms ~/ 60000) % 60;
    final s = (ms ~/ 1000) % 60;
    final d = (ms ~/ 100) % 10;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss.$d';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_state == _RecState.idle) return true;
        _cancel();
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFF0B1622),
        ),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF12263D), Color(0xFF0B1622)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 위쪽: 닫기 · 제목
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _cancel,
                          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7)),
                        ),
                        Expanded(
                          child: Center(
                            child: Text('새 녹음',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14.5)),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  _statusPill(),
                  const SizedBox(height: 18),
                  // 큰 시간
                  Text(
                    _timeText,
                    style: GoogleFonts.quicksand(
                      color: Colors.white,
                      fontSize: 58,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _timerChip(),
                  const SizedBox(height: 28),
                  // 파형
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _WavePainter(List.of(_levels), active: _state == _RecState.recording),
                    ),
                  ),
                  const Spacer(flex: 3),
                  _controls(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────── 타이머 (자동 저장) ─────────
  Widget _timerChip() {
    String label;
    if (_limit == null) {
      label = '타이머 없음';
    } else if (_state == _RecState.idle) {
      label = '${_limitText(_limit!)} 녹음하면 자동 저장';
    } else {
      final left = _limit! - _watch.elapsed;
      final s = left.isNegative ? 0 : left.inSeconds;
      final h = s ~/ 3600;
      final mm = ((s ~/ 60) % 60).toString().padLeft(2, '0');
      final ss = (s % 60).toString().padLeft(2, '0');
      label = '${h > 0 ? '$h:$mm:$ss' : '$mm:$ss'} 후 자동 저장';
    }
    return GestureDetector(
      onTap: _state == _RecState.saving ? null : _pickTimer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_limit == null ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 15, color: Colors.white.withOpacity(_limit == null ? 0.45 : 0.85)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(_limit == null ? 0.45 : 0.85), fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  String _limitText(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '$m분';
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  /// 타이머 고르기: 빠른 버튼 + 시간·분 휠 (음악 수면 타이머처럼)
  void _pickTimer() {
    HapticFeedback.selectionClick();
    var picked = _limit ?? const Duration(minutes: 30);

    void apply(BuildContext ctx, Duration? d) {
      Navigator.pop(ctx);
      // 이미 지난 시간을 고르면 바로 저장되지 않게
      if (d != null && _watch.elapsed >= d) {
        showParanToast(context, '이미 그보다 오래 녹음했어요');
        return;
      }
      setState(() => _limit = d);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF18304B),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('이만큼 녹음되면 자동으로 저장',
                    style: TextStyle(color: Colors.white70, fontSize: 13.5)),
                const SizedBox(height: 12),
                // 빠른 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final d in const [Duration(minutes: 15), Duration(minutes: 30), Duration(hours: 1)])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => apply(ctx, d),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(_limitText(d),
                                style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ),
                  ],
                ),
                // 시간·분 휠
                SizedBox(
                  height: 180,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(color: Colors.white, fontSize: 21),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => apply(ctx, null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('타이머 끄기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => apply(ctx, picked.inMinutes == 0 ? null : picked),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('설정'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 상태 표시: ● 녹음 중 / 일시정지 / 준비됐어요
  Widget _statusPill() {
    final (label, dot) = switch (_state) {
      _RecState.idle => ('준비됐어요', Colors.white38),
      _RecState.recording => ('녹음 중', _red),
      _RecState.paused => (_interrupted ? '통화 중 · 끝나면 이어서 녹음' : '일시정지', const Color(0xFFFFC857)),
      _RecState.saving => ('저장 중…', _sky),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _state == _RecState.recording
                ? Tween(begin: 0.35, end: 1.0).animate(_pulse)
                : const AlwaysStoppedAnimation(1.0),
            child: Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
        ],
      ),
    );
  }

  /// 아래 버튼: 지우기 · (녹음/일시정지) · 완료
  Widget _controls() {
    final started = _state == _RecState.recording || _state == _RecState.paused;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _smallBtn(Icons.delete_outline, '지우기', started ? _cancel : null),
        _mainBtn(),
        _smallBtn(Icons.check, '완료', started ? _finish : null, highlight: true),
      ],
    );
  }

  Widget _mainBtn() {
    if (_state == _RecState.saving) {
      return const SizedBox(
        width: 88,
        height: 88,
        child: Center(child: CircularProgressIndicator(color: _sky)),
      );
    }
    final recording = _state == _RecState.recording;
    return GestureDetector(
      onTap: _state == _RecState.idle ? _start : _togglePause,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 3),
        ),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: recording ? 34 : 66,
          height: recording ? 34 : 66,
          decoration: BoxDecoration(
            color: _red,
            borderRadius: BorderRadius.circular(recording ? 8 : 33),
            boxShadow: [BoxShadow(color: _red.withOpacity(0.45), blurRadius: 18)],
          ),
          // 녹음 중이면 네모(=일시정지), 아니면 동그라미(=녹음)
          child: recording ? null : const Icon(Icons.mic, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _smallBtn(IconData icon, String label, VoidCallback? onTap, {bool highlight = false}) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlight && enabled ? _blue : Colors.white.withOpacity(0.1),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// 소리 크기에 따라 움직이는 파형 (오른쪽이 가장 최근)
class _WavePainter extends CustomPainter {
  final List<double> levels;
  final bool active;
  _WavePainter(this.levels, {required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    const barW = 3.0;
    const gap = 3.0;
    final mid = size.height / 2;
    // 가운데 얇은 선
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..strokeWidth = 1,
    );
    if (levels.isEmpty) return;
    final count = (size.width / (barW + gap)).floor();
    final shown = levels.length > count ? levels.sublist(levels.length - count) : levels;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7FB8F0), Color(0xFF2589E8), Color(0xFF7FB8F0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    if (!active) paint.color = Colors.white.withOpacity(0.3);
    for (var i = 0; i < shown.length; i++) {
      final x = size.width - (shown.length - i) * (barW + gap);
      // 오래된 막대일수록 살짝 흐리게
      final fade = 0.35 + 0.65 * (i / math.max(1, shown.length - 1));
      final h = math.max(3.0, shown[i] * size.height * 0.9);
      final p = Paint()
        ..shader = active ? paint.shader : null
        ..color = (active ? Colors.white : Colors.white.withOpacity(0.3)).withOpacity(active ? fade : 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, mid), width: barW, height: h),
            const Radius.circular(2)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}