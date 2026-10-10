# -*- coding: utf-8 -*-
# 재생 화면: 위 줄 ← · 로고 · ⋯ 만 / 사진기는 아래 메뉴로 (파란포토일 때)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PATH = 'lib/screens/player_screen.dart'
MARK = "label: '사진',"

EDITS = [
('⌄ → ← 화살표',
"""            icon: Icon(Icons.keyboard_arrow_down,
                color: baseColor, size: 30),""",
"""            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: baseColor, size: 21),"""),
('위 줄 사진기 빼기',
"""          // 파란포토 사진 고르기 (파란포토 스타일일 때만, 열려 있으면 하늘색)
          if (_albumArtStyle == 6)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openParanPhotoSheet,
              child: SizedBox(
                width: 36,
                height: 40,
                child: Icon(
                  CupertinoIcons.camera,
                  color: baseColor,
                  size: 19,
                ),
              ),
            ),
""", ''),
('로고 정가운데 (왼쪽)',
"""          // 왼쪽 ⌄(48)와 오른쪽(사진기 36 + ⋯ 36)의 폭을 같게 → 로고가 화면 정가운데
          SizedBox(width: _albumArtStyle == 6 ? 24 : 0),""",
"""          // 왼쪽 ←(48)와 오른쪽 ⋯(36 + 여백 12)의 폭이 같아서 로고가 화면 정가운데"""),
('로고 정가운데 (오른쪽)',
"""          if (_albumArtStyle != 6) const SizedBox(width: 12),""",
"""          const SizedBox(width: 12),"""),
('아래 메뉴에 사진 (파란포토일 때)',
"""                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LyricsScreen()));
                          },
                        ),
                        ],""",
"""                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LyricsScreen()));
                          },
                        ),
                        // 파란포토 사진 고르기 (파란포토 스타일일 때만)
                        if (_albumArtStyle == 6)
                          _buildBottomBarItem(
                            context,
                            icon: CupertinoIcons.camera,
                            label: '사진',
                            isActive: false,
                            onTap: _openParanPhotoSheet,
                          ),
                        ],"""),
]

def main():
    try:
        raw = open(PATH, 'rb').read().decode('utf-8')
    except FileNotFoundError:
        print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
        s = s.replace(old, new); print(f'✔ {name}')
    for o, c in ('{}', '()', '[]'):
        if (s.count(o) - s.count(c)) != (raw.count(o) - raw.count(c)):
            print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('저장했어요 ✔')

main()
