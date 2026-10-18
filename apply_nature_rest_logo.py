# -*- coding: utf-8 -*-
# 자연·휴식 첫 화면 위쪽을 라디오와 같게: 앱 아이콘 + 'Nature' / 'Rest' (가운데, 회색 빛 애니메이션)
#  - 예전: 파란 글자 제목 + 소리 막대 + 아래 회색 설명 한 줄 → 지움
import os, sys

NATURE = os.path.join('lib', 'screens', 'nature_sounds_screen.dart')
REST = os.path.join('lib', 'screens', 'sleep_focus_screen.dart')
WIDGET = os.path.join('lib', 'widgets', 'logo_shine.dart')

def title_row(word, size):
    return """        centerTitle: true,
        // 라디오와 같은 위쪽: 앱 아이콘 + %(w)s (회색 빛이 지나감)
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 아이콘 (홈 로고와 같은 모양, 포인트 색과 상관없이 고정)
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset('assets/logo_icon.png',
                  width: 26, height: 26, filterQuality: FilterQuality.medium),
            ),
            const SizedBox(width: 8),
            LogoShine(
              base: baseColor,
              glow: isDarkMode ? const Color(0xFFA8A29A) : const Color(0xFF968F85),
              child: Text(
                '%(w)s',
                style: titleFont(
                  color: baseColor,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
""" % {'w': word}

NATURE_EDITS = [
    ('[자연] 소리 막대 대신 빛 위젯 불러오기',
     "import '../widgets/logo_eq_bars.dart';\n",
     "import '../widgets/logo_shine.dart';\n"),
    ('[자연] 위쪽: 아이콘 + Nature',
     """        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: tr.natureTitle1,
                        style: titleFont(
                            // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : baseColor, fontSize: 20),
                      ),
                      TextSpan(
                        text: tr.natureTitle2,
                        style: titleFont(
                            color: baseColor, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: LogoEqBars(),
                ),
              ],
            ),
            const SizedBox(height: 0),
            Text(
              tr.natureSub,
              style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 11.5),
            ),
          ],
        ),
""",
     title_row('Nature', 22)),
]

REST_EDITS = [
    ('[휴식] 소리 막대 대신 빛 위젯 불러오기',
     "import '../widgets/logo_eq_bars.dart';\n",
     "import '../widgets/logo_shine.dart';\n"),
    ('[휴식] 위쪽: 아이콘 + Rest',
     """        toolbarHeight: 64,
        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: tr.restLabel,
                        style: titleFont(
                            // 기본 포인트 색이면 파랑, 다른 색이면 먹색 (홈 로고와 같은 규칙)
                            color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : baseColor, fontSize: 19),
                      ),
                      TextSpan(
                        text: tr.focusTitlePart,
                        style: titleFont(
                            color: baseColor, fontSize: 19),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: LogoEqBars(),
                ),
              ],
            ),
            const SizedBox(height: 0),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                tr.restFocusSub,
                maxLines: 1,
                style: TextStyle(color: baseColor.withOpacity(0.5), fontSize: 11.5),
              ),
            ),
          ],
        ),
        centerTitle: false,
""",
     title_row('Rest', 22)),
    ('[휴식] 오른쪽 빈자리 (가운데 맞추기)',
     """      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
""",
     """        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
"""),
]

def load(p):
    raw = open(p, 'rb').read()
    crlf = b'\r\n' in raw
    return raw.decode('utf-8').replace('\r\n', '\n'), crlf

def apply(text, edits):
    ok = True
    for name, old, new in edits:
        n = text.count(old)
        if n == 1:
            text = text.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n); ok = False
    if 'LogoEqBars' in text:
        print('❌ 소리 막대가 아직 남아 있어요'); ok = False
    for o, c in ['()', '[]', '{}']:
        if text.count(o) != text.count(c):
            print('❌ 괄호 개수가 안 맞아요', o, c); ok = False
    return text, ok

def main():
    for p in (NATURE, REST):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    if not os.path.exists(WIDGET):
        print('❌ lib/widgets/logo_shine.dart가 없어요 — 먼저 새 파일로 만들어 주세요'); print('\n아무것도 저장하지 않았어요.'); return 1
    n, nc = load(NATURE); r, rc = load(REST)
    if 'LogoShine(' in n and 'LogoShine(' in r:
        print('이미 적용돼 있어요'); return 0
    n2, ok1 = apply(n, NATURE_EDITS)
    r2, ok2 = apply(r, REST_EDITS)
    if not (ok1 and ok2):
        print('\n아무것도 저장하지 않았어요.'); return 1
    for p, t, crlf in ((NATURE, n2, nc), (REST, r2, rc)):
        if crlf: t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
        print('저장했어요:', p)
    return 0

if __name__ == '__main__':
    sys.exit(main())
