# -*- coding: utf-8 -*-
# 프로젝트 폴더에 쌓인 apply_*.py (한 번 쓰고 끝난 고치기 파일)를 한꺼번에 지우기
#  · 프로젝트 폴더 맨 위에 있는 apply_로 시작하는 .py만 (lib 등 안쪽 폴더는 건드리지 않음)
#  · 지우기 전에 목록과 개수를 보여 주고, y를 눌러야 지움
import os, sys
sys.stdout.reconfigure(encoding='utf-8')

here = os.getcwd()
if not os.path.isfile(os.path.join(here, 'pubspec.yaml')):
    print('❌ 프로젝트 폴더(pubspec.yaml 있는 곳)에서 실행해 주세요'); sys.exit(1)

files = sorted(f for f in os.listdir(here)
               if f.startswith('apply_') and f.endswith('.py') and os.path.isfile(os.path.join(here, f)))
if not files:
    print('✔ 지울 apply 파일이 없어요'); sys.exit(0)

for f in files:
    print('  ·', f)
print('위 apply 파일 %d개를 지울까요? 지우려면 y 를 누르고 엔터' % len(files))
if input('> ').strip().lower() != 'y':
    print('✔ 아무것도 안 지웠어요'); sys.exit(0)

n = 0
for f in files:
    try:
        os.remove(os.path.join(here, f))
        n += 1
    except Exception as e:
        print('❌', f, e)
print('✔ %d개 지웠어요' % n)
