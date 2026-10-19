# -*- coding: utf-8 -*-
# 해외 라디오: 브라우저 이름표로 물으면 웹페이지만 주는 옛날 방송 서버(약 1,400개) 살리기
# ① 주소가 서버 첫 화면(http://주소:8000/)이면 처음부터 재생기 이름표로
# ② 그 밖에도 소리가 안 나와 다시 연결할 때는 재생기 이름표로 한 번 더
# 한국 방송(KR)은 지금 그대로
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
P = os.path.join('lib', 'providers', 'radio_provider.dart')
if not os.path.exists(P):
    print('❌ 파일을 못 찾았어요:', P); sys.exit(1)
raw = open(P, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_playerUa' in s:
    print('이미 적용돼 있어요'); sys.exit(0)

edits = [
 ('재생기 이름표 쓸 방송 목록',
  """  int _stallRetries = 0;""",
  """  int _stallRetries = 0;
  // 브라우저 이름표로는 웹페이지만 주는 해외 방송 → 재생기 이름표로 다시 (한 번 바꾸면 앱 켜져 있는 동안 기억)
  final Set<String> _playerUa = {};
  static const _browserUa = 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36';
  static const _playerUaName = 'VLC/3.0.20 LibVLC/3.0.20';"""),
 ('소리 안 나와 다시 연결할 때 이름표 바꾸기',
  """      _stallRetries++;
      debugPrint(""",
  """      // 해외 방송이면 다음 연결은 재생기 이름표로 (옛날 방송 서버는 브라우저에겐 웹페이지를 줌)
      if ((st.countryCode ?? '') != 'KR') _playerUa.add(st.stationUuid);
      _stallRetries++;
      debugPrint("""),
 ('열기 전에 이름표 정하기',
  """      await _player.open(
        Media(
          playUrl,""",
  """      // 해외 방송: 주소가 서버 첫 화면(http://주소:8000/)이거나 한 번 안 나왔던 방송이면 재생기 이름표로
      final isKr = (station.countryCode ?? '') == 'KR';
      final path = Uri.tryParse(playUrl)?.path ?? '';
      if (!isKr && (path.isEmpty || path == '/')) _playerUa.add(station.stationUuid);
      final ua = (!isKr && _playerUa.contains(station.stationUuid)) ? _playerUaName : _browserUa;
      try {
        await (_player.platform as NativePlayer).setProperty('user-agent', ua);
      } catch (_) {}
      await _player.open(
        Media(
          playUrl,"""),
 ('열 때 이름표',
  """            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'Referer': _getReferer(station),""",
  """            'User-Agent': ua,
            'Referer': _getReferer(station),"""),
]
for name, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ {name} — 찾을 코드를 못 찾았어요 ({n}곳). 아무것도 저장 안 했어요.'); sys.exit(1)
    s = s.replace(old, new); print('✔', name)
if crlf: s = s.replace('\n', '\r\n')
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
