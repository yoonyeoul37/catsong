# 음악 목록: 살포시 떠오르기 / 라디오 목록: 주파수 맞추기
import os, sys

SONG = os.path.join('lib', 'widgets', 'song_list_tile.dart')
RADIO = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')

RISE_CLASS = r'''

/// 곡 줄이 화면에 나타날 때 아래에서 살포시 떠오르게
class _RiseIn extends StatefulWidget {
  final Widget child;
  const _RiseIn({required this.child});

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = curve;
    _slide = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(curve);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
'''

DIAL_CLASSES = r'''

// ══════════════════════════════════════════
// 주파수 맞추기: 끝으로 갈수록 작아지고 흐려짐 + 가운데 방송 표시
// ══════════════════════════════════════════
class _DialScope extends InheritedWidget {
  final ValueNotifier<bool> tuned;
  final ValueNotifier<bool> scrolling;
  const _DialScope({required this.tuned, required this.scrolling, required super.child});

  static _DialScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_DialScope>();

  @override
  bool updateShouldNotify(_DialScope old) => old.tuned != tuned || old.scrolling != scrolling;
}

class _DialItem extends StatefulWidget {
  final ValueNotifier<bool> scrolling;
  final Widget child;
  const _DialItem({required this.scrolling, required this.child});

  @override
  State<_DialItem> createState() => _DialItemState();
}

class _DialItemState extends State<_DialItem> {
  final ValueNotifier<bool> _tuned = ValueNotifier(false);

  @override
  void dispose() {
    _tuned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialScope(
      tuned: _tuned,
      scrolling: widget.scrolling,
      child: _DialEffect(
        onTuned: (v) {
          if (mounted && _tuned.value != v) _tuned.value = v;
        },
        child: widget.child,
      ),
    );
  }
}

class _DialEffect extends SingleChildRenderObjectWidget {
  final ValueChanged<bool>? onTuned;
  const _DialEffect({this.onTuned, required Widget child}) : super(child: child);

  @override
  _RenderDial createRenderObject(BuildContext context) => _RenderDial(Scrollable.of(context), onTuned);

  @override
  void updateRenderObject(BuildContext context, _RenderDial renderObject) {
    renderObject
      ..scrollable = Scrollable.of(context)
      ..onTuned = onTuned;
  }
}

class _RenderDial extends RenderProxyBox {
  _RenderDial(this._scrollable, this.onTuned);

  ScrollableState _scrollable;
  ValueChanged<bool>? onTuned;
  bool? _lastTuned;

  set scrollable(ScrollableState s) {
    if (identical(s, _scrollable)) return;
    if (attached) _scrollable.position.removeListener(markNeedsPaint);
    _scrollable = s;
    if (attached) _scrollable.position.addListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollable.position.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scrollable.position.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    double k = 0;
    bool tuned = false;
    final vp = _scrollable.context.findRenderObject();
    if (vp is RenderBox && vp.hasSize) {
      final cy = localToGlobal(size.center(Offset.zero), ancestor: vp).dy;
      final half = vp.size.height / 2;
      if (half > 0) k = ((cy - half) / half).clamp(-1.0, 1.0).abs();
      tuned = (cy - half).abs() < size.height / 2;
    }
    // 가운데 방송인지 알려주기 (그리는 중엔 못 바꿔서 다음 화면에)
    if (onTuned != null && tuned != _lastTuned) {
      _lastTuned = tuned;
      final cb = onTuned!;
      SchedulerBinding.instance.addPostFrameCallback((_) => cb(tuned));
    }
    final s = 1 - 0.12 * k * k; // 끝으로 갈수록 작게 (최대 12%)
    final alpha = (255 * (1 - 0.55 * k * k)).round().clamp(0, 255); // 끝으로 갈수록 흐리게
    final m = Matrix4.identity()
      ..setEntry(0, 0, s)
      ..setEntry(1, 1, s)
      ..setEntry(0, 3, size.width / 2 * (1 - s))
      ..setEntry(1, 3, size.height / 2 * (1 - s));
    context.pushOpacity(offset, alpha, (ctx, o) {
      ctx.pushTransform(needsCompositing, o, m, (ctx2, o2) => ctx2.paintChild(c, o2));
    });
  }
}

/// 오른쪽 끝 주파수 눈금 (스크롤 따라 움직임, 위아래 끝은 흐리게)
class _TickPainter extends CustomPainter {
  final ValueListenable<double> px;
  final Color color;
  _TickPainter(this.px, this.color) : super(repaint: px);

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 12.0;
    final off = -(px.value * 0.6) % (gap * 5);
    final half = size.height / 2;
    if (half <= 0) return;
    final paint = Paint()..strokeWidth = 1;
    for (int i = -5; i < 400; i++) {
      final y = off + i * gap;
      if (y > size.height) break;
      if (y < 0) continue;
      final d = ((y - half).abs() / half).clamp(0.0, 1.0);
      paint.color = color.withOpacity(color.opacity * (1 - d * d));
      final w = (i % 5 + 5) % 5 == 0 ? 10.0 : 5.0;
      canvas.drawLine(Offset(size.width - w, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color || old.px != px;
}
'''

