import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart' show globalAudioHandler, SimpleAudioHandler;
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import '../providers/start_screen_provider.dart';
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
import 'package:marquee/marquee.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';
import 'nature_sounds_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


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
  bool _showMusicLibrary = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showBanner = false;
  bool _isSelectionMode = false;
  final Map<int, GlobalKey> _songItemKeys = {};
  int? _lastScrolledSongId;
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
      await _navigateToSavedStartScreen();
    });
  }

  Future<void> _navigateToSavedStartScreen() async {
    if (!mounted) return;
    final startScreen = context.read<StartScreenProvider>().startScreen;
    switch (startScreen) {
      case StartScreenType.music:
        setState(() => _showMusicLibrary = true);
        break;
      case StartScreenType.radio:
        Navigator.push(
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
        );
        break;
      case StartScreenType.nature:
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => NatureSoundsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
        break;
      case StartScreenType.sleep:
      case null:
        break;
    }
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

  void _handleStartScreenStarTap(BuildContext context, StartScreenType type, String label) {
    final provider = context.read<StartScreenProvider>();
    if (provider.startScreen == type) {
      provider.setStartScreen(null);
      return;
    }
    _showSetStartScreenDialog(context, type, label);
  }

  void _showSetStartScreenDialog(BuildContext context, StartScreenType type, String label) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '앱 시작 화면으로 설정할까요?',
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '파란소리를 실행할 때 이 화면을 가장 먼저 보여드립니다.',
                style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.white60 : Colors.black54,
                        side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        context.read<StartScreenProvider>().setStartScreen(type);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FA8DC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('설정하기', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmDialog(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '파란소리를 종료하시겠어요?',
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '재생 중인 소리가 멈춰요.',
                style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.white60 : Colors.black54,
                        side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('계속 듣기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                        _showFarewellAndExit(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('종료', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFarewellAndExit(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    late final String smallText;
    late final String farewellAsset;
    switch (langCode) {
      case 'ko':
        smallText = '파란소리와 함께한 시간,\n즐거우셨나요?\n\n언제든 다시 찾아오시면,\n좋은 소리로 맞아드릴게요.\n안녕히 가세요!';
        farewellAsset = 'assets/farewell_ko.mp3';
        break;
      case 'ja':
        smallText = 'Paransoriと過ごした時間、\n楽しんでいただけましたか?\n\nいつでもまた遊びに来てください、\n素敵な音でお迎えします。\nまた会いましょう!';
        farewellAsset = 'assets/farewell_ja.mp3';
        break;
      case 'zh':
        smallText = '与Paransori相伴的时光，\n您开心吗?\n\n欢迎随时回来，\n我们会用美好的声音迎接您。\n再见啦!';
        farewellAsset = 'assets/farewell_zh.mp3';
        break;
      default:
        smallText = 'Did you enjoy your time\nwith Paransori?\n\nCome back anytime — we\'ll\nwelcome you with great sounds again.\nGoodbye, and see you soon!';
        farewellAsset = 'assets/farewell_en.mp3';
    }
    if (context.read<ThemeProvider>().voiceGreetingEnabled) {
      final farewellPlayer = AudioPlayer();
      farewellPlayer.setAsset(farewellAsset).then((_) => farewellPlayer.play());
    }

    context.read<PlayerProvider>().player.setVolume(0.12);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.05, end: 0.85),
            duration: const Duration(milliseconds: 11000),
            curve: Curves.easeIn,
            builder: (_, darkValue, __) => Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/farewell_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(darkValue),
                    BlendMode.darken,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 15000), () async {
      late OverlayEntry fadeOutEntry;
      fadeOutEntry = OverlayEntry(
        builder: (_) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      );
      overlay.insert(fadeOutEntry);

      try {
        await context.read<PlayerProvider>().stopNatureSound();
      } catch (_) {}
      try {
        await context.read<RadioProvider>().stopRadio();
      } catch (_) {}
      final handler = globalAudioHandler;
      if (handler is SimpleAudioHandler) {
        handler.playbackState.add(PlaybackState());
        handler.mediaItem.add(null);
        await handler.stop();
      }

      await Future.delayed(const Duration(milliseconds: 900));
      entry.remove();
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('closeApp');
    });
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
              final selectedSongs = musicProvider.songs
                  .where((s) => _selectedSongIds.contains(s.id))
                  .toList();
              final paths = selectedSongs
                  .where((s) => s.uri != null)
                  .map((s) => s.uri!)
                  .toList();
              int successCount = 0;
              try {
                final result = await platform.invokeMethod('deleteSongs', {'paths': paths});
                if (result == true) successCount = paths.length;
              } catch (e) {
                debugPrint('일괄 삭제 실패: $e');
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSong = context.read<PlayerProvider>().currentSong;
      if (currentSong != null && currentSong.id != _lastScrolledSongId) {
        _lastScrolledSongId = currentSong.id;
        final key = _songItemKeys[currentSong.id];
        final targetContext = key?.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: 0.15,
          );
        }
      }
    });
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF17140F),
          systemNavigationBarIconBrightness: Brightness.light,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFEDE7DA),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_isSearching) {
          setState(() => _isSearching = false);
          _searchController.clear();
          context.read<MusicProvider>().clearSearch();
        } else {
          const platform = MethodChannel('kr.ssing.catsong/media');
          platform.invokeMethod('moveToBackground');
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA),
      elevation: 0,
      titleSpacing: 20,
      title: _isSearching
          ? _buildSearchField()
          : Builder(builder: (ctx) {
        final isKorean = Localizations.localeOf(context).languageCode == 'ko';
        if (isKorean) {
          return Image.asset(
            'assets/home_logo.png',
            height: 44,
            width: 110,
            fit: BoxFit.fill,
          );
        }
        return Transform(
          transform: Matrix4.skewX(-0.15),
          child: Text(
              'Paransori',
              style: TextStyle(
                  color: baseColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
        );
      }),
      actions: [
        if (!_isSearching) ...[
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() => _isSearching = true);
            },
            icon: Icons.search,
            baseColor: baseColor,
          ),
          const SizedBox(width: 8),
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              context.read<ThemeProvider>().setDarkMode(!isDarkMode);
            },
            icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            baseColor: baseColor,
          ),
          const SizedBox(width: 8),
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              _showExitConfirmDialog(context);
            },
            icon: Icons.power_settings_new_rounded,
            baseColor: baseColor,
          ),
          const SizedBox(width: 8),
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              showModalBottomSheet(
                context: context,
                backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.share_outlined, color: baseColor),
                        title: Text('친구에게 공유하기', style: TextStyle(color: baseColor)),
                        onTap: () {
                          Navigator.pop(ctx);
                          Share.share('뮤직웨이브 앱으로 음악 들어요! 🎧\nhttps://play.google.com/store/apps/details?id=kr.ssing.catsong');
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.mood, color: baseColor),
                        title: Text('앱 평가하기', style: TextStyle(color: baseColor)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final uri = Uri.parse('https://play.google.com/store/apps/details?id=kr.ssing.catsong');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.settings_outlined, color: baseColor),
                        title: Text('설정', style: TextStyle(color: baseColor)),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 250),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: Icons.more_vert,
            baseColor: baseColor,
          ),
          const SizedBox(width: 12),
        ] else
          Transform.translate(
            offset: const Offset(-12, 0),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                setState(() => _isSearching = false);
                _searchController.clear();
                context.read<MusicProvider>().clearSearch();
              },
              child: Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: baseColor.withOpacity(0.7), fontWeight: FontWeight.w600)),
            ),
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
        if (_showMusicLibrary) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showMusicLibrary = false);
              return false;
            },
            child: _buildSongsTab(),
          );
        }
        return _buildDashboard();
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

  Widget _buildDashboard() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final recentSongs = context.watch<MusicProvider>().recentSongs.take(8).toList();

    final startScreen = context.watch<StartScreenProvider>().startScreen;

    final categories = [
      _DashboardCategory('음악', '내 음악 · MP3 플레이어', 'assets/music_bg.png', StartScreenType.music, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        setState(() => _showMusicLibrary = true);
      }),
      _DashboardCategory('라디오', '국내외 라디오 · 즐겨찾기', 'assets/radio_bg.png', StartScreenType.radio, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
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
        );
      }),
      _DashboardCategory('자연소리', '비 · 바람 · 숲 · 파도', 'assets/nature_bg.png', StartScreenType.nature, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => NatureSoundsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }),
      _DashboardCategory('수면 · 집중', '백색소음 · 집중음 (준비중)', 'assets/sleep_bg.png', StartScreenType.sleep, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수면 · 집중 기능은 준비중입니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }),
    ];

    final recommended = [
      ('비 오는 날', 'assets/sound_rain.png'),
      ('파도 소리', 'assets/sound_wave.png'),
      ('장작불 소리', 'assets/sound_fire.png'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFilterTab(
                AppLocalizations.of(context)!.all,
                !_showFavorites && !_showRecent,
                    () => setState(() {
                  _showFavorites = false;
                  _showRecent = false;
                }),
                primaryColor,
              ),
              _buildFilterTab(
                AppLocalizations.of(context)!.favorites,
                _showFavorites,
                    () => setState(() {
                  _showFavorites = true;
                  _showRecent = false;
                }),
                primaryColor,
              ),
              _buildFilterTab(
                AppLocalizations.of(context)!.recent,
                _showRecent,
                    () => setState(() {
                  _showFavorites = false;
                  _showRecent = true;
                }),
                primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: categories.map((c) {
              return GestureDetector(
                onTap: c.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          c.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: baseColor.withOpacity(0.08),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.18),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.08),
                                  border: Border(
                                    top: BorderSide(color: Colors.white.withOpacity(0.18)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c.title,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.7),
                                                blurRadius: 8,
                                                offset: const Offset(0, 1),
                                              ),
                                            ])),
                                    const SizedBox(height: 2),
                                    Text(c.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.7),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                            ])),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              _handleStartScreenStarTap(context, c.type, c.title);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.28),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                startScreen == c.type
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                size: 18,
                                color: startScreen == c.type
                                    ? const Color(0xFF6FA8DC)
                                    : Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.volume_up_rounded, size: 18, color: baseColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('오늘의 추천 소리',
                  style: TextStyle(
                      color: baseColor, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: Row(
              children: List.generate(recommended.length * 2 - 1, (i) {
                if (i.isOdd) return const SizedBox(width: 12);
                final item = recommended[i ~/ 2];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => NatureSoundsScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 250),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.16),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              item.$2,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: baseColor.withOpacity(0.08),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.12),
                                  ],
                                  stops: const [0.55, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: ClipRRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.08),
                                      border: Border(
                                        top: BorderSide(color: Colors.white.withOpacity(0.16)),
                                      ),
                                    ),
                                    child: Text(item.$1,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.7),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                            ])),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (recentSongs.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.headphones_rounded, size: 18, color: baseColor.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('최근 들은 음악',
                    style: TextStyle(
                        color: baseColor, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentSongs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final song = recentSongs[index];
                  return GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      context.read<PlayerProvider>().playFromList(recentSongs, index);
                    },
                    child: SizedBox(
                      width: 78,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: song.albumArt != null
                                  ? Image.memory(
                                Uint8List.fromList(song.albumArt!),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                                  : Container(
                                width: 72,
                                height: 72,
                                color: primaryColor.withOpacity(0.7),
                                child: const Icon(Icons.music_note_rounded,
                                    color: Colors.white, size: 26),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(song.titleDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: baseColor, fontSize: 11, fontWeight: FontWeight.w600)),
                          Text(song.artistDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: baseColor.withOpacity(0.45), fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
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
                    style: TextStyle(color: baseColor.withOpacity(0.7))),
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
                color: baseColor.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: baseColor),
                      onPressed: () => setState(() {
                        _isSelectionMode = false;
                        _selectedSongIds.clear();
                      }),
                    ),
                    Text(
                      AppLocalizations.of(context)!.selectedCount(_selectedSongIds.length),
                      style: TextStyle(color: baseColor, fontWeight: FontWeight.bold),
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
              color: baseColor.withOpacity(0.06),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(
                children: [
                  Text('${musicProvider.songCount} ${AppLocalizations.of(context)!.songCount}',
                      style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (musicProvider.songs.isNotEmpty) {
                        context.read<PlayerProvider>().playFromList(musicProvider.songs, 0);
                      }
                    },
                    icon: Icon(Icons.play_arrow,
                        color: baseColor.withOpacity(0.6), size: 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (musicProvider.songs.isNotEmpty) {
                        final songs = List<Song>.from(musicProvider.songs)..shuffle();
                        context.read<PlayerProvider>().playFromList(songs, 0);
                      }
                    },
                    icon: Icon(Icons.shuffle, color: baseColor.withOpacity(0.6), size: 20),
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
                    _songItemKeys.putIfAbsent(song.id, () => GlobalKey());
                    return TweenAnimationBuilder<double>(
                      key: _songItemKeys[song.id],
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
                                        : baseColor.withOpacity(0.38),
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
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? baseColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? baseColor : baseColor.withOpacity(0.54),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView(MusicProvider musicProvider) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 72, color: primaryColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.permissionRequired,
                style: TextStyle(
                    color: baseColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.permissionMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: baseColor.withOpacity(0.7), fontSize: 14, height: 1.6)),
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
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
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
                style: TextStyle(color: baseColor.withOpacity(0.7), fontSize: 14)),
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
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 72, color: baseColor.withOpacity(0.38)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noSongs,
              style: TextStyle(color: baseColor.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.addMusic,
              style: TextStyle(color: baseColor.withOpacity(0.54), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Color primaryColor) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5);
    final l = AppLocalizations.of(context)!;
    final items = [
      {'icon': Icons.music_note, 'label': l.songs},
      {'icon': Icons.album, 'label': l.albums},
      {'icon': Icons.person, 'label': l.artists},
      {'icon': Icons.playlist_play, 'label': l.playlists},
      {'icon': Icons.folder, 'label': l.folders},
      {'icon': Icons.video_library, 'label': l.videos},
    ];
    return Container(
      color: bgColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = _currentTabIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    setState(() => _currentTabIndex = index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: isSelected ? baseColor : baseColor.withOpacity(0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          color: isSelected ? baseColor : baseColor.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
class _AppBarCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color baseColor;
  const _AppBarCircleButton({
    required this.onTap,
    required this.icon,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseColor.withOpacity(0.07),
          border: Border.all(color: baseColor.withOpacity(0.08)),
        ),
        child: Icon(icon, color: baseColor, size: 18),
      ),
    );
  }
}

class _RoundedStar extends StatelessWidget {
  final bool filled;
  final Color color;
  final double size;
  const _RoundedStar({required this.filled, required this.color, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RoundedStarPainter(filled: filled, color: color),
    );
  }
}

class _RoundedStarPainter extends CustomPainter {
  final bool filled;
  final Color color;
  _RoundedStarPainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR * 0.58;
    final points = <Offset>[];
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? outerR : innerR;
      points.add(Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)));
    }
    const cornerFactor = 0.38;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final curr = points[i];
      final prev = points[(i - 1 + points.length) % points.length];
      final next = points[(i + 1) % points.length];
      final p1 = Offset.lerp(curr, prev, cornerFactor)!;
      final p2 = Offset.lerp(curr, next, cornerFactor)!;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundedStarPainter oldDelegate) =>
      oldDelegate.filled != filled || oldDelegate.color != color;
}

class _DashboardCategory {
  final String title;
  final String subtitle;
  final String imageAsset;
  final StartScreenType type;
  final VoidCallback onTap;

  _DashboardCategory(this.title, this.subtitle, this.imageAsset, this.type, this.onTap);
}