package com.pypecrm.call_recording_engine.net

import android.util.Log
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.data.PendingCallEvent
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

data class OrgCallSettings(val autoRecordInbound: Boolean, val autoRecordOutbound: Boolean)

sealed class BulkSyncResult {
    data class Success(val count: Int) : BulkSyncResult()
    data class RateLimited(val retryAfterSeconds: Int) : BulkSyncResult()
    data object Failed : BulkSyncResult()
}

sealed class WhatsAppSyncResult {
    /** Logged to the CRM successfully. */
    data object Success : WhatsAppSyncResult()

    /** The org has `whatsAppScrapingEnabled = false` (Dad-backend's
     * `logExternalMessage` still responds 200 in this case) — not an error,
     * and never worth queuing for retry. */
    data object Disabled : WhatsAppSyncResult()

    /** Stale/invalid token (401) — retrying the same message won't help
     * until the user re-authenticates, so this is also never queued. */
    data object AuthFailed : WhatsAppSyncResult()

    /** Network error or a non-401 server error — transient, safe to queue
     * and retry later. */
    data object Failed : WhatsAppSyncResult()
}

/**
 * Talks to Dad-backend's `/api/android` and `/api/call-settings` endpoints
 * directly via OkHttp (not Dio) — this runs from CallMonitorService and
 * CallSyncWorker, both of which must function with the Flutter engine fully
 * suspended, so it can't depend on anything Dart-side being alive. Contract
 * re-confirmed directly against Dad-backend/src/routes/androidRoutes.ts,
 * controllers/androidController.ts and routes/callSettingsRoutes.ts —
 * see Dad-mobile/CALL_RECORDING_PLAN.md.
 */
class BackendApi(private val authPrefs: NativeAuthPrefs) {
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(120, TimeUnit.SECONDS)
        .build()

    private fun authOrNull(): Pair<String, String>? {
        val token = authPrefs.token ?: return null
        val base = authPrefs.apiBaseUrl ?: return null
        return token to base
    }

