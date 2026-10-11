# -*- coding: utf-8 -*-
# 해외 라디오 주사위: 처음 소개 팝업 + NEW 표시 (apply_world_dice.py 다음에 실행)
import sys, glob, os, shutil

hits = glob.glob(os.path.join('lib', '**', 'radio_country_stations_screen.dart'), recursive=True)
if not hits:
    print('❌ radio_country_stations_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'worldDiceCount' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)
if '_openWorldDice' not in s:
    print('❌ apply_world_dice.py 를 먼저 실행해 주세요'); sys.exit(1)

edits = [
('저장 기능 불러오기',
"import 'package:provider/provider.dart';\n",
"import 'package:provider/provider.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\n"),
('상태 칸',
"  final ScrollController _listCtrl = ScrollController();\n",
"""  final ScrollController _listCtrl = ScrollController();
  // 주사위: 처음 소개 팝업 · NEW 표시
  bool _diceIntro = false;
  bool _diceNew = false;
"""),
('처음 들어올 때 확인',
"""      context.read<RadioProvider>().fetchTopStations(widget.country.code);
    });
""",
"""      context.read<RadioProvider>().fetchTopStations(widget.country.code);
    });
    _loadDiceFlags();
"""),
('던질 때 기록',
"""    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pool = _worldDicePool(all);""",
"""    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    _diceUsed();
    final pool = _worldDicePool(all);"""),
('팝업·NEW 함수',
"  void _openWorldDice(List<RadioStation> all) {",
"""  // 소개 팝업은 한 번만 (한국 라디오와 같이 씀) · NEW는 7일 안에 3번 던질 때까지
  Future<void> _loadDiceFlags() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    var first = p.getInt('worldDiceNewFrom');
    if (first == null) {
      first = now;
      await p.setInt('worldDiceNewFrom', now);
    }
    final count = p.getInt('worldDiceCount') ?? 0;
    final days = (now - first) / 86400000;
    if (!mounted) return;
    setState(() {
      _diceNew = count < 3 && days < 7;
      _diceIntro = !(p.getBool('radioDiceIntroSeen') ?? false);
    });
  }

  Future<void> _diceUsed() async {
    final p = await SharedPreferences.getInstance();
    final count = (p.getInt('worldDiceCount') ?? 0) + 1;
    await p.setInt('worldDiceCount', count);
    await p.setBool('radioDiceIntroSeen', true);
    if (!mounted) return;
    setState(() {
      _diceIntro = false;
      if (count >= 3) _diceNew = false;
    });
  }

  Future<void> _closeDiceIntro() async {
    setState(() => _diceIntro = false);
    final p = await SharedPreferences.getInstance();
    await p.setBool('radioDiceIntroSeen', true);
  }

  void _openWorldDice(List<RadioStation> all) {"""),
('아이콘에 NEW',
"""              onPressed: () => _openWorldDice(allStations),
              icon: RollDiceIcon(size: 24, color: baseColor),""",
"""              onPressed: () => _openWorldDice(allStations),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  RollDiceIcon(size: 24, color: baseColor),
                  if (_diceNew)
                    Positioned(
                      top: -7,
                      right: -13,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE05A4F), borderRadius: BorderRadius.circular(6)),
                        child: const Text('NEW',
                            style: TextStyle(
                                color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                      ),
                    ),
                ],
              ),"""),
('팝업 자리 (시작)',
"""      body: SafeArea(
        top: false,
        child: Column(""",
"""      body: Stack(
        children: [
      SafeArea(
        top: false,
        child: Column("""),
('팝업 자리 (끝)',
"""      ),
      bottomNavigationBar: current != null
          ? Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),""",
"""      ),
          // 처음 들어왔을 때 한 번: 주사위 소개 (방송을 다 불러온 뒤)
          if (_diceIntro && !isLoading && allStations.isNotEmpty && _mode == _ViewMode.all)
            Positioned.fill(
              child: RadioDiceIntro(
                onThrow: () => _openWorldDice(allStations),
                onClose: _closeDiceIntro,
              ),
            ),
        ],
      ),
      bottomNavigationBar: current != null
          ? Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom),"""),
]

for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 바꾸지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

shutil.copy(path, path + '.bak3')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak3)')
