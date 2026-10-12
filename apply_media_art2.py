# -*- coding: utf-8 -*-
# 자연소리도 미디어 출력에 사진 넘기기 (apply_media_art.py 다음에 실행)
import os, sys, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')

def find(name):
    for d, _, fs in os.walk(LIB):
        if name in fs:
            return os.path.join(d, name)
    return None

NATURE_FN = r'''
  /// 자연소리: 이름에 맞는 사진
  static String natureImage(String name) {
    if (name.contains('비')) return 'assets/rest_rain.jpg';
    if (name.contains('파도') || name.contains('갈매기')) return 'assets/rest_wave.jpg';
    if (name.contains('모닥불')) return 'assets/rest_fire.jpg';
    if (name.contains('시냇물') || name.contains('강물')) return 'assets/rest_stream.jpg';
    if (name.contains('새') || name.contains('뻐꾸기')) return 'assets/rest_bird.jpg';
    return 'assets/nature_bg.jpg';
  }
'''

EDITS = [
    ("자연소리 재생할 때 사진",
     "        title: displayName,\n        artist: '자연소리',\n      ));\n    }\n",
     "        title: displayName,\n        artist: '자연소리',\n      ));\n      MediaArt.attachAsset(handler, MediaArt.natureImage(displayName), assetPath, displayName);\n    }\n"),
    ("자연소리 사진 고르는 함수",
     "    return 'assets/radio_hero_$slot.jpg';\n  }\n",
     "    return 'assets/radio_hero_$slot.jpg';\n  }\n" + NATURE_FN),
]

p = find('player_provider.dart')
if not p:
    print('❌ player_provider.dart 파일을 못 찾았어요'); sys.exit(1)
with open(p, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
t = raw.replace('\r\n', '\n')
if 'natureImage' in t:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'class MediaArt' not in t:
    print('❌ apply_media_art.py를 먼저 실행해 주세요'); sys.exit(1)

ok = True
for name, a, b in EDITS:
    if t.count(a) == 1:
        t = t.replace(a, b); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % t.count(a))
if ok and not all(t.count(x) == t.count(y) for x, y in ('()', '{}', '[]')):
    ok = False; print('❌ 괄호 개수가 안 맞아요')
if not ok:
    print('\n하나라도 ❌라서 아무것도 저장 안 했어요.'); sys.exit(1)
shutil.copyfile(p, p + '.bak')
if crlf:
    t = t.replace('\n', '\r\n')
with open(p, 'wb') as f:
    f.write(t.encode('utf-8'))
print('\n완료!')
