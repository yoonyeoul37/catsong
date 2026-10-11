# -*- coding: utf-8 -*-
# 곡 목록 속도: 곡 줄이 "자기 곡이 재생 중인지·즐겨찾기·재생 횟수"가 바뀔 때만 다시 그려지게
# (지금은 재생 위치가 바뀔 때마다 보이는 곡 줄이 전부 다시 그려짐)
import sys, glob, os, shutil

hits = [h for h in glob.glob(os.path.join('lib', '**', 'song_list_tile.dart'), recursive=True)
        if os.path.basename(h) == 'song_list_tile.dart']
if not hits:
    print('❌ song_list_tile.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if 'isPlayingNow' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('필요한 값만 지켜보기',
"""    final playerProvider = context.watch<PlayerProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final isCurrentSong = playerProvider.currentSong?.id == song.id;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isFav = musicProvider.isFavorite(song.id);
""",
"""    // 필요한 값만 지켜보기 → 이 값들이 바뀔 때만 이 줄을 다시 그림 (재생 위치가 움직일 때는 안 그림)
    final isCurrentSong = context.select<PlayerProvider, bool>((p) => p.currentSong?.id == song.id);
    final isPlayingNow = context.select<PlayerProvider, bool>((p) => p.currentSong?.id == song.id && p.isPlaying);
    final isFav = context.select<MusicProvider, bool>((m) => m.isFavorite(song.id));
    final trimmed = context.select<MusicProvider, bool>((m) => m.isTrimmedWithOriginal(song));
    final primaryColor = Theme.of(context).colorScheme.primary;
"""),
('앨범 사진에 넘기는 값',
"""            _buildAlbumArt(isCurrentSong, playerProvider, primaryColor, baseColor,
                musicProvider.isTrimmedWithOriginal(song)),""",
"""            _buildAlbumArt(isCurrentSong, isPlayingNow, primaryColor, baseColor, trimmed),"""),
('앨범 사진 받는 값',
"  Widget _buildAlbumArt(bool isCurrentSong, PlayerProvider playerProvider, Color primaryColor, Color baseColor,",
"  Widget _buildAlbumArt(bool isCurrentSong, bool isPlayingNow, Color primaryColor, Color baseColor,"),
('재생 중 막대',
"                isPlaying: playerProvider.isPlaying,",
"                isPlaying: isPlayingNow,"),
('재생 횟수도 바뀔 때만',
"              final playCount = context.watch<MusicProvider>().playCountOf(song);",
"              final playCount = context.select<MusicProvider, int>((m) => m.playCountOf(song));"),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

shutil.copy(path, path + '.bak_speed')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_speed)')
