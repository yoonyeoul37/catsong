# -*- coding: utf-8 -*-
# 곡 목록 초성 막대: 힌디어 글자 제목도 칸으로 (지금은 전부 # 으로 감)
#  모음 अ + 자음 7묶음 (क च ट त प य श) + A-Z + #   — 태국어처럼
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'utils', 'index_letter.dart')
def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)
if not os.path.exists(P): fail('파일을 못 찾았어요: ' + P)
raw = open(P, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n'); o = s
if '_kIndexGroupsHi' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ("힌디어 막대 칸",
  "const _kIndexGroupsRu = [..._kCyrRows, 'A-Z', '#'];\n",
  "const _kIndexGroupsRu = [..._kCyrRows, 'A-Z', '#'];\n"
  "// 힌디어: 모음(अ) + 자음을 소리 나는 자리별 7묶음 (क च ट त प य श) + A-Z + #\n"
  "const _kHindiRows = ['अ', 'क', 'च', 'ट', 'त', 'प', 'य', 'श'];\n"
  "const _kIndexGroupsHi = [..._kHindiRows, 'A-Z', '#'];\n"
  "\n"
  "/// 힌디어(데바나가리) 첫 글자 → 막대 칸, 아니면 null\n"
  "String? _hindiRow(int c) {\n"
  "  if ((c >= 0x0904 && c <= 0x0914) || c == 0x0960 || c == 0x0961 || (c >= 0x0972 && c <= 0x0977)) {\n"
  "    return 'अ'; // 모음 글자 (अ आ इ ई उ ऊ ए ऐ ओ औ …)\n"
  "  }\n"
  "  if (c >= 0x0958 && c <= 0x095F) { // 점 붙은 자음 (क़ ख़ ग़ ज़ ड़ ढ़ फ़ य़)\n"
  "    return const ['क', 'क', 'क', 'च', 'ट', 'ट', 'प', 'य'][c - 0x0958];\n"
  "  }\n"
  "  if (c < 0x0915 || c > 0x0939) return null;\n"
  "  if (c <= 0x0919) return 'क'; // क ख ग घ ङ\n"
  "  if (c <= 0x091E) return 'च'; // च छ ज झ ञ\n"
  "  if (c <= 0x0923) return 'ट'; // ट ठ ड ढ ण\n"
  "  if (c <= 0x0929) return 'त'; // त थ द ध न\n"
  "  if (c <= 0x092E) return 'प'; // प फ ब भ म\n"
  "  if (c <= 0x0935) return 'य'; // य र ल व\n"
  "  return 'श'; // श ष स ह\n"
  "}\n"),
 ("힌디어 막대 고르기",
  "  if (lang == 'ru' || lang == 'uk') return _kIndexGroupsRu;\n",
  "  if (lang == 'ru' || lang == 'uk') return _kIndexGroupsRu;\n"
  "  if (lang == 'hi') return _kIndexGroupsHi;\n"),
 ("힌디어 제목 → 칸",
  "  if (lang == 'ru' || lang == 'uk') {\n"
  "    final row = _cyrRow(c);\n",
  "  if (lang == 'hi') {\n"
  "    final row = _hindiRow(c);\n"
  "    if (row != null) return row;\n"
  "    return latinLetterOf(c) != null ? 'A-Z' : '#';\n"
  "  }\n"
  "  if (lang == 'ru' || lang == 'uk') {\n"
  "    final row = _cyrRow(c);\n"),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1: fail(f'{name} — 찾을 코드를 못 찾았어요 ({n}곳)')
    s = s.replace(old, new); print('✔ index_letter.dart ·', name)
for a, b in ['()', '[]', '{}']:
    if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'괄호 {a}{b} 짝이 안 맞아요')
open(P, 'wb').write((s.replace('\n', '\r\n') if crlf else s).encode('utf-8'))
print('저장했어요.')
