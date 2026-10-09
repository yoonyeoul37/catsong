# 가사 화면 "가사를 못 찾았어요" 카드에 ✕ 닫기 넣기
import os, sys

PATH = os.path.join('lib', 'screens', 'lyrics_screen.dart')

EDITS = [
    ('닫은 노래 기억하는 칸 넣기',
     "  List<String> _myPhotos = []; // 가사 배경용 내 사진 목록\n",
     "  List<String> _myPhotos = []; // 가사 배경용 내 사진 목록\n"
     "  String? _hideNoLyricsFor; // ✕로 닫은 \"가사 못 찾았어요\" 카드 (노래가 바뀌면 다시 나와요)\n"),
    ('닫았으면 카드 안 띄우기',
     "    if (!lyricsProvider.hasLyrics) {\n"
     "      // 가사 없을 때: 유리 카드 하나에 안내 + [다시 찾기] [직접 넣기]\n",
     "    if (!lyricsProvider.hasLyrics) {\n"
     "      // ✕로 닫았으면 이 노래에서는 안 띄움 (⋮ 메뉴에 다시 찾기·직접 넣기가 있어요)\n"
     "      final songKey = playerProvider.currentSong?.uri ?? '';\n"
     "      if (_hideNoLyricsFor == songKey) return const SizedBox.shrink();\n"
     "      // 가사 없을 때: 유리 카드 하나에 안내 + [다시 찾기] [직접 넣기]\n"),
    ('카드 오른쪽 위 ✕ 넣기',
     "                    Container(\n"
     "                      width: 48,\n"
     "                      height: 48,\n"
     "                      decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withOpacity(0.08)),\n"
     "                      child: Icon(Icons.music_note_rounded, size: 22, color: ink.withOpacity(0.7)),\n"
     "                    ),\n",
     "                    SizedBox(\n"
     "                      width: double.infinity,\n"
     "                      height: 48,\n"
     "                      child: Stack(\n"
     "                        alignment: Alignment.center,\n"
     "                        children: [\n"
     "                          Container(\n"
     "                            width: 48,\n"
     "                            height: 48,\n"
     "                            decoration: BoxDecoration(shape: BoxShape.circle, color: ink.withOpacity(0.08)),\n"
     "                            child: Icon(Icons.music_note_rounded, size: 22, color: ink.withOpacity(0.7)),\n"
     "                          ),\n"
     "                          // ✕ 닫기 (동그라미 없이 ✕만)\n"
     "                          Positioned(\n"
     "                            right: 0,\n"
     "                            top: 0,\n"
     "                            child: GestureDetector(\n"
     "                              behavior: HitTestBehavior.opaque,\n"
     "                              onTap: () {\n"
     "                                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n"
     "                                setState(() => _hideNoLyricsFor = playerProvider.currentSong?.uri ?? '');\n"
     "                              },\n"
     "                              child: Padding(\n"
     "                                padding: const EdgeInsets.all(4),\n"
     "                                child: Icon(Icons.close_rounded, size: 20, color: ink.withOpacity(0.6)),\n"
     "                              ),\n"
     "                            ),\n"
     "                          ),\n"
     "                        ],\n"
     "                      ),\n"
     "                    ),\n"),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        print('   프로젝트 맨 바깥 폴더(mp3_player_new)에서 실행해 주세요.')
        sys.exit(1)
    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    t = raw.replace('\r\n', '\n')
    if '_hideNoLyricsFor' in t:
        print('이미 적용돼 있어요')
        return
    ok = True
    for name, old, new in EDITS:
        if t.count(old) != 1:
            print('❌', name)
            ok = False
            continue
        t = t.replace(old, new)
        print('✔', name)
    if not ok:
        print('\n못 찾은 곳이 있어서 아무것도 저장하지 않았어요.')
        sys.exit(1)
    if crlf:
        t = t.replace('\n', '\r\n')
    open(PATH, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요.')

main()
