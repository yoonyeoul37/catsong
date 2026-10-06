# 파란소리: TV 연결 창 통일 (파랑 → 먹색 · 다크 모드)
# 실행: C:\apps\mp3_player_new 에서  python apply_tv_sheet.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_tv_sheet 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["func", "widgets/cast_sheets.dart", "void showCastPickerSheet(BuildContext context, {required Future<bool> Function(CastDevice) onPick})", "void showCastPickerSheet(BuildContext context, {required Future<bool> Function(CastDevice) onPick}) {\n    _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기\n  showModalBottomSheet(\n    context: context,\n    backgroundColor: Colors.transparent,\n    builder: (ctx) {\n      Future<List<CastDevice>> search = CastService.instance.discover();\n      return StatefulBuilder(builder: (ctx, setSheet) {\n        return SafeArea(\n          top: false,\n          child: Container(\n            margin: EdgeInsets.fromLTRB(12, 0, 12, 12),\n            padding: EdgeInsets.fromLTRB(16, 18, 16, 12),\n            decoration: BoxDecoration(\n              color: _cBg,\n              borderRadius: BorderRadius.circular(22),\n            ),\n            child: FutureBuilder<List<CastDevice>>(\n              future: search,\n              builder: (ctx, snap) {\n                final title = Row(\n                  children: [\n                    Icon(Icons.cast, color: _cInk, size: 22),\n                    SizedBox(width: 8),\n                    Expanded(\n                      child: Text('TV로 듣기',\n                          style: TextStyle(color: _cInk, fontSize: 16, fontWeight: FontWeight.w700)),\n                    ),\n                    IconButton(\n                      onPressed: () => Navigator.pop(ctx),\n                      icon: Icon(Icons.close_rounded, color: _cSub),\n                    ),\n                  ],\n                );\n                if (snap.connectionState != ConnectionState.done) {\n                  return Column(mainAxisSize: MainAxisSize.min, children: [\n                    title,\n                    SizedBox(height: 18),\n                    CircularProgressIndicator(color: _cInk),\n                    SizedBox(height: 12),\n                    Text('같은 와이파이에 있는 TV를 찾고 있어요',\n                        style: TextStyle(color: _cSub, fontSize: 13)),\n                    SizedBox(height: 18),\n                  ]);\n                }\n                final devices = snap.data ?? [];\n                if (devices.isEmpty) {\n                  return Column(mainAxisSize: MainAxisSize.min, children: [\n                    title,\n                    SizedBox(height: 14),\n                    Text('TV를 못 찾았어요.\\nTV가 켜져 있고 폰과 같은 와이파이인지 확인해 주세요.',\n                        textAlign: TextAlign.center,\n                        style: TextStyle(color: _cMuted, fontSize: 13, height: 1.5)),\n                    SizedBox(height: 12),\n                    TextButton(\n                      onPressed: () => setSheet(() => search = CastService.instance.discover()),\n                      child: Text('다시 찾기', style: TextStyle(color: _cInk)),\n                    ),\n                  ]);\n                }\n                return Column(mainAxisSize: MainAxisSize.min, children: [\n                  title,\n                  SizedBox(height: 6),\n                  Container(\n                    decoration: BoxDecoration(color: _cCard, borderRadius: BorderRadius.circular(14)),\n                    child: Column(children: [\n                      for (final d in devices)\n                        ListTile(\n                          leading: Icon(d.kind == CastKind.google ? Icons.cast : Icons.tv,\n                              color: _cInk),\n                          title: Text(d.name, style: TextStyle(color: _cInk)),\n                          onTap: () async {\n                            Navigator.pop(ctx);\n                            final ok = await onPick(d);\n                            if (!ok && context.mounted) {\n                              showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);\n                            }\n                          },\n                        ),\n                    ]),\n                  ),\n                  SizedBox(height: 6),\n                ]);\n              },\n            ),\n          ),\n        );\n      });\n    },\n  );\n}"], ["func", "widgets/cast_sheets.dart", "void showCastControlSheet(BuildContext context)", "void showCastControlSheet(BuildContext context) {\n    _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기\n  showModalBottomSheet(\n    context: context,\n    backgroundColor: Colors.transparent,\n    builder: (ctx) => AnimatedBuilder(\n      animation: CastService.instance,\n      builder: (ctx, _) {\n        final cast = CastService.instance;\n        return SafeArea(\n          top: false,\n          child: Container(\n            margin: EdgeInsets.fromLTRB(12, 0, 12, 12),\n            padding: EdgeInsets.fromLTRB(16, 18, 16, 16),\n            decoration: BoxDecoration(\n              color: _cBg,\n              borderRadius: BorderRadius.circular(22),\n            ),\n            child: Column(\n              mainAxisSize: MainAxisSize.min,\n              children: [\n                Icon(Icons.cast_connected, color: _cInk, size: 30),\n                SizedBox(height: 8),\n                Text(cast.device?.name ?? 'TV',\n                    style: TextStyle(color: _cInk, fontSize: 16, fontWeight: FontWeight.w700)),\n                SizedBox(height: 2),\n                Text(cast.tvPlaying ? 'TV에서 재생 중' : 'TV에서 일시정지',\n                    style: TextStyle(color: _cSub, fontSize: 12.5)),\n                SizedBox(height: 16),\n                Row(\n                  children: [\n                    Expanded(\n                      child: ElevatedButton.icon(\n                        onPressed: () => cast.tvPlaying ? cast.pause() : cast.play(),\n                        icon: Icon(cast.tvPlaying ? Icons.pause : Icons.play_arrow),\n                        label: Text(cast.tvPlaying ? '일시정지' : '재생'),\n                        style: ElevatedButton.styleFrom(\n                          backgroundColor: _cInk,\n                          foregroundColor: _cBg,\n                          elevation: 0,\n                          padding: EdgeInsets.symmetric(vertical: 12),\n                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                        ),\n                      ),\n                    ),\n                    SizedBox(width: 10),\n                    Expanded(\n                      child: OutlinedButton(\n                        onPressed: () async {\n                          Navigator.pop(ctx);\n                          await cast.disconnect();\n                        },\n                        style: OutlinedButton.styleFrom(\n                          foregroundColor: _cMuted,\n                          side: BorderSide(color: _cLine),\n                          padding: EdgeInsets.symmetric(vertical: 12),\n                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                        ),\n                        child: Text('연결 끊기'),\n                      ),\n                    ),\n                  ],\n                ),\n              ],\n            ),\n          ),\n        );\n      },\n    ),\n  );\n}"], ["str", "widgets/cast_sheets.dart", "import 'paran_toast.dart';\n", "import 'paran_toast.dart';\nimport 'package:provider/provider.dart';\nimport '../providers/theme_provider.dart';\n\n// ── TV 창 색 (라이트: 베이지 · 다크: 어두운 갈색) — 창을 열 때 다크 모드인지 맞춤 ──\nbool _tvDark = false;\nColor get _cBg => _tvDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);\nColor get _cCard => _tvDark ? const Color(0xFF332E26) : Colors.white;\nColor get _cInk => _tvDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\nColor get _cSub => _tvDark ? const Color(0xFFA29A8B) : const Color(0xFF8A857B);\nColor get _cMuted => _tvDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);\nColor get _cLine => _tvDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);\n\n"], ["func", "screens/player_screen.dart", "  void _showCastPicker(Song song, PlayerProvider playerProvider)", "  void _showCastPicker(Song song, PlayerProvider playerProvider) {\n    _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기\n    showModalBottomSheet(\n      context: context,\n      backgroundColor: Colors.transparent,\n      builder: (ctx) {\n        Future<List<CastDevice>> search = CastService.instance.discover();\n        return StatefulBuilder(builder: (ctx, setSheet) {\n          return SafeArea(\n            top: false,\n            child: Container(\n              margin: EdgeInsets.fromLTRB(12, 0, 12, 12),\n              padding: EdgeInsets.fromLTRB(16, 18, 16, 12),\n              decoration: BoxDecoration(\n                color: _cBg,\n                borderRadius: BorderRadius.circular(22),\n              ),\n              child: FutureBuilder<List<CastDevice>>(\n                future: search,\n                builder: (ctx, snap) {\n                  final title = Row(\n                    children: [\n                      Icon(Icons.cast, color: _cInk, size: 22),\n                      SizedBox(width: 8),\n                      Expanded(\n                        child: Text('TV로 듣기',\n                            style: TextStyle(color: _cInk, fontSize: 16, fontWeight: FontWeight.w700)),\n                      ),\n                      IconButton(\n                        onPressed: () => Navigator.pop(ctx),\n                        icon: Icon(Icons.close_rounded, color: _cSub),\n                      ),\n                    ],\n                  );\n                  if (snap.connectionState != ConnectionState.done) {\n                    return Column(mainAxisSize: MainAxisSize.min, children: [\n                      title,\n                      SizedBox(height: 18),\n                      CircularProgressIndicator(color: _cInk),\n                      SizedBox(height: 12),\n                      Text('같은 와이파이에 있는 TV를 찾고 있어요',\n                          style: TextStyle(color: _cSub, fontSize: 13)),\n                      SizedBox(height: 18),\n                    ]);\n                  }\n                  final devices = snap.data ?? [];\n                  if (devices.isEmpty) {\n                    return Column(mainAxisSize: MainAxisSize.min, children: [\n                      title,\n                      SizedBox(height: 14),\n                      Text('TV를 못 찾았어요.\\nTV가 켜져 있고 폰과 같은 와이파이인지 확인해 주세요.',\n                          textAlign: TextAlign.center,\n                          style: TextStyle(color: _cMuted, fontSize: 13, height: 1.5)),\n                      SizedBox(height: 12),\n                      TextButton(\n                        onPressed: () => setSheet(() => search = CastService.instance.discover()),\n                        child: Text('다시 찾기', style: TextStyle(color: _cInk)),\n                      ),\n                    ]);\n                  }\n                  return Column(mainAxisSize: MainAxisSize.min, children: [\n                    title,\n                    SizedBox(height: 6),\n                    Container(\n                      decoration: BoxDecoration(color: _cCard, borderRadius: BorderRadius.circular(14)),\n                      child: Column(children: [\n                        for (final d in devices)\n                          ListTile(\n                            leading: Icon(Icons.tv, color: _cInk),\n                            title: Text(d.name, style: TextStyle(color: _cInk)),\n                            onTap: () async {\n                              Navigator.pop(ctx);\n                              final cast = CastService.instance;\n                              cast.onTrackEnded = () => playerProvider.playNext(); // TV에서 곡 끝나면 다음 곡\n                              final ok = await cast.connect(d, song);\n                              if (ok) {\n                                playerProvider.player.pause();\n                              } else if (mounted) {\n                                showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);\n                              }\n                            },\n                          ),\n                      ]),\n                    ),\n                    SizedBox(height: 6),\n                  ]);\n                },\n              ),\n            ),\n          );\n        });\n      },\n    );\n  }"], ["func", "screens/player_screen.dart", "  void _showCastControl()", "  void _showCastControl() {\n    _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기\n    showModalBottomSheet(\n      context: context,\n      backgroundColor: Colors.transparent,\n      builder: (ctx) => AnimatedBuilder(\n        animation: CastService.instance,\n        builder: (ctx, _) {\n          final cast = CastService.instance;\n          return SafeArea(\n            top: false,\n            child: Container(\n              margin: EdgeInsets.fromLTRB(12, 0, 12, 12),\n              padding: EdgeInsets.fromLTRB(16, 18, 16, 16),\n              decoration: BoxDecoration(\n                color: _cBg,\n                borderRadius: BorderRadius.circular(22),\n              ),\n              child: Column(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Icon(Icons.cast_connected, color: _cInk, size: 30),\n                  SizedBox(height: 8),\n                  Text(cast.device?.name ?? 'TV',\n                      style: TextStyle(color: _cInk, fontSize: 16, fontWeight: FontWeight.w700)),\n                  SizedBox(height: 2),\n                  Text(cast.tvPlaying ? 'TV에서 재생 중' : 'TV에서 일시정지',\n                      style: TextStyle(color: _cSub, fontSize: 12.5)),\n                  SizedBox(height: 16),\n                  Row(\n                    children: [\n                      Expanded(\n                        child: ElevatedButton.icon(\n                          onPressed: () => cast.tvPlaying ? cast.pause() : cast.play(),\n                          icon: Icon(cast.tvPlaying ? Icons.pause : Icons.play_arrow),\n                          label: Text(cast.tvPlaying ? '일시정지' : '재생'),\n                          style: ElevatedButton.styleFrom(\n                            backgroundColor: _cInk,\n                            foregroundColor: _cBg,\n                            elevation: 0,\n                            padding: EdgeInsets.symmetric(vertical: 12),\n                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                          ),\n                        ),\n                      ),\n                      SizedBox(width: 10),\n                      Expanded(\n                        child: OutlinedButton(\n                          onPressed: () async {\n                            Navigator.pop(ctx);\n                            await cast.disconnect();\n                          },\n                          style: OutlinedButton.styleFrom(\n                            foregroundColor: _cMuted,\n                            side: BorderSide(color: _cLine),\n                            padding: EdgeInsets.symmetric(vertical: 12),\n                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                          ),\n                          child: Text('연결 끊기'),\n                        ),\n                      ),\n                    ],\n                  ),\n                ],\n              ),\n            ),\n          );\n        },\n      ),\n    );\n  }"], ["str", "screens/player_screen.dart", "class PlayerScreen extends StatefulWidget {", "// ── TV 창 색 (라이트: 베이지 · 다크: 어두운 갈색) — 창을 열 때 다크 모드인지 맞춤 ──\nbool _tvDark = false;\nColor get _cBg => _tvDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);\nColor get _cCard => _tvDark ? const Color(0xFF332E26) : Colors.white;\nColor get _cInk => _tvDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\nColor get _cSub => _tvDark ? const Color(0xFFA29A8B) : const Color(0xFF8A857B);\nColor get _cMuted => _tvDark ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);\nColor get _cLine => _tvDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);\n\nclass PlayerScreen extends StatefulWidget {"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_tv_sheet")

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
    print("   문제가 있으면 backup_tv_sheet 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
