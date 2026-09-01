import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_tile.dart';
import '../l10n/app_localizations.dart';

class RadioFavoritesScreen extends StatelessWidget {
  const RadioFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final accent = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);
    final radioProvider = context.watch<RadioProvider>();
    final favorites     = radioProvider.favorites;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF17140F),
          systemNavigationBarIconBrightness: Brightness.light,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFEDE7DA),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: accent, size: 20),
          onPressed: () {
            MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.favorites,
          style: TextStyle(
            color: accent,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: favorites.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.heart,
                size: 72,
                color: accent.withOpacity(0.4)),
            const SizedBox(height: 18),
            Text(AppLocalizations.of(context)!.radioNoFavorites,
                style: TextStyle(
                    color: accent.withOpacity(0.7),
                    fontSize: 17)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.radioNoFavoritesDesc,
                style: TextStyle(
                    color: accent.withOpacity(0.45),
                    fontSize: 13)),
          ],
        ),
      )
          : ListView.separated(
        padding:
        EdgeInsets.fromLTRB(24, 12, 24, 80 + MediaQuery.of(context).viewPadding.bottom),
        itemCount: favorites.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: accent.withOpacity(0.16)),
        itemBuilder: (context, index) {
          final station = favorites[index];
          return Dismissible(
            key: Key(station.stationUuid),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete,
                  color: Colors.redAccent, size: 26),
            ),
            onDismissed: (_) {
              radioProvider.toggleFavorite(station);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.radioRemovedFromFavorites),
                  backgroundColor: AppTheme.surfaceVariant,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              children: [
                Expanded(child: StationTile(station: station)),
                IconButton(
                  icon: Icon(Icons.close, color: accent.withOpacity(0.38), size: 20),
                  onPressed: () {
                    radioProvider.toggleFavorite(station);
                    final overlay = Overlay.of(context);
                    final entry = OverlayEntry(
                      builder: (_) => Positioned(
                        bottom: 180, left: 0, right: 0,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, value, child) => Opacity(
                              opacity: value,
                              child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.heart, color: Colors.black38, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.radioRemovedFromFavorites,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    overlay.insert(entry);
                    Future.delayed(const Duration(seconds: 2), () => entry.remove());
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
    );
  }
}