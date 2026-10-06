# 파란소리: 고르는 창 통일 2 (배속·수면 타이머·재생화면 스타일 + 설정 스타일 창 + 폴더 목록 겹침)
# 실행: C:\apps\mp3_player_new 에서  python apply_picker2.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_picker2 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "widgets/paran_dialog.dart", "/// 곡 정보 창 머리 (앨범 사진 + 제목 + 가수)\n", "/// 이미 만들어진 내용(배속·수면 타이머 등)을 베이지 카드 틀에 넣기\nclass ParanSheetFrame extends StatelessWidget {\n  final Widget child;\n  const ParanSheetFrame({super.key, required this.child});\n\n  @override\n  Widget build(BuildContext context) {\n    final p = _Pal.of(context);\n    return SafeArea(\n      top: false,\n      child: Container(\n        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),\n        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),\n        decoration: BoxDecoration(color: p.sheet, borderRadius: BorderRadius.circular(22)),\n        child: Column(\n          mainAxisSize: MainAxisSize.min,\n          children: [\n            Container(\n              width: 36,\n              height: 4,\n              decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),\n            ),\n            const SizedBox(height: 10),\n            child,\n          ],\n        ),\n      ),\n    );\n  }\n}\n\n/// 곡 정보 창 머리 (앨범 사진 + 제목 + 가수)\n"], ["str", "screens/player_screen.dart", "import '../widgets/paran_toast.dart';\n", "import '../widgets/paran_toast.dart';\nimport '../widgets/paran_dialog.dart';\n"], ["func", "screens/player_screen.dart", "  static void _showSpeedDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor)", "  static void _showSpeedDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {\n    showModalBottomSheet(\n      context: context,\n      backgroundColor: Colors.transparent,\n      isScrollControlled: true,\n      builder: (ctx) => ParanSheetFrame(\n        child: _SpeedDialog(playerProvider: playerProvider, primaryColor: const Color(0xFF2589E8)),\n      ),\n    );\n  }"], ["region", "screens/player_screen.dart", "Text(AppLocalizations.of(context)!.playbackSpeed,", "final primaryColor = AppTheme.fixedAccent;", "const SizedBox(height: 16),", "final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n    const primaryColor = Color(0xFF2589E8);\n    final textColor = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),\n      child: Column(\n        mainAxisSize: MainAxisSize.min,\n        children: [\n          Align(\n            alignment: Alignment.centerLeft,\n            child: Text(AppLocalizations.of(context)!.playbackSpeed,\n                style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n          ),\n          const SizedBox(height: 12),"], ["func", "screens/player_screen.dart", "  static void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor)", "  static void _showSleepTimerDialog(BuildContext context, PlayerProvider playerProvider, Color primaryColor) {\n    showModalBottomSheet(\n      context: context,\n      backgroundColor: Colors.transparent,\n      isScrollControlled: true,\n      builder: (ctx) => ParanSheetFrame(\n        child: _SleepTimerDialog(playerProvider: playerProvider, primaryColor: const Color(0xFF2589E8)),\n      ),\n    );\n  }"], ["str", "screens/player_screen.dart", "    final isActive = widget.playerProvider.isSleepTimerActive;\n    final primaryColor = widget.primaryColor;\n\n    return Padding(\n      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),", "    final isActive = widget.playerProvider.isSleepTimerActive;\n    final primaryColor = widget.primaryColor;\n\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),"], ["strall", "screens/player_screen.dart", "backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF7F5F0),", "backgroundColor: isDarkMode ? const Color(0xFF26221C) : const Color(0xFFF4EFE5),"], ["strall", "screens/player_screen.dart", "    final primaryColor = AppTheme.fixedAccent;\n    final isDarkMode = context.read<ThemeProvider>().isDarkMode;\n    final textColor = isDarkMode ? Colors.white : Colors.black;\n    Duration picked = const Duration(minutes: 30);", "    const primaryColor = Color(0xFF2589E8);\n    final isDarkMode = context.read<ThemeProvider>().isDarkMode;\n    final textColor = isDarkMode ? Colors.white : Colors.black;\n    Duration picked = const Duration(minutes: 30);"], ["func", "screens/player_screen.dart", "  static Future<void> _styleDialog(BuildContext context, int current, ValueChanged<int> onPick,\n      {int printStyle = 0, ValueChanged<int>? onPrintPick})", "  static Future<void> _styleDialog(BuildContext context, int current, ValueChanged<int> onPick,\n      {int printStyle = 0, ValueChanged<int>? onPrintPick}) {\n    const blue = Color(0xFF2589E8);\n    final l = AppLocalizations.of(context)!;\n    final styles = [\n      (1, l.styleCD, Icons.album_outlined),\n      (6, '파란포토', Icons.photo_outlined),\n      (3, l.styleCard, Icons.image_outlined),\n    ];\n    return showParanSheet(\n      context,\n      title: l.playerStyle,\n      builder: (ctx, setSheet) => ParanCard(\n        children: [\n          for (final st in styles) ...[\n            ParanRow(\n              icon: st.$3,\n              title: st.$2,\n              trailingText: st.$1 == 6 ? '추천' : null,\n              selected: current == st.$1,\n              onTap: () {\n                current = st.$1;\n                onPick(current);\n                setSheet(() {});\n                // 앨범은 바로 닫지 않고 아래에서 인화 모양을 고르게\n                if (current != 3 || onPrintPick == null) Navigator.pop(ctx);\n              },\n            ),\n            if (st.$1 == 3 && current == 3 && onPrintPick != null)\n              Padding(\n                padding: const EdgeInsets.fromLTRB(46, 0, 14, 14),\n                child: Wrap(\n                  spacing: 6,\n                  runSpacing: 6,\n                  children: [\n                    for (final e in const ['기본', '폴라로이드', '테이프', '겹친 사진', '둥근 테두리'].asMap().entries)\n                      GestureDetector(\n                        onTap: () {\n                          printStyle = e.key;\n                          onPrintPick(e.key);\n                          Navigator.pop(ctx);\n                        },\n                        child: Container(\n                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),\n                          decoration: BoxDecoration(\n                            color: printStyle == e.key ? blue : Colors.transparent,\n                            borderRadius: BorderRadius.circular(14),\n                            border: Border.all(color: printStyle == e.key ? blue : const Color(0x33888888)),\n                          ),\n                          child: Text(e.value,\n                              style: TextStyle(\n                                  color: printStyle == e.key ? Colors.white : const Color(0xFF8A8378),\n                                  fontSize: 12.5,\n                                  fontWeight: FontWeight.w600)),\n                        ),\n                      ),\n                  ],\n                ),\n              ),\n          ],\n        ],\n      ),\n    );\n  }"], ["str", "screens/settings_screen.dart", "import '../widgets/paran_dialog.dart';\n", "import '../widgets/paran_dialog.dart';\nimport 'player_screen.dart' show showPlayerStyleMenu;\n"], ["func", "screens/settings_screen.dart", "  void _showPlayerStyleDialog(BuildContext context)", "  void _showPlayerStyleDialog(BuildContext context) {\n    showPlayerStyleMenu(context); // 재생화면 ⋮ 메뉴와 같은 스타일 창 (시디롬·파란포토·앨범)\n  }"], ["str", "screens/folder_screen.dart", "    return Scaffold(\n      backgroundColor: bgColor,\n      body: CustomScrollView(\n        slivers: [\n          SliverAppBar(\n            expandedHeight: 220,", "    return Scaffold(\n      backgroundColor: bgColor,\n      body: SafeArea(\n        top: false, // 아래 시스템 아이콘과 안 겹치게\n        child: CustomScrollView(\n        slivers: [\n          SliverAppBar(\n            expandedHeight: 220,"], ["str", "screens/folder_screen.dart", "          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),\n        ],\n      ),\n    );", "          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),\n        ],\n      ),\n      ),\n    );"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_picker2")

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
    print("   문제가 있으면 backup_picker2 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
