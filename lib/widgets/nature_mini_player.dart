import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/paran_photo.dart';
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

// 목록 화면과 같은 사진들을 여기서도 쓴다. 파도소리 종류는 이름으로 하나를 골라 고정한다.
const List<String> _miniWaveImages = [
  'assets/nature_wave_bg.png',
  'assets/wave2.png',
  'assets/wave3.png',
  'assets/wave4.png',
  'assets/wave5.png',
  'assets/wave6.png',
];

String _natureMiniImage(String name) {
  if (name.contains('파도') || name.contains('갈매기')) {
    return _miniWaveImages[name.hashCode.abs() % _miniWaveImages.length];
  }
  switch (name) {
    case '빗소리':
      return 'assets/nature_rain_bg.png';
    case '새소리':
      return 'assets/nature_bird_bg.png';
    case '모닥불':
      return 'assets/nature_fire_bg.png';
    case '시냇물':
      return 'assets/nature_stream_bg.png';
    default:
      return 'assets/nature_wave_bg.png';
  }
}

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
      // 아래로 휙 쓸어내리면 미니플레이어 닫기
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 300) _close(context);
      },
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
              openedFromList: false,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: paranPhoto(
                      _natureMiniImage(name),
                      thumb: true,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      fallback: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                    ),
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

  /// 미니플레이어 닫기: 자연소리 완전히 멈추고 비우기
  Future<void> _close(BuildContext context) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final p = context.read<PlayerProvider>();
    await p.player.stop();
    p.clearNatureSoundState();
  }
}