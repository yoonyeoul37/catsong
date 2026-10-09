# -*- coding: utf-8 -*-
# 로고 B안: 포인트 색을 바꾸면 먹색 "파란" 위로 포인트 색 빛이 흘러감
# (apply_home_step1.py 를 먼저 실행한 뒤에 실행)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
HOME = os.path.join(ROOT, 'lib', 'screens', 'home_screen.dart')

EDITS = [
    ('한국어 "파란"에 포인트 색 빛',
     "                          else\n"
     "                            Text('파란',\n"
     "                                textScaler: TextScaler.noScaling,\n"
     "                                style: GoogleFonts.doHyeon(\n"
     "                                    color: baseColor,\n"
     "                                    fontSize: 22,\n"
     "                                    letterSpacing: -0.5)),\n",
     "                          else\n"
     "                            _LogoBreathe(\n"
     "                              base: baseColor,\n"
     "                              glow: pointColor,\n"
     "                              child: Text('파란',\n"
     "                                  textScaler: TextScaler.noScaling,\n"
     "                                  style: GoogleFonts.doHyeon(\n"
     "                                      color: baseColor,\n"
     "                                      fontSize: 22,\n"
     "                                      letterSpacing: -0.5)),\n"
     "                            ),\n"),
    ('해외 "Paran"에 포인트 색 빛',
     "                      else\n"
     "                        Text('Paran',\n"
     "                            style: GoogleFonts.doHyeon(\n"
     "                                color: baseColor,\n"
     "                                fontSize: 20,\n"
     "                                height: 1.0,\n"
     "                                letterSpacing: -0.3)),\n",
     "                      else\n"
     "                        _LogoBreathe(\n"
     "                          base: baseColor,\n"
     "                          glow: pointColor,\n"
     "                          child: Text('Paran',\n"
     "                              style: GoogleFonts.doHyeon(\n"
     "                                  color: baseColor,\n"
     "                                  fontSize: 20,\n"
     "                                  height: 1.0,\n"
     "                                  letterSpacing: -0.3)),\n"
     "                        ),\n"),
    ('빛 애니메이션이 색을 받게',
     "class _LogoBreathe extends StatefulWidget {\n"
     "  final Widget child;\n"
     "  const _LogoBreathe({required this.child});\n",
     "class _LogoBreathe extends StatefulWidget {\n"
     "  final Widget child;\n"
     "  final Color? base; // 글자 색 (없으면 기본 파랑)\n"
     "  final Color? glow; // 지나가는 빛 색 (없으면 기본 하늘색)\n"
     "  const _LogoBreathe({required this.child, this.base, this.glow});\n"),
    ('빛 색 적용',
     "            colors: const [\n"
     "              Color(0xFF2F7DE8),\n"
     "              Color(0xFF2F7DE8),\n"
     "              Color(0xFF5FA6F2), // 번짐 시작\n"
     "              Color(0xFFA9D3FF), // 가장 밝은 곳\n"
     "              Color(0xFF5FA6F2), // 번짐 끝\n"
     "              Color(0xFF2F7DE8),\n"
     "              Color(0xFF2F7DE8),\n"
     "            ],\n",
     "            colors: [\n"
     "              base,\n"
     "              base,\n"
     "              mid, // 번짐 시작\n"
     "              glow, // 가장 밝은 곳\n"
     "              mid, // 번짐 끝\n"
     "              base,\n"
     "              base,\n"
     "            ],\n"),
    ('빛 색 준비',
     "        final x = -0.5 + _c.value * 2.0; // 빛 위치: 왼쪽 밖 → 오른쪽 밖 (쉬지 않고)\n",
     "        final x = -0.5 + _c.value * 2.0; // 빛 위치: 왼쪽 밖 → 오른쪽 밖 (쉬지 않고)\n"
     "        // 기본: 파랑 글자 + 하늘색 빛 / 포인트 색 바꾸면: 먹색 글자 + 포인트 색 빛\n"
     "        final base = widget.base ?? const Color(0xFF2F7DE8);\n"
     "        final glow = widget.glow ?? const Color(0xFFA9D3FF);\n"
     "        final mid = widget.glow == null\n"
     "            ? const Color(0xFF5FA6F2)\n"
     "            : Color.lerp(base, glow, 0.55)!;\n"),
]

MARK = 'glow: pointColor'


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
    if not os.path.exists(HOME):
        print('❌ 파일을 못 찾았어요:', HOME)
        sys.exit(1)
    raw = open(HOME, 'rb').read().decode('utf-8')
    if MARK in raw:
        print('이미 적용돼 있어요')
        return
    if 'isBluePoint' not in raw:
        print('❌ apply_home_step1.py 를 먼저 실행해 주세요')
        sys.exit(1)
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
    open(HOME, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
