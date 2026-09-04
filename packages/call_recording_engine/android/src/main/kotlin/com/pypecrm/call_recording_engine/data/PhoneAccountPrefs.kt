package com.pypecrm.call_recording_engine.data

import android.content.Context

/**
 * Persists whether this app's PhoneAccount has been registered with
 * TelecomManager for this install. The registration itself is idempotent on
 * Android's side, but we guard it in SharedPreferences too so we can report
 * "registered / not registered" status to Dart without calling into
 * TelecomManager on every status-screen refresh (which requires
 * READ_PHONE_STATE and is marginally slower).
 *
 * Also stores whether the app is (or was last checked to be) the system
 * default dialer — checked at startup and after the user returns from the
 * role-request flow so the status/onboarding screens can show accurate state.
 */
class PhoneAccountPrefs(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** True once TelecomDialerManager.registerPhoneAccount has succeeded
     *  at least once. Reset to false on clearAuthForNative so a fresh login
     *  always re-registers (avoids stale account handles across org switches). */
    var phoneAccountRegistered: Boolean
        get() = prefs.getBoolean(KEY_REGISTERED, false)
        set(value) = prefs.edit().putBoolean(KEY_REGISTERED, value).apply()

    /** Cached result of the last TelecomDialerManager.isDefaultDialer check.
     *  Only a cache — always re-verify via TelecomManager for accuracy. */
    var wasDefaultDialer: Boolean
        get() = prefs.getBoolean(KEY_WAS_DEFAULT, false)
        set(value) = prefs.edit().putBoolean(KEY_WAS_DEFAULT, value).apply()

    fun clear() {
        prefs.edit().clear().apply()
    }

    companion object {
        private const val PREFS_NAME = "call_recording_engine_phone_account"
        private const val KEY_REGISTERED = "phone_account_registered"
        private const val KEY_WAS_DEFAULT = "was_default_dialer"
    }
}
