package com.pypecrm.call_recording_engine.util

import android.content.Context
import android.provider.CallLog
import android.util.Log
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
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
 * most recent candidates when available.
 *
 * For OUTGOING calls there's still no number to check against (Android
 * never hands one to a non-default-dialer app — see CallStateReceiver's
 * doc comment) — that gap is exactly what caused a real connected outgoing
 * call to get logged as "failed"/no-answer when an unrelated CallLog row
 * (e.g. a call on the other SIM, a spam-blocked entry) landed nearby and
 * had no number to disqualify it. [expectedType] (from
 * [com.pypecrm.call_recording_engine.data.CallStatePrefs.likelyOutgoing],
 * a free, permission-less direction guess CallStateReceiver already
 * computes) closes that gap as a second-tier preference: prefer a
 * candidate whose own CallLog TYPE matches the direction we already know
 * this call was, before falling back to "most recent."
 */
object CallLogLookup {
    private const val TAG = "CallLogLookup"
    private const val MAX_ATTEMPTS = 20
    private const val RETRY_DELAY_MS = 3000L
    private const val CANDIDATE_LIMIT = 5
    // 3 polls x 3s ≈ 6-9s of an unchanged 0s row — longer than any OEM's
    // observed CallLog DURATION write lag.
    private const val ZERO_DURATION_STABLE_POLLS = 3

    // A row dated meaningfully before the call started is stale (from a
    // previous call) — the system just hasn't written this call's row yet.
    private const val STALE_TOLERANCE_MS = 5_000L

    private val FINAL_ZERO_DURATION_TYPES = setOf("MISSED", "REJECTED", "BLOCKED")

    suspend fun awaitLatestCallDetails(
        context: Context,
        callStartedAtMillis: Long,
        expectedNumberSuffix: String? = null,
        expectedType: String? = null,
    ): CallLogDetails? {
        // An unanswered outgoing call (or a 0s incoming one) keeps DURATION=0
        // forever, so "duration > 0" never arrives for it — previously that
        // meant waiting the full ~60s and then returning null, so the live
        // path dropped every no-answer dial. Once the same zero-duration row
        // has been the chosen candidate for ZERO_DURATION_STABLE_POLLS polls
        // in a row, it's final: accept it.
        var lastZeroRowId: Long? = null
        var zeroRowSeenCount = 0
        repeat(MAX_ATTEMPTS) { attempt ->
            when (val result = queryOnce(context, callStartedAtMillis, expectedNumberSuffix, expectedType)) {
                is LookupResult.Final -> return result.details
                is LookupResult.Unfinalized -> {
                    if (result.details.hardwareId.toLongOrNull() == lastZeroRowId) {
                        zeroRowSeenCount++
                    } else {
                        lastZeroRowId = result.details.hardwareId.toLongOrNull()
                        zeroRowSeenCount = 1
                    }
                    if (zeroRowSeenCount >= ZERO_DURATION_STABLE_POLLS) return result.details
                }
                LookupResult.None -> {
                    lastZeroRowId = null
                    zeroRowSeenCount = 0
                }
            }
            if (attempt < MAX_ATTEMPTS - 1) delay(RETRY_DELAY_MS)
        }
        Log.w(TAG, "No CallLog entry appeared for call started at $callStartedAtMillis after $MAX_ATTEMPTS attempts")
        return null
    }

    private sealed class LookupResult {
        data class Final(val details: CallLogDetails) : LookupResult()
        /** Row found but DURATION is still 0 — either not written yet, or a
         * genuinely zero-length call (see awaitLatestCallDetails). */
        data class Unfinalized(val details: CallLogDetails) : LookupResult()
        object None : LookupResult()
    }

    private fun queryOnce(
        context: Context,
        callStartedAtMillis: Long,
        expectedNumberSuffix: String?,
        expectedType: String?,
    ): LookupResult {
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
                if (candidates.isEmpty()) return LookupResult.None

                // Three-tier preference: an exact number match (incoming
                // calls only) beats a direction-type match (mainly helps
                // outgoing calls, which have no number to check), which
                // beats the "most recent" fallback used when neither hint
                // is available or nothing matches.
                val numberMatch = if (!expectedNumberSuffix.isNullOrEmpty()) {
                    candidates.firstOrNull { it.number.filter(Char::isDigit).endsWith(expectedNumberSuffix) }
                } else null
                val typeMatch = if (numberMatch == null && expectedType != null) {
                    candidates.firstOrNull { typeToString(it.typeInt) == expectedType }
                } else null
                val chosen = numberMatch ?: typeMatch ?: candidates.first()

                val typeStr = typeToString(chosen.typeInt)
                if (typeStr == "UNKNOWN") {
                    // A CallLog TYPE outside Android's own documented set
                    // (1/2/3/4/5/6/7) — some OEMs use extra proprietary
                    // values (dual-SIM/VoLTE bookkeeping, etc.). Logging the
                    // raw int is the only way to ever find out what it was
                    // and map it properly, since it's otherwise invisible.
                    Log.w(TAG, "Unrecognized CallLog TYPE=${chosen.typeInt} for row ${chosen.id}")
                    EngineDebugLog(context).append(
                        "CALL_LOG_UNKNOWN_TYPE",
                        "CallLog TYPE=${chosen.typeInt} not recognized (row ${chosen.id})",
                        level = "warn",
                    )
                }
                // Only trust this row once it looks finalized: a real
                // duration, or a type that's legitimately always zero.
                val isFinalized = chosen.duration > 0 || typeStr in FINAL_ZERO_DURATION_TYPES
                val details = CallLogDetails(
                    phoneNumber = chosen.number,
                    durationSeconds = chosen.duration,
                    callType = typeStr,
                    timestampMillis = chosen.date,
                    hardwareId = chosen.id.toString(),
                )
                return if (isFinalized) LookupResult.Final(details) else LookupResult.Unfinalized(details)
            }
        } catch (e: Exception) {
            Log.e(TAG, "CallLog query failed", e)
        }
        return LookupResult.None
    }

    private fun typeToString(typeInt: Int): String = when (typeInt) {
        CallLog.Calls.INCOMING_TYPE -> "INCOMING"
        CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
        CallLog.Calls.MISSED_TYPE -> "MISSED"
        CallLog.Calls.VOICEMAIL_TYPE -> "MISSED" // no distinct backend bucket for voicemail
        CallLog.Calls.REJECTED_TYPE -> "REJECTED"
        CallLog.Calls.BLOCKED_TYPE -> "BLOCKED"
        CallLog.Calls.ANSWERED_EXTERNALLY_TYPE -> "INCOMING" // answered on a linked device — still inbound
        else -> "UNKNOWN"
    }

    private data class Candidate(val number: String, val duration: Int, val typeInt: Int, val date: Long, val id: Long)
}
