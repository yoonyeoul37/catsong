# -*- coding: utf-8 -*-
# 해외 라디오 목록: 곡 목록처럼 줄이 화면에 들어올 때 살포시 떠오르기 (탭을 바꾸면 새로 떠오름)
import sys, glob, os, shutil

hits = glob.glob(os.path.join('lib', '**', 'radio_country_stations_screen.dart'), recursive=True)
if not hits:
    print('❌ radio_country_stations_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'class _RiseIn' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

RISE = r"""/// 방송 줄이 화면에 나타날 때 살포시 떠오르게 (곡 목록 song_list_tile.dart 와 같은 움직임)
class _RiseIn extends StatefulWidget {
  final Widget child;
  const _RiseIn({required this.child});

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late Animation<Offset> _slide;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;
  ScrollPosition? _pos;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    final curve = _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(curve);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curve);
    // 처음 그려진 뒤: 화면에 보이는 줄은 바로 떠오르기
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(first: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Scrollable.maybeOf(context)?.position;
    if (!identical(p, _pos)) {
      _pos?.removeListener(_check);
      _pos = p;
      if (!_started) _pos?.addListener(_check);
    }
  }

  @override
  void didUpdateWidget(covariant _RiseIn old) {
    super.didUpdateWidget(old);
    // 목록이 바뀌어 줄이 스크롤 없이 화면에 들어온 경우도 챙기기
    if (!_started) WidgetsBinding.instance.addPostFrameCallback((_) => _check(first: true));
  }

  /// 줄이 실제로 화면 안에 들어왔는지 보고 시작
  void _check({bool first = false}) {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final vp = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (vp is! RenderBox || !vp.hasSize) {
      _start(animate: true);
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: vp).dy;
    final h = vp.size.height;
    if (top + box.size.height <= 0 || top >= h) return; // 아직 화면 밖
    // 아래에서 들어오면 아래→위로, 위에서 들어오면 위→아래로 살포시
    final fromTop = !first && top <= h * 0.5;
    if (fromTop) {
      setState(() => _slide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(_curve));
    }
    _start(animate: true);
  }

  void _start({required bool animate}) {
    _started = true;
    _pos?.removeListener(_check);
    if (animate) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
"""

edits = [
('방송 줄 감싸기 (시작)',
"""    return Container(
      color: Colors.transparent,
      child: InkWell(""",
"""    return _RiseIn(child: Container(
      color: Colors.transparent,
      child: InkWell("""),
('방송 줄 감싸기 (끝) + 떠오르기 코드',
"""    );
  }
}

class _GroupedStationListScreen""",
"""    ));
  }
}

""" + RISE + """
class _GroupedStationListScreen"""),
('방송 줄 이름표 받기',
"""  const _StationTile({
    required this.station,""",
"""  const _StationTile({
    super.key,
    required this.station,"""),
('탭 바꾸면 새로 떠오르게',
"""                        return _StationTile(
                          station: station,
                          isPlaying: isPlaying,
                          stationList: stations,
                          stationIndex: index,""",
"""                        return _StationTile(
                          key: ValueKey('$_chip|$_sub|${station.stationUuid}'),
                          station: station,
                          isPlaying: isPlaying,
                          stationList: stations,
                          stationIndex: index,"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

shutil.copy(path, path + '.bak10')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak10)')
