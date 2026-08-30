package com.pypecrm.call_recording_engine.telecom

import android.telecom.Call
import android.telecom.InCallService
import com.pypecrm.call_recording_engine.recorder.CallAudioRecorder
import java.io.File

/**
 * Milestone 1's `InCallService`. Bound by the Telecom framework whenever
 * this app holds `ROLE_DIALER` and a call is in progress — this is the
 * component that makes the whole experiment possible, since programmatic
 * conference operations (`Call.conference()`) and answering
 * (`Call.answer()`) are only meaningfully available to whichever app is
 * bound here. Behavior is entirely gated by [PocConfig.role]; when no POC
 * role is selected this service still exists (declared in the manifest,
 * required for `ROLE_DIALER` eligibility at all) but does nothing.
 */
class PypeInCallService : InCallService() {
    private lateinit var pocConfig: PocConfig
    private lateinit var debugLog: CallDebugLog
    private lateinit var stateMachine: CallStateMachine
    private var orchestrator: ConferenceOrchestrator? = null

    // Dialer role: tracks which of the (at most two) calls we've seen is
    // which, since Telecom hands us plain Call objects with no built-in
    // "this is the one I placed second" marker.
    private var customerCall: Call? = null
    private var recorderLegCall: Call? = null

    // Recorder role: the live capture for whatever call is currently
    // connected, and the callback registered on it.
    private var recorderAudio: CallAudioRecorder? = null
    private var recorderAnsweredCall: Call? = null
    private var recorderCaptureStartedAtMillis: Long = 0L

    override fun onCreate() {
        super.onCreate()
        pocConfig = PocConfig(this)
        debugLog = CallDebugLog(this)
        stateMachine = CallStateMachine(this)
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        debugLog.append("CALL_ADDED", "state=${call.state}")
        when (pocConfig.role) {
            PocConfig.ROLE_DIALER -> handleDialerCallAdded(call)
            PocConfig.ROLE_RECORDER -> handleRecorderCallAdded(call)
        }
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        debugLog.append("CALL_REMOVED", "")
        when (pocConfig.role) {
            PocConfig.ROLE_DIALER -> {
                if (call == customerCall || call == recorderLegCall) {
                    stateMachine.state = CallStateMachine.State.CALL_ENDED
                    customerCall = null
                    recorderLegCall = null
                    orchestrator = null
                }
            }
            PocConfig.ROLE_RECORDER -> {
                if (call == recorderAnsweredCall) finalizeRecorderCapture()
            }
        }
    }

    // ---- Dialer role ----

    private fun handleDialerCallAdded(call: Call) {
        if (customerCall == null) {
            // First call this session — the one the POC screen just placed
            // to the customer number.
            customerCall = call
            stateMachine.customerCallStarted = true
            stateMachine.state = CallStateMachine.State.CUSTOMER_RINGING
            val orch = ConferenceOrchestrator(this, debugLog, stateMachine, pocConfig)
            orchestrator = orch
            call.registerCallback(object : Call.Callback() {
                override fun onStateChanged(c: Call, state: Int) {
                    debugLog.append("CUSTOMER_CALL_STATE_CHANGED", "state=$state")
                    if (state == Call.STATE_ACTIVE) orch.onCustomerCallActive(c)
                }
            })
            if (call.state == Call.STATE_ACTIVE) orch.onCustomerCallActive(call)
        } else if (recorderLegCall == null) {
            // Second call — the recorder leg ConferenceOrchestrator placed.
            recorderLegCall = call
            orchestrator?.onRecorderCallAdded(call)
        } else {
            debugLog.append("UNEXPECTED_CALL_ADDED", "already tracking 2 calls")
        }
    }

    // ---- Recorder role ----

    private fun handleRecorderCallAdded(call: Call) {
        recorderAnsweredCall = call
        stateMachine.recorderCallStarted = true
        call.registerCallback(object : Call.Callback() {
            override fun onStateChanged(c: Call, state: Int) {
                debugLog.append("RECORDER_ROLE_CALL_STATE_CHANGED", "state=$state")
                if (state == Call.STATE_ACTIVE) {
                    stateMachine.recorderCallActive = true
                    startRecorderCapture()
                }
            }
        })
        try {
            call.answer(0)
            debugLog.append("RECORDER_ROLE_CALL_ANSWERED", "")
        } catch (e: Exception) {
            debugLog.append("RECORDER_ROLE_ANSWER_FAILED", e.message ?: e.toString())
        }
    }

    private fun startRecorderCapture() {
        if (recorderAudio != null) return // already recording this call
        val recorder = CallAudioRecorder(this)
        val started = recorder.start()
        debugLog.append(if (started) "RECORDER_AUDIO_STARTED" else "RECORDER_AUDIO_START_FAILED", "")
        if (started) {
            recorderAudio = recorder
            recorderCaptureStartedAtMillis = System.currentTimeMillis()
        }
    }

    /** This is the Recorder phone's OWN view of what it just captured —
     * `recorderAudioCreated`/`recorderDurationSeconds`/`recorderFilePath`
     * on THIS device's [CallStateMachine] answer "did I actually save
     * something", distinct from the Dialer phone's own (separate device,
     * separate SharedPreferences) `recorderCallActive`, which only means
     * "the call leg to the recorder connected" — the two devices never
     * share state in Milestone 1, each shows only what it can observe. */
    private fun finalizeRecorderCapture() {
        recorderAnsweredCall = null
        val recorder = recorderAudio ?: return
        recorderAudio = null
        val durationSeconds = ((System.currentTimeMillis() - recorderCaptureStartedAtMillis) / 1000).toInt()
        val file = recorder.stop()
        if (file == null) {
            debugLog.append("RECORDER_AUDIO_SAVE_FAILED", "stop() returned no file")
            return
        }
        // Rename to a clearly Milestone-1-labeled filename so it's never
        // confused with the existing Tier 1 LOCAL_ACOUSTIC_FALLBACK output
        // this same CallAudioRecorder class produces during ordinary
        // Phase 1-4 operation — see the plan's explicit requirement to keep
        // these visually/on-disk distinct.
        val labeled = File(file.parentFile, "conference_recording_${System.currentTimeMillis()}.${file.extension}")
        val renamed = file.renameTo(labeled)
        val finalFile = if (renamed) labeled else file
        stateMachine.recorderAudioCreated = true
        stateMachine.recorderDurationSeconds = durationSeconds
        stateMachine.recorderFilePath = finalFile.absolutePath
        debugLog.append(
            "RECORDER_AUDIO_SAVED",
            "path=${finalFile.absolutePath} size=${finalFile.length()} durationSec=$durationSeconds",
        )
    }

    override fun onDestroy() {
        recorderAudio?.stop()?.delete()
        super.onDestroy()
    }
}
