package com.pypecrm.call_recording_engine.data

import android.content.Context
import android.util.Log
import java.io.File

/**
 * Keeps a recording whose real-time upload failed in app-private storage
 * (not cacheDir, which the OS may clear under storage pressure) until
 * CallSyncRunner can retry it.
 */
object PendingRecordingStore {
    private const val TAG = "PendingRecordingStore"
    private const val DIR = "pending_recordings"

    /** Moves [source] into the pending directory; returns the new path, or
     * null if it couldn't be kept (the call then syncs metadata-only). */
    fun keep(context: Context, source: File, hardwareId: String?): String? {
        return try {
            val dir = File(context.filesDir, DIR).apply { mkdirs() }
            val ext = source.extension.ifEmpty { "m4a" }
            val target = File(dir, "call_${hardwareId ?: System.currentTimeMillis()}_${System.currentTimeMillis()}.$ext")
            if (!source.renameTo(target)) {
                source.copyTo(target, overwrite = true)
                source.delete()
            }
            target.absolutePath
        } catch (e: Exception) {
            Log.w(TAG, "Couldn't keep recording for retry", e)
            null
        }
    }

    fun delete(path: String?) {
        if (path.isNullOrEmpty()) return
        runCatching { File(path).delete() }
    }
}
