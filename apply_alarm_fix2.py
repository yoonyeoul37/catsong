# -*- coding: utf-8 -*-
# 아침 알람 고치기 2
# ① 화면이 꺼져 있을 때 기본 알람 소리가 먼저 울리던 것 → 조용히 알람 화면만 열고 바로 고른 노래·라디오
#    (혹시 1분 안에 알람 화면이 안 열리면 기본 알람 소리로 한 번 더 = 꼭 깨우기)
#    폰을 쓰는 중일 때는 지금처럼 위 알림 + 기본 알람 소리 (누르면 알람 화면)
# ② 알람으로 켜질 때 첫인삿말이 잠깐 나오던 것 → 안 나오게 (알람 화면이 뜨면 바로 멈춤)
# (apply_alarm.py · apply_alarm_help.py · apply_alarm_fix.py 를 먼저 실행한 뒤에)
import os, sys, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')
MAIN = os.path.join(LIB, 'main.dart')
SERVICE = os.path.join(LIB, 'services', 'alarm_service.dart')

RECEIVER = 'package __PACKAGE__\n\nimport android.app.AlarmManager\nimport android.app.KeyguardManager\nimport android.app.Notification\nimport android.app.NotificationChannel\nimport android.app.NotificationManager\nimport android.app.PendingIntent\nimport android.content.BroadcastReceiver\nimport android.content.Context\nimport android.content.Intent\nimport android.media.AudioAttributes\nimport android.media.RingtoneManager\nimport android.os.Build\nimport android.os.PowerManager\n\n/// 아침 알람 시간이 되면 폰이 이걸 깨움 (ALARM_MARK_V2)\n/// 안드로이드는 꺼져 있는 앱이 화면을 마음대로 띄우는 걸 막아서,\n/// "전체 화면 알림"으로 잠금화면 위에 알람 화면을 띄움\n/// - 화면이 꺼져 있으면: 기본 알람 소리 없이 조용히 알람 화면만 열고 → 고른 노래·라디오가 나옴\n///   (혹시 1분 안에 알람 화면이 안 열리면 기본 알람 소리로 한 번 더 = 꼭 깨우기)\n/// - 폰을 쓰는 중이면: 위에 알람 알림 + 기본 알람 소리 (누르면 알람 화면)\nclass AlarmReceiver : BroadcastReceiver() {\n    companion object {\n        const val CHANNEL_ID = "paran_alarm" // 소리 있는 알림\n        const val QUIET_CHANNEL_ID = "paran_alarm_quiet" // 소리 없는 알림 (바로 알람 화면이 열릴 때)\n        const val NOTI_ID = 7102\n        const val ACTION_FIRE = "kr.ssing.catsong.ALARM_FIRE"\n        const val ACTION_BACKUP = "kr.ssing.catsong.ALARM_BACKUP"\n\n        /// 알람 화면 열기 (MainActivity + paranAlarm 표시)\n        fun activityIntent(ctx: Context): PendingIntent {\n            val i = Intent(ctx, MainActivity::class.java).apply {\n                action = "kr.ssing.catsong.ALARM"\n                putExtra("paranAlarm", true)\n                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)\n            }\n            return PendingIntent.getActivity(\n                ctx, 7100, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT\n            )\n        }\n\n        private fun backupIntent(ctx: Context): PendingIntent {\n            val i = Intent(ctx, AlarmReceiver::class.java).apply { action = ACTION_BACKUP }\n            return PendingIntent.getBroadcast(\n                ctx, 7103, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT\n            )\n        }\n\n        fun cancelNotification(ctx: Context) {\n            try {\n                (ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTI_ID)\n            } catch (_: Exception) {}\n        }\n\n        /// 알람 화면이 열렸으면 "1분 뒤 한 번 더"는 취소\n        fun cancelBackup(ctx: Context) {\n            try {\n                (ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(backupIntent(ctx))\n            } catch (_: Exception) {}\n        }\n    }\n\n    override fun onReceive(ctx: Context, intent: Intent) {\n        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager\n        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)\n            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)\n\n        // 화면이 꺼져 있거나 잠겨 있고, 전체 화면 알림이 허용돼 있으면 → 바로 알람 화면이 열리니까 조용히\n        val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager\n        val km = ctx.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager\n        val inUse = pm.isInteractive && !km.isKeyguardLocked\n        val fsiOk = if (Build.VERSION.SDK_INT >= 34) nm.canUseFullScreenIntent() else true\n        val quiet = intent.action != ACTION_BACKUP && !inUse && fsiOk\n\n        if (Build.VERSION.SDK_INT >= 26) {\n            if (nm.getNotificationChannel(CHANNEL_ID) == null) {\n                val ch = NotificationChannel(CHANNEL_ID, "아침 알람", NotificationManager.IMPORTANCE_HIGH).apply {\n                    description = "파란소리 아침 알람"\n                    // 알람 소리로 (무음·진동 모드에서도 들리게)\n                    setSound(alarmUri, AudioAttributes.Builder()\n                        .setUsage(AudioAttributes.USAGE_ALARM)\n                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)\n                        .build())\n                    enableVibration(true)\n                    vibrationPattern = longArrayOf(0, 600, 400, 600)\n                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC\n                }\n                nm.createNotificationChannel(ch)\n            }\n            if (nm.getNotificationChannel(QUIET_CHANNEL_ID) == null) {\n                val ch = NotificationChannel(QUIET_CHANNEL_ID, "아침 알람 (화면 열기)", NotificationManager.IMPORTANCE_HIGH).apply {\n                    description = "잠금화면 위로 알람 화면을 열 때"\n                    setSound(null, null)\n                    enableVibration(false)\n                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC\n                }\n                nm.createNotificationChannel(ch)\n            }\n        }\n\n        val pi = activityIntent(ctx)\n        val b = if (Build.VERSION.SDK_INT >= 26) {\n            Notification.Builder(ctx, if (quiet) QUIET_CHANNEL_ID else CHANNEL_ID)\n        } else {\n            @Suppress("DEPRECATION")\n            Notification.Builder(ctx).setPriority(Notification.PRIORITY_MAX).apply {\n                if (!quiet) {\n                    setSound(alarmUri, android.media.AudioManager.STREAM_ALARM)\n                    setVibrate(longArrayOf(0, 600, 400, 600))\n                }\n            }\n        }\n        b.setSmallIcon(R.mipmap.ic_launcher)\n            .setContentTitle("아침 알람")\n            .setContentText("눌러서 알람 화면 열기")\n            .setCategory(Notification.CATEGORY_ALARM)\n            .setVisibility(Notification.VISIBILITY_PUBLIC)\n            .setFullScreenIntent(pi, true)\n            .setContentIntent(pi)\n            .setOngoing(true)\n            .setAutoCancel(true)\n        val n = b.build()\n        if (!quiet) n.flags = n.flags or Notification.FLAG_INSISTENT // 알람 화면을 열 때까지 계속 울림\n        try {\n            nm.notify(NOTI_ID, n)\n        } catch (e: SecurityException) {\n            android.util.Log.e("ParanAlarm", "알림 권한 없음: ${e.message}")\n        }\n\n        // 조용히 띄웠는데 1분 안에 알람 화면이 안 열리면 → 기본 알람 소리로 한 번 더\n        if (quiet) {\n            try {\n                val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager\n                val at = System.currentTimeMillis() + 60_000L\n                if (Build.VERSION.SDK_INT >= 23) {\n                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, backupIntent(ctx))\n                } else {\n                    am.setExact(AlarmManager.RTC_WAKEUP, at, backupIntent(ctx))\n                }\n            } catch (_: Exception) {}\n        }\n\n        // 앱이 화면에 떠 있으면 바로 알람 화면으로 (꺼져 있으면 위 알림이 대신 띄움)\n        try {\n            ctx.startActivity(Intent(ctx, MainActivity::class.java).apply {\n                action = "kr.ssing.catsong.ALARM"\n                putExtra("paranAlarm", true)\n                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)\n            })\n        } catch (_: Exception) {}\n    }\n}\n'

