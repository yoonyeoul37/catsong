# 파란소리: 화면 통일 6: 설정 (베이지 바탕·묶음 흰 카드·한 줄로)
# 실행: C:\apps\mp3_player_new 에서  python apply_screen6.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_screen6 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "screens/settings_screen.dart", "Color _sBg(bool d) => d ? const Color(0xFF17140F) : const Color(0xFFF7F5F0);\nColor _sCard(bool d) => d ? const Color(0xFF1E1B15) : const Color(0xFFFFFFFF);\nColor _sText(bool d) => d ? Colors.white : const Color(0xFF111111);\nColor _sTextSub(bool d) => d ? Colors.white70 : const Color(0xFF666666);\nColor _sTextHint(bool d) => d ? Colors.white38 : const Color(0xFF999999);\nColor _sBorder(bool d) => d ? Colors.white.withOpacity(0.12) : const Color(0xFFE8E4DA);", "// 화면 공통 색 (베이지 바탕 · 흰 카드 · 먹색 글자)\nColor _sBg(bool d) => d ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);\nColor _sCard(bool d) => d ? const Color(0xFF26221C) : const Color(0xFFFFFFFF);\nColor _sText(bool d) => d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\nColor _sTextSub(bool d) => d ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);\nColor _sTextHint(bool d) => d ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\nColor _sBorder(bool d) => d ? const Color(0xFF3A342B) : const Color(0xFFEEE9DF);"], ["func", "screens/settings_screen.dart", "  Widget _buildSection(String title)", "  Widget _buildSection(String title) {\n    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n    // 작은 회색 소제목 (다른 화면과 같은 모양)\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),\n      child: Text(title,\n          style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12, fontWeight: FontWeight.w600)),\n    );\n  }"], ["func", "screens/settings_screen.dart", "  Widget _buildTile(BuildContext context, {", "  Widget _buildTile(BuildContext context, {\n    required IconData icon, required String title, String? subtitle,\n    required VoidCallback onTap, required Color primaryColor,\n    Widget? trailing, bool isFirst = false, bool isLast = false,\n  }) {\n    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;\n    // 같은 묶음은 흰 카드 하나로 (위·아래 끝만 둥글게)\n    const r = Radius.circular(16);\n    final radius = BorderRadius.vertical(top: isFirst ? r : Radius.zero, bottom: isLast ? r : Radius.zero);\n    return Container(\n      margin: const EdgeInsets.symmetric(horizontal: 16),\n      decoration: BoxDecoration(color: _sCard(isDarkMode), borderRadius: radius),\n      child: Material(\n        type: MaterialType.transparency,\n        child: InkWell(\n          borderRadius: radius,\n          onTap: onTap,\n          child: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              if (!isFirst)\n                Container(height: 0.5, margin: const EdgeInsets.only(left: 50), color: _sBorder(isDarkMode)),\n              Padding(\n                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),\n                // 한 줄로: 아이콘 · 이름 ········ 작은 회색 글자 · 스위치/›\n                child: Row(children: [\n                  Icon(icon, color: _sTextHint(isDarkMode), size: 20),\n                  const SizedBox(width: 14),\n                  Expanded(\n                    child: Text(title,\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: TextStyle(color: _sText(isDarkMode), fontSize: 14.5)),\n                  ),\n                  if (subtitle != null) ...[\n                    const SizedBox(width: 8),\n                    ConstrainedBox(\n                      constraints: const BoxConstraints(maxWidth: 150),\n                      child: Text(subtitle,\n                          maxLines: 1,\n                          overflow: TextOverflow.ellipsis,\n                          style: TextStyle(color: _sTextHint(isDarkMode), fontSize: 12.5)),\n                    ),\n                  ],\n                  const SizedBox(width: 6),\n                  trailing ?? Icon(Icons.chevron_right_rounded, color: _sTextHint(isDarkMode), size: 20),\n                ]),\n              ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_screen6")

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
    print("   문제가 있으면 backup_screen6 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
