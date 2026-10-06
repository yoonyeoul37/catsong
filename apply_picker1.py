# 파란소리: 고르는 창 통일 1 (재생목록에 추가·곡 정보·글꼴·글자 크기·시작 화면)
# 실행: C:\apps\mp3_player_new 에서  python apply_picker1.py
# - 바꿀 곳이 전부 있는지 먼저 확인하고, 하나라도 없으면 아무것도 안 바꿔요
# - 바꾼 파일의 원본은 backup_picker1 폴더에 저장돼요
import os, sys, json, shutil
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

DATA = json.loads(r"""{"ops": [["str", "widgets/paran_dialog.dart", "import 'package:flutter/material.dart';\n", "import 'dart:typed_data';\nimport 'package:flutter/material.dart';\n"], ["str", "widgets/paran_dialog.dart", "  return r == 1 && text.isNotEmpty ? text : null;\n}", "  return r == 1 && text.isNotEmpty ? text : null;\n}\n\n// ───────────────────────── 고르는 창 ─────────────────────────\n\n/// 고르는 창 (아래에서 올라오는 베이지 카드 + 손잡이 + 제목 + 내용 + 닫기)\n/// builder 안에서 setSheet(() {}) 를 부르면 창 안이 다시 그려져요\nFuture<T?> showParanSheet<T>(\n  BuildContext context, {\n  required String title,\n  required Widget Function(BuildContext ctx, StateSetter setSheet) builder,\n  Widget? header, // 제목 대신 넣을 머리 (곡 정보처럼 사진+제목)\n  String closeLabel = '닫기',\n}) {\n  final p = _Pal.of(context);\n  return showModalBottomSheet<T>(\n    context: context,\n    isScrollControlled: true,\n    backgroundColor: Colors.transparent,\n    builder: (ctx) => SafeArea(\n      top: false,\n      child: Container(\n        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),\n        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),\n        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),\n        decoration: BoxDecoration(color: p.sheet, borderRadius: BorderRadius.circular(22)),\n        child: StatefulBuilder(\n          builder: (ctx, setSheet) => Column(\n            mainAxisSize: MainAxisSize.min,\n            crossAxisAlignment: CrossAxisAlignment.start,\n            children: [\n              Center(\n                child: Container(\n                  width: 36,\n                  height: 4,\n                  decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),\n                ),\n              ),\n              const SizedBox(height: 14),\n              header ??\n                  Padding(\n                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),\n                    child: Text(title,\n                        style: TextStyle(color: p.ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                  ),\n              Flexible(child: SingleChildScrollView(child: builder(ctx, setSheet))),\n              SizedBox(\n                width: double.infinity,\n                child: TextButton(\n                  onPressed: () => Navigator.pop(ctx),\n                  style: TextButton.styleFrom(foregroundColor: p.sub),\n                  child: Text(closeLabel, style: const TextStyle(fontSize: 14)),\n                ),\n              ),\n            ],\n          ),\n        ),\n      ),\n    ),\n  );\n}\n\n/// 고르는 창 안의 흰 카드 (줄 사이 얇은 선)\nclass ParanCard extends StatelessWidget {\n  final List<Widget> children;\n  final EdgeInsetsGeometry? padding;\n  const ParanCard({super.key, required this.children, this.padding});\n\n  @override\n  Widget build(BuildContext context) {\n    final p = _Pal.of(context);\n    return Container(\n      margin: const EdgeInsets.only(bottom: 10),\n      padding: padding,\n      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.stretch,\n        children: [\n          for (var i = 0; i < children.length; i++) ...[\n            if (i > 0 && padding == null) Container(height: 0.5, margin: const EdgeInsets.only(left: 46), color: p.line),\n            children[i],\n          ],\n        ],\n      ),\n    );\n  }\n}\n\n/// 카드 안의 한 줄 (아이콘 · 글자 · 오른쪽 작은 글씨 · 고르면 파란 ✓)\nclass ParanRow extends StatelessWidget {\n  final IconData? icon;\n  final String title;\n  final String? trailingText;\n  final bool selected;\n  final bool accent; // 글자를 파랗게 (예: 새로 만들기)\n  final VoidCallback? onTap;\n  const ParanRow({\n    super.key,\n    this.icon,\n    required this.title,\n    this.trailingText,\n    this.selected = false,\n    this.accent = false,\n    this.onTap,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    final p = _Pal.of(context);\n    return InkWell(\n      onTap: onTap == null\n          ? null\n          : () {\n              _vib();\n              onTap!();\n            },\n      child: Padding(\n        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),\n        child: Row(\n          children: [\n            if (icon != null) ...[\n              SizedBox(width: 22, child: Icon(icon, color: _kBlue, size: 20)),\n              const SizedBox(width: 10),\n            ],\n            Expanded(\n              child: Text(title,\n                  maxLines: 1,\n                  overflow: TextOverflow.ellipsis,\n                  style: TextStyle(\n                    color: accent || selected ? _kBlue : p.ink,\n                    fontSize: 14,\n                    fontWeight: accent || selected ? FontWeight.w700 : FontWeight.w500,\n                  )),\n            ),\n            if (trailingText != null) ...[\n              const SizedBox(width: 8),\n              Text(trailingText!, style: TextStyle(color: p.sub, fontSize: 12.5)),\n            ],\n            if (selected) ...[\n              const SizedBox(width: 8),\n              const Icon(Icons.check_circle_rounded, color: _kBlue, size: 20),\n            ],\n          ],\n        ),\n      ),\n    );\n  }\n}\n\n/// 정보 한 줄 (왼쪽 이름 · 오른쪽 값) — 곡 정보 등\nclass ParanInfoRow extends StatelessWidget {\n  final String label;\n  final String value;\n  const ParanInfoRow({super.key, required this.label, required this.value});\n\n  @override\n  Widget build(BuildContext context) {\n    final p = _Pal.of(context);\n    return Padding(\n      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),\n      child: Row(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          SizedBox(width: 64, child: Text(label, style: TextStyle(color: p.sub, fontSize: 13))),\n          Expanded(child: Text(value, style: TextStyle(color: p.ink, fontSize: 13.5, height: 1.4))),\n        ],\n      ),\n    );\n  }\n}\n\n/// 고르는 창 안의 큰 파란 버튼 (확인창 버튼과 같은 모양)\nclass ParanBigButton extends StatelessWidget {\n  final String label;\n  final VoidCallback onPressed;\n  const ParanBigButton({super.key, required this.label, required this.onPressed});\n\n  @override\n  Widget build(BuildContext context) {\n    return Padding(\n      padding: const EdgeInsets.only(top: 4),\n      child: SizedBox(\n        width: double.infinity,\n        height: 50,\n        child: ElevatedButton(\n          onPressed: () {\n            _vib();\n            onPressed();\n          },\n          style: ElevatedButton.styleFrom(\n            backgroundColor: _kBlue,\n            foregroundColor: Colors.white,\n            elevation: 6,\n            shadowColor: _kBlue.withOpacity(0.4),\n            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n          ),\n          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),\n        ),\n      ),\n    );\n  }\n}\n\n/// 곡 정보 창 머리 (앨범 사진 + 제목 + 가수)\nclass ParanSongHeader extends StatelessWidget {\n  final List<int>? art;\n  final String title;\n  final String subtitle;\n  const ParanSongHeader({super.key, this.art, required this.title, required this.subtitle});\n\n  @override\n  Widget build(BuildContext context) {\n    final p = _Pal.of(context);\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),\n      child: Row(\n        children: [\n          ClipRRect(\n            borderRadius: BorderRadius.circular(12),\n            child: SizedBox(\n              width: 56,\n              height: 56,\n              child: art != null\n                  ? Image.memory(Uint8List.fromList(art!), fit: BoxFit.cover)\n                  : Container(\n                      color: _kBlue.withOpacity(0.15),\n                      child: const Icon(Icons.music_note_rounded, color: _kBlue, size: 26),\n                    ),\n            ),\n          ),\n          const SizedBox(width: 12),\n          Expanded(\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Text(title,\n                    maxLines: 2,\n                    overflow: TextOverflow.ellipsis,\n                    style: TextStyle(color: p.ink, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),\n                const SizedBox(height: 3),\n                Text(subtitle,\n                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.sub, fontSize: 13)),\n              ],\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}"], ["str", "widgets/song_list_tile.dart", "import 'paran_dialog.dart';\n", "import 'paran_dialog.dart';\nimport 'playlist_pick_sheet.dart';\n"], ["func", "widgets/song_list_tile.dart", "  void _showAddToPlaylistDialog(BuildContext context, song)", "  void _showAddToPlaylistDialog(BuildContext context, song) {\n    showAddToPlaylistSheet(context, song); // 공통 고르는 창\n  }"], ["func", "widgets/song_list_tile.dart", "  void _showSongInfo(BuildContext context)", "  void _showSongInfo(BuildContext context) {\n    final l = AppLocalizations.of(context)!;\n    final nav = Navigator.of(context, rootNavigator: true);\n    showParanSheet(\n      context,\n      title: l.songInfo,\n      header: ParanSongHeader(art: song.albumArt, title: song.titleDisplay, subtitle: song.artistDisplay),\n      builder: (ctx, setSheet) => Column(\n        children: [\n          ParanCard(children: [\n            ParanInfoRow(label: l.album, value: song.albumDisplay),\n            ParanInfoRow(label: l.playTime, value: song.durationFormatted),\n            if (song.uri != null) ParanInfoRow(label: l.path, value: song.uri!),\n          ]),\n          ParanBigButton(\n            label: l.editSong,\n            onPressed: () {\n              Navigator.pop(ctx);\n              nav.push(MaterialPageRoute(builder: (_) => EditSongScreen(song: song)));\n            },\n          ),\n        ],\n      ),\n    );\n  }"], ["str", "screens/player_screen.dart", "import '../widgets/action_feedback.dart';\n", "import '../widgets/action_feedback.dart';\nimport '../widgets/playlist_pick_sheet.dart';\n"], ["func", "screens/player_screen.dart", "  void _showAddToPlaylistDialog(BuildContext context, Song song, Color primaryColor)", "  void _showAddToPlaylistDialog(BuildContext context, Song song, Color primaryColor) {\n    showAddToPlaylistSheet(context, song); // 공통 고르는 창\n  }"], ["str", "screens/settings_screen.dart", "import '../widgets/paran_toast.dart';\n", "import '../widgets/paran_toast.dart';\nimport '../widgets/paran_dialog.dart';\n"], ["func", "screens/settings_screen.dart", "  void _showFontDialog(BuildContext context)", "  void _showFontDialog(BuildContext context) {\n    final themeProvider = context.read<ThemeProvider>();\n    showParanSheet(\n      context,\n      title: AppLocalizations.of(context)!.fontChange,\n      builder: (ctx, setSheet) => ParanCard(\n        children: [\n          for (final font in ThemeProvider.availableFonts)\n            ParanRow(\n              icon: Icons.font_download_outlined,\n              title: _getFontName(context, font['key']!),\n              selected: themeProvider.fontFamily == font['key'],\n              onTap: () {\n                themeProvider.setFontFamily(font['key']!);\n                Navigator.pop(ctx);\n              },\n            ),\n        ],\n      ),\n    );\n  }"], ["func", "screens/settings_screen.dart", "  void _showTextSizeDialog(BuildContext context)", "  void _showTextSizeDialog(BuildContext context) {\n    final isDarkMode = context.read<ThemeProvider>().isDarkMode;\n    final themeProvider = context.read<ThemeProvider>();\n    const accent = AppTheme.fixedAccent;\n    showParanSheet(\n      context,\n      title: AppLocalizations.of(context)!.textSize,\n      builder: (ctx, setSheet) => Column(\n        children: [\n          // 미리보기\n          ParanCard(\n            padding: const EdgeInsets.all(16),\n            children: [\n              Text(AppLocalizations.of(context)!.preview,\n                  style: TextStyle(color: _sText(isDarkMode), fontSize: 16 * themeProvider.textScale)),\n            ],\n          ),\n          ParanCard(\n            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),\n            children: [\n              SliderTheme(\n                data: SliderTheme.of(context).copyWith(\n                  activeTrackColor: accent,\n                  inactiveTrackColor: accent.withOpacity(0.2),\n                  thumbColor: accent,\n                ),\n                child: Slider(\n                  value: themeProvider.textScale.clamp(1.0, 1.5),\n                  min: 1.0,\n                  max: 1.5,\n                  divisions: 10,\n                  label: '${(themeProvider.textScale * 100).toInt()}%',\n                  onChanged: (value) {\n                    themeProvider.setTextScale(value);\n                    setSheet(() {});\n                  },\n                ),\n              ),\n              Padding(\n                padding: const EdgeInsets.symmetric(horizontal: 12),\n                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [\n                  Text(AppLocalizations.of(context)!.small, style: TextStyle(color: _sTextSub(isDarkMode), fontSize: 12)),\n                  Text('${(themeProvider.textScale * 100).toInt()}%',\n                      style: const TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),\n                  Text(AppLocalizations.of(context)!.large, style: TextStyle(color: _sTextSub(isDarkMode), fontSize: 12)),\n                ]),\n              ),\n            ],\n          ),\n          Align(\n            alignment: Alignment.centerRight,\n            child: TextButton(\n              onPressed: () {\n                themeProvider.setTextScale(1.13);\n                setSheet(() {});\n              },\n              style: TextButton.styleFrom(foregroundColor: accent),\n              child: Text(AppLocalizations.of(context)!.defaultValue,\n                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),\n            ),\n          ),\n        ],\n      ),\n    );\n  }"], ["func", "screens/home_screen.dart", "  void _showSetStartScreenDialog(BuildContext context, StartScreenType type, String label)", "  void _showSetStartScreenDialog(BuildContext context, StartScreenType type, String label) async {\n    final ok = await showParanConfirm(\n      context,\n      title: '앱 시작 화면으로 설정할까요?',\n      message: '파란소리를 실행할 때 이 화면을 가장 먼저 보여드려요.',\n      confirmLabel: '설정하기',\n    );\n    if (!ok || !context.mounted) return;\n    context.read<StartScreenProvider>().setStartScreen(type);\n    showActionFeedback(context, type: ActionFeedbackType.saved);\n  }"]], "new": {"widgets/playlist_pick_sheet.dart": "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';\nimport '../models/song.dart';\nimport '../providers/playlist_provider.dart';\nimport 'paran_dialog.dart';\nimport 'action_feedback.dart';\n\n/// 재생목록에 추가 (곡 목록 ⋮ · 재생화면 ⋮ 같이 씀)\n/// 맨 위 \"새 재생목록 만들기\" → 이름 쓰면 만들고 바로 이 곡을 넣어요\nFuture<void> showAddToPlaylistSheet(BuildContext context, Song song) async {\n  final pp = context.read<PlaylistProvider>();\n  final appCtx = Navigator.of(context, rootNavigator: true).context;\n  await showParanSheet(\n    context,\n    title: '재생목록에 추가',\n    builder: (ctx, setSheet) => ParanCard(\n      children: [\n        ParanRow(\n          icon: Icons.add_rounded,\n          title: '새 재생목록 만들기',\n          accent: true,\n          onTap: () async {\n            Navigator.pop(ctx);\n            final name = await showParanInput(appCtx,\n                title: '새 재생목록', hint: '예) 드라이브할 때', confirmLabel: '만들고 추가');\n            if (name == null) return;\n            await pp.createPlaylist(name);\n            final made = pp.playlists.where((p) => p.name == name).toList();\n            if (made.isEmpty) return;\n            await pp.addSongToPlaylist(made.last.id, song);\n            showActionFeedback(appCtx, type: ActionFeedbackType.added, message: '재생목록에 추가했어요');\n          },\n        ),\n        for (final pl in pp.playlists)\n          ParanRow(\n            icon: Icons.queue_music_rounded,\n            title: pl.name,\n            trailingText: '${pl.songCount}곡',\n            onTap: () {\n              pp.addSongToPlaylist(pl.id, song);\n              Navigator.pop(ctx);\n              showActionFeedback(appCtx, type: ActionFeedbackType.added, message: '재생목록에 추가했어요');\n            },\n          ),\n      ],\n    ),\n  );\n}\n"}}""")

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, "lib")
BACKUP = os.path.join(ROOT, "backup_picker1")

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
    print("   문제가 있으면 backup_picker1 폴더의 원본으로 되돌릴 수 있어요.")

if __name__ == "__main__":
    main()
