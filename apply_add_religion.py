# -*- coding: utf-8 -*-
# 지역 CBS · 극동방송 · 불교방송 · 평화방송 추가 — radio_korea_screen2.dart
import os, sys
P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')
if not os.path.exists(P):
    for r, _, fs in os.walk('lib'):
        if 'radio_korea_screen2.dart' in fs: P = os.path.join(r, 'radio_korea_screen2.dart')
if not os.path.exists(P):
    print('❌ radio_korea_screen2.dart 를 못 찾았어요'); sys.exit(1)
s = open(P, 'rb').read().decode('utf-8')
if "name: 'FEBC 부산극동방송'" in s:
    print('이미 적용돼 있어요'); sys.exit(0)
NL = '\r\n' if '\r\n' in s else '\n'

C = 'https://m-aac.cbs.co.kr/%s/_definst_/%s.stream/playlist.m3u8'
F = 'https://mlive3.febc.net/%s/playlist.m3u8'
# (이름, 지역, 방송사, 도시, 주파수, 주소, 설명)
ST = [
    # CBS
    ('CBS 부산 표준FM', '부산/경남', 'CBS', '부산', '102.9 MHz', C % ('busan981', 'busan981'), '시사·종교'),
    ('CBS 부산 음악FM', '부산/경남', 'CBS', '부산', '102.1 MHz', C % ('busan939', 'busan939'), '음악'),
    ('CBS 울산 표준FM', '부산/경남', 'CBS', '울산', '', C % ('ulsan', 'ulsan'), '시사·종교'),
    ('CBS 경남 표준FM', '부산/경남', 'CBS', '창원', '106.9 MHz', C % ('gyeongnam', 'gyeongnam'), '시사·종교'),
    ('CBS 대구 표준FM', '대구/경북', 'CBS', '대구', '103.1 MHz', C % ('daegu', 'daegu'), '시사·종교'),
    ('CBS 대구 음악FM', '대구/경북', 'CBS', '대구', '97.1 MHz', C % ('daegu939', 'daegu939'), '음악'),
    ('CBS 포항 표준FM', '대구/경북', 'CBS', '포항', '91.5 MHz', C % ('pohang', 'pohang'), '시사·종교'),
    ('CBS 광주 표준FM', '광주/전남', 'CBS', '광주', '', C % ('gwangju', 'gwangju'), '시사·종교'),
    ('CBS 전남 표준FM', '광주/전남', 'CBS', '순천', '', C % ('jeonnam', 'jeonnam'), '시사·종교'),
    ('CBS 전북 표준FM', '전북', 'CBS', '전주', '', C % ('jeonbuk', 'jeonbuk'), '시사·종교'),
    ('CBS 대전 표준FM', '대전/충남', 'CBS', '대전', '', C % ('daejeon', 'daejeon'), '시사·종교'),
    ('CBS 청주 표준FM', '충북', 'CBS', '청주', '', C % ('cheongju', 'cheongju'), '시사·종교'),
    ('CBS 강원 표준FM', '강원', 'CBS', '춘천', '93.7 MHz', C % ('chuncheon', 'chuncheon'), '시사·종교'),
    ('CBS 강원영동 표준FM', '강원', 'CBS', '강릉', '91.5 MHz', C % ('youngdong', 'youngdong'), '시사·종교'),
    ('CBS 제주 표준FM', '제주', 'CBS', '제주', '93.3 MHz', C % ('jeju', 'jeju'), '시사·종교'),
    # 극동방송
    ('FEBC 부산극동방송', '부산/경남', 'FEBC', '부산', '93.3 MHz', F % 'live5/bsfebc', '종교·음악'),
    ('FEBC 창원극동방송', '부산/경남', 'FEBC', '창원', '98.1 MHz', F % 'live5/cwlive', '종교·음악'),
    ('FEBC 울산극동방송', '부산/경남', 'FEBC', '울산', '107.3 MHz', F % 'live5/uslive', '종교·음악'),
    ('FEBC 대구극동방송', '대구/경북', 'FEBC', '대구', '91.9 MHz', F % 'live5/daegulive', '종교·음악'),
    ('FEBC 포항극동방송', '대구/경북', 'FEBC', '포항', '90.3 MHz', F % 'live5/phlive', '종교·음악'),
    ('FEBC 광주극동방송', '광주/전남', 'FEBC', '광주', '93.1 MHz', F % 'live5/gjlive', '종교·음악'),
    ('FEBC 목포극동방송', '광주/전남', 'FEBC', '목포', '100.5 MHz', F % 'live5/mplive', '종교·음악'),
    ('FEBC 전남동부극동방송', '광주/전남', 'FEBC', '순천', '97.5 MHz', F % 'live/jndblive', '종교·음악'),
    ('FEBC 전북극동방송', '전북', 'FEBC', '전북', '91.1 MHz', F % 'live5/jblive', '종교·음악'),
    ('FEBC 대전극동방송', '대전/충남', 'FEBC', '대전', '93.3 MHz', F % 'live5/djlive', '종교·음악'),
    ('FEBC 강원극동방송', '강원', 'FEBC', '강릉', '90.1 MHz', F % 'live5/ydlive', '종교·음악'),
    # 불교방송
    ('BBS 부산불교방송', '부산/경남', 'BBS', '부산', '89.9 MHz', 'http://live.cdn.smilecdn.com:1935/bbsfm_live//playlist.m3u8', '종교·음악'),
    ('BBS 울산불교방송', '부산/경남', 'BBS', '울산', '88.3 MHz', 'https://bbslive.goldenday.kr:446/hls/bbsus_live.m3u8', '종교·음악'),
    ('BBS 대구불교방송', '대구/경북', 'BBS', '대구', '94.5 MHz', 'http://live.cdn.smilecdn.com:1935/dgbbs_live/live/playlist.m3u8', '종교·음악'),
    ('BBS 광주불교방송', '광주/전남', 'BBS', '광주', '89.7 MHz', 'http://live.cdn.smilecdn.com:1935/kjbbs1_live/live/playlist.m3u8', '종교·음악'),
    # 평화방송
    ('CPBC 부산평화방송', '부산/경남', 'CPBC', '부산', '101.1 MHz', 'http://pbcradio.dynamicsmart.com:1935/radio/bscpbc-radio/index.m3u8', '종교·음악'),
    ('CPBC 대구평화방송', '대구/경북', 'CPBC', '대구', '93.1 MHz', 'http://live.dgcpbc.co.kr/dgcpbclive/livestream/playlist.m3u8', '종교·음악'),
    ('CPBC 광주평화방송', '광주/전남', 'CPBC', '광주', '99.9 MHz', 'http://pbcradio.dynamicsmart.com:1935/radio/kjpbc2/index.m3u8', '종교·음악'),
]
for n, *_ in ST:
    if ("name: '%s'" % n) in s:
        print('❌ 이미 같은 이름이 있어요:', n); sys.exit(1)
for _, _, _, city, *_ in ST:
    if ("  '%s': {" % city) not in s:
        print('❌ 번역에 %s 가 없어요' % city); sys.exit(1)

jeju = "  _KStation(name: 'FEBC 제주극동방송', region: '제주', broadcaster: 'FEBC', subLabel: '제주', frequency: '104.7 MHz', streamUrl: 'http://mlive2.febc.net:1935/live/jejufm/playlist.m3u8'),"
lines = NL.join("  _KStation(name: '%s', region: '%s', broadcaster: '%s', subLabel: '%s', frequency: '%s', streamUrl: '%s')," % t[:6] for t in ST)
d_old = "    'FEBC 제주극동방송': '종교·음악',"
d_new = d_old + NL + NL.join("    '%s': '%s'," % (t[0], t[6]) for t in ST)
steps = [
    ('방송 %d개 추가 (제주극동방송 아래)' % len(ST), jeju, jeju + NL + lines),
    ('설명 추가', d_old, d_new),
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
