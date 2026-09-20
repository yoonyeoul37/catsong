import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/nature_sound_detail_screen.dart';

const _natureSoundMeta = <String, Map<String, dynamic>>{
  '파도소리': {'icon': Icons.waves, 'color': Color(0xFF4A7BA6)},
  '빗소리': {'icon': Icons.water_drop_outlined, 'color': Color(0xFF3E5A78)},
  '새소리': {'icon': Icons.forest_outlined, 'color': Color(0xFF5C7A5E)},
  '모닥불': {'icon': Icons.local_fire_department_outlined, 'color': Color(0xFFC97B4A)},
  '시냇물': {'icon': Icons.water_outlined, 'color': Color(0xFF2C6BB3)},
};

class NatureMiniPlayer extends StatelessWidget {
  const NatureMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final name = playerProvider.natureSoundName;
    if (name == null) return const SizedBox.shrink();

    final isPlaying = playerProvider.isPlaying;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final meta = _natureSoundMeta[name];
    final accent = (meta?['color'] as Color?) ?? const Color(0xFF3E9C7E);
    final icon = (meta?['icon'] as IconData?) ?? Icons.eco_rounded;

    return GestureDetector(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NatureSoundDetailScreen(
              name: name,
              icon: icon,
              description: '',
              assetPath: null,
              color: accent,
            ),
          ),
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
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPlaying ? '$name 재생 중' : '$name 일시정지',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('자연소리', style: TextStyle(color: accent, fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (isPlaying) {
                        context.read<PlayerProvider>().pauseNatureSound();
                      } else {
                        context.read<PlayerProvider>().resumeNatureSound();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: baseColor.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
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