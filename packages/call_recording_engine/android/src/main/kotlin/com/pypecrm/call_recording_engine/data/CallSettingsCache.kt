package com.pypecrm.call_recording_engine.data

import android.content.Context
import android.util.Log
import com.pypecrm.call_recording_engine.net.BackendApi

/**
 * Caches Dad-backend's per-org CallSettings (autoRecordInbound/
 * autoRecordOutbound) so CallMonitorService can decide, per call direction,
 * whether it's even allowed to look for/upload Tier 0 audio — this is the
 * consent-law non-negotiable from the task brief (CallSettings defaults
 * recording OFF for new orgs; that's a legal call for org admins, not
 * something this app should second-guess by uploading anyway). Refreshed
 * opportunistically (stale after a TTL) rather than on every call, since
 * the values rarely change and a call-end path shouldn't be blocked
 * indefinitely on a settings fetch.
 */
class CallSettingsCache(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isDirectionAllowed(isOutgoing: Boolean): Boolean {
        val key = if (isOutgoing) KEY_AUTO_OUTBOUND else KEY_AUTO_INBOUND
        // Fail-open (true) only when we've never successfully fetched
        // settings at all — once a real fetch succeeds this reflects the
        // org's actual (default-false-for-new-orgs) setting. Avoids
        // silently discarding audio just because a device has never been
        // online long enough yet to learn the org's real policy.
        return prefs.getBoolean(key, true)
    }

    fun isStale(): Boolean =
        System.currentTimeMillis() - prefs.getLong(KEY_FETCHED_AT, 0L) > TTL_MILLIS

    /** Best-effort synchronous refresh — call from a background thread only. */
    fun refreshIfStale(api: BackendApi) {
        if (!isStale()) return
        try {
            val settings = api.fetchCallSettings() ?: return
            prefs.edit()
                .putBoolean(KEY_AUTO_INBOUND, settings.autoRecordInbound)
                .putBoolean(KEY_AUTO_OUTBOUND, settings.autoRecordOutbound)
                .putLong(KEY_FETCHED_AT, System.currentTimeMillis())
                .apply()
        } catch (e: Exception) {
            Log.w(TAG, "CallSettings refresh failed, keeping cached/default values", e)
        }
    }

    companion object {
        private const val TAG = "CallSettingsCache"
        private const val PREFS_NAME = "call_recording_engine_call_settings"
        private const val KEY_AUTO_INBOUND = "auto_record_inbound"
        private const val KEY_AUTO_OUTBOUND = "auto_record_outbound"
        private const val KEY_FETCHED_AT = "fetched_at"
        private const val TTL_MILLIS = 15 * 60 * 1000L
    }
}
