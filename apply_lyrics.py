# -*- coding: utf-8 -*-
# 4단계: 가사
# - 가사 없을 때 화면: 유리 카드 + "이 노래 가사를 아직 못 찾았어요" + [다시 찾기] [직접 넣기]
# - 직접 넣기: 붙여넣기 창 (노래마다 저장, 인터넷 가사보다 먼저 나옴)
#   [00:12.34] 처럼 시간이 있는 .lrc 글이면 노래에 맞춰 한 줄씩 나와요
# - ⋮ 메뉴: 가사 직접 넣기/고치기 · 직접 넣은 가사 지우기
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PROV = os.path.join(ROOT, 'lib', 'providers', 'lyrics_provider.dart')
SCREEN = os.path.join(ROOT, 'lib', 'screens', 'lyrics_screen.dart')

PROV_EDITS = [
    ('가사 담당: 직접 넣은 가사 표시',
     "  String get currentSongKey => _currentSongKey;\n",
     "  String get currentSongKey => _currentSongKey;\n"
     "\n"
     "  // ───── 직접 넣은 가사 (노래마다 저장, 인터넷 가사보다 먼저) ─────\n"
     "  bool _manual = false;\n"
     "  bool get hasManual => _manual;\n"
     "\n"
     "  /// 고치기 창에 넣을 지금 가사 (시간 있는 가사는 [00:12.34] 모양 그대로)\n"
     "  String get editableText {\n"
     "    if (_lyrics.isNotEmpty && !isEstimated) {\n"
     "      String two(int n) => n.toString().padLeft(2, '0');\n"
     "      return _lyrics.map((l) {\n"
     "        final t = l.time;\n"
     "        return '[${two(t.inMinutes)}:${two(t.inSeconds % 60)}.${two((t.inMilliseconds % 1000) ~/ 10)}]${l.text}';\n"
     "      }).join('\\n');\n"
     "    }\n"
     "    return _plainLyrics;\n"
     "  }\n"),
    ('가사 담당: 직접 넣은 가사를 제일 먼저',
     "    _currentLineIndex = 0;\n"
     "    notifyListeners();\n"
     "\n"
     "    try {\n"
     "      if (filePath != null) {\n",
     "    _currentLineIndex = 0;\n"
     "    _manual = false;\n"
     "    notifyListeners();\n"
     "\n"
     "    try {\n"
     "      // ⓪ 직접 넣은 가사가 있으면 제일 먼저\n"
     "      final manual = await _readManual(songKey);\n"
     "      if (manual != null && _applyText(manual)) {\n"
     "        _manual = true;\n"
     "        return;\n"
     "      }\n"
     "\n"
     "      if (filePath != null) {\n"),
    ('가사 담당: 저장·지우기',
     "  /// 찾은 가사는 폰에 저장 → 다음엔 인터넷 없이 바로\n",
     "  /// 글 하나를 가사로 넣기 ([00:12] 같은 시간이 있으면 노래에 맞춰 나오는 가사)\n"
     "  bool _applyText(String text) {\n"
     "    final isLrc = RegExp(r'\\[\\d{1,2}:\\d{2}').hasMatch(text);\n"
     "    return _applyFound(isLrc ? {'syncedLyrics': text, 'plainLyrics': text} : {'plainLyrics': text});\n"
     "  }\n"
     "\n"
     "  Future<String?> _readManual(String key) async {\n"
     "    try {\n"
     "      final p = await SharedPreferences.getInstance();\n"
     "      final s = p.getString('lyricsManual_$key');\n"
     "      return (s == null || s.trim().isEmpty) ? null : s;\n"
     "    } catch (_) {\n"
     "      return null;\n"
     "    }\n"
     "  }\n"
     "\n"
     "  /// 직접 넣은 가사 저장 → 바로 화면에\n"
     "  Future<void> saveManualLyrics(String title, String artist, String text) async {\n"
     "    final t = text.trim();\n"
     "    if (t.isEmpty) return;\n"
     "    final key = '$title-$artist';\n"
     "    final p = await SharedPreferences.getInstance();\n"
     "    await p.setString('lyricsManual_$key', t);\n"
     "    _currentSongKey = key;\n"
     "    _lyrics = [];\n"
     "    _plainLyrics = '';\n"
     "    _estimatedFor = '';\n"
     "    _errorMessage = '';\n"
     "    _currentLineIndex = 0;\n"
     "    _isLoading = false;\n"
     "    _hasLyrics = false;\n"
     "    _manual = _applyText(t);\n"
     "    notifyListeners();\n"
     "  }\n"
     "\n"
     "  /// 직접 넣은 가사 지우기 → 인터넷에서 다시 찾기\n"
     "  Future<void> deleteManualLyrics(String title, String artist, {String? filePath}) async {\n"
     "    final p = await SharedPreferences.getInstance();\n"
     "    await p.remove('lyricsManual_$title-$artist');\n"
     "    _manual = false;\n"
     "    _estimatedFor = '';\n"
     "    await fetchLyrics(title, artist, filePath: filePath, force: true);\n"
     "  }\n"
     "\n"
     "  /// 찾은 가사는 폰에 저장 → 다음엔 인터넷 없이 바로\n"),
]

