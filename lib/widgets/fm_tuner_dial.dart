import 'dart:math';
import 'package:flutter/material.dart';

class FmTunerDial extends StatefulWidget {
  final String broadcaster;
  final double? frequency; // null이면 주파수 없음 (가운데 고정)
  final bool isPlaying;
  final Color bcColor;
  final Color primaryColor;
  final AnimationController pulseCtrl;

  const FmTunerDial({
    super.key,
    required this.broadcaster,
    required this.frequency,
    required this.isPlaying,
    required this.bcColor,
    required this.primaryColor,
    required this.pulseCtrl,
  });

  @override
  State<FmTunerDial> createState() => _FmTunerDialState();
}

class _FmTunerDialState extends State<FmTunerDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _pointerCtrl;
  late Animation<double> _pointerAnim;
  double _currentFreq = 97.5; // 기본 중앙값

  static const double minFreq = 88.0;
  static const double maxFreq = 108.0;

  @override
  void initState() {
    super.initState();
    _currentFreq = widget.frequency ?? (minFreq + maxFreq) / 2;
    _pointerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pointerAnim = Tween<double>(begin: _currentFreq, end: _currentFreq)
        .animate(CurvedAnimation(parent: _pointerCtrl, curve: Curves.easeOutCubic));
    _pointerCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(FmTunerDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newFreq = widget.frequency ?? (minFreq + maxFreq) / 2;
    if (newFreq != _currentFreq) {
      final startFreq = _currentFreq;
      _currentFreq = newFreq;
      _pointerAnim = Tween<double>(begin: startFreq, end: newFreq)
          .animate(CurvedAnimation(parent: _pointerCtrl, curve: Curves.easeOutCubic));
      _pointerCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pointerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFreq = widget.frequency != null;
    return SizedBox(
      width: 320,
      height: 320,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pointerAnim, widget.pulseCtrl]),
        builder: (context, child) {
          return CustomPaint(
            painter: _FmDialPainter(
              currentFreq: _pointerAnim.value,
              hasFreq: hasFreq,
              bcColor: widget.bcColor,
              primaryColor: widget.primaryColor,
              isPlaying: widget.isPlaying,
              pulseValue: widget.pulseCtrl.value,
            ),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.broadcaster,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.broadcaster.length > 4 ? 26 : 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FmDialPainter extends CustomPainter {
  final double currentFreq;
  final bool hasFreq;
  final Color bcColor;
  final Color primaryColor;
  final bool isPlaying;
  final double pulseValue;

  static const double minFreq = 88.0;
  static const double maxFreq = 108.0;
  // 다이얼 호: 8시 방향(135도)에서 시작해서 시계방향으로 4시 방향(45도)까지, 총 270도
  static const double startAngle = pi * 0.75; // 135도 (8시 방향)
  static const double sweepAngle = pi * 1.5;  // 270도

  _FmDialPainter({
    required this.currentFreq,
    required this.hasFreq,
    required this.bcColor,
    required this.primaryColor,
    required this.isPlaying,
    required this.pulseValue,
  });

  double _freqToAngle(double freq) {
    final t = ((freq - minFreq) / (maxFreq - minFreq)).clamp(0.0, 1.0);
    return startAngle + sweepAngle * t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 4;
    final tickR = outerR - 18;

    // 글로우 배경 (재생 중일 때 펄스)
    if (isPlaying) {
      final glowOpacity = 0.15 + 0.10 * pulseValue;
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(center, outerR, glowPaint);
    }

    // 바깥 원형 트랙 (네온 글로우 효과)
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerR),
      startAngle, sweepAngle, false, trackPaint,
    );

    final trackPaint2 = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerR),
      startAngle, sweepAngle, false, trackPaint2,
    );

    // 눈금 (0.2MHz 단위 작은 눈금, 1MHz 단위 큰 눈금 + 숫자)
    final totalTicks = ((maxFreq - minFreq) / 0.2).round();
    for (int i = 0; i <= totalTicks; i++) {
      final freq = minFreq + i * 0.2;
      final angle = _freqToAngle(freq);
      final isMajor = (freq * 10).round() % 40 == 0; // 4MHz 단위 큰 눈금(88,92,96...)
      final tickLen = isMajor ? 12.0 : 5.0;
      final tickColor = isMajor
          ? Colors.white.withOpacity(0.85)
          : Colors.white.withOpacity(0.35);

      final outer = Offset(
        center.dx + tickR * cos(angle),
        center.dy + tickR * sin(angle),
      );
      final inner = Offset(
        center.dx + (tickR - tickLen) * cos(angle),
        center.dy + (tickR - tickLen) * sin(angle),
      );
      canvas.drawLine(outer, inner,
          Paint()
            ..color = tickColor
            ..strokeWidth = isMajor ? 2.0 : 1.0
            ..strokeCap = StrokeCap.round);

      // 큰 눈금에 숫자 표시
      if (isMajor) {
        final labelR = tickR - tickLen - 16;
        final labelPos = Offset(
          center.dx + labelR * cos(angle),
          center.dy + labelR * sin(angle),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: freq.toStringAsFixed(0),
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // FM / MHz 라벨 제거 (숫자와 겹치는 문제로 삭제)

    // 포인터 (바늘)
    final pointerAngle = _freqToAngle(currentFreq);
    final pointerOpacity = hasFreq ? 1.0 : 0.35;
    final pointerColor = Colors.white.withOpacity(pointerOpacity);

    final pointerOuter = Offset(
      center.dx + (tickR + 8) * cos(pointerAngle),
      center.dy + (tickR + 8) * sin(pointerAngle),
    );
    final pointerInner = Offset(
      center.dx + (tickR - 50) * cos(pointerAngle),
      center.dy + (tickR - 50) * sin(pointerAngle),
    );

    // 포인터 글로우
    canvas.drawLine(pointerInner, pointerOuter,
        Paint()
          ..color = pointerColor.withOpacity(pointerOpacity * 0.4)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    canvas.drawLine(pointerInner, pointerOuter,
        Paint()
          ..color = pointerColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    // 현재 주파수 텍스트 (포인터 끝 근처)
    if (hasFreq) {
      final rawX = center.dx + (tickR + 30) * cos(pointerAngle);
      final rawY = center.dy + (tickR + 30) * sin(pointerAngle);
      // 캡슐이 화면 밖으로 안 나가도록 x 위치 제한
      final freqLabelPos = Offset(
        rawX.clamp(50.0, size.width - 50.0),
        rawY.clamp(16.0, size.height - 16.0),
      );
      final freqTp = TextPainter(
        text: TextSpan(
          text: '${currentFreq.toStringAsFixed(1)} MHz',
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // 배경 캡슐로 가독성 보강
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: freqLabelPos,
          width: freqTp.width + 14,
          height: freqTp.height + 6,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(bgRect, Paint()..color = Colors.white.withOpacity(0.9));
      final freqTextPainter = TextPainter(
        text: TextSpan(
          text: '${currentFreq.toStringAsFixed(1)} MHz',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      freqTextPainter.paint(canvas, freqLabelPos - Offset(freqTextPainter.width / 2, freqTextPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_FmDialPainter old) =>
      old.currentFreq != currentFreq ||
          old.isPlaying != isPlaying ||
          old.pulseValue != pulseValue;
}