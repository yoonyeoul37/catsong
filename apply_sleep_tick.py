# -*- coding: utf-8 -*-
# 라디오 수면 타이머: 1초마다 '남은 시간 글자'만 바뀌게 (라디오 화면 전체가 1초마다 다시 그려지지 않게)
import sys, glob, os, shutil

def find(name):
    hits = [h for h in glob.glob(os.path.join('lib', '**', name), recursive=True) if os.path.basename(h) == name]
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    return hits[0]

def prepare(path, edits, done_mark):
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    name = os.path.basename(path)
    if done_mark in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); return None
    for label, old, new in edits:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name}: [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
        s = s.replace(old, new)
        print(f'✔ {name}: {label}')
    return (path, s, crlf)

prov = [
('남은 시간 따로 알리는 칸',
"  Timer? _sleepCountdown;\n",
"""  Timer? _sleepCountdown;
  /// 수면 타이머 남은 시간 (1초마다 바뀜). 이 값만 따로 알려서 화면 전체가 1초마다 다시 그려지지 않게
  final ValueNotifier<Duration?> sleepTick = ValueNotifier<Duration?>(null);
"""),
('타이머 시작',
"    _sleepRemaining = duration;\n",
"    _sleepRemaining = duration;\n    sleepTick.value = duration;\n"),
('1초마다: 남은 시간만, 분이 바뀔 때만 전체 알림',
"""        setAlarmVolume(left / 60);
      }
      notifyListeners();
    });
    notifyListeners();
  }""",
"""        setAlarmVolume(left / 60);
      }
      sleepTick.value = _sleepRemaining; // 남은 시간 글자만 바뀜
      if (left % 60 == 59) notifyListeners(); // 'N분' 표시는 분이 바뀔 때만
    });
    notifyListeners();
  }"""),
('타이머 끄기',
"""    _sleepTimer = null;
    _sleepCountdown = null;
    _sleepRemaining = null;
    notifyListeners();
  }

  void addSchedule(""",
"""    _sleepTimer = null;
    _sleepCountdown = null;
    _sleepRemaining = null;
    sleepTick.value = null;
    notifyListeners();
  }

  void addSchedule("""),
]

player = [
('재생 화면 남은 시간: 글자만 1초마다',
"                      if (sleep != null) _SleepTimerBadge(remaining: sleep),\n",
"""                      if (sleep != null)
                        ValueListenableBuilder<Duration?>(
                          valueListenable: radioProvider.sleepTick,
                          builder: (_, d, __) =>
                              d == null ? const SizedBox.shrink() : _SleepTimerBadge(remaining: d),
                        ),
"""),
]

sheet = [
('수면 타이머 창 남은 시간: 글자만 1초마다',
"""              Text(
                _formatCountdown(sleep),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                ),
              ),""",
"""              ValueListenableBuilder<Duration?>(
                valueListenable: radioProvider.sleepTick,
                builder: (_, d, __) => Text(
                  _formatCountdown(d ?? sleep),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 52,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                  ),
                ),
              ),"""),
]

jobs = [
    prepare(find('radio_provider.dart'), prov, 'sleepTick'),
    prepare(find('radio_player_screen.dart'), player, 'sleepTick'),
    prepare(find('sleep_timer_sheet.dart'), sheet, 'sleepTick'),
]
for r in jobs:   # 모두 문제없을 때만 저장
    if r is None: continue
    path, s, crlf = r
    shutil.copy(path, path + '.bak_sleep')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_sleep)')
