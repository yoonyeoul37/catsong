# -*- coding: utf-8 -*-
# 곡 정보 수정: "찾는 곡을 선택하면" + 검색 결과 넣은 뒤 "되돌리기"
import os, sys

PATH = os.path.join('lib', 'screens', 'edit_song_screen.dart')
if not os.path.exists(PATH):
    for root, _, files in os.walk('lib'):
        if 'edit_song_screen.dart' in files:
            PATH = os.path.join(root, 'edit_song_screen.dart'); break

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '_beforePick' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
('안내 글 바꾸기',
"""                Text('맞는 곡을 고르면 제목·가수·앨범·앨범 사진이 채워져요',""",
"""                Text('찾는 곡을 선택하면 제목·가수·앨범·앨범 사진이 채워져요',"""),

('되돌리기용 값 자리',
"""  String? _pickedArt; // 고른 앨범 사진 주소 (저장할 때 받아서 넣음)
""",
"""  String? _pickedArt; // 고른 앨범 사진 주소 (저장할 때 받아서 넣음)
  // 검색 결과 넣기 전 값 (되돌리기용: 제목·가수·앨범·사진)
  (String, String, String, String?)? _beforePick;

  /// 검색 결과 넣기 전으로 되돌리기
  void _undoPick() {
    final b = _beforePick;
    if (b == null) return;
    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    setState(() {
      _titleController.text = b.$1;
      _artistController.text = b.$2;
      _albumController.text = b.$3;
      _pickedArt = b.$4;
      _beforePick = null;
    });
  }
"""),

('고르기 전 값 기억',
"""    if (picked == null || !mounted) return;
    setState(() {
      // 제목: 지금 한글인데 고른 게 영어면 한글 그대로""",
"""    if (picked == null || !mounted) return;
    setState(() {
      // 되돌리기용: 넣기 전 값 (여러 번 골라도 맨 처음 값으로)
      _beforePick ??= (_titleController.text, _artistController.text, _albumController.text, _pickedArt);
      // 제목: 지금 한글인데 고른 게 영어면 한글 그대로"""),

('검색 결과 안내 + 되돌리기 카드',
"""            section('곡 정보'),
            // 제목 · 아티스트 · 앨범을 흰 카드 하나에""",
"""            // 검색 결과를 넣었으면: 안내 + 되돌리기 (자동 정리 카드와 같은 모양)
            if (_beforePick != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.travel_explore_rounded, color: sub, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('검색 결과를 넣었어요', style: TextStyle(color: ink, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: _undoPick,
                      style: TextButton.styleFrom(foregroundColor: ink),
                      child: const Text('되돌리기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
            section('곡 정보'),
            // 제목 · 아티스트 · 앨범을 흰 카드 하나에"""),
]

ok = True
for name, old, new in edits:
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

if ok:
    for a, b in ('()', '[]', '{}'):
        if src.count(a) != src.count(b):
            ok = False; print('❌ 괄호 개수가 안 맞아요', a, b)

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
