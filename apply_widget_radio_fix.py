# -*- coding: utf-8 -*-
# 위젯: 앱을 끈 상태에서 라디오가 안 나오던 것 고치기
#  원인: 라디오를 틀 때 '화면 켜두기(wakelock)'를 끄는데, 앱 화면이 없으면 이게 오류를 내서
#        음악만 멈추고 라디오 틀기가 중간에 멈춰버림
#  고침: 화면 켜두기 켜고 끄기가 실패해도 그냥 넘어가게 (음악·라디오 둘 다)
#        + 화면 없을 때 '소리 차례 받기(requestAudioFocus)' 신호도 위젯이 받아서 오류 안 나게
import os, sys, shutil, re

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

pw = find('PlayerWidget.kt', 'android')
rp = find('radio_provider.dart', os.path.join('lib', 'providers'))
pp = find('player_provider.dart', os.path.join('lib', 'providers'))
for n, p in (('PlayerWidget.kt', pw), ('radio_provider.dart', rp), ('player_provider.dart', pp)):
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

writes = {}
ok = True
changed = False

# 1) 화면 켜두기: 실패해도 넘어가게
SAFE = '.catchError((Object _) {})'
pat = re.compile(r'WakelockPlus\.(enable|disable)\(\)(?!\.catchError)')
for path, label in ((rp, '라디오'), (pp, '음악')):
    src, crlf = load(path)
    n = len(pat.findall(src))
    if n == 0:
        if 'WakelockPlus.' in src and SAFE in src:
            print('✔ %s: 화면 켜두기 실패해도 넘어가게 (이미 적용돼 있어요)' % label)
        else:
            print('✔ %s: 화면 켜두기 쓰는 곳 없음' % label)
        continue
    src = pat.sub(lambda m: m.group(0) + SAFE, src)
    writes[path] = (src, crlf)
    changed = True
    print('✔ %s: 화면 켜두기 실패해도 넘어가게 (%d곳)' % (label, n))

# 2) 위젯 통로: requestAudioFocus 도 받기
src, crlf = load(pw)
NEW = '                if (call.method == "requestAudioFocus") {\n'
OLD = ('            ch.setMethodCallHandler { call, result ->\n'
       '                if (call.method == "updateWidget") {\n')
if NEW in src:
    print('✔ 위젯: 화면 없을 때 소리 차례 신호 받기 (이미 적용돼 있어요)')
elif src.count(OLD) != 1:
    print('❌ 위젯: 화면 없을 때 소리 차례 신호 받기 (찾은 개수 %d) — apply_widget_loading.py 먼저 해 주세요' % src.count(OLD))
    ok = False
else:
    src = src.replace(OLD,
        '            ch.setMethodCallHandler { call, result ->\n'
        '                if (call.method == "requestAudioFocus") {\n'
        '                    result.success(true) // 화면 없을 땐 그냥 통과 (오류 안 나게)\n'
        '                } else if (call.method == "updateWidget") {\n')
    writes[pw] = (src, crlf)
    changed = True
    print('✔ 위젯: 화면 없을 때 소리 차례 신호 받기')

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
if not changed:
    print('\n이미 적용돼 있어요'); sys.exit(0)

BK = os.path.join('..', 'paransori_backup_widget_radio_fix')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = text.replace('\n', '\r\n') if c else text
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_radio_fix)')
