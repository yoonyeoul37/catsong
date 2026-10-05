package kr.ssing.catsong

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/// 녹음하는 동안 앱을 나가도 마이크가 끊기지 않게 붙잡아 두는 서비스
/// 알림창에 "파란소리 녹음 중 00:12" 표시 (시간은 알림이 알아서 흘러감)
class RecordingService : Service() {
    companion object {
        const val CHANNEL_ID = "paransori_recording_v2" // 알림창 위쪽에 보이게 새로 만듦
        const val NOTI_ID = 3301
        const val EXTRA_PAUSED = "paused"
        const val EXTRA_BASE = "base" // 녹음 시작 기준 시각 (ms)
        const val EXTRA_ELAPSED = "elapsed" // 지금까지 녹음한 시간 (ms)
        // 알림 버튼
        const val ACTION_PAUSE = "kr.ssing.catsong.REC_PAUSE"
        const val ACTION_RESUME = "kr.ssing.catsong.REC_RESUME"
        const val ACTION_FINISH = "kr.ssing.catsong.REC_FINISH"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 알림 버튼을 누른 경우 → 앱(녹음 화면)에 전달만 하고 끝 (알림은 앱이 다시 바꿔줌)
        val act = when (intent?.action) {
            ACTION_PAUSE -> "pause"
            ACTION_RESUME -> "resume"
            ACTION_FINISH -> "finish"
            else -> null
        }
        if (act != null) {
            MainActivity.recordingChannel?.invokeMethod("action", act)
            return START_NOT_STICKY
        }
        val paused = intent?.getBooleanExtra(EXTRA_PAUSED, false) ?: false
        val base = intent?.getLongExtra(EXTRA_BASE, System.currentTimeMillis()) ?: System.currentTimeMillis()
        val elapsed = intent?.getLongExtra(EXTRA_ELAPSED, 0L) ?: 0L
        android.util.Log.d("RecordingService", "알림 시작 paused=$paused")
        val notification = build(paused, base, elapsed)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTI_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTI_ID, notification)
        }
        return START_NOT_STICKY
    }

    private fun build(paused: Boolean, base: Long, elapsed: Long): Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CHANNEL_ID) == null) {
            // 일반 중요도(위쪽·상태바에 보임) + 소리·진동 없음
            val ch = NotificationChannel(CHANNEL_ID, "녹음", NotificationManager.IMPORTANCE_DEFAULT)
            ch.description = "녹음 중일 때 알림창에 표시"
            ch.setShowBadge(false)
            ch.setSound(null, null)
            ch.enableVibration(false)
            nm.createNotificationChannel(ch)
        }
        // 알림을 누르면 녹음 화면으로 돌아가기
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        @Suppress("DEPRECATION")
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        b.setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle(if (paused) "파란소리 녹음 일시정지" else "파란소리 녹음 중")
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
        if (paused) {
            val s = elapsed / 1000
            b.setContentText(String.format("%02d:%02d · 탭해서 이어서 녹음", s / 60, s % 60))
                .setUsesChronometer(false)
                .setShowWhen(false)
        } else {
            // 시간이 알림에서 자동으로 흘러감
            b.setUsesChronometer(true)
                .setWhen(base)
                .setShowWhen(true)
                .setContentText("탭하면 녹음 화면으로 돌아가요")
        }
        // 알림 버튼: 일시정지(또는 이어서) · 완료
        fun pi(a: String) = PendingIntent.getService(
            this, a.hashCode(),
            Intent(this, RecordingService::class.java).setAction(a),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        @Suppress("DEPRECATION")
        b.addAction(
            if (paused) android.R.drawable.ic_media_play else android.R.drawable.ic_media_pause,
            if (paused) "이어서" else "일시정지",
            pi(if (paused) ACTION_RESUME else ACTION_PAUSE)
        )
        @Suppress("DEPRECATION")
        b.addAction(android.R.drawable.ic_menu_save, "완료", pi(ACTION_FINISH))
        return b.build()
    }
}