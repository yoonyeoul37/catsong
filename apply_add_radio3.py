# -*- coding: utf-8 -*-
# 관악FM · 성남FM · 라디오코리아(LA) 추가 — radio_korea_screen2.dart
import os, sys
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    for r, _, fs in os.walk('lib'):
        if 'radio_korea_screen2.dart' in fs: P = os.path.join(r, 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
if "name: '관악FM'" in s:
    print('이미 적용돼 있어요'); sys.exit(0)
NL = '\r\n' if '\r\n' in s else '\n'

def i18n(key, d):
    return NL.join(["  '%s': {" % key] + ["    '%s': '%s'," % (k, v) for k, v in d.items()] + ['  },']) + NL

gwanak = {'en':'Gwanak','de':'Gwanak','es':'Gwanak','fr':'Gwanak','it':'Gwanak','pt':'Gwanak','pl':'Gwanak','ro':'Gwanak','cs':'Kwanak','hu':'Kvanak','tr':'Gwanak','id':'Gwanak','vi':'Gwanak','ru':'Кванак','uk':'Кванак','ja':'冠岳','zh':'冠岳','zh_Hant':'冠岳','th':'ควันอัก','hi':'ग्वानाक','ar':'غواناك','ur':'گواناک'}
seongnam = {'en':'Seongnam','de':'Seongnam','es':'Seongnam','fr':'Seongnam','it':'Seongnam','pt':'Seongnam','pl':'Seongnam','ro':'Seongnam','cs':'Songnam','hu':'Szongnam','tr':'Seongnam','id':'Seongnam','vi':'Seongnam','ru':'Соннам','uk':'Сонам','ja':'城南','zh':'城南','zh_Hant':'城南','th':'ซองนัม','hi':'सोंगनाम','ar':'سونغنام','ur':'سونگنام'}

sdm = "  _KStation(name: '서대문FM', region: '수도권', broadcaster: '공동체', subLabel: '서대문', frequency: '91.3 MHz', streamUrl: 'http://115.68.193.176:8000/sdmfm'),"
rs = "  _KStation(name: '라디오서울', region: '', broadcaster: '라디오서울', subLabel: 'LA', frequency: 'AM 1650', streamUrl: 'https://onair1.radioseoul1650.com/radioseoul.mp3'),"
gw = "  _KStation(name: '관악FM', region: '수도권', broadcaster: '공동체', subLabel: '관악', frequency: '100.3 MHz', streamUrl: 'http://115.68.193.176:8000/gwanakfm'),"
sn = "  _KStation(name: '성남FM', region: '수도권', broadcaster: '공동체', subLabel: '성남', frequency: '90.7 MHz', streamUrl: 'http://115.85.182.39/seongnamfm'),"
rk = "  _KStation(name: '라디오코리아', region: '', broadcaster: '라디오코리아', subLabel: 'LA', frequency: 'AM 1540', streamUrl: 'https://onairweb.radiokorea.com/live;stream/1'),"
ccm = "  'CCM 음악': {"

steps = [
    ('관악FM · 성남FM 추가 (서대문FM 아래)', sdm, sdm + NL + gw + NL + sn),
    ('라디오코리아 추가 (라디오서울 아래)', rs, rs + NL + rk),
    ('설명 (공동체 라디오 · 한인 방송)', "    '라디오서울': '한인 방송',", "    '라디오서울': '한인 방송'," + NL + "    '관악FM': '공동체 라디오'," + NL + "    '성남FM': '공동체 라디오'," + NL + "    '라디오코리아': '한인 방송',"),
    ('주사위에서 빼기 (편성표 없음)', "'수원 SoneFM', '서대문FM'", "'수원 SoneFM', '서대문FM', '관악FM', '성남FM'"),
    ('관악 · 성남 번역', ccm, i18n('관악', gwanak) + i18n('성남', seongnam) + ccm),
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
