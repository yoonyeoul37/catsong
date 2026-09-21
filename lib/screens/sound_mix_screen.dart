import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/sound_mix_provider.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import 'settings_screen.dart';
import 'package:just_audio/just_audio.dart';

class SoundMixScreen extends StatefulWidget {
  const SoundMixScreen({super.key});

  @override
  State<SoundMixScreen> createState() => _SoundMixScreenState();
}

class _SoundMixScreenState extends State<SoundMixScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<PlayerProvider>();
      if (pp.natureSoundName != null) {
        pp.stopNatureSound();
      }
    });
  }

  static const _natureIcons = <String, IconData>{
    '파도소리': Icons.waves,
    '빗소리': Icons.water_drop_outlined,
    '새소리': Icons.forest_outlined,
    '모닥불': Icons.local_fire_department_outlined,
    '시냇물': Icons.water_outlined,
  };

  static const _natureColors = <String, Color>{
    '파도소리': Color(0xFF4A7BA6),
    '빗소리': Color(0xFF3E5A78),
    '새소리': Color(0xFF5C7A5E),
    '모닥불': Color(0xFFC97B4A),
    '시냇물': Color(0xFF2C6BB3),
  };

  void _showTimerPicker(BuildContext context) {
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
                        final totalMinutes = picked.inMinutes;
                        Navigator.pop(ctx);
                        if (totalMinutes > 0) {
                          context.read<SoundMixProvider>().setSleepTimer(totalMinutes);
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
                if (context.read<SoundMixProvider>().sleepMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<SoundMixProvider>().setSleepTimer(null);
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

  void _showSongPicker(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final baseColor = isDarkMode ? Colors.white : Colors.black;
        final primaryColor = Theme.of(ctx).colorScheme.primary;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final mix = ctx.watch<SoundMixProvider>();
            final query = searchController.text.trim().toLowerCase();
            final songs = query.isEmpty
                ? musicProvider.allSongs
                : musicProvider.allSongs.where((s) =>
            s.titleDisplay.toLowerCase().contains(query) ||
                s.artistDisplay.toLowerCase().contains(query)).toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.65,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text('노래 선택',
                              style: TextStyle(
                                  color: baseColor, fontSize: 17, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('완료', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        style: TextStyle(color: baseColor),
                        decoration: InputDecoration(
                          hintText: '제목, 아티스트로 검색',
                          hintStyle: TextStyle(color: baseColor.withOpacity(0.35)),
                          prefixIcon: Icon(Icons.search, color: baseColor.withOpacity(0.4), size: 20),
                          filled: true,
                          fillColor: baseColor.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: songs.isEmpty
                          ? Center(
                          child: Text(
                              query.isEmpty ? '내 음악이 없어요' : '검색 결과가 없어요',
                              style: TextStyle(color: baseColor.withOpacity(0.4))))
                          : ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          final selected = mix.isSongSelected(song);
                          return ListTile(
                            leading: Icon(Icons.music_note_rounded,
                                color: baseColor.withOpacity(0.6)),
                            title: Text(song.titleDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: baseColor)),
                            subtitle: Text(song.artistDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: baseColor.withOpacity(0.5))),
                            trailing: Icon(
                              selected ? Icons.check_circle : Icons.circle_outlined,
                              color: selected ? primaryColor : baseColor.withOpacity(0.25),
                            ),
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media')
                                  .invokeMethod('vibrate');
                              ctx.read<SoundMixProvider>().toggleSong(song);
                            },
                          );
                        },
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

  Widget _buildSliderRow(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required double value,
        required ValueChanged<double> onChanged,
        required Color baseColor,
      }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final percent = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Text('$percent%',
                  style: TextStyle(
                      color: percent > 0 ? primaryColor : baseColor.withOpacity(0.3),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: primaryColor,
              inactiveTrackColor: baseColor.withOpacity(0.08),
              thumbColor: primaryColor,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF17140F) : const Color(0xFFEDE7DA);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mix = context.watch<SoundMixProvider>();

    final activeNatureLabels = <String>[
      for (final entry in SoundMixProvider.natureAssets.keys)
        if ((mix.volumeOf(entry)) > 0) entry,
    ];
    final selectedSongs = mix.selectedSongs;
    final activeLabels = <String>[
      ...activeNatureLabels,
      ...selectedSongs.map((s) => s.titleDisplay),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: baseColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('나만의 소리 믹스',
            style: TextStyle(color: baseColor, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          _iconBtn(
            icon: Icons.home_rounded,
            baseColor: baseColor,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(width: 6),
          _iconBtn(
            icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            baseColor: baseColor,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              context.read<ThemeProvider>().setDarkMode(!isDarkMode);
            },
          ),
          const SizedBox(width: 6),
          _iconBtn(
            icon: Icons.settings_outlined,
            baseColor: baseColor,
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 6),
          _iconBtn(
            icon: Icons.power_settings_new_rounded,
            baseColor: baseColor,
            onTap: () => _showExitConfirmDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('여러 소리를 조합하여\n나만의 힐링 사운드를 만들어보세요.',
                  style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final entry in SoundMixProvider.natureAssets.keys)
                        _buildSliderRow(
                          context,
                          label: entry,
                          icon: _natureIcons[entry]!,
                          color: _natureColors[entry]!,
                          value: mix.volumeOf(entry),
                          baseColor: baseColor,
                          onChanged: (v) => context.read<SoundMixProvider>().setVolume(entry, v),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.music_note_rounded,
                                      color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('음악',
                                      style: TextStyle(
                                          color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                                GestureDetector(
                                  onTap: () => _showSongPicker(context),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline, color: primaryColor, size: 18),
                                      const SizedBox(width: 4),
                                      Text('추가', style: TextStyle(color: primaryColor, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (selectedSongs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 44),
                                child: Text('선택된 노래가 없어요',
                                    style: TextStyle(color: baseColor.withOpacity(0.35), fontSize: 12.5)),
                              )
                            else
                              ...selectedSongs.map((song) => Padding(
                                padding: const EdgeInsets.only(top: 8, left: 44),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                          '${song.titleDisplay} · ${song.artistDisplay}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: baseColor, fontSize: 13)),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.read<SoundMixProvider>().toggleSong(song),
                                      child: Icon(Icons.close,
                                          size: 16, color: baseColor.withOpacity(0.35)),
                                    ),
                                  ],
                                ),
                              )),
                          ],
                        ),
                      ),
                      if (activeLabels.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('지금 섞고 있는 소리',
                                  style: TextStyle(
                                      color: baseColor.withOpacity(0.4), fontSize: 11.5)),
                              const SizedBox(height: 4),
                              if (activeNatureLabels.isNotEmpty)
                                Text(activeNatureLabels.join(' · '),
                                    style: TextStyle(
                                        color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
                              if (selectedSongs.isNotEmpty) ...[
                                if (activeNatureLabels.isNotEmpty) const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.music_note_rounded,
                                        size: 14, color: primaryColor),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                          selectedSongs.map((s) => s.titleDisplay).join(' · '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showTimerPicker(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bedtime,
                          color: mix.sleepMinutes != null ? primaryColor : baseColor.withOpacity(0.5),
                          size: 18),
                      const SizedBox(width: 8),
                      Text(mix.sleepMinutes != null ? '${mix.remainingLabel} 후 자동 정지' : '수면 타이머 설정',
                          style: TextStyle(
                              color: mix.sleepMinutes != null ? primaryColor : baseColor.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: baseColor.withOpacity(0.3), size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: activeLabels.isEmpty
                      ? null
                      : () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    if (mix.isPlaying) {
                      context.read<SoundMixProvider>().stopAll();
                    } else {
                      context.read<SoundMixProvider>().playAll();
                    }
                  },
                  icon: Icon(mix.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(mix.isPlaying ? '믹스 정지하기' : '믹스 재생하기',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required Color baseColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: baseColor.withOpacity(0.07), shape: BoxShape.circle),
        child: Icon(icon, color: baseColor, size: 17),
      ),
    );
  }

  void _showExitConfirmDialog(BuildContext context) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
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
                '지금 나가면 소리가 멈춰요.',
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
        await context.read<SoundMixProvider>().stopAll();
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 900));
      entry.remove();
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('closeApp');
    });
  }
}