# -*- coding: utf-8 -*-
# 자연소리·라디오 하트: 켤 때 통통 튀기 (+ 하트 옆 눌러도 재생 안 되게 — 아직 안 했으면 같이)
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

NEW_FILE = 'lib/widgets/heart_pop.dart'
NEW_CODE = """import 'package:flutter/material.dart';

/// 하트가 켜질 때 통통 튀기 (1 → 1.35 → 0.9 → 1, 0.45초) — 끌 때는 조용히
class HeartPop extends StatefulWidget {
  final bool on;
  final Widget child;
  const HeartPop({super.key, required this.on, required this.child});

  @override
  State<HeartPop> createState() => _HeartPopState();
}

class _HeartPopState extends State<HeartPop> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 35),
  ]).animate(_c);

  @override
  void didUpdateWidget(HeartPop old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on) _c.forward(from: 0); // 켜질 때만
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}
"""

# (이름, [ (찾을 것, 바꿀 것), ... ])  — 앞에서부터 하나라도 맞으면 그걸로
FILES = {
'lib/screens/nature_sounds_screen.dart': [
('불러오기', [("import '../widgets/paran_toast.dart';\n",
               "import '../widgets/paran_toast.dart';\nimport '../widgets/heart_pop.dart';\n")]),
('목록 하트 칸 넓게', [
  ("""                          GestureDetector(
                            onTap: () => _toggleFavorite(primary.name),
                            child: SizedBox(
                              width: 34,
                              height: 34,""",
   """                          GestureDetector(
                            // 하트 주변 칸 전체가 하트 자리 (옆을 눌러도 재생 안 되게)
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _toggleFavorite(primary.name),
                            child: SizedBox(
                              width: 44,
                              height: 44,"""),
  ('// 하트 주변 칸 전체가 하트 자리', None),   # 이미 넓혀져 있으면 그대로
]),
('목록 하트 통통', [("""                                child: Icon(
                                  _favoriteNames.contains(primary.name)
                                      ? CupertinoIcons.heart_fill
                                      : CupertinoIcons.heart,
                                  color: _favoriteNames.contains(primary.name)
                                      ? const Color(0xFFE05A4F)
                                      : baseColor.withOpacity(0.3),
                                  size: 22,
                                ),""",
"""                                child: HeartPop(
                                  on: _favoriteNames.contains(primary.name),
                                  child: Icon(
                                    _favoriteNames.contains(primary.name)
                                        ? CupertinoIcons.heart_fill
                                        : CupertinoIcons.heart,
                                    color: _favoriteNames.contains(primary.name)
                                        ? const Color(0xFFE05A4F)
                                        : baseColor.withOpacity(0.3),
                                    size: 22,
                                  ),
                                ),""")]),
],
'lib/screens/nature_sound_detail_screen.dart': [
('불러오기', [("import '../widgets/paran_dialog.dart';\n",
               "import '../widgets/paran_dialog.dart';\nimport '../widgets/heart_pop.dart';\n")]),
('위쪽 하트 통통', [("""                            child: Icon(isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                color: isFavorite ? const Color(0xFFE05A4F) : Colors.white, size: 16),""",
"""                            child: HeartPop(
                              on: isFavorite,
                              child: Icon(isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                  color: isFavorite ? const Color(0xFFE05A4F) : Colors.white, size: 16),
                            ),""")]),
],
'lib/screens/radio_korea_screen2.dart': [
('불러오기', [("import '../widgets/radio_mini_player.dart';\n",
               "import '../widgets/radio_mini_player.dart';\nimport '../widgets/heart_pop.dart';\n")]),
('목록 하트 칸 넓게 + 통통', [
  ("""                  child: Icon(
                    context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                        ? const Color(0xFFE05A4F)
                        : baseColor.withOpacity(0.35),
                    size: 22,
                  ),
                ),""", None),
  ("""                  // 하트 둘레 넓게 (옆을 눌러도 재생 안 되게)
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                            ? const Color(0xFFE05A4F)
                            : baseColor.withOpacity(0.35),
                        size: 22,
                      ),
                    ),
                  ),
                ),""", None),
]),
],
'lib/screens/radio_country_stations_screen.dart': [
('불러오기', [("import '../widgets/station_logo.dart';\n",
               "import '../widgets/station_logo.dart';\nimport '../widgets/heart_pop.dart';\n")]),
('목록 하트 통통', [("""                  icon: Icon(
                    context
                        .watch<RadioProvider>()
                        .isFavorite(station.stationUuid)
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: context
                        .watch<RadioProvider>()
                        .isFavorite(station.stationUuid)
                        ? const Color(0xFFE05A4F)
                        : baseColor.withOpacity(0.25),
                    size: 21,
                  ),""",
"""                  icon: HeartPop(
                    on: context.watch<RadioProvider>().isFavorite(station.stationUuid),
                    child: Icon(
                      context
                          .watch<RadioProvider>()
                          .isFavorite(station.stationUuid)
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      color: context
                          .watch<RadioProvider>()
                          .isFavorite(station.stationUuid)
                          ? const Color(0xFFE05A4F)
                          : baseColor.withOpacity(0.25),
                      size: 21,
                    ),
                  ),""")]),
],
'lib/screens/radio_player_screen.dart': [
('불러오기', [("import '../widgets/overseas_radio_view.dart';\n",
               "import '../widgets/overseas_radio_view.dart';\nimport '../widgets/heart_pop.dart';\n")]),
('위쪽 하트 통통', [("""                                  child: Icon(
                                    radioProvider.isFavorite(current.stationUuid) ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                    color: radioProvider.isFavorite(current.stationUuid) ? const Color(0xFFE05A4F) : baseColor.withOpacity(0.6),
                                    size: 16,
                                  ),""",
"""                                  child: HeartPop(
                                    on: radioProvider.isFavorite(current.stationUuid),
                                    child: Icon(
                                      radioProvider.isFavorite(current.stationUuid) ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                      color: radioProvider.isFavorite(current.stationUuid) ? const Color(0xFFE05A4F) : baseColor.withOpacity(0.6),
                                      size: 16,
                                    ),
                                  ),""")]),
],
'lib/widgets/station_tile.dart': [
('불러오기', [("import 'station_logo.dart';\n", "import 'station_logo.dart';\nimport 'heart_pop.dart';\n")]),
('목록 하트 통통', [("""                icon: Icon(
                  isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                  color: isFav ? const Color(0xFFE05A4F) : baseColor.withOpacity(0.3),
                  size: 21,
                ),""",
"""                icon: HeartPop(
                  on: isFav,
                  child: Icon(
                    isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: isFav ? const Color(0xFFE05A4F) : baseColor.withOpacity(0.3),
                    size: 21,
                  ),
                ),""")]),
],
'lib/widgets/overseas_radio_view.dart': [
('불러오기', [("import 'station_logo.dart';\n", "import 'station_logo.dart';\nimport 'heart_pop.dart';\n")]),
('아래 하트 통통', [("""                          icon: Icon(
                            isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                            color: isFav ? const Color(0xFFE05A4F) : Colors.white70,
                            size: 24,
                          ),""",
"""                          icon: HeartPop(
                            on: isFav,
                            child: Icon(
                              isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                              color: isFav ? const Color(0xFFE05A4F) : Colors.white70,
                              size: 24,
                            ),
                          ),""")]),
],
}

