import 'dart:math';
import 'package:flutter/material.dart';

enum SeasonalEffectType { none, leaves, snow }

SeasonalEffectType currentSeasonalEffect() {
  final month = DateTime.now().month;
  if (month >= 9 && month <= 11) return SeasonalEffectType.leaves;
  if (month == 12 || month <= 2) return SeasonalEffectType.snow;
  return SeasonalEffectType.none;
}

class SeasonalEffect extends StatefulWidget {
  final bool enabled;
  const SeasonalEffect({super.key, required this.enabled});

  @override
  State<SeasonalEffect> createState() => _SeasonalEffectState();
}

class _SeasonalEffectState extends State<SeasonalEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final _rand = Random();
  late SeasonalEffectType _type;

  @override
  void initState() {
    super.initState();
    _type = currentSeasonalEffect();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    for (int i = 0; i < 4; i++) {
      _particles.add(_Particle(_rand));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _type == SeasonalEffectType.none) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ParticlePainter(
                particles: _particles,
                progress: _ctrl.value,
                type: _type,
              ),
            );
          },
        );
      }),
    );
  }
}

class _Particle {
  final double startX; // 0~1
  final double speed; // 0.5~1.2
  final double size; // px
  final double swayAmount;
  final double swaySpeed;
  final double rotationSpeed;
  final double phaseOffset; // 0~1, 시작 지연

  _Particle(Random rand)
      : startX = rand.nextDouble(),
        speed = 0.5 + rand.nextDouble() * 0.7,
        size = 6 + rand.nextDouble() * 8,
        swayAmount = 10 + rand.nextDouble() * 24,
        swaySpeed = 1 + rand.nextDouble() * 2,
        rotationSpeed = (rand.nextBool() ? 1 : -1) * (0.5 + rand.nextDouble()),
        phaseOffset = rand.nextDouble();
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final SeasonalEffectType type;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress * p.speed) + p.phaseOffset) % 1.0;
      final y = t * (size.height + 40) - 20;
      final sway = sin((t + p.phaseOffset) * 2 * pi * p.swaySpeed) * p.swayAmount;
      final x = p.startX * size.width + sway;
      final rotation = t * 2 * pi * p.rotationSpeed;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (type == SeasonalEffectType.leaves) {
        _drawLeaf(canvas, p.size);
      } else {
        _drawSnow(canvas, p.size);
      }

      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, double s) {
    final colors = [
      const Color(0xFFE04A2B),
      const Color(0xFFE8871E),
      const Color(0xFFC22E1F),
      const Color(0xFFF2A73B),
      const Color(0xFFD9531E),
    ];
    final color = colors[(s * 7).toInt() % colors.length];

    // 잎 몸통 (하트를 눕힌 듯한 단풍잎 형태)
    final paint = Paint()..color = color.withOpacity(0.85);
    final path = Path();
    path.moveTo(0, -s * 1.3);
    path.cubicTo(s * 1.1, -s * 0.9, s * 1.0, -s * 0.1, s * 0.3, s * 0.3);
    path.cubicTo(s * 0.5, s * 0.7, s * 0.2, s * 1.0, 0, s * 1.3);
    path.cubicTo(-s * 0.2, s * 1.0, -s * 0.5, s * 0.7, -s * 0.3, s * 0.3);
    path.cubicTo(-s * 1.0, -s * 0.1, -s * 1.1, -s * 0.9, 0, -s * 1.3);
    path.close();
    canvas.drawPath(path, paint);

    // 잎맥
    final veinPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, -s * 1.2), Offset(0, s * 1.1), veinPaint);
    canvas.drawLine(Offset(0, -s * 0.4), Offset(s * 0.55, -s * 0.1), veinPaint);
    canvas.drawLine(Offset(0, -s * 0.4), Offset(-s * 0.55, -s * 0.1), veinPaint);
    canvas.drawLine(Offset(0, s * 0.3), Offset(s * 0.4, s * 0.6), veinPaint);
    canvas.drawLine(Offset(0, s * 0.3), Offset(-s * 0.4, s * 0.6), veinPaint);
  }

  void _drawSnow(Canvas canvas, double s) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset.zero, s * 0.28, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}