# 메인 홈 카드: 라디오 카드는 '안 들어 본 방송 추천'으로 + 설정에 '메인 알림 카드' 켜기/끄기
# (아래 '최근에 들었어요'와 안 겹치게 / 국내 방송이라 한국어일 때만 / 다시 켜면 닫은 카드도 다시 나옴)
import re, sys

H = "lib/screens/home_screen.dart"
R = "lib/screens/radio_korea_screen2.dart"
S = "lib/screens/settings_screen.dart"
P = "lib/utils/home_card_pref.dart"

RADIO_BLOCK = "    // ② 라디오: 안 들어 본 방송 추천 (아래 '최근에 들었어요'와 안 겹치게) — 국내 방송이라 한국어일 때만\n    final radio = context.watch<RadioProvider>();\n    final cur = radio.currentStation?.name;\n    final pick = (isKo && !_homeClosed.contains('radio'))\n        ? niceKoreanStationNow(skip: {for (final r in radio.recentlyListened) r.name, if (cur != null) cur}, day: day)\n        : null;\n    if (pick != null) {\n      final s = pick;\n      _askProgram(radio, s);\n      final p = radio.currentProgramFor(s.name);\n      final prog = (radio.nowPlayingFor(s.name) ?? p?['program_title'] ?? p?['title'] ?? '').toString().trim();\n      final h = now.hour;\n      final mood = (h >= 5 && h < 11)\n          ? '아침을 여는 방송이에요'\n          : (h >= 11 && h < 17)\n              ? '낮에 듣기 좋은 방송이에요'\n              : (h >= 17 && h < 22)\n                  ? '저녁에 듣기 좋은 방송이에요'\n                  : '밤에 듣기 좋은 잔잔한 방송이에요';\n      return _homeInfoCard(\n        isDark: isDark,\n        lead: _LiveBadge(hole: card),\n        label: '이런 방송은 어때요?',\n        title: s.name,\n        sub: prog.isNotEmpty ? '지금 · $prog' : mood,\n        action: '듣기',\n        onAction: () => Navigator.push(\n          context,\n          MaterialPageRoute(builder: (_) => RadioPlayerScreen(station: s, openedFromList: false)),\n        ),\n        onClose: () => _closeHomeCard('radio'),\n      );\n    }\n"
DEFAULTS_CONST = "/// 시간대별 '지금 듣기 좋은' 기본 방송 (아침·낮·저녁·밤) — 라디오 목록 맨 위 카드와 메인 홈 카드가 같이 씀\nconst niceDefaults = [\n  ['KBS 제1라디오', 'MBC 표준FM', 'SBS 러브FM'], // 아침: 뉴스·아침 방송\n  ['MBC FM4U', 'KBS Cool FM', 'SBS 파워FM'], // 낮: 가요\n  ['SBS 파워FM', 'KBS 해피FM', 'MBC FM4U'], // 저녁: 퇴근길 음악\n  ['KBS Classic FM', 'CBS 음악FM', 'MBC 올댓뮤직'], // 밤: 잔잔한 음악\n];\n\n"
NICE_FN = '/// 메인 홈 카드용: 안 들어 본 국내 방송 하나 (지금 시간대 추천 → 다른 시간대 추천 → 전체 목록 순서)\n/// skip: 최근에 들은 방송·지금 듣는 방송 / 모두 들어 봤으면 null\nRadioStation? niceKoreanStationNow({Set<String> skip = const {}, int day = 0}) {\n  final h = DateTime.now().hour;\n  final s = (h >= 5 && h < 11) ? 0 : (h >= 11 && h < 17) ? 1 : (h >= 17 && h < 22) ? 2 : 3;\n  final names = <String>[\n    ...niceDefaults[s],\n    for (var k = 1; k < 4; k++) ...niceDefaults[(s + k) % 4],\n  ];\n  for (final n in names) {\n    if (skip.contains(n)) continue;\n    final i = koreanStations.indexWhere((k) => k.name == n);\n    if (i >= 0) return _RadioKoreaScreenState._toRadioStation(koreanStations[i]);\n  }\n  final rest = koreanStations.where((k) => !skip.contains(k.name)).toList();\n  if (rest.isEmpty) return null;\n  return _RadioKoreaScreenState._toRadioStation(rest[day % rest.length]);\n}\n\n'
MAINPREF = "\n/// 메인 홈 맨 위 카드 (나만의 색·라디오·팁) 켜기/끄기 — 홈 화면과 설정 화면이 같이 씀\nclass MainCardPref {\n  static final on = ValueNotifier<bool>(true);\n  static final reopened = ValueNotifier<int>(0); // 다시 켤 때마다 +1 → 홈이 닫은 카드 다시 불러오기\n  static bool _loaded = false;\n\n  static Future<void> load() async {\n    if (_loaded) return;\n    _loaded = true;\n    final p = await SharedPreferences.getInstance();\n    on.value = p.getBool('mainCardOn') ?? true;\n  }\n\n  static Future<void> setOn(bool v) async {\n    on.value = v;\n    final p = await SharedPreferences.getInstance();\n    await p.setBool('mainCardOn', v);\n    if (v) {\n      // 다시 켜면 오늘 닫은 카드와 나만의 색 카드도 다시 나오게\n      await p.remove('main_card_closed_day');\n      await p.remove('main_card_closed');\n      await p.remove('color_tip_hide_until');\n      await p.remove('color_tip_closed');\n      await p.remove('color_tip_done');\n      reopened.value++;\n    }\n  }\n}\n"
SET_TILE = "          // 메인 홈 맨 위 카드 (나만의 색·라디오·팁) — 다시 켜면 닫은 카드도 다시 나와요\n          ValueListenableBuilder<bool>(\n            valueListenable: MainCardPref.on,\n            builder: (context, on, _) => _buildTile(context,\n                icon: Icons.campaign_outlined,\n                title: '메인 알림 카드',\n                desc: '메인 화면 맨 위 카드예요. 다시 켜면 닫은 카드도 나와요',\n                onTap: () => MainCardPref.setOn(!on),\n                primaryColor: primaryColor,\n                trailing: Switch(value: on, onChanged: (v) => MainCardPref.setOn(v), activeColor: primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),\n          ),\n"
OLD_DEFAULTS = "    const defaults = [\n      ['KBS 제1라디오', 'MBC 표준FM', 'SBS 러브FM'], // 아침: 뉴스·아침 방송\n      ['MBC FM4U', 'KBS Cool FM', 'SBS 파워FM'], // 낮: 가요\n      ['SBS 파워FM', 'KBS 해피FM', 'MBC FM4U'], // 저녁: 퇴근길 음악\n      ['KBS Classic FM', 'CBS 음악FM', 'MBC 올댓뮤직'], // 밤: 잔잔한 음악\n    ];\n"

