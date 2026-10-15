# 알림 카드 ✕를 오른쪽 위로 + 카드 아래 점 (메인 홈) / 곡 목록 위 카드 ✕도 오른쪽 위로 / 미니플레이어 ✕ 모양 맞추기
import re, sys

H = "lib/screens/home_screen.dart"
MINIS = ["lib/widgets/radio_mini_player.dart", "lib/widgets/nature_mini_player.dart", "lib/widgets/sound_mix_mini_player.dart"]

FUNCS = "  Widget _buildHomeCard(bool isDark) {\n    if (!MainCardPref.on.value) return const SizedBox.shrink(); // 설정에서 끔\n    final isKo = Localizations.localeOf(context).languageCode == 'ko';\n    final card = isDark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);\n    final now = DateTime.now();\n    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024, 1, 1)).inDays;\n\n    // 라디오 추천: 안 들어 본 방송 (아래 '최근에 들었어요'와 안 겹치게) — 국내 방송이라 한국어일 때만\n    final radio = context.watch<RadioProvider>();\n    final cur = radio.currentStation?.name;\n    final pick = isKo\n        ? niceKoreanStationNow(skip: {for (final r in radio.recentlyListened) r.name, if (cur != null) cur}, day: day)\n        : null;\n\n    // 오늘 카드 차례 (점 개수 = 오늘 카드 수 · 닫은 카드도 점 자리는 그대로)\n    final deck = <String>[\n      if (_showColorTip || _homeClosed.contains('color')) 'color',\n      if (pick != null) 'radio',\n      'tip',\n    ];\n    final open = deck.where((k) => k == 'color' ? _showColorTip : !_homeClosed.contains(k)).toList();\n    if (open.isEmpty) return const SizedBox.shrink(); // 다 닫으면 오늘은 카드 없음 (내일 다시 처음부터)\n    final key = open.first;\n    final dot = deck.indexOf(key);\n    final dots = deck.length;\n\n    // ① 나만의 색 (나오는 조건은 예전 그대로)\n    if (key == 'color') return _buildColorTip(isDark, dot: dot, dots: dots);\n\n    // ② 이런 방송은 어때요?\n    if (key == 'radio' && pick != null) {\n      final s = pick;\n      _askProgram(radio, s);\n      final p = radio.currentProgramFor(s.name);\n      final prog = (radio.nowPlayingFor(s.name) ?? p?['program_title'] ?? p?['title'] ?? '').toString().trim();\n      final h = now.hour;\n      final mood = (h >= 5 && h < 11)\n          ? '아침을 여는 방송이에요'\n          : (h >= 11 && h < 17)\n              ? '낮에 듣기 좋은 방송이에요'\n              : (h >= 17 && h < 22)\n                  ? '저녁에 듣기 좋은 방송이에요'\n                  : '밤에 듣기 좋은 잔잔한 방송이에요';\n      return _homeInfoCard(\n        isDark: isDark,\n        lead: _LiveBadge(hole: card),\n        label: '이런 방송은 어때요?',\n        title: s.name,\n        sub: prog.isNotEmpty ? '지금 · $prog' : mood,\n        action: '듣기',\n        onAction: () => Navigator.push(\n          context,\n          MaterialPageRoute(builder: (_) => RadioPlayerScreen(station: s, openedFromList: false)),\n        ),\n        onClose: () => _closeHomeCard('radio'),\n        dot: dot,\n        dots: dots,\n      );\n    }\n\n    // ③ 오늘의 팁 (하루에 하나씩)\n    final i = day % _mainTips.length;\n    final t = _mainTips[i];\n    return _homeInfoCard(\n      isDark: isDark,\n      lead: _TipBadge(hole: card),\n      label: isKo ? '오늘의 팁' : 'TIP',\n      title: isKo ? t.$1 : t.$3,\n      sub: isKo ? t.$2 : t.$4,\n      action: i == 1 ? (isKo ? '설정' : 'Set') : null,\n      onAction: i == 1\n          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmScreen()))\n          : null,\n      onClose: () => _closeHomeCard('tip'),\n      dot: dot,\n      dots: dots,\n    );\n  }\n\n  /// 카드 오른쪽 위 작은 ✕ (보이는 건 작게, 누르는 자리는 넉넉하게) — 알림 카드 모두 같은 모양\n  Widget _cardCloseX(Color color, VoidCallback onTap) => GestureDetector(\n        behavior: HitTestBehavior.opaque,\n        onTap: onTap,\n        child: SizedBox(\n          width: 32,\n          height: 32,\n          child: Icon(Icons.close_rounded, size: 15, color: color),\n        ),\n      );\n\n  /// 카드 아래 작은 점 (지금 카드는 길쭉하게)\n  Widget _cardDots(int index, int count, Color on, Color off) => Row(\n        mainAxisSize: MainAxisSize.min,\n        children: [\n          for (var k = 0; k < count; k++) ...[\n            if (k > 0) const SizedBox(width: 4),\n            AnimatedContainer(\n              duration: const Duration(milliseconds: 250),\n              width: k == index ? 12 : 5,\n              height: 5,\n              decoration: BoxDecoration(\n                color: k == index ? on : off,\n                borderRadius: BorderRadius.circular(3),\n              ),\n            ),\n          ],\n        ],\n      );\n\n  /// 메인 홈 카드 모양 (✕는 오른쪽 위, 점은 가운데 아래)\n  Widget _homeInfoCard({\n    required bool isDark,\n    required Widget lead,\n    required String label,\n    required String title,\n    required String sub,\n    String? action,\n    VoidCallback? onAction,\n    VoidCallback? onClose,\n    int dot = 0,\n    int dots = 1,\n  }) {\n    final card = isDark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);\n    final ink = isDark ? const Color(0xFFF4EFE5) : const Color(0xFF17140F);\n    final subC = isDark ? const Color(0xFFA29A8B) : const Color(0xFF746C60);\n    final point = context.watch<ThemeProvider>().primaryColor;\n    final accent = _readable(\n        point.value == 0xFF2589E8\n            ? (isDark ? const Color(0xFF6FB0FF) : const Color(0xFF2F7DE8))\n            : point,\n        isDark);\n    final showDots = dots > 1;\n    return Container(\n      margin: const EdgeInsets.only(bottom: 16),\n      decoration: BoxDecoration(\n        color: card,\n        borderRadius: BorderRadius.circular(10),\n        boxShadow: [\n          BoxShadow(\n            color: const Color(0xFF17140F).withOpacity(isDark ? 0.4 : 0.10),\n            blurRadius: 16,\n            spreadRadius: -3,\n            offset: const Offset(0, 6),\n          ),\n          BoxShadow(\n            color: const Color(0xFF17140F).withOpacity(0.05),\n            blurRadius: 3,\n            offset: const Offset(0, 1),\n          ),\n        ],\n      ),\n      // ✕·점이 카드 안쪽에 있어야 눌려서: 여백은 글자 줄에만 주고 ✕·점은 카드 모서리 기준으로\n      child: Stack(\n        children: [\n          Padding(\n            padding: EdgeInsets.fromLTRB(14, 14, onClose == null ? 14 : 34, showDots ? 18 : 14),\n            child: Row(\n            children: [\n              Container(\n                width: 40,\n                height: 40,\n                decoration: BoxDecoration(\n                  shape: BoxShape.circle,\n                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],\n                ),\n                child: lead,\n              ),\n              const SizedBox(width: 12),\n              Expanded(\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  mainAxisSize: MainAxisSize.min,\n                  children: [\n                    Text(label,\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: TextStyle(color: accent, fontSize: 10, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: 0.6)),\n                    const SizedBox(height: 2),\n                    Text(title,\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: TextStyle(color: ink, fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w700)),\n                    const SizedBox(height: 3),\n                    Text(sub,\n                        maxLines: 1,\n                        overflow: TextOverflow.ellipsis,\n                        style: TextStyle(color: subC, fontSize: 11.5, height: 1.15)),\n                  ],\n                ),\n              ),\n              if (action != null && onAction != null) ...[\n                const SizedBox(width: 8),\n                GestureDetector(\n                  onTap: () {\n                    const MethodChannel('kr.ssing.catsong/media').invokeMethod('vibrate');\n                    onAction();\n                  },\n                  child: Container(\n                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),\n                    decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),\n                    child: Text(action, style: TextStyle(color: card, fontSize: 12.5, fontWeight: FontWeight.w700)),\n                  ),\n                ),\n              ],\n            ],\n          ),\n          ),\n          // ✕ 오른쪽 위 모서리\n          if (onClose != null)\n            Positioned(top: 2, right: 2, child: _cardCloseX(subC, onClose)),\n          // 점: 카드 아래 가운데\n          if (showDots)\n            Positioned(\n              left: 0,\n              right: 0,\n              bottom: 6,\n              child: Center(child: _cardDots(dot, dots, accent, subC.withOpacity(0.35))),\n            ),\n        ],\n      ),\n    );\n  }\n\n  /// 나만의 색 카드 (메인 홈 카드와 같은 모양 · 색 고리 + [꾸미기])\n  Widget _buildColorTip(bool isDark, {int dot = 0, int dots = 1}) {\n    final isKo = Localizations.localeOf(context).languageCode == 'ko';\n    final card = isDark ? const Color(0xFF32302C) : const Color(0xFFFBF8F2);\n    return _homeInfoCard(\n      isDark: isDark,\n      lead: _SpinRing(hole: card),\n      label: isKo ? '강조 색상' : 'Accent color',\n      title: isKo ? '나만의 색으로 꾸며보세요' : 'Make it your color',\n      sub: isKo ? '숲 · 노을 · 벚꽃 등 10가지 색' : '10 colors like Forest, Sunset, Blossom',\n      action: isKo ? '꾸미기' : 'Try it',\n      onAction: _openColorSheet,\n      onClose: () {\n        _finishColorTip();\n        _closeHomeCard('color');\n      },\n      dot: dot,\n      dots: dots,\n    );\n  }\n\n"

