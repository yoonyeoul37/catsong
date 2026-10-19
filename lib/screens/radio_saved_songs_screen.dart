import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/radio_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/paran_toast.dart';
import '../l10n/locale_holder.dart';

/// 저장한 곡 화면 (따로 열 때)
class RadioSavedSongsScreen extends StatelessWidget {
  const RadioSavedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: baseColor, size: 20),
        ),
        title: Text(tr.savedSongs,
            style: TextStyle(color: baseColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: const SafeArea(top: false, child: RadioSavedSongsList()),
    );
  }
}

/// 라디오에서 ♡ 누른 곡 목록 (해외 라디오 '저장한 곡' 탭에도 씀)
class RadioSavedSongsList extends StatefulWidget {
  const RadioSavedSongsList({super.key});

  @override
  State<RadioSavedSongsList> createState() => _RadioSavedSongsListState();
}

class _RadioSavedSongsListState extends State<RadioSavedSongsList> {
  @override
  void initState() {
    super.initState();
    context.read<RadioProvider>().loadSavedSongs();
  }

  static String _flag(String cc) {
    if (cc.length != 2) return '';
    return String.fromCharCodes(cc.toUpperCase().codeUnits.map((c) => c + 127397));
  }

  // 10월 11일 오후 3:12
  static String _when(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return tr.savedDate('${t.month}', '${t.day}', t.hour < 12 ? tr.am : tr.pm, '$h12:${t.minute.toString().padLeft(2, '0')}');
  }

  void _vibrate() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

  Future<void> _youtube(String title) async {
    final uri = Uri.https('www.youtube.com', '/results', {'search_query': title});
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) showParanToast(context, tr.youtubeOpenFailed, error: true);
    }
  }

  void _remove(Map<String, dynamic> m) {
    final radio = context.read<RadioProvider>();
    final i = radio.removeSavedSong(m);
    showParanToast(context, tr.savedSongDeleted,
        actionLabel: tr.revertChange, onAction: () => radio.restoreSavedSong(i, m));
  }

  void _openSheet(Map<String, dynamic> m, Color baseColor, bool isDark) {
    _vibrate();
    final title = (m['title'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2A2724) : const Color(0xFFF7F3EA),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        Widget item(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(icon, size: 22, color: color ?? baseColor.withOpacity(0.75)),
              title: Text(label,
                  style: TextStyle(color: color ?? baseColor, fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () {
                _vibrate();
                Navigator.pop(ctx);
                onTap();
              },
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: baseColor, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                item(Icons.play_circle_outline_rounded, tr.searchYoutube, () => _youtube(title)),
                item(Icons.copy_rounded, tr.copySongName, () {
                  Clipboard.setData(ClipboardData(text: title));
                  showParanToast(context, tr.songNameCopied);
                }),
                item(Icons.delete_outline_rounded, tr.clearAction, () => _remove(m), color: const Color(0xFFE05A4F)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<RadioProvider>().savedSongs;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDark ? Colors.white : Colors.black;
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.music_note_2, color: baseColor.withOpacity(0.25), size: 40),
            const SizedBox(height: 14),
            Text(tr.savedSongsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 14, height: 1.5)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 80 + MediaQuery.of(context).padding.bottom),
      itemCount: songs.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: baseColor.withOpacity(0.16)),
      itemBuilder: (context, i) {
        final m = songs[i];
        final flag = _flag((m['cc'] ?? '').toString());
        final sub = [
          (m['station'] ?? '').toString(),
          _when((m['at'] ?? '').toString()),
        ].where((t) => t.isNotEmpty).join(' · ');
        return Dismissible(
          key: ValueKey('${m['at']}|${m['title']}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE05A4F)),
          ),
          onDismissed: (_) => _remove(m),
          child: InkWell(
            onTap: () => _openSheet(m, baseColor, isDark),
            splashColor: baseColor.withOpacity(0.04),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: flag.isEmpty
                        ? Icon(CupertinoIcons.music_note, size: 20, color: baseColor.withOpacity(0.45))
                        : Text(flag, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((m['title'] ?? '').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: baseColor, fontSize: 15.5, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                        if (sub.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert_rounded, size: 20, color: baseColor.withOpacity(0.3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
