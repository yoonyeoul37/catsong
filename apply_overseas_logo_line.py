# -*- coding: utf-8 -*-
# 해외 홈 로고: 두 줄(Paran / sori) → 한 줄 'Paransori'(Paran 진하게 · sori 연하게)
#              + 아래 작은 대문자 'MUSIC · RADIO · NATURE' (한국 로고 '파란소리 / PARANSORI'와 같은 모양·크기)
import os, sys

PATH = os.path.join('lib', 'screens', 'home_screen.dart')

EDITS = [
    ('아이콘 높이: 한국·해외 똑같이',
     """              padding: EdgeInsets.only(top: isKorean ? 4 : 0),
""",
     """              padding: const EdgeInsets.only(top: 4),
"""),
    ('주석',
     "    // 로고: 왼쪽 앱 아이콘(색 고정) + 글씨는 먹색(다크는 크림색), \"파란\" 위로 회색 빛이 지나감 (포인트 색과 상관없이)\n",
     "    // 로고: 왼쪽 앱 아이콘(색 고정) + 글씨는 먹색(다크는 크림색), 글자 위로 회색 빛이 지나감 (포인트 색과 상관없이)\n"),
    ('해외 로고: 한 줄 Paransori + MUSIC · RADIO · NATURE',
     """                : Column(
                    // 해외: Paran / 밑에 sori (가운데 정렬), 둘 다 회색 빛
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        _LogoBreathe(
                          base: logoInk,
                          glow: logoShine,
                          child: Text('Paran',
                              style: GoogleFonts.quicksand(
                                  color: logoInk,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  letterSpacing: 0.2)),
                        ),
                      Transform.translate(
                        offset: const Offset(0, -3), // Paran과 sori 사이를 살짝 좁게
                        child: _LogoBreathe(
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
                    ],
                  ),
""",
     """                // 해외: 위 'Paransori'(Paran 진하게 · sori 연하게), 아래 MUSIC · RADIO · NATURE를 같은 폭으로 맞춤
                : Padding(
                    padding: const EdgeInsets.only(top: 4), // 한국 로고와 같은 높이
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 'Paransori' 전체 위로 회색 빛 (한국 '파란소리'와 같게)
                          _LogoBreathe(
                            base: logoInk,
                            glow: logoShine,
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: 'Paran', style: GoogleFonts.quicksand(
                                    color: logoInk, fontWeight: FontWeight.w700)),
                                TextSpan(text: 'sori', style: GoogleFonts.quicksand(
                                    color: logoInk.withOpacity(0.55), fontWeight: FontWeight.w500)),
                              ]),
                              textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정
                              style: const TextStyle(fontSize: 21, height: 1.15, letterSpacing: -0.3),
                            ),
                          ),
                          // MUSIC · RADIO · NATURE: 'Paransori' 폭에 딱 맞게 (작은 대문자)
                          Transform.translate(
                            offset: const Offset(0, -1),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 1, right: 1),
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text('MUSIC · RADIO · NATURE',
                                    textScaler: TextScaler.noScaling,
                                    style: GoogleFonts.quicksand(
                                        color: logoInk.withOpacity(0.7),
                                        fontSize: 8,
                                        height: 1.0,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),
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
    if 'MUSIC · RADIO · NATURE' in text:
        print('이미 적용돼 있어요')
        return 0
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
