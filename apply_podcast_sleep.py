# -*- coding: utf-8 -*-
# 팟캐스트 수면 타이머 — 라디오와 똑같은 다이얼 창(sleep_timer_sheet.dart)을 같이 씀
#  · 재생 화면: 오른쪽 아래 '수면' 버튼 (켜지면 남은 분) + 아래에 '12분 30초 후 종료 ×' 줄 (라디오와 같게)
#  · 끝나기 1분 전부터 천천히 작아지고 → 멈춤 (듣던 곳은 기억)
#  · 글자는 라디오에 있는 걸 그대로 써서 23개 언어 이미 됨
import os, sys

P = {
    'sheet': os.path.join('lib', 'widgets', 'sleep_timer_sheet.dart'),
    'pod': os.path.join('lib', 'podcast', 'podcast.dart'),
    'screens': os.path.join('lib', 'podcast', 'podcast_screens.dart'),
}


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


D = {}
for k, p in P.items():
    if not os.path.exists(p):
        fail('파일이 없어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8')
    D[k] = {'s': raw.replace('\r\n', '\n'), 'crlf': '\r\n' in raw}
    D[k]['orig'] = D[k]['s']


def name(k):
    return os.path.basename(P[k])


def rep(k, label, old, new, done, count=1):
    s = D[k]['s']
    if done in s:
        print('✔', name(k), label, '(이미 돼 있음)')
        return
    n = s.count(old)
    if n != count:
        fail(f'{name(k)} {label} — 찾을 코드를 못 찾았어요 ({n}곳)')
    D[k]['s'] = s.replace(old, new)
    print('✔', name(k), label)


# ───────── sleep_timer_sheet.dart: 같은 창을 팟캐스트도 쓰게 ─────────
k = 'sheet'
rep(k, 'import', "import '../l10n/locale_holder.dart';\n",
    "import '../l10n/locale_holder.dart';\nimport '../podcast/podcast.dart';\n",
    done="import '../podcast/podcast.dart';")
rep(k, '팟캐스트용으로 열기',
    'class SleepTimerSheet extends StatefulWidget {\n  const SleepTimerSheet({super.key});\n',
    'class SleepTimerSheet extends StatefulWidget {\n'
    '  final bool podcast; // true: 팟캐스트 타이머 (모양은 라디오와 똑같음)\n'
    '  const SleepTimerSheet({super.key, this.podcast = false});\n',
    done='final bool podcast;')
rep(k, '라디오·팟캐스트 중 고르기',
    '    final radioProvider = context.watch<RadioProvider>();\n'
    '    final sleep = radioProvider.sleepRemaining;\n',
    '    final radioProvider = context.watch<RadioProvider>();\n'
    '    final pod = context.watch<PodcastPlayer>();\n'
    '    final forPod = widget.podcast;\n'
    '    final timerOn = forPod ? pod.isSleepTimerActive : radioProvider.isSleepTimerActive;\n'
    '    final sleep = forPod ? pod.sleepRemaining : radioProvider.sleepRemaining;\n',
    done='final forPod = widget.podcast;')
rep(k, '설명 글자', '                        radioProvider.isSleepTimerActive\n                            ? l.sleepTimerActiveDesc\n',
    '                        timerOn\n                            ? l.sleepTimerActiveDesc\n', done='                        timerOn\n')
rep(k, '남은 시간 보이기', '            if (radioProvider.isSleepTimerActive && sleep != null) ...[\n',
    '            if (timerOn && sleep != null) ...[\n', done='if (timerOn && sleep != null)')
rep(k, '남은 시간 초', '                valueListenable: radioProvider.sleepTick,\n',
    '                valueListenable: forPod ? pod.sleepTick : radioProvider.sleepTick,\n',
    done='forPod ? pod.sleepTick : radioProvider.sleepTick')
rep(k, '타이머 끄기',
    '                  context.read<RadioProvider>().cancelSleepTimer();\n',
    '                  if (forPod) {\n'
    '                    context.read<PodcastPlayer>().cancelSleepTimer();\n'
    '                  } else {\n'
    '                    context.read<RadioProvider>().cancelSleepTimer();\n'
    '                  }\n',
    done='context.read<PodcastPlayer>().cancelSleepTimer();')
