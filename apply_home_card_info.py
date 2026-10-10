# -*- coding: utf-8 -*-
# 설정 → 홈 추천 카드 옆에 ⓘ (누르면 어떤 카드가 나오는지 말풍선, 포인트 색과 같은 모양)
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
PATH = 'lib/screens/settings_screen.dart'
MARK = '_homeInfoItems'

EDITS = [
('홈 카드 설명 목록',
"""  final GlobalKey _pointInfoKey = GlobalKey();
""",
"""  final GlobalKey _pointInfoKey = GlobalKey();
  final GlobalKey _homeInfoKey = GlobalKey();
  static const List<(String, String)> _homeInfoItems = [
    ('오늘의 한 곡', '내 음악 중에서 날마다 한 곡을 골라 줘요'),
    ('오랜만에 듣기', '한 달 동안 안 들은 곡을 섞어서 틀어요'),
    ('이번 주 기록', '7일 동안 들은 횟수와 가장 많이 들은 곡'),
    ('시간대 추천', '아침·낮·저녁·밤에 어울리는 자연소리'),
    ('알아두면 좋은 기능', '벨소리 만들기, 빗소리 섞기 같은 팁'),
    ('내일 알람', '알람을 켜 두면 저녁 7시부터 내일 깨울 시간'),
  ];
"""),
('줄 이름 옆에 붙일 칸 받기',
"""    Widget? trailing, bool isFirst = false, bool isLast = false,
  }) {""",
"""    Widget? trailing, bool isFirst = false, bool isLast = false,
    Widget? titleExtra, // 이름 바로 옆 (예: ⓘ)
  }) {"""),
('줄 이름 옆에 그리기',
"""                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _sText(isDarkMode), fontSize: 14.5)),
                        if (desc != null) ...[""",
"""                        Row(
                          children: [
                            Flexible(
                              child: Text(title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: _sText(isDarkMode), fontSize: 14.5)),
                            ),
                            if (titleExtra != null) titleExtra,
                          ],
                        ),
                        if (desc != null) ...["""),
('홈 추천 카드에 ⓘ',
"""                title: '홈 추천 카드',
                desc: '홈 맨 위에 날마다 바뀌는 카드',""",
"""                title: '홈 추천 카드',
                // ⓘ 누르면 어떤 카드가 나오는지 (포인트 색과 같은 말풍선)
                titleExtra: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showBubble(_homeInfoKey, context.read<ThemeProvider>().isDarkMode,
                      title: '홈 추천 카드에 나오는 것',
                      items: _homeInfoItems,
                      foot: '날마다 바뀌고, 정리할 곡이 있으면 정리 카드가 먼저 나와요'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
                    child: Icon(Icons.info_outline_rounded,
                        key: _homeInfoKey, size: 16, color: _sTextHint(context.read<ThemeProvider>().isDarkMode)),
                  ),
                ),
                desc: '홈 맨 위에 날마다 바뀌는 카드',"""),
]

def main():
    try:
        raw = open(PATH, 'rb').read().decode('utf-8')
    except FileNotFoundError:
        print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    if MARK in s:
        print('이미 적용돼 있어요'); return
    ok = True
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print(f'❌ {name} — 자리를 못 찾았어요 ({n}곳)'); ok = False; continue
        s = s.replace(old, new); print(f'✔ {name}')
    for o, c in ('{}', '()', '[]'):
        if (s.count(o) - s.count(c)) != (raw.count(o) - raw.count(c)):
            print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('저장했어요 ✔')

main()
