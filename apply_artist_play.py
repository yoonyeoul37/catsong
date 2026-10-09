# -*- coding: utf-8 -*-
# 6번: 아티스트 목록 › 자리에 ▶ 바로 재생 + 사진 없는 가수 동그라미를 곡 목록과 같은 차분한 색·첫 글자로
# (apply_list_step.py 를 먼저 실행한 뒤에 실행)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(ROOT, 'lib', 'screens', 'artist_screen.dart')
HELPER = os.path.join(ROOT, 'lib', 'utils', 'no_album_helper.dart')

EDITS = [
    ('› 자리에 ▶ 바로 재생 버튼',
     "            Icon(Icons.chevron_right, color: baseColor.withOpacity(0.24), size: 20),\n",
     "            // ▶ 바로 재생 (줄을 누르면 지금처럼 곡 목록, ▶는 그 가수 곡을 바로 전부 재생)\n"
     "            GestureDetector(\n"
     "              behavior: HitTestBehavior.opaque,\n"
     "              onTap: () {\n"
     "                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
     "                context.read<PlayerProvider>().playFromList(artist.songs, 0, isPlayAllAction: true);\n"
     "              },\n"
     "              child: Container(\n"
     "                width: 34,\n"
     "                height: 34,\n"
     "                decoration: BoxDecoration(\n"
     "                  color: baseColor.withOpacity(0.07),\n"
     "                  shape: BoxShape.circle,\n"
     "                ),\n"
     "                child: Icon(Icons.play_arrow_rounded, size: 20, color: baseColor.withOpacity(0.6)),\n"
     "              ),\n"
     "            ),\n"),
    ('사진 없는 가수: 그라데이션 → 차분한 색 + 첫 글자',
     "      final name = (artist.displayName as String).trim();\n"
     "      var h = 0;\n"
     "      for (final c in name.codeUnits) {\n"
     "        h = (h * 31 + c) & 0x7fffffff;\n"
     "      }\n"
     "      child = DecoratedBox(\n"
     "        decoration: BoxDecoration(\n"
     "          gradient: LinearGradient(\n"
     "            begin: Alignment.topLeft,\n"
     "            end: Alignment.bottomRight,\n"
     "            colors: _grads[h % _grads.length],\n"
     "          ),\n"
     "        ),\n"
     "        child: Center(\n"
     "          child: Text(\n"
     "            name.isEmpty ? '♪' : name.characters.first.toUpperCase(),\n"
     "            style: TextStyle(\n"
     "              color: const Color(0xFFF4EFE5),\n"
     "              fontSize: size * 0.38,\n"
     "              fontWeight: FontWeight.w800,\n"
     "            ),\n"
     "          ),\n"
     "        ),\n"
     "      );\n",
     "      // 곡 목록의 사진 없는 곡과 같은 색 세트 (가수 이름으로 골라서 늘 같은 색)\n"
     "      final name = (artist.displayName as String).trim();\n"
     "      child = NoArtTile(\n"
     "        title: name,\n"
     "        colorKey: name,\n"
     "        size: size,\n"
     "        radius: size / 2,\n"
     "        isDark: context.watch<ThemeProvider>().isDarkMode,\n"
     "      );\n"),
    ('안 쓰는 옛 색 세트 지우기',
     "  // 재생목록 표지와 같은 색 세트 (가수 이름으로 골라서 늘 같은 색)\n"
     "  static const _grads = <List<Color>>[\n"
     "    [Color(0xFF3A3550), Color(0xFF6B4A3A)],\n"
     "    [Color(0xFF1F4E6B), Color(0xFF6FB3C9)],\n"
     "    [Color(0xFF6B4A3A), Color(0xFFE0915F)],\n"
     "    [Color(0xFF4A3F7A), Color(0xFFC79ACF)],\n"
     "    [Color(0xFF233D32), Color(0xFF7FA77A)],\n"
     "  ];\n\n",
     ""),
]

MARK = 'Icons.play_arrow_rounded, size: 20, color: baseColor.withOpacity(0.6)'


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
    for p in (ART, HELPER):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if 'class NoArtTile' not in open(HELPER, 'rb').read().decode('utf-8'):
        print('❌ apply_list_step.py 를 먼저 실행해 주세요')
        sys.exit(1)
    raw = open(ART, 'rb').read().decode('utf-8')
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
    open(ART, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