def load(path):
    try:
        raw = open(path, "rb").read().decode("utf-8")
    except FileNotFoundError:
        print(f"❌ 파일이 없어요 ({path})")
        return None, False
    return raw.replace("\r\n", "\n"), "\r\n" in raw

files = {}
for path in (H, R, S, P):
    t, crlf = load(path)
    if t is None:
        print("❌ 아무것도 저장 안 했어요.")
        sys.exit(1)
    files[path] = [t, crlf]

if "// ② 라디오: 안 들어 본 방송 추천" in files[H][0] and "class MainCardPref" in files[P][0] \
        and "MainCardPref.on" in files[S][0] and "Set<String> skip" in files[R][0]:
    print("이미 적용돼 있어요")
    sys.exit(0)

if "_buildHomeCard" not in files[H][0]:
    print("❌ 먼저 python apply_home_cards.py 와 apply_home_cards_nodate.py 를 돌려 주세요. 아무것도 저장 안 했어요.")
    sys.exit(1)

ok = True

def rep(path, label, old, new):
    global ok
    t = files[path][0]
    if new in t:
        print(f"· {label} 이미 적용돼 있어요")
        return
    if t.count(old) == 1:
        files[path][0] = t.replace(old, new)
        print(f"✔ {label}")
    else:
        print(f"❌ {label} 못 찾음")
        ok = False

# ── radio_korea_screen2.dart ──
r = files[R][0]
if "Set<String> skip" in r:
    print("· 라디오: 안 들어 본 방송 꺼내 주기 이미 적용돼 있어요")
elif "const niceDefaults" in r:
    # 앞 버전 파일을 이미 돌린 경우: 함수만 새것으로
    r2, n = re.subn(r"/// 메인 홈 카드용: 지금 시간대에 어울리는 국내 방송 하나\nRadioStation niceKoreanStationNow\(\) \{.*?\n\}\n\n",
                    lambda m: NICE_FN, r, count=1, flags=re.S)
    if n == 1:
        files[R][0] = r2
        print("✔ 라디오: 안 들어 본 방송 꺼내 주기 (새것으로 바꿈)")
    else:
        print("❌ 라디오: 예전 함수 못 찾음")
        ok = False
else:
    rep(R, "라디오: 추천 목록 함께 쓰기", OLD_DEFAULTS, "    const defaults = niceDefaults;\n")
    rep(R, "라디오: 안 들어 본 방송 꺼내 주기", "class _KStation {", DEFAULTS_CONST + NICE_FN + "class _KStation {")

# ── home_card_pref.dart ──
if "class MainCardPref" in files[P][0]:
    print("· 켜기/끄기 저장 이미 적용돼 있어요")