rep(k, '타이머 켜기',
    '                    context.read<RadioProvider>().setSleepTimer(\n'
    '                      _wheelDuration,\n'
    '                    );\n',
    '                    if (forPod) {\n'
    '                      context.read<PodcastPlayer>().setSleepTimer(_wheelDuration);\n'
    '                    } else {\n'
    '                      context.read<RadioProvider>().setSleepTimer(\n'
    '                        _wheelDuration,\n'
    '                      );\n'
    '                    }\n',
    done='context.read<PodcastPlayer>().setSleepTimer(_wheelDuration);')

# ───────── podcast.dart: 타이머 ─────────
k = 'pod'
rep(k, '타이머 값',
    '  PodcastShow? lastShow; // 이어 듣기\n',
    '  // ── 수면 타이머 (라디오와 같게: 끝나기 1분 전부터 천천히 작게 → 멈춤) ──\n'
    '  Timer? _sleepTimer;\n'
    '  Timer? _sleepCountdown;\n'
    '  Duration? sleepRemaining;\n'
    '  final ValueNotifier<Duration?> sleepTick = ValueNotifier<Duration?>(null); // 남은 시간 글자만\n'
    '  bool _sleepFading = false;\n'
    '  bool get isSleepTimerActive => _sleepTimer != null;\n'
    '\n'
    '  PodcastShow? lastShow; // 이어 듣기\n',
    done='bool get isSleepTimerActive => _sleepTimer != null;')
rep(k, '음악·자연소리 틀면 타이머도 끄기',
    '      _savePos();\n      _mine = false;\n      _saveTick?.cancel();\n      notifyListeners();\n      return;\n',
    '      _savePos();\n      _mine = false;\n      _saveTick?.cancel();\n'
    '      cancelSleepTimer(); // 음악 쪽은 음악 타이머가 따로 있음\n'
    '      notifyListeners();\n      return;\n',
    done='cancelSleepTimer(); // 음악 쪽은 음악 타이머가 따로 있음')
rep(k, '타이머 켜기·끄기',
    '  static const speeds = [1.0, 1.25, 1.5, 2.0, 0.8];\n',
    '  void setSleepTimer(Duration d) {\n'
    '    cancelSleepTimer();\n'
    '    sleepRemaining = d;\n'
    '    sleepTick.value = d;\n'
    '    _sleepTimer = Timer(d, () async {\n'
    '      final p = _p;\n'
    '      if (p != null && active) {\n'
    '        await p.pause();\n'
    '        _savePos();\n'
    '      }\n'
    '      cancelSleepTimer(); // 소리 크기도 원래대로\n'
    '    });\n'
    '    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {\n'
    '      final r = sleepRemaining;\n'
    '      if (r == null || r.inSeconds <= 0) return;\n'
    '      sleepRemaining = r - const Duration(seconds: 1);\n'
    '      final left = sleepRemaining!.inSeconds;\n'
    '      // 끝나기 1분 전부터 천천히 작게 (뚝 끊겨서 잠이 깨지 않게)\n'
    '      if (left < 60 && active) {\n'
    '        _sleepFading = true;\n'
    '        _p?.setVolume((left / 60).clamp(0.0, 1.0).toDouble());\n'
    '      }\n'
    '      sleepTick.value = sleepRemaining;\n'
    "      if (left % 60 == 59) notifyListeners(); // 'N분' 표시는 분이 바뀔 때만\n"
    '    });\n'
    '    notifyListeners();\n'
    '  }\n'
    '\n'
    '  void cancelSleepTimer() {\n'
    '    if (_sleepTimer == null && _sleepCountdown == null) return;\n'
    '    if (_sleepFading) {\n'
    '      _sleepFading = false;\n'
    '      _p?.setVolume(1.0);\n'
    '    }\n'
    '    _sleepTimer?.cancel();\n'
    '    _sleepCountdown?.cancel();\n'
    '    _sleepTimer = null;\n'
    '    _sleepCountdown = null;\n'
    '    sleepRemaining = null;\n'
    '    sleepTick.value = null;\n'
    '    notifyListeners();\n'
    '  }\n'
    '\n'
    '  static const speeds = [1.0, 1.25, 1.5, 2.0, 0.8];\n',
    done='void setSleepTimer(Duration d) {')
