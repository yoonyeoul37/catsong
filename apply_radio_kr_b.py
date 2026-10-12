# -*- coding: utf-8 -*-
# 한국 라디오 목록 새 디자인 (B안 1단계)
#  - 맨 위: 홈 같은 미니어처 사진 카드 '지금 듣기 좋은' + ▶ + 🎲(주사위)
#  - 방송사 칸: 회색 → 홈 파스텔 색 (KBS 하늘 · MBC 복숭아 · SBS 연두 · CBS 라벤더 · EBS 노랑)
#  - 방송 이름: 도현체 / 글자 줄이기: 프로그램이 있으면 주파수·시간 줄은 빼기
#  - 오른쪽 위 주사위 아이콘 빼기 (사진 카드 안으로 옮김)
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('radio_korea_screen2.dart')
if not path:
    print('❌ lib 폴더에서 radio_korea_screen2.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if '_nowNiceCard' in s:
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

HERO = r"""  // ───── 맨 위 사진 카드: 지금 듣기 좋은 방송 ─────
  /// ① 이 시간대(아침·낮·저녁·밤)에 들었던 방송 (최근 것부터)  ② 없으면 시간대별 기본
  /// 지금 듣고 있는 방송은 빼기
  int _pickNiceIndex(RadioProvider radio) {
    int slot(DateTime t) {
      final h = t.hour;
      if (h >= 5 && h < 11) return 0;
      if (h >= 11 && h < 17) return 1;
      if (h >= 17 && h < 22) return 2;
      return 3;
    }

    final s = slot(DateTime.now());
    final cur = radio.currentStation?.name;
    for (final r in radio.recentlyListened) {
      final t = r.lastListened;
      if (t == null || slot(t) != s || r.name == cur) continue;
      final i = koreanStations.indexWhere((k) => k.name == r.name);
      if (i >= 0) return i;
    }
    const defaults = [
      ['KBS 제1라디오', 'MBC 표준FM', 'SBS 러브FM'], // 아침: 뉴스·아침 방송
      ['MBC FM4U', 'KBS Cool FM', 'SBS 파워FM'], // 낮: 가요
      ['SBS 파워FM', 'KBS 해피FM', 'MBC FM4U'], // 저녁: 퇴근길 음악
      ['KBS Classic FM', 'CBS 음악FM', 'MBC 올댓뮤직'], // 밤: 잔잔한 음악
    ];
    for (final n in defaults[s]) {
      if (n == cur) continue;
      final i = koreanStations.indexWhere((k) => k.name == n);
      if (i >= 0) return i;
    }
    return 0;
  }

  Widget _nowNiceCard(BuildContext context, RadioProvider radio, List<RadioStation> list) {
    final i = _pickNiceIndex(radio);
    final ks = koreanStations[i];
    final prog = radio.nowPlayingFor(ks.name) ?? (radio.currentProgramFor(ks.name)?['title'] as String?) ?? '';
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    const ink = Color(0xFF17140F);
    void open() {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RadioPlayerScreen(station: list[i], stationList: list, currentIndex: i),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }

    return GestureDetector(
      onTap: open,
      child: Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 8),
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
              Image.asset(
                'assets/radio_bg.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.3),
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD5E1EC)),
              ),
              // 홈 카드와 같은 유리 띠
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.65))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('지금 듣기 좋은',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                            const SizedBox(height: 1),
                            Text(ks.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textScaler: TextScaler.noScaling,
                                style: GoogleFonts.doHyeon(color: ink, fontSize: 18)),
                            if (prog.isNotEmpty)
                              Text(prog,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(color: ink.withOpacity(0.62), fontSize: 12)),
                          ],
                        ),
                      ),
                      // 🎲 주사위 (오른쪽 위 아이콘을 여기로)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openDice,
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), shape: BoxShape.circle),
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
    );
  }

  Widget _buildAllList(BuildContext context, RadioProvider radioProvider) {
"""
rep('맨 위 사진 카드 만들기', "  Widget _buildAllList(BuildContext context, RadioProvider radioProvider) {\n", HERO)

rep('목록 맨 위에 사진 카드 넣기',
    "      itemCount: koreanStations.length,\n"
    "      separatorBuilder: (_, __) => _DialEffect(\n"
    "          child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),\n"
    "      itemBuilder: (context, i) {\n"
    "        final ks = koreanStations[i];\n",
    "      itemCount: koreanStations.length + 1,\n"
    "      separatorBuilder: (_, i) => i == 0\n"
    "          ? const SizedBox(height: 6)\n"
    "          : _DialEffect(\n"
    "              child: Divider(height: 1, color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1))),\n"
    "      itemBuilder: (context, n) {\n"
    "        if (n == 0) return _nowNiceCard(context, radioProvider, radioStations); // 맨 위 사진 카드\n"
    "        final i = n - 1;\n"
    "        final ks = koreanStations[i];\n")

rep('방송사 칸: 파스텔 색 + 도현체',
    "                decoration: BoxDecoration(\n"
    "                  color: isPlaying ? primaryColor : baseColor.withOpacity(0.08),\n"
    "                  borderRadius: BorderRadius.circular(10),\n"
    "                ),\n"
    "                alignment: Alignment.center,\n"
    "                child: Text(\n"
    "                  station.broadcaster,\n"
    "                  style: TextStyle(\n"
    "                    color: isPlaying ? Colors.black : baseColor.withOpacity(0.6),\n"
    "                    fontSize: 11,\n"
    "                    fontWeight: FontWeight.w700,\n"
    "                  ),\n",
    "                // 홈 '최근에 들었어요'와 같은 파스텔 (듣는 중이면 강조 색 테두리)\n"
    "                decoration: BoxDecoration(\n"
    "                  color: _brandPastel(station.broadcaster).withOpacity(isDarkMode ? 0.9 : 1),\n"
    "                  borderRadius: BorderRadius.circular(10),\n"
    "                  border: isPlaying ? Border.all(color: primaryColor, width: 2) : null,\n"
    "                ),\n"
    "                alignment: Alignment.center,\n"
    "                child: Text(\n"
    "                  station.broadcaster,\n"
    "                  textScaler: TextScaler.noScaling,\n"
    "                  style: GoogleFonts.doHyeon(\n"
    "                    color: const Color(0xFF17140F).withOpacity(0.8),\n"
    "                    fontSize: station.broadcaster.length > 3 ? 10.5 : 12.5,\n"
    "                  ),\n")

rep('방송 이름 도현체',
    "                    Text(\n"
    "                      station.name,\n"
    "                      style: TextStyle(\n"
    "                        color: isPlaying ? primaryColor : baseColor,\n"
    "                        fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,\n"
    "                        fontSize: 15.5,\n"
    "                        letterSpacing: -0.2,\n"
    "                      ),\n",
    "                    Text(\n"
    "                      station.name,\n"
    "                      style: GoogleFonts.doHyeon(\n"
    "                        color: isPlaying ? primaryColor : baseColor,\n"
    "                        fontSize: 16.5,\n"
    "                      ),\n")

rep('글자 줄이기: 프로그램이 있으면 주파수·시간 줄 빼기',
    "                            Text(\n"
    "                              [\n"
    "                                if (station.frequency.isNotEmpty) station.frequency,\n",
    "                            if (displayNowPlaying == null || displayNowPlaying.isEmpty)\n"
    "                            Text(\n"
    "                              [\n"
    "                                if (station.frequency.isNotEmpty) station.frequency,\n")

# 오른쪽 위 주사위 아이콘 빼기
a = s.find("          // 주사위: 음악 방송 하나를 골라 바로 틀기 (처음엔 NEW)\n          IconButton(\n")
b = s.find("          const SizedBox(width: 6),\n        ],\n        title: Row(", a if a >= 0 else 0)
if a >= 0 and b > a:
    s = s[:a] + "          // 주사위는 맨 위 사진 카드 안으로 옮김\n" + s[b:]
    print('✔ 오른쪽 위 주사위 아이콘 빼기')
else:
    print('❌ 오른쪽 위 주사위 아이콘 — 코드를 못 찾았어요')
    ok = False

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

s = s.rstrip('\n') + """

/// 방송사 파스텔 (홈 '최근에 들었어요'와 같은 색)
Color _brandPastel(String b) {
  switch (b) {
    case 'KBS':
      return const Color(0xFFD5E1EC); // 하늘
    case 'MBC':
      return const Color(0xFFF3D9C9); // 복숭아
    case 'SBS':
      return const Color(0xFFDCE5D2); // 연두
    case 'CBS':
      return const Color(0xFFDDD6E8); // 라벤더
    case 'EBS':
      return const Color(0xFFF0E3C2); // 노랑
    default:
      return const Color(0xFFE6DFD2); // 그 밖: 연한 베이지
  }
}
"""
print('✔ 방송사 파스텔 색 정하기')

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
