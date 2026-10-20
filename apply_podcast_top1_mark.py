# -*- coding: utf-8 -*-
# ① 인기 1위 카드 A안: 먹색 박스는 그대로, 한 줄로 낮게 (그림 60 · 'NO. 1 · 만든 곳' 작게 · 제목 · 장르 · 오른쪽 가는 테두리 재생 동그라미)
#    → 예전 큰 그림·흰 '최신 회차' 버튼은 지움 (새 글자 없음 → 번역 필요 없음)
# ② 라디오 '팟캐스트' 탭에 색연필 동그라미 (포인트 색 · 처음 볼 때 쓱 그려짐)
#    → 국내 탭이든 해외 칩이든 한 번 누르면 둘 다 사라짐 · 안 눌러도 처음 본 지 2주 지나면 사라짐
import os, sys

P = {
    'pod': os.path.join('lib', 'podcast', 'podcast_screens.dart'),
    'kr': os.path.join('lib', 'screens', 'radio_korea_screen2.dart'),
    'world': os.path.join('lib', 'screens', 'radio_country_stations_screen.dart'),
}


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


D = {}
for k, p in P.items():
    if not os.path.exists(p):
        fail('파일이 없어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8')
    D[k] = {'s': raw.replace('\r\n', '\n'), 'crlf': '\r\n' in raw}
    D[k]['orig'] = D[k]['s']


def name(k):
    return os.path.basename(P[k])


