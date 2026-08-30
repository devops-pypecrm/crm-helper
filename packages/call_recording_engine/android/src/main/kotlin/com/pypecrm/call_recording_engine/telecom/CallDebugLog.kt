package com.pypecrm.call_recording_engine.telecom

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Append-only ring buffer of POC events, readable from Dart via the debug
 * screen. Exists specifically because **ColorOS suppresses third-party app
 * `Log.*` output from `adb logcat` entirely** (confirmed directly against a
 * real test device this session — system-level tags are visible, ours
 * never were) — a debug surface that depended on logcat being readable
 * would have been useless on exactly the device this was built and tested
 * against. Still calls through to [Log] as well, in case a future
 * device/ROM doesn't suppress it.
 */
class CallDebugLog(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun append(event: String, detail: String = "") {
        Log.d(TAG, "$event: $detail")
        synchronized(this) {
            val entries = readEntries()
            entries.add(
                JSONObject().apply {
                    put("event", event)
                    put("detail", detail)
                    put("timestampMillis", System.currentTimeMillis())
                }
            )
            while (entries.size > MAX_ENTRIES) entries.removeAt(0)
            prefs.edit().putString(KEY_ENTRIES, JSONArray(entries).toString()).apply()
        }
    }

    /** Newest-first, as a list of `{event, detail, timestampMillis}` maps —
     * matches the shape [com.pypecrm.call_recording_engine.CallRecordingEnginePlugin]
     * hands back over the MethodChannel as-is. */
    fun readAll(): List<Map<String, Any?>> =
        readEntries().asReversed().map { entry ->
            mapOf(
                "event" to entry.optString("event"),
                "detail" to entry.optString("detail"),
                "timestampMillis" to entry.optLong("timestampMillis"),
            )
        }

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
        private const val TAG = "CallDebugLog"
        private const val PREFS_NAME = "call_recording_engine_poc_debug_log"
        private const val KEY_ENTRIES = "entries"
        private const val MAX_ENTRIES = 200
    }
}
