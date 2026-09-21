import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/sound_mix_provider.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';

class SoundMixScreen extends StatelessWidget {
  const SoundMixScreen({super.key});

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

  void _showSongPicker(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final baseColor = isDarkMode ? Colors.white : Colors.black;
        final songs = musicProvider.allSongs;
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('노래 선택',
                        style: TextStyle(
                            color: baseColor, fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: songs.isEmpty
                      ? Center(
                      child: Text('내 음악이 없어요',
                          style: TextStyle(color: baseColor.withOpacity(0.4))))
                      : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
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
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media')
                              .invokeMethod('vibrate');
                          context.read<SoundMixProvider>().setMusicSong(song);
                          Navigator.pop(ctx);
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

    final activeLabels = <String>[
      for (final entry in SoundMixProvider.natureAssets.keys)
        if ((mix.volumeOf(entry)) > 0) entry,
      if (mix.volumeOf('music') > 0 && mix.musicSong != null) mix.musicSong!.titleDisplay,
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
                                  child: GestureDetector(
                                    onTap: () => _showSongPicker(context),
                                    child: Text(
                                      mix.musicSong?.titleDisplay ?? '내 음악에서 선택하기',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: mix.musicSong != null
                                              ? baseColor
                                              : primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                if (mix.musicSong != null)
                                  GestureDetector(
                                    onTap: () => _showSongPicker(context),
                                    child: Text('변경',
                                        style: TextStyle(color: primaryColor, fontSize: 12.5)),
                                  )
                                else
                                  Text('${(mix.volumeOf('music') * 100).round()}%',
                                      style: TextStyle(color: baseColor.withOpacity(0.3), fontSize: 12.5)),
                              ],
                            ),
                            if (mix.musicSong != null)
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
                                  value: mix.volumeOf('music'),
                                  onChanged: (v) =>
                                      context.read<SoundMixProvider>().setVolume('music', v),
                                ),
                              ),
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
                              Text(activeLabels.join(' · '),
                                  style: TextStyle(
                                      color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
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
}