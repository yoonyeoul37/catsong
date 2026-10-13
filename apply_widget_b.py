# -*- coding: utf-8 -*-
# 홈 위젯 B안 (4×2): 위 = 시간대 라디오 사진 + 지금 듣는 것 + 재생 버튼 / 아래 = 음악·라디오·자연·수면 바로가기
# 바로가기를 누르면 앱이 열리며 그 화면으로 (꺼져 있었으면 첫인사 건너뜀)
# 새로 필요한 파일(그림·색·위젯 코드)도 이 스크립트가 알아서 만들어요
import os, re, sys, shutil

def find(name, top):
    for root, _, files in os.walk(top):
        if name in files:
            return os.path.join(root, name)
    return None

def load(p):
    raw = open(p, 'rb').read().decode('utf-8')
    return raw.replace('\r\n', '\n'), ('\r\n' in raw)

if not os.path.isdir('lib') or not os.path.isdir('android'):
    print('❌ 프로젝트 폴더(mp3_player_new)에서 실행해 주세요'); sys.exit(1)

kt_widget = find('PlayerWidget.kt', 'android')
if not kt_widget:
    print('❌ PlayerWidget.kt 를 못 찾았어요'); sys.exit(1)
if 'paran_ic_play' in open(kt_widget, encoding='utf-8').read():
    print('이미 적용돼 있어요'); sys.exit(0)

MAIN = os.path.join('android', 'app', 'src', 'main')
RES = os.path.join(MAIN, 'res')
writes = {}      # 경로 → (내용, crlf)
ok = True

def edit(path_name, top, pairs):
    """찾아 바꾸기 (하나라도 못 찾으면 실패)"""
    global ok
    p = find(path_name, top)
    if not p:
        print('❌ %s 를 못 찾았어요' % path_name); ok = False; return
    src, crlf = writes[p] if p in writes else load(p)
    for label, old, new, cnt in pairs:
        n = src.count(old)
        if n != cnt:
            print('❌ %s (찾은 개수 %d)' % (label, n)); ok = False; continue
        src = src.replace(old, new)
        print('✔ %s' % label)
    writes[p] = (src, crlf)

def new_file(path, text, label):
    writes[path] = (text, True)
    print('✔ %s (새 파일)' % label)

