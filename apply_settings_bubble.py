# -*- coding: utf-8 -*-
# 설정: 빠른 카드 흰색으로 되돌리기 + ⓘ 말풍선(3초) + 톡 소리 + 포인트 색 설명
import os, sys

PATH = os.path.join('lib', 'screens', 'settings_screen.dart')
if not os.path.exists(PATH):
    for root, _, files in os.walk('lib'):
        if 'settings_screen.dart' in files:
            PATH = os.path.join(root, 'settings_screen.dart'); break

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if 'class _InfoBubble extends StatefulWidget' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

ok = True

# 1) 빠른 카드 3칸 + 설명 창 → 통째로 새것
START = '  /// 자주 켜고 끄는 3칸 (누르면 바로 켜짐/꺼짐, 켜지면 카드 전체 먹색 · ⓘ 누르면 설명)'
END = '  /// 포인트 색: 이름 + 아래 동그라미 10개'
NEW_TILES = r'''  /// 자주 켜고 끄는 3칸 (흰 카드, 켜지면 아이콘 칸만 먹색 · ⓘ 누르면 아래 말풍선)
  Widget _quickTiles(ThemeProvider t) {
    final d = t.isDarkMode;
    Widget tile(IconData icon, String label, String info, bool on, VoidCallback onTap) {
      final key = _infoKeys.putIfAbsent(label, () => GlobalKey());
      return Expanded(
        child: GestureDetector(
          onTap: () {
            const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
            _hideBubble();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 11),
            decoration: BoxDecoration(color: _sCard(d), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 켜지면 아이콘 칸만 먹색 (다크 모드는 크림색)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: on ? _sText(d) : _sIconBg(d),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 16, color: on ? _sBg(d) : _sTextSub(d)),
                    ),
                    const Spacer(),
                    // ⓘ 누르면 카드 아래 작은 말풍선
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showBubble(key, info, d),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
                        child: Icon(Icons.info_outline_rounded, key: key, size: 16, color: _sTextHint(d)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _sText(d), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(on ? '사용 중' : '꺼짐',
                    style: TextStyle(
                        color: on ? _sText(d) : _sTextHint(d),
                        fontSize: 11,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          tile(Icons.dark_mode_outlined, '다크 모드', '화면을 어둡게 바꿔요. 밤에 눈이 편해요.', t.isDarkMode,
              () => t.setDarkMode(!t.isDarkMode)),
          const SizedBox(width: 8),
          tile(
              Icons.water_drop_outlined,
              '효과음',
              '수정·저장·삭제가 끝나면 물방울 소리로 알려줘요. 진동 모드면 진동, 무음이면 조용해요.',
              t.feedbackSoundEnabled,
              () => t.setFeedbackSoundEnabled(!t.feedbackSoundEnabled)),
          const SizedBox(width: 8),
          tile(Icons.record_voice_over_outlined, '음성 안내', '앱을 켜고 끌 때 짧은 인사말이 나와요.', t.voiceGreetingEnabled,
              () => t.setVoiceGreetingEnabled(!t.voiceGreetingEnabled)),
        ],
      ),
    );
  }

  // ───────── ⓘ 말풍선 ─────────
  final Map<String, GlobalKey> _infoKeys = {};
  OverlayEntry? _bubble;
  final GlobalKey<_InfoBubbleState> _bubbleKey = GlobalKey();

  void _removeBubbleNow() {
    _bubble?.remove();
    _bubble = null;
  }

  /// 말풍선 닫기 (스르르)
  void _hideBubble() {
    final s = _bubbleKey.currentState;
    if (s != null) {
      s.close();
    } else {
      _removeBubbleNow();
    }
  }

  /// ⓘ 바로 아래에 먹색 말풍선 (꼬리는 ⓘ를 가리킴) · 3초 뒤 / 다른 곳 누르면 사라짐
  void _showBubble(GlobalKey iconKey, String text, bool d, {double width = 230}) {
    final box = iconKey.currentContext?.findRenderObject();
    final overlay = Overlay.maybeOf(context);
    if (box is! RenderBox || overlay == null) return;
    final ovBox = overlay.context.findRenderObject() as RenderBox;
    final iconPos = box.localToGlobal(Offset.zero, ancestor: ovBox);
    final iconCx = iconPos.dx + box.size.width / 2;
    final screenW = ovBox.size.width;
    final w = width.clamp(0.0, screenW - 32).toDouble();
    final left = (iconCx - w / 2).clamp(16.0, screenW - 16 - w).toDouble();
    // 카드 아랫부분 아래로 (ⓘ는 카드 위쪽에 있어서 카드 높이만큼 내려줌)
    final cardBox = _cardBoxOf(box);
    final cardBottom = cardBox != null
        ? cardBox.localToGlobal(Offset(0, cardBox.size.height), ancestor: ovBox).dy
        : iconPos.dy + box.size.height;
    final top = cardBottom + 8;

    // 소리: 효과음 켜져 있으면 톡 (폰이 진동 모드면 진동, 무음이면 조용) / 꺼져 있으면 평소 터치 진동
    final soundOn = context.read<ThemeProvider>().feedbackSoundEnabled;
    if (soundOn) {
      const MethodChannel('kr.ssing.catsong/media')
          .invokeMethod('feedbackSound', {'low': false})
          .catchError((Object _) => null);
    } else {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    }

    _removeBubbleNow();
    _bubble = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 다른 곳을 누르면 닫기 (누른 건 그대로 아래로 전달)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _hideBubble(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: w,
            child: IgnorePointer(
              child: _InfoBubble(
                key: _bubbleKey,
                text: text,
                tailX: iconCx - left,
                isDark: d,
                onClosed: _removeBubbleNow,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_bubble!);
  }

  /// ⓘ를 감싼 카드(위쪽으로 처음 만나는 꾸민 상자)
  RenderBox? _cardBoxOf(RenderBox icon) {
    RenderObject? r = icon.parent;
    var depth = 0;
    while (r != null && depth < 30) {
      if (r is RenderDecoratedBox) {
        final dec = r.decoration;
        if (dec is BoxDecoration && dec.borderRadius != null && r.size.width > 60) return r;
      }
      r = r.parent;
      depth++;
    }
    return null;
  }

'''

