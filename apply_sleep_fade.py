# -*- coding: utf-8 -*-
# 수면 타이머: 끝나기 1분 전부터 소리를 천천히 줄이다가 끄기 (뚝 끊겨서 잠이 깨지 않게)
# - 음악 · 자연(상세 화면) · 라디오 · 나만의 소리 믹스 모두
# - 꺼진 뒤(또는 타이머를 취소하면) 소리 크기는 원래대로 → 다음에 틀 때 작게 나오지 않게
# - 수면 타이머 창 5곳 제목 아래 "끝나기 1분 전부터 천천히 작아져요" 한 줄
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')
P = lambda *a: os.path.join(LIB, *a)

PLAYER_PROV = P('providers', 'player_provider.dart')
RADIO_PROV = P('providers', 'radio_provider.dart')
MIX_PROV = P('providers', 'sound_mix_provider.dart')
NATURE_DETAIL = P('screens', 'nature_sound_detail_screen.dart')
PLAYER_SCREEN = P('screens', 'player_screen.dart')
MIX_SCREEN = P('screens', 'sound_mix_screen.dart')
RADIO_SHEET = P('widgets', 'sleep_timer_sheet.dart')

# 타이머 창 제목 (음악 재생화면 2곳 · 자연 상세 · 믹스 — 모양이 같음)
TITLE_OLD = (
    "                        child: Text('몇 시간 몇 분 후 정지할까요?',\n"
    "                            textAlign: TextAlign.center,\n"
    "                            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),\n")
TITLE_NEW = (
    "                        child: Column(\n"
    "                          children: [\n"
    "                            Text('몇 시간 몇 분 후 정지할까요?',\n"
    "                                textAlign: TextAlign.center,\n"
    "                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),\n"
    "                            const SizedBox(height: 3),\n"
    "                            Text('끝나기 1분 전부터 천천히 작아져요',\n"
    "                                textAlign: TextAlign.center,\n"
    "                                style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),\n"
    "                          ],\n"
    "                        ),\n")

