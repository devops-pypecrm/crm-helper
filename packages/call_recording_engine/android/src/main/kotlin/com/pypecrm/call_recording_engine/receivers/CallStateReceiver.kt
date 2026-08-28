package com.pypecrm.call_recording_engine.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log
import com.pypecrm.call_recording_engine.data.CallStatePrefs
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.service.CallMonitorService

/**
 * Adapted from Dad-frontend's CallStateReceiver.kt with one deliberate
 * removal: NEW_OUTGOING_CALL handling. That broadcast (and the
 * PROCESS_OUTGOING_CALLS permission it needs) is a no-op on Android 10+ for
 * any app that isn't the default dialer, so it bought nothing but a stale
 * permission grant — dropping it is also why Phase 1's manifest doesn't
 * declare that permission at all. Direction and the outgoing number are
 * instead resolved authoritatively from the system CallLog once the call
 * ends (see [CallLogLookup], used by [CallMonitorService]) — this receiver's
 * only job is noticing that a call started or ended and handing off to the
 * service, which stays running independently of both this receiver and the
 * Flutter engine.
 */
class CallStateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        if (!EngineStats(appContext).monitoringEnabled) return

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, "android.intent.action.QUICKBOOT_POWERON" ->
                // A reboot kills the foreground service; restart it so the
                // "waiting for calls" monitoring resumes immediately rather
                // than waiting for the first call after reboot.
                startMonitorService(appContext, CallMonitorService.ACTION_ENSURE_RUNNING)
            TelephonyManager.ACTION_PHONE_STATE_CHANGED -> handleStateChanged(appContext, intent)
        }
    }

    private fun handleStateChanged(context: Context, intent: Intent) {
        val callState = when (intent.getStringExtra(TelephonyManager.EXTRA_STATE)) {
            TelephonyManager.EXTRA_STATE_OFFHOOK -> TelephonyManager.CALL_STATE_OFFHOOK
            TelephonyManager.EXTRA_STATE_RINGING -> TelephonyManager.CALL_STATE_RINGING
            else -> TelephonyManager.CALL_STATE_IDLE
        }

        val callStatePrefs = CallStatePrefs(context)
        val previousState = callStatePrefs.lastPhoneState
        if (previousState == callState) return
        callStatePrefs.lastPhoneState = callState

        // Reliable for incoming calls only (EXTRA_INCOMING_NUMBER is never
        // populated for outgoing ones) — captured whenever present, used as
        // a CallLogLookup matching hint, not a hard requirement.
        intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)?.let {
            callStatePrefs.expectedNumber = it
        }

        when (callState) {
            TelephonyManager.CALL_STATE_RINGING -> {
                // Ringing never starts Tier 1 recording — there's no call
                // audio yet, only a ring. RINGING is also the one state
                // that only ever happens for an incoming call, which is
                // what makes [CallStatePrefs.likelyOutgoing] a reliable
                // signal below.
                if (callStatePrefs.isCallActive) return
                callStatePrefs.isCallActive = true
                callStatePrefs.callStartTimeMillis = System.currentTimeMillis()
                startMonitorService(context, CallMonitorService.ACTION_CALL_RINGING)
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                // Real call audio starts flowing now — this is what starts
                // Tier 1 recording. Reachable either from RINGING (answered
                // incoming call) or directly from IDLE (outgoing call).
                if (!callStatePrefs.isCallActive) {
                    callStatePrefs.isCallActive = true
                    callStatePrefs.callStartTimeMillis = System.currentTimeMillis()
                }
                callStatePrefs.likelyOutgoing = previousState != TelephonyManager.CALL_STATE_RINGING
                startMonitorService(context, CallMonitorService.ACTION_CALL_ACTIVE)
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                if (!callStatePrefs.isCallActive) return
                callStatePrefs.isCallActive = false
                startMonitorService(context, CallMonitorService.ACTION_CALL_ENDED)
                // Cleared only after the service reads it during call-end
                // processing — not here, since CallMonitorService.handleCallEnded
                // runs asynchronously and needs it a moment after this returns.
            }
        }
    }

    private fun startMonitorService(context: Context, action: String) {
        val serviceIntent = Intent(context, CallMonitorService::class.java).apply { this.action = action }
        try {
            context.startForegroundService(serviceIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start CallMonitorService for action=$action", e)
        }
    }

    companion object {
        private const val TAG = "CallStateReceiver"
    }
}
