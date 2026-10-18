# -*- coding: utf-8 -*-
# 곡 목록 오른쪽 빠른 이동 막대 (index_bar.dart)
#  - 한국어(16칸)는 그대로
#  - 다른 언어(A~Z 27칸, 러시아어 30칸 등): 곡 있는 글자만 크게(15) 보여 주고,
#    그래도 한 칸이 20보다 좁으면 하나 걸러 • 점 (아이폰 연락처 방식, 점을 눌러도 그 글자로)
import os, sys

PATH = os.path.join('lib', 'widgets', 'index_bar.dart')
EDITS = [
 [
  "\n/// 곡 목록 오른쪽 세로 빠른 이동 막대\n/// 항목은 항상 A-Z / ㄱ ~ ㅎ / # 16개. 곡이 없는 글자는 연하게, 누르면 가까운 글자로.\nclass IndexBar extends StatefulWidget {\n  final Set<String> available; // 실제 곡이 있는 묶음 (A-Z, ㄱ, ㄴ ... #)\n",
  "\n/// 곡 목록 오른쪽 세로 빠른 이동 막대\n/// 한국어: A-Z / ㄱ ~ ㅎ / # 16칸 그대로 (곡 없는 글자는 연하게, 누르면 가까운 글자로)\n/// 다른 언어(A~Z 27칸 등): 곡 있는 글자만 크게 보이고, 그래도 칸이 좁으면 하나 걸러 • 점 (아이폰 연락처 방식)\nclass IndexBar extends StatefulWidget {\n  final Set<String> available; // 실제 곡이 있는 묶음 (A-Z, ㄱ, ㄴ ... #)\n"
 ],
 [
  "  int _releaseToken = 0;\n\n  /// 누른 칸에 곡이 없으면 아래쪽 → 위쪽으로 가장 가까운 글자\n  String? _resolve(int i) {\n",
  "  int _releaseToken = 0;\n\n  /// 한 칸 최소 높이 — 이보다 좁으면 하나 걸러 점으로 (손가락으로 누를 수 있게)\n  static const double _minSlot = 20;\n\n  /// 실제로 막대에 보이는 칸: 한국어(16칸 이하)는 그대로, 긴 언어는 곡 있는 글자만\n  List<String> get _shown {\n    final g = widget.groups;\n    if (g.length <= 16) return g;\n    final only = g.where(widget.available.contains).toList();\n    return only.isEmpty ? g : only;\n  }\n\n  /// 누른 칸에 곡이 없으면 아래쪽 → 위쪽으로 가장 가까운 글자\n  String? _resolve(int i) {\n"
 ],
 [
  "  /// 누른 칸에 곡이 없으면 아래쪽 → 위쪽으로 가장 가까운 글자\n  String? _resolve(int i) {\n    final g = widget.groups;\n    for (var k = i; k < g.length; k++) {\n      if (widget.available.contains(g[k])) return g[k];\n",
  "  /// 누른 칸에 곡이 없으면 아래쪽 → 위쪽으로 가장 가까운 글자\n  String? _resolve(int i) {\n    final g = _shown;\n    for (var k = i; k < g.length; k++) {\n      if (widget.available.contains(g[k])) return g[k];\n"
 ],
 [
  "  void _handle(double dy, double height) {\n    if (height <= 0) return;\n    final n = widget.groups.length;\n    final i = (dy / height * n).floor().clamp(0, n - 1);\n    final g = _resolve(i);\n",
  "  void _handle(double dy, double height) {\n    if (height <= 0) return;\n    final n = _shown.length;\n    final i = (dy / height * n).floor().clamp(0, n - 1);\n    final g = _resolve(i);\n"
 ],
 [
  "  }\n\n  Widget _item(String g) {\n    final isActive = g == _active;\n    final has = widget.available.contains(g);\n",
  "  }\n\n  Widget _item(String g, {bool dot = false}) {\n    final isActive = g == _active;\n    final has = widget.available.contains(g);\n"
 ],
 [
  "    final has = widget.available.contains(g);\n    final isAZ = g == 'A-Z';\n    final text = Text(\n      g,\n",
  "    final has = widget.available.contains(g);\n    final isAZ = g == 'A-Z';\n    // 하나 걸러 점: 누르고 있거나 지금 보는 글자가 아니면 작은 점만\n    if (dot && !isActive && g != widget.current) {\n      return Container(\n        width: 4,\n        height: 4,\n        decoration: BoxDecoration(\n          color: (widget.isDark ? kIndexMutedDark : kIndexMuted).withOpacity(0.8),\n          shape: BoxShape.circle,\n        ),\n      );\n    }\n    final longBar = widget.groups.length > 16; // 다른 언어 (곡 있는 글자만 보여서 칸이 넓음)\n    final text = Text(\n      g,\n"
 ],
 [
  "                : (widget.isDark ? kIndexMutedDark : kIndexMuted)\n                    .withOpacity(has ? 1.0 : 0.35),\n        fontSize: isAZ ? 11.5 : (widget.groups.length > 20 ? 12.5 : 14.5),\n        fontWeight: (isActive || g == widget.current) ? FontWeight.w900 : FontWeight.w800,\n        height: 1.0,\n",
  "                : (widget.isDark ? kIndexMutedDark : kIndexMuted)\n                    .withOpacity(has ? 1.0 : 0.35),\n        fontSize: isAZ ? 11.5 : (longBar ? 15 : 14.5),\n        fontWeight: (isActive || g == widget.current) ? FontWeight.w900 : FontWeight.w800,\n        height: 1.0,\n"
 ],
 [
  "    return LayoutBuilder(builder: (context, cons) {\n      final h = cons.maxHeight;\n      return GestureDetector(\n        behavior: HitTestBehavior.opaque,\n",
  "    return LayoutBuilder(builder: (context, cons) {\n      final h = cons.maxHeight;\n      final shown = _shown;\n      // 한 칸이 너무 좁으면 홀수 칸은 점으로 (# 은 늘 글자)\n      final useDots = shown.length > 16 && h > 0 && (h - 12) / shown.length < _minSlot;\n      return GestureDetector(\n        behavior: HitTestBehavior.opaque,\n"
 ],
 [
  "              ),\n              child: Column(\n                children: widget.groups\n                    .map((g) => Expanded(child: Center(child: _item(g))))\n                    .toList(),\n              ),\n            ),\n",
  "              ),\n              child: Column(\n                children: [\n                  for (var i = 0; i < shown.length; i++)\n                    Expanded(\n                      child: Center(\n                        child: _item(shown[i], dot: useDots && i.isOdd && shown[i] != '#'),\n                      ),\n                    ),\n                ],\n              ),\n            ),\n"
 ]
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    raw = open(PATH, 'rb').read(); crlf = b'\r\n' in raw
    t = raw.decode('utf-8').replace('\r\n', '\n')
    if '_minSlot' in t:
        print('이미 적용돼 있어요'); return 0
    ok = True
    for i, (old, new) in enumerate(EDITS, 1):
        if t.count(old) == 1:
            t = t.replace(old, new); print('✔ %d번째 고칠 곳' % i)
        else:
            print('❌ %d번째 고칠 곳을 못 찾았어요' % i); ok = False
    for o, c in ['()', '[]', '{}']:
        if t.count(o) != t.count(c):
            print('❌ 괄호 개수가 안 맞아요', o, c); ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if crlf: t = t.replace('\n', '\r\n')
    open(PATH, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요:', PATH)
    return 0

if __name__ == '__main__':
    sys.exit(main())
