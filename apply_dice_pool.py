# 라디오 주사위 방송 목록: 수도권 방송만 + 국악·극동·국방·불교는 덜 나오게
# (apply_radio_dice.py를 먼저 실행한 뒤에 실행)
import sys, os
SCREEN = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
WIDGET = os.path.join('lib', 'widgets', 'radio_dice.dart')
if len(sys.argv) > 2: SCREEN, WIDGET = sys.argv[1:3]

W = [
('방송마다 나올 확률(무게)',
"""  final String Function(RadioProvider radio) program;

  const DiceStation({
    required this.station,
    required this.badge,
    this.frequency = '',
    required this.program,
  });""",
"""  final String Function(RadioProvider radio) program;
  final double weight; // 나올 확률 (1 = 보통, 0.3 = 덜 나옴)

  const DiceStation({
    required this.station,
    required this.badge,
    this.frequency = '',
    required this.program,
    this.weight = 1.0,
  });"""),
('확률에 맞춰 고르기',
"""    var list = widget.pool.where((s) => s.station.name != _lastName).toList();
    if (list.isEmpty) list = widget.pool;
    final p = list[_rng.nextInt(list.length)];
    _lastName = p.station.name;""",
"""    var list = widget.pool.where((s) => s.station.name != _lastName).toList();
    if (list.isEmpty) list = widget.pool;
    // 무게가 큰 방송이 더 자주 나옴
    final total = list.fold<double>(0, (a, s) => a + s.weight);
    var r = _rng.nextDouble() * total;
    var p = list.last;
    for (final s in list) {
      r -= s.weight;
      if (r <= 0) {
        p = s;
        break;
      }
    }
    _lastName = p.station.name;"""),
]
S = [
('주사위 방송 목록',
"""  // 주사위에 넣는 음악 방송 (뉴스·교통·종교 방송은 빼기)
  static const _diceNames = [
    'KBS Classic FM', 'KBS Cool FM', 'KBS 해피FM', 'MBC FM4U', 'MBC 올댓뮤직',
    'SBS 파워FM', 'SBS 러브FM', 'CBS 음악FM', '국악FM',
  ];

  List<DiceStation> _dicePool() => [
        for (final ks in koreanStations)
          if (_diceNames.contains(ks.name))
            DiceStation(""",
"""  // 주사위는 수도권 방송만 (지역 방송은 빼기) · 아래 방송은 덜 나오게
  static const _diceLow = ['국악FM', 'FEBC 극동방송', '국방FM', 'BBS 불교방송'];

  List<DiceStation> _dicePool() => [
        for (final ks in koreanStations)
          if (ks.region == '수도권')
            DiceStation(
              weight: _diceLow.contains(ks.name) ? 0.3 : 1.0,"""),
]

def run(path, reps, mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    src = raw.replace('\r\n', '\n')
    if mark in src:
        print(f'{os.path.basename(path)}: 이미 적용돼 있어요'); return None
    ok = True
    for name, old, new in reps:
        n = src.count(old)
        if n != 1:
            print(f'❌ {name}: 찾을 코드를 {"못 찾았어요" if n == 0 else f"{n}곳에서 찾았어요"}'); ok = False
        else:
            src = src.replace(old, new); print(f'✔ {name}')
    return (path, src.replace('\n', '\r\n') if crlf else src) if ok else False

for p in (SCREEN, WIDGET):
    if not os.path.exists(p):
        print(f'❌ {p} 가 없어요. apply_radio_dice.py를 먼저 실행해 주세요'); sys.exit(1)
a = run(WIDGET, W, 'final double weight;')
b = run(SCREEN, S, '_diceLow')
if a is False or b is False:
    print('아무것도 저장하지 않았어요'); sys.exit(1)
for r in (a, b):
    if r:
        open(r[0], 'wb').write(r[1].encode('utf-8')); print('저장했어요:', r[0])
