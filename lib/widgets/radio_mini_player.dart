import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../screens/radio_player_screen.dart';
import 'dart:math' as math;
import '../services/cast_service.dart';

class RadioMiniPlayer extends StatelessWidget {
  const RadioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final station = radioProvider.currentStation;

    if (station == null) return const SizedBox.shrink();

    final isPlaying = radioProvider.isPlaying;
    final isLoading = radioProvider.isLoading;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    // 진한 띠 위라서 글자·아이콘은 늘 밝은 색
    const baseColor = Color(0xFFF4EFE5);
    const ink = Color(0xFF17140F);

    // ⏮ ⏭ : 지금 목록에서 이전·다음 방송 (끝이면 처음으로)
    void step(int d) {
      final queue = radioProvider.currentQueue;
      if (queue.isEmpty) return;
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      final idx = radioProvider.currentQueueIndex;
      final n = (idx + d) % queue.length;
      final newIdx = n < 0 ? n + queue.length : n;
      radioProvider.setQueue(queue, newIdx);
      radioProvider.playStation(queue[newIdx]);
    }
    final canStep = radioProvider.currentQueue.length > 1;

    return GestureDetector(
      // 아래로 휙 쓸어내리면 미니플레이어 닫기
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 300) _close(context);
      },
      onHorizontalDragEnd: (details) {
        final queue = radioProvider.currentQueue;
        if (queue.isEmpty) return;
        final idx = radioProvider.currentQueueIndex;
        if (details.primaryVelocity! < -300) {
          // 왼쪽 스와이프 → 다음
          final newIdx = idx < queue.length - 1 ? idx + 1 : 0;
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          radioProvider.setQueue(queue, newIdx);
          radioProvider.playStation(queue[newIdx]);
        } else if (details.primaryVelocity! > 300) {
          // 오른쪽 스와이프 → 이전
          final newIdx = idx > 0 ? idx - 1 : queue.length - 1;
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          radioProvider.setQueue(queue, newIdx);
          radioProvider.playStation(queue[newIdx]);
        }
      },
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => RadioPlayerScreen(
            station: station,
            stationList: radioProvider.currentQueue.isNotEmpty
                ? radioProvider.currentQueue
                : null,
            currentIndex: radioProvider.currentQueueIndex >= 0
                ? radioProvider.currentQueueIndex
                : null,
            openedFromList: false,
          ),
          transitionsBuilder: (_, animation, __, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.zero,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 72, // 살짝 낮게 (예전 80)
            decoration: BoxDecoration(
              // 진한 띠 (어두운 화면에서는 바탕보다 한 톤 밝게)
              color: isDarkMode ? const Color(0xFF3A3631) : ink,
            ),
            child: Column(
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? baseColor.withOpacity(0.6)
                        : baseColor.withOpacity(0.15),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: baseColor.withOpacity(0.08),
                            border: Border.all(
                                color: baseColor.withOpacity(0.15)),
                          ),
                          alignment: Alignment.center,
                          child: isPlaying
                              ? _MiniEqualizerBars(color: Theme.of(context).colorScheme.primary) // 포인트 색
                              : Icon(Icons.radio, color: baseColor.withOpacity(0.6), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 방송 이름이 길면 좌우로 흐르게
                              _MiniTitle(
                                station.name,
                                const TextStyle(
                                  color: baseColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    isLoading
                                        ? '접속 중...'
                                        : radioProvider.playerState == RadioPlayerState.error
                                        ? '나오지 않아요'
                                        : isPlaying
                                        ? '● LIVE'
                                        : '일시정지',
                                    style: TextStyle(
                                      // LIVE는 어디서나 빨강 (생방송 표시)
                                      color: isPlaying
                                          ? const Color(0xFFD84A3A)
                                          : baseColor.withOpacity(0.6),
                                      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  // 안 나오는 해외 방송 → 같은 나라 비슷한 방송
                                  if (radioProvider.similarStation != null) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                        radioProvider.playSimilar();
                                      },
                                      child: Text('비슷한 방송 듣기 ›',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                  if (isPlaying || radioProvider.currentStation != null) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Builder(builder: (ctx) {
                                        final nowPlaying = radioProvider.nowPlayingFor(station.name);
                                        final program = radioProvider.currentProgramFor(station.name);
                                        final kbsStart = program?['program_planned_start_time'] as String? ?? '';
                                        final kbsEnd = program?['program_planned_end_time'] as String? ?? '';
                                        final mbcStart = program?['StartTime'] as String? ?? '';
                                        final mbcEnd = program?['EndTime'] as String? ?? '';
                                        final sbsStart = program?['start_time'] as String? ?? '';
                                        final sbsEnd = program?['end_time'] as String? ?? '';

                                        String fmt(String t) {
                                          if (t.contains(':')) {
                                            final parts = t.split(':');
                                            int h = int.tryParse(parts[0]) ?? 0;
                                            if (h >= 24) h -= 24;
                                            return '$h:${parts[1]}';
                                          }
                                          if (t.length < 4) return t;
                                          int h = int.tryParse(t.substring(0, 2)) ?? 0;
                                          if (h >= 24) h -= 24;
                                          return '$h:${t.substring(2, 4)}';
                                        }

                                        String timeStr = '';
                                        if (kbsStart.isNotEmpty && kbsEnd.isNotEmpty) {
                                          timeStr = '${fmt(kbsStart)}~${fmt(kbsEnd)}';
                                        } else if (mbcStart.isNotEmpty && mbcEnd.isNotEmpty) {
                                          timeStr = '${fmt(mbcStart)}~${fmt(mbcEnd)}';
                                        } else if (sbsStart.isNotEmpty && sbsEnd.isNotEmpty) {
                                          timeStr = '$sbsStart~$sbsEnd';
                                        }

                                        if (nowPlaying == null || nowPlaying.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          timeStr.isNotEmpty ? '$nowPlaying  $timeStr' : nowPlaying,
                                          style: TextStyle(
                                            color: baseColor.withOpacity(0.6),
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 이전 방송 (음악 미니플레이어와 같은 모양)
                        if (canStep)
                          IconButton(
                            onPressed: () => step(-1),
                            icon: Icon(Icons.skip_previous, color: baseColor.withOpacity(0.7)),
                            iconSize: 26,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            radioProvider.togglePlayPause();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                            child: isLoading
                                ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ink),
                            )
                                : Icon(
                              isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: ink,
                              size: 22,
                            ),
                          ),
                        ),
                        // 다음 방송
                        if (canStep)
                          IconButton(
                            onPressed: () => step(1),
                            icon: Icon(Icons.skip_next, color: baseColor.withOpacity(0.7)),
                            iconSize: 26,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        // × (닫기): 재생 중에도 누르면 바로 멈추고 닫힘
                        IconButton(
                          onPressed: () => _close(context),
                          icon: Icon(Icons.close_rounded, color: baseColor.withOpacity(0.45)),
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 미니플레이어 닫기: 라디오 완전히 멈추고 비우기 (TV로 보내는 중이면 TV도 끊기)
  Future<void> _close(BuildContext context) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pp = context.read<PlayerProvider>();
    final radio = context.read<RadioProvider>();
    if (CastService.instance.isConnected) await CastService.instance.disconnect();
    final st = radio.currentStation;
    await radio.stopRadioAndClear();
    pp.dismissMediaNotification(resume: st == null ? null : () => radio.playStation(st));
  }
}
class _MiniEqualizerBars extends StatefulWidget {
  final Color color;
  const _MiniEqualizerBars({required this.color});

  @override
  State<_MiniEqualizerBars> createState() => _MiniEqualizerBarsState();
}

class _MiniEqualizerBarsState extends State<_MiniEqualizerBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 900 + i * 300),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrls[i],
            builder: (_, __) => Container(
              width: 3,
              height: 4 + _ctrls[i].value * 12,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 제목이 칸보다 길면 좌우로 천천히 흐르게 (짧으면 그냥 글자)
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
          key: ValueKey(text), // 곡이 바뀌면 처음부터
          text: text,
          style: style,
          velocity: 28, // 천천히
          blankSpace: 48,
          startAfter: const Duration(seconds: 2), // 2초 보여 주고 출발
          pauseAfterRound: const Duration(seconds: 2), // 한 바퀴 돌면 2초 쉬기
          fadingEdgeStartFraction: 0.06,
          fadingEdgeEndFraction: 0.06,
          showFadingOnlyWhenScrolling: true,
        ),
      );
    });
  }
}
