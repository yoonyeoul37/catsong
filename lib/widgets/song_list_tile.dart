import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'album_eq_overlay.dart';
import 'menu_parts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/edit_song_screen.dart';
import '../screens/ringtone_screen.dart';
import '../screens/equalizer_screen.dart';
import 'equalizer_animation.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../providers/theme_provider.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final int index;
  final List<Song> songList;
  final bool forceWhiteText;

  const SongListTile({
    super.key,
    required this.song,
    required this.index,
    required this.songList,
    this.forceWhiteText = false,
  });

  /// 다른 화면(재생화면 메뉴)에서도 같은 곡 정보 창을 띄울 수 있게
  static void showInfo(BuildContext context, Song song) =>
      SongListTile(song: song, index: 0, songList: [song])._showSongInfo(context);

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final isCurrentSong = playerProvider.currentSong?.id == song.id;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isFav = musicProvider.isFavorite(song.id);
    final isDarkMode = forceWhiteText ? true : context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return InkWell(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrentSong ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            _buildAlbumArt(isCurrentSong, playerProvider, primaryColor, baseColor,
                musicProvider.isTrimmedWithOriginal(song)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.titleDisplay,
                    style: TextStyle(
                      color: isCurrentSong ? primaryColor : baseColor,
                      fontSize: 15,
                      fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artistDisplay,
                    style: TextStyle(
                      color: isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.38),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Builder(builder: (context) {
              final playCount = context.watch<MusicProvider>().playCountOf(song);
              final subColor = isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.3);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    song.durationFormatted,
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                  if (playCount > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 11, color: subColor),
                        const SizedBox(width: 1),
                        Text(
                          '$playCount',
                          style: TextStyle(color: subColor, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
            GestureDetector(
              onTap: () => _showOptionsSheet(context, isFav),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.more_vert,
                    color: isCurrentSong ? baseColor.withOpacity(0.7) : baseColor.withOpacity(0.3),
                    size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt(bool isCurrentSong, PlayerProvider playerProvider, Color primaryColor, Color baseColor,
      bool showTrimBadge) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
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
              color: baseColor.withOpacity(0.15),
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
              color: primaryColor.withOpacity(0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: AlbumEqOverlay(
                isPlaying: playerProvider.isPlaying,
                width: 26,
                height: 22,
              ),
            ),
          ),
        // 자른 곡 표시: 앨범 사진 오른쪽 아래 파란 가위
        // 원본이 목록에 같이 있을 때만 (원본 지우면 자동으로 사라짐)
        if (showTrimBadge)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF2589E8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.content_cut, size: 11, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _showOptionsSheet(BuildContext context, bool isFav) async {
    // 재생화면 스타일 썸네일용 (지금 고른 스타일 · 파란포토 사진)
    final prefs = await SharedPreferences.getInstance();
    int style = prefs.getInt('albumArtStyle') ?? 6; // 처음엔 파란포토
    final bgPath = prefs.getString('nightBgPath') ?? 'assets/spring_photo1.png';
    final bgIsFile = prefs.getBool('nightBgIsFile') ?? false;
    bool showNew = !(prefs.getBool('hasSeenParanPhoto') ?? false);
    if (!context.mounted) return;
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final sheetColor = isDarkMode ? const Color(0xFF2A251D) : const Color(0xFFF4EFE5);
    final baseColor = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF1A1A1A);
    final descColor = isDarkMode ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    const accent = Color(0xFF2589E8); // 파란소리 포인트 블루 (재생화면 메뉴와 통일)

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        bool addedNext = false; // "다음에 재생" 눌렀는지 (메뉴 안에 표시)
        // 메뉴를 안 닫고 여러 개 할 수 있게: 즐겨찾기 등이 바로 다시 그려짐
        return StatefulBuilder(builder: (ctx, setSheet) {
        // 메뉴 안에서는 메뉴 자신의 context를 씀 (곡 정보 편집으로 목록이 다시 그려져도 안전)
        final context = ctx;
        final isFav = ctx.watch<MusicProvider>().isFavorite(song.id);
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, size: 24, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 곡 정보 + 빠른 버튼 (즐겨찾기 · 재생목록 · 공유 · 편집)
                MenuSongCard(
                  song: song,
                  isDark: isDarkMode,
                  actions: [
                    MenuQuickAction(isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, '즐겨찾기', () {
                      _handleMenuAction(context, 'favorite');
                    }),
                    MenuQuickAction(Icons.playlist_add, '재생목록', () {
                      _handleMenuAction(context, 'playlist');
                    }),
                    // 공유·편집: 메뉴는 그대로 두고 위에 띄움 → 돌아오면 메뉴가 그대로
                    MenuQuickAction(Icons.share, '공유', () {
                      _handleMenuAction(context, 'share');
                    }),
                    MenuQuickAction(Icons.edit, '편집', () {
                      _handleMenuAction(context, 'edit');
                    }),
                  ],
                ),
                MenuCard(isDark: isDarkMode, children: [
                  _sheetItem(context, Icons.play_arrow, AppLocalizations.of(context)!.play, 'play', accent, baseColor, isDarkMode),
                  _sheetItem(context, Icons.skip_next, AppLocalizations.of(context)!.playNext, 'play_next', accent, baseColor, isDarkMode,
                      keepOpen: true,
                      afterTap: () => setSheet(() => addedNext = true),
                      trailing: addedNext
                          ? const Text('추가됨 ✓',
                              style: TextStyle(color: accent, fontSize: 12.5, fontWeight: FontWeight.w600))
                          : null),
                ]),
                MenuCard(isDark: isDarkMode, children: [
                // 재생화면 메뉴와 똑같은 줄: 셔플 · 반복 · 수면 · 재생화면 스타일 · 배속
                ...playerSettingRows(
                  ctx,
                  song: song,
                  style: style,
                  bgPath: bgPath,
                  bgIsFile: bgIsFile,
                  showNew: showNew,
                  textColor: baseColor,
                  onStyleChanged: () async {
                    final p2 = await SharedPreferences.getInstance();
                    style = p2.getInt('albumArtStyle') ?? 6;
                    showNew = false;
                    if (ctx.mounted) setSheet(() {});
                  },
                ),
                ]),
                MenuCard(isDark: isDarkMode, children: [
                  // 들어갔다 나오면 메뉴가 그대로 있게 (keepOpen)
                  _sheetItem(context, Icons.music_note, AppLocalizations.of(context)!.setRingtone, 'ringtone', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                  _sheetItem(context, Icons.content_cut, '자르기', 'trim', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                  _sheetItem(context, Icons.info_outline, AppLocalizations.of(context)!.songInfo, 'info', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                  _sheetItem(context, Icons.equalizer, AppLocalizations.of(context)!.equalizer, 'equalizer', accent, baseColor, isDarkMode, arrow: true, keepOpen: true),
                ]),
                MenuCard(isDark: isDarkMode, children: [
                  _sheetItem(context, Icons.delete_outline, AppLocalizations.of(context)!.delete, 'delete', Colors.redAccent, Colors.redAccent, isDarkMode),
                ]),
                const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
        });
      },
    );
  }

  Widget _sheetItem(BuildContext context, IconData icon, String label, String value, Color iconColor, Color textColor, bool isDarkMode,
      {bool keepOpen = false, bool arrow = false, Widget? trailing, VoidCallback? afterTap}) {
    final isDelete = iconColor == Colors.redAccent;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // keepOpen이면 메뉴를 닫지 않고 바로 실행 (여러 개 연달아 가능)
        if (!keepOpen) Navigator.pop(context);
        _handleMenuAction(context, value);
        afterTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        child: Row(
          children: [
            // 카드 안 줄: 아이콘 배경 없이 아이콘만 (삭제는 빨간색)
            SizedBox(width: 24, child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            if (trailing != null) trailing,
            if (arrow) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 20, color: textColor.withOpacity(0.3)),
            ],
          ],
        ),
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
            content: Text(
              isFav ? '즐겨찾기에 추가됐습니다' : '즐겨찾기에서 제거됐습니다',
              style: const TextStyle(color: Colors.white),
            ),
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
      case 'trim':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RingtoneScreen(initialSong: song, trimMode: true),
          ),
        );
        break;
      case 'info':
        _showSongInfo(context);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditSongScreen(song: song)),
        );
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
    final primaryColor = AppTheme.fixedAccent;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.addToPlaylist,
            style: const TextStyle(color: Colors.black)),
        content: playlistProvider.playlists.isEmpty
            ? Text(AppLocalizations.of(context)!.noPlaylists,
            style: const TextStyle(color: Colors.black54))
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
                    style: const TextStyle(color: Colors.black)),
                subtitle: Text('${playlist.songCount}곡',
                    style: const TextStyle(color: Colors.black54)),
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
    final primaryColor = AppTheme.fixedAccent;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.songInfo,
            style: const TextStyle(color: Colors.black)),
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
                style: const TextStyle(color: Colors.black38)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Song song) {
    final primaryColor = AppTheme.fixedAccent;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.deleteSong,
            style: const TextStyle(color: Colors.black)),
        content: Text(AppLocalizations.of(context)!.deleteSongConfirmFormat(song.titleDisplay),
            style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.black38)),
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
                  color: Colors.black87, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}