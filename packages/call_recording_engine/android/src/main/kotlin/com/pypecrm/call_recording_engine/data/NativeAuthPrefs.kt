package com.pypecrm.call_recording_engine.data

import android.content.Context

/**
 * JWT + API base URL, duplicated here from Dart's flutter_secure_storage so
 * CallMonitorService/CallSyncWorker (which must keep working with the
 * Flutter engine fully suspended) can authenticate without decrypting
 * flutter_secure_storage's own encrypted store from native code. Mirrors
 * the proven `crm_prefs`/`jwt_token` pattern from the old wrapper app's
 * CallTrackerService.getAuthData() — this file is still app-sandboxed (no
 * other app can read it), just not additionally encrypted at rest the way
 * flutter_secure_storage is.
 */
class NativeAuthPrefs(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun save(token: String, apiBaseUrl: String) {
        prefs.edit()
            .putString(KEY_TOKEN, token)
            .putString(KEY_API_BASE, apiBaseUrl.trimEnd('/'))
            .apply()
    }

    fun clear() {
        prefs.edit().clear().apply()
    }

    val token: String? get() = prefs.getString(KEY_TOKEN, null)
    val apiBaseUrl: String? get() = prefs.getString(KEY_API_BASE, null)

    fun isSignedIn(): Boolean = !token.isNullOrEmpty() && !apiBaseUrl.isNullOrEmpty()

    companion object {
        private const val PREFS_NAME = "call_recording_engine_auth"
        private const val KEY_TOKEN = "jwt_token"
        private const val KEY_API_BASE = "api_base_url"
    }
}
