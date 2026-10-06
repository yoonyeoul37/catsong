# 파란소리: 화면 통일 1: 자르기·벨소리 화면 (베이지 바탕·흰 카드·먹색 버튼)
# 실행: C:\apps\mp3_player_new 에서  python apply_screen1.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_screen1 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "screens/ringtone_screen.dart", "import '../widgets/paran_toast.dart';\n", "import '../widgets/paran_toast.dart';\nimport '../providers/theme_provider.dart';\n"], ["func", "screens/ringtone_screen.dart", "  Widget build(BuildContext context)", "  Widget build(BuildContext context) {\n    final musicProvider = context.watch<MusicProvider>();\n    final isDark = context.watch<ThemeProvider>().isDarkMode;\n    // ── 화면 공통 모양 (베이지 바탕 · 흰 카드 · 먹색 큰 버튼) ──\n    final bg = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);\n    final card = isDark ? const Color(0xFF26221C) : Colors.white;\n    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n    final line = isDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);\n    const point = Color(0xFF2589E8); // 작은 포인트에만\n    // 녹음처럼 음악 목록에 없는 곡을 자를 때도 선택 칸에 보이게 같이 넣기\n    final songs = [\n      ...musicProvider.allSongs,\n      if (_selectedSong != null && !musicProvider.allSongs.contains(_selectedSong)) _selectedSong!,\n    ];\n\n    Widget section(String text) => Padding(\n          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),\n          child: Text(text, style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),\n        );\n    Widget whiteCard(Widget child, {EdgeInsets padding = const EdgeInsets.all(14)}) => Container(\n          width: double.infinity,\n          padding: padding,\n          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),\n          child: child,\n        );\n    Widget timeChip(String t) => Container(\n          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),\n          decoration: BoxDecoration(color: point.withOpacity(isDark ? 0.18 : 0.08), borderRadius: BorderRadius.circular(12)),\n          child: Text(t, style: const TextStyle(color: point, fontSize: 12.5, fontWeight: FontWeight.w700)),\n        );\n    final sliderTheme = SliderTheme.of(context).copyWith(\n      activeTrackColor: point,\n      inactiveTrackColor: line,\n      thumbColor: point,\n      overlayColor: point.withOpacity(0.1),\n      trackHeight: 3,\n    );\n    Widget rangeRow(String label, double value, ValueChanged<double> onChanged) => Row(\n          children: [\n            SizedBox(width: 40, child: Text(label, style: TextStyle(color: sub, fontSize: 13))),\n            Expanded(\n              child: SliderTheme(\n                data: sliderTheme,\n                child: Slider(\n                  value: value,\n                  min: 0,\n                  max: (_selectedSong!.duration / 1000).toDouble(),\n                  onChanged: onChanged,\n                ),\n              ),\n            ),\n            SizedBox(\n                width: 44,\n                child: Text(_formatTime(value.toInt()),\n                    textAlign: TextAlign.right, style: TextStyle(color: ink, fontSize: 13))),\n          ],\n        );\n\n    return Scaffold(\n      backgroundColor: bg,\n      appBar: AppBar(\n        backgroundColor: bg,\n        elevation: 0,\n        scrolledUnderElevation: 0,\n        titleSpacing: 0,\n        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,\n        title: Text(widget.trimMode ? '자르기' : AppLocalizations.of(context)!.ringtone,\n            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n        leading: IconButton(\n          onPressed: () => Navigator.pop(context),\n          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 20),\n        ),\n      ),\n      // 버튼은 맨 아래에 모아서 (시스템 아이콘 위)\n      bottomNavigationBar: _selectedSong == null\n          ? null\n          : SafeArea(\n              top: false,\n              child: Padding(\n                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),\n                child: Column(\n                  mainAxisSize: MainAxisSize.min,\n                  children: [\n                    // 미리 듣기 (흰 버튼)\n                    SizedBox(\n                      width: double.infinity,\n                      height: 48,\n                      child: OutlinedButton.icon(\n                        onPressed: _togglePreview,\n                        style: OutlinedButton.styleFrom(\n                          backgroundColor: card,\n                          foregroundColor: ink,\n                          side: BorderSide(color: line),\n                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                        ),\n                        icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),\n                        label: Text(_isPlaying ? AppLocalizations.of(context)!.playing : '미리 듣기',\n                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),\n                      ),\n                    ),\n                    const SizedBox(height: 8),\n                    // 잘라서 저장 / 벨소리로 지정 (먹색 큰 버튼)\n                    SizedBox(\n                      width: double.infinity,\n                      height: 50,\n                      child: ElevatedButton.icon(\n                        onPressed: _isProcessing\n                            ? null\n                            : () => widget.trimMode ? _trimAndSave(context) : _setRingtone(context),\n                        style: ElevatedButton.styleFrom(\n                          backgroundColor: ink,\n                          foregroundColor: bg,\n                          disabledBackgroundColor: ink.withOpacity(0.5),\n                          elevation: 6,\n                          shadowColor: Colors.black.withOpacity(0.25),\n                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                        ),\n                        icon: _isProcessing\n                            ? SizedBox(\n                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: bg))\n                            : Icon(widget.trimMode ? Icons.content_cut_rounded : Icons.notifications_active_rounded,\n                                size: 20),\n                        label: Text(widget.trimMode ? '잘라서 저장' : '벨소리로 지정',\n                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n            ),\n      body: SingleChildScrollView(\n        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            section(AppLocalizations.of(context)!.selectSong),\n            whiteCard(\n              DropdownButtonHideUnderline(\n                child: DropdownButton<Song>(\n                  value: _selectedSong,\n                  hint: Text(AppLocalizations.of(context)!.searchHint, style: TextStyle(color: sub)),\n                  isExpanded: true,\n                  dropdownColor: card,\n                  borderRadius: BorderRadius.circular(14),\n                  icon: Icon(Icons.expand_more_rounded, color: sub),\n                  items: songs.map((song) {\n                    return DropdownMenuItem<Song>(\n                      value: song,\n                      child: Text(song.titleDisplay,\n                          style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600),\n                          maxLines: 1,\n                          overflow: TextOverflow.ellipsis),\n                    );\n                  }).toList(),\n                  onChanged: (song) {\n                    setState(() {\n                      _selectedSong = song;\n                      _startValue = 0.0;\n                      _endValue = song != null\n                          ? (widget.trimMode\n                              ? (song.duration / 1000).toDouble()\n                              : (song.duration / 1000).clamp(0, 60).toDouble())\n                          : 30.0;\n                      _isPlaying = false;\n                    });\n                    _previewPlayer.stop();\n                  },\n                ),\n              ),\n              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),\n            ),\n            if (_selectedSong != null) ...[\n              section(AppLocalizations.of(context)!.selectRange),\n              whiteCard(\n                Column(\n                  children: [\n                    rangeRow(AppLocalizations.of(context)!.start, _startValue, (value) {\n                      if (value < _endValue) {\n                        setState(() {\n                          _startValue = value;\n                          _isPlaying = false;\n                        });\n                        _previewPlayer.stop();\n                      }\n                    }),\n                    rangeRow(AppLocalizations.of(context)!.end, _endValue, (value) {\n                      if (value > _startValue) {\n                        setState(() {\n                          _endValue = value;\n                          _isPlaying = false;\n                        });\n                        _previewPlayer.stop();\n                      }\n                    }),\n                    const SizedBox(height: 6),\n                    Row(\n                      mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                      children: [\n                        timeChip(_formatTime(_startValue.toInt())),\n                        Text('${(_endValue - _startValue).toInt()}초',\n                            style: TextStyle(color: sub, fontSize: 12.5)),\n                        timeChip(_formatTime(_endValue.toInt())),\n                      ],\n                    ),\n                  ],\n                ),\n                padding: const EdgeInsets.fromLTRB(10, 10, 14, 14),\n              ),\n            ],\n          ],\n        ),\n      ),\n    );\n  }"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_screen1")

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
    print("   문제가 있으면 backup_screen1 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
