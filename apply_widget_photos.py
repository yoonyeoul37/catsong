# -*- coding: utf-8 -*-
# 위젯 사진: 시간대 라디오 사진 → 위젯 전용 사진 6장 중 하루에 한 장 (날마다 바뀜, 어제와 같은 사진은 안 나옴)
#  (assets 폴더에 widget_photo1~6.jpg 가 있어야 해요)
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root.lower():
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
missing = [i for i in range(1, 7) if not os.path.isfile(os.path.join('assets', 'widget_photo%d.jpg' % i))]
if missing:
    print('❌ assets 폴더에 사진이 없어요: ' + ', '.join('widget_photo%d.jpg' % i for i in missing)); sys.exit(1)
pw = find('PlayerWidget.kt', os.path.join('android', 'app', 'src', 'main'))
if not pw:
    print('❌ PlayerWidget.kt 를 못 찾았어요'); sys.exit(1)
print('고칠 파일: %s' % pw)

writes = {}
ok = True
def edit(path, label, old, new):
    global ok
    src, crlf = writes[path] if path in writes else load(path)
    if new in src:
        print('✔ %s (이미 적용돼 있어요)' % label); writes[path] = (src, crlf); return
    n = src.count(old)
    if n != 1:
        print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; return
    writes[path] = (src.replace(old, new), crlf)
    print('✔ %s' % label)

edit('pubspec.yaml', 'pubspec: 위젯 사진 6장 등록',
     '    - assets/radio_media_night.jpg\n',
     '    - assets/radio_media_night.jpg\n'
     '    - assets/widget_photo1.jpg\n'
     '    - assets/widget_photo2.jpg\n'
     '    - assets/widget_photo3.jpg\n'
     '    - assets/widget_photo4.jpg\n'
     '    - assets/widget_photo5.jpg\n'
     '    - assets/widget_photo6.jpg\n')
edit(pw, '위젯: 하루에 한 장 랜덤 사진',
     '            val h = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)\n'
     '            val slot = when (h) {\n'
     '                in 5..10 -> "morning"\n'
     '                in 11..16 -> "day"\n'
     '                in 17..21 -> "evening"\n'
     '                else -> "night"\n'
     '            }\n'
     '            val path = "flutter_assets/assets/radio_media_$slot.jpg"\n',
     '            // 위젯 사진 6장 중 하루에 한 장 (하루 동안은 같고, 어제와 같은 사진은 안 나옴)\n'
     '            val cal = Calendar.getInstance()\n'
     '            val day = cal.get(Calendar.YEAR) * 400 + cal.get(Calendar.DAY_OF_YEAR)\n'
     '            fun pick(d: Int) = java.util.Random(d.toLong() * 7919).nextInt(6)\n'
     '            var n = pick(day)\n'
     '            if (n == pick(day - 1)) n = (n + 1) % 6\n'
     '            val path = "flutter_assets/assets/widget_photo${n + 1}.jpg"\n')

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
changed = {p: v for p, v in writes.items() if v[0] != load(p)[0]}
if not changed:
    print('\n이미 적용돼 있어요'); sys.exit(0)
BK = os.path.join('..', 'paransori_backup_widget_photos')
for p, (text, c) in changed.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    open(p, 'wb').write((text.replace('\n', '\r\n') if c else text).encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_photos)')
