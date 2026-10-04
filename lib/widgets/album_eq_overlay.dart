import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 곡 목록 · 미니플레이어 앨범 사진 위에 올리는 작은 이퀄라이저
/// 흰색 반투명 막대 5개, 가운데가 높고 양옆이 낮은 볼록한 모양.
/// 재생 중엔 부드럽게 움직이고, 일시정지하면 낮은 기본 높이로 스르륵 내려와 멈춤.
class AlbumEqOverlay extends StatefulWidget {
  final bool isPlaying;
  final double width;
  final double height;

  const AlbumEqOverlay({
    super.key,
    required this.isPlaying,
    this.width = 24,
    this.height = 20,
  });

  @override
  State<AlbumEqOverlay> createState() => _AlbumEqOverlayState();
}

class _AlbumEqOverlayState extends State<AlbumEqOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // 막대별 최대 높이 비율 (볼록한 모양)
  static const _shape = [0.5, 0.78, 1.0, 0.78, 0.5];
  // 막대별 움직임 속도(정수배라 끊김 없이 반복) / 시작 위치
  static const _speed = [2, 3, 2, 3, 2];
  static const _phase = [0.0, 1.7, 3.1, 4.4, 5.6];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9200), // 숫자가 클수록 느림
    );
    if (widget.isPlaying) _c.repeat();
  }

  @override
  void didUpdateWidget(AlbumEqOverlay old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.isPlaying && _c.isAnimating) {
      // 내려오는 동안은 조금 더 움직이다가 멈춤
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !widget.isPlaying) _c.stop();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barW = widget.width / (_shape.length * 1.9);
    final gap = (widget.width - barW * _shape.length) / (_shape.length - 1);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TweenAnimationBuilder<double>(
        // 재생 중 1 → 일시정지 0 으로 부드럽게
        tween: Tween(end: widget.isPlaying ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        builder: (context, f, _) => AnimatedBuilder(
          animation: _c,
          builder: (context, __) {
            final t = _c.value * 2 * math.pi;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_shape.length, (i) {
                final wave = 0.5 + 0.5 * math.sin(t * _speed[i] + _phase[i]);
                // 기본 높이 30% + 재생 중일 때 물결만큼
                final ratio = _shape[i] * (0.3 + 0.7 * f * (0.45 + 0.55 * wave));
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
                  child: Container(
                    width: barW,
                    height: math.max(barW, widget.height * ratio),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(barW),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}