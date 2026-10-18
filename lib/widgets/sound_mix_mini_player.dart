import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/sound_mix_provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/sound_mix_screen.dart';
import '../l10n/locale_holder.dart';
import '../utils/nature_sound_catalog.dart';

class SoundMixMiniPlayer extends StatelessWidget {
  const SoundMixMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final mix = context.watch<SoundMixProvider>();
    if (!mix.hasSession) return const SizedBox.shrink();

    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    // 진한 띠 위라서 글자·아이콘은 늘 밝은 색 (라디오 미니 플레이어와 같음)
    const baseColor = Color(0xFFF4EFE5);
    const ink = Color(0xFF17140F);
    const accent = Color(0xFF6366F1);

    final activeNames = [
      for (final entry in SoundMixProvider.natureAssets.keys)
        if (mix.volumeOf(entry) > 0) natureName(entry),
      if (mix.currentSong != null) mix.currentSong!.titleDisplay,
    ];
    final subtitle = activeNames.isEmpty ? tr.mixPlaying : activeNames.join(' · ');

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
              color: isDarkMode ? const Color(0xFF3A3631) : ink,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 22, 0), // 버튼은 오른쪽으로 · ✕는 오른쪽 위 작게
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
                        Text(tr.myMixDefault,
                            style: TextStyle(
                                color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        // 섞은 소리 이름이 길면 좌우로 흐르게
                        _MiniTitle(subtitle, TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12)),
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
                      decoration: const BoxDecoration(color: baseColor, shape: BoxShape.circle),
                      child: Icon(mix.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: ink, size: 22),
                    ),
                  ),
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

  /// 미니플레이어 닫기: 믹스 멈추고 닫기 (고른 소리·노래·음량은 그대로 기억)
  Future<void> _close(BuildContext context) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pp = context.read<PlayerProvider>();
    final mix = context.read<SoundMixProvider>();
    await mix.closeSession();
    pp.dismissMediaNotification(resume: () => mix.playAll());
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
