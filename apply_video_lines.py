# -*- coding: utf-8 -*-
# 동영상 목록 글자 줄 맞추기: 첫 줄 NEW + 날짜(요일) / 둘째 줄 시간·지역 (이름 바꾼 영상은 이름·지역)
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
if not os.path.exists(PATH):
    for root, _, files in os.walk('lib'):
        if 'video_screen.dart' in files:
            PATH = os.path.join(root, 'video_screen.dart'); break

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '// 첫 줄: 날짜(요일) / 둘째 줄' in src:
    print('이미 적용돼 있어요'); sys.exit(0)
if '// B안: 사진 위엔 재생 시간만' not in src:
    print('❌ apply_video_tiles.py 를 먼저 돌려 주세요'); sys.exit(1)

START = "                final cd = _cameraDate(widget.video.title);\n                if (cd == null) {"
END = "              }),\n            ),\n          ],\n        );\n      }),"

NEW = r"""                // 첫 줄: 날짜(요일) / 둘째 줄: 시간 · 지역 (이름 바꾼 영상은 이름 · 지역)
                final cd = _cameraDate(widget.video.title);
                String? first, time;
                if (cd != null) {
                  first = widget.dateMode == 'time' ? cd.time : (widget.dateMode == 'day' ? cd.day : cd.date);
                  time = cd.time;
                } else {
                  final ms = context.read<VideoProvider>().dateOf(widget.video.uri);
                  if (ms > 0) {
                    final d = DateTime.fromMillisecondsSinceEpoch(ms);
                    const week = ['월', '화', '수', '목', '금', '토', '일'];
                    final wd = week[d.weekday - 1];
                    final ampm = d.hour < 12 ? '오전' : '오후';
                    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
                    time = '$ampm $h12:${d.minute.toString().padLeft(2, '0')}';
                    // 위 묶음 제목과 겹치는 건 빼기 (올해면 연도 빼고)
                    first = widget.dateMode == 'time'
                        ? time
                        : widget.dateMode == 'day'
                            ? '${d.day}일 ($wd)'
                            : d.year == DateTime.now().year
                                ? '${d.month}월 ${d.day}일 ($wd)'
                                : '${d.year}.${d.month}.${d.day} ($wd)';
                  }
                }
                final hasName = cd == null; // 이름 바꾼 영상·다운받은 영상
                final firstStyle =
                    TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3);
                final subStyle = TextStyle(
                    color: baseColor.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.3);
                // 둘째 줄 뒤쪽: 이름 있는 영상은 지역(없으면 시간), 카메라 영상은 시간 · 지역
                final String? tail = hasName
                    ? (shortPlace ?? (widget.dateMode == 'time' ? null : time))
                    : (widget.dateMode == 'time' ? shortPlace : withPlace(time ?? ''));
                if (first == null) {
                  // 날짜를 모르면 이름만 (두 줄까지)
                  return title(widget.video.titleDisplay, firstStyle, maxLines: 2);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title(first, firstStyle),
                    if (hasName || tail != null)
                      Text.rich(
                        TextSpan(children: [
                          if (hasName)
                            TextSpan(
                              text: widget.video.titleDisplay,
                              style: TextStyle(color: baseColor.withOpacity(0.85), fontWeight: FontWeight.w600),
                            ),
                          if (hasName && tail != null) const TextSpan(text: ' · '),
                          if (tail != null) TextSpan(text: tail),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subStyle,
                      ),
                  ],
                );
"""

ok = True
a = src.find(START)
b = src.find(END, a) if a != -1 else -1
if a != -1 and b != -1 and src.count(START) == 1:
    src = src[:a] + NEW + src[b:]
    print('✔ 첫 줄 날짜 · 둘째 줄 시간/이름 · 지역')
else:
    ok = False; print('❌ 영상 글자 부분을 못 찾음')

def bal(t):
    return tuple(t.count(x) - t.count(y) for x, y in ('()', '[]', '{}'))
if ok and bal(src) != bal(raw.replace('\r\n', '\n')):
    ok = False; print('❌ 괄호 짝이 안 맞아요')

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
