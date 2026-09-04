package com.pypecrm.call_recording_engine.debug

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Append-only ring buffer of Tier 0 (native-recording scan) and Tier 2
 * (accessibility auto-enable) diagnostic events, readable from Dart. Exists
 * for the same reason the POC's debug log did: several OEMs suppress
 * third-party app `Log.*` output from `adb logcat` entirely (confirmed on
 * ColorOS this project's test device), so a debug surface that depends on
 * logcat being visible is unreliable — this is the thing to actually read
 * when iterating against a real device.
 */
class EngineDebugLog(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** [level] is "info" | "warn" | "error" — mirrors HelperActivityLog.level
     * server-side (see HelperLogUploader), shown as a badge in the
     * super-admin Helper Logs panel. */
    fun append(event: String, detail: String = "", level: String = "info") {
        Log.d(TAG, "$event: $detail")
        synchronized(this) {
            val entries = readEntries()
            entries.add(
                JSONObject().apply {
                    put("event", event)
                    put("detail", detail)
                    put("level", level)
                    put("timestampMillis", System.currentTimeMillis())
                }
            )
            while (entries.size > MAX_ENTRIES) entries.removeAt(0)
            prefs.edit().putString(KEY_ENTRIES, JSONArray(entries).toString()).apply()
        }
    }

    /** Newest-first, as a list of `{event, detail, level, timestampMillis}` maps. */
    fun readAll(): List<Map<String, Any?>> =
        readEntries().asReversed().map { entry ->
            mapOf(
                "event" to entry.optString("event"),
                "detail" to entry.optString("detail"),
                "level" to entry.optString("level", "info"),
                "timestampMillis" to entry.optLong("timestampMillis"),
            )
        }

    /** Same as [readAll] but ascending (oldest first) and only entries newer
     * than [afterMillis] — what [HelperLogUploader] actually wants to send,
     * since it needs to advance a watermark in chronological order. */
    fun readSince(afterMillis: Long): List<Map<String, Any?>> =
        readAll().asReversed().filter { (it["timestampMillis"] as? Long ?: 0L) > afterMillis }

    fun clear() {
        prefs.edit().remove(KEY_ENTRIES).apply()
    }

    private fun readEntries(): MutableList<JSONObject> {
        val raw = prefs.getString(KEY_ENTRIES, null) ?: return mutableListOf()
        return try {
            val array = JSONArray(raw)
            MutableList(array.length()) { array.getJSONObject(it) }
        } catch (e: Exception) {
            mutableListOf()
        }
    }

    companion object {
        private const val TAG = "EngineDebugLog"
        private const val PREFS_NAME = "call_recording_engine_debug_log"
        private const val KEY_ENTRIES = "entries"
        private const val MAX_ENTRIES = 200
    }
}