EMPTY_OLD = (
    "    if (!lyricsProvider.hasLyrics) {\n"
    "      return Center(\n"
    "        child: Padding(\n"
    "          padding: const EdgeInsets.symmetric(horizontal: 24),\n"
    "          child: Column(\n"
    "            mainAxisAlignment: MainAxisAlignment.center,\n"
    "            children: [\n"
    "              Icon(Icons.lyrics_outlined, size: 64, color: ink.withOpacity(0.45)),\n"
    "              const SizedBox(height: 16),\n"
    "              Text(\n"
    "                lyricsProvider.errorMessage.isEmpty\n"
    "                    ? AppLocalizations.of(context)!.lyricsSearchPrompt\n"
    "                    : lyricsProvider.errorMessage,\n"
    "                textAlign: TextAlign.center,\n"
    "                style: TextStyle(color: sub, fontSize: 15.5, shadows: shadow),\n"
    "              ),\n"
    "              const SizedBox(height: 24),\n"
    "              ElevatedButton(\n"
    "                onPressed: () {\n"
    "                  final song = playerProvider.currentSong;\n"
    "                  if (song != null) {\n"
    "                    lyricsProvider.fetchLyrics(song.titleDisplay, song.artistDisplay);\n"
    "                  }\n"
    "                },\n"
    "                style: ElevatedButton.styleFrom(\n"
    "                  backgroundColor: ink.withOpacity(_light ? 0.9 : 0.18),\n"
    "                  foregroundColor: _light ? const Color(0xFFF4EFE5) : Colors.white,\n"
    "                  elevation: 0,\n"
    "                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),\n"
    "                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),\n"
    "                ),\n"
    "                child: Text(AppLocalizations.of(context)!.lyricsSearchButton,\n"
    "                    style: const TextStyle(fontWeight: FontWeight.bold)),\n"
    "              ),\n"
    "            ],\n"
    "          ),\n"
    "        ),\n"
    "      );\n"
    "    }\n")
