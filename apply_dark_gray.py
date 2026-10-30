# -*- coding: utf-8 -*-
# 다크 모드를 네이트처럼 — 누런 갈색 기를 빼고 색 없는 회색으로 (밝은 모드·글자색·포인트색은 그대로)
import os, re, sys

# 다크 모드 배경·카드·선 색만 (밝은 모드 글자색 17140F·5A5348 등은 안 건드림)
OLD = ['24221F', '1C1A17', '2B2926', '32302C', '353330', '3E3B37', '3A3631', '302D29', '34312C',
       '2A2724', '2C2A26', '433F39', '403D39', '26221C', '332E26', '4A4640', '45413B', '14110C', '3A3732']
def gray(h):
    v = max(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    return ('%02X' % v) * 3
MAP = {h: gray(h) for h in OLD}

XML = os.path.join('android', 'app', 'src', 'main', 'res', 'values-night', 'colors.xml')
MAIN = os.path.join('lib', 'main.dart')
if not os.path.isdir('lib') or not os.path.isfile(MAIN):
    print('❌ 프로젝트 폴더(lib 이 있는 곳)에서 실행해 주세요'); sys.exit(1)
if not os.path.isfile(XML):
    print('❌ values-night/colors.xml 을 못 찾았어요'); sys.exit(1)

def load(p):
    return open(p, 'rb').read().decode('utf-8')

pat = re.compile(r'0xFF(' + '|'.join(OLD) + r')\b', re.I)
files = {}
count = {h: 0 for h in OLD}
for r, _, fs in os.walk('lib'):
    for f in fs:
        if not f.endswith('.dart'): continue
        p = os.path.join(r, f)
        s = load(p)
        def sub(m):
            h = m.group(1).upper(); count[h] += 1
            return '0xFF' + MAP[h]
        n = pat.sub(sub, s)
        if n != s: files[p] = n

main = files.get(MAIN, load(MAIN))
A_OLD = '.copyWith(systemOverlayStyle: themeProvider.systemBarStyle),'
A_NEW = ('.copyWith(\n'
         '                    systemOverlayStyle: themeProvider.systemBarStyle,\n'
         '                    // 목록을 내려도 제목 줄이 푸르스름하게 바뀌지 않게 (본문과 같은 색 한 가지로)\n'
         '                    scrolledUnderElevation: 0,\n'
         '                    surfaceTintColor: Colors.transparent,\n'
         '                  ),')
nl = '\r\n' if '\r\n' in main else '\n'
A_NEW = A_NEW.replace('\n', nl)

xml = load(XML)
xml_new = xml.replace('#24221F', '#242424').replace('#32302C', '#323232')

if not files and 'scrolledUnderElevation: 0' in main and xml_new == xml:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True
for h in OLD:
    if count[h]:
        print('✔ %s → %s  (%d곳)' % (h, MAP[h], count[h]))
    else:
        print('· %s 는 없음 (이미 바뀌었거나 안 쓰는 색)' % h)
if main.count(A_OLD) == 1:
    files[MAIN] = main.replace(A_OLD, A_NEW); print('✔ [main.dart] 내려도 제목 줄 색 그대로')
elif 'scrolledUnderElevation: 0' in main:
    print('✔ [main.dart] 제목 줄 색 — 이미 적용돼 있어요')
else:
    ok = False; print('❌ [main.dart] 제목 줄 설정 자리를 못 찾았어요')
if xml_new != xml:
    print('✔ [values-night/colors.xml] 홈 위젯 다크 색')
elif '#242424' in xml:
    print('✔ [values-night/colors.xml] 이미 적용돼 있어요')
else:
    ok = False; print('❌ [values-night/colors.xml] 위젯 색을 못 찾았어요')
if sum(count.values()) == 0 and MAIN not in files:
    ok = False; print('❌ 바꿀 색을 하나도 못 찾았어요')

if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
for p, s in files.items():
    open(p, 'wb').write(s.encode('utf-8'))
if xml_new != xml:
    open(XML, 'wb').write(xml_new.encode('utf-8'))
print('저장했어요 — 파일 %d개' % (len(files) + (1 if xml_new != xml else 0)))
