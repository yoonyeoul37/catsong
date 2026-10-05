import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../providers/player_provider.dart';

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
  String? _tmpPath;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _tick?.cancel();
    _ampSub?.cancel();
    _pulse.dispose();
    _rec.dispose();
    super.dispose();
  }

  // ───────── 녹음 시작 ─────────
  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    if (!await _rec.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('녹음하려면 마이크 권한이 필요해요')),
      );
      return;
    }
    // 음악이 나오고 있으면 잠깐 멈추기
    try {
      if (mounted) context.read<PlayerProvider>().player.pause();
    } catch (_) {}

    _tmpPath = '${Directory.systemTemp.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100, numChannels: 1),
      path: _tmpPath!,
    );
    _watch
      ..reset()
      ..start();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
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
    if (_state == _RecState.recording) {
      await _rec.pause();
      _watch.stop();
      setState(() => _state = _RecState.paused);
    } else if (_state == _RecState.paused) {
      await _rec.resume();
      _watch.start();
      setState(() => _state = _RecState.recording);
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
    final path = await _rec.stop() ?? _tmpPath;
    if (path == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name =
        '녹음 ${two(now.year % 100)}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
    String? saved;
    try {
      saved = await _channel.invokeMethod<String>('saveRecording', {'path': path, 'name': name});
    } catch (_) {}
    try {
      await File(path).delete();
    } catch (_) {}
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('녹음을 지울까요?', style: TextStyle(fontSize: 16)),
        content: const Text('지금까지 녹음한 내용이 저장되지 않아요.', style: TextStyle(fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('계속 녹음')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('지우기', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) {
      if (wasRecording) await _togglePause();
      return;
    }
    _tick?.cancel();
    _ampSub?.cancel();
    final p = await _rec.stop();
    try {
      if (p != null) await File(p).delete();
    } catch (_) {}
    if (mounted) Navigator.pop(context);
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
                  const SizedBox(height: 40),
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

  /// 상태 표시: ● 녹음 중 / 일시정지 / 준비됐어요
  Widget _statusPill() {
    final (label, dot) = switch (_state) {
      _RecState.idle => ('준비됐어요', Colors.white38),
      _RecState.recording => ('녹음 중', _red),
      _RecState.paused => ('일시정지', const Color(0xFFFFC857)),
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