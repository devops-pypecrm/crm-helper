package com.pypecrm.call_recording_engine.telecom

import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.telecom.Call
import android.telecom.TelecomManager
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Milestone 1's actual experiment. Owned by [PypeInCallService] for the
 * Dialer role only. Sequence, exactly as specified in the approved plan:
 *
 *  1. Customer call is placed by the caller of [onCustomerCallActive] once
 *     it reaches `STATE_ACTIVE` (placement itself happens in
 *     [PypeInCallService] via `TelecomManager.placeCall`).
 *  2. This class places the recorder-leg call, on the SAME `PhoneAccountHandle`
 *     as the customer call — dual-SIM phones generally can't conference two
 *     calls placed on different SIMs, so pinning both to one account from
 *     the start is a real, not cosmetic, choice.
 *  3. Once the recorder call also reaches `STATE_ACTIVE`, captures and logs
 *     the COMPLETE observable Telecom state of both calls — capabilities
 *     bitmask, properties, account handle, conferenceable calls — before
 *     attempting anything.
 *  4. Determines from that state whether a valid operation is actually
 *     exposed (`CAPABILITY_MERGE_CONFERENCE` present AND the other call
 *     present in `conferenceableCalls`). If not: **stop cleanly**, outcome
 *     A — never force an unexposed/undocumented call.
 *  5. If exposed, calls `customerCall.conference(recorderCall)` — the
 *     documented public API for merging one `Call` into another.
 *  6. Polls for up to [MERGE_OBSERVE_TIMEOUT_MS] for the only thing that
 *     actually proves success: a new `Call` with `PROPERTY_CONFERENCE`
 *     appearing, with BOTH the customer and recorder calls reporting it as
 *     their parent. Never inferred from the call not throwing.
 *
 * Outcomes (never collapsed into a single "merge failed" — see
 * [CallStateMachine.Outcome]): A (no operation exposed), B (exposed but
 * rejected/no conference appears), C (conference created — link proven,
 * audio not yet assessed), D (C is true but recorder audio is silent/
 * one-sided), E (full success — both test phrases audible on manual
 * review). This class can only ever produce A/B/C; D/E are decided by
 * [PypeInCallService] after listening to the recorder's file, which is a
 * human judgment call this code cannot make.
 */
