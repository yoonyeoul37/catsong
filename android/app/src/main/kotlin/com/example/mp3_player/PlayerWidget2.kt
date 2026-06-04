package com.example.mp3_player

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class PlayerWidget2 : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            PlayerWidget.ACTION_PLAY_PAUSE, PlayerWidget.ACTION_NEXT, PlayerWidget.ACTION_PREV -> {
                val keyCode = when (intent.action) {
                    PlayerWidget.ACTION_PLAY_PAUSE -> android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                    PlayerWidget.ACTION_NEXT -> android.view.KeyEvent.KEYCODE_MEDIA_NEXT
                    else -> android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS
                }
                val downEvent = android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keyCode)
                val upEvent = android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, keyCode)
                val downIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                    putExtra(Intent.EXTRA_KEY_EVENT, downEvent)
                    setPackage(context.packageName)
                }
                val upIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                    putExtra(Intent.EXTRA_KEY_EVENT, upEvent)
                    setPackage(context.packageName)
                }
                context.sendBroadcast(downIntent)
                context.sendBroadcast(upIntent)
            }
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            title: String = "플레이쏭",
            artist: String = "음악을 재생해보세요",
            isPlaying: Boolean = false
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_player2)

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_artist, artist)

            val playPauseIcon = if (isPlaying)
                android.R.drawable.ic_media_pause
            else
                android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.widget_play_pause, playPauseIcon)

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, openPendingIntent)

            val prevIntent = Intent(PlayerWidget.ACTION_PREV).apply { setPackage(context.packageName) }
            val prevPendingIntent = PendingIntent.getBroadcast(
                context, 4, prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_prev, prevPendingIntent)

            val playPauseIntent = Intent(PlayerWidget.ACTION_PLAY_PAUSE).apply { setPackage(context.packageName) }
            val playPausePendingIntent = PendingIntent.getBroadcast(
                context, 5, playPauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_play_pause, playPausePendingIntent)

            val nextIntent = Intent(PlayerWidget.ACTION_NEXT).apply { setPackage(context.packageName) }
            val nextPendingIntent = PendingIntent.getBroadcast(
                context, 6, nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_next, nextPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}