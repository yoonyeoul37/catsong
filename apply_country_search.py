# -*- coding: utf-8 -*-
# 라디오 나라 고르는 화면: 위에 나라 검색칸 + 오른쪽 대륙 빠른 이동 막대 (곡 목록 초성 막대처럼)
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('radio_home_screen.dart')
if not path:
    print('❌ lib 폴더에서 radio_home_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if '_ContinentBar' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

STATE = r"""class RadioHomeScreen extends StatefulWidget {
  const RadioHomeScreen({super.key});

  @override
  State<RadioHomeScreen> createState() => _RadioHomeScreenState();
}

class _RadioHomeScreenState extends State<RadioHomeScreen> {
  // ── 나라 검색 + 오른쪽 대륙 막대 ──
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  final GlobalKey _viewKey = GlobalKey();
  final Map<String, GlobalKey> _continentKeys = {};
  final List<String> _barOrder = []; // 화면에 보이는 대륙 순서
  String _query = '';
  String? _current; // 지금 보고 있는 대륙

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  /// 스크롤하면 지금 보고 있는 대륙을 막대에 표시
  void _onScroll() {
    final view = _viewKey.currentContext?.findRenderObject();
    if (view is! RenderBox || _barOrder.isEmpty) return;
    final top = view.localToGlobal(Offset.zero).dy;
    String cur = _barOrder.first;
    for (final c in _barOrder) {
      final box = _continentKeys[c]?.currentContext?.findRenderObject();
      if (box is! RenderBox) continue;
      if (box.localToGlobal(Offset.zero).dy - top <= 60) {
        cur = c;
      } else {
        break;
      }
    }
    if (cur != _current) setState(() => _current = cur);
  }

  /// 막대 누르면 그 대륙으로 바로
  void _jumpTo(String continent) {
    final ctx = _continentKeys[continent]?.currentContext;
    if (ctx == null) return;
    setState(() => _current = continent);
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  }

  /// 검색: 한글 이름 · 영어 이름 · 나라 코드 (띄어쓰기·대소문자 무시)
  bool _matches(RadioCountry c, String q) {
    String n(String v) => v.toLowerCase().replaceAll(' ', '');
    final k = n(q);
    if (k.isEmpty) return true;
    return n(c.displayName).contains(k) ||
        n(c.name).contains(k) ||
        n(_countryEn[c.code] ?? '').contains(k) ||
        c.code.toLowerCase() == k;
  }

  Widget _searchField(bool isDark) {
    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final hint = isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 20, color: hint),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              style: TextStyle(color: ink, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: isKo ? '나라 이름으로 찾기' : 'Search country',
                hintStyle: TextStyle(color: hint, fontSize: 15),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _search.clear();
                setState(() => _query = '');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.cancel_rounded, size: 18, color: hint),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  /// 검색 결과: 대륙 구분 없이 맞는 나라만
  List<Widget> _searchResults(List<RadioCountry> countries, bool isDark) {
    final found = countries.where((c) => _matches(c, _query)).toList();
    final base = isDark ? Colors.white : Colors.black;
    if (found.isEmpty) {
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      return [
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: base.withOpacity(0.25)),
              const SizedBox(height: 12),
              Text(isKo ? '찾는 나라가 없어요' : 'No country found',
                  style: TextStyle(color: base.withOpacity(0.45), fontSize: 14)),
            ],
          ),
        ),
      ];
    }
    return [
      for (int i = 0; i < found.length; i++)
        Column(
          children: [
            _CountryListTile(country: found[i], onTap: () => _onCountryTap(context, found[i])),
            if (i != found.length - 1)
              Divider(height: 1, thickness: 0.6, color: base.withOpacity(0.07), indent: 48),
          ],
        ),
    ];
  }
"""

rep('화면을 검색·막대가 되는 화면으로',
    "class RadioHomeScreen extends StatelessWidget {\n  const RadioHomeScreen({super.key});\n",
    STATE)

rep('대륙 순서 기억 (막대용)',
    "    final widgets = <Widget>[];\n",
    "    final widgets = <Widget>[];\n    _barOrder.clear();\n")

rep('대륙 순서 담기',
    "      if (group.isEmpty) continue;\n",
    "      if (group.isEmpty) continue;\n      _barOrder.add(continent);\n")

rep('대륙 제목에 위치표 달기',
    "      // 대륙 헤더\n"
    "      widgets.add(\n"
    "        Padding(\n"
    "          padding: const EdgeInsets.only(top: 24, bottom: 8),\n",
    "      // 대륙 헤더 (막대에서 누르면 여기로)\n"
    "      widgets.add(\n"
    "        Padding(\n"
    "          key: _continentKeys.putIfAbsent(continent, () => GlobalKey()),\n"
    "          padding: const EdgeInsets.only(top: 24, bottom: 8),\n")

OLD_BODY = """      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [

            Text(
              AppLocalizations.of(context)!.radioSelectCountry,
              style: TextStyle(
                color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.65),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            ..._buildCountryListByContinent(context, countries, isDarkMode),
            const SizedBox(height: 80),
          ],
        ),
      ),
"""
NEW_BODY = """      body: SafeArea(
        child: Column(
          children: [
            // 나라 검색칸
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: _searchField(isDarkMode),
            ),
            Expanded(
              child: Stack(
                key: _viewKey,
                children: [
                  SingleChildScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(24, 8, _query.isEmpty ? 40 : 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_query.isEmpty) ...[
                          Text(
                            AppLocalizations.of(context)!.radioSelectCountry,
                            style: TextStyle(
                              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.65),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ..._buildCountryListByContinent(context, countries, isDarkMode),
                        ] else
                          ..._searchResults(countries, isDarkMode),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  // 오른쪽 대륙 빠른 이동 막대 (검색 중엔 숨김)
                  if (_query.isEmpty && _barOrder.isNotEmpty)
                    Positioned(
                      right: 2,
                      top: 8,
                      bottom: 8,
                      child: _ContinentBar(
                        order: List.of(_barOrder),
                        current: _current ?? _barOrder.first,
                        isDark: isDarkMode,
                        isKo: Localizations.localeOf(context).languageCode == 'ko',
                        onPick: _jumpTo,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
"""
rep('검색칸 + 목록 + 오른쪽 막대 배치', OLD_BODY, NEW_BODY)

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

s = s.rstrip('\n') + r"""

/// 오른쪽 대륙 빠른 이동 막대 (곡 목록 초성 막대와 같은 느낌)
/// 지금 보는 대륙 = 강조 색 / 누르거나 쓸면 그 대륙으로
class _ContinentBar extends StatefulWidget {
  final List<String> order;
  final String current;
  final bool isDark;
  final bool isKo;
  final ValueChanged<String> onPick;
  const _ContinentBar({
    required this.order,
    required this.current,
    required this.isDark,
    required this.isKo,
    required this.onPick,
  });

  static const _ko = {
    'ASIA': '아시아',
    'EUROPE': '유럽',
    'NORTH_AMERICA': '북미',
    'SOUTH_AMERICA': '남미',
    'MIDDLE_EAST': '중동',
    'AFRICA': '아프리카',
    'OCEANIA': '오세아니아',
  };
  static const _en = {
    'ASIA': 'AS',
    'EUROPE': 'EU',
    'NORTH_AMERICA': 'NA',
    'SOUTH_AMERICA': 'SA',
    'MIDDLE_EAST': 'ME',
    'AFRICA': 'AF',
    'OCEANIA': 'OC',
  };

  @override
  State<_ContinentBar> createState() => _ContinentBarState();
}

class _ContinentBarState extends State<_ContinentBar> {
  String? _active; // 손가락이 닿아 있는 대륙

  void _handle(double dy, double h) {
    if (h <= 0 || widget.order.isEmpty) return;
    final i = (dy / h * widget.order.length).floor().clamp(0, widget.order.length - 1);
    final c = widget.order[i];
    if (c == _active) return;
    setState(() => _active = c);
    HapticFeedback.selectionClick();
    widget.onPick(c);
  }

  void _release() {
    if (_active != null) setState(() => _active = null);
  }

  @override
  Widget build(BuildContext context) {
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final muted = widget.isDark ? const Color(0xFFB8B0A2) : const Color(0xFF8A857B);
    return LayoutBuilder(builder: (context, cons) {
      final h = cons.maxHeight;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (d) => _handle(d.localPosition.dy, h),
        onVerticalDragUpdate: (d) => _handle(d.localPosition.dy, h),
        onVerticalDragEnd: (_) => _release(),
        onVerticalDragCancel: _release,
        onTapDown: (d) => _handle(d.localPosition.dy, h),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: SizedBox(
          width: 34,
          child: Column(
            children: [
              for (final c in widget.order)
                Expanded(
                  child: Center(
                    child: Builder(builder: (_) {
                      final active = c == _active;
                      final on = c == widget.current;
                      final label = widget.isKo
                          ? (_ContinentBar._ko[c] ?? c).split('').join('\n') // 한글은 세로로
                          : (_ContinentBar._en[c] ?? c);
                      final text = Text(
                        label,
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: active ? Colors.white : (on ? accent : muted),
                          fontSize: widget.isKo ? 11.5 : 11,
                          height: 1.15,
                          fontWeight: (active || on) ? FontWeight.w900 : FontWeight.w700,
                        ),
                      );
                      if (!active) return text;
                      return Container(
                        width: 24,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                        child: text,
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// 나라 영어 이름 (한국어 화면에서도 영어로 찾을 수 있게)
const Map<String, String> _countryEn = {
  'KR': 'Korea South Korea', 'JP': 'Japan', 'TW': 'Taiwan', 'CN': 'China', 'HK': 'Hong Kong',
  'VN': 'Vietnam', 'PH': 'Philippines', 'TH': 'Thailand', 'ID': 'Indonesia', 'IN': 'India',
  'MY': 'Malaysia', 'SG': 'Singapore', 'PK': 'Pakistan', 'BD': 'Bangladesh', 'LK': 'Sri Lanka',
  'NP': 'Nepal', 'MM': 'Myanmar', 'KH': 'Cambodia', 'MN': 'Mongolia', 'UZ': 'Uzbekistan',
  'KZ': 'Kazakhstan', 'LA': 'Laos', 'GE': 'Georgia', 'AM': 'Armenia', 'AZ': 'Azerbaijan',
  'GB': 'United Kingdom UK England Britain', 'DE': 'Germany', 'FR': 'France', 'ES': 'Spain', 'IT': 'Italy',
  'NL': 'Netherlands Holland', 'SE': 'Sweden', 'PL': 'Poland', 'RU': 'Russia', 'AT': 'Austria',
  'CH': 'Switzerland', 'BE': 'Belgium', 'PT': 'Portugal', 'GR': 'Greece', 'IE': 'Ireland',
  'NO': 'Norway', 'DK': 'Denmark', 'FI': 'Finland', 'CZ': 'Czech Czechia', 'RO': 'Romania',
  'UA': 'Ukraine', 'HU': 'Hungary', 'HR': 'Croatia', 'RS': 'Serbia', 'BG': 'Bulgaria',
  'SK': 'Slovakia', 'LT': 'Lithuania', 'LV': 'Latvia', 'EE': 'Estonia', 'IS': 'Iceland',
  'SI': 'Slovenia', 'AL': 'Albania', 'MK': 'North Macedonia', 'ME': 'Montenegro', 'BA': 'Bosnia Herzegovina',
  'MT': 'Malta', 'LU': 'Luxembourg', 'CY': 'Cyprus',
  'US': 'United States USA America', 'CA': 'Canada', 'MX': 'Mexico', 'CU': 'Cuba', 'JM': 'Jamaica',
  'DO': 'Dominican Republic', 'TT': 'Trinidad and Tobago', 'HT': 'Haiti', 'GT': 'Guatemala', 'HN': 'Honduras',
  'NI': 'Nicaragua', 'SV': 'El Salvador', 'PA': 'Panama', 'CR': 'Costa Rica', 'PR': 'Puerto Rico',
  'BR': 'Brazil', 'AR': 'Argentina', 'CO': 'Colombia', 'CL': 'Chile', 'PE': 'Peru',
  'VE': 'Venezuela', 'EC': 'Ecuador', 'BO': 'Bolivia', 'PY': 'Paraguay', 'UY': 'Uruguay',
  'TR': 'Turkey Turkiye', 'SA': 'Saudi Arabia', 'AE': 'United Arab Emirates UAE Dubai', 'IQ': 'Iraq', 'IR': 'Iran',
  'IL': 'Israel', 'EG': 'Egypt', 'JO': 'Jordan', 'LB': 'Lebanon',
  'ZA': 'South Africa', 'NG': 'Nigeria', 'KE': 'Kenya', 'GH': 'Ghana', 'TZ': 'Tanzania',
  'MA': 'Morocco', 'TN': 'Tunisia', 'ET': 'Ethiopia', 'UG': 'Uganda', 'CM': 'Cameroon',
  'SN': 'Senegal', 'ZW': 'Zimbabwe', 'MZ': 'Mozambique', 'MG': 'Madagascar',
  'AU': 'Australia', 'NZ': 'New Zealand', 'FJ': 'Fiji', 'PG': 'Papua New Guinea',
};
"""
print('✔ 대륙 막대 · 영어 나라 이름 넣기')

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
