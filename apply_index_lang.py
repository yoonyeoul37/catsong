# -*- coding: utf-8 -*-
# 곡 목록 초성 바를 폰 언어에 맞게 (한국어 / 영어·중국어 / 일본어) + 손 떼면 3초 뒤 닫기
import io, sys

FILES = {
    'letter': 'lib/utils/index_letter.dart',
    'bar': 'lib/widgets/index_bar.dart',
    'home': 'lib/screens/home_screen.dart',
}
data, crlf = {}, {}
for k, p in FILES.items():
    try:
        raw = io.open(p, 'r', encoding='utf-8', newline='').read()
    except FileNotFoundError:
        print('❌ 파일이 없어요:', p); sys.exit(1)
    crlf[k] = '\r\n' in raw
    data[k] = raw.replace('\r\n', '\n')

if 'List<String> indexGroupsFor(' in data['letter']:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
def rep(k, name, old, new, optional_done=None):
    global ok
    s = data[k]
    if optional_done and optional_done in s:
        print('✔', name, '(이미 돼 있음)'); return
    if s.count(old) == 1:
        data[k] = s.replace(old, new); print('✔', name); return
    print('❌', name, '(찾을 코드를 못 찾음)'); ok = False

# ── 1) index_letter.dart: 언어별 칸·글자 함수 추가 (원래 함수는 그대로 둠)
data['letter'] = data['letter'].rstrip('\n') + '\n' + r'''
// ───────── 폰 언어별 빠른 이동 막대 ─────────
// 한국어: A-Z · ㄱ~ㅎ · #   /   일본어: あ~わ · A-Z · #   /   그 밖(영어·중국어 등): A~Z · #

const _kAtoZ = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];
const _kKanaRows = ['あ', 'か', 'さ', 'た', 'な', 'は', 'ま', 'や', 'ら', 'わ'];
const _kIndexGroupsJa = [..._kKanaRows, 'A-Z', '#'];
const _kIndexGroupsLatin = [..._kAtoZ, '#'];

/// 막대에 나오는 칸 (폰 언어 코드: ko, ja, en, zh ...)
List<String> indexGroupsFor(String lang) {
  if (lang == 'ko') return kIndexGroups;
  if (lang == 'ja') return _kIndexGroupsJa;
  return _kIndexGroupsLatin;
}

/// 히라가나·가타카나 첫 글자 → 50음 줄 (あ か さ ...), 아니면 null
String? _kanaRow(int c) {
  if (c >= 0x30A1 && c <= 0x30F6) c -= 0x60; // 가타카나 → 히라가나
  if (c >= 0x30F7 && c <= 0x30FA) return 'わ'; // ヷ ヸ ヹ ヺ
  if (c < 0x3041 || c > 0x3096) return null;
  if (c <= 0x304A || c == 0x3094) return 'あ';
  if (c <= 0x3054 || c == 0x3095 || c == 0x3096) return 'か';
  if (c <= 0x305E) return 'さ';
  if (c <= 0x3069) return 'た';
  if (c <= 0x306E) return 'な';
  if (c <= 0x307D) return 'は';
  if (c <= 0x3082) return 'ま';
  if (c <= 0x3088) return 'や';
  if (c <= 0x308D) return 'ら';
  return 'わ';
}

/// 곡 제목(또는 가수) → 막대 칸
String indexGroupFor(String text, String lang) {
  if (lang == 'ko') return indexGroupOf(text);
  final t = text.trimLeft();
  if (t.isEmpty) return '#';
  final c = t.runes.first;
  final ch = String.fromCharCode(c).toUpperCase();
  final isLatin = ch.length == 1 && ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90;
  if (lang == 'ja') {
    final row = _kanaRow(c);
    if (row != null) return row;
    return isLatin ? 'A-Z' : '#'; // 한자 제목은 읽는 법을 몰라서 #
  }
  return isLatin ? ch : '#';
}
'''
print('✔ index_letter.dart 언어별 함수 추가')

