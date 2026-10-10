import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/paran_photo.dart';
import '../utils/nature_sound_catalog.dart';
import '../utils/greeting_images.dart';
import '../providers/theme_provider.dart';
import '../providers/player_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';
import 'radio_home_screen.dart';
import '../widgets/equalizer_animation.dart';
import '../widgets/logo_eq_bars.dart';
import 'nature_sound_detail_screen.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/paran_toast.dart';
import '../widgets/heart_pop.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../main.dart' show globalAudioHandler;
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NatureSoundsScreen extends StatefulWidget {
  const NatureSoundsScreen({super.key});

  @override
  State<NatureSoundsScreen> createState() => _NatureSoundsScreenState();
}

// 자연소리 목록은 utils/nature_sound_catalog.dart 에 있어요
typedef _NatureSound = NatureSound;

// 파도소리는 곡마다 다른 사진을, 나머지는 정해진 사진 한 장을 보여준다.
const List<String> _waveThumbImages = [
  'assets/nature_wave_bg.png',
  'assets/wave2.png',
  'assets/wave3.png',
  'assets/wave4.png',
  'assets/wave5.png',
  'assets/wave6.png',
];

// 소리 이름별로 상세페이지에 실제 정해둔 사진을 그대로 쓴다. (여기 없는 이름은 아래 폴백으로)
const Map<String, String> _natureImageByName = {
  '빗소리': 'assets/nature_rain_bg.png',
  '창문에 떨어지는 비': 'assets/nature_rain_bg.png',
  '숲속의 비와 새소리': 'assets/rain3.png',
  '숲속의 거센 밤비': 'assets/rain4.png',
  '뻐꾸기와 숲속 새소리': 'assets/bird2.png',
  '잔잔한 강물': 'assets/stream2.png',
};

