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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}