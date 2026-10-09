import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/video_provider.dart';
import '../models/video.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_toast.dart';
import 'video_trim_screen.dart';
import '../services/cast_service.dart';
import '../widgets/cast_sheets.dart';
import 'settings_help_screen.dart';

// 이어보기: 동영상마다 멈춘 곳 기억 (폰에 저장 + 바로 쓰게 메모리에도)
class VideoResume {
  static final Map<String, int> _mem = {};
  static String _key(String uri) => 'videoPos_$uri';

  static Future<int> get(String uri) async {
    if (_mem.containsKey(uri)) return _mem[uri]!;
    final p = await SharedPreferences.getInstance();
    final v = p.getInt(_key(uri)) ?? 0;
    _mem[uri] = v;
    return v;
  }

  static Future<void> save(String uri, int posMs, int durMs) async {
    // 처음 5초 안이거나 거의 끝까지 봤으면 기억 지우기 (다음엔 처음부터)
    final done = durMs <= 0 || posMs < 5000 || posMs > durMs - 10000 || posMs > durMs * 0.95;
    _mem[uri] = done ? 0 : posMs;
    final p = await SharedPreferences.getInstance();
    if (done) {
      await p.remove(_key(uri));
    } else {
      await p.setInt(_key(uri), posMs);
    }
  }
}

// 동영상 공유 (10분 넘으면 카톡 안내 먼저)
Future<void> shareVideo(BuildContext context, Video video) async {
  if (video.duration > 10 * 60 * 1000) {
    final ok = await showParanConfirm(
      context,
      title: '긴 동영상이에요',
      message: '10분이 넘는 영상은 카카오톡으로 안 보내질 수 있어요.\n구글 드라이브나 메일로 보내면 잘 가요.',
      confirmLabel: '보내기',
    );
    if (!ok || !context.mounted) return;
  }
  try {
    await Share.shareXFiles([XFile(video.uri)], text: video.titleDisplay);
  } catch (e) {
    debugPrint('동영상 공유 오류: $e');
  }
}

// 동영상 삭제 — 하나·여러 개·전체 모두 같은 창 (녹음 삭제와 같은 방식)
// 큰 버튼: 휴지통으로 (30일 뒤 완전 삭제) / 작은 빨간 글씨: 영구 삭제 · 지웠으면 true
Future<bool> deleteVideosFlow(BuildContext context, List<Video> targets, {bool isAll = false}) async {
  if (targets.isEmpty) return false;
  final n = targets.length;
  final what = (isAll || n > 1) ? '동영상 $n개를' : '이 동영상을';
  final pick = await showParanChoice(
    context,
    title: '$what 삭제할까요?',
    message: '휴지통으로 옮겨져요. 30일 뒤에 완전히 지워져요.',
    confirmLabel: '휴지통으로',
    extraLabel: '영구 삭제',
    danger: true,
  );
  if (pick == 0 || !context.mounted) return false;
  if (pick == 2) {
    // 영구 삭제: 되살릴 수 없다고 한 번 더 확인
    final ok = await showParanConfirm(
      context,
      title: '영구 삭제할까요?',
      message: '$what 영구 삭제하면 되살릴 수 없어요.',
      confirmLabel: '영구 삭제',
      danger: true,
    );
    if (!ok || !context.mounted) return false;
  }
  try {
    final done = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<bool>(
      pick == 1 ? 'trashVideos' : 'deleteVideosForever',
      {'paths': [for (final v in targets) v.uri]},
    );
    if (done != true) return false; // 폰 확인 창에서 취소
    if (!context.mounted) return true;
    context.read<VideoProvider>().loadVideos(quiet: true);
    showActionFeedback(context,
        type: ActionFeedbackType.deleted, message: pick == 1 ? '삭제했어요' : '영구 삭제했어요');
    return true;
  } catch (e) {
    if (context.mounted) showParanToast(context, '삭제하지 못했어요', error: true);
    return false;
  }
}

// 정렬 이름
const Map<String, String> _kSortLabels = {
  'new': '최신순',
  'old': '오래된순',
  'name': '이름순',
  'long': '긴 영상순',
  'short': '짧은 영상순',
};

