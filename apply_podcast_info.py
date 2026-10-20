# -*- coding: utf-8 -*-
# 팟캐스트 탭: 안내 카드('알겠어요') 빼고 → 목록 제목 옆 '팟캐스트란? ⓘ' (누르면 짧은 설명 펼침)
# + 추천 칩 이모지 빼고 가는 선 아이콘으로
# (apply_podcast_intro.py 를 돌린 다음에 돌리기)
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
    if done == '\x00never' and old not in s:  # 지우는 것: 이미 없으면 끝
        print('✔', label, '(이미 돼 있음)')
        return
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(label + ' — 찾을 코드를 못 찾았어요')
    s = s.replace(old, new)
    print('✔', label)


DESC_KO = "'뉴스부터 재미있는 이야기까지, 미리 녹음된 방송을 원하는 시간에 골라 들을 수 있어요. 듣고 싶은 순간, 편하게 즐겨보세요.'"
DESC_EN = "'From news to fun stories, pick pre-recorded shows and listen whenever you like. Enjoy them at your own pace.'"

rep('안 쓰는 import 빼기', "import 'package:shared_preferences/shared_preferences.dart';\n", '',
    done='\x00never')

rep('추천 칩: 이모지 → 아이콘',
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
    "  bool _infoOpen = false; // '팟캐스트란? ⓘ' 설명 펼침\n"
    '  String? _topic; // 고른 추천 칩\n'
    '\n'
    '  // 추천 칩: (아이콘, 한국어, 영어, 한국어 검색어, 영어 검색어)\n'
    '  static const _topics = [\n'
    "    (Icons.radio_rounded, '라디오 다시듣기', 'Radio shows', '라디오', 'radio'),\n"
    "    (Icons.article_outlined, '뉴스', 'News', '뉴스', 'news'),\n"
    "    (Icons.menu_book_rounded, '책 읽어주기', 'Books', '오디오북', 'audiobook'),\n"
    "    (Icons.translate_rounded, '영어 공부', 'Learn English', '영어', 'learn english'),\n"
    "    (Icons.sentiment_satisfied_rounded, '웃음', 'Comedy', '코미디', 'comedy'),\n"
    "    (Icons.bedtime_outlined, '잠들기 전', 'Sleep', '수면', 'sleep'),\n"
    "    (Icons.trending_up_rounded, '경제', 'Business', '경제', 'business'),\n"
    '  ];\n',
    done='bool _infoOpen = false;')

rep('안내 카드 기억 빼기',
    '    super.initState();\n    _loadChart();\n'
    '    SharedPreferences.getInstance().then((p) {\n'
    "      if (mounted && !(p.getBool('pod_intro_seen') ?? false)) setState(() => _introSeen = false);\n"
    '    });\n'
    '  }\n',
    '    super.initState();\n    _loadChart();\n  }\n',
    done='\x00never')

rep('알겠어요 함수 빼기',
    '\n  Future<void> _closeIntro() async {\n'
    '    _buzz();\n'
    '    setState(() => _introSeen = true);\n'
    '    try {\n'
    "      (await SharedPreferences.getInstance()).setBool('pod_intro_seen', true);\n"
    '    } catch (_) {}\n'
    '  }\n',
    '', done='\x00never')

rep('안내 카드 빼기', '            if (!_introSeen && _query.isEmpty) _introCard(dark),\n', '', done='\x00never')

