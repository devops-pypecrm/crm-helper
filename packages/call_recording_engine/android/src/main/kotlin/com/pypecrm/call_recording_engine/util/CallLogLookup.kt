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
 * Adapted from CallTrackerService.getLatestCallDetails, but keyed primarily
 * on recency rather than a phone-number LIKE match, since the PHONE_STATE
 * broadcast only reliably carries the number for INCOMING calls
 * (EXTRA_INCOMING_NUMBER) — the NEW_OUTGOING_CALL broadcast that would
 * supply it for outgoing calls is a no-op on Android 10+ for any app that
 * isn't the default dialer, so CallStateReceiver deliberately doesn't rely
 * on it.
 *
 * Hardening note: pure "most recent row" matching has a real failure mode —
 * confirmed on a real device — where an unrelated CallLog write (a second
 * call, a carrier-blocked/spam entry, etc.) lands between call-end and the
 * row we're actually waiting for, and gets picked up instead, uploading
 * that row's (possibly zero) duration for the wrong call. [expectedNumberSuffix]
 * (from [com.pypecrm.call_recording_engine.data.CallStatePrefs.expectedNumber],
 * only ever populated for incoming calls) is used as a preference among the
 * most recent candidates when available, without weakening outgoing-call
 * matching, which still has no number to check against.
 */
object CallLogLookup {
    private const val TAG = "CallLogLookup"
    private const val MAX_ATTEMPTS = 20
    private const val RETRY_DELAY_MS = 3000L
    private const val CANDIDATE_LIMIT = 5

    // A row dated meaningfully before the call started is stale (from a
    // previous call) — the system just hasn't written this call's row yet.
    private const val STALE_TOLERANCE_MS = 5_000L

    private val FINAL_ZERO_DURATION_TYPES = setOf("MISSED", "REJECTED", "BLOCKED")

    suspend fun awaitLatestCallDetails(
        context: Context,
        callStartedAtMillis: Long,
        expectedNumberSuffix: String? = null,
    ): CallLogDetails? {
        repeat(MAX_ATTEMPTS) { attempt ->
            val details = queryOnce(context, callStartedAtMillis, expectedNumberSuffix)
            if (details != null) return details
            if (attempt < MAX_ATTEMPTS - 1) delay(RETRY_DELAY_MS)
        }
        Log.w(TAG, "No CallLog entry appeared for call started at $callStartedAtMillis after $MAX_ATTEMPTS attempts")
        return null
    }

    private fun queryOnce(context: Context, callStartedAtMillis: Long, expectedNumberSuffix: String?): CallLogDetails? {
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
                // No `LIMIT` embedded in sortOrder — confirmed on a real
                // device that at least one OEM's CallLog ContentProvider
                // rejects it outright ("Invalid token LIMIT"), unlike
                // stock Android's SQLite passthrough. The row count is
                // capped in Kotlin below instead, which works against any
                // provider implementation.
                "${CallLog.Calls.DATE} DESC",
            )?.use { cursor ->
                val candidates = mutableListOf<Candidate>()
                while (cursor.moveToNext() && candidates.size < CANDIDATE_LIMIT) {
                    val date = cursor.getLong(3)
                    if (date < callStartedAtMillis - STALE_TOLERANCE_MS) continue
                    candidates.add(
                        Candidate(
                            number = cursor.getString(0) ?: "",
                            duration = cursor.getInt(1),
                            typeInt = cursor.getInt(2),
                            date = date,
                            id = cursor.getLong(4),
                        )
                    )
                }
                if (candidates.isEmpty()) return null

                // Prefer a candidate whose number matches the expected
                // suffix (incoming calls only — see class doc comment);
                // otherwise the most recent candidate, same as before.
                val chosen = if (!expectedNumberSuffix.isNullOrEmpty()) {
                    candidates.firstOrNull { it.number.filter(Char::isDigit).endsWith(expectedNumberSuffix) }
                        ?: candidates.first()
                } else {
                    candidates.first()
                }

                val typeStr = typeToString(chosen.typeInt)
                // Only trust this row once it looks finalized: a real
                // duration, or a type that's legitimately always zero.
                val isFinalized = chosen.duration > 0 || typeStr in FINAL_ZERO_DURATION_TYPES
                if (!isFinalized) return null

                return CallLogDetails(
                    phoneNumber = chosen.number,
                    durationSeconds = chosen.duration,
                    callType = typeStr,
                    timestampMillis = chosen.date,
                    hardwareId = chosen.id.toString(),
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "CallLog query failed", e)
        }
        return null
    }

    private fun typeToString(typeInt: Int): String = when (typeInt) {
        CallLog.Calls.INCOMING_TYPE -> "INCOMING"
        CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
        CallLog.Calls.MISSED_TYPE -> "MISSED"
        CallLog.Calls.REJECTED_TYPE -> "REJECTED"
        CallLog.Calls.BLOCKED_TYPE -> "BLOCKED"
        else -> "UNKNOWN"
    }

    private data class Candidate(val number: String, val duration: Int, val typeInt: Int, val date: Long, val id: Long)
}
