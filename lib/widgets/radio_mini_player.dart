import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../screens/radio_player_screen.dart';

class RadioMiniPlayer extends StatelessWidget {
  const RadioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final radioProvider = context.watch<RadioProvider>();
    final station = radioProvider.currentStation;

    if (station == null) return const SizedBox.shrink();

    final isPlaying = radioProvider.isPlaying;
    final isLoading = radioProvider.isLoading;

    return GestureDetector(
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
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? Colors.redAccent
                        : AppTheme.fixedAccent.withOpacity(0.3),
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
                            color: AppTheme.fixedAccent.withOpacity(0.15),
                            border: Border.all(
                                color: AppTheme.fixedAccent.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.radio,
                              color: AppTheme.fixedAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    isLoading
                                        ? '접속 중...'
                                        : isPlaying
                                        ? '● LIVE'
                                        : '일시정지',
                                    style: TextStyle(
                                      color: isPlaying
                                          ? Colors.redAccent
                                          : AppTheme.textHint,
                                      fontSize: 12,
                                    ),
                                  ),
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
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 8,
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
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : radioProvider.togglePlayPause,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppTheme.fixedAccent,
                              shape: BoxShape.circle,
                            ),
                            child: isLoading
                                ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                                : Icon(
                              isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
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
}