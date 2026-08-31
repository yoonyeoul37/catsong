import 'package:flutter/material.dart';

class RadioMoodPlaceholder extends StatelessWidget {
  final double height;
  const RadioMoodPlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _MoodPainter(),
      ),
    );
  }
}

class _MoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8DCC8);
    canvas.drawRect(Offset.zero & size, bg);

    // 은은한 햇살 (겹친 원)
    final moonCx = size.width * 0.7;
    final moonCy = size.height * 0.3;
    canvas.drawCircle(Offset(moonCx, moonCy), size.width * 0.24,
        Paint()..color = const Color(0xFFF2D9A8).withOpacity(0.6));
    canvas.drawCircle(Offset(moonCx, moonCy), size.width * 0.17,
        Paint()..color = const Color(0xFFF5C87A).withOpacity(0.7));
    canvas.drawCircle(Offset(moonCx, moonCy), size.width * 0.10,
        Paint()..color = const Color(0xFFF2A65A).withOpacity(0.6));
    canvas.drawCircle(Offset(moonCx, moonCy), size.width * 0.05,
        Paint()..color = const Color(0xFFF2A65A).withOpacity(0.85));

    // 떠다니는 점들
    final dots = [
      [0.2, 0.2, 2.0, const Color(0xFFB08D57), 0.5],
      [0.3, 0.35, 1.5, const Color(0xFFE8877E), 0.5],
      [0.83, 0.65, 2.0, const Color(0xFFB08D57), 0.4],
      [0.15, 0.55, 1.5, const Color(0xFF7EC8E3), 0.4],
      [0.9, 0.15, 1.5, const Color(0xFF8A7248), 0.3],
    ];
    for (final d in dots) {
      canvas.drawCircle(
        Offset(size.width * (d[0] as double), size.height * (d[1] as double)),
        d[2] as double,
        Paint()..color = (d[3] as Color).withOpacity(d[4] as double),
      );
    }

    // 마이크 실루엣 (중앙)
    final cx = size.width * 0.5;
    final cy = size.height * 0.48;
    final scale = size.height / 200;
    final micPaint = Paint()..color = const Color(0xFF0F0D09);

    // 스탠드
    canvas.drawLine(
      Offset(cx, cy + 55 * scale),
      Offset(cx, cy + 12 * scale),
      micPaint..strokeWidth = 4 * scale,
    );
    final standPath = Path()
      ..moveTo(cx - 24 * scale, cy + 55 * scale)
      ..quadraticBezierTo(cx, cy + 68 * scale, cx + 24 * scale, cy + 55 * scale);
    canvas.drawPath(
      standPath,
      Paint()
        ..color = const Color(0xFF0F0D09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );

    // 마이크 헤드
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 20 * scale), width: 48 * scale, height: 80 * scale),
      Radius.circular(24 * scale),
    );
    canvas.drawRRect(headRect, Paint()..color = const Color(0xFF0F0D09));

    // 케이지 라인
    final cagePath = Path()
      ..moveTo(cx - 38 * scale, cy - 12 * scale)
      ..quadraticBezierTo(cx - 38 * scale, cy + 8 * scale, cx, cy + 8 * scale)
      ..quadraticBezierTo(cx + 38 * scale, cy + 8 * scale, cx + 38 * scale, cy - 12 * scale);
    canvas.drawPath(
      cagePath,
      Paint()
        ..color = const Color(0xFF0F0D09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );

    // 하이라이트
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 10 * scale, cy - 36 * scale), width: 12 * scale, height: 20 * scale),
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.15),
    );
  }

  @override
  bool shouldRepaint(_MoodPainter oldDelegate) => false;
}