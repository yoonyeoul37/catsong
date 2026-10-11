# -*- coding: utf-8 -*-
# 곡 목록 오른쪽 초성: 살짝 움직일 땐 안 나오고, 3줄쯤 밀었을 때부터 나오게
import sys, glob, os, shutil

hits = glob.glob(os.path.join('lib', '**', 'home_screen.dart'), recursive=True)
if not hits:
    print('❌ home_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_scrollPokeIndexBar' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('밀기 시작한 곳 기억',
"  int _indexHideToken = 0;\n",
"""  int _indexHideToken = 0;
  double? _indexFrom; // 초성이 숨어 있을 때 밀기 시작한 위치
  DateTime _indexMovedAt = DateTime(0);
"""),
('스크롤할 때',
"""          _songListController.position.userScrollDirection != ScrollDirection.idle) {
        _pokeIndexBar();
      }""",
"""          _songListController.position.userScrollDirection != ScrollDirection.idle) {
        _scrollPokeIndexBar();
      }"""),
('3줄쯤 밀면 나오기',
"  /// 초성 막대: 스크롤하는 동안 보이고",
"""  /// 손으로 밀 때: 이미 보이면 계속 보이게, 숨어 있으면 3줄쯤(250) 밀었을 때부터 나타나게
  void _scrollPokeIndexBar() {
    final px = _songListController.position.pixels;
    final now = DateTime.now();
    if (_indexShow.value) {
      _indexFrom = null;
      _indexMovedAt = now;
      _pokeIndexBar();
      return;
    }
    // 잠깐 멈췄다가 다시 밀면 처음부터 다시 셈
    if (_indexFrom == null || now.difference(_indexMovedAt).inMilliseconds > 800) _indexFrom = px;
    _indexMovedAt = now;
    if ((px - _indexFrom!).abs() >= 250) {
      _indexFrom = null;
      _pokeIndexBar();
    }
  }

  /// 초성 막대: 스크롤하는 동안 보이고"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

shutil.copy(path, path + '.bak')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak)')
