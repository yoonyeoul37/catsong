# -*- coding: utf-8 -*-
# 재생 화면: ← 화살표 조금 작게 + 아래 사진기에 NEW (한 번 누르면 사라짐)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PATH = 'lib/screens/player_screen.dart'
MARK = '_photoBtnSeen'

EDITS = [
('사진기 눌렀는지 기억하는 칸',
"""  bool _hasSeenParanPhoto = true;
""",
"""  bool _hasSeenParanPhoto = true;
  bool _photoBtnSeen = true; // 아래 사진기를 한 번이라도 눌렀는지 (안 눌렀으면 NEW)
"""),
('저장된 값 읽기',
"""      _hasSeenParanPhoto = prefs.getBool('hasSeenParanPhoto') ?? false;
""",
"""      _hasSeenParanPhoto = prefs.getBool('hasSeenParanPhoto') ?? false;
      _photoBtnSeen = prefs.getBool('photoBtnSeen') ?? false;
"""),
('← 화살표 조금 작게',
"""            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: baseColor, size: 21),""",
"""            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: baseColor, size: 18),"""),
('사진기에 NEW · 누르면 사라짐',
"""                            label: '사진',
                            isActive: false,
                            onTap: _openParanPhotoSheet,""",
"""                            label: '사진',
                            isActive: false,
                            showNew: !_photoBtnSeen,
                            onTap: () {
                              if (!_photoBtnSeen) {
                                setState(() => _photoBtnSeen = true);
                                SharedPreferences.getInstance().then((p) => p.setBool('photoBtnSeen', true));
                              }
                              _openParanPhotoSheet();
                            },"""),
('아래 메뉴 버튼: NEW 받기',
"""        required VoidCallback onTap,
      }) {
    const baseColor = Colors.white;""",
"""        required VoidCallback onTap,
        bool showNew = false, // 아이콘 오른쪽 위 작은 NEW
      }) {
    const baseColor = Colors.white;"""),
('아래 메뉴 버튼: NEW 자리 (위)',
"""      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,""",
"""      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,"""),
('아래 메뉴 버튼: NEW 그리기',
"""                color: isActive ? point : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }""",
"""                color: isActive ? point : Colors.transparent,
              ),
            ),
          ],
        ),
            if (showNew)
              Positioned(
                top: -6,
                left: 11,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: point, borderRadius: BorderRadius.circular(5)),
                  child: const Text('NEW',
                      style: TextStyle(
                          color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 0.3, height: 1.2)),
                ),
              ),
          ],
        ),
      ),
    );
  }"""),
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
