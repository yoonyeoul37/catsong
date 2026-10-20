# -*- coding: utf-8 -*-
# 팟캐스트 목록 흰 박스 빼기 (A안: 바탕 위에 바로 · 줄 사이 아주 연한 선)
#  · 인기 순위 · 검색 결과 · 회차 목록(상세 페이지) · 구독 목록 창
#  · 이어 듣기 카드 · 1위 먹색 카드 · 주제 타일은 그대로
#  · 나타나기: 줄이 바탕 위에서 통째로 떠오름 (높이 14 → 20)
# (apply_podcast_appear.py 를 먼저 돌린 다음에)
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
if 'class _PodAppear' not in s:
    fail('나타나기가 아직 없어요. apply_podcast_appear.py 를 먼저 돌려 주세요')


def rep(label, old, new, done):
    global s
    if done == '\x00never' and old not in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if done in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if s.count(old) != 1:
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    s = s.replace(old, new)
    print('✔', label)


rep('순위·검색·회차 목록: 흰 박스 빼기',
    "/// 흰 카드 한 조각 (첫 줄은 위 모서리, 마지막 줄은 아래 모서리만 둥글게 → 붙이면 카드 하나)\n"
    'Widget _podPiece(bool dark, {required bool first, required bool last, required Widget child}) => Container(\n'
    '      padding: const EdgeInsets.symmetric(horizontal: 14),\n'
    '      decoration: BoxDecoration(\n'
    '        color: _card(dark),\n'
    '        borderRadius: BorderRadius.vertical(\n'
    '          top: Radius.circular(first ? 10 : 0),\n'
    '          bottom: Radius.circular(last ? 10 : 0),\n'
    '        ),\n'
    '      ),\n'
    '      child: child,\n'
    '    );\n',
    '/// 목록 한 줄 (박스 없이 바탕 위에 바로 · 줄 사이는 연한 선만 — 애플 팟캐스트처럼)\n'
    'Widget _podPiece(bool dark, {required bool first, required bool last, required Widget child}) => child;\n',
    done='Widget _podPiece(bool dark, {required bool first, required bool last, required Widget child}) => child;')

rep('나타나기 높이 14 → 20',
    'child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),',
    'child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),',
    done='Offset(0, 20 * (1 - t))')

rep('구독 창: 흰 박스 빼기',
    '                        Container(\n'
    '                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10)),\n'
    '                          clipBehavior: Clip.antiAlias,\n'
    '                          child: Column(\n',
    '                        Container(\n'
    '                          // 박스 없이 바탕 위에 바로 (팟캐스트 목록과 같게)\n'
    '                          child: Column(\n',
    done='// 박스 없이 바탕 위에 바로 (팟캐스트 목록과 같게)')
rep('구독 창: 줄 사이 선 자리',
    'if (i > 0) Container(height: 0.5, margin: const EdgeInsets.only(left: 68), color: line),',
    'if (i > 0) Container(height: 0.5, margin: const EdgeInsets.only(left: 60), color: line),',
    done='margin: const EdgeInsets.only(left: 60), color: line),')
rep('구독 창: 줄 왼쪽을 제목과 맞추기',
    '                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),\n',
    '                                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 10), // 위 제목 줄과 같은 왼쪽\n',
    done='padding: const EdgeInsets.fromLTRB(4, 10, 4, 10), // 위 제목 줄과 같은 왼쪽')
rep('구독 창: 새 회차 빨간 점 테두리 = 바탕색',
    '                                                    border: Border.all(color: card, width: 2),\n',
    '                                                    border: Border.all(color: bg, width: 2),\n',
    done='                                                    border: Border.all(color: bg, width: 2),\n')

rep('구독 창: 안 쓰게 된 흰색 값 빼기',
    "    final card = dark ? const Color(0xFF3E3B37) : Colors.white;\n    final ink = dark",
    "    final ink = dark",
    done='\x00never')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
