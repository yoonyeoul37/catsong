import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/call_recording.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'ringtone_screen.dart';
import 'voice_recorder_screen.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_toast.dart';

/// 통화 녹음 화면 (일반 음악과 따로)
class CallRecordingsScreen extends StatefulWidget {
  const CallRecordingsScreen({super.key});

  @override
  State<CallRecordingsScreen> createState() => _CallRecordingsScreenState();
}

class _CallRecordingsScreenState extends State<CallRecordingsScreen> {
  static const _blue = Color(0xFF2589E8); // 파란색은 "지금 재생 중"에만
  static const _ink = Color(0xFF3A352D); // 선택·강조는 차분한 먹색
  bool _voice = false; // false = 통화 녹음, true = 음성 녹음
  int _sort = 0; // 0 최신순, 1 오래된순, 2 긴 통화순
  bool _searching = false;
  String _query = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {}; // 여러 개 선택 (파일 경로)
  bool _selectMode = false; // ⋮ → 선택하기로 켰을 때
  bool get _selecting => _selectMode || _selected.isNotEmpty;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final music = context.read<MusicProvider>();
      // 녹음 중에 앱이 꺼져서 저장 못 한 녹음이 있으면 되살리기
      final n = await recoverUnsavedRecordings();
      if (!mounted) return;
      music.loadCallRecordings();
      if (n > 0) {
        showParanToast(context, '중간에 끊긴 녹음 $n개를 되살렸어요');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final player = context.watch<PlayerProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDark ? Colors.white : Colors.black;
    final everything = music.callRecordings;
    final all = everything.where((r) => r.isVoice == _voice).toList();

    // 차분한 색 (라이트: 베이지·갈색 / 다크: 반투명 흰색)
    final soft = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2DACB);
    final muted = isDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    final selBg = isDark ? Colors.white.withOpacity(0.9) : _ink;
    final selFg = isDark ? const Color(0xFF24221F) : Colors.white;
    var list = all;
    // 검색 (이름·번호·내가 바꾼 제목)
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((r) => music.recordingTitle(r).toLowerCase().contains(q) || r.name.toLowerCase().contains(q))
          .toList();
    }
    // 정렬
    list = List.of(list);
    if (_sort == 1) {
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } else if (_sort == 2) {
      list.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    }
    // 지금 재생 중인 녹음 (위에 작은 재생 막대)
    CallRecording? playing;
    for (final r in everything) {
      if (r.path == player.currentSong?.uri) playing = r;
    }
    // 바꾼 제목으로 재생 (미니플레이어·재생화면에도 바꾼 제목이 나오게)
    final songs = <Song>[
      for (var i = 0; i < list.length; i++) list[i].toSong(i, title: music.recordingTitle(list[i]))
    ];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // 제목 (여러 개 선택 중이면 선택 막대)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
                child: _selecting
                    ? Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        setState(() {
                          _selected.clear();
                          _selectMode = false;
                        });
                      },
                      icon: Icon(Icons.close, color: baseColor),
                    ),
                    Text('${_selected.length}개 선택',
                        style: TextStyle(color: baseColor, fontSize: 15, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        setState(() {
                          if (_selected.length == list.length) {
                            _selected.clear();
                            _selectMode = false; // 다 풀면 선택 끝
                          } else {
                            _selected
                              ..clear()
                              ..addAll(list.map((r) => r.path));
                          }
                        });
                      },
                      child: Text(_selected.length == list.length ? '선택 해제' : '전체 선택',
                          style: TextStyle(color: baseColor.withOpacity(0.75))),
                    ),
                    // (공유·잠금·삭제는 화면 아래 고정 버튼으로)
                  ],
                )
                    : Row(
                  children: [
                    Icon(Icons.mic_none, color: baseColor.withOpacity(0.55), size: 18),
                    const SizedBox(width: 6),
                    Text('녹음',
                        style: TextStyle(
                            color: baseColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(width: 8),
                    Text('(${everything.length})',
                        style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 13)),
                    const Spacer(),
                    // 지금 정렬 (누르면 바로 아래 작은 카드)
                    PopupMenuButton<int>(
                      tooltip: '정렬',
                      position: PopupMenuPosition.under,
                      onSelected: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _sort = v);
                      },
                      itemBuilder: (_) => [
                        for (final (v, label) in const [(0, '최신순'), (1, '오래된순'), (2, '긴 통화순')])
                          PopupMenuItem<int>(
                            value: v,
                            height: 42,
                            child: Row(
                              children: [
                                Text(label,
                                    style: TextStyle(fontWeight: _sort == v ? FontWeight.w700 : FontWeight.w400)),
                                const Spacer(),
                                if (_sort == v)
                                  const Icon(Icons.check_rounded, size: 17, color: Color(0xFF2589E8)),
                              ],
                            ),
                          ),
                      ],
                      // 바탕 없이 회색 글씨 + ▾ 만
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(const ['최신순', '오래된순', '긴 통화순'][_sort],
                                style: TextStyle(
                                    color: baseColor.withOpacity(0.5), fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Icon(Icons.keyboard_arrow_down_rounded, color: baseColor.withOpacity(0.5), size: 16),
                          ],
                        ),
                      ),
                    ),
                    // 검색
                    IconButton(
                      onPressed: () => setState(() {
                        _searching = !_searching;
                        if (!_searching) {
                          _query = '';
                          _searchCtrl.clear();
                        }
                      }),
                      icon: Icon(_searching ? Icons.search_off : Icons.search,
                          color: baseColor.withOpacity(0.5), size: 21),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    ),
                    // ⋮ 정렬 · 선택하기 · 전체 삭제 → 아래에서 올라오는 창
                    IconButton(
                      onPressed: () => _showMoreSheet(list, isDark),
                      icon: Icon(Icons.more_vert, color: baseColor.withOpacity(0.55), size: 21),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    ),
                  ],
                ),
              ),
            ),
            // 검색 칸
            if (_searching && !_selecting)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: TextStyle(color: baseColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '이름, 번호, 제목으로 찾기',
                      hintStyle: TextStyle(color: baseColor.withOpacity(0.35)),
                      prefixIcon: Icon(Icons.search, color: baseColor.withOpacity(0.4), size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: baseColor.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
            // 지금 재생 중인 녹음: 10초 앞뒤 · 배속
            // (재생 막대는 목록이 안 밀리게 화면 아래에 떠 있게 옮김)
            // 통화 녹음 | 음성 녹음 (선택 중엔 숨김)
            if (!_selecting)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Container(
                  height: 38,
                  // 라디오 카테고리와 같은 모양
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _seg('통화 녹음 (${everything.where((r) => !r.isVoice).length})', !_voice,
                              () => setState(() => _voice = false), baseColor, isDark),
                      _seg('음성 녹음 (${everything.where((r) => r.isVoice).length})', _voice,
                              () => setState(() => _voice = true), baseColor, isDark),
                    ],
                  ),
                ),
              ),
            ),
            if (music.callLoading && all.isEmpty)
              SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: muted)))
            else if (all.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_voice ? Icons.mic : Icons.call, size: 64, color: baseColor.withOpacity(0.2)),
                        const SizedBox(height: 14),
                        Text(_voice ? '음성 녹음이 없어요' : '통화 녹음이 없어요',
                            style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 15)),
                        const SizedBox(height: 6),
                        // 안내 문구 (이모지 대신 앱 선 아이콘을 글자 사이에)
                        Text.rich(
                            TextSpan(
                              children: _voice
                                  ? [
                                      const TextSpan(text: '오른쪽 아래 '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Icon(Icons.mic_none_rounded,
                                            size: 15, color: baseColor.withOpacity(0.3)),
                                      ),
                                      const TextSpan(text: ' 버튼으로\n바로 녹음할 수 있어요'),
                                    ]
                                  : const [TextSpan(text: '전화 앱 설정에서 통화 녹음을 켜면\n녹음된 통화가 여기에 모여요')],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: baseColor.withOpacity(0.3), fontSize: 12.5, height: 1.5)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    8, 4, 8, (_voice || _selecting) ? 100 : 16), // 녹음 버튼에 안 가리게
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final r = list[i];
                      final isCurrent = player.currentSong?.uri == r.path;
                      final sub = [r.dateLabel, if (r.durationLabel.isNotEmpty) r.durationLabel].join(' · ');
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          if (_selecting) {
                            setState(() {
                              _selected.contains(r.path) ? _selected.remove(r.path) : _selected.add(r.path);
                              if (_selected.isEmpty) _selectMode = false; // 다 풀면 선택 끝 (아래 막대도 사라짐)
                            });
                            return;
                          }
                          context.read<PlayerProvider>().playFromList(songs, i);
                        },
                        // 길게 누르면 여러 개 선택 시작
                        onLongPress: () {
                          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                          setState(() => _selected.add(r.path));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  // 선택 = 먹색, 재생 중 = 파란색, 나머지 = 베이지
                                  color: _selected.contains(r.path) ? selBg : (isCurrent ? _blue : soft),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                    _selecting
                                        ? (_selected.contains(r.path) ? Icons.check : Icons.circle_outlined)
                                        : (isCurrent && player.isPlaying
                                        ? Icons.graphic_eq
                                        : (r.isVoice ? Icons.mic : Icons.call)),
                                    color: _selected.contains(r.path) ? selFg : (isCurrent ? Colors.white : muted),
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(music.recordingTitle(r),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: isCurrent ? _blue : baseColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        if (music.isRecordingLocked(r.path)) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.lock, size: 14, color: baseColor.withOpacity(0.45)),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(sub,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (!_selecting)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _showMenu(r),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.more_vert, color: baseColor.withOpacity(0.35), size: 20),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              ),
          ],
        ),
        // 음성 녹음 칸에서만: 새로 녹음하기 버튼
        if (_voice && !_selecting)
          Positioned(right: 20, bottom: 24, child: _recordFab()),
        // (재생 막대는 맨 아래 미니플레이어에 합침)
        // 여러 개 선택 중: 아래 고정 버튼 (공유 · 잠금 · 삭제)
        if (_selected.isNotEmpty)
          Positioned(left: 0, right: 0, bottom: 0, child: _selectBar(list, music, baseColor, isDark)),
      ],
    );
  }

  /// 여러 개 선택했을 때 아래 버튼: 공유 · 잠금 · 삭제
  /// ⋮ 창: 정렬(한 줄 버튼) + 여러 개 선택하기 · 전체 삭제(빨강)
  void _showMoreSheet(List<CallRecording> list, bool isDark) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final bg = isDark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF3E3B37) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = isDark ? const Color(0xFF4A4640) : const Color(0xFFEFE9DE);
    const red = Color(0xFFD84A3A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {



        // 동작 한 줄 (아이콘 칸 + 글자)
        Widget action(IconData icon, String label, Color color, Color iconBg, VoidCallback onTap) => InkWell(
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                      child: Icon(icon, color: color, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Text(label, style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // 제목 + ✕
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('녹음 관리', style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: sub, size: 22),
                    ),
                  ],
                ),
                if (list.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        action(Icons.check_box_outlined, '여러 개 선택하기', ink, bg,
                            () => setState(() => _selectMode = true)),
                        Divider(height: 1, thickness: 1, color: line),
                        action(Icons.delete_outline_rounded, '전체 삭제', red, red.withOpacity(0.1),
                            () => _confirmTrash(list, isAll: true)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectBar(List<CallRecording> list, MusicProvider music, Color baseColor, bool isDark) {
    final picked = list.where((r) => _selected.contains(r.path)).toList();
    final enabled = picked.isNotEmpty;
    final allLocked = enabled && picked.every((r) => music.isRecordingLocked(r.path));

    // 먹색 바 (다크 모드는 크림색 바) — 정리 알림 바와 같은 식구
    final barBg = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final barFg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final barRed = isDark ? const Color(0xFFD84A3A) : const Color(0xFFFF8A7A);

    Widget btn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
      final c = enabled ? (color ?? barFg) : barFg.withOpacity(0.35);
      return Expanded(
        child: InkWell(
          onTap: enabled
              ? () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: c, size: 22),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(color: c, fontSize: 11.5)),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      padding: const EdgeInsets.symmetric(vertical: 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          // 고른 걸 한 번에 다 풀기 (동영상 화면과 같게)
          btn(Icons.remove_done_rounded, '선택 해제', () => setState(() {
                _selected.clear();
                _selectMode = false;
              })),
          btn(Icons.share_outlined, '공유', () => _share(picked)),
          btn(allLocked ? Icons.lock_open : Icons.lock_outline, allLocked ? '잠금 풀기' : '잠금', () async {
            // 다 잠겨 있으면 다 풀고, 아니면 안 잠긴 것만 잠그기
            for (final r in picked) {
              if (music.isRecordingLocked(r.path) == allLocked) await music.toggleRecordingLock(r);
            }
            if (!mounted) return;
            setState(() {
              _selected.clear();
              _selectMode = false;
            });
          }),
          btn(Icons.delete_outline, '삭제', () => _confirmTrash(picked, isAll: true), color: barRed),
        ],
      ),
      ),
    );
  }

  /// 빨간 녹음 버튼 → 녹음 화면
  Widget _recordFab() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final saved = await Navigator.push<String>(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const VoiceRecorderScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
        if (!mounted) return;
        context.read<MusicProvider>().loadCallRecordings();
        if (saved != null) {
          showActionFeedback(context, type: ActionFeedbackType.saved, message: '녹음을 저장했어요');
        }
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B6B), Color(0xFFE5383B)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFFE5383B).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
    );
  }

  // ───────── 지금 재생 중인 녹음: 10초 앞뒤 · 배속 ─────────
  Widget _miniBar(CallRecording r, PlayerProvider player, MusicProvider music, Color baseColor) {
    final pos = player.position;
    final dur = player.duration;
    final progress = dur.inMilliseconds > 0 ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0) : 0.0;
    String t(Duration d) =>
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    void jump(int sec) {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      var to = pos + Duration(seconds: sec);
      if (to < Duration.zero) to = Duration.zero;
      if (dur > Duration.zero && to > dur) to = dur;
      player.seekTo(to);
    }

    const speeds = [1.0, 1.25, 1.5, 2.0];
    final speed = player.playbackSpeed;
    final isDark = baseColor == Colors.white;
    final muted = isDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF353330) : Colors.white, // 떠 있는 카드
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.12), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(music.recordingTitle(r),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: baseColor, fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
              Text('${t(pos)} / ${t(dur)}', style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 11.5)),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: baseColor.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation(_blue),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => jump(-10), icon: Icon(Icons.replay_10, color: muted, size: 26)),
              IconButton(
                onPressed: () => player.togglePlayPause(),
                icon: Icon(player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: _blue, size: 38),
              ),
              IconButton(onPressed: () => jump(10), icon: Icon(Icons.forward_10, color: muted, size: 26)),
              const SizedBox(width: 8),
              // 배속: 누를 때마다 1.0 → 1.25 → 1.5 → 2.0
              GestureDetector(
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  final i = speeds.indexWhere((s) => (s - speed).abs() < 0.01);
                  player.setPlaybackSpeed(speeds[(i + 1) % speeds.length]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: speed == 1.0 ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.9) : _ink),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: speed == 1.0 ? baseColor.withOpacity(0.2) : Colors.transparent),
                  ),
                  child: Text('${speed == speed.roundToDouble() ? speed.toStringAsFixed(1) : speed}×',
                      style: TextStyle(
                          color: speed == 1.0 ? muted : (isDark ? const Color(0xFF24221F) : Colors.white),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 공유 (카톡·문자·메일 등)
  Future<void> _share(List<CallRecording> list) async {
    if (list.isEmpty) return;
    await Share.shareXFiles([for (final r in list) XFile(r.path)]);
  }

  /// 자르기: 잘라낸 파일은 원래 녹음 폴더에 "(자름)"을 붙여 저장 → 일반 음악 목록엔 안 섞임
  void _trim(CallRecording r) {
    final file = r.path.split('/').last;
    final base = file.replaceAll(RegExp(r'\.[^.]+$'), '');
    // 통화 녹음은 날짜 앞에 (자름)을 넣어서 날짜를 그대로 읽을 수 있게
    final m = RegExp(r'^(.*)(_\d{6}_\d{6})$').firstMatch(base);
    final outBase = m != null ? '${m.group(1)} (자름)${m.group(2)}' : '$base (자름)';
    final relDir = r.isVoice ? 'Recordings/Voice Recorder' : 'Recordings/Call';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RingtoneScreen(
          initialSong: r.toSong(0),
          trimMode: true,
          saveRelDir: relDir,
          saveBaseName: outBase,
        ),
      ),
    ).then((_) {
      if (mounted) context.read<MusicProvider>().loadCallRecordings();
    });
  }

  // ───────── 녹음 하나 메뉴: 공유 · 자르기 · 제목 바꾸기 · 잠금 · 삭제 ─────────
  void _showMenu(CallRecording r) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final music = context.read<MusicProvider>();
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final locked = music.isRecordingLocked(r.path);
    showParanSheet(
      context,
      title: music.recordingTitle(r),
      // 위: 녹음 제목 + 날짜
      header: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(music.recordingTitle(r),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            const SizedBox(height: 3),
            Text(r.dateLabel,
                style: TextStyle(
                    color: isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378), fontSize: 12.5)),
          ],
        ),
      ),
      builder: (ctx, setSheet) => Column(
        children: [
          ParanCard(children: [
            ParanRow(icon: Icons.share_outlined, title: '공유', onTap: () {
              Navigator.pop(ctx);
              _share([r]);
            }),
            ParanRow(icon: Icons.content_cut_rounded, title: '자르기', onTap: () {
              Navigator.pop(ctx);
              _trim(r);
            }),
            ParanRow(icon: Icons.edit_outlined, title: '제목 바꾸기', onTap: () {
              Navigator.pop(ctx);
              _renameDialog(r);
            }),
            ParanRow(
              icon: locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              title: locked ? '잠금 풀기' : '잠금 (삭제 안 되게)',
              onTap: () async {
                Navigator.pop(ctx);
                await music.toggleRecordingLock(r);
                if (!mounted) return;
                showActionFeedback(context,
                    type: ActionFeedbackType.saved,
                    message: locked ? '잠금을 풀었어요' : '잠갔어요',
                    icon: locked ? Icons.lock_open_rounded : Icons.lock_rounded);
              },
            ),
          ]),
          ParanCard(children: [
            ParanRow(
              icon: Icons.delete_outline_rounded,
              title: locked ? '잠긴 녹음은 삭제할 수 없어요' : '삭제',
              danger: true,
              onTap: locked
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _confirmTrash([r]);
                    },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, VoidCallback? onTap) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon, color: onTap == null ? color.withOpacity(0.35) : (color == Colors.redAccent ? color : color.withOpacity(0.6))),
      title: Text(label,
          style: TextStyle(color: onTap == null ? color.withOpacity(0.35) : color, fontSize: 14.5)),
      onTap: onTap,
    );
  }

  /// 제목 바꾸기 (앱 안에서만 바뀜, 원래 파일 이름은 그대로)
  void _renameDialog(CallRecording r) async {
    final music = context.read<MusicProvider>();
    final name = await showParanInput(
      context,
      title: '제목 바꾸기',
      initial: music.recordingTitle(r),
      hint: '예) 엄마랑 통화',
    );
    if (name == null || !mounted) return;
    await music.setRecordingTitle(r, name);
    if (!mounted) return;
    // 지금 듣고 있는 녹음이면 미니플레이어·재생화면 제목도 바로 바꾸기
    final cur = context.read<PlayerProvider>().currentSong;
    if (cur != null && cur.uri == r.path) cur.title = music.recordingTitle(r);
    showActionFeedback(context, type: ActionFeedbackType.edited, message: '이름을 바꿨어요');
  }

  /// 삭제 확인 → 휴지통으로 (잠근 건 빼고)
  void _confirmTrash(List<CallRecording> targets, {bool isAll = false}) async {
    final music = context.read<MusicProvider>();
    final lockedCount = targets.where((r) => music.isRecordingLocked(r.path)).length;
    final count = targets.length - lockedCount;
    if (count == 0) {
      showParanToast(context, '잠긴 녹음은 삭제할 수 없어요');
      return;
    }
    // 큰 버튼: 휴지통으로 / 작은 빨간 글씨: 영구 삭제
    final pick = await showParanChoice(
      context,
      title: isAll ? '녹음 $count개를 삭제할까요?' : '이 녹음을 삭제할까요?',
      message: [
        '휴지통으로 옮겨져요. 30일 뒤에 완전히 지워져요.',
        if (lockedCount > 0) '잠긴 녹음 $lockedCount개는 남겨둬요.',
      ].join('\n'),
      confirmLabel: '휴지통으로',
      extraLabel: '영구 삭제',
      danger: true,
    );
    if (!mounted) return;
    if (pick == 1) {
      final n = await music.trashRecordings(targets);
      _afterDelete(n, '삭제했어요');
    } else if (pick == 2) {
      _confirmForever(targets, count);
    }
  }

  /// 영구 삭제: 되살릴 수 없다고 한 번 더 확인
  void _confirmForever(List<CallRecording> targets, int count) async {
    final music = context.read<MusicProvider>();
    final ok = await showParanConfirm(
      context,
      title: '영구 삭제할까요?',
      message: '녹음 $count개를 영구 삭제하면 되살릴 수 없어요.',
      confirmLabel: '영구 삭제',
      danger: true,
    );
    if (!ok) return;
    final n = await music.deleteRecordingsForever(targets);
    _afterDelete(n, '영구 삭제했어요');
  }

  void _afterDelete(int n, String msg) {
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    if (n > 0) showActionFeedback(context, type: ActionFeedbackType.deleted, message: msg);
  }

  /// 통화 녹음 | 음성 녹음 고르는 칸
  Widget _seg(String label, bool selected, VoidCallback onTap, Color baseColor, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          // 라디오 카테고리와 같게: 선택 = 먹색 채움 + 흰 글자 (다크는 반대)
          decoration: BoxDecoration(
            color: selected ? (isDark ? Colors.white : const Color(0xFF17140F)) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected
                      ? (isDark ? const Color(0xFF24221F) : Colors.white)
                      : baseColor.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)), // 굵기를 항상 같게 → 글자가 안 흔들림
        ),
      ),
    );
  }

}