import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/song_list_tile.dart';

class FavoritesScreen extends StatelessWidget {
  final bool showHeader;
  const FavoritesScreen({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final favorites = musicProvider.favorites;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return CustomScrollView(
      slivers: [
        if (showHeader)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(AppLocalizations.of(context)!.favorites,
                      style: TextStyle(
                          color: baseColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  const SizedBox(width: 8),
                  Text('${favorites.length}',
                      style: TextStyle(
                          color: baseColor.withOpacity(0.38), fontSize: 16)),
                ],
              ),
            ),
          ),
        if (favorites.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, showHeader ? 0 : 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<PlayerProvider>()
                            .playFromList(favorites, 0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.lerp(primaryColor, Colors.black, 0.15),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(AppLocalizations.of(context)!.playAll,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final songs = List<Song>.from(favorites)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: baseColor,
                        side: BorderSide(color: baseColor.withOpacity(0.16)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.shuffle, size: 18),
                      label: Text(AppLocalizations.of(context)!.shuffle,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (favorites.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.heart,
                      size: 72, color: baseColor.withOpacity(0.24)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.favorites,
                      style: TextStyle(
                          color: baseColor.withOpacity(0.38), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.playMusic,
                      style: TextStyle(color: baseColor.withOpacity(0.24), fontSize: 13)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return SongListTile(
                    song: favorites[index],
                    index: index,
                    songList: favorites,
                  );
                },
                childCount: favorites.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}