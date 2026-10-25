# -*- coding: utf-8 -*-
# WBS 원음방송(서울) 추가 — radio_korea_screen2.dart
import os, sys
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    for r, _, fs in os.walk('lib'):
        if 'radio_korea_screen2.dart' in fs: P = os.path.join(r, 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
if 'WBS 원음방송' in s:
    print('이미 적용돼 있어요'); sys.exit(0)
NL = '\r\n' if '\r\n' in s else '\n'

bbs = "  _KStation(name: 'BBS 불교방송', region: '수도권', broadcaster: 'BBS', subLabel: '서울', frequency: '101.9 MHz', streamUrl: 'https://bbslive.clouducs.com/bbsradio-mlive/radio.stream/playlist.m3u8'),"
wbs = "  _KStation(name: 'WBS 원음방송', region: '수도권', broadcaster: 'WBS', subLabel: '서울', frequency: '89.7 MHz', streamUrl: 'https://wbsradio.kr/wbs-seoul'),"
steps = [
    ('방송 추가 (BBS 아래)', bbs, bbs + NL + wbs),
    ('설명 (종교·음악)', "    'BBS 불교방송': '종교·음악',", "    'BBS 불교방송': '종교·음악'," + NL + "    'WBS 원음방송': '종교·음악',"),
    ('종교 방송으로 분류', "if (const {'CPBC', 'FEBC', 'BBS'}.contains(s.broadcaster)) return 3;", "if (const {'CPBC', 'FEBC', 'BBS', 'WBS'}.contains(s.broadcaster)) return 3;"),
    ('방송사 순서 (BBS 다음)', "'OBS', 'CPBC', 'FEBC', 'BBS',", "'OBS', 'CPBC', 'FEBC', 'BBS', 'WBS',"),
    ('방송사별 → 종교 칸', "'FEBC' || 'BBS' || 'CPBC' => '종교',", "'FEBC' || 'BBS' || 'CPBC' || 'WBS' => '종교',"),
    ('주사위에서 빼기 (편성표 없음)', "'수원 SoneFM', '서대문FM'", "'수원 SoneFM', '서대문FM', 'WBS 원음방송'"),
]
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
