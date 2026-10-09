import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/video.dart';
import '../l10n/app_localizations.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/video_provider.dart';
import '../widgets/action_feedback.dart';
import '../widgets/paran_dialog.dart';
import '../widgets/paran_toast.dart';

const _media = MethodChannel('kr.ssing.catsong/media');
void _vib() => _media.invokeMethod('vibrate');

/// 동영상 소리만 뽑아서 음악으로 저장 (Music/Paransori · m4a) — 저장됐으면 true
Future<bool> saveVideoAudio(BuildContext context, Video video, int startMs, int endMs, {bool whole = false}) async {
  try {
    final saved = await _media.invokeMethod<String>('extractAudio', {
      'path': video.uri,
      'startMs': startMs,
      'endMs': endMs,
      'outBase': whole ? video.title : '${video.title}_자름',
    });
    if (!context.mounted) return saved != null;
    if (saved == null) {
      showParanToast(context, '음악으로 저장하지 못했어요', error: true);
      return false;
    }
    context.read<MusicProvider>().loadSongs(); // 음악 목록에 바로 보이게
    showActionFeedback(context,
        type: ActionFeedbackType.saved, message: '음악으로 저장했어요', icon: Icons.music_note_rounded);
    return true;
  } catch (e) {
    if (context.mounted) showParanToast(context, '음악으로 저장하지 못했어요', error: true);
    return false;
  }
}

/// 음악으로 저장: 전체 저장 / 구간 골라서 저장 (앱 공통 고르는 창)
Future<void> showSaveAudioSheet(BuildContext context, Video video) async {
  final isDark = context.read<ThemeProvider>().isDarkMode;
  final sub = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
  final pick = await showParanSheet<String>(
    context,
    title: '음악으로 저장',
    builder: (ctx, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text('영상의 소리만 뽑아서 음악 목록에 넣어요',
              style: TextStyle(color: sub, fontSize: 13, height: 1.4)),
        ),
        ParanCard(children: [
          ParanRow(
            icon: Icons.music_note_rounded,
            title: '전체 저장',
            trailingText: video.durationFormatted,
            onTap: () => Navigator.pop(ctx, 'all'),
          ),
          ParanRow(
            icon: Icons.content_cut_rounded,
            title: '구간 골라서 저장',
            onTap: () => Navigator.pop(ctx, 'pick'),
          ),
        ]),
      ],
    ),
  );
  if (!context.mounted || pick == null) return;
  if (pick == 'all') {
    await saveVideoAudio(context, video, 0, video.duration, whole: true);
  } else {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoTrimScreen(video: video, audioOnly: true)),
    );
  }
}

