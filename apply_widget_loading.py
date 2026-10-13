# -*- coding: utf-8 -*-
# 위젯 기본 다지기
#  1) 누르자마자 '불러오는 중…' + ⏸ 로 바뀜 (소리가 나면 곡·방송 이름으로)
#  2) 1초 안에 또 누른 건 무시 (꼬이지 않게)
#  3) 앱을 완전히 끈 뒤 위젯으로 켰을 때도 위젯 ↔ 앱 통로를 바로 연결 (그다음 누름부터 바로 반응, 이름도 위젯에 뜸)
#  4) 재생·이전·다음 버튼 누르는 자리 조금 크게
#  5) 라디오: 위젯 둘째 줄을 영어 나라 이름 대신 방송 설명 → 편성표가 있으면 지금 프로그램
import os, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if 'backup' in root:
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
lay = find('widget_player.xml', 'android')
rp = find('radio_provider.dart', os.path.join('lib', 'providers'))
for n, p in (('PlayerWidget.kt', pw), ('widget_player.xml', lay), ('radio_provider.dart', rp)):
    if not p:
        print('❌ %s 를 못 찾았어요' % n); sys.exit(1)

writes = {}
ok = True
already = 0
total = 0
def edit(path, pairs):
    """pairs: (이름, 찾을 것, 바꿀 것, 개수)  — 이미 바뀌어 있으면 '이미' 로 넘어감"""
    global ok, already, total
    src, crlf = writes[path] if path in writes else load(path)
    for item in pairs:
        label, old, new = item[0], item[1], item[2]
        cnt = item[3] if len(item) > 3 else 1
        total += 1
        n = src.count(old)
        if cnt is None:  # 여러 곳 모두 바꾸기 (남은 게 없으면 이미 적용)
            if n == 0:
                print('✔ %s (이미 적용돼 있어요)' % label); already += 1; continue
        elif new in src:
            print('✔ %s (이미 적용돼 있어요)' % label); already += 1; continue
        elif n != cnt:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[path] = (src, crlf)

