package com.pypecrm.call_recording_engine.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Tier 2. Adapted near-verbatim from Dad-frontend's
 * CallRecordingAccessibilityService.kt — it deliberately does nothing with
 * accessibility events. Its only purpose is existing and being enabled by
 * the user in system Settings > Accessibility: that alone is what unlocks
 * `MediaRecorder.AudioSource.VOICE_RECOGNITION` as an in-call audio source
 * on many Android versions (see CallAudioRecorder, AccessibilityUtils).
 *
 * This is the one component in the whole app whose permission
 * (`BIND_ACCESSIBILITY_SERVICE`) Google Play explicitly polices against for
 * call recording — it must never exist in Dad-mobile, only in this
 * sideloaded helper app.
 */
class CallRecordingAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Intentionally empty — see class doc comment.
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "Accessibility service unbound")
        return super.onUnbind(intent)
    }

    companion object {
        private const val TAG = "CallRecordingA11yService"
    }
}
