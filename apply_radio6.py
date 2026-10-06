# 파란소리: 라디오 하단바 새 디자인 (C3: 지금 프로그램 한 줄 + 수면 남은 시간 · 예약 개수)
# 실행: C:\apps\mp3_player_new 에서  python apply_radio6.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_radio6 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "screens/radio_player_screen.dart", "            Container(\n              height: 2.5,\n              color: baseColor.withOpacity(0.20),\n            ),\n            Container(\n              decoration: BoxDecoration(\n                color: baseColor.withOpacity(0.03),\n                border: Border(top: BorderSide(color: baseColor.withOpacity(0.06))),\n              ),\n              child: SafeArea(\n                top: false,\n                child: Padding(\n                  padding: const EdgeInsets.symmetric(vertical: 2),\n                  child: Row(", "            // 하단바: 바닥에 붙은 미니멀 (베이지 · 얇은 선)\n            Container(\n              decoration: BoxDecoration(\n                color: isDarkMode ? const Color(0xFF17140F) : const Color(0xFFF4EFE5),\n                border: Border(\n                    top: BorderSide(\n                        color: isDarkMode ? const Color(0xFF3A342B) : const Color(0xFFE2DACB), width: 0.5)),\n              ),\n              child: SafeArea(\n                top: false,\n                child: Padding(\n                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),\n                  child: Column(mainAxisSize: MainAxisSize.min, children: [\n                  // 지금 프로그램 한 줄 (한국 방송일 때)\n                  if (_isKoreanBroadcast(current.name)) const _NowProgramStrip(),\n                  Row("], ["str", "screens/radio_player_screen.dart", "                    ],\n                  ),\n                ),\n              ),\n            ),\n          ],\n        ),\n      ),\n      body: Stack(", "                    ],\n                  ),\n                  ]),\n                ),\n              ),\n            ),\n          ],\n        ),\n      ),\n      body: Stack("], ["str", "screens/radio_player_screen.dart", "                                hasIndicator: radioProvider.scheduleList.isNotEmpty,", "                                hasIndicator: false,"], ["str", "screens/radio_player_screen.dart", "                              label: AppLocalizations.of(context)!.radioSleep,\n                              hasIndicator: radioProvider.isSleepTimerActive,", "                              // 켜져 있으면 \"수면\" 대신 남은 시간 (예: 28분)\n                              label: radioProvider.isSleepTimerActive && radioProvider.sleepRemaining != null\n                                  ? '${radioProvider.sleepRemaining!.inMinutes + 1}분'\n                                  : AppLocalizations.of(context)!.radioSleep,\n                              hasIndicator: radioProvider.isSleepTimerActive,"], ["str", "screens/radio_player_screen.dart", "                              hasIndicator: radioProvider.schedules.isNotEmpty,", "                              hasIndicator: false,\n                              badge: radioProvider.schedules.where((s) => !s.triggered).length, // 예약 개수"], ["str", "screens/radio_player_screen.dart", "                              const Icon(Icons.power_settings_new, color: Color(0xFFE8877E), size: 22),", "                              Icon(Icons.power_settings_new_rounded, color: baseColor.withOpacity(0.55), size: 22),"], ["str", "screens/radio_player_screen.dart", "                                style: const TextStyle(color: Color(0xFFE8877E), fontSize: 10, fontWeight: FontWeight.w600),", "                                style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 10.5, fontWeight: FontWeight.w500),"], ["func", "screens/radio_player_screen.dart", "class _BottomBarItem extends StatelessWidget", "class _BottomBarItem extends StatelessWidget {\n  final IconData icon;\n  final String label;\n  final bool hasIndicator; // 켜져 있으면 진하게 (예: 수면 타이머)\n  final Color primaryColor;\n  final VoidCallback onTap;\n  final int badge; // 작은 숫자 (예: 예약 2개)\n\n  const _BottomBarItem({\n    required this.icon,\n    required this.label,\n    required this.hasIndicator,\n    required this.primaryColor,\n    required this.onTap,\n    this.badge = 0,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    final isDark = context.watch<ThemeProvider>().isDarkMode;\n    final strong = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n    final muted = isDark ? const Color(0xFFA29A8B) : const Color(0xFF5A5348);\n    final on = hasIndicator;\n    return GestureDetector(\n      onTap: onTap,\n      behavior: HitTestBehavior.opaque,\n      child: Padding(\n        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),\n        child: Stack(\n          clipBehavior: Clip.none,\n          children: [\n            Column(\n              mainAxisSize: MainAxisSize.min,\n              children: [\n                Icon(icon, color: on ? strong : muted, size: 22),\n                const SizedBox(height: 4),\n                Text(label,\n                    style: TextStyle(\n                      color: on ? strong : muted,\n                      fontSize: 10.5,\n                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,\n                    )),\n              ],\n            ),\n            if (badge > 0)\n              Positioned(\n                right: -7,\n                top: -4,\n                child: Container(\n                  constraints: const BoxConstraints(minWidth: 15),\n                  height: 15,\n                  padding: const EdgeInsets.symmetric(horizontal: 4),\n                  alignment: Alignment.center,\n                  decoration: BoxDecoration(color: strong, borderRadius: BorderRadius.circular(8)),\n                  child: Text('$badge',\n                      style: TextStyle(\n                          color: isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5),\n                          fontSize: 9.5,\n                          fontWeight: FontWeight.w700)),\n                ),\n              ),\n          ],\n        ),\n      ),\n    );\n  }\n}\n\n/// 하단바 위: 지금 프로그램 한 줄 (● 이름 · N분 남음 + 얇은 진행 막대)\nclass _NowProgramStrip extends StatefulWidget {\n  const _NowProgramStrip();\n\n  @override\n  State<_NowProgramStrip> createState() => _NowProgramStripState();\n}\n\nclass _NowProgramStripState extends State<_NowProgramStrip> {\n  Timer? _tick;\n\n  @override\n  void initState() {\n    super.initState();\n    // 남은 시간이 맞게 30초마다 다시 그리기\n    _tick = Timer.periodic(const Duration(seconds: 30), (_) {\n      if (mounted) setState(() {});\n    });\n  }\n\n  @override\n  void dispose() {\n    _tick?.cancel();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final radioProvider = context.watch<RadioProvider>();\n    final isDark = context.watch<ThemeProvider>().isDarkMode;\n    final strong = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n    final muted = isDark ? const Color(0xFFA29A8B) : const Color(0xFF5A5348);\n    final line = isDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);\n\n    final now = DateTime.now();\n    final nowM = _ScheduleListSheet._wrap(now.hour * 60 + now.minute);\n    String? title;\n    int? start, end;\n    for (final s in radioProvider.scheduleList) {\n      final t = (s['program_title'] ?? s['Title'] ?? s['title'] ?? '').toString();\n      final a = _ScheduleListSheet._mins((s['program_planned_start_time'] ?? s['StartTime'] ?? s['start_time'] ?? '').toString());\n      if (t.isEmpty || a == null) continue;\n      final b = _ScheduleListSheet._mins((s['program_planned_end_time'] ?? s['EndTime'] ?? s['end_time'] ?? '').toString()) ?? a + 60;\n      final ws = _ScheduleListSheet._wrap(a);\n      var we = _ScheduleListSheet._wrap(b);\n      if (we <= ws) we += 1440;\n      if (ws <= nowM && nowM < we) {\n        title = t;\n        start = ws;\n        end = we;\n        break;\n      }\n    }\n    if (title == null || start == null || end == null) return const SizedBox(height: 4);\n\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),\n      child: Column(\n        mainAxisSize: MainAxisSize.min,\n        children: [\n          Row(\n            children: [\n              Container(\n                width: 6,\n                height: 6,\n                decoration: const BoxDecoration(color: Color(0xFFFF6B5E), shape: BoxShape.circle),\n              ),\n              const SizedBox(width: 7),\n              Expanded(\n                child: Text(title,\n                    maxLines: 1,\n                    overflow: TextOverflow.ellipsis,\n                    style: TextStyle(color: strong, fontSize: 12, fontWeight: FontWeight.w700)),\n              ),\n              const SizedBox(width: 8),\n              Text('${end - nowM}분 남음', style: TextStyle(color: muted, fontSize: 11.5)),\n            ],\n          ),\n          const SizedBox(height: 7),\n          ClipRRect(\n            borderRadius: BorderRadius.circular(1),\n            child: LinearProgressIndicator(\n              value: ((nowM - start) / (end - start)).clamp(0.0, 1.0),\n              minHeight: 2,\n              backgroundColor: line,\n              color: strong,\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_radio6")

