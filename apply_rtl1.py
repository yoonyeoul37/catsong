# -*- coding: utf-8 -*-
# 아랍어·우르두어 화면 뒤집기 1차: 설정 화면
#  ① 줄 사이 구분선: 아이콘 쪽을 비우는 방향이 반대였음 → 글 쓰는 방향 따라가게
#  ② 포인트 색 동그라미 줄: 왼쪽만 비우던 것 → 아이콘 쪽 비우기
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)
jobs = {
 os.path.join('lib', 'screens', 'settings_screen.dart'): [
  ("설정 줄 구분선", "margin: const EdgeInsets.only(left: 58), color: _sBorder(isDarkMode))",
   "margin: const EdgeInsetsDirectional.only(start: 58), color: _sBorder(isDarkMode))"),
  ("포인트 색 줄", "          Padding(\n            padding: const EdgeInsets.only(left: 42),\n            child: Row(",
   "          Padding(\n            padding: const EdgeInsetsDirectional.only(start: 42),\n            child: Row("),
 ],
 os.path.join('lib', 'widgets', 'paran_dialog.dart'): [
  ("카드 안 줄 구분선", "margin: const EdgeInsets.only(left: 46), color: p.line)",
   "margin: const EdgeInsetsDirectional.only(start: 46), color: p.line)"),
 ],
}
out = {}
for p, eds in jobs.items():
    if not os.path.exists(p): fail('파일을 못 찾았어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n'); o = s
    for name, old, new in eds:
        if old not in s and new in s:
            print('✔', os.path.basename(p), '·', name, '(이미 돼 있어요)'); continue
        if s.count(old) != 1: fail(f'{os.path.basename(p)} · {name} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
        s = s.replace(old, new); print('✔', os.path.basename(p), '·', name)
    for a, b in ['()', '[]', '{}']:
        if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'{p} 괄호 짝이 안 맞아요')
    if s != o: out[p] = s.replace('\n', '\r\n') if crlf else s
if not out: print('이미 적용돼 있어요'); sys.exit(0)
for p, s in out.items(): open(p, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
