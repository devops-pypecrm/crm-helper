package com.pypecrm.call_recording_engine.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Tier 2. Adapted near-verbatim from Dad-frontend's
 * CallRecordingAccessibilityService.kt for its original purpose — it does
 * nothing with ordinary accessibility events. Its baseline job is existing
 * and being enabled by the user in system Settings > Accessibility: that
 * alone is what unlocks `MediaRecorder.AudioSource.VOICE_RECOGNITION` as an
 * in-call audio source on many Android versions (see CallAudioRecorder,
 * AccessibilityUtils).
 *
 * Also now the host for [SamsungAutoRecordAutomation]'s one-shot,
 * explicitly user-triggered UI automation (never run automatically on
 * every accessibility event) — see that class's doc comment for what it
 * does and why it needs real-device iteration to actually work.
 *
 * This is the one component in the whole app whose permission
 * (`BIND_ACCESSIBILITY_SERVICE`) Google Play explicitly polices against for
 * call recording — it must never exist in Dad-mobile, only in this
 * sideloaded helper app.
 */
class CallRecordingAccessibilityService : AccessibilityService() {

    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility service connected")
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Intentionally empty for ordinary events — see class doc comment.
        // SamsungAutoRecordAutomation drives its own navigation via polling
        // rootInActiveWindow rather than reacting to events here, since it
        // only ever runs for the few seconds of one explicit user-triggered
        // attempt.
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.d(TAG, "Accessibility service unbound")
        if (instance === this) instance = null
        return super.onUnbind(intent)
    }

    /** Explicitly user-triggered from the Dart "Advanced" setup screen —
     * never invoked automatically. Fire-and-forget: progress/outcome is
     * read back from [EngineDebugLog], not this call's return value, since
     * the automation itself takes several seconds and multiple screen
     * transitions. */
    fun attemptSamsungAutoRecordSetup() {
        scope.launch {
            SamsungAutoRecordAutomation.attempt(this@CallRecordingAccessibilityService, EngineDebugLog(applicationContext))
        }
    }

    companion object {
        private const val TAG = "CallRecordingA11yService"

        /** Null whenever the user hasn't enabled the service in system
         * Settings — callers (the plugin) must check for null rather than
         * assuming it's running. */
        var instance: CallRecordingAccessibilityService? = null
            private set
    }
}
