import '../utils/no_album_helper.dart';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/song_list_tile.dart';
import '../providers/theme_provider.dart';

class ArtistScreen extends StatelessWidget {
  final String searchQuery;
  const ArtistScreen({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final artists = searchQuery.isEmpty
        ? musicProvider.artists
        : musicProvider.searchArtists(searchQuery);

    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;

    if (artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 72, color: baseColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noArtists,
                style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 16)),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(AppLocalizations.of(context)!.artists,
                    style: TextStyle(
                        color: baseColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Text('(${artists.length})',
                    style: TextStyle(
                        color: baseColor.withOpacity(0.38), fontSize: 13)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return _buildArtistTile(context, artists[index]);
              },
              childCount: artists.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildArtistTile(BuildContext context, artist) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return InkWell(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ArtistDetailScreen(artist: artist),
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
            // 가수 얼굴 칸: 앨범 사진 있는 노래 → 없으면 그라데이션 + 첫 글자
            _ArtistAvatar(artist: artist, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artist.displayName,
                      style: TextStyle(
                          color: baseColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('${artist.songCount} ${AppLocalizations.of(context)!.songCount} • ${artist.albumCount} ${AppLocalizations.of(context)!.albums}',
                      style: TextStyle(
                          color: baseColor.withOpacity(0.38), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: baseColor.withOpacity(0.24), size: 20),
          ],
        ),
      ),
    );
  }
}

class ArtistDetailScreen extends StatelessWidget {
  final artist;
  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: artist.songs.first.albumArt != null
                  ? Image.memory(
                Uint8List.fromList(artist.songs.first.albumArt!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
                  : Image.asset(
                noAlbumImagePath(artist.name),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox.expand(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppTheme.background,
                leading: IconButton(
                  onPressed: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (artist.songs.first.albumArt != null)
                        Image.memory(
                          Uint8List.fromList(artist.songs.first.albumArt!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      else
                        Image.asset(noAlbumImagePath(artist.name), fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.8),
                              AppTheme.background,
                            ],
                            stops: const [0.0, 0.6, 1.0],
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
                            Text(artist.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4)),
                            const SizedBox(height: 4),
                            Text('${artist.songCount} ${AppLocalizations.of(context)!.songCount} • ${artist.albumCount} ${AppLocalizations.of(context)!.albums}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12.5)),
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
                          context.read<PlayerProvider>().playFromList(artist.songs, 0, isPlayAllAction: true);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.white60, size: 26),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        onPressed: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          final songs = List<Song>.from(artist.songs)..shuffle();
                          context.read<PlayerProvider>().playFromList(songs, 0, isPlayAllAction: true);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.shuffle, color: Colors.white60, size: 20),
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
                        song: artist.songs[index],
                        index: index,
                        songList: artist.songs,
                        forceWhiteText: true,
                      );
                    },
                    childCount: artist.songs.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 가수 동그라미 — 그 가수 노래 중 앨범 사진 있는 것, 없으면 그라데이션 + 첫 글자
class _ArtistAvatar extends StatelessWidget {
  final dynamic artist;
  final double size;
  const _ArtistAvatar({required this.artist, this.size = 56});

  // 재생목록 표지와 같은 색 세트 (가수 이름으로 골라서 늘 같은 색)
  static const _grads = <List<Color>>[
    [Color(0xFF3A3550), Color(0xFF6B4A3A)],
    [Color(0xFF1F4E6B), Color(0xFF6FB3C9)],
    [Color(0xFF6B4A3A), Color(0xFFE0915F)],
    [Color(0xFF4A3F7A), Color(0xFFC79ACF)],
    [Color(0xFF233D32), Color(0xFF7FA77A)],
  ];

  @override
  Widget build(BuildContext context) {
    List<int>? art;
    for (final s in (artist.songs as List)) {
      final a = s.albumArt as List<int>?;
      if (a != null && a.isNotEmpty) {
        art = a;
        break;
      }
    }
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round(); // 동그라미 크기만큼만 풀기

    Widget child;
    if (art != null) {
      child = Image.memory(
        Uint8List.fromList(art),
        fit: BoxFit.cover,
        cacheWidth: px,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE3DCCD)),
      );
    } else {
      final name = (artist.displayName as String).trim();
      var h = 0;
      for (final c in name.codeUnits) {
        h = (h * 31 + c) & 0x7fffffff;
      }
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
            name.isEmpty ? '♪' : name.characters.first.toUpperCase(),
            style: TextStyle(
              color: const Color(0xFFF4EFE5),
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: child));
  }
}