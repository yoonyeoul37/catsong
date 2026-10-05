import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/greeting_images.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart' show globalAudioHandler, SimpleAudioHandler;
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import '../providers/start_screen_provider.dart';
import '../providers/recent_content_provider.dart';
import 'all_favorites_screen.dart';
import '../models/recent_content_entry.dart';
import '../models/radio_station.dart';
import '../providers/video_provider.dart';
import '../widgets/nature_mini_player.dart';
import '../widgets/exit_confirm_dialog.dart';
import '../providers/sound_mix_provider.dart';
import '../widgets/sound_mix_mini_player.dart';
import 'video_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'dart:io' show Platform;
import 'call_recordings_screen.dart';
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
import 'nature_sound_detail_screen.dart';
import 'radio_player_screen.dart';
import '../utils/nature_sound_catalog.dart';
import '../utils/paran_photo.dart';
import '../utils/index_letter.dart';
import '../widgets/index_bar.dart';
import 'sleep_focus_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/more_menu_sheet.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';


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
  bool _showCalls = false; // 통화녹음 탭
  bool _showMusicLibrary = false;
  bool _pendingStartScreenNav = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final ScrollController _songListController = ScrollController();
  final ValueNotifier<String?> _indexBubble = ValueNotifier(null); // 가운데 큰 글자
  final ValueNotifier<String?> _currentGroup = ValueNotifier(null); // 지금 보고 있는 구간

  // ── 빠른 이동 막대용: 묶음(A-Z → ㄱ~ㅎ → #) 순서로 정리한 목록 (곡이 바뀔 때만 다시 계산) ──
  List<(String?, int)> _indexEntries = const []; // (머리글, null이면 곡) / 곡 번호
  List<Song> _indexSongs = const [];
  Map<String, int> _indexCounts = const {}; // 초성별 곡 수
  int _indexFingerprint = -1;
  static const double _indexHeaderH = 34; // 위 여백 + 초성 글자

  void _buildIndexEntries(List<Song> songs) {
    var fp = songs.length;
    for (final s in songs) {
      fp = (fp * 31 + s.titleDisplay.hashCode) & 0x3fffffff;
    }
    if (fp == _indexFingerprint) return;
    _indexFingerprint = fp;
    final byGroup = <String, List<Song>>{};
    for (final s in songs) {
      byGroup.putIfAbsent(indexGroupOf(s.titleDisplay), () => []).add(s);
    }
    final ordered = <Song>[];
    final entries = <(String?, int)>[];
    for (final g in kIndexGroups) {
      final list = byGroup[g];
      if (list == null || list.isEmpty) continue;
      list.sort((a, b) =>
          a.titleDisplay.toLowerCase().compareTo(b.titleDisplay.toLowerCase()));
      entries.add((g, -1));
      for (final s in list) {
        entries.add((null, ordered.length));
        ordered.add(s);
      }
    }
    _indexSongs = ordered;
    _indexCounts = {for (final e in byGroup.entries) e.key: e.value.length};
    _indexEntries = entries;
  }

  /// 지금 화면 맨 위에 보이는 구간(초성)을 찾아서 오른쪽 막대에 파랗게 표시
  void _updateCurrentGroup() {
    if (_indexEntries.isEmpty || !_songListController.hasClients) return;
    double rowH = 76;
    for (final k in _songItemKeys.values) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        rowH = box.size.height;
        break;
      }
    }
    final top = _songListController.offset + 1;
    double y = 0;
    String? cur;
    for (final e in _indexEntries) {
      if (y > top) break;
      if (e.$1 != null) cur = e.$1;
      y += e.$1 != null ? _indexHeaderH : rowH;
    }
    if (_currentGroup.value != cur) _currentGroup.value = cur;
  }

  /// 빠른 이동 막대: 그 묶음 머리글로 점프
  void _jumpToGroup(String group) {
    final hi = _indexEntries.indexWhere((e) => e.$1 == group);
    if (hi < 0 || !_songListController.hasClients) return;
    // 곡 한 줄 높이를 화면에 보이는 곡으로 재서 위치 계산
    double rowH = 76;
    for (final k in _songItemKeys.values) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        rowH = box.size.height;
        break;
      }
    }
    double offset = 0;
    for (var j = 0; j < hi; j++) {
      offset += _indexEntries[j].$1 != null ? _indexHeaderH : rowH;
    }
    final max = _songListController.position.maxScrollExtent;
    _songListController.jumpTo(offset.clamp(0.0, max));
  }

  /// 목록 안 초성 머리글: 바·선 없이 회갈색 초성 + 연한 곡 수
  Widget _buildIndexHeader(String group, bool isDark) {
    final count = _indexCounts[group] ?? 0;
    return SizedBox(
      height: _indexHeaderH,
      child: Padding(
        // 글자 시작을 앨범 이미지 시작 위치에 맞춤, 위쪽 여백으로 구간 구분
        padding: const EdgeInsets.fromLTRB(22, 14, 12, 2),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                group,
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF4A443B),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$count ${AppLocalizations.of(context)!.songCount}',
                style: TextStyle(
                  color: (isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  bool _showBanner = false;
  bool _isSelectionMode = false;
  final Map<int, GlobalKey> _songItemKeys = {};
  int? _lastScrolledSongId;
  Set<int> _selectedSongIds = {};
  bool _showThemeHint = false;

  @override
  void initState() {
    super.initState();
    _songListController.addListener(_updateCurrentGroup); // 스크롤하면 오른쪽 초성 파랗게 따라감
    final savedStart = context.read<StartScreenProvider>().startScreen;
    if (savedStart == StartScreenType.music) {
      _showMusicLibrary = true;
    } else if (savedStart == StartScreenType.radio || savedStart == StartScreenType.nature) {
      _pendingStartScreenNav = true;
    }
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
        await pushRadioEntry(context, instant: true);
        if (mounted) setState(() => _pendingStartScreenNav = false);
        break;
      case StartScreenType.nature:
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => NatureSoundsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        if (mounted) setState(() => _pendingStartScreenNav = false);
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
    _songListController.dispose();
    _indexBubble.dispose();
    _currentGroup.dispose();
    _speech.stop();
    super.dispose();
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _toggleListening() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );
    if (!available || !mounted) return;
    setState(() => _isListening = true);
    _speech.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        _searchController.text = result.recognizedWords;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        context.read<MusicProvider>().search(result.recognizedWords);
        setState(() {});
      },
    );
  }

  void _handleStartScreenStarTap(BuildContext context, StartScreenType type, String label) {
    final provider = context.read<StartScreenProvider>();
    if (provider.startScreen == type) {
      provider.setStartScreen(null);
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.heart_slash, color: Colors.black38, size: 30),
                    const SizedBox(height: 10),
                    Text(
                      '시작 화면이 취소되었습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      overlay.insert(entry);
      Future.delayed(const Duration(seconds: 2), () => entry.remove());
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

  void _showExitConfirmDialog(BuildContext context) async {
    // 새 종료창 (사진 + 큰 질문) — 홈·음악·라디오·자연소리 공통
    if (await showExitConfirm(context) && context.mounted) _showFarewellAndExit(context);
  }

  // (예전 종료창 — 코드 정리할 때 지우기)
  void _oldExitConfirmDialog(BuildContext context) {
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
                '다음에 또 좋은 소리로 만나요.',
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
        farewellAsset = 'assets/farewell_ko_v4.mp3';
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
    if (langCode == 'ko' && context.read<ThemeProvider>().voiceGreetingEnabled) {
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
                  image: CachedNetworkImageProvider(farewellImageUrl(context)),
                  onError: (_, __) {},
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

    Future.delayed(const Duration(milliseconds: 8000), () async {
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
                  if (playerProvider.natureSoundName != null) {
                    return const NatureMiniPlayer();
                  }
                  if (context.watch<SoundMixProvider>().hasSession) {
                    return const SoundMixMiniPlayer();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _showMusicLibrary
            ? _buildBottomNavBar(primaryColor)
            : const SafeArea(top: false, child: SizedBox.shrink()),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isKorean
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "파란"만 숨쉬듯 은은하게
                          _LogoBreathe(
                            child: Text('파란',
                                textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정
                                style: GoogleFonts.doHyeon(
                                    color: const Color(0xFF2F7DE8),
                                    fontSize: 22,
                                    letterSpacing: -0.5)),
                          ),
                          Text('소리',
                              textScaler: TextScaler.noScaling,
                              style: GoogleFonts.doHyeon(
                                  color: baseColor,
                                  fontSize: 22,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                      Transform.translate(
                        offset: const Offset(0, -4),
                        child: Text(
                          'Paransori',
                          style: TextStyle(
                              color: baseColor.withOpacity(0.55),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  )
                : Column(
                    // 해외: Paran(파란색) / 밑에 Sori (가운데 정렬)
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LogoBreathe(
                        child: Text('Paran',
                            style: GoogleFonts.doHyeon(
                                color: const Color(0xFF2F7DE8),
                                fontSize: 20,
                                height: 1.0,
                                letterSpacing: -0.3)),
                      ),
                      Text('Sori',
                          style: GoogleFonts.doHyeon(
                              color: baseColor,
                              fontSize: 20,
                              height: 1.0,
                              letterSpacing: -0.3)),
                    ],
                  ),
            const SizedBox(width: 6),
            Padding(
              // 해외는 아래 Sori 옆에 붙게 (파란 Paran과 안 겹치게)
              padding: EdgeInsets.only(top: isKorean ? 8 : 23, bottom: 4),
              child: const _LogoEqBars(),
            ),
          ],
        );
      }),
      actions: [
        if (!_isSearching) ...[
          if (_showMusicLibrary) ...[
            _AppBarCircleButton(
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                setState(() => _isSearching = true);
              },
              icon: Icons.search,
              baseColor: baseColor,
            ),
            const SizedBox(width: 8),
          ],
          _AppBarCircleButton(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllFavoritesScreen()),
              );
            },
            icon: CupertinoIcons.heart,
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
              showMoreMenuSheet(context);
              return;
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withOpacity(0.45),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) {
                  final sheetBg = isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFAFCFE);
                  final cardBg = isDarkMode
                      ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF22303F), Color(0xFF1A2632)])
                      : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFEAF3FC)]);
                  final cardBorder = isDarkMode ? Colors.white12 : const Color(0xFFE1EDF7);
                  const navy = Color(0xFF15304D);
                  final subColor = isDarkMode ? Colors.white60 : const Color(0xFF7891A8);

                  Widget menuCard({
                    required IconData icon,
                    required String title,
                    required String subtitle,
                    required VoidCallback onTap,
                  }) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: cardBg,
                            border: Border.all(color: cardBorder),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.45)
                                    : const Color(0xFF2C6BB3).withOpacity(0.16),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF4A90D9), Color(0xFF2C6BB3)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2C6BB3).withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, color: Colors.white, size: 21),
                              ),
                              const SizedBox(height: 14),
                              Text(title,
                                  style: TextStyle(
                                      color: isDarkMode ? Colors.white : navy,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(subtitle,
                                  maxLines: 2,
                                  style: TextStyle(color: subColor, fontSize: 11, height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: sheetBg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white24 : const Color(0xFFCBD9EC),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                width: 30,
                                height: 30,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white10 : const Color(0xFFF0F5FA),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close,
                                    size: 16, color: isDarkMode ? Colors.white70 : subColor),
                              ),
                            ),
                          ),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                menuCard(
                                  icon: Icons.share_outlined,
                                  title: '친구에게 공유하기',
                                  subtitle: '파란소리를 친구에게\n소개해보세요.',
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Share.share('파란소리 앱으로 음악 들어요! 🎧\nhttps://play.google.com/store/apps/details?id=kr.ssing.catsong');
                                  },
                                ),
                                const SizedBox(width: 12),
                                menuCard(
                                  icon: Icons.star_border_rounded,
                                  title: '앱 평가하기',
                                  subtitle: '좋은 평가가\n큰 힘이 됩니다.',
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final uri = Uri.parse('https://play.google.com/store/apps/details?id=kr.ssing.catsong');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                menuCard(
                                  icon: Icons.settings_outlined,
                                  title: '설정',
                                  subtitle: '앱 환경을\n설정할 수 있어요.',
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
                                const SizedBox(width: 12),
                                menuCard(
                                  icon: Icons.settings_input_antenna_rounded,
                                  title: '방송국 바로가기',
                                  subtitle: '다양한 라디오 방송을\n바로 들어보세요.',
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    pushRadioEntry(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
        suffixIcon: IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.redAccent : AppTheme.fixedAccent,
            size: 20,
          ),
          onPressed: _toggleListening,
        ),
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
        if (_showCalls) {
          return WillPopScope(
            onWillPop: () async {
              setState(() => _showCalls = false);
              return false;
            },
            child: const CallRecordingsScreen(),
          );
        }
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
        if (_pendingStartScreenNav) {
          return const SizedBox.shrink();
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
    final recentContent = context.watch<RecentContentProvider>().entries.take(20).toList();

    final startScreen = context.watch<StartScreenProvider>().startScreen;

    final categories = [
      _DashboardCategory('음악', '내 음악 · MP3 플레이어', 'assets/music_bg.jpg', StartScreenType.music, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        setState(() => _showMusicLibrary = true);
      }),
      _DashboardCategory('라디오', '국내외 라디오 · 즐겨찾기', 'assets/radio_bg.jpg', StartScreenType.radio, () {
        pushRadioEntry(context);
      }),
      _DashboardCategory('자연소리', '비 · 바람 · 숲 · 파도', 'assets/nature_bg.jpg', StartScreenType.nature, () {
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
      _DashboardCategory('수면 · 명상', '백색소음 · 명상음 (준비중)', 'assets/sleep_bg.jpg', StartScreenType.sleep, () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SleepFocusScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      }),
    ];

    // ── 잠시 쉬어가요: 하루에 한 번 바뀌는 추천 (자연소리 2개 + 편안한 라디오 1개) ──
    final now = DateTime.now();
    final daySeed = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 86400000;

    // 자연소리: 서로 다른 종류로 2개
    final naturePool = natureSoundCatalog.where((s) => s.isReady).toList()
      ..shuffle(math.Random(daySeed));
    final naturePicks = <NatureSound>[];
    for (final s in naturePool) {
      if (naturePicks.any((p) => p.category == s.category)) continue;
      naturePicks.add(s);
      if (naturePicks.length == 2) break;
    }

    const restColors = <String, Color>{
      '파도소리': Color(0xFF4A7BA6),
      '빗소리': Color(0xFF3E5A78),
      '새소리': Color(0xFF5C7A5E),
      '모닥불': Color(0xFFC97B4A),
      '시냇물': Color(0xFF2C6BB3),
    };

    String natureImage(NatureSound s) {
      switch (s.category) {
        case '파도소리':
          const waves = [
            'assets/nature_wave_bg.png',
            'assets/wave2.png',
            'assets/wave3.png',
            'assets/wave4.png',
            'assets/wave5.png',
            'assets/wave6.png',
          ];
          return waves[s.name.hashCode.abs() % waves.length];
        case '빗소리':
          return 'assets/nature_rain_bg.png';
        case '새소리':
          return 'assets/nature_bird_bg.png';
        case '모닥불':
          return 'assets/nature_fire_bg.png';
        case '시냇물':
          return 'assets/nature_stream_bg.png';
        default:
          return 'assets/nature_wave_bg.png';
      }
    }

    // 편안한 라디오: 하루에 하나씩 돌아가며 (보이는 이름, 방송국 이름, 주파수, 주소)
    const restRadios = [
      ('KBS 클래식FM', 'KBS Classic FM', '93.1 MHz',
          'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/24'),
      ('국악FM', '국악FM', '99.1 MHz',
          'http://mgugaklive.nowcdn.co.kr/gugakradio/gugakradio.stream/playlist.m3u8'),
      ('CBS 음악FM', 'CBS 음악FM', '93.9 MHz',
          'https://m-aac.cbs.co.kr/mweb_cbs939/_definst_/cbs939.stream/playlist.m3u8'),
    ];
    final todayRadio = restRadios[daySeed % restRadios.length];
    final restStation = RadioStation.fromJson({
      'stationuuid': 'kr_${todayRadio.$2.hashCode.abs()}',
      'name': todayRadio.$2,
      'url': todayRadio.$4,
      'url_resolved': '',
      'homepage': '',
      'favicon': '',
      'tags': '',
      'frequency': todayRadio.$3,
      'country': 'South Korea',
      'countrycode': 'KR',
      'bitrate': 0,
      'votes': 0,
    });

    // (카드 글자, 사진, 눌렀을 때)
    final recommended = <(String, String, VoidCallback)>[
      for (final s in naturePicks)
        (
          s.name,
          natureImage(s),
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NatureSoundDetailScreen(
                    name: s.name,
                    icon: s.icon,
                    description: s.description,
                    assetPath: s.assetPath,
                    color: restColors[s.category] ?? const Color(0xFF2F7DE8),
                    openedFromList: false, // 뒤로가기 → 자연소리 목록
                  ),
                ),
              ),
        ),
      (
        '📻 ${todayRadio.$1}',
        // 라디오 사진 10장 중 하루에 한 장
        'assets/rest_radio_${(daySeed % 10) + 1}.png',
        () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RadioPlayerScreen(
                  station: restStation,
                  openedFromList: false, // 뒤로가기 → 라디오 목록
                ),
              ),
            ),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: baseColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('이런 소리는 어때요?',
                  style: GoogleFonts.notoSansKr(
                      color: baseColor, fontSize: 14, fontWeight: FontWeight.w700)),
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
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                                        style: GoogleFonts.notoSansKr(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            shadows: [
                                              const Shadow(
                                                color: Colors.black,
                                                blurRadius: 3,
                                                offset: Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.9),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.75),
                                                blurRadius: 20,
                                                offset: const Offset(0, 3),
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
                                              const Shadow(
                                                color: Colors.black,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.85),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.65),
                                                blurRadius: 14,
                                                offset: const Offset(0, 2),
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
              Text('잠시 쉬어가요',
                  style: GoogleFonts.notoSansKr(
                      color: baseColor, fontSize: 14, fontWeight: FontWeight.w700)),
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
                      item.$3();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.24),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            paranPhoto(
                              item.$2,
                              thumb: true,
                              fit: BoxFit.cover,
                              fallback: Container(color: baseColor.withOpacity(0.08)),
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
                                              const Shadow(
                                                color: Colors.black,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.9),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.7),
                                                blurRadius: 14,
                                                offset: const Offset(0, 2),
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
          ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.headphones_rounded, size: 18, color: baseColor.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('최근에 들었어요',
                    style: GoogleFonts.notoSansKr(
                        color: baseColor, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (recentContent.isEmpty)
              Container(
                width: double.infinity,
                height: 124,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [const Color(0xFF1A2632), const Color(0xFF22303F)]
                        : [const Color(0xFFEAF3FC), const Color(0xFFD9E9F8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2C6BB3).withOpacity(isDarkMode ? 0.22 : 0.12),
                      ),
                      child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF2C6BB3), size: 19),
                    ),
                    const SizedBox(height: 10),
                    Text('최근 들은 곡이 없어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : const Color(0xFF15304D),
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('음악을 재생하면 여기에 표시됩니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white60 : const Color(0xFF7891A8),
                            fontSize: 11)),
                  ],
                ),
              )
            else
              Builder(builder: (context) {
                // 다음곡/이전곡이 "최근 재생 기록" 안의 음악끼리만 넘어가도록,
                // 여기 보이는 것 중 음악 항목만 모아서 재생목록으로 쓴다.
                final musicProviderForQueue = context.read<MusicProvider>();
                final recentMusicSongs = <Song>[];
                for (final e in recentContent) {
                  if (e.type == RecentContentType.music) {
                    for (final s in musicProviderForQueue.allSongs) {
                      if (s.uri == e.songUri) {
                        recentMusicSongs.add(s);
                        break;
                      }
                    }
                  }
                }
                return SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentContent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = recentContent[index];

                    IconData typeIcon;
                    Color typeColor;
                    Widget thumbnail;
                    VoidCallback onTapAction;

                    switch (item.type) {
                      case RecentContentType.music:
                        typeIcon = Icons.music_note_rounded;
                        typeColor = const Color(0xFF3B82F6);
                        final musicProvider = context.read<MusicProvider>();
                        Song? matched;
                        for (final s in musicProvider.allSongs) {
                          if (s.uri == item.songUri) {
                            matched = s;
                            break;
                          }
                        }
                        thumbnail = matched?.albumArt != null
                            ? Image.memory(
                          Uint8List.fromList(matched!.albumArt!),
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
                        );
                        onTapAction = () {
                          if (matched != null) {
                            final queueIndex = recentMusicSongs.indexWhere((s) => s.uri == matched!.uri);
                            context.read<PlayerProvider>().playFromList(
                              recentMusicSongs,
                              queueIndex >= 0 ? queueIndex : 0,
                            );
                          }
                        };
                        break;
                      case RecentContentType.radio:
                        typeIcon = Icons.radio_rounded;
                        typeColor = const Color(0xFF8B5CF6);
                        thumbnail = Container(
                          width: 72,
                          height: 72,
                          color: typeColor.withOpacity(0.7),
                          child: const Icon(Icons.radio_rounded, color: Colors.white, size: 26),
                        );
                        onTapAction = () {
                          if (item.stationData != null) {
                            final station = RadioStation.fromJson(item.stationData!);
                            context.read<RadioProvider>().playStation(station);
                          }
                        };
                        break;
                      case RecentContentType.nature:
                        typeIcon = Icons.waves_rounded;
                        typeColor = const Color(0xFF10B981);
                        thumbnail = Container(
                          width: 72,
                          height: 72,
                          color: typeColor.withOpacity(0.7),
                          child: const Icon(Icons.waves_rounded, color: Colors.white, size: 26),
                        );
                        onTapAction = () {
                          if (item.natureAssetPath != null) {
                            context.read<PlayerProvider>().playNatureSound(item.natureAssetPath!, item.title);
                          }
                        };
                        break;
                      case RecentContentType.sleep:
                        typeIcon = Icons.bedtime_rounded;
                        typeColor = const Color(0xFF6366F1);
                        thumbnail = Container(
                          width: 72,
                          height: 72,
                          color: typeColor.withOpacity(0.7),
                          child: const Icon(Icons.bedtime_rounded, color: Colors.white, size: 26),
                        );
                        onTapAction = () {};
                        break;
                    }

                    return GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        onTapAction();
                      },
                      child: SizedBox(
                        width: 78,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.24),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: thumbnail,
                                  ),
                                  Positioned(
                                    left: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(typeIcon, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: baseColor, fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(item.subtitle,
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
              );
              }),
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
                  // 녹음 (일반 음악과 따로) — 아이폰은 다른 앱 파일을 못 읽어서 안드로이드만
                  if (Platform.isAndroid) const Spacer(), // 통화녹음은 오른쪽 끝으로
                  // 통화녹음: 탭이 아니라 "다른 곳으로 가는" 작은 버튼 (안드로이드만)
                  if (Platform.isAndroid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() {
                            _showFavorites = false;
                            _showRecent = false;
                            _showCalls = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: baseColor.withOpacity(0.18), width: 0.8),
                          ),
                          child: Text('통화녹음 ›',
                              style: TextStyle(color: baseColor.withOpacity(0.65), fontSize: 12)),
                        ),
                      ),
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
              child: Builder(builder: (context) {
              // 빠른 이동 막대: 30곡 이상이고 검색 중이 아닐 때만
              final listSongs = musicProvider.songs;
              final showIndexBar = listSongs.length >= 30 && !_isSearching;
              if (showIndexBar) _buildIndexEntries(listSongs);
              final available = showIndexBar
                  ? _indexEntries.where((e) => e.$1 != null).map((e) => e.$1!).toSet()
                  : <String>{};
              // 막대가 있을 땐 묶음 순서(A-Z → ㄱ~ㅎ → #) + 머리글, 아니면 원래 목록 그대로
              final viewSongs = showIndexBar ? _indexSongs : listSongs;
              final List<(String?, int)> entries = showIndexBar
                  ? _indexEntries
                  : [for (var k = 0; k < listSongs.length; k++) (null, k)];
              final isDarkList = baseColor == Colors.white;
              return Stack(
              children: [
              RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: () => musicProvider.loadSongs(),
                child: ListView.builder(
                  controller: _songListController,
                  // 인덱스 띠와 곡 줄(선택 배경 포함) 사이에 틈 두기
                  padding: EdgeInsets.only(bottom: 8, right: showIndexBar ? 34 : 0),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    if (entry.$1 != null) {
                      return _buildIndexHeader(entry.$1!, isDarkList);
                    }
                    final index = entry.$2;
                    final songs = viewSongs;
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
              if (showIndexBar)
                Positioned(
                  right: 0,
                  top: 4,
                  bottom: 12,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _currentGroup,
                    builder: (context, cur, _) => IndexBar(
                      available: available,
                      isDark: isDarkList,
                      onLetter: _jumpToGroup,
                      onActiveChanged: (l) => _indexBubble.value = l,
                      current: cur ?? (available.isNotEmpty ? kIndexGroups.firstWhere(available.contains) : null),
                    ),
                  ),
                ),
              // 누르는 동안 가운데 큰 글자
              IgnorePointer(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _indexBubble,
                  builder: (context, letter, _) {
                    if (letter == null) return const SizedBox.shrink();
                    return Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kIndexBlue.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(letter,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: letter.length > 1 ? 28 : 40,
                                fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
              ),
              ],
              );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterTab(String label, bool isSelected, VoidCallback onTap, Color primaryColor,
      {IconData? icon, bool specialFont = false}) {
    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () {
        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(right: specialFont ? 0 : 20),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? baseColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘이 있으면 글자 앞에 작게 (예: 🎙 녹음)
            if (icon != null) ...[
              Icon(icon, size: 15, color: isSelected ? baseColor : baseColor.withOpacity(0.54)),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: specialFont
                  // 녹음 탭: 고운돋움 서체
                  ? GoogleFonts.dongle(
                      color: isSelected ? baseColor : baseColor.withOpacity(0.54),
                      fontSize: 19,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    )
                  : TextStyle(
                      color: isSelected ? baseColor : baseColor.withOpacity(0.54),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
            ),
          ],
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
                        color: isSelected ? const Color(0xFF2F7DE8) : baseColor.withOpacity(0.6),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseColor.withOpacity(0.07),
          border: Border.all(color: baseColor.withOpacity(0.08)),
        ),
        child: Icon(icon, color: baseColor, size: 16),
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


// 홈 화면 로고 옆의 작은 이퀄라이저 막대 (은은하게 움직임)
/// 로고 "파란"이 숨쉬듯 은은하게 밝아졌다 연해졌다 (3.2초에 한 번)
class _LogoBreathe extends StatefulWidget {
  final Widget child;
  const _LogoBreathe({required this.child});

  @override
  State<_LogoBreathe> createState() => _LogoBreatheState();
}

class _LogoBreatheState extends State<_LogoBreathe> with SingleTickerProviderStateMixin {
  // 3.5초마다 빛이 쉬지 않고 계속 흘러감 (시안과 같게)
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final x = -0.5 + _c.value * 2.0; // 빛 위치: 왼쪽 밖 → 오른쪽 밖 (쉬지 않고)
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: const Alignment(-1, -0.4), // 시안처럼 살짝 비스듬히
            end: const Alignment(1, 0.4),
            // 가운데만 밝고 양옆으로 부드럽게 번지는 넓은 빛
            colors: const [
              Color(0xFF2F7DE8),
              Color(0xFF2F7DE8),
              Color(0xFF5FA6F2), // 번짐 시작
              Color(0xFFA9D3FF), // 가장 밝은 곳
              Color(0xFF5FA6F2), // 번짐 끝
              Color(0xFF2F7DE8),
              Color(0xFF2F7DE8),
            ],
            stops: [
              0,
              (x - 0.38).clamp(0.0, 1.0),
              (x - 0.16).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.16).clamp(0.0, 1.0),
              (x + 0.38).clamp(0.0, 1.0),
              1,
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

class _LogoEqBars extends StatefulWidget {
  const _LogoEqBars();

  @override
  State<_LogoEqBars> createState() => _LogoEqBarsState();
}

class _LogoEqBarsState extends State<_LogoEqBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final t = _c.value * 2 * math.pi + i * 1.3;
              final v = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t));
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                child: Container(
                  width: 3,
                  height: 14 * v,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F7DE8),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}