# -*- coding: utf-8 -*-
# 음악 아래 탭(앨범·아티스트·재생목록·폴더·동영상)에서 뒤로가기 → 곡 탭으로
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('home_screen.dart')
if not path:
    print('❌ lib 폴더에서 home_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)

with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if 'else if (_currentTabIndex != 0)' in src or 'if (_currentTabIndex != 0) {' in src:
    print('이미 적용돼 있어요')
    sys.exit(0)

old = """        } else {
          const platform = MethodChannel('kr.ssing.catsong/media');
          platform.invokeMethod('moveToBackground');
        }"""
new = """        } else if (_currentTabIndex != 0) {
          // 앨범·아티스트·재생목록·폴더·동영상 탭 → 곡 탭으로
          setState(() => _currentTabIndex = 0);
        } else {
          const platform = MethodChannel('kr.ssing.catsong/media');
          platform.invokeMethod('moveToBackground');
        }"""

if src.count(old) != 1:
    print('❌ 뒤로가기 코드를 못 찾았어요. 아무것도 저장 안 했어요.')
    sys.exit(1)
src = src.replace(old, new)
print('✔ 뒤로가기: 아래 탭에서 누르면 곡 탭으로')

shutil.copy(path, path + '.bak')
if crlf:
    src = src.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(src.encode('utf-8'))
print('저장했어요:', path)
