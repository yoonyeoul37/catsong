# -*- coding: utf-8 -*-
# 라디오: 와이파이↔LTE 바뀔 때 뱅뱅 도는 것 고치기 (바뀌면 바로 새로 연결 + 10초 넘게 안 나오면 다시 연결)
# 실행: python apply_radio_network.py
import os, sys

EDITS = {
    'radio_provider.dart': [('  Timer? _playedTimer; // 30초 이상 들었을 때만 최근에 넣기', "  Timer? _playedTimer; // 30초 이상 들었을 때만 최근에 넣기\n  bool _userPaused = false; // 사용자가 직접 멈춤 → 자동 다시 연결 안 함\n  Timer? _stallTimer; // 너무 오래 '불러오는 중'이면 다시 연결\n  int _stallRetries = 0; // 연달아 다시 연결한 횟수 (3번까지)\n\n  /// [secs]초 뒤에도 소리가 안 나오면 새로 연결 (와이파이↔LTE 바뀔 때 뱅뱅 도는 것 막기)\n  void _armStall([int secs = 10]) {\n    _stallTimer?.cancel();\n    _stallTimer = Timer(Duration(seconds: secs), () {\n      final st = _currentStation;\n      if (st == null || _userPaused || _isActuallyPlaying) return;\n      if (_playerState == RadioPlayerState.idle) return;\n      if (_stallRetries >= 3) return; // 계속 안 되면 그만 (방송 자체 문제일 수 있음)\n      _stallRetries++;\n      debugPrint('$secs초 넘게 소리 없음 → 다시 연결 ($_stallRetries번째)');\n      playStation(st, force: true);\n    });\n  }"), ("  Future<void> playStation(RadioStation station) async {\n    if (_playerState == RadioPlayerState.loading) {\n      debugPrint('이미 로딩 중 - 중복 호출 무시');\n      return;\n    }", "  Future<void> playStation(RadioStation station, {bool force = false}) async {\n    // force: 네트워크가 바뀌어서 다시 연결할 때는 '불러오는 중'이어도 새로 시작\n    if (_playerState == RadioPlayerState.loading && !force) {\n      debugPrint('이미 로딩 중 - 중복 호출 무시');\n      return;\n    }\n    _userPaused = false;\n    _armStall(15); // 연결하는 데 15초 넘게 걸리면 한 번 더"), ('      _isActuallyPlaying = playing;\n      if (playing) {\n        _setPlayerState(RadioPlayerState.playing);', '      _isActuallyPlaying = playing;\n      if (playing) {\n        _stallTimer?.cancel(); // 소리 나옴 → 다시 연결 그만\n        _stallRetries = 0;\n        _setPlayerState(RadioPlayerState.playing);'), ('      if (buffering && !_isActuallyPlaying) {\n        _setPlayerState(RadioPlayerState.loading);\n      }\n    });', '      if (buffering && !_isActuallyPlaying) {\n        _setPlayerState(RadioPlayerState.loading);\n      }\n      // 10초 넘게 계속 불러오는 중이면 새로 연결\n      if (buffering) _armStall(10);\n    });'), ('      await _player.pause();\n      await WakelockPlus.disable().catchError((Object _) {});\n    } else if (_playerState == RadioPlayerState.paused) {', '      _userPaused = true; // 직접 멈춤 → 네트워크 바뀌어도 다시 켜지 않음\n      _stallTimer?.cancel();\n      await _player.pause();\n      await WakelockPlus.disable().catchError((Object _) {});\n    } else if (_playerState == RadioPlayerState.paused) {'), ('  Future<void> stopRadio() async {\n    _setPlayerState(RadioPlayerState.idle);', '  Future<void> stopRadio() async {\n    _stallTimer?.cancel();\n    _setPlayerState(RadioPlayerState.idle);'), ("      await nativePlayer.setProperty('network-timeout', '30');", "      await nativePlayer.setProperty('network-timeout', '15'); // 끊긴 연결을 30초씩 기다리지 않게"), ("  void _listenConnectivity() {\n    List<ConnectivityResult> _lastResults = [];\n    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {\n      final isNone = results.isEmpty || (results.contains(ConnectivityResult.none) && results.length == 1);\n      final wasNone = _lastResults.isEmpty || (_lastResults.contains(ConnectivityResult.none) && _lastResults.length == 1);\n      final networkChanged = !isNone && _lastResults.isNotEmpty && !wasNone && results.toString() != _lastResults.toString();\n      _lastResults = List.from(results);\n\n      if (_currentStation == null) return;\n\n      // 네트워크 없음→있음 복구 시\n      if (!isNone && wasNone && !_isActuallyPlaying &&\n          _playerState != RadioPlayerState.idle &&\n          _playerState != RadioPlayerState.error) {\n        debugPrint('네트워크 복구 감지 - 라디오 재연결 시도');\n        await Future.delayed(const Duration(seconds: 2));\n        if (_currentStation != null && !_isActuallyPlaying) {\n          await playStation(_currentStation!);\n        }\n      }\n      // WiFi↔LTE 전환 시 (스트림 끊김 대비)\n      else if (networkChanged &&\n          _playerState != RadioPlayerState.idle &&\n          _playerState != RadioPlayerState.error) {\n        debugPrint('네트워크 전환 감지 - 라디오 재연결 시도');\n        await Future.delayed(const Duration(milliseconds: 800));\n        if (_currentStation != null && !_isActuallyPlaying) {\n          await playStation(_currentStation!);\n        }\n      }\n    });\n  }\n\n", "  void _listenConnectivity() {\n    List<ConnectivityResult> lastResults = [];\n    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {\n      final isNone = results.isEmpty || (results.contains(ConnectivityResult.none) && results.length == 1);\n      final wasNone = lastResults.isEmpty || (lastResults.contains(ConnectivityResult.none) && lastResults.length == 1);\n      final hadWifi = lastResults.contains(ConnectivityResult.wifi);\n      final hasWifi = results.contains(ConnectivityResult.wifi);\n      lastResults = List.from(results);\n\n      if (_currentStation == null || isNone || _userPaused) return;\n      if (_playerState == RadioPlayerState.idle) return;\n\n      // 끊겼다 다시 연결됨 · 또는 와이파이↔LTE가 바뀜 → 소리가 나오는 중이어도 새 네트워크로 다시 연결\n      // (예전엔 '소리 안 날 때만' · '불러오는 중이면 무시'라서, 옛 네트워크에 매달려 30초 넘게 뱅뱅 돌았음)\n      if (wasNone || hadWifi != hasWifi) {\n        debugPrint('네트워크 바뀜 감지 (와이파이 $hadWifi → $hasWifi) - 라디오 다시 연결');\n        await Future.delayed(const Duration(milliseconds: 1500)); // 새 네트워크를 실제로 쓸 수 있을 때까지 잠깐\n        final cur = _currentStation;\n        if (cur == null || _userPaused || _playerState == RadioPlayerState.idle) return;\n        _stallRetries = 0;\n        await playStation(cur, force: true);\n      }\n    });\n  }\n\n")],
}


