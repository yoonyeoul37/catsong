# -*- coding: utf-8 -*-
# 위젯으로 켤 때 잠깐 검은 화면 + 인삿말 목소리가 나오던 것 고치기
#  · 안드로이드: 앱(다트)이 준비되는 즉시 위젯 바로가기를 알려줌 (0.1초마다 다시 시도)
#  · 다트: 위젯으로 켜졌다는 표시를 바로 남겨서 인삿말 목소리가 안 나오게
#  · 인삿말 틀기 직전에 한 번 더 확인
# apply_widget_launch.py 다음에 실행
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
ma = find('MainActivity.kt', 'android')
cur = open(ma, encoding='utf-8').read() if ma else ''
if 'pushPendingWidgetGo' not in cur:
    print('❌ apply_widget_launch.py 를 먼저 실행해 주세요'); sys.exit(1)
if 'pushPendingWidgetGo(tries' in cur:
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
    ('켜지자마자 바로 알려주기 (0.3초 기다리지 않고)',
     "        android.os.Handler(mainLooper).postDelayed({ pushPendingWidgetGo() }, 300)\n",
     "        pushPendingWidgetGo(0)\n"),
    ('앱(다트)이 준비될 때까지 0.1초마다 다시 시도',
     "    private fun pushPendingWidgetGo() {\n"
     "        val t = pendingWidgetGo ?: return\n"
     "        flutterMethodChannel?.invokeMethod(\"widgetGo\", t, object : MethodChannel.Result {\n"
     "            override fun success(result: Any?) {\n"
     "                if (pendingWidgetGo == t) pendingWidgetGo = null\n"
     "            }\n"
     "            override fun error(code: String, msg: String?, details: Any?) {}\n"
     "            override fun notImplemented() {}\n"
     "        })\n"
     "    }\n",
     "    private fun pushPendingWidgetGo(tries: Int) {\n"
     "        val t = pendingWidgetGo ?: return // 다트가 이미 가져갔으면 끝\n"
     "        if (tries > 40) return // 4초 넘게 준비 안 되면 그만 (다트가 켜지면서 직접 물어봄)\n"
     "        val retry = { android.os.Handler(mainLooper).postDelayed({ pushPendingWidgetGo(tries + 1) }, 100) }\n"
     "        val ch = flutterMethodChannel\n"
     "        if (ch == null) {\n"
     "            retry()\n"
     "            return\n"
     "        }\n"
     "        ch.invokeMethod(\"widgetGo\", t, object : MethodChannel.Result {\n"
     "            override fun success(result: Any?) {\n"
     "                if (pendingWidgetGo == t) pendingWidgetGo = null\n"
     "            }\n"
     "            override fun error(code: String, msg: String?, details: Any?) {}\n"
     "            override fun notImplemented() {\n"
     "                retry() // 다트가 아직 준비 중\n"
     "            }\n"
     "        })\n"
     "    }\n"),
])

edit('player_provider.dart', os.path.join('lib', 'providers'), [
    ('위젯으로 켜졌다는 표시 바로 남기기',
     "          WidgetGo.target.value = call.arguments as String?; // 홈 위젯 바로가기\n",
     "          WidgetGo.launched = true; // 위젯으로 켜졌으면 인삿말 목소리 안 함\n"
     "          WidgetGo.target.value = call.arguments as String?; // 홈 위젯 바로가기\n"),
])

edit('main.dart', 'lib', [
    ('인삿말 틀기 직전에 한 번 더 확인',
     "      if (_welcomePlayer == p && !AlarmService.launchedByAlarm) p.play(); // 준비하는 사이에 멈췄으면 재생 안 함\n",
     "      // 준비하는 사이에 멈췄거나 위젯으로 켜졌으면 재생 안 함\n"
     "      if (_welcomePlayer == p && !AlarmService.launchedByAlarm && !WidgetGo.launched) {\n"
     "        p.play();\n"
     "      } else {\n"
     "        _stopWelcome();\n"
     "      }\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
# 이번엔 백업을 프로젝트 밖(한 단계 위 폴더)에 둬서 헷갈리지 않게
BK = os.path.join('..', 'paransori_backup_widget6')
for p, (src, crlf) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요')
