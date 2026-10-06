# 파란소리: 포인트 색 5가지 (파란소리·숲·노을·라벤더·먹색)
# 실행: C:\apps\mp3_player_new 에서  python apply_point_color.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_point_color 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "providers/theme_provider.dart", "  Color _primaryColor = const Color(0xFF078CF6);", "  Color _primaryColor = const Color(0xFF2589E8); // 포인트 색 (기본: 파란소리)"], ["str", "providers/theme_provider.dart", "  Color get primaryColor => _primaryColor;\n", "  Color get primaryColor => _primaryColor;\n\n  /// 포인트 색 5가지 (설정 → 포인트 색) — 체크·스위치·막대 같은 작은 곳의 색\n  static const pointColors = <(String, Color)>[\n    ('파란소리', Color(0xFF2589E8)),\n    ('숲', Color(0xFF3E8E6A)),\n    ('노을', Color(0xFFE07A4F)),\n    ('라벤더', Color(0xFF8A6FD1)),\n    ('먹색', Color(0xFF4A4038)),\n  ];\n\n  /// 지금 포인트 색 이름 (예전에 고른 다른 색이면 null)\n  String? get pointColorName {\n    for (final c in pointColors) {\n      if (c.$2.value == _primaryColor.value) return c.$1;\n    }\n    return null;\n  }\n"], ["str", "screens/settings_screen.dart", "          _buildTile(context, icon: Icons.palette_outlined, title: l.themeColor, onTap: () => _showColorPicker(context), primaryColor: primaryColor),", "          _buildTile(context, icon: Icons.palette_outlined, title: '포인트 색', subtitle: context.watch<ThemeProvider>().pointColorName, onTap: () => _showColorPicker(context), primaryColor: primaryColor),"], ["func", "screens/settings_screen.dart", "  void _showColorPicker(BuildContext context)", "  void _showColorPicker(BuildContext context) {\n    final themeProvider = context.read<ThemeProvider>();\n    final isDarkMode = themeProvider.isDarkMode;\n    showParanSheet(\n      context,\n      title: '포인트 색',\n      builder: (ctx, setSheet) => Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Padding(\n            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),\n            child: Text('체크·스위치·막대 같은 작은 곳의 색이 바뀌어요',\n                style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12.5)),\n          ),\n          ParanCard(\n            children: [\n              for (final c in ThemeProvider.pointColors)\n                InkWell(\n                  onTap: () {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    themeProvider.setPrimaryColor(c.$2);\n                    Navigator.pop(ctx);\n                  },\n                  child: Padding(\n                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),\n                    child: Row(\n                      children: [\n                        Container(width: 22, height: 22, decoration: BoxDecoration(color: c.$2, shape: BoxShape.circle)),\n                        const SizedBox(width: 12),\n                        Expanded(\n                          child: Text(c.$1,\n                              style: TextStyle(\n                                color: _sText(isDarkMode),\n                                fontSize: 14.5,\n                                fontWeight: themeProvider.primaryColor.value == c.$2.value\n                                    ? FontWeight.w700\n                                    : FontWeight.w500,\n                              )),\n                        ),\n                        if (themeProvider.primaryColor.value == c.$2.value)\n                          Icon(Icons.check_circle_rounded, color: c.$2, size: 20),\n                      ],\n                    ),\n                  ),\n                ),\n            ],\n          ),\n        ],\n      ),\n    );\n  }"], ["str", "widgets/paran_dialog.dart", "const _kRed = Color(0xFFE05A4F);\n", "const _kRed = Color(0xFFE05A4F);\n\n/// 포인트 색 (설정에서 고른 색, 기본 파란소리)\nColor _point(BuildContext context) {\n  try {\n    return context.watch<ThemeProvider>().primaryColor;\n  } catch (_) {\n    return _kBlue;\n  }\n}\n"], ["str", "widgets/paran_dialog.dart", "    final p = _Pal.of(context);\n    return Opacity(", "    final p = _Pal.of(context);\n    final pt = _point(context);\n    return Opacity("], ["str", "widgets/paran_dialog.dart", "SizedBox(width: 22, child: Icon(icon, color: danger ? _kRed : (accent ? _kBlue : p.sub), size: 20)),", "SizedBox(width: 22, child: Icon(icon, color: danger ? _kRed : (accent ? pt : p.sub), size: 20)),"], ["str", "widgets/paran_dialog.dart", "color: danger ? _kRed : (accent || selected ? _kBlue : p.ink),", "color: danger ? _kRed : (accent || selected ? pt : p.ink),"], ["str", "widgets/paran_dialog.dart", "const Icon(Icons.check_circle_rounded, color: _kBlue, size: 20),", "Icon(Icons.check_circle_rounded, color: pt, size: 20),"], ["str", "widgets/paran_toast.dart", "  const blue = Color(0xFF2589E8);\n", "  var blue = const Color(0xFF2589E8);\n  try {\n    blue = context.read<ThemeProvider>().primaryColor; // 포인트 색\n  } catch (_) {}\n"], ["str", "screens/ringtone_screen.dart", "    const point = Color(0xFF2589E8); // 작은 포인트에만", "    final point = context.watch<ThemeProvider>().primaryColor; // 포인트 색 (설정에서 고름)"], ["str", "screens/ringtone_screen.dart", "child: Text(t, style: const TextStyle(color: point, fontSize: 12.5, fontWeight: FontWeight.w700)),", "child: Text(t, style: TextStyle(color: point, fontSize: 12.5, fontWeight: FontWeight.w700)),"], ["str", "screens/equalizer_screen.dart", "  static const _point = Color(0xFF2589E8); // 작은 포인트에만 (막대·숫자)", "  static Color _point = const Color(0xFF2589E8); // 포인트 색 (그릴 때마다 설정 색으로)"], ["str", "screens/equalizer_screen.dart", "    final c = _EqPal.of(context);\n", "    final c = _EqPal.of(context);\n    _point = context.watch<ThemeProvider>().primaryColor;\n"], ["strall", "screens/equalizer_screen.dart", "const TextStyle(color: _point", "TextStyle(color: _point"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_point_color")

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
    print("   문제가 있으면 backup_point_color 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
