# -*- coding: utf-8 -*-
# 라디오 다이얼 2차: 멈추면 깔끔, 눈금 길게, 하트 1초 뒤, MHz, 방송사별·지역별에도 적용
import os, sys

PATH = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(PATH):
    for root, _, files in os.walk('lib'):
        if 'radio_korea_screen2.dart' in files:
            PATH = os.path.join(root, 'radio_korea_screen2.dart'); break

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if 'class _DialHost extends StatefulWidget' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = []

# 1) 화면 State 의 스크롤 변수/함수 정리 (이제 _DialHost 가 맡아요)
edits.append(('스크롤 상태를 _DialHost 로 옮기기', '''  // 주파수 맞추기: 스크롤 중이면 true (멈추고 0.3초 뒤 false)
  final ValueNotifier<bool> _scrolling = ValueNotifier(false);
  final ValueNotifier<double> _scrollPx = ValueNotifier(0);
  Timer? _settleTimer;

  @override
  void dispose() {
    _settleTimer?.cancel();
    _scrolling.dispose();
    _scrollPx.dispose();
    super.dispose();
  }

  bool _onDialScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    _scrollPx.value = n.metrics.pixels;
    if (n is ScrollStartNotification || (n is ScrollUpdateNotification && !_scrolling.value)) {
      _settleTimer?.cancel();
      _scrolling.value = true;
    } else if (n is ScrollEndNotification) {
      _settleTimer?.cancel();
      _settleTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) _scrolling.value = false;
      });
    }
    return false;
  }
''', ''))

# 2) 전체 목록: Stack + 눈금 → _DialHost
edits.append(('전체 목록 감싸기 (시작)', '''    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onDialScroll,
          child: ListView.separated(''', '''    return _DialHost(
      tickColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35),
      child: ListView.separated('''))

edits.append(('전체 목록 줄 효과', '''          child: _DialItem(
            scrolling: _scrolling,
            child: _StationTile(''', '''          child: _DialItem(
            child: _StationTile('''))

edits.append(('전체 목록 감싸기 (끝)', '''          ),
        ),
        // 오른쪽 끝 주파수 눈금 (스크롤 따라 움직임)
        Positioned(
          top: 0,
          bottom: 0,
          right: 4,
          width: 12,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TickPainter(_scrollPx, (isDarkMode ? Colors.white : Colors.black).withOpacity(0.35)),
            ),
          ),
        ),
      ],
    );
  }''', '''      ),
    );
  }'''))

# 3) 오른쪽: 숫자 + 작은 MHz, 칸 넓히기
edits.append(('오른쪽 칸 넓히기', '''              SizedBox(
                width: 46,
                child: AnimatedSwitcher(''', '''              SizedBox(
                width: 76,
                child: AnimatedSwitcher('''))

edits.append(('숫자 뒤에 작은 MHz', '''                          ? Text(
                              station.frequency.replaceAll(' MHz', ''),
                              key: const ValueKey('freq'),
                              maxLines: 1,
                              style: GoogleFonts.quicksand(
                                color: tuned ? primaryColor : baseColor.withOpacity(0.45),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )''', '''                          ? Text.rich(
                              TextSpan(children: [
                                TextSpan(text: station.frequency.replaceAll(' MHz', '').trim()),
                                if (station.frequency.trim().isNotEmpty)
                                  TextSpan(
                                    text: ' MHz',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: (tuned ? primaryColor : baseColor).withOpacity(tuned ? 0.75 : 0.35),
                                    ),
                                  ),
                              ]),
                              key: const ValueKey('freq'),
                              maxLines: 1,
                              style: GoogleFonts.quicksand(
                                color: tuned ? primaryColor : baseColor.withOpacity(0.45),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )'''))

