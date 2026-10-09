package kr.ssing.catsong

import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.media.audiofx.Equalizer
import android.provider.MediaStore
import android.provider.Settings
import android.media.AudioManager
import android.media.AudioFocusRequest
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "kr.ssing.catsong/media"

    companion object {
        // 녹음 알림 버튼(일시정지·이어서·완료) → 앱(녹음 화면)으로 전달
        var recordingChannel: MethodChannel? = null
    }
    private var equalizer: Equalizer? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var flutterMethodChannel: MethodChannel? = null

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                flutterMethodChannel?.invokeMethod("onAudioFocusLost", null)
            }
            AudioManager.AUDIOFOCUS_GAIN,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT -> {
                flutterMethodChannel?.invokeMethod("onAudioFocusGain", null)
            }
        }
    }

    override fun onResume() {
        super.onResume()
    }

    // ───── 아침 알람 ─────
    // 폰의 알람 시계(setAlarmClock)에 예약 → 시간이 되면 이 화면이 잠금화면 위로 켜지고 앱에 "alarmFired"
    private var alarmChannel: MethodChannel? = null
    private var pendingAlarm = false // 알람 때문에 켜졌는지 (앱이 물어보면 알려주고 지움)

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleAlarmIntent(intent)
        handleHeadsetIntent(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleAlarmIntent(intent)
        handleHeadsetIntent(intent)
    }

    private fun handleAlarmIntent(i: android.content.Intent?) {
        if (i == null || !i.getBooleanExtra("paranAlarm", false)) return
        i.removeExtra("paranAlarm") // 화면을 다시 그릴 때 또 울리지 않게
        pendingAlarm = true
        AlarmReceiver.cancelNotification(this) // 계속 울리던 알람 알림 끄기
        AlarmReceiver.cancelBackup(this) // 1분 뒤 한 번 더도 취소
        showOverLock(true)
        alarmChannel?.invokeMethod("alarmFired", null)
    }

    /// 잠금화면 위로 보이기 + 화면 켜기 (알람 끄면 원래대로)
    private fun showOverLock(on: Boolean) {
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
        } else {
            @Suppress("DEPRECATION")
            val f = android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (on) window.addFlags(f) else window.clearFlags(f)
        }
    }

    private fun alarmPendingIntent(): android.app.PendingIntent {
        // 시간이 되면 AlarmReceiver가 받아서 알람 화면을 띄움 (꺼진 앱은 화면을 직접 못 띄워서)
        val i = android.content.Intent(this, AlarmReceiver::class.java).apply {
            action = "kr.ssing.catsong.ALARM_FIRE"
        }
        return android.app.PendingIntent.getBroadcast(
            this, 7100, i,
            android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun canExactAlarm(): Boolean {
        if (Build.VERSION.SDK_INT < 31) return true
        val am = getSystemService(ALARM_SERVICE) as android.app.AlarmManager
        return am.canScheduleExactAlarms()
    }

    private fun scheduleParanAlarm(at: Long): Boolean {
        return try {
            val am = getSystemService(ALARM_SERVICE) as android.app.AlarmManager
            // 상태바 알람 아이콘을 누르면 앱이 열리게
            val show = android.app.PendingIntent.getActivity(
                this, 7101, android.content.Intent(this, MainActivity::class.java),
                android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT
            )
            am.setAlarmClock(android.app.AlarmManager.AlarmClockInfo(at, show), alarmPendingIntent())
            true
        } catch (e: Exception) {
            android.util.Log.e("ParanAlarm", "예약 실패: ${e.message}")
            false
        }
    }

    private fun cancelParanAlarm() {
        try {
            val am = getSystemService(ALARM_SERVICE) as android.app.AlarmManager
            am.cancel(alarmPendingIntent())
            am.cancel(AlarmReceiver.activityIntent(this)) // 처음 방식으로 걸어둔 예약
        } catch (_: Exception) {}
    }

    private fun requestAudioFocus() {
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setOnAudioFocusChangeListener(audioFocusChangeListener)
                .build()
            audioManager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
        }
    }
    private var bassBoost: android.media.audiofx.BassBoost? = null
    private var presetReverb: android.media.audiofx.PresetReverb? = null // 울림
    private var virtualizer: android.media.audiofx.Virtualizer? = null
    private var deleteResult: MethodChannel.Result? = null
    // 노래·영상 정보 읽기는 뒤에서 하나씩 (화면·터치 담당 일꾼이 멈추지 않게)
    private val metaExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()
    // 곡마다 소리 크기 재기는 따로 (재는 동안 앨범 사진 불러오기가 안 막히게)
    private val loudExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()
    // 영상 찍은 곳 찾기는 따로 (주소 바꾸느라 느려도 썸네일은 안 막히게)
    private val placeExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()

    // ───── 완료 효과음 (소리 모드 = 물방울, 진동 모드 = 진동, 무음 = 없음) ─────
    private var soundPool: android.media.SoundPool? = null
    private var dropId = 0
    private var dropLowId = 0
    private var pendingLow: Boolean? = null // 처음 불러오는 중에 눌렸으면 다 불러온 뒤 재생

    private fun ensureSoundPool() {
        if (soundPool != null) return
        val attrs = android.media.AudioAttributes.Builder()
            .setUsage(android.media.AudioAttributes.USAGE_ASSISTANCE_SONIFICATION) // 음악을 멈추지 않고 살짝 겹쳐서
            .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val pool = android.media.SoundPool.Builder().setMaxStreams(2).setAudioAttributes(attrs).build()
        pool.setOnLoadCompleteListener { sp, id, status ->
            val want = pendingLow ?: return@setOnLoadCompleteListener
            if (status == 0 && id == (if (want) dropLowId else dropId)) {
                sp.play(id, 0.6f, 0.6f, 1, 0, 1f)
                pendingLow = null
            }
        }
        try {
            // R.raw 로 직접 가리켜야 앱 크기 줄이기(R8)가 소리 파일을 안 빼요
            dropId = pool.load(this, R.raw.water_drop, 1)
            dropLowId = pool.load(this, R.raw.water_drop_low, 1)
        } catch (e: Exception) {
            android.util.Log.e("FeedbackSound", "소리 파일 못 불러옴: ${e.message}")
        }
        soundPool = pool // 실패해도 하나만 만들고 다시 안 만들기 (쌓이지 않게)
    }

    private fun shortVibrate(ms: Long, twice: Boolean = false) {
        // 앱의 원래 터치 진동과 같은 방식·세기(최대)로 → 잘 느껴지게
        @Suppress("DEPRECATION")
        val v = getSystemService(android.content.Context.VIBRATOR_SERVICE) as android.os.Vibrator
        if (android.os.Build.VERSION.SDK_INT >= 26) {
            if (twice) {
                // 삭제: "드드" 두 번
                v.vibrate(android.os.VibrationEffect.createWaveform(
                    longArrayOf(0, ms, 70, ms), intArrayOf(0, 255, 0, 255), -1))
            } else {
                v.vibrate(android.os.VibrationEffect.createOneShot(ms, 255))
            }
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(ms)
        }
    }

    private var renameResult: MethodChannel.Result? = null
    private var pendingRenameName: String? = null
    private var pendingRenameUri: android.net.Uri? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 101 || requestCode == 102) {
            if (resultCode == android.app.Activity.RESULT_OK) {
                deleteResult?.success(true)
            } else {
                deleteResult?.success(false)
            }
            deleteResult = null
        }
        if (requestCode == 103) {
            android.util.Log.d("RenameVideo", "onActivityResult 103 호출됨, resultCode=$resultCode")
            if (resultCode == android.app.Activity.RESULT_OK) {
                val uri = pendingRenameUri
                val newName = pendingRenameName
                android.util.Log.d("RenameVideo", "uri=$uri, newName=$newName")
                if (uri != null && newName != null) {
                    val success = doRenameVideo(uri, newName)
                    android.util.Log.d("RenameVideo", "doRenameVideo 결과=$success")
                    renameResult?.success(success)
                } else {
                    renameResult?.success(false)
                }
            } else {
                android.util.Log.d("RenameVideo", "사용자가 거부했거나 resultCode 다름")
                renameResult?.success(false)
            }
            renameResult = null
            pendingRenameUri = null
            pendingRenameName = null
        }
    }

    // ───── 이어폰·블루투스 연결하면 "이어서 들을까요?" 알림 ─────
    private val headsetNotiId = 4207

    private fun showHeadsetAsk(title: String, text: String) {
        try {
            val nm = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
            if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel("paran_headset") == null) {
                val ch = android.app.NotificationChannel(
                    "paran_headset", "이어폰 연결 알림", android.app.NotificationManager.IMPORTANCE_HIGH)
                ch.setSound(null, null) // 소리 없이 위에 살짝만
                ch.enableVibration(false)
                nm.createNotificationChannel(ch)
            }
            val open = android.content.Intent(this, MainActivity::class.java).apply {
                putExtra("headsetResume", true)
                addFlags(android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            val pi = android.app.PendingIntent.getActivity(
                this, headsetNotiId, open,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE)
            val b = if (Build.VERSION.SDK_INT >= 26) android.app.Notification.Builder(this, "paran_headset")
                    else android.app.Notification.Builder(this)
            b.setSmallIcon(applicationInfo.icon)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(pi)
                .setAutoCancel(true)
                .addAction(android.app.Notification.Action.Builder(
                    null as android.graphics.drawable.Icon?, "재생", pi).build())
            if (Build.VERSION.SDK_INT >= 26) b.setTimeoutAfter(5 * 60 * 1000L) // 5분 지나면 저절로 사라짐
            nm.notify(headsetNotiId, b.build())
        } catch (_: Exception) {}
    }

    private fun cancelHeadsetAsk() {
        try {
            (getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager).cancel(headsetNotiId)
        } catch (_: Exception) {}
    }

    /// 알림의 "재생"을 눌러서 열렸으면 → 앱에 이어서 재생하라고
    private fun handleHeadsetIntent(i: android.content.Intent?) {
        if (i == null || !i.getBooleanExtra("headsetResume", false)) return
        i.removeExtra("headsetResume")
        cancelHeadsetAsk()
        flutterMethodChannel?.invokeMethod("onHeadsetResume", null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        flutterMethodChannel = channel
        HeadsetWatch.start(this, channel) // 이어폰·블루투스 연결 알아채기
        recordingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kr.ssing.catsong/recording")
        // 아침 알람 통로
        alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kr.ssing.catsong/alarm").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val at = (call.argument<Any>("at") as? Number)?.toLong() ?: 0L
                        val ok = at > 0 && scheduleParanAlarm(at)
                        if (ok) {
                            // 폰을 껐다 켜도 다시 예약할 수 있게 기억
                            AlarmReceiver.saveAt(this@MainActivity, at)
                            val h = (call.argument<Any>("hour") as? Number)?.toInt()
                            val m = (call.argument<Any>("minute") as? Number)?.toInt()
                            if (h != null && m != null) {
                                AlarmReceiver.saveRule(this@MainActivity, h, m, call.argument<String>("days") ?: "")
                            }
                        }
                        result.success(ok)
                    }
                    "cancel" -> {
                        cancelParanAlarm()
                        AlarmReceiver.clearRule(this@MainActivity)
                        result.success(true)
                    }
                    "canExact" -> result.success(canExactAlarm())
                    "openExactSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= 31) {
                                startActivity(android.content.Intent(
                                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                    android.net.Uri.parse("package:$packageName")))
                            }
                        } catch (_: Exception) {}
                        result.success(true)
                    }
                    "canFullScreen" -> {
                        // 안드로이드 14 이상: 잠금화면 위로 알람 화면 띄우기 허용됐는지
                        val ok = if (Build.VERSION.SDK_INT >= 34) {
                            (getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager)
                                .canUseFullScreenIntent()
                        } else true
                        result.success(ok)
                    }
                    "openFullScreenSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= 34) {
                                startActivity(android.content.Intent(
                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    android.net.Uri.parse("package:$packageName")))
                            }
                        } catch (_: Exception) {}
                        result.success(true)
                    }
                    "getMusicVolume" -> {
                        // 폰 미디어 볼륨 (0.0 ~ 1.0)
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        result.success(if (max > 0) am.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max else 0.0)
                    }
                    "setMusicVolume" -> {
                        val v = (call.argument<Any>("v") as? Number)?.toDouble() ?: 0.7
                        try {
                            val am = getSystemService(AUDIO_SERVICE) as AudioManager
                            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                            am.setStreamVolume(AudioManager.STREAM_MUSIC, Math.round(v.coerceIn(0.0, 1.0) * max).toInt(), 0)
                        } catch (_: Exception) {}
                        result.success(true)
                    }
                    "playFallback" -> {
                        AlarmReceiver.playFallback(this@MainActivity)
                        result.success(true)
                    }
                    "stopFallback" -> {
                        AlarmReceiver.stopFallback()
                        result.success(true)
                    }
                    "isAlarmIntent" -> {
                        // 지금 화면이 알람(전체 화면 알림)으로 열렸는지
                        result.success(intent?.action == "kr.ssing.catsong.ALARM")
                    }
                    "takeLaunchAlarm" -> {
                        val p = pendingAlarm
                        pendingAlarm = false
                        result.success(p)
                    }
                    "ringDone" -> {
                        AlarmReceiver.cancelNotification(this@MainActivity)
                        AlarmReceiver.stopFallback()
                        intent?.setAction(android.content.Intent.ACTION_MAIN) // 알람 표시 지우기
                        showOverLock(false)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlbumArt" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(null)
                    } else {
                        metaExecutor.execute {
                            val art = getAlbumArt(path)
                            runOnUiThread { result.success(art) }
                        }
                    }
                }
                "getSongMetadata" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(null)
                    } else {
                        metaExecutor.execute {
                            val meta = getSongMetadata(path)
                            runOnUiThread { result.success(meta) }
                        }
                    }
                }
                "trimAndSetRingtone" -> {
                    val path = call.argument<String>("path")
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: 0L
                    // 자르는 동안 화면이 안 멈추게 따로 처리
                    if (path != null) {
                        Thread {
                            val r = trimAndSetRingtone(path, startMs, endMs)
                            runOnUiThread { result.success(r) }
                        }.start()
                    } else result.success("fail")
                }
                "multicastLock" -> {
                    // TV 찾기(DLNA) 할 때 와이파이 멀티캐스트 응답을 받기 위해
                    val on = call.argument<Boolean>("on") ?: false
                    val wifi = applicationContext.getSystemService(android.content.Context.WIFI_SERVICE)
                            as android.net.wifi.WifiManager
                    if (on) {
                        if (multicastLock == null) {
                            multicastLock = wifi.createMulticastLock("paransori_cast").apply {
                                setReferenceCounted(false)
                            }
                        }
                        multicastLock?.acquire()
                    } else {
                        multicastLock?.release()
                    }
                    result.success(true)
                }
                "recordingService" -> {
                    // 녹음 중 알림: start / pause / resume / stop
                    val action = call.argument<String>("action") ?: "stop"
                    val intent = android.content.Intent(this, RecordingService::class.java)
                    if (action == "stop") {
                        stopService(intent)
                    } else {
                        intent.putExtra(RecordingService.EXTRA_PAUSED, action == "pause")
                        intent.putExtra(RecordingService.EXTRA_BASE,
                            (call.argument<Any>("base") as? Number)?.toLong() ?: System.currentTimeMillis())
                        intent.putExtra(RecordingService.EXTRA_ELAPSED,
                            (call.argument<Any>("elapsed") as? Number)?.toLong() ?: 0L)
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                    }
                    result.success(true)
                }
                "appFilesDir" -> result.success(filesDir.absolutePath) // 녹음 중인 파일을 두는 앱 전용 폴더
                "saveRecording" -> {
                    // 파란소리에서 녹음한 파일을 Recordings/Paransori 폴더에 저장
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name") ?: "녹음"
                    if (path == null) {
                        result.success(null)
                    } else {
                        try {
                            // 녹음은 끊겨도 안전한 .aac로 받으니까, 저장할 때 .m4a로 옮겨 담기 (길이·넘기기 정확하게)
                            var src = File(path)
                            if (path.endsWith(".aac")) {
                                val m4a = File(cacheDir, "rec_save.m4a")
                                if (m4a.exists()) m4a.delete()
                                if (trimWithMuxer(path, m4a, 0L, 24L * 3600 * 1000)) src = m4a
                            }
                            val relDir = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S)
                                "Recordings/Paransori" else "Podcasts/Paransori" // 안드로이드 11 이하: 음악 목록에 안 섞이는 곳
                            val values = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, "$name.m4a")
                                put(MediaStore.MediaColumns.MIME_TYPE, "audio/mp4")
                                put(MediaStore.MediaColumns.RELATIVE_PATH, "$relDir/")
                            }
                            val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                            if (uri == null) {
                                result.success(null)
                            } else {
                                contentResolver.openOutputStream(uri)?.use { os -> src.inputStream().use { it.copyTo(os) } }
                                var savedName = "$name.m4a"
                                contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                                    if (c.moveToFirst()) savedName = c.getString(0) ?: savedName
                                }
                                val outPath = File(android.os.Environment.getExternalStorageDirectory(), "$relDir/$savedName").absolutePath
                                android.media.MediaScannerConnection.scanFile(this, arrayOf(outPath), null, null)
                                result.success(outPath)
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("SaveRecording", "Error: ${e.message}", e)
                            // 실패 이유를 앱으로 보내서 Crashlytics에 남기기
                            result.error("SAVE_FAIL", "${e.javaClass.simpleName}: ${e.message} (SDK ${android.os.Build.VERSION.SDK_INT})", null)
                        }
                    }
                }
                "trimVideo", "extractAudio" -> {
                    // 동영상 잘라서 저장(영상) / 소리만 뽑아 음악으로 저장 — 다시 압축 안 해서 빠르고 화질 그대로
                    val path = call.argument<String>("path")
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: 0L
                    val outBase = (call.argument<String>("outBase") ?: "동영상").replace(Regex("[\\\\/:*?\"<>|]"), "_")
                    if (path == null || endMs <= startMs) {
                        result.success(null)
                    } else {
                        val audio = call.method == "extractAudio"
                        Thread {
                            val saved = if (audio) saveVideoAudio(path, startMs, endMs, outBase)
                                        else saveTrimmedVideo(path, startMs, endMs, outBase)
                            runOnUiThread { result.success(saved) }
                        }.start()
                    }
                }
                "trimAndSave" -> {
                    // 자르기: 원본은 그대로 두고 잘라낸 부분을 새 파일로 저장 (오래 걸릴 수 있어 따로 실행)
                    val path = call.argument<String>("path")
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: 0L
                    if (path == null) {
                        result.success(null)
                    } else {
                        Thread {
                            val saved = trimAndSave(path, startMs, endMs, call.argument<String>("relDir"), call.argument<String>("outBase"))
                            runOnUiThread { result.success(saved) }
                        }.start()
                    }
                }
                "initEqualizer" -> {
                    val audioSessionId = (call.argument<Any>("audioSessionId") as? Number)?.toInt() ?: 0
                    result.success(initEqualizer(audioSessionId))
                }
                "setEqualizerBand" -> {
                    val band = (call.argument<Any>("band") as? Number)?.toShort() ?: 0
                    val level = (call.argument<Any>("level") as? Number)?.toShort() ?: 0
                    equalizer?.setBandLevel(band, level)
                    result.success(true)
                }
                "setEqualizerPreset" -> {
                    val preset = (call.argument<Any>("preset") as? Number)?.toShort() ?: 0
                    equalizer?.usePreset(preset)
                    result.success(true)
                }
                "releaseEqualizer" -> {
                    equalizer?.release()
                    equalizer = null
                    result.success(true)
                }
                "getEqualizerBandLevel" -> {
                    val band = (call.argument<Any>("band") as? Number)?.toShort() ?: 0
                    val level = equalizer?.getBandLevel(band)?.toInt() ?: 0
                    result.success(level)
                }
                "initBassBoost" -> {
                    val audioSessionId = (call.argument<Any>("audioSessionId") as? Number)?.toInt() ?: 0
                    try {
                        bassBoost?.release()
                        bassBoost = android.media.audiofx.BassBoost(0, audioSessionId)
                        bassBoost?.enabled = true
                        result.success(bassBoost?.roundedStrength?.toInt() ?: 0)
                    } catch (e: Exception) {
                        result.success(0)
                    }
                }
                "setBassBoost" -> {
                    val strength = (call.argument<Any>("strength") as? Number)?.toShort() ?: 0
                    try {
                        bassBoost?.setStrength(strength)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "initVirtualizer" -> {
                    val audioSessionId = (call.argument<Any>("audioSessionId") as? Number)?.toInt() ?: 0
                    try {
                        virtualizer?.release()
                        virtualizer = android.media.audiofx.Virtualizer(0, audioSessionId)
                        virtualizer?.enabled = true
                        result.success(virtualizer?.roundedStrength?.toInt() ?: 0)
                    } catch (e: Exception) {
                        result.success(0)
                    }
                }
                "setVirtualizer" -> {
                    val strength = (call.argument<Any>("strength") as? Number)?.toShort() ?: 0
                    try {
                        virtualizer?.setStrength(strength)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "initReverb" -> {
                    // 울림(리버브): 폰이 지원하면 true
                    val audioSessionId = (call.argument<Any>("audioSessionId") as? Number)?.toInt() ?: 0
                    try {
                        presetReverb?.release()
                        presetReverb = android.media.audiofx.PresetReverb(0, audioSessionId)
                        presetReverb?.enabled = true
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("Reverb", "울림 안 됨: ${e.message}")
                        presetReverb = null
                        result.success(false)
                    }
                }
                "setReverb" -> {
                    // 0 끄기 · 1 작은 방 · 2 거실 · 3 큰 방 · 4 공연장 · 5 대극장 · 6 스튜디오
                    val preset = (call.argument<Any>("preset") as? Number)?.toShort() ?: 0
                    try {
                        presetReverb?.preset = preset
                        presetReverb?.enabled = preset.toInt() != 0
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "releaseAudioEffects" -> {
                    bassBoost?.release()
                    bassBoost = null
                    virtualizer?.release()
                    virtualizer = null
                    result.success(true)
                }
                "updateSongMetadata" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title")
                    val artist = call.argument<String>("artist")
                    val album = call.argument<String>("album")
                    if (path != null) {
                        result.success(updateSongMetadata(path, title, artist, album))
                    } else {
                        result.success(false)
                    }
                }
                "measureLoudness" -> {
                    // 곡마다 소리 크기 맞추기: 곡 가운데 몇 군데를 잠깐 풀어서 평균 소리 크기(dB)
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(null)
                    } else {
                        loudExecutor.execute {
                            val db = measureLoudness(path)
                            runOnUiThread { result.success(db) }
                        }
                    }
                }
                "getVideoList" -> {
                    val list = getVideoList()
                    android.util.Log.d("RenameVideo", "getVideoList 결과: $list")
                    result.success(list)
                }
                "getVideoPlace" -> {
                    // 영상 속 찍은 곳(위치 태그) → "서울 중구" (뒤에서 하나씩, 화면 안 멈추게)
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(null)
                    } else {
                        placeExecutor.execute {
                            val r = getVideoPlace(path)
                            runOnUiThread { result.success(r) }
                        }
                    }
                }
                "getVideoThumbnail" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(null)
                    } else {
                        metaExecutor.execute {
                            val thumb = getVideoThumbnail(path)
                            runOnUiThread { result.success(thumb) }
                        }
                    }
                }
                "renameVideo" -> {
                    val uri = call.argument<String>("uri")
                    val newName = call.argument<String>("newName")
                    if (uri != null && newName != null) {
                        renameVideo(uri, newName, result)
                    } else result.success(false)
                }
                "refreshMediaStore" -> {
                    android.media.MediaScannerConnection.scanFile(
                        this, arrayOf(android.os.Environment.getExternalStorageDirectory().absolutePath),
                        null, null
                    )
                    result.success(true)
                }
                "deleteFilesForever" -> {
                    // 녹음 영구 삭제 (휴지통 안 거치고 바로, 되살릴 수 없음)
                    val paths = call.argument<List<String>>("paths")
                    if (paths.isNullOrEmpty()) {
                        result.success(false)
                    } else {
                        try {
                            val uris = mutableListOf<android.net.Uri>()
                            for (path in paths) {
                                contentResolver.query(
                                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                                    arrayOf(MediaStore.Audio.Media._ID),
                                    "${MediaStore.Audio.Media.DATA}=?",
                                    arrayOf(path), null
                                )?.use {
                                    if (it.moveToFirst()) {
                                        val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                                        uris.add(android.net.Uri.withAppendedPath(
                                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id.toString()))
                                    }
                                }
                            }
                            if (uris.isEmpty()) {
                                result.error("NOT_FOUND", "MediaStore에서 못 찾음: ${paths.size}개 (SDK ${android.os.Build.VERSION.SDK_INT})", null)
                            } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                deleteResult = result
                                val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
                                startIntentSenderForResult(pendingIntent.intentSender, 102, null, 0, 0, 0)
                            } else {
                                var count = 0
                                for (uri in uris) count += contentResolver.delete(uri, null, null)
                                result.success(count > 0)
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("DeleteForever", "Error: ${e.message}", e)
                            result.error("DELETE_FAIL", "${e.javaClass.simpleName}: ${e.message} (SDK ${android.os.Build.VERSION.SDK_INT})", null)
                        }
                    }
                }
                "feedbackSound" -> {
                    // 폰 소리 모드를 보고: 소리 → 물방울 / 진동 → 진동 / 무음 → 아무것도 안 함
                    val low = call.argument<Boolean>("low") ?: false
                    val am = getSystemService(android.content.Context.AUDIO_SERVICE) as android.media.AudioManager
                    android.util.Log.d("FeedbackSound", "폰 모드: ${am.ringerMode} (2=소리, 1=진동, 0=무음)")
                    when (am.ringerMode) {
                        android.media.AudioManager.RINGER_MODE_NORMAL -> {
                            try {
                                val first = soundPool == null
                                ensureSoundPool()
                                val id = if (low) dropLowId else dropId
                                if (first) {
                                    pendingLow = low // 처음엔 불러오는 중이라, 다 불러오면 바로 재생
                                } else if (id != 0) {
                                    soundPool?.play(id, 0.6f, 0.6f, 1, 0, 1f)
                                }
                            } catch (e: Exception) {
                                android.util.Log.e("FeedbackSound", "소리 오류: ${e.message}")
                            }
                        }
                        android.media.AudioManager.RINGER_MODE_VIBRATE -> {
                            try {
                                shortVibrate(90L, twice = low) // 수정·저장: "드" / 삭제: "드드" (더 또렷하게)
                            } catch (e: Exception) {
                                android.util.Log.e("FeedbackSound", "진동 오류: ${e.message}")
                            }
                        }
                        else -> {}
                    }
                    result.success(null)
                }
                "trashFiles" -> {
                    // 녹음 삭제: 바로 지우지 않고 휴지통으로 (30일 동안 내 파일 → 휴지통에서 되살릴 수 있음)
                    val paths = call.argument<List<String>>("paths")
                    if (paths.isNullOrEmpty()) {
                        result.success(false)
                    } else {
                        try {
                            val uris = mutableListOf<android.net.Uri>()
                            for (path in paths) {
                                contentResolver.query(
                                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                                    arrayOf(MediaStore.Audio.Media._ID),
                                    "${MediaStore.Audio.Media.DATA}=?",
                                    arrayOf(path), null
                                )?.use {
                                    if (it.moveToFirst()) {
                                        val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                                        uris.add(android.net.Uri.withAppendedPath(
                                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id.toString()
                                        ))
                                    }
                                }
                            }
                            if (uris.isEmpty()) {
                                // 음악 목록에서 녹음 파일을 하나도 못 찾음 → 이유를 앱으로 보내기
                                result.error("NOT_FOUND", "MediaStore에서 못 찾음: ${paths.size}개 (예: ${paths.first()}) (SDK ${android.os.Build.VERSION.SDK_INT})", null)
                            } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                deleteResult = result
                                val pendingIntent = MediaStore.createTrashRequest(contentResolver, uris, true)
                                startIntentSenderForResult(pendingIntent.intentSender, 102, null, 0, 0, 0)
                            } else {
                                var count = 0
                                for (uri in uris) count += contentResolver.delete(uri, null, null)
                                result.success(count > 0)
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("TrashFiles", "Error: ${e.message}", e)
                            result.error("TRASH_FAIL", "${e.javaClass.simpleName}: ${e.message} (SDK ${android.os.Build.VERSION.SDK_INT})", null)
                        }
                    }
                }
                "deleteSongs" -> {
                    val paths = call.argument<List<String>>("paths")
                    if (paths != null && paths.isNotEmpty()) {
                        try {
                            val uris = mutableListOf<android.net.Uri>()
                            for (path in paths) {
                                val cursor = contentResolver.query(
                                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                                    arrayOf(MediaStore.Audio.Media._ID),
                                    "${MediaStore.Audio.Media.DATA}=?",
                                    arrayOf(path), null
                                )
                                cursor?.use {
                                    if (it.moveToFirst()) {
                                        val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                                        uris.add(android.net.Uri.withAppendedPath(
                                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id.toString()
                                        ))
                                    }
                                }
                            }
                            if (uris.isNotEmpty()) {
                                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                    deleteResult = result
                                    val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
                                    startIntentSenderForResult(pendingIntent.intentSender, 102, null, 0, 0, 0)
                                } else {
                                    var count = 0
                                    for (uri in uris) {
                                        count += contentResolver.delete(uri, null, null)
                                    }
                                    result.success(count > 0)
                                }
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else result.success(false)
                }
                "deleteSong" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        try {
                            val cursor = contentResolver.query(
                                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                                arrayOf(MediaStore.Audio.Media._ID),
                                "${MediaStore.Audio.Media.DATA}=?",
                                arrayOf(uri), null
                            )
                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                                    val audioUri = android.net.Uri.withAppendedPath(
                                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id.toString()
                                    )
                                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                        deleteResult = result
                                        val pendingIntent = MediaStore.createDeleteRequest(
                                            contentResolver, listOf(audioUri)
                                        )
                                        startIntentSenderForResult(
                                            pendingIntent.intentSender, 102, null, 0, 0, 0
                                        )
                                    } else {
                                        contentResolver.delete(audioUri, null, null)
                                        result.success(true)
                                    }
                                } else {
                                    result.success(false)
                                }
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("DeleteSong", "Error: ${e.message}", e)
                            result.success(false)
                        }
                    } else result.success(false)
                }
                "trashVideos", "deleteVideosForever" -> {
                    // 동영상 여러 개 삭제: 휴지통(30일 뒤 완전 삭제) 또는 영구 삭제 — 폰 확인 창은 한 번만
                    val paths = call.argument<List<String>>("paths")
                    if (paths.isNullOrEmpty()) {
                        result.success(false)
                    } else {
                        try {
                            val uris = mutableListOf<android.net.Uri>()
                            for (path in paths) {
                                contentResolver.query(
                                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                    arrayOf(MediaStore.Video.Media._ID),
                                    "${MediaStore.Video.Media.DATA}=?",
                                    arrayOf(path), null
                                )?.use {
                                    if (it.moveToFirst()) {
                                        val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media._ID))
                                        uris.add(android.net.Uri.withAppendedPath(
                                            MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString()))
                                    }
                                }
                            }
                            if (uris.isEmpty()) {
                                result.success(false)
                            } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                deleteResult = result
                                val pendingIntent = if (call.method == "trashVideos")
                                    MediaStore.createTrashRequest(contentResolver, uris, true)
                                else
                                    MediaStore.createDeleteRequest(contentResolver, uris)
                                startIntentSenderForResult(pendingIntent.intentSender, 101, null, 0, 0, 0)
                            } else {
                                var count = 0
                                for (uri in uris) count += contentResolver.delete(uri, null, null)
                                result.success(count > 0)
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("DeleteVideos", "Error: ${e.message}", e)
                            result.success(false)
                        }
                    }
                }
                "deleteVideo" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        try {
                            val cursor = contentResolver.query(
                                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                                arrayOf(MediaStore.Video.Media._ID),
                                "${MediaStore.Video.Media.DATA}=?",
                                arrayOf(uri), null
                            )
                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media._ID))
                                    val videoUri = android.net.Uri.withAppendedPath(
                                        MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString()
                                    )
                                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                        deleteResult = result
                                        val pendingIntent = MediaStore.createDeleteRequest(
                                            contentResolver, listOf(videoUri)
                                        )
                                        startIntentSenderForResult(
                                            pendingIntent.intentSender, 101, null, 0, 0, 0
                                        )
                                    } else {
                                        contentResolver.delete(videoUri, null, null)
                                        result.success(true)
                                    }
                                } else {
                                    result.success(false)
                                }
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("DeleteVideo", "Error: ${e.message}", e)
                            result.success(false)
                        }
                    } else result.success(false)
                }
                "moveToBackground" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }
                "closeApp" -> {
                    result.success(true)
                    finishAffinity()
                    android.os.Process.killProcess(android.os.Process.myPid())
                }
                "showHeadsetAsk" -> {
                    showHeadsetAsk(call.argument<String>("title") ?: "이어서 들을까요?",
                        call.argument<String>("text") ?: "")
                    result.success(true)
                }
                "cancelHeadsetAsk" -> {
                    cancelHeadsetAsk()
                    result.success(true)
                }
                "vibrate" -> {
                    try {
                        @Suppress("DEPRECATION")
                        val vibrator = getSystemService(android.content.Context.VIBRATOR_SERVICE) as android.os.Vibrator
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            vibrator.vibrate(android.os.VibrationEffect.createOneShot(50, 255))
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(50)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "widgetPlayPause" -> { result.success(true) }
                "widgetNext" -> { result.success(true) }
                "widgetPrev" -> { result.success(true) }
                "requestWidgetAdd" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(this)
                        val provider = android.content.ComponentName(this, PlayerWidget::class.java)
                        if (appWidgetManager.isRequestPinAppWidgetSupported) {
                            appWidgetManager.requestPinAppWidget(provider, null, null)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "requestBatteryOptimization" -> {
                    val pm = getSystemService(POWER_SERVICE) as android.os.PowerManager
                    if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = android.net.Uri.parse("package:$packageName")
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "isBatteryOptimized" -> {
                    val pm = getSystemService(POWER_SERVICE) as android.os.PowerManager
                    result.success(!pm.isIgnoringBatteryOptimizations(packageName))
                }
                "requestAudioFocus" -> {
                    requestAudioFocus()
                    result.success(true)
                }
                "updateWidget" -> {
                    val title = call.argument<String>("title") ?: "파란소리"
                    val artist = call.argument<String>("artist") ?: "음악을 재생해보세요"
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val schedule = call.argument<String>("schedule") ?: ""
                    val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(this)
                    val ids = appWidgetManager.getAppWidgetIds(
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
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// 곡마다 소리 크기 맞추기: 곡 가운데 몇 군데(각 8초)를 풀어서 평균 소리 크기(dB) 재기
    /// 결과: -60 ~ 0 쯤 (클수록 큰 곡), 못 재면 null
    private fun measureLoudness(path: String): Double? {
        val ex = android.media.MediaExtractor()
        var codec: android.media.MediaCodec? = null
        try {
            if (path.startsWith("content://")) {
                ex.setDataSource(this, android.net.Uri.parse(path), null)
            } else {
                ex.setDataSource(path)
            }
            var track = -1
            var fmt: android.media.MediaFormat? = null
            for (i in 0 until ex.trackCount) {
                val f = ex.getTrackFormat(i)
                if ((f.getString(android.media.MediaFormat.KEY_MIME) ?: "").startsWith("audio/")) {
                    track = i
                    fmt = f
                    break
                }
            }
            if (track < 0 || fmt == null) return null
            ex.selectTrack(track)
            val durUs = if (fmt.containsKey(android.media.MediaFormat.KEY_DURATION))
                fmt.getLong(android.media.MediaFormat.KEY_DURATION) else 0L
            val c = android.media.MediaCodec.createDecoderByType(fmt.getString(android.media.MediaFormat.KEY_MIME)!!)
            codec = c
            c.configure(fmt, null, null, 0)
            c.start()
            var sumSq = 0.0
            var count = 0L
            // 1분 넘는 곡은 25% · 50% · 75% 지점, 짧은 곡은 처음부터
            val starts = if (durUs > 60_000_000L) listOf(durUs / 4, durUs / 2, durUs * 3 / 4) else listOf(0L)
            val segUs = 8_000_000L
            val info = android.media.MediaCodec.BufferInfo()
            for (s in starts) {
                ex.seekTo(s, android.media.MediaExtractor.SEEK_TO_CLOSEST_SYNC)
                c.flush()
                val endUs = s + segUs
                var inputDone = false
                var outDone = false
                var guard = 0
                while (!outDone && guard++ < 4000) {
                    if (!inputDone) {
                        val ii = c.dequeueInputBuffer(10_000)
                        if (ii >= 0) {
                            val buf = c.getInputBuffer(ii)!!
                            val n = ex.readSampleData(buf, 0)
                            val t = ex.sampleTime
                            if (n < 0 || t > endUs) {
                                c.queueInputBuffer(ii, 0, 0, 0, android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            } else {
                                c.queueInputBuffer(ii, 0, n, t, 0)
                                ex.advance()
                            }
                        }
                    }
                    val oi = c.dequeueOutputBuffer(info, 10_000)
                    if (oi >= 0) {
                        if (info.size > 0) {
                            val ob = c.getOutputBuffer(oi)!!
                            ob.position(info.offset)
                            ob.limit(info.offset + info.size)
                            val sb = ob.order(java.nio.ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                            while (sb.hasRemaining()) {
                                val v = sb.get() / 32768.0
                                sumSq += v * v
                                count++
                            }
                        }
                        c.releaseOutputBuffer(oi, false)
                        if ((info.flags and android.media.MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) outDone = true
                    }
                }
            }
            if (count == 0L) return null
            val rms = Math.sqrt(sumSq / count)
            if (rms <= 0.0) return null
            return 20 * Math.log10(rms)
        } catch (e: Exception) {
            android.util.Log.e("Loudness", "소리 크기 못 잼: ${e.message}")
            return null
        } finally {
            try {
                codec?.stop()
                codec?.release()
            } catch (_: Exception) {}
            ex.release()
        }
    }

    private fun getAlbumArt(path: String): ByteArray? {
        return try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(path)
            val art = retriever.embeddedPicture
            retriever.release()
            art
        } catch (e: Exception) { null }
    }

    private fun getSongMetadata(path: String): Map<String, Any?> {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            val title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
            val artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
            val album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val rawArt = retriever.embeddedPicture
            val albumArt = rawArt?.let { resizeAlbumArt(it) }
            retriever.release()
            mapOf("title" to title, "artist" to artist, "album" to album,
                "duration" to duration?.toLongOrNull(), "albumArt" to albumArt)
        } catch (e: Exception) {
            retriever.release()
            mapOf("title" to null, "artist" to null, "album" to null,
                "duration" to null, "albumArt" to null)
        }
    }

    // 앨범아트가 너무 크면(폰 카메라로 찍은 원본 화질 등) 메모리를 많이 잡아먹어서,
    // 목록/미니플레이어에 쓸 정도의 작은 크기로 줄여서 내려보낸다.
    private fun resizeAlbumArt(bytes: ByteArray, maxSize: Int = 300): ByteArray {
        return try {
            val original = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return bytes
            val width = original.width
            val height = original.height
            if (width <= maxSize && height <= maxSize) {
                return bytes
            }
            val scale = maxSize.toFloat() / maxOf(width, height)
            val newWidth = (width * scale).toInt().coerceAtLeast(1)
            val newHeight = (height * scale).toInt().coerceAtLeast(1)
            val resized = Bitmap.createScaledBitmap(original, newWidth, newHeight, true)
            val stream = ByteArrayOutputStream()
            resized.compress(Bitmap.CompressFormat.JPEG, 80, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            bytes
        }
    }

    /// 벨소리: 고른 구간을 제대로 잘라서 Ringtones 폴더에 저장 → 기본 벨소리로 지정
    /// 결과: "ok" / "permission"(시스템 설정 변경 허용 필요) / "fail"
    private fun trimAndSetRingtone(path: String, startMs: Long, endMs: Long): String {
        return try {
            val inputFile = File(path)
            if (!inputFile.exists()) return "fail"
            // 먼저 허용부터 확인 (안 돼 있으면 허용 화면만 열고 끝)
            if (!Settings.System.canWrite(this)) {
                val intent = android.content.Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                intent.data = android.net.Uri.parse("package:$packageName")
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return "permission"
            }
            // 곡 자르기와 같은 방식으로 제대로 자르기 (mp3: 소리 부분만 / m4a: 정식 방식)
            val isMp3 = path.lowercase().endsWith(".mp3")
            val ext = if (isMp3) "mp3" else "m4a"
            val tmp = File(cacheDir, "ringtone_tmp.$ext")
            if (tmp.exists()) tmp.delete()
            val cut = if (isMp3) trimMp3Bytes(inputFile, tmp, startMs, endMs)
                      else trimWithMuxer(path, tmp, startMs, endMs)
            if (!cut || tmp.length() == 0L) return "fail"

            // 파일 이름에 못 쓰는 글자는 _ 로
            val safe = inputFile.nameWithoutExtension.replace(Regex("[\\\\/:*?\"<>|]"), "_")
            val displayName = "${safe}_벨소리.$ext"
            // 같은 노래로 다시 지정하면 예전 벨소리 파일은 지우기 (못 지워도 괜찮음)
            try {
                contentResolver.delete(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    "${MediaStore.MediaColumns.DISPLAY_NAME}=?",
                    arrayOf(displayName)
                )
            } catch (_: Exception) {}
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(MediaStore.MediaColumns.MIME_TYPE, if (isMp3) "audio/mpeg" else "audio/mp4")
                put(MediaStore.Audio.Media.IS_RINGTONE, true)
                put(MediaStore.Audio.Media.IS_MUSIC, false)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Ringtones/")
            }
            val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                ?: return "fail"
            contentResolver.openOutputStream(uri)?.use { os -> tmp.inputStream().use { it.copyTo(os) } }
            android.media.RingtoneManager.setActualDefaultRingtoneUri(
                this, android.media.RingtoneManager.TYPE_RINGTONE, uri)
            android.util.Log.d("Ringtone", "벨소리 지정 완료: $displayName")
            return "ok"
        } catch (e: Exception) {
            android.util.Log.e("Ringtone", "Error: ${e.message}", e)
            "fail"
        }
    }

    private fun oldTrimAndSetRingtone(path: String, startMs: Long, endMs: Long): Boolean {
        return try {
            val inputFile = File(path)
            if (!inputFile.exists()) return false

            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(path)
            val title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
                ?: inputFile.nameWithoutExtension
            val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0L
            retriever.release()

            val ringtoneDir = File(getExternalFilesDir(null), "Ringtones")
            if (!ringtoneDir.exists()) ringtoneDir.mkdirs()
            val outputFile = File(ringtoneDir, "${title}_ringtone.mp3")

            val totalBytes = inputFile.length()
            val startByte = (totalBytes * startMs / durationMs)
            val endByte = (totalBytes * endMs / durationMs)

            inputFile.inputStream().use { inputStream ->
                inputStream.skip(startByte)
                outputFile.outputStream().use { outputStream ->
                    val buffer = ByteArray(8192)
                    var remaining = endByte - startByte
                    while (remaining > 0) {
                        val toRead = minOf(buffer.size.toLong(), remaining).toInt()
                        val read = inputStream.read(buffer, 0, toRead)
                        if (read < 0) break
                        outputStream.write(buffer, 0, read)
                        remaining -= read
                    }
                }
            }

            val displayName = "${title}_ringtone.mp3"
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                put(MediaStore.Audio.Media.IS_RINGTONE, true)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Ringtones/")
            }

            contentResolver.delete(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                "${MediaStore.MediaColumns.DISPLAY_NAME}=?",
                arrayOf(displayName)
            )

            val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
            if (uri != null) {
                contentResolver.openOutputStream(uri)?.use { os ->
                    outputFile.inputStream().copyTo(os)
                }
                if (Settings.System.canWrite(this)) {
                    android.media.RingtoneManager.setActualDefaultRingtoneUri(
                        this, android.media.RingtoneManager.TYPE_RINGTONE, uri)
                } else {
                    val intent = android.content.Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    intent.data = android.net.Uri.parse("package:$packageName")
                    startActivity(intent)
                    return false
                }
            }
            true
        } catch (e: Exception) {
            android.util.Log.e("Ringtone", "Error: ${e.message}", e)
            false
        }
    }

    /// 자르기: mp3는 바이트로, m4a/aac는 MediaMuxer로 잘라서 Music/Paransori 폴더에 새 파일로 저장
    /// 성공하면 저장된 파일 경로, 실패하거나 지원 안 하는 형식이면 null
    private var multicastLock: android.net.wifi.WifiManager.MulticastLock? = null

    private fun trimAndSave(
        path: String, startMs: Long, endMs: Long,
        relDirArg: String? = null, outBase: String? = null
    ): String? {
        return try {
            val inputFile = File(path)
            android.util.Log.d("Trim", "요청: ${inputFile.name} 시작=$startMs 끝=$endMs")
            if (!inputFile.exists() || endMs <= startMs) return null
            val ext = inputFile.extension.lowercase()
            val isMp3 = ext == "mp3"
            val isMp4 = ext == "m4a" || ext == "aac" || ext == "mp4"
            if (!isMp3 && !isMp4) return null

            val outExt = if (isMp3) "mp3" else "m4a"
            val tmp = File(cacheDir, "trim_tmp.$outExt")
            val ok = if (isMp3) trimMp3Bytes(inputFile, tmp, startMs, endMs)
                     else trimWithMuxer(path, tmp, startMs, endMs)
            if (!ok) return null

            // 녹음 자르기는 원래 녹음 폴더에 (Recordings 폴더는 안드로이드 12 이상만 가능)
            val relDir = when {
                relDirArg == null -> "Music/Paransori" // 일반 음악 자르기
                android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S -> relDirArg
                else -> "Podcasts/Paransori" // 안드로이드 11 이하: 녹음은 음악 목록에 안 섞이는 곳으로
            }
            val outName = (outBase ?: "${inputFile.nameWithoutExtension}_자름") + ".$outExt"
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, outName)
                put(MediaStore.MediaColumns.MIME_TYPE, if (isMp3) "audio/mpeg" else "audio/mp4")
                put(MediaStore.Audio.Media.IS_MUSIC, true)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "$relDir/")
            }
            val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values) ?: return null
            contentResolver.openOutputStream(uri)?.use { os -> tmp.inputStream().use { it.copyTo(os) } }
            tmp.delete()

            // 같은 이름이 있으면 안드로이드가 (1) 등을 붙이니까 실제 이름을 다시 확인
            var savedName = outName
            contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) savedName = c.getString(0) ?: savedName
            }
            val outPath = File(android.os.Environment.getExternalStorageDirectory(), "$relDir/$savedName").absolutePath
            android.media.MediaScannerConnection.scanFile(this, arrayOf(outPath), null, null)
            android.util.Log.d("Trim", "저장 완료: $outPath 크기=${File(outPath).length()}")
            outPath
        } catch (e: Exception) {
            android.util.Log.e("Trim", "Error: ${e.message}", e)
            null
        }
    }

    /// mp3: 길이 비율로 바이트를 잘라냄
    /// 맨 앞의 곡 정보(ID3)와 "전체 길이 정보(Xing/Info)" 칸은 빼고 소리 부분만 자름
    /// (그대로 두면 잘라도 원래 노래처럼 같은 제목·같은 길이로 보이는 문제가 있었음)
    private fun trimMp3Bytes(inputFile: File, out: File, startMs: Long, endMs: Long): Boolean {
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(inputFile.absolutePath)
        val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            ?.toLongOrNull() ?: 0L
        retriever.release()
        if (durationMs <= 0) return false

        // 잘라낸 파일에 새로 붙일 곡 정보 (제목 뒤에 "(자름)", 가수·앨범·앨범 사진은 그대로)
        val metaR = MediaMetadataRetriever()
        metaR.setDataSource(inputFile.absolutePath)
        val origTitle = metaR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
            ?.takeIf { it.isNotBlank() } ?: inputFile.nameWithoutExtension
        val origArtist = metaR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST) ?: ""
        val origAlbum = metaR.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM) ?: ""
        val origArt = metaR.embeddedPicture
        metaR.release()
        // 제목은 원래 그대로 (자른 곡은 앱에서 가위 아이콘으로 구분, 파일 이름에 _자름)
        val newTag = buildId3Tag(origTitle, origArtist, origAlbum, origArt)

        val totalBytes = inputFile.length()
        var audioStart = 0L
        java.io.RandomAccessFile(inputFile, "r").use { raf ->
            // 1) 맨 앞 곡 정보(ID3) 건너뛰기
            val head = ByteArray(10)
            raf.readFully(head)
            if (head[0] == 'I'.code.toByte() && head[1] == 'D'.code.toByte() && head[2] == '3'.code.toByte()) {
                val size = ((head[6].toInt() and 0x7F) shl 21) or ((head[7].toInt() and 0x7F) shl 14) or
                        ((head[8].toInt() and 0x7F) shl 7) or (head[9].toInt() and 0x7F)
                audioStart = 10L + size + (if ((head[5].toInt() and 0x10) != 0) 10 else 0)
            }
            // 2) 첫 소리 조각에 "전체 길이 정보"가 있으면 그 조각도 건너뛰기
            val probe = ByteArray(131072) // 곡 정보 뒤에 빈 공간이 긴 파일도 있어서 넉넉히 찾기
            raf.seek(audioStart)
            val n = raf.read(probe)
            var sync = -1
            for (i in 0 until maxOf(0, n - 3)) {
                if ((probe[i].toInt() and 0xFF) == 0xFF && (probe[i + 1].toInt() and 0xE0) == 0xE0) {
                    sync = i
                    break
                }
            }
            android.util.Log.d("Trim", "첫 소리 위치 sync=$sync")
            if (sync >= 0) {
                val text = String(probe, sync, minOf(200, n - sync), Charsets.ISO_8859_1)
                var skip = sync.toLong()
                if (text.contains("Xing") || text.contains("Info") || text.contains("VBRI")) {
                    val h1 = probe[sync + 1].toInt() and 0xFF
                    val h2 = probe[sync + 2].toInt() and 0xFF
                    val ver = (h1 shr 3) and 3 // 3=MPEG1, 2=MPEG2, 0=MPEG2.5
                    val brIdx = (h2 shr 4) and 0xF
                    val srIdx = (h2 shr 2) and 3
                    val pad = (h2 shr 1) and 1
                    val br1 = intArrayOf(0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0)
                    val br2 = intArrayOf(0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0)
                    val srTable = when (ver) {
                        3 -> intArrayOf(44100, 48000, 32000, 0)
                        2 -> intArrayOf(22050, 24000, 16000, 0)
                        else -> intArrayOf(11025, 12000, 8000, 0)
                    }
                    val sr = srTable[srIdx]
                    val br = (if (ver == 3) br1 else br2)[brIdx]
                    if (sr > 0 && br > 0) {
                        val frameLen = (if (ver == 3) 144000 else 72000) * br / sr + pad
                        skip += frameLen
                    }
                }
                audioStart += skip
            }
        }

        // 3) 소리 부분 안에서 길이 비율로 자르기
        val audioLen = totalBytes - audioStart
        if (audioLen <= 0) return false
        val startByte = audioStart + audioLen * startMs / durationMs
        val endByte = audioStart + audioLen * minOf(endMs, durationMs) / durationMs
        android.util.Log.d("Trim", "mp3 원래길이=$durationMs 파일크기=$totalBytes 소리시작=$audioStart 자를곳=$startByte~$endByte")
        inputFile.inputStream().use { input ->
            var toSkip = startByte
            while (toSkip > 0) {
                val s = input.skip(toSkip)
                if (s <= 0) break
                toSkip -= s
            }
            out.outputStream().use { output ->
                output.write(newTag) // 새 곡 정보 먼저
                val buffer = ByteArray(8192)
                var remaining = endByte - startByte
                while (remaining > 0) {
                    val read = input.read(buffer, 0, minOf(buffer.size.toLong(), remaining).toInt())
                    if (read < 0) break
                    output.write(buffer, 0, read)
                    remaining -= read
                }
            }
        }
        return out.length() > 0
    }

    /// 잘라낸 mp3 앞에 붙일 새 곡 정보(ID3v2.3): 제목·가수·앨범·앨범 사진 (길이 메모는 안 넣음)
    private fun buildId3Tag(title: String, artist: String, album: String, art: ByteArray?): ByteArray {
        val frames = java.io.ByteArrayOutputStream()
        fun frame(id: String, body: ByteArray) {
            frames.write(id.toByteArray(Charsets.ISO_8859_1))
            val n = body.size
            frames.write(byteArrayOf((n shr 24).toByte(), (n shr 16).toByte(), (n shr 8).toByte(), n.toByte()))
            frames.write(byteArrayOf(0, 0))
            frames.write(body)
        }
        fun text(id: String, value: String) {
            if (value.isEmpty()) return
            // 1 = UTF-16 (한글 안 깨지게)
            frame(id, byteArrayOf(1) + value.toByteArray(Charsets.UTF_16))
        }
        text("TIT2", title)
        text("TPE1", artist)
        text("TALB", album)
        if (art != null && art.isNotEmpty()) {
            val isPng = art.size > 4 && art[0] == 0x89.toByte() && art[1] == 0x50.toByte()
            val mime = if (isPng) "image/png" else "image/jpeg"
            val body = java.io.ByteArrayOutputStream()
            body.write(0)
            body.write(mime.toByteArray(Charsets.ISO_8859_1))
            body.write(0)
            body.write(3) // 앞표지
            body.write(0) // 설명 없음
            body.write(art)
            frame("APIC", body.toByteArray())
        }
        val data = frames.toByteArray()
        val size = data.size
        val header = byteArrayOf(
            'I'.code.toByte(), 'D'.code.toByte(), '3'.code.toByte(), 3, 0, 0,
            ((size shr 21) and 0x7F).toByte(), ((size shr 14) and 0x7F).toByte(),
            ((size shr 7) and 0x7F).toByte(), (size and 0x7F).toByte()
        )
        return header + data
    }

    /// m4a/aac: 다시 압축하지 않고 구간만 그대로 옮겨 담음 (음질 그대로)
    private fun trimWithMuxer(src: String, out: File, startMs: Long, endMs: Long): Boolean {
        val extractor = android.media.MediaExtractor()
        extractor.setDataSource(src)
        var track = -1
        for (i in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(i).getString(android.media.MediaFormat.KEY_MIME) ?: ""
            if (mime.startsWith("audio/")) { track = i; break }
        }
        if (track < 0) { extractor.release(); return false }
        extractor.selectTrack(track)
        val format = extractor.getTrackFormat(track)
        val muxer = android.media.MediaMuxer(out.absolutePath,
            android.media.MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val dst = muxer.addTrack(format)
        muxer.start()
        val maxSize = if (format.containsKey(android.media.MediaFormat.KEY_MAX_INPUT_SIZE))
            format.getInteger(android.media.MediaFormat.KEY_MAX_INPUT_SIZE) else 1024 * 1024
        val buffer = java.nio.ByteBuffer.allocate(maxSize)
        val info = android.media.MediaCodec.BufferInfo()
        val startUs = startMs * 1000
        val endUs = endMs * 1000
        extractor.seekTo(startUs, android.media.MediaExtractor.SEEK_TO_CLOSEST_SYNC)
        var wrote = false
        while (true) {
            info.offset = 0
            info.size = extractor.readSampleData(buffer, 0)
            if (info.size < 0) break
            val t = extractor.sampleTime
            if (t > endUs) break
            if (t >= startUs) {
                info.presentationTimeUs = t - startUs
                info.flags = extractor.sampleFlags
                muxer.writeSampleData(dst, buffer, info)
                wrote = true
            }
            extractor.advance()
        }
        muxer.stop()
        muxer.release()
        extractor.release()
        return wrote
    }

    private fun updateSongMetadata(path: String, title: String?, artist: String?, album: String?): Boolean {
        return try {
            val values = ContentValues().apply {
                if (title != null) put(MediaStore.Audio.Media.TITLE, title)
                if (artist != null) put(MediaStore.Audio.Media.ARTIST, artist)
                if (album != null) put(MediaStore.Audio.Media.ALBUM, album)
            }
            val updated = contentResolver.update(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                values,
                "${MediaStore.Audio.Media.DATA}=?",
                arrayOf(path)
            )
            updated > 0
        } catch (e: Exception) {
            android.util.Log.e("UpdateMetadata", "Error: ${e.message}", e)
            false
        }
    }

    private fun initEqualizer(audioSessionId: Int): Map<String, Any?> {
        return try {
            equalizer?.release()
            equalizer = Equalizer(0, audioSessionId)
            equalizer?.enabled = true
            val numBands = equalizer?.numberOfBands?.toInt() ?: 0
            val minLevel = equalizer?.bandLevelRange?.get(0) ?: 0
            val maxLevel = equalizer?.bandLevelRange?.get(1) ?: 0
            val bands = mutableListOf<Map<String, Any>>()
            for (i in 0 until numBands) {
                val freq = equalizer?.getCenterFreq(i.toShort()) ?: 0
                val level = equalizer?.getBandLevel(i.toShort()) ?: 0
                bands.add(mapOf("band" to i, "freq" to freq, "level" to level.toInt()))
            }
            val numPresets = equalizer?.numberOfPresets?.toInt() ?: 0
            val presets = mutableListOf<String>()
            for (i in 0 until numPresets) {
                presets.add(equalizer?.getPresetName(i.toShort()) ?: "")
            }
            mapOf("numBands" to numBands, "minLevel" to minLevel.toInt(),
                "maxLevel" to maxLevel.toInt(), "bands" to bands, "presets" to presets)
        } catch (e: Exception) {
            android.util.Log.e("Equalizer", "Error: ${e.message}", e)
            mapOf("numBands" to 0, "minLevel" to -1500, "maxLevel" to 1500,
                "bands" to emptyList<Map<String, Any>>(), "presets" to emptyList<String>())
        }
    }

    private fun getVideoList(): List<Map<String, Any?>> {
        val videos = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_TAKEN, // 찍은 날짜 (밀리초)
            MediaStore.Video.Media.DATE_ADDED  // 폰에 들어온 날짜 (초)
        )
        val cursor = contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            projection, null, null,
            MediaStore.Video.Media.DATE_ADDED + " DESC" // 최신 영상이 맨 위
        )
        cursor?.use {
            val nameColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            val takenColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_TAKEN)
            val addedColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
            while (it.moveToNext()) {
                val path = it.getString(dataColumn)
                val displayName = it.getString(nameColumn) ?: ""
                val titleWithoutExt = displayName.substringBeforeLast('.')
                videos.add(mapOf(
                    "title" to titleWithoutExt,
                    "duration" to it.getLong(durationColumn),
                    "uri" to path,
                    // 찍은 날짜 (없으면 폰에 들어온 날짜) — 밀리초
                    "date" to (it.getLong(takenColumn).takeIf { t -> t > 0 } ?: (it.getLong(addedColumn) * 1000))
                ))
            }
        }
        return videos
    }

    /// 동영상 잘라서 Movies/Paransori 에 새로 저장 (원본 그대로). 저장된 경로, 실패면 null
    private fun saveTrimmedVideo(path: String, startMs: Long, endMs: Long, outBase: String): String? {
        val tmp = File(cacheDir, "video_trim_tmp.mp4")
        return try {
            if (tmp.exists()) tmp.delete()
            if (!trimVideoWithMuxer(path, tmp, startMs, endMs)) return null
            saveToMediaStore(tmp, MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "Movies/Paransori", "$outBase.mp4", "video/mp4")
        } catch (e: Exception) {
            android.util.Log.e("TrimVideo", "Error: ${e.message}", e)
            null
        } finally {
            tmp.delete()
        }
    }

    /// 동영상 소리만 뽑아서 Music/Paransori 에 m4a로 저장. 저장된 경로, 실패면 null
    private fun saveVideoAudio(path: String, startMs: Long, endMs: Long, outBase: String): String? {
        val tmp = File(cacheDir, "video_audio_tmp.m4a")
        return try {
            if (tmp.exists()) tmp.delete()
            if (!trimWithMuxer(path, tmp, startMs, endMs)) return null // 노래 자르기와 같은 방식
            saveToMediaStore(tmp, MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, "Music/Paransori", "$outBase.m4a", "audio/mp4", music = true)
        } catch (e: Exception) {
            android.util.Log.e("VideoAudio", "Error: ${e.message}", e)
            null
        } finally {
            tmp.delete()
        }
    }

    /// 만든 파일을 폰 갤러리·음악 폴더에 넣기 (같은 이름이 있으면 폰이 (1) 등을 붙임 → 실제 경로 돌려줌)
    private fun saveToMediaStore(
        src: File, collection: android.net.Uri, relDir: String, name: String, mime: String, music: Boolean = false
    ): String? {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, "$relDir/")
            if (music) put(MediaStore.Audio.Media.IS_MUSIC, true)
        }
        val uri = contentResolver.insert(collection, values) ?: return null
        contentResolver.openOutputStream(uri)?.use { os -> src.inputStream().use { it.copyTo(os) } }
        var savedName = name
        contentResolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) savedName = c.getString(0) ?: savedName
        }
        val outPath = File(android.os.Environment.getExternalStorageDirectory(), "$relDir/$savedName").absolutePath
        android.media.MediaScannerConnection.scanFile(this, arrayOf(outPath), null, null)
        return outPath
    }

    /// 영상(화면+소리)을 다시 압축하지 않고 구간만 옮겨 담기 — 시작은 가장 가까운 앞 장면 경계부터
    private fun trimVideoWithMuxer(src: String, out: File, startMs: Long, endMs: Long): Boolean {
        val ex = android.media.MediaExtractor()
        var muxer: android.media.MediaMuxer? = null
        try {
            ex.setDataSource(src)
            val mx = android.media.MediaMuxer(out.absolutePath, android.media.MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            muxer = mx
            val dst = HashMap<Int, Int>()
            var maxSize = 1024 * 1024
            for (i in 0 until ex.trackCount) {
                val f = ex.getTrackFormat(i)
                val mime = f.getString(android.media.MediaFormat.KEY_MIME) ?: continue
                val isVideo = mime.startsWith("video/")
                if (!isVideo && !mime.startsWith("audio/")) continue
                ex.selectTrack(i)
                dst[i] = mx.addTrack(f)
                if (f.containsKey(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)) {
                    maxSize = maxOf(maxSize, f.getInteger(android.media.MediaFormat.KEY_MAX_INPUT_SIZE))
                }
                // 세로로 찍은 영상이 눕지 않게 방향 그대로
                if (isVideo && f.containsKey("rotation-degrees")) mx.setOrientationHint(f.getInteger("rotation-degrees"))
            }
            if (dst.isEmpty()) return false
            // 찍은 곳(위치 태그)도 그대로 옮기기
            readVideoLocation(src)?.let { (lat, lng) ->
                try { mx.setLocation(lat, lng) } catch (_: Exception) {}
            }
            mx.start()
            val startUs = startMs * 1000
            val endUs = endMs * 1000
            ex.seekTo(startUs, android.media.MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            val buf = java.nio.ByteBuffer.allocate(maxSize)
            val info = android.media.MediaCodec.BufferInfo()
            val ended = HashSet<Int>()
            var base = -1L
            var wrote = false
            while (true) {
                val track = ex.sampleTrackIndex
                if (track < 0) break
                info.offset = 0
                info.size = ex.readSampleData(buf, 0)
                if (info.size < 0) break
                val t = ex.sampleTime
                if (t > endUs) {
                    ended.add(track)
                    if (ended.size >= dst.size) break
                    ex.advance()
                    continue
                }
                if (base < 0) base = t
                if (t < base) {
                    ex.advance()
                    continue
                }
                info.presentationTimeUs = t - base
                info.flags = ex.sampleFlags
                mx.writeSampleData(dst[track]!!, buf, info)
                wrote = true
                ex.advance()
            }
            if (wrote) mx.stop()
            return wrote
        } catch (e: Exception) {
            android.util.Log.e("TrimVideo", "Error: ${e.message}", e)
            return false
        } finally {
            try { muxer?.release() } catch (_: Exception) {}
            ex.release()
        }
    }

    /// 영상 속 위치 태그 (위도, 경도) — 없으면 null
    private fun readVideoLocation(path: String): Pair<Float, Float>? {
        val r = MediaMetadataRetriever()
        try {
            var opened = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    contentResolver.query(
                        MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                        arrayOf(MediaStore.Video.Media._ID),
                        "${MediaStore.Video.Media.DATA}=?", arrayOf(path), null
                    )?.use {
                        if (it.moveToFirst()) {
                            val uri = MediaStore.setRequireOriginal(
                                android.net.Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, it.getLong(0).toString()))
                            r.setDataSource(this, uri)
                            opened = true
                        }
                    }
                } catch (_: Exception) {}
            }
            if (!opened) r.setDataSource(path)
            val loc = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_LOCATION) ?: return null
            val m = Regex("([+-]\\d+(?:\\.\\d+)?)([+-]\\d+(?:\\.\\d+)?)").find(loc) ?: return null
            return Pair(m.groupValues[1].toFloat(), m.groupValues[2].toFloat())
        } catch (_: Exception) {
            return null
        } finally {
            try { r.release() } catch (_: Exception) {}
        }
    }

    private fun getVideoThumbnail(path: String): ByteArray? {
        return try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(path)
            val bitmap = retriever.getFrameAtTime(1000000)
            retriever.release()
            if (bitmap != null) {
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
                stream.toByteArray()
            } else null
        } catch (e: Exception) { null }
    }

    /// 영상 속 위치 태그 → 주소 짧게 ("서울 중구"). 위치 없으면 null, 주소를 못 바꾸면 place 없이 좌표만
    private fun getVideoPlace(path: String): Map<String, Any?>? {
        val retriever = MediaMetadataRetriever()
        try {
            // 안드로이드 10 이상은 위치가 가려진 채로 읽혀서 '원본'으로 열기 (ACCESS_MEDIA_LOCATION)
            var opened = false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    contentResolver.query(
                        MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                        arrayOf(MediaStore.Video.Media._ID),
                        "${MediaStore.Video.Media.DATA}=?", arrayOf(path), null
                    )?.use {
                        if (it.moveToFirst()) {
                            val id = it.getLong(0)
                            val uri = MediaStore.setRequireOriginal(
                                android.net.Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString()))
                            retriever.setDataSource(this, uri)
                            opened = true
                        }
                    }
                } catch (_: Exception) {}
            }
            if (!opened) retriever.setDataSource(path)
            val loc = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_LOCATION)
            if (loc == null) return null
            val m = Regex("([+-]\\d+(?:\\.\\d+)?)([+-]\\d+(?:\\.\\d+)?)").find(loc) ?: return null
            val lat = m.groupValues[1].toDouble()
            val lng = m.groupValues[2].toDouble()
            if (lat == 0.0 && lng == 0.0) return null
            var place: String? = null
            try {
                if (android.location.Geocoder.isPresent()) {
                    @Suppress("DEPRECATION")
                    val all = android.location.Geocoder(this, java.util.Locale.getDefault())
                        .getFromLocation(lat, lng, 5) ?: emptyList()
                    val a = all.firstOrNull()
                    if (a != null) {
                        // 짧게: 서울특별시 → 서울, 경기도 → 경기
                        val short = mapOf(
                            "서울특별시" to "서울", "부산광역시" to "부산", "대구광역시" to "대구", "인천광역시" to "인천",
                            "광주광역시" to "광주", "대전광역시" to "대전", "울산광역시" to "울산", "세종특별자치시" to "세종",
                            "경기도" to "경기", "강원도" to "강원", "강원특별자치도" to "강원", "충청북도" to "충북",
                            "충청남도" to "충남", "전라북도" to "전북", "전북특별자치도" to "전북", "전라남도" to "전남",
                            "경상북도" to "경북", "경상남도" to "경남", "제주특별자치도" to "제주"
                        )
                        val parts = listOf(a.adminArea, a.subAdminArea, a.locality, a.subLocality)
                            .mapNotNull { it?.trim()?.takeIf { s -> s.isNotEmpty() } }
                            .map { short[it] ?: it }
                            .distinct()
                            .take(2)
                        // 동·읍·면까지 (예: 명동, 정자동, 기장읍) — 도로 이름(○○로)만 있는 주소면 구까지만
                        val dongRule = Regex("^[가-힣0-9.]+(동|읍|면|가|리)$")
                        // 첫 주소가 도로명이면 동이 없어서, 다른 후보 주소들에서도 찾기
                        val candidates = all.flatMap { x ->
                            listOfNotNull(x.subLocality, x.thoroughfare, x.featureName) +
                                (x.getAddressLine(0) ?: "").split(" ")
                        }
                        val dong = candidates.map { it.trim() }
                            .firstOrNull { it.isNotEmpty() && dongRule.matches(it) && it !in parts }
                        val base = if (parts.isNotEmpty()) parts else listOfNotNull(a.countryName)
                        place = (base + listOfNotNull(dong)).joinToString(" ").ifBlank { null }
                    }
                }
            } catch (_: Exception) {}
            return mapOf("lat" to lat, "lng" to lng, "place" to place)
        } catch (e: Exception) {
            return null
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
    }

    private fun doRenameVideo(videoUri: android.net.Uri, newName: String): Boolean {
        return try {
            var extension = "mp4"
            val cursor = contentResolver.query(
                videoUri, arrayOf(MediaStore.Video.Media.DISPLAY_NAME), null, null, null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val oldDisplayName = it.getString(0) ?: ""
                    val dotIndex = oldDisplayName.lastIndexOf('.')
                    if (dotIndex != -1) {
                        extension = oldDisplayName.substring(dotIndex + 1)
                    }
                }
            }
            val newDisplayName = if (newName.contains('.')) newName else "$newName.$extension"
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.TITLE, newName)
                put(MediaStore.Video.Media.DISPLAY_NAME, newDisplayName)
            }
            val updated = contentResolver.update(videoUri, values, null, null)
            contentResolver.notifyChange(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, null)
            updated > 0
        } catch (e: Exception) {
            android.util.Log.e("RenameVideo", "Error: ${e.message}", e)
            false
        }
    }

    private fun renameVideo(path: String, newName: String, result: MethodChannel.Result) {
        android.util.Log.d("RenameVideo", "renameVideo 호출됨, path=$path, newName=$newName")
        try {
            val cursor = contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Video.Media._ID),
                "${MediaStore.Video.Media.DATA}=?",
                arrayOf(path), null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.Video.Media._ID))
                    val videoUri = android.net.Uri.withAppendedPath(
                        MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString()
                    )
                    android.util.Log.d("RenameVideo", "videoUri 찾음: $videoUri")
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        renameResult = result
                        pendingRenameUri = videoUri
                        pendingRenameName = newName
                        val pendingIntent = MediaStore.createWriteRequest(
                            contentResolver, listOf(videoUri)
                        )
                        android.util.Log.d("RenameVideo", "권한 요청 시작")
                        startIntentSenderForResult(
                            pendingIntent.intentSender, 103, null, 0, 0, 0
                        )
                    } else {
                        result.success(doRenameVideo(videoUri, newName))
                    }
                } else {
                    android.util.Log.d("RenameVideo", "DB에서 영상을 못 찾음")
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("RenameVideo", "Error: ${e.message}", e)
            result.success(false)
        }
    }
}


