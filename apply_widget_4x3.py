# 홈 위젯 4×3 (지금 위젯 + 아래에 최근에 들은 것 3개) 만들기
# - 옛날 위젯 2번(캣송 시절) 자리에 새 4×3 위젯
# - 옛날 위젯 3번은 지움
# - 최근 줄을 누르면 앱을 안 열고 바로 재생
# 하나라도 ❌ 이면 아무것도 저장 안 함
import os, sys

ROOT = os.getcwd()
SKIP = ("backup", "build", ".dart_tool", ".gradle", ".git", ".idea")


def find(name, under=""):
    hits = []
    base = os.path.join(ROOT, under)
    for d, dirs, files in os.walk(base):
        dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
        if name in files:
            hits.append(os.path.normpath(os.path.join(d, name)))  # 윈도우 \ / 섞임 방지
    return hits


def one(name, under=""):
    hits = find(name, under)
    if len(hits) != 1:
        print(f"❌ {name} 을(를) {'못 찾았어요' if not hits else '여러 개 찾았어요: ' + ', '.join(hits)}")
        return None
    return hits[0]


def read(p):
    raw = open(p, "rb").read().decode("utf-8")
    crlf = "\r\n" in raw
    return raw.replace("\r\n", "\n"), crlf


ok = True
out = {}      # 경로 → (내용, crlf)
dels = []     # 지울 파일


def edit(path, src, pairs, label):
    """pairs: [(찾을, 바꿀, 설명)]"""
    global ok
    for old, new, what in pairs:
        if src.count(old) != 1:
            print(f"❌ {label}: {what} (찾을 코드 {src.count(old)}곳)")
            ok = False
            continue
        src = src.replace(old, new)
        print(f"✔ {label}: {what}")
    return src


MAIN = "android/app/src/main"

# ───────── 이미 했는지 먼저 ─────────
pw = one("PlayerWidget.kt", MAIN)
if pw is None:
    sys.exit(1)
pw_src, pw_crlf = read(pw)
if "fun recentRows" in pw_src:
    print("이미 적용돼 있어요")
    sys.exit(0)

# ───────── 1. PlayerWidget.kt ─────────
RECENT_FN = '''        /// 4×3 위젯: '최근에 들었어요' 3개 (지금 위에 나오는 건 빼고) — 누르면 바로 재생
        /// 돌려주는 값: 아래 칸 높이(dp) → 사진 칸 크기 맞추기용 (위 4 + 아래 10 + 줄마다 40)
        private fun recentRows(context: Context, views: RemoteViews, now: String?): Int {
            val rows = arrayOf(
                intArrayOf(R.id.widget_recent1, R.id.widget_recent1_icon, R.id.widget_recent1_title, R.id.widget_recent1_sub),
                intArrayOf(R.id.widget_recent2, R.id.widget_recent2_icon, R.id.widget_recent2_title, R.id.widget_recent2_sub),
                intArrayOf(R.id.widget_recent3, R.id.widget_recent3_icon, R.id.widget_recent3_title, R.id.widget_recent3_sub)
            )
            // 앱이 저장해 둔 '최근에 들었어요' 목록 (음악·라디오·자연만)
            val list = mutableListOf<org.json.JSONObject>()
            try {
                val raw = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    .getString("flutter.recent_content_v1", null)
                if (raw != null) {
                    val arr = org.json.JSONArray(raw)
                    for (i in 0 until arr.length()) {
                        val o = arr.getJSONObject(i)
                        val type = o.optString("type")
                        if (type != "music" && type != "radio" && type != "nature") continue
                        if (now != null && o.optString("title") == now) continue
                        list.add(o)
                        if (list.size == rows.size) break
                    }
                }
            } catch (_: Exception) {}
            rows.forEachIndexed { i, r ->
                val o = list.getOrNull(i)
                if (o == null) {
                    views.setViewVisibility(r[0], View.GONE)
                    return@forEachIndexed
                }
                val type = o.optString("type")
                views.setViewVisibility(r[0], View.VISIBLE)
                views.setImageViewResource(r[1], when (type) {
                    "radio" -> R.drawable.paran_ic_radio
                    "nature" -> R.drawable.paran_ic_leaf
                    else -> R.drawable.paran_ic_music
                })
                views.setTextViewText(r[2], o.optString("title"))
                views.setTextViewText(r[3], o.optString("subtitle"))
                // 아래 버튼(음악·라디오·자연)과 같은 길로 → 앱이 꺼져 있어도 바로 재생
                views.setOnClickPendingIntent(r[0], PendingIntent.getBroadcast(context, 40 + i,
                    Intent(context, PlayerWidget::class.java)
                        .setAction(ACTION_KIND + "recent:" + type + "|" + o.optString("key")),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            }
            views.setViewVisibility(R.id.widget_recent_empty, if (list.isEmpty()) View.VISIBLE else View.GONE)
            return 14 + 40 * maxOf(list.size, 1)
        }

'''

