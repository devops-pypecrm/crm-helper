package com.pypecrm.call_recording_engine.telecom

import android.content.Context

/**
 * The Dialer-role state machine (`IDLE → OUTGOING_CALL_STARTED → … →
 * CALL_ENDED`) plus the debug-screen checklist booleans and the five-way
 * outcome classification (A-E, see [ConferenceOrchestrator]) — all
 * SharedPreferences-backed, same pattern as the existing `CallStatePrefs`,
 * so a process death mid-call (this service can be killed like any other)
 * doesn't corrupt what the debug screen shows on next read.
 */
class CallStateMachine(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var state: String
        get() = prefs.getString(KEY_STATE, State.IDLE) ?: State.IDLE
        set(value) = prefs.edit().putString(KEY_STATE, value).apply()

    var customerCallStarted: Boolean
        get() = prefs.getBoolean(KEY_CUSTOMER_STARTED, false)
        set(value) = prefs.edit().putBoolean(KEY_CUSTOMER_STARTED, value).apply()

    var customerCallActive: Boolean
        get() = prefs.getBoolean(KEY_CUSTOMER_ACTIVE, false)
        set(value) = prefs.edit().putBoolean(KEY_CUSTOMER_ACTIVE, value).apply()

    var recorderCallStarted: Boolean
        get() = prefs.getBoolean(KEY_RECORDER_STARTED, false)
        set(value) = prefs.edit().putBoolean(KEY_RECORDER_STARTED, value).apply()

    var recorderCallActive: Boolean
        get() = prefs.getBoolean(KEY_RECORDER_ACTIVE, false)
        set(value) = prefs.edit().putBoolean(KEY_RECORDER_ACTIVE, value).apply()

    var conferenceCapabilityPresent: Boolean
        get() = prefs.getBoolean(KEY_CONFERENCE_CAPABILITY, false)
        set(value) = prefs.edit().putBoolean(KEY_CONFERENCE_CAPABILITY, value).apply()

    var conferenceRequested: Boolean
        get() = prefs.getBoolean(KEY_CONFERENCE_REQUESTED, false)
        set(value) = prefs.edit().putBoolean(KEY_CONFERENCE_REQUESTED, value).apply()

    var conferenceCreated: Boolean
        get() = prefs.getBoolean(KEY_CONFERENCE_CREATED, false)
        set(value) = prefs.edit().putBoolean(KEY_CONFERENCE_CREATED, value).apply()

    var threeWayCallActive: Boolean
        get() = prefs.getBoolean(KEY_THREE_WAY_ACTIVE, false)
        set(value) = prefs.edit().putBoolean(KEY_THREE_WAY_ACTIVE, value).apply()

    var recorderAudioCreated: Boolean
        get() = prefs.getBoolean(KEY_RECORDER_AUDIO_CREATED, false)
        set(value) = prefs.edit().putBoolean(KEY_RECORDER_AUDIO_CREATED, value).apply()

    var recorderDurationSeconds: Int
        get() = prefs.getInt(KEY_RECORDER_DURATION, 0)
        set(value) = prefs.edit().putInt(KEY_RECORDER_DURATION, value).apply()

    var recorderFilePath: String?
        get() = prefs.getString(KEY_RECORDER_FILE_PATH, null)
        set(value) = prefs.edit().putString(KEY_RECORDER_FILE_PATH, value).apply()

    /** One of [Outcome]'s values, or null before a call has run to
     * completion — the thing that actually answers Milestone 1's question,
     * never inferred, only ever set once real observable Telecom state
     * justifies it (see `ConferenceOrchestrator`). */
    var outcome: String?
        get() = prefs.getString(KEY_OUTCOME, null)
        set(value) = prefs.edit().putString(KEY_OUTCOME, value).apply()

    fun reset() {
        prefs.edit().clear().apply()
    }

    fun snapshot(): Map<String, Any?> = mapOf(
        "state" to state,
        "customerCallStarted" to customerCallStarted,
        "customerCallActive" to customerCallActive,
        "recorderCallStarted" to recorderCallStarted,
        "recorderCallActive" to recorderCallActive,
        "conferenceCapabilityPresent" to conferenceCapabilityPresent,
        "conferenceRequested" to conferenceRequested,
        "conferenceCreated" to conferenceCreated,
        "threeWayCallActive" to threeWayCallActive,
        "recorderAudioCreated" to recorderAudioCreated,
        "recorderDurationSeconds" to recorderDurationSeconds,
        "recorderFilePath" to recorderFilePath,
        "outcome" to outcome,
    )

    object State {
        const val IDLE = "IDLE"
        const val OUTGOING_CALL_STARTED = "OUTGOING_CALL_STARTED"
        const val CUSTOMER_RINGING = "CUSTOMER_RINGING"
        const val CUSTOMER_CONNECTED = "CUSTOMER_CONNECTED"
        const val START_RECORDING_CALL = "START_RECORDING_CALL"
        const val RECORDING_CALL_RINGING = "RECORDING_CALL_RINGING"
        const val RECORDING_CALL_CONNECTED = "RECORDING_CALL_CONNECTED"
        const val MERGING_CALLS = "MERGING_CALLS"
        const val CONFERENCE_ACTIVE = "CONFERENCE_ACTIVE"
        const val MERGE_FAILED = "MERGE_FAILED"
        const val CALL_ACTIVE = "CALL_ACTIVE"
        const val CALL_ENDED = "CALL_ENDED"
    }

    /** The five outcomes the POC must distinguish — see
     * `ConferenceOrchestrator`'s doc comment for exactly what each means. */
    object Outcome {
        const val API_UNAVAILABLE = "PROGRAMMATIC_CONFERENCE_API_UNAVAILABLE"
        const val REJECTED = "CONFERENCE_REJECTED"
        const val CREATED = "CONFERENCE_CREATED"
        const val NO_RECORDER_AUDIO = "CONFERENCE_NO_RECORDER_AUDIO"
        const val FULL_SUCCESS = "FULL_SUCCESS"
    }

    companion object {
        private const val PREFS_NAME = "call_recording_engine_poc_state"
        private const val KEY_STATE = "state"
        private const val KEY_CUSTOMER_STARTED = "customer_call_started"
        private const val KEY_CUSTOMER_ACTIVE = "customer_call_active"
        private const val KEY_RECORDER_STARTED = "recorder_call_started"
        private const val KEY_RECORDER_ACTIVE = "recorder_call_active"
        private const val KEY_CONFERENCE_CAPABILITY = "conference_capability"
        private const val KEY_CONFERENCE_REQUESTED = "conference_requested"
        private const val KEY_CONFERENCE_CREATED = "conference_created"
        private const val KEY_THREE_WAY_ACTIVE = "three_way_active"
        private const val KEY_RECORDER_AUDIO_CREATED = "recorder_audio_created"
        private const val KEY_RECORDER_DURATION = "recorder_duration_seconds"
        private const val KEY_RECORDER_FILE_PATH = "recorder_file_path"
        private const val KEY_OUTCOME = "outcome"
    }
}
