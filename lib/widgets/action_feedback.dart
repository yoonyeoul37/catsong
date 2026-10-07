import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// 완료 피드백 종류
enum ActionFeedbackType { edited, deleted, saved, added }

/// 큰 작업이 끝났을 때: 가운데 카드 + [원래대로] [확인] (8초 지나면 저절로 슝)
void showActionFeedbackWithUndo(
  BuildContext context, {
  required String message,
  String subMessage = '마음에 안 들면 원래대로 돌릴 수 있어요',
  required Future<void> Function() onUndo,
  int seconds = 8,
}) {
  if (!context.mounted) return;
  final overlay = Navigator.maybeOf(context, rootNavigator: true)?.overlay ??
      Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  var isDark = false;
  var soundOn = true;
  try {
    isDark = context.read<ThemeProvider>().isDarkMode;
    soundOn = context.read<ThemeProvider>().feedbackSoundEnabled;
  } catch (_) {}
  if (_current != null && _current!.mounted) _current!.remove();
  _current = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _UndoFeedback(
      message: message,
      subMessage: subMessage,
      isDark: isDark,
      seconds: seconds,
      onUndo: onUndo,
      onDone: () {
        if (entry.mounted) entry.remove();
        if (identical(_current, entry)) _current = null;
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
  if (soundOn) {
    try {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('feedbackSound', {'low': false});
    } catch (_) {}
  }
}

class _UndoFeedback extends StatefulWidget {
  final String message;
  final String subMessage;
  final bool isDark;
  final int seconds;
  final Future<void> Function() onUndo;
  final VoidCallback onDone;
  const _UndoFeedback({
    required this.message,
    required this.subMessage,
    required this.isDark,
    required this.seconds,
    required this.onUndo,
    required this.onDone,
  });

  @override
  State<_UndoFeedback> createState() => _UndoFeedbackState();
}

class _UndoFeedbackState extends State<_UndoFeedback> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final AnimationController _life =
      AnimationController(vsync: this, duration: Duration(seconds: widget.seconds));
  late final AnimationController _out =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _in.forward();
    _life.addStatusListener((s) {
      if (s == AnimationStatus.completed) _close();
    });
    _life.forward();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _life.stop();
    final done = widget.onDone;
    await _out.forward(); // 오른쪽으로 슝
    done();
  }

  @override
  void dispose() {
    _in.dispose();
    _life.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final ink = widget.isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = widget.isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final line = widget.isDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);
    final bg = widget.isDark ? const Color(0xFF2A251E) : Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_in, _out, _life]),
      builder: (_, __) {
        // 등장: 0.9 → 1.05 → 1.0 / 사라짐: 점점 빨라지며 오른쪽으로
        final p = Curves.easeOut.transform(_in.value);
        final scale = _in.value < 0.65
            ? lerpDouble(0.9, 1.05, _in.value / 0.65)!
            : lerpDouble(1.05, 1.0, (_in.value - 0.65) / 0.35)!;
        final q = _out.value;
        final dx = Curves.easeInCubic.transform(q) * width * 0.6;
        final opacity = (p * (1 - Curves.easeIn.transform(q))).clamp(0.0, 1.0);
        return Center(
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: scale,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: (width * 0.8).clamp(0, 320).toDouble(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    decoration: BoxDecoration(
                      color: bg.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(widget.isDark ? 0.35 : 0.16),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2589E8), size: 46),
                        const SizedBox(height: 8),
                        Text(widget.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(widget.subMessage,
                            textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 12.5)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            // 원래대로: 정리하기 전으로
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    if (_closing) return;
                                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                    final undo = widget.onUndo;
                                    await _close();
                                    await undo();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ink,
                                    side: BorderSide(color: line),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('원래대로',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 확인: 이대로 두고 닫기
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: _close,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ink,
                                    foregroundColor: bg,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('확인',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 남은 시간 막대 (다 줄면 저절로 닫힘)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: LinearProgressIndicator(
                            value: 1 - _life.value,
                            minHeight: 2,
                            backgroundColor: line,
                            color: sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

OverlayEntry? _current; // 지금 떠 있는 피드백 (새 게 오면 바로 치움)

/// 화면 가운데에 "✓ 수정했어요" 같은 피드백을 잠깐 띄움
/// - 화면을 어둡게 하지 않고, 터치도 막지 않음
/// - 사용: showActionFeedback(context, type: ActionFeedbackType.deleted);
/// - 문구를 바꾸고 싶으면 message: '재생목록에 추가했어요'
void showActionFeedback(BuildContext context,
    {required ActionFeedbackType type, String? message, IconData? icon}) {
  if (!context.mounted) return; // 화면이 이미 닫혔으면 안 띄움
  // 앱 맨 위 화면 판에 띄우기 (메뉴·확인창이 먼저 닫혀도 확실하게)
  final overlay = Navigator.maybeOf(context, rootNavigator: true)?.overlay ??
      Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  var isDark = false;
  var soundOn = true; // 설정 → 효과음
  try {
    isDark = context.read<ThemeProvider>().isDarkMode;
    soundOn = context.read<ThemeProvider>().feedbackSoundEnabled;
  } catch (_) {}

  // 이전 피드백이 아직 있으면 바로 치우기 (겹치지 않게)
  if (_current != null && _current!.mounted) _current!.remove();
  _current = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ActionFeedback(
      type: type,
      message: message,
      icon: icon,
      isDark: isDark,
      onDone: () {
        if (entry.mounted) entry.remove();
        if (identical(_current, entry)) _current = null;
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);

  // 소리 모드면 물방울 "똑" (삭제는 "똑똑"), 진동 모드면 진동, 무음이면 없음
  if (soundOn) {
    try {
      const MethodChannel('kr.ssing.catsong/media')
          .invokeMethod('feedbackSound', {'low': type == ActionFeedbackType.deleted});
    } catch (_) {}
  }
}

class _ActionFeedback extends StatefulWidget {
  final ActionFeedbackType type;
  final String? message;
  final IconData? icon; // 자르기·벨소리·잠금처럼 다른 아이콘이 필요할 때
  final bool isDark;
  final VoidCallback onDone;
  const _ActionFeedback(
      {required this.type, this.message, this.icon, required this.isDark, required this.onDone});

  @override
  State<_ActionFeedback> createState() => _ActionFeedbackState();
}

class _ActionFeedbackState extends State<_ActionFeedback> with SingleTickerProviderStateMixin {
  // 속도: 등장 220ms · 머무름 800ms · 사라짐 320ms (전체 1.34초)
  static const _appearMs = 220;
  static const _holdMs = 800;
  static const _exitMs = 320;
  static const _totalMs = _appearMs + _holdMs + _exitMs;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  (IconData, Color, String) get _look {
    const blue = Color(0xFF2589E8);
    const red = Color(0xFFE05A4F);
    switch (widget.type) {
      case ActionFeedbackType.edited:
        return (Icons.check_circle_rounded, blue, '수정했어요');
      case ActionFeedbackType.deleted:
        return (Icons.delete_rounded, red, '삭제했어요');
      case ActionFeedbackType.saved:
        return (Icons.check_circle_rounded, blue, '저장했어요');
      case ActionFeedbackType.added:
        return (Icons.add_circle_rounded, blue, '추가했어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, text) = _look;
    final width = MediaQuery.of(context).size.width;
    const a = _appearMs / _totalMs; // 등장이 끝나는 지점
    const h = (_appearMs + _holdMs) / _totalMs; // 머무름이 끝나는 지점

    return IgnorePointer(
      // 애니메이션 중에도 아래 화면 터치는 그대로 됨
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          double opacity = 1, scale = 1, dx = 0;
          if (t < a) {
            // 등장: 빠르게 나타나며 0.9 → 1.05 → 1.0
            final p = t / a;
            opacity = Curves.easeOut.transform((p / 0.6).clamp(0.0, 1.0));
            scale = p < 0.65
                ? lerpDouble(0.9, 1.05, Curves.easeOut.transform(p / 0.65))!
                : lerpDouble(1.05, 1.0, Curves.easeInOut.transform((p - 0.65) / 0.35))!;
          } else if (t >= h) {
            // 사라짐: 점점 빨라지며 오른쪽으로 "슝" + 흐려짐
            final q = ((t - h) / (1 - h)).clamp(0.0, 1.0);
            dx = Curves.easeInCubic.transform(q) * width * 0.6;
            opacity = 1 - Curves.easeIn.transform(q);
          }
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.35 : 0.16),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF2A251E).withOpacity(0.82)
                          : Colors.white.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon ?? icon, color: iconColor, size: 52),
                        const SizedBox(height: 8),
                        Text(
                          widget.message ?? text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}