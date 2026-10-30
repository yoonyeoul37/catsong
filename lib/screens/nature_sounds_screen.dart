import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/title_font.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/paran_photo.dart';
import '../utils/nature_sound_catalog.dart';
import '../l10n/locale_holder.dart';
import '../providers/theme_provider.dart';
import '../providers/player_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';
import 'radio_home_screen.dart';
import '../widgets/equalizer_animation.dart';
import '../widgets/logo_shine.dart';
import 'nature_sound_detail_screen.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/paran_toast.dart';
import '../widgets/heart_pop.dart';
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
  _NatureSound? _selectedSound;
  Set<String> _favoriteNames = {};
  String _selectedCategory = '전체';

  static const _sounds = natureSoundCatalog;

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
        showParanToast(context, tr.soundPlayFailed, error: true);
      }
    }
  }

  static const _categories = ['전체', '파도소리', '빗소리', '새소리', '모닥불', '시냇물'];

  /// 라디오와 같은 탭: 박스 없이 글자 + 고른 탭만 아래 진한 밑줄
  Widget _natureTab(String category, bool isDarkMode) {
    final selected = _selectedCategory == category;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          setState(() => _selectedCategory = category);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? (isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F)) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // 글자가 커도 한 줄 (넘치면 칸에 맞게 살짝 줄임)
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              category == '전체' ? tr.all : natureName(category),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                color: selected
                    ? (isDarkMode ? Colors.white : const Color(0xFF17140F))
                    : baseColor.withOpacity(0.55),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 지금 시간에 어울리는 소리: 아침 새소리 · 낮 파도·시냇물(하루씩 번갈아) · 저녁 모닥불 · 밤 빗소리
  _NatureSound? _niceSoundNow() {
    final h = DateTime.now().hour;
    final cat = (h >= 5 && h < 11)
        ? '새소리'
        : (h >= 11 && h < 17)
            ? ((DateTime.now().millisecondsSinceEpoch ~/ 86400000).isEven ? '파도소리' : '시냇물')
            : (h >= 17 && h < 22)
                ? '모닥불'
                : '빗소리';
    final ready = _sounds.where((s) => s.isReady).toList();
    if (ready.isEmpty) return null;
    return ready.firstWhere((s) => s.category == cat, orElse: () => ready.first);
  }

  /// 카드 사진: 소리 종류별 그림 (사람이 앉아 듣는 장면)
  static String _niceImage(String category) => switch (category) {
        '새소리' => 'assets/nature_hero_morning.jpg',
        '파도소리' => 'assets/nature_hero_wave.jpg',
        '시냇물' => 'assets/nature_hero_stream.jpg',
        '모닥불' => 'assets/nature_hero_evening.jpg',
        _ => 'assets/nature_hero_night.jpg',
      };

  /// 전체 탭 맨 위 사진 카드 (라디오 '지금 듣기 좋은' 카드와 같은 모양)
  Widget _natureNiceCard(_NatureSound s, Color soundColor, void Function(_NatureSound, Color) open,
      PlayerProvider pp, bool isDark) {
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    const ink = Color(0xFF17140F);
    final playingThis = pp.natureSoundName == s.name && pp.isPlaying;
    return GestureDetector(
      onTap: () => open(s, soundColor),
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: ink.withOpacity(isDark ? 0.45 : 0.13),
              blurRadius: 20,
              spreadRadius: -3,
              offset: const Offset(0, 10),
            ),
            BoxShadow(color: ink.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 68, // 사진은 글자 띠 위에만
                // 다크 모드: 라디오 카드와 같게 색 반쯤 빼고 살짝 어둡게
                child: ColorFiltered(
                  colorFilter: isDark
                      ? const ColorFilter.matrix(<double>[
                          0.4082, 0.2832, 0.0286, 0, 0,
                          0.0842, 0.6072, 0.0286, 0, 0,
                          0.0842, 0.2832, 0.3526, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: Image.asset(
                    _niceImage(s.category),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2),
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => Container(color: soundColor),
                  ),
                ),
              ),
              // 사진 아래 크림 띠 (라디오 카드와 같은 색)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
                  decoration: const BoxDecoration(color: Color(0xFFFBF8F2)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr.niceNow,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                            const SizedBox(height: 1),
                            Text(natureName(s.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            Text(natureDesc(s.name, s.description),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(color: ink.withOpacity(0.62), fontSize: 12)),
                          ],
                        ),
                      ),
                      // ▶ 바로 듣기 (라디오 주사위 자리 · 같은 베이지 동그라미)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggleSound(s, playingThis),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Color(0xFFEDE7DA), shape: BoxShape.circle),
                          child: Icon(playingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: ink, size: 22),
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
    );
  }

  /// 전체 탭 묶음 제목: 이름 · 개수 뒤로 가는 선 (라디오와 같음)
  Widget _natureGroupTitle(String category, bool first, Color baseColor) {
    final count = _sounds.where((s) => s.category == category).length;
    return Padding(
      padding: EdgeInsets.only(top: first ? 6 : 22, bottom: 6),
      child: Row(
        children: [
          Flexible(
            child: Text(
              natureName(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: baseColor.withOpacity(0.72), fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          Text('$count',
              style: GoogleFonts.quicksand(color: baseColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: baseColor.withOpacity(0.18))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF242424) : const Color(0xFFEDE7DA);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final playerProvider = context.watch<PlayerProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF242424),
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
        centerTitle: true,
        // 라디오·자연·휴식 같은 위쪽: 앱 아이콘 + 제목 / 설명
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 아이콘 + 제목(회색 빛) / 아래 설명 — 홈 로고와 같은 짜임 (해외는 그 나라 말)
            Flexible(child: MenuTitle(title: tr.catNature, sub: tr.catNatureSub, isDark: isDarkMode)),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.12), width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in _categories) _natureTab(c, isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
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
                final displayTitle = natureName(isMulti ? categoryName : primary.name);
                // 설명은 짧게: "3가지 버전" (듣는 중이면 뒤에 붙이기)
                final baseDesc = isMulti ? tr.versionsCount(variants.length) : natureDesc(primary.name, primary.description);
                final displayDescription = isGroupPlaying ? '$baseDesc · ${tr.listeningNow}' : baseDesc;

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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    // 듣는 중: 라디오와 같은 연한 강조색 칸
                    color: isGroupPlaying ? primaryColor.withOpacity(0.08) : Colors.transparent,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
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
                                borderRadius: BorderRadius.circular(10),
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
                                    size: 18,
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
              // 라디오와 같게: 줄 사이 선 · 전체 탭은 소리 종류별 묶음 제목
              final cardCats = grouped.values.map((v) => v.first.category).toList();
              final order = List<int>.generate(_natureCards.length, (i) => i);
              final showTitles = _selectedCategory == '전체';
              if (showTitles) {
                int rank(String c) {
                  final r = _categories.indexOf(c);
                  return r < 0 ? 999 : r;
                }
                order.sort((a, b) {
                  final d = rank(cardCats[a]).compareTo(rank(cardCats[b]));
                  return d != 0 ? d : a.compareTo(b);
                });
              }
              final rows = <Widget>[];
              // 전체 탭 맨 위: 지금 듣기 좋은 사진 카드 (라디오와 같음)
              if (showTitles) {
                final nice = _niceSoundNow();
                if (nice != null) {
                  rows.add(_natureNiceCard(nice, soundColors[nice.category] ?? primaryColor, openVariant,
                      playerProvider, isDarkMode));
                }
              }
              String? lastCat;
              for (final i in order) {
                final cat = cardCats[i];
                if (showTitles && cat != lastCat) {
                  rows.add(_natureGroupTitle(cat, lastCat == null, baseColor)); // 제목 앞뒤는 선 없이
                } else if (rows.isNotEmpty) {
                  rows.add(Divider(height: 1, color: baseColor.withOpacity(0.1)));
                }
                lastCat = cat;
                rows.add(_natureCards[i]);
              }
              return [
                Column(children: rows),
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
        color: baseColor == Colors.white ? const Color(0xFF323232) : const Color(0xFFF4EFE5), // 다른 창과 같은 색
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
                child: Text(tr.pickVersion(natureName(categoryName)),
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
                            Text(natureName(v.name),
                                style: TextStyle(
                                    color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(natureDesc(v.name, v.description),
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

