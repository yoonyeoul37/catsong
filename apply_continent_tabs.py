# -*- coding: utf-8 -*-
# 해외 라디오 나라 고르기: 대륙 탭(D안: 글자 + 작은 점) + 검색칸은 오른쪽 위 돋보기로
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'screens', 'radio_home_screen.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_continentTabs(' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ('대륙·검색 상태 추가',
  """  bool _isListening = false;
""",
  """  bool _isListening = false;

  // ── 대륙 탭 (D안) · 검색칸은 오른쪽 위 돋보기로 열기 ──
  String _continent = 'ALL'; // 'ALL' = 전체
  bool _searchOpen = false;
  final FocusNode _searchFocus = FocusNode();
"""),
 ('정리할 때 검색 포커스도',
  """    _search.dispose();
    super.dispose();""",
  """    _search.dispose();
    _searchFocus.dispose();
    super.dispose();"""),
 ('검색칸 포커스 연결',
  """              controller: _search,
""",
  """              controller: _search,
              focusNode: _searchFocus,
"""),
 ('내 나라 카드는 전체에서만',
  """    if (myCountry != null) {
      final mine = myCountry;""",
  """    if (myCountry != null && _continent == 'ALL') {
      final mine = myCountry;"""),
 ('고른 대륙만 보이기',
  """    for (final continent in sorted) {
      final group = countries.where((c) => c.continent == continent && c.code != myCountry?.code).toList();""",
  """    for (final continent in sorted) {
      if (_continent != 'ALL' && continent != _continent) continue; // 대륙 탭: 고른 대륙만
      // 전체에선 내 나라가 위 카드로 가니 빼고, 대륙을 고르면 목록에 그대로 둠
      final group = countries.where((c) => c.continent == continent && (_continent != 'ALL' || c.code != myCountry?.code)).toList();"""),
 ('대륙 탭 만들기',
  """  void _onCountryTap(BuildContext context, RadioCountry country) {""",
  """  /// 대륙 탭 (D안): 글자만, 고른 곳은 진하게 + 아래 작은 점 — 옆으로 넘기기
  Widget _continentTabs(List<RadioCountry> countries, bool isDark) {
    const order = ['ASIA', 'EUROPE', 'NORTH_AMERICA', 'SOUTH_AMERICA', 'MIDDLE_EAST', 'AFRICA', 'OCEANIA'];
    // 목록과 같게: 내 대륙을 맨 앞으로
    final myCode = DeviceCountry.radioCountry(usePick: false);
    String? myCont;
    for (final c in countries) {
      if (c.code == myCode) {
        myCont = c.continent;
        break;
      }
    }
    final list = List<String>.from(order);
    if (myCont != null && list.remove(myCont)) list.insert(0, myCont);
    final keys = ['ALL', ...list.where((k) => countries.any((c) => c.continent == k))];
    String label(String k) => switch (k) {
          'ALL' => tr.all,
          'ASIA' => tr.continentAsia,
          'EUROPE' => tr.continentEurope,
          'NORTH_AMERICA' => tr.continentNorthAmerica,
          'SOUTH_AMERICA' => tr.continentSouthAmerica,
          'MIDDLE_EAST' => tr.continentMiddleEast,
          'AFRICA' => tr.continentAfrica,
          'OCEANIA' => tr.continentOceania,
          _ => k,
        };
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          for (final k in keys)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_continent == k) return;
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                setState(() => _continent = k);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label(k),
                      style: TextStyle(
                        color: _continent == k ? ink : ink.withOpacity(0.38),
                        fontSize: 15,
                        fontWeight: _continent == k ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // 고른 곳 아래 작은 점
                    AnimatedOpacity(
                      opacity: _continent == k ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onCountryTap(BuildContext context, RadioCountry country) {"""),
 ('오른쪽 위 돋보기',
  """        actions: [
          const SizedBox(width: 6),
        ],""",
  """        actions: [
          // 돋보기: 누르면 검색칸 열기 / 다시 누르면(✕) 닫고 검색어 지우기
          IconButton(
            onPressed: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _search.clear();
                  _query = '';
                  if (_isListening) {
                    _speech.stop();
                    _isListening = false;
                  }
                }
              });
              if (_searchOpen) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: isDarkMode ? Colors.white : Colors.black, size: 24),
          ),
          const SizedBox(width: 6),
        ],"""),
 ('검색칸은 열었을 때만 + 대륙 탭',
  """            // 나라 검색칸
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: _searchField(isDarkMode),
            ),""",
  """            // 나라 검색칸: 오른쪽 위 돋보기를 눌렀을 때만
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: _searchField(isDarkMode),
              ),
            // 대륙 탭 (검색하는 동안은 숨김)
            if (_query.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: _continentTabs(countries, isDarkMode),
              ),"""),
 ('대륙 바꾸면 목록 다시 스르륵',
  """                  key: ValueKey(_query), // 검색어 바뀌면 처음부터 다시 스르륵""",
  """                  key: ValueKey('$_query|$_continent'), // 검색어·대륙 바뀌면 처음부터 다시 스르륵"""),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)
if crlf: s = s.replace('\n', '\r\n')
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
