# -*- coding: utf-8 -*-
# SOS를 앱 어디서든 계속 깜빡이게 (lib/services/sos_service.dart 를 먼저 만들어 둘 것)
# 앞서 준 apply_sos.py 나 찾기/바꾸기를 했든 안 했든 그대로 돌리면 됨
import os, re, sys

SETTINGS = os.path.join('lib', 'screens', 'settings_screen.dart')
MAIN = os.path.join('lib', 'main.dart')
SERVICE = os.path.join('lib', 'services', 'sos_service.dart')


def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)


def save(p, s, crlf):
    if crlf:
        s = s.replace('\n', '\r\n')
    open(p, 'wb').write(s.encode('utf-8'))


def fail(msg):
    print('❌', msg, '— 아무것도 저장하지 않았어요.')
    sys.exit(1)


for p in (SETTINGS, MAIN):
    if not os.path.exists(p):
        fail('파일을 못 찾았어요: ' + p)
if not os.path.exists(SERVICE):
    fail('sos_service.dart 가 없어요. lib/services 에 먼저 만들어 주세요')

s, s_crlf = load(SETTINGS)
m, m_crlf = load(MAIN)
before_s, before_m = s, m


def rep(text, name, olds, new, must=True):
    """olds 중 하나를 new로 (new가 이미 있으면 건너뜀)"""
    if new and new in text:
        print('✔', name, '(이미 돼 있음)')
        return text
    for old in olds:
        if text.count(old) == 1:
            print('✔', name)
            return text.replace(old, new)
    if must:
        fail(name + ' 찾을 코드를 못 찾았어요')
    print('✔', name, '(할 것 없음)')
    return text


def drop(text, name, old):
    """old가 있으면 지우기 (없으면 그대로)"""
    if old in text:
        print('✔', name)
        return text.replace(old, '', 1)
    print('✔', name, '(이미 돼 있음)')
    return text


# ── settings_screen.dart ──
s = rep(s, 'sos_service import',
        ["import '../services/headset_resume.dart';"],
        "import '../services/headset_resume.dart';\nimport '../services/sos_service.dart';")
s = drop(s, 'wakelock import 빼기 (이제 sos_service에서)', "import 'package:wakelock_plus/wakelock_plus.dart';\n")
s = rep(s, '클래스 원래대로',
        ["class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {"],
        "class _SettingsScreenState extends State<SettingsScreen> {", must=False)
s = rep(s, 'SOS 상태는 sos_service에서',
        ["  bool _isSosOn = false;"],
        "  bool get _isSosOn => SosService.isOn; // SOS는 앱 전체에서 하나 (sos_service.dart)\n"
        "  void _onSosChanged() {\n    if (mounted) setState(() {});\n  }")
s = rep(s, 'initState: SOS 바뀌면 스위치 다시 그리기',
        ["    super.initState();\n    WidgetsBinding.instance.addObserver(this);\n    HomeCardPref.load();",
         "    super.initState();\n    HomeCardPref.load();"],
        "    super.initState();\n    SosService.on.addListener(_onSosChanged);\n    HomeCardPref.load();")
s = rep(s, 'dispose: 나가도 SOS는 계속',
        ["  void dispose() {\n    WidgetsBinding.instance.removeObserver(this);\n    _removeBubbleNow();\n    _isSosOn = false;\n    TorchLight.disableTorch();\n    super.dispose();\n  }",
         "  void dispose() {\n    _removeBubbleNow();\n    _isSosOn = false;\n    TorchLight.disableTorch();\n    super.dispose();\n  }"],
        "  void dispose() {\n    SosService.on.removeListener(_onSosChanged);\n    _removeBubbleNow();\n"
        "    if (!SosService.isOn) TorchLight.disableTorch(); // 그냥 손전등만 끄기 (SOS는 다른 화면에서도 계속)\n"
        "    super.dispose();\n  }")
# apply_sos.py 로 넣었던 '앱 밖으로 나가면 끄기'는 sos_service.dart로 옮김
s = drop(s, '설정 화면의 앱 밖 감지 빼기',
         "\n\n  /// 앱 밖(폰 홈 화면 등)으로 나가면 SOS 끄기 — 앱 밖에서는 상단 줄을 숨길 수 없어서\n"
         "  /// 삼성 '손전등' 표시 때문에 폰 홈 화면이 계속 흔들림\n"
         "  @override\n"
         "  void didChangeAppLifecycleState(AppLifecycleState state) {\n"
         "    if (state == AppLifecycleState.paused && _isSosOn) {\n"
         "      setState(() => _isSosOn = false);\n"
         "      TorchLight.disableTorch();\n"
         "    }\n  }")
s = rep(s, '손전등 켤 때 SOS 끄기',
        ["        if (_isSosOn) { setState(() => _isSosOn = false); await TorchLight.disableTorch(); await Future.delayed(const Duration(milliseconds: 200)); }"],
        "        if (_isSosOn) { await SosService.stop(); await Future.delayed(const Duration(milliseconds: 200)); }")
s = rep(s, 'SOS 스위치',
        ["  Future<void> _toggleSOS(BuildContext context) async {\n    if (_isSosOn) {\n      setState(() => _isSosOn = false);\n      await TorchLight.disableTorch();\n    } else {\n"
         "      if (_isFlashlightOn) { await TorchLight.disableTorch(); setState(() => _isFlashlightOn = false); await Future.delayed(const Duration(milliseconds: 200)); }\n"
         "      setState(() => _isSosOn = true);\n      _startSOS();\n    }\n  }"],
        "  Future<void> _toggleSOS(BuildContext context) async {\n    if (_isSosOn) {\n      await SosService.stop();\n    } else {\n"
        "      if (_isFlashlightOn) { await TorchLight.disableTorch(); setState(() => _isFlashlightOn = false); await Future.delayed(const Duration(milliseconds: 200)); }\n"
        "      SosService.start(); // 앱 어느 화면에서든 계속 깜빡임\n    }\n  }")
# 예전 깜빡임 함수(_startSOS)는 sos_service.dart로 옮김 → 지우기
a = s.find('  Future<void> _startSOS() async {')
if a >= 0:
    b = s.find('  /// 프로모션 코드', a)
    if b < 0:
        fail('_startSOS 끝을 못 찾았어요')
    s = s[:a] + s[b:]
    print('✔ 예전 _startSOS 지우기')
else:
    print('✔ 예전 _startSOS 지우기 (이미 돼 있음)')
if '_startSOS' in s or 'setState(() => _isSosOn' in s:
    fail('settings_screen.dart 에 예전 SOS 코드가 남아 있어요')

# ── main.dart ──
m = rep(m, 'main: sos_service import',
        ["import 'services/headset_resume.dart';"],
        "import 'services/headset_resume.dart';\nimport 'services/sos_service.dart';")
m = rep(m, 'main: 모든 화면 위에 SOS 띠',
        ["                  child: child!,\n"],
        "                  // SOS가 켜져 있으면 어느 화면이든 위쪽에 작은 빨간 'SOS ✕' 띠\n"
        "                  child: Stack(\n"
        "                    fit: StackFit.expand,\n"
        "                    children: [\n"
        "                      child!,\n"
        "                      const Positioned(top: 0, left: 0, right: 0, child: SosBanner()),\n"
        "                    ],\n"
        "                  ),\n")

if s == before_s and m == before_m:
    print('이미 적용돼 있어요')
    sys.exit(0)
save(SETTINGS, s, s_crlf)
save(MAIN, m, m_crlf)
print('저장했어요:', SETTINGS, '·', MAIN)
