import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 곡 목록 오른쪽 세로 빠른 이동 막대 (A~Z, ㄱ~ㅎ, #)
/// 평소엔 은은하게, 손가락 대는 동안만 진하게.
class IndexBar extends StatefulWidget {
  final List<String> letters; // 실제 곡이 있는 글자만
  final ValueChanged<String> onLetter; // 글자 바뀔 때마다 (점프)
  final ValueChanged<String?> onActiveChanged; // 가운데 큰 글자 표시용
  final Color color;

  const IndexBar({
    super.key,
    required this.letters,
    required this.onLetter,
    required this.onActiveChanged,
    required this.color,
  });

  @override
  State<IndexBar> createState() => _IndexBarState();
}

class _IndexBarState extends State<IndexBar> {
  String? _active;

  void _handle(double dy, double height) {
    final letters = widget.letters;
    if (letters.isEmpty || height <= 0) return;
    final i = (dy / height * letters.length).floor().clamp(0, letters.length - 1);
    final l = letters[i];
    if (l == _active) return;
    setState(() => _active = l);
    HapticFeedback.selectionClick();
    widget.onActiveChanged(l);
    widget.onLetter(l);
  }

  void _release() {
    if (_active == null) return;
    setState(() => _active = null);
    widget.onActiveChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final h = cons.maxHeight;
      final letters = widget.letters;

      // 자리가 모자라면 글자 사이를 점(·)으로 줄여서 보여줌 (누르는 건 전체 글자 기준)
      final maxVisible = (h / 15).floor().clamp(3, 1000);
      List<String> shown;
      if (letters.length <= maxVisible) {
        shown = letters;
      } else {
        final slots = maxVisible.isOdd ? maxVisible : maxVisible - 1;
        shown = [];
        for (int i = 0; i < slots; i++) {
          if (i.isEven) {
            final idx = (i * (letters.length - 1) / (slots - 1)).round();
            shown.add(letters[idx]);
          } else {
            shown.add('·');
          }
        }
      }

      final touching = _active != null;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (d) => _handle(d.localPosition.dy, h),
        onVerticalDragUpdate: (d) => _handle(d.localPosition.dy, h),
        onVerticalDragEnd: (_) => _release(),
        onVerticalDragCancel: _release,
        onTapDown: (d) => _handle(d.localPosition.dy, h),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          decoration: BoxDecoration(
            color: touching ? widget.color.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: shown.map((l) {
              final isActive = l == _active;
              return Text(
                l,
                style: TextStyle(
                  color: widget.color.withOpacity(
                      isActive ? 1.0 : (touching ? 0.85 : 0.55)),
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}