# 라디오 한국 목록: 넓은 칸 + 통통 (원래 모양이든 넓힌 모양이든 같은 결과로)
KOREA_NEW = """                  // 하트 둘레 넓게 (옆을 눌러도 재생 안 되게) + 켤 때 통통
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: HeartPop(
                        on: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid),
                        child: Icon(
                          context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: context.watch<RadioProvider>().isFavorite(radioStation.stationUuid)
                              ? const Color(0xFFE05A4F)
                              : baseColor.withOpacity(0.35),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),"""
KOREA_OLD_WIDE_PREFIX = "                  // 하트 둘레 넓게 (옆을 눌러도 재생 안 되게)\n"

def main():
    # 이미 적용됐는지
    if os.path.exists(NEW_FILE) and all('heart_pop.dart' in open(p, encoding='utf-8').read() for p in FILES if os.path.exists(p)):
        print('이미 적용돼 있어요'); return
    out = {}
    ok = True
    for path, edits in FILES.items():
        print(f'── {path.split("/")[-1]}')
        try:
            raw = open(path, 'rb').read().decode('utf-8')
        except FileNotFoundError:
            print('❌ 파일이 없어요 — 프로젝트 폴더(mp3_player_new)에서 실행해 주세요.'); return
        crlf = '\r\n' in raw
        s = raw.replace('\r\n', '\n')
        if 'heart_pop.dart' in s:
            print('이미 적용돼 있어요'); continue
        for name, alts in edits:
            done = False
            for old, new in alts:
                if new is None and path.endswith('radio_korea_screen2.dart'):
                    # 넓힌 모양이면 앞의 주석 줄까지 같이 바꾸기
                    if s.count(old) == 1:
                        s = s.replace(old, KOREA_NEW); done = True; break
                    continue
                if new is None:
                    if old in s: done = True; break   # 이미 돼 있음
                    continue
                if s.count(old) == 1:
                    s = s.replace(old, new); done = True; break
            if done: print(f'✔ {name}')
            else: print(f'❌ {name} — 자리를 못 찾았어요'); ok = False
        for o, c in ('{}', '()', '[]'):
            if (s.count(o) - s.count(c)) != (raw.count(o) - raw.count(c)):
                print(f'❌ 괄호 {o}{c} 가 안 맞아요'); ok = False
        out[path] = s.replace('\n', '\r\n') if crlf else s
    if not ok:
        print('아무것도 저장하지 않았어요.'); return
    for path, s in out.items():
        open(path, 'wb').write(s.encode('utf-8'))
    if not os.path.exists(NEW_FILE):
        open(NEW_FILE, 'wb').write(NEW_CODE.replace('\n', '\r\n').encode('utf-8'))
        print('✔ 새 파일 만들었어요: heart_pop.dart')
    print('저장했어요 ✔')

main()
