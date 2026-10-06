# 파란소리: TV 연결 창 새 디자인 (깔끔한 줄 목록 · 가운데 ⏯ 하나)
# 실행: C:\apps\mp3_player_new 에서  python apply_tv_sheet2.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_tv_sheet2 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["func", "widgets/cast_sheets.dart", "void showCastPickerSheet(BuildContext context, {required Future<bool> Function(CastDevice) onPick})", "void showCastPickerSheet(BuildContext context, {required Future<bool> Function(CastDevice) onPick}) {\n  _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기\n  showModalBottomSheet(\n    context: context,\n    backgroundColor: Colors.transparent,\n    builder: (ctx) {\n      Future<List<CastDevice>> search = CastService.instance.discover();\n      return StatefulBuilder(builder: (ctx, setSheet) {\n        return SafeArea(\n          top: false,\n          child: Container(\n            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),\n            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),\n            decoration: BoxDecoration(color: _cBg, borderRadius: BorderRadius.circular(22)),\n            child: Column(\n              mainAxisSize: MainAxisSize.min,\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Center(\n                  child: Container(\n                    width: 36,\n                    height: 4,\n                    decoration: BoxDecoration(color: _cLine, borderRadius: BorderRadius.circular(2)),\n                  ),\n                ),\n                const SizedBox(height: 14),\n                // 제목 + ✕\n                Row(\n                  children: [\n                    Expanded(\n                      child: Text('TV로 듣기',\n                          style: TextStyle(color: _cInk, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                    ),\n                    ParanCloseX(onTap: () => Navigator.pop(ctx)),\n                  ],\n                ),\n                const SizedBox(height: 6),\n                FutureBuilder<List<CastDevice>>(\n                  future: search,\n                  builder: (_, snap) {\n                    // ① 찾는 중\n                    if (snap.connectionState != ConnectionState.done) {\n                      return Padding(\n                        padding: const EdgeInsets.symmetric(vertical: 18),\n                        child: Row(\n                          children: [\n                            SizedBox(\n                              width: 16,\n                              height: 16,\n                              child: CircularProgressIndicator(strokeWidth: 2, color: _cSub),\n                            ),\n                            const SizedBox(width: 10),\n                            Text('같은 와이파이의 TV를 찾고 있어요', style: TextStyle(color: _cSub, fontSize: 13)),\n                          ],\n                        ),\n                      );\n                    }\n                    final devices = snap.data ?? [];\n                    // ③ 못 찾음\n                    if (devices.isEmpty) {\n                      return Padding(\n                        padding: const EdgeInsets.only(top: 8),\n                        child: Column(\n                          crossAxisAlignment: CrossAxisAlignment.start,\n                          children: [\n                            Text('TV를 못 찾았어요',\n                                style: TextStyle(color: _cInk, fontSize: 15, fontWeight: FontWeight.w700)),\n                            const SizedBox(height: 4),\n                            Text('TV가 켜져 있고 같은 와이파이인지 확인해 주세요',\n                                style: TextStyle(color: _cSub, fontSize: 12.5, height: 1.5)),\n                            const SizedBox(height: 12),\n                            GestureDetector(\n                              onTap: () {\n                                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                                setSheet(() => search = CastService.instance.discover());\n                              },\n                              child: Text('다시 찾기',\n                                  style: TextStyle(\n                                      color: _cInk,\n                                      fontSize: 14,\n                                      fontWeight: FontWeight.w700,\n                                      decoration: TextDecoration.underline)),\n                            ),\n                          ],\n                        ),\n                      );\n                    }\n                    // ② 찾음: 줄 목록\n                    return Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        for (final d in devices)\n                          InkWell(\n                            onTap: () async {\n                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                              Navigator.pop(ctx);\n                              final ok = await onPick(d);\n                              if (!ok && context.mounted) {\n                                showParanToast(context, 'TV로 보내지 못했어요. 다시 시도해 주세요.', error: true);\n                              }\n                            },\n                            child: Container(\n                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),\n                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _cLine, width: 0.5))),\n                              child: Row(\n                                children: [\n                                  Icon(d.kind == CastKind.google ? Icons.cast_rounded : Icons.tv_rounded,\n                                      color: _cSub, size: 20),\n                                  const SizedBox(width: 12),\n                                  Expanded(\n                                    child: Text(d.name,\n                                        maxLines: 1,\n                                        overflow: TextOverflow.ellipsis,\n                                        style: TextStyle(color: _cInk, fontSize: 14.5)),\n                                  ),\n                                ],\n                              ),\n                            ),\n                          ),\n                        Padding(\n                          padding: const EdgeInsets.only(top: 14),\n                          child: Row(\n                            children: [\n                              Icon(Icons.wifi_rounded, color: _cSub, size: 14),\n                              const SizedBox(width: 6),\n                              Text('같은 와이파이의 TV만 보여요', style: TextStyle(color: _cSub, fontSize: 12)),\n                            ],\n                          ),\n                        ),\n                      ],\n                    );\n                  },\n                ),\n              ],\n            ),\n          ),\n        );\n      });\n    },\n  );\n}"], ["func", "widgets/cast_sheets.dart", "void showCastControlSheet(BuildContext context)", "void showCastControlSheet(BuildContext context, {String? nowPlaying}) {\n  _tvDark = context.read<ThemeProvider>().isDarkMode; // 다크 모드 맞추기\n  showModalBottomSheet(\n    context: context,\n    backgroundColor: Colors.transparent,\n    builder: (ctx) => AnimatedBuilder(\n      animation: CastService.instance,\n      builder: (ctx, _) {\n        final cast = CastService.instance;\n        return SafeArea(\n          top: false,\n          child: Container(\n            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),\n            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),\n            decoration: BoxDecoration(color: _cBg, borderRadius: BorderRadius.circular(22)),\n            child: Column(\n              mainAxisSize: MainAxisSize.min,\n              children: [\n                Container(\n                  width: 36,\n                  height: 4,\n                  decoration: BoxDecoration(color: _cLine, borderRadius: BorderRadius.circular(2)),\n                ),\n                Align(alignment: Alignment.centerRight, child: ParanCloseX(onTap: () => Navigator.pop(ctx))),\n                // 가운데: TV · 이름 · 지금 나오는 것\n                Icon(Icons.tv_rounded, color: _cInk, size: 44),\n                const SizedBox(height: 6),\n                Text(cast.device?.name ?? 'TV',\n                    textAlign: TextAlign.center,\n                    style: TextStyle(color: _cInk, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                const SizedBox(height: 3),\n                Text(\n                  nowPlaying ?? (cast.tvPlaying ? 'TV에서 재생 중' : 'TV에서 일시정지'),\n                  maxLines: 1,\n                  overflow: TextOverflow.ellipsis,\n                  textAlign: TextAlign.center,\n                  style: TextStyle(color: _cSub, fontSize: 12.5),\n                ),\n                const SizedBox(height: 20),\n                // 먹색 ⏯ 하나\n                GestureDetector(\n                  onTap: () {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    cast.tvPlaying ? cast.pause() : cast.play();\n                  },\n                  child: Container(\n                    width: 60,\n                    height: 60,\n                    decoration: BoxDecoration(color: _cInk, shape: BoxShape.circle),\n                    child: Icon(cast.tvPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,\n                        color: _cBg, size: 32),\n                  ),\n                ),\n                const SizedBox(height: 20),\n                GestureDetector(\n                  onTap: () async {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    Navigator.pop(ctx);\n                    await cast.disconnect();\n                  },\n                  child: Text('연결 끊기',\n                      style: TextStyle(color: _cSub, fontSize: 13, decoration: TextDecoration.underline)),\n                ),\n              ],\n            ),\n          ),\n        );\n      },\n    ),\n  );\n}"], ["str", "widgets/cast_sheets.dart", "import 'paran_toast.dart';\n", "import 'paran_toast.dart';\nimport 'paran_dialog.dart';\nimport 'package:flutter/services.dart';\n"], ["str", "screens/player_screen.dart", "import '../services/cast_service.dart';\n", "import '../services/cast_service.dart';\nimport '../widgets/cast_sheets.dart';\n"], ["func", "screens/player_screen.dart", "  void _showCastPicker(Song song, PlayerProvider playerProvider)", "  void _showCastPicker(Song song, PlayerProvider playerProvider) {\n    // 공통 TV 찾기 창 (라디오와 같은 모양)\n    showCastPickerSheet(context, onPick: (d) async {\n      final cast = CastService.instance;\n      cast.onTrackEnded = () => playerProvider.playNext(); // TV에서 곡 끝나면 다음 곡\n      final ok = await cast.connect(d, song);\n      if (ok) playerProvider.player.pause();\n      return ok;\n    });\n  }"], ["func", "screens/player_screen.dart", "  void _showCastControl()", "  void _showCastControl() {\n    // 공통 TV 연결됨 창 (가운데: TV 이름 · 지금 곡 · ⏯)\n    final song = context.read<PlayerProvider>().currentSong;\n    showCastControlSheet(context,\n        nowPlaying: song == null ? null : '${song.titleDisplay} · ${song.artistDisplay}');\n  }"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_tv_sheet2")

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
    print("   문제가 있으면 backup_tv_sheet2 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
