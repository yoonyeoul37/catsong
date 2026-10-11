# -*- coding: utf-8 -*-
# 라디오에서 들은 곡 저장: 상세 화면 ♪ 줄 ♡ · 해외 라디오 '저장한 곡' 탭 · 새 화면 파일
import sys, glob, os, shutil

def find(name):
    hits = glob.glob(os.path.join('lib', '**', name), recursive=True)
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def prepare(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    name = os.path.basename(path)
    if done_mark in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); return None
    for label, old, new in edits:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

NEW_SCREEN = r"""import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/radio_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/paran_toast.dart';

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
        title: Text('저장한 곡',
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
    return '${t.month}월 ${t.day}일 ${t.hour < 12 ? '오전' : '오후'} $h12:${t.minute.toString().padLeft(2, '0')}';
  }

  void _vibrate() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

  Future<void> _youtube(String title) async {
    final uri = Uri.https('www.youtube.com', '/results', {'search_query': title});
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) showParanToast(context, '유튜브를 열지 못했어요', error: true);
    }
  }

  void _remove(Map<String, dynamic> m) {
    final radio = context.read<RadioProvider>();
    final i = radio.removeSavedSong(m);
    showParanToast(context, '저장한 곡에서 지웠어요',
        actionLabel: '되돌리기', onAction: () => radio.restoreSavedSong(i, m));
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
                item(Icons.play_circle_outline_rounded, '유튜브에서 찾기', () => _youtube(title)),
                item(Icons.copy_rounded, '곡 이름 복사', () {
                  Clipboard.setData(ClipboardData(text: title));
                  showParanToast(context, '곡 이름을 복사했어요');
                }),
                item(Icons.delete_outline_rounded, '지우기', () => _remove(m), color: const Color(0xFFE05A4F)),
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
            Text('방송에서 나온 곡 옆 ♡를 누르면\n여기에 모여요',
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
                      borderRadius: BorderRadius.circular(46 * 0.2),
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
"""

prov = [
('곡 저장 불러오기 (앱 켤 때)',
"""    _loadFromPrefs();
""",
"""    _loadFromPrefs();
    loadSavedSongs();
"""),
('곡 저장 기능',
"""  String? get streamTitle => _streamTitle;
""",
"""  String? get streamTitle => _streamTitle;

  // ── 저장한 곡 (라디오에서 ♡ 누른 곡) ──
  static const _keySongs = 'radio_saved_songs';
  List<Map<String, dynamic>> _savedSongs = [];
  bool _songsLoaded = false;
  List<Map<String, dynamic>> get savedSongs => _savedSongs;

  Future<void> loadSavedSongs() async {
    if (_songsLoaded) return;
    _songsLoaded = true;
    final p = await SharedPreferences.getInstance();
    _savedSongs = (p.getStringList(_keySongs) ?? [])
        .map((s) {
          try {
            return json.decode(s) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
    notifyListeners();
  }

  bool isSongSaved(String title) => _savedSongs.any((m) => m['title'] == title);

  /// ♡: 곡 저장 (이미 있으면 빼기). 저장했으면 true
  Future<bool> toggleSavedSong(String title, RadioStation station) async {
    await loadSavedSongs();
    final i = _savedSongs.indexWhere((m) => m['title'] == title);
    final saved = i < 0;
    if (saved) {
      _savedSongs.insert(0, {
        'title': title,
        'station': station.name,
        'cc': station.countryCode ?? '',
        'at': DateTime.now().toIso8601String(),
      });
      if (_savedSongs.length > 300) _savedSongs = _savedSongs.sublist(0, 300);
    } else {
      _savedSongs.removeAt(i);
    }
    notifyListeners();
    await _saveSongs();
    return saved;
  }

  /// 지운 자리 번호를 돌려줌 (되돌리기용)
  int removeSavedSong(Map<String, dynamic> song) {
    final i = _savedSongs.indexOf(song);
    if (i >= 0) {
      _savedSongs.removeAt(i);
      notifyListeners();
      _saveSongs();
    }
    return i;
  }

  void restoreSavedSong(int index, Map<String, dynamic> song) {
    if (_savedSongs.contains(song)) return;
    _savedSongs.insert(index.clamp(0, _savedSongs.length), song);
    notifyListeners();
    _saveSongs();
  }

  Future<void> _saveSongs() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_keySongs, _savedSongs.map((m) => json.encode(m)).toList());
  }
"""),
]

player = [
('♪ 줄 오른쪽 ♡',
"""                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Builder(builder: (ctx) {
                                        final smsNumber""",
"""                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              // ♡ 누르면 '저장한 곡'에 넣기
                                              Builder(builder: (ctx) {
                                                final saved = radioProvider.isSongSaved(radioProvider.streamTitle!);
                                                return GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () async {
                                                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                                    final title = radioProvider.streamTitle;
                                                    if (title == null || title.isEmpty) return;
                                                    final now = await radioProvider.toggleSavedSong(title, current);
                                                    if (!context.mounted) return;
                                                    showParanToast(context, now ? '저장한 곡에 넣었어요' : '저장한 곡에서 뺐어요');
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.fromLTRB(8, 2, 2, 2),
                                                    child: HeartPop(
                                                      on: saved,
                                                      child: Icon(
                                                        saved ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                                        size: 17,
                                                        color: saved ? const Color(0xFFE05A4F) : Colors.white.withOpacity(0.85),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      Builder(builder: (ctx) {
                                        final smsNumber"""),
]

screen = [
('새 화면 불러오기',
"import '../widgets/radio_dice.dart';\n",
"import '../widgets/radio_dice.dart';\nimport 'radio_saved_songs_screen.dart';\n"),
('탭 종류',
"enum _ViewMode { all, broadcaster, region, recent, favorite }",
"enum _ViewMode { all, broadcaster, region, recent, favorite, saved }"),
('저장한 곡 목록',
"    if (_mode == _ViewMode.broadcaster) {",
"    if (_mode == _ViewMode.saved) return const RadioSavedSongsList();\n    if (_mode == _ViewMode.broadcaster) {"),
('저장한 곡 탭',
"                    _toggleButton('최근청취', _ViewMode.recent, baseColor, isDarkMode),\n",
"                    _toggleButton('최근청취', _ViewMode.recent, baseColor, isDarkMode),\n                    _toggleButton('저장한 곡', _ViewMode.saved, baseColor, isDarkMode),\n"),
]

jobs = [
    prepare(find('radio_provider.dart'), prov, '_keySongs'),
    prepare(find('radio_player_screen.dart'), player, 'toggleSavedSong'),
    prepare(find('radio_country_stations_screen.dart'), screen, 'RadioSavedSongsList'),
]
# 모두 문제없을 때만 저장
for r in jobs:
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak6')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))

screens_dir = os.path.dirname(find('radio_country_stations_screen.dart'))
new_path = os.path.join(screens_dir, 'radio_saved_songs_screen.dart')
if os.path.exists(new_path):
    print('✔ radio_saved_songs_screen.dart: 이미 있어요')
else:
    open(new_path, 'w', encoding='utf-8', newline='\r\n').write(NEW_SCREEN)
    print('✔ radio_saved_songs_screen.dart: 새로 만들었어요')
print('끝! (원본은 .bak6)')
