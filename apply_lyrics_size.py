# -*- coding: utf-8 -*-
# 가사 글자 크기
# - 기본 크기를 한 단계 작게 (지금 부르는 줄 19 → 17, 다른 줄 15.5 → 14.5), 지금 줄 굵기도 한 단계 가볍게
# - ⋮ 메뉴 "가사 글자 크기": 작게 · 보통 · 크게 (모든 노래에 같이, 폰에 기억)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SCREEN = os.path.join(ROOT, 'lib', 'screens', 'lyrics_screen.dart')

SHEET = r"""
  // ───── 가사 글자 크기 (0 작게 · 1 보통 · 2 크게, 모든 노래에 같이) ─────
  static int _sizeStep = 1;
  double get _curSize => const [15.0, 17.0, 19.5][_sizeStep]; // 지금 부르는 줄
  double get _lineSize => const [13.0, 14.5, 16.5][_sizeStep]; // 다른 줄·시간 없는 가사

  /// 가 가 가 고르기 창 (누르면 뒤 가사에 바로 보임, 창은 안 닫힘)
  void _pickTextSize() {
    showParanSheet(
      context,
      title: '가사 글자 크기',
      builder: (ctx, setSheet) {
        final dark = context.read<ThemeProvider>().isDarkMode;
        final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
        final onInk = dark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
        final card = dark ? const Color(0xFF32302C) : Colors.white;
        final line = dark ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
        const labels = ['작게', '보통', '크게'];
        const sample = [15.0, 19.0, 23.0];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      setState(() => _sizeStep = i);
                      setSheet(() {});
                      final p = await SharedPreferences.getInstance();
                      await p.setInt('lyricsTextSize', i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 76,
                      decoration: BoxDecoration(
                        color: _sizeStep == i ? ink : card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _sizeStep == i ? ink : line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 28,
                            child: Center(
                              child: Text('가',
                                  style: TextStyle(
                                      color: _sizeStep == i ? onInk : ink,
                                      fontSize: sample[i],
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(labels[i],
                              style: TextStyle(
                                  color: _sizeStep == i ? onInk.withOpacity(0.8) : ink.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// ⏱ 박자 맞추기 창 (누를 때마다 바로 적용, 창은 안 닫힘)
"""

EDITS = [
    ('크기 고르기 창',
     "\n  /// ⏱ 박자 맞추기 창 (누를 때마다 바로 적용, 창은 안 닫힘)\n",
     SHEET),
    ('고른 크기 불러오기',
     "    _loadBgList(); // 인터넷 목록 받기 (못 받으면 기본 목록)\n",
     "    _loadBgList(); // 인터넷 목록 받기 (못 받으면 기본 목록)\n"
     "    SharedPreferences.getInstance().then((p) {\n"
     "      final s = (p.getInt('lyricsTextSize') ?? 1).clamp(0, 2);\n"
     "      if (s != _sizeStep && mounted) setState(() => _sizeStep = s);\n"
     "    });\n"),
    ('⋮ 메뉴: 누르면',
     "                  if (v == 'offset') _pickOffset(lp);\n",
     "                  if (v == 'offset') _pickOffset(lp);\n"
     "                  if (v == 'size') _pickTextSize();\n"),
    ('⋮ 메뉴: 가사 글자 크기',
     "                  if (lp.lyrics.isNotEmpty) _menuItem(Icons.timer_outlined, '박자 맞추기', 'offset'),\n",
     "                  if (lp.hasLyrics) _menuItem(Icons.format_size_rounded, '가사 글자 크기', 'size'),\n"
     "                  if (lp.lyrics.isNotEmpty) _menuItem(Icons.timer_outlined, '박자 맞추기', 'offset'),\n"),
    ('시간 있는 가사: 크기·굵기',
     "                        fontSize: index == lyricsProvider.currentLineIndex ? 19 : 15.5,\n"
     "                        height: 1.4,\n"
     "                        fontWeight:\n"
     "                            index == lyricsProvider.currentLineIndex ? FontWeight.w800 : FontWeight.w500,\n",
     "                        fontSize: index == lyricsProvider.currentLineIndex ? _curSize : _lineSize,\n"
     "                        height: 1.45,\n"
     "                        letterSpacing: -0.2,\n"
     "                        fontWeight:\n"
     "                            index == lyricsProvider.currentLineIndex ? FontWeight.w700 : FontWeight.w500,\n"),
    ('시간 없는 가사: 크기',
     "                      fontSize: 15.5,\n"
     "                      height: 1.8,\n",
     "                      fontSize: _lineSize,\n"
     "                      height: 1.8,\n"
     "                      letterSpacing: -0.2,\n"),
]

MARK = "'lyricsTextSize'"


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    if not os.path.exists(SCREEN):
        print('❌ 파일을 못 찾았어요:', SCREEN)
        sys.exit(1)
    raw = open(SCREEN, 'rb').read().decode('utf-8')
    if MARK in raw:
        print('이미 적용돼 있어요')
        return
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    before = balanced(text)
    ok = True
    for name, old, new in EDITS:
        if text.count(old) != 1:
            print('❌', name, '(찾을 코드를 못 찾았어요)')
            ok = False
            continue
        text = text.replace(old, new)
        print('✔', name)
    if before and not balanced(text):
        print('❌ 괄호가 안 맞아요')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    if crlf:
        text = text.replace('\n', '\r\n')
    open(SCREEN, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