# ───────── 1) 위젯 코드 (PlayerWidget.kt 새로) ─────────
new_file(kt_widget, r'''package kr.ssing.catsong

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

/// 홈 위젯 B안 (4×2)
/// 위: 시간대 라디오 사진 위에 지금 듣는 것 + 이전·재생·다음
/// 아래: 음악 · 라디오 · 자연 · 수면 바로가기 (누르면 앱이 그 화면으로 열림)
class PlayerWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) updateAppWidget(context, appWidgetManager, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val keyCode = when (intent.action) {
            ACTION_PLAY_PAUSE -> android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            ACTION_NEXT -> android.view.KeyEvent.KEYCODE_MEDIA_NEXT
            ACTION_PREV -> android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else -> return
        }
        sendMediaKey(context, keyCode)
    }

    companion object {
        const val ACTION_PLAY_PAUSE = "kr.ssing.catsong.PLAY_PAUSE"
        const val ACTION_NEXT = "kr.ssing.catsong.NEXT"
        const val ACTION_PREV = "kr.ssing.catsong.PREV"
        private const val PREFS = "paran_widget"

        /// 재생·다음·이전 → 앱의 미디어 버튼으로 (음악·라디오·자연 모두)
        fun sendMediaKey(context: Context, keyCode: Int) {
            for (a in intArrayOf(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.ACTION_UP)) {
                context.sendBroadcast(Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                    putExtra(Intent.EXTRA_KEY_EVENT, android.view.KeyEvent(a, keyCode))
                    setPackage(context.packageName)
                })
            }
        }

        /// 곡 정보가 오면 기억해 두고, 없으면(시간대 바뀔 때 등) 기억한 걸로 다시 그림
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            title: String? = null,
            artist: String? = null,
            isPlaying: Boolean? = null,
            schedule: String = ""
        ) {
            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (title != null) {
                p.edit().putString("t", title).putString("a", artist ?: "")
                    .putBoolean("p", isPlaying ?: false).putString("s", schedule).apply()
            }
            val t = p.getString("t", null)
            val a = p.getString("a", null) ?: ""
            val s = p.getString("s", null) ?: ""
            val playing = p.getBoolean("p", false)
            val empty = t == null || t == "플레이쏭" || t == "캣송"

            val views = RemoteViews(context.packageName, R.layout.widget_player)
            views.setTextViewText(R.id.widget_title, if (empty) "파란소리" else t)
            views.setTextViewText(R.id.widget_artist, if (empty) "음악 · 라디오 · 자연을 들어보세요" else a)
            views.setTextViewText(R.id.widget_schedule, s)
            views.setViewVisibility(R.id.widget_schedule, if (s.isEmpty()) View.GONE else View.VISIBLE)
            views.setImageViewResource(R.id.widget_play_pause,
                if (playing) R.drawable.paran_ic_pause else R.drawable.paran_ic_play)
            photo(context)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }

            // 사진 부분 누르면 앱 열기
            val open = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_top, PendingIntent.getActivity(
                context, 0, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))

            // 이전 · 재생 · 다음 (이 위젯에게만 보내기 → 두 번 눌리는 일 없게)
            fun media(action: String, code: Int) = PendingIntent.getBroadcast(
                context, code, Intent(context, PlayerWidget::class.java).setAction(action),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_prev, media(ACTION_PREV, 1))
            views.setOnClickPendingIntent(R.id.widget_play_pause, media(ACTION_PLAY_PAUSE, 2))
            views.setOnClickPendingIntent(R.id.widget_next, media(ACTION_NEXT, 3))

            // 바로가기 4개
            val go = listOf(
                R.id.widget_go_music to "music",
                R.id.widget_go_radio to "radio",
                R.id.widget_go_nature to "nature",
                R.id.widget_go_sleep to "sleep"
            )
            go.forEachIndexed { i, (viewId, target) ->
                val goIntent = Intent(context, MainActivity::class.java).apply {
                    action = "kr.ssing.catsong.WIDGET_GO_$target" // 버튼마다 다른 이름 (안 섞이게)
                    putExtra("widgetGo", target)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                views.setOnClickPendingIntent(viewId, PendingIntent.getActivity(
                    context, 20 + i, goIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /// 지금 시간대 라디오 사진 (아침 5–11 · 낮 11–17 · 저녁 17–22 · 밤)
        /// 위젯 띠 모양으로 자르고, 모서리 둥글게, 아래쪽은 글자가 보이게 살짝 어둡게
        private fun photo(context: Context): Bitmap? {
            val h = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            val slot = when (h) {
                in 5..10 -> "morning"
                in 11..16 -> "day"
                in 17..21 -> "evening"
                else -> "night"
            }
            val path = "flutter_assets/assets/radio_media_$slot.jpg"
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                context.assets.open(path).use { BitmapFactory.decodeStream(it, null, bounds) }
                var sample = 1
                while (bounds.outWidth / (sample * 2) >= 560) sample *= 2
                val src = context.assets.open(path).use {
                    BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
                } ?: return null
                val w = src.width
                val bh = (w / 2.2f).toInt().coerceAtMost(src.height)
                val top = ((src.height - bh) * 0.35f).toInt()
                val out = Bitmap.createBitmap(w, bh, Bitmap.Config.ARGB_8888)
                val c = Canvas(out)
                val r = w * 0.05f
                c.clipPath(Path().apply {
                    addRoundRect(RectF(0f, 0f, w.toFloat(), bh.toFloat()), r, r, Path.Direction.CW)
                })
                c.drawBitmap(src, Rect(0, top, w, top + bh), Rect(0, 0, w, bh), Paint(Paint.FILTER_BITMAP_FLAG))
                c.drawRect(0f, 0f, w.toFloat(), bh.toFloat(), Paint().apply {
                    shader = LinearGradient(0f, bh * 0.25f, 0f, bh.toFloat(),
                        0x00000000, 0x99000000.toInt(), Shader.TileMode.CLAMP)
                })
                src.recycle()
                out
            } catch (e: Exception) {
                null
            }
        }
    }
}
''', '위젯 코드 PlayerWidget.kt')

# ───────── 2) 위젯 모양 (widget_player.xml 새로) ─────────
lay = find('widget_player.xml', RES)
if not lay:
    print('❌ widget_player.xml 를 못 찾았어요'); sys.exit(1)

