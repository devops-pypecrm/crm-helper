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
)