KT_EDITS = [
    ('MainActivity: 알람 화면 열리면 "1분 뒤 한 번 더" 취소',
     "        AlarmReceiver.cancelNotification(this) // 계속 울리던 알람 알림 끄기\n",
     "        AlarmReceiver.cancelNotification(this) // 계속 울리던 알람 알림 끄기\n"
     "        AlarmReceiver.cancelBackup(this) // 1분 뒤 한 번 더도 취소\n"),
]

SERVICE_EDITS = [
    ('알람: 울릴 때 알려줄 곳',
     "  static bool _ringing = false;\n",
     "  static bool _ringing = false;\n"
     "\n"
     "  /// 알람 화면이 뜰 때 부르기 (첫인삿말 멈추기용)\n"
     "  static VoidCallback? onRingStart;\n"),
    ('알람: 울리면 첫인삿말·리뷰 창 막기',
     "    if (_ringing) return;\n"
     "    _ringing = true;\n",
     "    if (_ringing) return;\n"
     "    _ringing = true;\n"
     "    launchedByAlarm = true; // 리뷰·업데이트 창도 안 띄우게\n"
     "    onRingStart?.call(); // 첫인삿말 바로 멈추기\n"),
]

MAIN_EDITS = [
    ('main: 알람이 울리면 첫인삿말 멈추기',
     "    WidgetsBinding.instance.addObserver(this);\n"
     "    if (AlarmService.launchedByAlarm) {\n",
     "    WidgetsBinding.instance.addObserver(this);\n"
     "    AlarmService.onRingStart = _stopWelcome; // 알람이 울리면 첫인삿말 바로 멈춤\n"
     "    if (AlarmService.launchedByAlarm) {\n"),
    ('main: 첫인삿말 틀기 직전에 한 번 더 확인',
     "      if (_welcomePlayer == p) p.play();",
     "      if (_welcomePlayer == p && !AlarmService.launchedByAlarm) p.play();"),
    ('main: 화면 닫을 때 정리',
     "    WidgetsBinding.instance.removeObserver(this);\n"
     "    _stopWelcome();\n",
     "    WidgetsBinding.instance.removeObserver(this);\n"
     "    AlarmService.onRingStart = null;\n"
     "    _stopWelcome();\n"),
]


