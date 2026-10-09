# -*- coding: utf-8 -*-
# 아침 알람 고치기: 꺼진 앱에서도 알람 화면이 뜨게
# 왜 안 울렸나: 안드로이드가 "꺼져 있는 앱이 화면을 마음대로 띄우는 것"을 막아서, 예약은 됐는데 화면이 안 열렸음
# 고친 방법: 시간이 되면 AlarmReceiver가 받아서 "전체 화면 알림"으로 띄움 (폰 기본 알람 앱과 같은 방식)
#   - 화면이 꺼져 있거나 잠겨 있으면: 잠금화면 위로 알람 화면이 바로 열림 → 고른 노래·라디오
#   - 화면을 쓰는 중이면: 위에 알람 알림이 계속 울림 → 누르면 알람 화면
#   - 알람 소리 알림은 무음·진동 모드에서도 울림 (알람 화면이 열리면 바로 꺼짐)
# - 저장할 때 알림 권한 확인, 안드로이드 14 이상은 "전체 화면 알림" 허용 안내
# - 저장하면 홈 아래 알림 대신 화면 가운데 피드백 "내일 오전 7:00에 깨워 드릴게요"
# - 새 파일 AlarmReceiver.kt 는 이 스크립트가 MainActivity.kt 옆에 직접 만들어요
# (apply_alarm.py, apply_alarm_help.py 를 먼저 실행한 뒤에)
import os, sys, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(ROOT, 'lib')
SERVICE = os.path.join(LIB, 'services', 'alarm_service.dart')
SCREEN = os.path.join(LIB, 'screens', 'alarm_screen.dart')
MANIFEST = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'AndroidManifest.xml')

RECEIVER = 'package __PACKAGE__\n\nimport android.app.Notification\nimport android.app.NotificationChannel\nimport android.app.NotificationManager\nimport android.app.PendingIntent\nimport android.content.BroadcastReceiver\nimport android.content.Context\nimport android.content.Intent\nimport android.media.AudioAttributes\nimport android.media.RingtoneManager\nimport android.os.Build\n\n/// 아침 알람 시간이 되면 폰이 이걸 깨움\n/// 안드로이드는 꺼져 있는 앱이 화면을 마음대로 띄우는 걸 막아서,\n/// "전체 화면 알림"으로 잠금화면 위에 알람 화면을 띄움 (화면이 켜져 있으면 위에 알림으로)\n/// 알람 화면이 열리면 이 알림은 바로 지워지고, 고른 노래·라디오가 나옴\nclass AlarmReceiver : BroadcastReceiver() {\n    companion object {\n        const val CHANNEL_ID = "paran_alarm"\n        const val NOTI_ID = 7102\n\n        /// 알람 화면 열기 (MainActivity + paranAlarm 표시)\n        fun activityIntent(ctx: Context): PendingIntent {\n            val i = Intent(ctx, MainActivity::class.java).apply {\n                action = "kr.ssing.catsong.ALARM"\n                putExtra("paranAlarm", true)\n                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)\n            }\n            return PendingIntent.getActivity(\n                ctx, 7100, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT\n            )\n        }\n\n        fun cancelNotification(ctx: Context) {\n            try {\n                (ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTI_ID)\n            } catch (_: Exception) {}\n        }\n    }\n\n    override fun onReceive(ctx: Context, intent: Intent) {\n        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager\n        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)\n            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)\n        if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel(CHANNEL_ID) == null) {\n            val ch = NotificationChannel(CHANNEL_ID, "아침 알람", NotificationManager.IMPORTANCE_HIGH).apply {\n                description = "파란소리 아침 알람"\n                // 알람 소리로 (무음·진동 모드에서도 들리게)\n                setSound(alarmUri, AudioAttributes.Builder()\n                    .setUsage(AudioAttributes.USAGE_ALARM)\n                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)\n                    .build())\n                enableVibration(true)\n                vibrationPattern = longArrayOf(0, 600, 400, 600)\n                lockscreenVisibility = Notification.VISIBILITY_PUBLIC\n            }\n            nm.createNotificationChannel(ch)\n        }\n        val pi = activityIntent(ctx)\n        val b = if (Build.VERSION.SDK_INT >= 26) {\n            Notification.Builder(ctx, CHANNEL_ID)\n        } else {\n            @Suppress("DEPRECATION")\n            Notification.Builder(ctx)\n                .setPriority(Notification.PRIORITY_MAX)\n                .setSound(alarmUri, android.media.AudioManager.STREAM_ALARM)\n                .setVibrate(longArrayOf(0, 600, 400, 600))\n        }\n        b.setSmallIcon(R.mipmap.ic_launcher)\n            .setContentTitle("아침 알람")\n            .setContentText("눌러서 알람 화면 열기")\n            .setCategory(Notification.CATEGORY_ALARM)\n            .setVisibility(Notification.VISIBILITY_PUBLIC)\n            .setFullScreenIntent(pi, true)\n            .setContentIntent(pi)\n            .setOngoing(true)\n            .setAutoCancel(true)\n        val n = b.build()\n        n.flags = n.flags or Notification.FLAG_INSISTENT // 알람 화면을 열 때까지 계속 울림\n        try {\n            nm.notify(NOTI_ID, n)\n        } catch (e: SecurityException) {\n            android.util.Log.e("ParanAlarm", "알림 권한 없음: ${e.message}")\n        }\n        // 앱이 화면에 떠 있으면 바로 알람 화면으로 (꺼져 있으면 위 알림이 대신 띄움)\n        try {\n            ctx.startActivity(Intent(ctx, MainActivity::class.java).apply {\n                action = "kr.ssing.catsong.ALARM"\n                putExtra("paranAlarm", true)\n                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)\n            })\n        } catch (_: Exception) {}\n    }\n}\n'

