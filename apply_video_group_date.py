# 동영상 목록: 날짜 제목 아래 칸에서는 날짜 빼고 시간만 (날짜가 두 번 나오지 않게)
# 실행: python apply_video_group_date.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
DONE_MARK = 'showDate'

EDITS = [
    ("날짜별로 묶인 칸인지 알려주기",
     "    Widget grid(List<Video> list, double top) => SliverPadding(",
     "    Widget grid(List<Video> list, double top, {bool grouped = false}) => SliverPadding("),
    ("묶인 칸이면 날짜 숨기기",
     "                  video: v,\n                  selecting: _selecting,",
     "                  video: v,\n                  showDate: !grouped, // 날짜 제목 아래면 날짜는 빼고 시간만\n                  selecting: _selecting,"),
    ("날짜 제목 아래 칸들",
     "      out.add(grid(bucket, 0));",
     "      out.add(grid(bucket, 0, grouped: true));"),
    ("영상 칸: 날짜 보일지 받기",
     """  final VoidCallback? onSelect;

  const _VideoTile({super.key, required this.video, this.selecting = false, this.selected = false, this.onSelect});""",
     """  final VoidCallback? onSelect;
  final bool showDate; // false면 날짜 빼고 시간만 (날짜 제목 아래)

  const _VideoTile(
      {super.key, required this.video, this.selecting = false, this.selected = false, this.onSelect, this.showDate = true});"""),
    ("이름 바꾼 영상: 날짜 제목 아래면 시간만",
     "                    when = '$day (${week[d.weekday - 1]}) $ampm $h12:${d.minute.toString().padLeft(2, '0')}';",
     """                    final hm = '$ampm $h12:${d.minute.toString().padLeft(2, '0')}';
                    when = widget.showDate ? '$day (${week[d.weekday - 1]}) $hm' : hm;"""),
    ("카메라 영상: 날짜 제목 아래면 시간만 (진하게)",
     """                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cd.date,""",
     """                // 날짜 제목 아래면 날짜는 이미 위에 있으니까 시간만
                if (!widget.showDate) {
                  return Text(
                    cd.time,
                    maxLines: 1,
                    style: TextStyle(color: baseColor, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cd.date,"""),
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