/// 동영상 자르기 화면 (벨소리·녹음 자르기 화면과 같은 모양)
/// audioOnly = false: 잘라서 보내기 / 저장만 · true: 고른 구간을 음악으로 저장
class VideoTrimScreen extends StatefulWidget {
  final Video video;
  final bool audioOnly;
  const VideoTrimScreen({super.key, required this.video, this.audioOnly = false});

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  late final VideoPlayerController _ctrl;
  double _max = 1; // 영상 길이 (초)
  double _start = 0;
  double _end = 1;
  bool _previewing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _max = widget.video.duration > 1000 ? widget.video.duration / 1000 : 1;
    _end = _max;
    _ctrl = VideoPlayerController.file(File(widget.video.uri));
    _ctrl.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _ctrl.addListener(_onTick);
  }

  // 미리 보기: 고른 끝에 닿으면 멈추기
  void _onTick() {
    if (!_previewing) return;
    if (_ctrl.value.position.inMilliseconds >= (_end * 1000).toInt()) {
      _ctrl.pause();
      if (mounted) setState(() => _previewing = false);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTick);
    _ctrl.dispose();
    super.dispose();
  }

  int get _startMs => (_start * 1000).toInt();
  int get _endMs => _end >= _max ? widget.video.duration : (_end * 1000).toInt();

  Future<void> _togglePreview() async {
    if (!_ctrl.value.isInitialized) return;
    _vib();
    if (_previewing) {
      await _ctrl.pause();
      setState(() => _previewing = false);
      return;
    }
    await _ctrl.seekTo(Duration(milliseconds: _startMs));
    await _ctrl.play();
    setState(() => _previewing = true);
  }

  Future<void> _stopPreview() async {
    if (!_previewing) return;
    await _ctrl.pause();
    if (mounted) setState(() => _previewing = false);
  }

  // 잘라서 저장 (send = true면 저장 후 바로 공유 창)
  Future<void> _cut({required bool send}) async {
    await _stopPreview();
    if (send && _end - _start > 600) {
      final ok = await showParanConfirm(
        context,
        title: '긴 동영상이에요',
        message: '10분이 넘는 영상은 카카오톡으로 안 보내질 수 있어요.\n구글 드라이브나 메일로 보내면 잘 가요.',
        confirmLabel: '보내기',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final saved = await _media.invokeMethod<String>('trimVideo', {
        'path': widget.video.uri,
        'startMs': _startMs,
        'endMs': _endMs,
        'outBase': '${widget.video.title}_자름',
      });
      if (!mounted) return;
      if (saved == null) {
        showParanToast(context, '자르지 못했어요', error: true);
        return;
      }
      context.read<VideoProvider>().loadVideos(quiet: true); // 동영상 목록에 바로 보이게
      if (send) {
        await Share.shareXFiles([XFile(saved)], text: widget.video.titleDisplay);
      } else {
        showActionFeedback(context,
            type: ActionFeedbackType.saved, message: '잘라서 저장했어요', icon: Icons.content_cut_rounded);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showParanToast(context, '자르지 못했어요', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAudio() async {
    await _stopPreview();
    setState(() => _busy = true);
    final ok = await saveVideoAudio(context, widget.video, _startMs, _endMs, whole: _start == 0 && _end >= _max);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  String _fmt(double sec) {
    final s = sec.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  String _len(double sec) {
    final s = sec.round();
    return s >= 60 ? '${s ~/ 60}분 ${s % 60}초' : '$s초';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    // ── 벨소리·녹음 자르기 화면과 같은 모양 (베이지 바탕 · 흰 카드 · 먹색 큰 버튼) ──
    final bg = isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final card = isDark ? const Color(0xFF32302C) : Colors.white;
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = isDark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    final point = context.watch<ThemeProvider>().primaryColor;
    final ready = _ctrl.value.isInitialized;
    final l = AppLocalizations.of(context)!;

    Widget section(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text(text, style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
        );
    Widget whiteCard(Widget child, {EdgeInsets padding = const EdgeInsets.all(14)}) => Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
          child: child,
        );
    Widget timeChip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration:
              BoxDecoration(color: point.withOpacity(isDark ? 0.18 : 0.08), borderRadius: BorderRadius.circular(12)),
          child: Text(t, style: TextStyle(color: point, fontSize: 12.5, fontWeight: FontWeight.w700)),
        );
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: point,
      inactiveTrackColor: line,
      thumbColor: point,
      overlayColor: point.withOpacity(0.1),
      trackHeight: 3,
    );
    Widget rangeRow(String label, double value, ValueChanged<double> onChanged) => Row(
          children: [
            SizedBox(width: 40, child: Text(label, style: TextStyle(color: sub, fontSize: 13))),
            Expanded(
              child: SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: value.clamp(0, _max).toDouble(),
                  min: 0,
                  max: _max,
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (_previewing) {
                            _ctrl.pause();
                            _previewing = false;
                          }
                          onChanged(v);
                        },
                  // 손을 떼면 그 장면을 미리 보기에 보여주기
                  onChangeEnd: (v) {
                    if (ready) _ctrl.seekTo(Duration(milliseconds: (v * 1000).toInt()));
                  },
                ),
              ),
            ),
            SizedBox(
                width: 44,
                child: Text(_fmt(value), textAlign: TextAlign.right, style: TextStyle(color: ink, fontSize: 13))),
          ],
        );

    final mainStyle = ElevatedButton.styleFrom(
      backgroundColor: ink,
      foregroundColor: bg,
      disabledBackgroundColor: ink.withOpacity(0.5),
      disabledForegroundColor: bg,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    final subStyle = OutlinedButton.styleFrom(
      backgroundColor: card,
      foregroundColor: ink,
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    Widget spinner() =>
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: bg));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        title: Text(widget.audioOnly ? '음악으로 저장' : '잘라서 보내기',
            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        leading: IconButton(
          onPressed: () {
            _vib();
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 20),
        ),
      ),
      // 버튼은 맨 아래에 모아서 (벨소리 자르기와 같게)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 미리 보기 (흰 버튼)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: ready && !_busy ? _togglePreview : null,
                  style: subStyle,
                  icon: Icon(_previewing ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
                  label: Text(_previewing ? '멈추기' : (widget.audioOnly ? '미리 듣기' : '미리 보기'),
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.audioOnly)
                // 음악으로 저장 (먹색 큰 버튼)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _saveAudio,
                    style: mainStyle,
                    icon: _busy ? spinner() : const Icon(Icons.music_note_rounded, size: 20),
                    label: const Text('음악으로 저장', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                )
              else
                // 저장만 (흰 버튼) · 보내기 (먹색 큰 버튼)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _cut(send: false),
                          style: subStyle,
                          icon: const Icon(Icons.save_alt_rounded, size: 20),
                          label: const Text('저장만', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : () => _cut(send: true),
                          style: mainStyle,
                          icon: _busy ? spinner() : const Icon(Icons.ios_share_rounded, size: 20),
                          label: const Text('보내기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 영상 미리 보기 (세로 영상도 화면을 다 덮지 않게 높이 고정)
            GestureDetector(
              onTap: ready && !_busy ? _togglePreview : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.34,
                  width: double.infinity,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: ready
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
                            if (!_previewing)
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                              ),
                          ],
                        )
                      : const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(widget.video.titleDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
            section(l.selectRange),
            whiteCard(
              Column(
                children: [
                  rangeRow(l.start, _start, (v) {
                    if (v < _end - 1) setState(() => _start = v);
                  }),
                  rangeRow(l.end, _end, (v) {
                    if (v > _start + 1) setState(() => _end = v);
                  }),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      timeChip(_fmt(_start)),
                      Text(_len(_end - _start), style: TextStyle(color: sub, fontSize: 12.5)),
                      timeChip(_fmt(_end)),
                    ],
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 14),
            ),
            // 짧은 안내 (회색)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(
                widget.audioOnly
                    ? '고른 구간의 소리만 음악 목록에 저장해요 (Music/Paransori · M4A)'
                    : '원본은 그대로 두고 잘라낸 영상을 새로 저장해요 (Movies/Paransori)\n다시 압축하지 않아 화질 그대로예요. 시작이 1초쯤 앞당겨질 수 있어요',
                style: TextStyle(color: sub, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
