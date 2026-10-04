import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/index_letter.dart';

/// 파란소리 포인트 블루 / 연한 배경
const kIndexBlue = Color(0xFF2589E8);
const kIndexBg = Color(0xFFEDF4F8);
/// 평소 글자색: 차분한 회갈색 (라이트 / 다크)
const kIndexMuted = Color(0xFF8A857B);
const kIndexMutedDark = Color(0xFFA29A8B);

/// 곡 목록 오른쪽 세로 빠른 이동 막대
/// 항목은 항상 A-Z / ㄱ ~ ㅎ / # 16개. 곡이 없는 글자는 연하게, 누르면 가까운 글자로.
class IndexBar extends StatefulWidget {
  final Set<String> available; // 실제 곡이 있는 묶음 (A-Z, ㄱ, ㄴ ... #)
  final bool isDark;
  final ValueChanged<String> onLetter; // 묶음 바뀔 때마다 (점프)
  final ValueChanged<String?> onActiveChanged; // 가운데 큰 글자 표시용

  const IndexBar({
    super.key,
    required this.available,
    required this.isDark,
    required this.onLetter,
    required this.onActiveChanged,
  });

  @override
  State<IndexBar> createState() => _IndexBarState();
}

class _IndexBarState extends State<IndexBar> {
  String? _active;
  int _releaseToken = 0;

  /// 누른 칸에 곡이 없으면 아래쪽 → 위쪽으로 가장 가까운 글자
  String? _resolve(int i) {
    const g = kIndexGroups;
    for (var k = i; k < g.length; k++) {
      if (widget.available.contains(g[k])) return g[k];
    }
    for (var k = i - 1; k >= 0; k--) {
      if (widget.available.contains(g[k])) return g[k];
    }
    return null;
  }

  void _handle(double dy, double height) {
    if (height <= 0) return;
    final i = (dy / height * kIndexGroups.length)
        .floor()
        .clamp(0, kIndexGroups.length - 1);
    final g = _resolve(i);
    if (g == null || g == _active) return;
    _releaseToken++; // 사라지기 예약 취소
    setState(() => _active = g);
    HapticFeedback.selectionClick();
    widget.onActiveChanged(g);
    widget.onLetter(g);
  }

  void _release() {
    if (_active == null) return;
    setState(() => _active = null);
    // 큰 글자 팝업은 손 떼고 잠시 뒤에 사라짐
    final token = ++_releaseToken;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && token == _releaseToken) widget.onActiveChanged(null);
    });
  }

  Widget _item(String g) {
    final isActive = g == _active;
    final has = widget.available.contains(g);
    final isAZ = g == 'A-Z';
    final text = Text(
      g,
      style: TextStyle(
        color: isActive
            ? Colors.white
            : (widget.isDark ? kIndexMutedDark : kIndexMuted)
                .withOpacity(has ? 1.0 : 0.35),
        fontSize: isAZ ? 11.5 : 14.5,
        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
        height: 1.0,
      ),
    );
    if (!isActive) return text;
    return Container(
      height: 24,
      constraints: const BoxConstraints(minWidth: 24),
      padding: EdgeInsets.symmetric(horizontal: isAZ ? 4 : 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kIndexBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final h = cons.maxHeight;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (d) => _handle(d.localPosition.dy, h),
        onVerticalDragUpdate: (d) => _handle(d.localPosition.dy, h),
        onVerticalDragEnd: (_) => _release(),
        onVerticalDragCancel: _release,
        onTapDown: (d) => _handle(d.localPosition.dy, h),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        // 터치 영역은 넓게(36), 보이는 띠는 좁게(30)
        child: SizedBox(
          width: 36,
          child: Center(
            child: Container(
              width: 30,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent, // 막대 배경 없음
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: kIndexGroups
                    .map((g) => Expanded(child: Center(child: _item(g))))
                    .toList(),
              ),
            ),
          ),
        ),
      );
    });
  }
}