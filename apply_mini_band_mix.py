# -*- coding: utf-8 -*-
# 소리 믹스 미니 플레이어: 라디오와 같은 진한 띠로
import sys, glob, os, shutil

hits = glob.glob(os.path.join('lib', '**', 'sound_mix_mini_player.dart'), recursive=True)
if not hits:
    print('❌ sound_mix_mini_player.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '진한 띠' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('띠 위 글자색',
"    final baseColor = isDarkMode ? Colors.white : Colors.black;\n",
"""    // 진한 띠 위라서 글자·아이콘은 늘 밝은 색 (라디오 미니 플레이어와 같음)
    const baseColor = Color(0xFFF4EFE5);
    const ink = Color(0xFF17140F);
"""),
('네모난 띠',
"""          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),""",
"""          topLeft: Radius.zero,
          topRight: Radius.zero,"""),
('진한 띠 색 · 높이 맞추기',
"""            height: 72,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEDE7DA).withOpacity(0.92),
              border: Border(top: BorderSide(color: baseColor.withOpacity(0.10))),
            ),""",
"""            height: 80,
            decoration: BoxDecoration(
              // 진한 띠 (어두운 화면에서는 바탕보다 한 톤 밝게)
              color: isDarkMode ? const Color(0xFF3A3631) : ink,
            ),"""),
('아래 글자: 띠 위에서 잘 보이게',
"                            style: const TextStyle(color: accent, fontSize: 12)),",
"                            style: TextStyle(color: baseColor.withOpacity(0.6), fontSize: 12)),"),
('재생 버튼: 밝은 동그라미 + 진한 아이콘',
"""                      decoration: BoxDecoration(color: baseColor.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(mix.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: baseColor.withOpacity(0.7), size: 20),""",
"""                      decoration: const BoxDecoration(color: baseColor, shape: BoxShape.circle),
                      child: Icon(mix.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: ink, size: 22),"""),
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
