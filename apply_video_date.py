# 동영상 목록: 카메라 영상 이름을 "2026년 10월 8일 (목) / 오후 4:03"으로 + 썸네일 뒤바뀜 고치기
# 실행: python apply_video_date.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
DONE_MARK = '_cameraDate'

EDITS = [
    ("썸네일 뒤바뀜 고치기: 칸마다 영상 이름표 붙이기",
     "                  return _VideoTile(video: videoProvider.videos[index]);",
     "                  final v = videoProvider.videos[index];\n"
     "                  // 이름표(key)가 있어야 새 영상이 끼어들어도 썸네일이 안 뒤바뀜\n"
     "                  return _VideoTile(key: ValueKey(v.uri), video: v);"),

    ("썸네일 뒤바뀜 고치기: 이름표 받을 수 있게",
     "  const _VideoTile({required this.video});",
     "  const _VideoTile({super.key, required this.video});"),

    ("카메라 영상 이름 → 날짜·요일·시간 바꾸는 도우미",
     "class _VideoTile extends StatefulWidget {",
     """// 카메라로 찍은 영상 이름(20261008_160312)을 날짜·시간으로 바꿔 보여주기
({String date, String time})? _cameraDate(String title) {
  final m = RegExp(r'(\\d{4})(\\d{2})(\\d{2})_(\\d{2})(\\d{2})(\\d{2})').firstMatch(title);
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final h = int.parse(m[4]!), mi = int.parse(m[5]!);
  if (y < 2000 || mo < 1 || mo > 12 || d < 1 || d > 31 || h > 23 || mi > 59) return null;
  const week = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = week[DateTime(y, mo, d).weekday - 1];
  final ampm = h < 12 ? '오전' : '오후';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return (
    date: '$y년 $mo월 $d일 ($wd)',
    time: '$ampm $h12:${mi.toString().padLeft(2, '0')}',
  );
}

class _VideoTile extends StatefulWidget {"""),

    ("제목 자리: 카메라 영상이면 날짜(진하게) + 시간(연하게) 두 줄",
     """            // 제목 두 줄까지
            Flexible(
              child: Text(
                widget.video.titleDisplay,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
              ),
            ),""",
     """            // 제목 두 줄까지 (카메라 영상이면 날짜 + 시간)
            Flexible(
              child: Builder(builder: (_) {
                final cd = _cameraDate(widget.video.title);
                if (cd == null) {
                  return Text(
                    widget.video.titleDisplay,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cd.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    Text(
                      cd.time,
                      maxLines: 1,
                      style: TextStyle(color: baseColor.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.3),
                    ),
                  ],
                );
              }),
            ),"""),
]


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)

    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    if DONE_MARK in text:
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    before = balance(text)
    for i, (name, old, new) in enumerate(EDITS, 1):
        n = text.count(old)
        if n != 1:
            print(f'❌ {i}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
            print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
            sys.exit(1)
        text = text.replace(old, new)
        print(f'✔ {i}. {name}')

    if balance(text) != before:
        print('❌ 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
        sys.exit(1)

    if crlf:
        text = text.replace('\n', '\r\n')
    open(PATH, 'wb').write(text.encode('utf-8'))
    print(f'완료! {len(EDITS)}군데 바꿨어요.')


main()