# 4) 방송사별·지역별 목록에도 다이얼
edits.append(('방송사별·지역별 목록 감싸기', '''        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
          itemCount: stations.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: baseColor.withOpacity(0.1)),''', '''        child: _DialHost(
          tickColor: baseColor.withOpacity(0.35),
          child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
          itemCount: stations.length,
          separatorBuilder: (_, __) => _DialEffect(child: Divider(height: 1, color: baseColor.withOpacity(0.1))),'''))

edits.append(('방송사별·지역별 줄 효과', '''            return _StationTile(
              station: ks,
              isPlaying: isPlaying,
              radioStation: radioStations[i],
              stationList: radioStations,
              stationIndex: i,
            );
          },
        ),
      ),''', '''            return _DialItem(
              child: _StationTile(
                station: ks,
                isPlaying: isPlaying,
                radioStation: radioStations[i],
                stationList: radioStations,
                stationIndex: i,
              ),
            );
          },
        ),
        ),
      ),'''))

# 5) _DialItem: 스크롤 상태를 _DialHost 에서 받기
edits.append(('_DialItem 정리', '''class _DialItem extends StatefulWidget {
  final ValueNotifier<bool> scrolling;
  final Widget child;
  const _DialItem({required this.scrolling, required this.child});''', '''class _DialItem extends StatefulWidget {
  final Widget child;
  const _DialItem({required this.child});'''))

edits.append(('_DialItem 스크롤 연결', '''    return _DialScope(
      tuned: _tuned,
      scrolling: widget.scrolling,''', '''    final host = _DialHostScope.of(context);
    if (host == null) return widget.child;
    return _DialScope(
      tuned: _tuned,
      scrolling: host.scrolling,'''))

# 6) _DialEffect / _RenderDial: 세기(strength) 곱하기
edits.append(('_DialEffect 세기 넘기기', '''  @override
  _RenderDial createRenderObject(BuildContext context) => _RenderDial(Scrollable.of(context), onTuned);

  @override
  void updateRenderObject(BuildContext context, _RenderDial renderObject) {
    renderObject
      ..scrollable = Scrollable.of(context)
      ..onTuned = onTuned;
  }''', '''  @override
  _RenderDial createRenderObject(BuildContext context) =>
      _RenderDial(Scrollable.of(context), onTuned, _DialHostScope.of(context)?.strength);

  @override
  void updateRenderObject(BuildContext context, _RenderDial renderObject) {
    renderObject
      ..scrollable = Scrollable.of(context)
      ..onTuned = onTuned
      ..strength = _DialHostScope.of(context)?.strength;
  }'''))

edits.append(('_RenderDial 세기 연결', '''  _RenderDial(this._scrollable, this.onTuned);

  ScrollableState _scrollable;
  ValueChanged<bool>? onTuned;
  bool? _lastTuned;
''', '''  _RenderDial(this._scrollable, this.onTuned, this._strength);

  ScrollableState _scrollable;
  ValueChanged<bool>? onTuned;
  bool? _lastTuned;
  Animation<double>? _strength;

  set strength(Animation<double>? a) {
    if (identical(a, _strength)) return;
    if (attached) _strength?.removeListener(markNeedsPaint);
    _strength = a;
    if (attached) _strength?.addListener(markNeedsPaint);
    markNeedsPaint();
  }
'''))

edits.append(('_RenderDial 붙이기/떼기', '''    super.attach(owner);
    _scrollable.position.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scrollable.position.removeListener(markNeedsPaint);
    super.detach();
  }''', '''    super.attach(owner);
    _scrollable.position.addListener(markNeedsPaint);
    _strength?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scrollable.position.removeListener(markNeedsPaint);
    _strength?.removeListener(markNeedsPaint);
    super.detach();
  }'''))

edits.append(('멈추면 효과 풀기', '''    final s = 1 - 0.12 * k * k; // 끝으로 갈수록 작게 (최대 12%)''', '''    // 멈춰 있으면 0 → 깔끔한 목록, 스크롤하면 1 → 다이얼
    k = k * (_strength?.value ?? 1.0);
    final s = 1 - 0.12 * k * k; // 끝으로 갈수록 작게 (최대 12%)'''))

