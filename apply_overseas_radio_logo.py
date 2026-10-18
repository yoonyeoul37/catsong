# -*- coding: utf-8 -*-
# 해외 라디오 위쪽 맞추기 (국내 라디오와 같게)
#  ① 나라 고르기 화면(radio_home_screen.dart): 'Radio' + 소리 막대 → 앱 아이콘 + 'Radio'(회색 빛)
#  ② 나라별 라디오 화면(radio_country_stations_screen.dart): 위쪽 나라 이름 → 앱 아이콘 + 'Radio'(회색 빛),
#     나라는 그 아래 '나라 선택 | 국기 나라 ▾' 상자로 (국내 라디오 상자와 같은 모양, 누르면 나라 고르기)
import os, sys

HOME = os.path.join('lib', 'screens', 'radio_home_screen.dart')
COUNTRY = os.path.join('lib', 'screens', 'radio_country_stations_screen.dart')
WIDGET = os.path.join('lib', 'widgets', 'logo_shine.dart')

ICON_RADIO = """            // 앱 아이콘 (홈 로고와 같은 모양, 포인트 색과 상관없이 고정)
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset('assets/logo_icon.png',
                  width: 26, height: 26, filterQuality: FilterQuality.medium),
            ),
            const SizedBox(width: 8),
            // 홈 로고와 같은 회색 빛이 지나감 (다크 모드는 흰 글자 위로 연한 회색 빛)
            LogoShine(
              base: %(c)s,
              glow: isDarkMode ? const Color(0xFFA8A29A) : const Color(0xFF968F85),
              child: Text(
                'Radio',
                style: titleFont(
                  color: %(c)s,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
            ),
"""

HOME_EDITS = [
    ('[나라 고르기] 빛 위젯 불러오기',
     "import '../widgets/radio_mini_player.dart';\n",
     "import '../widgets/radio_mini_player.dart';\nimport '../widgets/logo_shine.dart';\n"),
    ('[나라 고르기] 안 쓰는 dart:math 지우기',
     "import 'dart:math' as math;\n",
     ""),
    ('[나라 고르기] 아이콘 + Radio, 소리 막대 빼기',
     """          children: [
            Text(
              'Radio',
              style: titleFont(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            // 라디오를 틀면(미니플레이어가 뜨면) 여기 막대는 숨기기
            if (radioProvider.currentStation == null) ...[
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: _LogoEqBars(),
              ),
            ],
          ],
""",
     "          children: [\n" + ICON_RADIO % {'c': 'isDarkMode ? Colors.white : Colors.black'} + "          ],\n"),
]
HOME_EQ = ("// 상단바에 쓰는 작은 이퀄라이저 막대 (은은하게 움직임)\n", "/// 음악 곡 목록과 같은 등장")

COUNTRY_EDITS = [
    ('[나라별] 빛 위젯·글꼴 불러오기',
     "import '../widgets/radio_mini_player.dart';\n",
     "import '../widgets/radio_mini_player.dart';\nimport '../widgets/logo_shine.dart';\nimport '../utils/title_font.dart';\n"),
    ('[나라별] 위쪽: 나라 이름 → 아이콘 + Radio',
     """        // 나라 이름 (누르면 나라 고르기) — 긴 이름은 … 로 줄임
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.country.displayName,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: baseColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: baseColor.withOpacity(0.5)),
            ],
          ),
        ),
""",
     """        // 국내 라디오와 같은 위쪽: 앱 아이콘 + Radio (나라는 아래 '나라 선택' 상자로)
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
""" + ICON_RADIO % {'c': 'baseColor'} + """          ],
        ),
"""),
    ('[나라별] 위쪽 아래에 나라 선택 상자',
     """          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showSearch) Padding(
""",
     """          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 나라 선택 상자 (국내 라디오 상자와 같은 모양) — 누르면 나라 고르기
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 6),
              child: GestureDetector(
                onTap: () {
                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: radioTextScaler(ctx)), child: const RadioHomeScreen())), // 라디오 목록 글자 크기 맞추기 (다른 길과 같게)
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10), // 홈 카드·국내 라디오 상자와 같은 둥글기
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode
                              ? const Color(0x14FFFFFF)
                              : Colors.white.withOpacity(0.8),
                        ),
                        child: Icon(
                          Icons.public,
                          size: 16,
                          color: context.watch<ThemeProvider>().primaryColor.value == 0xFF2589E8
                              ? (isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
                              : context.watch<ThemeProvider>().primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tr.selectCountryShort,
                          style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, color: baseColor, fontSize: 13, fontWeight: FontWeight.w700)),
                      Container(
                        width: 1,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: baseColor.withOpacity(0.18),
                      ),
                      Text(widget.country.flag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(widget.country.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                color: baseColor.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: baseColor.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
            ),
            if (_showSearch) Padding(
"""),
]
COUNTRY_EQ = ("// 상단바에 쓰는 작은 이퀄라이저 막대 (은은하게 움직임)\n", None)  # 파일 끝까지

def load(p):
    raw = open(p, 'rb').read()
    crlf = b'\r\n' in raw
    return raw.decode('utf-8').replace('\r\n', '\n'), crlf

def apply(text, edits, eq):
    ok = True
    for name, old, new in edits:
        n = text.count(old)
        if n == 1:
            text = text.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n); ok = False
    s = text.find(eq[0])
    e = len(text) if eq[1] is None else text.find(eq[1])
    if s != -1 and e != -1 and s < e:
        text = text[:s].rstrip('\n') + '\n' + ('\n' + text[e:] if eq[1] else '')
        print('✔ 안 쓰는 소리 막대 위젯(_LogoEqBars) 지우기')
    else:
        print('❌ 소리 막대 위젯(_LogoEqBars) 지우기'); ok = False
    if '_LogoEqBars' in text:
        print('❌ 막대 코드가 아직 남아 있어요'); ok = False
    for o, c in ['()', '[]', '{}']:
        if text.count(o) != text.count(c):
            print('❌ 괄호 개수가 안 맞아요', o, c); ok = False
    return text, ok

def main():
    for p in (HOME, COUNTRY):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    if not os.path.exists(WIDGET):
        print('❌ lib/widgets/logo_shine.dart가 없어요 — 먼저 새 파일로 만들어 주세요'); print('\n아무것도 저장하지 않았어요.'); return 1
    h, hc = load(HOME); c, cc = load(COUNTRY)
    if 'LogoShine(' in h and 'LogoShine(' in c:
        print('이미 적용돼 있어요'); return 0
    h2, ok1 = apply(h, HOME_EDITS, HOME_EQ)
    c2, ok2 = apply(c, COUNTRY_EDITS, COUNTRY_EQ)
    if 'math.' in h2:
        print('❌ [나라 고르기] math가 아직 쓰이고 있어요'); ok1 = False
    if not (ok1 and ok2):
        print('\n아무것도 저장하지 않았어요.'); return 1
    for p, t, crlf in ((HOME, h2, hc), (COUNTRY, c2, cc)):
        if crlf: t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
        print('저장했어요:', p)
    return 0

if __name__ == '__main__':
    sys.exit(main())
