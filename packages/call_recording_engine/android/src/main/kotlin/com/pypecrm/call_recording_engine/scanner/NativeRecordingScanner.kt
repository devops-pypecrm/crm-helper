package com.pypecrm.call_recording_engine.scanner

import android.content.ContentUris
import android.content.Context
import android.provider.MediaStore
import android.util.Log
import android.webkit.MimeTypeMap
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.util.PhoneNumberUtils
import java.io.File

/**
 * Tier 0: looks for a file the OEM's own call-recorder already wrote to
 * MediaStore — the highest-quality source when available (a real
 * privileged-app capture, not an acoustic workaround), and since
 * [SamsungAutoRecordAutomation] now tries to switch that OEM recorder on
 * programmatically, this is also the tier responsible for actually
 * retrieving whatever it then produces. Adapted from Dad-frontend's
 * NativeRecordingScanner.kt with the fixes found while hardening it for
 * Phase 1 (see Dad-mobile/CALL_RECORDING_PLAN.md), plus one more:
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
 *  3. Number-suffix matching is a preference, not a hard requirement — some
 *     OEMs (observed in Samsung's own documentation of its recording
 *     filename format across regions) name the file from a timestamp only,
 *     with no caller number in it at all. When no candidate's filename
 *     contains the expected number, [scanOnce] falls back to the single
 *     newest audio file inside [WINDOW_AFTER_MS] of call-end — deliberately
 *     NOT the same wide ±5min window the number-matched path tolerates,
 *     since without a number to cross-check, a wide window risks grabbing
 *     an unrelated recording (see the false-"failed"-status bug this
 *     project already hit once from under-verified CallLog matching).
 */
object NativeRecordingScanner {

    private const val TAG = "NativeRecordingScanner"

    // Narrower than the old code's ±5min: the caller now polls every ~2s
    // starting right at call-end, so a wide symmetric window only risks
    // matching an unrelated older recording. The file should appear at or
    // shortly after call end, essentially never meaningfully before it.
    private const val WINDOW_BEFORE_MS = 60_000L
    private const val WINDOW_AFTER_MS = 5 * 60_000L
    // Tighter window for the no-number-match fallback — see class doc
    // comment point 3. A false match here is worse than no match, since it
    // would silently upload the wrong call's audio.
    private const val FALLBACK_WINDOW_MS = 30_000L
    private const val MIN_FILE_SIZE_BYTES = 1024L

    fun scanOnce(context: Context, phoneNumber: String, callEndMillis: Long): File? {
        val debugLog = EngineDebugLog(context)
        val suffix = PhoneNumberUtils.last10Digits(phoneNumber)
        val numberMatch = if (suffix.length >= 10) queryMatching(context, suffix, callEndMillis) else null
        if (numberMatch != null) {
            debugLog.append("TIER0_MATCH_FOUND", "by number suffix: ${numberMatch.absolutePath}")
            return numberMatch
        }

        val fallbackMatch = queryNewestWithinWindow(context, callEndMillis)
        if (fallbackMatch != null) {
            debugLog.append("TIER0_MATCH_FOUND", "by nearest-timestamp fallback (no number match): ${fallbackMatch.absolutePath}")
            return fallbackMatch
        }

        debugLog.append("TIER0_NO_MATCH", "suffix=$suffix callEndMillis=$callEndMillis")
        return null
    }

    private fun queryMatching(context: Context, suffix: String, callEndMillis: Long): File? {
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

                    val copied = copyToCache(context, uri, id, name, mimeType)
                    if (copied != null) {
                        Log.d(TAG, "Tier 0 match: $name -> ${copied.absolutePath}")
                        return copied
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "MediaStore query failed", e)
        }
        return null
    }

    /** No candidate filename contained the expected number — fall back to
     * the single newest audio file within a tight window of call-end. Only
     * returns a match when exactly one file falls in that window, since a
     * tie between two candidates means this heuristic can't tell them
     * apart and a wrong guess is worse than no recording at all. */
    private fun queryNewestWithinWindow(context: Context, callEndMillis: Long): File? {
        val resolver = context.contentResolver
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.MIME_TYPE,
        )
        val sortOrder = "${MediaStore.Audio.Media.DATE_MODIFIED} DESC"

        data class Candidate(val id: Long, val name: String, val mimeType: String?)
        val candidates = mutableListOf<Candidate>()

        try {
            resolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
                val dateCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
                val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
                val mimeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)

                while (cursor.moveToNext() && candidates.size <= 1) {
                    val lastModifiedMillis = cursor.getLong(dateCol) * 1000
                    val delta = lastModifiedMillis - callEndMillis
                    // Results are DATE_MODIFIED DESC, so once we're past
                    // the window on the "too old" side nothing later helps.
                    if (delta < -FALLBACK_WINDOW_MS) break
                    if (delta > FALLBACK_WINDOW_MS) continue
                    val size = cursor.getLong(sizeCol)
                    if (size in 0 until MIN_FILE_SIZE_BYTES) continue
                    candidates.add(Candidate(cursor.getLong(idCol), cursor.getString(nameCol) ?: "", cursor.getString(mimeCol)))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "MediaStore fallback query failed", e)
            return null
        }

        if (candidates.size != 1) return null
        val candidate = candidates.first()
        return copyToCache(context, uri, candidate.id, candidate.name, candidate.mimeType)
    }

    private fun copyToCache(context: Context, uri: android.net.Uri, id: Long, name: String, mimeType: String?): File? {
        val contentUri = ContentUris.withAppendedId(uri, id)
        val extension = extensionFor(mimeType, name)
        val cacheFile = File(context.cacheDir, "tier0_call_$id.$extension")
        val copied = context.contentResolver.openInputStream(contentUri)?.use { input ->
            cacheFile.outputStream().use { output -> input.copyTo(output) }
            true
        } ?: false
        return if (copied && cacheFile.exists() && cacheFile.length() >= MIN_FILE_SIZE_BYTES) cacheFile else null
    }

    private fun extensionFor(mimeType: String?, displayName: String): String {
        val fromMime = mimeType?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
        if (!fromMime.isNullOrEmpty()) return fromMime
        val fromName = displayName.substringAfterLast('.', missingDelimiterValue = "")
        return fromName.ifEmpty { "m4a" }
    }
}
