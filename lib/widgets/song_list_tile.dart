import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../screens/player_screen.dart';
import '../screens/edit_song_screen.dart';
import '../screens/ringtone_screen.dart';
import '../screens/equalizer_screen.dart';
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
                _buildPopupItem(Icons.play_arrow, '지금 재생', 'play', primaryColor),
                _buildPopupItem(Icons.skip_next, '다음에 재생', 'play_next', primaryColor),
                _buildPopupItem(Icons.playlist_add, '재생목록에 추가', 'playlist', primaryColor),
                _buildPopupItem(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  isFav ? '즐겨찾기 제거' : '즐겨찾기 추가',
                  'favorite',
                  isFav ? Colors.redAccent : primaryColor,
                ),
                _buildPopupItem(Icons.music_note, '벨소리로 설정', 'ringtone', primaryColor),
                _buildPopupItem(Icons.info_outline, '곡 정보', 'info', primaryColor),
                _buildPopupItem(Icons.equalizer, '이퀄라이저', 'equalizer', primaryColor),
                _buildPopupItem(Icons.share, '공유', 'share', primaryColor),
                _buildPopupItem(Icons.delete_outline, '삭제', 'delete', Colors.redAccent),
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
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.music_note,
                color: Colors.white38, size: 24),
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
                ? _EqualizerAnimation(color: primaryColor)
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
            content: const Text('다음에 재생됩니다'),
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
        title: const Text('재생목록에 추가',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: playlistProvider.playlists.isEmpty
            ? const Text('재생목록이 없습니다.\n재생목록 탭에서 먼저 만들어주세요.',
            style: TextStyle(color: AppTheme.textSecondary))
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
                      content: Text('${playlist.name}에 추가됐습니다'),
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
            child: Text('닫기', style: TextStyle(color: primaryColor)),
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
        title: const Text('곡 정보',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('제목', song.titleDisplay, primaryColor),
            _infoRow('아티스트', song.artistDisplay, primaryColor),
            _infoRow('앨범', song.albumDisplay, primaryColor),
            _infoRow('재생 시간', song.durationFormatted, primaryColor),
            if (song.uri != null) _infoRow('경로', song.uri!, primaryColor),
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
            child: Text('편집', style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기',
                style: TextStyle(color: AppTheme.textHint)),
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
        title: const Text('곡 삭제',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('${song.titleDisplay}을(를) 삭제할까요?\n기기에서 영구 삭제됩니다.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (song.uri != null) {
                  const platform = MethodChannel('com.example.mp3_player/media');
                  final result = await platform.invokeMethod('deleteSong', {'uri': song.uri});
                  if (result == true) {
                    context.read<MusicProvider>().loadSongs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('삭제됐습니다'),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('삭제 실패'),
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
            child: const Text('삭제',
                style: TextStyle(color: Colors.redAccent)),
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

class _EqualizerAnimation extends StatefulWidget {
  final Color color;
  const _EqualizerAnimation({required this.color});

  @override
  State<_EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<_EqualizerAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 150),
      )..repeat(reverse: true);
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              width: 3,
              height: 6 + (12 * _animations[i].value),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}