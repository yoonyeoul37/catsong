# 설정 '메인 알림 카드': [다시 보기] 버튼 → 설명 끝 '다시 보기 ›' (B안)
# 누르면 그 자리에 2초 동안 "카드를 다시 켰어요" + 효과음 (아래쪽 알림은 안 띄움)
import sys

S = "lib/screens/settings_screen.dart"

OLD_TILE = """          // 메인 홈 맨 위 카드 (나만의 색·라디오·팁) — 오늘 다 닫았으면 [다시 보기]
          ValueListenableBuilder<bool>(
            valueListenable: MainCardPref.on,
            builder: (context, on, _) => ValueListenableBuilder<bool>(
              valueListenable: MainCardPref.allClosedToday,
              builder: (context, allClosed, _) {
                final closed = on && allClosed;
                return _buildTile(context,
                    icon: Icons.campaign_outlined,
                    title: '메인 알림 카드',
                    desc: closed ? '오늘은 모두 닫았어요 · 내일 다시 나와요' : '메인 화면 맨 위에 방송 추천·팁을 보여줘요',
                    onTap: () => MainCardPref.setOn(!on),
                    primaryColor: primaryColor,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (closed)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
                              MainCardPref.reopenToday();
                              showParanToast(context, '메인 화면에 카드가 다시 나와요',
                                  duration: const Duration(milliseconds: 1500));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _sIconBg(isDarkMode),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('다시 보기',
                                  style: TextStyle(color: _sText(isDarkMode), fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        Switch(value: on, onChanged: (v) => MainCardPref.setOn(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ],
                    ));
              },
            ),
          ),
"""
NEW_TILE = """          // 메인 홈 맨 위 카드 (나만의 색·라디오·팁) — 오늘 다 닫았으면 설명 끝에 '다시 보기 ›'
          ValueListenableBuilder<bool>(
            valueListenable: MainCardPref.on,
            builder: (context, on, _) => ValueListenableBuilder<bool>(
              valueListenable: MainCardPref.allClosedToday,
              builder: (context, allClosed, _) {
                final closed = on && allClosed && !_mainReopened;
                final point = pointColorOf(context);
                const descStyle = TextStyle(fontSize: 11.5);
                Widget? descWidget;
                if (_mainReopened) {
                  // 누른 뒤 2초: 그 자리에서 바로 알려 주기
                  descWidget = Text('카드를 다시 켰어요',
                      maxLines: 1, style: descStyle.copyWith(color: point, fontWeight: FontWeight.w700));
                } else if (closed) {
                  descWidget = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _reopenMainCards,
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: '오늘은 모두 닫았어요 · '),
                        TextSpan(text: '다시 보기 ›', style: TextStyle(color: point, fontWeight: FontWeight.w700)),
                      ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: descStyle.copyWith(color: _sTextHint(isDarkMode)),
                    ),
                  );
                }
                return _buildTile(context,
                    icon: Icons.campaign_outlined,
                    title: '메인 알림 카드',
                    desc: '메인 화면 맨 위에 방송 추천·팁을 보여줘요',
                    descWidget: descWidget,
                    onTap: () => MainCardPref.setOn(!on),
                    primaryColor: primaryColor,
                    trailing: Switch(value: on, onChanged: (v) => MainCardPref.setOn(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap));
              },
            ),
          ),
"""

EDITS = [
    ("강조 색 불러오기",
     "import '../utils/home_card_pref.dart';\n",
     "import '../utils/home_card_pref.dart';\nimport '../utils/point_color.dart';\n"),
    ("다시 켠 뒤 2초 표시 상태",
     "  double _zoom = 1.0;\n",
     "  double _zoom = 1.0;\n  bool _mainReopened = false; // '다시 보기' 누른 뒤 2초 동안 \"카드를 다시 켰어요\"\n"),
    ("메인 알림 카드 줄 (B안)", OLD_TILE, NEW_TILE),
    ("다시 보기 누르면 (효과음 + 2초 표시)",
     "  // ───────── B안 부품 ─────────\n",
     """  /// '다시 보기 ›': 오늘 닫은 메인 알림 카드 다시 켜기 → 설명 자리에 2초 동안 "카드를 다시 켰어요"
  void _reopenMainCards() {
    // 효과음: 켜져 있으면 물방울 "똑" (진동 모드면 진동, 무음이면 조용) / 꺼져 있으면 터치 진동
    if (context.read<ThemeProvider>().feedbackSoundEnabled) {
      const MethodChannel('kr.ssing.catsong/media')
          .invokeMethod('feedbackSound', {'low': false})
          .catchError((Object _) => null);
    } else {
      const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');
    }
    MainCardPref.reopenToday();
    setState(() => _mainReopened = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mainReopened = false);
    });
  }

  // ───────── B안 부품 ─────────
"""),
    ("설정 줄: 설명 자리에 다른 글자도 넣을 수 있게 1",
     "    Widget? titleExtra, // 이름 바로 옆 (예: ⓘ)\n  }) {\n",
     "    Widget? titleExtra, // 이름 바로 옆 (예: ⓘ)\n    Widget? descWidget, // 설명 대신 보여 줄 것 (예: '다시 보기 ›')\n  }) {\n"),
    ("설정 줄: 설명 자리에 다른 글자도 넣을 수 있게 2",
     "                          const SizedBox(height: 2),\n                          Text(desc,\n",
     "                          const SizedBox(height: 2),\n                          descWidget ??\n                          Text(desc,\n"),
]

try:
    raw = open(S, "rb").read().decode("utf-8")
except FileNotFoundError:
    print(f"❌ 파일이 없어요 ({S})")
    sys.exit(1)
crlf = "\r\n" in raw
t = raw.replace("\r\n", "\n")

if "void _reopenMainCards()" in t:
    print("이미 적용돼 있어요")
    sys.exit(0)

ok = True
for label, old, new in EDITS:
    if t.count(old) == 1:
        t = t.replace(old, new)
        print(f"✔ {label}")
    else:
        print(f"❌ {label} 못 찾음")
        ok = False

if t.count("(") != t.count(")") or t.count("{") != t.count("}") or t.count("[") != t.count("]"):
    print("❌ 괄호 짝이 안 맞아요")
    ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if crlf:
    t = t.replace("\n", "\r\n")
open(S, "wb").write(t.encode("utf-8"))
print("완료")
