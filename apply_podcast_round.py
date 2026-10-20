# -*- coding: utf-8 -*-
# 팟캐스트 화면: 박스 모서리 전부 10으로 + '인기 팟캐스트' 제목 작게 (19 → 15, '주제로 찾기'·'구독 중'과 같게)
# (그림 모서리 · 가는 진행 막대 · 알약 버튼은 그대로)
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


def rep(label, old, new, count=1):
    global s
    n = s.count(old)
    if n == 0 and new in s:
        print('✔', label, '(이미 돼 있음)')
        return
    if n != count:
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({n}곳)')
    s = s.replace(old, new)
    print('✔', label)


rep("'팟캐스트란?' 설명 상자 12 → 10",
    'decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(12)),',
    'decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(10)),')
rep('검색칸 14 → 10',
    '      height: 44,\n      decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(14)),',
    '      height: 44,\n      decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(10)),')
rep('이어 듣기 카드 16 → 10',
    '      color: _card(dark),\n      borderRadius: BorderRadius.circular(16),\n      child: InkWell(\n        borderRadius: BorderRadius.circular(16),',
    '      color: _card(dark),\n      borderRadius: BorderRadius.circular(10),\n      child: InkWell(\n        borderRadius: BorderRadius.circular(10),')
rep('1위 먹색 카드 18 → 10',
    '      color: bg,\n      borderRadius: BorderRadius.circular(18),\n      child: InkWell(\n        borderRadius: BorderRadius.circular(18),',
    '      color: bg,\n      borderRadius: BorderRadius.circular(10),\n      child: InkWell(\n        borderRadius: BorderRadius.circular(10),')
rep('순위·검색 목록 카드 · 회차 목록 카드 16 → 10 (2곳)',
    'decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(16)),',
    'decoration: BoxDecoration(color: _card(dark), borderRadius: BorderRadius.circular(10)),', count=2)
rep('주제 타일 14 → 10',
    '                  color: dark ? _topics[i].$8 : _topics[i].$7,\n                  borderRadius: BorderRadius.circular(14),',
    '                  color: dark ? _topics[i].$8 : _topics[i].$7,\n                  borderRadius: BorderRadius.circular(10),')
rep("'최신 회차 듣기' 버튼 14 → 10",
    '                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),',
    '                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),')
rep("'인기 팟캐스트' 제목 19 → 15",
    'style: TextStyle(color: _text(dark), fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3),',
    'style: TextStyle(color: _text(dark), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
