# -*- coding: utf-8 -*-
# 팟캐스트 탭: '팟캐스트란?' 안내 카드(처음 한 번, 알겠어요 누르면 접힘) + 주제 추천 칩(누르면 그 주제로 검색)
import os, sys

PATH = os.path.join('lib', 'podcast', 'podcast_screens.dart')


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
        fail(label + ' — 찾을 코드를 못 찾았어요')
    s = s.replace(old, new)
    print('✔', label)


rep('import', "import 'package:cached_network_image/cached_network_image.dart';\n",
    "import 'package:cached_network_image/cached_network_image.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\n",
    done="import 'package:shared_preferences/shared_preferences.dart';")

rep('안내 카드·추천 칩 값', '  Future<List<PodcastShow>>? _results;\n',
    '  Future<List<PodcastShow>>? _results;\n'
    "  bool _introSeen = true; // '팟캐스트란?' 안내 카드를 접었는지\n"
    '  String? _topic; // 고른 추천 칩\n'
    '\n'
    '  // 추천 칩: (그림, 한국어, 영어, 한국어 검색어, 영어 검색어)\n'
    '  static const _topics = [\n'
    "    ('📻', '라디오 다시듣기', 'Radio shows', '라디오', 'radio'),\n"
    "    ('📰', '뉴스', 'News', '뉴스', 'news'),\n"
    "    ('📚', '책 읽어주기', 'Books', '오디오북', 'audiobook'),\n"
    "    ('🗣️', '영어 공부', 'Learn English', '영어', 'learn english'),\n"
    "    ('😂', '웃음', 'Comedy', '코미디', 'comedy'),\n"
    "    ('🌙', '잠들기 전', 'Sleep', '수면', 'sleep'),\n"
    "    ('💰', '경제', 'Business', '경제', 'business'),\n"
    '  ];\n',
    done='static const _topics = [')

rep('안내 카드 본 적 있는지 불러오기', '    super.initState();\n    _loadChart();\n  }\n',
    '    super.initState();\n    _loadChart();\n'
    '    SharedPreferences.getInstance().then((p) {\n'
    "      if (mounted && !(p.getBool('pod_intro_seen') ?? false)) setState(() => _introSeen = false);\n"
    '    });\n'
    '  }\n',
    done="p.getBool('pod_intro_seen')")

rep('직접 검색하면 칩 풀기', '      _query = q;\n      _results = q.isEmpty ? null : PodcastApi.search(q, _cc);\n    });\n  }\n',
    '      _query = q;\n      _topic = null;\n      _results = q.isEmpty ? null : PodcastApi.search(q, _cc);\n    });\n  }\n'
    '\n'
    '  /// 추천 칩 누르기: 그 주제로 검색 (같은 칩 한 번 더 → 인기 순위로)\n'
    '  void _pickTopic(int i) {\n'
    '    _buzz();\n'
    '    final t = _topics[i];\n'
    '    _search.clear();\n'
    '    FocusScope.of(context).unfocus();\n'
    '    if (_topic == t.$2) {\n'
    "      _runSearch('');\n"
    '      return;\n'
    '    }\n'
    '    _runSearch(podText(t.$4, t.$5));\n'
    '    setState(() => _topic = t.$2);\n'
    '  }\n'
    '\n'
    '  String _topicLabel() {\n'
    '    for (final t in _topics) {\n'
    '      if (t.$2 == _topic) return podText(t.$2, t.$3);\n'
    '    }\n'
    "    return '';\n"
    '  }\n'
    '\n'
    '  Future<void> _closeIntro() async {\n'
    '    _buzz();\n'
    '    setState(() => _introSeen = true);\n'
    '    try {\n'
    "      (await SharedPreferences.getInstance()).setBool('pod_intro_seen', true);\n"
    '    } catch (_) {}\n'
    '  }\n',
    done='void _pickTopic(int i)')

rep('검색칸 아래에 안내 카드·추천 칩', '            _searchBox(dark),\n',
    '            _searchBox(dark),\n'
    '            if (!_introSeen && _query.isEmpty) _introCard(dark),\n'
    '            const SizedBox(height: 12),\n'
    '            _topicChips(dark),\n',
    done='            _topicChips(dark),\n')

rep('목록 제목 (칩 이름 · 팟캐스트란? 다시 보기)',
    "            _sectionTitle(\n"
    "                _query.isNotEmpty\n"
    "                    ? podText('\\'$_query\\' 검색 결과', 'Results for \"$_query\"')\n"
    "                    : podText('인기 팟캐스트', 'Top podcasts'),\n"
    "                dark),\n",
    "            Row(\n"
    "              children: [\n"
    "                Flexible(\n"
    "                  child: _sectionTitle(\n"
    "                      _topic != null\n"
    "                          ? podText('\\'${_topicLabel()}\\' 팟캐스트', '${_topicLabel()} podcasts')\n"
    "                          : _query.isNotEmpty\n"
    "                              ? podText('\\'$_query\\' 검색 결과', 'Results for \"$_query\"')\n"
    "                              : podText('인기 팟캐스트', 'Top podcasts'),\n"
    "                      dark),\n"
    "                ),\n"
    "                // 안내 카드를 접은 뒤에도 다시 볼 수 있게\n"
    "                if (_introSeen && _query.isEmpty)\n"
    "                  GestureDetector(\n"
    "                    behavior: HitTestBehavior.opaque,\n"
    "                    onTap: () {\n"
    "                      _buzz();\n"
    "                      setState(() => _introSeen = false);\n"
    "                    },\n"
    "                    child: Padding(\n"
    "                      padding: const EdgeInsets.fromLTRB(8, 0, 2, 10),\n"
    "                      child: Text(podText('팟캐스트란?', 'What is a podcast?'),\n"
    "                          style: TextStyle(\n"
    "                              color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),\n"
    "                    ),\n"
    "                  ),\n"
    "              ],\n"
    "            ),\n",
    done="_topic != null\n")