String _natureThumbImage(String name, String category, String assetPath) {
  final fixed = _natureImageByName[name];
  if (fixed != null) return fixed;
  if (category == '파도소리') {
    final hash = assetPath.hashCode.abs();
    return _waveThumbImages[hash % _waveThumbImages.length];
  }
  switch (category) {
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

class _NatureSoundsScreenState extends State<NatureSoundsScreen> {
  Timer? _sleepTimer;
  int? _sleepMinutes;
  _NatureSound? _selectedSound;
  Set<String> _favoriteNames = {};
  bool _showFavoritesOnly = false;
  String _selectedCategory = '전체';

  static const _sounds = natureSoundCatalog;

  // 예전 목록 (안 씀) — 나중에 지워도 됨
  static const _oldSounds = <_NatureSound>[
    _NatureSound(
      name: '파도소리',
      category: '파도소리',
      icon: Icons.waves,
      emoji: '🌊',
      description: '규칙적인 파도 소리는 마음을 차분히 가라앉혀 깊은 휴식과 수면에 도움을 줘요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_sound.mp3',
    ),
    _NatureSound(
      name: '잔잔한 파도',
      category: '파도소리',
      icon: Icons.waves,
      emoji: '🌊',
      description: '한결 부드럽고 잔잔하게 밀려오는 파도 소리로 편안한 휴식을 도와줘요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_calm_sound.mp3',
    ),
    _NatureSound(
      name: '갈매기와 파도',
      category: '파도소리',
      icon: Icons.waves,
      emoji: '🌊',
      description: '갈매기 울음소리가 어우러진 파도 소리로 생생한 해변 분위기를 느껴보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_seagull_sound.mp3',
    ),
    _NatureSound(
      name: '바위에 부딪히는 파도',
      category: '파도소리',
      icon: Icons.waves,
      emoji: '🌊',
      description: '바위에 세게 부딪히며 부서지는 파도 소리로 역동적인 바다를 느껴보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_rocks_sound.mp3',
    ),
    _NatureSound(
      name: '멀리서 들리는 갈매기',
      category: '파도소리',
      icon: Icons.waves,
      emoji: '🌊',
      description: '고요한 바닷가, 멀리서 은은하게 들려오는 갈매기 소리로 차분한 휴식을 느껴보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_distant_seagull_sound.mp3',
    ),
    _NatureSound(
      name: '거친 파도',
      category: '파도소리',
      icon: Icons.waves,
      emoji: '🌊',
      description: '거칠게 밀려와 부서지는 파도 소리로 힘 있는 바다를 느껴보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/wave_rough_sound.mp3',
    ),
    _NatureSound(
      name: '빗소리',
      category: '빗소리',
      icon: Icons.water_drop_outlined,
      emoji: '☔',
      description: '일정한 빗소리는 집중력을 높이고 불안한 마음을 편안하게 다독여줘요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_sound.mp3',
    ),
    _NatureSound(
      name: '창문에 떨어지는 비',
      category: '빗소리',
      icon: Icons.water_drop_outlined,
      emoji: '🪟',
      description: '창문을 두드리는 부드러운 빗소리로 편안하게 잠들어보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_window_sound.mp3',
    ),
    _NatureSound(
      name: '숲속의 비와 새소리',
      category: '빗소리',
      icon: Icons.water_drop_outlined,
      emoji: '🌲',
      description: '숲속에 내리는 빗소리와 새소리가 어우러져 마음을 편안하게 해줘요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_forest_sound.mp3',
    ),
    _NatureSound(
      name: '숲속의 거센 밤비',
      category: '빗소리',
      icon: Icons.water_drop_outlined,
      emoji: '🌙',
      description: '깊은 밤 숲속에 세차게 내리는 빗소리로 몰입감 있는 휴식을 느껴보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/rain_night_forest_sound.mp3',
    ),
    _NatureSound(
      name: '새소리',
      category: '새소리',
      icon: Icons.forest_outlined,
      emoji: '🐦',
      description: '청아한 새소리는 스트레스를 줄이고 상쾌한 기분을 만들어줘요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/bird_sound.mp3',
    ),
    _NatureSound(
      name: '뻐꾸기와 숲속 새소리',
      category: '새소리',
      icon: Icons.forest_outlined,
      emoji: '🌳',
      description: '뻐꾸기 소리가 어우러진 숲속의 새소리로 상쾌한 아침을 느껴보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/bird_forest_cuckoo_sound.mp3',
    ),
    _NatureSound(
      name: '모닥불',
      category: '모닥불',
      icon: Icons.local_fire_department_outlined,
      emoji: '🔥',
      description: '타닥타닥 장작 타는 소리는 아늑한 분위기로 깊은 이완을 도와줘요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/campfire_sound.mp3',
    ),
    _NatureSound(
      name: '시냇물',
      category: '시냇물',
      icon: Icons.water_outlined,
      emoji: '💧',
      description: '졸졸 흐르는 시냇물 소리는 마음을 편안하게 하고 잡생각을 줄여줘요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/stream_sound.mp3',
    ),
    _NatureSound(
      name: '잔잔한 강물',
      category: '시냇물',
      icon: Icons.water_outlined,
      emoji: '🌊',
      description: '넓은 강물이 잔잔하게 흐르는 소리로 편안한 휴식을 느껴보세요',
      assetPath: 'https://srdzgrinceazcimdwayu.supabase.co/storage/v1/object/public/nature-sounds/stream_river_sound.mp3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('nature_favorites') ?? [];
    if (mounted) setState(() => _favoriteNames = favs.toSet());
  }

  Future<void> _toggleFavorite(String name) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('nature_favorites') ?? [];
    final nowFavorite = !_favoriteNames.contains(name);
    setState(() {
      if (nowFavorite) {
        _favoriteNames.add(name);
      } else {
        _favoriteNames.remove(name);
      }
    });
    if (nowFavorite) {
      if (!favs.contains(name)) favs.add(name);
    } else {
      favs.remove(name);
    }
    await prefs.setStringList('nature_favorites', favs);
    // (하트가 바로 바뀌어서 따로 알림 없음)
  }

  void _showCenterToast(String message) {
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
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleSound(_NatureSound sound, bool isThisOnePlaying) async {
    if (!sound.isReady) return;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pp = context.read<PlayerProvider>();
    try {
      if (isThisOnePlaying) {
        await pp.togglePlayPause();
      } else {
        setState(() => _selectedSound = sound);
        await pp.playNatureSound(sound.assetPath!, sound.name);
      }
    } catch (e) {
      debugPrint('=== 자연소리 재생 오류: $e ===');
      if (mounted) {
        showParanToast(context, '소리를 재생하지 못했어요', error: true);
      }
    }
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
              const Text(
                '자연소리를 종료하시겠어요?',
                style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                '다음에 또 좋은 소리로 만나요.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
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

      await context.read<PlayerProvider>().stopNatureSound();
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

  void _setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutes = minutes);
    if (minutes != null) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        context.read<PlayerProvider>().stopNatureSound();
        setState(() => _sleepMinutes = null);
      });
    }
  }

  void _showSleepTimerDialog(Color baseColor, bool isDarkMode) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
        title: Text('수면 타이머', style: TextStyle(color: baseColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 15, 30, 60].map((m) {
            return ListTile(
              title: Text('$m분 후 정지', style: TextStyle(color: baseColor)),
              onTap: () {
                Navigator.pop(ctx);
                _setSleepTimer(m);
              },
            );
          }).toList()
            ..add(ListTile(
              title: Text('끄기', style: TextStyle(color: baseColor.withOpacity(0.5))),
              onTap: () {
                Navigator.pop(ctx);
                _setSleepTimer(null);
              },
            )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final playerProvider = context.watch<PlayerProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF24221F),
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        systemOverlayStyle: isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: baseColor, size: 20),
        ),
        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '자연',
                        style: GoogleFonts.doHyeon(
                            // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : baseColor, fontSize: 20),
                      ),
                      TextSpan(
                        text: ' 휴식',
                        style: GoogleFonts.doHyeon(
                            color: baseColor, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: LogoEqBars(),
                ),
              ],
            ),
            const SizedBox(height: 0),
            Text(
              '마음이 편안해지는 소리를 들어보세요',
              style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 11.5),
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            Builder(builder: (context) {
              final categories = ['전체', '파도소리', '빗소리', '새소리', '모닥불', '시냇물'];
              return Container(
                height: 38,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final count = category == '전체'
                        ? _sounds.length
                        : _sounds.where((s) => s.category == category).length;
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        setState(() => _selectedCategory = category);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDarkMode ? Colors.white : const Color(0xFF17140F))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$category($count)',
                          style: TextStyle(
                            color: isSelected
                                ? (isDarkMode ? const Color(0xFF24221F) : Colors.white)
                                : baseColor.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            ...(() {
              const soundColors = <String, Color>{
                '파도소리': Color(0xFF4A7BA6),
                '빗소리': Color(0xFF3E5A78),
                '새소리': Color(0xFF5C7A5E),
                '모닥불': Color(0xFFC97B4A),
                '시냇물': Color(0xFF2C6BB3),
              };
              final filtered = _selectedCategory == '전체'
                  ? _sounds
                  : _sounds.where((s) => s.category == _selectedCategory).toList();

              // 같은 카테고리(예: 파도소리)끼리 묶는다
              final Map<String, List<_NatureSound>> grouped = {};
              for (final s in filtered) {
                grouped.putIfAbsent(s.name, () => []).add(s);
              }

              void openVariant(_NatureSound sound, Color soundColor) {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                final isThisOne = playerProvider.natureSoundName == sound.name;
                final isPlayingThis = isThisOne && playerProvider.isPlaying;
                if (!isPlayingThis) {
                  _toggleSound(sound, isPlayingThis);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NatureSoundDetailScreen(
                      name: sound.name,
                      icon: sound.icon,
                      description: sound.description,
                      assetPath: sound.assetPath,
                      color: soundColor,
                    ),
                  ),
                );
              }

              final _natureCards = grouped.entries.map((entry) {
                final categoryName = entry.key;
                final variants = entry.value;
                final primary = variants.first;
                final isMulti = variants.length > 1;
                final soundColor = soundColors[primary.category] ?? primaryColor;
                final isGroupPlaying = variants.any((v) => playerProvider.natureSoundName == v.name) &&
                    playerProvider.isPlaying;
                final displayTitle = isMulti ? categoryName : primary.name;
                // 설명은 짧게: "3가지 버전" (듣는 중이면 뒤에 붙이기)
                final baseDesc = isMulti ? '${variants.length}가지 버전' : primary.description;
                final displayDescription = isGroupPlaying ? '$baseDesc · 듣는 중' : baseDesc;

                return GestureDetector(
                  onTap: variants.every((v) => !v.isReady)
                      ? null
                      : () {
                    if (!isMulti) {
                      openVariant(primary, soundColor);
                      return;
                    }
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => _VariantPickerSheet(
                        categoryName: categoryName,
                        variants: variants,
                        soundColor: soundColor,
                        baseColor: baseColor,
                        favoriteNames: _favoriteNames,
                        onPick: (sound) {
                          Navigator.pop(ctx);
                          openVariant(sound, soundColor);
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    // 듣는 중: 바탕 위에 살짝 밝은 칸
                    decoration: BoxDecoration(
                      color: isGroupPlaying
                          ? (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.55))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: paranPhoto(
                            _natureThumbImage(primary.name, primary.category, primary.assetPath ?? ''),
                            thumb: true,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            fallback: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: soundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(primary.icon, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayTitle,
                                  style: TextStyle(
                                      color: baseColor,
                                      fontSize: 14.5,
                                      fontWeight: isGroupPlaying ? FontWeight.w800 : FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(displayDescription,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 11.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isGroupPlaying)
                          _NatureEqBars(
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8
                                ? (isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
                                : context.watch<ThemeProvider>().primaryColor,
                          )
                        else if (isMulti)
                          Icon(Icons.chevron_right_rounded, color: baseColor.withOpacity(0.3), size: 22)
                        else
                          GestureDetector(
                            // 하트 주변 칸 전체가 하트 자리 (옆을 눌러도 재생 안 되게)
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleFavorite(primary.name),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: HeartPop(
                                  on: _favoriteNames.contains(primary.name),
                                  child: Icon(
                                    _favoriteNames.contains(primary.name)
                                        ? CupertinoIcons.heart_fill
                                        : CupertinoIcons.heart,
                                    color: _favoriteNames.contains(primary.name)
                                        ? const Color(0xFFE05A4F)
                                        : baseColor.withOpacity(0.3),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList();
              // 흰 카드 없이 바탕 위에 줄만 (국가 목록과 같은 방식, 아주 연한 구분선)
              return [
                Column(
                  children: [
                    for (var i = 0; i < _natureCards.length; i++) ...[
                      if (i > 0)
                        Container(
                            height: 0.6,
                            margin: const EdgeInsets.only(left: 78, right: 12),
                            color: baseColor.withOpacity(0.07)),
                      _natureCards[i],
                    ],
                  ],
                ),
              ];
            })(),
          ],
        ),
      ),
      ),
    );
  }
}

class _VariantPickerSheet extends StatelessWidget {
  final String categoryName;
  final List<_NatureSound> variants;
  final Color soundColor;
  final Color baseColor;
  final Set<String> favoriteNames;
  final ValueChanged<_NatureSound> onPick;

  const _VariantPickerSheet({
    required this.categoryName,
    required this.variants,
    required this.soundColor,
    required this.baseColor,
    required this.favoriteNames,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: baseColor == Colors.white ? const Color(0xFF32302C) : const Color(0xFFF4EFE5), // 다른 창과 같은 색
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('$categoryName 버전 고르기',
                    style: TextStyle(color: baseColor, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              ParanCloseX(onTap: () => Navigator.pop(context)), // 닫기
            ],
          ),
          const SizedBox(height: 14),
          ...variants.map((v) => GestureDetector(
                onTap: v.isReady ? () => onPick(v) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: soundColor,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(v.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name,
                                style: TextStyle(
                                    color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(v.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 11)),
                          ],
                        ),
                      ),
                      if (favoriteNames.contains(v.name))
                        Icon(CupertinoIcons.heart_fill, color: const Color(0xFFE05A4F), size: 15),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
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

class _CircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color baseColor;
  const _CircleIconButton({
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

// 라디오 목록에서 실제로 쓰는 것과 완전히 똑같은 재생중 막대 (막대 3개, 폭이 좁아요)
class _NatureEqBars extends StatefulWidget {
  final Color color;
  const _NatureEqBars({required this.color});

  @override
  State<_NatureEqBars> createState() => _NatureEqBarsState();
}

class _NatureEqBarsState extends State<_NatureEqBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1400 + i * 400),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrls[i],
            builder: (_, __) => Container(
              width: 4,
              height: 6 + _ctrls[i].value * 14,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