DAILY_A_OLD = ("      margin: const EdgeInsets.only(bottom: 4),\n"
               "      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),\n"
               "      decoration: BoxDecoration(color: card),\n"
               "      child: AnimatedOpacity(\n")
DAILY_A_NEW = ("      margin: const EdgeInsets.only(bottom: 4),\n"
               "      decoration: BoxDecoration(color: card),\n"
               "      // ✕가 카드 안쪽에 있어야 눌려서: 여백은 글자 줄에만\n"
               "      child: Stack(\n"
               "        children: [\n"
               "      Padding(\n"
               "        padding: const EdgeInsets.fromLTRB(20, 10, 34, 10),\n"
               "        child: AnimatedOpacity(\n")
DAILY_B_OLD = ("          // ✕ = 오늘만 숨기기\n"
               "          IconButton(\n"
               "            onPressed: _closeDailyCard,\n"
               "            icon: Icon(Icons.close_rounded, color: sub, size: 17),\n"
               "            padding: EdgeInsets.zero,\n"
               "            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),\n"
               "          ),\n"
               "        ],\n"
               "      ),\n"
               "      ),\n"
               "    );\n")
DAILY_B_NEW = ("        ],\n"
               "      ),\n"
               "      ),\n"
               "      ),\n"
               "          // ✕ = 오늘만 숨기기 (오른쪽 위 모서리 · 메인 홈 카드와 같은 모양)\n"
               "          Positioned(top: 0, right: 2, child: _cardCloseX(sub, _closeDailyCard)),\n"
               "        ],\n"
               "      ),\n"
               "    );\n")
