package kr.ssing.catsong

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import java.util.Calendar

/// 아침 알람 시간이 되면 폰이 이걸 깨움 (ALARM_MARK_V2, ALARM_MARK_V3)
/// 안드로이드는 꺼져 있는 앱이 화면을 마음대로 띄우는 걸 막아서,
/// "전체 화면 알림"으로 잠금화면 위에 알람 화면을 띄움
/// - 화면이 꺼져 있으면: 기본 알람 소리 없이 조용히 알람 화면만 열고 → 고른 노래·라디오가 나옴
///   (혹시 1분 안에 알람 화면이 안 열리면 기본 알람 소리로 한 번 더 = 꼭 깨우기)
/// - 폰을 쓰는 중이면: 위에 알람 알림 + 기본 알람 소리 (누르면 알람 화면)
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "paran_alarm" // 소리 있는 알림
        const val QUIET_CHANNEL_ID = "paran_alarm_quiet" // 소리 없는 알림 (바로 알람 화면이 열릴 때)
        const val NOTI_ID = 7102
        const val ACTION_FIRE = "kr.ssing.catsong.ALARM_FIRE"
        const val ACTION_BACKUP = "kr.ssing.catsong.ALARM_BACKUP"

        /// 알람 화면 열기 (MainActivity + paranAlarm 표시)
        fun activityIntent(ctx: Context): PendingIntent {
            val i = Intent(ctx, MainActivity::class.java).apply {
                action = "kr.ssing.catsong.ALARM"
                putExtra("paranAlarm", true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            return PendingIntent.getActivity(
                ctx, 7100, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        }

        private fun backupIntent(ctx: Context): PendingIntent {
            val i = Intent(ctx, AlarmReceiver::class.java).apply { action = ACTION_BACKUP }
            return PendingIntent.getBroadcast(
                ctx, 7103, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        }

        fun cancelNotification(ctx: Context) {
            try {
                (ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTI_ID)
            } catch (_: Exception) {}
        }

        // ───── 예약 기억 (폰을 껐다 켜도 다시 예약하려고) ─────
        private const val PREFS = "paran_alarm_native"

        /// 시간이 되면 이 AlarmReceiver를 깨우는 예약표
        fun firePendingIntent(ctx: Context): PendingIntent {
            val i = Intent(ctx, AlarmReceiver::class.java).apply { action = ACTION_FIRE }
            return PendingIntent.getBroadcast(
                ctx, 7100, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        }

        fun saveAt(ctx: Context, at: Long) {
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putLong("at", at).apply()
        }

        fun saveRule(ctx: Context, hour: Int, minute: Int, days: String) {
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putInt("hour", hour).putInt("minute", minute).putString("days", days).apply()
        }

        fun clearRule(ctx: Context) {
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
        }

        /// 폰이 켜진 뒤: 기억해둔 알람 다시 예약 (지난 시간이면 다음 요일로)
        fun reschedule(ctx: Context) {
            val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val at = p.getLong("at", 0L)
            if (at == 0L) return
            var t = at
            val now = System.currentTimeMillis()
            if (t <= now) {
                val days = (p.getString("days", "") ?: "").split(',').mapNotNull { it.trim().toIntOrNull() }
                if (days.isEmpty()) return // 한 번만 울리는 알람인데 이미 지남
                val hour = p.getInt("hour", 7)
                val minute = p.getInt("minute", 0)
                var found = 0L
                for (d in 0..7) {
                    val c = Calendar.getInstance().apply {
                        add(Calendar.DAY_OF_YEAR, d)
                        set(Calendar.HOUR_OF_DAY, hour)
                        set(Calendar.MINUTE, minute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    val dow = c.get(Calendar.DAY_OF_WEEK)
                    val day = if (dow == Calendar.SUNDAY) 7 else dow - 1 // 1=월 … 7=일
                    if (c.timeInMillis > now && days.contains(day)) {
                        found = c.timeInMillis
                        break
                    }
                }
                if (found == 0L) return
                t = found
            }
            try {
                val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val show = PendingIntent.getActivity(
                    ctx, 7101, Intent(ctx, MainActivity::class.java),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
                am.setAlarmClock(AlarmManager.AlarmClockInfo(t, show), firePendingIntent(ctx))
                saveAt(ctx, t)
            } catch (e: Exception) {
                android.util.Log.e("ParanAlarm", "다시 예약 실패: ${e.message}")
            }
        }

        // ───── 폰 기본 알람 소리 (인터넷도 안 되고 노래도 없을 때) ─────
        private var ringtone: android.media.Ringtone? = null

        fun playFallback(ctx: Context) {
            stopFallback()
            try {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                val r = RingtoneManager.getRingtone(ctx, uri) ?: return
                r.audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                if (Build.VERSION.SDK_INT >= 28) r.isLooping = true
                r.play()
                ringtone = r
            } catch (e: Exception) {
                android.util.Log.e("ParanAlarm", "기본 알람 소리 실패: ${e.message}")
            }
        }

        fun stopFallback() {
            try {
                ringtone?.stop()
            } catch (_: Exception) {}
            ringtone = null
        }

        /// 알람 화면이 열렸으면 "1분 뒤 한 번 더"는 취소
        fun cancelBackup(ctx: Context) {
            try {
                (ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(backupIntent(ctx))
            } catch (_: Exception) {}
        }
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        // 화면이 꺼져 있거나 잠겨 있고, 전체 화면 알림이 허용돼 있으면 → 바로 알람 화면이 열리니까 조용히
        val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
        val km = ctx.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val inUse = pm.isInteractive && !km.isKeyguardLocked
        val fsiOk = if (Build.VERSION.SDK_INT >= 34) nm.canUseFullScreenIntent() else true
        val quiet = intent.action != ACTION_BACKUP && !inUse && fsiOk

        if (Build.VERSION.SDK_INT >= 26) {
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val ch = NotificationChannel(CHANNEL_ID, "아침 알람", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "파란소리 아침 알람"
                    // 알람 소리로 (무음·진동 모드에서도 들리게)
                    setSound(alarmUri, AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build())
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 600, 400, 600)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(ch)
            }
            if (nm.getNotificationChannel(QUIET_CHANNEL_ID) == null) {
                val ch = NotificationChannel(QUIET_CHANNEL_ID, "아침 알람 (화면 열기)", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "잠금화면 위로 알람 화면을 열 때"
                    setSound(null, null)
                    enableVibration(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                nm.createNotificationChannel(ch)
            }
        }

        val pi = activityIntent(ctx)
        val b = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(ctx, if (quiet) QUIET_CHANNEL_ID else CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(ctx).setPriority(Notification.PRIORITY_MAX).apply {
                if (!quiet) {
                    setSound(alarmUri, android.media.AudioManager.STREAM_ALARM)
                    setVibrate(longArrayOf(0, 600, 400, 600))
                }
            }
        }
        b.setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("아침 알람")
            .setContentText("눌러서 알람 화면 열기")
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setFullScreenIntent(pi, true)
            .setContentIntent(pi)
            .setOngoing(true)
            .setAutoCancel(true)
        val n = b.build()
        if (!quiet) n.flags = n.flags or Notification.FLAG_INSISTENT // 알람 화면을 열 때까지 계속 울림
        try {
            nm.notify(NOTI_ID, n)
        } catch (e: SecurityException) {
            android.util.Log.e("ParanAlarm", "알림 권한 없음: ${e.message}")
        }

        // 조용히 띄웠는데 1분 안에 알람 화면이 안 열리면 → 기본 알람 소리로 한 번 더
        if (quiet) {
            try {
                val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val at = System.currentTimeMillis() + 60_000L
                if (Build.VERSION.SDK_INT >= 23) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, backupIntent(ctx))
                } else {
                    am.setExact(AlarmManager.RTC_WAKEUP, at, backupIntent(ctx))
                }
            } catch (_: Exception) {}
        }

        // 앱이 화면에 떠 있으면 바로 알람 화면으로 (꺼져 있으면 위 알림이 대신 띄움)
        try {
            ctx.startActivity(Intent(ctx, MainActivity::class.java).apply {
                action = "kr.ssing.catsong.ALARM"
                putExtra("paranAlarm", true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            })
        } catch (_: Exception) {}
    }
}

/// 폰을 껐다 켜거나 앱을 업데이트하면 안드로이드가 예약을 지워서 → 다시 예약
class AlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED -> AlarmReceiver.reschedule(ctx)
        }
    }
}
