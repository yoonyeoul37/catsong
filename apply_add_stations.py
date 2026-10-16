# -*- coding: utf-8 -*-
# 국내 라디오 목록에 새 방송 넣기 (radio_korea_screen2.dart)
# 지금 소리가 나오는 걸 확인한 주소만 넣어요. 주파수는 확인 못 해서 비워 둠.
# 실행: python apply_add_stations.py   (프로젝트 폴더에서)
import os, re, sys

P = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')

def K(name, region, bc, sub, url):
    return f"  _KStation(name: '{name}', region: '{region}', broadcaster: '{bc}', subLabel: '{sub}', frequency: '', streamUrl: '{url}'),"

NEW = {
    '수도권': [
        K('CBS JOY4U', '수도권', 'CBS', '서울', 'https://m-aac.cbs.co.kr/mweb_cbscmc/_definst_/cbscmc.stream/playlist.m3u8'),
        K('FEBC 극동방송 AM', '수도권', 'FEBC', '서울', 'http://mlive2.febc.net:1935/live/seoulam/playlist.m3u8'),
        K('아리랑 라디오', '수도권', 'Arirang', '서울', 'http://amdlive.ctnd.com.edgesuite.net/arirang_3ch/smil:arirang_3ch.smil/playlist.m3u8'),
        K('마포FM', '수도권', '공동체', '마포', 'http://onair.mapofm.net/mapofm'),
        K('수원 SoneFM', '수도권', '공동체', '수원', 'http://115.85.182.39/sonefm'),
    ],
    '부산/경남': [
        K('TBN 부산교통', '부산/경남', 'TBN', '부산', 'http://radio2.tbn.or.kr:1935/busan/myStream/playlist.m3u8'),
        K('TBN 경남교통', '부산/경남', 'TBN', '경남', 'http://radio2.tbn.or.kr:1935/gyeongnam/myStream/playlist.m3u8'),
    ],
    '대구/경북': [
        K('TBN 대구교통', '대구/경북', 'TBN', '대구', 'http://radio2.tbn.or.kr:1935/daegu/myStream/playlist.m3u8'),
        K('성서공동체FM', '대구/경북', '공동체', '대구', 'http://115.85.182.39/scnfm'),
    ],
    '광주/전남': [
        K('TBN 광주교통', '광주/전남', 'TBN', '광주', 'http://radio2.tbn.or.kr:1935/gwangju/myStream/playlist.m3u8'),
    ],
    '대전/충남': [
        K('TBN 대전교통', '대전/충남', 'TBN', '대전', 'http://radio2.tbn.or.kr:1935/daejeon/myStream/playlist.m3u8'),
        K('TBN 충남교통', '대전/충남', 'TBN', '충남', 'http://radio2.tbn.or.kr:1935/chungnam/myStream/playlist.m3u8'),
    ],
    '충북': [
        K('TBN 충북교통', '충북', 'TBN', '충북', 'http://radio2.tbn.or.kr:1935/chungbuk/myStream/playlist.m3u8'),
    ],
    '강원': [
        K('TBN 강원교통', '강원', 'TBN', '강원', 'http://radio2.tbn.or.kr:1935/gangwon/myStream/playlist.m3u8'),
    ],
    '전북': [
        K('전주MBC 표준FM', '전북', 'MBC', '전주', 'https://live.jmbc.co.kr/live/am_live.m3u8'),
        K('전주MBC FM4U', '전북', 'MBC', '전주', 'https://live.jmbc.co.kr/live/fm_live.m3u8'),
        K('TBN 전북교통', '전북', 'TBN', '전북', 'http://radio2.tbn.or.kr:1935/jeonbuk/myStream/playlist.m3u8'),
        K('전주FM', '전북', '공동체', '전주', 'http://radiostream.communityradio.kr/jcfm1'),
    ],
    '제주': [
        K('TBN 제주교통', '제주', 'TBN', '제주', 'http://radio2.tbn.or.kr:1935/jeju/myStream/playlist.m3u8'),
        K('FEBC 제주극동방송', '제주', 'FEBC', '제주', 'http://mlive2.febc.net:1935/live/jejufm/playlist.m3u8'),
    ],
}
DESC_ANCHOR = "    'JTV 매직FM': '음악·생활',\n"
DESC_ADD = ("    'CBS JOY4U': 'CCM 음악',\n"
            "    'FEBC 극동방송 AM': '종교·음악',\n"
            "    'FEBC 제주극동방송': '종교·음악',\n"
            "    '아리랑 라디오': '영어 방송',\n"
            "    '마포FM': '공동체 라디오',\n"
            "    '수원 SoneFM': '공동체 라디오',\n"
            "    '성서공동체FM': '공동체 라디오',\n"
            "    '전주FM': '공동체 라디오',\n")

if not os.path.isfile(P):
    print('❌ lib/screens/radio_korea_screen2.dart 가 없어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
with open(P, 'r', encoding='utf-8', newline='') as f:
    t = f.read()
crlf = '\r\n' in t
t = t.replace('\r\n', '\n')
if "name: 'TBN 부산교통'" in t:
    print('이미 적용돼 있어요'); sys.exit(0)

start = t.find('const koreanStations = <_KStation>[')
end = t.find('\n];', start)
if start < 0 or end < 0:
    print('❌ 방송 목록(koreanStations)을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
lines = t[start:end].split('\n')
for region, adds in NEW.items():
    idx = max((i for i, l in enumerate(lines) if f"region: '{region}'" in l), default=-1)
    if idx < 0:
        print(f'❌ {region} 지역 방송을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
    for a in adds:
        name = re.search(r"name: '([^']+)'", a).group(1)
        if f"name: '{name}'" in t:
            print(f'  ({name} 은 이미 있어서 건너뜀)')
            continue
        idx += 1
        lines.insert(idx, a)
    print(f'✔ {region}: {len(adds)}개')
t = t[:start] + '\n'.join(lines) + t[end:]
if t.count(DESC_ANCHOR) != 1:
    print('❌ 방송 설명 목록(JTV 매직FM 줄)을 못 찾았어요 — 아무것도 저장 안 했어요'); sys.exit(1)
t = t.replace(DESC_ANCHOR, DESC_ANCHOR + DESC_ADD)
print('✔ 방송 설명 8개')
d = lambda s: [s.count(a) - s.count(b) for a, b in ['()', '[]', '{}']]
if d(re.sub(r"'(?:[^'\\\n]|\\.)*'|//[^\n]*", '', t)) != [0, 0, 0]:
    print('❌ 괄호가 안 맞아요 — 아무것도 저장 안 했어요'); sys.exit(1)
if crlf:
    t = t.replace('\n', '\r\n')
with open(P, 'w', encoding='utf-8', newline='') as f:
    f.write(t)
print('완료! 국내 방송 21개를 넣었어요')
