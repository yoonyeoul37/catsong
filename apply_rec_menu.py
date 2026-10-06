# 파란소리: 녹음 ⋮ 메뉴를 공통 고르는 창 모양으로 (+ 목록 아이콘 차분한 회색)
# 실행: C:\apps\mp3_player_new 에서  python apply_rec_menu.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_rec_menu 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "widgets/paran_dialog.dart", "  final bool accent; // 글자를 파랗게 (예: 새로 만들기)\n  final VoidCallback? onTap;\n  const ParanRow({\n    super.key,\n    this.icon,\n    required this.title,\n    this.trailingText,\n    this.selected = false,\n    this.accent = false,\n    this.onTap,\n  });", "  final bool accent; // 글자를 파랗게 (예: 새로 만들기)\n  final bool danger; // 빨갛게 (예: 삭제)\n  final VoidCallback? onTap; // 없으면 흐리게 (누를 수 없음)\n  const ParanRow({\n    super.key,\n    this.icon,\n    required this.title,\n    this.trailingText,\n    this.selected = false,\n    this.accent = false,\n    this.danger = false,\n    this.onTap,\n  });"], ["str", "widgets/paran_dialog.dart", "    final p = _Pal.of(context);\n    return InkWell(\n      onTap: onTap == null\n          ? null\n          : () {\n              _vib();\n              onTap!();\n            },\n      child: Padding(\n        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),", "    final p = _Pal.of(context);\n    return Opacity(\n      opacity: onTap == null ? 0.4 : 1,\n      child: InkWell(\n      onTap: onTap == null\n          ? null\n          : () {\n              _vib();\n              onTap!();\n            },\n      child: Padding(\n        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),"], ["str", "widgets/paran_dialog.dart", "              SizedBox(width: 22, child: Icon(icon, color: _kBlue, size: 20)),", "              // 아이콘은 차분한 회색 (새로 만들기만 파랑, 삭제는 빨강)\n              SizedBox(width: 22, child: Icon(icon, color: danger ? _kRed : (accent ? _kBlue : p.sub), size: 20)),"], ["str", "widgets/paran_dialog.dart", "                    color: accent || selected ? _kBlue : p.ink,", "                    color: danger ? _kRed : (accent || selected ? _kBlue : p.ink),"], ["str", "widgets/paran_dialog.dart", "            if (selected) ...[\n              const SizedBox(width: 8),\n              const Icon(Icons.check_circle_rounded, color: _kBlue, size: 20),\n            ],\n          ],\n        ),\n      ),\n    );\n  }", "            if (selected) ...[\n              const SizedBox(width: 8),\n              const Icon(Icons.check_circle_rounded, color: _kBlue, size: 20),\n            ],\n          ],\n        ),\n      ),\n      ),\n    );\n  }"], ["func", "screens/call_recordings_screen.dart", "  void _showMenu(CallRecording r)", "  void _showMenu(CallRecording r) {\n    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n    final music = context.read<MusicProvider>();\n    final isDark = context.read<ThemeProvider>().isDarkMode;\n    final locked = music.isRecordingLocked(r.path);\n    showParanSheet(\n      context,\n      title: music.recordingTitle(r),\n      // 위: 녹음 제목 + 날짜\n      header: Padding(\n        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Text(music.recordingTitle(r),\n                maxLines: 1,\n                overflow: TextOverflow.ellipsis,\n                style: TextStyle(\n                    color: isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F),\n                    fontSize: 17,\n                    fontWeight: FontWeight.w800,\n                    letterSpacing: -0.3)),\n            const SizedBox(height: 3),\n            Text(r.dateLabel,\n                style: TextStyle(\n                    color: isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378), fontSize: 12.5)),\n          ],\n        ),\n      ),\n      builder: (ctx, setSheet) => Column(\n        children: [\n          ParanCard(children: [\n            ParanRow(icon: Icons.share_outlined, title: '공유', onTap: () {\n              Navigator.pop(ctx);\n              _share([r]);\n            }),\n            ParanRow(icon: Icons.content_cut_rounded, title: '자르기', onTap: () {\n              Navigator.pop(ctx);\n              _trim(r);\n            }),\n            ParanRow(icon: Icons.edit_outlined, title: '제목 바꾸기', onTap: () {\n              Navigator.pop(ctx);\n              _renameDialog(r);\n            }),\n            ParanRow(\n              icon: locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,\n              title: locked ? '잠금 풀기' : '잠금 (삭제 안 되게)',\n              onTap: () async {\n                Navigator.pop(ctx);\n                await music.toggleRecordingLock(r);\n                if (!mounted) return;\n                showActionFeedback(context,\n                    type: ActionFeedbackType.saved,\n                    message: locked ? '잠금을 풀었어요' : '잠갔어요',\n                    icon: locked ? Icons.lock_open_rounded : Icons.lock_rounded);\n              },\n            ),\n          ]),\n          ParanCard(children: [\n            ParanRow(\n              icon: Icons.delete_outline_rounded,\n              title: locked ? '잠긴 녹음은 삭제할 수 없어요' : '삭제',\n              danger: true,\n              onTap: locked\n                  ? null\n                  : () {\n                      Navigator.pop(ctx);\n                      _confirmTrash([r]);\n                    },\n            ),\n          ]),\n        ],\n      ),\n    );\n  }"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_rec_menu")

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
    print("   문제가 있으면 backup_rec_menu 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
