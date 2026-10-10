# -*- coding: utf-8 -*-
# 설정: 빠른 카드 흰색 + ⓘ 넓은 설명(✕로 닫기, 큰 글자) + 톡 소리 + 포인트 색 설명
# (예전 apply_settings_bubble.py 를 돌렸어도, 안 돌렸어도 둘 다 돼요)
import os, sys

PATH = os.path.join('lib', 'screens', 'settings_screen.dart')
if not os.path.exists(PATH):
    for root, _, files in os.walk('lib'):
        if 'settings_screen.dart' in files:
            PATH = os.path.join(root, 'settings_screen.dart'); break

raw = open(PATH, 'rb').read().decode('utf-8')
crlf = '\r\n' in raw
src = raw.replace('\r\n', '\n')

if '_pointInfoItems' in src:
    print('이미 적용돼 있어요'); sys.exit(0)

V1_CODE = 'ok = True\n\n# 1) 빠른 카드 3칸 + 설명 창 → 통째로 새것\nSTART = \'  /// 자주 켜고 끄는 3칸 (누르면 바로 켜짐/꺼짐, 켜지면 카드 전체 먹색 · ⓘ 누르면 설명)\'\nEND = \'  /// 포인트 색: 이름 + 아래 동그라미 10개\'\nNEW_TILES = r\'\'\'  /// 자주 켜고 끄는 3칸 (흰 카드, 켜지면 아이콘 칸만 먹색 · ⓘ 누르면 아래 말풍선)\n  Widget _quickTiles(ThemeProvider t) {\n    final d = t.isDarkMode;\n    Widget tile(IconData icon, String label, String info, bool on, VoidCallback onTap) {\n      final key = _infoKeys.putIfAbsent(label, () => GlobalKey());\n      return Expanded(\n        child: GestureDetector(\n          onTap: () {\n            const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n            _hideBubble();\n            onTap();\n          },\n          child: Container(\n            padding: const EdgeInsets.fromLTRB(12, 12, 6, 11),\n            decoration: BoxDecoration(color: _sCard(d), borderRadius: BorderRadius.circular(16)),\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Row(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    // 켜지면 아이콘 칸만 먹색 (다크 모드는 크림색)\n                    AnimatedContainer(\n                      duration: const Duration(milliseconds: 180),\n                      width: 30,\n                      height: 30,\n                      decoration: BoxDecoration(\n                        color: on ? _sText(d) : _sIconBg(d),\n                        borderRadius: BorderRadius.circular(9),\n                      ),\n                      child: Icon(icon, size: 16, color: on ? _sBg(d) : _sTextSub(d)),\n                    ),\n                    const Spacer(),\n                    // ⓘ 누르면 카드 아래 작은 말풍선\n                    GestureDetector(\n                      behavior: HitTestBehavior.opaque,\n                      onTap: () => _showBubble(key, info, d),\n                      child: Padding(\n                        padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),\n                        child: Icon(Icons.info_outline_rounded, key: key, size: 16, color: _sTextHint(d)),\n                      ),\n                    ),\n                  ],\n                ),\n                const SizedBox(height: 8),\n                Text(label,\n                    maxLines: 1,\n                    overflow: TextOverflow.ellipsis,\n                    style: TextStyle(color: _sText(d), fontSize: 13, fontWeight: FontWeight.w600)),\n                const SizedBox(height: 2),\n                Text(on ? \'사용 중\' : \'꺼짐\',\n                    style: TextStyle(\n                        color: on ? _sText(d) : _sTextHint(d),\n                        fontSize: 11,\n                        fontWeight: on ? FontWeight.w700 : FontWeight.w400)),\n              ],\n            ),\n          ),\n        ),\n      );\n    }\n\n    return Padding(\n      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),\n      child: Row(\n        children: [\n          tile(Icons.dark_mode_outlined, \'다크 모드\', \'화면을 어둡게 바꿔요. 밤에 눈이 편해요.\', t.isDarkMode,\n              () => t.setDarkMode(!t.isDarkMode)),\n          const SizedBox(width: 8),\n          tile(\n              Icons.water_drop_outlined,\n              \'효과음\',\n              \'수정·저장·삭제가 끝나면 물방울 소리로 알려줘요. 진동 모드면 진동, 무음이면 조용해요.\',\n              t.feedbackSoundEnabled,\n              () => t.setFeedbackSoundEnabled(!t.feedbackSoundEnabled)),\n          const SizedBox(width: 8),\n          tile(Icons.record_voice_over_outlined, \'음성 안내\', \'앱을 켜고 끌 때 짧은 인사말이 나와요.\', t.voiceGreetingEnabled,\n              () => t.setVoiceGreetingEnabled(!t.voiceGreetingEnabled)),\n        ],\n      ),\n    );\n  }\n\n  // ───────── ⓘ 말풍선 ─────────\n  final Map<String, GlobalKey> _infoKeys = {};\n  OverlayEntry? _bubble;\n  final GlobalKey<_InfoBubbleState> _bubbleKey = GlobalKey();\n\n  void _removeBubbleNow() {\n    _bubble?.remove();\n    _bubble = null;\n  }\n\n  /// 말풍선 닫기 (스르르)\n  void _hideBubble() {\n    final s = _bubbleKey.currentState;\n    if (s != null) {\n      s.close();\n    } else {\n      _removeBubbleNow();\n    }\n  }\n\n  /// ⓘ 바로 아래에 먹색 말풍선 (꼬리는 ⓘ를 가리킴) · 3초 뒤 / 다른 곳 누르면 사라짐\n  void _showBubble(GlobalKey iconKey, String text, bool d, {double width = 230}) {\n    final box = iconKey.currentContext?.findRenderObject();\n    final overlay = Overlay.maybeOf(context);\n    if (box is! RenderBox || overlay == null) return;\n    final ovBox = overlay.context.findRenderObject() as RenderBox;\n    final iconPos = box.localToGlobal(Offset.zero, ancestor: ovBox);\n    final iconCx = iconPos.dx + box.size.width / 2;\n    final screenW = ovBox.size.width;\n    final w = width.clamp(0.0, screenW - 32).toDouble();\n    final left = (iconCx - w / 2).clamp(16.0, screenW - 16 - w).toDouble();\n    // 카드 아랫부분 아래로 (ⓘ는 카드 위쪽에 있어서 카드 높이만큼 내려줌)\n    final cardBox = _cardBoxOf(box);\n    final cardBottom = cardBox != null\n        ? cardBox.localToGlobal(Offset(0, cardBox.size.height), ancestor: ovBox).dy\n        : iconPos.dy + box.size.height;\n    final top = cardBottom + 8;\n\n    // 소리: 효과음 켜져 있으면 톡 (폰이 진동 모드면 진동, 무음이면 조용) / 꺼져 있으면 평소 터치 진동\n    final soundOn = context.read<ThemeProvider>().feedbackSoundEnabled;\n    if (soundOn) {\n      const MethodChannel(\'kr.ssing.catsong/media\')\n          .invokeMethod(\'feedbackSound\', {\'low\': false})\n          .catchError((Object _) => null);\n    } else {\n      const MethodChannel(\'kr.ssing.catsong/media\').invokeMethod(\'vibrate\');\n    }\n\n    _removeBubbleNow();\n    _bubble = OverlayEntry(\n      builder: (_) => Stack(\n        children: [\n          // 다른 곳을 누르면 닫기 (누른 건 그대로 아래로 전달)\n          Positioned.fill(\n            child: Listener(\n              behavior: HitTestBehavior.translucent,\n              onPointerDown: (_) => _hideBubble(),\n            ),\n          ),\n          Positioned(\n            left: left,\n            top: top,\n            width: w,\n            child: IgnorePointer(\n              child: _InfoBubble(\n                key: _bubbleKey,\n                text: text,\n                tailX: iconCx - left,\n                isDark: d,\n                onClosed: _removeBubbleNow,\n              ),\n            ),\n          ),\n        ],\n      ),\n    );\n    overlay.insert(_bubble!);\n  }\n\n  /// ⓘ를 감싼 카드(위쪽으로 처음 만나는 꾸민 상자)\n  RenderBox? _cardBoxOf(RenderBox icon) {\n    RenderObject? r = icon.parent;\n    var depth = 0;\n    while (r != null && depth < 30) {\n      if (r is RenderDecoratedBox) {\n        final dec = r.decoration;\n        if (dec is BoxDecoration && dec.borderRadius != null && r.size.width > 60) return r;\n      }\n      r = r.parent;\n      depth++;\n    }\n    return null;\n  }\n\n\'\'\'\n\ni = src.find(START); j = src.find(END)\nif i != -1 and j != -1 and i < j:\n    src = src[:i] + NEW_TILES + src[j:]\n    print(\'✔ 빠른 카드 흰색으로 + ⓘ 말풍선\')\nelse:\n    ok = False; print(\'❌ 빠른 카드 부분을 못 찾음\')\n\nedits = []\n\n# 2) 포인트 색 줄: 회색 설명 + ⓘ\nedits.append((\'포인트 색 설명 + ⓘ\', \'\'\'          Row(\n            children: [\n              _iconBox(Icons.palette_outlined, d),\n              const SizedBox(width: 12),\n              Expanded(child: Text(\'포인트 색\', style: TextStyle(color: _sText(d), fontSize: 14.5))),\n              Text(t.pointColorName ?? \'\', style: TextStyle(color: _sTextHint(d), fontSize: 12.5)),\n            ],\n          ),\'\'\', \'\'\'          Row(\n            children: [\n              _iconBox(Icons.palette_outlined, d),\n              const SizedBox(width: 12),\n              Expanded(\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  mainAxisSize: MainAxisSize.min,\n                  children: [\n                    Row(\n                      children: [\n                        Text(\'포인트 색\', style: TextStyle(color: _sText(d), fontSize: 14.5)),\n                        // ⓘ 누르면 바뀌는 곳 말풍선\n                        GestureDetector(\n                          behavior: HitTestBehavior.opaque,\n                          onTap: () => _showBubble(_pointInfoKey, _pointInfoText, d, width: 290),\n                          child: Padding(\n                            padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),\n                            child: Icon(Icons.info_outline_rounded, key: _pointInfoKey, size: 16, color: _sTextHint(d)),\n                          ),\n                        ),\n                      ],\n                    ),\n                    Text(\'재생 중 표시·막대·스위치 같은 작은 곳의 색\',\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: TextStyle(color: _sTextHint(d), fontSize: 11.5)),\n                  ],\n                ),\n              ),\n              Text(t.pointColorName ?? \'\', style: TextStyle(color: _sTextHint(d), fontSize: 12.5)),\n            ],\n          ),\'\'\'))\n\nedits.append((\'포인트 색 설명 글\', \'\'\'  /// 포인트 색: 이름 + 아래 동그라미 10개 (누르면 바로 바뀜, 폰 크기에 맞춰 한 줄)\n  Widget _pointColorTile(ThemeProvider t) {\'\'\', \'\'\'  final GlobalKey _pointInfoKey = GlobalKey();\n  static const String _pointInfoText = \'포인트 색이 바뀌는 곳\\\\n\'\n      \'· 음악: 재생 중인 곡 표시, 오른쪽 초성 글자\\\\n\'\n      \'· 재생 화면: 진행 막대, 시디롬 빛 번짐\\\\n\'\n      \'· 가사: 지금 부르는 줄, 진행 막대\\\\n\'\n      \'· 라디오: 주파수 바늘·눈금, 재생 중 표시\\\\n\'\n      \'· 자연·믹스: 소리 막대, 선택 표시, 수면 타이머\\\\n\'\n      \'· 동영상: 진행 표시, 반복·체크 표시\\\\n\'\n      \'· 그 밖에: 스위치, 체크, 알림, 이퀄라이저, 알람\\\\n\'\n      \'큰 버튼과 앱 아이콘은 바뀌지 않아요.\';\n\n  /// 포인트 색: 이름 + 아래 동그라미 10개 (누르면 바로 바뀜, 폰 크기에 맞춰 한 줄)\n  Widget _pointColorTile(ThemeProvider t) {\'\'\'))\n\n# 3) 화면 나갈 때 말풍선 지우기\nedits.append((\'나갈 때 말풍선 지우기\', \'\'\'  void dispose() {\n    _isSosOn = false;\'\'\', \'\'\'  void dispose() {\n    _removeBubbleNow();\n    _isSosOn = false;\'\'\'))\n\n# 4) 스크롤하면 말풍선 닫기\nedits.append((\'스크롤하면 닫기\', \'\'\'        child: ListView(\n        padding: const EdgeInsets.only(bottom: 16),\'\'\', \'\'\'        child: NotificationListener<ScrollStartNotification>(\n        onNotification: (_) {\n          _hideBubble();\n          return false;\n        },\n        child: ListView(\n        padding: const EdgeInsets.only(bottom: 16),\'\'\'))\n\nedits.append((\'스크롤 감싸기 닫기\', \'\'\'          Center(child: Text(\'KNEXM.Co.,LTD\', style: TextStyle(color: Colors.grey[400], fontSize: 12))),\n          const SizedBox(height: 8),\n        ],\n      ),\n      ),\'\'\', \'\'\'          Center(child: Text(\'KNEXM.Co.,LTD\', style: TextStyle(color: Colors.grey[400], fontSize: 12))),\n          const SizedBox(height: 8),\n        ],\n      ),\n      ),\n      ),\'\'\'))\n\nfor name, old, new in edits:\n    n = src.count(old)\n    if n == 1:\n        src = src.replace(old, new); print(\'✔\', name)\n    else:\n        ok = False; print(\'❌\', name, \'(못 찾음)\' if n == 0 else f\'({n}곳)\')\n\nNEW_CLASS = r\'\'\'\n\n/// 먹색 말풍선 (다크 모드는 크림색) · 위쪽 꼬리 · 3초 뒤 스르르\nclass _InfoBubble extends StatefulWidget {\n  final String text;\n  final double tailX;\n  final bool isDark;\n  final VoidCallback onClosed;\n  const _InfoBubble({super.key, required this.text, required this.tailX, required this.isDark, required this.onClosed});\n\n  @override\n  State<_InfoBubble> createState() => _InfoBubbleState();\n}\n\nclass _InfoBubbleState extends State<_InfoBubble> with SingleTickerProviderStateMixin {\n  late final AnimationController _c =\n      AnimationController(vsync: this, duration: const Duration(milliseconds: 200));\n  Timer? _timer;\n  bool _closing = false;\n\n  @override\n  void initState() {\n    super.initState();\n    _c.forward();\n    _timer = Timer(const Duration(seconds: 3), close);\n  }\n\n  void close() {\n    if (_closing || !mounted) return;\n    _closing = true;\n    _timer?.cancel();\n    _c.reverse().whenComplete(widget.onClosed);\n  }\n\n  @override\n  void dispose() {\n    _timer?.cancel();\n    _c.dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final bg = widget.isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);\n    final fg = widget.isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);\n    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);\n    return FadeTransition(\n      opacity: curve,\n      child: SlideTransition(\n        position: Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero).animate(curve),\n        child: Material(\n          type: MaterialType.transparency,\n          child: Stack(\n            clipBehavior: Clip.none,\n            children: [\n              // 꼬리 (ⓘ 쪽을 가리킴)\n              Positioned(\n                top: -5,\n                left: (widget.tailX - 6).clamp(12.0, double.infinity).toDouble(),\n                child: Transform.rotate(\n                  angle: 0.785398,\n                  child: Container(\n                    width: 12,\n                    height: 12,\n                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),\n                  ),\n                ),\n              ),\n              Container(\n                padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),\n                decoration: BoxDecoration(\n                  color: bg,\n                  borderRadius: BorderRadius.circular(12),\n                  boxShadow: [\n                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8)),\n                  ],\n                ),\n                child: Text(widget.text, style: TextStyle(color: fg, fontSize: 12.5, height: 1.6)),\n              ),\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}\n\'\'\'\n\nif ok:\n    src = src.rstrip(\'\\n\') + \'\\n\' + NEW_CLASS\n    if "import \'dart:async\';" not in src:\n        src = "import \'dart:async\';\\n" + src\n        print(\'✔ dart:async 추가\')\n    if "package:flutter/rendering.dart" not in src:\n        src = src.replace("import \'package:flutter/material.dart\';\\n",\n                          "import \'package:flutter/material.dart\';\\nimport \'package:flutter/rendering.dart\';\\n", 1)\n        print(\'✔ rendering 추가\')\n    for a, b in (\'()\', \'[]\', \'{}\'):\n        if src.count(a) != src.count(b):\n            ok = False; print(\'❌ 괄호 개수가 안 맞아요\', a, b)\n\n'

