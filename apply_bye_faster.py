# -*- coding: utf-8 -*-
# 끝인사: 서서히 어두워지고 사라지는 시간을 살짝 짧게 (8초 → 6.5초, 자연소리 화면 15초 → 6.5초)
import sys, glob, os, shutil

FILES = ['home_screen.dart', 'player_screen.dart', 'nature_sound_detail_screen.dart',
         'nature_sounds_screen.dart', 'radio_player_screen.dart', 'sound_mix_screen.dart']
DARK_OLD = 'duration: const Duration(milliseconds: 11000),'
DARK_NEW = 'duration: const Duration(milliseconds: 7000), // 끝인사: 서서히 어둡게'

jobs = []
for name in FILES:
    hits = [h for h in glob.glob(os.path.join('lib', '**', name), recursive=True) if os.path.basename(h) == name]
    if not hits:
        print(f'❌ {name} 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
    path = hits[0]
    raw = open(path, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if DARK_NEW in s:
        print(f'✔ {name}: 이미 적용돼 있어요'); continue
    if s.count(DARK_OLD) != 1:
        print(f'❌ {name}: 어두워지는 시간 찾을 곳이 {s.count(DARK_OLD)}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(DARK_OLD, DARK_NEW)
    end_old = None
    for ms in ('8000', '15000'):
        cand = f'Future.delayed(const Duration(milliseconds: {ms}), () async {{'
        if s.count(cand) == 1:
            end_old = cand
    if end_old is None:
        print(f'❌ {name}: 사라지는 시간을 못 찾았어요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(end_old, 'Future.delayed(const Duration(milliseconds: 6500), () async {')
    print(f'✔ {name}')
    jobs.append((path, s, crlf))

for path, s, crlf in jobs:   # 모두 문제없을 때만 저장
    shutil.copy(path, path + '.bak_bye')
    if crlf: s = s.replace('\n', '\r\n')
    open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_bye)')
