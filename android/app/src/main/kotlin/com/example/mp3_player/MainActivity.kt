package com.example.mp3_player

import android.content.ContentValues
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.media.audiofx.Equalizer
import android.provider.MediaStore
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.mp3_player/media"
    private var equalizer: Equalizer? = null
    private var deleteResult: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 101) {
            if (resultCode == android.app.Activity.RESULT_OK) {
                deleteResult?.success(true)
            } else {
                deleteResult?.success(false)
            }
            deleteResult = null
        }
    }



    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                "getVideoList" -> {
                    result.success(getVideoList())
                }
                "getVideoThumbnail" -> {
                    val path = call.argument<String>("path")
                    if (path != null) result.success(getVideoThumbnail(path))
                    else result.success(null)
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
                "widgetPlayPause" -> {
                    result.success(true)
                }
                "widgetNext" -> {
                    result.success(true)
                }
                "widgetPrev" -> {
                    result.success(true)
                }
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
                    val title = call.argument<String>("title") ?: "플레이쏭"
                    val artist = call.argument<String>("artist") ?: "음악을 재생해보세요"
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(this)
                    val ids = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(this, PlayerWidget::class.java)
                    )
                    for (id in ids) {
                        PlayerWidget.updateAppWidget(this, appWidgetManager, id, title, artist, isPlaying)
                    }
                    val ids2 = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(this, PlayerWidget2::class.java)
                    )
                    for (id in ids2) {
                        PlayerWidget2.updateAppWidget(this, appWidgetManager, id, title, artist, isPlaying)
                    }
                    val ids3 = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(this, PlayerWidget3::class.java)
                    )
                    for (id in ids3) {
                        PlayerWidget3.updateAppWidget(this, appWidgetManager, id, title, artist, isPlaying)
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
            MediaStore.Video.Media.TITLE,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.DATA
        )
        val cursor = contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            projection, null, null,
            MediaStore.Video.Media.TITLE + " ASC"
        )
        cursor?.use {
            val titleColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.TITLE)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            while (it.moveToNext()) {
                val path = it.getString(dataColumn)
                videos.add(mapOf(
                    "title" to it.getString(titleColumn),
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
}