// 묶음 제목: 오늘 / 어제는 날짜별, 그 전은 월별 (10월 / 2025년 10월) → 한 칸만 남는 줄이 거의 없게
String _dayLabel(int ms) {
  if (ms <= 0) return '날짜 모름';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '어제';
  if (d.year == now.year) return '${d.month}월';
  return '${d.year}년 ${d.month}월';
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with WidgetsBindingObserver {
  final Set<String> _selected = {}; // 여러 개 선택 (영상 경로)
  bool _selectMode = false; // ⋮ → 여러 개 선택하기로 켰을 때
  bool get _selecting => _selectMode || _selected.isNotEmpty;

  void _endSelect() => setState(() {
        _selected.clear();
        _selectMode = false;
      });
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoProvider>();
      if (!provider.hasPermission && provider.videos.isEmpty) {
        provider.requestPermissionAndLoad();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 정렬 고르는 창 (길게 눌렀을 때 창과 같은 모양)
  void _showSortSheet(BuildContext context) {
    final p = context.read<VideoProvider>();
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final bg = isDarkMode ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    final card = isDarkMode ? const Color(0xFF3E3B37) : Colors.white;
    final ink = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDarkMode ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = isDarkMode ? const Color(0xFF4A4640) : const Color(0xFFEFE9DE);
    final iconColor = isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    final primary = Theme.of(context).colorScheme.primary;
    const icons = {
      'new': Icons.schedule_rounded,
      'old': Icons.history_rounded,
      'name': Icons.sort_by_alpha_rounded,
      'long': Icons.hourglass_bottom_rounded,
      'short': Icons.timer_outlined,
    };
    final keys = _kSortLabels.keys.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('정렬',
                            style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: sub, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      for (var i = 0; i < keys.length; i++) ...[
                        if (i > 0) Divider(height: 1, thickness: 1, color: line),
                        InkWell(
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            Navigator.pop(ctx);
                            p.setSort(keys[i]);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                                  child: Icon(icons[keys[i]], color: iconColor, size: 17),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_kSortLabels[keys[i]]!,
                                      style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600)),
                                ),
                                if (p.sort == keys[i]) Icon(Icons.check_rounded, size: 20, color: primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ⋮ 창: 여러 개 선택하기 · 전체 삭제(빨강) — 녹음 관리 창과 같은 모양
  void _showMoreSheet(bool isDark) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final list = context.read<VideoProvider>().videos;
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
                      child: Text('동영상 관리', style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
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
                            () => deleteVideosFlow(context, List.of(list), isAll: true)),
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

  // 선택 중 위 줄: ✕ · N개 선택 · 전체 선택 (녹음 화면과 같은 모양)
  Widget _selectHeader(List<Video> list, Color baseColor) {
    final all = list.isNotEmpty && _selected.length == list.length;
    return Row(
      children: [
        IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            _endSelect();
          },
          icon: Icon(Icons.close, color: baseColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        ),
        const SizedBox(width: 4),
        Text('${_selected.length}개 선택',
            style: TextStyle(color: baseColor, fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            setState(() {
              if (all) {
                _selected.clear();
                _selectMode = false; // 다 풀면 선택 끝
              } else {
                _selected
                  ..clear()
                  ..addAll(list.map((v) => v.uri));
              }
            });
          },
          child: Text(all ? '선택 해제' : '전체 선택', style: TextStyle(color: baseColor.withOpacity(0.75))),
        ),
      ],
    );
  }

  // 선택 중 아래 고정 버튼: 공유 · 삭제 (녹음 화면과 같은 먹색 막대)
  Widget _selectBar(List<Video> list, bool isDark) {
    final picked = list.where((v) => _selected.contains(v.uri)).toList();
    final enabled = picked.isNotEmpty;
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
            // 고른 걸 한 번에 다 풀기 (막대·동그라미도 같이 사라짐)
            btn(Icons.remove_done_rounded, '선택 해제', _endSelect),
            btn(Icons.share_outlined, '공유', () async {
              await Share.shareXFiles([for (final v in picked) XFile(v.uri)]);
            }),
            btn(Icons.delete_outline, '삭제', () async {
              if (await deleteVideosFlow(context, picked, isAll: true) && mounted) _endSelect();
            }, color: barRed),
          ],
        ),
      ),
    );
  }

  // 영상 칸들 (최신순·오래된순이면 날짜마다 작은 제목)
  List<Widget> _videoSlivers(VideoProvider p, Color baseColor) {
    Widget grid(List<Video> list, double top, {String dateMode = 'full'}) => SliverPadding(
          padding: EdgeInsets.fromLTRB(12, top, 12, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.18, // 16:9 사진 + 제목 두 줄
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final v = list[index];
                // 이름표(key)가 있어야 새 영상이 끼어들어도 썸네일이 안 뒤바뀜
                return _VideoTile(
                  key: ValueKey(v.uri),
                  video: v,
                  dateMode: dateMode,
                  selecting: _selecting,
                  selected: _selected.contains(v.uri),
                  onSelect: () => setState(() {
                    _selected.contains(v.uri) ? _selected.remove(v.uri) : _selected.add(v.uri);
                    if (_selected.isEmpty) _selectMode = false; // 다 풀면 선택 끝 (아래 버튼도 사라짐)
                  }),
                );
              },
              childCount: list.length,
            ),
          ),
        );

    if (p.sort != 'new' && p.sort != 'old') return [grid(p.videos, 4)];

    final out = <Widget>[];
    String? cur;
    var bucket = <Video>[];
    void flush() {
      if (cur == null || bucket.isEmpty) return;
      out.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, out.isEmpty ? 4 : 10, 16, 8),
          child: Text(cur!,
              style: TextStyle(
                  color: baseColor.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        ),
      ));
      out.add(grid(bucket, 0, dateMode: (cur == '오늘' || cur == '어제') ? 'time' : 'day'));
    }

    for (final v in p.videos) {
      final label = _dayLabel(p.dateOf(v.uri));
      if (label != cur) {
        flush();
        cur = label;
        bucket = <Video>[];
      }
      bucket.add(v);
    }
    flush();
    return out;
  }

  // 앱으로 돌아오면 새로 찍은 영상 있는지 조용히 다시 찾기
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final provider = context.read<VideoProvider>();
    if (!provider.permissionDenied && !provider.isLoading) {
      provider.loadVideos(quiet: true);
    } else if (provider.permissionDenied) {
      // 설정에서 허용하고 돌아왔으면 바로 불러오기 (아직 안 했으면 창 안 띄움)
      Permission.videos.status.then((s) {
        if (s.isGranted || s.isLimited) provider.requestPermissionAndLoad();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.watch<VideoProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);

    if (videoProvider.permissionDenied) {
      // 권한 안내: 작은 아이콘 + 부드러운 문구 + 1·2·3 순서 카드 + 먹색 버튼
      final card = isDarkMode ? const Color(0xFF32302C) : Colors.white;
      final ink = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
      final sub = isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
      final hint = isDarkMode ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
      Widget step(int n, String text, {String? note}) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                  child: Text('$n', style: TextStyle(color: bgColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: TextStyle(color: ink, fontSize: 13.5)),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(note, style: TextStyle(color: hint, fontSize: 11.5)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: card, shape: BoxShape.circle),
                      child: Icon(Icons.movie_outlined, size: 26, color: sub),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('폰에 있는 동영상을 불러올게요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  Text('동영상 접근을 한 번만 허용해 주세요',
                      textAlign: TextAlign.center, style: TextStyle(color: hint, fontSize: 13)),
                  const SizedBox(height: 22),
                  step(1, '아래 설정에서 허용하기 누르기', note: '파란소리 앱 설정이 바로 열려요'),
                  step(2, '권한 → 사진 및 동영상 누르기'),
                  step(3, '허용 고르고 돌아오기', note: '돌아오면 바로 목록이 나와요'),
                  // 버튼 대신 직접 찾아갈 때 (폰 회사마다 메뉴 이름이 조금 달라요)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Text('직접 찾아갈 때: 설정 → 애플리케이션(앱) → 파란소리 → 권한 → 사진 및 동영상',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: hint, fontSize: 11.5, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: bgColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('설정에서 허용하기',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SettingsHelpScreen())),
                      style: TextButton.styleFrom(foregroundColor: hint),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('다른 설정 도움말 보기', style: TextStyle(fontSize: 12.5)),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (videoProvider.isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: baseColor.withOpacity(0.6)),
        ),
      );
    }

    if (videoProvider.videos.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 72, color: baseColor.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.noVideosFound,
                  style: TextStyle(
                      color: baseColor.withOpacity(0.7), fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
      CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: bgColor,
            expandedHeight: 80 * MediaQuery.of(context).textScaler.scale(1.0),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _selecting
                          ? _selectHeader(videoProvider.videos, baseColor)
                          : Row(
                        children: [
                          Text(AppLocalizations.of(context)!.videos,
                              style: TextStyle(
                                  color: baseColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          const SizedBox(width: 8),
                          Text('(${videoProvider.videos.length})',
                              style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 13)),
                          const Spacer(),
                          // 정렬 버튼: 최신순 ▾
                          GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              _showSortSheet(context);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_kSortLabels[videoProvider.sort] ?? '최신순',
                                      style: TextStyle(
                                          color: baseColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: baseColor.withOpacity(0.6)),
                                ],
                              ),
                            ),
                          ),
                          // ⋮ 여러 개 선택하기 · 전체 삭제 (녹음 화면과 같게)
                          IconButton(
                            onPressed: () => _showMoreSheet(isDarkMode),
                            icon: Icon(Icons.more_vert, color: baseColor.withOpacity(0.55), size: 21),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ..._videoSlivers(videoProvider, baseColor),
          // 선택 중엔 아래 버튼에 안 가리게 여백 넉넉히
          SliverPadding(padding: EdgeInsets.only(bottom: _selecting ? 100 : 16)),
        ],
      ),
          // 여러 개 선택 중: 아래 고정 버튼 (공유 · 삭제)
          if (_selected.isNotEmpty)
            Positioned(left: 0, right: 0, bottom: 0, child: _selectBar(videoProvider.videos, isDarkMode)),
        ],
      ),
    );
  }
}

