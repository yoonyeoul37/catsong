import 'dart:typed_data';
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
import 'package:cached_network_image/cached_network_image.dart';

// 재생목록 위쪽 그림 (수파베이스 app-images/covers 폴더)
const _kCoverBase =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images/covers';
const _kCoverCount = 5; // 그림 수 (더 올리면 여기만 바꾸기)

// 같은 재생목록이면 항상 같은 그림 (5장 중 하나)
String _coverUrl(String key) {
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final n = h % _kCoverCount + 1;
  return '$_kCoverBase/cover_${n.toString().padLeft(2, '0')}.webp';
}

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
            // 표지: 앨범 사진 4장 → 1장 → 그라데이션 + 첫 글자
            _PlaylistCover(playlist: playlist, size: 56),
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
            // ⋮ 이름 바꾸기 · 삭제 (앱 공통 둥근 카드, 다크 모드 자동)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: baseColor.withOpacity(0.38), size: 20),
              position: PopupMenuPosition.under,
              itemBuilder: (context) => [
                _buildPopupItem(context, Icons.edit_outlined, AppLocalizations.of(context)!.rename, 'rename'),
                _buildPopupItem(context, Icons.delete_outline_rounded, AppLocalizations.of(context)!.delete, 'delete',
                    danger: true),
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

  /// 메뉴 한 줄: 아이콘 베이지 칸 + 글자 (삭제는 빨강)
  PopupMenuItem<String> _buildPopupItem(BuildContext context, IconData icon, String label, String value,
      {bool danger = false}) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    const red = Color(0xFFD84A3A);
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final color = danger ? red : ink;
    final boxBg = danger
        ? red.withOpacity(isDark ? 0.18 : 0.1)
        : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5));
    final iconColor = danger ? red : (isDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348));
    return PopupMenuItem(
      value: value,
      height: 46,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: boxBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
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

  // 그림 불러오는 동안·못 불러오면 원래 색 배경
  Widget _fallbackBg(Color primaryColor, Color bgColor) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor.withOpacity(0.6), primaryColor.withOpacity(0.2), bgColor],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);
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
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: bgColor.withOpacity(0.55), shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_ios_new, color: baseColor, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _coverUrl(playlist.id),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.3, 0),
                    fadeInDuration: const Duration(milliseconds: 250),
                    placeholder: (_, __) => _fallbackBg(primaryColor, bgColor),
                    errorWidget: (_, __, ___) => _fallbackBg(primaryColor, bgColor),
                  ),
                  // 아래로 갈수록 배경색으로 → 글자가 잘 보이고 목록과 자연스럽게 이어지게
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bgColor.withOpacity(0),
                          bgColor.withOpacity(0),
                          bgColor.withOpacity(0.7),
                          bgColor,
                        ],
                        stops: const [0.0, 0.55, 0.88, 1.0],
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
                        Text(playlist.name,
                            style: TextStyle(
                                color: baseColor,
                                fontSize: 20,
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

/// 재생목록 표지 — 회색 칸 대신
/// 앨범 사진 있는 곡 4곡 이상: 2×2 / 1~3곡: 첫 사진 / 없으면: 그라데이션 + 첫 글자
class _PlaylistCover extends StatelessWidget {
  final Playlist playlist;
  final double size;
  const _PlaylistCover({required this.playlist, this.size = 56});

  // 목록마다 늘 같은 색 (이름이 아니라 id로 골라서 이름 바꿔도 그대로)
  static const _grads = <List<Color>>[
    [Color(0xFF3A3550), Color(0xFF6B4A3A)],
    [Color(0xFF1F4E6B), Color(0xFF6FB3C9)],
    [Color(0xFF6B4A3A), Color(0xFFE0915F)],
    [Color(0xFF4A3F7A), Color(0xFFC79ACF)],
    [Color(0xFF233D32), Color(0xFF7FA77A)],
  ];

  @override
  Widget build(BuildContext context) {
    final arts = <List<int>>[
      for (final s in playlist.songs)
        if (s.albumArt != null && s.albumArt!.isNotEmpty) s.albumArt!,
    ].take(4).toList();
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round(); // 화면 크기만큼만 풀기

    Widget img(List<int> b, int w) => Image.memory(
      Uint8List.fromList(b),
      fit: BoxFit.cover,
      cacheWidth: w,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE3DCCD)),
    );

    Widget child;
    if (arts.length >= 4) {
      child = GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [for (final a in arts) img(a, px ~/ 2)],
      );
    } else if (arts.isNotEmpty) {
      child = img(arts.first, px);
    } else {
      var h = 0;
      for (final c in playlist.id.codeUnits) {
        h = (h * 31 + c) & 0x7fffffff;
      }
      final name = playlist.name.trim();
      child = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _grads[h % _grads.length],
          ),
        ),
        child: Center(
          child: Text(
            name.isEmpty ? '♪' : name.characters.first,
            style: TextStyle(
              color: const Color(0xFFF4EFE5),
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(borderRadius: BorderRadius.circular(size * 0.2), child: child),
    );
  }
}