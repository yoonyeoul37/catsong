import '../providers/video_provider.dart';
import 'video_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/mini_player.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'playlist_screen.dart';
import 'favorites_screen.dart';
import 'recent_screen.dart';
import 'folder_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  bool _showFavorites = false;
  bool _showRecent = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final musicProvider = context.read<MusicProvider>();
      if (musicProvider.songs.isEmpty && !musicProvider.isLoading) {
        await musicProvider.initialize();
      }
      context.read<VideoProvider>().loadVideos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(primaryColor),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      titleSpacing: 20,
      title: _isSearching
          ? _buildSearchField()
          : Text('캣송',
          style: TextStyle(
              color: primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5)),
      actions: [
        if (!_isSearching) ...[
          IconButton(
            onPressed: () => setState(() => _isSearching = true),
            icon: const Icon(Icons.search, color: AppTheme.textPrimary, size: 26),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary, size: 24),
          ),
          const SizedBox(width: 4),
        ] else
          TextButton(
            onPressed: () {
              setState(() => _isSearching = false);
              _searchController.clear();
              context.read<MusicProvider>().clearSearch();
            },
            child: Text('취소', style: TextStyle(color: primaryColor)),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: '곡, 아티스트, 앨범 검색...',
        hintStyle: const TextStyle(color: AppTheme.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        prefixIcon: const Icon(Icons.search, color: AppTheme.textHint, size: 18),
        isDense: true,
      ),
      onChanged: (value) => context.read<MusicProvider>().search(value),
    );
  }

  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        if (_showFavorites) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showFavorites = false);
              return false;
            },
            child: const FavoritesScreen(),
          );
        }
        if (_showRecent) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showRecent = false);
              return false;
            },
            child: const RecentScreen(),
          );
        }
        return _buildSongsTab();
      case 1: return const AlbumScreen();
      case 2: return const ArtistScreen();
      case 3: return const PlaylistScreen();
      case 4: return const FolderScreen();
      case 5: return const VideoScreen();
      default: return _buildSongsTab();
    }
  }

  Widget _buildSongsTab() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        if (musicProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                const Text('음악을 스캔하는 중...',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        if (!musicProvider.hasPermission) return _buildPermissionDeniedView(musicProvider);
        if (musicProvider.errorMessage.isNotEmpty) return _buildErrorView(musicProvider);
        if (musicProvider.songs.isEmpty) return _buildEmptySongsView();

        return Column(
          children: [
            // 필터 + 버튼 바
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _buildFilterChip('전체', !_showFavorites && !_showRecent,
                      Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  _buildFilterChip('즐겨찾기', _showFavorites,
                      Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  _buildFilterChip('최근', _showRecent,
                      Theme.of(context).colorScheme.primary),
                  const Spacer(),
                  _buildIconButton(
                    Icons.play_circle_filled,
                    Theme.of(context).colorScheme.primary,
                        () {
                      if (musicProvider.songs.isNotEmpty) {
                        context.read<PlayerProvider>()
                            .playFromList(musicProvider.songs, 0);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    Icons.shuffle,
                    AppTheme.textSecondary,
                        () {
                      if (musicProvider.songs.isNotEmpty) {
                        final songs = List.from(musicProvider.songs)..shuffle();
                        context.read<PlayerProvider>()
                            .playFromList(songs as List<Song>, 0);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text('${musicProvider.songCount}곡',
                      style: const TextStyle(
                          color: AppTheme.textHint, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: musicProvider.songs.length,
                itemBuilder: (context, index) {
                  final songs = musicProvider.songs;
                  return SongListTile(
                    song: songs[index],
                    index: index,
                    songList: songs,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Color primaryColor) {
    return GestureDetector(
      onTap: () => setState(() {
        _showFavorites = label == '즐겨찾기';
        _showRecent = label == '최근';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildPermissionDeniedView(MusicProvider musicProvider) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 72, color: primaryColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            const Text('저장소 접근 권한 필요',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('MP3 파일을 스캔하려면\n저장소 접근 권한이 필요합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => musicProvider.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('권한 허용',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(MusicProvider musicProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(musicProvider.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => musicProvider.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySongsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 72, color: AppTheme.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('MP3 파일이 없습니다',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('기기에 음악 파일을 추가해 주세요',
              style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Color primaryColor) {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) => setState(() => _currentTabIndex = index),
      backgroundColor: const Color(0xFF0A0A0A),
      selectedItemColor: primaryColor,
      unselectedItemColor: AppTheme.textHint,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: '곡'),
        BottomNavigationBarItem(icon: Icon(Icons.album), label: '앨범'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '아티스트'),
        BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: '재생목록'),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: '폴더'),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: '동영상'),
      ],
    );
  }
}