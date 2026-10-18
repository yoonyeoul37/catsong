# -*- coding: utf-8 -*-
# 라디오(국내·나라 고르기·나라별)·자연·휴식 위쪽을 홈 로고와 같은 짜임으로:
#   앱 아이콘 + 제목(홈 카드 이름, 회색 빛) / 아래 설명 한 줄(홈 카드 설명, '(준비중)'은 빼고)
#   한국어 폰: 라디오 / 자연 / 휴식 · 집중,  해외: 그 나라 말 (이미 번역된 홈 카드 문구)
import os, re, sys

WIDGET = os.path.join('lib', 'widgets', 'logo_shine.dart')
FILES = [
    (os.path.join('lib', 'screens', 'radio_korea_screen2.dart'), 'Radio', 'tr.catRadio', 'tr.catRadioSub'),
    (os.path.join('lib', 'screens', 'radio_home_screen.dart'), 'Radio', 'tr.catRadio', 'tr.catRadioSub'),
    (os.path.join('lib', 'screens', 'radio_country_stations_screen.dart'), 'Radio', 'tr.catRadio', 'tr.catRadioSub'),
    (os.path.join('lib', 'screens', 'nature_sounds_screen.dart'), 'Nature', 'tr.catNature', 'tr.catNatureSub'),
    (os.path.join('lib', 'screens', 'sleep_focus_screen.dart'), 'Rest', 'tr.catRest', 'tr.catRestSub'),
]

MENU_TITLE = '''

/// 메뉴 첫 화면 위쪽 (라디오·자연·휴식): 앱 아이콘 + 제목(회색 빛) / 아래 설명 한 줄
/// 홈 로고(아이콘 + 파란소리 / PARANSORI)와 같은 짜임
class MenuTitle extends StatelessWidget {
  final String title; // 홈 카드 이름 (라디오 · 자연 · 휴식 · 집중)
  final String sub; // 홈 카드 설명
  final bool isDark;
  const MenuTitle({super.key, required this.title, required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white : Colors.black;
    // 위쪽은 이름표라서 '(준비중)' 같은 끝 괄호는 빼기
    final shortSub = sub.replaceAll(RegExp(r'\\s*[\\x28（][^\\x29）]*[\\x29）]\\s*$'), '');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 앱 아이콘 (홈 로고와 같은 모양, 포인트 색과 상관없이 고정)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/logo_icon.png',
              width: 32, height: 32, filterQuality: FilterQuality.medium),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 위로만 회색 빛 (다크 모드는 흰 글자 위로 연한 회색 빛)
              LogoShine(
                base: base,
                glow: isDark ? const Color(0xFFA8A29A) : const Color(0xFF968F85),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling, // 로고처럼 글자 크기 설정과 상관없이 고정
                  style: titleFont(color: base, fontSize: 20, letterSpacing: 0.3),
                ),
              ),
              // 설명 한 줄: 긴 언어는 넘치지 않게 살짝 작아짐
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  shortSub,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(color: base.withOpacity(0.5), fontSize: 11.5, height: 1.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
'''

# 지금 위쪽: '// 앱 아이콘 (홈 로고와 같은 모양…)' 부터 'Radio/Nature/Rest' 글자를 감싼 LogoShine 끝까지
PAT = r"( *)// 앱 아이콘 \(홈 로고와 같은 모양, 포인트 색과 상관없이 고정\)\n.*?'%s',\n.*?\n\1\),\n"

def load(p):
    raw = open(p, 'rb').read()
    crlf = b'\r\n' in raw
    return raw.decode('utf-8').replace('\r\n', '\n'), crlf

def main():
    for p, *_ in FILES:
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    if not os.path.exists(WIDGET):
        print('❌ lib/widgets/logo_shine.dart가 없어요 — 먼저 새 파일로 만들어 주세요'); print('\n아무것도 저장하지 않았어요.'); return 1
    w, wc = load(WIDGET)
    texts = {p: load(p) for p, *_ in FILES}
    if 'class MenuTitle' in w and all('MenuTitle(' in texts[p][0] for p, *_ in FILES):
        print('이미 적용돼 있어요'); return 0
    ok = True
    out = {}
    # ① logo_shine.dart에 MenuTitle 더하기
    if 'class MenuTitle' not in w:
        if "import '../utils/title_font.dart';" not in w:
            w = w.replace("import 'package:flutter/material.dart';\n",
                          "import 'package:flutter/material.dart';\nimport '../utils/title_font.dart';\n", 1)
        w = w.rstrip('\n') + '\n' + MENU_TITLE
        print('✔ logo_shine.dart: 메뉴 위쪽 모양(MenuTitle) 더하기')
    out[WIDGET] = (w, wc)
    # ② 화면 다섯 곳 위쪽 바꾸기
    for p, word, title, sub in FILES:
        t, crlf = texts[p]
        name = os.path.basename(p)
        if 'MenuTitle(' in t:
            print('✔', name, '(이미 바뀌어 있음)'); out[p] = (t, crlf); continue
        m = list(re.finditer(PAT % word, t, re.S))
        if len(m) != 1:
            print('❌', name, ': 위쪽 아이콘 + %s 자리를 못 찾았어요 (찾은 개수: %d)' % (word, len(m))); ok = False; continue
        ind = m[0].group(1)
        new = ('%s// 앱 아이콘 + 제목(회색 빛) / 아래 설명 — 홈 로고와 같은 짜임 (해외는 그 나라 말)\n'
               '%sFlexible(child: MenuTitle(title: %s, sub: %s, isDark: isDarkMode)),\n') % (ind, ind, title, sub)
        t = t[:m[0].start()] + new + t[m[0].end():]
        t = t.replace('// 라디오와 같은 위쪽: 앱 아이콘 + %s (회색 빛이 지나감)' % word,
                      '// 라디오·자연·휴식 같은 위쪽: 앱 아이콘 + 제목 / 설명')
        for o, c in ['()', '[]', '{}']:
            if t.count(o) != t.count(c):
                print('❌', name, ': 괄호 개수가 안 맞아요', o, c); ok = False
        print('✔', name, ': 아이콘 + %s / %s' % (title, sub))
        out[p] = (t, crlf)
    for o, c in ['()', '[]', '{}']:
        if w.count(o) != w.count(c):
            print('❌ logo_shine.dart: 괄호 개수가 안 맞아요', o, c); ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    for p, (t, crlf) in out.items():
        if crlf: t = t.replace('\n', '\r\n')
        open(p, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요 (6개 파일)')
    return 0

if __name__ == '__main__':
    sys.exit(main())