pw_src = edit(pw, pw_src, [
    ('''                } else if (call.method == "updateWidget") {
                    val mgr = AppWidgetManager.getInstance(app)
                    val ids = mgr.getAppWidgetIds(android.content.ComponentName(app, PlayerWidget::class.java))
                    for (id in ids) updateAppWidget(app, mgr, id,''',
     '''                } else if (call.method == "refreshWidget") {
                    refreshAll(app) // 최근에 들은 목록이 바뀜
                    result.success(null)
                } else if (call.method == "updateWidget") {
                    val mgr = AppWidgetManager.getInstance(app)
                    for (id in allIds(app)) updateAppWidget(app, mgr, id,''',
     "화면 없이 켜졌을 때도 두 위젯 다 그리기"),
    ('''        /// 바탕화면에 붙은 이 위젯 전부 다시 그리기 (앱이 켜지고 꺼질 때)
        fun refreshAll(context: Context) {
            try {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget::class.java))
                for (id in ids) updateAppWidget(context, mgr, id)
            } catch (_: Exception) {}
        }''',
     '''        /// 바탕화면에 붙은 파란소리 위젯 전부 (4×2 + 4×3)
        fun allIds(context: Context): IntArray {
            val mgr = AppWidgetManager.getInstance(context)
            return mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget::class.java)) +
                mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget2::class.java))
        }

        /// 바탕화면에 붙은 위젯 전부 다시 그리기 (앱이 켜지고 꺼질 때)
        fun refreshAll(context: Context) {
            try {
                val mgr = AppWidgetManager.getInstance(context)
                for (id in allIds(context)) updateAppWidget(context, mgr, id)
            } catch (_: Exception) {}
        }''',
     "다시 그릴 때 두 위젯 다"),
    ('''            val views = RemoteViews(context.packageName, R.layout.widget_player)
''',
     '''            // 4×3 위젯이면 큰 모양 (위는 똑같고, 아래에 최근에 들은 것)
            val big = appWidgetManager.getAppWidgetInfo(appWidgetId)?.provider?.className == PlayerWidget2::class.java.name
            val views = RemoteViews(context.packageName, if (big) R.layout.widget_player2 else R.layout.widget_player)
''',
     "4×3이면 큰 모양으로"),
    ('''            photo(context, appWidgetManager, appWidgetId)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }''',
     '''            // 4×3: 아래 '최근에 들었어요' 줄 (사진 칸 높이도 그만큼 빼기)
            val bottomDp = if (big) recentRows(context, views, if (empty) null else t) else 64
            photo(context, appWidgetManager, appWidgetId, bottomDp, big)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }''',
     "최근 줄 그리기"),
    ('''            go.forEachIndexed { i, (viewId, target) ->''',
     '''            if (!big) go.forEachIndexed { i, (viewId, target) -> // 바로가기는 4×2만''',
     "바로가기는 4×2만"),
    ('''        private fun photo(context: Context, mgr: AppWidgetManager, id: Int): Bitmap? {
            // 사진 칸 크기(dp): 위젯 크기 - 아래 바로가기 줄(46 + 위 8 + 아래 10)
            val opt = mgr.getAppWidgetOptions(id)
            val vw = opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
            val vh = ((opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 180) - 64)''',
     '''        private fun photo(context: Context, mgr: AppWidgetManager, id: Int, bottomDp: Int, big: Boolean): Bitmap? {
            // 사진 칸 크기(dp): 위젯 크기 - 아래 줄 (4×2 바로가기 64 · 4×3 최근에 들은 것)
            val opt = mgr.getAppWidgetOptions(id)
            val vw = opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
            val vh = ((opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: if (big) 280 else 180) - bottomDp)''',
     "사진 칸 크기 (4×3 맞춤)"),
    ('''        /// 지금 시간대 라디오 사진''',
     RECENT_FN + '''        /// 지금 시간대 라디오 사진''',
     "최근 줄 만드는 코드 넣기"),
], "PlayerWidget.kt")
out[pw] = (pw_src, pw_crlf)