rep(k, '미니플레이어 × 누르면 타이머도 끄기',
    '    _savePos();\n    _saveTick?.cancel();\n    final s = show, e = episode;\n',
    '    _savePos();\n    _saveTick?.cancel();\n    cancelSleepTimer();\n    final s = show, e = episode;\n',
    done='    _saveTick?.cancel();\n    cancelSleepTimer();\n')

# ───────── podcast_screens.dart: 재생 화면 버튼 + 남은 시간 줄 ─────────
k = 'screens'
rep(k, 'import', "import 'podcast.dart';\n",
    "import 'podcast.dart';\n"
    "import '../l10n/app_localizations.dart';\n"
    "import '../l10n/locale_holder.dart';\n"
    "import '../widgets/sleep_timer_sheet.dart';\n",
    done="import '../widgets/sleep_timer_sheet.dart';")
rep(k, "재생 화면 오른쪽 아래 '수면' 버튼",
    '                  icon: _SkipIcon(back: false, color: _text(dark), size: 34),\n'
    '                ),\n'
    '                const SizedBox(width: 70),\n',
    '                  icon: _SkipIcon(back: false, color: _text(dark), size: 34),\n'
    '                ),\n'
    '                const SizedBox(width: 6),\n'
    "                // 수면 타이머 (라디오 재생 화면 '수면' 버튼과 같게: 켜지면 남은 분)\n"
    '                SizedBox(\n'
    '                  width: 64,\n'
    '                  child: _PodSleepButton(dark: dark, pod: pod),\n'
    '                ),\n',
    done='child: _PodSleepButton(dark: dark, pod: pod),')
rep(k, "아래에 '12분 30초 후 종료 ×' 줄",
    '                const SizedBox(width: 6),\n'
    "                // 수면 타이머 (라디오 재생 화면 '수면' 버튼과 같게: 켜지면 남은 분)\n"
    '                SizedBox(\n'
    '                  width: 64,\n'
    '                  child: _PodSleepButton(dark: dark, pod: pod),\n'
    '                ),\n'
    '              ],\n'
    '            ),\n',
    '                const SizedBox(width: 6),\n'
    "                // 수면 타이머 (라디오 재생 화면 '수면' 버튼과 같게: 켜지면 남은 분)\n"
    '                SizedBox(\n'
    '                  width: 64,\n'
    '                  child: _PodSleepButton(dark: dark, pod: pod),\n'
    '                ),\n'
    '              ],\n'
    '            ),\n'
    "            // 수면 타이머 남은 시간 (라디오와 같은 줄 · 누르면 끄기)\n"
    '            const SizedBox(height: 14),\n'
    '            SizedBox(\n'
    '              height: 20,\n'
    '              child: ValueListenableBuilder<Duration?>(\n'
    '                valueListenable: pod.sleepTick,\n'
    '                builder: (_, d, __) => d == null ? const SizedBox.shrink() : _PodSleepBadge(remaining: d),\n'
    '              ),\n'
    '            ),\n',
    done='_PodSleepBadge(remaining: d)')

