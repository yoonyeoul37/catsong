# -*- coding: utf-8 -*-
# 설정 ⓘ 말풍선: 화면 아래쪽 줄이면 카드 "위"로 띄우기 (아래 시스템 버튼과 안 겹치게)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
PATH = 'lib/screens/settings_screen.dart'
MARK = 'tailDown'

EDITS = [
('위로 띄울지 정하기',
"""    final top = (cardRect?.bottom ?? iconPos.dy + box.size.height) + 10;
""",
"""    final top = (cardRect?.bottom ?? iconPos.dy + box.size.height) + 10;
    // 줄이 화면 아래쪽에 있으면 말풍선을 카드 위로 (아래 시스템 버튼과 안 겹치게)
    final above = (cardRect?.center.dy ?? iconPos.dy) > ovBox.size.height * 0.5;
    final bottomGap = ovBox.size.height - (cardRect?.top ?? iconPos.dy) + 10;
"""),
('말풍선 자리',
"""          Positioned(
            left: 16,
            top: top,
            width: w,
            child: _InfoBubble(""",
"""          Positioned(
            left: 16,
            top: above ? null : top,
            bottom: above ? bottomGap : null,
            width: w,
            child: _InfoBubble(
              tailDown: above,"""),
('꼬리 방향 받기',
"""  final VoidCallback onClosed;
  const _InfoBubble({
    super.key,""",
"""  final VoidCallback onClosed;
  final bool tailDown; // true면 말풍선이 위에 있고 꼬리가 아래(ⓘ 쪽)를 가리킴
  const _InfoBubble({
    super.key,
    this.tailDown = false,"""),
('나타날 때 방향',
"""        position: Tween<Offset>(begin: const Offset(0, -0.03), end: Offset.zero).animate(curve),""",
"""        position: Tween<Offset>(begin: Offset(0, widget.tailDown ? 0.03 : -0.03), end: Offset.zero).animate(curve),"""),
('꼬리 위치',
"""              Positioned(
                top: -6,
                left: (widget.tailX - 6.5).clamp(14.0, double.infinity).toDouble(),""",
"""              Positioned(
                top: widget.tailDown ? null : -6,
                bottom: widget.tailDown ? -6 : null,
                left: (widget.tailX - 6.5).clamp(14.0, double.infinity).toDouble(),"""),
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
