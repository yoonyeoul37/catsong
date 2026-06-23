import '../providers/video_provider.dart';
import 'video_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/playlist_provider.dart';
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
import 'radio_home_screen.dart';
import '../widgets/radio_mini_player.dart';
import '../providers/radio_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScrollingUp = true;
  double _lastScrollOffset = 0;
  int _currentTabIndex = 0;
  bool _showFavorites = false;
  bool _showRecent = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showBanner = false;
  bool _isSelectionMode = false;
  Set<int> _selectedSongIds = {};
  bool _showThemeHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final musicProvider = context.read<MusicProvider>();
      if (musicProvider.songs.isEmpty && !musicProvider.isLoading) {
        await musicProvider.initialize();
        context.read<PlaylistProvider>().restorePlaylistSongs(musicProvider.allSongs);
      }
      context.read<VideoProvider>().loadVideos();
      await _checkBanner();
      await _checkThemeHint();
    });
  }

  Future<void> _checkThemeHint() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('theme_hint_shown_count') ?? 0;
    if (count < 20) {
      await prefs.setInt('theme_hint_shown_count', count + 1);
      if (mounted) setState(() => _showThemeHint = true);
      Future.delayed(const Duration(seconds: 20), () {
        if (mounted) setState(() => _showThemeHint = false);
      });
    }
  }

  Future<void> _checkBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final isUnlocked = prefs.getBool('promo_unlocked') ?? false;
    if (isUnlocked) return;
    final now = DateTime.now();
    final start = DateTime(2026, 6, 7);
    final end = DateTime(2026, 7, 7);
    if (now.isBefore(start) || now.isAfter(end)) return;
    final lastShown = prefs.getString('banner_last_shown');
    final today = '${now.year}-${now.month}-${now.day}';
    if (lastShown == today) return;
    await prefs.setString('banner_last_shown', today);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMultiDeleteDialog(BuildContext context, MusicProvider musicProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.deleteSelected, style: const TextStyle(color: Colors.black)),
        content: Text(AppLocalizations.of(context)!.deleteSelectedConfirm(_selectedSongIds.length),
            style: const TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.black38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              const platform = MethodChannel('kr.ssing.catsong/media');
              int successCount = 0;
              final selectedSongs = musicProvider.songs
                  .where((s) => _selectedSongIds.contains(s.id))
                  .toList();
              for (final song in selectedSongs) {
                try {
                  if (song.uri != null) {
                    final result = await platform.invokeMethod('deleteSong', {'uri': song.uri});
                    if (result == true) successCount++;
                  }
                } catch (e) {
                  debugPrint('삭제 실패: $e');
                }
              }
              setState(() {
                _isSelectionMode = false;
                _selectedSongIds.clear();
              });
              musicProvider.loadSongs();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.deletedCount(successCount)),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
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
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
            ),
            child: Consumer2<RadioProvider, PlayerProvider>(
              builder: (context, radioProvider, playerProvider, _) {
                if (playerProvider.currentSong != null) {
                  return const MiniPlayer();
                }
                if (radioProvider.currentStation != null) {
                  return const RadioMiniPlayer();
                }
                return const SizedBox.shrink();
              },
            ),
          ),
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
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform(
                  transform: Matrix4.skewX(-0.15),
                  child: Text(AppLocalizations.of(context)!.appName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                ),
                if (Localizations.localeOf(context).languageCode == 'ko')
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text('MusicWave',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5)),
                  ),
              ],
            ),
      actions: [
        if (!_isSearching) ...[
          IconButton(
            onPressed: () => setState(() => _isSearching = true),
            icon: const Icon(Icons.search, color: AppTheme.textPrimary, size: 23),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.25),
                  ),
                  child: const RadioHomeScreen(),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 250),
              ),
            ),
            icon: const Icon(Icons.radio_outlined, color: AppTheme.textPrimary, size: 23),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 250),
              ),
            ),
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary, size: 23),
          ),
          const SizedBox(width: 4),
        ] else
          TextButton(
            onPressed: () {
              setState(() => _isSearching = false);
              _searchController.clear();
              context.read<MusicProvider>().clearSearch();
            },
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchHint,
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        prefixIcon: const Icon(Icons.search, color: AppTheme.fixedAccent, size: 18),
        isDense: true,
      ),
      onChanged: (value) {
        context.read<MusicProvider>().search(value);
        setState(() {});
      },
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
            child: const RecentScreen(key: ValueKey('recent')),
          );
        }
        return _buildSongsTab();
      case 1:
        return AlbumScreen(searchQuery: _isSearching ? _searchController.text : '');
      case 2:
        return ArtistScreen(searchQuery: _isSearching ? _searchController.text : '');
      case 3:
        return const PlaylistScreen();
      case 4:
        return const FolderScreen();
      case 5:
        return const VideoScreen();
      default:
        return _buildSongsTab();
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
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.scanningMusic,
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        if (!musicProvider.hasPermission) return _buildPermissionDeniedView(musicProvider);
        if (musicProvider.errorMessage.isNotEmpty) return _buildErrorView(musicProvider);
        if (musicProvider.songs.isEmpty) return _buildEmptySongsView();

        return Column(
          children: [
            if (_isSelectionMode)
              Container(
                color: AppTheme.surfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() {
                        _isSelectionMode = false;
                        _selectedSongIds.clear();
                      }),
                    ),
                    Text(
                      AppLocalizations.of(context)!.selectedCount(_selectedSongIds.length),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          final allIds = musicProvider.songs.map((s) => s.id).toSet();
                          if (_selectedSongIds.length == allIds.length) {
                            _selectedSongIds.clear();
                          } else {
                            _selectedSongIds = allIds;
                          }
                        });
                      },
                      child: Text(
                          _selectedSongIds.length == musicProvider.songs.length
                              ? AppLocalizations.of(context)!.deselectAll
                              : AppLocalizations.of(context)!.selectAll,
                          style: const TextStyle(color: AppTheme.fixedAccent)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: _selectedSongIds.isEmpty
                          ? null
                          : () => _showMultiDeleteDialog(context, musicProvider),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _buildFilterTab(
                    AppLocalizations.of(context)!.all,
                    !_showFavorites && !_showRecent,
                        () => setState(() {
                      _showFavorites = false;
                      _showRecent = false;
                    }),
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildFilterTab(
                    AppLocalizations.of(context)!.favorites,
                    _showFavorites,
                        () => setState(() {
                      _showFavorites = true;
                      _showRecent = false;
                    }),
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildFilterTab(
                    AppLocalizations.of(context)!.recent,
                    _showRecent,
                        () => setState(() {
                      _showFavorites = false;
                      _showRecent = true;
                    }),
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 0),
              height: 1,
              color: Colors.white.withOpacity(0.06),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                children: [
                  Text('${musicProvider.songCount} ${AppLocalizations.of(context)!.songCount}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  if (_showThemeHint)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          ),
                          child: SizedBox(
                            height: 18,
                            child: Marquee(
                              text: '· ${AppLocalizations.of(context)!.themeColorHint}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                              scrollAxis: Axis.horizontal,
                              blankSpace: 40,
                              velocity: 30,
                              pauseAfterRound: const Duration(seconds: 1),
                              startPadding: 0,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (musicProvider.songs.isNotEmpty) {
                        context.read<PlayerProvider>().playFromList(musicProvider.songs, 0);
                      }
                    },
                    icon: const Icon(Icons.play_arrow,
                        color: Colors.white60, size: 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () {
                      if (musicProvider.songs.isNotEmpty) {
                        final songs = List<Song>.from(musicProvider.songs)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0);
                      }
                    },
                    icon: const Icon(Icons.shuffle, color: Colors.white60, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: () => musicProvider.loadSongs(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: musicProvider.songs.length,
                  itemBuilder: (context, index) {
                    final songs = musicProvider.songs;
                    final song = songs[index];
                    final isSelected = _selectedSongIds.contains(song.id);
                    return TweenAnimationBuilder<double>(
                      key: ValueKey('anim_${song.id}'),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset((1 - value) * 24, 0.0),
                          child: Transform.scale(
                            scale: 0.95 + (0.05 * value),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedSongIds.add(song.id);
                          });
                        },
                        onTap: _isSelectionMode
                            ? () {
                          setState(() {
                            if (isSelected) {
                              _selectedSongIds.remove(song.id);
                              if (_selectedSongIds.isEmpty) {
                                _isSelectionMode = false;
                              }
                            } else {
                              _selectedSongIds.add(song.id);
                            }
                          });
                        }
                            : null,
                        child: Container(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white38,
                                    size: 22,
                                  ),
                                ),
                              Expanded(
                                child: SongListTile(
                                  song: song,
                                  index: index,
                                  songList: songs,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap, Color primaryColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
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
            Text(AppLocalizations.of(context)!.permissionRequired,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.permissionMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => musicProvider.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(AppLocalizations.of(context)!.allowPermission,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => musicProvider.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: Text(AppLocalizations.of(context)!.retry),
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
          Text(AppLocalizations.of(context)!.noSongs,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.addMusic,
              style: const TextStyle(color: AppTheme.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Color primaryColor) {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) => setState(() => _currentTabIndex = index),
      backgroundColor: const Color(0xFF0A0A0A),
      selectedItemColor: Colors.white,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      elevation: 0,
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.music_note),
            label: AppLocalizations.of(context)!.songs),
        BottomNavigationBarItem(
            icon: const Icon(Icons.album),
            label: AppLocalizations.of(context)!.albums),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.artists),
        BottomNavigationBarItem(
            icon: const Icon(Icons.playlist_play),
            label: AppLocalizations.of(context)!.playlists),
        BottomNavigationBarItem(
            icon: const Icon(Icons.folder),
            label: AppLocalizations.of(context)!.folders),
        BottomNavigationBarItem(
            icon: const Icon(Icons.video_library),
            label: AppLocalizations.of(context)!.videos),
      ],
    );
  }
}