def shortcut(vid, icon, label):
    return f'''
        <LinearLayout
            android:id="@+id/{vid}"
            android:layout_width="0dp"
            android:layout_height="match_parent"
            android:layout_weight="1"
            android:layout_marginStart="3dp"
            android:layout_marginEnd="3dp"
            android:background="@drawable/paran_widget_chip"
            android:gravity="center"
            android:orientation="vertical">

            <ImageView
                android:layout_width="18dp"
                android:layout_height="18dp"
                android:src="@drawable/{icon}"
                android:tint="@color/paran_w_sub" />

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginTop="2dp"
                android:text="{label}"
                android:textColor="@color/paran_w_ink"
                android:textSize="11sp" />
        </LinearLayout>
'''

new_file(lay, '''<?xml version="1.0" encoding="utf-8"?>
<!-- 홈 위젯 B안: 위 사진 + 지금 듣는 것 / 아래 바로가기 4개 -->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/paran_widget_bg"
    android:orientation="vertical"
    android:padding="8dp">

    <!-- 위: 시간대 라디오 사진 + 글자 + 버튼 -->
    <FrameLayout
        android:id="@+id/widget_top"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1">

        <ImageView
            android:id="@+id/widget_photo"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:scaleType="centerCrop"
            android:src="@drawable/paran_widget_photo_empty" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:layout_gravity="top|start"
            android:layout_marginStart="12dp"
            android:layout_marginTop="8dp"
            android:shadowColor="#66000000"
            android:shadowDy="1"
            android:shadowRadius="4"
            android:text="Paransori"
            android:textColor="#F2FFFFFF"
            android:textSize="11.5sp"
            android:textStyle="bold" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_gravity="bottom"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="12dp"
            android:paddingEnd="6dp"
            android:paddingBottom="8dp">

            <LinearLayout
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:orientation="vertical">

                <TextView
                    android:id="@+id/widget_title"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:shadowColor="#66000000"
                    android:shadowDy="1"
                    android:shadowRadius="4"
                    android:text="파란소리"
                    android:textColor="#FFFFFF"
                    android:textSize="14.5sp"
                    android:textStyle="bold" />

                <TextView
                    android:id="@+id/widget_artist"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:shadowColor="#66000000"
                    android:shadowDy="1"
                    android:shadowRadius="4"
                    android:text="음악 · 라디오 · 자연을 들어보세요"
                    android:textColor="#D9FFFFFF"
                    android:textSize="11.5sp" />

                <TextView
                    android:id="@+id/widget_schedule"
                    android:layout_width="match_parent"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:maxLines="1"
                    android:text=""
                    android:textColor="#B3FFFFFF"
                    android:textSize="10.5sp"
                    android:visibility="gone" />
            </LinearLayout>

            <ImageView
                android:id="@+id/widget_prev"
                android:layout_width="34dp"
                android:layout_height="34dp"
                android:padding="7dp"
                android:src="@drawable/paran_ic_prev"
                android:tint="#FFFFFF" />

            <ImageView
                android:id="@+id/widget_play_pause"
                android:layout_width="38dp"
                android:layout_height="38dp"
                android:layout_marginStart="2dp"
                android:layout_marginEnd="2dp"
                android:background="@drawable/paran_widget_play"
                android:padding="9dp"
                android:src="@drawable/paran_ic_play"
                android:tint="#17140F" />

            <ImageView
                android:id="@+id/widget_next"
                android:layout_width="34dp"
                android:layout_height="34dp"
                android:padding="7dp"
                android:src="@drawable/paran_ic_next"
                android:tint="#FFFFFF" />
        </LinearLayout>
    </FrameLayout>

    <!-- 아래: 바로가기 4개 -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="46dp"
        android:layout_marginTop="6dp"
        android:orientation="horizontal">
''' + shortcut('widget_go_music', 'paran_ic_music', '음악')
    + shortcut('widget_go_radio', 'paran_ic_radio', '라디오')
    + shortcut('widget_go_nature', 'paran_ic_leaf', '자연')
    + shortcut('widget_go_sleep', 'paran_ic_moon', '수면') + '''
    </LinearLayout>
</LinearLayout>
''', '위젯 모양 widget_player.xml')

# ───────── 3) 위젯 크기 정보 (4×2) ─────────
info = find('widget_info.xml', RES)
if not info:
    print('❌ widget_info.xml 를 못 찾았어요'); sys.exit(1)
