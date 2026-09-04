package com.pypecrm.call_recording_engine.dialer

import android.content.Intent
import android.telecom.Call
import android.telecom.InCallService
import android.util.Log
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.service.CallMonitorService

/**
 * The real integration point for becoming the default Phone app. An
 * InCallService (not a self-managed ConnectionService — see this package's
 * earlier PypeConnection/PypeConnectionService, removed, whose doc comments
 * explain why that approach could never place or represent a real SIM call)
 * receives the actual [Call] objects the system's own telephony
 * ConnectionService creates — for both calls WE place (via
 * TelecomManager.placeCall()/ACTION_CALL, once we're the default dialer)
 * and calls placed TO this device. There is nothing else to "connect" —
 * the SIM/radio call already exists; this service just gets told about it
 * and can observe/control it (mute, hold, end) via the Call object itself.
 *
 * State changes are mirrored into [CallMonitorService] (so the existing
 * Tier 0-4 recording/CRM-sync pipeline runs unchanged for dialer-originated
 * calls) and pushed to Flutter via [CallEventBridge]'s EventChannel for the
 * in-app dialer/in-call UI.
 */
class PypeInCallService : InCallService() {

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        Log.d(TAG, "onCallAdded: state=${call.state}")
        CallEventBridge.service = this
        CallEventBridge.attach(call)
        call.registerCallback(callback)
        // Fire immediately for the call's initial state too (e.g. RINGING
        // for an already-ringing incoming call added while Flutter wasn't
        // listening yet).
        handleStateChanged(call, call.state)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callback)
        CallEventBridge.detach(call)
    }

    private val callback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            handleStateChanged(call, state)
        }
    }

    private fun handleStateChanged(call: Call, state: Int) {
        val number = call.details?.handle?.schemeSpecificPart ?: ""
        val isOutgoing = call.details?.callDirection == Call.Details.DIRECTION_OUTGOING
        val stateLabel = stateLabel(state)
        Log.d(TAG, "state=$stateLabel number=${number.take(4)}*** outgoing=$isOutgoing")

        CallEventBridge.emit(
            mapOf(
                "state" to stateLabel,
                "number" to number,
                "isOutgoing" to isOutgoing,
            )
        )

        when (state) {
            Call.STATE_RINGING -> notifyCallMonitor(CallMonitorService.ACTION_CALL_RINGING, number, isOutgoing)
            Call.STATE_ACTIVE -> notifyCallMonitor(CallMonitorService.ACTION_CALL_ACTIVE, number, isOutgoing)
            Call.STATE_DISCONNECTED -> {
                notifyCallMonitor(CallMonitorService.ACTION_CALL_ENDED, number, isOutgoing)
                EngineDebugLog(applicationContext).append(
                    "DIALER_CALL_ENDED",
                    "Call ${if (isOutgoing) "to" else "from"} ${number.take(4)}*** ended",
                )
            }
        }
    }

    private fun notifyCallMonitor(action: String, number: String, isOutgoing: Boolean) {
        if (!EngineStats(applicationContext).monitoringEnabled) return
        try {
            startForegroundService(
                Intent(applicationContext, CallMonitorService::class.java).apply {
                    this.action = action
                    putExtra(CallMonitorService.EXTRA_CALLED_FROM_DIALER, true)
                    putExtra(CallMonitorService.EXTRA_PHONE_NUMBER, number)
                    putExtra(CallMonitorService.EXTRA_IS_OUTGOING, isOutgoing)
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to notify CallMonitorService for action=$action", e)
        }
    }

    private fun stateLabel(state: Int): String = when (state) {
        Call.STATE_NEW -> "NEW"
        Call.STATE_DIALING -> "DIALING"
        Call.STATE_RINGING -> "RINGING"
        Call.STATE_HOLDING -> "HOLDING"
        Call.STATE_ACTIVE -> "ACTIVE"
        Call.STATE_DISCONNECTED -> "DISCONNECTED"
        Call.STATE_CONNECTING -> "CONNECTING"
        Call.STATE_DISCONNECTING -> "DISCONNECTING"
        else -> "UNKNOWN($state)"
    }

    companion object {
        private const val TAG = "PypeInCallService"
    }
}
