# -*- coding: utf-8 -*-
# 위젯으로 앱을 켰을 때 첫인사(검은 화면 + 인삿말 목소리)가 나오던 것 고치기
#  · 안드로이드: 앱이 켜지자마자(다트가 묻기 전에) 위젯 바로가기를 먼저 기억
#  · 다트: 아직 준비 안 됐으면 몇 번 다시 물어보기 + 늦게 알게 돼도 첫인사를 바로 끄기
#  · 위젯으로 켜졌으면 인삿말 목소리 안 함
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if '_backup_widget' in root:
            continue
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
wg = find('widget_go.dart', 'lib')
if not wg:
    print('❌ widget_go.dart 가 없어요. apply_widget_b.py 를 먼저 실행해 주세요'); sys.exit(1)
if 'static bool launched' in open(wg, encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)

writes = {}
ok = True
def edit(name, top, pairs):
    global ok
    p = find(name, top)
    if not p:
        print('❌ %s 를 못 찾았어요' % name); ok = False; return
    src, crlf = writes[p] if p in writes else load(p)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[p] = (src, crlf)

edit('MainActivity.kt', 'android', [
    ('켜지자마자 위젯 바로가기 먼저 기억',
     "    override fun onCreate(savedInstanceState: android.os.Bundle?) {\n"
     "        super.onCreate(savedInstanceState)\n"
     "        handleAlarmIntent(intent)\n",
     "    override fun onCreate(savedInstanceState: android.os.Bundle?) {\n"
     "        // 홈 위젯으로 켜졌는지: 앱(다트)이 물어보기 전에 먼저 기억 (늦으면 첫인사가 나와 버림)\n"
     "        intent?.getStringExtra(\"widgetGo\")?.let {\n"
     "            pendingWidgetGo = it\n"
     "            intent.removeExtra(\"widgetGo\")\n"
     "        }\n"
     "        super.onCreate(savedInstanceState)\n"
     "        handleAlarmIntent(intent)\n"),
    ('앱이 이미 켜져 있던 경우에도 전달',
     "    /// 홈 위젯 바로가기 (음악·라디오·자연·수면)\n",
     "    /// 앱(다트)이 화면 없이 살아 있다가 다시 열린 경우에도 위젯 바로가기 전달\n"
     "    /// (다트가 아직 준비 전이면 그대로 두고 → 다트가 켜지면서 직접 물어봄)\n"
     "    private fun pushPendingWidgetGo() {\n"
     "        val t = pendingWidgetGo ?: return\n"
     "        flutterMethodChannel?.invokeMethod(\"widgetGo\", t, object : MethodChannel.Result {\n"
     "            override fun success(result: Any?) {\n"
     "                if (pendingWidgetGo == t) pendingWidgetGo = null\n"
     "            }\n"
     "            override fun error(code: String, msg: String?, details: Any?) {}\n"
     "            override fun notImplemented() {}\n"
     "        })\n"
     "    }\n\n"
     "    /// 홈 위젯 바로가기 (음악·라디오·자연·수면)\n"),
    ('켜지고 잠깐 뒤 전달 시도',
     "        handleWidgetGo(intent, false)\n",
     "        handleWidgetGo(intent, false)\n"
     "        android.os.Handler(mainLooper).postDelayed({ pushPendingWidgetGo() }, 300)\n"),
])

edit('widget_go.dart', 'lib', [
    ('위젯으로 켜졌는지 표시',
     "  static final target = ValueNotifier<String?>(null);\n",
     "  static final target = ValueNotifier<String?>(null);\n"
     "  /// 이번에 위젯으로 켜졌는지 (첫인사 목소리 안 하게)\n"
     "  static bool launched = false;\n"),
    ('아직 준비 안 됐으면 다시 물어보기',
     "    try {\n"
     "      final t = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<String>('takeWidgetGo');\n"
     "      if (t != null && t.isNotEmpty) target.value = t;\n"
     "    } catch (_) {}\n",
     "    for (var k = 0; k < 5; k++) {\n"
     "      try {\n"
     "        final t = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<String>('takeWidgetGo');\n"
     "        if (t != null && t.isNotEmpty) {\n"
     "          launched = true;\n"
     "          target.value = t;\n"
     "        }\n"
     "        return;\n"
     "      } on MissingPluginException {\n"
     "        await Future.delayed(const Duration(milliseconds: 150)); // 안드로이드 쪽이 아직 준비 중\n"
     "      } catch (_) {\n"
     "        return;\n"
     "      }\n"
     "    }\n"),
])

edit('main.dart', 'lib', [
    ('위젯으로 켜졌으면 인삿말 목소리 안 함',
     "    if (!mounted || AlarmService.launchedByAlarm) return;\n",
     "    if (!mounted || AlarmService.launchedByAlarm) return;\n"
     "    if (WidgetGo.launched || WidgetGo.target.value != null) return; // 위젯으로 켜졌으면 인삿말 없이\n"),
    ('첫인사 중에 위젯 바로가기를 알게 되면 바로 끄기 (시작)',
     "    AlarmService.onRingStart = _stopWelcome; // 알람이 울리면 첫인삿말 바로 멈춤\n",
     "    AlarmService.onRingStart = _stopWelcome; // 알람이 울리면 첫인삿말 바로 멈춤\n"
     "    WidgetGo.target.addListener(_onWidgetGoIntro); // 첫인사 중에 위젯 바로가기 → 첫인사 끄기\n"),
    ('첫인사 중에 위젯 바로가기를 알게 되면 바로 끄기 (끝)',
     "    AlarmService.onRingStart = null;\n",
     "    AlarmService.onRingStart = null;\n"
     "    WidgetGo.target.removeListener(_onWidgetGoIntro);\n"),
    ('첫인사 끄기 함수',
     "  /// 첫인사 멈추고 재생기 정리\n",
     "  /// 위젯 바로가기로 들어오면 첫인사(사진·목소리)를 바로 끄고 그 화면으로\n"
     "  void _onWidgetGoIntro() {\n"
     "    if (WidgetGo.target.value == null || !mounted) return;\n"
     "    WidgetGo.launched = true;\n"
     "    _stopWelcome();\n"
     "    if (_showIntro) setState(() => _showIntro = false);\n"
     "  }\n\n"
     "  /// 첫인사 멈추고 재생기 정리\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = '_backup_widget5'
for p, (src, crlf) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (원래 것은 _backup_widget5 폴더에 백업)')
