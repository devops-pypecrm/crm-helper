package com.pypecrm.call_recording_engine.recorder

import android.content.Context
import android.media.AudioManager
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import com.pypecrm.call_recording_engine.util.AccessibilityUtils
import java.io.File

/**
 * Tiers 1 and 2 — both are `MediaRecorder`, differing only in which audio
 * source is used, so they share one recorder class rather than being
 * separate tiers with separate files. Adapted from Dad-frontend's
 * AudioRecorderService/CallTrackerService — the tier the user has
 * explicitly flagged as unreliable in the old app, so treat every choice
 * here as something to re-validate on real devices, not as proven.
 *
 * Audio sources are tried in order at [start] time — MediaRecorder can only
 * use one source per instance, and a call's audio can't be re-recorded
 * after the fact, so unlike the Tier 0 vs Tier 4 choice (made after the
 * call, from data that still exists) this one has to be made live:
 *
 *  1. `VOICE_COMMUNICATION` (Tier 1, preferred — this is literally what the
 *     dialer itself uses).
 *  2. `VOICE_RECOGNITION` (Tier 2, only attempted if
 *     [AccessibilityUtils.isCallRecordingServiceEnabled] — some Android
 *     versions expose in-call audio to this source once an Accessibility
 *     Service is active, that they don't expose to `VOICE_COMMUNICATION`).
 *  3. Plain `MIC` (Tier 1 fallback) if both of the above throw on
 *     `prepare()`/`start()` — some OEMs restrict the specialized sources
 *     during an active call outright, which the old blueprint had no
 *     fallback for at all.
 *
 * [isLikelySilent] gives the caller an objective silence check (bytes per
 * second of claimed duration) instead of trusting "recording started
 * without throwing" as success — a call can "succeed" and still produce a
 * near-empty/silent file, the "succeeded but silent" failure mode
 * Dad-mobile/CALL_RECORDING_PLAN.md calls out for these tiers.
 */
class CallAudioRecorder(private val context: Context) {
    private var recorder: MediaRecorder? = null
    private var outputFile: File? = null
    private var previousAudioMode: Int = AudioManager.MODE_NORMAL
    private var previousSpeakerphoneOn: Boolean = false

    /** 1 or 2 depending on which audio source actually started — see class
     * doc comment. Set once [start] succeeds; cleared by [stop]. */
    var activeTier: Int? = null
        private set

    /** Which [MediaRecorder.AudioSource] constant actually started — same
     * lifecycle as [activeTier], just the underlying source rather than the
     * tier number, for diagnostics (VOICE_COMMUNICATION vs VOICE_RECOGNITION
     * vs plain MIC makes a real difference to what a "successful" recording
     * actually contains). */
    var activeAudioSource: Int? = null
        private set

    /** True only if `audioManager.isSpeakerphoneOn` read back as `true`
     * right after we set it — NOT just that the call didn't throw.
     * Confirmed real-world cause of "recording exists, correct duration,
     * but no audible far-end voice": on some Android builds (observed on a
     * stock/near-AOSP device) a non-default-dialer app's speakerphone
     * force is silently ignored by the platform's Telecom-managed audio
     * routing — the call to set it succeeds, MediaRecorder still produces
     * a normal-bitrate file, but there was never real acoustic coupling to
     * the far-end audio, so the recording is real but near-silent/ambient
     * only. Same lifecycle as [activeTier]. */
    var speakerphoneForceConfirmed: Boolean = false
        private set

    val isRecording: Boolean get() = recorder != null

    fun start(): Boolean {
        if (isRecording) return true
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        previousAudioMode = audioManager.mode
        previousSpeakerphoneOn = audioManager.isSpeakerphoneOn
        try {
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            audioManager.isSpeakerphoneOn = true
        } catch (e: Exception) {
            Log.w(TAG, "Failed to force speakerphone/communication mode", e)
        }
        // Read back rather than trust the setter not throwing — see
        // speakerphoneForceConfirmed's doc comment on why this matters.
        speakerphoneForceConfirmed = audioManager.isSpeakerphoneOn

        val file = File(context.cacheDir, "live_call_${System.currentTimeMillis()}.m4a")
        val attempts = buildList {
            add(1 to MediaRecorder.AudioSource.VOICE_COMMUNICATION)
            if (AccessibilityUtils.isCallRecordingServiceEnabled(context)) {
                add(2 to MediaRecorder.AudioSource.VOICE_RECOGNITION)
            }
            add(1 to MediaRecorder.AudioSource.MIC)
        }

        for ((tier, source) in attempts) {
            if (tryStart(file, source)) {
                activeTier = tier
                activeAudioSource = source
                outputFile = file
                return true
            }
        }
        restoreAudioState()
        return false
    }

    private fun tryStart(file: File, audioSource: Int): Boolean {
        @Suppress("DEPRECATION")
        val mr = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(context) else MediaRecorder()
        return try {
            mr.setAudioSource(audioSource)
            mr.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mr.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            mr.setAudioEncodingBitRate(96_000)
            mr.setAudioSamplingRate(44_100)
            mr.setOutputFile(file.absolutePath)
            mr.prepare()
            mr.start()
            recorder = mr
            true
        } catch (e: Exception) {
            Log.w(TAG, "MediaRecorder start failed (audioSource=$audioSource)", e)
            try {
                mr.release()
            } catch (_: Exception) {
            }
            false
        }
    }

    /** Stops recording and returns the file if one was produced — caller
     * (CallMonitorService) is responsible for validating it with
     * [isLikelySilent] before trusting it as a real result. Read
     * [activeTier]/[activeAudioSource]/[speakerphoneForceConfirmed] BEFORE
     * calling this — all cleared here. */
    fun stop(): File? {
        val mr = recorder ?: return null
        recorder = null
        var result = outputFile
        try {
            mr.stop()
        } catch (e: Exception) {
            Log.w(TAG, "MediaRecorder.stop() failed — output is likely unusable", e)
            result?.delete()
            result = null
        } finally {
            try {
                mr.release()
            } catch (_: Exception) {
            }
            restoreAudioState()
        }
        outputFile = null
        activeTier = null
        activeAudioSource = null
        speakerphoneForceConfirmed = false
        return result
    }

    private fun restoreAudioState() {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.isSpeakerphoneOn = previousSpeakerphoneOn
            audioManager.mode = previousAudioMode
        } catch (e: Exception) {
            Log.w(TAG, "Failed to restore audio state", e)
        }
    }

    companion object {
        private const val TAG = "CallAudioRecorder"

        // A real voice recording at our AAC settings runs well above this
        // floor; a file at or under it for its claimed duration is silence
        // or a near-instant MediaRecorder failure, not a usable recording.
        private const val MIN_BYTES_PER_SECOND = 500

        fun isLikelySilent(file: File, durationSeconds: Int): Boolean {
            if (durationSeconds <= 0) return true
            if (!file.exists() || file.length() == 0L) return true
            return (file.length() / durationSeconds) < MIN_BYTES_PER_SECOND
        }
    }
}
