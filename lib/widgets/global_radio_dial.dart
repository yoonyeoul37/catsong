import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'station_logo.dart';

class GlobalRadioDial extends StatefulWidget {
  final String stationName;
  final String? logoUrl;
  final bool isPlaying;
  final Color primaryColor;
  final AnimationController pulseCtrl;

  const GlobalRadioDial({
    super.key,
    required this.stationName,
    required this.logoUrl,
    required this.isPlaying,
    required this.primaryColor,
    required this.pulseCtrl,
  });

  @override
  State<GlobalRadioDial> createState() => _GlobalRadioDialState();
}

class _GlobalRadioDialState extends State<GlobalRadioDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    if (widget.isPlaying) _rotCtrl.repeat();
  }

  @override
  void didUpdateWidget(GlobalRadioDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_rotCtrl.isAnimating) {
      _rotCtrl.repeat();
    } else if (!widget.isPlaying && _rotCtrl.isAnimating) {
      _rotCtrl.stop();
    }
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 외곽 글로우 + 펄스
          AnimatedBuilder(
            animation: widget.pulseCtrl,
            builder: (context, child) {
              final glow = widget.isPlaying
                  ? 0.25 + 0.15 * widget.pulseCtrl.value
                  : 0.12;
              return Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(glow),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              );
            },
          ),

          // 회전하는 원형 (흐릿한 배경 이미지)
          AnimatedBuilder(
            animation: _rotCtrl,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotCtrl.value * 2 * pi,
                child: child,
              );
            },
            child: ClipOval(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 블러된 배경 이미지 (로고 확대)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: StationLogo(
                        logoUrl: widget.logoUrl,
                        name: widget.stationName,
                        size: 260,
                        fontSize: 90,
                      ),
                    ),
                    // 어둡게 오버레이
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withOpacity(0.15),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                    // 회전 테두리 장식 (도트)
                    ...List.generate(24, (i) {
                      final angle = (i / 24) * 2 * pi;
                      return Align(
                        alignment: Alignment(
                          0.93 * cos(angle),
                          0.93 * sin(angle),
                        ),
                        child: Container(
                          width: i % 6 == 0 ? 3 : 1.5,
                          height: i % 6 == 0 ? 3 : 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(i % 6 == 0 ? 0.6 : 0.3),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // 고정 테두리 링
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.primaryColor.withOpacity(0.6),
                width: 2,
              ),
            ),
          ),

          // 중앙 고정 텍스트 (회전 안 함)
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.55),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.stationName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}