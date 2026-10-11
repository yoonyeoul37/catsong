# -*- coding: utf-8 -*-
# 홈 '최근에 들었어요': 사진 없는 칸을 위 큰 카드와 같은 파스텔 색 + 먹색 아이콘으로
import sys, glob, os, shutil

NAME = 'home_screen.dart'
hits = [h for h in glob.glob(os.path.join('lib', '**', NAME), recursive=True) if os.path.basename(h) == NAME]
if not hits:
    print(f'❌ {NAME} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_recentTile(' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

def tile(bg, icon):
    # 라이트: 파스텔 바탕 + 먹색 아이콘 / 다크: 어두운 갈색 바탕 + 크림색 아이콘
    return (f"_recentTile(isDarkMode, const Color({bg}), Icons.{icon})")

edits = [
('음악 (살구색)',
"""                            : Container(
                          width: 72,
                          height: 72,
                          color: primaryColor.withOpacity(0.7),
                          child: const Icon(Icons.music_note_rounded,
                              color: Colors.white, size: 26),
                        );""",
"                            : " + tile('0xFFF3D9C9', 'music_note_rounded') + ";"),
('라디오 (하늘색)',
"""                        thumbnail = Container(
                          width: 72,
                          height: 72,
                          color: typeColor.withOpacity(0.7),
                          child: const Icon(Icons.radio_rounded, color: Colors.white, size: 26),
                        );""",
"                        thumbnail = " + tile('0xFFD5E1EC', 'radio_rounded') + ";"),
('자연소리 (연두색)',
"""                        thumbnail = Container(
                          width: 72,
                          height: 72,
                          color: typeColor.withOpacity(0.7),
                          child: const Icon(Icons.waves_rounded, color: Colors.white, size: 26),
                        );""",
"                        thumbnail = " + tile('0xFFDCE5D2', 'waves_rounded') + ";"),
('수면 (연보라)',
"""                        thumbnail = Container(
                          width: 72,
                          height: 72,
                          color: typeColor.withOpacity(0.7),
                          child: const Icon(Icons.bedtime_rounded, color: Colors.white, size: 26),
                        );""",
"                        thumbnail = " + tile('0xFFDDD6E8', 'bedtime_rounded') + ";"),
('칸 그리는 함수 추가 (파일 맨 끝)',
None, None),
]

for label, old, new in edits[:-1]:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

s = s.rstrip('\n') + """

/// 최근에 들었어요: 사진 없는 칸 (위 큰 카드와 같은 파스텔 색)
Widget _recentTile(bool isDarkMode, Color pastel, IconData icon) {
  return Container(
    width: 72,
    height: 72,
    color: isDarkMode ? const Color(0xFF3A3631) : pastel,
    child: Icon(
      icon,
      size: 26,
      color: isDarkMode
          ? const Color(0xFFF3EFE7).withOpacity(0.75)
          : const Color(0xFF17140F).withOpacity(0.55),
    ),
  );
}
"""
print('✔ 칸 그리는 함수 추가')
shutil.copy(path, path + '.bak_recent')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_recent)')
