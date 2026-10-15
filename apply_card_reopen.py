# 설정 '메인 알림 카드': 오늘 카드를 다 닫았으면 "오늘은 모두 닫았어요" + [다시 보기] 버튼 (스위치는 켜짐 그대로)
import sys

H = "lib/screens/home_screen.dart"
S = "lib/screens/settings_screen.dart"
P = "lib/utils/home_card_pref.dart"

P_OLD = """  static Future<void> setOn(bool v) async {
    on.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('mainCardOn', v);
    if (v) {
      // 다시 켜면 오늘 닫은 카드와 나만의 색 카드도 다시 나오게
      await p.remove('main_card_closed_day');
      await p.remove('main_card_closed');
      await p.remove('color_tip_hide_until');
      await p.remove('color_tip_closed');
      await p.remove('color_tip_done');
      reopened.value++;
    }
  }
}"""
P_NEW = """  static Future<void> setOn(bool v) async {
    on.value = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('mainCardOn', v);
    if (v) await reopenToday(); // 다시 켜면 닫은 카드도 다시
  }

  /// 오늘 카드를 다 닫았는지 (홈 화면이 알려 줌 → 설정에 [다시 보기])
  static final allClosedToday = ValueNotifier<bool>(false);

  /// [다시 보기]: 오늘 닫은 카드와 나만의 색 카드 다시 나오게 (스위치는 그대로)
  static Future<void> reopenToday() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('main_card_closed_day');
    await p.remove('main_card_closed');
    await p.remove('color_tip_hide_until');
    await p.remove('color_tip_closed');
    await p.remove('color_tip_done');
    allClosedToday.value = false;
    reopened.value++;
  }
}"""

H_OLD = "    if (open.isEmpty) return const SizedBox.shrink(); // 다 닫으면 오늘은 카드 없음 (내일 다시 처음부터)\n"
H_NEW = ("    // 다 닫았는지 설정 화면에 알려 주기 (그리는 중엔 못 바꿔서 그린 다음에)\n"
         "    final allClosed = open.isEmpty;\n"
         "    if (MainCardPref.allClosedToday.value != allClosed) {\n"
         "      WidgetsBinding.instance.addPostFrameCallback((_) => MainCardPref.allClosedToday.value = allClosed);\n"
         "    }\n"
         + H_OLD)

S_OLD = """          // 메인 홈 맨 위 카드 (나만의 색·라디오·팁) — 다시 켜면 닫은 카드도 다시 나와요
          ValueListenableBuilder<bool>(
            valueListenable: MainCardPref.on,
            builder: (context, on, _) => _buildTile(context,
                icon: Icons.campaign_outlined,
                title: '메인 알림 카드',
                desc: '메인 화면 맨 위 카드예요. 다시 켜면 닫은 카드도 나와요',
                onTap: () => MainCardPref.setOn(!on),
                primaryColor: primaryColor,
                trailing: Switch(value: on, onChanged: (v) => MainCardPref.setOn(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          ),
"""
S_NEW = """          // 메인 홈 맨 위 카드 (나만의 색·라디오·팁) — 오늘 다 닫았으면 [다시 보기]
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

def load(path):
    try:
        raw = open(path, "rb").read().decode("utf-8")
    except FileNotFoundError:
        print(f"❌ 파일이 없어요 ({path})")
        return None
    return [raw.replace("\r\n", "\n"), "\r\n" in raw]

files = {}
for p in (H, S, P):
    f = load(p)
    if f is None:
        print("❌ 아무것도 저장 안 했어요.")
        sys.exit(1)
    files[p] = f

JOBS = [
    (P, "켜짐 저장: 다 닫았는지 + 다시 보기", P_OLD, P_NEW, "static Future<void> reopenToday()"),
    (H, "홈: 다 닫으면 설정에 알려 주기", H_OLD, H_NEW, "MainCardPref.allClosedToday.value = allClosed"),
    (S, "설정: [다시 보기] 버튼", S_OLD, S_NEW, "MainCardPref.reopenToday();"),
]

ok = True
todo = 0
for path, label, old, new, mark in JOBS:
    t = files[path][0]
    if mark in t:
        print(f"· {label} 이미 적용돼 있어요")
    elif t.count(old) == 1:
        files[path][0] = t.replace(old, new)
        todo += 1
        print(f"✔ {label}")
    else:
        print(f"❌ {label} 못 찾음")
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
