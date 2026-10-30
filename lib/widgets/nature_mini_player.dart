import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/paran_photo.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/nature_sound_detail_screen.dart';
import '../l10n/locale_holder.dart';
import '../utils/nature_sound_catalog.dart';

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
    // 진한 띠 위라서 글자·아이콘은 늘 밝은 색 (라디오 미니 플레이어와 같음)
    const baseColor = Color(0xFFF4EFE5);
    const ink = Color(0xFF17140F);
    final meta = _natureSoundMeta[name];
    final accent = (meta?['color'] as Color?) ?? const Color(0xFF3E9C7E);
    final icon = (meta?['icon'] as IconData?) ?? Icons.eco_rounded;

    // ⏮ ⏭ : 자연소리 목록에서 이전·다음 (끝이면 처음으로)
    void step(int d) {
      final order = PlayerProvider.natureSoundOrder;
      if (order.isEmpty) return;
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      final i = order.indexWhere((s) => s['name'] == name);
      var n = ((i < 0 ? 0 : i) + d) % order.length;
      if (n < 0) n += order.length;
      final s = order[n];
      context.read<PlayerProvider>().playNatureSound(s['assetPath']!, s['name']!);
    }

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
      child: Stack(
        children: [
      ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.zero,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 72, // 음악·라디오 미니플레이어와 같은 높이 (예전 80)
            decoration: BoxDecoration(
              // 진한 띠 (어두운 화면에서는 바탕보다 한 톤 밝게)
              color: isDarkMode ? const Color(0xFF3A3A3A) : ink,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 22, 0), // 버튼은 오른쪽으로 · ✕는 오른쪽 위 작게
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
                        // 이름이 길면 좌우로 흐르게
                        _MiniTitle(isPlaying ? tr.naturePlaying(natureName(name)) : tr.naturePaused(natureName(name)),
                            const TextStyle(
                                color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(tr.natureSounds, style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(textDirection: TextDirection.ltr, mainAxisSize: MainAxisSize.min, children: [ // ⏮ ▶ ⏭ 순서는 어느 언어나 같게
                  // 이전 자연소리 (음악 미니플레이어와 같은 모양)
                  IconButton(
                    onPressed: () => step(-1),
                    icon: Icon(Icons.skip_previous, color: baseColor.withOpacity(0.7)),
                    iconSize: 26,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                      decoration: const BoxDecoration(color: baseColor, shape: BoxShape.circle),
                      child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                          color: ink, size: 22),
                    ),
                  ),
                  // 다음 자연소리
                  IconButton(
                    onPressed: () => step(1),
                    icon: Icon(Icons.skip_next, color: baseColor.withOpacity(0.7)),
                    iconSize: 26,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
          // × (닫기): 오른쪽 위 작게 · 재생 중에도 누르면 바로 멈추고 닫힘
          Positioned(top: 4, right: 2, child: _MiniCloseX(onTap: () => _close(context))),
        ],
      ),
    );
  }

  /// 미니플레이어 닫기: 자연소리 완전히 멈추고 비우기
  Future<void> _close(BuildContext context) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final p = context.read<PlayerProvider>();
    final resume = p.natureResumer();
    await p.player.stop();
    p.clearNatureSoundState();
    p.dismissMediaNotification(resume: resume);
  }
}

/// 글자가 칸보다 길면 좌우로 천천히 흐르게 (짧으면 그냥 글자) — 음악·라디오 미니플레이어와 같음
class _MiniTitle extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _MiniTitle(this.text, this.style);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (tp.width <= c.maxWidth) {
        return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      }
      return SizedBox(
        width: c.maxWidth,
        height: tp.height,
        child: Marquee(
          key: ValueKey(text),
          text: text,
          style: style,
          velocity: 28,
          blankSpace: 48,
          startAfter: const Duration(seconds: 2),
          pauseAfterRound: const Duration(seconds: 2),
          fadingEdgeStartFraction: 0.06,
          fadingEdgeEndFraction: 0.06,
          showFadingOnlyWhenScrolling: true,
        ),
      );
    });
  }
}

/// 미니플레이어 오른쪽 위 작은 ✕ (보이는 건 작게, 누르는 자리는 넉넉하게)
class _MiniCloseX extends StatelessWidget {
  final VoidCallback onTap;
  const _MiniCloseX({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(Icons.close_rounded, size: 17, color: const Color(0xFFF4EFE5).withOpacity(0.45)),
        ),
      );
}
