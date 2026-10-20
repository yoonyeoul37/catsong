# -*- coding: utf-8 -*-
# 아랍어·우르두어(오른쪽→왼쪽)에서 숫자 순서 바로잡기
#  · 재생 화면 남은 시간: '1:16:56-' → '-1:16:56'
#  · 아래 줄 속도: '×1' → '1×'
#  · 미니플레이어 시간: '1:17:00 / 0:08' → '0:08 / 1:17:00' (들은 시간이 앞)
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
        fail(f'{label} — 찾을 코드를 못 찾았어요 ({s.count(old)}곳)')
    s = s.replace(old, new)
    print('✔', label)


rep('재생 화면 남은 시간 (- 가 앞에)',
    "Text(total > 0 ? '-${podClock(dur > shown ? dur - shown : Duration.zero)}' : '', style: TextStyle(color: _sub(dark), fontSize: 12)),",
    "Text(total > 0 ? '-${podClock(dur > shown ? dur - shown : Duration.zero)}' : '',\n"
    "                      textDirection: TextDirection.ltr, // 아랍어에서도 -1:16:56\n"
    "                      style: TextStyle(color: _sub(dark), fontSize: 12)),",
    done='// 아랍어에서도 -1:16:56')
rep('아래 줄 속도 (1×)',
    "top: Text('${_speedText(pod.speed)}×',\n",
    "top: Text('${_speedText(pod.speed)}×',\n"
    "                            textDirection: TextDirection.ltr, // 아랍어에서도 1×\n",
    done='// 아랍어에서도 1×')
rep('미니플레이어 시간 순서 (들은 시간 / 전체)',
    "dur.inSeconds > 0 ? '${s.title} · ${podClock(pos)} / ${podClock(dur)}' : s.title,",
    "dur.inSeconds > 0 ? '${s.title} · \\u2066${podClock(pos)} / ${podClock(dur)}\\u2069' : s.title, // 시간은 늘 왼→오",
    done='// 시간은 늘 왼→오')

if s.count('(') != s.count(')') or s.count('{') != s.count('}') or s.count('[') != s.count(']'):
    fail('괄호가 안 맞아요')
if s == orig:
    print('이미 적용돼 있어요')
    sys.exit(0)
if crlf:
    s = s.replace('\n', '\r\n')
open(PATH, 'wb').write(s.encode('utf-8'))
print('저장했어요:', PATH)
