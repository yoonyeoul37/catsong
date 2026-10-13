# -*- coding: utf-8 -*-
# 위젯 재생: 앱이 꺼져 있어도 앱 화면을 열지 않고 위젯에서만 재생 (시험판)
#  · 앱이 켜져 있으면: 지금처럼 앱에게 바로
#  · 앱이 꺼져 있으면: 화면 없이 재생 엔진만 깨워서 마지막에 듣던 것 재생
#  · 엔진이 깨어나면 다트가 '위젯 재생 눌림' 표시를 보고 바로 재생
#  · 블루투스·알림의 재생 버튼도: 틀 게 없으면 마지막에 듣던 것
import os, re, sys, shutil

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
pw = find('PlayerWidget.kt', 'android')
cur = open(pw, encoding='utf-8').read() if pw else ''
if 'widget_play_at' in cur:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'MainActivity.activityAlive' not in cur:
    print('❌ apply_widget_fix2.py 까지 먼저 실행해 주세요'); sys.exit(1)

writes = {}
ok = True
def edit(path, pairs):
    global ok
    src, crlf = writes[path] if path in writes else load(path)
    for label, old, new in pairs:
        n = src.count(old)
        if n != 1:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

# 1) 위젯 코드
src, crlf = load(pw)
pat = re.compile(r"                // 앱이 꺼져 있으면: 첫인사 없이 열면서 마지막에 듣던 것 이어서\n.*?\n                refreshAll\(context\)\n", re.S)
if len(pat.findall(src)) != 1:
    print('❌ 위젯 - 앱이 꺼져 있을 때 재생 부분'); ok = False
else:
    src = pat.sub(lambda _: (
        "                // 앱이 꺼져 있으면: 앱 화면은 안 열고, 재생 엔진만 깨워서 마지막에 듣던 것\n"
        "                // (엔진이 깨어나면 다트가 이 표시를 보고 바로 재생)\n"
        "                context.getSharedPreferences(\"FlutterSharedPreferences\", Context.MODE_PRIVATE)\n"
        "                    .edit().putLong(\"flutter.widget_play_at\", System.currentTimeMillis()).apply()\n"
        "                sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PLAY)\n"), src)
    print('✔ 위젯 - 앱이 꺼져 있으면 화면 없이 재생')
writes[pw] = (src, crlf)
edit(pw, [
    ('위젯 - 재생 버튼은 항상 위젯에서만 (앱 열기 없앰)',
     "            if (MainActivity.activityAlive) {\n"
     "                views.setOnClickPendingIntent(R.id.widget_play_pause, media(ACTION_PLAY_PAUSE, 2))\n"
     "            } else {\n"
     "                val resume = Intent(context, MainActivity::class.java).apply {\n"
     "                    action = \"kr.ssing.catsong.WIDGET_GO_resume\"\n"
     "                    putExtra(\"widgetGo\", \"resume\")\n"
     "                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP\n"
     "                }\n"
     "                views.setOnClickPendingIntent(R.id.widget_play_pause, PendingIntent.getActivity(\n"
     "                    context, 30, resume, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))\n"
     "            }\n",
     "            views.setOnClickPendingIntent(R.id.widget_play_pause, media(ACTION_PLAY_PAUSE, 2))\n"),
])

# 2) 다트: 엔진이 화면 없이 깨어났을 때 바로 재생
edit(find('main.dart', 'lib'), [
    ('앱이 꺼져 있을 때 위젯 재생 → 화면 없이 바로 재생',
     "  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것\n",
     "  HeadsetResume.attachRecent(recentContentProvider, musicProvider); // 위젯 재생: 마지막에 듣던 것\n"
     "  // 앱이 꺼져 있을 때 위젯 재생을 눌렀으면 (화면 없이 엔진만 켜짐) → 마지막에 듣던 것 바로\n"
     "  try {\n"
     "    final sp = await SharedPreferences.getInstance();\n"
     "    final at = sp.getInt('widget_play_at') ?? 0;\n"
     "    if (at > 0) await sp.remove('widget_play_at');\n"
     "    if (at > 0 && DateTime.now().millisecondsSinceEpoch - at < 15000) {\n"
     "      WidgetGo.launched = true; // 나중에 앱을 열어도 인삿말 목소리 안 함\n"
     "      if (musicProvider.songs.isEmpty) musicProvider.initialize(); // 곡 목록 (화면이 없어서 여기서)\n"
     "      HeadsetResume.widgetPlay();\n"
     "    }\n"
     "  } catch (_) {}\n"),
])

# 3) 재생 버튼(블루투스·알림·위젯)을 눌렀는데 틀 게 없으면 → 마지막에 듣던 것
edit(find('player_provider.dart', os.path.join('lib', 'providers')), [
    ('틀 게 없을 때 재생 버튼 → 마지막에 듣던 것',
     "        await f();\n      }\n    }\n  }\n",
     "        await f();\n"
     "      } else {\n"
     "        HeadsetResume.widgetPlay(); // 틀 게 없으면 마지막에 듣던 것 (위젯·블루투스 재생 버튼)\n"
     "      }\n    }\n  }\n"),
])

# 4) 같은 순간에 두 번 불려도 한 번만 (위젯 표시 + 재생 버튼 신호가 같이 올 때)
edit(find('headset_resume.dart', 'lib'), [
    ('두 번 겹쳐 틀지 않게',
     "    await _playLastRecent();\n",
     "    // 위젯 표시와 재생 버튼 신호가 거의 같이 오면 한 번만\n"
     "    if (DateTime.now().difference(_lastWidgetPlay).inMilliseconds < 2000) return;\n"
     "    _lastWidgetPlay = DateTime.now();\n"
     "    await _playLastRecent();\n"),
    ('겹침 확인용 시간',
     "  static Future<void> widgetPlay() async {\n",
     "  static DateTime _lastWidgetPlay = DateTime(2000);\n"
     "  static Future<void> widgetPlay() async {\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_widget8')
for p, (text, crlf) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = text.replace('\n', '\r\n') if crlf else text
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요')
