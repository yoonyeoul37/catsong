# -*- coding: utf-8 -*-
# 해외 라디오 '지역': 어느 나라든 지역(주)이 처음부터 전부 나오게
#  - 서버에 '이 나라 지역 목록 + 방송 수'를 물어봐서 칩에 전부 보여줌
#  - 지역을 누르면 그 지역 방송만 서버에서 바로 불러옴
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

def load(path):
    with open(path, 'rb') as f:
        raw = f.read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

def save(path, src, crlf):
    shutil.copy(path, path + '.bak')
    if crlf:
        src = src.replace('\n', '\r\n')
    with open(path, 'wb') as f:
        f.write(src.encode('utf-8'))
    print('저장했어요:', path)

prov_path = find_file('radio_provider.dart')
scr_path = find_file('radio_country_stations_screen.dart')
if not prov_path or not scr_path:
    print('❌ lib 폴더에서 radio_provider.dart / radio_country_stations_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)

prov, prov_crlf = load(prov_path)
scr, scr_crlf = load(scr_path)

if 'fetchStateStations' in prov and 'countryStates' in scr:
    print('이미 적용돼 있어요')
    sys.exit(0)
if 'String _stateOf(RadioStation s)' not in scr:
    print('❌ 먼저 apply_radio_region.py를 적용해야 해요. 아무것도 저장 안 했어요.')
    sys.exit(1)

ok = True
def rep(src, name, old, new):
    global ok
    if src.count(old) == 1:
        print('✔', name)
        return src.replace(old, new)
    print('❌', name, '— 코드를 못 찾았어요')
    ok = False
    return src

# ───────── radio_provider.dart ─────────
PROV_BLOCK = r"""  // ── 지역(주): 서버에 이 나라 지역 목록과 방송 수를 물어봄 ──
  String? _countryApiName; // 서버가 쓰는 나라 이름 (예: The United States Of America)
  Map<String, int> _countryStates = {}; // 맞춘 지역 이름 → 방송 수
  final Map<String, Set<String>> _stateRawNames = {}; // 맞춘 이름 → 서버 이름들 (CA, California)
  final Set<String> _stateTried = {}; // 이미 불러온 지역
  String? _loadingState;
  static List<dynamic>? _allStatesCache;
  Map<String, int> get countryStates => _countryStates;
  bool stateTried(String state) => _stateTried.contains(state);
  bool isStateLoading(String state) => _loadingState == state;

  // 미국 주 약자 → 이름 (CA, California 를 한 지역으로 묶기)
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

  /// 지역 이름을 하나로 맞추기 (대소문자·띄어쓰기·미국 주 약자)
  static String normState(String raw, String countryCode) {
    var st = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (st.isEmpty) return '';
    if (countryCode.toUpperCase() == 'US') {
      final full = _usStates[st.toUpperCase()];
      if (full != null) return full;
    }
    // 전부 대문자이거나 전부 소문자면 첫 글자만 대문자로 (CALIFORNIA, california → California)
    if (st.length > 3 && (st == st.toUpperCase() || st == st.toLowerCase())) {
      st = st.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
    }
    return st;
  }

  Map<String, int> _statesFrom(List<dynamic> items, String countryCode, String name) {
    final counts = <String, int>{};
    _stateRawNames.clear();
    for (final it in items) {
      if (it is! Map) continue;
      if ((it['country'] ?? '').toString().toLowerCase() != name.toLowerCase()) continue;
      final raw = (it['name'] ?? '').toString();
      final key = normState(raw, countryCode);
      if (key.isEmpty) continue;
      final c = it['stationcount'] is num ? (it['stationcount'] as num).toInt() : 0;
      if (c <= 0) continue;
      counts[key] = (counts[key] ?? 0) + c;
      _stateRawNames.putIfAbsent(key, () => <String>{}).add(raw);
    }
    return counts;
  }

  Future<void> _fetchCountryStates(String countryCode) async {
    final name = _countryApiName;
    if (name == null || name.isEmpty) return;
    List<String> servers;
    try {
      servers = await _getApiServers();
    } catch (e) {
      return;
    }
    var counts = <String, int>{};
    // 먼저 이 나라 지역만
    for (final server in servers) {
      try {
        final uri = Uri.https(server, '/json/states/$name/', {'hidebroken': 'true'});
        final r = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) continue;
        final d = json.decode(r.body);
        if (d is List) counts = _statesFrom(d, countryCode, name);
        break;
      } catch (e) {
        debugPrint('지역 목록 오류($server): $e');
      }
    }
    // 안 되면 전체 지역 목록에서 이 나라 것만 (한 번 받아서 계속 씀)
    if (counts.isEmpty) {
      if (_allStatesCache == null) {
        for (final server in servers) {
          try {
            final uri = Uri.https(server, '/json/states', {'hidebroken': 'true'});
            final r = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 25));
            if (r.statusCode != 200) continue;
            final d = json.decode(r.body);
            if (d is List) _allStatesCache = d;
            break;
          } catch (e) {
            debugPrint('전체 지역 목록 오류($server): $e');
          }
        }
      }
      if (_allStatesCache != null) counts = _statesFrom(_allStatesCache!, countryCode, name);
    }
    if (_countryCode != countryCode) return;
    _countryStates = counts;
    notifyListeners();
  }

  /// 지역을 고르면 그 지역 방송을 서버에서 따로 불러와 목록에 붙이기
  Future<void> fetchStateStations(String state) async {
    final code = _countryCode;
    if (code == null || _stateTried.contains(state) || _loadingState != null) return;
    _stateTried.add(state);
    _loadingState = state;
    notifyListeners();
    final raws = _stateRawNames[state] ?? {state};
    final added = <RadioStation>[];
    try {
      final servers = await _getApiServers();
      for (final raw in raws.take(5)) {
        for (final server in servers) {
          try {
            final uri = Uri.https(server, '/json/stations/search', {
              'countrycode': code,
              'state': raw,
              'order': 'clickcount',
              'reverse': 'true',
              'limit': '300',
              'hidebroken': 'true',
            });
            final r = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 15));
            if (r.statusCode != 200) continue;
            final List<dynamic> data = json.decode(r.body);
            if (_countryCode != code) break;
            for (final j in data) {
              final m = j as Map<String, dynamic>;
              final codec = (m['codec'] ?? '').toString().toUpperCase();
              if (codec.isNotEmpty && !const ['MP3', 'AAC', 'AAC+', 'OGG'].contains(codec)) continue;
              if (m['lastcheckok'] == 0) continue;
              final s = RadioStation.fromJson(m);
              if (s.streamUrl.isEmpty) continue;
              if (normState(s.state ?? '', code) != state) continue;
              final key = _nameKey(s.name);
              if (key.isEmpty || !_countryNameKeys.add(key)) continue;
              final lang = (m['language'] ?? '').toString().split(',').first.trim();
              if (lang.isNotEmpty) _stationLanguage[s.stationUuid] = lang;
              final tr = m['clicktrend'];
              if (tr is num) _stationTrend[s.stationUuid] = tr.toInt();
              added.add(s);
            }
            break;
          } catch (e) {
            debugPrint('지역 방송 로드 오류($server): $e');
          }
        }
      }
    } catch (e) {
      debugPrint('지역 방송 로드 실패: $e');
    }
    if (_countryCode == code && added.isNotEmpty) {
      _mergeFavoriteFlags(added);
      _countryStations = [..._countryStations, ...added];
    }
    _loadingState = null;
    notifyListeners();
  }

  /// 목록 끝에 가까워지면 다음 200개 더 불러오기
"""

prov = rep(prov, '지역 목록·지역 방송 불러오기 추가',
           "  /// 목록 끝에 가까워지면 다음 200개 더 불러오기\n", PROV_BLOCK)

prov = rep(prov, '서버가 쓰는 나라 이름 기억',
           "          final m = j as Map<String, dynamic>;\n"
           "          final s = RadioStation.fromJson(m);\n"
           "          if (s.streamUrl.isEmpty) continue;\n"
           "          final key = _nameKey(s.name);\n",
           "          final m = j as Map<String, dynamic>;\n"
           "          if (_countryApiName == null && (m['country'] ?? '').toString().trim().isNotEmpty) {\n"
           "            _countryApiName = m['country'].toString().trim();\n"
           "          }\n"
           "          final s = RadioStation.fromJson(m);\n"
           "          if (s.streamUrl.isEmpty) continue;\n"
           "          final key = _nameKey(s.name);\n")

prov = rep(prov, '나라 바뀌면 지역 정보 비우기',
           "      _countryNameKeys.clear();\n"
           "      _countryOffset = 0;\n",
           "      _countryNameKeys.clear();\n"
           "      _countryApiName = null;\n"
           "      _countryStates = {};\n"
           "      _stateRawNames.clear();\n"
           "      _stateTried.clear();\n"
           "      _loadingState = null;\n"
           "      _countryOffset = 0;\n")

prov = rep(prov, '첫 방송 불러온 뒤 지역 목록 묻기',
           "    if (got > 0) {\n"
           "      _countryOffset = got;\n"
           "      _countryHasMore = got >= limit;\n"
           "    }\n",
           "    if (got > 0) {\n"
           "      _countryOffset = got;\n"
           "      _countryHasMore = got >= limit;\n"
           "      _fetchCountryStates(countryCode);\n"
           "    }\n")

# ───────── radio_country_stations_screen.dart ─────────
start = scr.find("  // 미국 주 약자 → 이름 (CA, California 를 한 지역으로 묶기)\n")
end = scr.find("  /// 칩마다 고를 항목 (이름, 방송 수)")
if start >= 0 and end > start and 'String _stateOf(RadioStation s)' in scr[start:end]:
    scr = scr[:start] + (
        "  /// 방송국 지역 이름을 하나로 맞추기 (대소문자·띄어쓰기·미국 주 약자)\n"
        "  String _stateOf(RadioStation s) => RadioProvider.normState(s.state ?? '', widget.country.code);\n\n"
    ) + scr[end:]
    print('✔ 지역 이름 맞추기를 라디오 정보 쪽과 같이 쓰기')
else:
    print('❌ 지역 이름 맞추기 — 코드를 못 찾았어요')
    ok = False

scr = rep(scr, '지역 칩: 서버 지역 목록을 전부 보여주기',
          "  List<(String, int)> _optionsFor(String chip, List<RadioStation> all, RadioProvider radio) {\n",
          "  List<(String, int)> _optionsFor(String chip, List<RadioStation> all, RadioProvider radio) {\n"
          "    // 지역: 서버가 알려준 이 나라 지역 전부 (방송 많은 순)\n"
          "    if (chip == 'region' && radio.countryStates.length >= 2) {\n"
          "      final l = radio.countryStates.entries.map((e) => (e.key, e.value)).toList()\n"
          "        ..sort((a, b) => b.$2.compareTo(a.$2));\n"
          "      return l.take(100).toList();\n"
          "    }\n")

scr = rep(scr, '지역 고르면 그 지역 방송 불러오기',
          "    // 찾는 방송이 적게 보이면 다음 방송을 자동으로 더 불러오기 (2000개까지)\n"
          "    if ((_query.isNotEmpty || _chip != 'pop') &&\n",
          "    // 지역을 고르면 그 지역 방송을 서버에서 따로 불러오기\n"
          "    final regionSub = (_chip == 'region' && radioProvider.countryStates.isNotEmpty) ? _sub : null;\n"
          "    if (regionSub != null && !radioProvider.stateTried(regionSub)) {\n"
          "      WidgetsBinding.instance.addPostFrameCallback((_) {\n"
          "        if (mounted) context.read<RadioProvider>().fetchStateStations(regionSub);\n"
          "      });\n"
          "    }\n"
          "    // 찾는 방송이 적게 보이면 다음 방송을 자동으로 더 불러오기 (2000개까지)\n"
          "    if ((_query.isNotEmpty || _chip != 'pop') &&\n"
          "        regionSub == null &&\n")

scr = rep(scr, '지역 방송 불러오는 동안 동그라미 보이기',
          "    final isLoading = radioProvider.isLoadingCountryStations;\n",
          "    final isLoading = radioProvider.isLoadingCountryStations ||\n"
          "        (stations.isEmpty && regionSub != null && radioProvider.isStateLoading(regionSub));\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

save(prov_path, prov, prov_crlf)
save(scr_path, scr, scr_crlf)
