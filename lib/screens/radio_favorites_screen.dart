import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_tile.dart';
import '../l10n/app_localizations.dart';

class RadioFavoritesScreen extends StatelessWidget {
  const RadioFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Colors.white;
    final radioProvider = context.watch<RadioProvider>();
    final favorites     = radioProvider.favorites;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.favorites,
          style: const TextStyle(
            color: AppTheme.textPrimary,
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
            Icon(Icons.favorite_border,
                size: 72,
                color: accent.withOpacity(0.4)),
            const SizedBox(height: 18),
            Text(AppLocalizations.of(context)!.radioNoFavorites,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 17)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.radioNoFavoritesDesc,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13)),
          ],
        ),
      )
          : ListView.separated(
        padding:
        EdgeInsets.fromLTRB(24, 12, 24, 80 + MediaQuery.of(context).viewPadding.bottom),
        itemCount: favorites.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.white.withOpacity(0.16)),
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
            child: StationTile(station: station),
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