ok = True
if 'class _InfoBubble extends StatefulWidget' not in src:
    ns = {'src': src, 'sys': sys}
    exec(V1_CODE, ns)
    src, ok = ns['src'], ns['ok']
else:
    print('✔ 1차(말풍선)는 이미 들어가 있어요 → 2차만 고쳐요')


# ───── 2차: 넓은 설명 · ✕로 닫기 · 큰 글자 · 점 색 = 포인트 색 ─────
up = []

S1 = '  // ───────── ⓘ 말풍선 ─────────'
E1 = '  /// ⓘ를 감싼 카드'
NEW_SHOW = r'''  // ───────── ⓘ 설명 (넓은 먹색 칸 · ✕로 닫기) ─────────
  final Map<String, GlobalKey> _infoKeys = {};
  OverlayEntry? _bubble;
  GlobalKey? _bubbleFor;
  final GlobalKey<_InfoBubbleState> _bubbleKey = GlobalKey();

  void _removeBubbleNow() {
    _bubble?.remove();
    _bubble = null;
    _bubbleFor = null;
  }

  /// 설명 닫기 (스르르)
  void _hideBubble() {
    final s = _bubbleKey.currentState;
    if (s != null) {
      s.close();
    } else {
      _removeBubbleNow();
    }
  }

  /// ⓘ 누르면 카드 아래에 넓은 설명 (꼬리는 ⓘ를 가리킴)
  /// 저절로 안 사라지고 ✕ · 다른 곳 누르기 · 스크롤로 닫힘 / 같은 ⓘ 다시 누르면 닫힘
  void _showBubble(GlobalKey iconKey, bool d,
      {String? title, String? text, List<(String, String)>? items, String? foot, bool keepOpenOnCard = false}) {
    if (_bubble != null && identical(_bubbleFor, iconKey)) {
      _hideBubble();
      return;
    }
    final box = iconKey.currentContext?.findRenderObject();
    final overlay = Overlay.maybeOf(context);
    if (box is! RenderBox || overlay == null) return;
    final ovBox = overlay.context.findRenderObject() as RenderBox;
    final iconPos = box.localToGlobal(Offset.zero, ancestor: ovBox);
    final iconCx = iconPos.dx + box.size.width / 2;
    final w = ovBox.size.width - 32;
    final cardBox = _cardBoxOf(box);
    final cardRect = cardBox != null ? cardBox.localToGlobal(Offset.zero, ancestor: ovBox) & cardBox.size : null;
    final top = (cardRect?.bottom ?? iconPos.dy + box.size.height) + 10;

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
    _bubbleFor = iconKey;
    _bubble = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 다른 곳을 누르면 닫기 (누른 건 그대로 아래로 전달)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                // 포인트 색 카드 안(동그라미)은 눌러도 열어 둠 → 바꿔 보며 비교
                if (keepOpenOnCard && cardRect != null && cardRect.contains(ovBox.globalToLocal(e.position))) return;
                _hideBubble();
              },
            ),
          ),
          Positioned(
            left: 16,
            top: top,
            width: w,
            child: _InfoBubble(
              key: _bubbleKey,
              title: title,
              text: text,
              items: items,
              foot: foot,
              tailX: iconCx - 16,
              isDark: d,
              onClose: _hideBubble,
              onClosed: _removeBubbleNow,
            ),
          ),
        ],
      ),
    );
    overlay.insert(_bubble!);
  }

'''
i = src.find(S1); j = src.find(E1)
if i != -1 and j != -1 and i < j:
    src = src[:i] + NEW_SHOW + src[j:]; print('✔ 설명 칸: 넓게 · ✕로 닫기')