KT_EDITS = [
    ('MainActivity: 시간이 되면 AlarmReceiver로',
     "        val i = android.content.Intent(this, MainActivity::class.java).apply {\n"
     "            action = \"kr.ssing.catsong.ALARM\"\n"
     "            putExtra(\"paranAlarm\", true)\n"
     "            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP)\n"
     "        }\n"
     "        return android.app.PendingIntent.getActivity(\n",
     "        // 시간이 되면 AlarmReceiver가 받아서 알람 화면을 띄움 (꺼진 앱은 화면을 직접 못 띄워서)\n"
     "        val i = android.content.Intent(this, AlarmReceiver::class.java).apply {\n"
     "            action = \"kr.ssing.catsong.ALARM_FIRE\"\n"
     "        }\n"
     "        return android.app.PendingIntent.getBroadcast(\n"),
    ('MainActivity: 예전 방식 예약도 지우기',
     "            am.cancel(alarmPendingIntent())\n",
     "            am.cancel(alarmPendingIntent())\n"
     "            am.cancel(AlarmReceiver.activityIntent(this)) // 처음 방식으로 걸어둔 예약\n"),
    ('MainActivity: 알람 화면 열리면 울리던 알림 끄기',
     "        pendingAlarm = true\n"
     "        showOverLock(true)\n",
     "        pendingAlarm = true\n"
     "        AlarmReceiver.cancelNotification(this) // 계속 울리던 알람 알림 끄기\n"
     "        showOverLock(true)\n"),
    ('MainActivity: 알람 끝나면 알림도 끄기',
     "                    \"ringDone\" -> {\n"
     "                        showOverLock(false)\n",
     "                    \"ringDone\" -> {\n"
     "                        AlarmReceiver.cancelNotification(this@MainActivity)\n"
     "                        showOverLock(false)\n"),
    ('MainActivity: 전체 화면 알림 허용 확인·설정 열기',
     "                    \"takeLaunchAlarm\" -> {\n",
     "                    \"canFullScreen\" -> {\n"
     "                        // 안드로이드 14 이상: 잠금화면 위로 알람 화면 띄우기 허용됐는지\n"
     "                        val ok = if (Build.VERSION.SDK_INT >= 34) {\n"
     "                            (getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager)\n"
     "                                .canUseFullScreenIntent()\n"
     "                        } else true\n"
     "                        result.success(ok)\n"
     "                    }\n"
     "                    \"openFullScreenSettings\" -> {\n"
     "                        try {\n"
     "                            if (Build.VERSION.SDK_INT >= 34) {\n"
     "                                startActivity(android.content.Intent(\n"
     "                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,\n"
     "                                    android.net.Uri.parse(\"package:$packageName\")))\n"
     "                            }\n"
     "                        } catch (_: Exception) {}\n"
     "                        result.success(true)\n"
     "                    }\n"
     "                    \"takeLaunchAlarm\" -> {\n"),
]

MANIFEST_EDITS = [
    ('AndroidManifest: 전체 화면 알림 권한',
     "    <uses-permission android:name=\"android.permission.SCHEDULE_EXACT_ALARM\"/>\n",
     "    <uses-permission android:name=\"android.permission.SCHEDULE_EXACT_ALARM\"/>\n"
     "    <!-- 아침 알람: 잠금화면 위로 알람 화면 띄우기 -->\n"
     "    <uses-permission android:name=\"android.permission.USE_FULL_SCREEN_INTENT\"/>\n"),
    ('AndroidManifest: AlarmReceiver 등록',
     "        <!-- 녹음 중 알림 (앱을 나가도 계속 녹음) -->\n",
     "        <!-- 아침 알람: 시간이 되면 알람 화면 띄우기 -->\n"
     "        <receiver\n"
     "            android:name=\".AlarmReceiver\"\n"
     "            android:exported=\"false\" />\n"
     "        <!-- 녹음 중 알림 (앱을 나가도 계속 녹음) -->\n"),
]

