# -*- coding: utf-8 -*-
# 라디오 나라 목록: 오른쪽 대륙 글자 막대 빼고,
# 음악 곡 목록처럼 내리고 올릴 때 줄이 옆에서 스르륵 들어오는 애니메이션 넣기 (검색칸은 그대로)
import os, sys, shutil, re

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

if 'class _Appear' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)
if '_ContinentBar' not in s:
    print('❌ 먼저 apply_country_search.py를 적용해야 해요. 아무것도 저장 안 했어요.')
    sys.exit(1)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

def cut(title, start, end, keep_end=True, insert=''):
    global s, ok
    a = s.find(start)
    b = s.find(end, a + 1) if a >= 0 else -1
    if a >= 0 and b > a:
        s = s[:a] + insert + (s[b:] if keep_end else s[b + len(end):])
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

# 1) 막대용 칸·스크롤 따라가기 빼기
rep('막대용 기억 칸 빼기',
    "  // ── 나라 검색 + 오른쪽 대륙 막대 ──\n"
    "  final ScrollController _scroll = ScrollController();\n"
    "  final TextEditingController _search = TextEditingController();\n"
    "  final GlobalKey _viewKey = GlobalKey();\n"
    "  final Map<String, GlobalKey> _continentKeys = {};\n"
    "  final List<String> _barOrder = []; // 화면에 보이는 대륙 순서\n"
    "  String _query = '';\n"
    "  String? _current; // 지금 보고 있는 대륙\n"
    "\n"
    "  @override\n"
    "  void initState() {\n"
    "    super.initState();\n"
    "    _scroll.addListener(_onScroll);\n"
    "  }\n"
    "\n"
    "  @override\n"
    "  void dispose() {\n"
    "    _scroll.dispose();\n"
    "    _search.dispose();\n"
    "    super.dispose();\n"
    "  }\n",
    "  // ── 나라 검색 ──\n"
    "  final TextEditingController _search = TextEditingController();\n"
    "  String _query = '';\n"
    "\n"
    "  @override\n"
    "  void dispose() {\n"
    "    _search.dispose();\n"
    "    super.dispose();\n"
    "  }\n")

cut('스크롤 따라가기·막대 이동 빼기',
    "  /// 스크롤하면 지금 보고 있는 대륙을 막대에 표시\n",
    "  /// 검색: 한글 이름")

rep('대륙 순서 기억 빼기 (1)', "    final widgets = <Widget>[];\n    _barOrder.clear();\n", "    final widgets = <Widget>[];\n")
rep('대륙 순서 기억 빼기 (2)', "      if (group.isEmpty) continue;\n      _barOrder.add(continent);\n", "      if (group.isEmpty) continue;\n")
rep('대륙 제목 위치표 빼기',
    "      // 대륙 헤더 (막대에서 누르면 여기로)\n"
    "      widgets.add(\n"
    "        Padding(\n"
    "          key: _continentKeys.putIfAbsent(continent, () => GlobalKey()),\n",
    "      // 대륙 헤더\n"
    "      widgets.add(\n"
    "        Padding(\n")

# 2) 목록: 음악 곡 목록처럼 보일 때마다 스르륵
NEW_LIST = """            Expanded(
              child: Builder(builder: (context) {
                final items = <Widget>[
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
                ];
                // 음악 곡 목록처럼: 내리고 올릴 때 화면에 들어오는 줄이 옆에서 스르륵
                return ListView.builder(
                  key: ValueKey(_query), // 검색어 바뀌면 처음부터 다시 스르륵
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _Appear(child: items[i]),
                );
              }),
            ),
"""
cut('목록에 스르륵 애니메이션 (막대 빼기)',
    "            Expanded(\n              child: Stack(\n                key: _viewKey,\n",
    "          ],\n        ),\n      ),\n      bottomNavigationBar:",
    keep_end=True, insert=NEW_LIST)

# 3) 막대 그림 빼고 애니메이션 부품 넣기
cut('대륙 막대 그림 빼기',
    "/// 오른쪽 대륙 빠른 이동 막대 (곡 목록 초성 막대와 같은 느낌)\n",
    "/// 나라 영어 이름 (한국어 화면에서도 영어로 찾을 수 있게)\n",
    keep_end=True,
    insert="""/// 음악 곡 목록과 같은 등장: 옆에서 살짝 밀려 들어오며 커지고 선명해짐
class _Appear extends StatelessWidget {
  final Widget child;
  const _Appear({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) => Transform.translate(
        offset: Offset((1 - v) * 24, 0),
        child: Transform.scale(
          scale: 0.95 + 0.05 * v,
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
      ),
    );
  }
}

""")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