# ───────── 2. PlayerWidget2.kt (옛날 → 새 4×3) ─────────
pw2 = one("PlayerWidget2.kt", MAIN)
if pw2:
    s, crlf = read(pw2)
    if "R.layout.widget_player2" in s and "PlayerWidget.updateAppWidget" not in s:
        out[pw2] = ('''package kr.ssing.catsong

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/// 홈 위젯 4×3: 4×2 위젯 + 아래에 최근에 들은 것 3개
/// 그리기·버튼은 모두 PlayerWidget이 같이 함 (모양만 큰 것)
class PlayerWidget2 : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) PlayerWidget.updateAppWidget(context, appWidgetManager, id)
    }

    // 바탕화면에서 위젯 크기를 바꾸면 사진도 새 크기에 맞게
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager,
                                           appWidgetId: Int, newOptions: android.os.Bundle) {
        PlayerWidget.updateAppWidget(context, appWidgetManager, appWidgetId)
    }
}
''', crlf)
        print("✔ PlayerWidget2.kt: 새 4×3 위젯으로 바꿈")
    else:
        print("❌ PlayerWidget2.kt: 예상한 옛날 파일이 아니에요")
        ok = False
else:
    ok = False

# ───────── 3. widget_player2.xml (위는 지금 위젯 그대로 + 아래 최근 3줄) ─────────
lay1 = one("widget_player.xml", MAIN + "/res")
lay2 = one("widget_player2.xml", MAIN + "/res")
if lay1 and lay2:
    s1, crlf = read(lay1)
    cut = "    <!-- 아래: 바로가기 4개 -->"
    if s1.count(cut) != 1:
        print("❌ widget_player.xml: 바로가기 시작 부분을 못 찾았어요")
        ok = False
    else:
        top = s1[:s1.index(cut)]
        top = top.replace("<!-- 홈 위젯 B안: 위 사진(위·양옆 꽉) + 지금 듣는 것 / 아래 바로가기 4개 -->",
                          "<!-- 홈 위젯 4×3: 위는 4×2 위젯과 똑같이 / 아래 최근에 들은 것 3개 -->")

        def row(n, icon, title, sub):
            return f'''
        <LinearLayout
            android:id="@+id/widget_recent{n}"
            android:layout_width="match_parent"
            android:layout_height="36dp"
            android:layout_marginTop="4dp"
            android:background="@drawable/paran_widget_chip"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="12dp"
            android:paddingEnd="12dp">

            <ImageView
                android:id="@+id/widget_recent{n}_icon"
                android:layout_width="16dp"
                android:layout_height="16dp"
                android:src="@drawable/{icon}"
                android:tint="@color/paran_w_sub" />

            <TextView
                android:id="@+id/widget_recent{n}_title"
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_marginStart="10dp"
                android:layout_weight="1"
                android:ellipsize="end"
                android:maxLines="1"
                android:text="{title}"
                android:textColor="@color/paran_w_ink"
                android:textSize="12.5sp" />

            <TextView
                android:id="@+id/widget_recent{n}_sub"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="8dp"
                android:ellipsize="end"
                android:maxLines="1"
                android:maxWidth="110dp"
                android:text="{sub}"
                android:textColor="@color/paran_w_sub"
                android:textSize="11sp" />
        </LinearLayout>
'''
        bottom = '''    <!-- 아래: 최근에 들은 것 3개 (누르면 바로 재생) — 높이를 바꾸면 PlayerWidget.kt recentRows 숫자도 같이 -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginStart="10dp"
        android:layout_marginTop="4dp"
        android:layout_marginEnd="10dp"
        android:layout_marginBottom="10dp"
        android:orientation="vertical">

        <TextView
            android:id="@+id/widget_recent_empty"
            android:layout_width="match_parent"
            android:layout_height="36dp"
            android:layout_marginTop="4dp"
            android:background="@drawable/paran_widget_chip"
            android:gravity="center"
            android:text="최근에 들은 게 여기에 나와요"
            android:textColor="@color/paran_w_sub"
            android:textSize="11.5sp"
            android:visibility="gone" />
''' + row(1, "paran_ic_music", "좋아하는 노래", "가수") \
    + row(2, "paran_ic_radio", "라디오 방송", "라디오") \
    + row(3, "paran_ic_leaf", "빗소리", "자연소리") + '''    </LinearLayout>
</LinearLayout>
'''
        out[lay2] = (top + bottom, crlf)
        print("✔ widget_player2.xml: 새 4×3 모양")
else:
    ok = False

