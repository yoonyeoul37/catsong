# -*- coding: utf-8 -*-
# 홈: 검정 카드 글자 색 / 최근에 들었어요 날짜 묶음·사진 / 강조 색상 카드 다시 나오기
import os, sys, shutil

NAME = 'home_screen.dart'

def find_file():
    for root, _, files in os.walk('lib'):
        if NAME in files:
            return os.path.join(root, NAME)
    return None

path = find_file()
if not path:
    print('❌ lib 폴더에서 %s 를 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)' % NAME)
    sys.exit(1)

raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '_recentGroup(' in src:
    print('이미 적용돼 있어요')
    sys.exit(0)

EDITS = []
def edit(label, old, new, count=1):
    EDITS.append((label, old, new, count))

# 1) 강조 색: 카드 위에서 잘 보이게 (3군데 같은 코드)
edit('강조 색 글자 잘 보이게 (3군데)',
"""    final accent = point.value == 0xFF2589E8
        ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
        : point;""",
"""    final accent = _readable(
        point.value == 0xFF2589E8
            ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
            : point,
        isDark);""", count=3)

# 2) 강조 색상 카드: ✕ 누르면 7일 뒤 다시 (3번 닫으면 끝)
edit('강조 색상 카드 - 숨긴 기간 확인',
"""    if (prefs.getBool('color_tip_done') ?? false) return;""",
"""    if (prefs.getBool('color_tip_done') ?? false) return;
    // ✕로 닫았으면 7일 동안은 안 보여줌
    if (DateTime.now().millisecondsSinceEpoch < (prefs.getInt('color_tip_hide_until') ?? 0)) return;""")

edit('강조 색상 카드 - ✕ 누르면 7일 뒤 다시',
"""  /// [바꾸기]·✕ 누르면 끝 (다시 안 나옴)
  Future<void> _finishColorTip() async {
    if (mounted) setState(() => _showColorTip = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('color_tip_done', true);
  }""",
"""  /// ✕ 누르면 7일 뒤 다시 나옴 (3번 닫으면 그 뒤로는 안 나옴)
  Future<void> _finishColorTip() async {
    if (mounted) setState(() => _showColorTip = false);
    final prefs = await SharedPreferences.getInstance();
    final closed = (prefs.getInt('color_tip_closed') ?? 0) + 1;
    await prefs.setInt('color_tip_closed', closed);
    if (closed >= 3) {
      await prefs.setBool('color_tip_done', true);
    } else {
      await prefs.setInt('color_tip_hide_until',
          DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch);
    }
  }""")

# 3) 최근에 들었어요: 7일 안 · 같은 것 한 번만 · 최대 20개
edit('최근 목록 - 7일 안·중복 빼기·20개',
"""    final recentContent = context.watch<RecentContentProvider>().entries.take(20).toList();""",
"""    // 7일 안에 들은 것만 · 같은 것은 가장 최근 한 번만 · 최대 20개
    final recentContent = () {
      final cut = DateTime.now().subtract(const Duration(days: 7));
      final seen = <String>{};
      final out = <RecentContentEntry>[];
      for (final e in context.watch<RecentContentProvider>().entries) {
        if (e.playedAt.isBefore(cut)) continue;
        if (!seen.add('${e.type.name}|${e.key}')) continue;
        out.add(e);
        if (out.length >= 20) break;
      }
      return out;
    }();""")

# 4) 높이: 날짜 줄 자리만큼 늘리기
edit('최근 목록 - 높이 (날짜 줄 자리)',
"""                return SizedBox(
                height: 124,
                child: ListView.separated(""",
"""                return SizedBox(
                height: 142,
                child: ListView.separated(""")

# 5) 묶음 사이 얇은 세로선
edit('최근 목록 - 묶음 사이 세로선',
"""                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = recentContent[index];""",
"""                  // 날짜 묶음이 바뀌는 곳에만 얇은 세로선
                  separatorBuilder: (_, i) => _recentGroup(recentContent[i].playedAt) ==
                          _recentGroup(recentContent[i + 1].playedAt)
                      ? const SizedBox(width: 14)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 56),
                          child: Container(width: 1, color: baseColor.withOpacity(0.12)),
                        ),
                  itemBuilder: (context, index) {
                    final item = recentContent[index];
                    // 묶음 첫 카드 위에만 날짜 (오늘 · 어제 · 3일 안 · 일주일 안)
                    final group = _recentGroup(item.playedAt);
                    final showGroup = index == 0 || _recentGroup(recentContent[index - 1].playedAt) != group;""")

