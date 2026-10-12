# -*- coding: utf-8 -*-
# 한국 라디오 목록: 편성표가 없는 방송은 둘째 줄에 주파수 대신 '지역 · 방송 성격'
#  예) YTN 라디오 → 서울 · 뉴스·시사 / 국방FM → 서울 · 국군 방송 / TBN 경인교통 → 경기 · 교통 정보
#  (돌릴 때 오른쪽에 나오는 주파수와 안 겹치게)
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('radio_korea_screen2.dart')
if not path:
    print('❌ lib 폴더에서 radio_korea_screen2.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if 'String _stationDesc(' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

rep('편성표 없는 방송: 주파수 → 지역 · 방송 성격',
    "                          return Text(\n"
    "                            station.frequency.isNotEmpty\n"
    "                                ? station.frequency\n"
    "                                : '',\n"
    "                            style: TextStyle(\n"
    "                              color: baseColor.withOpacity(0.4),\n"
    "                              fontSize: 12,\n"
    "                            ),\n"
    "                          );\n",
    "                          return Text(\n"
    "                            _stationDesc(station), // 지역 · 방송 성격\n"
    "                            maxLines: 1,\n"
    "                            overflow: TextOverflow.ellipsis,\n"
    "                            style: TextStyle(\n"
    "                              color: baseColor.withOpacity(0.55),\n"
    "                              fontSize: 12,\n"
    "                            ),\n"
    "                          );\n")

rep('프로그램을 아직 못 불러온 방송도 같은 줄로',
    "                            Text(\n"
    "                              [\n"
    "                                if (station.frequency.isNotEmpty) station.frequency,\n"
    "                                if (timeStr.isNotEmpty) timeStr,\n"
    "                              ].join(' · '),\n"
    "                              style: TextStyle(\n"
    "                                color: baseColor.withOpacity(0.55),\n"
    "                                fontSize: 11,\n"
    "                              ),\n"
    "                            ),\n",
    "                            Text(\n"
    "                              _stationDesc(station), // 지역 · 방송 성격\n"
    "                              maxLines: 1,\n"
    "                              overflow: TextOverflow.ellipsis,\n"
    "                              style: TextStyle(\n"
    "                                color: baseColor.withOpacity(0.55),\n"
    "                                fontSize: 12,\n"
    "                              ),\n"
    "                            ),\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

s = s.rstrip('\n') + """

/// 방송 둘째 줄: '지역 · 방송 성격' (예: 서울 · 뉴스·시사)
String _stationDesc(_KStation s) {
  const exact = {
    'KBS Cool FM': '가요·팝',
    'KBS 3라디오': '사회·복지',
    'MBC 올댓뮤직': '음악',
    'SBS 파워FM': '가요·예능',
    'SBS 러브FM': '시사·생활',
    'CBS 음악FM': '음악',
    'CBS 표준FM': '시사·종교',
    'YTN 라디오': '뉴스·시사',
    'TBS FM': '교통·생활',
    'TBS eFM': '영어 방송',
    'EBS FM': '교육',
    'EBS 반디': '외국어 학습',
    'OBS 라디오': '음악·생활',
    '경인방송': '음악·생활',
    'CPBC 가톨릭': '종교·음악',
    'FEBC 극동방송': '종교·음악',
    'BBS 불교방송': '종교·음악',
    '국악FM': '국악',
    '국방FM': '국군 방송',
    'BeFM': '영어 방송',
    'JTV 매직FM': '음악·생활',
  };
  final n = s.name;
  String? g = exact[n];
  if (g == null) {
    if (n.startsWith('TBN')) {
      g = '교통 정보';
    } else if (n.contains('1라디오')) {
      g = '뉴스·시사';
    } else if (n.contains('해피FM')) {
      g = '가요·생활';
    } else if (n.contains('1FM') || n.contains('Classic')) {
      g = '클래식';
    } else if (n.contains('FM4U')) {
      g = '음악';
    } else if (n.contains('표준FM')) {
      g = '시사·교양';
    }
  }
  final loc = (s.subLabel.isEmpty || s.subLabel == '외국어') ? '서울' : s.subLabel;
  return g == null ? loc : '$loc · $g';
}
"""
print('✔ 방송 성격 정하기')

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
