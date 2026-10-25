# -*- coding: utf-8 -*-
# WBS 원음방송 지역(부산·대구·광주·전북) 추가 — radio_korea_screen2.dart
import os, sys
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    for r, _, fs in os.walk('lib'):
        if 'radio_korea_screen2.dart' in fs: P = os.path.join(r, 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
if 'WBS 부산원음방송' in s:
    print('이미 적용돼 있어요'); sys.exit(0)
NL = '\r\n' if '\r\n' in s else '\n'
U = 'https://wbsradio.kr/wbs-seoul'
L = [('부산', '부산/경남', '104.9 MHz'), ('대구', '대구/경북', '98.3 MHz'), ('광주', '광주/전남', '107.9 MHz'), ('전북', '전북', '97.9 MHz')]
seoul = "  _KStation(name: 'WBS 원음방송', region: '수도권', broadcaster: 'WBS', subLabel: '서울', frequency: '89.7 MHz', streamUrl: '%s')," % U
st = NL.join("  _KStation(name: 'WBS %s원음방송', region: '%s', broadcaster: 'WBS', subLabel: '%s', frequency: '%s', streamUrl: '%s')," % (c, r, c, f, U) for c, r, f in L)
d_old = "    'WBS 원음방송': '종교·음악',"
d_new = d_old + NL + NL.join("    'WBS %s원음방송': '종교·음악'," % c for c, _, _ in L)
steps = [
    ('지역 원음방송 4개 추가 (서울 아래)', seoul, seoul + NL + st),
    ('설명 (종교·음악)', d_old, d_new),
]
for w in ['부산', '대구', '광주', '전북']:
    if ("  '%s': {" % w) not in s:
        print('❌ 번역에 %s 가 없어요' % w); sys.exit(1)
ok = True
for name, old, new in steps:
    c = s.count(old)
    if c == 1:
        s = s.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % c)
if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요:', P)
