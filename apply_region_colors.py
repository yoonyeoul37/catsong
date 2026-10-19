# -*- coding: utf-8 -*-
# 라디오 지역별 색 바꾸기(A안) + 다크 모드에서 방송사별·지역별 박스 색 차분하게
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_softDark(' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ('지역 색 바꾸기 (대구/경북·광주/전남·전북)',
  """    '대구/경북': Color(0xFF7A1F1F),
    '광주/전남': Color(0xFF1E4A2E),
    '전북': Color(0xFF4A1E5C),""",
  """    '대구/경북': Color(0xFF4A1E5C), // 자주 (정치색 오해 없게 빨강·녹색 안 씀)
    '광주/전남': Color(0xFF5A4632), // 회갈
    '전북': Color(0xFF33405A), // 회청"""),
 ('지역별 박스 다크 모드 색',
  """                colors: [
                  _regionColors[region] ?? const Color(0xFF3A342A),
                  (_regionColors[region] ?? const Color(0xFF3A342A)).withOpacity(0.8),
                ],""",
  """                colors: [
                  _softDark(_regionColors[region] ?? const Color(0xFF3A342A), isDarkMode),
                  _softDark(_regionColors[region] ?? const Color(0xFF3A342A), isDarkMode).withOpacity(0.8),
                ],"""),
 ('방송사별 박스 다크 모드 색',
  """                colors: [
                  _cardColors[key] ?? const Color(0xFF3A342A),
                  (_cardColors[key] ?? const Color(0xFF3A342A)).withOpacity(0.8),
                ],""",
  """                colors: [
                  _softDark(_cardColors[key] ?? const Color(0xFF3A342A), isDarkMode),
                  _softDark(_cardColors[key] ?? const Color(0xFF3A342A), isDarkMode).withOpacity(0.8),
                ],"""),
 ('채널 목록 위쪽 색 띠도 다크 모드 색',
  """  Widget _header(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;""",
  """  Widget _header(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final color = _softDark(this.color, context.watch<ThemeProvider>().isDarkMode);"""),
 ('색 줄이는 함수 추가',
  """class _BroadcasterGridScreen extends StatelessWidget {""",
  """/// 다크 모드에서 박스 색을 차분하게 (홈 카드처럼 색 반쯤 빼고 살짝 어둡게)
Color _softDark(Color c, bool dark) {
  if (!dark) return c;
  final h = HSLColor.fromColor(c);
  return h.withSaturation(h.saturation * 0.5).withLightness(h.lightness * 0.85).toColor();
}

class _BroadcasterGridScreen extends StatelessWidget {"""),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)
if crlf: s = s.replace('\n', '\r\n')
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
