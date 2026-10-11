# -*- coding: utf-8 -*-
# 홈 오늘의 카드: 종류마다 작은 이름표 + 내용이 보이는 왼쪽 그림
import sys, glob, os, shutil

hits = [h for h in glob.glob(os.path.join('lib', '**', 'home_screen.dart'), recursive=True)
        if os.path.basename(h) == 'home_screen.dart']
if not hits:
    print('❌ home_screen.dart 파일을 못 찾았어요 (프로젝트 폴더에서 실행해 주세요)'); sys.exit(1)
path = hits[0]
raw = open(path, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')
if '_cardArt(' in s:
    print('✔ 이미 적용돼 있어요'); sys.exit(0)

edits = [
('곡 사진 칸 불러오기',
"import '../utils/paran_photo.dart';\n",
"import '../utils/paran_photo.dart';\nimport '../utils/no_album_helper.dart';\n"),
('이름표 · 그림 자리',
"    VoidCallback? onAction;\n",
"""    VoidCallback? onAction;
    late String label; // 제목 위 작은 이름표
    late Widget lead; // 왼쪽 그림
    // 이름표·막대 강조 색 (기본 파랑이면 로고와 같은 파랑)
    final point = context.read<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8
        ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
        : point;
    final softBox = isDark ? const Color(0xFF3A3631) : const Color(0x8CFFFFFF);
"""),
('① 오늘의 곡: 앨범 사진',
"      icon = Icons.album_outlined;\n",
"""      icon = Icons.album_outlined;
      label = '오늘의 곡';
      lead = _cardArt(s, 40, isDark);
"""),
('② 다시 듣기: 앨범 사진 3장 겹치기',
"      icon = Icons.history_rounded;\n",
"""      icon = Icons.history_rounded;
      label = '다시 듣기';
      lead = SizedBox(
        width: 50,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var k = 0; k < math.min(3, notPlayed.length); k++)
              Positioned(
                left: k * 7.0,
                top: 4,
                child: Transform.rotate(
                  angle: const [-8.0, -2.0, 5.0][k] * math.pi / 180,
                  child: _cardArt(notPlayed[k], 32, isDark),
                ),
              ),
          ],
        ),
      );
"""),
('③ 내 기록: 작은 막대그래프',
"      icon = Icons.bar_chart_rounded;\n",
"""      icon = Icons.bar_chart_rounded;
      label = '내 기록';
      lead = Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(color: softBox, borderRadius: BorderRadius.circular(9)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (k, hgt) in const [(0, 9.0), (1, 15.0), (2, 11.0), (3, 20.0), (4, 13.0)]) ...[
              if (k > 0) const SizedBox(width: 3),
              Container(
                width: 4,
                height: hgt,
                decoration: BoxDecoration(
                  color: k == 3 ? accent : ink.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      );
"""),
('④ 지금 이 시간: 자연 사진 동그라미',
"      icon = ic;\n",
"""      icon = ic;
      label = '지금 이 시간';
      const natureImg = {
        '새소리': 'assets/nature_bird_bg.png',
        '시냇물': 'assets/nature_stream_bg.png',
        '파도소리': 'assets/nature_wave_bg.png',
        '빗소리': 'assets/nature_rain_bg.png',
      };
      lead = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipOval(
          child: paranPhoto(
            natureImg[sound] ?? 'assets/nature_wave_bg.png',
            thumb: true,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            fallback: Container(color: softBox, child: Icon(ic, size: 18, color: ink)),
          ),
        ),
      );
"""),
('⑤ 내일 알람: 시각 숫자',
"      icon = Icons.alarm_rounded;\n",
"""      icon = Icons.alarm_rounded;
      label = '내일 알람';
      final hm = RegExp(r'\\d{1,2}:\\d{2}').firstMatch(alarmNext)?.group(0);
      lead = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: softBox, borderRadius: BorderRadius.circular(9)),
        child: hm == null
            ? Icon(Icons.alarm_rounded, size: 18, color: ink)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    child: Text(hm,
                        style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800, height: 1.0)),
                  ),
                  const SizedBox(height: 2),
                  Text(alarmNext.contains('내일') ? '내일' : '오늘',
                      style: TextStyle(color: sub, fontSize: 8.5, height: 1.0)),
                ],
              ),
      );
"""),
('⑥ TIP: 점선 네모 안 선 아이콘',
"      icon = tip.$1;\n",
"""      icon = tip.$1;
      label = 'TIP';
      lead = CustomPaint(
        painter: _DashedBoxPainter(ink.withOpacity(0.28)),
        child: SizedBox(width: 40, height: 40, child: Icon(tip.$1, size: 18, color: ink)),
      );
"""),
('왼쪽 동그라미 → 그림',
"""          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: ink),
          ),
          const SizedBox(width: 10),""",
"""          lead,
          const SizedBox(width: 12),"""),
('제목 위 이름표',
"""                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),""",
"""                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 1),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),"""),
('곡 사진 그리기',
"  Future<void> _closeDailyCard() async {",
"""  /// 오늘의 카드 왼쪽: 곡 앨범 사진 (없으면 글자 타일)
  Widget _cardArt(Song s, double size, bool isDark) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.18),
          child: s.albumArt != null
              ? Image.memory(Uint8List.fromList(s.albumArt!),
                  width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: (size * 3).round())
              : NoArtTile(title: s.titleDisplay, colorKey: s.uri ?? s.titleDisplay, size: size, isDark: isDark),
        ),
      );

  Future<void> _closeDailyCard() async {"""),
]
for label, old, new in edits:
    n = s.count(old)
    if n != 1:
        print(f'❌ [{label}] 찾을 곳이 {n}개예요. 아무것도 저장하지 않고 멈춰요.'); sys.exit(1)
    s = s.replace(old, new)
    print(f'✔ {label}')

s = s.rstrip('\n') + '''

/// 오늘의 카드 TIP 그림: 점선 네모
class _DashedBoxPainter extends CustomPainter {
  final Color color;
  _DashedBoxPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(9)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => old.color != color;
}
'''
print('✔ 점선 네모 그리기')

shutil.copy(path, path + '.bak_card')
if crlf: s = s.replace('\n', '\r\n')
open(path, 'wb').write(s.encode('utf-8'))
print('끝! (원본은 .bak_card)')