MINI_OLD = "Icon(Icons.close, color: baseColor.withOpacity(0.45))"
MINI_NEW = "Icon(Icons.close_rounded, color: baseColor.withOpacity(0.45))"

def load(path):
    try:
        raw = open(path, "rb").read().decode("utf-8")
    except FileNotFoundError:
        print(f"❌ 파일이 없어요 ({path})")
        return None
    return [raw.replace("\r\n", "\n"), "\r\n" in raw]

files = {}
for p in [H] + MINIS:
    f = load(p)
    if f is None:
        print("❌ 아무것도 저장 안 했어요.")
        sys.exit(1)
    files[p] = f

h = files[H][0]
if "_buildHomeCard" not in h or "niceKoreanStationNow" not in h:
    print("❌ 먼저 apply_home_cards.py → apply_home_cards_nodate.py → apply_home_radio_setting.py 를 돌려 주세요. 아무것도 저장 안 했어요.")
    sys.exit(1)

ok = True
todo = 0

# 메인 홈 카드 (✕ 오른쪽 위 + 점)
if "Widget _cardCloseX(" in h:
    print("· 메인 홈 카드 이미 적용돼 있어요")
else:
    h2, n = re.subn(r"  Widget _buildHomeCard\(bool isDark\) \{\n.*?(?=  /// 홈에서 바로 색 고르기)", lambda m: FUNCS, h, count=1, flags=re.S)
    if n == 1:
        h = h2
        todo += 1
        print("✔ 메인 홈 카드: ✕ 오른쪽 위 + 아래 점 (나만의 색 카드도 같은 모양)")
    else:
        print("❌ 메인 홈 카드 자리 못 찾음")
        ok = False

# 곡 목록 위 카드
if "_cardCloseX(sub, _closeDailyCard)" in h:
    print("· 곡 목록 위 카드 이미 적용돼 있어요")
elif h.count(DAILY_A_OLD) == 1 and h.count(DAILY_B_OLD) == 1:
    h = h.replace(DAILY_A_OLD, DAILY_A_NEW).replace(DAILY_B_OLD, DAILY_B_NEW)
    todo += 1
    print("✔ 곡 목록 위 카드: ✕ 오른쪽 위로")
else:
    print("❌ 곡 목록 위 카드 자리 못 찾음")
    ok = False
files[H][0] = h

# 미니플레이어 ✕ 모양
for p in MINIS:
    t = files[p][0]
    name = p.split("/")[-1]
    if MINI_NEW in t and MINI_OLD not in t:
        print(f"· {name} 이미 적용돼 있어요")
    elif t.count(MINI_OLD) == 1:
        files[p][0] = t.replace(MINI_OLD, MINI_NEW)
        todo += 1
        print(f"✔ {name}: ✕ 모양 맞추기")
    else:
        print(f"❌ {name}: ✕ 못 찾음")
        ok = False

for p, (t, _) in files.items():
    if t.count("(") != t.count(")") or t.count("{") != t.count("}") or t.count("[") != t.count("]"):
        print(f"❌ {p} 괄호 짝이 안 맞아요")
        ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)
if todo == 0:
    print("이미 적용돼 있어요")
    sys.exit(0)
for p, (t, crlf) in files.items():
    if crlf:
        t = t.replace("\n", "\r\n")
    open(p, "wb").write(t.encode("utf-8"))
print("완료")
