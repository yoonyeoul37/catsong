# -*- coding: utf-8 -*-
# 새 언어 폰 확인 2차 고침
#  ① 통화 녹음 화면 위 '녹음 (17)' 줄 넘침(루마니아어) → 제목이 길면 끝을 … 로
#  ② 재생 화면 ⋯ 메뉴: 줄 이름과 오른쪽 값(끔·1.0× 등)이 붙어 보임(헝가리어) → 사이 간격
import os, sys
sys.stdout.reconfigure(encoding='utf-8')

def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)

jobs = {
 os.path.join('lib', 'screens', 'call_recordings_screen.dart'): [
  ("녹음 제목 줄 넘침",
   """                    Text(tr.recordings,
                        style: TextStyle(
                            color: baseColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(width: 8),
                    Text('(${everything.length})',
                        style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 13)),
                    const Spacer(),
""",
   """                    // 제목이 긴 언어(루마니아어 등)는 끝을 … 로 (오른쪽 정렬·검색 버튼 자리 지키기)
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(tr.recordings,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: baseColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          ),
                          const SizedBox(width: 8),
                          Text('(${everything.length})',
                              style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 13)),
                        ],
                      ),
                    ),
"""),
 ],
 os.path.join('lib', 'screens', 'player_screen.dart'): [
  ("메뉴 줄 이름과 값 사이 간격",
   """            // 오른쪽: 지금 상태 표시 (보여주기만, 누르면 줄 전체 동작 그대로)
            if (trailing != null) trailingTappable ? trailing : IgnorePointer(child: trailing),""",
   """            // 오른쪽: 지금 상태 표시 (보여주기만, 누르면 줄 전체 동작 그대로)
            if (trailing != null) const SizedBox(width: 10), // 줄 이름이 길어도 값과 붙지 않게
            if (trailing != null) trailingTappable ? trailing : IgnorePointer(child: trailing),"""),
 ],
}
out = {}
for p, edits in jobs.items():
    if not os.path.exists(p): fail('파일을 못 찾았어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n'); o = s
    if '// 줄 이름이 길어도 값과 붙지 않게' in s or '// 제목이 긴 언어(루마니아어 등)는' in s:
        print('이미 적용돼 있어요'); sys.exit(0)
    for name, old, new in edits:
        n = s.count(old)
        if n != 1: fail(f'{os.path.basename(p)} · {name} — 찾을 코드를 못 찾았어요 ({n}곳)')
        s = s.replace(old, new); print('✔', os.path.basename(p), '·', name)
    for a, b in ['()', '[]', '{}']:
        if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'{p} 괄호 {a}{b} 짝이 안 맞아요')
    out[p] = s.replace('\n', '\r\n') if crlf else s
for p, s in out.items():
    open(p, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