/// 이어폰·블루투스 연결 알아채기 (앱이 켜져 있거나 뒤에 있을 때)
/// 소리 나가는 곳이 이어폰·블루투스로 바뀌는 것만 봐서 새 권한이 필요 없음
object HeadsetWatch {
    private var channel: MethodChannel? = null
    private var registered = false
    private var startedAt = 0L
    private var lastAt = 0L

    private fun isHeadset(t: Int): Boolean = when (t) {
        AudioDeviceInfo.TYPE_WIRED_HEADSET,
        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_USB_HEADSET -> true
        else -> Build.VERSION.SDK_INT >= 31 &&
            (t == AudioDeviceInfo.TYPE_BLE_HEADSET || t == AudioDeviceInfo.TYPE_BLE_SPEAKER)
    }

    private val callback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(added: Array<out AudioDeviceInfo>?) {
            val now = System.currentTimeMillis()
            if (now - startedAt < 2500) return // 처음 등록할 때 이미 연결돼 있던 건 무시
            if (added == null || added.none { it.isSink && isHeadset(it.type) }) return
            if (now - lastAt < 4000) return // 블루투스는 신호가 여러 번 와서 한 번만
            lastAt = now
            channel?.invokeMethod("onHeadsetConnected", null)
        }
    }

    fun start(ctx: android.content.Context, ch: MethodChannel) {
        channel = ch
        if (registered) return
        registered = true
        startedAt = System.currentTimeMillis()
        val am = ctx.applicationContext.getSystemService(android.content.Context.AUDIO_SERVICE) as AudioManager
        am.registerAudioDeviceCallback(callback, android.os.Handler(android.os.Looper.getMainLooper()))
    }
}
