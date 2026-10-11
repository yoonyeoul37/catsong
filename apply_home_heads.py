# -*- coding: utf-8 -*-
# 홈 칸 제목 3개(이런 소리는 어때요? · 잠시 쉬어가요 · 최근에 들었어요)를 로고와 같은 도현 글꼴로
import sys, glob, os, shutil

NAME = 'home_screen.dart'
hits = [h for h in glob.glob(os.path.join('lib', '**', NAME), recursive=True) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ {NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if "Text('잠시 쉬어가요',\n                  style: GoogleFonts.doHyeon(" in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = []
for title, ind in (('이런 소리는 어때요?', 14), ('잠시 쉬어가요', 14), ('최근에 들었어요', 16)):
    a = ' ' * ind
    old = (f"{a}Text('{title}',\n"
           f"{a}    style: GoogleFonts.notoSansKr(\n"
           f"{a}        color: baseColor, fontSize: 14, fontWeight: FontWeight.w700)),")
    new = (f"{a}Text('{title}',\n"
           f"{a}    style: GoogleFonts.doHyeon( // 로고와 같은 글꼴\n"
           f"{a}        color: baseColor, fontSize: 17, fontWeight: FontWeight.w400)),")
    edits.append((title, old, new))

for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')
shutil.copy(path, path + '.bak_heads')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_heads)')
