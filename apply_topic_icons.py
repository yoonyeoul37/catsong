# -*- coding: utf-8 -*-
# 팟캐스트 '주제로 찾기' 카드: 오른쪽 아래에 연한 아이콘 (C안, 너무 크지 않게)
import os, re, sys
sys.stdout.reconfigure(encoding='utf-8')

p = None
for root, dirs, files in os.walk('lib'):
    if 'podcast_screens.dart' in files:
        p = os.path.join(root, 'podcast_screens.dart')
if not p:
    print('❌ podcast_screens.dart 못 찾음 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
raw = open(p, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if '_topicIcons' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

ok = True
def rep(label, old, new):
    global s, ok
    n = s.count(old)
    if n != 1:
        print('❌', label, '(찾은 개수 %d)' % n); ok = False; return
    s = s.replace(old, new)
    print('✔', label)

rep('주제별 아이콘 목록 추가',
    "    ('잠들기 전', 'Sleep', '조용한 이야기', 'Calm stories', '수면', 'sleep', Color(0xFFDCDBE6), Color(0xFF302F3A)),\n  ];\n",
    "    ('잠들기 전', 'Sleep', '조용한 이야기', 'Calm stories', '수면', 'sleep', Color(0xFFDCDBE6), Color(0xFF302F3A)),\n  ];\n"
    "  // 주제 카드 오른쪽 아래 연한 아이콘 (위 주제 순서와 같게)\n"
    "  static const _topicIcons = [\n"
    "    Icons.radio_rounded,\n"
    "    Icons.newspaper_rounded,\n"
    "    Icons.menu_book_rounded,\n"
    "    Icons.translate_rounded,\n"
    "    Icons.sentiment_satisfied_alt_rounded,\n"
    "    Icons.bedtime_rounded,\n"
    "  ];\n")

rep('카드에 연한 아이콘 깔기',
"""              child: Container(
                width: w,
                height: 66,
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: dark ? _topics[i].$8 : _topics[i].$7,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(podText(_topics[i].$1, _topics[i].$2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _text(dark), fontSize: 13.5, fontWeight: FontWeight.w600)),
                    Text(podText(_topics[i].$3, _topics[i].$4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _sub(dark), fontSize: 11)),
                  ],
                ),
              ),""",
"""              child: Container(
                width: w,
                height: 66,
                clipBehavior: Clip.antiAlias, // 살짝 걸친 아이콘은 카드 안에서만
                decoration: BoxDecoration(
                  color: dark ? _topics[i].$8 : _topics[i].$7,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    // 오른쪽 아래 연한 아이콘 (글자 뒤에 은은하게 · 아랍어는 왼쪽 아래)
                    PositionedDirectional(
                      end: 4,
                      bottom: -4,
                      child: Icon(_topicIcons[i % _topicIcons.length],
                          size: 38, color: _text(dark).withOpacity(dark ? 0.12 : 0.09)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(podText(_topics[i].$1, _topics[i].$2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _text(dark), fontSize: 13.5, fontWeight: FontWeight.w600)),
                          Text(podText(_topics[i].$3, _topics[i].$4),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _sub(dark), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),""")

t = re.sub(r"'''.*?'''", "''", s, flags=re.S)
t = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", t)
t = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', t)
t = re.sub(r'//[^\n]*', '', t)
for a, b in ('()', '[]', '{}'):
    if t.count(a) != t.count(b):
        print('❌ 괄호 안 맞음', a, t.count(a), t.count(b)); ok = False
if not ok:
    print('❌ 아무것도 저장 안 했어요'); sys.exit(1)
if crlf: s = s.replace('\n', '\r\n')
open(p, 'wb').write(s.encode('utf-8'))
print('✔ 저장: podcast_screens.dart')
