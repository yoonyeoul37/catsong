# -*- coding: utf-8 -*-
# 재생 화면: TV 아이콘을 ⋯ 안으로 (재생 ⋯ · 곡 목록 ⋯ 둘 다) + 로고 정가운데
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
PATH = 'lib/screens/player_screen.dart'
MARK = 'Widget castMenuRow('

TV_OLD = "          AnimatedBuilder(\n            animation: CastService.instance,\n            builder: (context, _) {\n              final cast = CastService.instance;\n              return GestureDetector(\n                behavior: HitTestBehavior.opaque,\n                onTap: () {\n                  const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                  if (song == null) return;\n                  if (cast.isConnected) {\n                    _showCastControl();\n                  } else {\n                    _showCastPicker(song, playerProvider);\n                  }\n                },\n                child: SizedBox(\n                  width: 36,\n                  height: 40,\n                  child: Icon(\n                    Icons.sensors_rounded, // 연결되면 하늘색\n                    color: cast.isConnected ? const Color(0xFF7FB8F0) : baseColor,\n                    size: 19,\n                  ),\n                ),\n              );\n            },\n          ),\n"

EDITS = [
('위 줄 TV 아이콘 빼기', TV_OLD, ''),
('주석 정리',
"""          // TV로 듣기 (연결되면 하늘색 아이콘)
          // 파란포토 사진 고르기""",
"""          // 파란포토 사진 고르기"""),
('로고 정가운데 (왼쪽 폭)',
"""          SizedBox(width: (_albumArtStyle == 6 ? 36.0 * 3 : 36.0 * 2) - 48),""",
"""          // 왼쪽 ⌄(48)와 오른쪽(사진기 36 + ⋯ 36)의 폭을 같게 → 로고가 화면 정가운데
          SizedBox(width: _albumArtStyle == 6 ? 24 : 0),"""),
('TV 연결 중이면 ⋯에 하늘색 점',
"""                  Icon(Icons.more_vert_rounded, color: baseColor, size: 19),
""",
"""                  Icon(Icons.more_vert_rounded, color: baseColor, size: 19),
                  // TV로 듣는 중이면 하늘색 점 (TV는 ⋯ 안에 있어서)
                  Positioned(
                    right: -3,
                    bottom: -2,
                    child: AnimatedBuilder(
                      animation: CastService.instance,
                      builder: (_, __) => CastService.instance.isConnected
                          ? Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(color: Color(0xFF7FB8F0), shape: BoxShape.circle),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
"""),
('로고 정가운데 (오른쪽 폭)',
"""                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerOptionsSheet(""",
"""                ],
              ),
              ),
            ),
          ),
          if (_albumArtStyle != 6) const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _showPlayerOptionsSheet("""),
('재생 화면 ⋯ 메뉴 맨 위에 TV로 듣기',
"""                  MenuCard(isDark: isDark, children: [
                  _playerSheetItem(
                    ctx,
                    Icons.shuffle_rounded,""",
"""                  MenuCard(isDark: isDark, children: [
                  castMenuRow(ctx, baseColor), // TV로 듣기
                  _playerSheetItem(
                    ctx,
                    Icons.shuffle_rounded,"""),
('곡 목록 ⋯ 메뉴에도 TV로 듣기',
"""  return [
    _PlayerScreenState._playerSheetItem(
      context, Icons.shuffle_rounded,""",
"""  return [
    // TV로 듣기 (곡이 재생 중일 때만)
    if (p.currentSong != null) castMenuRow(context, textColor),
    _PlayerScreenState._playerSheetItem(
      context, Icons.shuffle_rounded,"""),
('TV로 듣기 줄 만들기',
"""void showPlayerSleepMenu(BuildContext context) {""",
"""/// TV로 듣기 줄 (재생 화면 ⋯ · 곡 목록 ⋯ 같이 씀) — 지금 재생 중인 곡을 TV로
Widget castMenuRow(BuildContext context, Color textColor) {
  return AnimatedBuilder(
    animation: CastService.instance,
    builder: (_, __) {
      final cast = CastService.instance;
      final on = cast.isConnected;
      return _PlayerScreenState._playerSheetItem(
        context,
        Icons.sensors_rounded,
        'TV로 듣기',
        on ? const Color(0xFF2589E8) : const Color(0xFF8A8378),
        textColor,
        () {
          const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
          final p = context.read<PlayerProvider>();
          final song = p.currentSong;
          if (on) {
            showCastControlSheet(context,
                nowPlaying: song == null ? null : '${song.titleDisplay} · ${song.artistDisplay}');
          } else if (song != null) {
            showCastPickerSheet(context, onPick: (d) async {
              cast.onTrackEnded = () => p.playNext(); // TV에서 곡 끝나면 다음 곡
              final ok = await cast.connect(d, song);
              if (ok) p.player.pause();
              return ok;
            });
          }
        },
        trailing: on ? _PlayerScreenState._sheetValue(cast.device?.name ?? '연결됨') : null,
        arrow: true,
      );
    },
  );
}

void showPlayerSleepMenu(BuildContext context) {"""),
]

def main():
    try:
        raw = open(PATH, 'rb').read().decode('utf-8')
    except FileNotFoundError:
        print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
        s = s.replace(old, new); print(f'✔ {name}')
    # 괄호: 빼는 TV 블록은 그 자체로 짝이 맞으니 전체 짝만 확인
    for o, c in ('{}', '()', '[]'):
        if s.count(o) != s.count(c) and raw.count(o) == raw.count(c):
            print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('저장했어요 ✔')

main()
