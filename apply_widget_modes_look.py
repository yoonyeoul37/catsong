# -*- coding: utf-8 -*-
# 위젯 섞기·반복 아이콘 잘 보이게
#  - 아이콘 뒤에 반투명 어두운 동그라미 (밝은 사진 위에서도 보이게)
#  - 꺼짐은 조금 덜 흐리게, 켜짐은 동그라미를 흰색으로 채워 확실히 구분
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
res = os.path.join('android', 'app', 'src', 'main', 'res')
lay = find('widget_player.xml', res)
pw = find('PlayerWidget.kt', 'android')
if not lay or not pw:
    print('❌ 위젯 파일을 못 찾았어요'); sys.exit(1)
if 'paran_widget_mode_bg' in open(lay, encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)
if 'widget_modes' not in open(lay, encoding='utf-8').read():
    print('❌ apply_widget_modes.py 를 먼저 해 주세요'); sys.exit(1)

writes = {}
ok = True
def edit(path, pairs):
    global ok
    src, crlf = writes[path] if path in writes else load(path)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

# 동그라미 2개 (꺼짐: 반투명 검정 / 켜짐: 흰색)
new_files = {
    os.path.join(res, 'drawable', 'paran_widget_mode_bg.xml'):
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- 위젯 섞기·반복 아이콘 뒤 동그라미 (꺼짐) -->\n'
        '<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">\n'
        '    <solid android:color="#66000000" />\n'
        '</shape>\n',
    os.path.join(res, 'drawable', 'paran_widget_mode_on.xml'):
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- 위젯 섞기·반복 아이콘 뒤 동그라미 (켜짐) -->\n'
        '<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">\n'
        '    <solid android:color="#F2FFFFFF" />\n'
        '</shape>\n',
}
for p in new_files:
    print('✔ 동그라미 만들기: %s' % os.path.basename(p))

edit(lay, [
    ('위젯 모양: 섞기 동그라미',
     '                android:id="@+id/widget_shuffle"\n'
     '                android:layout_width="34dp"\n'
     '                android:layout_height="34dp"\n'
     '                android:padding="8dp"\n',
     '                android:id="@+id/widget_shuffle"\n'
     '                android:layout_width="30dp"\n'
     '                android:layout_height="30dp"\n'
     '                android:layout_marginEnd="6dp"\n'
     '                android:background="@drawable/paran_widget_mode_bg"\n'
     '                android:padding="6dp"\n'),
    ('위젯 모양: 반복 동그라미',
     '                android:id="@+id/widget_repeat"\n'
     '                android:layout_width="34dp"\n'
     '                android:layout_height="34dp"\n'
     '                android:padding="8dp"\n',
     '                android:id="@+id/widget_repeat"\n'
     '                android:layout_width="30dp"\n'
     '                android:layout_height="30dp"\n'
     '                android:background="@drawable/paran_widget_mode_bg"\n'
     '                android:padding="6dp"\n'),
    ('위젯 모양: 위치 맞추기',
     '            android:layout_gravity="top|end"\n'
     '            android:layout_marginTop="2dp"\n'
     '            android:layout_marginEnd="6dp"\n',
     '            android:layout_gravity="top|end"\n'
     '            android:layout_marginTop="6dp"\n'
     '            android:layout_marginEnd="10dp"\n'),
])

edit(pw, [
    ('위젯: 켜짐은 흰 동그라미 + 먹색 아이콘, 꺼짐은 어두운 동그라미 + 흰 아이콘',
     '            views.setInt(R.id.widget_repeat, "setImageAlpha", if (loop == 0L) 110 else 255)\n'
     '            views.setInt(R.id.widget_shuffle, "setImageAlpha", if (shuf) 255 else 110)\n',
     '            fun mode(id: Int, on: Boolean) {\n'
     '                views.setInt(id, "setBackgroundResource",\n'
     '                    if (on) R.drawable.paran_widget_mode_on else R.drawable.paran_widget_mode_bg)\n'
     '                views.setInt(id, "setColorFilter", if (on) 0xFF17140F.toInt() else 0xFFFFFFFF.toInt())\n'
     '                views.setInt(id, "setImageAlpha", if (on) 255 else 200)\n'
     '            }\n'
     '            mode(R.id.widget_repeat, loop != 0L)\n'
     '            mode(R.id.widget_shuffle, shuf)\n'),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_widget_modes_look')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    open(p, 'wb').write((text.replace('\n', '\r\n') if c else text).encode('utf-8'))
for p, text in new_files.items():
    open(p, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_modes_look)')
