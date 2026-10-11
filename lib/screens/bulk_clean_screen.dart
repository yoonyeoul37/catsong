import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/song_title_cleaner.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBackupKey = 'bulk_clean_backup'; // 마지막으로 한꺼번에 정리하기 전의 원래 제목·가수

/// 마지막 한꺼번에 정리를 되돌리기. 되돌린 곡 수
Future<int> undoBulkClean(MusicProvider music) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kBackupKey);
  if (raw == null) return 0;
  var n = 0;
  for (final e in (jsonDecode(raw) as List).cast<Map>()) {
    final uri = e['uri'] as String?;
    final match = music.allSongs.where((s) => s.uri == uri);
    if (match.isEmpty) continue;
    await music.updateSongInfo(match.first,
        title: (e['title'] ?? '') as String, artist: (e['artist'] ?? '') as String);
    n++;
  }
  await prefs.remove(_kBackupKey);
  return n;
}

/// 곡 정보 한꺼번에 정리: 지저분한 곡만 골라서 "원래 → 정리 후"를 보여주고, 체크한 곡만 바꿈
class BulkCleanScreen extends StatefulWidget {
  const BulkCleanScreen({super.key});

  @override
  State<BulkCleanScreen> createState() => _BulkCleanScreenState();
}

class _CleanItem {
  final Song song;
  final SongClean clean;
  bool checked = true;
  _CleanItem(this.song, this.clean);
}

class _BulkCleanScreenState extends State<BulkCleanScreen> {
  static const _blue = Color(0xFF2589E8);
  List<_CleanItem> _items = [];
  bool _ready = false; // 곡 정보를 다 읽은 뒤에 검사했는지
  bool _working = false;
  int _done = 0;
  int _backupCount = 0; // 되돌릴 수 있는 곡 수 (마지막 정리)

  @override
  void initState() {
    super.initState();
    // 되돌릴 수 있는 게 있는지
    SharedPreferences.getInstance().then((p) {
      final raw = p.getString(_kBackupKey);
      if (raw != null && mounted) setState(() => _backupCount = (jsonDecode(raw) as List).length);
    });
  }

  /// 곡 정보를 다 읽은 뒤에 정리할 곡 찾기
  void _scan(MusicProvider music) {
    // 내 노래 목록에 있는 가수 이름들 → "노래 - 가수" 순서도 알아봄
    final known = music.artists
        .map((x) => x.name.toLowerCase().trim())
        .where((n) => n.isNotEmpty && !n.contains('unknown') && n != '알 수 없는 아티스트')
        .toSet();
    final list = <_CleanItem>[];
    for (final s in music.allSongs) {
      if (music.isCallRecordingPath(s.uri)) continue; // 녹음은 빼기
      final c = SongTitleCleaner.clean(s.titleDisplay, s.artistDisplay, knownArtists: known);
      if (c.title != s.titleDisplay || c.artist != s.artistDisplay) list.add(_CleanItem(s, c));
    }
    _items = list;
    _ready = true;
  }

  Future<void> _undo() async {
    if (_working) return;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final music = context.read<MusicProvider>();
    final navigator = Navigator.of(context);
    setState(() => _working = true);
    final n = await undoBulkClean(music);
    if (!mounted) return;
    showActionFeedback(context, type: ActionFeedbackType.edited, message: '$n곡을 되돌렸어요');
    navigator.pop();
  }

  int get _checkedCount => _items.where((e) => e.checked).length;

  Future<void> _apply() async {
    final targets = _items.where((e) => e.checked).toList();
    if (targets.isEmpty || _working) return;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final music = context.read<MusicProvider>();
    final navigator = Navigator.of(context);
    setState(() {
      _working = true;
      _done = 0;
    });
    // 정리하기 전 원래 제목·가수를 저장 → 되돌리기용
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kBackupKey,
        jsonEncode([
          for (final it in targets) {'uri': it.song.uri, 'title': it.song.title, 'artist': it.song.artist}
        ]));
    for (final it in targets) {
      await music.updateSongInfo(it.song, title: it.clean.title, artist: it.clean.artist);
      if (!mounted) return;
      setState(() => _done++);
    }
    final appCtx = Navigator.of(context, rootNavigator: true).context;
    navigator.pop();
    // 되돌리기 버튼이 있어서 하단 알림으로
    showActionFeedbackWithUndo(appCtx, message: '${targets.length}곡을 정리했어요', onUndo: () async {
      final n = await undoBulkClean(music);
      showActionFeedback(appCtx, type: ActionFeedbackType.edited, message: '$n곡을 되돌렸어요');
    });
  }

  /// 마지막 정리 되돌리기 카드
  Widget _undoCard(Color card, Color ink, Color sub) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: sub, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('마지막에 정리한 $_backupCount곡',
                style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: _working ? null : _undo,
            style: TextButton.styleFrom(foregroundColor: ink),
            child: const Text('되돌리기', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF32302C) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    // 곡 정보를 아직 읽는 중이면 기다리기 (파일 이름 상태로 검사하면 잘못 나와서)
    final music = context.watch<MusicProvider>();
    if (music.isLoading || music.metaLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: ink, size: 20),
          ),
          title: Text('음악 정보 일괄 정리',
              style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: ink),
              ),
              const SizedBox(height: 16),
              Text('곡 정보를 읽는 중이에요', style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('잠시만 기다려 주세요', style: TextStyle(color: sub, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    if (!_ready) _scan(music);
    final allChecked = _items.isNotEmpty && _items.every((e) => e.checked);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: _working ? null : () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: ink, size: 20),
        ),
        title: Text('음악 정보 일괄 정리',
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          if (_items.isNotEmpty && !_working)
            TextButton(
              onPressed: () => setState(() {
                for (final e in _items) {
                  e.checked = !allChecked;
                }
              }),
              style: TextButton.styleFrom(foregroundColor: ink),
              child: Text(allChecked ? '전체 해제' : '전체 선택',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _items.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: sub, size: 40),
            const SizedBox(height: 14),
            Text('정리할 곡이 없어요',
                style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('모든 곡의 제목·가수가 깔끔해요', style: TextStyle(color: sub, fontSize: 13)),
            if (_backupCount > 0) ...[
              const SizedBox(height: 24),
              _undoCard(card, ink, sub),
            ],
          ],
        ),
      )
          : Column(
        children: [
          if (_backupCount > 0) _undoCard(card, ink, sub),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: sub, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('정리할 수 있는 곡 ${_items.length}개 · 체크한 곡만 바꿔요',
                      style: TextStyle(color: sub, fontSize: 13)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final it = _items[i];
                return Material(
                  color: card,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _working ? null : () => setState(() => it.checked = !it.checked),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 14, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: it.checked,
                            activeColor: ink,
                            checkColor: bg,
                            onChanged: _working ? null : (v) => setState(() => it.checked = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 원래 (연하게)
                                  Text('${it.song.titleDisplay} · ${it.song.artistDisplay}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: sub, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                  const SizedBox(height: 6),
                                  // 정리 후 (진하게)
                                  Text(it.clean.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(it.clean.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: sub, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_checkedCount == 0 || _working) ? null : _apply,
              style: ElevatedButton.styleFrom(
                // 큰 버튼: 먹색 (다크 모드는 크림색)
                backgroundColor: ink,
                foregroundColor: bg,
                disabledBackgroundColor: ink.withOpacity(0.35),
                disabledForegroundColor: bg,
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _working ? '정리하는 중… $_done / $_checkedCount' : '$_checkedCount곡 정리하기',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}