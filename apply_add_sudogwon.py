# -*- coding: utf-8 -*-
# 서대문FM · 단원FM · 라디오서울(LA) 추가 — lib/screens/radio_korea_screen2.dart
import os, sys
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    for r, _, fs in os.walk('lib'):
        if 'radio_korea_screen2.dart' in fs: P = os.path.join(r, 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
if '서대문FM' in s:
    print('이미 적용돼 있어요'); sys.exit(0)
NL = '\r\n' if '\r\n' in s else '\n'

def i18n(key, d):
    lines = ["  '%s': {" % key] + ["    '%s': '%s'," % (k, v) for k, v in d.items()] + ['  },']
    return NL.join(lines) + NL

seodaemun = {'en':'Seodaemun','de':'Seodaemun','es':'Seodaemun','fr':'Seodaemun','it':'Seodaemun','pt':'Seodaemun','pl':'Seodaemun','ro':'Seodaemun','cs':'Sodemun','hu':'Szodemun','tr':'Seodaemun','id':'Seodaemun','vi':'Seodaemun','ru':'Содэмун','uk':'Содемун','ja':'西大門','zh':'西大门','zh_Hant':'西大門','th':'ซอแดมุน','hi':'सोदेमुन','ar':'سوديمون','ur':'سودیمون'}
ansan = {'en':'Ansan','de':'Ansan','es':'Ansan','fr':'Ansan','it':'Ansan','pt':'Ansan','pl':'Ansan','ro':'Ansan','cs':'Ansan','hu':'Anszan','tr':'Ansan','id':'Ansan','vi':'Ansan','ru':'Ансан','uk':'Ансан','ja':'安山','zh':'安山','zh_Hant':'安山','th':'อันซัน','hi':'आनसान','ar':'أنسان','ur':'انسان'}
hanin = {'en':'Korean-American radio','de':'Koreanisch-amerikanisches Radio','es':'Radio coreano-estadounidense','fr':'Radio coréano-américaine','it':'Radio coreano-americana','pt':'Rádio coreano-americana','pl':'Radio koreańsko-amerykańskie','ro':'Radio coreeano-american','cs':'Korejsko-americké rádio','hu':'Koreai-amerikai rádió','tr':'Kore-Amerikan radyosu','id':'Radio Korea-Amerika','vi':'Đài người Hàn tại Mỹ','ru':'Корейское радио в США','uk':'Корейське радіо в США','ja':'在米韓国語放送','zh':'美国韩侨电台','zh_Hant':'美國韓僑電台','th':'วิทยุชาวเกาหลีในอเมริกา','hi':'कोरियाई-अमेरिकी रेडियो','ar':'راديو الكوريين في أمريكا','ur':'کوریائی امریکی ریڈیو'}

sone = "  _KStation(name: '수원 SoneFM', region: '수도권', broadcaster: '공동체', subLabel: '수원', frequency: '96.3 MHz', streamUrl: 'http://115.85.182.39/sonefm'),"
new_st = NL.join([
    "  _KStation(name: '서대문FM', region: '수도권', broadcaster: '공동체', subLabel: '서대문', frequency: '91.3 MHz', streamUrl: 'http://115.68.193.176:8000/sdmfm'),",
    "  _KStation(name: '단원FM', region: '수도권', broadcaster: '공동체', subLabel: '안산', frequency: '', streamUrl: 'http://radiostream.communityradio.kr/dwfm1'),",
    "  _KStation(name: '라디오서울', region: '', broadcaster: '라디오서울', subLabel: 'LA', frequency: 'AM 1650', streamUrl: 'https://onair1.radioseoul1650.com/radioseoul.mp3'),",
])
desc_old = "    '수원 SoneFM': '공동체 라디오',"
desc_new = desc_old + NL + "    '서대문FM': '공동체 라디오'," + NL + "    '단원FM': '공동체 라디오'," + NL + "    '라디오서울': '한인 방송',"
dice_old = "static const _diceOut = {'FEBC 극동방송 AM', '수원 SoneFM'};"
dice_new = "static const _diceOut = {'FEBC 극동방송 AM', '수원 SoneFM', '서대문FM', '단원FM'};"
ccm = "  'CCM 음악': {"

steps = [
    ('방송 3개 추가 (SoneFM 아래)', sone, sone + NL + new_st),
    ('설명(공동체 라디오 · 한인 방송)', desc_old, desc_new),
    ('주사위에서 빼기 (편성표 없음)', dice_old, dice_new),
    ('서대문·안산·한인 방송 번역', ccm, i18n('서대문', seodaemun) + i18n('안산', ansan) + i18n('한인 방송', hanin) + ccm),
]
ok = True
for name, old, new in steps:
    old_n = old.replace('\n', NL); new_n = new.replace('\r\n', '\n').replace('\n', NL)
    c = s.count(old_n)
    if c == 1:
        s = s.replace(old_n, new_n); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % c)
if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요:', P)
