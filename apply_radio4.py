# 파란소리: 라디오 예약 창 새 디자인 (내 예약 + 새 예약 1·2단계)
# 실행: C:\apps\mp3_player_new 에서  python apply_radio4.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_radio4 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "widgets/schedule_sheet.dart", "import 'paran_toast.dart';\n", "import 'paran_toast.dart';\nimport 'paran_dialog.dart';\nimport 'package:flutter/services.dart';\n"], ["func", "widgets/schedule_sheet.dart", "class _ScheduleSheetState extends State<ScheduleSheet>", "class _ScheduleSheetState extends State<ScheduleSheet> {\n  TimeOfDay? _selectedTime;\n  RadioStation? _selectedStation;\n\n  // 화면 공통 색\n  static const _bg = Color(0xFFF4EFE5);\n  static const _ink = Color(0xFF17140F);\n  static const _sub = Color(0xFF8A8378);\n  static const _line = Color(0xFFE2DACB);\n\n  void _vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n\n  /// 지금부터 그 시간까지 남은 시간 (\"2시간 뒤\", \"35분 뒤\")\n  String _until(TimeOfDay t) {\n    final now = DateTime.now();\n    var target = DateTime(now.year, now.month, now.day, t.hour, t.minute);\n    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));\n    final d = target.difference(now);\n    if (d.inMinutes < 60) return '${d.inMinutes}분 뒤';\n    final h = d.inHours;\n    final m = d.inMinutes % 60;\n    return m == 0 ? '$h시간 뒤' : '$h시간 $m분 뒤';\n  }\n\n  TimeOfDay _after(int minutes) {\n    final t = DateTime.now().add(Duration(minutes: minutes));\n    return TimeOfDay(hour: t.hour, minute: t.minute);\n  }\n\n  Future<void> _pickTime() async {\n    _vib();\n    final time = await showTimePicker(\n      context: context,\n      initialTime: _selectedTime ?? TimeOfDay.now(),\n      builder: (context, child) => Theme(\n        data: Theme.of(context).copyWith(\n          colorScheme: const ColorScheme.light(primary: _ink, onPrimary: _bg, surface: _bg, onSurface: _ink),\n        ),\n        child: child!,\n      ),\n    );\n    if (time != null) setState(() => _selectedTime = time);\n  }\n\n  Widget _step(int n, String text) => Padding(\n        padding: const EdgeInsets.only(bottom: 8),\n        child: Row(\n          children: [\n            Container(\n              width: 18,\n              height: 18,\n              alignment: Alignment.center,\n              decoration: const BoxDecoration(color: _ink, shape: BoxShape.circle),\n              child: Text('$n', style: const TextStyle(color: _bg, fontSize: 10.5, fontWeight: FontWeight.w700)),\n            ),\n            const SizedBox(width: 8),\n            Text(text, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),\n          ],\n        ),\n      );\n\n  Widget _quick(String label, TimeOfDay t) {\n    final on = _selectedTime == t;\n    return Expanded(\n      child: GestureDetector(\n        onTap: () {\n          _vib();\n          setState(() => _selectedTime = t);\n        },\n        child: Container(\n          padding: const EdgeInsets.symmetric(vertical: 8),\n          alignment: Alignment.center,\n          decoration: BoxDecoration(color: on ? _ink : _bg, borderRadius: BorderRadius.circular(10)),\n          child: Text(label,\n              style: TextStyle(color: on ? _bg : const Color(0xFF5A5348), fontSize: 12, fontWeight: FontWeight.w600)),\n        ),\n      ),\n    );\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final radioProvider = context.watch<RadioProvider>();\n    final schedules = radioProvider.schedules;\n    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;\n    final stationList = radioProvider.currentQueue.isNotEmpty\n        ? radioProvider.currentQueue\n        : radioProvider.recentlyListened;\n    final canAdd = schedules.length < 5;\n\n    Widget section(String text, {Widget? right}) => Padding(\n          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),\n          child: Row(\n            children: [\n              Expanded(child: Text(text, style: const TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w600))),\n              if (right != null) right,\n            ],\n          ),\n        );\n\n    return Container(\n      decoration: const BoxDecoration(\n        color: _bg,\n        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),\n      ),\n      padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomPadding),\n      child: SingleChildScrollView(\n        child: Column(\n          mainAxisSize: MainAxisSize.min,\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Center(\n              child: Container(\n                width: 36,\n                height: 4,\n                decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2)),\n              ),\n            ),\n            const SizedBox(height: 14),\n            // 위: 제목 · 개수\n            Padding(\n              padding: const EdgeInsets.symmetric(horizontal: 4),\n              child: Row(\n                crossAxisAlignment: CrossAxisAlignment.end,\n                children: [\n                  const Expanded(\n                    child: Text('예약',\n                        style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                  ),\n                  Text('${schedules.length} / 5', style: const TextStyle(color: _sub, fontSize: 12.5)),\n                ],\n              ),\n            ),\n            const Padding(\n              padding: EdgeInsets.fromLTRB(4, 4, 4, 0),\n              child: Text('정한 시간이 되면 그 방송으로 바꿔줘요', style: TextStyle(color: _sub, fontSize: 12.5)),\n            ),\n\n            // ───── 내 예약 ─────\n            if (schedules.isNotEmpty) ...[\n              section('내 예약',\n                  right: GestureDetector(\n                    onTap: () async {\n                      final ok = await showParanConfirm(context,\n                          title: '예약을 전부 취소할까요?', confirmLabel: '전체 취소', danger: true);\n                      if (!ok || !context.mounted) return;\n                      radioProvider.clearSchedules();\n                      showActionFeedback(context, type: ActionFeedbackType.deleted, message: '예약을 취소했어요');\n                    },\n                    child: const Text('전체 취소',\n                        style: TextStyle(color: Color(0xFFE05A4F), fontSize: 12, fontWeight: FontWeight.w600)),\n                  )),\n              Container(\n                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),\n                child: Column(\n                  children: [\n                    for (var i = 0; i < schedules.length; i++) ...[\n                      if (i > 0) Container(height: 0.5, color: const Color(0xFFEEE9DF)),\n                      Opacity(\n                        opacity: schedules[i].triggered ? 0.45 : 1,\n                        child: Padding(\n                          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),\n                          child: Row(\n                            children: [\n                              SizedBox(\n                                width: 68,\n                                child: Column(\n                                  crossAxisAlignment: CrossAxisAlignment.start,\n                                  children: [\n                                    Text(schedules[i].time.period == DayPeriod.am ? '오전' : '오후',\n                                        style: const TextStyle(color: _sub, fontSize: 10.5, fontWeight: FontWeight.w600)),\n                                    Text(\n                                        '${schedules[i].time.hourOfPeriod == 0 ? 12 : schedules[i].time.hourOfPeriod}:${schedules[i].time.minute.toString().padLeft(2, '0')}',\n                                        style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),\n                                  ],\n                                ),\n                              ),\n                              Expanded(\n                                child: Column(\n                                  crossAxisAlignment: CrossAxisAlignment.start,\n                                  children: [\n                                    Text(schedules[i].station.name,\n                                        maxLines: 1,\n                                        overflow: TextOverflow.ellipsis,\n                                        style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600)),\n                                    const SizedBox(height: 2),\n                                    Text(schedules[i].triggered ? '바꿨어요 ✓' : _until(schedules[i].time),\n                                        style: const TextStyle(color: _sub, fontSize: 11.5)),\n                                  ],\n                                ),\n                              ),\n                              IconButton(\n                                onPressed: () {\n                                  _vib();\n                                  radioProvider.removeSchedule(i);\n                                },\n                                icon: const Icon(Icons.close_rounded, color: Color(0xFFB5AC9C), size: 20),\n                              ),\n                            ],\n                          ),\n                        ),\n                      ),\n                    ],\n                  ],\n                ),\n              ),\n            ],\n\n            // ───── 새 예약 (1 시간 → 2 방송) ─────\n            if (canAdd) ...[\n              section('새 예약'),\n              Container(\n                padding: const EdgeInsets.all(12),\n                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    _step(1, '몇 시에?'),\n                    // 시간 칸: 누르면 시계로 직접 맞추기\n                    GestureDetector(\n                      onTap: _pickTime,\n                      child: Container(\n                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),\n                        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),\n                        child: Row(\n                          children: [\n                            Expanded(\n                              child: Text(\n                                _selectedTime != null ? _formatTime(_selectedTime!) : '시간 고르기',\n                                style: TextStyle(\n                                  color: _selectedTime != null ? _ink : _sub,\n                                  fontSize: _selectedTime != null ? 22 : 15,\n                                  fontWeight: _selectedTime != null ? FontWeight.w800 : FontWeight.w500,\n                                ),\n                              ),\n                            ),\n                            const Icon(Icons.schedule_rounded, color: _sub, size: 20),\n                          ],\n                        ),\n                      ),\n                    ),\n                    const SizedBox(height: 8),\n                    Row(\n                      children: [\n                        _quick('30분 뒤', _after(30)),\n                        const SizedBox(width: 6),\n                        _quick('1시간 뒤', _after(60)),\n                        const SizedBox(width: 6),\n                        _quick('아침 7시', const TimeOfDay(hour: 7, minute: 0)),\n                      ],\n                    ),\n                    const SizedBox(height: 14),\n                    _step(2, '어떤 방송?'),\n                    if (stationList.isEmpty)\n                      Padding(\n                        padding: const EdgeInsets.symmetric(vertical: 8),\n                        child: Text(AppLocalizations.of(context)!.radioPlayFirst,\n                            style: const TextStyle(color: _sub, fontSize: 12.5)),\n                      )\n                    else\n                      SizedBox(\n                        height: 38,\n                        child: ListView.separated(\n                          scrollDirection: Axis.horizontal,\n                          itemCount: stationList.length,\n                          separatorBuilder: (_, __) => const SizedBox(width: 6),\n                          itemBuilder: (_, i) {\n                            final st = stationList[i];\n                            final on = _selectedStation?.name == st.name;\n                            return GestureDetector(\n                              onTap: () {\n                                _vib();\n                                setState(() => _selectedStation = st);\n                              },\n                              child: Container(\n                                padding: const EdgeInsets.symmetric(horizontal: 12),\n                                alignment: Alignment.center,\n                                decoration: BoxDecoration(color: on ? _ink : _bg, borderRadius: BorderRadius.circular(12)),\n                                child: Text(st.name,\n                                    style: TextStyle(\n                                        color: on ? Colors.white : const Color(0xFF5A5348),\n                                        fontSize: 12.5,\n                                        fontWeight: on ? FontWeight.w700 : FontWeight.w500)),\n                              ),\n                            );\n                          },\n                        ),\n                      ),\n                    // 편성표에서 프로그램으로 고르기 (방송을 먼저 고르면)\n                    if (stationList.isNotEmpty)\n                      GestureDetector(\n                        onTap: () {\n                          final st = _selectedStation ?? stationList.first;\n                          showModalBottomSheet(\n                            context: context,\n                            backgroundColor: Colors.transparent,\n                            isScrollControlled: true,\n                            builder: (_) => _ScheduleListBottomSheet(stationName: st.name),\n                          );\n                        },\n                        child: const Padding(\n                          padding: EdgeInsets.only(top: 10),\n                          child: Row(\n                            children: [\n                              Icon(Icons.format_list_bulleted_rounded, color: _sub, size: 16),\n                              SizedBox(width: 5),\n                              Text('편성표에서 프로그램으로 고르기',\n                                  style: TextStyle(color: _sub, fontSize: 12, decoration: TextDecoration.underline)),\n                            ],\n                          ),\n                        ),\n                      ),\n                  ],\n                ),\n              ),\n              const SizedBox(height: 12),\n              SizedBox(\n                width: double.infinity,\n                height: 50,\n                child: ElevatedButton(\n                  onPressed: _selectedTime != null && _selectedStation != null\n                      ? () {\n                          _vib();\n                          radioProvider.addSchedule(_selectedTime!, _selectedStation!);\n                          setState(() {\n                            _selectedTime = null;\n                            _selectedStation = null;\n                          });\n                          showActionFeedback(context,\n                              type: ActionFeedbackType.saved, message: '예약했어요', icon: Icons.schedule_rounded);\n                        }\n                      : null,\n                  style: ElevatedButton.styleFrom(\n                    backgroundColor: _ink,\n                    foregroundColor: _bg,\n                    disabledBackgroundColor: _ink.withOpacity(0.25),\n                    disabledForegroundColor: _bg,\n                    elevation: 6,\n                    shadowColor: Colors.black.withOpacity(0.25),\n                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                  ),\n                  child: const Text('예약하기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),\n                ),\n              ),\n            ] else\n              const Padding(\n                padding: EdgeInsets.fromLTRB(4, 14, 4, 0),\n                child: Text('예약은 5개까지예요. 지난 예약을 지우면 새로 넣을 수 있어요',\n                    style: TextStyle(color: _sub, fontSize: 12.5)),\n              ),\n          ],\n        ),\n      ),\n    );\n  }\n\n  String _formatTime(TimeOfDay time) {\n    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;\n    final m = time.minute.toString().padLeft(2, '0');\n    final period = time.period == DayPeriod.am ? '오전' : '오후';\n    return '$period $h:$m';\n  }\n}"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_radio4")

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
    print("   문제가 있으면 backup_radio4 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
