package com.pypecrm.call_recording_engine.service

import android.net.Uri
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log
import com.pypecrm.call_recording_engine.debug.EngineDebugLog

/**
 * The Android Telecom ConnectionService implementation for PypeCRM Helper's
 * self-managed PhoneAccount. Registered in the plugin's AndroidManifest with
 * android.permission.BIND_TELECOM_CONNECTION_SERVICE so only the OS can bind.
 *
 * This is the authoritative source of call state for dialer-originated calls,
 * replacing the TelephonyManager broadcast path (CallStateReceiver) for calls
 * made through this app. CallStateReceiver is kept alive as a reconciliation
 * backstop for calls that happened outside this app or before it was the
 * default dialer.
 *
 * Self-managed means:
 *   - We handle our own in-call UI (DialerScreen / InCallScreen in Flutter)
 *   - No InCallService needed
 *   - Emergency calls are still routed by the OS, unaffected by our implementation
 *   - CAPABILITY_SELF_MANAGED connections don't appear in Android's system call log;
 *     we write our own records via CallEventDbHelper (as we've always done)
 *
 * Each call becomes a PypeConnection which mirrors state changes into
 * CallMonitorService (and through it, into the existing Tier 0-4
 * recording/CRM-sync machinery), so no sync logic lives here directly.
 */
class PypeConnectionService : ConnectionService() {

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest,
    ): Connection {
        val number = extractNumber(request.address)
        Log.d(TAG, "onCreateIncomingConnection: number=${number.take(4)}***")
        EngineDebugLog(applicationContext).append(
            "DIALER_INCOMING_CONNECTION",
            "Incoming connection created from ${number.take(4)}***"
        )
        return PypeConnection(applicationContext, number, isOutgoing = false).apply {
            setRinging()
        }
    }

    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest,
    ): Connection {
        val number = extractNumber(request.address)
        Log.d(TAG, "onCreateOutgoingConnection: number=${number.take(4)}***")
        EngineDebugLog(applicationContext).append(
            "DIALER_OUTGOING_CONNECTION",
            "Outgoing connection created to ${number.take(4)}***"
        )
        return PypeConnection(applicationContext, number, isOutgoing = true).apply {
            setDialing()
        }
    }

    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest,
    ) {
        Log.e(TAG, "onCreateIncomingConnectionFailed — address=${request.address}")
        EngineDebugLog(applicationContext).append(
            "DIALER_INCOMING_CONNECTION",
            "FAILED to create incoming connection",
            level = "error"
        )
    }

    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest,
    ) {
        Log.e(TAG, "onCreateOutgoingConnectionFailed — address=${request.address}")
        EngineDebugLog(applicationContext).append(
            "DIALER_OUTGOING_CONNECTION",
            "FAILED to create outgoing connection",
            level = "error"
        )
    }

    private fun extractNumber(address: Uri?): String =
        address?.schemeSpecificPart?.trimStart('+') ?: ""

    companion object {
        private const val TAG = "PypeConnectionService"
    }
}
