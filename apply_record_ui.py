# -*- coding: utf-8 -*-
# 2단계 화면: 재생 기록을 화면에 쓰기
# - 홈 오늘의 카드 2개 추가: "한 달 동안 안 들은 곡" [틀기] · "최근 7일 동안 N번 들었어요" [듣기]
#   (순서: 오늘의 한 곡 → 안 들은 곡 → 7일 기록 → 시간대 추천 → 기능 알려주기, 기록이 없으면 시간대 추천으로)
# - "최근에 들었어요"가 비어 있을 때 안내: 30초 이상 들은 것만 모인다고
# - 곡 목록의 재생 횟수(▶ 숫자)를 누르면 "30초 이상 들은 횟수예요"
# (apply_play_record.py 를 먼저 실행한 뒤에 실행)
import os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
HOME = os.path.join(ROOT, 'lib', 'screens', 'home_screen.dart')
TILE = os.path.join(ROOT, 'lib', 'widgets', 'song_list_tile.dart')
MUSIC = os.path.join(ROOT, 'lib', 'providers', 'music_provider.dart')

HOME_EDITS = [
    ('홈 카드: 5가지로 늘리기',
     "    var kind = day % 3; // 날짜 따라 순서대로 (같은 날은 같은 카드)\n"
     "    if (kind == 0 && songs.isEmpty) kind = 1;\n",
     "    var kind = day % 5; // 날짜 따라 순서대로 (같은 날은 같은 카드)\n"
     "    final notPlayed = kind == 1 ? music.songsNotPlayedFor(const Duration(days: 30)) : const <Song>[];\n"
     "    final weekCount = kind == 2 ? music.weekPlayCount : 0;\n"
     "    final weekTop = kind == 2 ? music.weekTopSong : null;\n"
     "    // 보여줄 게 없으면 시간대 추천으로\n"
     "    if (kind == 0 && songs.isEmpty) kind = 3;\n"
     "    if (kind == 1 && notPlayed.length < 3) kind = 3;\n"
     "    if (kind == 2 && (weekCount == 0 || weekTop == null)) kind = 3;\n"),
    ('홈 카드: 안 들은 곡 · 7일 기록 추가',
     "    } else if (kind == 1) {\n"
     "      // ② 시간대 추천 (자연소리)\n",
     "    } else if (kind == 1) {\n"
     "      // ② 한 달 동안 안 들은 곡 (섞어서 틀기)\n"
     "      icon = Icons.history_rounded;\n"
     "      title = '한 달 동안 안 들은 곡 ${notPlayed.length}개';\n"
     "      subLine = Text('오랜만에 다시 들어볼까요',\n"
     "          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11.5));\n"
     "      action = '틀기';\n"
     "      onAction = () {\n"
     "        final list = List<Song>.from(notPlayed)..shuffle();\n"
     "        context.read<PlayerProvider>().playFromList(list, 0);\n"
     "      };\n"
     "    } else if (kind == 2) {\n"
     "      // ③ 최근 7일 듣기 기록 + 가장 많이 들은 곡\n"
     "      final top = weekTop!;\n"
     "      icon = Icons.bar_chart_rounded;\n"
     "      title = '최근 7일 동안 $weekCount번 들었어요';\n"
     "      subLine = Text.rich(\n"
     "        TextSpan(children: [\n"
     "          const TextSpan(text: '가장 많이 들은 곡  '),\n"
     "          TextSpan(text: top.titleDisplay, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),\n"
     "        ]),\n"
     "        maxLines: 1,\n"
     "        overflow: TextOverflow.ellipsis,\n"
     "        style: TextStyle(color: sub, fontSize: 11.5),\n"
     "      );\n"
     "      action = '듣기';\n"
     "      onAction = () {\n"
     "        final i = songs.indexWhere((s) => s.uri == top.uri);\n"
     "        context.read<PlayerProvider>().playFromList(i >= 0 ? songs : [top], i >= 0 ? i : 0);\n"
     "      };\n"
     "    } else if (kind == 3) {\n"
     "      // ④ 시간대 추천 (자연소리)\n"),
    ('홈 카드: 팁은 5일마다 다음 것',
     "      final tip = tips[(day ~/ 3) % tips.length];\n",
     "      final tip = tips[(day ~/ 5) % tips.length];\n"),
    ('최근에 들었어요: 빈 화면 안내',
     "                    Text('음악을 재생하면 여기에 표시됩니다',\n",
     "                    Text('30초 이상 들은 곡·라디오·자연이 여기에 모여요',\n"),
]

TILE_OLD = (
    "                  if (playCount > 0) ...[\n"
    "                    const SizedBox(height: 2),\n"
    "                    Row(\n"
    "                      mainAxisSize: MainAxisSize.min,\n"
    "                      children: [\n"
    "                        Icon(Icons.play_arrow_rounded, size: 11, color: subColor),\n"
    "                        const SizedBox(width: 1),\n"
    "                        Text(\n"
    "                          '$playCount',\n"
    "                          style: TextStyle(color: subColor, fontSize: 10.5),\n"
    "                        ),\n"
    "                      ],\n"
    "                    ),\n"
    "                  ],\n")
TILE_NEW = (
    "                  if (playCount > 0) ...[\n"
    "                    const SizedBox(height: 2),\n"
    "                    // 누르면 세는 기준 알려주기\n"
    "                    GestureDetector(\n"
    "                      behavior: HitTestBehavior.opaque,\n"
    "                      onTap: () => showParanToast(context, '30초 이상 들은 횟수예요'),\n"
    "                      child: Row(\n"
    "                        mainAxisSize: MainAxisSize.min,\n"
    "                        children: [\n"
    "                          Icon(Icons.play_arrow_rounded, size: 11, color: subColor),\n"
    "                          const SizedBox(width: 1),\n"
    "                          Text(\n"
    "                            '$playCount',\n"
    "                            style: TextStyle(color: subColor, fontSize: 10.5),\n"
    "                          ),\n"
    "                        ],\n"
    "                      ),\n"
    "                    ),\n"
    "                  ],\n")
TILE_EDITS = [('곡 목록: 재생 횟수 누르면 기준 안내', TILE_OLD, TILE_NEW)]

MARK = 'songsNotPlayedFor(const Duration(days: 30))'


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    for p in (HOME, TILE, MUSIC):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    if 'songsNotPlayedFor' not in open(MUSIC, 'rb').read().decode('utf-8'):
        print('❌ apply_play_record.py 를 먼저 실행해 주세요')
        sys.exit(1)
    if MARK in open(HOME, 'rb').read().decode('utf-8'):
        print('이미 적용돼 있어요')
        return
    out = []
    ok = True
    for path, edits in ((HOME, HOME_EDITS), (TILE, TILE_EDITS)):
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    print('\n다 바꿨어요. flutter run 으로 확인해 보세요.')


if __name__ == '__main__':
    main()