# 7) 눈금 길게 + 멈추면 살짝 흐리게
edits.append(('눈금 painter 세기', '''class _TickPainter extends CustomPainter {
  final ValueNotifier<double> px;
  final Color color;
  _TickPainter(this.px, this.color) : super(repaint: px);''', '''class _TickPainter extends CustomPainter {
  final ValueNotifier<double> px;
  final Color color;
  final Animation<double> strength;
  _TickPainter(this.px, this.color, this.strength) : super(repaint: Listenable.merge([px, strength]));'''))

edits.append(('눈금 길이/투명도', '''      paint.color = color.withOpacity(color.opacity * (1 - d * d));
      final w = (i % 5 + 5) % 5 == 0 ? 10.0 : 5.0;''', '''      paint.color = color.withOpacity(color.opacity * (1 - d * d) * (0.35 + 0.65 * strength.value));
      final w = (i % 5 + 5) % 5 == 0 ? 18.0 : 9.0;'''))

edits.append(('눈금 다시 그리기 조건', '''  bool shouldRepaint(_TickPainter old) => old.color != color || old.px != px;''', '''  bool shouldRepaint(_TickPainter old) => old.color != color || old.px != px || old.strength != strength;'''))

NEW_CLASSES = '''

/// 목록 하나를 다이얼로 감싸요: 스크롤 감지, 효과 세기, 오른쪽 눈금
class _DialHost extends StatefulWidget {
  final Color tickColor;
  final Widget child;
  const _DialHost({required this.tickColor, required this.child});

  @override
  State<_DialHost> createState() => _DialHostState();
}

class _DialHostState extends State<_DialHost> with SingleTickerProviderStateMixin {
  // 스크롤 중이면 true (멈추고 1초 뒤 false → 하트)
  final ValueNotifier<bool> _scrolling = ValueNotifier(false);
  final ValueNotifier<double> _px = ValueNotifier(0);
  late final AnimationController _strength = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 450),
  );
  Timer? _relaxTimer;
  Timer? _heartTimer;

  @override
  void dispose() {
    _relaxTimer?.cancel();
    _heartTimer?.cancel();
    _strength.dispose();
    _scrolling.dispose();
    _px.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    _px.value = n.metrics.pixels;
    if (n is ScrollStartNotification || (n is ScrollUpdateNotification && !_scrolling.value)) {
      _relaxTimer?.cancel();
      _heartTimer?.cancel();
      _scrolling.value = true;
      _strength.forward();
    } else if (n is ScrollEndNotification) {
      _relaxTimer?.cancel();
      _heartTimer?.cancel();
      // 멈추면 다이얼이 부드럽게 풀리고
      _relaxTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _strength.reverse();
      });
      // 1초 뒤에 하트
      _heartTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) _scrolling.value = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _DialHostScope(
      scrolling: _scrolling,
      strength: _strength,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
          // 오른쪽 끝 주파수 눈금 (스크롤 따라 움직임)
          Positioned(
            top: 0,
            bottom: 0,
            right: 3,
            width: 20,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TickPainter(_px, widget.tickColor, _strength),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialHostScope extends InheritedWidget {
  final ValueNotifier<bool> scrolling;
  final Animation<double> strength;
  const _DialHostScope({required this.scrolling, required this.strength, required super.child});

  static _DialHostScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_DialHostScope>();

  @override
  bool updateShouldNotify(_DialHostScope old) => old.scrolling != scrolling || old.strength != strength;
}
'''

ok = True
for name, old, new in edits:
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

if ok:
    src = src.rstrip('\n') + '\n' + NEW_CLASSES
    for a, b in ('()', '[]', '{}'):
        if src.count(a) != src.count(b):
            ok = False; print('❌ 괄호 개수가 안 맞아요', a, b)

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
