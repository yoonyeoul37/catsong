# -*- coding: utf-8 -*-
# 팟캐스트 미니플레이어: 회차 이름이 길면 좌우로 흐르게 (라디오 미니플레이어와 같은 방식)
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


rep('import', "import 'package:provider/provider.dart';\n",
    "import 'package:provider/provider.dart';\nimport 'package:marquee/marquee.dart';\n",
    done="import 'package:marquee/marquee.dart';")
rep('미니플레이어 회차 이름 흐르게',
    '                              Text(e.title,\n'
    '                                  maxLines: 1,\n'
    '                                  overflow: TextOverflow.ellipsis,\n'
    '                                  style: const TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),\n',
    '                              // 회차 이름이 길면 좌우로 흐르게\n'
    '                              _PodMarquee(e.title, const TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600)),\n',
    done='_PodMarquee(e.title,')
if 'class _PodMarquee' not in s:
    s = s.rstrip('\n') + '\n' + (
        '\n'
        '/// 글자가 칸보다 길면 좌우로 천천히 흐르게 (짧으면 그냥 글자) — 라디오 미니플레이어와 같은 설정\n'
        'class _PodMarquee extends StatelessWidget {\n'
        '  final String text;\n'
        '  final TextStyle style;\n'
        '  const _PodMarquee(this.text, this.style);\n'
        '\n'
        '  @override\n'
        '  Widget build(BuildContext context) {\n'
        '    return LayoutBuilder(builder: (context, c) {\n'
        '      final tp = TextPainter(\n'
        '        text: TextSpan(text: text, style: style),\n'
        '        maxLines: 1,\n'
        '        textDirection: TextDirection.ltr,\n'
        '        textScaler: MediaQuery.textScalerOf(context),\n'
        '      )..layout();\n'
        '      if (tp.width <= c.maxWidth) {\n'
        '        return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);\n'
        '      }\n'
        '      return SizedBox(\n'
        '        width: c.maxWidth,\n'
        '        height: tp.height,\n'
        '        child: Marquee(\n'
        '          key: ValueKey(text), // 회차가 바뀌면 처음부터\n'
        '          text: text,\n'
        '          style: style,\n'
        '          velocity: 28, // 천천히\n'
        '          blankSpace: 48,\n'
        '          startAfter: const Duration(seconds: 2), // 2초 보여 주고 출발\n'
        '          pauseAfterRound: const Duration(seconds: 2), // 한 바퀴 돌면 2초 쉬기\n'
        '          fadingEdgeStartFraction: 0.06,\n'
        '          fadingEdgeEndFraction: 0.06,\n'
        '          showFadingOnlyWhenScrolling: true,\n'
        '        ),\n'
        '      );\n'
        '    });\n'
        '  }\n'
        '}\n')
    print('✔ 흐르는 글자 모양 넣기')
else:
    print('✔ 흐르는 글자 모양 넣기 (이미 돼 있음)')

if s.count('(') != s.count(')') or s.count('{') != s.count('}'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
