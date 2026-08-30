package com.pypecrm.call_recording_engine.telecom

import android.content.Context

/**
 * Milestone 1 POC configuration — which role (if any) this device is
 * playing, and the recorder SIM's phone number the Dialer role calls.
 * Selecting either role is mutually exclusive with the existing Phase 1-4
 * monitoring pipeline (see [isActive] and its use in `CallStateReceiver`) —
 * this milestone needs one unambiguous recording path per test call, not
 * the shipped acoustic-fallback tier firing at the same time. Deliberately
 * separate from [com.pypecrm.call_recording_engine.data.EngineStats] rather
 * than overloading its `monitoringEnabled` flag — this is POC-only state
 * that must never leak into or be confused with the real Phase 1-4 feature.
 */
class PocConfig(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var role: String?
        get() = prefs.getString(KEY_ROLE, null)
        set(value) = prefs.edit().putString(KEY_ROLE, value).apply()

    /** The Pype Recorder SIM's phone number — configured on the Dialer
     * phone only; the Recorder phone doesn't need to know its own number. */
    var recordingNumber: String?
        get() = prefs.getString(KEY_RECORDING_NUMBER, null)
        set(value) = prefs.edit().putString(KEY_RECORDING_NUMBER, value).apply()

    val isDialerRole: Boolean get() = role == ROLE_DIALER
    val isRecorderRole: Boolean get() = role == ROLE_RECORDER

    /** True whenever a POC role is selected — the existing Phase 1-4
     * `CallStateReceiver` checks this and stands down entirely while it's
     * true, since `PypeInCallService` is the sole call-handling path for
     * either POC role. */
    val isActive: Boolean get() = role != null

    companion object {
        private const val PREFS_NAME = "call_recording_engine_poc_config"
        private const val KEY_ROLE = "role"
        private const val KEY_RECORDING_NUMBER = "recording_number"

        const val ROLE_DIALER = "DIALER"
        const val ROLE_RECORDER = "RECORDER"
    }
}
