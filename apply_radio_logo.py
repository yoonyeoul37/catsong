# -*- coding: utf-8 -*-
# 국내 라디오 첫 화면 위쪽: 'Radio' + 소리 막대 → 앱 아이콘 + 'Radio' (막대 없음)
import os, sys

PATH = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')

EDITS = [
    ('제목 왼쪽에 앱 아이콘, 소리 막대 빼기',
     """          children: [
            Text(
              'Radio',
              style: titleFont(
                color: baseColor,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            // 라디오를 틀면(미니플레이어가 뜨면) 막대는 미니플레이어 하나만 → 여기선 숨기기
            if (radioProvider.currentStation == null) ...[
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: _LogoEqBars(),
              ),
            ],
          ],
""",
     """          children: [
            // 앱 아이콘 (홈 로고와 같은 모양, 포인트 색과 상관없이 고정)
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset('assets/logo_icon.png',
                  width: 26, height: 26, filterQuality: FilterQuality.medium),
            ),
            const SizedBox(width: 8),
            Text(
              'Radio',
              style: titleFont(
                color: baseColor,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
          ],
"""),
    ('안 쓰는 dart:math 지우기',
     "import 'dart:math' as math;\n",
     ""),
]

EQ_START = "// 상단바에 쓰는 작은 이퀄라이저 막대 (은은하게 움직임)\n"
EQ_END = "// ══════════════════════════════════════════\n// 주파수 맞추기"

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
            text = text.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n); ok = False
    s = text.find(EQ_START); e = text.find(EQ_END)
    if s != -1 and e != -1 and s < e:
        text = text[:s] + text[e:]; print('✔ 소리 막대 위젯(_LogoEqBars) 지우기')
    else:
        print('❌ 소리 막대 위젯(_LogoEqBars) 지우기'); ok = False
    if '_LogoEqBars' in text or 'math.' in text:
        print('❌ 막대 코드나 math가 아직 쓰이고 있어요'); ok = False
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
