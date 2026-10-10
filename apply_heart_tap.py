# -*- coding: utf-8 -*-
# 라디오·자연소리 목록: 하트 옆을 눌러도 재생 안 되게 (하트 누르는 칸 넓게)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

FILES = {
'lib/screens/radio_korea_screen2.dart': ('하트 둘레 넓게', [
('라디오 하트 칸 넓게',
"""                  child: Icon(
                    context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                        ? const Color(0xFFE05A4F)
                        : baseColor.withOpacity(0.35),
                    size: 22,
                  ),
                ),""",
"""                  // 하트 둘레 넓게 (옆을 눌러도 재생 안 되게)
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                            ? const Color(0xFFE05A4F)
                            : baseColor.withOpacity(0.35),
                        size: 22,
                      ),
                    ),
                  ),
                ),"""),
]),
'lib/screens/nature_sounds_screen.dart': ('하트 주변 칸 전체가 하트 자리', [
('자연소리 하트 칸 넓게',
"""                          GestureDetector(
                            onTap: () => _toggleFavorite(primary.name),
                            child: SizedBox(
                              width: 34,
                              height: 34,""",
"""                          GestureDetector(
                            // 하트 주변 칸 전체가 하트 자리 (옆을 눌러도 재생 안 되게)
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleFavorite(primary.name),
                            child: SizedBox(
                              width: 44,
                              height: 44,"""),
]),
}

def main():
    out = {}
    ok = True
    for path, (mark, edits) in FILES.items():
        print(f'── {path.split("/")[-1]}')
        try:
            raw = open(path, 'rb').read().decode('utf-8')
        except FileNotFoundError:
            print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
        crlf = '\r\n' in raw
        s = raw.replace('\r\n', '\n')
        if mark in s:
            print('이미 적용돼 있어요'); continue
        for name, old, new in edits:
            n = s.count(old)
            if n != 1:
                print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
            s = s.replace(old, new); print(f'✔ {name}')
        for o, c in ('{}', '()', '[]'):
            if (s.count(o) - s.count(c)) != (raw.count(o) - raw.count(c)):
                print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
        out[path] = s.replace('\n', '\r\n') if crlf else s
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    for path, s in out.items():
        open(path, 'wb').write(s.encode('utf-8'))
    if out: print('저장했어요 ✔')

main()
