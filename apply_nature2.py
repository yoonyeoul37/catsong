# 파란소리: 자연소리 목록 A (흰 카드 목록 · 듣는 중 파랑 대신 굵게)
# 실행: C:\apps\mp3_player_new 에서  python apply_nature2.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_nature2 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "screens/nature_sounds_screen.dart", "                final displayTitle = isMulti ? '$categoryName (${variants.length})' : primary.name;\n                final displayDescription = isMulti ? '${variants.length}가지 버전 중 골라보세요' : primary.description;", "                final displayTitle = isMulti ? categoryName : primary.name;\n                // 설명은 짧게: \"3가지 버전\" (듣는 중이면 뒤에 붙이기)\n                final baseDesc = isMulti ? '${variants.length}가지 버전' : primary.description;\n                final displayDescription = isGroupPlaying ? '$baseDesc · 듣는 중' : baseDesc;"], ["str", "screens/nature_sounds_screen.dart", "                  child: Container(\n                    padding: const EdgeInsets.symmetric(vertical: 13),\n                    color: isGroupPlaying\n                        ? (isDarkMode ? const Color(0x262F7DE8) : const Color(0x142F7DE8))\n                        : Colors.transparent,", "                  child: Container(\n                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),\n                    // 듣는 중: 파란 배경 대신 연한 베이지\n                    color: isGroupPlaying\n                        ? (isDarkMode ? const Color(0xFF332E26) : const Color(0xFFF7F3EB))\n                        : Colors.transparent,"], ["str", "screens/nature_sounds_screen.dart", "                                  style: TextStyle(\n                                      color: isGroupPlaying\n                                          ? (isDarkMode ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))\n                                          : baseColor,\n                                      fontSize: 14.5,\n                                      fontWeight: FontWeight.w600)),", "                                  style: TextStyle(\n                                      color: baseColor,\n                                      fontSize: 14.5,\n                                      fontWeight: isGroupPlaying ? FontWeight.w800 : FontWeight.w600)),"], ["str", "screens/nature_sounds_screen.dart", "                                      ? const Color(0xFFF0506E)\n", "                                      ? const Color(0xFFE05A4F)\n"], ["str", "screens/nature_sounds_screen.dart", "              return [\n                for (var i = 0; i < _natureCards.length; i++) ...[\n                  _natureCards[i],\n                  if (i != _natureCards.length - 1)\n                    Divider(height: 1, color: baseColor.withOpacity(0.12)),\n                ],\n              ];", "              // 흰 카드 하나에 묶기 (설정·즐겨찾기 창과 같은 모양)\n              return [\n                Container(\n                  decoration: BoxDecoration(\n                    color: isDarkMode ? const Color(0xFF26221C) : Colors.white,\n                    borderRadius: BorderRadius.circular(16),\n                  ),\n                  clipBehavior: Clip.antiAlias,\n                  child: Column(\n                    children: [\n                      for (var i = 0; i < _natureCards.length; i++) ...[\n                        if (i > 0)\n                          Container(\n                              height: 0.5,\n                              margin: const EdgeInsets.only(left: 78),\n                              color: baseColor.withOpacity(0.08)),\n                        _natureCards[i],\n                      ],\n                    ],\n                  ),\n                ),\n              ];"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_nature2")

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
    print("   문제가 있으면 backup_nature2 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
