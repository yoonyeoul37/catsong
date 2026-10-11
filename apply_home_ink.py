# -*- coding: utf-8 -*-
# 홈 큰 카드 4개: 밝은 새 사진에 맞게 먹색 글자 (어두운 그림자·칸 없애기, 하트도 밝게)
import sys, glob, os, shutil

NAME = 'home_screen.dart'
hits = [h for h in glob.glob(os.path.join('lib', '**', NAME), recursive=True) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ {NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '// 밝은 사진: 먹색 글자' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('사진: 물건이 잘 보이게 위쪽 기준으로',
"""                          c.imageAsset,
                          fit: BoxFit.cover,
                          cacheWidth: 600,""",
"""                          c.imageAsset,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.4), // 물건·사람이 위쪽에 있어서
                          cacheWidth: 600,"""),
('사진 위 어두운 칸 없애기',
"""                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.22),
                                Colors.black.withOpacity(0.66),
                              ],
                              stops: const [0.35, 0.6, 1.0],
                            ),
                          ),
                        ),
""",
"""                        // 밝은 사진: 먹색 글자 (어두운 칸 없음)
"""),
('제목 먹색',
"""                                        style: GoogleFonts.notoSansKr(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ])),""",
"""                                        style: GoogleFonts.notoSansKr(
                                            color: const Color(0xFF17140F),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3)),"""),
('설명 글자 먹색(흐리게)',
"""                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.88),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ])),""",
"""                                        style: TextStyle(
                                            color: const Color(0xFF17140F).withOpacity(0.6),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500)),"""),
('하트 바탕 밝게',
"""                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.28),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                startScreen == c.type""",
"""                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                startScreen == c.type"""),
('하트 선 먹색',
"""                                color: startScreen == c.type
                                    ? const Color(0xFF6FA8DC)
                                    : Colors.white.withOpacity(0.85),""",
"""                                color: startScreen == c.type
                                    ? const Color(0xFF6FA8DC)
                                    : const Color(0xFF17140F).withOpacity(0.7),"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')
shutil.copy(path, path + '.bak_ink')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_ink)')
