package kr.ssing.catsong

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
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngineCache
import com.ryanheise.audioservice.AudioServicePlugin
import java.util.Calendar

/// 홈 위젯 B안 (4×2)
/// 위: 시간대 라디오 사진 위에 지금 듣는 것 + 이전·재생·다음
/// 아래: 음악 · 라디오 · 자연 · 수면 바로가기 (누르면 앱이 그 화면으로 열림)
class PlayerWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) updateAppWidget(context, appWidgetManager, id)
    }

    // 바탕화면에서 위젯 크기를 바꾸면 사진도 새 크기에 맞게
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager,
                                           appWidgetId: Int, newOptions: android.os.Bundle) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val a = intent.action ?: return
        if (MainActivity.mediaChannel == null) attachHeadless(context)
        when {
            a == ACTION_PLAY_PAUSE -> {
                if (tooSoon(context)) return
                pressed(context, null)
                toApp("widgetPlayPause", null) { wakeAndPlay(context, null) }
            }
            a == ACTION_NEXT -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_NEXT)
            a == ACTION_PREV -> sendMediaKey(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            a == ACTION_REPEAT || a == ACTION_SHUFFLE -> {
                if (MainActivity.mediaChannel != null) {
                    flipMode(context, a == ACTION_REPEAT) // 누르자마자 모양 먼저
                    toApp(if (a == ACTION_REPEAT) "widgetRepeat" else "widgetShuffle", null) {}
                }
            }
            a.startsWith(ACTION_KIND) -> {
                // 아래 버튼: 음악 · 라디오 · 자연 바로 재생 (앱 안 열고)
                if (tooSoon(context)) return
                val kind = a.removePrefix(ACTION_KIND)
                pressed(context, kind)
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
        h.postDelayed({
            finish(true)
        }, 1200)
        try {
            ch.invokeMethod(method, arg, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    finish(false)
                }
                override fun error(code: String, msg: String?, details: Any?) = finish(false)
                override fun notImplemented() {
                    finish(true)
                }
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

    companion object {
        const val ACTION_PLAY_PAUSE = "kr.ssing.catsong.PLAY_PAUSE"
        const val ACTION_NEXT = "kr.ssing.catsong.NEXT"
        const val ACTION_PREV = "kr.ssing.catsong.PREV"
        const val ACTION_KIND = "kr.ssing.catsong.PLAY_KIND_" // 뒤에 music · radio · nature
        const val ACTION_REPEAT = "kr.ssing.catsong.REPEAT"
        const val ACTION_SHUFFLE = "kr.ssing.catsong.SHUFFLE"
        private const val PREFS = "paran_widget"
        private const val TAP_GAP = 1000L    // 이 시간 안에 또 누르면 무시 (1초)
        private const val LOAD_MAX = 10000L  // '불러오는 중…' 은 길어도 10초까지만

        /// 1초 안에 또 누른 거면 true (무시)
        private fun tooSoon(context: Context): Boolean {
            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val gap = now - p.getLong("tap", 0L)
            if (gap in 0 until TAP_GAP) {
                return true
            }
            p.edit().putLong("tap", now).apply()
            return false
        }

        /// 반복·섞기: 누르자마자 위젯 모양 먼저 (앱도 같은 값으로 저장함)
        private fun flipMode(context: Context, repeat: Boolean) {
            try {
                val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                if (repeat) {
                    // 0 반복 안 함 → 1 한 곡 반복 → 2 전체 반복
                    fp.edit().putLong("flutter.w_loop", (fp.getLong("flutter.w_loop", 0L) + 1) % 3).apply()
                } else {
                    fp.edit().putBoolean("flutter.w_shuffle", !fp.getBoolean("flutter.w_shuffle", false)).apply()
                }
            } catch (_: Exception) {}
            refreshAll(context)
        }

        /// 누르자마자 위젯 모양부터 바꾸기
        /// - 듣는 중에 재생 버튼 = 멈춤 → 버튼만 바로 ▶
        /// - 그 밖엔 '불러오는 중…' + ⏸ (진짜 곡·방송 이름이 오면 바뀜)
        private fun pressed(context: Context, kind: String?) {
            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val playing = p.getBoolean("p", false)
            if (kind == null && playing) {
                p.edit().putBoolean("p", false).apply()
            } else {
                // load_any: 다른 걸 듣다가 바꾼 경우 → 어떤 소식이 와도 끝냄
                p.edit().putLong("load", System.currentTimeMillis()).putBoolean("load_any", playing).apply()
                val app = context.applicationContext
                android.os.Handler(android.os.Looper.getMainLooper())
                    .postDelayed({ refreshAll(app) }, LOAD_MAX + 300)
            }
            refreshAll(context)
        }

        /// 앱 화면 없이 재생 엔진만 깨어났을 때: 위젯 ↔ 앱 통로를 위젯이 직접 연결
        /// (그래야 다음 누름부터 바로 전달되고, 곡·방송 이름도 위젯에 뜸)
        /// 나중에 앱 화면이 열리면 앱이 자기 통로로 다시 바꿔 끼움
        fun attachHeadless(context: Context, tries: Int = 0) {
            if (MainActivity.mediaChannel != null) return
            val app = context.applicationContext
            val engine = FlutterEngineCache.getInstance().get(AudioServicePlugin.getFlutterEngineId())
            if (engine == null) {
                if (tries < 40) android.os.Handler(android.os.Looper.getMainLooper())
                    .postDelayed({ attachHeadless(app, tries + 1) }, 250)
                return
            }
            val ch = MethodChannel(engine.dartExecutor.binaryMessenger, "kr.ssing.catsong/media")
            ch.setMethodCallHandler { call, result ->
                if (call.method == "requestAudioFocus") {
                    result.success(true) // 화면 없을 땐 그냥 통과 (오류 안 나게)
                } else if (call.method == "updateWidget") {
                    val mgr = AppWidgetManager.getInstance(app)
                    val ids = mgr.getAppWidgetIds(android.content.ComponentName(app, PlayerWidget::class.java))
                    for (id in ids) updateAppWidget(app, mgr, id,
                        call.argument<String>("title") ?: "파란소리",
                        call.argument<String>("artist") ?: "",
                        call.argument<Boolean>("isPlaying") ?: false,
                        call.argument<String>("schedule") ?: "")
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
            MainActivity.mediaChannel = ch
        }

        /// 다음·이전 → 앱의 재생 버튼 받는 곳(audio_service)으로 바로
        fun sendMediaKey(context: Context, keyCode: Int) {
            context.sendBroadcast(Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                component = android.content.ComponentName(
                    context.packageName, "com.ryanheise.audioservice.MediaButtonReceiver")
                putExtra(Intent.EXTRA_KEY_EVENT,
                    android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keyCode))
            })
        }

        /// 바탕화면에 붙은 이 위젯 전부 다시 그리기 (앱이 켜지고 꺼질 때)
        fun refreshAll(context: Context) {
            try {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(android.content.ComponentName(context, PlayerWidget::class.java))
                for (id in ids) updateAppWidget(context, mgr, id)
            } catch (_: Exception) {}
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
                // 소리가 나기 시작하면 끝 (다른 걸 듣다 바꾼 경우엔 어떤 소식이든 오면 끝)
                if (isPlaying == true || p.getBoolean("load_any", false)) p.edit().remove("load").apply()
            }
            // 가사 줄만 바뀐 건 폰 화면이 꺼져 있으면 기억만 하고 안 그림 (화면 켜면 다음 줄부터)
            if (schedule.startsWith("♪")) {
                val pm = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                if (!pm.isInteractive) return
            }
            val loadAt = p.getLong("load", 0L)
            val loading = loadAt > 0 && System.currentTimeMillis() - loadAt in 0 until LOAD_MAX
            val t = p.getString("t", null)
            val a = p.getString("a", null) ?: ""
            val s = p.getString("s", null) ?: ""
            val playing = p.getBoolean("p", false)
            val empty = t == null || t == "플레이쏭" || t == "캣송"

            val views = RemoteViews(context.packageName, R.layout.widget_player)
            views.setTextViewText(R.id.widget_title,
                if (loading) "불러오는 중…" else if (empty) "파란소리" else t)
            views.setTextViewText(R.id.widget_artist,
                if (loading) "잠시만 기다려 주세요" else if (empty) "음악 · 라디오 · 자연을 들어보세요" else a)
            views.setTextViewText(R.id.widget_schedule, s)
            views.setViewVisibility(R.id.widget_schedule, if (loading || s.isEmpty()) View.GONE else View.VISIBLE)
            views.setImageViewResource(R.id.widget_play_pause,
                if (playing || loading) R.drawable.paran_ic_pause else R.drawable.paran_ic_play)
            // 섞기 · 반복 (음악일 때만, 꺼져 있으면 흐리게)
            val fp = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val music = try { fp.getBoolean("flutter.w_music", false) } catch (_: Exception) { false }
            val loop = try { fp.getLong("flutter.w_loop", 0L) } catch (_: Exception) { 0L }
            val shuf = try { fp.getBoolean("flutter.w_shuffle", false) } catch (_: Exception) { false }
            views.setViewVisibility(R.id.widget_modes, if (music && !empty) View.VISIBLE else View.GONE)
            views.setImageViewResource(R.id.widget_repeat,
                if (loop == 1L) R.drawable.paran_ic_repeat_one else R.drawable.paran_ic_repeat)
            fun mode(id: Int, on: Boolean) {
                views.setInt(id, "setBackgroundResource",
                    if (on) R.drawable.paran_widget_mode_on else R.drawable.paran_widget_mode_bg)
                views.setInt(id, "setColorFilter", if (on) 0xFF17140F.toInt() else 0xFFFFFFFF.toInt())
                views.setInt(id, "setImageAlpha", if (on) 255 else 200)
            }
            mode(R.id.widget_repeat, loop != 0L)
            mode(R.id.widget_shuffle, shuf)
            photo(context, appWidgetManager, appWidgetId)?.let { views.setImageViewBitmap(R.id.widget_photo, it) }

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
            // 재생: 앱이 켜져 있으면 앱에게 바로 / 꺼져 있으면 앱을 열면서 마지막에 듣던 것
            views.setOnClickPendingIntent(R.id.widget_play_pause, media(ACTION_PLAY_PAUSE, 2))
            views.setOnClickPendingIntent(R.id.widget_next, media(ACTION_NEXT, 3))
            views.setOnClickPendingIntent(R.id.widget_repeat, media(ACTION_REPEAT, 4))
            views.setOnClickPendingIntent(R.id.widget_shuffle, media(ACTION_SHUFFLE, 5))

            // 바로가기 4개
            val go = listOf(
                R.id.widget_go_music to "music",
                R.id.widget_go_radio to "radio",
                R.id.widget_go_nature to "nature",
                R.id.widget_go_sleep to "sleep"
            )
            go.forEachIndexed { i, (viewId, target) ->
                val pi = if (target == "sleep") {
                    // 수면: 아직 소리가 없어서 화면 열기
                    val goIntent = Intent(context, MainActivity::class.java).apply {
                        action = "kr.ssing.catsong.WIDGET_GO_$target"
                        putExtra("widgetGo", target)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    }
                    PendingIntent.getActivity(context, 20 + i, goIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                } else {
                    // 음악(첫 곡부터) · 라디오 · 자연: 앱 안 열고 위젯에서 바로 재생
                    PendingIntent.getBroadcast(context, 20 + i,
                        Intent(context, PlayerWidget::class.java).setAction(ACTION_KIND + target),
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                }
                views.setOnClickPendingIntent(viewId, pi)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /// 지금 시간대 라디오 사진 (아침 5–11 · 낮 11–17 · 저녁 17–22 · 밤)
        /// 위젯 띠 모양으로 자르고, 모서리 둥글게, 아래쪽은 글자가 보이게 살짝 어둡게
        private fun photo(context: Context, mgr: AppWidgetManager, id: Int): Bitmap? {
            // 사진 칸 크기(dp): 위젯 크기 - 아래 바로가기 줄(46 + 위 8 + 아래 10)
            val opt = mgr.getAppWidgetOptions(id)
            val vw = opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
            val vh = ((opt.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 180) - 64)
                .coerceAtLeast(56)
            // 바깥 모서리 크기(dp) = res/values 의 paran_w_radius (안드로이드 12 이상은 폰이 정한 크기)
            val dens = context.resources.displayMetrics.density
            val radiusDp = context.resources.getDimension(R.dimen.paran_w_radius) / dens
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
                val bh = (w * vh.toFloat() / vw).toInt().coerceIn(1, src.height)
                val top = ((src.height - bh) * 0.35f).toInt()
                val out = Bitmap.createBitmap(w, bh, Bitmap.Config.ARGB_8888)
                val c = Canvas(out)
                val r = radiusDp * w / vw
                c.clipPath(Path().apply {
                    addRoundRect(RectF(0f, 0f, w.toFloat(), bh.toFloat()),
                        floatArrayOf(r, r, r, r, 0f, 0f, 0f, 0f), Path.Direction.CW)
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
