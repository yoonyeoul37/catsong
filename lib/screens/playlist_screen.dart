import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/song_list_tile.dart';
import '../providers/theme_provider.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/action_feedback.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final playlists = playlistProvider.playlists;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.playlists,
                    style: TextStyle(
                        color: baseColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const Spacer(),
                IconButton(
                  onPressed: () => _showCreateDialog(context),
                  icon: Icon(Icons.add_circle, color: baseColor.withOpacity(0.7), size: 28),
                ),
              ],
            ),
          ),
        ),
        if (playlists.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add,
                      size: 72, color: baseColor.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.playlists,
                      style: TextStyle(
                          color: baseColor.withOpacity(0.6), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.playMusic,
                      style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 13)),
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
                  return _buildPlaylistTile(context, playlists[index], primaryColor);
                },
                childCount: playlists.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildPlaylistTile(BuildContext context, Playlist playlist, Color primaryColor) {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return InkWell(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PlaylistDetailScreen(playlist: playlist),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.playlist_play, color: baseColor.withOpacity(0.7), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name,
                      style: TextStyle(
                          color: baseColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('${AppLocalizations.of(context)!.playlistLabel} • ${playlist.songCount}${AppLocalizations.of(context)!.songCountSuffix}',
                      style: TextStyle(
                          color: baseColor.withOpacity(0.38), fontSize: 12)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: baseColor.withOpacity(0.38), size: 20),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                _buildPopupItem(Icons.edit, AppLocalizations.of(context)!.rename, 'rename', AppTheme.fixedAccent),
                _buildPopupItem(Icons.delete, AppLocalizations.of(context)!.delete, 'delete', Colors.redAccent),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(context, playlist);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, playlist);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      IconData icon, String label, String value, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) async {
    final name = await showParanInput(
      context,
      title: '새 재생목록',
      hint: AppLocalizations.of(context)!.playlistNameHint,
      confirmLabel: '만들기',
    );
    if (name == null || !context.mounted) return;
    context.read<PlaylistProvider>().createPlaylist(name);
    showActionFeedback(context, type: ActionFeedbackType.added, message: '재생목록을 만들었어요');
  }

  void _showRenameDialog(BuildContext context, Playlist playlist) async {
    final name = await showParanInput(
      context,
      title: '재생목록 이름 바꾸기',
      initial: playlist.name,
      confirmLabel: '바꾸기',
    );
    if (name == null || !context.mounted) return;
    context.read<PlaylistProvider>().renamePlaylist(playlist.id, name);
    showActionFeedback(context, type: ActionFeedbackType.edited, message: '이름을 바꿨어요');
  }

  void _showDeleteDialog(BuildContext context, Playlist playlist) async {
    final ok = await showParanConfirm(
      context,
      title: '재생목록을 삭제할까요?',
      message: "'${playlist.name}' 재생목록이 지워져요 (노래 파일은 그대로예요)",
      confirmLabel: '삭제',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    context.read<PlaylistProvider>().deletePlaylist(playlist.id);
    showActionFeedback(context, type: ActionFeedbackType.deleted);
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: bgColor,
            leading: IconButton(
              onPressed: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: baseColor),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.6),
                          primaryColor.withOpacity(0.2),
                          bgColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.playlist_play,
                              color: baseColor.withOpacity(0.7), size: 44),
                        ),
                        const SizedBox(height: 12),
                        Text(playlist.name,
                            style: TextStyle(
                                color: baseColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('재생목록 • ${playlist.songCount}곡',
                            style: TextStyle(
                                color: baseColor.withOpacity(0.6), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: playlist.songs.isEmpty ? null : () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      context.read<PlayerProvider>().playFromList(playlist.songs, 0);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.play_arrow, color: baseColor.withOpacity(0.6), size: 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: playlist.songs.isEmpty ? null : () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      final songs = List<Song>.from(playlist.songs)..shuffle();
                      context.read<PlayerProvider>().playFromList(songs, 0);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.shuffle, color: baseColor.withOpacity(0.6), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ),
          if (playlist.songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note,
                        size: 64, color: baseColor.withOpacity(0.12)),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.noSongs,
                        style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.addMusic,
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
                      song: playlist.songs[index],
                      index: index,
                      songList: playlist.songs,
                    );
                  },
                  childCount: playlist.songs.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}