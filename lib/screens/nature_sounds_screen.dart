import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/player_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';
import 'radio_home_screen.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../main.dart' show globalAudioHandler;

class NatureSoundsScreen extends StatefulWidget {
  const NatureSoundsScreen({super.key});

  @override
  State<NatureSoundsScreen> createState() => _NatureSoundsScreenState();
}

class _NatureSound {
  final String name;
  final IconData icon;
  final String emoji;
  final String description;
  final String? assetPath;
  const _NatureSound({
    required this.name,
    required this.icon,
    required this.emoji,
    required this.description,
    this.assetPath,
  });
  bool get isReady => assetPath != null;
}

class _NatureSoundsScreenState extends State<NatureSoundsScreen> {
  Timer? _sleepTimer;
  int? _sleepMinutes;
  _NatureSound? _selectedSound;

  static const _sounds = <_NatureSound>[
    _NatureSound(
      name: '파도소리',
      icon: Icons.waves,
      emoji: '🌊',
      description: '규칙적인 파도 소리는 마음을 차분히 가라앉혀 깊은 휴식과 수면에 도움을 줘요',
      assetPath: 'assets/wave_sound.mp3',
    ),
    _NatureSound(
      name: '빗소리',
      icon: Icons.water_drop_outlined,
      emoji: '☔',
      description: '일정한 빗소리는 집중력을 높이고 불안한 마음을 편안하게 다독여줘요',
      assetPath: 'assets/rain_sound.mp3',
    ),
    _NatureSound(
      name: '새소리',
      icon: Icons.forest_outlined,
      emoji: '🐦',
      description: '청아한 새소리는 스트레스를 줄이고 상쾌한 기분을 만들어줘요',
      assetPath: 'assets/bird_sound.mp3',
    ),
    _NatureSound(
      name: '모닥불',
      icon: Icons.local_fire_department_outlined,
      emoji: '🔥',
      description: '타닥타닥 장작 타는 소리는 아늑한 분위기로 깊은 이완을 도와줘요',
      assetPath: 'assets/campfire_sound.mp3',
    ),
    _NatureSound(
      name: '시냇물',
      icon: Icons.water_outlined,
      emoji: '💧',
      description: '졸졸 흐르는 시냇물 소리는 마음을 편안하게 하고 잡생각을 줄여줘요',
      assetPath: 'assets/stream_sound.mp3',
    ),
  ];

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('재생 오류: $e')),
        );
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
    late final String smallText;
    late final String farewellAsset;
    switch (langCode) {
      case 'ko':
        smallText = '파란소리와 함께해 주셔서 고마워요.\n다음에 또 좋은 소리로 만나요!';
        farewellAsset = 'assets/farewell_ko.mp3';
        break;
      case 'ja':
        smallText = 'Paransoriと一緒にいてくれてありがとう。\nまた素敵な音でお会いしましょう!';
        farewellAsset = 'assets/farewell_ja.mp3';
        break;
      case 'zh':
        smallText = '感谢您与Paransori相伴。\n下次再见，聆听更多美好的声音!';
        farewellAsset = 'assets/farewell_zh.mp3';
        break;
      default:
        smallText = 'Thank you for being with Paransori.\nSee you again with great sounds!';
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
          child: Container(
            color: Colors.black.withOpacity(0.95 * value),
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 300,
                  height: 130,
                  child: CustomPaint(
                    painter: _FarewellTextPainter(opacity: value, smallText: smallText),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(value),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 5500), () async {
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
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final playerProvider = context.watch<PlayerProvider>();

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
        title: Text(
          '자연소리',
          style: TextStyle(color: baseColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          _CircleIconButton(
            baseColor: baseColor,
            icon: Icons.queue_music,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            baseColor: baseColor,
            icon: Icons.radio_outlined,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RadioHomeScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            baseColor: _sleepMinutes != null ? primaryColor : baseColor,
            icon: Icons.bedtime,
            onTap: () => _showSleepTimerDialog(baseColor, isDarkMode),
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            baseColor: baseColor,
            icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              context.read<ThemeProvider>().setDarkMode(!isDarkMode);
            },
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            baseColor: baseColor,
            icon: Icons.more_vert,
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
                          Share.share('파란소리 자연소리로 편안한 시간 보내요 🌊\nhttps://play.google.com/store/apps/details?id=kr.ssing.catsong');
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
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.construction_outlined, color: baseColor.withOpacity(0.5), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '리뉴얼중입니다',
                    style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedSound != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedSound!.emoji} ${_selectedSound!.name}',
                      style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedSound!.description,
                      style: TextStyle(color: baseColor.withOpacity(0.85), fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sounds.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final sound = _sounds[index];
                final isThisOne = playerProvider.natureSoundName == sound.name;
                final isPlaying = isThisOne && playerProvider.isPlaying;
                return GestureDetector(
                  onTap: sound.isReady ? () => _toggleSound(sound, isPlaying) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPlaying ? primaryColor.withOpacity(0.12) : baseColor.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: isPlaying ? Border.all(color: primaryColor, width: 1.5) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPlaying ? Icons.pause : sound.icon,
                          color: sound.isReady
                              ? (isPlaying ? primaryColor : baseColor.withOpacity(0.7))
                              : baseColor.withOpacity(0.25),
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sound.name,
                          style: TextStyle(
                            color: sound.isReady
                                ? (isPlaying ? primaryColor : baseColor.withOpacity(0.8))
                                : baseColor.withOpacity(0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!sound.isReady) ...[
                          const SizedBox(height: 2),
                          Text('준비중', style: TextStyle(color: baseColor.withOpacity(0.25), fontSize: 9)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: baseColor.withOpacity(0.08))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    playerProvider.natureSoundName != null
                        ? '${playerProvider.natureSoundName} 재생 중'
                        : '재생 중인 소리 없음',
                    style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showExitConfirmDialog(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Icon(Icons.power_settings_new, color: Color(0xFFE8877E), size: 16),
                      const SizedBox(width: 4),
                      const Text('종료', style: TextStyle(color: Color(0xFFE8877E), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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