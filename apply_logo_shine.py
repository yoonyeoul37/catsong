# -*- coding: utf-8 -*-
# 홈 로고 "파란"(해외 "Paran") 애니메이션: 색 빛 → 회색(다크는 흰) 빛이 지나가게. 글자는 항상 먹색/크림색
import os, sys

PATH = os.path.join('lib', 'screens', 'home_screen.dart')

EDITS = [
    ('포인트 색 변수 → 빛 색',
     """    final pointColor = context.watch<ThemeProvider>().primaryColor;
    final isBluePoint = pointColor.value == 0xFF2589E8;
""",
     ""),
    ('로고 주석',
     "    // 로고: 왼쪽 앱 아이콘(색 고정) + 기본 색(파란소리)일 땐 \"파란\"만 파랑, 다른 포인트 색이면 글씨는 먹색\n",
     "    // 로고: 왼쪽 앱 아이콘(색 고정) + 글씨는 먹색(다크는 크림색), \"파란\" 위로 회색 빛이 지나감 (포인트 색과 상관없이)\n"),
    ('빛 색 넣기',
     """    final logoInk = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
""",
     """    final logoInk = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final logoShine = isDarkMode ? Colors.white : const Color(0xFF968F85);
"""),
    ('한국어 "파란"',
     """                            if (isBluePoint)
                              _LogoBreathe(
                                child: Text('파란',
                                    textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정
                                    style: GoogleFonts.doHyeon(
                                        color: const Color(0xFF2F7DE8),
                                        fontSize: 22,
                                        letterSpacing: -0.5)),
                              )
                            else
                              _LogoBreathe(
                                base: logoInk,
                                glow: pointColor,
                                child: Text('파란',
                                    textScaler: TextScaler.noScaling,
                                    style: GoogleFonts.doHyeon(
                                        color: logoInk,
                                        fontSize: 22,
                                        letterSpacing: -0.5)),
                              ),
""",
     """                            _LogoBreathe(
                              base: logoInk,
                              glow: logoShine,
                              child: Text('파란',
                                  textScaler: TextScaler.noScaling, // 로고는 텍스트 크기 설정과 상관없이 고정
                                  style: GoogleFonts.doHyeon(
                                      color: logoInk,
                                      fontSize: 22,
                                      letterSpacing: -0.5)),
                            ),
"""),
    ('해외 "Paran"',
     """                      if (isBluePoint)
                        _LogoBreathe(
                          child: Text('Paran',
                              style: GoogleFonts.quicksand(
                                  color: const Color(0xFF2F7DE8),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  letterSpacing: 0.2)),
                        )
                      else
                        _LogoBreathe(
                          base: logoInk,
                          glow: pointColor,
                          child: Text('Paran',
""",
     """                        _LogoBreathe(
                          base: logoInk,
                          glow: logoShine,
                          child: Text('Paran',
"""),
    ('해외 주석',
     "                    // 해외: Paran(파란색) / 밑에 Sori (가운데 정렬)\n",
     "                    // 해외: Paran / 밑에 sori (가운데 정렬), Paran 위로 회색 빛\n"),
    ('빛 위젯: 색 꼭 받기',
     """  final Color? base; // 글자 색 (없으면 기본 파랑)
  final Color? glow; // 지나가는 빛 색 (없으면 기본 하늘색)
  const _LogoBreathe({required this.child, this.base, this.glow});
""",
     """  final Color base; // 글자 색
  final Color glow; // 지나가는 빛 색 (색 없이 회색/흰색)
  const _LogoBreathe({required this.child, required this.base, required this.glow});
"""),
    ('빛 위젯: 예전 파랑 기본값 지우기',
     """        // 기본: 파랑 글자 + 하늘색 빛 / 포인트 색 바꾸면: 먹색 글자 + 포인트 색 빛
        final base = widget.base ?? const Color(0xFF2F7DE8);
        final glow = widget.glow ?? const Color(0xFFA9D3FF);
        final mid = widget.glow == null
            ? const Color(0xFF5FA6F2)
            : Color.lerp(base, glow, 0.55)!;
""",
     """        final base = widget.base;
        final glow = widget.glow;
        final mid = Color.lerp(base, glow, 0.55)!;
"""),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요')
        return 1
    raw = open(PATH, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('utf-8').replace('\r\n', '\n')
    if 'logoShine' in text:
        print('이미 적용돼 있어요')
        return 0
    ok = True
    for name, old, new in EDITS:
        n = text.count(old)
        if n == 1:
            text = text.replace(old, new)
            print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n)
            ok = False
    if 'isBluePoint' in text:
        print('❌ isBluePoint가 아직 남아 있어요')
        ok = False
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
