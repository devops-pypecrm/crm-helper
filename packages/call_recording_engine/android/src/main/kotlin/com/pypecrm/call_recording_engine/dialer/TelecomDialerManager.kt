package com.pypecrm.call_recording_engine.dialer

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.telecom.TelecomManager
import android.util.Log
import com.pypecrm.call_recording_engine.debug.EngineDebugLog

/**
 * Manages interaction with Android's Telecom framework needed to become
 * (and place calls as) the default Phone app:
 *   - Default-dialer role request (RoleManager on API 29+, legacy intent below)
 *   - Outgoing call placement via TelecomManager.placeCall()
 *
 * Deliberately does NOT register a PhoneAccount or implement a
 * ConnectionService. An earlier version of this feature did (a
 * self-managed one), which was the wrong tool: a self-managed
 * ConnectionService is for VoIP/OTT apps that provide their OWN calling
 * backend, and Android explicitly does not consider such an app eligible
 * to be the default Phone app — which is exactly why it never showed up in
 * the system's "default apps" picker. There is also no way for a
 * self-managed Connection to ever represent a real SIM call (nothing
 * third-party code can do calls that) — the earlier code's `setDialing()`
 * had no way to ever transition further, so the in-call UI's timer showing
 * with no real call is the direct, expected consequence of that design.
 *
 * The correct integration for a real Phone app is [PypeInCallService]: once
 * this app holds the RoleManager.ROLE_DIALER role, Android delivers the
 * REAL Call objects (created by the system's own telephony
 * ConnectionService, tied to the SIM) to that service — for both calls we
 * place here and calls placed to this device. See its class doc comment.
 */
object TelecomDialerManager {
    private const val TAG = "TelecomDialerManager"

    // Request code used by CallRecordingEnginePlugin for the role-request intent result.
    const val REQUEST_CODE_SET_DEFAULT_DIALER = 4204

    /** Returns true if this app is currently the system default dialer. */
    fun isDefaultDialer(context: Context): Boolean {
        return try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            telecom?.defaultDialerPackage == context.packageName
        } catch (e: Exception) {
            Log.w(TAG, "Could not check default dialer status", e)
            false
        }
    }

    /**
     * Fires the system dialog for setting this app as the default dialer.
     * This is a user-action-only flow — cannot be silently granted.
     * Result is delivered to [activity].onActivityResult() with
     * request code [REQUEST_CODE_SET_DEFAULT_DIALER].
     *
     * Uses RoleManager.createRequestRoleIntent(ROLE_DIALER) on API 29+
     * and falls back to TelecomManager.ACTION_CHANGE_DEFAULT_DIALER below that.
     */
    fun requestDefaultDialerRole(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = activity.getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_DIALER) &&
                !roleManager.isRoleHeld(RoleManager.ROLE_DIALER)
            ) {
                activity.startActivityForResult(
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER),
                    REQUEST_CODE_SET_DEFAULT_DIALER
                )
            }
            // Already held — no-op; caller re-checks isDefaultDialer().
        } else {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                putExtra(
                    TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME,
                    activity.packageName
                )
            }
            try {
                activity.startActivityForResult(intent, REQUEST_CODE_SET_DEFAULT_DIALER)
            } catch (e: Exception) {
                Log.e(TAG, "Could not launch legacy default-dialer intent", e)
            }
        }
    }

    /**
     * Places an outgoing call via TelecomManager.placeCall() — no custom
     * PhoneAccountHandle, so Telecom routes it through the SIM's own phone
     * account (same as the stock dialer would). Requires CALL_PHONE. Once
     * this app is the default dialer, [PypeInCallService.onCallAdded] fires
     * for the resulting real Call, which is the only place actual call
     * state (dialing/active/disconnected) comes from — this method's job
     * ends at requesting the call, nothing here should be read as
     * confirmation the call connected.
     */
    fun placeCall(context: Context, number: String) {
        try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                ?: return.also { Log.e(TAG, "TelecomManager unavailable") }

            val uri = Uri.fromParts("tel", number, null)
            telecom.placeCall(uri, null)
            EngineDebugLog(context).append(
                "DIALER_CALL_REQUESTED",
                "Outgoing call requested to ${number.take(4)}*** via TelecomManager"
            )
        } catch (e: SecurityException) {
            Log.e(TAG, "CALL_PHONE permission missing", e)
            EngineDebugLog(context).append(
                "DIALER_CALL_REQUESTED",
                "FAILED — missing CALL_PHONE: ${e.message}",
                level = "error"
            )
        } catch (e: Exception) {
            Log.e(TAG, "placeCall failed", e)
            EngineDebugLog(context).append("DIALER_CALL_REQUESTED", "FAILED: ${e.message}", level = "error")
        }
    }
}
