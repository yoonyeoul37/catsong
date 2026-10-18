# -*- coding: utf-8 -*-
# 홈 '이런 소리는 어때요?' — 끝 물음표만 떼어서 통통 튀게
#  둥근 물음표(퀵샌드 굵게) · 제목보다 살짝 크게 · 포인트 색 따라감 (물음표 없는 언어는 글만)
import os, sys

PATH = os.path.join('lib', 'screens', 'home_screen.dart')

NEW_HEADER = """              // 끝의 물음표만 떼어서 통통 튀게 — 둥근 물음표 · 살짝 크게 · 포인트 색 (물음표 없는 언어는 글만)
              Builder(builder: (_) {
                final h = tr.homeSoundsHeader;
                final q = RegExp(r'\\s*[?？]$').firstMatch(h);
                final st = titleFont( // 로고와 같은 글꼴
                    color: baseColor, fontSize: 16.5, fontWeight: FontWeight.w400);
                if (q == null) return Text(h, style: st);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(h.substring(0, q.start), style: st),
                    const SizedBox(width: 3),
                    _BounceQ(
                      color: pointColorOf(context),
                      style: GoogleFonts.quicksand(
                          color: pointColorOf(context), fontSize: 20, height: 1.0, fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              }),
"""

OLD_HEADER = """              Text(tr.homeSoundsHeader,
                  style: titleFont( // 로고와 같은 글꼴
                      color: baseColor, fontSize: 16.5, fontWeight: FontWeight.w400)),
"""
# 아까 드린 찾기/바꾸기를 이미 넣었을 때의 모양
OLD_HEADER2_START = "              // 끝의 물음표만 떼어서 통통 튀게 (물음표 없는 언어는 글만)\n"
OLD_HEADER2_END = "                    _BounceQ(color: baseColor, style: st),\n                  ],\n                );\n              }),\n"

Q_EDITS = [
    ('물음표: 글자 모양 받기',
     """  final Color color;
  const _BounceQ({required this.color});
""",
     """  final Color color;
  final TextStyle? style; // 주면 이 글자 모양으로 (홈 '이런 소리는 어때요?' 제목)
  const _BounceQ({required this.color, this.style});
"""),
    ('물음표: 받은 글자 모양 쓰기',
     """            child: Text('?',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
""",
     """            child: Text('?',
                textScaler: widget.style != null ? null : TextScaler.noScaling,
                style: widget.style ?? TextStyle(
"""),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); return 1
    raw = open(PATH, 'rb').read(); crlf = b'\r\n' in raw
    t = raw.decode('utf-8').replace('\r\n', '\n')
    if 'color: pointColorOf(context),\n                      style: GoogleFonts.quicksand(' in t:
        print('이미 적용돼 있어요'); return 0
    ok = True
    if t.count(OLD_HEADER) == 1:
        t = t.replace(OLD_HEADER, NEW_HEADER); print('✔ 제목: 물음표 떼어서 통통 튀게')
    else:
        s = t.find(OLD_HEADER2_START); e = t.find(OLD_HEADER2_END)
        if s != -1 and e != -1 and s < e:
            t = t[:s] + NEW_HEADER + t[e + len(OLD_HEADER2_END):]; print('✔ 제목: 아까 넣은 물음표를 둥근 포인트 색으로')
        else:
            print('❌ 제목(이런 소리는 어때요) 자리를 못 찾았어요'); ok = False
    for name, old, new in Q_EDITS:
        if new in t:
            print('✔', name, '(이미 되어 있음)'); continue
        if t.count(old) == 1:
            t = t.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % t.count(old)); ok = False
    for o, c in ['()', '[]', '{}']:
        if t.count(o) != t.count(c):
            print('❌ 괄호 개수가 안 맞아요', o, c); ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.'); return 1
    if crlf: t = t.replace('\n', '\r\n')
    open(PATH, 'wb').write(t.encode('utf-8'))
    print('\n저장했어요:', PATH)
    return 0

if __name__ == '__main__':
    sys.exit(main())