def find(name):
    for root, _, files in list(os.walk('tools')) + list(os.walk('lib')):
        if name in files:
            return os.path.join(root, name)
    return None


done = {}
total = 0
for name, edits in EDITS.items():
    p = find(name)
    if not p:
        print(f'❌ {name} 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요) — 아무것도 저장 안 했어요'); sys.exit(1)
    with open(p, 'r', encoding='utf-8', newline='') as f:
        t = f.read()
    crlf = '\r\n' in t
    t = t.replace('\r\n', '\n')
    cnt = lambda x: [x.count(ch) - x.count(cl) for ch, cl in ('()', '{}', '[]')]
    before = cnt(t)
    n = 0
    for i, (o, new) in enumerate(edits, 1):
        if new in t:
            continue
        if t.count(o) != 1:
            print(f'❌ {name} {i}번 고칠 곳을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
        t = t.replace(o, new)
        print(f'✔ {name} {i}번 고침')
        n += 1
    if name.endswith('.py'):
        try:
            compile(t, p, 'exec')
        except SyntaxError as e:
            print(f'❌ {name} 고친 뒤 코드가 맞지 않아요 ({e}) — 아무것도 저장 안 했어요'); sys.exit(1)
    elif cnt(t) != before:  # 고치기 전과 괄호 짝이 같아야 함
        print(f'❌ {name} 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
    done[p] = (t, crlf, n)
    total += n

if total == 0:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, (t, crlf, n) in done.items():
    if n:
        with open(p, 'w', encoding='utf-8', newline='') as f:
            f.write(t.replace('\n', '\r\n') if crlf else t)
print('완료!')