SERVICE_EDITS = [
    ('알람: 전체 화면 알림 확인·설정 열기',
     "  /// 저장 + 예약. 권한(알람 및 리마인더)이 없으면 false\n",
     "  /// 안드로이드 14 이상: 잠금화면 위로 알람 화면 띄우기(전체 화면 알림) 허용됐는지\n"
     "  static Future<bool> canFullScreen() async {\n"
     "    try {\n"
     "      return await _ch.invokeMethod('canFullScreen') != false;\n"
     "    } catch (_) {\n"
     "      return true;\n"
     "    }\n"
     "  }\n"
     "\n"
     "  static Future<void> openFullScreenSettings() async {\n"
     "    try {\n"
     "      await _ch.invokeMethod('openFullScreenSettings');\n"
     "    } catch (_) {}\n"
     "  }\n"
     "\n"
     "  /// 저장 + 예약. 권한(알람 및 리마인더)이 없으면 false\n"),
]

SCREEN_EDITS = [
    ('알람 화면: 불러오기',
     "import '../widgets/paran_toast.dart';\n",
     "import '../widgets/paran_toast.dart';\n"
     "import '../widgets/action_feedback.dart';\n"
     "import 'package:permission_handler/permission_handler.dart';\n"),
    ('알람 화면: 알림 권한 · 전체 화면 알림 · 가운데 피드백',
     "    showParanToast(context, _a.enabled ? '${AlarmService.nextLabel(_a)}에 깨워 드릴게요' : '알람을 껐어요');\n"
     "    Navigator.pop(context);\n",
     "    if (_a.enabled) {\n"
     "      // 알림 권한: 알람이 울릴 때 알림으로 화면을 띄워서 꼭 필요\n"
     "      try {\n"
     "        if (await Permission.notification.isDenied) await Permission.notification.request();\n"
     "      } catch (_) {}\n"
     "      // 안드로이드 14 이상: 잠금화면 위로 알람 화면 띄우기 허용 (안 해도 알람 소리는 울림)\n"
     "      if (!await AlarmService.canFullScreen() && mounted) {\n"
     "        final go = await showParanConfirm(\n"
     "          context,\n"
     "          title: '잠금화면에 알람 화면 띄우기',\n"
     "          message: '\"전체 화면 알림\"을 허용하면 잠금화면 위로 알람 화면이 바로 떠요. 허용 안 해도 알람 소리는 울려요.',\n"
     "          confirmLabel: '설정 열기',\n"
     "          cancelLabel: '나중에',\n"
     "        );\n"
     "        if (go) AlarmService.openFullScreenSettings();\n"
     "      }\n"
     "    }\n"
     "    if (!mounted) return;\n"
     "    // 화면 가운데 피드백 (저장·수정 때와 같은 모양)\n"
     "    showActionFeedback(\n"
     "      context,\n"
     "      type: ActionFeedbackType.saved,\n"
     "      icon: _a.enabled ? Icons.alarm_rounded : Icons.alarm_off_rounded,\n"
     "      message: _a.enabled ? '${AlarmService.nextLabel(_a)}에 깨워 드릴게요' : '알람을 껐어요',\n"
     "    );\n"
     "    Navigator.pop(context);\n"),
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
    for p in (SERVICE, SCREEN, MANIFEST):
        if not os.path.exists(p):
            print('❌ 파일을 못 찾았어요:', p)
            print('   apply_alarm.py 를 먼저 실행해 주세요')
            sys.exit(1)
    rec_path = os.path.join(os.path.dirname(act), 'AlarmReceiver.kt')
    if os.path.exists(rec_path):
        print('이미 적용돼 있어요')
        return
    act_text = open(act, 'rb').read().decode('utf-8')
    pkg = None
    for line in act_text.splitlines():
        if line.startswith('package '):
            pkg = line.split()[1].strip()
            break
    if not pkg:
        print('❌ MainActivity.kt 에서 package 줄을 못 찾았어요')
        sys.exit(1)

    out = []
    ok = True
    for path, edits, check in ((act, KT_EDITS, True), (MANIFEST, MANIFEST_EDITS, False),
                               (SERVICE, SERVICE_EDITS, True), (SCREEN, SCREEN_EDITS, True)):
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
        if check and before and not balanced(text):
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
    print('✔ 새 파일:', os.path.relpath(rec_path, ROOT).replace('\\', '/'))
    print('\n다 바꿨어요. 앱을 완전히 끄고 flutter run 으로 다시 켠 뒤, 알람을 한 번 더 저장해 주세요.')


if __name__ == '__main__':
    main()
