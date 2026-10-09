# -*- coding: utf-8 -*-
# 홈 1단계: 로고 C안 + 셔플 둥글게 + 초성 굵게
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
HOME = os.path.join(ROOT, 'lib', 'screens', 'home_screen.dart')
BAR = os.path.join(ROOT, 'lib', 'widgets', 'index_bar.dart')

EDITS = {
    HOME: [
        ('로고: 지금 포인트 색 읽기',
         "    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n"
         "    final baseColor = isDarkMode ? Colors.white : Colors.black;\n"
         "    return AppBar(\n",
         "    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n"
         "    final baseColor = isDarkMode ? Colors.white : Colors.black;\n"
         "    // 로고: 기본 색(파란소리)일 땐 \"파란\"만 파랑, 다른 포인트 색이면 글씨는 전부 먹색 + 막대만 포인트 색\n"
         "    final pointColor = context.watch<ThemeProvider>().primaryColor;\n"
         "    final isBluePoint = pointColor.value == 0xFF2589E8;\n"
         "    final logoBarColor = isBluePoint ? const Color(0xFF2F7DE8) : pointColor;\n"
         "    return AppBar(\n"),
        ('로고: 한국어 "파란"',
         "                          _LogoBreathe(\n"
         "                            child: Text('파란',\n"
         "                                textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정\n"
         "                                style: GoogleFonts.doHyeon(\n"
         "                                    color: const Color(0xFF2F7DE8),\n"
         "                                    fontSize: 22,\n"
         "                                    letterSpacing: -0.5)),\n"
         "                          ),\n",
         "                          if (isBluePoint)\n"
         "                            _LogoBreathe(\n"
         "                              child: Text('파란',\n"
         "                                  textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정\n"
         "                                  style: GoogleFonts.doHyeon(\n"
         "                                      color: const Color(0xFF2F7DE8),\n"
         "                                      fontSize: 22,\n"
         "                                      letterSpacing: -0.5)),\n"
         "                            )\n"
         "                          else\n"
         "                            Text('파란',\n"
         "                                textScaler: TextScaler.noScaling,\n"
         "                                style: GoogleFonts.doHyeon(\n"
         "                                    color: baseColor,\n"
         "                                    fontSize: 22,\n"
         "                                    letterSpacing: -0.5)),\n"),
        ('로고: 해외 "Paran"',
         "                      _LogoBreathe(\n"
         "                        child: Text('Paran',\n"
         "                            style: GoogleFonts.doHyeon(\n"
         "                                color: const Color(0xFF2F7DE8),\n"
         "                                fontSize: 20,\n"
         "                                height: 1.0,\n"
         "                                letterSpacing: -0.3)),\n"
         "                      ),\n",
         "                      if (isBluePoint)\n"
         "                        _LogoBreathe(\n"
         "                          child: Text('Paran',\n"
         "                              style: GoogleFonts.doHyeon(\n"
         "                                  color: const Color(0xFF2F7DE8),\n"
         "                                  fontSize: 20,\n"
         "                                  height: 1.0,\n"
         "                                  letterSpacing: -0.3)),\n"
         "                        )\n"
         "                      else\n"
         "                        Text('Paran',\n"
         "                            style: GoogleFonts.doHyeon(\n"
         "                                color: baseColor,\n"
         "                                fontSize: 20,\n"
         "                                height: 1.0,\n"
         "                                letterSpacing: -0.3)),\n"),
        ('로고: 막대에 색 넘겨주기',
         "              child: const _LogoEqBars(),\n",
         "              child: _LogoEqBars(color: logoBarColor),\n"),
        ('로고: 막대 위젯이 색 받기',
         "class _LogoEqBars extends StatefulWidget {\n"
         "  const _LogoEqBars();\n",
         "class _LogoEqBars extends StatefulWidget {\n"
         "  final Color color;\n"
         "  const _LogoEqBars({required this.color});\n"),
        ('로고: 막대 색 적용',
         "                  height: 14 * v,\n"
         "                  decoration: BoxDecoration(\n"
         "                    color: const Color(0xFF2F7DE8),\n",
         "                  height: 14 * v,\n"
         "                  decoration: BoxDecoration(\n"
         "                    color: widget.color,\n"),
        ('셔플 아이콘 둥글게',
         "icon: Icon(Icons.shuffle, color: baseColor.withOpacity(0.6), size: 20),",
         "icon: Icon(Icons.shuffle_rounded, color: baseColor.withOpacity(0.6), size: 21),"),
    ],
    BAR: [
        ('초성 글자 굵게',
         "        fontWeight: (isActive || g == widget.current) ? FontWeight.w800 : FontWeight.w600,",
         "        fontWeight: (isActive || g == widget.current) ? FontWeight.w900 : FontWeight.w700,"),
    ],
}

MARK = 'isBluePoint'


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
    for p in EDITS:
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)

    with open(HOME, 'rb') as f:
        if MARK.encode() in f.read():
            print('이미 적용돼 있어요')
            return

    results = {}
    ok = True
    for path, edits in EDITS.items():
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        results[path] = text.replace('\n', '\r\n') if crlf else text

    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)

    for path, text in results.items():
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
