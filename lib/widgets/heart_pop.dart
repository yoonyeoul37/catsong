import 'package:flutter/material.dart';

/// 하트가 켜질 때 통통 튀기 (1 → 1.35 → 0.9 → 1, 0.45초) — 끌 때는 조용히
class HeartPop extends StatefulWidget {
  final bool on;
  final Widget child;
  const HeartPop({super.key, required this.on, required this.child});

  @override
  State<HeartPop> createState() => _HeartPopState();
}

class _HeartPopState extends State<HeartPop> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 35),
  ]).animate(_c);

  @override
  void didUpdateWidget(HeartPop old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on) _c.forward(from: 0); // 켜질 때만
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}
