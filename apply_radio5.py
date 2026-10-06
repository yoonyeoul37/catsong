# 파란소리: 라디오 즐겨찾기 창 새 디자인 (듣는 중 먹색 카드 + 바로 듣기 목록 + 밀어서 빼기)
# 실행: C:\apps\mp3_player_new 에서  python apply_radio5.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_radio5 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["func", "screens/radio_player_screen.dart", "class _FavoritesSheet extends StatelessWidget", "class _FavoritesSheet extends StatelessWidget {\n  final Color primaryColor;\n  const _FavoritesSheet({required this.primaryColor});\n\n  // 화면 공통 색\n  static const _bg = Color(0xFFF4EFE5);\n  static const _ink = Color(0xFF17140F);\n  static const _sub = Color(0xFF8A8378);\n  static const _line = Color(0xFFE2DACB);\n\n  /// 방송국 로고 (없으면 이름 앞 글자)\n  Widget _logo(RadioStation s, {required bool onDark}) {\n    final short = (s.broadcaster ?? s.name).replaceAll(' ', '');\n    final label = short.length > 4 ? short.substring(0, 4) : short;\n    return Container(\n      width: 44,\n      height: 44,\n      decoration: BoxDecoration(color: onDark ? Colors.white : _bg, borderRadius: BorderRadius.circular(12)),\n      clipBehavior: Clip.antiAlias,\n      alignment: Alignment.center,\n      child: (s.logoUrl != null && s.logoUrl!.isNotEmpty)\n          ? Image.network(s.logoUrl!,\n              width: 44,\n              height: 44,\n              fit: BoxFit.cover,\n              errorBuilder: (_, __, ___) => Text(label,\n                  style: const TextStyle(color: _ink, fontSize: 10.5, fontWeight: FontWeight.w800)))\n          : Text(label, style: const TextStyle(color: _ink, fontSize: 10.5, fontWeight: FontWeight.w800)),\n    );\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final radioProvider = context.watch<RadioProvider>();\n    final favorites = radioProvider.favorites;\n    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;\n    final curId = radioProvider.currentStation?.stationUuid;\n    final current = favorites.where((s) => s.stationUuid == curId).toList();\n    final others = favorites.where((s) => s.stationUuid != curId).toList();\n\n    void vib() => const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n\n    return Container(\n      decoration: const BoxDecoration(\n        color: _bg,\n        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),\n      ),\n      padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomPadding),\n      child: Column(\n        mainAxisSize: MainAxisSize.min,\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Center(\n            child: Container(\n              width: 36,\n              height: 4,\n              decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2)),\n            ),\n          ),\n          const SizedBox(height: 14),\n          // 위: 제목 · 개수\n          Padding(\n            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),\n            child: Row(\n              crossAxisAlignment: CrossAxisAlignment.end,\n              children: [\n                Expanded(\n                  child: Text(AppLocalizations.of(context)!.favorites,\n                      style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                ),\n                Text('${favorites.length}개', style: const TextStyle(color: _sub, fontSize: 12.5)),\n              ],\n            ),\n          ),\n          if (favorites.isEmpty)\n            Padding(\n              padding: const EdgeInsets.symmetric(vertical: 32),\n              child: Center(\n                child: Column(\n                  children: [\n                    Icon(CupertinoIcons.heart, size: 40, color: _sub.withOpacity(0.5)),\n                    const SizedBox(height: 12),\n                    Text(AppLocalizations.of(context)!.radioNoFavorites,\n                        style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600)),\n                    const SizedBox(height: 4),\n                    Text(AppLocalizations.of(context)!.radioNoFavoritesDesc,\n                        textAlign: TextAlign.center, style: const TextStyle(color: _sub, fontSize: 12.5)),\n                  ],\n                ),\n              ),\n            )\n          else\n            ConstrainedBox(\n              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),\n              child: SingleChildScrollView(\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    // 지금 듣는 방송 (먹색 카드)\n                    for (final s in current)\n                      Container(\n                        margin: const EdgeInsets.only(bottom: 12),\n                        padding: const EdgeInsets.all(12),\n                        decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(16)),\n                        child: Row(\n                          children: [\n                            _logo(s, onDark: true),\n                            const SizedBox(width: 12),\n                            Expanded(\n                              child: Column(\n                                crossAxisAlignment: CrossAxisAlignment.start,\n                                children: [\n                                  Container(\n                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),\n                                    decoration: BoxDecoration(\n                                        color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),\n                                    child: Row(\n                                      mainAxisSize: MainAxisSize.min,\n                                      children: [\n                                        Container(\n                                            width: 6,\n                                            height: 6,\n                                            decoration:\n                                                const BoxDecoration(color: Color(0xFFFF6B5E), shape: BoxShape.circle)),\n                                        const SizedBox(width: 5),\n                                        const Text('듣는 중',\n                                            style: TextStyle(color: _bg, fontSize: 10, fontWeight: FontWeight.w700)),\n                                      ],\n                                    ),\n                                  ),\n                                  const SizedBox(height: 5),\n                                  Text(s.name,\n                                      maxLines: 1,\n                                      overflow: TextOverflow.ellipsis,\n                                      style: const TextStyle(color: _bg, fontSize: 15, fontWeight: FontWeight.w700)),\n                                  if ((radioProvider.nowPlayingFor(s.name) ?? '').isNotEmpty)\n                                    Text(radioProvider.nowPlayingFor(s.name)!,\n                                        maxLines: 1,\n                                        overflow: TextOverflow.ellipsis,\n                                        style: TextStyle(color: _bg.withOpacity(0.65), fontSize: 11.5)),\n                                ],\n                              ),\n                            ),\n                            const Icon(Icons.graphic_eq_rounded, color: Color(0xFF7FB8F0), size: 22),\n                          ],\n                        ),\n                      ),\n                    if (others.isNotEmpty) ...[\n                      const Padding(\n                        padding: EdgeInsets.fromLTRB(4, 0, 4, 6),\n                        child: Text('눌러서 바로 듣기',\n                            style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w600)),\n                      ),\n                      Container(\n                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),\n                        clipBehavior: Clip.antiAlias,\n                        child: Column(\n                          children: [\n                            for (var i = 0; i < others.length; i++) ...[\n                              if (i > 0) Container(height: 0.5, margin: const EdgeInsets.only(left: 68), color: const Color(0xFFEEE9DF)),\n                              // 왼쪽으로 밀면 즐겨찾기에서 빼기\n                              Dismissible(\n                                key: ValueKey('fav_${others[i].stationUuid}'),\n                                direction: DismissDirection.endToStart,\n                                background: Container(\n                                  color: const Color(0xFFE05A4F),\n                                  alignment: Alignment.centerRight,\n                                  padding: const EdgeInsets.only(right: 20),\n                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),\n                                ),\n                                onDismissed: (_) {\n                                  final st = others[i];\n                                  showActionFeedback(context, type: ActionFeedbackType.deleted, message: '즐겨찾기에서 뺐어요');\n                                  Future.microtask(() => radioProvider.toggleFavorite(st));\n                                },\n                                child: InkWell(\n                                  onTap: () {\n                                    vib();\n                                    Navigator.pop(context);\n                                    radioProvider.playStation(others[i]);\n                                  },\n                                  child: Padding(\n                                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),\n                                    child: Row(\n                                      children: [\n                                        _logo(others[i], onDark: false),\n                                        const SizedBox(width: 12),\n                                        Expanded(\n                                          child: Column(\n                                            crossAxisAlignment: CrossAxisAlignment.start,\n                                            children: [\n                                              Text(others[i].name,\n                                                  maxLines: 1,\n                                                  overflow: TextOverflow.ellipsis,\n                                                  style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600)),\n                                              if ((radioProvider.nowPlayingFor(others[i].name) ?? '').isNotEmpty)\n                                                Text(radioProvider.nowPlayingFor(others[i].name)!,\n                                                    maxLines: 1,\n                                                    overflow: TextOverflow.ellipsis,\n                                                    style: const TextStyle(color: _sub, fontSize: 11.5)),\n                                            ],\n                                          ),\n                                        ),\n                                        Container(\n                                          width: 32,\n                                          height: 32,\n                                          decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),\n                                          child: const Icon(Icons.play_arrow_rounded, color: _ink, size: 20),\n                                        ),\n                                      ],\n                                    ),\n                                  ),\n                                ),\n                              ),\n                            ],\n                          ],\n                        ),\n                      ),\n                      const Padding(\n                        padding: EdgeInsets.only(top: 8),\n                        child: Center(\n                          child: Text('왼쪽으로 밀면 즐겨찾기에서 빼요', style: TextStyle(color: _sub, fontSize: 11.5)),\n                        ),\n                      ),\n                    ],\n                  ],\n                ),\n              ),\n            ),\n        ],\n      ),\n    );\n  }\n}"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_radio5")

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
    print("   문제가 있으면 backup_radio5 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