rep("제목 옆 '팟캐스트란? ⓘ' + 누르면 짧은 설명",
    '                // 안내 카드를 접은 뒤에도 다시 볼 수 있게\n'
    '                if (_introSeen && _query.isEmpty)\n'
    '                  GestureDetector(\n'
    '                    behavior: HitTestBehavior.opaque,\n'
    '                    onTap: () {\n'
    '                      _buzz();\n'
    '                      setState(() => _introSeen = false);\n'
    '                    },\n'
    '                    child: Padding(\n'
    '                      padding: const EdgeInsets.fromLTRB(8, 0, 2, 10),\n'
    "                      child: Text(podText('팟캐스트란?', 'What is a podcast?'),\n"
    '                          style: TextStyle(\n'
    '                              color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),\n'
    '                    ),\n'
    '                  ),\n'
    '              ],\n'
    '            ),\n',
    "                // '팟캐스트란? ⓘ' — 누르면 아래에 짧은 설명\n"
    '                if (_query.isEmpty)\n'
    '                  GestureDetector(\n'
    '                    behavior: HitTestBehavior.opaque,\n'
    '                    onTap: () {\n'
    '                      _buzz();\n'
    '                      setState(() => _infoOpen = !_infoOpen);\n'
    '                    },\n'
    '                    child: Padding(\n'
    '                      padding: const EdgeInsets.fromLTRB(8, 0, 2, 10),\n'
    '                      child: Row(\n'
    '                        mainAxisSize: MainAxisSize.min,\n'
    '                        children: [\n'
    "                          Text(podText('팟캐스트란?', 'What is a podcast?'),\n"
    '                              style: TextStyle(color: _sub(dark), fontSize: 12, fontWeight: FontWeight.w600)),\n'
    '                          const SizedBox(width: 4),\n'
    '                          Icon(_infoOpen ? Icons.info_rounded : Icons.info_outline_rounded, size: 15, color: _sub(dark)),\n'
    '                        ],\n'
    '                      ),\n'
    '                    ),\n'
    '                  ),\n'
    '              ],\n'
    '            ),\n'
    '            AnimatedSize(\n'
    '              duration: const Duration(milliseconds: 200),\n'
    '              curve: Curves.easeOut,\n'
    '              alignment: Alignment.topCenter,\n'
    '              child: _infoOpen && _query.isEmpty\n'
    '                  ? Container(\n'
    '                      width: double.infinity,\n'
    '                      margin: const EdgeInsets.only(bottom: 10),\n'
    '                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),\n'
    '                      decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(12)),\n'
    f'                      child: Text(podText({DESC_KO}, {DESC_EN}),\n'
    '                          style: TextStyle(color: _sub(dark), fontSize: 12.5, height: 1.55)),\n'
    '                    )\n'
    '                  : const SizedBox(width: double.infinity),\n'
    '            ),\n',
    done='setState(() => _infoOpen = !_infoOpen);')

# 안내 카드 모양 함수 통째로 빼기
a = s.find("  // '팟캐스트란?' 안내 카드 (처음 한 번 · 알겠어요 누르면 접힘)\n")
if a >= 0:
    b = s.find('  // 주제 추천 칩 한 줄 (옆으로 넘기기)\n', a)
    if b < 0:
        fail('안내 카드 모양 끝을 못 찾았어요')
    s = s[:a] + s[b:]
    print('✔ 안내 카드 모양 빼기')
else:
    print('✔ 안내 카드 모양 빼기 (이미 돼 있음)')

rep('추천 칩: 아이콘 + 글자',
    "                child: Text('${t.$1} ${podText(t.$2, t.$3)}',\n"
    '                    style: TextStyle(\n'
    '                      color: on ? (dark ? const Color(0xFF24221F) : _cream) : _text(dark).withOpacity(0.8),\n'
    '                      fontSize: 12.5,\n'
    '                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,\n'
    '                    )),\n',
    '                child: Row(\n'
    '                  mainAxisSize: MainAxisSize.min,\n'
    '                  children: [\n'
    '                    Icon(t.$1, size: 15, color: on ? (dark ? const Color(0xFF24221F) : _cream) : _sub(dark)),\n'
    '                    const SizedBox(width: 5),\n'
    '                    Text(podText(t.$2, t.$3),\n'
    '                        style: TextStyle(\n'
    '                          color: on ? (dark ? const Color(0xFF24221F) : _cream) : _text(dark).withOpacity(0.8),\n'
    '                          fontSize: 12.5,\n'
    '                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,\n'
    '                        )),\n'
    '                  ],\n'
    '                ),\n',
    done='Icon(t.$1, size: 15')

for bad in ('_introSeen', '_introCard', '_closeIntro', 'pod_intro_seen'):
    if bad in s:
        fail(f'예전 안내 카드 코드({bad})가 남아 있어요')
if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
