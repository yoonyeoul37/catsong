# -*- coding: utf-8 -*-
# 아침 알람: 알람 소리에 "한 곡" 추가
# - 맨 위 "한 곡" → 곡 고르기 창 (위에 검색칸, 제목·가수로 찾기)
# - 고른 곡은 [끄기] 누를 때까지 반복 (알람이 끝나면 원래 반복 설정으로 돌려놓기)
# - 그 곡이 지워졌으면 음악 전체 랜덤으로 대신
# (apply_alarm3.py 까지 실행한 뒤에)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SCREEN = os.path.join(ROOT, 'lib', 'screens', 'alarm_screen.dart')
RING = os.path.join(ROOT, 'lib', 'screens', 'alarm_ring_screen.dart')

PICK_SONG = r"""  /// 한 곡 고르기 (검색칸 + 곡 목록)
  void _pickSong() {
    final music = context.read<MusicProvider>();
    final all = music.allSongs.where((s) => !music.isCallRecordingPath(s.uri)).toList();
    if (all.isEmpty) {
      showParanToast(context, '폰에 있는 노래가 없어요');
      return;
    }
    final d = context.read<ThemeProvider>().isDarkMode;
    final point = context.read<ThemeProvider>().primaryColor;
    final sheet = d ? const Color(0xFF2B2926) : const Color(0xFFF4EFE5);
    final card = d ? const Color(0xFF32302C) : Colors.white;
    final ink = d ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final hint = d ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final line = d ? const Color(0xFF4A4640) : const Color(0xFFE2DACB);
    var q = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // 키보드 위로
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          decoration: BoxDecoration(color: sheet, borderRadius: BorderRadius.circular(22)),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              final key = q.trim().toLowerCase();
              final list = key.isEmpty
                  ? all
                  : all
                      .where((s) =>
                          s.titleDisplay.toLowerCase().contains(key) || s.artistDisplay.toLowerCase().contains(key))
                      .toList();
              return Column(
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
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text('알람 곡 고르기',
                              style: TextStyle(
                                  color: ink, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        ),
                      ),
                      ParanCloseX(onTap: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setSheet(() => q = v),
                    style: TextStyle(color: ink, fontSize: 14.5),
                    cursorColor: ink,
                    decoration: InputDecoration(
                      hintText: '제목이나 가수로 찾기',
                      hintStyle: TextStyle(color: hint, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: hint, size: 20),
                      filled: true,
                      fillColor: card,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 10),
                  Expanded(
                    child: list.isEmpty
                        ? Center(child: Text('찾는 곡이 없어요', style: TextStyle(color: hint, fontSize: 13)))
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final s = list[i];
                              final sel = _a.kind == 'song' && _a.refId == s.uri;
                              return InkWell(
                                onTap: () {
                                  _vib();
                                  setState(() {
                                    _a.kind = 'song';
                                    _a.refId = s.uri;
                                    _a.label = '${s.titleDisplay} · ${s.artistDisplay}';
                                    _a.station = null;
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.titleDisplay,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: ink,
                                                    fontSize: 14.5,
                                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                                            const SizedBox(height: 2),
                                            Text(s.artistDisplay,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: hint, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      if (sel) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.check_circle_rounded, size: 20, color: point),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _pickPlaylist() {
"""

SCREEN_EDITS = [
    ('알람 화면: 노래 목록 불러오기',
     "import '../providers/player_provider.dart';\n",
     "import '../providers/player_provider.dart';\n"
     "import '../providers/music_provider.dart';\n"),
    ('알람 화면: 한 곡 고르기 창',
     "  void _pickPlaylist() {\n",
     PICK_SONG),
    ('알람 화면: 맨 위 "한 곡"',
     "                      soundRow(Icons.shuffle_rounded, '음악 전체 랜덤', _a.kind == 'music_all',\n",
     "                      soundRow(Icons.music_note_rounded, '한 곡', _a.kind == 'song', _pickSong,\n"
     "                          sub: _a.kind == 'song' ? _a.label : '고른 노래 하나를 반복해서', more: true),\n"
     "                      soundRow(Icons.shuffle_rounded, '음악 전체 랜덤', _a.kind == 'music_all',\n"),
]

RING_EDITS = [
    ('알람: 반복 설정 불러오기',
     "import 'package:provider/provider.dart';\n",
     "import 'package:provider/provider.dart';\n"
     "import 'package:just_audio/just_audio.dart' show LoopMode;\n"),
    ('알람: 원래 반복 설정 기억',
     "  Timer? _auto; // 10분 지나도 안 끄면 5분 뒤 다시\n",
     "  Timer? _auto; // 10분 지나도 안 끄면 5분 뒤 다시\n"
     "  LoopMode? _prevLoop; // 한 곡 반복 전 반복 설정 (알람 끝나면 돌려놓기)\n"),
    ('알람: 한 곡 찾기',
     "    if (_a.kind == 'music_fav') {\n"
     "      list = music.favorites;\n",
     "    if (_a.kind == 'song') {\n"
     "      // 한 곡 (지워졌으면 아래에서 전체 곡으로)\n"
     "      final found = music.allSongs.where((s) => s.uri == _a.refId);\n"
     "      list = found.isNotEmpty ? [found.first] : const [];\n"
     "    } else if (_a.kind == 'music_fav') {\n"
     "      list = music.favorites;\n"),
    ('알람: 한 곡이면 반복',
     "          await _setVol(_vol);\n"
     "          await player.playFromList(songs, 0);\n"
     "          ok = true;\n",
     "          await _setVol(_vol);\n"
     "          // 한 곡이면 끌 때까지 반복\n"
     "          if (_a.kind == 'song' && songs.length == 1 && songs.first.uri == _a.refId) {\n"
     "            _prevLoop = player.loopMode;\n"
     "            player.setLoopMode(LoopMode.one);\n"
     "          }\n"
     "          await player.playFromList(songs, 0);\n"
     "          ok = true;\n"),
    ('알람: 끝나면 반복 설정 원래대로',
     "    if (phone && _origVol != null) await AlarmService.setMusicVolume(_origVol!);\n",
     "    if (phone && _origVol != null) await AlarmService.setMusicVolume(_origVol!);\n"
     "    if (_prevLoop != null && mounted) {\n"
     "      context.read<PlayerProvider>().setLoopMode(_prevLoop!);\n"
     "      _prevLoop = null;\n"
     "    }\n"),
    ('알람: 한 곡 아이콘',
     "    if (_a.kind == 'music_fav') return Icons.favorite_border_rounded;\n",
     "    if (_a.kind == 'music_fav') return Icons.favorite_border_rounded;\n"
     "    if (_a.kind == 'song') return Icons.music_note_rounded;\n"),
]

MARK = "_pickSong"


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
    for p in (SCREEN, RING):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if MARK in open(SCREEN, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in ((SCREEN, SCREEN_EDITS), (RING, RING_EDITS)):
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
