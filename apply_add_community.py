# -*- coding: utf-8 -*-
# 공동체 라디오 8개 추가 — radio_korea_screen2.dart
import os, sys
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    for r, _, fs in os.walk('lib'):
        if 'radio_korea_screen2.dart' in fs: P = os.path.join(r, 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
if "name: '연제FM'" in s:
    print('이미 적용돼 있어요'); sys.exit(0)
NL = '\r\n' if '\r\n' in s else '\n'

def i18n(key, d):
    return NL.join(["  '%s': {" % key] + ["    '%s': '%s'," % (k, v) for k, v in d.items()] + ['  },']) + NL

namhae = {'en':'Namhae','de':'Namhae','es':'Namhae','fr':'Namhae','it':'Namhae','pt':'Namhae','pl':'Namhae','ro':'Namhae','cs':'Namhe','hu':'Namhe','tr':'Namhae','id':'Namhae','vi':'Namhae','ru':'Намхэ','uk':'Намхе','ja':'南海','zh':'南海','zh_Hant':'南海','th':'นัมแฮ','hi':'नामहे','ar':'نامهاي','ur':'نامہے'}
sejong = {'en':'Sejong','de':'Sejong','es':'Sejong','fr':'Sejong','it':'Sejong','pt':'Sejong','pl':'Sejong','ro':'Sejong','cs':'Sedžong','hu':'Szedzsong','tr':'Sejong','id':'Sejong','vi':'Sejong','ru':'Седжон','uk':'Седжон','ja':'世宗','zh':'世宗','zh_Hant':'世宗','th':'เซจง','hi':'सेजोंग','ar':'سيجونغ','ur':'سیجونگ'}
okcheon = {'en':'Okcheon','de':'Okcheon','es':'Okcheon','fr':'Okcheon','it':'Okcheon','pt':'Okcheon','pl':'Okcheon','ro':'Okcheon','cs':'Okčon','hu':'Okcson','tr':'Okcheon','id':'Okcheon','vi':'Okcheon','ru':'Окчхон','uk':'Окчхон','ja':'沃川','zh':'沃川','zh_Hant':'沃川','th':'อกช็อน','hi':'ओकचोन','ar':'أوكتشون','ur':'اوکچون'}

ST = [
    ('단원FM', '수도권', '안산', '88.7 MHz', 'https://stream.cradio.kr/dwfm1'),
    ('남해FM', '부산/경남', '남해', '91.9 MHz', 'https://stream.namhaefm.com/namhaefm'),
    ('연제FM', '부산/경남', '부산', '106.3 MHz', 'https://stream.cradio.kr/yeonjefm'),
    ('대구동구FM', '대구/경북', '대구', '104.5 MHz', 'https://stream.cradio.kr/daegufm'),
    ('고려FM', '광주/전남', '광주', '93.5 MHz', 'http://115.68.193.176:8000/crfm'),
    ('금강FM', '대전/충남', '충남', '104.9 MHz', 'http://121.183.240.143:8000/KKFM1'),
    ('세종FM', '대전/충남', '세종', '98.9 MHz', 'https://stream.cradio.kr/sejongfm'),
    ('옥천FM', '충북', '옥천', '104.9 MHz', 'https://stream.cradio.kr/obn'),
]
for n, *_ in ST:
    if ("name: '%s'" % n) in s:
        print('❌ 이미 같은 이름이 있어요:', n); sys.exit(1)

sn = "  _KStation(name: '성남FM', region: '수도권', broadcaster: '공동체', subLabel: '성남', frequency: '90.7 MHz', streamUrl: 'http://115.85.182.39/seongnamfm'),"
lines = NL.join("  _KStation(name: '%s', region: '%s', broadcaster: '공동체', subLabel: '%s', frequency: '%s', streamUrl: '%s')," % t for t in ST)
desc_new = NL.join("    '%s': '공동체 라디오'," % t[0] for t in ST if t[0] != '단원FM')
ccm = "  'CCM 음악': {"
steps = [
    ('공동체 라디오 %d개 추가 (성남FM 아래)' % len(ST), sn, sn + NL + lines),
    ('설명 (공동체 라디오)', "    '성남FM': '공동체 라디오',", "    '성남FM': '공동체 라디오'," + NL + desc_new),
    ('남해 · 세종 · 옥천 번역', ccm, i18n('남해', namhae) + i18n('세종', sejong) + i18n('옥천', okcheon) + ccm),
]
for key in ['남해', '세종', '옥천']:
    if ("  '%s': {" % key) in s:
        print('❌ 번역에 %s 가 이미 있어요' % key); sys.exit(1)
ok = True
for name, old, new in steps:
    c = s.count(old)
    if c == 1:
        s = s.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(찾은 개수: %d)' % c)
if "'단원FM': '공동체 라디오'," not in s:
    s = s.replace("    '성남FM': '공동체 라디오',", "    '성남FM': '공동체 라디오'," + NL + "    '단원FM': '공동체 라디오',", 1)
if not ok:
    print('❌ 하나라도 실패해서 저장 안 했어요'); sys.exit(1)
open(P, 'wb').write(s.encode('utf-8'))
print('저장했어요:', P)
