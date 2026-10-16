# -*- coding: utf-8 -*-
# 정리 1단계: 백업 파일·빈 파일·안 쓰는 화면 지우기 + 안 쓰는 패키지(flutter_colorpicker) 빼기
# 프로젝트 폴더(C:\apps\mp3_player_new)에서: python cleanup_step1.py
import os, re, sys

if not os.path.isdir('lib') or not os.path.exists('pubspec.yaml'):
    print('❌ 프로젝트 폴더(C:\\apps\\mp3_player_new)에서 실행해 주세요.')
    sys.exit(1)

# ── 지울 파일 모으기 ──
targets = []
for dp, _, fs in os.walk('lib'):
    for f in fs:
        if re.search(r'\.dart\.bak\w*$', f):  # home_screen.dart.bak_card 같은 백업
            targets.append(os.path.join(dp, f))
for p in ['lib/assets', 'lib/l10n/locale_holder']:  # 0바이트 빈 파일만
    if os.path.isfile(p) and os.path.getsize(p) == 0:
        targets.append(p)
china = 'lib/screens/radio_china_screen.dart'  # 아무 데서도 안 부르는 화면
if os.path.isfile(china):
    targets.append(china)
targets.sort()

# ── 고칠 곳: flutter_colorpicker는 import만 있고 안 씀 ──
EDITS = [
    ('lib/screens/settings_screen.dart', 'flutter_colorpicker import 빼기',
     "import 'package:flutter_colorpicker/flutter_colorpicker.dart';\n", ''),
    ('pubspec.yaml', 'flutter_colorpicker 패키지 빼기',
     "  flutter_colorpicker: ^1.1.0\n", ''),
]

texts, crlf, ok, todo = {}, {}, True, False
for path, desc, old, new in EDITS:
    if path not in texts:
        raw = open(path, 'rb').read().decode('utf-8')
        crlf[path] = '\r\n' in raw
        texts[path] = raw.replace('\r\n', '\n')
    n = texts[path].count(old)
    if n == 1:
        texts[path] = texts[path].replace(old, new)
        print(f'✔ {os.path.basename(path)} - {desc}')
        todo = True
    elif n == 0 and 'flutter_colorpicker' not in texts[path]:
        print(f'✔ {os.path.basename(path)} - {desc} (이미 돼 있음)')
    else:
        print(f'❌ {os.path.basename(path)} - {desc} (찾을 코드가 {n}군데)')
        ok = False

if not ok:
    print('\n❌ 못 찾은 곳이 있어서 아무것도 지우거나 저장하지 않았어요.')
    sys.exit(1)

# 안 쓰는 화면이 정말 아무 데서도 안 불리는지 한 번 더
if china in targets:
    for dp, _, fs in os.walk('lib'):
        for f in fs:
            p = os.path.join(dp, f)
            if f.endswith('.dart') and os.path.normpath(p) != os.path.normpath(china):
                s = open(p, encoding='utf-8', errors='ignore').read()
                if 'radio_china_screen' in s or 'RadioChinaScreen' in s:
                    print(f'❌ {f}에서 radio_china_screen을 쓰고 있어요. 아무것도 지우지 않았어요.')
                    sys.exit(1)

if not targets and not todo:
    print('이미 적용돼 있어요')
    sys.exit(0)

print(f'\n지울 파일 {len(targets)}개:')
for t in targets:
    print('  ', t)
if input('\n위 파일을 지울까요? (y 입력 후 엔터) ').strip().lower() != 'y':
    print('취소했어요. 아무것도 바꾸지 않았어요.')
    sys.exit(0)

for t in targets:
    os.remove(t)
    print('✔ 지움', t)
for path in texts:
    t = texts[path].replace('\n', '\r\n') if crlf[path] else texts[path]
    open(path, 'wb').write(t.encode('utf-8'))
print(f'\n완료! 파일 {len(targets)}개 지우고, 패키지 정리했어요.')
