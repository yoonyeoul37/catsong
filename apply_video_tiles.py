# -*- coding: utf-8 -*-
# 동영상 목록 B안: 모서리 덜 둥글게(10) · 사진 위 알약 칸 없애기 · NEW는 제목 앞 · 지역은 날짜 뒤
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
if not os.path.exists(PATH):
    for root, _, files in os.walk('lib'):
        if 'video_screen.dart' in files:
            PATH = os.path.join(root, 'video_screen.dart'); break

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '// B안: 사진 위엔 재생 시간만' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True

def rep(name, old, new):
    global src, ok
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

rep('모서리 덜 둥글게 (12 → 10)',
"""            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,""",
"""            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,""")

rep('재생 시간: 작고 옅은 표',
"""                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17140F).withOpacity(0.72),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.video.durationFormatted,""",
"""                      // B안: 사진 위엔 재생 시간만 작게
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.video.durationFormatted,""")

# 사진 위 지역 칸 + NEW 칸 없애기
a = src.find('                    // 찍은 곳: 왼쪽 아래 (오른쪽 재생 시간 표와 같은 모양, 흰 선 핀)')
b = src.find('                    // 여러 개 선택 중: 고른 건 살짝 어둡게')
if a != -1 and b != -1 and a < b and '// 새로 찍은(아직 안 본) 영상: 왼쪽 위 NEW' in src[a:b]:
    src = src[:a] + src[b:]; print('✔ 사진 위 지역·NEW 칸 없애기')
else:
    ok = False; print('❌ 사진 위 지역·NEW 칸을 못 찾음')

rep('제목 앞 NEW · 날짜 뒤 지역 (준비)',
"""              child: Builder(builder: (_) {
                final cd = _cameraDate(widget.video.title);""",
"""              child: Builder(builder: (_) {
                // NEW는 제목 앞 작은 포인트색 글자, 찍은 곳은 날짜 뒤에 "· 중구 명동"
                final isNew = context.watch<VideoProvider>().isNew(widget.video.uri);
                final place = context.watch<VideoProvider>().placeOf(widget.video.uri);
                final words = place?.split(' ') ?? const <String>[];
                final shortPlace = place == null
                    ? null
                    : (words.length > 2 ? words.sublist(words.length - 2).join(' ') : place);
                String withPlace(String s) => shortPlace == null ? s : '$s · $shortPlace';
                Widget title(String text, TextStyle style, {int maxLines = 1}) => Text.rich(
                      TextSpan(children: [
                        if (isNew)
                          TextSpan(
                            text: 'NEW  ',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3),
                          ),
                        TextSpan(text: text),
                      ]),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    );
                final cd = _cameraDate(widget.video.title);""")

rep('이름 있는 영상: 제목·날짜',
"""                      Text(
                        widget.video.titleDisplay,
                        maxLines: when == null ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                      if (when != null)
                        Text(
                          when,""",
"""                      title(
                        widget.video.titleDisplay,
                        TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: when == null && shortPlace == null ? 2 : 1,
                      ),
                      if (when != null || shortPlace != null)
                        Text(
                          when == null ? shortPlace! : withPlace(when),""")

rep('오늘·어제 묶음: 시간 + 지역',
"""                if (widget.dateMode == 'time') {
                  return Text(
                    cd.time,
                    maxLines: 1,
                    style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                  );
                }""",
"""                if (widget.dateMode == 'time') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title(cd.time,
                          TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3)),
                      if (shortPlace != null)
                        Text(
                          shortPlace,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.3),
                        ),
                    ],
                  );
                }""")

rep('카메라 영상: 날짜 + 시간 · 지역',
"""                    Text(
                      // 월별 묶음이면 "5일 (월)", 아니면 "2026년 10월 5일 (월)"
                      widget.dateMode == 'day' ? cd.day : cd.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    Text(
                      cd.time,
                      maxLines: 1,
                      style:""",
"""                    title(
                      // 월별 묶음이면 "5일 (월)", 아니면 "2026년 10월 5일 (월)"
                      widget.dateMode == 'day' ? cd.day : cd.date,
                      TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    Text(
                      withPlace(cd.time),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:""")

def bal(t):
    return tuple(t.count(x) - t.count(y) for x, y in ('()', '[]', '{}'))
if ok and bal(src) != bal(raw.replace('\r\n', '\n')):
    ok = False; print('❌ 괄호 짝이 안 맞아요', bal(src), bal(raw))

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
