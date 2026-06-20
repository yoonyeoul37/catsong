import 'dart:typed_data';
import 'package:flutter/material.dart';
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
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
                color: const Color(0xFF282828),
                child: const Center(
                  child: Icon(Icons.album, color: Colors.white24, size: 56),
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<PlayerProvider>().playFromList(album.songs, 0);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(AppLocalizations.of(context)!.playAll,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final songs = List<Song>.from(album.songs)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.shuffle, size: 20),
                      label: Text(AppLocalizations.of(context)!.shuffle,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
    );
  }
}