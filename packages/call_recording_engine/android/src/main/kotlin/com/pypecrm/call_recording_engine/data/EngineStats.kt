package com.pypecrm.call_recording_engine.data

import android.content.Context

/**
 * Small SharedPreferences-backed flags/counters read by the status screen
 * (via CallRecordingEnginePlugin.getStatus) and by CallStateReceiver to
 * decide whether to react to a call at all. Deliberately not a database —
 * these are a handful of scalars, not queryable rows (contrast
 * [CallEventDbHelper], which genuinely needs to be a table).
 */
class EngineStats(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var monitoringEnabled: Boolean
        get() = prefs.getBoolean(KEY_MONITORING_ENABLED, false)
        set(value) = prefs.edit().putBoolean(KEY_MONITORING_ENABLED, value).apply()

    var lastSyncedAtMillis: Long
        get() = prefs.getLong(KEY_LAST_SYNCED_AT, 0L)
        set(value) = prefs.edit().putLong(KEY_LAST_SYNCED_AT, value).apply()

    var tier0SuccessCount: Int
        get() = prefs.getInt(KEY_TIER0_SUCCESS, 0)
        set(value) = prefs.edit().putInt(KEY_TIER0_SUCCESS, value).apply()

    var tier1SuccessCount: Int
        get() = prefs.getInt(KEY_TIER1_SUCCESS, 0)
        set(value) = prefs.edit().putInt(KEY_TIER1_SUCCESS, value).apply()

    var tier2SuccessCount: Int
        get() = prefs.getInt(KEY_TIER2_SUCCESS, 0)
        set(value) = prefs.edit().putInt(KEY_TIER2_SUCCESS, value).apply()

    var tier3SuccessCount: Int
        get() = prefs.getInt(KEY_TIER3_SUCCESS, 0)
        set(value) = prefs.edit().putInt(KEY_TIER3_SUCCESS, value).apply()

    var tier4SuccessCount: Int
        get() = prefs.getInt(KEY_TIER4_SUCCESS, 0)
        set(value) = prefs.edit().putInt(KEY_TIER4_SUCCESS, value).apply()

    /** Client-side mirror of the server's 1-req/user/10min bulk-sync rate
     * limit (Dad-backend's androidRoutes.ts) — lets CallSyncWorker skip a
     * call it already knows will 429 instead of burning a WorkManager run. */
    var nextBulkSyncAllowedAtMillis: Long
        get() = prefs.getLong(KEY_NEXT_BULK_SYNC, 0L)
        set(value) = prefs.edit().putLong(KEY_NEXT_BULK_SYNC, value).apply()

    fun recordTier0Success(atMillis: Long) {
        tier0SuccessCount += 1
        lastSyncedAtMillis = atMillis
    }

    fun recordTier1Success(atMillis: Long) {
        tier1SuccessCount += 1
        lastSyncedAtMillis = atMillis
    }

    fun recordTier2Success(atMillis: Long) {
        tier2SuccessCount += 1
        lastSyncedAtMillis = atMillis
    }

    fun recordTier3Success(atMillis: Long) {
        tier3SuccessCount += 1
        lastSyncedAtMillis = atMillis
    }

    fun recordTier4Success(atMillis: Long, count: Int) {
        if (count <= 0) return
        tier4SuccessCount += count
        lastSyncedAtMillis = atMillis
    }

    /** Count/timestamp for [com.pypecrm.call_recording_engine.service.WhatsAppSyncListenerService]
     * — deliberately separate from the call-sync tier counters/[lastSyncedAtMillis]
     * above, since this is an unrelated data source (notification content,
     * not call events) surfaced as its own row on the status screen. */
    var whatsAppSyncCount: Int
        get() = prefs.getInt(KEY_WHATSAPP_SYNC_COUNT, 0)
        set(value) = prefs.edit().putInt(KEY_WHATSAPP_SYNC_COUNT, value).apply()

    var lastWhatsAppSyncAtMillis: Long
        get() = prefs.getLong(KEY_LAST_WHATSAPP_SYNC_AT, 0L)
        set(value) = prefs.edit().putLong(KEY_LAST_WHATSAPP_SYNC_AT, value).apply()

    fun recordWhatsAppSync(atMillis: Long) {
        whatsAppSyncCount += 1
        lastWhatsAppSyncAtMillis = atMillis
    }

    companion object {
        private const val PREFS_NAME = "call_recording_engine_stats"
        private const val KEY_MONITORING_ENABLED = "monitoring_enabled"
        private const val KEY_LAST_SYNCED_AT = "last_synced_at"
        private const val KEY_TIER0_SUCCESS = "tier0_success_count"
        private const val KEY_TIER1_SUCCESS = "tier1_success_count"
        private const val KEY_TIER2_SUCCESS = "tier2_success_count"
        private const val KEY_TIER3_SUCCESS = "tier3_success_count"
        private const val KEY_TIER4_SUCCESS = "tier4_success_count"
        private const val KEY_NEXT_BULK_SYNC = "next_bulk_sync_allowed_at"
        private const val KEY_WHATSAPP_SYNC_COUNT = "whatsapp_sync_count"
        private const val KEY_LAST_WHATSAPP_SYNC_AT = "last_whatsapp_sync_at"
    }
}
