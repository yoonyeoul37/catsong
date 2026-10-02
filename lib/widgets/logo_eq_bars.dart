import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 제목 옆에 붙는 작은 파란 이퀄라이저 (계속 움직임)
class LogoEqBars extends StatefulWidget {
  const LogoEqBars({super.key});

  @override
  State<LogoEqBars> createState() => _LogoEqBarsState();
}

class _LogoEqBarsState extends State<LogoEqBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final t = _c.value * 2 * math.pi + i * 1.3;
              final v = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t));
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                child: Container(
                  width: 3,
                  height: 14 * v,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F7DE8),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}