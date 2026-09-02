import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../screens/player_screen.dart';
import 'equalizer_animation.dart';
import '../providers/theme_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final song = playerProvider.currentSong;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -300) {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          playerProvider.playNext();
        } else if (details.primaryVelocity! > 300) {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          playerProvider.playPrevious();
        }
      },
      onTap: () {
        final isPlaying = context.read<PlayerProvider>().isPlaying;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 350),
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
              color: isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFEDE7DA).withOpacity(0.92),
              border: Border(
                top: BorderSide(color: baseColor.withOpacity(0.10)),
              ),
            ),
            child: Column(
              children: [
                // 진행바
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      value: playerProvider.progress,
                      backgroundColor: baseColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          baseColor.withOpacity(0.4)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // 앨범아트
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.albumArt != null
                                  ? Image.memory(
                                Uint8List.fromList(song.albumArt!),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                                  : Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/no_album2.jpg',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            if (playerProvider.isPlaying)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 16,
                                    child: EqualizerAnimation(color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // 제목/아티스트
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.titleDisplay,
                                style: TextStyle(
                                    color: baseColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      song.artistDisplay,
                                      style: TextStyle(
                                          color: baseColor.withOpacity(0.6),
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${playerProvider.formatDuration(playerProvider.position)} / ${playerProvider.formatDuration(playerProvider.duration)}',
                                    style: TextStyle(
                                        color: baseColor.withOpacity(0.38),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 이전 버튼
                        IconButton(
                          onPressed: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.playPrevious();
                          },
                          icon: Icon(Icons.skip_previous,
                              color: baseColor.withOpacity(0.7)),
                          iconSize: 26,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                        // 재생/정지 버튼
                        GestureDetector(
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.togglePlayPause();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: playerProvider.isLoading
                                ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: baseColor.withOpacity(0.7)),
                            )
                                : Icon(
                              playerProvider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: baseColor.withOpacity(0.7),
                              size: 22,
                            ),
                          ),
                        ),
                        // 다음 버튼
                        IconButton(
                          onPressed: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.playNext();
                          },
                          icon: Icon(Icons.skip_next,
                              color: baseColor.withOpacity(0.7)),
                          iconSize: 26,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
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
}