import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../screens/player_screen.dart';
import '../screens/edit_song_screen.dart';
import '../screens/ringtone_screen.dart';
import '../screens/equalizer_screen.dart';
import 'equalizer_animation.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class SongListTile extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song> songList;

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.songList,
  });

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final isCurrentSong = playerProvider.currentSong?.id == song.id;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isFav = musicProvider.isFavorite(song.id);

    return InkWell(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        context.read<PlayerProvider>().playFromList(songList, index);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const PlayerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            _buildAlbumArt(isCurrentSong, playerProvider, primaryColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.titleDisplay,
                    style: TextStyle(
                      color: isCurrentSong ? primaryColor : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artistDisplay,
                    style: TextStyle(
                      color: isCurrentSong
                          ? primaryColor.withOpacity(0.7)
                          : Colors.white38,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              song.durationFormatted,
              style: TextStyle(
                color: isCurrentSong ? primaryColor : Colors.white30,
                fontSize: 12,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: isCurrentSong ? primaryColor : Colors.white30,
                  size: 20),
              color: AppTheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                _buildPopupItem(Icons.play_arrow, AppLocalizations.of(context)!.play, 'play', primaryColor),
                _buildPopupItem(Icons.skip_next, AppLocalizations.of(context)!.playNext, 'play_next', primaryColor),
                _buildPopupItem(Icons.playlist_add, AppLocalizations.of(context)!.addToPlaylist, 'playlist', primaryColor),
                _buildPopupItem(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  isFav ? AppLocalizations.of(context)!.removeFromFavorites : AppLocalizations.of(context)!.addToFavorites,
                  'favorite',
                  isFav ? Colors.redAccent : primaryColor,
                ),
                _buildPopupItem(Icons.music_note, AppLocalizations.of(context)!.setRingtone, 'ringtone', primaryColor),
                _buildPopupItem(Icons.info_outline, AppLocalizations.of(context)!.songInfo, 'info', primaryColor),
                _buildPopupItem(Icons.equalizer, AppLocalizations.of(context)!.equalizer, 'equalizer', primaryColor),
                _buildPopupItem(Icons.share, AppLocalizations.of(context)!.share, 'share', primaryColor),
                _buildPopupItem(Icons.delete_outline, AppLocalizations.of(context)!.delete, 'delete', Colors.redAccent),
              ],
              onSelected: (value) => _handleMenuAction(context, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt(bool isCurrentSong, PlayerProvider playerProvider, Color primaryColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: song.albumArt != null
              ? Image.memory(
            Uint8List.fromList(song.albumArt!),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: 52,
            cacheHeight: 52,
          )
              : Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/no_album.svg',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (isCurrentSong)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: playerProvider.isPlaying
                ? EqualizerAnimation(color: primaryColor)
                : Icon(Icons.pause, color: primaryColor, size: 22),
          ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      IconData icon, String label, String value, Color primaryColor) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    final playerProvider = context.read<PlayerProvider>();
    final musicProvider = context.read<MusicProvider>();

    switch (action) {
      case 'play':
        playerProvider.playFromList(songList, index);
        break;
      case 'play_next':
        playerProvider.addToPlayNext(song);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.addedToQueue),
            backgroundColor: AppTheme.surfaceVariant,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'playlist':
        _showAddToPlaylistDialog(context, song);
        break;
      case 'favorite':
        musicProvider.toggleFavorite(song);
        final isFav = musicProvider.isFavorite(song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFav ? '즐겨찾기에 추가됐습니다' : '즐겨찾기에서 제거됐습니다'),
            backgroundColor: AppTheme.surfaceVariant,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'ringtone':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RingtoneScreen(initialSong: song),
          ),
        );
        break;
      case 'info':
        _showSongInfo(context);
        break;
      case 'equalizer':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EqualizerScreen(),
          ),
        );
        break;
      case 'share':
        if (song.uri != null) {
          final file = XFile(song.uri!);
          await Share.shareXFiles([file], text: song.titleDisplay);
        }
        break;
      case 'delete':
        _showDeleteDialog(context, song);
        break;
    }
  }

  void _showAddToPlaylistDialog(BuildContext context, song) {
    final playlistProvider = context.read<PlaylistProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(AppLocalizations.of(context)!.addToPlaylist,
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: playlistProvider.playlists.isEmpty
            ? Text(AppLocalizations.of(context)!.noPlaylists,
            style: const TextStyle(color: AppTheme.textSecondary))
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlistProvider.playlists[index];
              return ListTile(
                leading: Icon(Icons.playlist_play, color: primaryColor),
                title: Text(playlist.name,
                    style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text('${playlist.songCount}곡',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  playlistProvider.addSongToPlaylist(playlist.id, song);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${playlist.name} ${AppLocalizations.of(context)!.addedToPlaylist}'),
                      backgroundColor: AppTheme.surfaceVariant,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close, style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSongInfo(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(AppLocalizations.of(context)!.songInfo,
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(AppLocalizations.of(context)!.title, song.titleDisplay, primaryColor),
            _infoRow(AppLocalizations.of(context)!.artist, song.artistDisplay, primaryColor),
            _infoRow(AppLocalizations.of(context)!.album, song.albumDisplay, primaryColor),
            _infoRow(AppLocalizations.of(context)!.playTime, song.durationFormatted, primaryColor),
            if (song.uri != null) _infoRow(AppLocalizations.of(context)!.path, song.uri!, primaryColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSongScreen(song: song),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.editSong, style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close,
                style: const TextStyle(color: AppTheme.textHint)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Song song) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(AppLocalizations.of(context)!.deleteSong,
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text(AppLocalizations.of(context)!.deleteSongConfirmFormat(song.titleDisplay),
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (song.uri != null) {
                  const platform = MethodChannel('kr.ssing.catsong/media');
                  final result = await platform.invokeMethod('deleteSong', {'uri': song.uri});
                  if (result == true) {
                    context.read<MusicProvider>().loadSongs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.deleted),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                        content: Text(AppLocalizations.of(context)!.deleteFailed),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('삭제 실패: $e'),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: primaryColor, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}