# -*- coding: utf-8 -*-
# 홈 위젯: 앱을 완전히 끈 상태에서 재생 버튼을 누르면 → 앱이 첫인사 없이 열리며 마지막에 듣던 것
# (앱이 꺼지면 위젯 재생 버튼을 '앱 열기 + 이어 듣기'로 바꿔 두고, 앱이 켜지면 다시 원래대로)
# apply_widget_b.py → apply_widget_fix.py 다음에 실행
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

if not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)
kt = find('PlayerWidget.kt', 'android')
if not kt:
    print('❌ PlayerWidget.kt 를 못 찾았어요'); sys.exit(1)
cur = open(kt, encoding='utf-8').read()
if 'WIDGET_GO_resume' not in cur:
    print('❌ apply_widget_fix.py 를 먼저 실행해 주세요'); sys.exit(1)
if 'refreshAll' in cur:
    print('이미 적용돼 있어요'); sys.exit(0)

writes = {}
ok = True
def edit(name, pairs):
    global ok
    p = find(name, 'android')
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

edit('PlayerWidget.kt', [
    ('재생 버튼: 앱이 꺼져 있으면 앱 열기 + 이어 듣기',
     "            views.setOnClickPendingIntent(R.id.widget_play_pause, media(ACTION_PLAY_PAUSE, 2))\n",
     "            // 재생: 앱이 켜져 있으면 앱에게 바로 / 꺼져 있으면 앱을 열면서 마지막에 듣던 것\n"
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
     "            }\n"),
    ('모든 위젯 다시 그리기 함수',
     "        /// 곡 정보가 오면 기억해 두고",
     "        /// 바탕화면에 붙은 이 위젯 전부 다시 그리기 (앱이 켜지고 꺼질 때)\n"
     "        fun refreshAll(context: Context) {\n"
     "            try {\n"
     "                val mgr = AppWidgetManager.getInstance(context)\n"
     "                val ids = mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget::class.java))\n"
     "                for (id in ids) updateAppWidget(context, mgr, id)\n"
     "            } catch (_: Exception) {}\n"
     "        }\n\n"
     "        /// 곡 정보가 오면 기억해 두고"),
    ('앱이 막 꺼진 뒤 눌렀으면 다음부터는 바로 열리게',
     "                } catch (_: Exception) {\n                    sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)\n                }\n",
     "                } catch (_: Exception) {\n                    sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)\n                }\n"
     "                refreshAll(context)\n"),
])

edit('MainActivity.kt', [
    ('앱 화면이 켜져 있는지 표시 칸',
     "        var mediaChannel: MethodChannel? = null\n",
     "        var mediaChannel: MethodChannel? = null\n"
     "        // 앱 화면이 살아 있는지 (위젯 재생 버튼이 어떻게 동작할지 정함)\n"
     "        var activityAlive = false\n"),
    ('앱 켜질 때 위젯 재생 버튼 원래대로',
     "        handleWidgetGo(intent, false)\n    }\n",
     "        handleWidgetGo(intent, false)\n"
     "        activityAlive = true\n"
     "        PlayerWidget.refreshAll(this)\n"
     "    }\n\n"
     "    override fun onDestroy() {\n"
     "        // 앱을 완전히 끄면: 위젯 재생 버튼을 '앱 열면서 이어 듣기'로\n"
     "        activityAlive = false\n"
     "        mediaChannel = null\n"
     "        PlayerWidget.refreshAll(this)\n"
     "        super.onDestroy()\n"
     "    }\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = '_backup_widget3'
for p, (src, crlf) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (원래 것은 _backup_widget3 폴더에 백업)')