# ───────── PlayerWidget.kt ─────────
edit(pw, [
    ('위젯: 필요한 것 불러오기',
     'import io.flutter.plugin.common.MethodChannel\n',
     'import io.flutter.plugin.common.MethodChannel\n'
     'import io.flutter.embedding.engine.FlutterEngineCache\n'
     'import com.ryanheise.audioservice.AudioServicePlugin\n'),

    ('위젯: 누르자마자 표시 + 연타 무시',
     '        when {\n'
     '            a == ACTION_PLAY_PAUSE -> toApp("widgetPlayPause", null) { wakeAndPlay(context, null) }\n',
     '        if (MainActivity.mediaChannel == null) attachHeadless(context)\n'
     '        when {\n'
     '            a == ACTION_PLAY_PAUSE -> {\n'
     '                if (tooSoon(context)) return\n'
     '                pressed(context, null)\n'
     '                toApp("widgetPlayPause", null) { wakeAndPlay(context, null) }\n'
     '            }\n'),

    ('위젯: 아래 버튼도 똑같이',
     '                val kind = a.removePrefix(ACTION_KIND)\n'
     '                toApp("widgetPlayKind", kind) { wakeAndPlay(context, kind) }\n',
     '                if (tooSoon(context)) return\n'
     '                val kind = a.removePrefix(ACTION_KIND)\n'
     '                pressed(context, kind)\n'
     '                toApp("widgetPlayKind", kind) { wakeAndPlay(context, kind) }\n'),

    ('위젯: 연타·불러오는 중·통로 연결 함수',
     '        private const val PREFS = "paran_widget"\n',
     '        private const val PREFS = "paran_widget"\n'
     '        private const val TAP_GAP = 1000L    // 이 시간 안에 또 누르면 무시 (1초)\n'
     '        private const val LOAD_MAX = 10000L  // \'불러오는 중…\' 은 길어도 10초까지만\n'
     '\n'
     '        /// 1초 안에 또 누른 거면 true (무시)\n'
     '        private fun tooSoon(context: Context): Boolean {\n'
     '            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)\n'
     '            val now = System.currentTimeMillis()\n'
     '            val gap = now - p.getLong("tap", 0L)\n'
     '            if (gap in 0 until TAP_GAP) {\n'
     '                android.util.Log.d("PARAN_W", "연타 무시 (${gap}ms)")\n'
     '                return true\n'
     '            }\n'
     '            p.edit().putLong("tap", now).apply()\n'
     '            return false\n'
     '        }\n'
     '\n'
     '        /// 누르자마자 위젯 모양부터 바꾸기\n'
     '        /// - 듣는 중에 재생 버튼 = 멈춤 → 버튼만 바로 ▶\n'
     '        /// - 그 밖엔 \'불러오는 중…\' + ⏸ (진짜 곡·방송 이름이 오면 바뀜)\n'
     '        private fun pressed(context: Context, kind: String?) {\n'
     '            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)\n'
     '            val playing = p.getBoolean("p", false)\n'
     '            if (kind == null && playing) {\n'
     '                p.edit().putBoolean("p", false).apply()\n'
     '            } else {\n'
     '                // load_any: 다른 걸 듣다가 바꾼 경우 → 어떤 소식이 와도 끝냄\n'
     '                p.edit().putLong("load", System.currentTimeMillis()).putBoolean("load_any", playing).apply()\n'
     '                val app = context.applicationContext\n'
     '                android.os.Handler(android.os.Looper.getMainLooper())\n'
     '                    .postDelayed({ refreshAll(app) }, LOAD_MAX + 300)\n'
     '            }\n'
     '            refreshAll(context)\n'
     '        }\n'
     '\n'
     '        /// 앱 화면 없이 재생 엔진만 깨어났을 때: 위젯 ↔ 앱 통로를 위젯이 직접 연결\n'
     '        /// (그래야 다음 누름부터 바로 전달되고, 곡·방송 이름도 위젯에 뜸)\n'
     '        /// 나중에 앱 화면이 열리면 앱이 자기 통로로 다시 바꿔 끼움\n'
     '        fun attachHeadless(context: Context, tries: Int = 0) {\n'
     '            if (MainActivity.mediaChannel != null) return\n'
     '            val app = context.applicationContext\n'
     '            val engine = FlutterEngineCache.getInstance().get(AudioServicePlugin.getFlutterEngineId())\n'
     '            if (engine == null) {\n'
     '                if (tries < 40) android.os.Handler(android.os.Looper.getMainLooper())\n'
     '                    .postDelayed({ attachHeadless(app, tries + 1) }, 250)\n'
     '                return\n'
     '            }\n'
     '            val ch = MethodChannel(engine.dartExecutor.binaryMessenger, "kr.ssing.catsong/media")\n'
     '            ch.setMethodCallHandler { call, result ->\n'
     '                if (call.method == "updateWidget") {\n'
     '                    val mgr = AppWidgetManager.getInstance(app)\n'
     '                    val ids = mgr.getAppWidgetIds(android.content.ComponentName(app, PlayerWidget::class.java))\n'
     '                    for (id in ids) updateAppWidget(app, mgr, id,\n'
     '                        call.argument<String>("title") ?: "파란소리",\n'
     '                        call.argument<String>("artist") ?: "",\n'
     '                        call.argument<Boolean>("isPlaying") ?: false,\n'
     '                        call.argument<String>("schedule") ?: "")\n'
     '                    result.success(null)\n'
     '                } else {\n'
     '                    result.notImplemented()\n'
     '                }\n'
     '            }\n'
     '            MainActivity.mediaChannel = ch\n'
     '            android.util.Log.d("PARAN_W", "엔진만 깨어남 → 위젯 통로 연결")\n'
     '        }\n'),

    ('위젯: 진짜 이름이 오면 \'불러오는 중\' 끝내기',
     '                    .putBoolean("p", isPlaying ?: false).putString("s", schedule).apply()\n'
     '            }\n',
     '                    .putBoolean("p", isPlaying ?: false).putString("s", schedule).apply()\n'
     '                // 소리가 나기 시작하면 끝 (다른 걸 듣다 바꾼 경우엔 어떤 소식이든 오면 끝)\n'
     '                if (isPlaying == true || p.getBoolean("load_any", false)) p.edit().remove("load").apply()\n'
     '            }\n'
     '            val loadAt = p.getLong("load", 0L)\n'
     '            val loading = loadAt > 0 && System.currentTimeMillis() - loadAt in 0 until LOAD_MAX\n'),

    ('위젯: \'불러오는 중…\' 그리기',
     '            views.setTextViewText(R.id.widget_title, if (empty) "파란소리" else t)\n'
     '            views.setTextViewText(R.id.widget_artist, if (empty) "음악 · 라디오 · 자연을 들어보세요" else a)\n'
     '            views.setTextViewText(R.id.widget_schedule, s)\n'
     '            views.setViewVisibility(R.id.widget_schedule, if (s.isEmpty()) View.GONE else View.VISIBLE)\n'
     '            views.setImageViewResource(R.id.widget_play_pause,\n'
     '                if (playing) R.drawable.paran_ic_pause else R.drawable.paran_ic_play)\n',
     '            views.setTextViewText(R.id.widget_title,\n'
     '                if (loading) "불러오는 중…" else if (empty) "파란소리" else t)\n'
     '            views.setTextViewText(R.id.widget_artist,\n'
     '                if (loading) "잠시만 기다려 주세요" else if (empty) "음악 · 라디오 · 자연을 들어보세요" else a)\n'
     '            views.setTextViewText(R.id.widget_schedule, s)\n'
     '            views.setViewVisibility(R.id.widget_schedule, if (loading || s.isEmpty()) View.GONE else View.VISIBLE)\n'
     '            views.setImageViewResource(R.id.widget_play_pause,\n'
     '                if (playing || loading) R.drawable.paran_ic_pause else R.drawable.paran_ic_play)\n'),
])