new_file(info, '''<?xml version="1.0" encoding="utf-8"?>
<!-- 홈 위젯 B안: 4×2 (사진이 시간대에 맞게 30분마다 바뀜) -->
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:minResizeWidth="180dp"
    android:minResizeHeight="110dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/widget_player"
    android:previewLayout="@layout/widget_player"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen">
</appwidget-provider>
''', '위젯 크기 widget_info.xml')

# ───────── 4) 그림 (모양·아이콘) ─────────
DR = os.path.join(RES, 'drawable')
def shape(name, xml):
    new_file(os.path.join(DR, name + '.xml'), '<?xml version="1.0" encoding="utf-8"?>\n' + xml, name)
shape('paran_widget_bg', '''<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="@color/paran_w_bg" />
    <corners android:radius="22dp" />
</shape>
''')
shape('paran_widget_chip', '''<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="@color/paran_w_chip" />
    <corners android:radius="12dp" />
</shape>
''')
shape('paran_widget_play', '''<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="oval">
    <solid android:color="#FFFFFF" />
</shape>
''')
shape('paran_widget_photo_empty', '''<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#2C3A55" />
    <corners android:radius="16dp" />
</shape>
''')
ICONS = {
    'paran_ic_play': 'M8,5v14l11,-7z',
    'paran_ic_pause': 'M6,19h4V5H6v14zM14,5v14h4V5h-4z',
    'paran_ic_next': 'M6,18l8.5,-6L6,6v12zM16,6v12h2V6h-2z',
    'paran_ic_prev': 'M6,6h2v12H6zM9.5,12l8.5,6V6z',
    'paran_ic_music': 'M12,3v10.55c-0.59,-0.34 -1.27,-0.55 -2,-0.55 -2.21,0 -4,1.79 -4,4s1.79,4 4,4 4,-1.79 4,-4V7h4V3h-6z',
    'paran_ic_radio': 'M3.24,6.15C2.51,6.43 2,7.17 2,8v12c0,1.1 0.89,2 2,2h16c1.11,0 2,-0.9 2,-2V8c0,-1.11 -0.89,-2 -2,-2H8.3l8.26,-3.34L15.88,1 3.24,6.15zM7,20c-1.66,0 -3,-1.34 -3,-3s1.34,-3 3,-3 3,1.34 3,3 -1.34,3 -3,3zM20,12h-2v-2h-2v2H4V8h16v4z',
    'paran_ic_leaf': 'M6.05,8.05c-2.73,2.73 -2.73,7.15 -0.02,9.88c1.47,-3.4 4.09,-6.24 7.36,-7.93c-2.77,2.34 -4.71,5.61 -5.39,9.32c2.6,1.23 5.8,0.78 7.95,-1.37C19.43,14.47 20,4 20,4S9.53,4.57 6.05,8.05z',
    'paran_ic_moon': 'M12.34,2.02C6.59,1.82 2,6.42 2,12c0,5.52 4.48,10 10,10c3.71,0 6.93,-2.02 8.66,-5.02C13.15,16.73 8.57,8.55 12.34,2.02z',
}
for n, d in ICONS.items():
    shape(n, f'''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path android:fillColor="#FFFFFFFF" android:pathData="{d}" />
</vector>
''')

