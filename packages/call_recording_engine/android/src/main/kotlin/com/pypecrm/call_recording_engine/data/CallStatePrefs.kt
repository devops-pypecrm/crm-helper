package com.pypecrm.call_recording_engine.data

import android.content.Context
import android.telephony.TelephonyManager

/**
 * Ephemeral in-call state CallStateReceiver and CallMonitorService
 * coordinate through — same pattern as the old wrapper app's
 * `call_state_prefs`. SharedPreferences (not an in-memory singleton)
 * because the receiver and the foreground service are separate Android
 * components the OS can recreate independently; state has to survive that.
 */
class CallStatePrefs(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var isCallActive: Boolean
        get() = prefs.getBoolean(KEY_IS_ACTIVE, false)
        set(value) = prefs.edit().putBoolean(KEY_IS_ACTIVE, value).apply()

    var callStartTimeMillis: Long
        get() = prefs.getLong(KEY_START_TIME, 0L)
        set(value) = prefs.edit().putLong(KEY_START_TIME, value).apply()

    var lastPhoneState: Int
        get() = prefs.getInt(KEY_LAST_STATE, TelephonyManager.CALL_STATE_IDLE)
        set(value) = prefs.edit().putInt(KEY_LAST_STATE, value).apply()

    /** Best-effort, permission-free direction guess: RINGING only ever
     * happens for an incoming call in Android's phone-state machine, so
     * "did we see RINGING right before this OFFHOOK" is a reliable signal
     * without needing the deprecated NEW_OUTGOING_CALL broadcast (which is
     * unreliable on Android 10+ — see CallStateReceiver's doc comment).
     * Used only to decide whether Tier 1 recording may even START (a live
     * decision, made before the call ends); the final upload gate uses the
     * CallLog's authoritative direction instead, see CallMonitorService. */
    var likelyOutgoing: Boolean
        get() = prefs.getBoolean(KEY_LIKELY_OUTGOING, false)
        set(value) = prefs.edit().putBoolean(KEY_LIKELY_OUTGOING, value).apply()

    /** Number from `TelephonyManager.EXTRA_INCOMING_NUMBER`, when the OS
     * hands it to us at RINGING — reliable for incoming calls, always null
     * for outgoing ones (the OS never provides an outgoing number to a
     * non-default-dialer app, same reason [likelyOutgoing] exists). Used
     * only as a matching HINT for [CallLogLookup] to prefer the right
     * CallLog row when several calls land close together — never a hard
     * requirement, since it's legitimately absent for outgoing calls. */
    var expectedNumber: String?
        get() = prefs.getString(KEY_EXPECTED_NUMBER, null)
        set(value) = prefs.edit().putString(KEY_EXPECTED_NUMBER, value).apply()

    companion object {
        private const val PREFS_NAME = "call_recording_engine_call_state"
        private const val KEY_IS_ACTIVE = "is_call_active"
        private const val KEY_START_TIME = "call_start_time"
        private const val KEY_LAST_STATE = "last_state"
        private const val KEY_LIKELY_OUTGOING = "likely_outgoing"
        private const val KEY_EXPECTED_NUMBER = "expected_number"
    }
}
