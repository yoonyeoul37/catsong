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
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (station == null) return const SizedBox.shrink();

    final isPlaying = radioProvider.isPlaying;
    final isLoading = radioProvider.isLoading;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              RadioPlayerScreen(station: station),
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
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // LIVE 바 (움직이지 않는 고정 색상)
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: isPlaying
                    ? Colors.redAccent
                    : primaryColor.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.15),
                        border: Border.all(
                            color: primaryColor.withOpacity(0.4)),
                      ),
                      child: Icon(Icons.radio,
                          color: primaryColor, size: 22),
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
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: isLoading
                            ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black),
                        )
                            : Icon(
                          isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.black,
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
    );
  }
}