else:
    files[P][0] = files[P][0].rstrip("\n") + "\n" + MAINPREF
    print("✔ 켜기/끄기 저장 (home_card_pref.dart)")

# ── settings_screen.dart ──
rep(S, "설정: 메인 알림 카드 스위치",
    "          ValueListenableBuilder<bool>(\n            valueListenable: HomeCardPref.on,",
    SET_TILE + "          ValueListenableBuilder<bool>(\n            valueListenable: HomeCardPref.on,")
rep(S, "설정: 켜짐 상태 불러오기", "    HomeCardPref.load();\n", "    HomeCardPref.load();\n    MainCardPref.load();\n")

# ── home_screen.dart ──
rep(H, "홈: 추천 방송 불러오기", "import 'radio_player_screen.dart';\n",
    "import 'radio_player_screen.dart';\nimport 'radio_korea_screen2.dart' show niceKoreanStationNow;\n")
rep(H, "홈: 방송마다 편성표 한 번씩",
    "  bool _favProgramAsked = false; // 즐겨찾기 방송 편성표는 한 번만 받기\n",
    "  final Set<String> _programAsked = {}; // 방송마다 편성표는 한 번만 받기\n")
rep(H, "홈: 편성표 받기 고치기",
    "  /// 즐겨찾기 방송의 지금 프로그램 받아 오기 (편성표 있는 국내 방송만)\n  void _askFavProgram(RadioProvider radio, RadioStation s) {\n    if (_favProgramAsked) return;\n    _favProgramAsked = true;\n    final n = s.name;\n",
    "  void _onMainCardPref() {\n    if (mounted) setState(() {});\n  }\n\n  /// 설정에서 다시 켜면: 오늘 닫은 카드·나만의 색 카드 다시 불러오기\n  void _onMainCardReopen() {\n    _loadHomeClosed();\n    _checkColorTip();\n  }\n\n  /// 홈 카드 방송의 지금 프로그램 받아 오기 (편성표 있는 국내 방송만)\n  void _askProgram(RadioProvider radio, RadioStation s) {\n    final n = s.name;\n    if (!_programAsked.add(n)) return;\n")

h = files[H][0]
if "// ② 라디오: 안 들어 본 방송 추천" in h:
    print("· 홈: 라디오 카드 이미 적용돼 있어요")
else:
    h2, n = re.subn(r"    // ② (?:지금 방송 중 \(즐겨찾기 라디오가 있을 때만\)|라디오: 최근에 들은 방송[^\n]*)\n.*?        onClose: \(\) => _closeHomeCard\('radio'\),\n      \);\n    \}\n",
                    lambda m: RADIO_BLOCK, h, count=1, flags=re.S)
    if n == 1:
        files[H][0] = h2
        print("✔ 홈: 라디오 카드 → 안 들어 본 방송 추천")
    else:
        print("❌ 홈: 라디오 카드 자리 못 찾음")
        ok = False

rep(H, "홈: 설정에서 끄면 카드 숨기기",
    "    // ① 나만의 색 (나오는 조건은 예전 그대로)\n",
    "    if (!MainCardPref.on.value) return const SizedBox.shrink(); // 설정에서 끔\n    // ① 나만의 색 (나오는 조건은 예전 그대로)\n")
rep(H, "홈: 설정 바뀌면 바로 반영",
    "    _loadHomeClosed(); // 메인 홈 카드: 오늘 닫은 것\n",
    "    _loadHomeClosed(); // 메인 홈 카드: 오늘 닫은 것\n    MainCardPref.load().then((_) => _onMainCardPref());\n    MainCardPref.on.addListener(_onMainCardPref);\n    MainCardPref.reopened.addListener(_onMainCardReopen);\n")
rep(H, "홈: 화면 닫을 때 정리",
    "    WidgetGo.target.removeListener(_onWidgetGo);\n    HomeScreen.goHome.removeListener(_onGoHome);\n",
    "    WidgetGo.target.removeListener(_onWidgetGo);\n    HomeScreen.goHome.removeListener(_onGoHome);\n    MainCardPref.on.removeListener(_onMainCardPref);\n    MainCardPref.reopened.removeListener(_onMainCardReopen);\n")

for path, (t, _) in files.items():
    if "_askFavProgram" in t or "_favProgramAsked" in t:
        print(f"❌ {path} 옛 이름이 남아 있어요")
        ok = False
    if t.count("(") != t.count(")") or t.count("{") != t.count("}") or t.count("[") != t.count("]"):
        print(f"❌ {path} 괄호 짝이 안 맞아요")
        ok = False

if not ok:
    print("❌ 아무것도 저장 안 했어요.")
    sys.exit(1)

for path, (t, crlf) in files.items():
    if crlf:
        t = t.replace("\n", "\r\n")
    open(path, "wb").write(t.encode("utf-8"))
print("완료")
