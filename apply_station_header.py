# -*- coding: utf-8 -*-
# 라디오 방송사별·지역별 채널 목록 화면 위쪽: 이름만 → 색 띠 머리(A안)
#  - 격자 칸과 같은 색 바탕 + 큰 이름 + 채널 수 + 오른쪽 은은한 워터마크 아이콘
import os, sys

PATH = os.path.join('lib', 'screens', 'radio_korea_screen2.dart')

CLASS_START = "class _BroadcasterStationList extends StatelessWidget {"
CLASS_END = "// 상단바에 쓰는 작은 이퀄라이저 막대"

# 파일 전체에서 바꿀 곳 (부르는 곳 2군데)
EDITS_FILE = [
    ('지역별 칸 → 지역 색·아이콘 넘기기',
     "_BroadcasterStationList(broadcaster: region, stations: stations)",
     "_BroadcasterStationList(broadcaster: region, stations: stations, color: _regionColors[region] ?? const Color(0xFF3A342A), icon: _regionIcons[region] ?? Icons.place_rounded)"),
    ('방송사별 칸 → 방송사 색·아이콘 넘기기',
     "_BroadcasterStationList(broadcaster: key, stations: stations)",
     "_BroadcasterStationList(broadcaster: key, stations: stations, color: _cardColors[key] ?? const Color(0xFF3A342A), icon: _cardIcons[key] ?? Icons.radio_rounded)"),
]

# 목록 화면 안에서만 바꿀 곳
EDITS_CLASS = [
    ('색·아이콘 받기',
     """  final String broadcaster;
  final List<_KStation> stations;
  const _BroadcasterStationList({required this.broadcaster, required this.stations});
""",
     """  final String broadcaster;
  final List<_KStation> stations;
  final Color color; // 머리 색 (격자 칸과 같은 색)
  final IconData icon; // 머리 오른쪽 워터마크 (격자 칸과 같은 아이콘)
  const _BroadcasterStationList({
    required this.broadcaster,
    required this.stations,
    required this.color,
    required this.icon,
  });

  /// 위쪽 색 띠 머리: 뒤로가기 + 큰 이름 + 채널 수 + 은은한 큰 아이콘
  Widget _header(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // 격자 칸과 같은 그라데이션
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
      ),
      padding: EdgeInsets.only(top: top),
      child: Stack(
        children: [
          // 오른쪽 아래 큰 아이콘 (배경 무늬처럼 은은하게, 띠 밖으로 살짝 잘리게)
          Positioned(
            right: -14,
            bottom: -26,
            child: Icon(icon, size: 130, color: Colors.white.withOpacity(0.10)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _BroadcasterGridScreen.gridLabel(context, broadcaster),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr.channelsCount(stations.length),
                        maxLines: 1,
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
"""),
    ('위쪽: 이름만 있던 AppBar 지우고 색 띠 머리로',
     """    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDarkMode
            ? const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        )
            : const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          onPressed: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: baseColor, size: 20),
        ),
        title: Text(_BroadcasterGridScreen.gridLabel(context, broadcaster),
            style: TextStyle(color: baseColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: _DialHost(
          tickColor: baseColor.withOpacity(0.35),
          child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
""",
     """    // 색 띠 위라서 상태바 아이콘은 흰색
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF24221F) : const Color(0xFFEDE7DA),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SafeArea(
        top: false,
        child: _DialHost(
          tickColor: baseColor.withOpacity(0.35),
          child: ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 90 + MediaQuery.of(context).viewPadding.bottom),
"""),
    ('목록 닫는 괄호 맞추기',
     """          },
        ),
        ),
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
    );
  }
}
""",
     """          },
        ),
        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: radioProvider.currentStation != null
          ? Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: const RadioMiniPlayer(),
      )
          : null,
    ),
    );
  }
}
"""),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH, '— 프로젝트 폴더(mp3_player_new)에서 실행해 주세요')
        return 1
    raw = open(PATH, 'rb').read()
    crlf = b'\r\n' in raw
    text = raw.decode('utf-8').replace('\r\n', '\n')
    if 'Widget _header(BuildContext context)' in text and 'required this.icon' in text:
        print('이미 적용돼 있어요')
        return 0
    ok = True
    for name, old, new in EDITS_FILE:
        n = text.count(old)
        if n == 1:
            text = text.replace(old, new); print('✔', name)
        else:
            print('❌', name, '(찾은 개수: %d)' % n); ok = False
    s = text.find(CLASS_START); e = text.find(CLASS_END)
    if s == -1 or e == -1 or s > e:
        print('❌ 채널 목록 화면(_BroadcasterStationList)을 못 찾았어요'); ok = False
    else:
        part = text[s:e]
        for name, old, new in EDITS_CLASS:
            n = part.count(old)
            if n == 1:
                part = part.replace(old, new); print('✔', name)
            else:
                print('❌', name, '(찾은 개수: %d)' % n); ok = False
        text = text[:s] + part + text[e:]
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        return 1
    for o, c in ['()', '[]', '{}']:
        if text.count(o) != text.count(c):
            print('❌ 괄호 개수가 안 맞아요', o, c); print('\n아무것도 저장하지 않았어요.'); return 1
    if crlf:
        text = text.replace('\n', '\r\n')
    open(PATH, 'wb').write(text.encode('utf-8'))
    print('\n저장했어요:', PATH)
    return 0

if __name__ == '__main__':
    sys.exit(main())
