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

// 마지막에 누른 버튼 기억 (true = 셔플, false = 전체재생)
final ValueNotifier<bool> _favShuffleOn = ValueNotifier(false);

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
    // 큰 버튼은 먹색 (다크 모드는 크림색)
    final inkFill = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final inkText = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);

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
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  const SizedBox(width: 8),
                  Text('(${favorites.length})',
                      style: TextStyle(
                          color: baseColor.withOpacity(0.38), fontSize: 13)),
                ],
              ),
            ),
          ),
        if (favorites.isNotEmpty)
          SliverToBoxAdapter(
            child: ValueListenableBuilder<bool>(
              valueListenable: _favShuffleOn,
              builder: (context, shuffleOn, _) => Padding(
              padding: EdgeInsets.fromLTRB(16, showHeader ? 0 : 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _favShuffleOn.value = false;
                        context.read<PlayerProvider>()
                            .playFromList(favorites, 0, isPlayAllAction: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: shuffleOn ? Colors.transparent : inkFill,
                        foregroundColor: shuffleOn ? baseColor : inkText,
                        side: shuffleOn ? BorderSide(color: baseColor.withOpacity(0.16)) : null,
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
                        _favShuffleOn.value = true;
                        final songs = List<Song>.from(favorites)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0, isPlayAllAction: true);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: shuffleOn ? inkFill : null,
                        foregroundColor: shuffleOn ? inkText : baseColor,
                        side: BorderSide(color: shuffleOn ? Colors.transparent : baseColor.withOpacity(0.16)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.shuffle,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              ),
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