# ───────── 4. widget_info2.xml ─────────
inf2 = one("widget_info2.xml", MAIN + "/res")
if inf2:
    _, crlf = read(inf2)
    out[inf2] = ('''<?xml version="1.0" encoding="utf-8"?>
<!-- 홈 위젯 4×3: 4×2 위젯 + 아래에 최근에 들은 것 3개 -->
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="180dp"
    android:minResizeWidth="180dp"
    android:minResizeHeight="180dp"
    android:targetCellWidth="4"
    android:targetCellHeight="3"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/widget_player2"
    android:previewLayout="@layout/widget_player2"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen">
</appwidget-provider>
''', crlf)
    print("✔ widget_info2.xml: 4×3 크기")
else:
    ok = False

# ───────── 5. MainActivity.kt ─────────
ma = one("MainActivity.kt", MAIN)
if ma:
    s, crlf = read(ma)
    s = edit(ma, s, [
        ('''                    val ids = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(this, PlayerWidget::class.java)
                    )
                    for (id in ids) {
                        PlayerWidget.updateAppWidget(this, appWidgetManager, id, title, artist, isPlaying, schedule)
                    }
                    val ids2 = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(this, PlayerWidget2::class.java)
                    )
                    for (id in ids2) {
                        PlayerWidget2.updateAppWidget(this, appWidgetManager, id, title, artist, isPlaying, schedule)
                    }
                    val ids3 = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(this, PlayerWidget3::class.java)
                    )
                    for (id in ids3) {
                        PlayerWidget3.updateAppWidget(this, appWidgetManager, id, title, artist, isPlaying, schedule)
                    }
''',
         '''                    for (id in PlayerWidget.allIds(this)) { // 4×2 + 4×3 둘 다
                        PlayerWidget.updateAppWidget(this, appWidgetManager, id, title, artist, isPlaying, schedule)
                    }
''',
         "위젯 그리기 (옛날 3번 위젯 빼기)"),
        ('''                "updateWidget" -> {
''',
         '''                "refreshWidget" -> {
                    PlayerWidget.refreshAll(this) // 최근에 들은 목록이 바뀜
                    result.success(true)
                }
                "updateWidget" -> {
''',
         "최근 목록 바뀌면 위젯 다시 그리기"),
    ], "MainActivity.kt")
    out[ma] = (s, crlf)
else:
    ok = False

# ───────── 6. AndroidManifest.xml ─────────
mf = os.path.normpath(os.path.join(ROOT, MAIN, "AndroidManifest.xml"))
if os.path.isfile(mf):
    s, crlf = read(mf)
    s = edit(mf, s, [
        ('''        <receiver
            android:name=".PlayerWidget2"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="kr.ssing.catsong.PLAY_PAUSE" />
                <action android:name="kr.ssing.catsong.NEXT" />
                <action android:name="kr.ssing.catsong.PREV" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_info2" />
        </receiver>

        <receiver
            android:name=".PlayerWidget3"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="kr.ssing.catsong.PLAY_PAUSE" />
                <action android:name="kr.ssing.catsong.NEXT" />
                <action android:name="kr.ssing.catsong.PREV" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_info3" />
        </receiver>
''',
         '''        <!-- 홈 위젯 4×3 (버튼은 모두 위 PlayerWidget이 받음) -->
        <receiver
            android:name=".PlayerWidget2"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_info2" />
        </receiver>
''',
         "새 4×3 위젯 등록 · 옛날 3번 빼기"),
    ], "AndroidManifest.xml")
    out[mf] = (s, crlf)
else:
    print("❌ android/app/src/main/AndroidManifest.xml 이 없어요")
    ok = False

