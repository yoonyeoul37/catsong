# 파란소리: 화면 통일 3: 곡 정보 편집 (베이지 바탕·흰 카드·먹색 버튼)
# 실행: C:\apps\mp3_player_new 에서  python apply_screen3.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_screen3 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "screens/edit_song_screen.dart", "import 'package:flutter/material.dart';\n", "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n"], ["func", "screens/edit_song_screen.dart", "  Widget build(BuildContext context)", "  Widget build(BuildContext context) {\n    final isDark = context.watch<ThemeProvider>().isDarkMode;\n    // ── 화면 공통 모양 (베이지 바탕 · 흰 카드 · 먹색 큰 버튼) ──\n    final bg = isDark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);\n    final card = isDark ? const Color(0xFF26221C) : Colors.white;\n    final ink = isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);\n    final line = isDark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);\n\n    Widget section(String text) => Padding(\n          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),\n          child: Text(text, style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),\n        );\n\n    return Scaffold(\n      backgroundColor: bg,\n      appBar: AppBar(\n        backgroundColor: bg,\n        elevation: 0,\n        scrolledUnderElevation: 0,\n        titleSpacing: 0,\n        systemOverlayStyle: SystemUiOverlayStyle(\n          statusBarColor: Colors.transparent,\n          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,\n          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,\n          systemNavigationBarColor: bg,\n          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,\n        ),\n        title: Text(AppLocalizations.of(context)!.editSong,\n            style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n        leading: IconButton(\n          onPressed: () => Navigator.pop(context),\n          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 20),\n        ),\n      ),\n      // 버튼은 맨 아래에 모아서: 인터넷에서 찾기(흰) · 저장(먹색)\n      bottomNavigationBar: SafeArea(\n        top: false,\n        child: Padding(\n          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),\n          child: Column(\n            mainAxisSize: MainAxisSize.min,\n            children: [\n              SizedBox(\n                width: double.infinity,\n                height: 48,\n                child: OutlinedButton.icon(\n                  onPressed: _searching ? null : _lookup,\n                  style: OutlinedButton.styleFrom(\n                    backgroundColor: card,\n                    foregroundColor: ink,\n                    side: BorderSide(color: line),\n                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                  ),\n                  icon: _searching\n                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ink))\n                      : const Icon(Icons.travel_explore_rounded, size: 20),\n                  label: Text(_searching ? '찾는 중…' : '인터넷에서 정확한 정보 찾기',\n                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),\n                ),\n              ),\n              const SizedBox(height: 8),\n              SizedBox(\n                width: double.infinity,\n                height: 50,\n                child: ElevatedButton(\n                  onPressed: () => _saveSong(context),\n                  style: ElevatedButton.styleFrom(\n                    backgroundColor: ink,\n                    foregroundColor: bg,\n                    elevation: 6,\n                    shadowColor: Colors.black.withOpacity(0.25),\n                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n                  ),\n                  child: Text(AppLocalizations.of(context)!.save,\n                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n      body: SingleChildScrollView(\n        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            // 앨범 사진: 고른 사진 → 원래 앨범 사진 → 없으면 음표\n            Center(\n              child: ClipRRect(\n                borderRadius: BorderRadius.circular(16),\n                child: SizedBox(\n                  width: 120,\n                  height: 120,\n                  child: _pickedArt != null\n                      ? Image.network(_pickedArt!, fit: BoxFit.cover)\n                      : widget.song.albumArt != null\n                          ? Image.memory(Uint8List.fromList(widget.song.albumArt!), fit: BoxFit.cover)\n                          : Container(\n                              color: card,\n                              child: Icon(Icons.music_note_rounded, color: sub, size: 46),\n                            ),\n                ),\n              ),\n            ),\n            // ✨ 자동 정리 안내 (정리할 게 있을 때만)\n            if (_canClean) ...[\n              const SizedBox(height: 16),\n              Container(\n                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),\n                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),\n                child: Row(\n                  children: [\n                    Icon(Icons.auto_awesome_rounded, color: sub, size: 18),\n                    const SizedBox(width: 10),\n                    Expanded(\n                      child: Text(\n                        _cleanedOn ? '제목·가수를 자동으로 정리했어요' : '원래 제목·가수예요',\n                        style: TextStyle(color: ink, fontSize: 13),\n                      ),\n                    ),\n                    TextButton(\n                      onPressed: _toggleClean,\n                      style: TextButton.styleFrom(foregroundColor: ink),\n                      child: Text(_cleanedOn ? '원래대로' : '다시 정리',\n                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),\n                    ),\n                  ],\n                ),\n              ),\n            ],\n            section('곡 정보'),\n            // 제목 · 아티스트 · 앨범을 흰 카드 하나에\n            Container(\n              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),\n              child: Column(\n                children: [\n                  _field('제목', _titleController, ink, sub),\n                  Divider(height: 1, thickness: 0.5, indent: 16, color: line),\n                  _field('아티스트', _artistController, ink, sub),\n                  Divider(height: 1, thickness: 0.5, indent: 16, color: line),\n                  _field('앨범', _albumController, ink, sub),\n                ],\n              ),\n            ),\n          ],\n        ),\n      ),\n    );\n  }"], ["func", "screens/edit_song_screen.dart", "  Widget _buildTextField(", "  /// 흰 카드 안 한 줄: 위에 작은 이름, 아래에 고칠 글자\n  Widget _field(String label, TextEditingController controller, Color ink, Color sub) {\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Text(label, style: TextStyle(color: sub, fontSize: 12)),\n          TextField(\n            controller: controller,\n            style: TextStyle(color: ink, fontSize: 15.5, fontWeight: FontWeight.w600),\n            cursorColor: ink,\n            decoration: const InputDecoration(\n              isDense: true,\n              border: InputBorder.none,\n              contentPadding: EdgeInsets.symmetric(vertical: 8),\n            ),\n          ),\n        ],\n      ),\n    );\n  }"], ["str", "screens/edit_song_screen.dart", "            color: isDark ? const Color(0xFF26221C) : Colors.white,\n            borderRadius: BorderRadius.circular(22),", "            color: isDark ? const Color(0xFF26221C) : const Color(0xFFF4EFE5), // 다른 고르는 창과 같은 베이지\n            borderRadius: BorderRadius.circular(22),"]], "new": {}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_screen3")

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
    print("   문제가 있으면 backup_screen3 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
