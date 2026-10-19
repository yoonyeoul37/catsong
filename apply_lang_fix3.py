# -*- coding: utf-8 -*-
# 새 언어 폰 확인 3차 고침
#  ① 자연소리 섞기 창: 소리 이름 + 종류 고르기 칸이 길면 넘침(루마니아어) → 이름·칸 둘 다 끝을 … 로
#  ② 벨소리 만들기 · 영상 자르기: '시작/끝' 글자가 좁은 칸에서 글자 중간에 줄이 바뀜 → 칸 넓히고 한 줄로
import os, sys
sys.stdout.reconfigure(encoding='utf-8')

def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)

RANGE_OLD = "            SizedBox(width: 40, child: Text(label, style: TextStyle(color: sub, fontSize: 13))),\n"
RANGE_NEW = ("            SizedBox( // 시작/끝: 긴 언어도 한 줄로 (칸에 맞게 살짝 줄임)\n"
             "                width: 56,\n"
             "                child: FittedBox(\n"
             "                    fit: BoxFit.scaleDown,\n"
             "                    alignment: Alignment.centerLeft,\n"
             "                    child: Text(label, maxLines: 1, style: TextStyle(color: sub, fontSize: 13)))),\n")
jobs = {
 os.path.join('lib', 'services', 'nature_overlay.dart'): [
  ("소리 이름 넘침",
   """                                  Row(
                                    children: [
                                      Text(natureName(k),
                                          style: TextStyle(
                                              color: const Color(0xFF17140F)
                                                  .withOpacity(o.volumeOf(k) > 0 ? 1 : 0.6),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      const Spacer(),
""",
   """                                  Row(
                                    children: [
                                      // 이름이 길면 끝을 … 로 (종류 고르기 칸은 오른쪽에 그대로)
                                      Expanded(
                                        child: Text(natureName(k),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: const Color(0xFF17140F)
                                                    .withOpacity(o.volumeOf(k) > 0 ? 1 : 0.6),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 8),
"""),
  ("종류 고르기 칸 넓이 제한",
   """                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            margin: const EdgeInsets.only(right: 8),
""",
   """                                          child: Container(
                                            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(ctx).width * 0.4),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            margin: const EdgeInsets.only(right: 8),
"""),
  ("종류 고르기 글자 …",
   """                                                Text(natureName(o.variantOf(k)),
                                                    style: const TextStyle(
                                                        color: Color(0xFF5A5348), fontSize: 12)),
                                                const Icon(Icons.expand_more, size: 16, color: Color(0xFF8A857B)),""",
   """                                                Flexible(
                                                  child: Text(natureName(o.variantOf(k)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          color: Color(0xFF5A5348), fontSize: 12)),
                                                ),
                                                const Icon(Icons.expand_more, size: 16, color: Color(0xFF8A857B)),"""),
 ],
 os.path.join('lib', 'screens', 'ringtone_screen.dart'): [("시작/끝 글자 줄바꿈", RANGE_OLD, RANGE_NEW)],
 os.path.join('lib', 'screens', 'video_trim_screen.dart'): [("시작/끝 글자 줄바꿈", RANGE_OLD, RANGE_NEW)],
}
out = {}
for p, edits in jobs.items():
    if not os.path.exists(p): fail('파일을 못 찾았어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n'); o = s
    if '// 이름이 길면 끝을 … 로 (종류 고르기' in s or '// 시작/끝: 긴 언어도 한 줄로' in s:
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
