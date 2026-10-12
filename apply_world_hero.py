# -*- coding: utf-8 -*-
# 해외 라디오 목록 맨 위 사진 카드 (한국 라디오와 같은 모양)
#  - 사진: 그 나라 현지 시간 기준 아침·낮·저녁·밤
#  - 방송: 그 나라에서 내가 들었던 방송 → 없으면 인기 1위 (지금 듣는 방송은 빼기)
#  - 이름표: '지금 미국은 밤 · 인기 1위' / 주사위로 뽑으면 '주사위가 고른 방송'
#  - 🎲 주사위는 카드 안으로 (오른쪽 위 아이콘 빼기) · '인기(많이 듣는)'에서만 보임
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('radio_country_stations_screen.dart')
if not path:
    print('❌ lib 폴더에서 radio_country_stations_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if '_worldHero' in s:
    print('이미 적용돼 있어요')
    sys.exit(0)

ok = True
def rep(title, old, new):
    global s, ok
    if s.count(old) == 1:
        s = s.replace(old, new)
        print('✔', title)
    else:
        print('❌', title, '— 코드를 못 찾았어요')
        ok = False

rep('주사위가 고른 방송 기억 칸',
    "  bool _showSearch = false; // 돋보기 눌렀을 때만 검색칸 보이기\n",
    "  bool _showSearch = false; // 돋보기 눌렀을 때만 검색칸 보이기\n"
    "  String? _worldDiceChoice; // 주사위로 나온 방송 (사진 카드에 그대로)\n")

# 주사위: 판이 닫히면 카드에 나온 방송 남기기
rep('주사위 판 닫히길 기다리기',
    "  void _openWorldDice(List<RadioStation> all) {\n",
    "  Future<void> _openWorldDice(List<RadioStation> all) async {\n")
rep('주사위 판 닫히면 카드를 나온 방송으로',
    "    showRadioDice(context, pool, onOpen: (st) {\n",
    "    await showRadioDice(context, pool, onOpen: (st) {\n")
a = s.find("    await showRadioDice(context, pool, onOpen: (st) {\n")
b = s.find("    });\n  }\n", a if a >= 0 else 0)
if a >= 0 and b > a:
    s = s[:b] + ("    });\n"
                 "    // 판이 닫히면: 주사위로 나와서 듣는 방송을 카드에 그대로\n"
                 "    if (!mounted) return;\n"
                 "    final cur = context.read<RadioProvider>().currentStation;\n"
                 "    if (cur != null && cur.countryCode == widget.country.code) {\n"
                 "      setState(() => _worldDiceChoice = cur.stationUuid);\n"
                 "    }\n"
                 "  }\n") + s[b + len("    });\n  }\n"):]
    print('✔ 주사위 결과 기억')
else:
    print('❌ 주사위 결과 기억 — 코드를 못 찾았어요')
    ok = False

HERO = r"""  // ───── 맨 위 사진 카드 (한국 라디오와 같은 모양) ─────
  Widget _worldHero(BuildContext context, RadioProvider radio, List<RadioStation> all) {
    final code = widget.country.code;
    final curUuid = radio.currentStation?.stationUuid;
    RadioStation? pick;
    String why;
    // ① 주사위로 고른 방송
    if (_worldDiceChoice != null) {
      for (final st in [...all, if (radio.currentStation != null) radio.currentStation!]) {
        if (st.stationUuid == _worldDiceChoice) {
          pick = st;
          break;
        }
      }
    }
    if (pick != null) {
      why = '주사위가 고른 방송';
    } else {
      why = '인기 1위';
      // ② 이 나라에서 들었던 방송 (지금 듣는 건 빼기)
      for (final r in radio.recentlyListened) {
        if (r.countryCode == code && r.stationUuid != curUuid) {
          pick = r;
          why = '최근 들은 방송';
          break;
        }
      }
      // ③ 인기 1위
      if (pick == null) {
        for (final st in all) {
          if (st.stationUuid != curUuid) {
            pick = st;
            break;
          }
        }
        pick ??= all.first;
        why = all.indexOf(pick) <= 0 ? '인기 1위' : '인기 ${all.indexOf(pick) + 1}위';
      }
    }
    final st = pick!;
    // 사진·이름표: 그 나라 현지 시간 기준
    final h = _localHour(code) ?? DateTime.now().hour;
    final slot = h >= 5 && h < 11 ? 0 : h >= 11 && h < 17 ? 1 : h >= 17 && h < 22 ? 2 : 3;
    const slotName = ['아침', '낮', '저녁', '밤'];
    const photos = [
      'assets/radio_hero_morning.jpg',
      'assets/radio_hero_day.jpg',
      'assets/radio_hero_evening.jpg',
      'assets/radio_hero_night.jpg',
    ];
    final cname = widget.country.displayName;
    final last = cname.isEmpty ? 0 : cname.codeUnitAt(cname.length - 1);
    final hangul = last >= 0xAC00 && last <= 0xD7A3;
    final josa = hangul ? (((last - 0xAC00) % 28) != 0 ? '은' : '는') : '';
    final label = why == '주사위가 고른 방송' ? why : '지금 $cname$josa ${slotName[slot]} · $why';
    final sub = [
      if (st.state?.trim().isNotEmpty ?? false) st.state!.trim(),
      ..._genresOf(st).take(1),
    ].join(' · ');
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    const ink = Color(0xFF17140F);
    void open() {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      final list = all.any((x) => x.stationUuid == st.stationUuid) ? all : [st, ...all];
      final i = math.max(0, list.indexWhere((x) => x.stationUuid == st.stationUuid));
      context.read<RadioProvider>().setQueue(list, i);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => RadioPlayerScreen(station: st, stationList: list, currentIndex: i),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: GestureDetector(
        onTap: open,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ink.withOpacity(isDark ? 0.45 : 0.13),
                blurRadius: 20,
                spreadRadius: -3,
                offset: const Offset(0, 10),
              ),
              BoxShadow(color: ink.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 68, // 사진은 글자 띠 위에만
                  child: Image.asset(
                    photos[slot],
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2),
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD5E1EC)),
                  ),
                ),
                // 사진 아래 크림 띠
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
                    color: const Color(0xFFFBF8F2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                              const SizedBox(height: 1),
                              Text(st.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textScaler: TextScaler.noScaling,
                                  style: GoogleFonts.doHyeon(color: ink, fontSize: 18)),
                              if (sub.isNotEmpty)
                                Text(sub,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(color: ink.withOpacity(0.62), fontSize: 12)),
                            ],
                          ),
                        ),
                        // 🎲 주사위
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openWorldDice(all),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Color(0xFFEDE7DA), shape: BoxShape.circle),
                            child: const RollDiceIcon(size: 21, color: ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ▶ 듣기
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFF4EFE5), size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 맨 위 '다시 듣기': 이 나라에서 최근 들은 방송 + 즐겨찾기 ──
"""
rep('사진 카드 만들기', "  // ── 맨 위 '다시 듣기': 이 나라에서 최근 들은 방송 + 즐겨찾기 ──\n", HERO)

rep('목록 맨 위에 사진 카드 자리',
    "    final head = again.isEmpty ? 0 : 1;\n",
    "    // 사진 카드: '인기(많이 듣는)'에서만, 검색 중이 아닐 때\n"
    "    final showHero = _chip == 'pop' && !_isTrend && _query.isEmpty && allStations.isNotEmpty && !isLoading;\n"
    "    final head = (showHero ? 1 : 0) + (again.isEmpty ? 0 : 1);\n")

rep('목록 맨 위에 사진 카드 넣기',
    "                        if (index < head) return _againRow(again, radioProvider, baseColor);\n",
    "                        if (showHero && index == 0) return _worldHero(context, radioProvider, allStations);\n"
    "                        if (index < head) return _againRow(again, radioProvider, baseColor);\n")

# 오른쪽 위 주사위 아이콘 빼기
a = s.find("          if (!isLoading && allStations.isNotEmpty)\n            IconButton(\n              onPressed: () => _openWorldDice(allStations),\n")
b = s.find("          IconButton(\n            onPressed: () {\n              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n              setState(() {\n                _showSearch = !_showSearch;", a if a >= 0 else 0)
if a >= 0 and b > a:
    s = s[:a] + "          // 주사위는 맨 위 사진 카드 안으로 옮김\n" + s[b:]
    print('✔ 오른쪽 위 주사위 아이콘 빼기')
else:
    print('❌ 오른쪽 위 주사위 아이콘 — 코드를 못 찾았어요')
    ok = False

# 현지 시각(시) 구하기
rep('현지 시각 구하기',
    "/// 이름 속 주파수 찾기",
    "/// 현지 시각의 '시' (모르는 나라는 null) — 사진 카드 아침·낮·저녁·밤용\n"
    "int? _localHour(String code) {\n"
    "  final now = DateTime.now().toUtc();\n"
    "  var off = _utcFixed[code];\n"
    "  if (off == null) {\n"
    "    final eu = _utcEu[code];\n"
    "    if (eu == null) return null;\n"
    "    final summer = !now.isBefore(_lastSundayUtc(now.year, 3)) && now.isBefore(_lastSundayUtc(now.year, 10));\n"
    "    off = eu + (summer ? 1 : 0);\n"
    "  }\n"
    "  return now.add(Duration(minutes: (off * 60).round())).hour;\n"
    "}\n"
    "\n"
    "/// 이름 속 주파수 찾기")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
