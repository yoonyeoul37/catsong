# -*- coding: utf-8 -*-
# 자연 화면을 라디오와 똑같이: 위쪽 밑줄 탭 · 구분선 · 전체 탭 묶음 제목
import os, sys

PATH = os.path.join('lib', 'screens', 'nature_sounds_screen.dart')

EDITS = [
    (
        '탭 목록과 밑줄 탭 만들기',
        "  @override\n  Widget build(BuildContext context) {\n    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n    final baseColor = isDarkMode ? Colors.white : Colors.black;\n    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);",
        """  static const _categories = ['전체', '파도소리', '빗소리', '새소리', '모닥불', '시냇물'];

  /// 라디오와 같은 탭: 박스 없이 글자 + 고른 탭만 아래 진한 밑줄
  Widget _natureTab(String category, bool isDarkMode) {
    final selected = _selectedCategory == category;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          setState(() => _selectedCategory = category);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? (isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F)) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // 글자가 커도 한 줄 (넘치면 칸에 맞게 살짝 줄임)
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              category == '전체' ? tr.all : natureName(category),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                color: selected
                    ? (isDarkMode ? Colors.white : const Color(0xFF17140F))
                    : baseColor.withOpacity(0.55),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 전체 탭 묶음 제목: 이름 · 개수 뒤로 가는 선 (라디오와 같음)
  Widget _natureGroupTitle(String category, bool first, Color baseColor) {
    final count = _sounds.where((s) => s.category == category).length;
    return Padding(
      padding: EdgeInsets.only(top: first ? 6 : 22, bottom: 6),
      child: Row(
        children: [
          Flexible(
            child: Text(
              natureName(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: baseColor.withOpacity(0.72), fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          Text('$count',
              style: GoogleFonts.quicksand(color: baseColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: baseColor.withOpacity(0.18))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA);""",
    ),
    (
        '위쪽에 라디오와 같은 탭 줄 넣기',
        "        actions: const [\n          SizedBox(width: 8),\n        ],\n      ),",
        """        actions: const [
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: baseColor.withOpacity(0.12), width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in _categories) _natureTab(c, isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),""",
    ),
    (
        '목록 여백을 라디오와 같게 (양옆 24)',
        "        padding: const EdgeInsets.all(20),",
        "        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),",
    ),
    (
        '예전 회색 상자 탭 지우기',
        None,  # 아래에서 시작~끝으로 찾아 지움
        "",
    ),
    (
        '곡 줄을 라디오와 같게 (양옆 여백 없음 · 듣는 중이면 연한 강조색)',
        """                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    // 듣는 중: 바탕 위에 살짝 밝은 칸
                    decoration: BoxDecoration(
                      color: isGroupPlaying
                          ? (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.55))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),""",
        """                    padding: const EdgeInsets.symmetric(vertical: 12),
                    // 듣는 중: 라디오와 같은 연한 강조색 칸
                    color: isGroupPlaying ? primaryColor.withOpacity(0.08) : Colors.transparent,""",
    ),
    (
        '줄 사이 구분선 · 전체 탭 묶음 제목 (라디오와 같음)',
        """              // 흰 카드 없이 바탕 위에 줄만 (국가 목록과 같은 방식, 아주 연한 구분선)
              return [
                Column(
                  children: [
                    for (var i = 0; i < _natureCards.length; i++) ...[
                      if (i > 0)
                        Container(
                            height: 0.6,
                            margin: const EdgeInsetsDirectional.only(start: 78, end: 12),
                            color: baseColor.withOpacity(0.07)),
                      _natureCards[i],
                    ],
                  ],
                ),
              ];""",
        """              // 라디오와 같게: 줄 사이 선 · 전체 탭은 소리 종류별 묶음 제목
              final cardCats = grouped.values.map((v) => v.first.category).toList();
              final order = List<int>.generate(_natureCards.length, (i) => i);
              final showTitles = _selectedCategory == '전체';
              if (showTitles) {
                int rank(String c) {
                  final r = _categories.indexOf(c);
                  return r < 0 ? 999 : r;
                }
                order.sort((a, b) {
                  final d = rank(cardCats[a]).compareTo(rank(cardCats[b]));
                  return d != 0 ? d : a.compareTo(b);
                });
              }
              final rows = <Widget>[];
              String? lastCat;
              for (final i in order) {
                final cat = cardCats[i];
                if (showTitles && cat != lastCat) {
                  rows.add(_natureGroupTitle(cat, lastCat == null, baseColor)); // 제목 앞뒤는 선 없이
                } else if (rows.isNotEmpty) {
                  rows.add(Divider(height: 1, color: baseColor.withOpacity(0.1)));
                }
                lastCat = cat;
                rows.add(_natureCards[i]);
              }
              return [
                Column(children: rows),
              ];""",
    ),
]

OLD_TAB_START = "            \n            Builder(builder: (context) {\n              final categories = ['전체', '파도소리', '빗소리', '새소리', '모닥불', '시냇물'];"
OLD_TAB_END = "              );\n            }),\n            const SizedBox(height: 16),\n"


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        sys.exit(1)
    with open(PATH, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    if '_natureTab(' in text:
        print('이미 적용돼 있어요')
        return

    for name, old, new in EDITS:
        if old is None:
            s = text.find(OLD_TAB_START)
            if s < 0 or text.count(OLD_TAB_START) != 1:
                print('❌', name, '— 시작 부분을 못 찾았어요. 아무것도 저장 안 했어요')
                sys.exit(1)
            e = text.find(OLD_TAB_END, s)
            if e < 0:
                print('❌', name, '— 끝 부분을 못 찾았어요. 아무것도 저장 안 했어요')
                sys.exit(1)
            text = text[:s] + text[e + len(OLD_TAB_END):]
            print('✔', name)
            continue
        n = text.count(old)
        if n != 1:
            print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        text = text.replace(old, new)
        print('✔', name)

    if crlf:
        text = text.replace('\n', '\r\n')
    with open(PATH, 'wb') as f:
        f.write(text.encode('utf-8'))
    print('✔ 저장했어요:', PATH)


main()
