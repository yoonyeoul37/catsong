import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/sound_mix_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/sound_mix_screen.dart';

class SoundMixMiniPlayer extends StatelessWidget {
  const SoundMixMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final mix = context.watch<SoundMixProvider>();
    if (!mix.hasSession) return const SizedBox.shrink();

    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    const accent = Color(0xFF6366F1);

    final activeNames = [
      for (final entry in SoundMixProvider.natureAssets.keys)
        if (mix.volumeOf(entry) > 0) entry,
      if (mix.currentSong != null) mix.currentSong!.titleDisplay,
    ];
    final subtitle = activeNames.isEmpty ? '믹스 재생 중' : activeNames.join(' · ');

    return GestureDetector(
      // 아래로 휙 쓸어내리면 미니플레이어 닫기
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 300) _close(context);
      },
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SoundMixScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEDE7DA).withOpacity(0.92),
              border: Border(top: BorderSide(color: baseColor.withOpacity(0.10))),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('나만의 소리 믹스',
                            style: TextStyle(
                                color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: accent, fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (mix.isPlaying) {
                        context.read<SoundMixProvider>().stopAll();
                      } else {
                        context.read<SoundMixProvider>().playAll();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: baseColor.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(mix.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: baseColor.withOpacity(0.7), size: 20),
                    ),
                  ),
                  // × (닫기): 재생 중에도 누르면 바로 멈추고 닫힘
                  IconButton(
                    onPressed: () => _close(context),
                    icon: Icon(Icons.close, color: baseColor.withOpacity(0.45)),
                    iconSize: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 미니플레이어 닫기: 믹스 멈추고 닫기 (고른 소리·노래·음량은 그대로 기억)
  Future<void> _close(BuildContext context) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    await context.read<SoundMixProvider>().closeSession();
  }
}