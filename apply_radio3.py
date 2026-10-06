# 파란소리: 라디오 편성표 새 디자인 (타임라인 + 지금 방송 중 + 🔔 예약)
# 실행: C:\apps\mp3_player_new 에서  python apply_radio3.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_radio3 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["func", "screens/radio_player_screen.dart", "class _ScheduleListSheet extends StatelessWidget", "class _ScheduleListSheet extends StatelessWidget {\n  final String stationName;\n  const _ScheduleListSheet({required this.stationName});\n\n  // 화면 공통 색\n  static const _bg = Color(0xFFF4EFE5);\n  static const _ink = Color(0xFF17140F);\n  static const _sub = Color(0xFF8A8378);\n  static const _line = Color(0xFFE2DACB);\n\n  /// 시간 글자 → 하루 중 몇 분 (14:00 → 840). 못 읽으면 null\n  static int? _mins(String t) {\n    t = t.trim();\n    if (t.isEmpty) return null;\n    int h, m;\n    if (t.contains(':')) {\n      final p = t.split(':');\n      h = int.tryParse(p[0]) ?? -1;\n      m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;\n    } else {\n      final d = t.replaceAll(RegExp(r'[^0-9]'), '');\n      if (d.length >= 12 && d.startsWith('20')) {\n        // 20231015160000 처럼 날짜가 붙은 것\n        h = int.tryParse(d.substring(8, 10)) ?? -1;\n        m = int.tryParse(d.substring(10, 12)) ?? 0;\n      } else if (d.length >= 4) {\n        h = int.tryParse(d.substring(0, 2)) ?? -1;\n        m = int.tryParse(d.substring(2, 4)) ?? 0;\n      } else {\n        return null;\n      }\n    }\n    if (h < 0) return null;\n    if (h >= 24) h -= 24;\n    return h * 60 + m;\n  }\n\n  static String _hm(int mins) {\n    final x = mins % 1440;\n    return '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';\n  }\n\n  /// 새벽(0~6시)은 하루의 맨 끝으로 (편성표 순서)\n  static int _wrap(int mins) => mins < 360 ? mins + 1440 : mins;\n\n  static String _part(int mins) {\n    final h = (mins % 1440) ~/ 60;\n    if (h < 6) return '새벽';\n    if (h < 12) return '아침';\n    if (h < 18) return '오후';\n    return '저녁 · 밤';\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final radioProvider = context.watch<RadioProvider>();\n    final station = radioProvider.currentStation;\n    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;\n\n    // 편성표 정리: 제목 · 시작 · 끝\n    final items = <({String title, int start, int end})>[];\n    for (final s in radioProvider.scheduleList) {\n      String title = (s['program_title'] ?? s['Title'] ?? s['title'] ?? '').toString();\n      String st = (s['program_planned_start_time'] ?? s['StartTime'] ?? s['start_time'] ?? '').toString();\n      String en = (s['program_planned_end_time'] ?? s['EndTime'] ?? s['end_time'] ?? '').toString();\n      final a = _mins(st);\n      if (title.isEmpty || a == null) continue;\n      var b = _mins(en) ?? (a + 60);\n      var ws = _wrap(a);\n      var we = _wrap(b);\n      if (we <= ws) we += 1440;\n      items.add((title: title, start: ws, end: we));\n    }\n    items.sort((x, y) => x.start.compareTo(y.start));\n\n    final now = DateTime.now();\n    final nowM = _wrap(now.hour * 60 + now.minute);\n    final current = items.where((e) => e.start <= nowM && nowM < e.end).toList();\n    final cur = current.isEmpty ? null : current.first;\n    final upcoming = items.where((e) => e.start > nowM).toList();\n    final nextStart = upcoming.isEmpty ? null : upcoming.first.start;\n\n    bool reserved(int mins) =>\n        station != null &&\n        radioProvider.schedules.any((s) =>\n            s.time.hour == (mins % 1440) ~/ 60 &&\n            s.time.minute == (mins % 1440) % 60 &&\n            s.station.stationUuid == station.stationUuid);\n\n    void reserve(int mins) {\n      if (station == null || reserved(mins)) return;\n      final before = radioProvider.schedules.length;\n      radioProvider.addSchedule(TimeOfDay(hour: (mins % 1440) ~/ 60, minute: (mins % 1440) % 60), station);\n      if (radioProvider.schedules.length > before) {\n        showActionFeedback(context, type: ActionFeedbackType.saved, message: '예약했어요', icon: Icons.notifications_active_rounded);\n      } else {\n        showParanToast(context, '예약을 더 넣을 수 없어요. 예약 창에서 지난 예약을 지워주세요');\n      }\n    }\n\n    // 목록: 시간대(아침·오후…)마다 작은 제목\n    final rows = <Widget>[];\n    String? lastPart;\n    for (final e in items) {\n      if (cur != null && e == cur) continue; // 지금 방송은 위 먹색 카드에\n      final part = _part(e.start);\n      if (part != lastPart) {\n        rows.add(Padding(\n          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),\n          child: Text(part, style: const TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600)),\n        ));\n        lastPart = part;\n      }\n      final past = e.end <= nowM;\n      final isNext = e.start == nextStart;\n      final done = reserved(e.start);\n      rows.add(Opacity(\n        opacity: past ? 0.45 : 1,\n        child: IntrinsicHeight(\n          child: Row(\n            crossAxisAlignment: CrossAxisAlignment.stretch,\n            children: [\n              // 세로 줄 + 점 (타임라인)\n              SizedBox(\n                width: 16,\n                child: Stack(\n                  alignment: Alignment.center,\n                  children: [\n                    Container(width: 1.5, color: _line),\n                    Container(\n                      width: 8,\n                      height: 8,\n                      decoration: BoxDecoration(color: isNext ? _ink : _line, shape: BoxShape.circle),\n                    ),\n                  ],\n                ),\n              ),\n              const SizedBox(width: 8),\n              Expanded(\n                child: Padding(\n                  padding: const EdgeInsets.symmetric(vertical: 9),\n                  child: Row(\n                    children: [\n                      SizedBox(\n                        width: 46,\n                        child: Text(_hm(e.start),\n                            style: const TextStyle(\n                                color: _sub, fontSize: 12.5, fontFeatures: [FontFeature.tabularFigures()])),\n                      ),\n                      Expanded(\n                        child: Text(e.title,\n                            maxLines: 1,\n                            overflow: TextOverflow.ellipsis,\n                            style: TextStyle(\n                                color: _ink, fontSize: 14, fontWeight: isNext ? FontWeight.w700 : FontWeight.w500)),\n                      ),\n                      if (isNext) ...[\n                        const SizedBox(width: 6),\n                        Container(\n                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),\n                          decoration: BoxDecoration(\n                            color: Colors.white,\n                            borderRadius: BorderRadius.circular(8),\n                            border: Border.all(color: _line),\n                          ),\n                          child: const Text('다음',\n                              style: TextStyle(color: _ink, fontSize: 10.5, fontWeight: FontWeight.w700)),\n                        ),\n                      ],\n                      // 🔔 이 시간에 예약 (지난 방송은 없음)\n                      if (!past)\n                        IconButton(\n                          onPressed: () {\n                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                            reserve(e.start);\n                          },\n                          visualDensity: VisualDensity.compact,\n                          icon: Icon(\n                            done ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,\n                            color: done ? _ink : _sub,\n                            size: 20,\n                          ),\n                        )\n                      else\n                        const SizedBox(width: 40),\n                    ],\n                  ),\n                ),\n              ),\n            ],\n          ),\n        ),\n      ));\n    }\n\n    return Container(\n      decoration: const BoxDecoration(\n        color: _bg,\n        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),\n      ),\n      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),\n      child: Column(\n        mainAxisSize: MainAxisSize.min,\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Center(\n            child: Container(\n              width: 36,\n              height: 4,\n              decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2)),\n            ),\n          ),\n          const SizedBox(height: 14),\n          // 위: 방송국 + 오늘 날짜\n          Row(\n            children: [\n              Container(\n                width: 40,\n                height: 40,\n                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),\n                child: const Icon(Icons.radio_rounded, color: _sub, size: 22),\n              ),\n              const SizedBox(width: 10),\n              Expanded(\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    Text(AppLocalizations.of(context)!.radioScheduleTitle(stationName),\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: const TextStyle(color: _ink, fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                    const SizedBox(height: 2),\n                    Text('오늘 · ${now.month}월 ${now.day}일 ${const ['월', '화', '수', '목', '금', '토', '일'][now.weekday - 1]}요일',\n                        style: const TextStyle(color: _sub, fontSize: 12)),\n                  ],\n                ),\n              ),\n            ],\n          ),\n          const SizedBox(height: 12),\n          if (items.isEmpty)\n            Padding(\n              padding: const EdgeInsets.symmetric(vertical: 36),\n              child: Center(\n                child: Text(AppLocalizations.of(context)!.radioLoadingSchedule,\n                    style: const TextStyle(color: _sub, fontSize: 13)),\n              ),\n            )\n          else ...[\n            // 지금 방송 중 (먹색 카드)\n            if (cur != null)\n              Container(\n                width: double.infinity,\n                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),\n                decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(16)),\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    Container(\n                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),\n                      decoration: BoxDecoration(\n                          color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),\n                      child: Row(\n                        mainAxisSize: MainAxisSize.min,\n                        children: [\n                          Container(\n                              width: 6,\n                              height: 6,\n                              decoration: const BoxDecoration(color: Color(0xFFFF6B5E), shape: BoxShape.circle)),\n                          const SizedBox(width: 5),\n                          const Text('지금 방송 중',\n                              style: TextStyle(color: _bg, fontSize: 10.5, fontWeight: FontWeight.w700)),\n                        ],\n                      ),\n                    ),\n                    const SizedBox(height: 8),\n                    Text(cur.title,\n                        maxLines: 2,\n                        overflow: TextOverflow.ellipsis,\n                        style: const TextStyle(color: _bg, fontSize: 16, fontWeight: FontWeight.w800)),\n                    const SizedBox(height: 3),\n                    Text('${_hm(cur.start)} – ${_hm(cur.end)} · ${cur.end - nowM}분 남음',\n                        style: TextStyle(color: _bg.withOpacity(0.7), fontSize: 12)),\n                    const SizedBox(height: 10),\n                    ClipRRect(\n                      borderRadius: BorderRadius.circular(2),\n                      child: LinearProgressIndicator(\n                        value: ((nowM - cur.start) / (cur.end - cur.start)).clamp(0.0, 1.0),\n                        minHeight: 4,\n                        backgroundColor: Colors.white.withOpacity(0.15),\n                        color: const Color(0xFF7FB8F0),\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n            ConstrainedBox(\n              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),\n              child: ListView(\n                shrinkWrap: true,\n                padding: const EdgeInsets.only(top: 2),\n                children: rows,\n              ),\n            ),\n          ],\n        ],\n      ),\n    );\n  }\n}"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_radio3")

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
    print("   문제가 있으면 backup_radio3 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