# 6) 사진 없는 곡: 노앨범 사진
edit('최근 목록 - 사진 없는 곡은 노앨범 사진',
"""                            : _recentTile(isDarkMode, const Color(0xFFF3D9C9), Icons.music_note_rounded);""",
"""                            : _recentAsset(noAlbumImagePath(matched?.uri ?? item.songUri ?? item.title));""")

# 7) 라디오: 들은 시간대 라디오 사진
edit('최근 목록 - 라디오 사진',
"""                        thumbnail = _recentTile(isDarkMode, const Color(0xFFD5E1EC), Icons.radio_rounded);""",
"""                        thumbnail = _recentAsset(_radioSlotImage(item.playedAt));""")

# 8) 자연: 이름에 맞는 사진
edit('최근 목록 - 자연 사진',
"""                        thumbnail = _recentTile(isDarkMode, const Color(0xFFDCE5D2), Icons.waves_rounded);""",
"""                        thumbnail = _recentAsset(MediaArt.natureImage(item.title));""")

# 9) 카드 위 날짜 줄
edit('최근 목록 - 카드 위 날짜 글자',
"""                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.45 : 0.13),""",
"""                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 18,
                              child: showGroup
                                  ? Text(group,
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                      softWrap: false,
                                      style: TextStyle(
                                          color: baseColor.withOpacity(0.5),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800))
                                  : null,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF17140F).withOpacity(isDarkMode ? 0.45 : 0.13),""")

# 10) 도우미 함수 (맨 아래 _recentTile 바로 앞에)
edit('도우미 함수 추가',
"""Widget _recentTile(bool isDarkMode, Color pastel, IconData icon) {""",
"""/// 카드 바탕 위에서 강조 색 글자가 잘 보이게: 다크는 너무 어두우면 밝게, 라이트는 너무 밝으면 진하게
Color _readable(Color c, bool isDark) {
  var out = c;
  for (var i = 0; i < 8; i++) {
    final l = out.computeLuminance();
    if (isDark ? l >= 0.22 : l <= 0.30) break;
    out = Color.lerp(out, isDark ? Colors.white : const Color(0xFF17140F), 0.18)!;
  }
  return out;
}

/// 최근에 들었어요 날짜 묶음 이름
String _recentGroup(DateTime t) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (days <= 0) return '오늘';
  if (days == 1) return '어제';
  if (days <= 3) return '3일 안';
  return '일주일 안';
}

/// 라디오: 들은 시간대 사진 (아침 5–11 · 낮 11–17 · 저녁 17–22 · 밤)
String _radioSlotImage(DateTime t) {
  final h = t.hour;
  final slot = h >= 5 && h < 11
      ? 'morning'
      : h >= 11 && h < 17
          ? 'day'
          : h >= 17 && h < 22
              ? 'evening'
              : 'night';
  return 'assets/radio_media_$slot.jpg';
}

/// 최근 카드 사진 (앱 안 사진)
Widget _recentAsset(String asset) {
  return Image.asset(
    asset,
    width: 72,
    height: 72,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    cacheWidth: 216,
  );
}

Widget _recentTile(bool isDarkMode, Color pastel, IconData icon) {""")

ok = True
for label, old, new, count in EDITS:
    n = src.count(old)
    if n != count:
        print('❌ %s (찾은 개수 %d, 필요 %d)' % (label, n, count))
        ok = False
        continue
    src = src.replace(old, new)
    print('✔ %s' % label)

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요')
    sys.exit(1)

shutil.copyfile(path, path + '.bak')
out = src.replace('\n', '\r\n') if crlf else src
open(path, 'wb').write(out.encode('utf-8'))
print('\n저장했어요: %s (원본은 .bak)' % path)
