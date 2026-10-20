# -*- coding: utf-8 -*-
# SOS: 켜는 동안 상단 줄 숨기기 + 화면 켜 두기 + 앱 밖(폰 홈)으로 나가면 SOS 끄기
# (앞서 준 찾기/바꾸기 2개를 했든 안 했든 그대로 돌리면 됨)
import os, sys

PATH = os.path.join('lib', 'screens', 'settings_screen.dart')

HIDE_OLD = "    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);\n"
P_LINE = "    final p = [200, 200, 200, 200, 200, 400, 600, 200, 600, 200, 600, 400, 200, 200, 200, 200, 200, 800];"
START_HEAD = "  Future<void> _startSOS() async {\n"
START_NEW = (START_HEAD +
    "    // SOS 동안 상단 줄 숨기기 (삼성 '손전등' 표시가 깜빡일 때마다 아이콘이 왔다 갔다 해서) — 아래 줄은 그대로\n"
    "    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);\n"
    "    WakelockPlus.enable().catchError((Object _) {}); // SOS 동안 화면 꺼지지 않게\n"
    + P_LINE)

END_OLD_PLAIN = "    if (mounted) await TorchLight.disableTorch();\n  }"
END_OLD_PREV = ("    if (mounted) await TorchLight.disableTorch();\n"
    "    // SOS가 끝나면 상단 줄 다시 보이기 (그 사이 SOS를 다시 켰으면 그대로 숨김)\n"
    "    if (!_isSosOn) {\n"
    "      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);\n"
    "    }\n  }")
END_NEW = ("    if (mounted) await TorchLight.disableTorch();\n"
    "    // SOS가 끝나면 상단 줄 다시 보이기 · 화면 꺼짐 원래대로 (그 사이 SOS를 다시 켰으면 그대로)\n"
    "    if (!_isSosOn) {\n"
    "      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);\n"
    "      WakelockPlus.disable().catchError((Object _) {});\n"
    "    }\n  }")

DISPOSE_OLD = ("  void dispose() {\n    _removeBubbleNow();\n    _isSosOn = false;\n"
    "    TorchLight.disableTorch();\n    super.dispose();\n  }")
DISPOSE_NEW = ("  void dispose() {\n    WidgetsBinding.instance.removeObserver(this);\n    _removeBubbleNow();\n    _isSosOn = false;\n"
    "    TorchLight.disableTorch();\n    super.dispose();\n  }\n\n"
    "  /// 앱 밖(폰 홈 화면 등)으로 나가면 SOS 끄기 — 앱 밖에서는 상단 줄을 숨길 수 없어서\n"
    "  /// 삼성 '손전등' 표시 때문에 폰 홈 화면이 계속 흔들림\n"
    "  @override\n"
    "  void didChangeAppLifecycleState(AppLifecycleState state) {\n"
    "    if (state == AppLifecycleState.paused && _isSosOn) {\n"
    "      setState(() => _isSosOn = false);\n"
    "      TorchLight.disableTorch();\n"
    "    }\n  }")

EDITS = [
    ("wakelock import",
     ["import 'package:torch_light/torch_light.dart';"],
     "import 'package:torch_light/torch_light.dart';\nimport 'package:wakelock_plus/wakelock_plus.dart';"),
    ("WidgetsBindingObserver",
     ["class _SettingsScreenState extends State<SettingsScreen> {"],
     "class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {"),
    ("initState addObserver",
     ["    super.initState();\n    HomeCardPref.load();"],
     "    super.initState();\n    WidgetsBinding.instance.addObserver(this);\n    HomeCardPref.load();"),
    ("dispose + 앱 밖으로 나가면 SOS 끄기", [DISPOSE_OLD], DISPOSE_NEW),
    ("SOS 시작: 상단 줄 숨기기 + 화면 켜 두기",
     [START_HEAD + "    // SOS 동안 상단 줄 숨기기 (삼성 '손전등' 표시가 깜빡일 때마다 아이콘이 왔다 갔다 해서) — 아래 줄은 그대로\n" + HIDE_OLD + P_LINE,
      START_HEAD + P_LINE],
     START_NEW),
    ("SOS 끝: 상단 줄 다시 보이기", [END_OLD_PREV, END_OLD_PLAIN], END_NEW),
]

def main():
    if not os.path.exists(PATH):
        print('❌ 파일을 못 찾았어요:', PATH); sys.exit(1)
    raw = open(PATH, 'rb').read().decode('utf-8')
    crlf = '\r\n' in raw
    s = raw.replace('\r\n', '\n')
    changed = False
    for name, olds, new in EDITS:
        if new in s:
            print('✔', name, '(이미 돼 있음)'); continue
        for old in olds:
            if s.count(old) == 1:
                s = s.replace(old, new); changed = True
                print('✔', name); break
        else:
            print('❌', name, '— 찾을 코드를 못 찾았어요. 아무것도 저장하지 않았어요.'); sys.exit(1)
    if not changed:
        print('이미 적용돼 있어요'); return
    if crlf: s = s.replace('\n', '\r\n')
    open(PATH, 'wb').write(s.encode('utf-8'))
    print('저장했어요:', PATH)

main()
