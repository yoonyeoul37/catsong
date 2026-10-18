import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/index_letter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// 파란소리 포인트 블루 / 연한 배경
Color kIndexBlue = const Color(0xFF2589E8); // 포인트 색 (그릴 때마다 설정 색으로)
const kIndexBg = Color(0xFFEDF4F8);
/// 평소 글자색: 차분한 회갈색 (라이트 / 다크)
const kIndexMuted = Color(0xFF8A857B);
const kIndexMutedDark = Color(0xFFB8B0A2);

/// 곡 목록 오른쪽 세로 빠른 이동 막대
/// 한국어: A-Z / ㄱ ~ ㅎ / # 16칸 그대로 (곡 없는 글자는 연하게, 누르면 가까운 글자로)
/// 다른 언어(A~Z 27칸 등): 곡 있는 글자만 크게 보이고, 그래도 칸이 좁으면 하나 걸러 • 점 (아이폰 연락처 방식)
class IndexBar extends StatefulWidget {
  final Set<String> available; // 실제 곡이 있는 묶음 (A-Z, ㄱ, ㄴ ... #)
  final bool isDark;
  final ValueChanged<String> onLetter; // 묶음 바뀔 때마다 (점프)
  final String? current; // 지금 보고 있는 구간 (파란 글자로 표시)
  final ValueChanged<String?> onActiveChanged; // 가운데 큰 글자 표시용
  final List<String> groups; // 막대 칸 (폰 언어별)

  const IndexBar({
    super.key,
    required this.available,
    required this.isDark,
    required this.onLetter,
    required this.onActiveChanged,
    this.current,
    this.groups = kIndexGroups,
  });

  @override
  State<IndexBar> createState() => _IndexBarState();
}

class _IndexBarState extends State<IndexBar> {
  String? _active;
  int _releaseToken = 0;

  /// 한 칸 최소 높이 — 이보다 좁으면 하나 걸러 점으로 (손가락으로 누를 수 있게)
  static const double _minSlot = 20;

  /// 실제로 막대에 보이는 칸: 한국어(16칸 이하)는 그대로, 긴 언어는 곡 있는 글자만
  List<String> get _shown {
    final g = widget.groups;
    if (g.length <= 16) return g;
    final only = g.where(widget.available.contains).toList();
    return only.isEmpty ? g : only;
  }

  /// 누른 칸에 곡이 없으면 아래쪽 → 위쪽으로 가장 가까운 글자
  String? _resolve(int i) {
    final g = _shown;
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
    final n = _shown.length;
    final i = (dy / height * n).floor().clamp(0, n - 1);
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

  Widget _item(String g, {bool dot = false}) {
    final isActive = g == _active;
    final has = widget.available.contains(g);
    final isAZ = g == 'A-Z';
    // 하나 걸러 점: 누르고 있거나 지금 보는 글자가 아니면 작은 점만
    if (dot && !isActive && g != widget.current) {
      return Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: (widget.isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.8),
          shape: BoxShape.circle,
        ),
      );
    }
    final longBar = widget.groups.length > 16; // 다른 언어 (곡 있는 글자만 보여서 칸이 넓음)
    final text = Text(
      g,
      style: TextStyle(
        color: isActive
            ? Colors.white
            : g == widget.current
                ? kIndexBlue // 지금 보고 있는 구간
                : (widget.isDark ? kIndexMutedDark : kIndexMuted)
                    .withOpacity(has ? 1.0 : 0.35),
        fontSize: isAZ ? 11.5 : (longBar ? 15 : 14.5),
        fontWeight: (isActive || g == widget.current) ? FontWeight.w900 : FontWeight.w800,
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
    kIndexBlue = context.watch<ThemeProvider>().primaryColor; // 초성 표시 = 포인트 색
    return LayoutBuilder(builder: (context, cons) {
      final h = cons.maxHeight;
      final shown = _shown;
      // 한 칸이 너무 좁으면 홀수 칸은 점으로 (# 은 늘 글자)
      final useDots = shown.length > 16 && h > 0 && (h - 12) / shown.length < _minSlot;
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
                color: Colors.transparent, // 막대 배경 없음 (초성 글자만)
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Expanded(
                      child: Center(
                        child: _item(shown[i], dot: useDots && i.isOdd && shown[i] != '#'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}