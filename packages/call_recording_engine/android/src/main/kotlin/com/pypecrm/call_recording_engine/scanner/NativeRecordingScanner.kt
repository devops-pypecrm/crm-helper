package com.pypecrm.call_recording_engine.scanner

import android.content.ContentUris
import android.content.Context
import android.provider.MediaStore
import android.util.Log
import android.webkit.MimeTypeMap
import com.pypecrm.call_recording_engine.util.PhoneNumberUtils
import java.io.File

/**
 * Tier 0: looks for a file the OEM's own call-recorder already wrote to
 * MediaStore. Adapted from Dad-frontend's NativeRecordingScanner.kt with
 * two fixes found while hardening it for Phase 1 (see
 * Dad-mobile/CALL_RECORDING_PLAN.md):
 *
 *  1. This is a SINGLE query attempt — CallMonitorService is responsible
 *     for calling [scanOnce] repeatedly (~2s apart, ~15-20s total) after
 *     call end, since several OEMs finalize the file a few seconds late.
 *     The old code queried exactly once, at call-end, and silently missed
 *     those.
 *  2. The matched file is copied to cache preserving its REAL extension
 *     (via MediaStore's MIME_TYPE column, falling back to the source
 *     filename's own extension) instead of the old code's hardcoded
 *     `.mp3`, which corrupted playback for OEMs recording `.amr`/`.wav`/etc.
 */
object NativeRecordingScanner {

    private const val TAG = "NativeRecordingScanner"

    // Narrower than the old code's ±5min: the caller now polls every ~2s
    // starting right at call-end, so a wide symmetric window only risks
    // matching an unrelated older recording. The file should appear at or
    // shortly after call end, essentially never meaningfully before it.
    private const val WINDOW_BEFORE_MS = 60_000L
    private const val WINDOW_AFTER_MS = 5 * 60_000L
    private const val MIN_FILE_SIZE_BYTES = 1024L

    fun scanOnce(context: Context, phoneNumber: String, callEndMillis: Long): File? {
        val suffix = PhoneNumberUtils.last10Digits(phoneNumber)
        if (suffix.length < 10) return null

        val resolver = context.contentResolver
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.MIME_TYPE,
        )
        val selection = "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE ?"
        val selectionArgs = arrayOf("%$suffix%")
        val sortOrder = "${MediaStore.Audio.Media.DATE_MODIFIED} DESC"

        try {
            resolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
                val dateCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
                val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
                val mimeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idCol)
                    val name = cursor.getString(nameCol) ?: ""
                    val lastModifiedMillis = cursor.getLong(dateCol) * 1000
                    val size = cursor.getLong(sizeCol)
                    val mimeType = cursor.getString(mimeCol)

                    val delta = lastModifiedMillis - callEndMillis
                    if (delta < -WINDOW_BEFORE_MS || delta > WINDOW_AFTER_MS) continue
                    if (size in 0 until MIN_FILE_SIZE_BYTES) {
                        Log.d(TAG, "Skipping suspiciously small MediaStore match: $name ($size bytes)")
                        continue
                    }

                    val contentUri = ContentUris.withAppendedId(uri, id)
                    val extension = extensionFor(mimeType, name)
                    val cacheFile = File(context.cacheDir, "tier0_call_$id.$extension")
                    val copied = resolver.openInputStream(contentUri)?.use { input ->
                        cacheFile.outputStream().use { output -> input.copyTo(output) }
                        true
                    } ?: false

                    if (copied && cacheFile.exists() && cacheFile.length() >= MIN_FILE_SIZE_BYTES) {
                        Log.d(TAG, "Tier 0 match: $name -> ${cacheFile.absolutePath}")
                        return cacheFile
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "MediaStore query failed", e)
        }
        return null
    }

    private fun extensionFor(mimeType: String?, displayName: String): String {
        val fromMime = mimeType?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
        if (!fromMime.isNullOrEmpty()) return fromMime
        val fromName = displayName.substringAfterLast('.', missingDelimiterValue = "")
        return fromName.ifEmpty { "m4a" }
    }
}
