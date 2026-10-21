# -*- coding: utf-8 -*-
# 팟캐스트: 주제·검색 결과를 보다가 휴대폰 뒤로가기 → 홈이 아니라 인기 순위로 (국내·해외 같은 화면)
import os, sys

PATH = os.path.join('lib', 'podcast', 'podcast_screens.dart')

EDITS = [
    (
        '뒤로가기 잡기 시작',
        "    return FutureBuilder<List<PodcastShow>>(\n      future: _results ?? _chart,\n",
        "    // 주제·검색 결과를 보는 중이면 뒤로가기 → 인기 순위로 (화면을 나가지 않게)\n"
        "    return PopScope(\n"
        "      canPop: !searching && !_searchOpen,\n"
        "      onPopInvokedWithResult: (didPop, _) {\n"
        "        if (!didPop) _backToChart();\n"
        "      },\n"
        "      child: FutureBuilder<List<PodcastShow>>(\n"
        "      future: _results ?? _chart,\n",
    ),
    (
        '뒤로가기 잡기 끝',
        "        );\n      },\n    );\n  }\n\n  // '구독 중':",
        "        );\n      },\n    ),\n    );\n  }\n\n  // '구독 중':",
    ),
]


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        sys.exit(1)
    with open(PATH, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')
    if 'canPop: !searching && !_searchOpen' in text:
        print('이미 적용돼 있어요')
        return
    for name, old, new in EDITS:
        n = text.count(old)
        if n != 1:
            print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        text = text.replace(old, new)
        print('✔', name)
    if crlf:
        text = text.replace('\n', '\r\n')
    with open(PATH, 'wb') as f:
        f.write(text.encode('utf-8'))
    print('✔ 저장했어요:', PATH)


main()
