# -*- coding: utf-8 -*-
# PlayerWidget.kt 에 두 번 들어간 코드(연타 무시·불러오는 중·통로 연결)를 하나만 남기기
import os, sys, shutil, re

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
pw = find('PlayerWidget.kt', 'android')
if not pw:
    print('❌ PlayerWidget.kt 를 못 찾았어요'); sys.exit(1)
print('고칠 파일: %s' % pw)

raw = open(pw, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

START = '        private const val TAP_GAP'
END = '            android.util.Log.d("PARAN_W", "엔진만 깨어남 → 위젯 통로 연결")\n        }\n'
blocks = [m for m in re.finditer(re.escape(START) + r'.*?' + re.escape(END), src, re.S)]
print('들어간 개수: %d' % len(blocks))
if len(blocks) <= 1:
    print('이미 적용돼 있어요 (겹친 곳 없음)'); sys.exit(0)
if len(blocks) != 2:
    print('❌ 예상과 달라요 — 파일을 보내 주세요'); sys.exit(1)

# requestAudioFocus 까지 들어간(새 것) 하나만 남기기
keep = 1 if 'requestAudioFocus' in blocks[1].group(0) and 'requestAudioFocus' not in blocks[0].group(0) else 0
drop = blocks[1 - keep]
s, e = drop.span()
# 빼는 블록 앞뒤 빈 줄 하나 정리
if src[e:e + 1] == '\n':
    e += 1
src = src[:s] + src[e:]
print('✔ 겹친 코드 하나 지움')

# 같은 import 두 번 들어간 것 정리
lines = src.split('\n')
seen = set()
out = []
removed = 0
for ln in lines:
    if ln.startswith('import '):
        if ln in seen:
            removed += 1
            continue
        seen.add(ln)
    out.append(ln)
src = '\n'.join(out)
if removed:
    print('✔ 겹친 import %d줄 지움' % removed)

for name in ('fun attachHeadless', 'fun tooSoon', 'fun pressed', 'val TAP_GAP', 'val LOAD_MAX'):
    n = src.count(name)
    if n != 1:
        print('❌ %s 가 %d개 — 저장 안 했어요' % (name, n)); sys.exit(1)
    print('✔ %s 1개' % name)

BK = os.path.join('..', 'paransori_backup_widget_double')
b = os.path.join(BK, pw)
os.makedirs(os.path.dirname(b), exist_ok=True)
shutil.copyfile(pw, b)
open(pw, 'wb').write((src.replace('\n', '\r\n') if crlf else src).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_double)')
