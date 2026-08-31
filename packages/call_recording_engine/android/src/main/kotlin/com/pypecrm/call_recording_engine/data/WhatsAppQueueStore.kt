package com.pypecrm.call_recording_engine.data

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Tiny offline retry queue for WhatsApp message syncs that failed with a
 * transient/network error (never for an auth failure or an org that has
 * turned the feature off — see [com.pypecrm.call_recording_engine.service.WhatsAppSyncListenerService],
 * which decides what belongs here). A handful of short text rows at most, so
 * a plain JSON array in SharedPreferences is enough — no SQLite needed,
 * unlike [CallEventDbHelper] which genuinely needs queryable columns for a
 * much larger, longer-lived dataset.
 */
class WhatsAppQueueStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun enqueue(phoneNumber: String, messageText: String) {
        val array = readArray()
        array.put(
            JSONObject().apply {
                put("phoneNumber", phoneNumber)
                put("messageText", messageText)
            }
        )
        writeArray(array)
    }

    fun getAll(): List<Pair<String, String>> {
        val array = readArray()
        return (0 until array.length()).map {
            val obj = array.getJSONObject(it)
            obj.getString("phoneNumber") to obj.getString("messageText")
        }
    }

    /** Overwrites the queue with exactly [items] — used by the sync worker to
     * drop the entries it just handled while keeping the ones that still
     * failed, without a race against a notification arriving mid-drain. */
    fun replaceAll(items: List<Pair<String, String>>) {
        val array = JSONArray()
        for ((phoneNumber, messageText) in items) {
            array.put(
                JSONObject().apply {
                    put("phoneNumber", phoneNumber)
                    put("messageText", messageText)
                }
            )
        }
        writeArray(array)
    }

    private fun readArray(): JSONArray =
        runCatching { JSONArray(prefs.getString(KEY_QUEUE, "[]")) }.getOrDefault(JSONArray())

    private fun writeArray(array: JSONArray) {
        prefs.edit().putString(KEY_QUEUE, array.toString()).apply()
    }

    companion object {
        private const val PREFS_NAME = "call_recording_engine_whatsapp_queue"
        private const val KEY_QUEUE = "queue"
    }
}
