# -*- coding: utf-8 -*-
# 전화 끝난 뒤: 내가 멈춰 둔 라디오·음악이 저절로 다시 틀어지지 않게
# (전화 때문에 멈춘 것만 다시 틀기)
import os, sys

EDITS = {
    'lib/providers/radio_provider.dart': [
        (
"""      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          debugPrint('오디오 인터럽트 발생 - 라디오 정지');
          if (_playerState == RadioPlayerState.playing) {
          _player.pause();
          _setPlayerState(RadioPlayerState.paused);
          _updateForeground(false);
          }
        } else {
          debugPrint('오디오 인터럽트 종료 - 라디오 재개');
          if (_currentStation != null && _playerState == RadioPlayerState.paused) {
            playStation(_currentStation!);
          }
        }
      });""",
"""      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          debugPrint('오디오 인터럽트 발생 - 라디오 정지');
          if (_playerState == RadioPlayerState.playing) {
          _player.pause();
          _pausedByInterrupt = true; // 전화 등으로 멈춘 것만 나중에 다시 틀기
          _setPlayerState(RadioPlayerState.paused);
          _updateForeground(false);
          }
        } else {
          debugPrint('오디오 인터럽트 종료 - 라디오 재개');
          // 내가 직접 멈춰 둔 거면 그대로 (전화 끝나고 저절로 틀어지지 않게)
          if (_pausedByInterrupt && _currentStation != null && _playerState == RadioPlayerState.paused) {
            playStation(_currentStation!);
          }
          _pausedByInterrupt = false;
        }
      });""",
        ),
        (
"""  bool _pausedByFocusLoss = false;
""",
"""  bool _pausedByFocusLoss = false;
  bool _pausedByInterrupt = false; // 전화 등(인터럽트)으로 멈췄는지
""",
        ),
    ],
    'lib/providers/player_provider.dart': [
        (
"""  void _initWidgetChannel() {
    _channel.setMethodCallHandler((call) async {""",
"""  bool _pausedByFocus = false; // 다른 소리(전화 등) 때문에 멈췄는지

  void _initWidgetChannel() {
    _channel.setMethodCallHandler((call) async {""",
        ),
        (
"""          if (_isPlaying && DateTime.now().difference(_startedAt).inSeconds >= 2) {
            await _player.pause();
          }""",
"""          if (_isPlaying && DateTime.now().difference(_startedAt).inSeconds >= 2) {
            await _player.pause();
            _pausedByFocus = true;
          }""",
        ),
        (
"""        case 'onAudioFocusGain':
          if (!_isPlaying && _currentIndex >= 0) {
            await _player.play();
          }""",
"""        case 'onAudioFocusGain':
          // 다른 소리 때문에 멈춘 것만 다시 (내가 멈춰 둔 건 그대로)
          if (_pausedByFocus && !_isPlaying && _currentIndex >= 0) {
            await _player.play();
          }
          _pausedByFocus = false;""",
        ),
    ],
}

MARK = '_pausedByInterrupt'


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    base = os.getcwd()
    out = {}
    ok = True
    first = os.path.join(base, 'lib/providers/radio_provider.dart')
    if os.path.exists(first):
        with open(first, 'rb') as f:
            if MARK.encode() in f.read():
                print('이미 적용돼 있어요')
                return
    for rel, pairs in EDITS.items():
        path = os.path.join(base, rel)
        if not os.path.exists(path):
            print('❌ 파일이 없어요:', rel)
            ok = False
            continue
        with open(path, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = gaps(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (os.path.basename(rel), i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (os.path.basename(rel), i))
        if gaps(text) != before:
            print('❌ %s 괄호가 안 맞아요' % os.path.basename(rel))
            ok = False
        out[path] = text.replace('\n', '\r\n') if crlf else text
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for path, text in out.items():
        with open(path, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
