# -*- coding: utf-8 -*-
# 차 화면: 음악 다음/이전 곡 누르면 "선택한 항목을 가져오는 중…" 뒤 목록으로 튕기던 것
#  - 곡 바꾸는 아주 짧은 순간 '정지(idle)'로 알려서 차가 재생이 끝난 줄 알았음
#  - 곡 바꾸는 동안엔 '불러오는 중(loading)'으로 알리기
import os, sys

PP = os.path.join('lib', 'providers', 'player_provider.dart')

EDITS = {
    PP: [
        (
"""  bool _isChangingSong = false;
  DateTime _startedAt = DateTime(2000); // 곡을 막 튼 시각""",
"""  bool _isChangingSong = false;
  bool _switching = false; // 곡 바꾸는 중 (차 화면에 '정지'로 알리지 않게)
  DateTime _startedAt = DateTime(2000); // 곡을 막 튼 시각""",
        ),
        (
"""      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      // 자연소리가 남긴""",
"""      _switching = true;
      try {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      } finally {
        _switching = false;
      }
      // 자연소리가 남긴""",
        ),
        (
"""  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(""",
"""  PlaybackState _transformEvent(PlaybackEvent event) {
    var ps = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;
    // 곡 바꾸는 순간의 '정지'는 '불러오는 중'으로 (차가 재생 끝난 줄 알고 목록으로 돌아가지 않게)
    if (ps == AudioProcessingState.idle && _provider._switching) ps = AudioProcessingState.loading;
    return PlaybackState(""",
        ),
        (
"""      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,""",
"""      androidCompactActionIndices: const [0, 1, 2],
      processingState: ps,
      playing: _player.playing,""",
        ),
    ],
}

MARK = (PP, '_provider._switching')


def gaps(s):
    return (s.count('(') - s.count(')'), s.count('{') - s.count('}'), s.count('[') - s.count(']'))


def main():
    if os.path.exists(MARK[0]):
        with open(MARK[0], 'rb') as f:
            if MARK[1].encode() in f.read():
                print('이미 적용돼 있어요')
                return
    out = {}
    ok = True
    for rel, pairs in EDITS.items():
        name = os.path.basename(rel)
        if not os.path.exists(rel):
            print('❌ 파일이 없어요:', rel)
            ok = False
            continue
        with open(rel, 'rb') as f:
            raw = f.read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = gaps(text)
        for i, (old, new) in enumerate(pairs, 1):
            n = text.count(old)
            if n != 1:
                print('❌ %s %d번째 곳을 못 찾았어요 (%d개)' % (name, i, n))
                ok = False
                continue
            text = text.replace(old, new)
            print('✔ %s %d번째 곳' % (name, i))
        if gaps(text) != before:
            print('❌ %s 괄호가 안 맞아요' % name)
            ok = False
        out[rel] = text.replace('\n', '\r\n') if crlf else text
    if not ok:
        print('\n❌ 하나라도 실패해서 아무것도 저장 안 했어요')
        sys.exit(1)
    for rel, text in out.items():
        with open(rel, 'wb') as f:
            f.write(text.encode('utf-8'))
    print('\n✔ 다 됐어요')


main()