# ── 2) index_bar.dart: 칸 목록을 밖에서 받기
rep('bar', '막대 칸 받기 (필드)',
"""  final ValueChanged<String?> onActiveChanged; // 가운데 큰 글자 표시용
""",
"""  final ValueChanged<String?> onActiveChanged; // 가운데 큰 글자 표시용
  final List<String> groups; // 막대 칸 (폰 언어별)
""")
rep('bar', '막대 칸 받기 (생성자)',
"""    this.current,
  });""",
"""    this.current,
    this.groups = kIndexGroups,
  });""")
rep('bar', '가까운 글자 찾기',
"""    const g = kIndexGroups;""",
"""    final g = widget.groups;""")
rep('bar', '누른 위치 계산',
"""    final i = (dy / height * kIndexGroups.length)
        .floor()
        .clamp(0, kIndexGroups.length - 1);""",
"""    final n = widget.groups.length;
    final i = (dy / height * n).floor().clamp(0, n - 1);""")
rep('bar', '글자 크기 (칸이 많으면 조금 작게)',
"""        fontSize: isAZ ? 11.5 : 14.5,""",
"""        fontSize: isAZ ? 11.5 : (widget.groups.length > 20 ? 12.5 : 14.5),""")
rep('bar', '막대 그리기',
"""                children: kIndexGroups
                    .map((g) => Expanded(child: Center(child: _item(g))))""",
"""                children: widget.groups
                    .map((g) => Expanded(child: Center(child: _item(g))))""")

# ── 3) home_screen.dart
rep('home', '묶기: 폰 언어 읽기',
"""    var fp = songs.length * 2 + (_byArtist ? 1 : 0);""",
"""    final lang = Localizations.localeOf(context).languageCode; // 초성 바는 폰 언어별
    var fp = songs.length * 2 + (_byArtist ? 1 : 0) + lang.hashCode;""")
rep('home', '묶기: 언어별 칸',
"""      byGroup.putIfAbsent(indexGroupOf(keyOf(s)), () => []).add(s);""",
"""      byGroup.putIfAbsent(indexGroupFor(keyOf(s), lang), () => []).add(s);""")
rep('home', '묶기: 언어별 순서',
"""    for (final g in kIndexGroups) {""",
"""    for (final g in indexGroupsFor(lang)) {""")
rep('home', '막대에 칸 넘기기',
"""                      builder: (context, cur, _) => IndexBar(
                        available: available,""",
"""                      builder: (context, cur, _) => IndexBar(
                        groups: indexGroupsFor(Localizations.localeOf(context).languageCode),
                        available: available,""")
rep('home', '지금 칸 표시',
"""                        current: cur ?? (available.isNotEmpty ? kIndexGroups.firstWhere(available.contains) : null),""",
"""                        current: cur ?? (available.isNotEmpty
                            ? indexGroupsFor(Localizations.localeOf(context).languageCode).firstWhere(available.contains)
                            : null),""")
# 손 떼면 3초 (아침에 준 찾기/바꾸기를 이미 했으면 건너뜀)
rep('home', '손 떼면 3초 뒤 닫기 ①',
"""                          _pokeIndexBar(); // 누르고 있는 동안은 안 사라지게
""",
"""                          // 누르고 있는 동안은 안 사라지게, 손 떼면 3초 뒤에 닫기
                          _pokeIndexBar(hideMs: l == null ? 3000 : 1500);
""", optional_done='_pokeIndexBar(hideMs: l == null ? 3000 : 1500);')
rep('home', '손 떼면 3초 뒤 닫기 ②',
"""  void _pokeIndexBar() {
    if (!_indexShow.value) _indexShow.value = true;
    final t = ++_indexHideToken;
    Future.delayed(const Duration(milliseconds: 1500), () {""",
"""  void _pokeIndexBar({int hideMs = 1500}) {
    if (!_indexShow.value) _indexShow.value = true;
    final t = ++_indexHideToken;
    Future.delayed(Duration(milliseconds: hideMs), () {""", optional_done='void _pokeIndexBar({int hideMs = 1500})')

if not ok:
    print('\n아무것도 저장하지 않았어요. 지금 파일들을 다시 보내 주세요.'); sys.exit(1)
for k, p in FILES.items():
    out = data[k].replace('\n', '\r\n') if crlf[k] else data[k]
    io.open(p, 'w', encoding='utf-8', newline='').write(out)
print('\n저장했어요 ✔')
