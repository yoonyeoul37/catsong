# -*- coding: utf-8 -*-
# 위젯 이전·재생·다음 버튼 키우기 (아이콘도 같이)
#  다음·이전: 누르는 자리 40→44, 아이콘 20→26 / 재생: 원 42→46, 아이콘 20→24
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
p = find('widget_player.xml', os.path.join('android', 'app', 'src', 'main', 'res'))
if not p:
    print('❌ widget_player.xml 을 못 찾았어요'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

pairs = [
    ('이전 버튼 크게',
     '                android:id="@+id/widget_prev"\n'
     '                android:layout_width="40dp"\n'
     '                android:layout_height="40dp"\n'
     '                android:padding="10dp"\n',
     '                android:id="@+id/widget_prev"\n'
     '                android:layout_width="44dp"\n'
     '                android:layout_height="44dp"\n'
     '                android:padding="9dp"\n'),
    ('재생 버튼 크게',
     '                android:layout_width="42dp"\n'
     '                android:layout_height="42dp"\n'
     '                android:layout_marginStart="2dp"\n'
     '                android:layout_marginEnd="2dp"\n'
     '                android:background="@drawable/paran_widget_play"\n'
     '                android:padding="11dp"\n',
     '                android:layout_width="46dp"\n'
     '                android:layout_height="46dp"\n'
     '                android:layout_marginStart="4dp"\n'
     '                android:layout_marginEnd="4dp"\n'
     '                android:background="@drawable/paran_widget_play"\n'
     '                android:padding="11dp"\n'),
    ('다음 버튼 크게',
     '                android:id="@+id/widget_next"\n'
     '                android:layout_width="40dp"\n'
     '                android:layout_height="40dp"\n'
     '                android:padding="10dp"\n',
     '                android:id="@+id/widget_next"\n'
     '                android:layout_width="44dp"\n'
     '                android:layout_height="44dp"\n'
     '                android:padding="9dp"\n'),
]
ok = True
already = 0
for label, old, new in pairs:
    if new in src:
        print('✔ %s (이미 적용돼 있어요)' % label); already += 1; continue
    n = src.count(old)
    if n != 1:
        print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
    src = src.replace(old, new)
    print('✔ %s' % label)
if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
if already == len(pairs):
    print('\n이미 적용돼 있어요'); sys.exit(0)
BK = os.path.join('..', 'paransori_backup_widget_bigger')
b = os.path.join(BK, p)
os.makedirs(os.path.dirname(b), exist_ok=True)
shutil.copyfile(p, b)
open(p, 'wb').write((src.replace('\n', '\r\n') if crlf else src).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_bigger)')
