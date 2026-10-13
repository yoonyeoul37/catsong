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

            // 이전 · 재생 · 다음 → 앱의 재생 버튼 받는 곳으로 바로 (음악·라디오·자연 모두)
            fun media(keyCode: Int, code: Int) = PendingIntent.getBroadcast(
                context, code,
                Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                    component = android.content.ComponentName(
                        context.packageName, "com.ryanheise.audioservice.MediaButtonReceiver")
                    putExtra(Intent.EXTRA_KEY_EVENT,
                        android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keyCode))
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_prev, media(android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS, 1))
            views.setOnClickPendingIntent(R.id.widget_play_pause, media(android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 2))
            views.setOnClickPendingIntent(R.id.widget_next, media(android.view.KeyEvent.KEYCODE_MEDIA_NEXT, 3))

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