rep('안내 카드·추천 칩 모양', '  Widget _sectionTitle(String t, bool dark) => Padding(\n',
    "  // '팟캐스트란?' 안내 카드 (처음 한 번 · 알겠어요 누르면 접힘)\n"
    '  Widget _introCard(bool dark) => Container(\n'
    '        margin: const EdgeInsets.only(top: 12),\n'
    '        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),\n'
    '        decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(16)),\n'
    '        child: Row(\n'
    '          crossAxisAlignment: CrossAxisAlignment.start,\n'
    '          children: [\n'
    '            Container(\n'
    '              width: 36,\n'
    '              height: 36,\n'
    '              alignment: Alignment.center,\n'
    '              decoration: BoxDecoration(\n'
    '                color: dark ? const Color(0xFF45413B) : const Color(0xFFEDE5D6),\n'
    '                borderRadius: BorderRadius.circular(10),\n'
    '              ),\n'
    "              child: const Text('🎧', style: TextStyle(fontSize: 18)),\n"
    '            ),\n'
    '            const SizedBox(width: 12),\n'
    '            Expanded(\n'
    '              child: Column(\n'
    '                crossAxisAlignment: CrossAxisAlignment.start,\n'
    '                children: [\n'
    "                  Text(podText('팟캐스트란?', 'What is a podcast?'),\n"
    '                      style: TextStyle(color: _text(dark), fontSize: 14.5, fontWeight: FontWeight.w700)),\n'
    '                  const SizedBox(height: 4),\n'
    '                  Text(\n'
    '                      podText(\n'
    "                          '뉴스부터 재미있는 이야기까지, 미리 녹음된 방송을 원하는 시간에 골라 들을 수 있어요. 듣고 싶은 순간, 편하게 즐겨보세요.',\n"
    "                          'From news to fun stories, pick pre-recorded shows and listen whenever you like. Enjoy them at your own pace.'),\n"
    '                      style: TextStyle(color: _sub(dark), fontSize: 12.5, height: 1.55)),\n'
    '                  const SizedBox(height: 10),\n'
    '                  GestureDetector(\n'
    '                    onTap: _closeIntro,\n'
    '                    child: Container(\n'
    '                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),\n'
    '                      decoration: BoxDecoration(\n'
    '                        color: dark ? const Color(0xFFF3EFE7) : _ink,\n'
    '                        borderRadius: BorderRadius.circular(999),\n'
    '                      ),\n'
    "                      child: Text(podText('알겠어요', 'Got it'),\n"
    '                          style: TextStyle(\n'
    '                              color: dark ? const Color(0xFF24221F) : _cream, fontSize: 12.5, fontWeight: FontWeight.w700)),\n'
    '                    ),\n'
    '                  ),\n'
    '                ],\n'
    '              ),\n'
    '            ),\n'
    '          ],\n'
    '        ),\n'
    '      );\n'
    '\n'
    '  // 주제 추천 칩 한 줄 (옆으로 넘기기)\n'
    '  Widget _topicChips(bool dark) => SizedBox(\n'
    '        height: 34,\n'
    '        child: ListView.separated(\n'
    '          scrollDirection: Axis.horizontal,\n'
    '          itemCount: _topics.length,\n'
    '          separatorBuilder: (_, __) => const SizedBox(width: 7),\n'
    '          itemBuilder: (_, i) {\n'
    '            final t = _topics[i];\n'
    '            final on = _topic == t.$2;\n'
    '            return GestureDetector(\n'
    '              onTap: () => _pickTopic(i),\n'
    '              child: Container(\n'
    '                padding: const EdgeInsets.symmetric(horizontal: 12),\n'
    '                alignment: Alignment.center,\n'
    '                decoration: BoxDecoration(\n'
    '                  color: on ? (dark ? const Color(0xFFF3EFE7) : _ink) : _card(dark),\n'
    '                  borderRadius: BorderRadius.circular(999),\n'
    '                  border: Border.all(color: on ? Colors.transparent : _line(dark)),\n'
    '                ),\n'
    "                child: Text('${t.$1} ${podText(t.$2, t.$3)}',\n"
    '                    style: TextStyle(\n'
    '                      color: on ? (dark ? const Color(0xFF24221F) : _cream) : _text(dark).withOpacity(0.8),\n'
    '                      fontSize: 12.5,\n'
    '                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,\n'
    '                    )),\n'
    '              ),\n'
    '            );\n'
    '          },\n'
    '        ),\n'
    '      );\n'
    '\n'
    '  Widget _sectionTitle(String t, bool dark) => Padding(\n',
    done='Widget _topicChips(bool dark)')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