i = src.find(START); j = src.find(END)
if i != -1 and j != -1 and i < j:
    src = src[:i] + NEW_TILES + src[j:]
    print('✔ 빠른 카드 흰색으로 + ⓘ 말풍선')
else:
    ok = False; print('❌ 빠른 카드 부분을 못 찾음')

edits = []

# 2) 포인트 색 줄: 회색 설명 + ⓘ
edits.append(('포인트 색 설명 + ⓘ', '''          Row(
            children: [
              _iconBox(Icons.palette_outlined, d),
              const SizedBox(width: 12),
              Expanded(child: Text('포인트 색', style: TextStyle(color: _sText(d), fontSize: 14.5))),
              Text(t.pointColorName ?? '', style: TextStyle(color: _sTextHint(d), fontSize: 12.5)),
            ],
          ),''', '''          Row(
            children: [
              _iconBox(Icons.palette_outlined, d),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('포인트 색', style: TextStyle(color: _sText(d), fontSize: 14.5)),
                        // ⓘ 누르면 바뀌는 곳 말풍선
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showBubble(_pointInfoKey, _pointInfoText, d, width: 290),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
                            child: Icon(Icons.info_outline_rounded, key: _pointInfoKey, size: 16, color: _sTextHint(d)),
                          ),
                        ),
                      ],
                    ),
                    Text('재생 중 표시·막대·스위치 같은 작은 곳의 색',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _sTextHint(d), fontSize: 11.5)),
                  ],
                ),
              ),
              Text(t.pointColorName ?? '', style: TextStyle(color: _sTextHint(d), fontSize: 12.5)),
            ],
          ),'''))

