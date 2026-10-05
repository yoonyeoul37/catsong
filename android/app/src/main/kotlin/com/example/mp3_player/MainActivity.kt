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
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "kr.ssing.catsong/media"
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
    private var virtualizer: android.media.audiofx.Virtualizer? = null
    private var deleteResult: MethodChannel.Result? = null
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        flutterMethodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlbumArt" -> {
                    val path = call.argument<String>("path")
                    if (path != null) result.success(getAlbumArt(path))
                    else result.success(null)
                }
                "getSongMetadata" -> {
                    val path = call.argument<String>("path")
                    if (path != null) result.success(getSongMetadata(path))
                    else result.success(null)
                }
                "trimAndSetRingtone" -> {
                    val path = call.argument<String>("path")
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: 0L
                    if (path != null) result.success(trimAndSetRingtone(path, startMs, endMs))
                    else result.success(false)
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
                "saveRecording" -> {
                    // 파란소리에서 녹음한 파일을 Recordings/Paransori 폴더에 저장
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name") ?: "녹음"
                    if (path == null) {
                        result.success(null)
                    } else {
                        try {
                            val src = File(path)
                            val relDir = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S)
                                "Recordings/Paransori" else "Music/Paransori"
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
                            result.success(null)
                        }
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
                "getVideoList" -> {
                    val list = getVideoList()
                    android.util.Log.d("RenameVideo", "getVideoList 결과: $list")
                    result.success(list)
                }
                "getVideoThumbnail" -> {
                    val path = call.argument<String>("path")
                    if (path != null) result.success(getVideoThumbnail(path))
                    else result.success(null)
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
                                result.success(false)
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
                            result.success(false)
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

    private fun trimAndSetRingtone(path: String, startMs: Long, endMs: Long): Boolean {
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
            val relDir = if (relDirArg != null &&
                android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) relDirArg else "Music/Paransori"
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
            MediaStore.Video.Media.DATA
        )
        val cursor = contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            projection, null, null,
            MediaStore.Video.Media.DISPLAY_NAME + " ASC"
        )
        cursor?.use {
            val nameColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            while (it.moveToNext()) {
                val path = it.getString(dataColumn)
                val displayName = it.getString(nameColumn) ?: ""
                val titleWithoutExt = displayName.substringBeforeLast('.')
                videos.add(mapOf(
                    "title" to titleWithoutExt,
                    "duration" to it.getLong(durationColumn),
                    "uri" to path
                ))
            }
        }
        return videos
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