# ───────── 5) 색 (라이트 / 다크) ─────────
edit('colors.xml', os.path.join(RES, 'values'), [
    ('위젯 색 (라이트)', '</resources>', '''    <!-- 홈 위젯 (라이트) -->
    <color name="paran_w_bg">#F4EFE5</color>
    <color name="paran_w_chip">#FFFFFF</color>
    <color name="paran_w_ink">#17140F</color>
    <color name="paran_w_sub">#5A5348</color>
</resources>''', 1),
])
new_file(os.path.join(RES, 'values-night', 'colors.xml'), '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- 홈 위젯 (다크) -->
    <color name="paran_w_bg">#24221F</color>
    <color name="paran_w_chip">#32302C</color>
    <color name="paran_w_ink">#F3EFE7</color>
    <color name="paran_w_sub">#CFC8BB</color>
</resources>
''', '위젯 색 (다크) values-night/colors.xml')

# ───────── 6) 예전 위젯 2·3: 버튼이 세 번 눌리던 것 고치기 ─────────
for n in ('PlayerWidget2', 'PlayerWidget3'):
    pairs = []
    for act in ('PREV', 'PLAY_PAUSE', 'NEXT'):
        pairs.append(('%s - %s 버튼은 자기한테만' % (n, act),
                      'Intent(PlayerWidget.ACTION_%s).apply { setPackage(context.packageName) }' % act,
                      'Intent(context, %s::class.java).setAction(PlayerWidget.ACTION_%s)' % (n, act), 1))
    edit(n + '.kt', 'android', pairs)

# ───────── 7) MainActivity: 바로가기로 열렸는지 앱에 알려주기 ─────────
edit('MainActivity.kt', 'android', [
    ('바로가기 기억 칸',
     '    private var pendingAlarm = false // 알람 때문에 켜졌는지 (앱이 물어보면 알려주고 지움)\n',
     '    private var pendingAlarm = false // 알람 때문에 켜졌는지 (앱이 물어보면 알려주고 지움)\n'
     '    private var pendingWidgetGo: String? = null // 홈 위젯 바로가기로 켜졌으면 어느 화면인지\n', 1),
    ('앱 켤 때 바로가기 확인',
     '        handleAlarmIntent(intent)\n        handleHeadsetIntent(intent)\n    }\n',
     '        handleAlarmIntent(intent)\n        handleHeadsetIntent(intent)\n        handleWidgetGo(intent, false)\n    }\n', 1),
    ('켜져 있을 때 바로가기',
     '        handleHomeIntent(intent)\n    }\n',
     '''        handleHomeIntent(intent)
        handleWidgetGo(intent, true)
    }

    /// 홈 위젯 바로가기 (음악·라디오·자연·수면)
    /// 꺼져 있다 켜졌으면 기억만 (앱이 물어봄) / 켜져 있으면 바로 앱에 알림
    private fun handleWidgetGo(i: android.content.Intent?, running: Boolean) {
        val target = i?.getStringExtra("widgetGo") ?: return
        i.removeExtra("widgetGo")
        if (running && flutterMethodChannel != null) {
            flutterMethodChannel?.invokeMethod("widgetGo", target)
        } else {
            pendingWidgetGo = target
        }
    }
''', 1),
    ('앱이 물어보면 알려주기',
     '                "widgetPlayPause" -> { result.success(true) }\n',
     '''                "takeWidgetGo" -> {
                    val t = pendingWidgetGo
                    pendingWidgetGo = null
                    result.success(t)
                }
                "widgetPlayPause" -> { result.success(true) }
''', 1),
])

# ───────── 8) 앱(다트) 쪽 ─────────
new_file(os.path.join('lib', 'utils', 'widget_go.dart'), '''import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 홈 위젯 바로가기 (music · radio · nature · sleep)
/// 눌러서 앱이 열리면 홈 화면이 이 값을 보고 그 화면으로 감
class WidgetGo {
  static final target = ValueNotifier<String?>(null);

  /// 앱이 꺼져 있다가 위젯 바로가기로 켜졌는지 (켤 때 한 번 물어봄)
  static Future<void> loadLaunch() async {
    try {
      final t = await const MethodChannel('kr.ssing.catsong/media').invokeMethod<String>('takeWidgetGo');
      if (t != null && t.isNotEmpty) target.value = t;
    } catch (_) {}
  }

