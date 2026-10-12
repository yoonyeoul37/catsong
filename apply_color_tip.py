# -*- coding: utf-8 -*-
# 홈: 강조 색상 안내 카드 (앱을 3번째 켤 때부터 딱 한 번)
#  - 로고 아래, '이런 소리는 어때요?' 위 / 크림 카드 + 색 고리 + [바꾸기] + ✕
#  - [바꾸기] → 홈에서 바로 색 고르는 창 (누르면 즉시 바뀜, [완료]로 닫기)
#  - [바꾸기]·✕를 누르거나, 이미 색을 바꾼 사람은 다시 안 나옴
import os, sys, shutil

def find_file(name):
    for root, _, files in os.walk('lib'):
        if name in files:
            return os.path.join(root, name)
    return None

path = find_file('home_screen.dart')
if not path:
    print('❌ lib 폴더에서 home_screen.dart를 못 찾았어요. 프로젝트 폴더에서 실행해 주세요.')
    sys.exit(1)
with open(path, 'rb') as f:
    raw = f.read().decode('utf-8')
crlf = '\r\n' in raw
s = raw.replace('\r\n', '\n')

if '_showColorTip' in s:
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

rep('안내 카드 기억 칸·보여줄지 정하기',
    "  bool _showThemeHint = false;\n",
    r"""  bool _showThemeHint = false;

  // ───── 강조 색상 안내 카드: 앱을 3번째 켤 때부터 딱 한 번 ─────
  bool _showColorTip = false;
  static bool _launchCounted = false; // 앱 한 번 켤 때 한 번만 세기

  Future<void> _checkColorTip() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('color_tip_done') ?? false) return;
    var n = prefs.getInt('app_launch_count') ?? 0;
    if (!_launchCounted) {
      _launchCounted = true;
      n++;
      await prefs.setInt('app_launch_count', n);
    }
    if (!mounted) return;
    // 이미 색을 바꾼 사람은 알고 있으니 안 보여줌
    if (context.read<ThemeProvider>().primaryColor.value != 0xFF2589E8) {
      await prefs.setBool('color_tip_done', true);
      return;
    }
    if (n >= 3) setState(() => _showColorTip = true);
  }

  /// [바꾸기]·✕ 누르면 끝 (다시 안 나옴)
  Future<void> _finishColorTip() async {
    if (mounted) setState(() => _showColorTip = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('color_tip_done', true);
  }

  /// 크림 카드 + 색 고리 + 문구 + [바꾸기] + ✕ (홈 사진 카드와 같은 모서리·그림자)
  Widget _buildColorTip(bool isDark) {
    final card = isDark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);
    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);
    final sub = isDark ? const Color(0xFFA29A8B) : const Color(0xFF746C60);
    final point = context.watch<ThemeProvider>().primaryColor;
    final accent = point.value == 0xFF2589E8
        ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))
        : point;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17140F).withOpacity(isDark ? 0.4 : 0.10),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF17140F).withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 색 고리 (강조 색상 10가지)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: CustomPaint(painter: _ColorRingPainter(hole: card)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('꾸미기',
                    maxLines: 1,
                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 1),
                Text('앱 색을 바꿔보세요',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('10가지 색 중에 골라요',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: sub, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
              _openColorSheet();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
              child: Text('바꾸기', style: TextStyle(color: card, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
          IconButton(
            onPressed: _finishColorTip,
            icon: Icon(Icons.close_rounded, color: sub, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
    );
  }

  /// 홈에서 바로 색 고르기: 누르면 즉시 바뀌고 창은 열린 채로 (여러 색 비교) → [완료]
  Future<void> _openColorSheet() async {
    final t = context.read<ThemeProvider>();
    final dark = t.isDarkMode;
    final ink = dark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final sub = dark ? const Color(0xFFB8B0A2) : const Color(0xFF8A8378);
    final sheetBg = dark ? const Color(0xFF32302C) : const Color(0xFFF4EFE5);
    await showParanSheet(
      context,
      title: '강조 색상',
      builder: (ctx, setSheet) {
        Widget dot(int i) {
          final (name, c) = ThemeProvider.pointColors[i];
          final on = t.primaryColor.value == c.value;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                t.setPrimaryColor(c);
                setSheet(() {});
              },
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    padding: on ? const EdgeInsets.all(3) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? sheetBg : c,
                      border: on ? Border.all(color: ink, width: 2) : null,
                    ),
                    child: on ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c)) : null,
                  ),
                  const SizedBox(height: 6),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: on ? ink : sub,
                          fontSize: 11.5,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            ),
          );
        }

        final n = ThemeProvider.pointColors.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Text('누르면 바로 바뀌어요 · 설정에서 언제든 다시 바꿀 수 있어요',
                  style: TextStyle(color: sub, fontSize: 12.5)),
            ),
            for (var row = 0; row * 5 < n; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    for (var i = row * 5; i < row * 5 + 5; i++)
                      if (i < n) dot(i) else const Expanded(child: SizedBox()),
                  ],
                ),
              ),
          ],
        );
      },
      footer: (ctx, setSheet) => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: sheetBg,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('완료', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
        ),
      ),
    );
    _finishColorTip();
  }
""")

rep('앱 켤 때 안내 카드 확인',
    "      await _checkThemeHint();\n",
    "      await _checkThemeHint();\n"
    "      await _checkColorTip();\n")

rep("홈: '이런 소리는 어때요?' 위에 안내 카드",
    "        crossAxisAlignment: CrossAxisAlignment.start,\n"
    "        children: [\n"
    "          Row(\n"
    "            children: [\n"
    "              Icon(Icons.tune_rounded, size: 18, color: baseColor.withOpacity(0.7)),\n",
    "        crossAxisAlignment: CrossAxisAlignment.start,\n"
    "        children: [\n"
    "          if (_showColorTip) _buildColorTip(isDarkMode),\n"
    "          Row(\n"
    "            children: [\n"
    "              Icon(Icons.tune_rounded, size: 18, color: baseColor.withOpacity(0.7)),\n")

if not ok:
    print('하나라도 못 찾아서 아무것도 저장 안 했어요.')
    sys.exit(1)

s = s.rstrip('\n') + r"""

/// 강조 색상 10가지를 한 바퀴로 (가운데는 카드 색 구멍)
class _ColorRingPainter extends CustomPainter {
  final Color hole;
  const _ColorRingPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [for (final c in ThemeProvider.pointColors) c.$2];
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: r);
    final sweep = 2 * math.pi / colors.length;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * sweep, sweep + 0.01, true, Paint()..color = colors[i]);
    }
    canvas.drawCircle(center, r * 0.46, Paint()..color = hole);
  }

  @override
  bool shouldRepaint(covariant _ColorRingPainter old) => old.hole != hole;
}
"""
print('✔ 색 고리 그리기')

shutil.copy(path, path + '.bak')
if crlf:
    s = s.replace('\n', '\r\n')
with open(path, 'wb') as f:
    f.write(s.encode('utf-8'))
print('저장했어요:', path)
