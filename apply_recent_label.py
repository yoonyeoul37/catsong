# -*- coding: utf-8 -*-
# 홈 '최근에 들었어요' 카드: 그림 위 검은 동그라미 아이콘 빼고 → 제목 위에 작은 아이콘 + 종류 글자 (A안)
# 음악 · 라디오 · 팟캐스트 · 자연소리 · 휴식 (팟캐스트 글자는 번역할 때 23개 언어로)
import os, sys

PATH = os.path.join('lib', 'screens', 'home_screen.dart')


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


rep('그림 위 검은 동그라미 아이콘 빼기',
    '                                  Positioned(\n'
    '                                    left: 4,\n'
    '                                    top: 4,\n'
    '                                    child: Container(\n'
    '                                      padding: const EdgeInsets.all(3),\n'
    '                                      decoration: BoxDecoration(\n'
    '                                        color: Colors.black.withOpacity(0.4),\n'
    '                                        shape: BoxShape.circle,\n'
    '                                      ),\n'
    '                                      child: Icon(typeIcon, size: 10, color: Colors.white),\n'
    '                                    ),\n'
    '                                  ),\n',
    '', done='// 종류: 작은 아이콘 + 글자')
rep('제목 위에 종류 글자',
    '                            const SizedBox(height: 6),\n'
    '                            Text(item.type == RecentContentType.nature ? natureName(item.title) : item.title,\n',
    '                            const SizedBox(height: 6),\n'
    '                            // 종류: 작은 아이콘 + 글자 (음악 · 라디오 · 팟캐스트 · 자연소리 · 휴식)\n'
    '                            Row(\n'
    '                              children: [\n'
    '                                Icon(typeIcon, size: 10, color: baseColor.withOpacity(0.42)),\n'
    '                                const SizedBox(width: 3),\n'
    '                                Flexible(\n'
    '                                  child: Text(_recentTypeName(item.type),\n'
    '                                      maxLines: 1,\n'
    '                                      overflow: TextOverflow.ellipsis,\n'
    '                                      style: TextStyle(\n'
    '                                          color: baseColor.withOpacity(0.42), fontSize: 9.5, fontWeight: FontWeight.w700)),\n'
    '                                ),\n'
    '                              ],\n'
    '                            ),\n'
    '                            const SizedBox(height: 1),\n'
    '                            Text(item.type == RecentContentType.nature ? natureName(item.title) : item.title,\n',
    done='// 종류: 작은 아이콘 + 글자')
rep('카드 줄 높이 (글자 한 줄 늘어난 만큼)',
    '                return SizedBox(\n                height: 142,\n',
    '                return SizedBox(\n                height: 156, // 종류 글자 한 줄 더 (예전 142)\n',
    done='height: 156, // 종류 글자 한 줄 더')
if 'String _recentTypeName(' not in s:
    s = s.rstrip('\n') + '\n' + (
        '\n'
        "/// '최근에 들었어요' 카드 종류 이름 (팟캐스트는 번역할 때 23개 언어로)\n"
        'String _recentTypeName(RecentContentType t) => switch (t) {\n'
        '      RecentContentType.music => tr.catMusic,\n'
        '      RecentContentType.radio => tr.catRadio,\n'
        '      RecentContentType.nature => tr.catNature,\n'
        '      RecentContentType.sleep => tr.catRest,\n'
        "      RecentContentType.podcast => podText('팟캐스트', 'Podcast'),\n"
        '    };\n')
    print('✔ 종류 이름 함수')
else:
    print('✔ 종류 이름 함수 (이미 돼 있음)')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
