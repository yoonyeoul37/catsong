import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';
import '../l10n/app_localizations.dart';

class AlbumScreen extends StatelessWidget {
  final String searchQuery;
  const AlbumScreen({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final albums = searchQuery.isEmpty
        ? musicProvider.albums
        : musicProvider.searchAlbums(searchQuery);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(AppLocalizations.of(context)!.albums,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    const SizedBox(width: 8),
                    Text('${albums.length}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (albums.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 72, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noAlbums,
                      style: const TextStyle(color: Colors.white38, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildAlbumCard(context, albums[index], primaryColor);
                },
                childCount: albums.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildAlbumCard(BuildContext context, album, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => AlbumDetailScreen(album: album),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: album.songs.first.albumArt != null
                  ? Image.memory(
                Uint8List.fromList(album.songs.first.albumArt!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
                  : Container(
                color: const Color(0xFF2A2A2A),
                child: const Center(
                  child: Icon(Icons.album, color: AppTheme.fixedAccent, size: 56),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(album.displayName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${album.displayArtist} • ${album.songCount} ${AppLocalizations.of(context)!.songCount}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class AlbumDetailScreen extends StatelessWidget {
  final album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 앨범아트 블러 배경
          SizedBox.expand(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: album.songs.first.albumArt != null
                  ? Image.memory(
                      Uint8List.fromList(album.songs.first.albumArt!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Image.asset(
                      'assets/no_album2.jpg',
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
            expandedHeight: 280,
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
                  if (album.songs.first.albumArt != null)
                    Image.memory(
                      Uint8List.fromList(album.songs.first.albumArt!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    Container(color: const Color(0xFF282828)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
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
                        Text(album.displayName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(album.displayArtist,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('${album.songCount} ${AppLocalizations.of(context)!.songCount}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 13)),
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
                      context.read<PlayerProvider>().playFromList(album.songs, 0);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white60, size: 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      final songs = List<Song>.from(album.songs)..shuffle();
                      context.read<PlayerProvider>().playFromList(songs, 0);
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
                    song: album.songs[index],
                    index: index,
                    songList: album.songs,
                  );
                },
                childCount: album.songs.length,
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