edits.append(('포인트 색 설명 글', '''  /// 포인트 색: 이름 + 아래 동그라미 10개 (누르면 바로 바뀜, 폰 크기에 맞춰 한 줄)
  Widget _pointColorTile(ThemeProvider t) {''', '''  final GlobalKey _pointInfoKey = GlobalKey();
  static const String _pointInfoText = '포인트 색이 바뀌는 곳\\n'
      '· 음악: 재생 중인 곡 표시, 오른쪽 초성 글자\\n'
      '· 재생 화면: 진행 막대, 시디롬 빛 번짐\\n'
      '· 가사: 지금 부르는 줄, 진행 막대\\n'
      '· 라디오: 주파수 바늘·눈금, 재생 중 표시\\n'
      '· 자연·믹스: 소리 막대, 선택 표시, 수면 타이머\\n'
      '· 동영상: 진행 표시, 반복·체크 표시\\n'
      '· 그 밖에: 스위치, 체크, 알림, 이퀄라이저, 알람\\n'
      '큰 버튼과 앱 아이콘은 바뀌지 않아요.';

  /// 포인트 색: 이름 + 아래 동그라미 10개 (누르면 바로 바뀜, 폰 크기에 맞춰 한 줄)
  Widget _pointColorTile(ThemeProvider t) {'''))

# 3) 화면 나갈 때 말풍선 지우기
edits.append(('나갈 때 말풍선 지우기', '''  void dispose() {
    _isSosOn = false;''', '''  void dispose() {
    _removeBubbleNow();
    _isSosOn = false;'''))

# 4) 스크롤하면 말풍선 닫기
edits.append(('스크롤하면 닫기', '''        child: ListView(
        padding: const EdgeInsets.only(bottom: 16),''', '''        child: NotificationListener<ScrollStartNotification>(
        onNotification: (_) {
          _hideBubble();
          return false;
        },
        child: ListView(
        padding: const EdgeInsets.only(bottom: 16),'''))

edits.append(('스크롤 감싸기 닫기', '''          Center(child: Text('KNEXM.Co.,LTD', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
          const SizedBox(height: 8),
        ],
      ),
      ),''', '''          Center(child: Text('KNEXM.Co.,LTD', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
          const SizedBox(height: 8),
        ],
      ),
      ),
      ),'''))

for name, old, new in edits:
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

NEW_CLASS = r'''

/// 먹색 말풍선 (다크 모드는 크림색) · 위쪽 꼬리 · 3초 뒤 스르르
class _InfoBubble extends StatefulWidget {
  final String text;
  final double tailX;
  final bool isDark;
  final VoidCallback onClosed;
  const _InfoBubble({super.key, required this.text, required this.tailX, required this.isDark, required this.onClosed});

  @override
  State<_InfoBubble> createState() => _InfoBubbleState();
}

class _InfoBubbleState extends State<_InfoBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(seconds: 3), close);
  }

  void close() {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    _c.reverse().whenComplete(widget.onClosed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = widget.isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero).animate(curve),
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 꼬리 (ⓘ 쪽을 가리킴)
              Positioned(
                top: -5,
                left: (widget.tailX - 6).clamp(12.0, double.infinity).toDouble(),
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Text(widget.text, style: TextStyle(color: fg, fontSize: 12.5, height: 1.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'''

if ok:
    src = src.rstrip('\n') + '\n' + NEW_CLASS
    if "import 'dart:async';" not in src:
        src = "import 'dart:async';\n" + src
        print('✔ dart:async 추가')
    if "package:flutter/rendering.dart" not in src:
        src = src.replace("import 'package:flutter/material.dart';\n",
                          "import 'package:flutter/material.dart';\nimport 'package:flutter/rendering.dart';\n", 1)
        print('✔ rendering 추가')
    for a, b in ('()', '[]', '{}'):
        if src.count(a) != src.count(b):
            ok = False; print('❌ 괄호 개수가 안 맞아요', a, b)

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
