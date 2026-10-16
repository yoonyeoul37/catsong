import 'dart:async';
import 'package:flutter/material.dart';
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
import '../widgets/logo_eq_bars.dart';
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
                        text: tr.natureTitle1,
                        style: GoogleFonts.doHyeon(
                            // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : baseColor, fontSize: 20),
                      ),
                      TextSpan(
                        text: tr.natureTitle2,
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
              tr.natureSub,
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
                          '${category == '전체' ? tr.all : natureName(category)}($count)',
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