if 'class _PodSleepButton' not in D[k]['s']:
    D[k]['s'] = D[k]['s'].rstrip('\n') + '\n' + (
        '\n'
        "/// 재생 화면 '수면' 버튼 — 라디오 재생 화면 아래 버튼과 같은 모양 (아이콘 + 글자, 켜지면 진하게 · 남은 분)\n"
        'class _PodSleepButton extends StatelessWidget {\n'
        '  final bool dark;\n'
        '  final PodcastPlayer pod;\n'
        '  const _PodSleepButton({required this.dark, required this.pod});\n'
        '\n'
        '  @override\n'
        '  Widget build(BuildContext context) {\n'
        '    final strong = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n'
        '    final muted = dark ? const Color(0xFFB8B0A2) : const Color(0xFF5A5348);\n'
        '    final on = pod.isSleepTimerActive;\n'
        '    final left = pod.sleepRemaining;\n'
        '    return GestureDetector(\n'
        '      behavior: HitTestBehavior.opaque,\n'
        '      onTap: () {\n'
        '        _buzz();\n'
        '        showModalBottomSheet(\n'
        '          context: context,\n'
        '          backgroundColor: Colors.transparent,\n'
        '          barrierColor: Colors.black.withOpacity(0.7),\n'
        '          isScrollControlled: true,\n'
        '          useSafeArea: true,\n'
        '          builder: (_) => const SleepTimerSheet(podcast: true),\n'
        '        );\n'
        '      },\n'
        '      child: Padding(\n'
        '        padding: const EdgeInsets.symmetric(vertical: 4),\n'
        '        child: Column(\n'
        '          mainAxisSize: MainAxisSize.min,\n'
        '          children: [\n'
        '            Icon(Icons.bedtime_outlined, color: on ? strong : muted, size: 22),\n'
        '            const SizedBox(height: 4),\n'
        '            Text(\n'
        '                on && left != null ? tr.durM(left.inMinutes + 1) : AppLocalizations.of(context)!.radioSleep,\n'
        '                maxLines: 1,\n'
        '                overflow: TextOverflow.ellipsis,\n'
        '                style: TextStyle(\n'
        '                  color: on ? strong : muted,\n'
        '                  fontSize: 10.5,\n'
        '                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,\n'
        '                )),\n'
        '          ],\n'
        '        ),\n'
        '      ),\n'
        '    );\n'
        '  }\n'
        '}\n'
        '\n'
        "/// 수면 타이머 남은 시간 줄 — 라디오 재생 화면과 같은 모양 ('12분 30초 후 종료 ×', 누르면 끄기)\n"
        'class _PodSleepBadge extends StatelessWidget {\n'
        '  final Duration remaining;\n'
        '  const _PodSleepBadge({required this.remaining});\n'
        '\n'
        '  @override\n'
        '  Widget build(BuildContext context) {\n'
        '    final l = AppLocalizations.of(context)!;\n'
        '    final h = remaining.inHours;\n'
        '    final m = remaining.inMinutes.remainder(60);\n'
        '    final s = remaining.inSeconds.remainder(60);\n'
        '    final timeText = h > 0\n'
        '        ? l.sleepCountdownHMS(h, m, s)\n'
        '        : m > 0\n'
        '            ? l.sleepCountdownMS(m, s)\n'
        '            : l.sleepCountdownS(s);\n'
        '    final baseColor = context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black;\n'
        '    return GestureDetector(\n'
        '      onTap: () => PodcastPlayer.instance.cancelSleepTimer(),\n'
        '      child: Row(\n'
        '        mainAxisSize: MainAxisSize.min,\n'
        '        children: [\n'
        '          Icon(Icons.bedtime_outlined, color: baseColor.withOpacity(0.5), size: 13),\n'
        '          const SizedBox(width: 6),\n'
        '          Text(timeText, style: TextStyle(color: baseColor.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w600)),\n'
        '          const SizedBox(width: 3),\n'
        '          Text(l.radioAfterEnd, style: TextStyle(color: baseColor.withOpacity(0.4), fontSize: 11)),\n'
        '          const SizedBox(width: 6),\n'
        '          Icon(Icons.close, color: baseColor.withOpacity(0.35), size: 12),\n'
        '        ],\n'
        '      ),\n'
        '    );\n'
        '  }\n'
        '}\n')
    print('✔', name(k), '수면 버튼·남은 시간 줄 모양')
else:
    print('✔', name(k), '수면 버튼·남은 시간 줄 모양 (이미 돼 있음)')

for k in D:
    s = D[k]['s']
    if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
        fail(name(k) + ' 괄호가 안 맞아요')
changed = [k for k in D if D[k]['s'] != D[k]['orig']]
if not changed:
    print('이미 적용돼 있어요')
    sys.exit(0)
for k in changed:
    s = D[k]['s']
    if D[k]['crlf']:
        s = s.replace('\n', '\r\n')
    open(P[k], 'wb').write(s.encode('utf-8'))
print('저장했어요:', ', '.join(name(k) for k in changed))