else:
    ok = False; print('❌ 설명 칸 부분을 못 찾음')

up.append(('카드 ⓘ 연결', '''onTap: () => _showBubble(key, info, d),''', '''onTap: () => _showBubble(key, d, text: info),'''))
up.append(('포인트 색 ⓘ 연결', '''onTap: () => _showBubble(_pointInfoKey, _pointInfoText, d, width: 290),''',
           '''onTap: () => _showBubble(_pointInfoKey, d,
                              title: '포인트 색이 바뀌는 곳',
                              items: _pointInfoItems,
                              foot: '큰 버튼과 앱 아이콘은 바뀌지 않아요',
                              keepOpenOnCard: true),'''))
up.append(('포인트 색 바뀌는 곳 목록', '''  static const String _pointInfoText = '포인트 색이 바뀌는 곳\\n'
      '· 음악: 재생 중인 곡 표시, 오른쪽 초성 글자\\n'
      '· 재생 화면: 진행 막대, 시디롬 빛 번짐\\n'
      '· 가사: 지금 부르는 줄, 진행 막대\\n'
      '· 라디오: 주파수 바늘·눈금, 재생 중 표시\\n'
      '· 자연·믹스: 소리 막대, 선택 표시, 수면 타이머\\n'
      '· 동영상: 진행 표시, 반복·체크 표시\\n'
      '· 그 밖에: 스위치, 체크, 알림, 이퀄라이저, 알람\\n'
      '큰 버튼과 앱 아이콘은 바뀌지 않아요.';''', '''  static const List<(String, String)> _pointInfoItems = [
    ('음악', '재생 중인 곡 표시, 오른쪽 초성 글자'),
    ('재생 화면', '진행 막대, 시디롬 빛 번짐'),
    ('가사', '지금 부르는 줄, 진행 막대'),
    ('라디오', '주파수 바늘·눈금, 재생 중 표시'),
    ('자연·믹스', '소리 막대, 선택 표시, 수면 타이머'),
    ('동영상', '진행 표시, 반복·체크 표시'),
    ('그 밖에', '스위치, 체크, 알림, 이퀄라이저, 알람'),
  ];'''))

