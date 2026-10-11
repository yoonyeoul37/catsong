# -*- coding: utf-8 -*-
# 해외 라디오 주사위: 나라 화면 오른쪽 위 주사위 → 이 나라 음악 방송 중 하나
import sys, glob, os, shutil

def find(name):
    hits = glob.glob(os.path.join('lib', '**', name), recursive=True)
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def patch(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if done_mark in s:
        print(f'✔ {os.path.basename(path)}: 이미 적용돼 있어요'); return
    for label, old, new in edits:
        n = s.count(old)
        if n != 1:
            print(f'❌ {os.path.basename(path)}: [{label}] 찾을 곳이 {n}개예요. 바꾸지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
    shutil.copy(path, path + '.bak2')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
    print(f'✔ {os.path.basename(path)}: {len(edits)}곳 바꿈 (원본은 .bak2)')

# ───── radio_dice.dart: 결과 카드 글자를 바꿀 수 있게 ─────
dice = [
('DiceStation 칸 추가',
"""  final double weight; // 나올 확률 (1 = 보통, 0.3 = 덜 나옴)

  const DiceStation({
    required this.station,
    required this.badge,
    this.frequency = '',
    required this.program,
    this.weight = 1.0,
  });""",
"""  final double weight; // 나올 확률 (1 = 보통, 0.3 = 덜 나옴)
  final double badgeSize; // 로고 칸 글자 크기 (국기는 크게)
  final String programLabel; // 카드 아래 작은 제목
  final String emptyProgram; // 정보가 없을 때

  const DiceStation({
    required this.station,
    required this.badge,
    this.frequency = '',
    required this.program,
    this.weight = 1.0,
    this.badgeSize = 10.5,
    this.programLabel = '지금 하는 프로그램',
    this.emptyProgram = '편성 정보가 없어요',
  });"""),
('로고 칸 글자 크기',
"style: TextStyle(color: point, fontSize: 10.5, fontWeight: FontWeight.w800)),",
"style: TextStyle(color: point, fontSize: item.badgeSize, fontWeight: FontWeight.w800)),"),
('작은 제목',
"const Text('지금 하는 프로그램', style: TextStyle(color: hint, fontSize: 11.5)),",
"Text(item.programLabel, style: const TextStyle(color: hint, fontSize: 11.5)),"),
('정보 없을 때',
"Text(program.isEmpty ? '편성 정보가 없어요' : program,",
"Text(program.isEmpty ? item.emptyProgram : program,"),
]

# ───── radio_country_stations_screen.dart ─────
pool = r"""  // ── 해외 라디오 주사위: 이 나라 인기 음악 방송 중 하나 ──
  static const Set<String> _notMusic = {'뉴스', '토크', '스포츠', '종교', '어린이'};

  List<DiceStation> _worldDicePool(List<RadioStation> all) {
    final music = <RadioStation>[], plain = <RadioStation>[];
    for (final s in all.take(400)) {
      final g = _genresOf(s);
      if (g.any(_notMusic.contains)) continue; // 뉴스·토크·종교 등은 빼기
      (g.isEmpty ? plain : music).add(s);
    }
    var list = music.take(150).toList();
    if (list.length < 10) list = [...list, ...plain].take(150).toList(); // 장르 정보가 적은 나라
    final c = widget.country;
    final time = _localTimeText(c.code);
    return [
      for (final s in list)
        DiceStation(
          station: s,
          badge: c.flag,
          badgeSize: 20,
          frequency: [
            (s.state?.trim().isNotEmpty ?? false) ? s.state!.trim() : c.displayName,
            if (time != null) time,
          ].join(' · '),
          programLabel: '지금 나오는 곡',
          emptyProgram: '곡 정보가 아직 없어요',
          program: (r) =>
              r.currentStation?.stationUuid == s.stationUuid ? (r.streamTitle ?? '').trim() : '',
        ),
    ];
  }

  void _openWorldDice(List<RadioStation> all) {
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    final pool = _worldDicePool(all);
    if (pool.isEmpty) return;
    final list = [for (final d in pool) d.station];
    showRadioDice(context, pool, onOpen: (st) {
      if (!mounted) return;
      final i = math.max(0, list.indexWhere((x) => x.stationUuid == st.stationUuid));
      context.read<RadioProvider>().setQueue(list, i);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => RadioPlayerScreen(station: st, stationList: list, currentIndex: i),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    });
  }

  String _sloganFor(BuildContext context, String countryCode) {"""

localtime = r"""// ── 현지 시각 (시간대가 하나인 나라만. 여러 시간대 나라는 안 보여줌) ──
const Map<String, double> _utcFixed = {
  'JP': 9, 'KR': 9, 'CN': 8, 'TW': 8, 'HK': 8, 'SG': 8, 'MY': 8, 'PH': 8, 'MN': 8,
  'TH': 7, 'VN': 7, 'KH': 7, 'LA': 7, 'MM': 6.5, 'BD': 6, 'NP': 5.75, 'IN': 5.5, 'LK': 5.5,
  'PK': 5, 'UZ': 5, 'KZ': 5, 'AE': 4, 'AZ': 4, 'AM': 4, 'GE': 4, 'IR': 3.5,
  'SA': 3, 'IQ': 3, 'JO': 3, 'TR': 3, 'KE': 3, 'ET': 3, 'TZ': 3, 'UG': 3, 'MG': 3,
  'ZA': 2, 'ZW': 2, 'MZ': 2, 'NG': 1, 'CM': 1, 'TN': 1, 'GH': 0, 'SN': 0, 'IS': 0,
  'AR': -3, 'UY': -3, 'VE': -4, 'BO': -4, 'DO': -4, 'PR': -4, 'TT': -4,
  'CO': -5, 'PE': -5, 'EC': -5, 'PA': -5, 'JM': -5,
  'GT': -6, 'HN': -6, 'NI': -6, 'SV': -6, 'CR': -6, 'PG': 10, 'FJ': 12,
};
// 유럽: 3월 마지막 일요일 ~ 10월 마지막 일요일은 한 시간 빠름
const Map<String, double> _utcEu = {
  'GB': 0, 'IE': 0, 'PT': 0,
  'ES': 1, 'FR': 1, 'DE': 1, 'IT': 1, 'NL': 1, 'BE': 1, 'LU': 1, 'CH': 1, 'AT': 1,
  'SE': 1, 'NO': 1, 'DK': 1, 'PL': 1, 'CZ': 1, 'SK': 1, 'HU': 1, 'HR': 1, 'SI': 1,
  'RS': 1, 'BA': 1, 'ME': 1, 'MK': 1, 'AL': 1, 'MT': 1,
  'FI': 2, 'EE': 2, 'LV': 2, 'LT': 2, 'RO': 2, 'BG': 2, 'GR': 2, 'CY': 2, 'UA': 2,
};

DateTime _lastSundayUtc(int y, int m) {
  final last = DateTime.utc(y, m + 1, 0); // 그 달 마지막 날
  return DateTime.utc(y, m, last.day - (last.weekday % 7), 1);
}

/// '현지 오후 3:12' (모르는 나라는 null)
String? _localTimeText(String code) {
  final now = DateTime.now().toUtc();
  var off = _utcFixed[code];
  if (off == null) {
    final eu = _utcEu[code];
    if (eu == null) return null;
    final summer = !now.isBefore(_lastSundayUtc(now.year, 3)) && now.isBefore(_lastSundayUtc(now.year, 10));
    off = eu + (summer ? 1 : 0);
  }
  final t = now.add(Duration(minutes: (off * 60).round()));
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '현지 ${t.hour < 12 ? '오전' : '오후'} $h12:${t.minute.toString().padLeft(2, '0')}';
}

class _StationTile extends StatelessWidget {"""

screen = [
('주사위 불러오기',
"import '../widgets/heart_pop.dart';\n",
"import '../widgets/heart_pop.dart';\nimport '../widgets/radio_dice.dart';\n"),
('주사위 함수',
"  String _sloganFor(BuildContext context, String countryCode) {", pool),
('위쪽 주사위 아이콘',
"""        actions: [
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() {
                _showSearch = !_showSearch;""",
"""        actions: [
          if (!isLoading && allStations.isNotEmpty)
            IconButton(
              onPressed: () => _openWorldDice(allStations),
              icon: RollDiceIcon(size: 24, color: baseColor),
            ),
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() {
                _showSearch = !_showSearch;"""),
('현지 시각',
"class _StationTile extends StatelessWidget {", localtime),
]

patch(find('radio_dice.dart'), dice, 'this.programLabel')
patch(find('radio_country_stations_screen.dart'), screen, '_openWorldDice')
print('끝! 해외 나라 화면 오른쪽 위 주사위를 눌러 보세요.')