  /// 가져가고 비우기
  static String? take() {
    final t = target.value;
    target.value = null;
    return t;
  }
}
''', 'lib/utils/widget_go.dart')

edit('main.dart', 'lib', [
    ('불러오기', "import 'utils/greeting_images.dart';\n",
     "import 'utils/greeting_images.dart';\nimport 'utils/widget_go.dart';\n", 1),
    ('켤 때 위젯 바로가기 확인',
     '  await initGreetingScene(); // 첫인사·끝인사 오늘 장면 (지난번과 다르게)\n',
     '  await initGreetingScene(); // 첫인사·끝인사 오늘 장면 (지난번과 다르게)\n'
     '  await WidgetGo.loadLaunch(); // 홈 위젯 바로가기로 켜졌는지\n', 1),
    ('위젯 바로가기로 켜졌으면 첫인사 건너뛰기',
     '  bool _showIntro = !AlarmService.launchedByAlarm; // 알람으로 켜졌으면 인트로 없이 바로\n',
     '  // 알람이나 홈 위젯 바로가기로 켜졌으면 첫인사 없이 바로\n'
     '  bool _showIntro = !AlarmService.launchedByAlarm && WidgetGo.target.value == null;\n', 1),
])

edit('player_provider.dart', os.path.join('lib', 'providers'), [
    ('불러오기', "import '../utils/no_album_helper.dart';\n",
     "import '../utils/no_album_helper.dart';\nimport '../utils/widget_go.dart';\n", 1),
    ('앱이 켜져 있을 때 위젯 바로가기 받기',
     "        case 'onAudioFocusGain':\n",
     "        case 'widgetGo':\n"
     "          WidgetGo.target.value = call.arguments as String?; // 홈 위젯 바로가기\n"
     "          break;\n"
     "        case 'onAudioFocusGain':\n", 1),
    ('위젯 기본 문구 (플레이쏭 → 파란소리)',
     "        'title': song?.titleDisplay ?? '플레이쏭',\n        'artist': song?.artistDisplay ?? '음악을 재생해보세요',\n",
     "        'title': song?.titleDisplay ?? '파란소리',\n        'artist': song?.artistDisplay ?? '음악 · 라디오 · 자연을 들어보세요',\n", 1),
])

edit('home_screen.dart', os.path.join('lib', 'screens'), [
    ('불러오기', "import '../utils/no_album_helper.dart';\n",
     "import '../utils/no_album_helper.dart';\nimport '../utils/widget_go.dart';\n", 1),
    ('위젯 바로가기 듣기 시작',
     "    _loadRecentSearches();\n",
     "    _loadRecentSearches();\n    WidgetGo.target.addListener(_onWidgetGo); // 앱이 켜져 있을 때 위젯 바로가기\n", 1),
    ('위젯 바로가기 듣기 끝',
     "    _searchController.dispose();\n    _recentSaveTimer?.cancel();\n",
     "    WidgetGo.target.removeListener(_onWidgetGo);\n    _searchController.dispose();\n    _recentSaveTimer?.cancel();\n", 1),
    ('켤 때 위젯 바로가기가 먼저',
     "      await _navigateToSavedStartScreen();\n    });\n  }\n",
     "      // 위젯 바로가기로 켜졌으면 그 화면으로, 아니면 정해 둔 시작 화면으로\n"
     "      if (WidgetGo.target.value != null) {\n"
     "        await _handleWidgetGo();\n"
     "      } else {\n"
     "        await _navigateToSavedStartScreen();\n"
     "      }\n"
     "    });\n  }\n\n"
     "  void _onWidgetGo() {\n"
     "    if (WidgetGo.target.value != null && mounted) _handleWidgetGo();\n"
     "  }\n\n"
     "  /// 홈 위젯 바로가기: 열려 있던 화면을 닫고 고른 화면으로\n"
     "  Future<void> _handleWidgetGo() async {\n"
     "    final t = WidgetGo.take();\n"
     "    if (t == null || !mounted) return;\n"
     "    Navigator.of(context).popUntil((r) => r.isFirst);\n"
     "    setState(() => _pendingStartScreenNav = false);\n"
     "    PageRouteBuilder<void> instant(Widget page) => PageRouteBuilder(\n"
     "          pageBuilder: (_, __, ___) => page,\n"
     "          transitionsBuilder: (_, __, ___, child) => child,\n"
     "          transitionDuration: Duration.zero,\n"
     "          reverseTransitionDuration: Duration.zero,\n"
     "        );\n"
     "    switch (t) {\n"
     "      case 'music':\n"
     "        setState(() => _showMusicLibrary = true);\n"
     "        break;\n"
     "      case 'radio':\n"
     "        await pushRadioEntry(context, instant: true);\n"
     "        break;\n"
     "      case 'nature':\n"
     "        await Navigator.push(context, instant(NatureSoundsScreen()));\n"
     "        break;\n"
     "      case 'sleep':\n"
     "        await Navigator.push(context, instant(const SleepFocusScreen()));\n"
     "        break;\n"
     "    }\n"
     "  }\n", 1),
])

if not ok:
    print('\n하나라도 못 찾아서 아무것도 저장 안 했어요')
    sys.exit(1)

# 백업은 res 폴더 안에 두면 빌드 오류가 나서 따로 한 곳에 모아 둠
BK = '_backup_widget'
for p, (src, crlf) in writes.items():
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if os.path.exists(p):
        b = os.path.join(BK, p)
        os.makedirs(os.path.dirname(b), exist_ok=True)
        shutil.copyfile(p, b)
    out = src.replace('\n', '\r\n') if crlf else src
    open(p, 'wb').write(out.encode('utf-8'))
print('\n저장했어요 (%d개 파일, 원래 있던 건 _backup_widget 폴더에 백업)' % len(writes))