EMPTY_NEW = (
    "    if (!lyricsProvider.hasLyrics) {\n"
    "      // 가사 없을 때: 유리 카드 하나에 안내 + [다시 찾기] [직접 넣기]\n"
    "      final noNet = lyricsProvider.errorMessage.isNotEmpty &&\n"
    "          lyricsProvider.errorMessage == AppLocalizations.of(context)!.lyricsErrorNetwork;\n"
    "      final fillBg = _light ? const Color(0xFF17140F) : const Color(0xFFF4EFE5); // 꽉 찬 버튼\n"
    "      final fillFg = _light ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);\n"
    "      return Center(\n"
    "        child: Padding(\n"
    "          padding: const EdgeInsets.symmetric(horizontal: 28),\n"
    "          child: ClipRRect(\n"
    "            borderRadius: BorderRadius.circular(22),\n"
    "            child: BackdropFilter(\n"
    "              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),\n"
    "              child: Container(\n"
    "                width: double.infinity,\n"
    "                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),\n"
    "                decoration: BoxDecoration(\n"
    "                  color: _light ? Colors.white.withOpacity(0.38) : Colors.black.withOpacity(0.28),\n"
    "                  borderRadius: BorderRadius.circular(22),\n"
    "                  border: Border.all(color: ink.withOpacity(0.08)),\n"
    "                ),\n"
    "                child: Column(\n"
    "                  mainAxisSize: MainAxisSize.min,\n"
    "                  children: [\n"
    "                    Container(\n"
    "                      width: 48,\n"
    "                      height: 48,\n"
    "                      decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withOpacity(0.08)),\n"
    "                      child: Icon(Icons.music_note_rounded, size: 22, color: ink.withOpacity(0.7)),\n"
    "                    ),\n"
    "                    const SizedBox(height: 16),\n"
    "                    Text(\n"
    "                      noNet ? '인터넷 연결을 확인해 주세요' : '이 노래 가사를 아직 못 찾았어요',\n"
    "                      textAlign: TextAlign.center,\n"
    "                      style: TextStyle(\n"
    "                          color: ink, fontSize: 16.5, fontWeight: FontWeight.w700, letterSpacing: -0.3, shadows: shadow),\n"
    "                    ),\n"
    "                    const SizedBox(height: 6),\n"
    "                    Text(\n"
    "                      noNet ? '연결되면 다시 찾아볼 수 있어요' : '다시 찾거나, 가사를 직접 넣을 수 있어요',\n"
    "                      textAlign: TextAlign.center,\n"
    "                      style: TextStyle(color: sub, fontSize: 13, height: 1.4, shadows: shadow),\n"
    "                    ),\n"
    "                    const SizedBox(height: 22),\n"
    "                    Row(\n"
    "                      children: [\n"
    "                        Expanded(\n"
    "                          child: SizedBox(\n"
    "                            height: 46,\n"
    "                            child: ElevatedButton(\n"
    "                              onPressed: () {\n"
    "                                final song = playerProvider.currentSong;\n"
    "                                if (song != null) {\n"
    "                                  lyricsProvider.fetchLyrics(song.titleDisplay, song.artistDisplay,\n"
    "                                      filePath: song.uri, force: true);\n"
    "                                }\n"
    "                              },\n"
    "                              style: ElevatedButton.styleFrom(\n"
    "                                backgroundColor: fillBg,\n"
    "                                foregroundColor: fillFg,\n"
    "                                elevation: 0,\n"
    "                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n"
    "                              ),\n"
    "                              child: const Text('다시 찾기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),\n"
    "                            ),\n"
    "                          ),\n"
    "                        ),\n"
    "                        const SizedBox(width: 10),\n"
    "                        Expanded(\n"
    "                          child: SizedBox(\n"
    "                            height: 46,\n"
    "                            child: OutlinedButton(\n"
    "                              onPressed: () => _editLyrics(lyricsProvider, playerProvider),\n"
    "                              style: OutlinedButton.styleFrom(\n"
    "                                foregroundColor: ink,\n"
    "                                side: BorderSide(color: ink.withOpacity(0.35), width: 1.2),\n"
    "                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),\n"
    "                              ),\n"
    "                              child: const Text('직접 넣기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),\n"
    "                            ),\n"
    "                          ),\n"
    "                        ),\n"
    "                      ],\n"
    "                    ),\n"
    "                  ],\n"
    "                ),\n"
    "              ),\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "      );\n"
    "    }\n")

