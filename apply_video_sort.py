# 동영상 목록: 정렬(최신순·오래된순·이름순·긴/짧은 영상순) + 날짜별 제목
# 실행: python apply_video_sort.py   (mp3_player_new 폴더에서)
import os, sys

DONE_FILE = os.path.join('lib', 'providers', 'video_provider.dart')
DONE_MARK = 'videoSort'

FILES = {
    # ───────────── 폰에서 영상마다 찍은 날짜 받아오기 ─────────────
    'MAIN_ACTIVITY': [
        ("영상 날짜 칸 같이 읽기",
         """            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATA
        )""",
         """            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_TAKEN, // 찍은 날짜 (밀리초)
            MediaStore.Video.Media.DATE_ADDED  // 폰에 들어온 날짜 (초)
        )"""),
        ("날짜 칸 위치 찾기",
         """            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            while (it.moveToNext()) {""",
         """            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            val takenColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_TAKEN)
            val addedColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
            while (it.moveToNext()) {"""),
        ("앱으로 날짜 보내기",
         """                    "uri" to path
                ))""",
         """                    "uri" to path,
                    // 찍은 날짜 (없으면 폰에 들어온 날짜) — 밀리초
                    "date" to (it.getLong(takenColumn).takeIf { t -> t > 0 } ?: (it.getLong(addedColumn) * 1000))
                ))"""),
    ],

    # ───────────── 정렬 기억하고 순서 바꾸기 ─────────────
    os.path.join('lib', 'providers', 'video_provider.dart'): [
        ("정렬·날짜 칸",
         "  Set<String>? _seen; // 열어본(또는 처음부터 있던) 영상",
         """  Set<String>? _seen; // 열어본(또는 처음부터 있던) 영상
  final Map<String, int> _dates = {}; // 영상마다 찍은 날짜 (밀리초)
  String _sort = 'new'; // new 최신순 · old 오래된순 · name 이름순 · long 긴 영상순 · short 짧은 영상순"""),
        ("정렬 고르기 / 날짜 알려주기",
         "  // 새로 찍은 영상인지 (아직 안 열어본 것)",
         """  String get sort => _sort;
  int dateOf(String uri) => _dates[uri] ?? 0;

  // 정렬 바꾸기 (앱 다시 켜도 기억)
  Future<void> setSort(String s) async {
    if (s == _sort) return;
    _sort = s;
    _applySort();
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('videoSort', s);
  }

  void _applySort() {
    switch (_sort) {
      case 'old':
        _videos.sort((a, b) => dateOf(a.uri).compareTo(dateOf(b.uri)));
        break;
      case 'name':
        _videos.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'long':
        _videos.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case 'short':
        _videos.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      default:
        _videos.sort((a, b) => dateOf(b.uri).compareTo(dateOf(a.uri)));
    }
  }

  // 새로 찍은 영상인지 (아직 안 열어본 것)"""),
        ("영상마다 날짜 받아두기",
         """            duration: map['duration'] ?? 0,
          ));""",
         """            duration: map['duration'] ?? 0,
          ));
          _dates[map['uri'] ?? ''] = (map['date'] as num?)?.toInt() ?? 0;"""),
        ("고른 정렬대로 줄 세우기",
         """      // 순서는 폰에서 받은 그대로 (최신이 맨 위)
      _videos = foundVideos;""",
         """      // 고른 정렬대로 줄 세우기 (처음엔 최신순)
      _sort = (await SharedPreferences.getInstance()).getString('videoSort') ?? 'new';
      _videos = foundVideos;
      _applySort();"""),
    ],

    # ───────────── 화면: 정렬 버튼 + 날짜별 제목 ─────────────
    os.path.join('lib', 'screens', 'video_screen.dart'): [
        ("정렬 이름표 + 날짜 제목 만드는 도우미",
         "class VideoScreen extends StatefulWidget {",
         """// 정렬 이름
const Map<String, String> _kSortLabels = {
  'new': '최신순',
  'old': '오래된순',
  'name': '이름순',
  'long': '긴 영상순',
  'short': '짧은 영상순',
};

// 날짜 제목: 오늘 / 어제 / 10월 3일 (금) / 2025년 10월 3일 (금)
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
}

class VideoScreen extends StatefulWidget {"""),

        ("정렬 창 + 날짜별 칸 나누기",
         "  // 앱으로 돌아오면 새로 찍은 영상 있는지 조용히 다시 찾기",
         """  // 정렬 고르는 창 (길게 눌렀을 때 창과 같은 모양)
  void _showSortSheet(BuildContext context) {
    final p = context.read<VideoProvider>();
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final bg = isDarkMode ? const Color(0xFF26221C) : const Color(0xFFF4EFE5);
    final card = isDarkMode ? const Color(0xFF332E26) : Colors.white;
    final ink = isDarkMode ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = isDarkMode ? const Color(0xFFA29A8B) : const Color(0xFF8A8378);
    final line = isDarkMode ? const Color(0xFF3A342B) : const Color(0xFFEFE9DE);
    final iconColor = isDarkMode ? const Color(0xFFCFC8BB) : const Color(0xFF5A5348);
    final primary = Theme.of(context).colorScheme.primary;
    const icons = {
      'new': Icons.schedule_rounded,
      'old': Icons.history_rounded,
      'name': Icons.sort_by_alpha_rounded,
      'long': Icons.hourglass_bottom_rounded,
      'short': Icons.timer_outlined,
    };
    final keys = _kSortLabels.keys.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // 제목 + ✕
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('정렬',
                            style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: sub, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      for (var i = 0; i < keys.length; i++) ...[
                        if (i > 0) Divider(height: 1, thickness: 1, color: line),
                        InkWell(
                          onTap: () {
                            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                            Navigator.pop(ctx);
                            p.setSort(keys[i]);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                                  child: Icon(icons[keys[i]], color: iconColor, size: 17),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_kSortLabels[keys[i]]!,
                                      style: TextStyle(color: ink, fontSize: 14.5, fontWeight: FontWeight.w600)),
                                ),
                                if (p.sort == keys[i]) Icon(Icons.check_rounded, size: 20, color: primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 영상 칸들 (최신순·오래된순이면 날짜마다 작은 제목)
  List<Widget> _videoSlivers(VideoProvider p, Color baseColor) {
    Widget grid(List<Video> list, double top) => SliverPadding(
          padding: EdgeInsets.fromLTRB(12, top, 12, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.18, // 16:9 사진 + 제목 두 줄
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final v = list[index];
                // 이름표(key)가 있어야 새 영상이 끼어들어도 썸네일이 안 뒤바뀜
                return _VideoTile(key: ValueKey(v.uri), video: v);
              },
              childCount: list.length,
            ),
          ),
        );

    if (p.sort != 'new' && p.sort != 'old') return [grid(p.videos, 4)];

    final out = <Widget>[];
    String? cur;
    var bucket = <Video>[];
    void flush() {
      if (cur == null || bucket.isEmpty) return;
      out.add(SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, out.isEmpty ? 4 : 10, 16, 8),
          child: Text(cur!,
              style: TextStyle(
                  color: baseColor.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        ),
      ));
      out.add(grid(bucket, 0));
    }

    for (final v in p.videos) {
      final label = _dayLabel(p.dateOf(v.uri));
      if (label != cur) {
        flush();
        cur = label;
        bucket = <Video>[];
      }
      bucket.add(v);
    }
    flush();
    return out;
  }

  // 앱으로 돌아오면 새로 찍은 영상 있는지 조용히 다시 찾기"""),

        ("제목 줄 오른쪽 끝에 정렬 버튼",
         """                          Text('(${videoProvider.videos.length})',
                              style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 13)),
                        ],""",
         """                          Text('(${videoProvider.videos.length})',
                              style: TextStyle(color: baseColor.withOpacity(0.38), fontSize: 13)),
                          const Spacer(),
                          // 정렬 버튼: 최신순 ▾
                          GestureDetector(
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              _showSortSheet(context);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_kSortLabels[videoProvider.sort] ?? '최신순',
                                      style: TextStyle(
                                          color: baseColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: baseColor.withOpacity(0.6)),
                                ],
                              ),
                            ),
                          ),
                        ],"""),

        ("영상 칸 자리를 날짜별 칸으로 바꾸기",
         """          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.18, // 16:9 사진 + 제목 두 줄
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final v = videoProvider.videos[index];
                  // 이름표(key)가 있어야 새 영상이 끼어들어도 썸네일이 안 뒤바뀜
                  return _VideoTile(key: ValueKey(v.uri), video: v);
                },
                childCount: videoProvider.videos.length,
              ),
            ),
          ),""",
         """          ..._videoSlivers(videoProvider, baseColor),"""),
    ],
}