def func_span(s, sig):
    i = s.find(sig)
    if i < 0 or s.find(sig, i + 1) >= 0:
        return None
    j = s.find("{", i + len(sig))
    if j < 0:
        return None
    depth = 0
    k = j
    while k < len(s):
        c = s[k]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return (i, k + 1)
        k += 1
    return None

def main():
    if not os.path.isdir(LIB):
        print("[실패] lib 폴더를 못 찾았어요. 이 파일을 C:\\apps\\mp3_player_new 에 두고 실행해 주세요.")
        sys.exit(1)
    texts, newlines, problems = {}, {}, []
    for op in DATA["ops"]:
        kind, rel = op[0], op[1]
        if rel not in texts:
            p = os.path.join(LIB, rel)
            if not os.path.exists(p):
                problems.append(f"{rel}: 파일이 없어요")
                continue
            with open(p, "r", encoding="utf-8", newline="") as fh:
                raw = fh.read()
            newlines[rel] = "\r\n" if "\r\n" in raw else "\n"
            texts[rel] = raw.replace("\r\n", "\n")
    if not problems:
        # 미리 해보기 (진짜 파일은 아직 안 바꿈)
        trial = dict(texts)
        for op in DATA["ops"]:
            kind, rel = op[0], op[1]
            a = op[2]
            b = op[3] if len(op) > 3 else None
            s = trial[rel]
            if kind == "str":
                n = s.count(a)
                if n != 1:
                    problems.append(f"{rel}: '{a.strip().splitlines()[0][:60]}' → {n}군데 (1군데여야 해요)")
                    continue
                trial[rel] = s.replace(a, b, 1)
            elif kind == "strall":
                n = s.count(a)
                if n < 1:
                    problems.append(f"{rel}: '{a.strip().splitlines()[0][:60]}' 를 못 찾았어요")
                    continue
                trial[rel] = s.replace(a, b)
            elif kind == "region":
                key, start, end, repl = op[2], op[3], op[4], op[5]
                ki = s.find(key)
                if ki < 0 or s.find(key, ki + 1) >= 0:
                    problems.append(f"{rel}: '{key[:50]}' 를 못 찾았어요")
                    continue
                si = s.rfind(start, 0, ki)
                ei = s.find(end, ki)
                if si < 0 or ei < 0:
                    problems.append(f"{rel}: '{key[:50]}' 주변을 못 찾았어요")
                    continue
                ls = s.rfind("\n", 0, si) + 1
                indent = s[ls:si]
                le = s.find("\n", ei)
                le = len(s) if le < 0 else le + 1
                trial[rel] = s[:ls] + indent + repl + "\n" + s[le:]
            else:
                span = func_span(s, a)
                if span is None:
                    problems.append(f"{rel}: 함수 '{a.strip()[:60]}' 를 못 찾았어요")
                    continue
                trial[rel] = s[:span[0]] + b + s[span[1]:]
    if problems:
        print("[실패] 아래 곳을 못 찾아서 아무것도 안 바꿨어요. 이 내용을 그대로 보내주세요:")
        for p in problems:
            print("   -", p)
        sys.exit(1)

    os.makedirs(BACKUP, exist_ok=True)
    for rel in texts:
        dst = os.path.join(BACKUP, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(os.path.join(LIB, rel), dst)
    for rel, s in trial.items():
        with open(os.path.join(LIB, rel), "w", encoding="utf-8", newline="") as fh:
            fh.write(s.replace("\n", "\r\n") if newlines[rel] == "\r\n" else s)
        print("[완료] 바꿨어요:", rel)
    for rel, content in DATA["new"].items():
        p = os.path.join(LIB, rel)
        if os.path.exists(p):
            print("[참고] 이미 있어서 그대로 둬요:", rel)
            continue
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8", newline="") as fh:
            fh.write(content.replace("\n", "\r\n"))
        print("[완료] 새로 만들었어요:", rel)
    print("\n[끝] 끝! 이제  flutter run  으로 확인해 주세요.")
    print("   문제가 있으면 backup_radio6 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
