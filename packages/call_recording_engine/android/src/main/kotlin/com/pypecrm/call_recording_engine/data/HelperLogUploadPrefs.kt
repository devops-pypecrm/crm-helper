package com.pypecrm.call_recording_engine.data

import android.content.Context

/**
 * Watermark for [com.pypecrm.call_recording_engine.sync.HelperLogUploader] —
 * "EngineDebugLog entries up to this timestamp have already been sent to
 * the backend." Starts at 0 so the very first upload after this feature
 * ships sends whatever's already sitting in the local ring buffer.
 */
class HelperLogUploadPrefs(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var lastUploadedAtMillis: Long
        get() = prefs.getLong(KEY_LAST_UPLOADED, 0L)
        set(value) = prefs.edit().putLong(KEY_LAST_UPLOADED, value).apply()

    companion object {
        private const val PREFS_NAME = "call_recording_engine_helper_log_upload"
        private const val KEY_LAST_UPLOADED = "last_uploaded_at_millis"
    }
}
