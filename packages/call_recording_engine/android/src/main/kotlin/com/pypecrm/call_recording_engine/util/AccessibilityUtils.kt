package com.pypecrm.call_recording_engine.util

import android.content.Context
import android.provider.Settings
import android.text.TextUtils
import com.pypecrm.call_recording_engine.accessibility.CallRecordingAccessibilityService

object AccessibilityUtils {
    /**
     * Whether the user has enabled [CallRecordingAccessibilityService] in
     * system Settings > Accessibility. Its mere presence — not any actual
     * event handling — is what unlocks `MediaRecorder.AudioSource.VOICE_RECOGNITION`
     * as a usable in-call audio source on many Android versions (Tier 2;
     * see CallAudioRecorder).
     */
    fun isCallRecordingServiceEnabled(context: Context): Boolean {
        val expectedComponent = "${context.packageName}/" +
            "${CallRecordingAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        if (TextUtils.isEmpty(enabledServices)) return false
        return enabledServices!!.split(':').any { it.equals(expectedComponent, ignoreCase = true) }
    }
}
