import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';
import 'package:just_audio/just_audio.dart';

class NatureSoundDetailScreen extends StatefulWidget {
  final String name;
  final IconData icon;
  final String description;
  final String? assetPath;
  final Color color;

  const NatureSoundDetailScreen({
    super.key,
    required this.name,
    required this.icon,
    required this.description,
    required this.assetPath,
    required this.color,
  });

  @override
  State<NatureSoundDetailScreen> createState() => _NatureSoundDetailScreenState();
}

class _NatureSoundDetailScreenState extends State<NatureSoundDetailScreen> {
  Timer? _sleepTicker;
  DateTime? _sleepEndTime;
  int? _sleepMinutes;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<PlayerProvider>();
      final alreadyPlaying = pp.natureSoundName == widget.name && pp.isPlaying;
      if (!alreadyPlaying && widget.assetPath != null) {
        pp.playNatureSound(widget.assetPath!, widget.name);
      }
    });
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('nature_favorites') ?? [];
    if (mounted) setState(() => _isFavorite = favs.contains(widget.name));
  }

  Future<void> _toggleFavorite() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('nature_favorites') ?? [];
    final nowFavorite = !_isFavorite;
    setState(() => _isFavorite = nowFavorite);
    if (nowFavorite) {
      if (!favs.contains(widget.name)) favs.add(widget.name);
    } else {
      favs.remove(widget.name);
    }
    await prefs.setStringList('nature_favorites', favs);
    _showCenterToast(nowFavorite ? '즐겨찾기에 추가되었습니다' : '즐겨찾기에서 삭제되었습니다');
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
    _sleepTicker?.cancel();
    super.dispose();
  }

  void _setSleepTimer(int? minutes) {
    _sleepTicker?.cancel();
    if (minutes == null) {
      setState(() {
        _sleepMinutes = null;
        _sleepEndTime = null;
      });
      return;
    }
    setState(() {
      _sleepMinutes = minutes;
      _sleepEndTime = DateTime.now().add(Duration(minutes: minutes));
    });
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final remaining = _sleepEndTime!.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        timer.cancel();
        context.read<PlayerProvider>().stopNatureSound();
        setState(() {
          _sleepMinutes = null;
          _sleepEndTime = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  String _formatRemaining() {
    if (_sleepEndTime == null) return '타이머';
    final remaining = _sleepEndTime!.difference(DateTime.now());
    if (remaining.isNegative) return '타이머';
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    if (h > 0) return '$h시간 $m분';
    return '$m분';
  }

  void _showCustomMinutesDialog(bool isDarkMode) {
    Duration picked = const Duration(minutes: 30);
    final textColor = isDarkMode ? Colors.white : Colors.black;
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
                        final totalMinutes = picked.inMinutes;
                        Navigator.pop(ctx);
                        if (totalMinutes > 0) {
                          _setSleepTimer(totalMinutes);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                if (_sleepMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _setSleepTimer(null);
                      },
                      child: Text('타이머 끄기', style: TextStyle(color: textColor.withOpacity(0.5))),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _togglePlay(bool isPlaying) async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pp = context.read<PlayerProvider>();
    final isThisOne = pp.natureSoundName == widget.name;
    if (isThisOne && isPlaying) {
      await pp.pauseNatureSound();
    } else if (isThisOne && !isPlaying) {
      await pp.resumeNatureSound();
    } else if (widget.assetPath != null) {
      await pp.playNatureSound(widget.assetPath!, widget.name);
    }
  }

  void _showExitConfirmDialog(BuildContext context) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
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
                '파란소리를 종료하시겠어요?',
                style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                '지금 나가면 소리가 멈춰요.',
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
    late final String farewellAsset;
    switch (langCode) {
      case 'ko':
        farewellAsset = 'assets/farewell_ko_v3.mp3';
        break;
      case 'ja':
        farewellAsset = 'assets/farewell_ja.mp3';
        break;
      case 'zh':
        farewellAsset = 'assets/farewell_zh.mp3';
        break;
      default:
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

      await Future.delayed(const Duration(milliseconds: 900));
      entry.remove();
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('closeApp');
    });
  }

  void _showMixComingSoon() {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('여러 소리를 함께 섞는 믹스 기능은 곧 추가돼요.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final playerProvider = context.watch<PlayerProvider>();
    final isThisOne = playerProvider.natureSoundName == widget.name;
    final isPlaying = isThisOne && playerProvider.isPlaying;

    return Scaffold(
      backgroundColor: widget.color,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(_isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                      context.read<ThemeProvider>().setDarkMode(!isDarkMode);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
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
                                            ? Colors.black.withOpacity(0.35)
                                            : const Color(0xFF2C6BB3).withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
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
                                    margin: const EdgeInsets.only(bottom: 18),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.white24 : const Color(0xFFCBD9EC),
                                      borderRadius: BorderRadius.circular(2),
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
                                            Share.share('파란소리 자연소리로 편안한 시간 보내요 🌊\nhttps://play.google.com/store/apps/details?id=kr.ssing.catsong');
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
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: cardBg,
                                        border: Border.all(color: cardBorder),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDarkMode
                                                ? Colors.black.withOpacity(0.35)
                                                : const Color(0xFF2C6BB3).withOpacity(0.08),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
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
                                            ),
                                            child: const Icon(Icons.settings_outlined, color: Colors.white, size: 21),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('설정',
                                                    style: TextStyle(
                                                        color: isDarkMode ? Colors.white : navy,
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 2),
                                                Text('앱 환경을 설정할 수 있어요.',
                                                    style: TextStyle(color: subColor, fontSize: 11.5)),
                                              ],
                                            ),
                                          ),
                                        ],
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
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showExitConfirmDialog(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Icon(widget.icon, size: 70, color: Colors.white),
                    ),
                    const SizedBox(height: 28),
                    Text(widget.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(widget.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.6)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => _showCustomMinutesDialog(isDarkMode),
                    child: Column(
                      children: [
                        Icon(Icons.bedtime,
                            color: _sleepMinutes != null
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            size: 22),
                        const SizedBox(height: 4),
                        Text(_formatRemaining(),
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _togglePlay(isPlaying),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                          color: widget.color, size: 28),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showMixComingSoon,
                    child: Column(
                      children: [
                        Icon(Icons.graphic_eq_rounded, color: Colors.white.withOpacity(0.7), size: 22),
                        const SizedBox(height: 4),
                        Text('믹스', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}