EDITS = {
    PLAYER_PROV: [
        ('음악: 수면 타이머 1분 전부터 작게',
         "  void setSleepTimer(Duration duration) {\n"
         "    _sleepTimer?.cancel();\n"
         "    _sleepTimerDuration = duration;\n"
         "    _sleepTimerEnd = DateTime.now().add(duration);\n"
         "    _sleepTimer = Timer(duration, () {\n"
         "      _player.pause();\n"
         "      _sleepTimer = null;\n",
         "  // ───── 수면 타이머: 끝나기 1분 전부터 천천히 작게 ─────\n"
         "  Timer? _sleepFadeStart; // 1분 전에 줄이기 시작\n"
         "  Timer? _sleepFade; // 1초마다 조금씩 작게\n"
         "\n"
         "  void _beginSleepFade() {\n"
         "    _sleepFade?.cancel();\n"
         "    _sleepFade = Timer.periodic(const Duration(seconds: 1), (t) {\n"
         "      final end = _sleepTimerEnd;\n"
         "      if (end == null) {\n"
         "        t.cancel();\n"
         "        return;\n"
         "      }\n"
         "      final left = end.difference(DateTime.now()).inMilliseconds / 60000.0;\n"
         "      _player.setVolume(left.clamp(0.0, 1.0));\n"
         "    });\n"
         "  }\n"
         "\n"
         "  /// 줄이던 걸 멈추고 소리 크기 원래대로\n"
         "  void _endSleepFade() {\n"
         "    _sleepFadeStart?.cancel();\n"
         "    _sleepFadeStart = null;\n"
         "    if (_sleepFade == null) return;\n"
         "    _sleepFade!.cancel();\n"
         "    _sleepFade = null;\n"
         "    _player.setVolume(1.0);\n"
         "  }\n"
         "\n"
         "  void setSleepTimer(Duration duration) {\n"
         "    _sleepTimer?.cancel();\n"
         "    _endSleepFade();\n"
         "    _sleepTimerDuration = duration;\n"
         "    _sleepTimerEnd = DateTime.now().add(duration);\n"
         "    final fadeAt = duration - const Duration(minutes: 1);\n"
         "    _sleepFadeStart = Timer(fadeAt.isNegative ? Duration.zero : fadeAt, _beginSleepFade);\n"
         "    _sleepTimer = Timer(duration, () {\n"
         "      // 다 작아진 뒤 멈추고, 멈춘 다음 소리 크기 원래대로\n"
         "      _player.pause().then((_) => _endSleepFade());\n"
         "      _sleepTimer = null;\n"),
        ('음악: 타이머 취소하면 소리 크기 원래대로',
         "  void cancelSleepTimer() {\n"
         "    _sleepTimer?.cancel();\n",
         "  void cancelSleepTimer() {\n"
         "    _sleepTimer?.cancel();\n"
         "    _endSleepFade();\n"),
    ],
    RADIO_PROV: [
        ('라디오: 줄이는 중 표시',
         "  Timer? _sleepCountdown;\n",
         "  Timer? _sleepCountdown;\n"
         "  bool _sleepFading = false; // 수면 타이머 끝나기 1분 전부터 작게 하는 중\n"),
        ('라디오: 1분 전부터 작게',
         "      _sleepRemaining = _sleepRemaining! - const Duration(seconds: 1);\n",
         "      _sleepRemaining = _sleepRemaining! - const Duration(seconds: 1);\n"
         "      // 끝나기 1분 전부터 천천히 작게 (뚝 끊겨서 잠이 깨지 않게)\n"
         "      final left = _sleepRemaining!.inSeconds;\n"
         "      if (left < 60) {\n"
         "        _sleepFading = true;\n"
         "        setAlarmVolume(left / 60);\n"
         "      }\n"),
        ('라디오: 멈춘 다음 소리 크기 원래대로',
         "    _sleepTimer = Timer(duration, () async {\n"
         "      await _player.stop();\n",
         "    _sleepTimer = Timer(duration, () async {\n"
         "      await _player.stop();\n"
         "      if (_sleepFading) {\n"
         "        _sleepFading = false;\n"
         "        await setAlarmVolume(1.0);\n"
         "      }\n"),
        ('라디오: 타이머 취소하면 소리 크기 원래대로',
         "  void cancelSleepTimer() {\n"
         "    _scheduleCheckTimer?.cancel();\n",
         "  void cancelSleepTimer() {\n"
         "    if (_sleepFading) {\n"
         "      _sleepFading = false;\n"
         "      setAlarmVolume(1.0);\n"
         "    }\n"
         "    _scheduleCheckTimer?.cancel();\n"),
    ],
    MIX_PROV: [
        ('믹스: 줄이기·되돌리기',
         "  void setSleepTimer(int? minutes) {\n"
         "    _sleepTicker?.cancel();\n",
         "  // ───── 수면 타이머: 끝나기 1분 전부터 천천히 작게 ─────\n"
         "  bool _sleepFading = false;\n"
         "\n"
         "  void _applySleepFade(double f) {\n"
         "    _natureLayers.forEach((key, p) {\n"
         "      p.setVolume((_volumes[key] ?? 0.0) * f);\n"
         "    });\n"
         "    _songPlayer?.setVolume(_songVolume * f);\n"
         "  }\n"
         "\n"
         "  /// 소리 크기 원래대로 (다음에 틀 때 작게 나오지 않게)\n"
         "  void _restoreSleepFade() {\n"
         "    if (!_sleepFading) return;\n"
         "    _sleepFading = false;\n"
         "    _applySleepFade(1.0);\n"
         "  }\n"
         "\n"
         "  void setSleepTimer(int? minutes) {\n"
         "    _sleepTicker?.cancel();\n"
         "    _restoreSleepFade();\n"),
        ('믹스: 1분 전부터 작게 → 멈춘 뒤 원래대로',
         "      if (remaining.isNegative || remaining == Duration.zero) {\n"
         "        timer.cancel();\n"
         "        stopAll();\n"
         "        _sleepMinutes = null;\n"
         "        _sleepEndTime = null;\n"
         "      }\n",
         "      if (remaining.isNegative || remaining == Duration.zero) {\n"
         "        timer.cancel();\n"
         "        stopAll().then((_) => _restoreSleepFade());\n"
         "        _sleepMinutes = null;\n"
         "        _sleepEndTime = null;\n"
         "      } else if (remaining.inSeconds < 60) {\n"
         "        // 끝나기 1분 전부터 천천히 작게\n"
         "        _sleepFading = true;\n"
         "        _applySleepFade(remaining.inMilliseconds / 60000.0);\n"
         "      }\n"),
        ('믹스: 닫을 때도 원래대로',
         "    _sleepTicker?.cancel();\n"
         "    _sleepMinutes = null;\n"
         "    _sleepEndTime = null;\n"
         "    notifyListeners();\n"
         "  }\n",
         "    _sleepTicker?.cancel();\n"
         "    _sleepFading = false;\n"
         "    _sleepMinutes = null;\n"
         "    _sleepEndTime = null;\n"
         "    notifyListeners();\n"
         "  }\n"),
    ],
    NATURE_DETAIL: [
        ('자연: 줄이는 중 표시',
         "  int? _sleepMinutes;\n"
         "  Set<String> _favoriteNames = {};\n",
         "  int? _sleepMinutes;\n"
         "  bool _sleepFading = false; // 수면 타이머 끝나기 1분 전부터 작게 하는 중\n"
         "  PlayerProvider? _pp; // 화면을 나갈 때도 소리 크기를 돌려놓으려고 미리 잡아둠\n"
         "  Set<String> _favoriteNames = {};\n"
         "\n"
         "  /// 소리 크기 원래대로 (다음에 틀 때 작게 나오지 않게)\n"
         "  void _restoreSleepFade() {\n"
         "    if (!_sleepFading) return;\n"
         "    _sleepFading = false;\n"
         "    _pp?.player.setVolume(1.0);\n"
         "  }\n"),
        ('자연: 음악 담당 미리 잡아두기',
         "    super.initState();\n"
         "    _loadFavorites();\n",
         "    super.initState();\n"
         "    _pp = context.read<PlayerProvider>();\n"
         "    _loadFavorites();\n"),
        ('자연: 화면 나가도 원래대로',
         "  void dispose() {\n"
         "    _sleepTicker?.cancel();\n"
         "    super.dispose();\n",
         "  void dispose() {\n"
         "    _sleepTicker?.cancel();\n"
         "    _restoreSleepFade();\n"
         "    super.dispose();\n"),
        ('자연: 타이머 바꾸거나 끄면 원래대로',
         "  void _setSleepTimer(int? minutes) {\n"
         "    _sleepTicker?.cancel();\n",
         "  void _setSleepTimer(int? minutes) {\n"
         "    _sleepTicker?.cancel();\n"
         "    _restoreSleepFade();\n"),
        ('자연: 1분 전부터 작게 → 멈춘 뒤 원래대로',
         "        timer.cancel();\n"
         "        context.read<PlayerProvider>().stopNatureSound();\n"
         "        setState(() {\n"
         "          _sleepMinutes = null;\n"
         "          _sleepEndTime = null;\n"
         "        });\n"
         "      } else {\n"
         "        setState(() {});\n"
         "      }\n",
         "        timer.cancel();\n"
         "        context.read<PlayerProvider>().stopNatureSound().then((_) {\n"
         "          if (mounted) _restoreSleepFade();\n"
         "        });\n"
         "        setState(() {\n"
         "          _sleepMinutes = null;\n"
         "          _sleepEndTime = null;\n"
         "        });\n"
         "      } else {\n"
         "        // 끝나기 1분 전부터 천천히 작게\n"
         "        if (remaining.inSeconds < 60) {\n"
         "          _sleepFading = true;\n"
         "          context.read<PlayerProvider>().player.setVolume(remaining.inMilliseconds / 60000.0);\n"
         "        }\n"
         "        setState(() {});\n"
         "      }\n"),
        ('자연: 타이머 창 안내',
         TITLE_OLD, TITLE_NEW),
    ],
    PLAYER_SCREEN: [
        ('음악 재생화면: 타이머 창 안내 (2곳)', TITLE_OLD, TITLE_NEW),
    ],
    MIX_SCREEN: [
        ('믹스 화면: 타이머 창 안내', TITLE_OLD, TITLE_NEW),
    ],
    RADIO_SHEET: [
        ('라디오 타이머 창: 안내',
         "              Text('몇 시간 몇 분 후 정지할까요?',\n"
         "                  style: TextStyle(color: _rInk, fontSize: 15, fontWeight: FontWeight.w600)),\n",
         "              Text('몇 시간 몇 분 후 정지할까요?',\n"
         "                  style: TextStyle(color: _rInk, fontSize: 15, fontWeight: FontWeight.w600)),\n"
         "              SizedBox(height: 3),\n"
         "              Text('끝나기 1분 전부터 천천히 작아져요', style: TextStyle(color: _rSub, fontSize: 12)),\n"),
    ],
}
# 같은 모양이 여러 번 나오는 곳 (모두 바꾸기)
EXPECT = {(PLAYER_SCREEN, TITLE_OLD): 2}

MARK = '_endSleepFade'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    for p in EDITS:
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(PLAYER_PROV, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in EDITS.items():
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            want = EXPECT.get((path, old), 1)
            if text.count(old) != want:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
