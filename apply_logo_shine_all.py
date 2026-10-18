# -*- coding: utf-8 -*-
# 홈 로고 빛: "파란"만 → "파란소리" 전체 (해외는 Paran + sori 둘 다), 라디오 'Radio'와 똑같이
import os, sys

PATH = os.path.join('lib', 'screens', 'home_screen.dart')

EDITS = [
    ('한국어: 파란소리 전체에 빛',
     """                            // "파란"만 숨쉬듯 은은하게
                            _LogoBreathe(
                              base: logoInk,
                              glow: logoShine,
                              child: Text('파란',
                                  textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정
                                  style: GoogleFonts.doHyeon(
                                      color: logoInk,
                                      fontSize: 22,
                                      letterSpacing: -0.5)),
                            ),
                            Text('소리',
                                textScaler: TextScaler.noScaling,
                                style: GoogleFonts.doHyeon(
                                    color: logoInk,
                                    fontSize: 22,
                                    letterSpacing: -0.5)),
""",
     """                            // "파란소리" 전체 위로 회색 빛이 지나감 (라디오 'Radio'와 같게)
                            _LogoBreathe(
                              base: logoInk,
                              glow: logoShine,
                              child: Text('파란소리',
                                  textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정
                                  style: GoogleFonts.doHyeon(
                                      color: logoInk,
                                      fontSize: 22,
                                      letterSpacing: -0.5)),
                            ),
"""),
    ('해외 주석',
     "                    // 해외: Paran / 밑에 sori (가운데 정렬), Paran 위로 회색 빛\n",
     "                    // 해외: Paran / 밑에 sori (가운데 정렬), 둘 다 회색 빛\n"),
    ('해외: sori에도 빛',
     """                        child: Text('sori',
                            style: GoogleFonts.quicksand(
                                color: logoInk,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                letterSpacing: 0.2)),
                      ),
""",
     """                        child: _LogoBreathe(
                          base: logoInk,
                          glow: logoShine,
                          child: Text('sori',
                              style: GoogleFonts.quicksand(
                                  color: logoInk,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  letterSpacing: 0.2)),
                        ),
                      ),
"""),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요')
        return 1
    raw = open(PATH, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('utf-8').replace('\r\n', '\n')
    if "child: Text('파란소리'," in text:
        print('이미 적용돼 있어요')
        return 0
    if 'logoShine' not in text:
        print('❌ 먼저 apply_logo_shine.py를 실행해 주세요')
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