// 카메라로 찍은 영상 이름(20261008_160312)을 날짜·시간으로 바꿔 보여주기
({String date, String time, String day})? _cameraDate(String title) {
  final m = RegExp(r'(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})').firstMatch(title);
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final h = int.parse(m[4]!), mi = int.parse(m[5]!);
  if (y < 2000 || mo < 1 || mo > 12 || d < 1 || d > 31 || h > 23 || mi > 59) return null;
  const week = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = week[DateTime(y, mo, d).weekday - 1];
  final ampm = h < 12 ? '오전' : '오후';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return (
    date: '$y년 $mo월 $d일 ($wd)',
    time: '$ampm $h12:${mi.toString().padLeft(2, '0')}',
    day: '$d일 ($wd)',
  );
}

class _VideoTile extends StatefulWidget {
  final Video video;
  final bool selecting; // 여러 개 선택 중
  final bool selected; // 이 영상을 골랐는지
  final VoidCallback? onSelect;
  final String dateMode; // full 날짜까지 · day 일(요일)+시간 (월별 묶음) · time 시간만 (오늘·어제)

  const _VideoTile(
      {super.key, required this.video, this.selecting = false, this.selected = false, this.onSelect, this.dateMode = 'full'});

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  static const _channel = MethodChannel('kr.ssing.catsong/media');
  Uint8List? _thumbnail;
  double _progress = 0; // 이어보기 진행 막대 (0~1)

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    _loadResume();
    context.read<VideoProvider>().loadPlace(widget.video.uri); // 찍은 곳 (위치 태그 있으면)
  }

  // 어디까지 봤는지 불러와서 막대 길이 정하기
  Future<void> _loadResume() async {
    final pos = await VideoResume.get(widget.video.uri);
    final dur = widget.video.duration;
    final p = (pos > 0 && dur > 0) ? (pos / dur).clamp(0.0, 1.0).toDouble() : 0.0;
    if (mounted && p != _progress) setState(() => _progress = p);
  }

  Future<void> _loadThumbnail() async {
    try {
      final result = await _channel.invokeMethod('getVideoThumbnail', {
        'path': widget.video.uri,
      });
      if (result != null && mounted) {
        setState(() {
          _thumbnail = Uint8List.fromList(List<int>.from(result));
        });
      }
    } catch (e) {
      // 썸네일 로드 실패
    }
  }

  Future<void> _showOptions(BuildContext context) async {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    // 아래에서 올라오는 창 (통화녹음 ⋮ 창과 같은 모양)
    final bg = isDarkMode ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    final card = isDarkMode ? const Color(0xFF3E3B37) : Colors.white;
    final ink = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDarkMode ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = isDarkMode ? const Color(0xFF4A4640) : const Color(0xFFEFE9DE);
    const red = Color(0xFFD84A3A);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget action(IconData icon, String label, Color color, Color iconBg, Color iconColor, VoidCallback onTap) =>
            InkWell(
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
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
                      child: Icon(icon, color: iconColor, size: 17),
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
                // 동영상 이름 + ✕
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.video.titleDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
                            // 찍은 곳 (위치 태그 있으면) — 회색 선 핀
                            if (context.read<VideoProvider>().placeOf(widget.video.uri) case final place?)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.place_outlined, size: 13, color: sub),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(place,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: sub, fontSize: 11.5, fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: sub, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      action(Icons.ios_share_rounded, '공유하기', ink, bg,
                          isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348),
                          () => shareVideo(context, widget.video)),
                      Divider(height: 1, thickness: 1, color: line),
                      action(Icons.content_cut_rounded, '잘라서 보내기', ink, bg,
                          isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348),
                          () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => VideoTrimScreen(video: widget.video)))),
                      Divider(height: 1, thickness: 1, color: line),
                      action(Icons.music_note_rounded, '음악으로 저장', ink, bg,
                          isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348),
                          () => showSaveAudioSheet(context, widget.video)),
                      Divider(height: 1, thickness: 1, color: line),
                      action(Icons.edit_outlined, AppLocalizations.of(context)!.rename, ink, bg,
                          isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348), () => _renameVideo(context)),
                      Divider(height: 1, thickness: 1, color: line),
                      action(Icons.delete_outline_rounded, AppLocalizations.of(context)!.delete, red,
                          red.withOpacity(0.1), red, () => _deleteVideo(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _renameVideo(BuildContext context) async {
    final newName = await showParanInput(
      context,
      title: AppLocalizations.of(context)!.rename,
      initial: widget.video.titleDisplay,
    );
    if (newName == null || !context.mounted) return;
    try {
      await _channel.invokeMethod('renameVideo', {
        'uri': widget.video.uri,
        'newName': newName,
      });
      if (!context.mounted) return;
      final vp = context.read<VideoProvider>();
      await vp.carrySeen(widget.video.uri, newName); // 이름 바꿔도 NEW 안 붙게
      vp.loadVideos();
      if (!context.mounted) return;
      showActionFeedback(context, type: ActionFeedbackType.edited, message: '이름을 바꿨어요');
    } catch (e) {
      showParanToast(context, '이름을 바꾸지 못했어요', error: true);
    }
  }

  Future<void> _deleteVideo(BuildContext context) async {
    await deleteVideosFlow(context, [widget.video]); // 휴지통 / 영구 삭제 (모두 같은 창)
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.selecting ? null : () => _showOptions(context),
      onTap: () async {
        _channel.invokeMethod('vibrate');
        // 여러 개 선택 중이면 고르기만
        if (widget.selecting) {
          widget.onSelect?.call();
          return;
        }
        context.read<VideoProvider>().markSeen(widget.video.uri); // 열어보면 NEW 지우기
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(video: widget.video),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
        if (mounted) _loadResume(); // 돌아오면 막대 새로
      },
      child: Builder(builder: (ctx) {
        final isDarkMode = ctx.watch<ThemeProvider>().isDarkMode;
        final baseColor = isDarkMode ? Colors.white : Colors.black;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 썸네일 (회색 칸·큰 ▶ 없이) + 오른쪽 아래 재생 시간 작은 표
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_thumbnail != null)
                      Image.memory(
                        _thumbnail!,
                        fit: BoxFit.cover,
                        cacheWidth: 400, // 칸 크기만큼만 풀기
                        gaplessPlayback: true,
                      )
                    else
                      Container(
                        color: baseColor.withOpacity(0.06),
                        child: Icon(Icons.movie_outlined, color: baseColor.withOpacity(0.3), size: 26),
                      ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17140F).withOpacity(0.72),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.video.durationFormatted,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    // 찍은 곳: 왼쪽 아래 (오른쪽 재생 시간 표와 같은 모양, 흰 선 핀)
                    if (ctx.watch<VideoProvider>().placeOf(widget.video.uri) case final place?)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 110),
                          padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF17140F).withOpacity(0.72),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place_outlined, size: 11, color: Colors.white),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  // 칸이 좁아서 뒤 두 낱말만 (서울 중구 명동 → 중구 명동)
                                  place.split(' ').length > 2
                                      ? place.split(' ').sublist(place.split(' ').length - 2).join(' ')
                                      : place,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // 새로 찍은(아직 안 본) 영상: 왼쪽 위 NEW
                    if (ctx.watch<VideoProvider>().isNew(widget.video.uri))
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                          ),
                        ),
                      ),
                    // 여러 개 선택 중: 고른 건 살짝 어둡게 + 오른쪽 위 동그라미 ✓ (녹음 선택과 같은 먹색)
                    if (widget.selecting) ...[
                      if (widget.selected) Container(color: Colors.black.withOpacity(0.28)),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.selected
                                ? (isDarkMode ? Colors.white.withOpacity(0.9) : const Color(0xFF3A352D))
                                : Colors.black.withOpacity(0.25),
                            border: Border.all(color: Colors.white, width: 1.6),
                          ),
                          child: widget.selected
                              ? Icon(Icons.check, size: 15, color: isDarkMode ? const Color(0xFF24221F) : Colors.white)
                              : null,
                        ),
                      ),
                    ],
                    // 이어보기: 어디까지 봤는지 얇은 막대 (포인트색)
                    if (_progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 3,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 제목 두 줄까지 (카메라 영상이면 날짜 + 시간)
            Flexible(
              child: Builder(builder: (_) {
                final cd = _cameraDate(widget.video.title);
                if (cd == null) {
                  // 이름 바꾼 영상·다운받은 영상: 이름 + 찍은 날짜·요일·시간
                  final ms = context.read<VideoProvider>().dateOf(widget.video.uri);
                  String? when;
                  if (ms > 0) {
                    final d = DateTime.fromMillisecondsSinceEpoch(ms);
                    const week = ['월', '화', '수', '목', '금', '토', '일'];
                    final ampm = d.hour < 12 ? '오전' : '오후';
                    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
                    // 올해면 연도 빼고, 작년 이전이면 숫자로 짧게 (칸에 다 들어가게)
                    final day = d.year == DateTime.now().year
                        ? '${d.month}월 ${d.day}일'
                        : '${d.year}.${d.month}.${d.day}';
                    final hm = '$ampm $h12:${d.minute.toString().padLeft(2, '0')}';
                    final wd = week[d.weekday - 1];
                    // 위 묶음 제목과 겹치는 건 빼기
                    when = widget.dateMode == 'time'
                        ? hm
                        : widget.dateMode == 'day'
                            ? '${d.day}일 ($wd) $hm'
                            : '$day ($wd) $hm';
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.video.titleDisplay,
                        maxLines: when == null ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                      if (when != null)
                        Text(
                          when,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.3),
                        ),
                    ],
                  );
                }
                // 오늘·어제 묶음: 시간만 (진하게)
                if (widget.dateMode == 'time') {
                  return Text(
                    cd.time,
                    maxLines: 1,
                    style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // 월별 묶음이면 "5일 (월)", 아니면 "2026년 10월 5일 (월)"
                      widget.dateMode == 'day' ? cd.day : cd.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    Text(
                      cd.time,
                      maxLines: 1,
                      style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.3),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final Video video;
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  Timer? _saveTimer; // 5초마다 어디까지 봤는지 저장
  bool _audioOnly = false; // 소리만 듣기 (화면 꺼도 계속)
  double _speed = 1.0; // 재생 속도
  bool _loopOn = false; // 구간 반복 막대 보이기
  int? _loopA; // 구간 반복 시작 (밀리초)
  int? _loopB; // 구간 반복 끝 (밀리초)
  bool _loopSeeking = false;
  int _seekSide = 0; // 두 번 탭 표시: -1 왼쪽 / 1 오른쪽 / 0 없음
  int _seekSec = 0; // 두 번 탭으로 쌓인 초
  Timer? _seekHide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // 라디오/음악 정지
    try {
      context.read<VideoProvider>().stopOtherPlayers();
    } catch (e) {
      debugPrint('stopOtherPlayers 오류: $e');
    }

    _videoPlayerController = VideoPlayerController.file(
      File(widget.video.uri),
      // 앱을 나가도 멈추지 않게 (멈출지는 소리만 듣기 설정으로 직접 정함)
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
    );

    await _videoPlayerController.initialize();
    _videoPlayerController.addListener(_loopTick); // 구간 반복: B에 닿으면 A로
    // 소리만 듣기 설정 불러오기 (한 번 켜면 다음 영상도 그대로)
    _audioOnly = (await SharedPreferences.getInstance()).getBool('videoAudioOnly') ?? false;
    // 이어보기: 멈췄던 곳부터
    final resumeMs = await VideoResume.get(widget.video.uri);
    if (!mounted) return;

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      startAt: resumeMs > 0 ? Duration(milliseconds: resumeMs) : null,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      showOptions: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.white,
        handleColor: Colors.white,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white38,
      ),
    );

    setState(() {});
    // 5초마다 어디까지 봤는지 기억 (앱이 갑자기 꺼져도)
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _savePosition());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_videoPlayerController.value.isInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // 소리만 듣기 꺼져 있으면 원래처럼 멈추기
      if (!_audioOnly) {
        _videoPlayerController.pause();
        _savePosition();
      }
    }
  }

  // ───── TV로 보기 (구글 캐스트 · 스마트 TV) ─────
  bool get _castingHere {
    final c = CastService.instance;
    return c.isConnected && c.isVideo && c.currentUri == widget.video.uri;
  }

  Future<void> _openCast() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final cast = CastService.instance;
    if (_castingHere) {
      showCastControlSheet(context, nowPlaying: widget.video.titleDisplay);
      return;
    }
    // 폰은 멈추고, 보던 곳부터 TV로
    Future<bool> send(Future<bool> Function(int startSec) go) async {
      if (!_videoPlayerController.value.isInitialized) return false;
      final pos = _videoPlayerController.value.position.inSeconds;
      _videoPlayerController.pause();
      final ok = await go(pos);
      if (!ok && mounted) _videoPlayerController.play();
      return ok;
    }

    if (cast.isConnected) {
      // 이미 TV에 연결돼 있으면 (음악 보내던 중 등) 같은 TV로 바로
      final ok = await send((s) =>
          cast.castVideo(path: widget.video.uri, title: widget.video.titleDisplay, startSec: s));
      if (!ok && mounted) showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);
      return;
    }
    showCastPickerSheet(
      context,
      title: 'TV로 보기',
      onPick: (d) => send((s) =>
          cast.connectVideo(d, path: widget.video.uri, title: widget.video.titleDisplay, startSec: s)),
    );
  }

  /// TV → 폰으로 돌아오기 (TV에서 보던 곳부터 이어서)
  Future<void> _backToPhone() async {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final cast = CastService.instance;
    final pos = cast.tvPosition;
    await cast.disconnect();
    if (!mounted) return;
    await _videoPlayerController.seekTo(pos);
    _videoPlayerController.play();
  }

  /// TV로 보는 동안 폰 화면
  Widget _castPanel() {
    final cast = CastService.instance;
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tv_rounded, color: Colors.white70, size: 46),
          const SizedBox(height: 12),
          Text('${cast.device?.name ?? 'TV'}에서 보는 중',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.video.titleDisplay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              cast.tvPlaying ? cast.pause() : cast.play();
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: Color(0xFFF3EFE7), shape: BoxShape.circle),
              child: Icon(cast.tvPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF17140F), size: 32),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _backToPhone,
            child: const Text('폰에서 이어 보기',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38)),
          ),
        ],
      ),
    );
  }

  // ───── 재생 화면 편의 기능: 두 번 탭 10초 · 재생 속도 · 구간 반복 ─────
  void _vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');

  String _speedLabel(double s) => s == s.roundToDouble() ? '${s.toStringAsFixed(1)}×' : '$s×';

  String _fmtMs(int? ms) {
    if (ms == null) return '--:--';
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  // 구간 반복: B에 닿으면 A로
  void _loopTick() {
    final a = _loopA, b = _loopB;
    if (a == null || b == null || b <= a || _loopSeeking) return;
    final v = _videoPlayerController.value;
    if (!v.isInitialized) return;
    if (v.position.inMilliseconds >= b) {
      _loopSeeking = true;
      _videoPlayerController.seekTo(Duration(milliseconds: a)).whenComplete(() => _loopSeeking = false);
    }
  }

  // 두 번 탭: -1 = 왼쪽 10초 뒤로 / 1 = 오른쪽 10초 앞으로 (연달아 누르면 20초, 30초…)
  void _doubleTapSeek(int dir) {
    final v = _videoPlayerController.value;
    if (!v.isInitialized) return;
    _vib();
    var to = v.position + Duration(seconds: 10 * dir);
    if (to < Duration.zero) to = Duration.zero;
    if (to > v.duration) to = v.duration;
    _videoPlayerController.seekTo(to);
    setState(() {
      if (_seekSide != dir) _seekSec = 0;
      _seekSide = dir;
      _seekSec += 10;
    });
    _seekHide?.cancel();
    _seekHide = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _seekSide = 0;
          _seekSec = 0;
        });
      }
    });
  }

  void _setSpeed(double s) {
    _videoPlayerController.setPlaybackSpeed(s);
    setState(() => _speed = s);
  }

  // 재생 속도 고르는 창 (정렬 창과 같은 모양 · 재생 화면이라 어두운 색)
  void _showSpeedSheet() {
    const bg = Color(0xFF32302C);
    const card = Color(0xFF3E3B37);
    const ink = Color(0xFFF3EFE7);
    const sub = Color(0xFFB8B0A2);
    const line = Color(0xFF4A4640);
    final primary = Theme.of(context).colorScheme.primary;
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
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
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('재생 속도', style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, color: sub, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    for (var i = 0; i < speeds.length; i++) ...[
                      if (i > 0) const Divider(height: 1, thickness: 1, color: line),
                      InkWell(
                        onTap: () {
                          _vib();
                          Navigator.pop(ctx);
                          _setSpeed(speeds[i]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  speeds[i] == 1.0 ? '${_speedLabel(speeds[i])}  보통' : _speedLabel(speeds[i]),
                                  style: TextStyle(
                                    color: _speed == speeds[i] ? primary : ink,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_speed == speeds[i]) Icon(Icons.check_rounded, size: 20, color: primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 구간 반복 A·B 정하기
  void _setLoopA() {
    _vib();
    final pos = _videoPlayerController.value.position.inMilliseconds;
    setState(() {
      _loopA = pos;
      if (_loopB != null && _loopB! <= pos + 500) _loopB = null; // B가 A보다 앞이면 B 다시 정하기
    });
  }

  void _setLoopB() {
    _vib();
    final pos = _videoPlayerController.value.position.inMilliseconds;
    if (_loopA == null || pos <= _loopA! + 500) {
      showParanToast(context, _loopA == null ? 'A를 먼저 정해 주세요' : 'A보다 뒤에서 눌러 주세요');
      return;
    }
    setState(() => _loopB = pos);
    _videoPlayerController.seekTo(Duration(milliseconds: _loopA!));
    _videoPlayerController.play();
  }

  void _loopOff() {
    setState(() {
      _loopOn = false;
      _loopA = null;
      _loopB = null;
    });
  }

  // 구간 반복 막대 (영상 아래 · 어두운 둥근 카드)
  Widget _loopBar() {
    final primary = Theme.of(context).colorScheme.primary;
    final hint = _loopA == null
        ? 'A를 정해 주세요'
        : (_loopB == null ? 'B를 정하면 반복돼요' : '반복 중');
    Widget btn(String label, String sub, bool set, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: set ? primary.withOpacity(0.22) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: set ? primary.withOpacity(0.6) : Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(color: Color(0xFFF3EFE7), fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                ],
              ),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(color: const Color(0xFF32302C), borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.repeat_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
              const Text('구간 반복',
                  style: TextStyle(color: Color(0xFFF3EFE7), fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(hint, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              btn('A 지정', _fmtMs(_loopA), _loopA != null, _setLoopA),
              const SizedBox(width: 8),
              btn('B 지정', _fmtMs(_loopB), _loopB != null, _setLoopB),
              const SizedBox(width: 8),
              btn('끄기', '반복 끝', false, () {
                _vib();
                _loopOff();
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _savePosition() {
    final v = _videoPlayerController.value;
    if (!v.isInitialized) return;
    VideoResume.save(widget.video.uri, v.position.inMilliseconds, v.duration.inMilliseconds);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _seekHide?.cancel();
    _videoPlayerController.removeListener(_loopTick);
    if (_castingHere) CastService.instance.disconnect(); // 화면을 나가면 TV도 정지
    try {
      _savePosition(); // 나갈 때 멈춘 곳 기억
    } catch (_) {}
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(widget.video.titleDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white)),
                ),
                // 속도가 보통이 아니면 작은 표
                if (_speed != 1.0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white38),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_speedLabel(_speed),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
                // 구간 반복 중이면 반복 아이콘
                if (_loopA != null && _loopB != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.repeat_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                ],
              ],
            ),
            // 찍은 곳 (위치 태그 있으면) — 회색 작은 글씨
            if (context.watch<VideoProvider>().placeOf(widget.video.uri) case final place?)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_outlined, size: 13, color: Colors.white54),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        actions: [
          // TV로 보기
          AnimatedBuilder(
            animation: CastService.instance,
            builder: (context, _) => IconButton(
              onPressed: _openCast,
              icon: Icon(_castingHere ? Icons.cast_connected_rounded : Icons.cast_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            // 재생 화면은 늘 어두워서 어두운 둥근 카드 (재생목록 ⋮과 같은 모양)
            color: const Color(0xFF32302C),
            position: PopupMenuPosition.under,
            itemBuilder: (context) {
              const red = Color(0xFFD84A3A);
              PopupMenuItem<String> item(IconData icon, String label, String value, {bool danger = false, bool on = false}) =>
                  PopupMenuItem(
                    value: value,
                    height: 46,
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: danger ? red.withOpacity(0.18) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(icon, size: 17, color: danger ? red : const Color(0xFFCFC8BB)),
                        ),
                        const SizedBox(width: 12),
                        Text(label,
                            style: TextStyle(
                                color: danger ? red : const Color(0xFFF3EFE7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        if (on) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.check_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                        ],
                      ],
                    ),
                  );
              return [
                item(Icons.ios_share_rounded, '공유하기', 'share'),
                item(Icons.headphones_rounded, '소리만 듣기', 'audioOnly', on: _audioOnly),
                item(Icons.speed_rounded, '재생 속도 (${_speedLabel(_speed)})', 'speed'),
                item(Icons.repeat_rounded, '구간 반복', 'loop', on: _loopOn),
                item(Icons.content_cut_rounded, '잘라서 보내기', 'trim'),
                item(Icons.music_note_rounded, '음악으로 저장', 'toMusic'),
                item(Icons.edit_outlined, AppLocalizations.of(context)!.rename, 'rename'),
                item(Icons.delete_outline_rounded, AppLocalizations.of(context)!.delete, 'delete', danger: true),
              ];
            },
            onSelected: (value) async {
              if (value == 'share') {
                await shareVideo(context, widget.video);
                return;
              }
              if (value == 'audioOnly') {
                setState(() => _audioOnly = !_audioOnly);
                (await SharedPreferences.getInstance()).setBool('videoAudioOnly', _audioOnly);
                if (context.mounted) {
                  showParanToast(context, _audioOnly ? '화면을 꺼도 소리가 계속 나와요' : '앱을 나가면 멈춰요');
                }
                return;
              }
              if (value == 'speed') {
                _showSpeedSheet();
                return;
              }
              if (value == 'loop') {
                if (_loopOn) {
                  _loopOff();
                } else {
                  setState(() => _loopOn = true);
                }
                return;
              }
              if (value == 'trim' || value == 'toMusic') {
                _videoPlayerController.pause(); // 자르는 동안 멈추기
                if (value == 'trim') {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => VideoTrimScreen(video: widget.video)));
                } else {
                  await showSaveAudioSheet(context, widget.video);
                }
                return;
              }
              if (value == 'rename') {
                final newName = await showParanInput(
                  context,
                  title: AppLocalizations.of(context)!.rename,
                  initial: widget.video.titleDisplay,
                );
                if (newName != null && newName.isNotEmpty) {
                  final ok = await const MethodChannel('kr.ssing.catsong/media')
                      .invokeMethod<bool>('renameVideo', {
                    'uri': widget.video.uri,
                    'newName': newName,
                  });
                  if (ok != true || !context.mounted) return; // 폰 확인 창에서 취소하면 그대로
                  final vp = context.read<VideoProvider>();
                  await vp.carrySeen(widget.video.uri, newName); // 이름 바꿔도 NEW 안 붙게
                  vp.loadVideos(quiet: true);
                  if (!context.mounted) return;
                  showActionFeedback(context, type: ActionFeedbackType.edited, message: '이름을 바꿨어요');
                  Navigator.pop(context);
                }
              } else if (value == 'delete') {
                // 목록과 같은 삭제 창 (휴지통 / 영구 삭제)
                if (await deleteVideosFlow(context, [widget.video]) && context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _chewieController != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Chewie(controller: _chewieController!),
                          // 두 번 탭: 왼쪽 10초 뒤로 · 오른쪽 10초 앞으로 (아래 조작 막대 자리는 비워둠)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 56,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onDoubleTap: () => _doubleTapSeek(-1),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onDoubleTap: () => _doubleTapSeek(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 누른 쪽에 잠깐: 동그라미 + 선 아이콘 + "10초"
                          if (_seekSide != 0)
                            Positioned(
                              left: _seekSide < 0 ? 28 : null,
                              right: _seekSide > 0 ? 28 : null,
                              child: IgnorePointer(
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_seekSide < 0 ? Icons.fast_rewind_rounded : Icons.fast_forward_rounded,
                                          color: Colors.white, size: 26),
                                      const SizedBox(height: 2),
                                      Text('$_seekSec초',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // TV로 보는 중이면 화면을 가리고 TV 조작
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: CastService.instance,
                              builder: (context, _) =>
                                  _castingHere ? _castPanel() : const IgnorePointer(child: SizedBox.shrink()),
                            ),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            // 구간 반복 막대 (⋮ → 구간 반복)
            if (_loopOn) _loopBar(),
          ],
        ),
      ),
    );
  }
}