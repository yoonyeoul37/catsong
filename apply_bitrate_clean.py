# -*- coding: utf-8 -*-
# 곡 정리: 제목 뒤 "192k", "320k", "(320kbps)" 같은 음질 숫자도 지우기
import os, sys

PATH = os.path.join('lib', 'utils', 'song_title_cleaner.dart')

EDITS = [
    (
        '괄호 안 음질 숫자 (320kbps) 지우기',
        r"hd|hq|4k|\d{3,4}p|",
        r"hd|hq|4k|\d{3,4}p|\d{2,3}\s*k(?:bps)?|",
    ),
    (
        '음질 숫자 찾는 규칙 추가',
        "  static bool _looksUnknown(String a) {",
        "  // 음질 표시: 192k, 320k, 128kbps\n"
        "  static final _bitrate = RegExp(r'^\\d{2,3}\\s*k(bps)?$', caseSensitive: false);\n"
        "\n"
        "  static bool _looksUnknown(String a) {",
    ),
    (
        '"제목 - 192k"처럼 따로 떨어진 음질 칸 빼기',
        "        if (partRe.hasMatch(s)) continue; // Part. 09, CD 2 → 빼기",
        "        if (partRe.hasMatch(s) || _bitrate.hasMatch(s)) continue; // Part. 09, CD 2, 192k → 빼기",
    ),
    (
        '제목 맨 뒤에 붙은 음질 숫자 지우기',
        "    // 맨 앞 트랙 번호 \"01. 노래\", \"03 - 노래\" 떼기",
        "    // 맨 뒤 음질 숫자 \"노래 320k\", \"노래 - 192kbps\" 떼기\n"
        "    t = t.replaceAll(RegExp(r'[\\s\\-–—_]+\\d{2,3}\\s*k(bps)?\\s*$', caseSensitive: false), '');\n"
        "\n"
        "    // 맨 앞 트랙 번호 \"01. 노래\", \"03 - 노래\" 떼기",
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

    if '_bitrate' in text:
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
