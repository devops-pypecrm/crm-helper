package com.pypecrm.call_recording_engine.data

import android.app.Activity
import android.content.Intent

/**
 * Tier 3 needs a MediaProjection consent token, obtainable only from a
 * foreground Activity (`MediaProjectionManager.createScreenCaptureIntent()`
 * via `CallRecordingEnginePlugin.requestMediaProjectionPermission`). Held
 * in memory only — same limitation as Dad-frontend's old blueprint: the
 * token becomes invalid once this process dies, so an app that's been
 * background-killed needs the user to reopen it and re-grant before
 * Tier 3 works again. That's an inherent MediaProjection constraint, not
 * something this store can work around, and part of why the plan ranks
 * this tier last/lowest-priority.
 */
object MediaProjectionTokenStore {
    @Volatile private var resultCode: Int = Activity.RESULT_CANCELED
    @Volatile private var resultData: Intent? = null

    fun store(resultCode: Int, resultData: Intent?) {
        this.resultCode = resultCode
        this.resultData = resultData
    }

    fun hasToken(): Boolean = resultData != null && resultCode == Activity.RESULT_OK

    /** Reused across every call for the lifetime of this process — same
     * pattern as the reference implementation, which re-derives a fresh
     * MediaProjection instance from the same stored grant Intent per call
     * rather than re-prompting the user every time. */
    fun current(): Pair<Int, Intent>? {
        val data = resultData ?: return null
        if (resultCode != Activity.RESULT_OK) return null
        return resultCode to data
    }

    fun clear() {
        resultCode = Activity.RESULT_CANCELED
        resultData = null
    }
}
