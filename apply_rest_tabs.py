# -*- coding: utf-8 -*-
# 휴식·집중 화면 탭을 라디오·자연과 똑같이 (박스 없이 글자 + 고른 탭만 밑줄, 위쪽에 고정)
import os, sys

PATH = os.path.join('lib', 'screens', 'sleep_focus_screen.dart')

TAB_METHOD = """  String _selectedCategory = '전체';

  /// 라디오·자연과 같은 탭: 박스 없이 글자 + 고른 탭만 아래 진한 밑줄
  Widget _restTab(String category, bool isDarkMode) {
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
              _catLabel(category),
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
"""

EDITS = [
    ('탭 만들기 (라디오와 같은 모양)', "  String _selectedCategory = '전체';\n", TAB_METHOD),
    (
        '위쪽에 탭 줄 넣기',
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
                  for (final c in categories) _restTab(c, isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),""",
    ),
    ('예전 회색 상자 탭 지우기', None, ''),
]

OLD_START = "              const SizedBox(height: 8),\n              Container(\n                height: 38,"
OLD_END = "                    }).toList(),\n                  ),\n                ),\n              ),\n"


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        sys.exit(1)
    with open(PATH, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    if '_restTab(' in text:
        print('이미 적용돼 있어요')
        return

    for name, old, new in EDITS:
        if old is None:
            if text.count(OLD_START) != 1:
                print('❌', name, '— 시작 부분을 못 찾았어요. 아무것도 저장 안 했어요')
                sys.exit(1)
            s = text.find(OLD_START)
            e = text.find(OLD_END, s)
            if e < 0:
                print('❌', name, '— 끝 부분을 못 찾았어요. 아무것도 저장 안 했어요')
                sys.exit(1)
            text = text[:s] + text[e + len(OLD_END):]
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
