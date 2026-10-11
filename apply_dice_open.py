# 주사위 결과 판: 흰 방송 카드를 누르면 그 방송 상세 화면(라디오 재생 화면)으로
# (apply_dice_result.py 다음에 실행)
import sys, os
SCREEN = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
WIDGET = os.path.join('lib', 'widgets', 'radio_dice.dart')
if len(sys.argv) > 2: SCREEN, WIDGET = sys.argv[1:3]

W = [
('판 열 때 "상세 화면 열기" 받기',
"""Future<void> showRadioDice(BuildContext context, List<DiceStation> pool) {
  if (pool.isEmpty) return Future.value();""",
"""Future<void> showRadioDice(BuildContext context, List<DiceStation> pool,
    {void Function(RadioStation station)? onOpen}) {
  if (pool.isEmpty) return Future.value();"""),
('판에 넘기기', "    pageBuilder: (ctx, _, __) => _DiceBoard(pool: pool),",
                "    pageBuilder: (ctx, _, __) => _DiceBoard(pool: pool, onOpen: onOpen),"),
('판 위젯',
"""class _DiceBoard extends StatefulWidget {
  final List<DiceStation> pool;
  const _DiceBoard({required this.pool});""",
"""class _DiceBoard extends StatefulWidget {
  final List<DiceStation> pool;
  final void Function(RadioStation station)? onOpen;
  const _DiceBoard({required this.pool, this.onOpen});"""),
('카드 누르면 판 닫고 상세 화면',
"                            child: _StationInfo(item: _cur!, face: _lastFace, onAgain: _roll),",
"""                            child: _StationInfo(
                              item: _cur!,
                              face: _lastFace,
                              onAgain: _roll,
                              onOpen: widget.onOpen == null
                                  ? null
                                  : () {
                                      if (_busy) return;
                                      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                                      final st = _cur!.station;
                                      Navigator.of(context).pop();
                                      widget.onOpen!(st);
                                    },
                            ),"""),
('결과 위젯에 받기',
"""  final VoidCallback onAgain;
  const _StationInfo({required this.item, required this.face, required this.onAgain});""",
"""  final VoidCallback onAgain;
  final VoidCallback? onOpen; // 카드 누르면 상세 화면
  const _StationInfo({required this.item, required this.face, required this.onAgain, this.onOpen});"""),
('카드를 누를 수 있게',
"""            // 판 위에 살짝 비스듬히 놓인 흰 카드
            Transform.rotate(""",
"""            // 판 위에 살짝 비스듬히 놓인 흰 카드 (누르면 상세 화면)
            GestureDetector(
              onTap: onOpen,
              child: Transform.rotate("""),
('카드 닫는 괄호',
"""                        style: TextStyle(
                            color: program.isEmpty ? hint : ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const Spacer(),""",
"""                        style: TextStyle(
                            color: program.isEmpty ? hint : ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              ),
            ),
            const Spacer(),"""),
('프로그램 줄 오른쪽에 › 표시',
"""                    const Text('지금 하는 프로그램', style: TextStyle(color: hint, fontSize: 11.5)),
                    const SizedBox(height: 1),
                    Text(program.isEmpty ? '편성 정보가 없어요' : program,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: program.isEmpty ? hint : ink, fontSize: 13.5, fontWeight: FontWeight.w700)),""",
"""                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('지금 하는 프로그램', style: TextStyle(color: hint, fontSize: 11.5)),
                              const SizedBox(height: 1),
                              Text(program.isEmpty ? '편성 정보가 없어요' : program,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: program.isEmpty ? hint : ink, fontSize: 13.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        if (onOpen != null) const Icon(Icons.chevron_right_rounded, color: hint, size: 22),
                      ],
                    ),"""),
]
S = [
('상세 화면 열기 연결',
"    showRadioDice(context, _dicePool());",
"""    showRadioDice(context, _dicePool(), onOpen: (st) {
      // 전체 목록 순서 그대로 넘겨서 상세 화면에서 이전/다음도 되게
      final list = koreanStations.map(_toRadioStation).toList();
      final i = list.indexWhere((s) => s.name == st.name);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => RadioPlayerScreen(
            station: i >= 0 ? list[i] : st,
            stationList: list,
            currentIndex: i >= 0 ? i : 0,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    });"""),
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
        print(f'❌ {p} 가 없어요'); sys.exit(1)
if 'class _MiniFace' not in open(WIDGET, encoding='utf-8').read():
    print('❌ apply_dice_result.py를 먼저 실행해 주세요'); sys.exit(1)
a = run(WIDGET, W, 'final VoidCallback? onOpen;')
b = run(SCREEN, S, 'showRadioDice(context, _dicePool(), onOpen:')
if a is False or b is False:
    print('아무것도 저장하지 않았어요'); sys.exit(1)
for r in (a, b):
    if r:
        open(r[0], 'wb').write(r[1].encode('utf-8')); print('저장했어요:', r[0])
