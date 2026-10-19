# -*- coding: utf-8 -*-
# 사진·카드 모서리를 홈 큰 박스와 같은 10으로 통일 (음악 곡 목록 앨범 사진은 그대로 4)
#  ① 라디오 방송줄 로고 ② 라디오 저장한 노래 국기 칸 ④ 앨범 탭 사진
#  ⑤ 폴더·재생목록 사진 ⑥ 음악 미니 플레이어 사진 ⑦ 홈 '오늘의 카드' 앨범 사진
import os, sys
sys.stdout.reconfigure(encoding='utf-8')
def fail(m):
    print('❌', m, '— 아무것도 저장 안 했어요.'); sys.exit(1)
S = os.path.join('lib', 'screens'); W = os.path.join('lib', 'widgets')
# (이름, 찾을 글자, 바꿀 글자, 몇 군데)
jobs = {
 os.path.join(W, 'station_logo.dart'): [
  ("① 방송국 로고", "BorderRadius.circular(size * 0.2)", "BorderRadius.circular(size <= 60 ? 10 : size * 0.2)", 2)],
 os.path.join(S, 'radio_country_stations_screen.dart'): [
  ("① 재생 중 로고 위 덮개", "BorderRadius.circular(46 * 0.2)", "BorderRadius.circular(10)", 1)],
 os.path.join(S, 'radio_saved_songs_screen.dart'): [
  ("② 국기 칸", "BorderRadius.circular(46 * 0.2)", "BorderRadius.circular(10)", 1)],
 os.path.join(S, 'album_screen.dart'): [
  ("④ 앨범 사진", "BorderRadius.circular(4)", "BorderRadius.circular(10)", 2)],
 os.path.join(S, 'folder_screen.dart'): [
  ("⑤ 폴더 사진", "ClipRRect(borderRadius: BorderRadius.circular(size * 0.2), child: child)", "ClipRRect(borderRadius: BorderRadius.circular(10), child: child)", 1)],
 os.path.join(S, 'playlist_screen.dart'): [
  ("⑤ 재생목록 사진", "ClipRRect(borderRadius: BorderRadius.circular(size * 0.2), child: child)", "ClipRRect(borderRadius: BorderRadius.circular(10), child: child)", 1)],
 os.path.join(W, 'mini_player.dart'): [
  ("⑥ 미니 플레이어 앨범 사진", "BorderRadius.circular(8)", "BorderRadius.circular(10)", 3)],
 os.path.join(S, 'home_screen.dart'): [
  ("⑦ 오늘의 카드 앨범 사진", "BorderRadius.circular(size * 0.18)", "BorderRadius.circular(size >= 40 ? 10 : size * 0.25)", 2)],
}
MARK = 'BorderRadius.circular(size <= 60 ? 10 : size * 0.2)'
out = {}; done = 0
for p, edits in jobs.items():
    if not os.path.exists(p): fail('파일을 못 찾았어요: ' + p)
    raw = open(p, 'rb').read().decode('utf-8'); crlf = '\r\n' in raw; s = raw.replace('\r\n', '\n'); o = s
    for name, old, new, cnt in edits:
        n = s.count(old)
        if n == 0 and s.count(new) >= cnt:
            print('✔', os.path.basename(p), '·', name, '(이미 10이에요)'); done += 1; continue
        if n != cnt: fail(f'{os.path.basename(p)} · {name} — 찾을 코드가 {cnt}곳이어야 하는데 {n}곳이에요')
        s = s.replace(old, new); print('✔', os.path.basename(p), '·', name, f'({cnt}곳)')
    for a, b in ['()', '[]', '{}']:
        if s.count(a) - s.count(b) != o.count(a) - o.count(b): fail(f'{p} 괄호 짝이 안 맞아요')
    if s != o: out[p] = s.replace('\n', '\r\n') if crlf else s
if not out:
    print('이미 적용돼 있어요'); sys.exit(0)
for p, s in out.items():
    open(p, 'wb').write(s.encode('utf-8'))
print('저장했어요.')
