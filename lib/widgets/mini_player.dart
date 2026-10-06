import '../utils/no_album_helper.dart';
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
import 'album_eq_overlay.dart';
import '../providers/theme_provider.dart';
import '../services/cast_service.dart';
import '../providers/music_provider.dart';

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

    // 녹음을 듣는 중이면 ⏮⏭ 대신 10초 앞뒤 + 배속 (녹음 화면 재생 막대를 여기로 합침)
    final isRec = context.read<MusicProvider>().isCallRecordingPath(song.uri);
    void jump(int sec) {
      var to = playerProvider.position + Duration(seconds: sec);
      if (to < Duration.zero) to = Duration.zero;
      final dur = playerProvider.duration;
      if (dur > Duration.zero && to > dur) to = dur;
      playerProvider.seekTo(to);
    }

    return GestureDetector(
      // 아래로 휙 쓸어내리면 미니플레이어 닫기
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 300) _close(context);
      },
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
                                    noAlbumImagePath(song.uri ?? song.title),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: AlbumEqOverlay(
                                  isPlaying: playerProvider.isPlaying,
                                  width: 20,
                                  height: 16,
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
                                  // TV로 듣는 중이면 가수 대신 📺 TV 이름
                                  if (CastService.instance.isConnected) ...[
                                    const Icon(Icons.cast_connected, size: 13, color: Color(0xFF2589E8)),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      CastService.instance.isConnected
                                          ? '${CastService.instance.device?.name ?? 'TV'}에서 재생'
                                          : song.artistDisplay,
                                      style: TextStyle(
                                          color: CastService.instance.isConnected
                                              ? const Color(0xFF2589E8)
                                              : baseColor.withOpacity(0.6),
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // 녹음처럼 버튼이 많거나 작은 폰에서도 넘치지 않게
                                  Flexible(
                                    child: Text(
                                      '${playerProvider.formatDuration(playerProvider.position)} / ${playerProvider.formatDuration(playerProvider.duration)}',
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                          color: baseColor.withOpacity(0.38),
                                          fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 이전 버튼 (녹음이면 10초 뒤로)
                        IconButton(
                          onPressed: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            isRec ? jump(-10) : playerProvider.playPrevious();
                          },
                          icon: Icon(isRec ? Icons.replay_10 : Icons.skip_previous,
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
                        // 다음 버튼 (녹음이면 10초 앞으로)
                        IconButton(
                          onPressed: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            isRec ? jump(10) : playerProvider.playNext();
                          },
                          icon: Icon(isRec ? Icons.forward_10 : Icons.skip_next,
                              color: baseColor.withOpacity(0.7)),
                          iconSize: 26,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                        // 녹음이면 배속 (누를 때마다 1.0 → 1.25 → 1.5 → 2.0)
                        if (isRec)
                          GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              const speeds = [1.0, 1.25, 1.5, 2.0];
                              final s = playerProvider.playbackSpeed;
                              final i = speeds.indexWhere((x) => (x - s).abs() < 0.01);
                              playerProvider.setPlaybackSpeed(speeds[(i + 1) % speeds.length]);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: baseColor.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${playerProvider.playbackSpeed == playerProvider.playbackSpeed.roundToDouble() ? playerProvider.playbackSpeed.toStringAsFixed(1) : playerProvider.playbackSpeed}×',
                                style: TextStyle(
                                    color: baseColor.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w700),
                              ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 미니플레이어 닫기: 완전히 멈추고 비우기 (TV로 보내는 중이면 TV도 끊기)
  Future<void> _close(BuildContext context) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final p = context.read<PlayerProvider>();
    if (CastService.instance.isConnected) await CastService.instance.disconnect();
    await p.player.stop();
    p.clearNatureSoundState();
    p.clearCurrentSong();
  }
}