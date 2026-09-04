package com.pypecrm.call_recording_engine.service

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telecom.Connection
import android.telecom.DisconnectCause
import android.util.Log
import com.pypecrm.call_recording_engine.data.CallStatePrefs
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.debug.EngineDebugLog

/**
 * A single call managed by PypeConnectionService. Extends android.telecom.Connection
 * so Android Telecom gets authoritative call-state from us (instead of us
 * reverse-engineering it from TelephonyManager broadcasts).
 *
 * Lifecycle mapping to CallMonitorService:
 *   RINGING  → ACTION_CALL_RINGING  (incoming only)
 *   ACTIVE   → ACTION_CALL_ACTIVE
 *   ENDED    → ACTION_CALL_ENDED    (with calledFromDialer=true so CallMonitorService
 *                                    can skip CallLogLookup — number/direction are
 *                                    already authoritative here)
 *
 * The audio-capture / CRM-sync machinery in CallMonitorService is unchanged —
 * this class is only the "source of truth" trigger layer that replaces the
 * CallStateReceiver broadcast path for dialer-originated calls.
 */
class PypeConnection(
    private val appContext: Context,
    val phoneNumber: String,
    val isOutgoing: Boolean,
) : Connection() {

    private val debugLog = EngineDebugLog(appContext)

    init {
        // Set audio properties for a voice call
        audioModeIsVoip = false
        connectionCapabilities = CAPABILITY_MUTE or CAPABILITY_SUPPORT_HOLD or CAPABILITY_HOLD
    }

    override fun onStateChanged(state: Int) {
        super.onStateChanged(state)
        val stateLabel = when (state) {
            STATE_RINGING -> "RINGING"
            STATE_DIALING -> "DIALING"
            STATE_ACTIVE -> "ACTIVE"
            STATE_HOLDING -> "HOLDING"
            STATE_DISCONNECTED -> "DISCONNECTED"
            STATE_INITIALIZING -> "INITIALIZING"
            STATE_NEW -> "NEW"
            else -> "UNKNOWN($state)"
        }
        Log.d(TAG, "onStateChanged: $stateLabel, number=${phoneNumber.take(4)}***, outgoing=$isOutgoing")

        when (state) {
            STATE_RINGING -> {
                // Incoming call just arrived — mirror to CallMonitorService.
                // Only reachable for incoming calls (outgoing never enters RINGING).
                debugLog.append("DIALER_CALL_RINGING", "Incoming call from ${phoneNumber.take(4)}***")
                val callStatePrefs = CallStatePrefs(appContext)
                if (!callStatePrefs.isCallActive) {
                    callStatePrefs.isCallActive = true
                    callStatePrefs.callStartTimeMillis = System.currentTimeMillis()
                    callStatePrefs.likelyOutgoing = false
                    callStatePrefs.expectedNumber = phoneNumber
                }
                startMonitorService(CallMonitorService.ACTION_CALL_RINGING, false)
            }
            STATE_ACTIVE -> {
                // Call audio is flowing (incoming answered or outgoing connected).
                debugLog.append(
                    "DIALER_CALL_ANSWERED",
                    if (isOutgoing) "Outgoing call connected to ${phoneNumber.take(4)}***"
                    else "Incoming call answered from ${phoneNumber.take(4)}***"
                )
                val callStatePrefs = CallStatePrefs(appContext)
                if (!callStatePrefs.isCallActive) {
                    callStatePrefs.isCallActive = true
                    callStatePrefs.callStartTimeMillis = System.currentTimeMillis()
                }
                callStatePrefs.likelyOutgoing = isOutgoing
                callStatePrefs.expectedNumber = phoneNumber
                startMonitorService(CallMonitorService.ACTION_CALL_ACTIVE, false)
            }
        }
    }

    override fun onDisconnect() {
        val durationSecs = (System.currentTimeMillis() - CallStatePrefs(appContext).callStartTimeMillis) / 1000
        debugLog.append(
            "DIALER_CALL_ENDED",
            "Call to/from ${phoneNumber.take(4)}*** ended, duration=${durationSecs}s"
        )

        // Mark call ended in prefs before signalling the service so it reads
        // the correct state when ACTION_CALL_ENDED arrives.
        val callStatePrefs = CallStatePrefs(appContext)
        callStatePrefs.isCallActive = false
        callStatePrefs.likelyOutgoing = isOutgoing
        callStatePrefs.expectedNumber = phoneNumber

        // calledFromDialer=true so CallMonitorService.handleCallEnded() can
        // skip CallLogLookup (we already have authoritative number + direction).
        startMonitorService(CallMonitorService.ACTION_CALL_ENDED, true)

        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        destroy()
    }

    override fun onAbort() {
        onDisconnect()
    }

    override fun onReject() {
        debugLog.append(
            "DIALER_CALL_REJECTED",
            "Incoming call from ${phoneNumber.take(4)}*** rejected"
        )
        CallStatePrefs(appContext).isCallActive = false
        setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
        destroy()
    }

    override fun onHold() {
        setOnHold()
    }

    override fun onUnhold() {
        setActive()
    }

    private fun startMonitorService(action: String, calledFromDialer: Boolean) {
        if (!EngineStats(appContext).monitoringEnabled) return
        try {
            appContext.startForegroundService(
                Intent(appContext, CallMonitorService::class.java).apply {
                    this.action = action
                    putExtra(CallMonitorService.EXTRA_CALLED_FROM_DIALER, calledFromDialer)
                    putExtra(CallMonitorService.EXTRA_PHONE_NUMBER, phoneNumber)
                    putExtra(CallMonitorService.EXTRA_IS_OUTGOING, isOutgoing)
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start CallMonitorService action=$action", e)
        }
    }

    companion object {
        private const val TAG = "PypeConnection"
    }
}