for name, old, new in up:
    n = src.count(old)
    if n == 1:
        src = src.replace(old, new); print('✔', name)
    else:
        ok = False; print('❌', name, '(못 찾음)' if n == 0 else f'({n}곳)')

S2 = '/// 먹색 말풍선 (다크 모드는 크림색) · 위쪽 꼬리 · 3초 뒤 스르르'
NEW_CLASS2 = r'''/// 넓은 먹색 설명 (다크 모드는 크림색) · 위쪽 꼬리 · ✕로 닫기
class _InfoBubble extends StatefulWidget {
  final String? title;
  final String? text;
  final List<(String, String)>? items;
  final String? foot;
  final double tailX;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onClosed;
  const _InfoBubble({
    super.key,
    this.title,
    this.text,
    this.items,
    this.foot,
    required this.tailX,
    required this.isDark,
    required this.onClose,
    required this.onClosed,
  });

  @override
  State<_InfoBubble> createState() => _InfoBubbleState();
}

class _InfoBubbleState extends State<_InfoBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  void close() {
    if (_closing || !mounted) return;
    _closing = true;
    _c.reverse().whenComplete(widget.onClosed);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFFF3EFE7) : const Color(0xFF17140F);
    final fg = widget.isDark ? const Color(0xFF24221F) : const Color(0xFFF4EFE5);
    final point = context.watch<ThemeProvider>().primaryColor; // 점 = 지금 포인트 색
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    final head = widget.title ?? widget.text ?? '';
    final items = widget.items ?? const <(String, String)>[];
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.03), end: Offset.zero).animate(curve),
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 꼬리 (ⓘ 쪽을 가리킴)
              Positioned(
                top: -6,
                left: (widget.tailX - 6.5).clamp(14.0, double.infinity).toDouble(),
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              head,
                              style: widget.title != null
                                  ? TextStyle(color: fg, fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.3)
                                  : TextStyle(color: fg, fontSize: 14, height: 1.55),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ✕ 닫기
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onClose,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(color: fg.withOpacity(0.12), shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, size: 19, color: fg),
                          ),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) Container(height: 1, margin: const EdgeInsets.only(right: 6), color: fg.withOpacity(0.12)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 7, 6, 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(color: point, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(text: items[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const TextSpan(text: '  '),
                                    TextSpan(text: items[i].$2, style: TextStyle(color: fg.withOpacity(0.75))),
                                  ]),
                                  style: TextStyle(color: fg, fontSize: 14, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (widget.foot != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: fg.withOpacity(0.65)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(widget.foot!,
                                style: TextStyle(color: fg.withOpacity(0.65), fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'''
k = src.find(S2)
if k != -1:
    src = src[:k] + NEW_CLASS2; print('✔ 설명 칸 모양 (큰 글자 · ✕ · 점)')
else:
    ok = False; print('❌ 말풍선 모양 부분을 못 찾음')

if ok and 'Timer' not in src and src.startswith("import 'dart:async';\n"):
    src = src[len("import 'dart:async';\n"):]  # 이제 안 써서 빼기

if ok:
    for a, b in ('()', '[]', '{}'):
        if src.count(a) != src.count(b):
            ok = False; print('❌ 괄호 개수가 안 맞아요', a, b)

if not ok:
    print('\n하나라도 실패해서 저장 안 했어요.'); sys.exit(1)

out = src.replace('\n', '\r\n') if crlf else src
open(PATH, 'wb').write(out.encode('utf-8'))
print('\n저장했어요:', PATH)
