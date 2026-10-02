import 'dart:math' as math;
import '../utils/no_album_helper.dart';
import '../utils/paran_photo.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/greeting_images.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../providers/lyrics_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import 'edit_song_screen.dart';
import 'lyrics_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';
import '../main.dart' show globalAudioHandler;
import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _equalizerController;
  late List<AnimationController> _eqControllers;
  late List<Animation<double>> _eqAnimations;
  int _albumArtStyle = 1;
  bool _showNightPicker = true;
  String? _nightSelectedCategory;
  String _nightBgPath = 'assets/music_night_bg.png';
  Set<String> _nightFavPaths = {};
  bool _nightBgIsFile = false;
  int _bgFilter = 0; // 0 컬러, 1 흑백, 2 세피아
  int _autoBgMin = 0; // 0 끄기, 10, 30 (분)
  Timer? _autoBgTimer;

  static const Map<String, String> _nightCategoryCover = {
    '봄': 'assets/spring_photo1.png',
    '여름': 'assets/summer_photo1.png',
    '가을': 'assets/autumn_photo1.png',
    '겨울': 'assets/winter_photo1.png',
    '감성': 'assets/mood_photo1.png',
    '동물': 'assets/animal_photo1.png',
    '사랑': 'assets/love_photo1.png',
    '기타': 'assets/etc_photo1.png',
  };

  static const Map<String, List<String>> _nightCategoryPhotos = {
    '봄': [
      'assets/spring_photo1.png',
      'assets/spring_photo2.png',
      'assets/spring_photo3.png',
      'assets/spring_photo4.png',
      'assets/spring_photo5.png',
      'assets/spring_photo6.png',
    ],
    '여름': [
      'assets/summer_photo1.png',
      'assets/summer_photo2.png',
      'assets/summer_photo3.png',
      'assets/summer_photo4.png',
      'assets/summer_photo5.png',
      'assets/summer_photo6.png',
    ],
    '가을': [
      'assets/autumn_photo1.png',
      'assets/autumn_photo2.png',
      'assets/autumn_photo3.png',
      'assets/autumn_photo4.png',
      'assets/autumn_photo5.png',
      'assets/autumn_photo6.png',
    ],
    '겨울': [
      'assets/winter_photo1.png',
      'assets/winter_photo2.png',
      'assets/winter_photo3.png',
      'assets/winter_photo4.png',
      'assets/winter_photo5.png',
      'assets/winter_photo6.png',
    ],
    '감성': [
      'assets/mood_photo1.png',
      'assets/mood_photo2.png',
      'assets/mood_photo3.png',
      'assets/mood_photo4.png',
      'assets/mood_photo5.png',
      'assets/mood_photo6.png',
    ],
    '동물': [
      'assets/animal_photo1.png',
      'assets/animal_photo2.png',
      'assets/animal_photo3.png',
      'assets/animal_photo4.png',
      'assets/animal_photo5.png',
      'assets/animal_photo6.png',
    ],
    '사랑': [
      'assets/love_photo1.png',
      'assets/love_photo2.png',
      'assets/love_photo3.png',
      'assets/love_photo4.png',
      'assets/love_photo5.png',
      'assets/love_photo6.png',
      'assets/love_photo7.png',
      'assets/love_photo8.png',
      'assets/love_photo9.png',
      'assets/love_photo10.png',
    ],
    '기타': [
      'assets/etc_photo1.png',
      'assets/etc_photo2.png',
      'assets/etc_photo3.png',
      'assets/etc_photo4.png',
      'assets/etc_photo5.png',
      'assets/etc_photo6.png',
    ],
  };
  Color _dominantColor = const Color(0xFF1A1A1A);
  bool _showSwipeHint = false;
  bool _hasSeenParanPhoto = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startEqAnimations();

    _loadStyle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      final currentSong = playerProvider.currentSong;
      if (currentSong != null) {
        context.read<LyricsProvider>().fetchLyrics(
          currentSong.titleDisplay,
          currentSong.artistDisplay,
          filePath: currentSong.uri,
        );
        _extractColor(currentSong);
      }
      playerProvider.onSongChanged = (song) {
        _extractColor(song);
      };
    });
  }

  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = false;
    setState(() {
      _albumArtStyle = prefs.getInt('albumArtStyle') ?? 1;
      _nightBgPath = prefs.getString('nightBgPath') ?? 'assets/spring_photo1.png';
      _nightFavPaths = (prefs.getStringList('nightFavPaths') ?? []).toSet();
      _nightBgIsFile = prefs.getBool('nightBgIsFile') ?? false;
      _showNightPicker = prefs.getBool('showNightPicker') ?? true;
      _hasSeenParanPhoto = prefs.getBool('hasSeenParanPhoto') ?? false;
      _showSwipeHint = !shown;
      _bgFilter = prefs.getInt('bgFilter') ?? 0;
      _autoBgMin = prefs.getInt('autoBgMin') ?? 0;
    });
    _restartAutoBgTimer();
    if (!shown) {
      await prefs.setBool('swipe_hint_shown', true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSwipeHint = false);
      });
    }
  }

  // ===== 파란포토 색감 / 자동 변경 =====
  Future<void> _setBgFilter(int v) async {
    setState(() => _bgFilter = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bgFilter', v);
  }

  Future<void> _setAutoBg(int minutes) async {
    setState(() => _autoBgMin = minutes);
    _restartAutoBgTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('autoBgMin', minutes);
  }

  void _restartAutoBgTimer() {
    _autoBgTimer?.cancel();
    _autoBgTimer = null;
    if (_autoBgMin <= 0) return;
    _autoBgTimer = Timer.periodic(Duration(minutes: _autoBgMin), (_) => _autoChangeBg());
  }

  void _autoChangeBg() {
    if (!mounted || _albumArtStyle != 6) return;
    if (!context.read<PlayerProvider>().isPlaying) return;
    // 하트한 사진이 2장 이상이면 그중에서, 아니면 지금 사진과 같은 카테고리에서
    final List<String> pool = _nightFavPaths.length >= 2
        ? _nightFavPaths.toList()
        : _nightCategoryPhotos.values
            .firstWhere((l) => l.contains(_nightBgPath), orElse: () => const [])
            .toList();
    pool.remove(_nightBgPath);
    if (pool.isEmpty) return;
    final next = pool[math.Random().nextInt(pool.length)];
    final nextIsFile = !next.startsWith('assets/');
    if (!nextIsFile) precacheParanPhoto(next, context); // 미리 받아두기
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _nightBgPath = next;
        _nightBgIsFile = nextIsFile;
      });
      _saveNightBg(next, isFile: nextIsFile);
    });
  }

  Widget _bgFiltered(Widget child) {
    if (_bgFilter == 1) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }
    if (_bgFilter == 2) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: child,
      );
    }
    return child;
  }

  Widget _buildPhotoOptions() {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2F7DE8) : Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.white.withOpacity(0.25),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    Widget optionRow(String title, List<Widget> chips) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            for (final c in chips) ...[c, const SizedBox(width: 6)],
          ],
        ),
      );
    }

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Center(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        );

    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          label('색감'),
          chip('컬러', _bgFilter == 0, () => _setBgFilter(0)),
          const SizedBox(width: 6),
          chip('흑백', _bgFilter == 1, () => _setBgFilter(1)),
          const SizedBox(width: 6),
          chip('세피아', _bgFilter == 2, () => _setBgFilter(2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Container(width: 1, color: Colors.white.withOpacity(0.3)),
          ),
          label('자동'),
          chip('끄기', _autoBgMin == 0, () => _setAutoBg(0)),
          const SizedBox(width: 6),
          chip('10분', _autoBgMin == 10, () => _setAutoBg(10)),
          const SizedBox(width: 6),
          chip('30분', _autoBgMin == 30, () => _setAutoBg(30)),
        ],
      ),
    );
  }

  Future<void> _saveStyle(int style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('albumArtStyle', style);
  }

  Future<void> _saveNightBg(String path, {bool isFile = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nightBgPath', path);
    await prefs.setBool('nightBgIsFile', isFile);
    await prefs.setBool('showNightPicker', false);
  }

  void _toggleNightFav(String path) {
    setState(() {
      if (_nightFavPaths.contains(path)) {
        _nightFavPaths.remove(path);
      } else {
        _nightFavPaths.add(path);
      }
    });
    SharedPreferences.getInstance()
        .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
  }

  void _showGalleryFavManager(BuildContext context) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final myPhotos = _nightFavPaths.where((p) => !p.startsWith('assets/')).toList();
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A251D),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('내 사진 관리',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 20, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (myPhotos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('아직 등록한 내 사진이 없어요',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: myPhotos.map((path) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(File(path), width: 70, height: 70, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                        setState(() {
                                          _nightFavPaths.remove(path);
                                          // 지금 배경으로 쓰는 사진을 지웠으면 바로 다른 사진으로 바꾼다
                                          if (_nightBgPath == path) {
                                            final next = _nightFavPaths.isNotEmpty
                                                ? _nightFavPaths.first
                                                : 'assets/spring_photo1.png';
                                            _nightBgPath = next;
                                            _nightBgIsFile = !next.startsWith('assets/');
                                            _saveNightBg(next, isFile: _nightBgIsFile);
                                          }
                                        });
                                        setSheetState(() {});
                                        SharedPreferences.getInstance().then(
                                                (p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 13, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _pickFromGallery() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty || !mounted) return;
    for (final file in picked) {
      _nightFavPaths.add(file.path);
    }
    SharedPreferences.getInstance()
        .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
    final first = picked.first.path;
    setState(() {
      _nightBgPath = first;
      _nightBgIsFile = true;
      _showNightPicker = false;
      _nightSelectedCategory = null;
    });
    _saveNightBg(first, isFile: true);
  }

  Future<void> _extractColor(Song song) async {
    if (song.albumArt == null) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      setState(() => _dominantColor = Color.fromRGBO(
        (primaryColor.red * 0.7).toInt().clamp(60, 255),
        (primaryColor.green * 0.7).toInt().clamp(60, 255),
        (primaryColor.blue * 0.7).toInt().clamp(60, 255),
        1,
      ));
      return;
    }
    try {
      final codec = await instantiateImageCodec(
        Uint8List.fromList(song.albumArt!),
        targetWidth: 20,
        targetHeight: 20,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData();
      if (byteData != null) {
        int totalR = 0, totalG = 0, totalB = 0;
        int pixelCount = 0;
        for (int i = 0; i < byteData.lengthInBytes; i += 4) {
          totalR += byteData.getUint8(i);
          totalG += byteData.getUint8(i + 1);
          totalB += byteData.getUint8(i + 2);
          pixelCount++;
        }
        if (pixelCount > 0) {
          final r = (totalR / pixelCount).toInt();
          final g = (totalG / pixelCount).toInt();
          final b = (totalB / pixelCount).toInt();
          final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
          if (brightness < 30) {
            setState(() => _dominantColor = const Color(0xFF3D3D5C));
          } else {
            setState(() {
              _dominantColor = Color.fromRGBO(
                (r * 0.5).toInt(),
                (g * 0.5).toInt(),
                (b * 0.5).toInt(),
                1,
              );
            });
          }
        }
      }
    } catch (e) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      setState(() => _dominantColor = Color.fromRGBO(
        (primaryColor.red * 0.4).toInt(),
        (primaryColor.green * 0.4).toInt(),
        (primaryColor.blue * 0.4).toInt(),
        1,
      ));
    }
  }

  void _startEqAnimations() {
    final durations = [900, 1100, 800, 1300];
    final delays = [0, 200, 400, 100];
    _eqControllers = List.generate(4, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durations[i]),
      );
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
    _eqAnimations = List.generate(4, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _eqControllers[i], curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    _autoBgTimer?.cancel();
    _rotationController.dispose();
    _equalizerController.dispose();
    for (final c in _eqControllers) c.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final song = playerProvider.currentSong;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (song == null) {
      final baseColorEmpty = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('No song is playing',
              style: TextStyle(color: baseColorEmpty.withOpacity(0.6))),
        ),
      );
    }

    final lyricsProvider = context.read<LyricsProvider>();
    final currentKey = '${song.titleDisplay}-${song.artistDisplay}';
    if (lyricsProvider.currentSongKey != currentKey) {
      lyricsProvider.clearLyrics();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lyricsProvider.fetchLyrics(
          song.titleDisplay,
          song.artistDisplay,
          filePath: song.uri,
        );
      });
      if (_albumArtStyle == 6 && _nightFavPaths.length >= 2) {
        final options = _nightFavPaths.where((p) => p != _nightBgPath).toList();
        if (options.isNotEmpty) {
          final next = options[math.Random().nextInt(options.length)];
          final nextIsFile = !next.startsWith('assets/');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _nightBgPath = next;
              _nightBgIsFile = nextIsFile;
            });
            _saveNightBg(next, isFile: nextIsFile);
          });
        }
      }
    }

    if (playerProvider.isPlaying) {
      _rotationController.repeat();
      _equalizerController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _equalizerController.stop();
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -300) {
          playerProvider.playNext();
        } else if (details.primaryVelocity! > 300) {
          playerProvider.playPrevious();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.45),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomBarItem(
                          context,
                          icon: null,
                          customIcon: '<path d="M18 4L22 8L18 12" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 6H5.5C7 6 8 6.7 9 8L11 11" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 20L22 16L18 12" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 18H5.5C7 18 8 17.3 9 16L15 8C16 6.7 17 6 18.5 6H22" stroke-linecap="round" stroke-linejoin="round"/>',
                          label: AppLocalizations.of(context)!.shuffle,
                          isActive: playerProvider.isShuffled,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.toggleShuffle();
                          },
                        ),
                        _buildBottomBarItem(
                          context,
                          icon: playerProvider.loopMode == LoopMode.one
                              ? null
                              : null,
                          customIcon: playerProvider.loopMode == LoopMode.one
                              ? '<path d="M17 2L21 6L17 10" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 11V9C3 7.3 4.3 6 6 6H21" stroke-linecap="round" stroke-linejoin="round"/><path d="M7 22L3 18L7 14" stroke-linecap="round" stroke-linejoin="round"/><path d="M21 13V15C21 16.7 19.7 18 18 18H3" stroke-linecap="round" stroke-linejoin="round"/><path d="M11 10V14M13 10L11 10V14L13 14" stroke-linecap="round" stroke-linejoin="round"/>'
                              : '<path d="M17 2L21 6L17 10" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 11V9C3 7.3 4.3 6 6 6H21" stroke-linecap="round" stroke-linejoin="round"/><path d="M7 22L3 18L7 14" stroke-linecap="round" stroke-linejoin="round"/><path d="M21 13V15C21 16.7 19.7 18 18 18H3" stroke-linecap="round" stroke-linejoin="round"/>',
                          label: '반복',
                          isActive: playerProvider.loopMode != LoopMode.off,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            playerProvider.toggleLoopMode();
                          },
                        ),
                        _buildBottomBarItem(
                          context,
                          icon: Icons.nightlight_round,
                          label: '수면',
                          isActive: playerProvider.isSleepTimerActive,
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            if (playerProvider.isSleepTimerActive) {
                              _showSleepTimerDialog(context, playerProvider, primaryColor);
                            } else {
                              _showSleepWheelPickerDirect(context, playerProvider, primaryColor);
                            }
                          },
                        ),
                        ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.white.withOpacity(0.12),
                  ),
                  GestureDetector(
                    onTap: () => _showExitConfirmDialog(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.power_settings_new, color: Color(0xFFE8877E), size: 22),
                          const SizedBox(height: 4),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // 앨범아트 블러 배경
            SizedBox.expand(
              child: _albumArtStyle == 6
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1200),
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('$_nightBgPath-$_bgFilter'),
                        child: _bgFiltered(_nightBgIsFile
                            ? Image.file(File(_nightBgPath), fit: BoxFit.cover)
                            : paranPhoto(_nightBgPath, fit: BoxFit.cover)),
                      ),
                    )
                  : ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: song.albumArt != null
                    ? Image.memory(
                  Uint8List.fromList(song.albumArt!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
                    : Image.asset(
                  noAlbumImagePath(song.title),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox.expand(
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
            // 상단 페이드
            Positioned(
              top: 0, left: 0, right: 0, height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 하단 페이드
            Positioned(
              bottom: 0, left: 0, right: 0, height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            // 왼쪽 페이드
            Positioned(
              top: 0, bottom: 0, left: 0, width: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 오른쪽 페이드
            Positioned(
              top: 0, bottom: 0, right: 0, width: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 62),
                child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: constraints.maxHeight < 600
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildTopBar(context, playerProvider, primaryColor),
                            constraints.maxHeight < 600
                                ? SizedBox(
                              height: constraints.maxHeight * 0.35,
                              child: _buildAlbumArt(song, primaryColor),
                            )
                                : Expanded(
                              flex: 5,
                              child: _buildAlbumArt(song, primaryColor),
                            ),
                            _buildEqualizer(playerProvider, primaryColor),
                            _buildCurrentLyrics(playerProvider, primaryColor),
                            constraints.maxHeight < 600
                                ? _buildControls(
                                context, playerProvider, musicProvider, song, primaryColor)
                                : Expanded(
                              flex: 4,
                              child: _buildControls(
                                  context, playerProvider, musicProvider, song, primaryColor),
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
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    final song = playerProvider.currentSong;
    const baseColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.pop(context);
            },
            icon: Icon(Icons.keyboard_arrow_down,
                color: baseColor, size: 30),
          ),
          Expanded(
            child: Center(
              child: Text(AppLocalizations.of(context)!.nowPlaying,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: baseColor.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2)),
            ),
          ),
          GestureDetector(
            onTap: () => _showPlayerOptionsSheet(context, song, primaryColor),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.more_vert, color: baseColor),
                  if (!_hasSeenParanPhoto)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerOptionsSheet(BuildContext context, Song? song, Color primaryColor) {
    if (song == null) return;
    final playerProvider = context.read<PlayerProvider>();
    const sheetColor = Color(0xFFF4EFE5);
    const baseColor = Color(0xFF1A1A1A);
    const descColor = Color(0xFF8A8378);
    const accent = AppTheme.fixedAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close, size: 24, color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: song.albumArt != null
                            ? Image.memory(
                          Uint8List.fromList(song.albumArt!),
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                            : Image.asset(
                          noAlbumImagePath(song.title),
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(song.titleDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(song.artistDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: descColor, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: baseColor.withOpacity(0.08)),
                  ),
                  _playerSheetItem(
                    ctx,
                    Icons.shuffle_rounded,
                    AppLocalizations.of(context)!.shuffle,
                    playerProvider.isShuffled ? accent : baseColor,
                    baseColor,
                        () {
                      Navigator.pop(ctx);
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      playerProvider.toggleShuffle();
                    },
                  ),
                  _playerSheetItem(
                    ctx,
                    Icons.repeat_rounded,
                    '반복',
                    playerProvider.loopMode != LoopMode.off ? accent : baseColor,
                    baseColor,
                        () {
                      Navigator.pop(ctx);
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      playerProvider.toggleLoopMode();
                    },
                  ),
                  _playerSheetItem(
                    ctx,
                    Icons.nightlight_round,
                    '수면',
                    playerProvider.isSleepTimerActive ? accent : baseColor,
                    baseColor,
                        () {
                      Navigator.pop(ctx);
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      if (playerProvider.isSleepTimerActive) {
                        _showSleepTimerDialog(context, playerProvider, primaryColor);
                      } else {
                        _showSleepWheelPickerDirect(context, playerProvider, primaryColor);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, color: baseColor.withOpacity(0.08)),
                  ),
                  _playerSheetItem(ctx, Icons.edit, AppLocalizations.of(context)!.editSong, accent, baseColor, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditSongScreen(song: song)));
                  }),
                  _playerSheetItem(ctx, Icons.playlist_add, AppLocalizations.of(context)!.addToPlaylist, accent, baseColor, () {
                    Navigator.pop(ctx);
                    _showAddToPlaylistDialog(context, song, primaryColor);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, color: baseColor.withOpacity(0.08)),
                  ),
                  _playerSheetItem(ctx, Icons.style, AppLocalizations.of(context)!.playerStyle, accent, baseColor, () {
                    Navigator.pop(ctx);
                    if (!_hasSeenParanPhoto) {
                      setState(() => _hasSeenParanPhoto = true);
                      SharedPreferences.getInstance().then((p) => p.setBool('hasSeenParanPhoto', true));
                    }
                    _showStyleDialog(context, primaryColor);
                  }, showNew: !_hasSeenParanPhoto),
                  _playerSheetItem(ctx, Icons.speed, '배속', accent, baseColor, () {
                    Navigator.pop(ctx);
                    _showSpeedDialog(context, context.read<PlayerProvider>(), primaryColor);
                  }),
                  _playerSheetItem(ctx, Icons.lyrics_outlined, AppLocalizations.of(context)!.lyrics, accent, baseColor, () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LyricsScreen()));
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _playerSheetItem(BuildContext context, IconData icon, String label, Color iconColor, Color textColor, VoidCallback onTap, {bool showNew = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
            if (showNew) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildAlbumArt(Song song, Color primaryColor) {
    switch (_albumArtStyle) {
      case 3: return _buildCardStyle(song, primaryColor);
      case 6: return _buildNightPhotoArea(song);
      default: return _buildCDStyle(song, primaryColor);
    }
  }

  Widget _buildNightPhotoArea(Song song) {
    return Stack(
      children: [
        _buildNightBgPicker(),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width - 90,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  song.titleDisplay,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  song.artistDisplay,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildNightBgPicker() {
    if (!_showNightPicker) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() => _showNightPicker = true);
              SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', true));
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
              ),
              child: const Icon(Icons.photo_outlined, color: Colors.white, size: 18),
            ),
          ),
        ),
      );
    }

    // 2단계: 카테고리를 아직 안 골랐으면 카테고리 목록을 보여준다.
    if (_nightSelectedCategory == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _nightCategoryCover.length + 4,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      setState(() => _nightSelectedCategory = '전체');
                    },
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('전체보기', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                if (index == _nightCategoryCover.length + 1) {
                  return GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('내 사진', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                if (index == _nightCategoryCover.length + 2) {
                  return GestureDetector(
                    onTap: () => _showGalleryFavManager(context),
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('관리', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                if (index == _nightCategoryCover.length + 3) {
                  return GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      setState(() => _showNightPicker = false);
                      SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', false));
                    },
                    child: Container(
                      width: 60,
                      height: 74,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.35),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 22),
                          SizedBox(height: 4),
                          Text('닫기', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
                final category = _nightCategoryCover.keys.elementAt(index - 1);
                final cover = _nightCategoryCover[category]!;
                return GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    setState(() => _nightSelectedCategory = category);
                  },
                  child: Container(
                    width: 60,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: paranPhoto(
                            cover,
                            thumb: true,
                            width: 60,
                            height: 74,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(11),
                                bottomRight: Radius.circular(11),
                              ),
                            ),
                            child: Text(
                              category,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // 3단계: 고른 카테고리 안의 사진들을 보여준다.
    final photos = _nightSelectedCategory == '전체'
        ? _nightCategoryPhotos.values.expand((e) => e).toList()
        : (_nightCategoryPhotos[_nightSelectedCategory] ?? []);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
        SizedBox(
          height: 64,
          child: photos.isEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        setState(() => _nightSelectedCategory = null);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.35),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      '준비중입니다',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _nightSelectedCategory == '전체' ? photos.length + 3 : photos.length + 2,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() => _nightSelectedCategory = null);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.35),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                        ),
                      );
                    }
                    if (_nightSelectedCategory == '전체' && index == 1) {
                      final allSelected = photos.every((p) => _nightFavPaths.contains(p));
                      return GestureDetector(
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() {
                            if (allSelected) {
                              _nightFavPaths.removeAll(photos);
                            } else {
                              _nightFavPaths.addAll(photos);
                            }
                          });
                          SharedPreferences.getInstance()
                              .then((p) => p.setStringList('nightFavPaths', _nightFavPaths.toList()));
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: allSelected ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.35),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: allSelected ? Colors.black : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '전체 선택',
                                style: TextStyle(
                                  color: allSelected ? Colors.black : Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final photoIndex = _nightSelectedCategory == '전체' ? index - 2 : index - 1;
                    if (index == photos.length + (_nightSelectedCategory == '전체' ? 2 : 1)) {
                      return GestureDetector(
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() {
                            _showNightPicker = false;
                            _nightSelectedCategory = null;
                          });
                          SharedPreferences.getInstance().then((p) => p.setBool('showNightPicker', false));
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.9),
                          ),
                          child: const Icon(Icons.check, color: Colors.black, size: 22),
                        ),
                      );
                    }
                    final path = photos[photoIndex];
                    final isFav = _nightFavPaths.contains(path);
                    return GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        _toggleNightFav(path);
                        setState(() {
                          _nightBgPath = path;
                          _nightBgIsFile = false;
                        });
                        _saveNightBg(path);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFav ? Colors.white : Colors.white.withOpacity(0.25),
                            width: isFav ? 2.5 : 1,
                          ),
                          boxShadow: isFav
                              ? [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: paranPhoto(path, fit: BoxFit.cover, thumb: true),
                        ),
                      ),
                    );
                  },
                ),
        ),
            const SizedBox(height: 10),
            _buildPhotoOptions(),
          ],
        ),
      ),
    );
  }
  Widget _buildCDStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _dominantColor.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: song.albumArt != null
                        ? SizedBox.expand(
                      child: Image.memory(
                        Uint8List.fromList(song.albumArt!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                        : SizedBox.expand(
                      child: Image.asset(
                        noAlbumImagePath(song.title),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // 중앙 구멍
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.2, -0.2),
                        colors: [
                          Colors.grey.shade400.withOpacity(0.5),
                          Colors.grey.shade600.withOpacity(0.4),
                          Colors.grey.shade800.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.grey.shade500.withOpacity(0.15),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoAlbumGradient(Song song) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hash = (song.title + song.artist).codeUnits.fold(0, (a, b) => a + b);
    // 곡마다 조금씩 다른 각도와 밝기
    final angles = [
      [Alignment.topLeft, Alignment.bottomRight],
      [Alignment.topRight, Alignment.bottomLeft],
      [Alignment.topCenter, Alignment.bottomCenter],
      [Alignment.centerLeft, Alignment.centerRight],
    ];
    final brightFactors = [0.9, 0.75, 0.6, 0.8, 0.7];
    final darkFactors = [0.3, 0.2, 0.4, 0.25, 0.35];
    final ai = hash % angles.length;
    final bi = hash % brightFactors.length;
    final di = (hash ~/ 3) % darkFactors.length;

    final bright = Color.fromRGBO(
      (primaryColor.red + (255 - primaryColor.red) * brightFactors[bi]).toInt().clamp(0, 255),
      (primaryColor.green + (255 - primaryColor.green) * brightFactors[bi]).toInt().clamp(0, 255),
      (primaryColor.blue + (255 - primaryColor.blue) * brightFactors[bi]).toInt().clamp(0, 255),
      1,
    );
    final dark = Color.fromRGBO(
      (primaryColor.red * darkFactors[di]).toInt().clamp(0, 255),
      (primaryColor.green * darkFactors[di]).toInt().clamp(0, 255),
      (primaryColor.blue * darkFactors[di]).toInt().clamp(0, 255),
      1,
    );

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: angles[ai][0],
          end: angles[ai][1],
          colors: [bright, primaryColor, dark],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildCassetteStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 릴 2개
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGlassReel(song: song),
                    const SizedBox(width: 48),
                    _buildGlassReel(song: song),
                  ],
                ),
                const SizedBox(height: 12),
                // 테이프 라인
                Container(
                  width: 100,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 곡명
                Text(
                  song.titleDisplay,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassReel({Song? song}) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 앨범아트 배경
                  if (song?.albumArt != null)
                    Image.memory(
                      Uint8List.fromList(song!.albumArt!),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    Container(
                      color: Colors.white.withOpacity(0.04),
                    ),
                  // 어둡게 오버레이
                  Container(
                    color: Colors.black.withOpacity(0.35),
                  ),
                  // 중앙 구멍
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141414),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReel(Color primaryColor, Song song) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * 3.14159,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2A2A),
              border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(6, (i) {
                  return Transform.rotate(
                    angle: i * 3.14159 / 3,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: primaryColor.withOpacity(0.4),
                    ),
                  );
                }),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            final scale = _rotationController.isAnimating ? 1.03 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: song.albumArt != null
                    ? Image.memory(
                  Uint8List.fromList(song.albumArt!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
                    : Image.asset(
                  noAlbumImagePath(song.title),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizerStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _equalizerController,
            builder: (context, child) {
              return CustomPaint(
                painter: _RadialVisualizerPainter(
                  progress: _equalizerController.value,
                  isPlaying: _rotationController.isAnimating,
                ),
                child: child,
              );
            },
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1a1a1a),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: song.albumArt != null
                    ? ClipOval(
                  child: Image.memory(
                    Uint8List.fromList(song.albumArt!),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                )
                    : const Center(
                  child: Text('♪',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 28)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientStyle(Song song, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.8),
                      primaryColor.withOpacity(0.3),
                      AppTheme.background,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (song.albumArt != null)
                        Opacity(
                          opacity: 0.3,
                          child: Image.memory(
                            Uint8List.fromList(song.albumArt!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            gaplessPlayback: true,
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (song.albumArt != null)
                            ClipOval(
                              child: Image.memory(
                                Uint8List.fromList(song.albumArt!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            )
                          else
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.3),
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Colors.white, size: 60),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            song.titleDisplay,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizer(PlayerProvider playerProvider, Color primaryColor) {
    if (!playerProvider.isPlaying) return const SizedBox(height: 20);
    final minHeights = [6.0, 4.0, 8.0, 5.0];
    final maxHeights = [18.0, 16.0, 20.0, 14.0];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return AnimatedBuilder(
              animation: _eqAnimations[i],
              builder: (context, child) {
                final height = minHeights[i] +
                    (maxHeights[i] - minHeights[i]) * _eqAnimations[i].value;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 3,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentLyrics(PlayerProvider playerProvider, Color primaryColor) {
    final lyricsProvider = context.watch<LyricsProvider>();
    if (!lyricsProvider.hasLyrics || lyricsProvider.lyrics.isEmpty) {
      return const SizedBox(height: 36);
    }
    lyricsProvider.updateCurrentLine(playerProvider.position);
    final currentLine = lyricsProvider.lyrics[lyricsProvider.currentLineIndex];
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          currentLine.text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerProvider playerProvider,
      MusicProvider musicProvider, Song song, Color primaryColor) {
    final isFav = musicProvider.isFavorite(song.id);
    const baseColor = Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.titleDisplay,
                        style: TextStyle(
                            color: baseColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 0),
                    Text(song.artistDisplay,
                        style: TextStyle(
                            color: baseColor.withOpacity(0.7), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  musicProvider.toggleFavorite(song);
                  final isFavNow = musicProvider.isFavorite(song.id);
                  final overlay = Overlay.of(context);
                  final entry = OverlayEntry(
                    builder: (context) => Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFavNow ? Icons.favorite : Icons.favorite_border,
                                  color: isFavNow ? Colors.redAccent : Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isFavNow
                                      ? AppLocalizations.of(context)!.addedToFavorites
                                      : AppLocalizations.of(context)!.removedFromFavorites,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      decoration: TextDecoration.none),
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
                },
                icon: Icon(
                  isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: isFav ? Colors.redAccent : baseColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: baseColor.withOpacity(0.7),
              inactiveTrackColor: baseColor.withOpacity(0.24),
              thumbColor: baseColor,
              overlayColor: baseColor.withOpacity(0.1),
            ),
            child: Slider(
              value: playerProvider.progress,
              onChanged: (value) {
                final position = Duration(
                  milliseconds:
                  (value * playerProvider.duration.inMilliseconds).toInt(),
                );
                playerProvider.seekTo(position);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(playerProvider.formatDuration(playerProvider.position),
                  style: TextStyle(
                      color: baseColor.withOpacity(0.7), fontSize: 12)),
              Text(playerProvider.formatDuration(playerProvider.duration),
                  style: TextStyle(
                      color: baseColor.withOpacity(0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  playerProvider.playPrevious();
                },
                icon: const Icon(Icons.skip_previous),
                color: baseColor,
                iconSize: 36,
              ),
              GestureDetector(
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  playerProvider.togglePlayPause();
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: playerProvider.isLoading
                      ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: baseColor),
                  )
                      : Icon(
                    playerProvider.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: baseColor,
                    size: 36,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  playerProvider.playNext();
                },
                icon: const Icon(Icons.skip_next),
                color: baseColor,
                iconSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song, Color primaryColor) {
    final playlistProvider = context.read<PlaylistProvider>();
    const accent = AppTheme.fixedAccent;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.addToPlaylist,
            style: const TextStyle(color: Colors.black)),
        content: playlistProvider.playlists.isEmpty
            ? Text(AppLocalizations.of(context)!.noPlaylists,
            style: const TextStyle(color: Colors.black54))
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlistProvider.playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play, color: accent),
                title: Text(playlist.name,
                    style: const TextStyle(color: Colors.black)),
                subtitle: Text('${playlist.songCount} songs',
                    style: const TextStyle(color: Colors.black54)),
                onTap: () {
                  playlistProvider.addSongToPlaylist(playlist.id, song);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${playlist.name} ${AppLocalizations.of(context)!.addedToPlaylist}'),
                      backgroundColor: AppTheme.surfaceVariant,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SleepTimerDialog(playerProvider: playerProvider, primaryColor: AppTheme.fixedAccent),
    );
  }

  void _showSleepWheelPickerDirect(BuildContext context, PlayerProvider playerProvider, Color _unusedColor) {
    final primaryColor = AppTheme.fixedAccent;
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    Duration picked = const Duration(minutes: 30);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('몇 시간 몇 분 후 정지할까요?',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(color: textColor, fontSize: 20),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (picked.inMinutes > 0) {
                          playerProvider.setSleepTimer(picked);
                          final timeLabel =
                              '${picked.inHours > 0 ? '${picked.inHours}${AppLocalizations.of(context)!.hourWord} ' : ''}${picked.inMinutes % 60}${AppLocalizations.of(context)!.minuteShort}';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.autoStopFormat(timeLabel),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: primaryColor,
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.set,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SpeedDialog(playerProvider: playerProvider, primaryColor: AppTheme.fixedAccent),
    );
  }

  void _showFarewellAndExit(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    late final String smallText;
    late final String farewellAsset;
    switch (langCode) {
      case 'ko':
        smallText = '파란소리와 함께한 시간,\n즐거우셨나요?\n\n언제든 다시 찾아오시면,\n좋은 소리로 맞아드릴게요.\n안녕히 가세요!';
        farewellAsset = 'assets/farewell_ko_v3.mp3';
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
    context.read<PlayerProvider>().player.setVolume(0.12);
    if (context.read<ThemeProvider>().voiceGreetingEnabled) {
      final farewellPlayer = AudioPlayer();
      farewellPlayer.setAsset(farewellAsset).then((_) => farewellPlayer.play());
    }
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

      final pp = context.read<PlayerProvider>();
      if (pp.isPlaying) {
        await pp.togglePlayPause();
      }
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

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.musicExitConfirmTitle,
                style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.musicExitConfirmMessage,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
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
                        foregroundColor: Colors.black54,
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.radioExitKeepListening),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        Navigator.pop(ctx);
                        _showFarewellAndExit(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.radioExitConfirmButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildBottomBarItem(
      BuildContext context, {
        IconData? icon,
        String? customIcon,
        required String label,
        required bool isActive,
        required VoidCallback onTap,
      }) {
    const baseColor = Colors.white;
    final iconColor = isActive ? baseColor : baseColor.withOpacity(0.55);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon != null
                ? SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2.2">$customIcon</svg>',
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  )
                : Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
            const SizedBox(height: 4),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.fixedAccent : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStyleDialog(BuildContext context, Color primaryColor) {
    const accent = AppTheme.fixedAccent;
    final styles = [
      {'id': 1, 'name': AppLocalizations.of(context)!.styleCD, 'icon': Icons.album, 'desc': AppLocalizations.of(context)!.styleCDDesc},
      {'id': 6, 'name': '파란포토', 'icon': Icons.photo_outlined, 'desc': '좋아하는 사진을 배경으로 골라보세요'},
      {'id': 3, 'name': AppLocalizations.of(context)!.styleCard, 'icon': Icons.image, 'desc': AppLocalizations.of(context)!.styleCardDesc},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.style, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.playerStyle,
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = _albumArtStyle == style['id'];
                return InkWell(
                  onTap: () {
                    setState(() => _albumArtStyle = style['id'] as int);
                    _saveStyle(style['id'] as int);
                    setDialogState(() {});
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withOpacity(0.10) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(style['icon'] as IconData,
                            color: isSelected ? accent : Colors.black38, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(style['name'] as String,
                                      style: TextStyle(
                                          color: isSelected ? accent : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  if (style['id'] == 6) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(style['desc'] as String,
                                  style: const TextStyle(color: Colors.black45, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: accent, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: accent)),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLoopModeDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {
  const accent = AppTheme.fixedAccent;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.repeatMode,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildLoopOption(ctx,
              icon: Icons.arrow_forward,
              title: AppLocalizations.of(context)!.noRepeat,
              subtitle: AppLocalizations.of(context)!.noRepeat,
              isSelected: playerProvider.loopMode == LoopMode.off,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.off);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            _buildLoopOption(ctx,
              icon: Icons.repeat_one,
              title: AppLocalizations.of(context)!.repeatOne,
              subtitle: AppLocalizations.of(context)!.repeatOne,
              isSelected: playerProvider.loopMode == LoopMode.one,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.one);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            _buildLoopOption(ctx,
              icon: Icons.repeat,
              title: AppLocalizations.of(context)!.repeatAll,
              subtitle: AppLocalizations.of(context)!.repeatAll,
              isSelected: playerProvider.loopMode == LoopMode.all,
              primaryColor: accent,
              onTap: () {
                playerProvider.setLoopMode(LoopMode.all);
                setDialogState(() {});
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLoopOption(
    BuildContext ctx, {
      required IconData icon,
      required String title,
      required String subtitle,
      required bool isSelected,
      required Color primaryColor,
      required VoidCallback onTap,
    }) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.12) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isSelected ? primaryColor : Colors.black38, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: isSelected ? primaryColor : Colors.black87,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: primaryColor, size: 20),
        ],
      ),
    ),
  );
}

class _SleepTimerDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SleepTimerDialog({required this.playerProvider, required this.primaryColor});

  @override
  State<_SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<_SleepTimerDialog> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    if (widget.playerProvider.isSleepTimerActive &&
        widget.playerProvider.sleepTimerEnd != null) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final end = widget.playerProvider.sleepTimerEnd;
    if (end != null) {
      _remaining = end.difference(DateTime.now());
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final end = widget.playerProvider.sleepTimerEnd;
      if (end == null) {
        timer.cancel();
        return;
      }
      setState(() {
        _remaining = end.difference(DateTime.now());
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    final l = AppLocalizations.of(context)!;
    final timeStr = hours > 0
        ? '$hours${l.hourWord} $minutes${l.minuteShort} $seconds${l.secondShort}'
        : '$minutes${l.minuteShort} $seconds${l.secondShort}';
    return '$timeStr ${l.autoStopCountdownSuffix}';
  }

  // 자연소리와 똑같은, 시간·분을 휠로 돌려서 정하는 방식
  void _showWheelPicker(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    Duration picked = const Duration(minutes: 30);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('몇 시간 몇 분 후 정지할까요?',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(
                  height: 216,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(color: textColor, fontSize: 20),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (picked.inMinutes > 0) {
                          widget.playerProvider.setSleepTimer(picked);
                          if (!mounted) return;
                          _startCountdown();
                          setState(() {});
                          final timeLabel =
                              '${picked.inHours > 0 ? '${picked.inHours}${AppLocalizations.of(context)!.hourWord} ' : ''}${picked.inMinutes % 60}${AppLocalizations.of(context)!.minuteShort}';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.autoStopFormat(timeLabel),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: widget.primaryColor,
                            duration: const Duration(seconds: 2),
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.set,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.playerProvider.isSleepTimerActive;
    final primaryColor = widget.primaryColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.sleepTimer,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.timer, color: primaryColor, size: 32),
                  const SizedBox(height: 8),
                  Text(_formatRemaining(_remaining),
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.playerProvider.cancelSleepTimer();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.timerCancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showWheelPicker(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.set,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeedDialog extends StatefulWidget {
  final PlayerProvider playerProvider;
  final Color primaryColor;
  const _SpeedDialog({required this.playerProvider, required this.primaryColor});

  @override
  State<_SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends State<_SpeedDialog> {
  static const List<double> _speeds = [
    0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95,
    1.0, 1.05, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4, 1.45,
    1.5, 1.55, 1.6, 1.65, 1.7, 1.75, 1.8, 1.85, 1.9, 1.95, 2.0,
  ];

  late double _speed;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _speed = widget.playerProvider.playbackSpeed;
    final initialIndex = _speeds.indexWhere((s) => (s - _speed).abs() < 0.01);
    _scrollController = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 10,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    widget.playerProvider.setPlaybackSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.fixedAccent;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.playbackSpeed,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                CupertinoPicker(
                  scrollController: _scrollController,
                  itemExtent: 44,
                  selectionOverlay: const SizedBox.shrink(),
                  onSelectedItemChanged: (index) => _setSpeed(_speeds[index]),
                  children: _speeds.map((speed) {
                    final isSelected = (_speed - speed).abs() < 0.01;
                    return Center(
                      child: Text(
                        '${speed.toStringAsFixed(2)}x',
                        style: TextStyle(
                          color: isSelected ? primaryColor : textColor.withOpacity(0.4),
                          fontSize: isSelected ? 22 : 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final index = _speeds.indexWhere((s) => (s - 1.0).abs() < 0.01);
                    _scrollController.animateToItem(
                      index >= 0 ? index : 10,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                    _setSpeed(1.0);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.defaultValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _RadialVisualizerPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  static final List<double> _heights = List.filled(48, 0.5);
  static final List<double> _speeds = List.generate(
      48, (i) => 0.003 + (i * 0.0007) % 0.005);
  static final List<double> _dirs = List.filled(48, 1.0);
  static bool _initialized = false;

  _RadialVisualizerPainter({
    required this.progress,
    required this.isPlaying,
  }) {
    if (!_initialized) {
      for (int i = 0; i < 48; i++) {
        _heights[i] = 0.1 + (i * 0.019) % 0.9;
        _dirs[i] = i % 2 == 0 ? 1.0 : -1.0;
      }
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const innerR = 52.0;
    const maxBar = 55.0;
    const barCount = 48;

    for (int i = 0; i < barCount; i++) {
      if (isPlaying) {
        _heights[i] += _speeds[i] * _dirs[i];
        if (_heights[i] > 1.0 || _heights[i] < 0.1) _dirs[i] *= -1;
      }

      final angle = (i / barCount) * 2 * pi - pi / 2;
      final barH = isPlaying ? 8 + _heights[i] * maxBar : 6.0;
      final alpha = isPlaying ? 0.12 + _heights[i] * 0.5 : 0.1;

      final x1 = center.dx + innerR * cos(angle);
      final y1 = center.dy + innerR * sin(angle);
      final x2 = center.dx + (innerR + barH) * cos(angle);
      final y2 = center.dy + (innerR + barH) * sin(angle);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = Colors.white.withOpacity(alpha)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RadialVisualizerPainter old) => true;
}
class _FarewellTextPainter extends CustomPainter {
  final double opacity;
  final String smallText;
  _FarewellTextPainter({required this.opacity, required this.smallText});

  @override
  void paint(Canvas canvas, Size size) {
    final isMultiline = smallText.contains('\n');
    final smallPainter = TextPainter(
      text: TextSpan(
        text: smallText,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity * 0.85),
          fontSize: isMultiline ? 17 : 14,
          letterSpacing: isMultiline ? 0.2 : 5,
          fontWeight: FontWeight.w500,
          fontStyle: isMultiline ? FontStyle.normal : FontStyle.italic,
          height: 1.6,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    smallPainter.paint(canvas, Offset((size.width - smallPainter.width) / 2, 0));

    final bigPainter = TextPainter(
      text: TextSpan(
        text: 'Paransori',
        style: TextStyle(color: Colors.white.withOpacity(opacity), fontSize: 33, letterSpacing: 3, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bigPainter.paint(canvas, Offset((size.width - bigPainter.width) / 2, smallPainter.height + 12));
  }

  @override
  bool shouldRepaint(covariant _FarewellTextPainter oldDelegate) => oldDelegate.opacity != opacity;
}