def rep(k, label, old, new, done):
    s = D[k]['s']
    if done in s:
        print('✔', name(k), label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(f'{name(k)} {label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    D[k]['s'] = s.replace(old, new)
    print('✔', name(k), label)


# ───────── ① 1위 카드 ─────────
k = 'pod'
OLD_TOP = '''          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PodcastArt(url: s.art, title: s.title, size: 86, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NO. 1',
                        style: TextStyle(color: fg.withOpacity(0.55), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(s.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
                    const SizedBox(height: 2),
                    Text([s.author, s.genre].where((x) => x.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg.withOpacity(0.6), fontSize: 11.5)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _latestLoading ? null : () => _playLatest(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _latestLoading
                                ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: bg))
                                : Icon(Icons.play_arrow_rounded, size: 16, color: bg),
                            const SizedBox(width: 4),
                            Text(podText('최신 회차', 'Latest episode'),
                                style: TextStyle(color: bg, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
'''
NEW_TOP = '''          padding: const EdgeInsets.all(12),
          // A안: 한 줄로 낮게 — 그림 · (NO. 1 · 만든 곳 / 제목 / 장르) · 오른쪽 가는 테두리 재생 동그라미
          child: Row(
            children: [
              PodcastArt(url: s.art, title: s.title, size: 60, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(['NO. 1', if (s.author.isNotEmpty) s.author].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg.withOpacity(0.5), fontSize: 10.5, letterSpacing: 0.4, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    if (s.genre.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(s.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg.withOpacity(0.5), fontSize: 11)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 최신 회차 바로 듣기 (가는 테두리 동그라미)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _latestLoading ? null : () => _playLatest(s),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: fg.withOpacity(0.35)),
                  ),
                  child: _latestLoading
                      ? Padding(
                          padding: const EdgeInsets.all(11),
                          child: CircularProgressIndicator(strokeWidth: 1.6, color: fg),
                        )
                      : Icon(Icons.play_arrow_rounded, size: 20, color: fg),
                ),
              ),
            ],
          ),
'''
rep(k, '인기 1위 카드 A안 (예전 큰 카드 지우고)', OLD_TOP, NEW_TOP, done='// A안: 한 줄로 낮게')
rep(k, 'import', "import 'podcast.dart';\n",
    "import 'podcast.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\n",
    done="import 'package:shared_preferences/shared_preferences.dart';")

if 'class PodPencilCircle' not in D[k]['s']:
    D[k]['s'] = D[k]['s'].rstrip('\n') + '\n' + r'''
/// 라디오 '팟캐스트' 탭 새 기능 표시 — 한 번 누르면(국내·해외 어디서든) · 처음 본 지 2주 지나면 사라짐
class PodNewMark {
  static final ValueNotifier<bool> show = ValueNotifier(false);
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final sp = await SharedPreferences.getInstance();
      if (sp.getBool('pod_tab_seen') ?? false) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final first = sp.getInt('pod_tab_first');
      if (first == null) {
        await sp.setInt('pod_tab_first', now);
      } else if (now - first > const Duration(days: 14).inMilliseconds) {
        await sp.setBool('pod_tab_seen', true); // 2주 지나면 저절로
        return;
      }
      show.value = true;
    } catch (_) {}
  }

  /// 팟캐스트 탭을 눌렀을 때
  static Future<void> seen() async {
    _loaded = true;
    if (show.value) show.value = false;
    try {
      (await SharedPreferences.getInstance()).setBool('pod_tab_seen', true);
    } catch (_) {}
  }
}

/// 글자 둘레에 색연필로 쓱 두 번 그린 듯한 동그라미 (포인트 색 · 처음 볼 때 그려지는 움직임)
class PodPencilCircle extends StatefulWidget {
  final bool enabled;
  final Widget child;
  const PodPencilCircle({super.key, required this.enabled, required this.child});

  @override
  State<PodPencilCircle> createState() => _PodPencilCircleState();
}

class _PodPencilCircleState extends State<PodPencilCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      PodNewMark.load();
      PodNewMark.show.addListener(_go);
      _go();
    }
  }

  void _go() {
    if (PodNewMark.show.value && !_c.isAnimating && _c.value == 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    PodNewMark.show.removeListener(_go);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final color = pointColorOf(context);
    return ValueListenableBuilder<bool>(
      valueListenable: PodNewMark.show,
      builder: (_, on, child) => !on
          ? child!
          : Stack(
              clipBehavior: Clip.none,
              children: [
                child!,
                Positioned(
                  left: -9,
                  right: -9,
                  top: -6,
                  bottom: -6,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) => CustomPaint(painter: _PencilPainter(Curves.easeOut.transform(_c.value), color)),
                    ),
                  ),
                ),
              ],
            ),
      child: widget.child,
    );
  }
}

class _PencilPainter extends CustomPainter {
  final double t; // 0 → 1 그려지는 정도
  final Color color;
  _PencilPainter(this.t, this.color);

  // 80×50 칸에 그린 손그림 동그라미 두 줄 (시안과 같은 모양)
  Path _loop(Size s, List<double> p) {
    double x(double v) => v / 80 * s.width;
    double y(double v) => v / 50 * s.height;
    final path = Path()..moveTo(x(p[0]), y(p[1]));
    for (var i = 2; i + 5 < p.length; i += 6) {
      path.cubicTo(x(p[i]), y(p[i + 1]), x(p[i + 2]), y(p[i + 3]), x(p[i + 4]), y(p[i + 5]));
    }
    return path;
  }

  void _draw(Canvas canvas, Path path, double progress, Paint paint) {
    if (progress <= 0) return;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress.clamp(0.0, 1.0)), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = _loop(size, const [58, 9, 44, 2, 16, 4, 8, 16, 1, 28, 14, 42, 40, 43, 64, 44, 78, 34, 74, 21, 71, 11, 58, 6, 44, 7]);
    final b = _loop(size, const [56, 11, 42, 5, 18, 7, 10, 18, 4, 29, 16, 40, 40, 41, 62, 42, 75, 33, 72, 22, 70, 13, 60, 9, 48, 9]);
    final p1 = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final p2 = Paint()
      ..color = color.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    _draw(canvas, a, t * 1.4, p1); // 첫 줄 먼저
    _draw(canvas, b, (t - 0.3) * 1.45, p2); // 겹친 줄은 조금 늦게
  }

  @override
  bool shouldRepaint(_PencilPainter o) => o.t != t || o.color != color;
}
'''
    print('✔', name(k), '색연필 동그라미 모양 · 한 번 누르면 사라지기')
else:
    print('✔', name(k), '색연필 동그라미 모양 · 한 번 누르면 사라지기 (이미 돼 있음)')

# ───────── ② 국내 라디오 탭 ─────────
k = 'kr'
rep(k, '팟캐스트 탭 누르면 동그라미 사라지기',
    '''          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          setState(() => _mode = mode);
        },
        child: AnimatedContainer(''',
    '''          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          if (mode == _ViewMode.podcast) PodNewMark.seen(); // 색연필 동그라미 지우기
          setState(() => _mode = mode);
        },
        child: AnimatedContainer(''',
    done='if (mode == _ViewMode.podcast) PodNewMark.seen();')
rep(k, '팟캐스트 탭 글자에 동그라미 (앞)',
    '''          // 글자가 커도 한 줄 (넘치면 칸에 맞게 살짝 줄임)
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,''',
    '''          // 글자가 커도 한 줄 (넘치면 칸에 맞게 살짝 줄임) · 팟캐스트는 색연필 동그라미
          child: PodPencilCircle(
            enabled: mode == _ViewMode.podcast,
            child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,''',
    done='enabled: mode == _ViewMode.podcast,')
rep(k, '팟캐스트 탭 글자에 동그라미 (끝)',
    '''                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
''',
    '''                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
''',
    done='''              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
''')

# ───────── ② 해외 라디오 칩 ─────────
k = 'world'
rep(k, '팟캐스트 칩 누르면 동그라미 사라지기',
    "        if (c == 'podcast') {\n          _mode = _ViewMode.podcast;\n",
    "        if (c == 'podcast') {\n          PodNewMark.seen(); // 색연필 동그라미 지우기\n          _mode = _ViewMode.podcast;\n",
    done='PodNewMark.seen(); // 색연필 동그라미 지우기')
rep(k, '팟캐스트 칩 글자에 동그라미',
    '''                          Text(
                            names[c]!,
                            softWrap: false,
                            style: TextStyle(
                              color: _chip == c ? baseColor : dim,
                              fontSize: 15,
                              fontWeight: _chip == c ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
''',
    '''                          PodPencilCircle( // 팟캐스트만 색연필 동그라미
                            enabled: c == 'podcast',
                            child: Text(
                              names[c]!,
                              softWrap: false,
                              style: TextStyle(
                                color: _chip == c ? baseColor : dim,
                                fontSize: 15,
                                fontWeight: _chip == c ? FontWeight.w800 : FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
''',
    done="PodPencilCircle( // 팟캐스트만 색연필 동그라미")

for k in D:
    s = D[k]['s']
    if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
        fail(name(k) + ' 괄호가 안 맞아요')
changed = [k for k in D if D[k]['s'] != D[k]['orig']]
if not changed:
    print('이미 적용돼 있어요')
    sys.exit(0)
for k in changed:
    s = D[k]['s']
    if D[k]['crlf']:
        s = s.replace('\n', '\r\n')
    open(P[k], 'wb').write(s.encode('utf-8'))
print('저장했어요:', ', '.join(name(k) for k in changed))
