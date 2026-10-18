# -*- coding: utf-8 -*-
# 국내 라디오 위쪽 'Radio' 글자에 홈 로고와 같은 회색 빛 애니메이션 넣기
import os, sys

PATH = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
WIDGET = os.path.join('lib', 'widgets', 'logo_shine.dart')

EDITS = [
    ('빛 위젯 불러오기',
     "import '../widgets/radio_mini_player.dart';\n",
     "import '../widgets/radio_mini_player.dart';\nimport '../widgets/logo_shine.dart';\n"),
    ("'Radio' 글자에 빛 넣기",
     """            const SizedBox(width: 8),
            Text(
              'Radio',
              style: titleFont(
                color: baseColor,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
""",
     """            const SizedBox(width: 8),
            // 홈 로고와 같은 회색 빛이 지나감 (다크 모드는 흰 글자 위로 연한 회색 빛)
            LogoShine(
              base: baseColor,
              glow: isDarkMode ? const Color(0xFFA8A29A) : const Color(0xFF968F85),
              child: Text(
                'Radio',
                style: titleFont(
                  color: baseColor,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
            ),
"""),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요')
        return 1
    if not os.path.exists(WIDGET):
        print('❌ lib/widgets/logo_shine.dart가 없어요 — 먼저 새 파일로 만들어 주세요')
        print('\n아무것도 저장하지 않았어요.')
        return 1
    raw = open(PATH, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('utf-8').replace('\r\n', '\n')
    if 'LogoShine(' in text:
        print('이미 적용돼 있어요')
        return 0
    if 'assets/logo_icon.png' not in text:
        print('❌ 먼저 apply_radio_logo.py를 실행해 주세요')
        print('\n아무것도 저장하지 않았어요.')
        return 1
    ok = True
    for name, old, new in EDITS:
        n = text.count(old)
        if n == 1:
            text = text.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n); ok = False
    for o, c in ['()', '[]', '{}']:
        if text.count(o) != text.count(c):
            print('❌ 괄호 개수가 안 맞아요', o, c); ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        return 1
    if crlf:
        text = text.replace('\n', '\r\n')
    open(PATH, 'wb').write(text.encode('utf-8'))
    print('\n저장했어요:', PATH)
    return 0

if __name__ == '__main__':
    sys.exit(main())