# ───────── 7. headset_resume.dart ─────────
hr = one("headset_resume.dart", "lib")
if hr:
    s, crlf = read(hr)
    s = edit(hr, s, [
        ('''    _lastWidgetPlay = DateTime.now(); // 재생 버튼 신호가 같이 와도 겹치지 않게
''',
         '''    _lastWidgetPlay = DateTime.now(); // 재생 버튼 신호가 같이 와도 겹치지 않게
    if (kind.startsWith('recent:')) {
      await _playRecent(kind.substring(7), pp, radio, r); // 4×3 위젯 '최근에 들었어요' 줄
      return;
    }
''',
         "위젯 최근 줄 누름 받기"),
        ('''  static Future<void> widgetPlay() async {
''',
         '''  /// 4×3 위젯 '최근에 들었어요' 줄 ("종류|키"): 그것 바로 틀기
  /// 이미 나오고 있는 거면 멈춤 · 다시
  static Future<void> _playRecent(
      String id, PlayerProvider pp, RadioProvider radio, RecentContentProvider r) async {
    final cut = id.indexOf('|');
    if (cut < 0) return;
    final type = id.substring(0, cut);
    final key = id.substring(cut + 1);
    // 앱을 막 켰으면 기록이 불러와질 때까지 잠깐 기다리기
    for (var i = 0; i < 25 && r.entries.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    RecentContentEntry? e;
    for (final x in r.entries) {
      if (x.type.name == type && x.key == key) {
        e = x;
        break;
      }
    }
    if (e == null) return;
    try {
      switch (e.type) {
        case RecentContentType.radio:
          if (radio.currentStation?.stationUuid == key && (radio.isPlaying || radio.isLoading)) {
            await radio.togglePlayPause();
            return;
          }
          if (e.stationData == null) return;
          await _playSaved({'type': 'radio', 'station': e.stationData}, r);
        case RecentContentType.nature:
          if (pp.isPlaying && pp.natureSoundName == e.title) {
            await pp.pauseNatureSound();
            return;
          }
          if (e.natureAssetPath == null) return;
          await pp.playNatureSound(e.natureAssetPath!, e.title);
        case RecentContentType.music:
          if (pp.natureSoundName == null && pp.currentSong?.uri == key) {
            await pp.togglePlayPause(); // 같은 곡이면 멈춤 · 이어서
            return;
          }
          final m = _music;
          if (m != null && m.allSongs.isEmpty && !m.isLoading) m.initialize();
          await _playSaved({'type': 'music', 'uri': key}, r); // 그 곡부터 목록 순서대로
        case RecentContentType.sleep:
          break;
      }
    } catch (err) {
      debugPrint('위젯 최근 재생 오류: $err');
    }
  }

  static Future<void> widgetPlay() async {
''',
         "최근 줄 재생 코드 넣기"),
    ], "headset_resume.dart")
    out[hr] = (s, crlf)
else:
    ok = False

# ───────── 8. recent_content_provider.dart ─────────
rc = one("recent_content_provider.dart", "lib")
if rc:
    s, crlf = read(rc)
    s = edit(rc, s, [
        ('''import 'package:flutter/foundation.dart';
''',
         '''import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
''',
         "통로(services) 불러오기"),
        ('''      await prefs.setString(_prefsKey, raw);
    } catch (_) {}
''',
         '''      await prefs.setString(_prefsKey, raw);
    } catch (_) {}
    // 홈 위젯(4×3)의 '최근에 들었어요'도 다시 그리기
    try {
      await const MethodChannel('kr.ssing.catsong/media').invokeMethod('refreshWidget');
    } catch (_) {}
''',
         "목록 바뀌면 위젯에 알리기"),
    ], "recent_content_provider.dart")
    out[rc] = (s, crlf)
else:
    ok = False

# ───────── 9. 옛날 3번 위젯 파일 지우기 ─────────
for name, under in (("PlayerWidget3.kt", MAIN), ("widget_player3.xml", MAIN + "/res"), ("widget_info3.xml", MAIN + "/res")):
    hits = find(name, under)
    if len(hits) == 1:
        dels.append(hits[0])
        print(f"✔ 옛날 위젯 파일 지움: {name}")
    elif len(hits) > 1:
        print(f"❌ {name} 이(가) 여러 개 있어요: {', '.join(hits)}")
        ok = False

# 지운 파일을 다른 곳에서 쓰고 있지 않은지
for d, dirs, files in os.walk(ROOT):
    dirs[:] = [x for x in dirs if not any(s in x.lower() for s in SKIP)]
    rel = os.path.relpath(d, ROOT).replace("\\", "/")
    if not (rel.startswith("android/app/src") or rel.startswith("lib")):
        continue
    for f in files:
        p = os.path.normpath(os.path.join(d, f))
        if p in dels or not f.endswith((".kt", ".xml", ".dart", ".java")):
            continue
        txt = out[p][0] if p in out else open(p, "rb").read().decode("utf-8", "ignore")
        for word in ("PlayerWidget3", "widget_player3", "widget_info3"):
            if word in txt:
                print(f"❌ {os.path.relpath(p, ROOT)} 에서 아직 {word} 을(를) 써요")
                ok = False

if not ok:
    print()
    print("❌ 하나라도 안 돼서 아무것도 저장 안 했어요")
    sys.exit(1)

for p, (s, crlf) in out.items():
    if crlf:
        s = s.replace("\n", "\r\n")
    with open(p, "wb") as fp:
        fp.write(s.encode("utf-8"))
for p in dels:
    os.remove(p)
print()
print("다 됐어요! 폰에서 앱을 지우지 말고 그냥 flutter run 해 보세요")
