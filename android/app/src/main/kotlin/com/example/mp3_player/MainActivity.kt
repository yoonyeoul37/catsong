package kr.ssing.catsong

import android.content.ContentValues
import android.graphics.Bitmap
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
        }
    }

    override fun onResume() {
        super.onResume()
        requestAudioFocus()
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
                "updateWidget" -> {
                    val title = call.argument<String>("title") ?: "캣송"
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
            val albumArt = retriever.embeddedPicture
            retriever.release()
            mapOf("title" to title, "artist" to artist, "album" to album,
                "duration" to duration?.toLongOrNull(), "albumArt" to albumArt)
        } catch (e: Exception) {
            retriever.release()
            mapOf("title" to null, "artist" to null, "album" to null,
                "duration" to null, "albumArt" to null)
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