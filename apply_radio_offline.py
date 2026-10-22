# -*- coding: utf-8 -*-
# 라디오: 인터넷이 없을 때 차 화면이 '재생 중(⏸)'으로 멈춰 있던 것
#  1) 틀 때 인터넷이 아예 없으면 바로 "인터넷 연결을 확인해 주세요"
#  2) 다시 연결을 3번 해도 소리가 안 나오면 "방송을 불러오지 못했어요" (예전엔 그냥 멈춰 있었음)
import os, sys

RP = os.path.join('lib', 'providers', 'radio_provider.dart')

EDITS = {
    RP: [
        (
"""      _startSchedule(station); // 편성표는 소리 연결을 기다리지 않고 바로 받기 시작
      notifyListeners();
""",
"""      _startSchedule(station); // 편성표는 소리 연결을 기다리지 않고 바로 받기 시작
      notifyListeners();

      // 인터넷이 아예 없으면 바로 안내 (차 화면 · 알림창이 '재생 중'으로 멈춰 있지 않게)
      final net = await Connectivity().checkConnectivity();
      if (gen != _playGen) return;
      if (net.isEmpty || net.every((r) => r == ConnectivityResult.none)) {
        _stallTimer?.cancel();
        _simpleHandler?.setRadioMediaItem(title: station.name, artist: _mediaSubtitle(station), url: station.streamUrl);
        _simpleHandler?.setRadioMode(true);
        _errorMessage = tr.checkInternet;
        _setPlayerState(RadioPlayerState.error);
        return;
      }
""",
        ),
        (
"""      if (_stallRetries >= 3) return; // 계속 안 되면 그만 (방송 자체 문제일 수 있음)""",
"""      if (_stallRetries >= 3) {
        // 계속 안 되면 그만하고 안내 (방송 자체 문제일 수 있음)
        _errorMessage = tr.stationLoadFailed;
        _setPlayerState(RadioPlayerState.error);
        return;
      }""",
        ),
    ],
}

MARK = (RP, 'Connectivity().checkConnectivity()')


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
