import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/radio_mini_player.dart';
import '../widgets/station_tile.dart';

class RadioFavoritesScreen extends StatelessWidget {
  const RadioFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor  = Theme.of(context).colorScheme.primary;
    final radioProvider = context.watch<RadioProvider>();
    final favorites     = radioProvider.favorites;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '즐겨찾기',
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
                color: primaryColor.withOpacity(0.3)),
            const SizedBox(height: 18),
            const Text('즐겨찾기가 없습니다',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 17)),
            const SizedBox(height: 8),
            const Text('채널 목록에서 ♡를 눌러 추가해 보세요',
                style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 13)),
          ],
        ),
      )
          : ListView.builder(
        padding:
        const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final station = favorites[index];
          return Dismissible(
            key: Key(station.stationUuid),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.redAccent.withOpacity(0.8),
              child: const Icon(Icons.delete,
                  color: Colors.white, size: 26),
            ),
            onDismissed: (_) {
              radioProvider.toggleFavorite(station);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('즐겨찾기에서 제거했습니다'),
                  backgroundColor: AppTheme.surfaceVariant,
                  duration: Duration(seconds: 2),
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