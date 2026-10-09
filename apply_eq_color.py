# -*- coding: utf-8 -*-
# 제목 옆 작은 이퀄라이저 → 포인트 색 따라가기 (기본 파란소리일 땐 원래 파란색)
# 라디오 홈 · 국내 라디오 · 국가별 라디오 · 자연 · 나만의 소리 · 수면·집중 제목 옆이 같이 바뀌어요
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
FILE = os.path.join(ROOT, 'lib', 'widgets', 'logo_eq_bars.dart')

EDITS = [
    ('불러오기',
     "import 'package:flutter/material.dart';\n",
     "import 'package:flutter/material.dart';\n"
     "import 'package:provider/provider.dart';\n"
     "import '../providers/theme_provider.dart';\n"),
    ('포인트 색 고르기',
     "  Widget build(BuildContext context) {\n"
     "    return SizedBox(\n",
     "  Widget build(BuildContext context) {\n"
     "    // 포인트 색 (바꾸면 바로 따라감) — 기본 파란소리면 원래 파란색 그대로\n"
     "    final point = context.watch<ThemeProvider>().primaryColor;\n"
     "    final color = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;\n"
     "    return SizedBox(\n"),
    ('막대 색',
     "                    color: const Color(0xFF2F7DE8),\n",
     "                    color: color,\n"),
]

MARK = 'context.watch<ThemeProvider>().primaryColor'


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
    if not os.path.exists(FILE):
        print('❌ 파일을 못 찾았어요:', FILE)
        sys.exit(1)
    raw = open(FILE, 'rb').read().decode('utf-8')
    if MARK in raw:
        print('이미 적용돼 있어요')
        return
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    ok = True
    for name, old, new in EDITS:
        if text.count(old) != 1:
            print('❌', name, '(찾을 코드를 못 찾았어요)')
            ok = False
            continue
        text = text.replace(old, new)
        print('✔', name)
    if not balanced(text):
        print('❌ 괄호가 안 맞아요')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    if crlf:
        text = text.replace('\n', '\r\n')
    open(FILE, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
