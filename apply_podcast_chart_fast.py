# -*- coding: utf-8 -*-
# 팟캐스트 탭 첫 화면(인기 순위)도 빨리 뜨게 — 모든 나라 같게
#  A. 한 번 본 나라 순위는 폰에 저장 → 다음부터 바로 (하루 지나면 새로 받기 · 인터넷이 안 되면 저장된 것)
#  B. 순위 기다리는 시간 15초 → 6초 (순위가 없는 나라는 빨리 미국 순위로)
#  + 같은 검색은 앱 켜져 있는 동안 다시 안 받기
import os, sys

PATH = os.path.join('lib', 'podcast', 'podcast.dart')


def fail(m):
    print('❌', m, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


if not os.path.exists(PATH):
    fail('파일이 없어요: ' + PATH)
raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
orig = s


def rep(label, old, new, done):
    global s
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    s = s.replace(old, new)
    print('✔', label)


rep('인기 순위: 폰에 저장 + 6초',
    '  /// 나라별 인기 순위 (앱 켜져 있는 동안 한 번만 받음)\n'
    '  static Future<List<PodcastShow>> top(String country, {int n = 50}) async {\n'
    '    final cc = country.toLowerCase();\n'
    '    final hit = _charts[cc];\n'
    '    if (hit != null) return hit;\n'
    '    final r = await http\n'
    "        .get(Uri.parse('https://rss.applemarketingtools.com/api/v2/$cc/podcasts/top/$n/podcasts.json'), headers: _ua)\n"
    '        .timeout(const Duration(seconds: 15));\n'
    "    if (r.statusCode != 200) throw Exception('chart ${r.statusCode}');\n",
    '  /// 나라별 인기 순위 — 한 번 본 나라는 폰에 저장해서 바로 (하루 지나면 새로 · 인터넷이 안 되면 저장된 것)\n'
    '  static Future<List<PodcastShow>> top(String country, {int n = 50}) async {\n'
    '    final cc = country.toLowerCase();\n'
    '    final hit = _charts[cc];\n'
    '    if (hit != null) return hit;\n'
    '    List<PodcastShow>? saved;\n'
    '    var fresh = false;\n'
    '    try {\n'
    "      final raw = (await SharedPreferences.getInstance()).getString('pod_chart_$cc');\n"
    '      if (raw != null) {\n'
    '        final j = jsonDecode(raw) as Map<String, dynamic>;\n'
    "        saved = [for (final x in (j['list'] as List)) PodcastShow.fromJson(Map<String, dynamic>.from(x))];\n"
    "        final at = DateTime.fromMillisecondsSinceEpoch(j['at'] is int ? j['at'] : 0);\n"
    '        fresh = DateTime.now().difference(at) < const Duration(hours: 24);\n'
    '        if (saved.isEmpty) saved = null;\n'
    '      }\n'
    '    } catch (_) {}\n'
    '    if (saved != null && fresh) return _charts[cc] = saved; // 하루 안에 받은 것 → 바로\n'
    '    try {\n'
    '      final list = await _fetchTop(cc, n);\n'
    '      _saveChart(cc, list);\n'
    '      return _charts[cc] = list;\n'
    '    } catch (_) {\n'
    '      if (saved != null) return _charts[cc] = saved; // 못 받으면 예전 순위라도\n'
    '      rethrow;\n'
    '    }\n'
    '  }\n'
    '\n'
    '  static Future<void> _saveChart(String cc, List<PodcastShow> list) async {\n'
    '    try {\n'
    '      if (list.isEmpty) return;\n'
    '      (await SharedPreferences.getInstance()).setString(\'pod_chart_$cc\',\n'
    "          jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'list': [for (final x in list) x.toJson()]}));\n"
    '    } catch (_) {}\n'
    '  }\n'
    '\n'
    '  static Future<List<PodcastShow>> _fetchTop(String cc, int n) async {\n'
    '    final r = await http\n'
    "        .get(Uri.parse('https://rss.applemarketingtools.com/api/v2/$cc/podcasts/top/$n/podcasts.json'), headers: _ua)\n"
    '        .timeout(const Duration(seconds: 6)); // 순위가 없는 나라는 빨리 미국 순위로\n'
    "    if (r.statusCode != 200) throw Exception('chart ${r.statusCode}');\n",
    done='static Future<List<PodcastShow>> _fetchTop(String cc, int n) async {')
rep('인기 순위: 받은 목록 돌려주기',
    '          genre: (x[\'genres\'] is List && (x[\'genres\'] as List).isNotEmpty)\n'
    "              ? '${(x['genres'] as List).first['name'] ?? ''}'\n"
    "              : '',\n"
    '        ),\n'
    '    ];\n'
    '    return _charts[cc] = list;\n'
    '  }\n',
    '          genre: (x[\'genres\'] is List && (x[\'genres\'] as List).isNotEmpty)\n'
    "              ? '${(x['genres'] as List).first['name'] ?? ''}'\n"
    "              : '',\n"
    '        ),\n'
    '    ];\n'
    "    if (list.isEmpty) throw Exception('chart empty');\n"
    '    return list;\n'
    '  }\n',
    done="if (list.isEmpty) throw Exception('chart empty');")
rep('검색: 같은 검색은 다시 안 받기',
    '  /// 검색 (그 나라 스토어에서)\n'
    '  static Future<List<PodcastShow>> search(String term, String country) async {\n',
    "  static final Map<String, List<PodcastShow>> _searches = {}; // 앱 켜져 있는 동안 같은 검색은 바로\n"
    '\n'
    '  /// 검색 (그 나라 스토어에서)\n'
    '  static Future<List<PodcastShow>> search(String term, String country) async {\n'
    "    final key = '${country.toLowerCase()}|$term';\n"
    '    final hit = _searches[key];\n'
    '    if (hit != null) return hit;\n'
    '    final list = await _search(term, country);\n'
    '    if (_searches.length > 40) _searches.remove(_searches.keys.first);\n'
    '    return _searches[key] = list;\n'
    '  }\n'
    '\n'
    '  static Future<List<PodcastShow>> _search(String term, String country) async {\n',
    done='static final Map<String, List<PodcastShow>> _searches = {};')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
