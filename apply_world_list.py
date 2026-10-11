# -*- coding: utf-8 -*-
# 해외 라디오 목록: 요즘 뜨는 탭 · 나라마다 고른 칩 기억 · 맨 위 '다시 듣기' 한 줄
import sys, glob, os, shutil

def find(name):
    hits = glob.glob(os.path.join('lib', '**', name), recursive=True)
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def prepare(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    name = os.path.basename(path)
    if done_mark in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); return None
    for label, old, new, cnt in edits:
        n = s.count(old)
        if n != cnt:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요 (있어야 할 수 {cnt}). 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

# ───────── radio_provider.dart: 요즘 뜨는 정도(최근 이틀 사이 늘어난 청취 수) 기억 ─────────
prov = [
('요즘 뜨는 칸',
"  final Map<String, String> _stationLanguage = {}; // 방송 → 언어 (언어 칩용)\n",
"""  final Map<String, String> _stationLanguage = {}; // 방송 → 언어 (언어 칩용)
  final Map<String, int> _stationTrend = {}; // 방송 → 최근 이틀 사이 늘어난 청취 수 (요즘 뜨는 탭용)
""", 1),
('요즘 뜨는 값 꺼내기',
"  String languageOf(String stationUuid) => _stationLanguage[stationUuid] ?? '';\n",
"""  String languageOf(String stationUuid) => _stationLanguage[stationUuid] ?? '';
  int trendOf(String stationUuid) => _stationTrend[stationUuid] ?? 0;
""", 1),
('받을 때 기록',
"          if (lang.isNotEmpty) _stationLanguage[s.stationUuid] = lang;\n",
"""          if (lang.isNotEmpty) _stationLanguage[s.stationUuid] = lang;
          final tr = m['clicktrend'];
          if (tr is num) _stationTrend[s.stationUuid] = tr.toInt();
""", 1),
]

# ───────── radio_country_stations_screen.dart ─────────
funcs = r"""  // ── 인기 칩 안: 많이 듣는 · 요즘 뜨는 ──
  bool _hasTrend(List<RadioStation> all, RadioProvider radio) =>
      all.where((s) => radio.trendOf(s.stationUuid) > 0).length >= 5;

  // ── 나라마다 마지막으로 고른 칩 기억 ──
  String get _chipKey => 'radioChip_${widget.country.code}';

  Future<void> _loadChip() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_chipKey);
    if (v != null && mounted) setState(() => _savedChip = v);
  }

  void _saveChip() {
    final v = '$_chip|${_sub ?? ''}';
    SharedPreferences.getInstance().then((p) => p.setString(_chipKey, v));
  }

  /// 방송을 불러온 뒤 한 번: 저장해 둔 칩이 이 나라에 있으면 다시 골라 줌
  void _restoreChip(List<RadioStation> all, RadioProvider radio) {
    final v = _savedChip;
    if (v == null) return;
    _savedChip = null;
    final i = v.indexOf('|');
    final chip = i < 0 ? v : v.substring(0, i);
    final sub = i < 0 ? '' : v.substring(i + 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (chip == 'pop') {
        if (sub == _popTrend && _hasTrend(all, radio)) setState(() => _sub = _popTrend);
        return;
      }
      final opts = _optionsFor(chip, all, radio);
      if (opts.isEmpty) return;
      setState(() {
        _chip = chip;
        _sub = opts.any((o) => o.$1 == sub) ? sub : opts.first.$1;
      });
    });
  }

  // ── 맨 위 '다시 듣기': 이 나라에서 최근 들은 방송 + 즐겨찾기 ──
  List<RadioStation> _againList(RadioProvider radio) {
    final code = widget.country.code;
    final seen = <String>{};
    return [
      ...radio.recentlyListened.where((s) => s.countryCode == code),
      ...radio.favorites.where((s) => s.countryCode == code),
    ].where((s) => seen.add(s.stationUuid)).take(12).toList();
  }

  Widget _againRow(List<RadioStation> list, RadioProvider radio, Color baseColor) {
    final point = context.read<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final cur = radio.currentStation?.stationUuid;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('다시 듣기',
              style: TextStyle(color: baseColor.withOpacity(0.45), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final s = list[i];
                final on = s.stationUuid == cur;
                return GestureDetector(
                  onTap: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    radio.setQueue(list, i);
                    // 처음 누르면 바로 재생, 듣는 중인 방송을 또 누르면 상세 화면
                    if (!on) {
                      radio.playStation(s);
                      return;
                    }
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => RadioPlayerScreen(station: s, stationList: list, currentIndex: i),
                        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 54,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: on ? accent : Colors.transparent, width: 2),
                          ),
                          child: StationLogo(logoUrl: s.logoUrl, name: s.name, size: 46),
                        ),
                        const SizedBox(height: 5),
                        Text(s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: on ? accent : baseColor.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: baseColor.withOpacity(0.16)),
        ],
      ),
    );
  }

  /// 목록 맨 아래: 다음 방송 불러오는 중"""

