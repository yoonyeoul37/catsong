# 파란소리: 화면 통일 5: 곡 정보 한꺼번에 정리 · 앨범 사진 한꺼번에 찾기 (먹색 버튼·체크, 회색 아이콘)
# 실행: C:\apps\mp3_player_new 에서  python apply_screen5.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_screen5 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["strall", "screens/bulk_clean_screen.dart", "style: TextButton.styleFrom(foregroundColor: _blue),", "style: TextButton.styleFrom(foregroundColor: ink),"], ["str", "screens/bulk_clean_screen.dart", "              const SizedBox(\n                width: 28,\n                height: 28,\n                child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue),", "              SizedBox(\n                width: 28,\n                height: 28,\n                child: CircularProgressIndicator(strokeWidth: 2.5, color: ink),"], ["str", "screens/bulk_clean_screen.dart", "const Icon(Icons.auto_awesome, color: _blue, size: 40),", "Icon(Icons.auto_awesome_rounded, color: sub, size: 40),"], ["str", "screens/bulk_clean_screen.dart", "const Icon(Icons.auto_awesome, color: _blue, size: 16),", "Icon(Icons.auto_awesome_rounded, color: sub, size: 16),"], ["str", "screens/bulk_clean_screen.dart", "activeColor: _blue,", "activeColor: ink,\n                            checkColor: bg,"], ["str", "screens/bulk_clean_screen.dart", "                backgroundColor: _blue,\n                foregroundColor: Colors.white,\n                disabledBackgroundColor: _blue.withOpacity(0.4),\n                disabledForegroundColor: Colors.white,\n                elevation: 6,\n                shadowColor: _blue.withOpacity(0.45),", "                // 큰 버튼: 먹색 (다크 모드는 크림색)\n                backgroundColor: ink,\n                foregroundColor: bg,\n                disabledBackgroundColor: ink.withOpacity(0.35),\n                disabledForegroundColor: bg,\n                elevation: 6,\n                shadowColor: Colors.black.withOpacity(0.25),"], ["str", "screens/bulk_art_screen.dart", "            color: isDark ? const Color(0xFF26221C) : Colors.white,", "            color: isDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5), // 다른 고르는 창과 같은 베이지"], ["str", "screens/bulk_art_screen.dart", "const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue)),", "SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: ink)),"], ["str", "screens/bulk_art_screen.dart", "style: TextButton.styleFrom(foregroundColor: _blue),", "style: TextButton.styleFrom(foregroundColor: ink),"], ["str", "screens/bulk_art_screen.dart", "const Icon(Icons.photo_library_outlined, color: _blue, size: 40),", "Icon(Icons.photo_library_outlined, color: sub, size: 40),"], ["str", "screens/bulk_art_screen.dart", "                  const SizedBox(\n                      width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _blue))\n                else\n                  const Icon(Icons.travel_explore, color: _blue, size: 16),", "                  SizedBox(\n                      width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: sub))\n                else\n                  Icon(Icons.travel_explore_rounded, color: sub, size: 16),"], ["str", "screens/bulk_art_screen.dart", "                                    : const SizedBox(\n                                    width: 16,\n                                    height: 16,\n                                    child: CircularProgressIndicator(strokeWidth: 2, color: _blue)),", "                                    : SizedBox(\n                                    width: 16,\n                                    height: 16,\n                                    child: CircularProgressIndicator(strokeWidth: 2, color: sub)),"], ["str", "screens/bulk_art_screen.dart", "activeColor: _blue,", "activeColor: ink,\n                                  checkColor: bg,"], ["str", "screens/bulk_art_screen.dart", "                backgroundColor: _blue,\n                foregroundColor: Colors.white,\n                disabledBackgroundColor: _blue.withOpacity(0.4),\n                disabledForegroundColor: Colors.white,\n                elevation: 6,\n                shadowColor: _blue.withOpacity(0.45),", "                // 큰 버튼: 먹색 (다크 모드는 크림색)\n                backgroundColor: ink,\n                foregroundColor: bg,\n                disabledBackgroundColor: ink.withOpacity(0.35),\n                disabledForegroundColor: bg,\n                elevation: 6,\n                shadowColor: Colors.black.withOpacity(0.25),"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_screen5")

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
    print("   문제가 있으면 backup_screen5 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
