# -*- coding: utf-8 -*-
# 인터넷이 없을 때 차 화면 안내
#  - 자연소리: 못 받아 오면 "인터넷 연결을 확인해 주세요" (예전엔 0:00으로 재생 중처럼 멈춰 있었음)
#              그 뒤 재생 버튼을 누르면 다시 받아 오기
#  - 팟캐스트: 목록을 못 받으면 "항목 없음" 대신 "인터넷 연결을 확인해 주세요" 칸 (누르면 같은 안내)
import os, sys

PP = os.path.join('lib', 'providers', 'player_provider.dart')
CB = os.path.join('lib', 'services', 'car_browse.dart')

EDITS = {
    PP: [
        (
"""      handler.onNaturePlay = () => resumeNatureSound();""",
"""      // 못 받아 와서 멈춰 있으면(인터넷 없음 등) 재생 버튼 → 다시 받아 오기
      handler.onNaturePlay = () => _player.processingState == ProcessingState.idle
          ? playNatureSound(assetPath, displayName)
          : resumeNatureSound();""",
        ),
        (
"""        await _player.setAudioSource(source);
      } finally {
        _switching = false;
      }
      await _player.setLoopMode(LoopMode.one);""",
"""        await _player.setAudioSource(source).timeout(const Duration(seconds: 15)); // 인터넷 없으면 오래 기다리지 않게
      } finally {
        _switching = false;
      }
      await _player.setLoopMode(LoopMode.one);""",
        ),
        (
"""      debugPrint('자연소리 재생 오류: $e');
    }""",
"""      debugPrint('자연소리 재생 오류: $e');
      // 차 화면 · 알림창에도 안내 (재생 중처럼 멈춰 있지 않게)
      if (handler is SimpleAudioHandler && _natureSoundName == displayName) {
        handler.showError(tr.checkInternet); // 먼저 안내를 띄우고 멈추기 (멈출 때 '정지'로 바뀌지 않게)
        await _player.stop().catchError((Object _) {});
      }
    }""",
        ),
        (
"""    _player.playbackEventStream.listen((event) {
      if (!_radioMode) {
        playbackState.add(_transformEvent(event));
      }
    });""",
"""    _player.playbackEventStream.listen((event) {
      if (!_radioMode) {
        // 안내 글을 띄운 뒤 멈춰 있는 동안은 그대로 (다시 틀기 시작하면 보통 상태로)
        if (_holdError && _player.processingState == ProcessingState.idle) return;
        _holdError = false;
        playbackState.add(_transformEvent(event));
      }
    });""",
        ),
        (
"""  void setRadioMode(bool enabled) {
    _radioMode = enabled;
  }""",
"""  void setRadioMode(bool enabled) {
    _radioMode = enabled;
  }

  bool _holdError = false; // 안내 글을 띄워 둔 동안 true

  /// 못 틀었을 때 (인터넷 없음 등): 차 화면 · 알림창에 안내 글 — 재생 버튼을 다시 누르면 다시
  void showError(String message) {
    _holdError = true;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      playing: false,
      processingState: AudioProcessingState.error,
      errorCode: 1, // 앱 오류 (안드로이드 ERROR_CODE_APP_ERROR)
      errorMessage: message,
      updatePosition: Duration.zero,
      speed: 0.0,
    ));
  }""",
        ),
    ],
    CB: [
        (
"""      items.add(_showItem(s, podText('인기 팟캐스트', 'Top podcasts')));
    }
    return items;
  }""",
"""      items.add(_showItem(s, podText('인기 팟캐스트', 'Top podcasts')));
    }
    if (items.isEmpty) return [_offlineItem()]; // 못 받았으면 "항목 없음" 대신 안내
    return items;
  }

  /// 인터넷이 없어서 목록을 못 받았을 때 보이는 칸 (누르면 차 화면에 같은 안내)
  static MediaItem _offlineItem() => MediaItem(
        id: 'offline',
        title: tr.checkInternet,
        playable: true,
        artUri: _tile('!', '', 0xFF33405A),
      );""",
        ),
        (
"""    return [for (final e in eps.take(100)) _episodeItem(s, e)];""",
"""    if (eps.isEmpty) return [_offlineItem()]; // 못 받았으면 "항목 없음" 대신 안내
    return [for (final e in eps.take(100)) _episodeItem(s, e)];""",
        ),
        (
"""      } else if (id == 'mshuffle') {""",
"""      } else if (id == 'offline') {
        // "인터넷 연결을 확인해 주세요" 칸: 아무것도 안 나오는 중일 때만 재생 화면에 안내 (듣던 건 그대로)
        final h = pp.audioHandler;
        if (h is SimpleAudioHandler && !pp.isPlaying && !radio.isPlaying && !radio.isLoading) {
          h.mediaItem.add(MediaItem(id: 'offline', title: podText('팟캐스트', 'Podcasts')));
          h.showError(tr.checkInternet);
        }
      } else if (id == 'mshuffle') {""",
        ),
    ],
}

MARK = (PP, 'void showError(')


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