SONG_EDITS = [
    ('곡 줄을 떠오르기로 감싸기 (시작)',
     "    return InkWell(\n      onTap: () {\n        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n        FocusManager.instance.primaryFocus?.unfocus();\n",
     "    return _RiseIn(child: InkWell(\n      onTap: () {\n        const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n        FocusManager.instance.primaryFocus?.unfocus();\n"),
    ('곡 줄을 떠오르기로 감싸기 (끝)',
     "      ),\n    );\n  }\n\n  Widget _buildAlbumArt(",
     "      ),\n    ));\n  }\n\n  Widget _buildAlbumArt("),
]

RADIO_EDITS = [
    ('필요한 도구 불러오기',
     "import 'dart:math' as math;\n",
     "import 'dart:math' as math;\nimport 'dart:async';\nimport 'package:flutter/rendering.dart';\nimport 'package:flutter/scheduler.dart';\n"),
    ('스크롤 상태 칸 넣기',
     "  _ViewMode _mode = _ViewMode.all;\n",
     "  _ViewMode _mode = _ViewMode.all;\n"
     "  // 주파수 맞추기: 스크롤 중이면 true (멈추고 0.3초 뒤 false)\n"
     "  final ValueNotifier<bool> _scrolling = ValueNotifier(false);\n"
     "  final ValueNotifier<double> _scrollPx = ValueNotifier(0);\n"
     "  Timer? _settleTimer;\n"
     "\n"
     "  @override\n"
     "  void dispose() {\n"
     "    _settleTimer?.cancel();\n"
     "    _scrolling.dispose();\n"
     "    _scrollPx.dispose();\n"
     "    super.dispose();\n"
     "  }\n"
     "\n"
     "  bool _onDialScroll(ScrollNotification n) {\n"
     "    if (n.depth != 0) return false;\n"
     "    _scrollPx.value = n.metrics.pixels;\n"
     "    if (n is ScrollStartNotification || (n is ScrollUpdateNotification && !_scrolling.value)) {\n"
     "      _settleTimer?.cancel();\n"
     "      _scrolling.value = true;\n"
     "    } else if (n is ScrollEndNotification) {\n"
     "      _settleTimer?.cancel();\n"
     "      _settleTimer = Timer(const Duration(milliseconds: 300), () {\n"
     "        if (mounted) _scrolling.value = false;\n"
     "      });\n"
     "    }\n"
     "    return false;\n"
     "  }\n"),
    ('전체 목록에 스크롤 감지 + 다이얼 (시작)',
     "    return ListView.separated(\n"
     "      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n"
     "      itemCount: koreanStations.length,\n"
     "      separatorBuilder: (_, __) => Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1)),\n",
     "    return Stack(\n"
     "      children: [\n"
     "        NotificationListener<ScrollNotification>(\n"
     "          onNotification: _onDialScroll,\n"
     "          child: ListView.separated(\n"
     "      padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),\n"
     "      itemCount: koreanStations.length,\n"
     "      separatorBuilder: (_, __) => _DialEffect(\n"
     "          child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),\n"),
    ('전체 목록에 스크롤 감지 + 다이얼 (끝) + 오른쪽 눈금',
     "        return Container(\n"
     "          key: _stationItemKeys[ks.name],\n"
     "          child: _StationTile(\n"
     "            station: ks,\n"
     "            isPlaying: isPlaying,\n"
     "            radioStation: radioStations[i],\n"
     "            stationList: radioStations,\n"
     "            stationIndex: i,\n"
     "          ),\n"
     "        );\n"
     "      },\n"
     "    );\n"
     "  }\n",
     "        return Container(\n"
     "          key: _stationItemKeys[ks.name],\n"
     "          child: _DialItem(\n"
     "            scrolling: _scrolling,\n"
     "            child: _StationTile(\n"
     "              station: ks,\n"
     "              isPlaying: isPlaying,\n"
     "              radioStation: radioStations[i],\n"
     "              stationList: radioStations,\n"
     "              stationIndex: i,\n"
     "            ),\n"
     "          ),\n"
     "        );\n"
     "      },\n"
     "          ),\n"
     "        ),\n"
     "        // 오른쪽 끝 주파수 눈금 (스크롤 따라 움직임)\n"
     "        Positioned(\n"
     "          top: 0,\n"
     "          bottom: 0,\n"
     "          right: 4,\n"
     "          width: 12,\n"
     "          child: IgnorePointer(\n"
     "            child: CustomPaint(\n"
     "              painter: _TickPainter(_scrollPx, (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35)),\n"
     "            ),\n"
     "          ),\n"
     "        ),\n"
     "      ],\n"
     "    );\n"
     "  }\n"),
    ('방송 줄: 가운데·스크롤 상태 받기',
     "  @override\n"
     "  Widget build(BuildContext context) {\n"
     "    final primaryColor = Theme.of(context).colorScheme.primary;\n"
     "    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n"
     "    final baseColor = isDarkMode ? Colors.white : Colors.black;\n"
     "\n"
     "    return Container(\n"
     "      color: isPlaying ? primaryColor.withOpacity(0.08) : Colors.transparent,\n"
     "      child: InkWell(\n",
     "  @override\n"
     "  Widget build(BuildContext context) {\n"
     "    final dial = _DialScope.of(context);\n"
     "    if (dial == null) return _tile(context, false, false);\n"
     "    return AnimatedBuilder(\n"
     "      animation: Listenable.merge([dial.tuned, dial.scrolling]),\n"
     "      builder: (ctx, _) => _tile(ctx, dial.tuned.value && dial.scrolling.value, dial.scrolling.value),\n"
     "    );\n"
     "  }\n"
     "\n"
     "  Widget _tile(BuildContext context, bool tuned, bool scrolling) {\n"
     "    final primaryColor = Theme.of(context).colorScheme.primary;\n"
     "    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n"
     "    final baseColor = isDarkMode ? Colors.white : Colors.black;\n"
     "\n"
     "    return AnimatedContainer(\n"
     "      duration: const Duration(milliseconds: 180),\n"
     "      // 스크롤 중 가운데 방송은 살짝 밝은 칸\n"
     "      color: isPlaying\n"
     "          ? primaryColor.withOpacity(0.08)\n"
     "          : tuned\n"
     "              ? baseColor.withOpacity(0.06)\n"
     "              : Colors.transparent,\n"
     "      child: InkWell(\n"),
    ('오른쪽: 스크롤 중엔 주파수, 멈추면 하트 (시작)',
     "              if (isPlaying)\n"
     "                _PlayingBars(color: primaryColor)\n"
     "              else\n"
     "                GestureDetector(\n"
     "                  behavior: HitTestBehavior.opaque,\n",
     "              SizedBox(\n"
     "                width: 46,\n"
     "                child: AnimatedSwitcher(\n"
     "                  duration: const Duration(milliseconds: 250),\n"
     "                  layoutBuilder: (cur, prev) => Stack(\n"
     "                    alignment: Alignment.centerRight,\n"
     "                    children: [...prev, if (cur != null) cur],\n"
     "                  ),\n"
     "                  child: isPlaying\n"
     "                      ? KeyedSubtree(key: const ValueKey('bars'), child: _PlayingBars(color: primaryColor))\n"
     "                      : scrolling\n"
     "                          ? Text(\n"
     "                              station.frequency.replaceAll(' MHz', ''),\n"
     "                              key: const ValueKey('freq'),\n"
     "                              maxLines: 1,\n"
     "                              style: GoogleFonts.quicksand(\n"
     "                                color: tuned ? primaryColor : baseColor.withOpacity(0.45),\n"
     "                                fontSize: 14,\n"
     "                                fontWeight: FontWeight.w600,\n"
     "                              ),\n"
     "                            )\n"
     "                          : GestureDetector(\n"
     "                  key: const ValueKey('heart'),\n"
     "                  behavior: HitTestBehavior.opaque,\n"),
    ('오른쪽: 스크롤 중엔 주파수, 멈추면 하트 (끝)',
     "                    size: 22,\n"
     "                  ),\n"
     "                ),\n"
     "            ],\n"
     "          ),\n"
     "        ),\n"
     "      ),\n"
     "    );\n"
     "  }\n"
     "}\n",
     "                    size: 22,\n"
     "                  ),\n"
     "                ),\n"
     "                ),\n"
     "              ),\n"
     "            ],\n"
     "          ),\n"
     "        ),\n"
     "      ),\n"
     "    );\n"
     "  }\n"
     "}\n"),
]

