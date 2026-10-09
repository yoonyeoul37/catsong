import 'dart:typed_data';
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
            // 폴더 표지: 앨범 사진 + 작은 아이콘 → 없으면 크림색 칸 + 아이콘
            _FolderCover(folder: folder, size: 56),
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
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);
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

/// 폴더 표지 — 재생목록·아티스트와 같은 규칙
/// 앨범 사진 4장 이상: 2×2 / 1~3장: 첫 사진 / 없으면: 크림색 칸 + 아이콘
/// 사진 위엔 오른쪽 아래 작은 아이콘 (폴더 이름 보고 자동: 메신저·다운로드·음악·녹음…)
class _FolderCover extends StatelessWidget {
  final MusicFolder folder;
  final double size;
  const _FolderCover({required this.folder, this.size = 56});

  /// 폴더 이름으로 어울리는 아이콘 고르기 (나라마다 메신저가 달라도 다 말풍선)
  static IconData iconFor(String name) {
    final n = name.toLowerCase();
    bool has(List<String> ks) => ks.any((k) => n.contains(k));
    if (has(['kakao', '카카오', 'whatsapp', 'telegram', 'messenger', 'wechat', 'viber', 'signal']) ||
        n == 'line') {
      return Icons.chat_bubble_outline_rounded;
    }
    if (has(['download', '다운로드'])) return Icons.download_rounded;
    if (has(['record', 'call', '녹음', '통화', 'voice'])) return Icons.mic_none_rounded;
    if (has(['bluetooth', '블루투스'])) return Icons.bluetooth_rounded;
    if (has(['music', '음악', 'song', 'audio', 'mp3'])) return Icons.music_note_rounded;
    return Icons.folder_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final arts = <List<int>>[
      for (final s in folder.songs)
        if (s.albumArt != null && s.albumArt!.isNotEmpty) s.albumArt!,
    ].take(4).toList();
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round(); // 칸 크기만큼만 풀기
    final icon = iconFor(folder.name);

    Widget img(List<int> b, int w) => Image.memory(
      Uint8List.fromList(b),
      fit: BoxFit.cover,
      cacheWidth: w,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE3DCCD)),
    );

    Widget child;
    if (arts.isEmpty) {
      // 사진 없음: 크림색 칸 + 아이콘
      child = ColoredBox(
        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF4EFE5),
        child: Center(
          child: Icon(icon, size: size * 0.42, color: isDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348)),
        ),
      );
    } else {
      child = Stack(
        fit: StackFit.expand,
        children: [
          if (arts.length >= 4)
            GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [for (final a in arts) img(a, px ~/ 2)],
            )
          else
            img(arts.first, px),
          // 오른쪽 아래 작은 아이콘 (폴더라는 표시)
          Positioned(
            right: 3,
            bottom: 3,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: const Color(0xFF17140F).withOpacity(0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: size * 0.2, color: const Color(0xFFF4EFE5)),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(borderRadius: BorderRadius.circular(size * 0.2), child: child),
    );
  }
}