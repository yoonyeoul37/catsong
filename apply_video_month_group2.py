# 동영상 목록: 오늘·어제는 날짜별, 그 전은 월별로 묶기 + 칸 아래는 겹치지 않는 정보만
#  - 오늘·어제 묶음: 시간만 / 월별 묶음: 일(요일) + 시간 / 이름순·길이순: 날짜까지 다
# (apply_video_group_date.py 를 이미 실행한 파일용)
# 실행: python apply_video_month_group2.py   (mp3_player_new 폴더에서)
import os, sys

PATH = os.path.join('lib', 'screens', 'video_screen.dart')
DONE_MARK = 'dateMode'

EDITS = [
    ("묶음 제목: 오늘 / 어제 / 10월 / 2025년 10월",
     """// 날짜 제목: 오늘 / 어제 / 10월 3일 (금) / 2025년 10월 3일 (금)
String _dayLabel(int ms) {
  if (ms <= 0) return '날짜 모름';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '어제';
  const week = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = week[d.weekday - 1];
  if (d.year == now.year) return '${d.month}월 ${d.day}일 ($wd)';
  return '${d.year}년 ${d.month}월 ${d.day}일 ($wd)';
}""",
     """// 묶음 제목: 오늘 / 어제는 날짜별, 그 전은 월별 (10월 / 2025년 10월) → 한 칸만 남는 줄이 거의 없게
String _dayLabel(int ms) {
  if (ms <= 0) return '날짜 모름';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '오늘';
  if (diff == 1) return '어제';
  if (d.year == now.year) return '${d.month}월';
  return '${d.year}년 ${d.month}월';
}"""),

    ("묶음마다 칸 아래 날짜 보이는 방식 넘기기",
     "    Widget grid(List<Video> list, double top, {bool grouped = false}) => SliverPadding(",
     "    Widget grid(List<Video> list, double top, {String dateMode = 'full'}) => SliverPadding("),

    ("영상 칸에 날짜 보이는 방식 주기",
     "                  showDate: !grouped, // 날짜 제목 아래면 날짜는 빼고 시간만\n",
     "                  dateMode: dateMode,\n"),

    ("오늘·어제 묶음은 시간만, 월별 묶음은 일(요일)+시간",
     "      out.add(grid(bucket, 0, grouped: true));",
     "      out.add(grid(bucket, 0, dateMode: (cur == '오늘' || cur == '어제') ? 'time' : 'day'));"),

    ("카메라 영상 이름에서 일(요일)도 꺼내기",
     "({String date, String time})? _cameraDate(String title) {",
     "({String date, String time, String day})? _cameraDate(String title) {"),
    ("카메라 영상: 일(요일) 만들기",
     """    date: '$y년 $mo월 $d일 ($wd)',
    time: '$ampm $h12:${mi.toString().padLeft(2, '0')}',
  );""",
     """    date: '$y년 $mo월 $d일 ($wd)',
    time: '$ampm $h12:${mi.toString().padLeft(2, '0')}',
    day: '$d일 ($wd)',
  );"""),

    ("영상 칸: 날짜 보이는 방식 받기",
     """  final bool showDate; // false면 날짜 빼고 시간만 (날짜 제목 아래)

  const _VideoTile(
      {super.key, required this.video, this.selecting = false, this.selected = false, this.onSelect, this.showDate = true});""",
     """  final String dateMode; // full 날짜까지 · day 일(요일)+시간 (월별 묶음) · time 시간만 (오늘·어제)

  const _VideoTile(
      {super.key, required this.video, this.selecting = false, this.selected = false, this.onSelect, this.dateMode = 'full'});"""),

    ("이름 바꾼 영상: 묶음에 맞게 날짜 줄이기",
     "                    when = widget.showDate ? '$day (${week[d.weekday - 1]}) $hm' : hm;",
     """                    final wd = week[d.weekday - 1];
                    // 위 묶음 제목과 겹치는 건 빼기
                    when = widget.dateMode == 'time'
                        ? hm
                        : widget.dateMode == 'day'
                            ? '${d.day}일 ($wd) $hm'
                            : '$day ($wd) $hm';"""),

    ("카메라 영상: 오늘·어제 묶음은 시간만",
     """                // 날짜 제목 아래면 날짜는 이미 위에 있으니까 시간만
                if (!widget.showDate) {""",
     """                // 오늘·어제 묶음: 시간만 (진하게)
                if (widget.dateMode == 'time') {"""),
    ("카메라 영상: 월별 묶음은 일(요일)",
     """                    Text(
                      cd.date,""",
     """                    Text(
                      // 월별 묶음이면 "5일 (월)", 아니면 "2026년 10월 5일 (월)"
                      widget.dateMode == 'day' ? cd.day : cd.date,"""),
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
