# -*- coding: utf-8 -*-
# 3단계: 재생화면 색 정리
# - 아래 줄(셔플·반복·수면·가사): 켜진 기능 점 = 포인트 색(조금 크게), 꺼진 아이콘은 더 흐리게 → 켜진 게 또렷
# - ⋮ 메뉴 안 셔플 스위치·반복 칸·스타일 표시: 포인트 색을 바꾸면 바로 따라가게 (늦게 바뀌던 것)
# - 재생화면 스타일 → 앨범 → 앨범아트 카드 모양 고르는 칸: 파란색 고정 → 먹색 (다크는 크림색)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PLAYER = os.path.join(ROOT, 'lib', 'screens', 'player_screen.dart')

EDITS = [
    ('아래 줄: 꺼진 아이콘 흐리게 + 포인트 색 준비',
     "    const baseColor = Colors.white;\n"
     "    final iconColor = isActive ? baseColor : baseColor.withOpacity(0.55);\n",
     "    const baseColor = Colors.white;\n"
     "    // 켜진 건 또렷한 흰색, 꺼진 건 흐리게 (사진 위라서 큰 건 흰색 유지)\n"
     "    final iconColor = isActive ? baseColor : baseColor.withOpacity(0.45);\n"
     "    final point = context.watch<ThemeProvider>().primaryColor; // 켜짐 점 = 포인트 색\n"),
    ('아래 줄: 켜짐 점을 포인트 색으로',
     "            Container(\n"
     "              width: 3,\n"
     "              height: 3,\n"
     "              decoration: BoxDecoration(\n"
     "                shape: BoxShape.circle,\n"
     "                color: isActive ? AppTheme.fixedAccent : Colors.transparent,\n",
     "            Container(\n"
     "              width: 4,\n"
     "              height: 4,\n"
     "              decoration: BoxDecoration(\n"
     "                shape: BoxShape.circle,\n"
     "                color: isActive ? point : Colors.transparent,\n"),
    ('⋮ 메뉴: 포인트 색 바꾸면 바로 따라가게',
     "        final playerProvider = ctx.watch<PlayerProvider>();\n"
     "        return SafeArea(\n",
     "        final playerProvider = ctx.watch<PlayerProvider>();\n"
     "        _sheetBlue = ctx.watch<ThemeProvider>().primaryColor; // 셔플·반복·스타일 표시 = 지금 포인트 색\n"
     "        return SafeArea(\n"),
    ('앨범아트 카드 모양 칸: 먹색',
     "    const blue = Color(0xFF2589E8);\n"
     "    final l = AppLocalizations.of(context)!;\n",
     "    // 고른 칸은 먹색 (다크 모드는 크림색) — 포인트 색과 상관없이 늘 같게\n"
     "    final dark = context.read<ThemeProvider>().isDarkMode;\n"
     "    final blue = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n"
     "    final onBlue = dark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);\n"
     "    final l = AppLocalizations.of(context)!;\n"),
    ('앨범아트 카드 모양 칸: 글자색',
     "                                  color: printStyle == e.key ? Colors.white : const Color(0xFF8A8378),\n",
     "                                  color: printStyle == e.key ? onBlue : const Color(0xFF8A8378),\n"),
]

MARK = 'final onBlue = dark'


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
    if not os.path.exists(PLAYER):
        print('❌ 파일을 못 찾았어요:', PLAYER)
        sys.exit(1)
    raw = open(PLAYER, 'rb').read().decode('utf-8')
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
    open(PLAYER, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