scr = [
('상태 칸',
"""  bool _diceNew = false;
""",
"""  bool _diceNew = false;
  // 인기 칩 안 두 탭 · 이 나라에서 마지막으로 고른 칩
  static const String _popMost = '많이 듣는', _popTrend = '요즘 뜨는';
  String? _savedChip;
  bool get _isTrend => _chip == 'pop' && _sub == _popTrend;
""", 1),
('칩 기억 불러오기',
"""    _loadDiceFlags();
""",
"""    _loadDiceFlags();
    _loadChip();
""", 1),
('요즘 뜨는 탭은 더 안 불러옴',
"""      if (!_listCtrl.hasClients) return;
      final p = _listCtrl.position;""",
"""      if (!_listCtrl.hasClients || _isTrend) return;
      final p = _listCtrl.position;""", 1),
('함수들', "  /// 목록 맨 아래: 다음 방송 불러오는 중", funcs, 1),
('인기 탭 두 개',
"""    if (chips.length < 2) return const SizedBox.shrink(); // 고를 게 없는 나라는 칩 없이
    final selBg = isDarkMode ? Colors.white : const Color(0xFF17140F);
    final selFg = isDarkMode ? const Color(0xFF24221F) : Colors.white;
    final cur = _chip == 'pop' ? const <(String, int)>[] : (opts[_chip] ?? const <(String, int)>[]);""",
"""    final popOpts = _hasTrend(all, radio) ? const [(_popMost, 0), (_popTrend, 0)] : const <(String, int)>[];
    if (chips.length < 2 && popOpts.isEmpty) return const SizedBox.shrink(); // 고를 게 없는 나라는 칩 없이
    final selBg = isDarkMode ? Colors.white : const Color(0xFF17140F);
    final selFg = isDarkMode ? const Color(0xFF24221F) : Colors.white;
    final cur = _chip == 'pop' ? popOpts : (opts[_chip] ?? const <(String, int)>[]);
    final selSub = _chip == 'pop' ? (_sub ?? _popMost) : _sub;""", 1),
('칩 줄 (나라에 칩이 하나뿐이면 숨김)',
"""      children: [
        SizedBox(
          height: 34,""",
"""      children: [
        if (chips.length >= 2)
        SizedBox(
          height: 34,""", 1),
('칩 누르면 기억',
"""                      setState(() {
                        _chip = c;
                        final o = opts[c] ?? const <(String, int)>[];
                        _sub = o.isEmpty ? null : o.first.$1;
                      });
                      toTop();""",
"""                      setState(() {
                        _chip = c;
                        final o = opts[c] ?? const <(String, int)>[];
                        _sub = o.isEmpty ? null : o.first.$1;
                        _savedChip = null;
                      });
                      _saveChip();
                      toTop();""", 1),
('밑줄 탭 간격',
"""        if (cur.isNotEmpty) ...[
          const SizedBox(height: 10),""",
"""        if (cur.isNotEmpty) ...[
          if (chips.length >= 2) const SizedBox(height: 10),""", 1),
('밑줄 탭 누르면 기억',
"""                      setState(() => _sub = o.$1);
                      toTop();""",
"""                      setState(() {
                        _sub = o.$1;
                        _savedChip = null;
                      });
                      _saveChip();
                      toTop();""", 1),
('밑줄 표시', "_sub == o.$1", "selSub == o.$1", 3),
('개수는 있을 때만',
"""                          TextSpan(
                              text: ' ${o.$2}',""",
"""                          if (o.$2 > 0)
                          TextSpan(
                              text: ' ${o.$2}',""", 1),
('목록 정렬',
"""    final stations = allStations
        .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()))
        .where((s) => _matches(s, radioProvider))
        .toList();
""",
"""    var stations = allStations
        .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()))
        .where((s) => _matches(s, radioProvider))
        .toList();
    // 요즘 뜨는: 최근 이틀 사이 듣는 사람이 많이 늘어난 순
    if (_isTrend) {
      stations = stations.where((s) => radioProvider.trendOf(s.stationUuid) > 0).toList()
        ..sort((a, b) => radioProvider.trendOf(b.stationUuid).compareTo(radioProvider.trendOf(a.stationUuid)));
    }
""", 1),
('칩 되살리기 · 다시 듣기 목록',
"""    final isLoading = radioProvider.isLoadingCountryStations;
    final current = radioProvider.currentStation;
""",
"""    final isLoading = radioProvider.isLoadingCountryStations;
    final current = radioProvider.currentStation;
    if (!isLoading && allStations.isNotEmpty) _restoreChip(allStations, radioProvider);
    final again = (_chip == 'pop' && !_isTrend && _query.isEmpty)
        ? _againList(radioProvider)
        : const <RadioStation>[];
    final head = again.isEmpty ? 0 : 1;
""", 1),
('개수 글자',
"""                          _chip == 'pop' && _query.isEmpty
                              ? '방송""",
"""                          _isTrend
                              ? '요즘 듣는 사람이 늘어난 순'
                              : _chip == 'pop' && _query.isEmpty
                              ? '방송""", 1),
('목록 맨 위에 다시 듣기',
"""                      itemCount: stations.length + (radioProvider.countryHasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: baseColor.withOpacity(0.16)),
                      itemBuilder: (context, index) {
                        if (index >= stations.length) return _loadMoreRow(baseColor);""",
"""                      itemCount: head + stations.length + (radioProvider.countryHasMore && !_isTrend ? 1 : 0),
                      separatorBuilder: (_, i) => i < head
                          ? const SizedBox.shrink()
                          : Divider(height: 1, color: baseColor.withOpacity(0.16)),
                      itemBuilder: (context, index) {
                        if (index < head) return _againRow(again, radioProvider, baseColor);
                        index -= head;
                        if (index >= stations.length) return _loadMoreRow(baseColor);""", 1),
]

a = prepare(find('radio_provider.dart'), prov, '_stationTrend')
b = prepare(find('radio_country_stations_screen.dart'), scr, '_popTrend')
for r in (a, b):   # 둘 다 문제없을 때만 저장
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak4')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak4)')
