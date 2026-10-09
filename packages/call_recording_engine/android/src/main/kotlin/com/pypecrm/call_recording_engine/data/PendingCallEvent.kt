package com.pypecrm.call_recording_engine.data

/**
 * One call's metadata — either a Tier 4 offline-queue row still waiting for
 * a batched `POST /api/android/bulk-sync`, or the in-memory payload for an
 * immediate Tier 0 `POST /api/android/recordings` upload (see
 * BackendApi). Both paths share this shape since the backend fields are
 * identical either way.
 */
data class PendingCallEvent(
    val id: Long = 0,
    val phoneNumber: String,
    val durationSeconds: Int,
    val callType: String,
    val timestampMillis: Long,
    val hardwareId: String?,
    val callSessionId: String?,
    /** Local copy of a recording whose real-time upload failed (offline,
     * server error) — retried by CallSyncRunner before the metadata-only
     * fallback, so a call made without connectivity still gets its audio
     * into the CRM instead of the file being deleted at call-end. */
    val recordingPath: String? = null,
)
