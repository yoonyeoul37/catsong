# -*- coding: utf-8 -*-
# 해외 라디오 '지역' 칩 고치기
#  1) 인도: 지역을 누르면 지역 칩이 사라지던 것
#  2) 미국: CA / California / CALIFORNIA 처럼 이름이 제각각이라 지역이 적게 보이던 것
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('radio_country_stations_screen.dart')
if not path:
    print('❌ lib 폴더에서 radio_country_stations_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)

with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if 'String _stateOf(RadioStation s)' in src:
    print('이미 적용돼 있어요')
    sys.exit(0)

STATE_FN = r"""  // 미국 주 약자 → 이름 (CA, California 를 한 지역으로 묶기)
  static const Map<String, String> _usStates = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California',
    'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware', 'FL': 'Florida', 'GA': 'Georgia',
    'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa',
    'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
    'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi', 'MO': 'Missouri',
    'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire', 'NJ': 'New Jersey',
    'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio',
    'OK': 'Oklahoma', 'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
    'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont',
    'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia', 'WI': 'Wisconsin', 'WY': 'Wyoming',
    'DC': 'District of Columbia',
  };

  /// 방송국 지역 이름을 하나로 맞추기 (대소문자·띄어쓰기·미국 주 약자)
  String _stateOf(RadioStation s) {
    var st = (s.state ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (st.isEmpty) return '';
    if (widget.country.code.toUpperCase() == 'US') {
      final full = _usStates[st.toUpperCase()];
      if (full != null) return full;
    }
    // 전부 대문자이거나 전부 소문자면 첫 글자만 대문자로 (CALIFORNIA, california → California)
    if (st.length > 3 && (st == st.toUpperCase() || st == st.toLowerCase())) {
      st = st.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
    }
    return st;
  }

"""

edits = [
    ('지역 이름 맞추는 함수 추가',
     "  /// 칩마다 고를 항목 (이름, 방송 수) — 자료가 충분한 나라만\n",
     STATE_FN + "  /// 칩마다 고를 항목 (이름, 방송 수) — 자료가 충분한 나라만\n"),
    ('지역 칩 개수 셀 때 맞춘 이름 쓰기',
     "        final st = s.state?.trim() ?? '';\n",
     "        final st = _stateOf(s);\n"),
    ('지역 칩이 사라지지 않게 (고른 동안은 계속, 지역 있는 방송 20개 넘으면 계속)',
     "    if (chip == 'region' && (list.length < 2 || withInfo < all.length * 0.3)) return const [];\n",
     "    if (chip == 'region' && _chip != 'region' &&\n"
     "        (list.length < 2 || (withInfo < 20 && withInfo < all.length * 0.3))) return const [];\n"),
    ('지역 최대 15개 → 30개',
     "    return list.take(chip == 'region' ? 15 : 10).toList();\n",
     "    return list.take(chip == 'region' ? 30 : 10).toList();\n"),
    ('지역 고를 때 맞춘 이름으로 찾기',
     "    if (_chip == 'region') return (s.state?.trim() ?? '') == sub;\n",
     "    if (_chip == 'region') return _stateOf(s) == sub;\n"),
    ('지역별 보기도 맞춘 이름으로 묶기',
     "        if (s.state == null || s.state!.trim().isEmpty) continue;\n"
     "        grouped.putIfAbsent(s.state!.trim(), () => []).add(s);\n",
     "        final st = _stateOf(s);\n"
     "        if (st.isEmpty) continue;\n"
     "        grouped.putIfAbsent(st, () => []).add(s);\n"),
]

ok = True
for name, old, new in edits:
    if src.count(old) == 1:
        src = src.replace(old, new)
        print('✔', name)
    else:
        print('❌', name, '— 코드를 못 찾았어요')
        ok = False

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    src = src.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(src.encode('utf-8'))
print('저장했어요:', path)
