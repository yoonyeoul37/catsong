# -*- coding: utf-8 -*-
# 자연 화면 전체 탭 맨 위: 라디오와 같은 '지금 듣기 좋은' 사진 카드
import os, sys

PATH = os.path.join('lib', 'screens', 'nature_sounds_screen.dart')

METHODS = r'''  /// 지금 시간에 어울리는 소리: 아침 새소리 · 낮 시냇물 · 저녁 모닥불 · 밤 빗소리
  _NatureSound? _niceSoundNow() {
    final h = DateTime.now().hour;
    final cat = (h >= 5 && h < 11)
        ? '새소리'
        : (h >= 11 && h < 17)
            ? '시냇물'
            : (h >= 17 && h < 22)
                ? '모닥불'
                : '빗소리';
    final ready = _sounds.where((s) => s.isReady).toList();
    if (ready.isEmpty) return null;
    return ready.firstWhere((s) => s.category == cat, orElse: () => ready.first);
  }

  /// 전체 탭 맨 위 사진 카드 (라디오 '지금 듣기 좋은' 카드와 같은 모양)
  Widget _natureNiceCard(_NatureSound s, Color soundColor, void Function(_NatureSound, Color) open,
      PlayerProvider pp, bool isDark) {
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8 ? const Color(0xFF2F7DE8) : point;
    const ink = Color(0xFF17140F);
    final playingThis = pp.natureSoundName == s.name && pp.isPlaying;
    return GestureDetector(
      onTap: () => open(s, soundColor),
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
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
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 68, // 사진은 글자 띠 위에만
                // 다크 모드: 라디오 카드와 같게 색 반쯤 빼고 살짝 어둡게
                child: ColorFiltered(
                  colorFilter: isDark
                      ? const ColorFilter.matrix(<double>[
                          0.4082, 0.2832, 0.0286, 0, 0,
                          0.0842, 0.6072, 0.0286, 0, 0,
                          0.0842, 0.2832, 0.3526, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: paranPhoto(
                    _natureThumbImage(s.name, s.category, s.assetPath ?? ''),
                    fit: BoxFit.cover,
                    fallback: Container(color: soundColor),
                  ),
                ),
              ),
              // 사진 아래 크림 띠 (라디오 카드와 같은 색)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
                  decoration: const BoxDecoration(color: Color(0xFFFBF8F2)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr.niceNow,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                            const SizedBox(height: 1),
                            Text(natureName(s.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            Text(natureDesc(s.name, s.description),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(color: ink.withOpacity(0.62), fontSize: 12)),
                          ],
                        ),
                      ),
                      // ▶ 바로 듣기 (라디오 주사위 자리 · 같은 베이지 동그라미)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggleSound(s, playingThis),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Color(0xFFEDE7DA), shape: BoxShape.circle),
                          child: Icon(playingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: ink, size: 22),
                        ),
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

  /// 전체 탭 묶음 제목:'''

EDITS = [
    ('지금 듣기 좋은 카드 만들기', "  /// 전체 탭 묶음 제목:", METHODS),
    (
        '전체 탭 맨 위에 카드 넣기',
        "              final rows = <Widget>[];\n",
        "              final rows = <Widget>[];\n"
        "              // 전체 탭 맨 위: 지금 듣기 좋은 사진 카드 (라디오와 같음)\n"
        "              if (showTitles) {\n"
        "                final nice = _niceSoundNow();\n"
        "                if (nice != null) {\n"
        "                  rows.add(_natureNiceCard(nice, soundColors[nice.category] ?? primaryColor, openVariant,\n"
        "                      playerProvider, isDarkMode));\n"
        "                }\n"
        "              }\n",
    ),
]


def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH)
        sys.exit(1)
    with open(PATH, 'rb') as f:
        raw = f.read().decode('utf-8')
    crlf = '\r\n' in raw
    text = raw.replace('\r\n', '\n')

    if '_natureNiceCard(' in text:
        print('이미 적용돼 있어요')
        return
    if '_natureTab(' not in text:
        print('❌ apply_nature_radio_style.py 를 먼저 돌려 주세요. 아무것도 저장 안 했어요')
        sys.exit(1)

    for name, old, new in EDITS:
        n = text.count(old)
        if n != 1:
            print('❌', name, '(찾은 개수: %d) — 아무것도 저장 안 했어요' % n)
            sys.exit(1)
        text = text.replace(old, new)
        print('✔', name)

    if crlf:
        text = text.replace('\n', '\r\n')
    with open(PATH, 'wb') as f:
        f.write(text.encode('utf-8'))
    print('✔ 저장했어요:', PATH)


main()
