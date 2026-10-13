# -*- coding: utf-8 -*-
# 위젯 버튼이 앱에 안 닿던 것 고치기
#  · 앱 화면을 닫아도(뒤로가기) 음악이 계속 나오는 동안엔 위젯이 앱에게 바로 말하게
#  · 앱이 대답을 바로 하게 (재생이 끝날 때까지 기다리느라 대답이 늦던 것)
#  · 앱이 정말 꺼져 있으면 그때만 '엔진 깨우기'로
#  · 라디오 버튼: 마지막 방송 기록이 없으면 라디오 최근 목록 → 즐겨찾기 순서로
# apply_widget_kind.py 다음에 실행
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
if 'fun toApp(' in cur:
    print('이미 적용돼 있어요'); sys.exit(0)
if 'ACTION_KIND' not in cur:
    print('❌ apply_widget_kind.py 를 먼저 실행해 주세요'); sys.exit(1)

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

# ── 1) 위젯: 버튼 받는 곳 새로 ──
src, crlf = load(pw)
s1 = src.find('    override fun onReceive(context: Context, intent: Intent) {')
s2 = src.find('    companion object {')
if s1 < 0 or s2 < 0 or s2 < s1:
    print('❌ 위젯 - 버튼 받는 곳'); ok = False
else:
    src = src[:s1] + '''    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val a = intent.action ?: return
        when {
            a == ACTION_PLAY_PAUSE -> toApp("widgetPlayPause", null) { wakeAndPlay(context, null) }
            a == ACTION_NEXT -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_NEXT)
            a == ACTION_PREV -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            a.startsWith(ACTION_KIND) -> {
                // 아래 버튼: 음악 · 라디오 · 자연 바로 재생 (앱 안 열고)
                val kind = a.removePrefix(ACTION_KIND)
                toApp("widgetPlayKind", kind) { wakeAndPlay(context, kind) }
            }
        }
    }

    /// 앱(다트)에게 바로 전달 — 앱이 꺼져 있거나 1.2초 안에 대답이 없으면 fallback
    private fun toApp(method: String, arg: Any?, fallback: () -> Unit) {
        val ch = MainActivity.mediaChannel
        if (ch == null) {
            fallback()
            return
        }
        val pending = goAsync()
        val h = android.os.Handler(android.os.Looper.getMainLooper())
        var done = false
        val finish = { useFallback: Boolean ->
            if (!done) {
                done = true
                if (useFallback) fallback()
                pending.finish()
            }
        }
        h.postDelayed({ finish(true) }, 1200)
        try {
            ch.invokeMethod(method, arg, object : MethodChannel.Result {
                override fun success(result: Any?) = finish(false)
                override fun error(code: String, msg: String?, details: Any?) = finish(false)
                override fun notImplemented() = finish(true)
            })
        } catch (_: Exception) {
            finish(true)
        }
    }

    /// 앱이 정말 꺼져 있으면: 화면 없이 재생 엔진만 깨우기 (다트가 이 표시를 보고 틂)
    private fun wakeAndPlay(context: Context, kind: String?) {
        val e = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).edit()
            .putLong("flutter.widget_play_at", System.currentTimeMillis())
        if (kind == null) e.remove("flutter.widget_play_kind") else e.putString("flutter.widget_play_kind", kind)
        e.apply()
        sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PLAY)
    }

''' + src[s2:]
    print('✔ 위젯 - 버튼 받는 곳 (앱에게 바로, 대답 없으면 엔진 깨우기)')
if 'import io.flutter.plugin.common.MethodChannel' not in src:
    src = src.replace('import android.widget.RemoteViews\n',
                      'import android.widget.RemoteViews\nimport io.flutter.plugin.common.MethodChannel\n', 1)
writes[pw] = (src, crlf)

# ── 2) 앱 화면을 닫아도 통로는 그대로 (음악이 계속 나오는 동안 위젯이 말할 수 있게) ──
edit(find('MainActivity.kt', 'android'), [
    ('화면을 닫아도 위젯 → 앱 통로 유지',
     '        mediaChannel = null\n',
     '        // (mediaChannel 은 그대로: 화면만 닫히고 재생 엔진은 살아 있을 수 있어서)\n'),
])

# ── 3) 다트: 위젯 신호에 바로 대답 (재생 끝날 때까지 기다리지 않게) ──
edit(find('player_provider.dart', os.path.join('lib', 'providers')), [
    ('위젯 재생 버튼: 바로 대답',
     "          await HeadsetResume.widgetPlay(); // 안 틀었으면 마지막에 듣던 것\n",
     "          HeadsetResume.widgetPlay(); // 안 틀었으면 마지막에 듣던 것 (기다리지 않고 바로 대답)\n"),
    ('위젯 아래 버튼: 바로 대답',
     "          await HeadsetResume.widgetPlayKind(call.arguments as String); // 위젯 아래 버튼\n",
     "          HeadsetResume.widgetPlayKind(call.arguments as String); // 위젯 아래 버튼 (바로 대답)\n"),
])

# ── 4) 라디오 버튼: 기록이 없으면 라디오 최근 목록 → 즐겨찾기 ──
edit(find('headset_resume.dart', 'lib'), [
    ('라디오 버튼: 라디오 최근 목록·즐겨찾기도',
     "          if (list.isEmpty) return;\n",
     "          // 그래도 없으면 라디오 화면의 최근 목록 → 즐겨찾기\n"
     "          for (final s in [...radio.recentlyListened, ...radio.favorites]) {\n"
     "            if (!list.any((e) => e.stationUuid == s.stationUuid)) list.add(s);\n"
     "          }\n"
     "          if (list.isEmpty) return;\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
BK = os.path.join('..', 'paransori_backup_widget10')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = text.replace('\n', '\r\n') if c else text
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요')