def balance(t):
    return (t.count('(') - t.count(')'), t.count('[') - t.count(']'), t.count('{') - t.count('}'))


def find_main_activity():
    # MainActivity.kt 가 어느 폴더에 있든 찾아오기
    for root, _, files in os.walk(os.path.join('android', 'app', 'src', 'main')):
        if 'MainActivity.kt' in files:
            return os.path.join(root, 'MainActivity.kt')
    return None


def main():
    ma = find_main_activity()
    if ma is None:
        print('❌ MainActivity.kt 를 못 찾았어요 (android\\app\\src\\main 안).')
        print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
        sys.exit(1)
    FILES[ma] = FILES.pop('MAIN_ACTIVITY')
    order = [ma] + [k for k in FILES if k != ma]
    for k in order:
        FILES[k] = FILES.pop(k)

    for path in FILES:
        if not os.path.exists(path):
            print('❌ 파일을 못 찾았어요:', path)
            print('   mp3_player_new 폴더에서 실행했는지 확인해 주세요.')
            sys.exit(1)

    if DONE_MARK in open(DONE_FILE, encoding='utf-8').read():
        print('이미 적용돼 있어요. 바꿀 게 없어요.')
        return

    results = {}
    num = 0
    for path, edits in FILES.items():
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balance(text)
        print(f'[{os.path.basename(path)}]')
        for name, old, new in edits:
            num += 1
            n = text.count(old)
            if n != 1:
                print(f'❌ {num}. {name} — 찾을 곳이 {n}개예요 (1개여야 해요)')
                print('   아무것도 저장하지 않았어요. 지금 파일을 다시 보내주세요.')
                sys.exit(1)
            text = text.replace(old, new)
            print(f'✔ {num}. {name}')
        if balance(text) != before:
            print(f'❌ {os.path.basename(path)} 괄호 개수가 안 맞아요. 아무것도 저장하지 않았어요.')
            sys.exit(1)
        if crlf:
            text = text.replace('\n', '\r\n')
        results[path] = text

    # 세 파일 다 문제없을 때만 저장
    for path, text in results.items():
        open(path, 'wb').write(text.encode('utf-8'))
    print(f'완료! {num}군데 바꿨어요.')


main()
