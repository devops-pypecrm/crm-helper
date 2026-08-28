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

    companion object {
        private const val TAG = "BackendApi"
    }
}