# ───────── widget_player.xml: 누르는 자리 크게 (아이콘 크기는 그대로) ─────────
edit(lay, [
    ('위젯 모양: 이전 버튼 자리 크게',
     '            <ImageView\n'
     '                android:id="@+id/widget_prev"\n'
     '                android:layout_width="34dp"\n'
     '                android:layout_height="34dp"\n'
     '                android:padding="7dp"\n',
     '            <ImageView\n'
     '                android:id="@+id/widget_prev"\n'
     '                android:layout_width="40dp"\n'
     '                android:layout_height="40dp"\n'
     '                android:padding="10dp"\n'),
    ('위젯 모양: 재생 버튼 자리 크게',
     '                android:layout_width="38dp"\n'
     '                android:layout_height="38dp"\n'
     '                android:layout_marginStart="2dp"\n'
     '                android:layout_marginEnd="2dp"\n'
     '                android:background="@drawable/paran_widget_play"\n'
     '                android:padding="9dp"\n',
     '                android:layout_width="42dp"\n'
     '                android:layout_height="42dp"\n'
     '                android:layout_marginStart="2dp"\n'
     '                android:layout_marginEnd="2dp"\n'
     '                android:background="@drawable/paran_widget_play"\n'
     '                android:padding="11dp"\n'),
    ('위젯 모양: 다음 버튼 자리 크게',
     '            <ImageView\n'
     '                android:id="@+id/widget_next"\n'
     '                android:layout_width="34dp"\n'
     '                android:layout_height="34dp"\n'
     '                android:padding="7dp"\n',
     '            <ImageView\n'
     '                android:id="@+id/widget_next"\n'
     '                android:layout_width="40dp"\n'
     '                android:layout_height="40dp"\n'
     '                android:padding="10dp"\n'),
])

# ───────── radio_provider.dart: 위젯 둘째 줄 ─────────
edit(rp, [
    ('라디오: 틀 때 영어 나라 이름 대신 방송 설명',
     "_updateWidget(station.name, station.country ?? '', true);",
     "_updateWidget(station.name, _mediaSubtitle(station), true);", None),
    ('라디오: 편성표 받은 뒤에도 방송 설명',
     "_updateWidget(stationName, _currentStation?.country ?? '', true);",
     "_updateWidget(stationName, _currentStation == null ? '' : _mediaSubtitle(_currentStation!), true);", None),
    ('라디오: 지금 프로그램 기억할 곳',
     '  void _updateNotification(String stationName) {\n',
     '  /// 위젯 둘째 줄에 쓸 지금 프로그램 (방송 이름 → "프로그램 9:00~11:00")\n'
     '  final Map<String, String> _widgetProgram = {};\n'
     '\n'
     '  void _updateNotification(String stationName) {\n'),
    ('라디오: 지금 프로그램 기억하기',
     '    // 위젯에도 지금 하는 프로그램 (늦게 도착해도 바로 바뀌게)\n',
     '    // 위젯에도 지금 하는 프로그램 (늦게 도착해도 바로 바뀌게)\n'
     '    _widgetProgram[stationName] = artist;\n'),
    ('라디오: 위젯 그릴 때 프로그램 있으면 그걸로 (나중에 덮어써도 안 사라지게)',
     "        'artist': schedule.isNotEmpty ? schedule : artist,\n",
     "        'artist': schedule.isNotEmpty ? schedule : (_widgetProgram[title] ?? artist),\n"),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요'); sys.exit(1)
if already == total:
    print('\n이미 적용돼 있어요'); sys.exit(0)

# 백업은 프로젝트 밖에 (res 폴더 안에 백업이 있으면 빌드가 깨짐)
BK = os.path.join('..', 'paransori_backup_widget_loading')
for p, (text, c) in writes.items():
    b = os.path.join(BK, p)
    os.makedirs(os.path.dirname(b), exist_ok=True)
    shutil.copyfile(p, b)
    out = text.replace('\n', '\r\n') if c else text
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (백업: ../paransori_backup_widget_loading)')