    /** `apiBaseUrl` already includes the `/api` suffix (see Dad-call-recorder's
     * AppConfig.apiBaseUrl, whose value is what CallRecordingEnginePlugin's
     * saveAuthForNative persists here), so paths below only add the
     * resource-specific segment. */
    fun fetchCallSettings(): OrgCallSettings? {
        val (token, base) = authOrNull() ?: return null
        val request = Request.Builder()
            .url("$base/call-settings")
            .header("Authorization", "Bearer $token")
            .get()
            .build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                Log.w(TAG, "fetchCallSettings failed: ${response.code}")
                return null
            }
            val body = response.body?.string() ?: return null
            val json = JSONObject(body)
            return OrgCallSettings(
                autoRecordInbound = json.optBoolean("autoRecordInbound", false),
                autoRecordOutbound = json.optBoolean("autoRecordOutbound", false),
            )
        }
    }

    /** Tier 0 path: a real recording file was found and this call's
     * direction is allowed — `POST /api/android/recordings`, multipart,
     * file field `audio`. `hardwareId` is sent un-namespaced; the server
     * prefixes it with `${userId}_` itself. */
    fun uploadRecording(event: PendingCallEvent, audioFile: File): Boolean {
        val (token, base) = authOrNull() ?: return false
        val mediaType = "audio/*".toMediaTypeOrNull()
        val body = MultipartBody.Builder().setType(MultipartBody.FORM)
            .addFormDataPart("phoneNumber", event.phoneNumber)
            .addFormDataPart("duration", event.durationSeconds.toString())
            .addFormDataPart("callType", event.callType)
            .addFormDataPart("timestamp", event.timestampMillis.toString())
            .addFormDataPart("hardwareId", event.hardwareId ?: "")
            .addFormDataPart("callSessionId", event.callSessionId ?: "")
            .addFormDataPart("audio", audioFile.name, audioFile.asRequestBody(mediaType))
            .build()
        val request = Request.Builder()
            .url("$base/android/recordings")
            .header("Authorization", "Bearer $token")
            .post(body)
            .build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                Log.w(TAG, "uploadRecording failed: ${response.code} ${response.body?.string()}")
            }
            return response.isSuccessful
        }
    }

    /** Tier 4 path: batches every unsynced [events] into ONE call — the
     * server hard rate-limits this endpoint to 1 request/user/10min
     * (Dad-backend's androidRoutes.ts bulkSyncRateLimiter), so callers
     * (CallSyncWorker) must never call this per-event. */
    fun bulkSync(events: List<PendingCallEvent>): BulkSyncResult {
        val (token, base) = authOrNull() ?: return BulkSyncResult.Failed
        val callsJson = JSONArray()
        for (event in events) {
            callsJson.put(
                JSONObject().apply {
                    put("phoneNumber", event.phoneNumber)
                    put("duration", event.durationSeconds)
                    put("callType", event.callType)
                    put("timestamp", event.timestampMillis)
                    put("hardwareId", event.hardwareId ?: "")
                    if (event.callSessionId != null) put("callSessionId", event.callSessionId)
                }
            )
        }
        val payload = JSONObject().apply { put("calls", callsJson) }
        val request = Request.Builder()
            .url("$base/android/bulk-sync")
            .header("Authorization", "Bearer $token")
            .post(payload.toString().toRequestBody("application/json".toMediaTypeOrNull()))
            .build()
        client.newCall(request).execute().use { response ->
            return when {
                response.code == 429 -> {
                    val body = response.body?.string().orEmpty()
                    val retryAfter = runCatching { JSONObject(body).optInt("retryAfterSeconds", 600) }
                        .getOrDefault(600)
                    BulkSyncResult.RateLimited(retryAfter)
                }
                response.isSuccessful -> BulkSyncResult.Success(events.size)
                else -> {
                    Log.w(TAG, "bulkSync failed: ${response.code}")
                    BulkSyncResult.Failed
                }
            }
        }
    }

    /** `POST /api/android/whatsapp/sync` — logs an inbound WhatsApp reply
     * (as read from the notification banner, never the full chat) against
     * the matching lead/contact by phone number. Ported from
     * Dad-frontend/android's old WebView-wrapper app; contract re-confirmed
     * against Dad-backend's `androidRoutes.ts` + `whatsAppController.ts`'s
     * `logExternalMessage`, which gates on `Organisation.whatsAppScrapingEnabled`
     * server-side and still returns 200 (`{ success: false }`) when the org
     * has it turned off — that's [WhatsAppSyncResult.Disabled], not a
     * failure. */
    fun syncWhatsAppMessage(phoneNumber: String, messageText: String): WhatsAppSyncResult {
        val (token, base) = authOrNull() ?: return WhatsAppSyncResult.AuthFailed
        val json = JSONObject().apply {
            put("phoneNumber", phoneNumber)
            put("messageText", messageText)
            put("timestamp", System.currentTimeMillis())
            put("source", "NOTIFICATION_LISTENER")
        }
        val request = Request.Builder()
            .url("$base/android/whatsapp/sync")
            .header("Authorization", "Bearer $token")
            .post(json.toString().toRequestBody("application/json".toMediaTypeOrNull()))
            .build()
        return try {
            client.newCall(request).execute().use { response ->
                val body = response.body?.string().orEmpty()
                when {
                    response.code == 401 -> WhatsAppSyncResult.AuthFailed
                    !response.isSuccessful -> {
                        Log.w(TAG, "syncWhatsAppMessage failed: ${response.code}")
                        WhatsAppSyncResult.Failed
                    }
                    else -> {
                        val success = runCatching { JSONObject(body).optBoolean("success", true) }
                            .getOrDefault(true)
                        if (success) WhatsAppSyncResult.Success else WhatsAppSyncResult.Disabled
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "syncWhatsAppMessage network error", e)
            WhatsAppSyncResult.Failed
        }
    }

    companion object {
        private const val TAG = "BackendApi"
    }
}
