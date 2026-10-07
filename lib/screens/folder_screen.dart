import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/song_list_tile.dart';
import '../providers/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// 폴더 위쪽 그림 (수파베이스 app-images/covers 폴더)
const _kCoverBase =
    'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/app-images/covers';
const _kCoverCount = 5; // 그림 수 (더 올리면 여기만 바꾸기)

// 같은 폴더면 항상 같은 그림 (5장 중 하나)
String _coverUrl(String key) {
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final n = h % _kCoverCount + 1;
  return '$_kCoverBase/cover_${n.toString().padLeft(2, '0')}.webp';
}

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final folders = musicProvider.folders;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.folders,
                    style: TextStyle(
                        color: baseColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Text('(${folders.length})',
                    style: TextStyle(
                        color: baseColor.withOpacity(0.38), fontSize: 13)),
              ],
            ),
          ),
        ),
        if (folders.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 72, color: baseColor.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.folders,
                      style: TextStyle(
                          color: baseColor.withOpacity(0.6), fontSize: 16)),
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
                  return _buildFolderTile(context, folders[index], primaryColor);
                },
                childCount: folders.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildFolderTile(BuildContext context, MusicFolder folder, Color primaryColor) {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return InkWell(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FolderDetailScreen(folder: folder),
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
              child: Icon(Icons.folder, color: baseColor.withOpacity(0.7), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folder.name,
                      style: TextStyle(
                          color: baseColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('${folder.songCount} ${AppLocalizations.of(context)!.songCount}',
                      style: TextStyle(
                          color: baseColor.withOpacity(0.38), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: baseColor.withOpacity(0.24), size: 20),
          ],
        ),
      ),
    );
  }
}

class FolderDetailScreen extends StatelessWidget {
  final MusicFolder folder;
  const FolderDetailScreen({super.key, required this.folder});

  // 그림 불러오는 동안·못 불러오면 원래 색 배경
  Widget _fallbackBg(Color primaryColor, Color bgColor) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor.withOpacity(0.5), primaryColor.withOpacity(0.2), bgColor],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false, // 아래 시스템 아이콘과 안 겹치게
        child: CustomScrollView(
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
                    imageUrl: _coverUrl(folder.name),
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
                        Text(folder.name,
                            style: TextStyle(
                                color: baseColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('${folder.songCount} ${AppLocalizations.of(context)!.songCount}',
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
                    onPressed: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      context.read<PlayerProvider>().playFromList(folder.songs, 0);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.play_arrow, color: baseColor.withOpacity(0.6), size: 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      final songs = List<Song>.from(folder.songs)..shuffle();
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return SongListTile(
                    song: folder.songs[index],
                    index: index,
                    songList: folder.songs,
                  );
                },
                childCount: folder.songs.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
      ),
    );
  }
}