import 'package:flutter/material.dart';

class SimpleRadioDial extends StatelessWidget {
  final String stationName;
  final String? logoUrl;
  final bool isPlaying;
  final Color primaryColor;
  final AnimationController pulseCtrl;

  const SimpleRadioDial({
    super.key,
    required this.stationName,
    required this.logoUrl,
    required this.isPlaying,
    required this.primaryColor,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: pulseCtrl,
        builder: (context, child) {
          final progress = isPlaying ? 0.55 + 0.05 * pulseCtrl.value : 0.55;
          return Stack(
            alignment: Alignment.center,
            children: [
              // 바깥 원형 트랙 (연한 배경 링)
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.08)),
                ),
              ),
              // 진행 표시 원형 (움직이는 두꺼운 링)
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation(primaryColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // 로고 또는 방송국 이름 (배경 원 없이 바로)
              SizedBox(
                width: 168,
                height: 168,
                child: (logoUrl != null && logoUrl!.isNotEmpty)
                    ? ClipOval(
                  child: Image.network(
                    logoUrl!,
                    width: 168,
                    height: 168,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        stationName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                    : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      stationName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
