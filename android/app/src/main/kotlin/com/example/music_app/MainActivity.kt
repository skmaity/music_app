package com.shubha.music

import android.content.ContentUris
import android.media.MediaMetadataRetriever
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity, not FlutterActivity. It is a FlutterActivity subclass
// that keeps the Flutter engine attached while the media session is running, so
// tapping the notification card returns to the existing app instance.
class MainActivity : AudioServiceActivity() {
    private val channelName = "com.nyro.app/local_media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "sdkVersion" -> result.success(Build.VERSION.SDK_INT)
                    "queryAudio" -> result.success(queryAudio())
                    "loadArtwork" -> {
                        val uri = call.argument<String>("uri")
                        result.success(uri?.let(::loadArtwork))
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("local_media", error.message, null)
            }
        }
    }

    private fun queryAudio(): List<Map<String, Any?>> {
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION
        )
        val rows = mutableListOf<Map<String, Any?>>()
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        contentResolver.query(
            collection,
            projection,
            selection,
            null,
            "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                rows.add(
                    mapOf(
                        "contentUri" to ContentUris.withAppendedId(collection, id).toString(),
                        "title" to cursor.getString(titleColumn),
                        "artist" to cursor.getString(artistColumn),
                        "albumId" to cursor.getLong(albumIdColumn).toString(),
                        "album" to cursor.getString(albumColumn),
                        "durationMs" to cursor.getLong(durationColumn)
                    )
                )
            }
        }
        return rows
    }

    private fun loadArtwork(uriString: String): ByteArray? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(this, android.net.Uri.parse(uriString))
            retriever.embeddedPicture
        } finally {
            retriever.release()
        }
    }
}
