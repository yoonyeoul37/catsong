import 'package:flutter/material.dart';

class FrequencyRuler extends StatefulWidget {
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
  State<FrequencyRuler> createState() => _FrequencyRulerState();
}

class _FrequencyRulerState extends State<FrequencyRuler>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frequency == null) return const SizedBox.shrink();
    final freq = widget.frequency!.clamp(widget.minFreq, widget.maxFreq);
    final fraction = (freq - widget.minFreq) / (widget.maxFreq - widget.minFreq);

    return Column(
      children: [
        SizedBox(
          height: 34,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final baseX = width * fraction;
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final wobble = (_ctrl.value - 0.5) * 24;
                final handleX = (baseX + wobble).clamp(6.0, width - 6.0);
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 3,
                      width: width,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    Container(
                      height: 3,
                      width: handleX,
                      color: widget.primaryColor,
                    ),
                    CustomPaint(
                      size: Size(width, 20),
                      painter: _TickPainter(color: Colors.white.withOpacity(0.25)),
                    ),
                    Positioned(
                      left: handleX - 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: widget.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.minFreq.toStringAsFixed(0),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            Text('${freq.toStringAsFixed(1)} MHz',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600)),
            Text(widget.maxFreq.toStringAsFixed(0),
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