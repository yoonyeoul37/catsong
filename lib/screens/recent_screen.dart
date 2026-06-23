import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations.dart';

String _formatPlayedAt(BuildContext context, DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  final l = AppLocalizations.of(context)!;
  if (diff.inMinutes < 1) return l.justNow;
  if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
  return l.dateFormat(dt.year, dt.month, dt.day);
}

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final recentSongs = musicProvider.recentSongs;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.recent,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Text('${recentSongs.length}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 16)),
                const Spacer(),
                if (recentSongs.isNotEmpty) ...[
                  IconButton(
                    onPressed: () {
                      context.read<PlayerProvider>().playFromList(recentSongs, 0);
                      final overlay = Overlay.of(context);
                      final entry = OverlayEntry(
                        builder: (_) => Positioned(
                          top: 60, left: 0, right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(AppLocalizations.of(context)!.playAll,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, decoration: TextDecoration.none)),
                            ),
                          ),
                        ),
                      );
                      overlay.insert(entry);
                      Future.delayed(const Duration(milliseconds: 800), () => entry.remove());
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white60, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () {
                      final songs = List<Song>.from(recentSongs)..shuffle();
                      context.read<PlayerProvider>().playFromList(songs, 0);
                      final overlay = Overlay.of(context);
                      final entry = OverlayEntry(
                        builder: (_) => Positioned(
                          top: 60, left: 0, right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(AppLocalizations.of(context)!.shuffle,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, decoration: TextDecoration.none)),
                            ),
                          ),
                        ),
                      );
                      overlay.insert(entry);
                      Future.delayed(const Duration(milliseconds: 800), () => entry.remove());
                    },
                    icon: const Icon(Icons.shuffle, color: Colors.white60, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () => _showClearAllDialog(context),
                    icon: const Icon(Icons.delete_sweep, color: Colors.white38, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        if (recentSongs.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 72, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noRecentSongs,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.playMusic,
                      style: const TextStyle(color: Colors.white24, fontSize: 13)),
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
                  final song = recentSongs[index];
                  return Dismissible(
                    key: Key('recent_${song.id}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      context.read<MusicProvider>().removeFromRecent(song);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (song.lastPlayedAt != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Text(
                              _formatPlayedAt(context, song.lastPlayedAt!),
                              style: const TextStyle(
                                  color: Colors.white24, fontSize: 11),
                            ),
                          ),
                        SongListTile(
                          song: song,
                          index: index,
                          songList: recentSongs,
                        ),
                      ],
                    ),
                  );
                },
                childCount: recentSongs.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_sweep, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.clearRecent,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.clearRecentConfirm,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<MusicProvider>().clearRecent();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}