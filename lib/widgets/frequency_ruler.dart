import 'package:flutter/material.dart';

class FrequencyRuler extends StatelessWidget {
  final double? frequency; // 예: 89.1
  final Color primaryColor;
  final double minFreq;
  final double maxFreq;

  const FrequencyRuler({
    super.key,
    required this.frequency,
    required this.primaryColor,
    this.minFreq = 88.0,
    this.maxFreq = 108.0,
  });

  @override
  Widget build(BuildContext context) {
    if (frequency == null) return const SizedBox.shrink();
    final freq = frequency!.clamp(minFreq, maxFreq);
    final fraction = (freq - minFreq) / (maxFreq - minFreq);

    return Column(
      children: [
        SizedBox(
          height: 34,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final handleX = (width * fraction).clamp(6.0, width - 6.0);
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 배경 트랙
                Container(
                  height: 3,
                  width: width,
                  color: Colors.white.withOpacity(0.15),
                ),
                // 진행된 부분
                Container(
                  height: 3,
                  width: handleX,
                  color: primaryColor,
                ),
                // 눈금
                CustomPaint(
                  size: Size(width, 20),
                  painter: _TickPainter(color: Colors.white.withOpacity(0.25)),
                ),
                // 손잡이
                Positioned(
                  left: handleX - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minFreq.toStringAsFixed(0),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            Text('${freq.toStringAsFixed(1)} MHz',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600)),
            Text(maxFreq.toStringAsFixed(0),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _TickPainter extends CustomPainter {
  final Color color;
  _TickPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const tickCount = 40;
    for (int i = 0; i <= tickCount; i++) {
      final x = size.width * (i / tickCount);
      final isMajor = i % 5 == 0;
      final tickHeight = isMajor ? 10.0 : 5.0;
      canvas.drawLine(
        Offset(x, size.height / 2 - tickHeight / 2),
        Offset(x, size.height / 2 + tickHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => false;
}