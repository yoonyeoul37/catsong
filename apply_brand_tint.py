# -*- coding: utf-8 -*-
# 라디오 전체 목록 왼쪽 방송사 칸 색을 방송사별 박스 색과 맞추기 (박스 색을 바탕에 16%만 섞기)
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_brandTint' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ('목록 칸 색',
  """                  color: _brandPastel(station.broadcaster).withOpacity(isDarkMode ? 0.9 : 1),""",
  """                  color: _brandPastel(station.broadcaster, isDarkMode), // 방송사별 박스와 같은 색 계열"""),
 ('목록 칸 글자 색 (다크 모드는 밝게)',
  """                    color: const Color(0xFF17140F).withOpacity(0.8),
                    fontSize: station.broadcaster.length > 3 ? 10 : 12,""",
  """                    color: isDarkMode ? const Color(0xFFF3EFE7).withOpacity(0.85) : const Color(0xFF17140F).withOpacity(0.8),
                    fontSize: station.broadcaster.length > 3 ? 10 : 12,"""),
 ('색 만드는 함수 바꾸기',
  """/// 방송사 파스텔 (홈 '최근에 들었어요'와 같은 색)
Color _brandPastel(String b) {
  switch (b) {
    // 파스텔을 바탕(베이지)과 반쯤 섞어 은은하게
    case 'KBS':
      return const Color(0xFFE1E4E3); // 하늘
    case 'MBC':
      return const Color(0xFFF0E0D2); // 복숭아
    case 'SBS':
      return const Color(0xFFE4E6D6); // 연두
    case 'CBS':
      return const Color(0xFFE5DEE1); // 라벤더
    case 'EBS':
      return const Color(0xFFEEE5CE); // 노랑
    default:
      return const Color(0xFFEAE3D6); // 그 밖: 연한 베이지
  }
}""",
  """/// 목록 왼쪽 방송사 칸 색 = 방송사별 박스 색을 바탕에 조금만 섞은 색
/// (박스 색을 바꾸면 여기도 저절로 따라감)
const double _brandTint = 0.16; // 라이트 모드 진하기 (0.16 → 더 진하게는 0.2·0.26)
Color _brandPastel(String b, bool dark) {
  final box = _BroadcasterGridScreen._cardColors[_BroadcasterGridScreen._keyOf(b)];
  if (dark) {
    // 다크: 어두운 바탕에 차분하게 줄인 박스 색을 섞기 (글자는 밝게)
    const bg = Color(0xFF24221F);
    if (box == null) return const Color(0xFF3A3732);
    return Color.lerp(bg, _softDark(box, true), 0.45)!;
  }
  const bg = Color(0xFFEDE7DA); // 라디오 화면 바탕 (베이지)
  if (box == null) return const Color(0xFFE3DCCD); // 그 밖: 연한 베이지
  return Color.lerp(bg, box, _brandTint)!;
}"""),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)
if '_softDark(' not in s:
    print('❌ apply_region_colors.py를 먼저 실행해 주세요. 아무것도 저장 안 했어요.'); sys.exit(1)
if crlf: s = s.replace('\n', '\r\n')
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