def balanced(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    st = []
    for ch in s:
        if ch in '([{':
            st.append(ch)
        elif ch in ')]}':
            if not st or st.pop() != pairs[ch]:
                return False
    return not st


def main():
    hits = glob.glob(os.path.join(ROOT, 'android', 'app', 'src', 'main', 'kotlin', '**', 'MainActivity.kt'),
                     recursive=True)
    if len(hits) != 1:
        print('❌ MainActivity.kt 를 못 찾았어요 (android/app/src/main/kotlin 안)')
        sys.exit(1)
    act = hits[0]
    rec_path = os.path.join(os.path.dirname(act), 'AlarmReceiver.kt')
    if not os.path.exists(rec_path):
        print('❌ AlarmReceiver.kt 가 없어요. apply_alarm_fix.py 를 먼저 실행해 주세요')
        sys.exit(1)
    for p in (MAIN, SERVICE):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            sys.exit(1)
    old_rec = open(rec_path, 'rb').read().decode('utf-8')
    if 'ALARM_MARK_V2' in old_rec:
        print('이미 적용돼 있어요')
        return
    pkg = None
    for line in old_rec.splitlines():
        if line.startswith('package '):
            pkg = line.split()[1].strip()
            break
    if not pkg:
        print('❌ AlarmReceiver.kt 에서 package 줄을 못 찾았어요')
        sys.exit(1)

    out = []
    ok = True
    for path, edits in ((act, KT_EDITS), (SERVICE, SERVICE_EDITS), (MAIN, MAIN_EDITS)):
        raw = open(path, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        text = raw.replace('\r\n', '\n')
        before = balanced(text)
        for name, old, new in edits:
            if text.count(old) != 1:
                print('❌', name, '(찾을 코드를 못 찾았어요)')
                ok = False
                continue
            text = text.replace(old, new)
            print('✔', name)
        if before and not balanced(text):
            print('❌ 괄호가 안 맞아요:', os.path.basename(path))
            ok = False
        out.append((path, text.replace('\n', '\r\n') if crlf else text))
    receiver = RECEIVER.replace('__PACKAGE__', pkg)
    if not balanced(receiver):
        print('❌ 괄호가 안 맞아요: AlarmReceiver.kt')
        ok = False
    if not ok:
        print('\n아무것도 저장하지 않았어요.')
        sys.exit(1)
    for path, text in out:
        open(path, 'wb').write(text.encode('utf-8'))
    open(rec_path, 'wb').write(receiver.encode('utf-8'))
    print('✔ AlarmReceiver.kt 새로 고침 (화면 꺼져 있으면 조용히 알람 화면 열기)')
    print('\n다 바꿨어요. 앱을 완전히 끄고 flutter run 으로 다시 켠 뒤, 알람을 한 번 더 저장해 주세요.')


if __name__ == '__main__':
    main()
