import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';

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