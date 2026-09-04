package com.pypecrm.call_recording_engine.sync

import android.content.Context
import android.util.Log
import com.pypecrm.call_recording_engine.data.HelperLogUploadPrefs
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.net.HelperLogUploadResult

/**
 * Drains [EngineDebugLog] (everything since the last upload's watermark)
 * to `POST /api/android/helper-logs` — the feed behind the super-admin
 * "Helper Logs" panel in Dad-frontend. Runs from [CallSyncWorker], so it
 * rides the same cadence real call activity already triggers: immediately
 * after a call ends ([CallSyncWorker.scheduleNow]) and on the 15-minute
 * periodic safety net — no separate WorkManager schedule needed, and no
 * new permission (this is purely an upload of what's already being logged
 * locally, not a new data source).
 */
object HelperLogUploader {
    private const val TAG = "HelperLogUploader"

    fun upload(context: Context, authPrefs: NativeAuthPrefs) {
        val prefs = HelperLogUploadPrefs(context)
        val debugLog = EngineDebugLog(context)
        val pending = debugLog.readSince(prefs.lastUploadedAtMillis)
        if (pending.isEmpty()) return

        val api = BackendApi(authPrefs)
        when (val result = api.uploadHelperLogs(pending)) {
            is HelperLogUploadResult.Success -> {
                val newestMillis = pending.maxOf { (it["timestampMillis"] as? Long) ?: 0L }
                prefs.lastUploadedAtMillis = newestMillis
                Log.d(TAG, "Uploaded ${result.stored} helper log entries")
            }
            HelperLogUploadResult.Failed -> {
                // Watermark stays put — the same entries are retried on the
                // next CallSyncWorker run. EngineDebugLog's own 200-entry
                // cap means a very long outage could drop the oldest
                // unsent entries locally before they ever upload, but
                // that's an acceptable tradeoff for a diagnostics feed.
                Log.w(TAG, "Helper log upload failed, will retry next sync")
            }
        }
    }
}
