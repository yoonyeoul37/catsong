# -*- coding: utf-8 -*-
# 홈 로고: 왼쪽에 앱 아이콘 + 파란소리 / 아래 PARANSORI(대문자, 한글 폭에 맞춤), 소리 막대 없애기
import os, sys

PATH = os.path.join('lib', 'screens', 'home_screen.dart')

EDITS = [
    ('막대 색 변수 지우기',
     """    final logoBarColor = isBluePoint ? const Color(0xFF2F7DE8) : pointColor;
""",
     ""),
    ('주석 고치기',
     "    // 로고: 기본 색(파란소리)일 땐 \"파란\"만 파랑, 다른 포인트 색이면 글씨는 전부 먹색 + 막대만 포인트 색\n",
     "    // 로고: 왼쪽 앱 아이콘(색 고정) + 기본 색(파란소리)일 땐 \"파란\"만 파랑, 다른 포인트 색이면 글씨는 먹색\n"),
    ('로고 줄 가운데 정렬 + 왼쪽 앱 아이콘',
     """        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isKorean
""",
     """        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 앱 아이콘 (포인트 색과 상관없이 고정)
            Padding(
              padding: EdgeInsets.only(top: isKorean ? 4 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset('assets/logo_icon.png',
                    width: 36, height: 36, filterQuality: FilterQuality.medium),
              ),
            ),
            const SizedBox(width: 10),
            isKorean
"""),
    ('한국어 주석',
     "                // 한국어: 위 '파란소리 + 소리 막대', 아래 Paransori를 같은 폭으로 늘려 맞춤\n",
     "                // 한국어: 위 '파란소리', 아래 PARANSORI(작은 대문자)를 같은 폭으로 맞춤\n"),
    ('한국어 소리 막대 지우기',
     """                                    letterSpacing: -0.5)),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: _LogoEqBars(color: logoBarColor),
                            ),
                          ],
""",
     """                                    letterSpacing: -0.5)),
                          ],
"""),
    ('아래 영어를 PARANSORI 대문자로',
     """                        // Paransori: 글자를 고르게 벌려서 '파' 왼쪽 끝 ~ 막대 오른쪽 끝까지
                        Transform.translate(
                          offset: const Offset(0, -6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final ch in 'Paransori'.split(''))
                                  Text(ch,
                                      textScaler: TextScaler.noScaling,
                                      style: GoogleFonts.quicksand(
                                          color: logoInk.withOpacity(0.75),
                                          fontSize: 12,
                                          height: 1.0,
                                          fontWeight: FontWeight.w600)),
""",
     """                        // PARANSORI: 작은 대문자를 고르게 벌려서 '파' 왼쪽 끝 ~ '리' 오른쪽 끝까지
                        Transform.translate(
                          offset: const Offset(0, -4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final ch in 'PARANSORI'.split(''))
                                  Text(ch,
                                      textScaler: TextScaler.noScaling,
                                      style: GoogleFonts.quicksand(
                                          color: logoInk.withOpacity(0.7),
                                          fontSize: 9.5,
                                          height: 1.0,
                                          fontWeight: FontWeight.w700)),
"""),
    ('해외 소리 막대 지우기',
     """            if (!isKorean) ...[
              const SizedBox(width: 6),
              Padding(
                // 해외는 아래 Sori 옆에 붙게 (파란 Paran과 안 겹치게)
                padding: const EdgeInsets.only(top: 20, bottom: 7),
                child: _LogoEqBars(color: logoBarColor),
              ),
            ],
""",
     ""),
]

# 안 쓰게 된 소리 막대 위젯 통째로 지우기
EQ_START = "class _LogoEqBars extends StatefulWidget {"
EQ_END = "/// 오늘의 카드 TIP 그림: 점선 네모"

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요')
        return 1
    raw = open(PATH, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('utf-8').replace('\r\n', '\n')
    if "assets/logo_icon.png" in text:
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
    s = text.find(EQ_START); e = text.find(EQ_END)
    if s != -1 and e != -1 and s < e:
        text = text[:s] + text[e:]
        print('✔ 소리 막대 위젯(_LogoEqBars) 지우기')
    else:
        print('❌ 소리 막대 위젯(_LogoEqBars) 지우기')
        ok = False
    if '_LogoEqBars' in text or 'logoBarColor' in text:
        print('❌ 아직 막대 코드가 남아 있어요')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        return 1
    if crlf:
        text = text.replace('\n', '\r\n')
    open(PATH, 'wb').write(text.encode('utf-8'))
    print('\n저장했어요:', PATH)
    if not os.path.exists(os.path.join('assets', 'logo_icon.png')):
        print('⚠ assets 폴더에 logo_icon.png를 넣어 주세요')
    return 0

if __name__ == '__main__':
    sys.exit(main())
