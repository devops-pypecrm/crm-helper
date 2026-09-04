package com.pypecrm.call_recording_engine.data

import android.content.Context

/**
 * Watermark for [com.pypecrm.call_recording_engine.sync.CallLogReconciler] —
 * "the system CallLog has already been scanned up to this point in time."
 *
 * Deliberately starts at "midnight today" rather than 0/epoch: the very
 * first reconciliation run (whenever it happens to fire — could be right
 * after this feature ships to an existing install, could be a brand new
 * install) naturally backfills the whole current day's calls, including
 * anything the real-time capture path missed earlier today, without any
 * separate "was the app just updated" detection needed. Every run after
 * that just advances forward from wherever the last one left off.
 */
class CallLogReconcilePrefs(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var lastReconciledAtMillis: Long
        get() {
            val stored = prefs.getLong(KEY_LAST_RECONCILED, -1L)
            return if (stored >= 0L) stored else startOfTodayMillis()
        }
        set(value) = prefs.edit().putLong(KEY_LAST_RECONCILED, value).apply()

    private fun startOfTodayMillis(): Long {
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    companion object {
        private const val PREFS_NAME = "call_recording_engine_reconcile"
        private const val KEY_LAST_RECONCILED = "last_reconciled_at_millis"
    }
}
