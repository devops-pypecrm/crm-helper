package com.pypecrm.call_recording_engine.util

import android.content.Context
import android.provider.CallLog
import android.util.Log
import kotlinx.coroutines.delay

data class CallLogDetails(
    val phoneNumber: String,
    val durationSeconds: Int,
    val callType: String,
    val timestampMillis: Long,
    val hardwareId: String,
)

/**
 * Retry-polls the system CallLog for the row a just-ended call produced.
 * Adapted from CallTrackerService.getLatestCallDetails, but keyed on "the
 * newest entry written since this call started" rather than a phone-number
 * LIKE match.
 *
 * Why: the PHONE_STATE broadcast reliably carries the number for INCOMING
 * calls (EXTRA_INCOMING_NUMBER) but not for OUTGOING ones — the
 * NEW_OUTGOING_CALL broadcast that would have supplied it is a no-op on
 * Android 10+ for any app that isn't the default dialer, so
 * CallStateReceiver deliberately no longer depends on it (see this app's
 * plan). A number-based query alone can't be trusted for outgoing calls as
 * a result; recency plus the fact the CallLog write is the system's own
 * authoritative record works for both directions without it.
 */
object CallLogLookup {
    private const val TAG = "CallLogLookup"
    private const val MAX_ATTEMPTS = 20
    private const val RETRY_DELAY_MS = 3000L

    // A row dated meaningfully before the call started is stale (from a
    // previous call) — the system just hasn't written this call's row yet.
    private const val STALE_TOLERANCE_MS = 5_000L

    private val FINAL_ZERO_DURATION_TYPES = setOf("MISSED", "REJECTED", "BLOCKED")

    suspend fun awaitLatestCallDetails(context: Context, callStartedAtMillis: Long): CallLogDetails? {
        repeat(MAX_ATTEMPTS) { attempt ->
            val details = queryOnce(context, callStartedAtMillis)
            if (details != null) return details
            if (attempt < MAX_ATTEMPTS - 1) delay(RETRY_DELAY_MS)
        }
        Log.w(TAG, "No CallLog entry appeared for call started at $callStartedAtMillis after $MAX_ATTEMPTS attempts")
        return null
    }

    private fun queryOnce(context: Context, callStartedAtMillis: Long): CallLogDetails? {
        try {
            context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DATE,
                    CallLog.Calls._ID,
                ),
                null,
                null,
                "${CallLog.Calls.DATE} DESC LIMIT 1",
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return null
                val date = cursor.getLong(3)
                if (date < callStartedAtMillis - STALE_TOLERANCE_MS) return null

                val typeStr = when (cursor.getInt(2)) {
                    CallLog.Calls.INCOMING_TYPE -> "INCOMING"
                    CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
                    CallLog.Calls.MISSED_TYPE -> "MISSED"
                    CallLog.Calls.REJECTED_TYPE -> "REJECTED"
                    CallLog.Calls.BLOCKED_TYPE -> "BLOCKED"
                    else -> "UNKNOWN"
                }
                val duration = cursor.getInt(1)
                // Only trust this row once it looks finalized: a real
                // duration, or a type that's legitimately always zero.
                val isFinalized = duration > 0 || typeStr in FINAL_ZERO_DURATION_TYPES
                if (!isFinalized) return null

                return CallLogDetails(
                    phoneNumber = cursor.getString(0) ?: "",
                    durationSeconds = duration,
                    callType = typeStr,
                    timestampMillis = date,
                    hardwareId = cursor.getLong(4).toString(),
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "CallLog query failed", e)
        }
        return null
    }
}
