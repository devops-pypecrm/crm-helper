package com.pypecrm.call_recording_engine.dialer

import android.app.Activity
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log
import com.pypecrm.call_recording_engine.data.PhoneAccountPrefs
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.service.PypeConnectionService

/**
 * Manages all interaction with Android's Telecom framework:
 *   - PhoneAccount registration (self-managed, CAPABILITY_SELF_MANAGED)
 *   - Default-dialer role request (RoleManager on API 29+, legacy intent below)
 *   - Outgoing call placement via TelecomManager.placeCall()
 *
 * Self-managed was chosen over fully-managed because:
 *   - The goal is CRM data capture, not being a general-purpose phone replacement
 *   - Self-managed gives us authoritative Connection lifecycle callbacks
 *     (direction, number, state) without requiring an InCallService or
 *     having to render Android's own in-call surfaces across OEM skins
 *   - Self-managed connections are exempted from emergency-call routing concerns
 *
 * CAPABILITY_SELF_MANAGED means:
 *   - We show our own in-call UI (InCallScreen / IncomingCallScreen in Flutter)
 *   - Android's built-in in-call UI does NOT appear for our calls
 *   - We do NOT implement InCallService
 *   - Emergency calls are handled by the OS regardless of which app is default dialer
 */
object TelecomDialerManager {
    private const val TAG = "TelecomDialerManager"
    const val PHONE_ACCOUNT_ID = "pypecrm_dialer"

    // Request code used by CallRecordingEnginePlugin for the role-request intent result.
    const val REQUEST_CODE_SET_DEFAULT_DIALER = 4204

    /** Stable PhoneAccountHandle — same component + ID across sessions. */
    fun phoneAccountHandle(context: Context) = PhoneAccountHandle(
        ComponentName(context.applicationContext, PypeConnectionService::class.java),
        PHONE_ACCOUNT_ID
    )

    /**
     * Registers (or re-registers) this app's self-managed PhoneAccount.
     * TelecomManager.registerPhoneAccount() is itself idempotent, but we
     * also update PhoneAccountPrefs so Dart can query registration state
     * without an additional round-trip.
     */
    fun registerPhoneAccount(context: Context): Boolean {
        return try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                ?: return false.also { Log.e(TAG, "TelecomManager not available") }

            val handle = phoneAccountHandle(context)
            val account = PhoneAccount.builder(handle, "PypeCRM Dialer")
                .setCapabilities(PhoneAccount.CAPABILITY_SELF_MANAGED)
                .build()

            telecom.registerPhoneAccount(account)
            PhoneAccountPrefs(context).phoneAccountRegistered = true
            EngineDebugLog(context).append(
                "DIALER_PHONE_ACCOUNT_REGISTERED",
                "Self-managed PhoneAccount registered with TelecomManager"
            )
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register PhoneAccount", e)
            EngineDebugLog(context).append(
                "DIALER_PHONE_ACCOUNT_REGISTERED",
                "FAILED: ${e.message}",
                level = "error"
            )
            false
        }
    }

    /**
     * Returns true if this app is currently the system default dialer.
     * Also caches the result in PhoneAccountPrefs.wasDefaultDialer.
     */
    fun isDefaultDialer(context: Context): Boolean {
        return try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            val result = telecom?.defaultDialerPackage == context.packageName
            PhoneAccountPrefs(context).wasDefaultDialer = result
            result
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
     * Places an outgoing call via TelecomManager.placeCall() using our
     * self-managed PhoneAccountHandle. Requires CALL_PHONE (dangerous,
     * now in the required-permissions set) and MANAGE_OWN_CALLS (normal).
     *
     * The call is handed to PypeConnectionService.onCreateOutgoingConnection(),
     * which creates a PypeConnection that fires CallMonitorService actions
     * for recording/CRM sync — no duplicate logic here.
     */
    fun placeCall(context: Context, number: String) {
        try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                ?: return.also { Log.e(TAG, "TelecomManager unavailable") }

            val uri = Uri.fromParts("tel", number, null)
            val extras = android.os.Bundle().apply {
                putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, phoneAccountHandle(context))
            }
            telecom.placeCall(uri, extras)
            EngineDebugLog(context).append(
                "DIALER_CALL_PLACED",
                "Outgoing call placed to ${number.take(4)}*** via TelecomManager"
            )
        } catch (e: SecurityException) {
            Log.e(TAG, "CALL_PHONE permission missing", e)
            EngineDebugLog(context).append(
                "DIALER_CALL_PLACED",
                "FAILED — missing CALL_PHONE: ${e.message}",
                level = "error"
            )
        } catch (e: Exception) {
            Log.e(TAG, "placeCall failed", e)
            EngineDebugLog(context).append("DIALER_CALL_PLACED", "FAILED: ${e.message}", level = "error")
        }
    }
}