EDIT_SHEET = r"""
  /// ✏ 가사 직접 넣기·고치기 창 (붙여넣기 → 저장, 노래마다 기억)
  Future<void> _editLyrics(LyricsProvider lp, PlayerProvider pp) async {
    final song = pp.currentSong;
    if (song == null) return;
    final ctrl = TextEditingController(text: lp.hasLyrics ? lp.editableText : '');
    final dark = context.read<ThemeProvider>().isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final onInk = dark ? const Color(0xFF17140F) : const Color(0xFFF4EFE5);
    final card = dark ? const Color(0xFF26221C) : Colors.white;
    final line = dark ? const Color(0xFF3A342B) : const Color(0xFFE2DACB);
    final sheet = dark ? const Color(0xFF1F1C18) : const Color(0xFFF4EFE5);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // 키보드 위로
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(color: sheet, borderRadius: BorderRadius.circular(22)),
            child: StatefulBuilder(
              builder: (ctx, setSheet) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lp.hasManual ? '가사 직접 고치기' : '가사 직접 넣기',
                                  style: TextStyle(
                                      color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                              const SizedBox(height: 3),
                              Text('${song.titleDisplay} · ${song.artistDisplay}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: sub, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ),
                      ParanCloseX(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    minLines: 8,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    onChanged: (_) => setSheet(() {}),
                    style: TextStyle(color: ink, fontSize: 14.5, height: 1.5),
                    cursorColor: ink,
                    decoration: InputDecoration(
                      hintText: '가사를 붙여넣어 주세요\n[00:12.34] 처럼 시간이 있으면 노래에 맞춰 나와요',
                      hintMaxLines: 3,
                      hintStyle: TextStyle(color: sub, fontSize: 13.5, height: 1.5),
                      filled: true,
                      fillColor: card,
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: ink, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final d = await Clipboard.getData('text/plain');
                          final t = d?.text ?? '';
                          if (t.trim().isEmpty) return;
                          ctrl.text = t;
                          setSheet(() {});
                        },
                        style: TextButton.styleFrom(foregroundColor: ink),
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        label: const Text('붙여넣기', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      if (ctrl.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            ctrl.clear();
                            setSheet(() {});
                          },
                          style: TextButton.styleFrom(foregroundColor: sub),
                          child: const Text('비우기'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: ctrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: onInk,
                        disabledBackgroundColor: ink.withOpacity(0.15),
                        disabledForegroundColor: sub,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (saved == true) {
      await lp.saveManualLyrics(song.titleDisplay, song.artistDisplay, ctrl.text);
      if (mounted) showParanToast(context, '이 노래 가사로 저장했어요');
    }
  }

  /// 직접 넣은 가사 지우기 (지우면 인터넷에서 다시 찾기)
  Future<void> _deleteManual(LyricsProvider lp, PlayerProvider pp) async {
    final song = pp.currentSong;
    if (song == null) return;
    final ok = await showParanConfirm(
      context,
      title: '직접 넣은 가사를 지울까요?',
      message: '지우면 인터넷에서 다시 찾아요',
      confirmLabel: '지우기',
      danger: true,
    );
    if (!ok) return;
    await lp.deleteManualLyrics(song.titleDisplay, song.artistDisplay, filePath: song.uri);
  }

  /// 🖼 배경 고르기 창
"""

SCREEN_EDITS = [
    ('가사 없을 때 화면: 유리 카드 + 버튼 두 개', EMPTY_OLD, EMPTY_NEW),
    ('직접 넣기 창 · 지우기',
     "\n  /// 🖼 배경 고르기 창\n",
     EDIT_SHEET),
    ('⋮ 메뉴: 직접 넣기·고치기·지우기 (누르면)',
     "                  if (v == 'offset') _pickOffset(lp);\n",
     "                  if (v == 'offset') _pickOffset(lp);\n"
     "                  if (v == 'edit') _editLyrics(lp, pp);\n"
     "                  if (v == 'delete') _deleteManual(lp, pp);\n"),
    ('⋮ 메뉴: 직접 넣기·고치기·지우기 (목록)',
     "                  _menuItem(Icons.refresh, '가사 다시 찾기', 'refresh'),\n",
     "                  // 직접 넣은 가사가 있으면 그게 먼저라서 \"다시 찾기\" 대신 \"지우기\"\n"
     "                  if (!lp.hasManual) _menuItem(Icons.refresh, '가사 다시 찾기', 'refresh'),\n"
     "                  _menuItem(Icons.edit_note_rounded, lp.hasManual ? '가사 직접 고치기' : '가사 직접 넣기', 'edit'),\n"
     "                  if (lp.hasManual) _menuItem(Icons.delete_outline_rounded, '직접 넣은 가사 지우기', 'delete'),\n"),
]

MARK = 'lyricsManual_'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    for p in (PROV, SCREEN):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(PROV, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in ((PROV, PROV_EDITS), (SCREEN, SCREEN_EDITS)):
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
