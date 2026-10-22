# -*- coding: utf-8 -*-
# 라디오 재생 시간 줄 (차 화면 · 폰 알림창)
#  - 편성표가 있으면: 프로그램 시작~끝 (예: 11:00~12:00 프로그램을 11:40에 들으면 40:00 / 1:00:00)
#  - 편성표가 없으면: 시간 줄 없애기 (생방송이라 길이가 없어서 0:00으로 나오던 것)
import os, sys

PP = os.path.join('lib', 'providers', 'player_provider.dart')
RP = os.path.join('lib', 'providers', 'radio_provider.dart')

EDITS = {
    PP: [
        (
"""  void setRadioPlaybackState({required bool playing}) {
    if (playing) _radioMode = true;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: playing,
      processingState: AudioProcessingState.ready,
    ));
  }""",
"""  void setRadioPlaybackState({required bool playing}) {
    if (playing) _radioMode = true;
    final pos = _radioPos();
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: playing,
      processingState: AudioProcessingState.ready,
      updatePosition: pos ?? const Duration(milliseconds: -1), // -1 = 위치 모름 → 시간 줄 안 보임
      speed: pos != null && playing ? 1.0 : 0.0,
    ));
  }

  // ───── 라디오 시간 줄: 지금 프로그램 시작~끝 (편성표) ─────
  String? _progFor; // 어느 방송의 프로그램 시간인지
  DateTime? _progStart;
  DateTime? _progEnd;

  /// 지금 프로그램이 시작한 뒤 지난 시간 (편성표 없거나 시간 밖이면 null)
  Duration? _radioPos() {
    final s = _progStart, e = _progEnd;
    if (s == null || e == null) return null;
    final now = DateTime.now();
    if (now.isBefore(s) || !now.isBefore(e)) return null;
    return now.difference(s);
  }

  Duration? _radioLength() {
    final s = _progStart, e = _progEnd;
    if (_radioPos() == null || s == null || e == null) return null;
    return e.difference(s);
  }

  /// 편성표에서 지금 프로그램 시간이 오면 (없으면 null, null) → 시간 줄 다시
  void setRadioProgramTime(String station, DateTime? start, DateTime? end) {
    _progFor = station;
    _progStart = start;
    _progEnd = end;
    if (!_radioMode) return;
    final pos = _radioPos();
    playbackState.add(playbackState.value.copyWith(
      updatePosition: pos ?? const Duration(milliseconds: -1),
      speed: pos != null && playbackState.value.playing ? 1.0 : 0.0,
    ));
    // 길이를 없앨 때도 있어서 copyWith 말고 새로 (copyWith는 null을 넣어도 예전 길이가 남음)
    final cur = mediaItem.value;
    if (cur != null) {
      mediaItem.add(MediaItem(
        id: cur.id,
        title: cur.title,
        artist: cur.artist,
        album: cur.album,
        artUri: cur.artUri,
        displaySubtitle: cur.displaySubtitle,
        duration: _radioLength(),
      ));
    }
  }""",
        ),
        (
"""    // 차에 연결돼 있으면: 차 화면 목록과 같은 방송 그림 / 아니면 시간대 사진
    final carArt = CarBrowse.nowPlayingArt();
    mediaItem.add(MediaItem(
      id: url ?? '',
      title: title,
      artist: artist,
      album: tr.paransoriRadio,
      artUri: carArt,
    ));""",
"""    // 다른 방송으로 바뀌었으면 지난 프로그램 시간은 버리기
    if (_progFor != title) {
      _progFor = title;
      _progStart = null;
      _progEnd = null;
    }
    // 차에 연결돼 있으면: 차 화면 목록과 같은 방송 그림 / 아니면 시간대 사진
    final carArt = CarBrowse.nowPlayingArt();
    mediaItem.add(MediaItem(
      id: url ?? '',
      title: title,
      artist: artist,
      album: tr.paransoriRadio,
      artUri: carArt,
      duration: _radioLength(), // 프로그램 길이 (편성표 없으면 없음)
    ));""",
        ),
    ],
    RP: [
        (
"""    _simpleHandler?.setRadioMediaItem(
      title: stationName,
      artist: _carLine(stationName, programTitle, start) ?? artist, // 차에선 다음 방송까지
      url: _currentStation?.streamUrl ?? '',
    );""",
"""    // 시간 줄: 지금 프로그램 시작~끝 (편성표 시간 그대로)
    final span = _programSpan(start, end);
    _simpleHandler?.setRadioProgramTime(stationName, span?.$1, span?.$2);
    _simpleHandler?.setRadioMediaItem(
      title: stationName,
      artist: _carLine(stationName, programTitle, start) ?? artist, // 차에선 다음 방송까지
      url: _currentStation?.streamUrl ?? '',
    );""",
        ),
        (
"""  void _updateNotification(String stationName) {""",
"""  /// 편성표 시간("11050000" · "1100" · "11:00", 24시 넘는 것도) → 지금 프로그램의 (시작, 끝) — 지금이 그 안이 아니면 null
  (DateTime, DateTime)? _programSpan(String start, String end) {
    (int, int)? hm(String t) {
      final s = t.trim();
      if (s.contains(':')) {
        final p = s.split(':');
        final h = int.tryParse(p[0].replaceAll(RegExp(r'[^0-9]'), ''));
        final m = int.tryParse(p.length > 1 ? p[1].replaceAll(RegExp(r'[^0-9]'), '') : '');
        return (h == null || m == null) ? null : (h, m);
      }
      if (s.length < 4) return null;
      final h = int.tryParse(s.substring(0, 2));
      final m = int.tryParse(s.substring(2, 4));
      return (h == null || m == null) ? null : (h, m);
    }

    final a = hm(start), b = hm(end);
    if (a == null || b == null) return null;
    final now = DateTime.now();
    var st = DateTime(now.year, now.month, now.day, a.$1, a.$2);
    if (st.isAfter(now)) st = st.subtract(const Duration(days: 1)); // 어제 시작한 밤 프로그램
    var en = DateTime(st.year, st.month, st.day, b.$1, b.$2);
    while (!en.isAfter(st)) {
      en = en.add(const Duration(days: 1)); // 자정 넘어 끝나는 프로그램
    }
    if (now.isBefore(st) || !now.isBefore(en) || en.difference(st) > const Duration(hours: 12)) return null;
    return (st, en);
  }

  void _updateNotification(String stationName) {""",
        ),
    ],
}

MARK = (PP, 'setRadioProgramTime(')


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
