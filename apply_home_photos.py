# -*- coding: utf-8 -*-
# 홈 큰 카드 4개: 글자 깔끔하게 (끊기는 줄·진한 그림자 없애고, 사진 아래만 부드럽게 어둡게)
import sys, glob, os, shutil

NAME = 'home_screen.dart'
hits = [h for h in glob.glob(os.path.join('lib', '**', NAME), recursive=True) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ {NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'stops: const [0.35, 0.6, 1.0]' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)
edits = [
('사진 아래만 부드럽게 어둡게',
"""                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.18),
                              ],
                              stops: const [0.5, 1.0],""",
"""                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.22),
                                Colors.black.withOpacity(0.66),
                              ],
                              stops: const [0.35, 0.6, 1.0],"""),
('끊기는 줄(글자 칸 테두리) 없애기',
"""                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.08),
                                  border: Border(
                                    top: BorderSide(color: Colors.white.withOpacity(0.18)),
                                  ),
                                ),
""",
"""                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
"""),
('제목 그림자 옅게',
"""                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            shadows: [
                                              const Shadow(
                                                color: Colors.black,
                                                blurRadius: 3,
                                                offset: Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.9),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.75),
                                                blurRadius: 20,
                                                offset: const Offset(0, 3),
                                              ),
                                            ])),""",
"""                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ])),"""),
('설명 글자 그림자 옅게',
"""                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            shadows: [
                                              const Shadow(
                                                color: Colors.black,
                                                blurRadius: 2,
                                                offset: Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.85),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                              Shadow(
                                                color: Colors.black.withOpacity(0.65),
                                                blurRadius: 14,
                                                offset: const Offset(0, 2),
                                              ),
                                            ])),""",
"""                                            color: Colors.white.withOpacity(0.88),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ])),"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')
shutil.copy(path, path + '.bak_photos')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_photos)')