class ConferenceOrchestrator(
    private val context: Context,
    private val debugLog: CallDebugLog,
    private val stateMachine: CallStateMachine,
    private val pocConfig: PocConfig,
) {
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    private var recorderCall: Call? = null

    private val recorderCallCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            debugLog.append("RECORDING_CALL_STATE_CHANGED", "state=${stateName(state)}")
            when (state) {
                Call.STATE_RINGING, Call.STATE_DIALING, Call.STATE_CONNECTING ->
                    stateMachine.state = CallStateMachine.State.RECORDING_CALL_RINGING
                Call.STATE_ACTIVE -> onRecorderCallActive(call)
                Call.STATE_DISCONNECTED ->
                    debugLog.append("RECORDING_CALL_DISCONNECTED", "")
            }
        }
    }

    /** Called by [PypeInCallService] once the customer call it placed
     * reaches `STATE_ACTIVE` for the first time. */
    fun onCustomerCallActive(customerCall: Call) {
        customerCallRef = customerCall
        stateMachine.customerCallActive = true
        stateMachine.state = CallStateMachine.State.CUSTOMER_CONNECTED
        debugLog.append("CUSTOMER_CALL_ACTIVE", "")

        val recorderNumber = pocConfig.recordingNumber
        if (recorderNumber.isNullOrBlank()) {
            debugLog.append("RECORDING_CALL_SKIPPED", "no recorder number configured")
            return
        }

        stateMachine.state = CallStateMachine.State.START_RECORDING_CALL
        debugLog.append("RECORDING_CALL_STARTED", "number=$recorderNumber")
        stateMachine.recorderCallStarted = true

        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val extras = Bundle().apply {
            // Same SIM/account as the customer call — see class doc comment.
            customerCall.details.accountHandle?.let {
                putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, it)
            }
        }
        try {
            telecomManager.placeCall(Uri.fromParts("tel", recorderNumber, null), extras)
        } catch (e: Exception) {
            debugLog.append("RECORDING_CALL_PLACE_FAILED", e.message ?: e.toString())
        }
    }

    /** Called by [PypeInCallService] when the SECOND call it observes
     * being added is the recorder-leg call it just placed. */
    fun onRecorderCallAdded(call: Call) {
        recorderCall = call
        call.registerCallback(recorderCallCallback)
        // In case it's already active by the time we register (unlikely,
        // but the callback only fires on future transitions).
        if (call.state == Call.STATE_ACTIVE) onRecorderCallActive(call)
    }

    private fun onRecorderCallActive(call: Call) {
        if (stateMachine.recorderCallActive) return // already handled
        stateMachine.recorderCallActive = true
        stateMachine.state = CallStateMachine.State.RECORDING_CALL_CONNECTED
        debugLog.append("RECORDING_CALL_ACTIVE", "")

        val customer = customerCallRef ?: return
        scope.launch {
            // Let Telecom-reported metadata settle before trusting it —
            // capability/conferenceable-calls fields can lag a moment
            // behind the state transition itself.
            delay(STATE_SETTLE_DELAY_MS)
            attemptConference(customer, call)
        }
    }

    // Set by PypeInCallService right after placing the customer call —
    // kept here rather than threading it through every callback signature.
    var customerCallRef: Call? = null

    private suspend fun attemptConference(customerCall: Call, recorderCall: Call) {
        logCallState("CUSTOMER", customerCall)
        logCallState("RECORDER", recorderCall)

        val customerCapabilities = customerCall.details.callCapabilities
        val recorderConferenceable = customerCall.conferenceableCalls.contains(recorderCall)
        val capabilityPresent = (customerCapabilities and Call.Details.CAPABILITY_MERGE_CONFERENCE) != 0
        stateMachine.conferenceCapabilityPresent = capabilityPresent
        debugLog.append(
            "CONFERENCE_CAPABILITY_CHECK",
            "capabilityPresent=$capabilityPresent conferenceable=$recorderConferenceable",
        )

        if (!capabilityPresent || !recorderConferenceable) {
            stateMachine.outcome = CallStateMachine.Outcome.API_UNAVAILABLE
            stateMachine.state = CallStateMachine.State.MERGE_FAILED
            debugLog.append("OUTCOME_A_API_UNAVAILABLE", "no valid exposed conference operation for these two calls")
            return
        }

        stateMachine.conferenceRequested = true
        stateMachine.state = CallStateMachine.State.MERGING_CALLS
        debugLog.append("CONFERENCE_MERGE_REQUESTED", "")

        val requestThrew = try {
            customerCall.conference(recorderCall)
            false
        } catch (e: Exception) {
            debugLog.append("CONFERENCE_MERGE_THREW", e.message ?: e.toString())
            true
        }

        if (requestThrew) {
            stateMachine.outcome = CallStateMachine.Outcome.REJECTED
            stateMachine.state = CallStateMachine.State.MERGE_FAILED
            debugLog.append("OUTCOME_B_CONFERENCE_REJECTED", "conference() threw")
            return
        }

        val merged = awaitConferenceObserved(customerCall, recorderCall)
        if (!merged) {
            stateMachine.outcome = CallStateMachine.Outcome.REJECTED
            stateMachine.state = CallStateMachine.State.MERGE_FAILED
            debugLog.append(
                "OUTCOME_B_CONFERENCE_REJECTED",
                "conference() did not throw but no properly-parented Conference appeared within ${MERGE_OBSERVE_TIMEOUT_MS}ms",
            )
            return
        }

        stateMachine.conferenceCreated = true
        stateMachine.threeWayCallActive = true
        stateMachine.outcome = CallStateMachine.Outcome.CREATED
        stateMachine.state = CallStateMachine.State.CONFERENCE_ACTIVE
        debugLog.append("CONFERENCE_MERGE_SUCCESS", "")
        debugLog.append("THREE_WAY_CALL_ACTIVE", "")
    }

    /** Polls for the only real proof of a merge: a `Call` with
     * `PROPERTY_CONFERENCE` whose parent both the customer and recorder
     * calls report via `getParent()`. */
    private suspend fun awaitConferenceObserved(customerCall: Call, recorderCall: Call): Boolean {
        val deadline = System.currentTimeMillis() + MERGE_OBSERVE_TIMEOUT_MS
        while (System.currentTimeMillis() < deadline) {
            val customerParent = customerCall.parent
            val recorderParent = recorderCall.parent
            if (customerParent != null &&
                recorderParent != null &&
                customerParent == recorderParent &&
                customerParent.details.hasProperty(Call.Details.PROPERTY_CONFERENCE)
            ) {
                return true
            }
            delay(POLL_INTERVAL_MS)
        }
        return false
    }

    private fun logCallState(label: String, call: Call) {
        val d = call.details
        debugLog.append(
            "${label}_PRE_MERGE_STATE",
            "state=${stateName(call.state)} " +
                "capabilities=${d.callCapabilities} " +
                "properties=${d.callProperties} " +
                "account=${d.accountHandle} " +
                "conferenceable=${call.conferenceableCalls.size} " +
                "parent=${call.parent}",
        )
    }

    private fun stateName(state: Int): String = when (state) {
        Call.STATE_NEW -> "NEW"
        Call.STATE_DIALING -> "DIALING"
        Call.STATE_RINGING -> "RINGING"
        Call.STATE_HOLDING -> "HOLDING"
        Call.STATE_ACTIVE -> "ACTIVE"
        Call.STATE_DISCONNECTED -> "DISCONNECTED"
        Call.STATE_CONNECTING -> "CONNECTING"
        Call.STATE_DISCONNECTING -> "DISCONNECTING"
        Call.STATE_SELECT_PHONE_ACCOUNT -> "SELECT_PHONE_ACCOUNT"
        else -> "UNKNOWN($state)"
    }

    companion object {
        private const val TAG = "ConferenceOrchestrator"
        private const val STATE_SETTLE_DELAY_MS = 1500L
        private const val MERGE_OBSERVE_TIMEOUT_MS = 5000L
        private const val POLL_INTERVAL_MS = 250L
    }
}