def load(path):
    if not os.path.exists(path):
        print('❌ 파일을 못 찾았어요:', path)
        print('   프로젝트 맨 바깥 폴더(mp3_player_new)에서 실행해 주세요.')
        sys.exit(1)
    raw = open(path, 'rb').read().decode('utf-8')
    return raw, '\r\n' in raw, raw.replace('\r\n', '\n')

def apply(t, edits, label):
    ok = True
    for name, old, new in edits:
        if t.count(old) != 1:
            print('❌', label, '-', name)
            ok = False
            continue
        t = t.replace(old, new)
        print('✔', label, '-', name)
    return t, ok

def balanced(t):
    return t.count('{') == t.count('}') and t.count('(') == t.count(')') and t.count('[') == t.count(']')

def main():
    s_raw, s_crlf, s = load(SONG)
    r_raw, r_crlf, r = load(RADIO)
    if 'class _RiseIn' in s and 'class _DialEffect' in r:
        print('이미 적용돼 있어요')
        return
    if 'class _RiseIn' in s or 'class _DialEffect' in r:
        print('❌ 한쪽만 적용돼 있어요. 아무것도 저장하지 않았어요.')
        sys.exit(1)

    s, ok1 = apply(s, SONG_EDITS, '음악')
    s += RISE_CLASS
    r, ok2 = apply(r, RADIO_EDITS, '라디오')
    r += DIAL_CLASSES

    if not (ok1 and ok2):
        print('\n못 찾은 곳이 있어서 아무것도 저장하지 않았어요.')
        sys.exit(1)
    if not balanced(s) or not balanced(r):
        print('❌ 괄호 짝이 안 맞아요. 저장하지 않았어요.')
        sys.exit(1)

    for path, crlf, t in ((SONG, s_crlf, s), (RADIO, r_crlf, r)):
        if crlf:
            t = t.replace('\n', '\r\n')
        open(path, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요.')

main()
