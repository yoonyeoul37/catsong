import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';

class ArtistScreen extends StatelessWidget {
  final String searchQuery;
  const ArtistScreen({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final artists = searchQuery.isEmpty
        ? musicProvider.artists
        : musicProvider.searchArtists(searchQuery);

    if (artists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 72, color: AppTheme.textHint),
            SizedBox(height: 16),
            Text('아티스트가 없습니다',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
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
                const Text('아티스트',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const SizedBox(width: 8),
                Text('${artists.length}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 16)),
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
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailScreen(artist: artist),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 아티스트 이미지
            ClipOval(
              child: SizedBox(
                width: 56,
                height: 56,
                child: artist.songs.first.albumArt != null
                    ? Image.memory(
                  Uint8List.fromList(artist.songs.first.albumArt!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
                    : Container(
                  color: const Color(0xFF282828),
                  child: const Icon(Icons.person,
                      color: Colors.white38, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artist.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('${artist.songCount}곡 • ${artist.albumCount}앨범',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.white24, size: 20),
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
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
                  // 배경 이미지
                  if (artist.songs.first.albumArt != null)
                    Image.memory(
                      Uint8List.fromList(artist.songs.first.albumArt!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    Container(color: const Color(0xFF282828)),
                  // 그라데이션
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
                  // 아티스트 정보
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(artist.displayName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text('${artist.songCount}곡 • ${artist.albumCount}앨범',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 전체재생/셔플 버튼
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<PlayerProvider>()
                            .playFromList(artist.songs, 0);
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
                      label: const Text('전체 재생',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final songs = List<Song>.from(artist.songs)..shuffle();
                        context.read<PlayerProvider>()
                            .playFromList(songs, 0);
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
                      label: const Text('셔플',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                    song: artist.songs[index],
                    index: index,
                    songList: artist.songs,
                  );
                },
                childCount: artist.songs.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}